import 'package:aidrun_demo/app/providers.dart';
import 'package:aidrun_demo/core/models/place_suggestion.dart';
import 'package:aidrun_demo/core/models/run_request_input.dart';
import 'package:aidrun_demo/core/models/run_status.dart';
import 'package:aidrun_demo/core/services/amap_location_service.dart';
import 'package:aidrun_demo/core/services/place_search_service.dart';
import 'package:aidrun_demo/core/services/speech_recognition_service.dart';
import 'package:aidrun_demo/core/services/speech_service.dart';
import 'package:aidrun_demo/features/blind/blind_active_run_page.dart';
import 'package:aidrun_demo/features/blind/blind_dashboard_page.dart';
import 'package:aidrun_demo/features/blind/place_search_page.dart';
import 'package:aidrun_demo/features/blind/request_run_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('blind dashboard exposes clear primary semantics and AI entry', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final preferences = await _mockPreferences();
    final speech = _FakeSpeechService();

    try {
      await tester.pumpWidget(
        _buildTestApp(
          preferences: preferences,
          speechService: speech,
          child: const MaterialApp(home: BlindDashboardPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('发起陪跑预约'), findsOneWidget);
      expect(find.bySemanticsLabel('AI语音助手'), findsOneWidget);
      expect(
        tester.getSemantics(find.bySemanticsLabel('发起陪跑预约')),
        matchesSemantics(
          label: '发起陪跑预约',
          hint: '打开预约页面，先选择地点，再设置出发时间',
          isButton: true,
          hasEnabledState: true,
          hasTapAction: true,
          isEnabled: true,
        ),
      );
      expect(
        tester.getSemantics(find.byKey(const Key('blind-ai-assistant-button'))),
        matchesSemantics(
          label: 'AI语音助手',
          hint: '当前未开放，点击后会提示稍后使用',
          isButton: true,
          hasEnabledState: true,
          hasTapAction: true,
          isEnabled: true,
        ),
      );

      await tester.tap(find.byKey(const Key('blind-ai-assistant-button')));
      await tester.pumpAndSettle();

      expect(speech.messages, contains('AI语音助手即将开放，当前请继续使用页面主操作。'));
    } finally {
      semantics.dispose();
    }
  });

  testWidgets(
    'request page keeps manual fallback when voice input is unavailable',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final preferences = await _mockPreferences();
      final speech = _FakeSpeechService();
      final speechRecognition = _FakeSpeechRecognitionService(
        result: const VoiceCaptureResult(state: VoiceCaptureState.unavailable),
      );

      await tester.pumpWidget(
        _buildTestApp(
          preferences: preferences,
          speechService: speech,
          speechRecognitionService: speechRecognition,
          child: const MaterialApp(home: RequestRunPage()),
        ),
      );
      await tester.pumpAndSettle();

      final voiceButton = find.byKey(
        const Key('blind-request-time-voice-button'),
      );
      await tester.ensureVisible(voiceButton);
      await tester.tap(voiceButton);
      await tester.pumpAndSettle();

      expect(find.text('当前设备语音输入不可用，请直接选择下方时间选项。'), findsOneWidget);
      expect(speech.messages, contains('当前设备语音输入不可用，请直接选择下方时间选项。'));
      expect(find.text('现在出发'), findsWidgets);
      expect(find.text('30分钟后'), findsOneWidget);
    },
  );

  testWidgets(
    'place search voice button stays tappable and results announce name plus address',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final semantics = tester.ensureSemantics();
      final preferences = await _mockPreferences();
      final speech = _FakeSpeechService();

      try {
        await tester.pumpWidget(
          _buildTestApp(
            preferences: preferences,
            speechService: speech,
            placeSearchService: _FakePlaceSearchService(),
            locationService: _FakeLocationService(),
            child: const MaterialApp(home: BlindPlaceSearchPage()),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          tester.getSemantics(
            find.byKey(const Key('blind-place-search-voice-button')),
          ),
          matchesSemantics(
            label: '语音搜索地点',
            hint: '开始语音录入地点名称；如果失败，可继续使用文字搜索',
            isButton: true,
            hasEnabledState: true,
            hasTapAction: true,
            isEnabled: true,
          ),
        );

        expect(find.byType(TextField), findsOneWidget);
        await tester.tap(find.byType(TextField));
        await tester.enterText(find.byType(TextField), '朝阳');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();

        expect(
          speech.messages,
          contains('已找到1个地点候选。第一条是朝阳公园，北京市朝阳区朝阳公园南路1号。请逐项选择。'),
        );
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

  testWidgets(
    'active run announces status changes without requiring visual tracking',
    (tester) async {
      final preferences = await _mockPreferences();
      final speech = _FakeSpeechService();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          speechServiceProvider.overrideWithValue(speech),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: BlindActiveRunPage(runId: 'mock-1')),
        ),
      );
      await tester.pumpAndSettle();

      container.read(appStateControllerProvider.notifier).acceptRun('mock-1');
      await tester.pumpAndSettle();
      container
          .read(appStateControllerProvider.notifier)
          .updateRunStatus('mock-1', RunStatus.arrived);
      await tester.pumpAndSettle();
      container
          .read(appStateControllerProvider.notifier)
          .updateRunStatus('mock-1', RunStatus.running);
      await tester.pumpAndSettle();
      container
          .read(appStateControllerProvider.notifier)
          .updateRunStatus('mock-1', RunStatus.completed);
      await tester.pumpAndSettle();

      expect(speech.messages, contains('当前状态：志愿者已接单，正在赶来。'));
      expect(speech.messages, contains('当前状态：志愿者已到达，请准备汇合。'));
      expect(speech.messages, contains('当前状态：已经开始跑步。'));
      expect(speech.messages, contains('当前状态：行程已结束，请评价本次志愿服务。'));
    },
  );

  testWidgets('all blind core pages keep the fixed AI assistant button', (
    tester,
  ) async {
    final preferences = await _mockPreferences();

    Future<void> pumpPage(Widget page) async {
      await tester.pumpWidget(
        _buildTestApp(
          preferences: preferences,
          placeSearchService: _FakePlaceSearchService(),
          locationService: _FakeLocationService(),
          child: MaterialApp(home: page),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('blind-ai-assistant-button')),
        findsOneWidget,
      );
    }

    await pumpPage(const BlindDashboardPage());
    await pumpPage(const RequestRunPage());
    await pumpPage(const BlindPlaceSearchPage());
    await pumpPage(const BlindActiveRunPage(runId: 'mock-1'));
  });
}

Widget _buildTestApp({
  required SharedPreferences preferences,
  SpeechService? speechService,
  SpeechRecognitionService? speechRecognitionService,
  PlaceSearchService? placeSearchService,
  AppLocationService? locationService,
  required Widget child,
}) {
  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(preferences),
      if (speechService != null)
        speechServiceProvider.overrideWithValue(speechService),
      if (speechRecognitionService != null)
        speechRecognitionServiceProvider.overrideWithValue(
          speechRecognitionService,
        ),
      if (placeSearchService != null)
        placeSearchServiceProvider.overrideWithValue(placeSearchService),
      if (locationService != null)
        appLocationServiceProvider.overrideWithValue(locationService),
    ],
    child: child,
  );
}

Future<SharedPreferences> _mockPreferences() async {
  SharedPreferences.setMockInitialValues({});
  return SharedPreferences.getInstance();
}

class _FakeSpeechService implements SpeechService {
  final List<String> messages = <String>[];

  @override
  Future<void> speak(String text) async {
    messages.add(text);
  }

  @override
  Future<void> stop() async {}
}

class _FakeSpeechRecognitionService implements SpeechRecognitionService {
  _FakeSpeechRecognitionService({required this.result});

  final VoiceCaptureResult result;

  @override
  Future<RunRequestInput> listenForRunRequest() async {
    return RunRequestInput(
      place: const PlaceSuggestion(
        name: '测试地点',
        address: '测试地址',
        latitude: 31.2304,
        longitude: 121.4737,
      ),
      timeLabel: parseTimeLabel(result.transcript),
    );
  }

  @override
  Future<VoiceCaptureResult> listenForTranscript({
    Duration listenFor = const Duration(seconds: 6),
    Duration pauseFor = const Duration(seconds: 2),
    void Function(VoiceCaptureState state)? onStateChanged,
  }) async {
    if (result.state == VoiceCaptureState.unavailable) {
      onStateChanged?.call(VoiceCaptureState.unavailable);
      return result;
    }
    onStateChanged?.call(VoiceCaptureState.listening);
    onStateChanged?.call(VoiceCaptureState.processing);
    onStateChanged?.call(result.state);
    return result;
  }

  @override
  String parseTimeLabel(String transcript) {
    return transcript.trim().isEmpty ? '现在出发' : transcript.trim();
  }
}

class _FakePlaceSearchService implements PlaceSearchService {
  @override
  Future<List<PlaceSuggestion>> search(
    String keyword, {
    DeviceLocation? near,
  }) async {
    return const [
      PlaceSuggestion(
        name: '朝阳公园',
        address: '北京市朝阳区朝阳公园南路1号',
        latitude: 39.9435,
        longitude: 116.4830,
      ),
    ];
  }
}

class _FakeLocationService implements AppLocationService {
  @override
  Future<DeviceLocation?> locateOnce() async {
    return const DeviceLocation(latitude: 39.9042, longitude: 116.4074);
  }
}
