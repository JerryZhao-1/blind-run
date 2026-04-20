import 'package:aidrun_demo/app/aidrun_app.dart';
import 'package:aidrun_demo/app/providers.dart';
import 'package:aidrun_demo/core/services/amap_config.dart';
import 'package:aidrun_demo/core/models/run_status.dart';
import 'package:aidrun_demo/core/services/speech_recognition_service.dart';
import 'package:aidrun_demo/core/widgets/common_widgets.dart';
import 'package:aidrun_demo/demo/demo_showcase_seed.dart';
import 'package:aidrun_demo/demo/demo_runtime.dart';
import 'package:aidrun_demo/demo/demo_scenario_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_doubles.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('presentation mode boots directly into volunteer flow', (
    tester,
  ) async {
    final preferences = await _mockPreferences();

    await tester.pumpWidget(
      _buildDemoApp(
        preferences: preferences,
        scenario: DemoShowcaseScenario.volunteerJourney,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('发送验证码'), findsNothing);
    expect(find.text('附近需求 (1)'), findsOneWidget);
    expect(find.text('演示模式'), findsNothing);
  });

  testWidgets('volunteer capture scene boots directly into active checkpoint', (
    tester,
  ) async {
    final preferences = await _mockPreferences();

    await tester.pumpWidget(
      _buildDemoApp(
        preferences: preferences,
        scenario: DemoShowcaseScenario.volunteerJourney,
        captureScene: DemoVideoCaptureScene.volunteerEnRoute,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('前往集合地点'), findsOneWidget);
    expect(find.text('我已到达集合点'), findsOneWidget);
    expect(find.text('附近需求 (1)'), findsNothing);
  });

  testWidgets('blind capture scene boots directly into review checkpoint', (
    tester,
  ) async {
    final preferences = await _mockPreferences();

    await tester.pumpWidget(
      _buildDemoApp(
        preferences: preferences,
        scenario: DemoShowcaseScenario.blindJourney,
        captureScene: DemoVideoCaptureScene.blindReview,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('请评价本次志愿服务'), findsOneWidget);
    expect(find.text('非常满意'), findsOneWidget);
    expect(find.byKey(const Key('blind-dashboard-create-order-button')), findsNothing);
  });

  testWidgets('volunteer showcase can accept and complete a simulated run', (
    tester,
  ) async {
    final preferences = await _mockPreferences();

    await tester.pumpWidget(
      _buildDemoApp(
        preferences: preferences,
        scenario: DemoShowcaseScenario.volunteerJourney,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('附近需求 (1)'), findsOneWidget);
    expect(find.text('立即接单'), findsOneWidget);

    await tester.tap(find.text('立即接单'));
    await tester.pumpAndSettle();

    expect(find.text('我已出发'), findsOneWidget);

    await tester.tap(find.text('我已出发'));
    await tester.pumpAndSettle();
    expect(find.text('我已到达集合点'), findsOneWidget);

    await tester.tap(find.text('我已到达集合点'));
    await tester.pumpAndSettle();
    expect(find.text('结束行程'), findsOneWidget);

    await tester.tap(find.text('结束行程'));
    await tester.pumpAndSettle();
    expect(find.text('行程结算'), findsOneWidget);
  });

  testWidgets('blind showcase can create a simulated order and open it', (
    tester,
  ) async {
    final preferences = await _mockPreferences();

    await tester.pumpWidget(
      _buildDemoApp(
        preferences: preferences,
        scenario: DemoShowcaseScenario.blindJourney,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('blind-dashboard-create-order-button')), findsOneWidget);
    await tester.tap(find.byKey(const Key('blind-dashboard-create-order-button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('blind-request-place-button')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '观景台');
    await tester.tap(find.byKey(const Key('blind-place-search-submit-button')));
    await tester.pumpAndSettle();

    expect(find.text('小径湾沙滩观景台'), findsOneWidget);
    await _tapLargeActionButton(tester, '小径湾沙滩观景台');

    final submitButton = find.byKey(const Key('blind-request-submit-button'));
    await tester.scrollUntilVisible(
      submitButton,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    expect(find.text('查看当前订单'), findsOneWidget);
    await _tapLargeActionButton(tester, '查看当前订单');

    expect(find.text('当前订单'), findsOneWidget);
    expect(find.text('正在匹配志愿者'), findsWidgets);
  });

  test('paired capture scenes keep the same story anchors', () {
    final blindStore = DemoScenarioStore()
      ..activateCaptureScene(DemoVideoCaptureScene.blindActive);
    final volunteerStore = DemoScenarioStore()
      ..activateCaptureScene(DemoVideoCaptureScene.volunteerEnRoute);

    final blindRun = blindStore.blindRuns.single;
    final volunteerRun = volunteerStore.volunteerRuns.single;

    expect(blindRun.id, kDemoStoryOrderId);
    expect(volunteerRun.id, kDemoStoryOrderId);
    expect(blindRun.location, kDemoStoryPrimaryPlace.name);
    expect(volunteerRun.location, kDemoStoryPrimaryPlace.name);
    expect(blindRun.address, kDemoStoryPrimaryPlace.address);
    expect(volunteerRun.address, kDemoStoryPrimaryPlace.address);
    expect(blindRun.status, RunStatus.driverEnRoute);
    expect(volunteerRun.status, RunStatus.driverEnRoute);
    expect(blindRun.volunteerPhone, kDemoStoryVolunteerPhoneMasked);
    expect(volunteerRun.blindUserPhone, kDemoStoryBlindPhoneMasked);
  });
}

Widget _buildDemoApp({
  required SharedPreferences preferences,
  required DemoShowcaseScenario scenario,
  DemoVideoCaptureScene? captureScene,
}) {
  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(preferences),
      aMapConfigProvider.overrideWithValue(AMapConfig.empty),
      demoShowcaseScenarioProvider.overrideWithValue(scenario),
      if (captureScene != null)
        demoVideoCaptureSceneProvider.overrideWithValue(captureScene),
      ...buildDemoShowcaseOverrides(),
      speechServiceProvider.overrideWithValue(FakeSpeechService()),
      speechRecognitionServiceProvider.overrideWithValue(
        FakeSpeechRecognitionService(
          result: const VoiceCaptureResult(
            state: VoiceCaptureState.success,
            transcript: '30分钟后',
          ),
        ),
      ),
    ],
    child: const AidRunApp(),
  );
}

Future<SharedPreferences> _mockPreferences() async {
  SharedPreferences.setMockInitialValues({});
  return SharedPreferences.getInstance();
}

Future<void> _tapLargeActionButton(WidgetTester tester, String label) async {
  final button = find.ancestor(
    of: find.text(label),
    matching: find.byType(BlindAccessibleButton),
  );
  final actionSurface = find.descendant(
    of: button,
    matching: find.byType(FilledButton),
  );
  await tester.ensureVisible(actionSurface);
  final center = tester.getCenter(actionSurface);
  if (center.dy > 520) {
    final scrollable = find.ancestor(
      of: actionSurface,
      matching: find.byType(Scrollable),
    );
    if (scrollable.evaluate().isNotEmpty) {
      await tester.drag(scrollable.first, const Offset(0, -160));
      await tester.pumpAndSettle();
    }
  }
  await tester.tapAt(tester.getCenter(actionSurface));
  await tester.pumpAndSettle();
}
