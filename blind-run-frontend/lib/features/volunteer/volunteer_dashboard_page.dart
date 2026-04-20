import 'dart:async';

import 'package:aidrun_demo/app/providers.dart';
import 'package:aidrun_demo/app/state/app_state_controller.dart';
import 'package:aidrun_demo/core/models/reward_item.dart';
import 'package:aidrun_demo/core/models/run.dart';
import 'package:aidrun_demo/core/models/run_status.dart';
import 'package:aidrun_demo/core/models/volunteer_intake_readiness.dart';
import 'package:aidrun_demo/core/services/amap_config.dart';
import 'package:aidrun_demo/core/services/amap_location_service.dart';
import 'package:aidrun_demo/core/models/volunteer_profile.dart';
import 'package:aidrun_demo/core/theme/app_theme.dart';
import 'package:aidrun_demo/core/widgets/amap_map_view.dart';
import 'package:aidrun_demo/core/widgets/common_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class VolunteerDashboardPage extends ConsumerStatefulWidget {
  const VolunteerDashboardPage({super.key});

  @override
  ConsumerState<VolunteerDashboardPage> createState() =>
      _VolunteerDashboardPageState();
}

class _VolunteerDashboardPageState
    extends ConsumerState<VolunteerDashboardPage> {
  Timer? _refreshTimer;
  Timer? _locationHeartbeatTimer;
  int _tabIndex = 0;
  String? _lastLocationStatusMessage;
  String? _lastLocationDebugInfo;
  DeviceLocation? _latestVolunteerLocation;
  int _mapCameraMoveRequestKey = 0;
  bool _hasAutoCenteredMap = false;
  Future<void>? _ongoingReadinessSync;
  late final AppStateController _controller;
  late final AppLocationService _locationService;

  @override
  void initState() {
    super.initState();
    _controller = ref.read(appStateControllerProvider.notifier);
    _locationService = ref.read(appLocationServiceProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _refreshDashboardResult();
      _syncAvailabilityState();
      await _establishVolunteerIntakeReadiness(visibleConnecting: true);
      _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
        final refreshed = await _refreshDashboardResult();
        if (!refreshed &&
            _controller.settings.volunteerAvailable &&
            _controller.volunteerIntakeReadiness.isReady) {
          _controller.setVolunteerIntakeReadiness(
            VolunteerIntakeReadiness.reportFailed,
          );
        }
      });
      _startOrStopLocationHeartbeat(sendImmediately: false);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _locationHeartbeatTimer?.cancel();
    unawaited(_sendOfflineLocation());
    super.dispose();
  }

  Future<bool> _refreshDashboardResult() async {
    return _controller.refreshVolunteerDashboard();
  }

  void _syncAvailabilityState() {
    if (_controller.settings.volunteerAvailable) {
      _controller.setVolunteerIntakeReadiness(
        VolunteerIntakeReadiness.connecting,
        clearError: true,
      );
      return;
    }
    _controller.setVolunteerIntakeReadiness(
      VolunteerIntakeReadiness.offline,
      clearError: true,
    );
  }

  Future<void> _establishVolunteerIntakeReadiness({
    required bool visibleConnecting,
  }) async {
    final inFlight = _ongoingReadinessSync;
    if (inFlight != null) {
      return inFlight;
    }

    final future = _establishVolunteerIntakeReadinessInternal(
      visibleConnecting: visibleConnecting,
    );
    _ongoingReadinessSync = future;
    try {
      await future;
    } finally {
      if (identical(_ongoingReadinessSync, future)) {
        _ongoingReadinessSync = null;
      }
    }
  }

  Future<void> _establishVolunteerIntakeReadinessInternal({
    required bool visibleConnecting,
  }) async {
    if (!_controller.settings.volunteerAvailable) {
      if (mounted) {
        setState(() {
          _lastLocationStatusMessage = null;
          _lastLocationDebugInfo = null;
          _latestVolunteerLocation = null;
          _mapCameraMoveRequestKey = 0;
          _hasAutoCenteredMap = false;
        });
      }
      _controller.setVolunteerIntakeReadiness(
        VolunteerIntakeReadiness.offline,
        clearError: true,
      );
      return;
    }
    if (visibleConnecting || !_controller.volunteerIntakeReadiness.isReady) {
      _controller.setVolunteerIntakeReadiness(
        VolunteerIntakeReadiness.connecting,
        clearError: true,
      );
    }
    final lookup = await _locationService.locate();
    if (mounted) {
      setState(() {
        _lastLocationStatusMessage = null;
        _lastLocationDebugInfo = _formatLocationDebugInfo(lookup);
      });
    }
    final location = lookup.location;
    if (location == null) {
      final message =
          lookup.failureReason == DeviceLocationFailureReason.permissionDenied
          ? '没有定位权限，请在系统设置中允许定位后重试。'
          : (lookup.errorMessage?.trim().isNotEmpty == true
                ? lookup.errorMessage!.trim()
                : '无法获取当前位置，请稍后重试。');
      _controller.setVolunteerIntakeReadiness(
        VolunteerIntakeReadiness.locationUnavailable,
        errorMessage: message,
      );
      if (mounted) {
        setState(() {
          _lastLocationStatusMessage = message;
        });
      }
      return;
    }
    _storeLatestVolunteerLocation(location);
    final reported = await _controller.reportVolunteerLocation(
      latitude: location.latitude,
      longitude: location.longitude,
      isOnline: true,
    );
    if (!reported) {
      _controller.setVolunteerIntakeReadiness(
        VolunteerIntakeReadiness.reportFailed,
      );
      if (mounted) {
        setState(() {
          _lastLocationStatusMessage = ref
              .read(appStateControllerProvider)
              .errorMessage;
        });
      }
      return;
    }
    _controller.setVolunteerIntakeReadiness(
      VolunteerIntakeReadiness.onlineReady,
      clearError: true,
    );
    if (mounted) {
      setState(() {
        _lastLocationStatusMessage = null;
      });
    }
    final refreshed = await _refreshDashboardResult();
    if (!refreshed) {
      _controller.setVolunteerIntakeReadiness(
        VolunteerIntakeReadiness.reportFailed,
      );
      if (mounted) {
        setState(() {
          _lastLocationStatusMessage = ref
              .read(appStateControllerProvider)
              .errorMessage;
        });
      }
    }
  }

  void _startOrStopLocationHeartbeat({bool sendImmediately = true}) {
    final available = ref
        .read(appStateControllerProvider)
        .settings
        .volunteerAvailable;
    _locationHeartbeatTimer?.cancel();
    if (!available) {
      if (mounted) {
        setState(() {
          _lastLocationStatusMessage = null;
          _lastLocationDebugInfo = null;
          _latestVolunteerLocation = null;
          _mapCameraMoveRequestKey = 0;
          _hasAutoCenteredMap = false;
        });
      }
      _controller.setVolunteerIntakeReadiness(
        VolunteerIntakeReadiness.offline,
        clearError: true,
      );
      unawaited(_sendOfflineLocation());
      return;
    }
    if (sendImmediately) {
      _controller.setVolunteerIntakeReadiness(
        VolunteerIntakeReadiness.connecting,
        clearError: true,
      );
      unawaited(_sendOnlineLocation(visibleConnecting: true));
    }
    _locationHeartbeatTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _sendOnlineLocation(visibleConnecting: false),
    );
  }

  Future<void> _sendOnlineLocation({required bool visibleConnecting}) async {
    await _establishVolunteerIntakeReadiness(
      visibleConnecting: visibleConnecting,
    );
  }

  Future<void> _sendOfflineLocation() async {
    final location = await _locationService.locateOnce();
    final latitude = location?.latitude ?? 39.9042;
    final longitude = location?.longitude ?? 116.4074;
    await _controller.reportVolunteerLocation(
      latitude: latitude,
      longitude: longitude,
      isOnline: false,
    );
  }

  void _storeLatestVolunteerLocation(DeviceLocation location) {
    final shouldAutoCenter = !_hasAutoCenteredMap;
    if (!mounted) {
      _latestVolunteerLocation = location;
      if (shouldAutoCenter) {
        _hasAutoCenteredMap = true;
        _mapCameraMoveRequestKey += 1;
      }
      return;
    }
    setState(() {
      _latestVolunteerLocation = location;
      if (shouldAutoCenter) {
        _hasAutoCenteredMap = true;
        _mapCameraMoveRequestKey += 1;
      }
    });
  }

  void _centerMapOnLatestLocation() {
    if (_latestVolunteerLocation == null || !mounted) {
      return;
    }
    setState(() {
      _mapCameraMoveRequestKey += 1;
    });
  }

  String _formatLocationDebugInfo(DeviceLocationLookup lookup) {
    final raw = lookup.rawResult;
    final values = <String>[
      'failureReason=${lookup.failureReason?.name ?? '-'}',
      'errorCode=${lookup.errorCode ?? raw?['errorCode'] ?? '-'}',
      'errorInfo=${lookup.errorMessage ?? raw?['errorInfo'] ?? '-'}',
      'latitude=${raw?['latitude'] ?? lookup.location?.latitude ?? '-'}',
      'longitude=${raw?['longitude'] ?? lookup.location?.longitude ?? '-'}',
    ];
    if (raw != null && raw.isNotEmpty) {
      values.add('raw=$raw');
    }
    return values.join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateControllerProvider);
    final controller = ref.read(appStateControllerProvider.notifier);
    final pendingRuns = state.volunteerAvailableRuns;
    final activeRun = controller.volunteerActiveRun;
    final volunteerHistoryRuns = controller.volunteerHistoryRuns;

    final pages = [
      _VolunteerMapTab(
        config: ref.watch(aMapConfigProvider),
        controller: controller,
        pendingRuns: pendingRuns,
        activeRun: activeRun,
        readiness: state.volunteerIntakeReadiness,
        errorMessage: _lastLocationStatusMessage ?? state.errorMessage,
        locationDebugInfo: _lastLocationDebugInfo,
        currentLocation: _latestVolunteerLocation,
        cameraMoveRequestKey: _mapCameraMoveRequestKey,
        onAvailabilityChanged: (value) {
          controller.updateVolunteerAvailability(value);
          _startOrStopLocationHeartbeat();
        },
        onCenterOnCurrentLocation: _centerMapOnLatestLocation,
      ),
      _VolunteerHistoryTab(history: volunteerHistoryRuns),
      _VolunteerStoreTab(rewards: state.rewards),
      _VolunteerProfileTab(
        controller: controller,
        profile: state.volunteerProfile,
      ),
    ];

    return Scaffold(
      body: pages[_tabIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        indicatorColor: Colors.black,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected: (value) => setState(() => _tabIndex = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.map_outlined), label: '地图'),
          NavigationDestination(icon: Icon(Icons.history), label: '历史'),
          NavigationDestination(icon: Icon(Icons.card_giftcard), label: '商城'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: '我的'),
        ],
      ),
    );
  }
}

class _VolunteerMapTab extends StatelessWidget {
  const _VolunteerMapTab({
    required this.config,
    required this.controller,
    required this.pendingRuns,
    required this.activeRun,
    required this.readiness,
    required this.errorMessage,
    required this.locationDebugInfo,
    required this.currentLocation,
    required this.cameraMoveRequestKey,
    required this.onAvailabilityChanged,
    required this.onCenterOnCurrentLocation,
  });

  final AMapConfig config;
  final AppStateController controller;
  final List<Run> pendingRuns;
  final Run? activeRun;
  final VolunteerIntakeReadiness readiness;
  final String? errorMessage;
  final String? locationDebugInfo;
  final DeviceLocation? currentLocation;
  final int cameraMoveRequestKey;
  final ValueChanged<bool> onAvailabilityChanged;
  final VoidCallback onCenterOnCurrentLocation;

  @override
  Widget build(BuildContext context) {
    final currentActiveRun = activeRun;
    final latestLocation = currentLocation;
    final primaryPinnedRun =
        currentActiveRun ??
        pendingRuns.where((run) => run.latitude != null && run.longitude != null).firstOrNull;
    final points = pendingRuns
        .where((run) => run.latitude != null && run.longitude != null)
        .map(
          (run) => AMapMarkerViewData(
            id: run.id,
            latitude: run.latitude!,
            longitude: run.longitude!,
            title: run.location,
            snippet: run.address.isEmpty ? run.timeLabel : run.address,
          ),
        )
        .toList(growable: true);
    if (latestLocation != null) {
      points.add(
        AMapMarkerViewData(
          id: '__current_location__',
          latitude: latestLocation.latitude,
          longitude: latestLocation.longitude,
          title: '当前位置',
          snippet: '以当前接单定位为准',
        ),
      );
    }
    final initialCenterLatitude =
        latestLocation?.latitude ??
        primaryPinnedRun?.latitude ??
        23.0785;
    final initialCenterLongitude =
        latestLocation?.longitude ??
        primaryPinnedRun?.longitude ??
        114.4127;
    final isOnline = controller.settings.volunteerAvailable;
    final status = _readinessContent(readiness);
    final emptyState = _emptyStateCopy(readiness);

    return Stack(
      children: [
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 220),
            child: AMapMapView(
              config: config,
              centerLatitude: initialCenterLatitude,
              centerLongitude: initialCenterLongitude,
              zoom: 11,
              showMyLocation: true,
              markers: points,
              cameraMoveRequestKey: latestLocation == null
                  ? null
                  : cameraMoveRequestKey,
              cameraMoveLatitude: latestLocation?.latitude,
              cameraMoveLongitude: latestLocation?.longitude,
              cameraMoveZoom: 15,
              fallbackMessage: '高德地图未配置完成，当前显示附近需求列表，地图区域已降级。',
            ),
          ),
        ),
        Positioned(
          top: MediaQuery.of(context).padding.top + 16,
          left: 16,
          right: 16,
          child: SectionCard(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                Icon(Icons.circle, color: status.color, size: 12),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    status.title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Switch(value: isOnline, onChanged: onAvailabilityChanged),
              ],
            ),
          ),
        ),
        if (latestLocation != null)
          Positioned(
            top: MediaQuery.of(context).padding.top + 92,
            right: 16,
            child: FilledButton.icon(
              onPressed: onCenterOnCurrentLocation,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                elevation: 2,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              icon: const Icon(Icons.my_location),
              label: const Text(
                '回到当前位置',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            height: MediaQuery.of(context).size.height * 0.58,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '附近需求 (${pendingRuns.length})',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        status.description,
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '地图会在首次定位成功后跳转到当前位置，之后可通过按钮回到当前位置。',
                        style: TextStyle(
                          color: Colors.black45,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    children: [
                      if (currentActiveRun != null)
                        GestureDetector(
                          onTap: () => context.go(
                            '/volunteer/run/${currentActiveRun.id}',
                          ),
                          child: SectionCard(
                            color: Colors.black,
                            child: const Row(
                              children: [
                                Icon(Icons.navigation, color: Colors.white),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    '当前行程进行中',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (currentActiveRun != null) const SizedBox(height: 12),
                      if (pendingRuns.isEmpty)
                        SectionCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                emptyState,
                                style: const TextStyle(fontSize: 18),
                              ),
                              if (errorMessage != null) ...[
                                const SizedBox(height: 12),
                                Text(
                                  errorMessage!,
                                  style: const TextStyle(
                                    color: AppTheme.red,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                              if (locationDebugInfo != null &&
                                  locationDebugInfo!.trim().isNotEmpty &&
                                  readiness !=
                                      VolunteerIntakeReadiness.onlineReady) ...[
                                const SizedBox(height: 12),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF6F6F6),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        '定位诊断',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        locationDebugInfo!,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.black54,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      if (errorMessage != null && pendingRuns.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          errorMessage!,
                          style: const TextStyle(
                            color: AppTheme.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      for (final run in pendingRuns) ...[
                        SectionCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppTheme.softGray,
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: const Icon(Icons.place),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          run.location,
                                          style: const TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          run.timeLabel,
                                          style: const TextStyle(
                                            color: Colors.black54,
                                            fontSize: 16,
                                          ),
                                        ),
                                        if (run.distanceKm != null) ...[
                                          const SizedBox(height: 6),
                                          Text(
                                            '距离约 ${run.distanceKm!.toStringAsFixed(1)} km',
                                            style: const TextStyle(
                                              color: Colors.black54,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                        if ((run.blindUserPhone ?? '')
                                            .isNotEmpty) ...[
                                          const SizedBox(height: 6),
                                          Text(
                                            '跑者电话 ${run.blindUserPhone!}',
                                            style: const TextStyle(
                                              color: Colors.black54,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton(
                                  onPressed: currentActiveRun != null
                                      ? null
                                      : () async {
                                          final result = await controller.acceptRun(
                                            run.id,
                                          );
                                          if (!context.mounted) {
                                            return;
                                          }
                                          if (!result.isConfirmed) {
                                            return;
                                          }
                                          context.go(
                                            '/volunteer/run/${run.id}',
                                          );
                                        },
                                  style: FilledButton.styleFrom(
                                    backgroundColor: Colors.black,
                                    foregroundColor: Colors.white,
                                    disabledBackgroundColor: Colors.black12,
                                    disabledForegroundColor: Colors.black38,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                  ),
                                  child: Text(
                                    currentActiveRun != null
                                        ? '请先完成当前行程'
                                        : '立即接单',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ReadinessContent {
  const _ReadinessContent({
    required this.title,
    required this.description,
    required this.color,
  });

  final String title;
  final String description;
  final Color color;
}

_ReadinessContent _readinessContent(VolunteerIntakeReadiness readiness) {
  return switch (readiness) {
    VolunteerIntakeReadiness.offline => const _ReadinessContent(
      title: '离线 - 暂停接收新订单',
      description: '你当前未接收新订单，打开开关后应用会尝试定位并建立接单状态。',
      color: AppTheme.red,
    ),
    VolunteerIntakeReadiness.connecting => const _ReadinessContent(
      title: '准备中 - 正在建立接单状态',
      description: '正在获取当前位置并同步到后台，完成后才会确认附近订单结果。',
      color: Colors.orange,
    ),
    VolunteerIntakeReadiness.onlineReady => const _ReadinessContent(
      title: '在线 - 已可接收附近订单',
      description: '当前位置已同步到后台，附近订单列表现在代表真实可接机会。',
      color: AppTheme.emerald,
    ),
    VolunteerIntakeReadiness.locationUnavailable => const _ReadinessContent(
      title: '定位失败 - 尚未进入接单状态',
      description: '需要先成功获取当前位置，才能确认附近可接订单。',
      color: AppTheme.red,
    ),
    VolunteerIntakeReadiness.reportFailed => const _ReadinessContent(
      title: '同步失败 - 尚未进入接单状态',
      description: '已尝试定位，但后台未确认当前位置，附近订单结果暂不可信。',
      color: AppTheme.red,
    ),
  };
}

String _emptyStateCopy(VolunteerIntakeReadiness readiness) {
  return switch (readiness) {
    VolunteerIntakeReadiness.offline => '你当前处于离线状态，打开接单开关后才会尝试加载附近订单。',
    VolunteerIntakeReadiness.connecting => '正在准备接单状态，请稍候，系统完成定位和同步后会刷新附近需求。',
    VolunteerIntakeReadiness.onlineReady => '当前附近暂无可接订单。请保持在线，有新需求会自动刷新。',
    VolunteerIntakeReadiness.locationUnavailable =>
      '暂时无法确认附近订单，因为当前定位未成功。请检查定位权限后重试。',
    VolunteerIntakeReadiness.reportFailed =>
      '暂时无法确认附近订单，因为当前位置尚未成功同步到后台。请稍后重试。',
  };
}

class _VolunteerHistoryTab extends StatelessWidget {
  const _VolunteerHistoryTab({required this.history});

  final List<Run> history;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          '历史行程',
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (history.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Text('暂无历史行程'),
              ),
            ),
          for (final run in history) ...[
            SectionCard(
              child: Row(
                children: [
                  const Icon(Icons.check_circle, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          run.location,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text('${run.timeLabel} · ${run.status.volunteerLabel}'),
                      ],
                    ),
                  ),
                  Text(
                    run.status == RunStatus.completed ? '+50 积分' : '已取消',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _VolunteerStoreTab extends StatelessWidget {
  const _VolunteerStoreTab({required this.rewards});

  final List<RewardItem> rewards;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.softGray,
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            title: const Text('积分商城'),
          ),
          SliverToBoxAdapter(
            child: Container(
              color: Colors.black,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: const SectionCard(
                color: Color(0xFF1D1D1F),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('当前可用积分', style: TextStyle(color: Colors.white70)),
                    SizedBox(height: 12),
                    Text(
                      '1,250 分',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.6,
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
                final item = rewards[index];
                return SectionCard(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppNetworkImage(
                        imageUrl: item.imageUrl,
                        height: 96,
                        width: double.infinity,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        item.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${item.points} 积分',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: () {},
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.black,
                                foregroundColor: Colors.white,
                                minimumSize: const Size.fromHeight(36),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                              ),
                              child: const Text('兑换'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }, childCount: rewards.length),
            ),
          ),
        ],
      ),
    );
  }
}

class _VolunteerProfileTab extends StatelessWidget {
  const _VolunteerProfileTab({required this.controller, required this.profile});

  final AppStateController controller;
  final VolunteerProfile? profile;

  @override
  Widget build(BuildContext context) {
    final user = controller.currentUser;
    final displayName = profile?.name.isNotEmpty == true
        ? profile!.name
        : (user?.displayName ?? '志愿者');

    return Scaffold(
      backgroundColor: AppTheme.softGray,
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 32),
          SectionCard(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 42,
                  backgroundColor: AppTheme.softGray,
                  child: Text(
                    displayName.characters.first,
                    style: const TextStyle(fontSize: 36),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  displayName,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '认证状态：${profile?.verificationStatus.isNotEmpty == true ? profile!.verificationStatus : '未认证'}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _Metric(
                      label: '完成行程',
                      value:
                          '${controller.volunteerHistoryRuns.where((run) => run.status == RunStatus.completed).length}',
                    ),
                    _Metric(
                      label: '进行中',
                      value: controller.volunteerActiveRun == null ? '0' : '1',
                    ),
                    _Metric(
                      label: '可接订单',
                      value: '${controller.pendingRuns.length}',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SectionCard(
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.settings),
                  title: const Text('设置'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/settings'),
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.logout, color: AppTheme.red),
                  title: const Text(
                    '退出登录',
                    style: TextStyle(color: AppTheme.red),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    controller.logout();
                    context.go('/login');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.black54)),
      ],
    );
  }
}
