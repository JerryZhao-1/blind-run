import 'package:aidrun_demo/app/aidrun_app.dart';
import 'package:aidrun_demo/app/providers.dart';
import 'package:aidrun_demo/core/models/place_suggestion.dart';
import 'package:aidrun_demo/core/models/run_request_input.dart';
import 'package:aidrun_demo/core/services/amap_config.dart';
import 'package:aidrun_demo/core/services/place_search_service.dart';
import 'package:aidrun_demo/core/widgets/amap_map_view.dart';
import 'package:aidrun_demo/features/blind/blind_active_run_page.dart';
import 'package:aidrun_demo/features/volunteer/volunteer_dashboard_page.dart';
import 'package:aidrun_demo/core/models/user_role.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('shows role selection on first launch', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
        ],
        child: const AidRunApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('我是盲人跑者'), findsOneWidget);
    expect(find.text('我是志愿者'), findsOneWidget);
  });

  testWidgets('restores blind session route', (tester) async {
    SharedPreferences.setMockInitialValues({
      'aidrun_role': UserRole.blind.name,
    });
    final preferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
        ],
        child: const AidRunApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('发起预约'), findsOneWidget);
  });

  testWidgets('blind active run page refreshes after simulated volunteer accept', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(preferences),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: BlindActiveRunPage(runId: 'mock-1'),
        ),
      ),
    );

    expect(find.text('[测试] 模拟志愿者接单'), findsOneWidget);
    expect(find.text('正在匹配志愿者'), findsOneWidget);

    await tester.tap(find.text('[测试] 模拟志愿者接单'));
    await tester.pump();

    expect(find.text('志愿者已接单'), findsOneWidget);
    expect(find.text('联系志愿者'), findsOneWidget);
  });

  testWidgets('volunteer dashboard refreshes pending and active sections after accept', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({
      'aidrun_role': UserRole.volunteer.name,
    });
    final preferences = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(preferences),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: VolunteerDashboardPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('附近需求 (3)'), findsOneWidget);
    expect(find.text('当前行程进行中'), findsNothing);

    container.read(appStateControllerProvider.notifier).acceptRun('mock-1');
    await tester.pumpAndSettle();

    expect(find.text('附近需求 (2)'), findsOneWidget);
    expect(find.text('当前行程进行中'), findsOneWidget);
  });

  testWidgets('volunteer demand sheet defaults to middle state and snaps between states', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final container = await _createVolunteerContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: VolunteerDashboardPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('volunteer-demand-sheet-middle')), findsOneWidget);
    expect(find.byKey(const ValueKey('run-card-mock-2')), findsOneWidget);

    await tester.drag(
      find.byKey(const ValueKey('volunteer-demand-sheet-handle')),
      const Offset(0, 320),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('volunteer-demand-sheet-lower')), findsOneWidget);
    expect(find.byKey(const ValueKey('run-card-mock-2')), findsNothing);
    expect(find.byKey(const ValueKey('run-card-mock-1')), findsOneWidget);

    await tester.drag(
      find.byKey(const ValueKey('volunteer-demand-sheet-handle')),
      const Offset(0, -520),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('volunteer-demand-sheet-upper')), findsOneWidget);
    expect(find.byKey(const ValueKey('run-card-mock-2')), findsOneWidget);
  });

  testWidgets('marker tap expands lower sheet to middle and reveals the matching card', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final container = await _createVolunteerContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: VolunteerDashboardPage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.drag(
      find.byKey(const ValueKey('volunteer-demand-sheet-handle')),
      const Offset(0, 320),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('volunteer-demand-sheet-lower')), findsOneWidget);

    await tester.ensureVisible(find.byKey(const ValueKey('fallback-marker-mock-2')));
    await tester.tap(find.byKey(const ValueKey('fallback-marker-mock-2')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('volunteer-demand-sheet-middle')), findsOneWidget);
    expect(find.byKey(const ValueKey('run-card-mock-2')), findsOneWidget);
  });

  testWidgets('upper sheet keeps state while list scrolls and only collapses after returning to top', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final container = await _createVolunteerContainer();
    addTearDown(container.dispose);
    _seedExtraPendingRuns(container, 5);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: VolunteerDashboardPage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.drag(
      find.byKey(const ValueKey('volunteer-demand-sheet-handle')),
      const Offset(0, -520),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('volunteer-demand-sheet-upper')), findsOneWidget);

    final list = find.byKey(const ValueKey('volunteer-demand-sheet-list'));
    await tester.drag(list, const Offset(0, -320));
    await tester.pumpAndSettle();

    await tester.drag(list, const Offset(0, 160));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('volunteer-demand-sheet-upper')), findsOneWidget);

    await tester.drag(list, const Offset(0, 720));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('volunteer-demand-sheet-upper')), findsOneWidget);

    await tester.drag(
      find.byKey(const ValueKey('volunteer-demand-sheet-handle')),
      const Offset(0, 280),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('volunteer-demand-sheet-upper')), findsNothing);
  });

  testWidgets('volunteer demand actions preserve navigation to the run page', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final container = await _createVolunteerContainer();
    addTearDown(container.dispose);
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const VolunteerDashboardPage(),
        ),
        GoRoute(
          path: '/volunteer/run/:id',
          builder: (context, state) => Scaffold(
            body: Text('run-${state.pathParameters['id']}'),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('立即接单').first);
    await tester.pumpAndSettle();

    expect(find.text('run-mock-1'), findsOneWidget);
  });

  testWidgets('volunteer history tab renders status labels without runtime errors', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({
      'aidrun_role': UserRole.volunteer.name,
    });
    final preferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
        ],
        child: const MaterialApp(home: VolunteerDashboardPage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('历史'));
    await tester.pumpAndSettle();

    expect(find.text('上周六 07:00 · 已完成'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('volunteer profile tab renders initials without characters crash', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({
      'aidrun_role': UserRole.volunteer.name,
    });
    final preferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
        ],
        child: const MaterialApp(home: VolunteerDashboardPage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('我的'));
    await tester.pumpAndSettle();

    expect(find.text('爱'), findsWidgets);
    expect(find.text('爱心志愿者'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('volunteer store tab stays stable on narrow screens', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({
      'aidrun_role': UserRole.volunteer.name,
    });
    final preferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
        ],
        child: const MaterialApp(home: VolunteerDashboardPage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('商城'));
    await tester.pumpAndSettle();

    expect(find.text('速干排汗T恤'), findsOneWidget);
    expect(find.text('兑换'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  test('place search falls back to local demo data when web key is missing', () async {
    final service = AMapPlaceSearchService(
      const AMapConfig(
        androidKey: '',
        iosKey: '',
        webKey: '',
      ),
    );

    final results = await service.search('朝阳');

    expect(results, isNotEmpty);
    expect(
      results.any(
        (item) => item.name.contains('朝阳') || item.address.contains('朝阳'),
      ),
      isTrue,
    );
  });

  testWidgets('amap map view shows fallback when native key is missing', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AMapMapView(
            config: AMapConfig(
              androidKey: '',
              iosKey: '',
              webKey: '',
            ),
            centerLatitude: 39.9042,
            centerLongitude: 116.4074,
            markers: [],
            fallbackMessage: '测试占位提示',
          ),
        ),
      ),
    );

    expect(find.textContaining('测试占位提示'), findsOneWidget);
  });

  test('amap config load merges runtime configuration from native channel', () async {
    const channel = MethodChannel('aidrun/device');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'getAMapConfig') {
            return <String, String>{
              'androidKey': 'ANDROID123',
              'iosKey': 'IOS123',
              'webKey': 'WEB123',
            };
          }
          return null;
        });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    final config = await AMapConfig.load();

    expect(config.androidKey, 'ANDROID123');
    expect(config.iosKey, 'IOS123');
    expect(config.webKey, 'WEB123');
  });

  test('blind run stores selected place coordinates', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(preferences),
      ],
    );
    addTearDown(container.dispose);

    final run = container.read(appStateControllerProvider.notifier).createBlindRun(
          const RunRequestInput(
            place: PlaceSuggestion(
              name: '测试地点',
              address: '测试地址',
              latitude: 31.2304,
              longitude: 121.4737,
            ),
            timeLabel: '今天晚上',
          ),
        );

    expect(run.location, '测试地点');
    expect(run.address, '测试地址');
    expect(run.latitude, 31.2304);
    expect(run.longitude, 121.4737);
  });
}

Future<ProviderContainer> _createVolunteerContainer() async {
  SharedPreferences.setMockInitialValues({
    'aidrun_role': UserRole.volunteer.name,
  });
  final preferences = await SharedPreferences.getInstance();
  return ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(preferences),
    ],
  );
}

void _seedExtraPendingRuns(ProviderContainer container, int count) {
  final controller = container.read(appStateControllerProvider.notifier);

  for (var index = 0; index < count; index++) {
    controller.createBlindRun(
      RunRequestInput(
        place: PlaceSuggestion(
          name: '加测地点 ${index + 1}',
          address: '测试地址 ${index + 1}',
          latitude: 30.0 + index,
          longitude: 120.0 + index,
        ),
        timeLabel: '明天 ${8 + index}:00',
        notes: '用于滚动测试 ${index + 1}',
      ),
    );
  }
}
