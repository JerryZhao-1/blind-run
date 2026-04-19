import 'package:aidrun_demo/app/aidrun_app.dart';
import 'package:aidrun_demo/app/providers.dart';
import 'package:aidrun_demo/core/models/api_failure.dart';
import 'package:aidrun_demo/core/models/auth_session.dart';
import 'package:aidrun_demo/core/models/current_user.dart';
import 'package:aidrun_demo/core/models/place_suggestion.dart';
import 'package:aidrun_demo/core/models/run_request_input.dart';
import 'package:aidrun_demo/core/models/run_status.dart';
import 'package:aidrun_demo/core/models/user_role.dart';
import 'package:aidrun_demo/features/volunteer/volunteer_dashboard_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_doubles.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('shows login page on first launch without session', (tester) async {
    final preferences = await _mockPreferences();

    await tester.pumpWidget(
      _buildApp(
        preferences: preferences,
        child: const AidRunApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('发送验证码'), findsOneWidget);
    expect(find.text('登录'), findsOneWidget);
  });

  testWidgets('restores blind session route from persisted auth session', (tester) async {
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

  testWidgets('routes authenticated unset users to role selection', (tester) async {
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

  test('blind run creation is gated when no emergency contact exists', () async {
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
        settingsRepositoryProvider.overrideWithValue(FakeSettingsRepository()),
        blindProfileRepositoryProvider.overrideWithValue(FakeBlindProfileRepository()),
        emergencyContactRepositoryProvider.overrideWithValue(
          FakeEmergencyContactRepository(),
        ),
        orderRepositoryProvider.overrideWithValue(orderRepository),
        volunteerProfileRepositoryProvider.overrideWithValue(
          FakeVolunteerProfileRepository(),
        ),
        appLocationServiceProvider.overrideWithValue(const FakeLocationService()),
      ],
    );
    addTearDown(container.dispose);

    await _waitForBootstrap(container);
    await container.read(appStateControllerProvider.notifier).loadBlindProfileData();

    expect(
      () => container.read(appStateControllerProvider.notifier).createBlindRun(
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
        isA<ApiFailure>().having((error) => error.message, 'message', '请先添加至少一个紧急联系人'),
      ),
    );
    expect(orderRepository.createOrderCalls, 0);
  });

  testWidgets('volunteer dashboard renders backend-backed runs and sends location heartbeat', (
    tester,
  ) async {
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
          const AuthSession(token: 'token', userId: 2, role: UserRole.volunteer),
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
    expect(volunteerProfileRepository.locationCalls.where((call) => call.isOnline), isNotEmpty);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(volunteerProfileRepository.locationCalls.last.isOnline, isFalse);
  });
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
  FakeLocationService? locationService,
  required Widget child,
}) {
  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(preferences),
      authSessionStoreProvider.overrideWithValue(sessionStore ?? FakeAuthSessionStore()),
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
