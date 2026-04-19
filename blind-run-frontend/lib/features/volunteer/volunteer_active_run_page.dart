import 'dart:async';

import 'package:aidrun_demo/app/providers.dart';
import 'package:aidrun_demo/core/models/run_status.dart';
import 'package:aidrun_demo/core/theme/app_theme.dart';
import 'package:aidrun_demo/core/widgets/amap_map_view.dart';
import 'package:aidrun_demo/core/widgets/common_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class VolunteerActiveRunPage extends ConsumerStatefulWidget {
  const VolunteerActiveRunPage({
    super.key,
    required this.runId,
  });

  final String runId;

  @override
  ConsumerState<VolunteerActiveRunPage> createState() =>
      _VolunteerActiveRunPageState();
}

class _VolunteerActiveRunPageState extends ConsumerState<VolunteerActiveRunPage> {
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refresh();
      _pollingTimer = Timer.periodic(
        const Duration(seconds: 5),
        (_) => _refresh(),
      );
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    await ref.read(appStateControllerProvider.notifier).refreshOrder(widget.runId);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateControllerProvider);
    final controller = ref.read(appStateControllerProvider.notifier);
    final config = ref.watch(aMapConfigProvider);
    final run = controller.runById(widget.runId);
    if (run == null) {
      return const Scaffold(
        body: Center(child: Text('未找到行程')),
      );
    }

    if (run.status == RunStatus.completed) {
      return Scaffold(
        backgroundColor: AppTheme.softGray,
        body: Stack(
          children: [
            Positioned.fill(
              child: AMapMapView(
                config: config,
                centerLatitude: run.latitude ?? 39.9062,
                centerLongitude: run.longitude ?? 116.4074,
                zoom: 15,
                markers: [
                  if (run.latitude != null && run.longitude != null)
                    AMapMarkerViewData(
                      id: run.id,
                      latitude: run.latitude!,
                      longitude: run.longitude!,
                      title: run.location,
                      snippet: run.address,
                    ),
                ],
                fallbackMessage: '高德地图未配置完成，结算页地图已降级为占位状态。',
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '行程结算',
                      style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 8),
                    const Text('感谢您的爱心陪伴'),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: SectionCard(
                            color: AppTheme.softGray,
                            child: Column(
                              children: [
                                const Text('里程'),
                                const SizedBox(height: 8),
                                Text(
                                  '${run.distanceKm?.toStringAsFixed(1) ?? '—'} km',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SectionCard(
                            color: AppTheme.softGray,
                            child: Column(
                              children: [
                                const Text('时长'),
                                const SizedBox(height: 8),
                                Text(
                                  '${run.durationMinutes ?? 60} min',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: SectionCard(
                            color: Color(0xFFD1FAE5),
                            child: Column(
                              children: [
                                Text('获得积分'),
                                SizedBox(height: 8),
                                Text(
                                  '+50',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    color: AppTheme.emerald,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => context.go('/volunteer'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text('返回大厅'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    final supportText = switch (run.status) {
      RunStatus.inProgress => '请先出发前往集合地点',
      RunStatus.driverEnRoute => '请尽快到达集合地点',
      RunStatus.driverArrived => '你已到达，请完成本次陪跑并在结束后结算',
      RunStatus.pendingAccept => '准备接单',
      RunStatus.pendingMatch => '订单仍在匹配中',
      RunStatus.cancelled => '行程已取消',
      RunStatus.rematching => '订单重新匹配中',
      RunStatus.noVolunteer => '暂无可用状态',
      RunStatus.completed => '感谢您的志愿服务',
    };

    return Scaffold(
      backgroundColor: AppTheme.softGray,
      body: Stack(
        children: [
          Positioned.fill(
            child: AMapMapView(
              config: config,
              centerLatitude: run.latitude ?? 39.9042,
              centerLongitude: run.longitude ?? 116.4074,
              zoom: 13,
              markers: [
                if (run.latitude != null && run.longitude != null)
                  AMapMarkerViewData(
                    id: run.id,
                    latitude: run.latitude!,
                    longitude: run.longitude!,
                    title: run.location,
                    snippet: run.address.isEmpty ? run.timeLabel : run.address,
                  ),
              ],
              fallbackMessage: '高德地图未配置完成，行程地图已降级为占位状态。',
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            child: FilledButton(
              onPressed: () => context.go('/volunteer'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(16),
              ),
              child: const Icon(Icons.arrow_back),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    run.status.volunteerLabel,
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  Text(supportText),
                  const SizedBox(height: 20),
                  SectionCard(
                    color: AppTheme.softGray,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const CircleAvatar(child: Icon(Icons.person)),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                '盲人跑者',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            if ((run.blindUserPhone ?? '').isNotEmpty)
                              Text(
                                run.blindUserPhone!,
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.place),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '${run.location}\n${run.timeLabel}${run.notes.isEmpty ? '' : '\n备注: ${run.notes}'}',
                                style: const TextStyle(height: 1.6),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () async {
                        switch (run.status) {
                          case RunStatus.inProgress:
                            await controller.markEnRoute(run.id);
                          case RunStatus.driverEnRoute:
                            await controller.markArrived(run.id);
                          case RunStatus.driverArrived:
                            await controller.finishRun(run.id);
                          default:
                            return;
                        }
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: run.status == RunStatus.driverArrived
                            ? AppTheme.red
                            : Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      icon: Icon(
                        switch (run.status) {
                          RunStatus.inProgress => Icons.navigation,
                          RunStatus.driverEnRoute => Icons.place,
                          RunStatus.driverArrived => Icons.flag,
                          _ => Icons.check,
                        },
                      ),
                      label: Text(
                        switch (run.status) {
                          RunStatus.inProgress => '我已出发',
                          RunStatus.driverEnRoute => '我已到达集合点',
                          RunStatus.driverArrived => '结束行程',
                          _ => '返回',
                        },
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  if (state.errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      state.errorMessage!,
                      style: const TextStyle(color: AppTheme.red),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
