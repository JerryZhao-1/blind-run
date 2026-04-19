import 'package:aidrun_demo/app/providers.dart';
import 'package:aidrun_demo/core/models/auth_session.dart';
import 'package:aidrun_demo/core/models/current_user.dart';
import 'package:aidrun_demo/core/models/emergency_contact.dart';
import 'package:aidrun_demo/core/models/run_status.dart';
import 'package:aidrun_demo/core/models/user_role.dart';
import 'package:aidrun_demo/core/services/place_search_service.dart';
import 'package:aidrun_demo/core/services/speech_recognition_service.dart';
import 'package:aidrun_demo/core/widgets/common_widgets.dart';
import 'package:aidrun_demo/features/blind/blind_active_run_page.dart';
import 'package:aidrun_demo/features/blind/blind_dashboard_page.dart';
import 'package:aidrun_demo/features/blind/place_search_page.dart';
import 'package:aidrun_demo/features/blind/request_run_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_doubles.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('blind dashboard exposes clear primary semantics and AI entry', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final preferences = await _mockPreferences();
    final speech = FakeSpeechService();

    try {
      await tester.pumpWidget(
        _buildBlindApp(
          preferences: preferences,
          speechService: speech,
          child: const MaterialApp(home: BlindDashboardPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('发起陪跑预约'), findsOneWidget);
      expect(find.bySemanticsLabel('AI语音助手'), findsOneWidget);
      expect(find.text('发起预约'), findsOneWidget);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets(
    'request page keeps manual fallback when voice input is unavailable',
    (tester) async {
      final preferences = await _mockPreferences();
      final speech = FakeSpeechService();
      final speechRecognition = FakeSpeechRecognitionService(
        result: const VoiceCaptureResult(state: VoiceCaptureState.unavailable),
      );

      await tester.pumpWidget(
        _buildBlindApp(
          preferences: preferences,
          speechService: speech,
          speechRecognitionService: speechRecognition,
          child: const MaterialApp(home: RequestRunPage()),
        ),
      );
      await tester.pumpAndSettle();

      final button = tester.widget<BlindAccessibleButton>(
        find.byKey(const Key('blind-request-time-voice-button')),
      );
      button.onPressed!.call();
      await tester.pumpAndSettle();

      expect(find.text('当前设备语音输入不可用，请直接选择下方时间选项。'), findsOneWidget);
      expect(speech.messages, contains('当前设备语音输入不可用，请直接选择下方时间选项。'));
      expect(find.text('现在出发'), findsWidgets);
      expect(find.text('30分钟后'), findsOneWidget);
    },
  );

  testWidgets(
    'place search renders backend-compatible place candidates with semantics',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final preferences = await _mockPreferences();

      try {
        await tester.pumpWidget(
          _buildBlindApp(
            preferences: preferences,
            placeSearchService: const FakePlaceSearchService(),
            child: const MaterialApp(home: BlindPlaceSearchPage()),
          ),
        );
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), '朝阳');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();

        expect(find.text('朝阳公园'), findsOneWidget);
        expect(
          find.bySemanticsLabel('地点候选，朝阳公园，地址北京市朝阳区朝阳公园南路1号，选择此地点'),
          findsOneWidget,
        );
      } finally {
        semantics.dispose();
      }
    },
  );

  testWidgets('blind active run reflects backend status and removes mock action buttons', (
    tester,
  ) async {
    final preferences = await _mockPreferences();
    final orderRepository = FakeOrderRepository(
      blindRuns: [
        buildRun(
          id: '301',
          location: '朝阳公园南门',
          status: RunStatus.driverEnRoute,
          volunteerPhone: '138****8000',
        ),
      ],
    );

    await tester.pumpWidget(
      _buildBlindApp(
        preferences: preferences,
        orderRepository: orderRepository,
        child: const MaterialApp(home: BlindActiveRunPage(runId: '301')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('志愿者正在赶来'), findsWidgets);
    expect(find.textContaining('[测试]'), findsNothing);
  });

  testWidgets('all blind core pages keep the fixed AI assistant button', (
    tester,
  ) async {
    final preferences = await _mockPreferences();

    Future<void> pumpPage(Widget page) async {
      await tester.pumpWidget(
        _buildBlindApp(
          preferences: preferences,
          placeSearchService: const FakePlaceSearchService(),
          child: MaterialApp(home: page),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('blind-ai-assistant-button')), findsOneWidget);
    }

    await pumpPage(const BlindDashboardPage());
    await pumpPage(const RequestRunPage());
    await pumpPage(const BlindPlaceSearchPage());
    await pumpPage(const BlindActiveRunPage(runId: 'mock-1'));
  });
}

Widget _buildBlindApp({
  required SharedPreferences preferences,
  FakeSpeechService? speechService,
  FakeSpeechRecognitionService? speechRecognitionService,
  PlaceSearchService? placeSearchService,
  FakeOrderRepository? orderRepository,
  required Widget child,
}) {
  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(preferences),
      authSessionStoreProvider.overrideWithValue(
        FakeAuthSessionStore(
          const AuthSession(token: 'token', userId: 1, role: UserRole.blind),
        ),
      ),
      authRepositoryProvider.overrideWithValue(
        FakeAuthRepository(
          currentUser: const CurrentUser(
            userId: 1,
            phoneMasked: '138****8000',
            role: UserRole.blind,
          ),
        ),
      ),
      if (speechService != null) speechServiceProvider.overrideWithValue(speechService),
      if (speechRecognitionService != null)
        speechRecognitionServiceProvider.overrideWithValue(speechRecognitionService),
      if (placeSearchService != null)
        placeSearchServiceProvider.overrideWithValue(placeSearchService),
      appLocationServiceProvider.overrideWithValue(const FakeLocationService()),
      orderRepositoryProvider.overrideWithValue(orderRepository ?? FakeOrderRepository(
        blindRuns: [
          buildRun(id: 'mock-1', location: '朝阳公园', status: RunStatus.pendingMatch),
        ],
      )),
      blindProfileRepositoryProvider.overrideWithValue(FakeBlindProfileRepository()),
      emergencyContactRepositoryProvider.overrideWithValue(
        FakeEmergencyContactRepository(
          [const EmergencyContact(id: 1, name: '张三', phone: '139****9000', relationship: '家人', isPrimary: true)],
        ),
      ),
    ],
    child: child,
  );
}

Future<SharedPreferences> _mockPreferences() async {
  SharedPreferences.setMockInitialValues({});
  return SharedPreferences.getInstance();
}
