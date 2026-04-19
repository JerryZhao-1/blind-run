import 'package:aidrun_demo/app/providers.dart';
import 'package:aidrun_demo/core/models/place_suggestion.dart';
import 'package:aidrun_demo/core/models/run_request_input.dart';
import 'package:aidrun_demo/core/services/speech_recognition_service.dart';
import 'package:aidrun_demo/core/theme/app_theme.dart';
import 'package:aidrun_demo/core/widgets/blind_page_scaffold.dart';
import 'package:aidrun_demo/core/widgets/common_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class RequestRunPage extends ConsumerStatefulWidget {
  const RequestRunPage({super.key});

  @override
  ConsumerState<RequestRunPage> createState() => _RequestRunPageState();
}

class _RequestRunPageState extends ConsumerState<RequestRunPage> {
  PlaceSuggestion? _selectedPlace;
  String _timeLabel = '现在出发';
  bool _submitting = false;
  VoiceCaptureState _timeVoiceState = VoiceCaptureState.idle;
  String _timeVoiceMessage = '你可以语音输入出发时间，也可以直接选择下方预设时间。';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(blindAccessibilityServiceProvider)
          .announcePage('预约页面。先选择地点，再设置出发时间，最后确认预约。');
    });
  }

  Future<void> _selectPlace() async {
    final place = await context.push<PlaceSuggestion>('/blind/request/place');
    if (!mounted || place == null) {
      return;
    }
    setState(() => _selectedPlace = place);
    await ref
        .read(blindAccessibilityServiceProvider)
        .announceStatusChange('已选择地点${place.name}。接下来请选择或语音输入出发时间。');
  }

  Future<void> _listenForTime() async {
    if (_timeVoiceState == VoiceCaptureState.listening ||
        _timeVoiceState == VoiceCaptureState.processing) {
      return;
    }
    final speechRecognition = ref.read(speechRecognitionServiceProvider);
    await ref
        .read(blindAccessibilityServiceProvider)
        .announcePage('请说出出发时间，例如三十分钟后或明天上午。');
    final result = await speechRecognition.listenForTranscript(
      listenFor: const Duration(seconds: 5),
      onStateChanged: (state) {
        if (!mounted) {
          return;
        }
        setState(() {
          _timeVoiceState = state;
          _timeVoiceMessage = _voiceMessageForState(
            state,
            unavailableMessage: '当前设备语音输入不可用，请直接选择下方时间选项。',
            errorMessage: '没有识别到清晰时间，请直接点选下方时间选项重试。',
          );
        });
      },
    );
    if (!mounted) {
      return;
    }

    if (result.state == VoiceCaptureState.success && result.hasTranscript) {
      setState(() {
        _timeLabel = speechRecognition.parseTimeLabel(result.transcript);
        _timeVoiceMessage = '已识别出发时间$_timeLabel。你也可以继续切换下方时间选项。';
      });
      await ref
          .read(blindAccessibilityServiceProvider)
          .announceStatusChange('已设置出发时间$_timeLabel。');
      return;
    }

    await ref
        .read(blindAccessibilityServiceProvider)
        .announceError(_timeVoiceMessage);
  }

  Future<void> _submit() async {
    final place = _selectedPlace;
    if (place == null || _submitting) {
      return;
    }
    setState(() => _submitting = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final run = await ref
          .read(appStateControllerProvider.notifier)
          .createBlindRun(RunRequestInput(place: place, timeLabel: _timeLabel));
      await ref
          .read(blindAccessibilityServiceProvider)
          .announceStatusChange('预约成功，正在为您匹配志愿者。');
      if (!mounted) {
        return;
      }
      context.go('/blind/run/${run.id}');
    } catch (_) {
      if (!mounted) {
        return;
      }
      final message =
          ref.read(appStateControllerProvider).errorMessage ?? '提交失败，请稍后重试';
      await ref.read(blindAccessibilityServiceProvider).announceError(message);
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  static String _voiceMessageForState(
    VoiceCaptureState state, {
    required String unavailableMessage,
    required String errorMessage,
  }) {
    return switch (state) {
      VoiceCaptureState.idle => '你可以语音输入，也可以使用手动选项继续。',
      VoiceCaptureState.listening => '正在收听你的出发时间，请直接说出时间。',
      VoiceCaptureState.processing => '正在处理语音内容，请稍候。',
      VoiceCaptureState.success => '语音识别成功。',
      VoiceCaptureState.error => errorMessage,
      VoiceCaptureState.unavailable => unavailableMessage,
    };
  }

  @override
  Widget build(BuildContext context) {
    return BlindPageScaffold(
      aiButtonKey: const Key('blind-ai-assistant-button'),
      header: Row(
        children: [
          BlindAccessibleButton(
            onPressed: () => context.go('/blind'),
            enabled: true,
            label: '返回盲人主页',
            hint: '返回首页，不保存当前预约内容',
            child: FilledButton.icon(
              onPressed: () {},
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.zinc,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              icon: const Icon(Icons.arrow_back),
              label: const Text(
                '返回首页',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Semantics(
              header: true,
              child: const Text(
                '填写预约',
                style: TextStyle(
                  color: AppTheme.yellow,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        children: [
          LargeActionButton(
            onPressed: _selectPlace,
            backgroundColor: AppTheme.yellow,
            foregroundColor: Colors.black,
            icon: const Icon(Icons.place, size: 120),
            title: _selectedPlace == null ? '先选择地点' : '重新选择地点',
            subtitle: _selectedPlace?.summary ?? '支持语音搜索和文字搜索',
            semanticsLabel: _selectedPlace == null
                ? '选择跑步地点'
                : '重新选择跑步地点，当前已选${_selectedPlace!.name}',
            semanticsHint: '打开地点搜索页面，支持文字和语音搜索地点',
          ),
          const SizedBox(height: 16),
          SectionCard(
            color: AppTheme.zinc,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: const Text(
                    '出发时间',
                    style: TextStyle(
                      color: AppTheme.yellow,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Semantics(
                  label: '当前出发时间$_timeLabel',
                  child: Text(
                    _timeLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Semantics(
                  container: true,
                  liveRegion: true,
                  focusable: false,
                  label: _timeVoiceMessage,
                  child: ExcludeSemantics(
                    child: Text(
                      _timeVoiceMessage,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                BlindAccessibleButton(
                  key: const Key('blind-request-time-voice-button'),
                  onPressed: _listenForTime,
                  enabled: true,
                  label: '语音输入出发时间',
                  hint: '开始录入出发时间；如果失败，可继续使用下方时间选项',
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {},
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.emerald,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                      ),
                      icon: Icon(
                        _timeVoiceState == VoiceCaptureState.listening
                            ? Icons.graphic_eq
                            : Icons.mic,
                      ),
                      label: Text(
                        switch (_timeVoiceState) {
                          VoiceCaptureState.listening => '正在收听时间...',
                          VoiceCaptureState.processing => '正在处理语音...',
                          _ => '语音输入时间',
                        },
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final option in const [
                      '现在出发',
                      '30分钟后',
                      '明天上午',
                      '今天晚上',
                    ])
                      Semantics(
                        button: true,
                        selected: _timeLabel == option,
                        label: '选择时间$option',
                        hint: '将出发时间设置为$option',
                        child: ChoiceChip(
                          label: Text(option),
                          selected: _timeLabel == option,
                          onSelected: (_) =>
                              setState(() => _timeLabel = option),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          BlindAccessibleButton(
            onPressed: _selectedPlace != null && !_submitting ? _submit : null,
            enabled: _selectedPlace != null && !_submitting,
            label: _selectedPlace == null ? '确认预约，不可用，请先选择地点' : '确认预约',
            hint: _selectedPlace == null ? '先完成地点选择，再确认预约' : '提交当前地点和时间，创建陪跑预约',
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {},
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  disabledBackgroundColor: Colors.white24,
                  disabledForegroundColor: Colors.white54,
                  padding: const EdgeInsets.symmetric(vertical: 22),
                ),
                child: Text(
                  _selectedPlace == null
                      ? '请先选择地点'
                      : (_submitting ? '正在提交...' : '确认预约'),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
