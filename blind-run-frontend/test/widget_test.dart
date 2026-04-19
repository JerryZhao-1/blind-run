import 'dart:async';

import 'package:aidrun_demo/app/aidrun_app.dart';
import 'package:aidrun_demo/app/providers.dart';
import 'package:aidrun_demo/core/models/api_failure.dart';
import 'package:aidrun_demo/core/models/auth_session.dart';
import 'package:aidrun_demo/core/models/current_user.dart';
import 'package:aidrun_demo/core/models/place_suggestion.dart';
import 'package:aidrun_demo/core/models/run_request_input.dart';
import 'package:aidrun_demo/core/models/run_status.dart';
import 'package:aidrun_demo/core/models/user_role.dart';
import 'package:aidrun_demo/core/services/amap_location_service.dart';
import 'package:aidrun_demo/features/volunteer/volunteer_active_run_page.dart';
import 'package:aidrun_demo/features/volunteer/volunteer_dashboard_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_doubles.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('shows login page on first launch without session', (
    tester,
  ) async {
    final preferences = await _mockPreferences();

    await tester.pumpWidget(
      _buildApp(preferences: preferences, child: const AidRunApp()),
    );

    await tester.pumpAndSettle();

    expect(find.text('发送验证码'), findsOneWidget);
    expect(find.text('登录'), findsOneWidget);
  });

  testWidgets('restores blind session route from persisted auth session', (
    tester,
  ) async {
    final preferences = await _mockPreferences();
    final sessionStore = FakeAuthSessionStore(
      const AuthSession(token: 'token', userId: 1, role: UserRole.blind),
    );
    final authRepository = FakeAuthRepository(
      currentUser: const CurrentUser(
        userId: 1,
        phoneMasked: '138****8000',
        role: UserRole.blind,
      ),
    );

    await tester.pumpWidget(
      _buildApp(
        preferences: preferences,
        sessionStore: sessionStore,
        authRepository: authRepository,
        child: const AidRunApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('发起预约'), findsOneWidget);
  });

  testWidgets('routes authenticated unset users to role selection', (
    tester,
  ) async {
    final preferences = await _mockPreferences();
    final sessionStore = FakeAuthSessionStore(
      const AuthSession(token: 'token', userId: 1, role: UserRole.unset),
    );
    final authRepository = FakeAuthRepository(
      currentUser: const CurrentUser(
        userId: 1,
        phoneMasked: '138****8000',
        role: UserRole.unset,
      ),
    );

    await tester.pumpWidget(
      _buildApp(
        preferences: preferences,
        sessionStore: sessionStore,
        authRepository: authRepository,
        child: const AidRunApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('我是盲人跑者'), findsOneWidget);
    expect(find.text('我是志愿者'), findsOneWidget);
  });

  test(
    'blind run creation is gated when no emergency contact exists',
    () async {
      final preferences = await _mockPreferences();
      final sessionStore = FakeAuthSessionStore(
        const AuthSession(token: 'token', userId: 1, role: UserRole.blind),
      );
      final orderRepository = FakeOrderRepository();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          authSessionStoreProvider.overrideWithValue(sessionStore),
          authRepositoryProvider.overrideWithValue(
            FakeAuthRepository(
              currentUser: const CurrentUser(
                userId: 1,
                phoneMasked: '138****8000',
                role: UserRole.blind,
              ),
            ),
          ),
          settingsRepositoryProvider.overrideWithValue(
            FakeSettingsRepository(),
          ),
          blindProfileRepositoryProvider.overrideWithValue(
            FakeBlindProfileRepository(),
          ),
          emergencyContactRepositoryProvider.overrideWithValue(
            FakeEmergencyContactRepository(),
          ),
          orderRepositoryProvider.overrideWithValue(orderRepository),
          volunteerProfileRepositoryProvider.overrideWithValue(
            FakeVolunteerProfileRepository(),
          ),
          appLocationServiceProvider.overrideWithValue(
            const FakeLocationService(),
          ),
        ],
      );
      addTearDown(container.dispose);

      await _waitForBootstrap(container);
      await container
          .read(appStateControllerProvider.notifier)
          .loadBlindProfileData();

      expect(
        () => container
            .read(appStateControllerProvider.notifier)
            .createBlindRun(
              const RunRequestInput(
                place: PlaceSuggestion(
                  name: '测试地点',
                  address: '测试地址',
                  latitude: 31.2304,
                  longitude: 121.4737,
                ),
                timeLabel: '今天晚上',
              ),
            ),
        throwsA(
          isA<ApiFailure>().having(
            (error) => error.message,
            'message',
            '请先添加至少一个紧急联系人',
          ),
        ),
      );
      expect(orderRepository.createOrderCalls, 0);
    },
  );

  testWidgets(
    'volunteer dashboard renders backend-backed runs and sends location heartbeat',
    (tester) async {
      final preferences = await _mockPreferences();
      final volunteerProfileRepository = FakeVolunteerProfileRepository();
      final orderRepository = FakeOrderRepository(
        availableRuns: [
          buildRun(
            id: '101',
            location: '朝阳公园南门',
            address: '北京市朝阳区朝阳公园南路1号',
            status: RunStatus.pendingAccept,
            blindUserPhone: '138****8000',
          ),
        ],
        volunteerRuns: [
          buildRun(
            id: '202',
            location: '奥森公园',
            status: RunStatus.driverEnRoute,
          ),
        ],
      );

      await tester.pumpWidget(
        _buildApp(
          preferences: preferences,
          sessionStore: FakeAuthSessionStore(
            const AuthSession(
              token: 'token',
              userId: 2,
              role: UserRole.volunteer,
            ),
          ),
          authRepository: FakeAuthRepository(
            currentUser: const CurrentUser(
              userId: 2,
              phoneMasked: '139****9000',
              role: UserRole.volunteer,
            ),
          ),
          orderRepository: orderRepository,
          volunteerProfileRepository: volunteerProfileRepository,
          locationService: const FakeLocationService(),
          child: const MaterialApp(home: VolunteerDashboardPage()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('附近需求 (1)'), findsOneWidget);
      expect(find.text('朝阳公园南门'), findsOneWidget);
      expect(find.text('在线 - 已可接收附近订单'), findsOneWidget);
      expect(
        volunteerProfileRepository.locationCalls.where((call) => call.isOnline),
        isNotEmpty,
      );

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(volunteerProfileRepository.locationCalls.last.isOnline, isFalse);
    },
  );

  testWidgets(
    'volunteer dashboard shows location-unavailable readiness state',
    (tester) async {
      final preferences = await _mockPreferences();

      await tester.pumpWidget(
        _buildApp(
          preferences: preferences,
          sessionStore: FakeAuthSessionStore(
            const AuthSession(
              token: 'token',
              userId: 2,
              role: UserRole.volunteer,
            ),
          ),
          authRepository: FakeAuthRepository(
            currentUser: const CurrentUser(
              userId: 2,
              phoneMasked: '139****9000',
              role: UserRole.volunteer,
            ),
          ),
          locationService: const FakeLocationService(location: null),
          child: const MaterialApp(home: VolunteerDashboardPage()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('定位失败 - 尚未进入接单状态'), findsOneWidget);
      expect(find.textContaining('暂时无法确认附近订单，因为当前定位未成功'), findsOneWidget);
      expect(find.text('无法获取当前位置，请稍后重试。'), findsOneWidget);
      expect(find.text('回到当前位置'), findsNothing);
    },
  );

  testWidgets(
    'volunteer dashboard shows permission-denied message separately',
    (tester) async {
      final preferences = await _mockPreferences();

      await tester.pumpWidget(
        _buildApp(
          preferences: preferences,
          sessionStore: FakeAuthSessionStore(
            const AuthSession(
              token: 'token',
              userId: 2,
              role: UserRole.volunteer,
            ),
          ),
          authRepository: FakeAuthRepository(
            currentUser: const CurrentUser(
              userId: 2,
              phoneMasked: '139****9000',
              role: UserRole.volunteer,
            ),
          ),
          locationService: const FakeLocationService(
            location: null,
            failureReason: DeviceLocationFailureReason.permissionDenied,
          ),
          child: const MaterialApp(home: VolunteerDashboardPage()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('定位失败 - 尚未进入接单状态'), findsOneWidget);
      expect(find.text('没有定位权限，请在系统设置中允许定位后重试。'), findsOneWidget);
    },
  );

  testWidgets('volunteer dashboard shows report-failed readiness state', (
    tester,
  ) async {
    final preferences = await _mockPreferences();
    final volunteerProfileRepository = FakeVolunteerProfileRepository(
      locationError: const ApiFailure(message: '位置同步失败'),
    );

    await tester.pumpWidget(
      _buildApp(
        preferences: preferences,
        sessionStore: FakeAuthSessionStore(
          const AuthSession(
            token: 'token',
            userId: 2,
            role: UserRole.volunteer,
          ),
        ),
        authRepository: FakeAuthRepository(
          currentUser: const CurrentUser(
            userId: 2,
            phoneMasked: '139****9000',
            role: UserRole.volunteer,
          ),
        ),
        volunteerProfileRepository: volunteerProfileRepository,
        locationService: const FakeLocationService(),
        child: const MaterialApp(home: VolunteerDashboardPage()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('同步失败 - 尚未进入接单状态'), findsOneWidget);
    expect(find.textContaining('当前位置尚未成功同步到后台'), findsOneWidget);
    expect(find.text('位置同步失败'), findsOneWidget);
  });

  testWidgets('volunteer dashboard distinguishes ready empty state', (
    tester,
  ) async {
    final preferences = await _mockPreferences();
    final volunteerProfileRepository = FakeVolunteerProfileRepository();

    await tester.pumpWidget(
      _buildApp(
        preferences: preferences,
        sessionStore: FakeAuthSessionStore(
          const AuthSession(
            token: 'token',
            userId: 2,
            role: UserRole.volunteer,
          ),
        ),
        authRepository: FakeAuthRepository(
          currentUser: const CurrentUser(
            userId: 2,
            phoneMasked: '139****9000',
            role: UserRole.volunteer,
          ),
        ),
        volunteerProfileRepository: volunteerProfileRepository,
        orderRepository: FakeOrderRepository(),
        locationService: const FakeLocationService(),
        child: const MaterialApp(home: VolunteerDashboardPage()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('在线 - 已可接收附近订单'), findsOneWidget);
    expect(find.text('当前附近暂无可接订单。请保持在线，有新需求会自动刷新。'), findsOneWidget);
    expect(find.text('回到当前位置'), findsOneWidget);
  });

  testWidgets('volunteer heartbeat keeps ready state while locating', (
    tester,
  ) async {
    final preferences = await _mockPreferences();
    final heartbeatLookup = Completer<DeviceLocationLookup>();
    final locationService = SequencedFakeLocationService([
      const DeviceLocationLookup(
        location: DeviceLocation(latitude: 39.9042, longitude: 116.4074),
      ),
      heartbeatLookup.future,
    ]);

    await tester.pumpWidget(
      _buildApp(
        preferences: preferences,
        sessionStore: FakeAuthSessionStore(
          const AuthSession(
            token: 'token',
            userId: 2,
            role: UserRole.volunteer,
          ),
        ),
        authRepository: FakeAuthRepository(
          currentUser: const CurrentUser(
            userId: 2,
            phoneMasked: '139****9000',
            role: UserRole.volunteer,
          ),
        ),
        locationService: locationService,
        child: const MaterialApp(home: VolunteerDashboardPage()),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('在线 - 已可接收附近订单'), findsOneWidget);
    expect(find.text('回到当前位置'), findsOneWidget);

    await tester.pump(const Duration(seconds: 15));
    await tester.pump();

    expect(find.text('在线 - 已可接收附近订单'), findsOneWidget);
    expect(find.text('准备中 - 正在建立接单状态'), findsNothing);
    expect(find.text('回到当前位置'), findsOneWidget);

    heartbeatLookup.complete(
      const DeviceLocationLookup(
        location: DeviceLocation(latitude: 39.9043, longitude: 116.4075),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('在线 - 已可接收附近订单'), findsOneWidget);
    expect(find.text('回到当前位置'), findsOneWidget);
  });

  testWidgets(
    'volunteer heartbeat downgrades when location fails after ready',
    (tester) async {
      final preferences = await _mockPreferences();
      final locationService = SequencedFakeLocationService([
        const DeviceLocationLookup(
          location: DeviceLocation(latitude: 39.9042, longitude: 116.4074),
        ),
        const DeviceLocationLookup(
          failureReason: DeviceLocationFailureReason.unavailable,
        ),
      ]);

      await tester.pumpWidget(
        _buildApp(
          preferences: preferences,
          sessionStore: FakeAuthSessionStore(
            const AuthSession(
              token: 'token',
              userId: 2,
              role: UserRole.volunteer,
            ),
          ),
          authRepository: FakeAuthRepository(
            currentUser: const CurrentUser(
              userId: 2,
              phoneMasked: '139****9000',
              role: UserRole.volunteer,
            ),
          ),
          locationService: locationService,
          child: const MaterialApp(home: VolunteerDashboardPage()),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('在线 - 已可接收附近订单'), findsOneWidget);

      await tester.pump(const Duration(seconds: 15));
      await tester.pumpAndSettle();

      expect(find.text('定位失败 - 尚未进入接单状态'), findsOneWidget);
      expect(find.text('无法获取当前位置，请稍后重试。'), findsOneWidget);
    },
  );

  testWidgets('volunteer heartbeat downgrades when report fails after ready', (
    tester,
  ) async {
    final preferences = await _mockPreferences();
    final volunteerProfileRepository = FakeVolunteerProfileRepository(
      locationErrors: [
        null,
        const ApiFailure(message: '心跳同步失败'),
      ],
    );
    final locationService = SequencedFakeLocationService([
      const DeviceLocationLookup(
        location: DeviceLocation(latitude: 39.9042, longitude: 116.4074),
      ),
      const DeviceLocationLookup(
        location: DeviceLocation(latitude: 39.9043, longitude: 116.4075),
      ),
    ]);

    await tester.pumpWidget(
      _buildApp(
        preferences: preferences,
        sessionStore: FakeAuthSessionStore(
          const AuthSession(
            token: 'token',
            userId: 2,
            role: UserRole.volunteer,
          ),
        ),
        authRepository: FakeAuthRepository(
          currentUser: const CurrentUser(
            userId: 2,
            phoneMasked: '139****9000',
            role: UserRole.volunteer,
          ),
        ),
        volunteerProfileRepository: volunteerProfileRepository,
        locationService: locationService,
        child: const MaterialApp(home: VolunteerDashboardPage()),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('在线 - 已可接收附近订单'), findsOneWidget);

    await tester.pump(const Duration(seconds: 15));
    await tester.pumpAndSettle();

    expect(find.text('同步失败 - 尚未进入接单状态'), findsOneWidget);
    expect(find.text('心跳同步失败'), findsOneWidget);
  });

  test(
    'volunteer accept handoff preserves pickup context from preview data',
    () async {
      final preferences = await _mockPreferences();
      final orderRepository = FakeOrderRepository(
        availableRuns: [
          buildRun(
            id: '301',
            location: '大亚湾霞涌小径湾1号',
            address: '广东省惠州市惠阳区大亚湾霞涌小径湾1号',
            status: RunStatus.pendingAccept,
            blindUserPhone: '130****9977',
            latitude: 22.7426,
            longitude: 114.6523,
          ),
        ],
        acceptedVolunteerStatus: RunStatus.pendingAccept,
        stripVolunteerContextOnOwnedReads: true,
      );
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          authSessionStoreProvider.overrideWithValue(
            FakeAuthSessionStore(
              const AuthSession(
                token: 'token',
                userId: 2,
                role: UserRole.volunteer,
              ),
            ),
          ),
          authRepositoryProvider.overrideWithValue(
            FakeAuthRepository(
              currentUser: const CurrentUser(
                userId: 2,
                phoneMasked: '139****9000',
                role: UserRole.volunteer,
              ),
            ),
          ),
          settingsRepositoryProvider.overrideWithValue(
            FakeSettingsRepository(),
          ),
          blindProfileRepositoryProvider.overrideWithValue(
            FakeBlindProfileRepository(),
          ),
          emergencyContactRepositoryProvider.overrideWithValue(
            FakeEmergencyContactRepository(),
          ),
          orderRepositoryProvider.overrideWithValue(orderRepository),
          volunteerProfileRepositoryProvider.overrideWithValue(
            FakeVolunteerProfileRepository(),
          ),
          appLocationServiceProvider.overrideWithValue(
            const FakeLocationService(),
          ),
        ],
      );
      addTearDown(container.dispose);

      await _waitForBootstrap(container);
      final controller = container.read(appStateControllerProvider.notifier);
      await controller.refreshVolunteerDashboard();

      final result = await controller.acceptRun('301');

      expect(result.isConfirmed, isTrue);
      final confirmedRun = controller.volunteerOwnedRunById('301');
      expect(confirmedRun, isNotNull);
      expect(confirmedRun!.volunteerOwnershipConfirmed, isTrue);
      expect(confirmedRun.status, RunStatus.pendingAccept);
      expect(confirmedRun.latitude, 22.7426);
      expect(confirmedRun.longitude, 114.6523);
      expect(confirmedRun.blindUserPhone, '130****9977');
      expect(
        container
            .read(appStateControllerProvider)
            .volunteerAvailableRuns
            .where((run) => run.id == '301'),
        isEmpty,
      );
    },
  );

  testWidgets('volunteer accept failure stays on dashboard with feedback', (
    tester,
  ) async {
    final preferences = await _mockPreferences();
    final orderRepository = FakeOrderRepository(
      availableRuns: [
        buildRun(
          id: '302',
          location: '朝阳公园南门',
          address: '北京市朝阳区朝阳公园南路1号',
          status: RunStatus.pendingAccept,
          blindUserPhone: '138****8000',
        ),
      ],
      acceptError: const ApiFailure(message: '您无权查看此订单'),
    );

    await tester.pumpWidget(
      _buildApp(
        preferences: preferences,
        sessionStore: FakeAuthSessionStore(
          const AuthSession(
            token: 'token',
            userId: 2,
            role: UserRole.volunteer,
          ),
        ),
        authRepository: FakeAuthRepository(
          currentUser: const CurrentUser(
            userId: 2,
            phoneMasked: '139****9000',
            role: UserRole.volunteer,
          ),
        ),
        orderRepository: orderRepository,
        volunteerProfileRepository: FakeVolunteerProfileRepository(),
        locationService: const FakeLocationService(),
        child: const AidRunApp(),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('立即接单'));
    await tester.pumpAndSettle();

    expect(find.text('附近需求 (1)'), findsOneWidget);
    expect(find.text('您无权查看此订单'), findsOneWidget);
    expect(find.byType(VolunteerActiveRunPage), findsNothing);
  });

  testWidgets(
    'volunteer active run page keeps confirmed pending state and preserves contact preview',
    (tester) async {
      final preferences = await _mockPreferences();
      final orderRepository = FakeOrderRepository(
        volunteerRuns: [
          buildRun(
            id: '303',
            location: '大亚湾霞涌小径湾1号',
            address: '广东省惠州市惠阳区大亚湾霞涌小径湾1号',
            status: RunStatus.pendingAccept,
            blindUserPhone: '130****9977',
            latitude: 22.7426,
            longitude: 114.6523,
            volunteerOwnershipConfirmed: true,
          ),
        ],
      );

      await tester.pumpWidget(
        _buildApp(
          preferences: preferences,
          sessionStore: FakeAuthSessionStore(
            const AuthSession(
              token: 'token',
              userId: 2,
              role: UserRole.volunteer,
            ),
          ),
          authRepository: FakeAuthRepository(
            currentUser: const CurrentUser(
              userId: 2,
              phoneMasked: '139****9000',
              role: UserRole.volunteer,
            ),
          ),
          orderRepository: orderRepository,
          child: const MaterialApp(home: VolunteerActiveRunPage(runId: '303')),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('接单确认中'), findsOneWidget);
      expect(find.text('订单已归属给你，等待后台同步下一步状态'), findsOneWidget);
      expect(find.text('130****9977'), findsOneWidget);
      expect(find.text('待接单'), findsNothing);
    },
  );

  testWidgets(
    'volunteer active run page shows explicit location-unavailable state when pickup coordinates are missing',
    (tester) async {
      final preferences = await _mockPreferences();
      final orderRepository = FakeOrderRepository(
        volunteerRuns: [
          buildRun(
            id: '304',
            location: '大亚湾霞涌小径湾1号',
            address: '广东省惠州市惠阳区大亚湾霞涌小径湾1号',
            status: RunStatus.inProgress,
            latitude: null,
            longitude: null,
            volunteerOwnershipConfirmed: true,
          ),
        ],
      );

      await tester.pumpWidget(
        _buildApp(
          preferences: preferences,
          sessionStore: FakeAuthSessionStore(
            const AuthSession(
              token: 'token',
              userId: 2,
              role: UserRole.volunteer,
            ),
          ),
          authRepository: FakeAuthRepository(
            currentUser: const CurrentUser(
              userId: 2,
              phoneMasked: '139****9000',
              role: UserRole.volunteer,
            ),
          ),
          orderRepository: orderRepository,
          child: const MaterialApp(home: VolunteerActiveRunPage(runId: '304')),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('集合点定位暂不可用'), findsOneWidget);
      expect(find.text('我已出发'), findsOneWidget);
    },
  );
}

Widget _buildApp({
  required SharedPreferences preferences,
  FakeAuthSessionStore? sessionStore,
  FakeAuthRepository? authRepository,
  FakeBlindProfileRepository? blindProfileRepository,
  FakeEmergencyContactRepository? emergencyContactRepository,
  FakeOrderRepository? orderRepository,
  FakeVolunteerProfileRepository? volunteerProfileRepository,
  FakeSettingsRepository? settingsRepository,
  AppLocationService? locationService,
  required Widget child,
}) {
  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(preferences),
      authSessionStoreProvider.overrideWithValue(
        sessionStore ?? FakeAuthSessionStore(),
      ),
      authRepositoryProvider.overrideWithValue(
        authRepository ??
            FakeAuthRepository(
              currentUser: const CurrentUser(
                userId: 1,
                phoneMasked: '138****8000',
                role: UserRole.unset,
              ),
            ),
      ),
      settingsRepositoryProvider.overrideWithValue(
        settingsRepository ?? FakeSettingsRepository(),
      ),
      blindProfileRepositoryProvider.overrideWithValue(
        blindProfileRepository ?? FakeBlindProfileRepository(),
      ),
      emergencyContactRepositoryProvider.overrideWithValue(
        emergencyContactRepository ?? FakeEmergencyContactRepository(),
      ),
      orderRepositoryProvider.overrideWithValue(
        orderRepository ?? FakeOrderRepository(),
      ),
      volunteerProfileRepositoryProvider.overrideWithValue(
        volunteerProfileRepository ?? FakeVolunteerProfileRepository(),
      ),
      appLocationServiceProvider.overrideWithValue(
        locationService ?? const FakeLocationService(),
      ),
    ],
    child: child,
  );
}

Future<SharedPreferences> _mockPreferences() async {
  SharedPreferences.setMockInitialValues({});
  return SharedPreferences.getInstance();
}

Future<void> _waitForBootstrap(ProviderContainer container) async {
  container.read(appStateControllerProvider);
  for (var index = 0; index < 10; index += 1) {
    if (!container.read(appStateControllerProvider).bootstrapping) {
      return;
    }
    await Future<void>.delayed(Duration.zero);
  }
}
