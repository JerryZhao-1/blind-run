import 'dart:async';

import 'package:aidrun_demo/core/services/speech_service.dart';

abstract class BlindAccessibilityService {
  Future<void> announcePage(String message);
  Future<void> announceStatusChange(String message);
  Future<void> announceError(String message);
  Future<void> announceAiAssistantPlaceholder();
}

class CoordinatedBlindAccessibilityService
    implements BlindAccessibilityService {
  CoordinatedBlindAccessibilityService(this._speechService);

  final SpeechService _speechService;
  Future<void> _queue = Future<void>.value();

  Future<void> _enqueue(String message) {
    _queue = _queue.then((_) => _speechService.speak(message));
    return _queue;
  }

  @override
  Future<void> announceAiAssistantPlaceholder() {
    return _enqueue('AI语音助手即将开放，当前请继续使用页面主操作。');
  }

  @override
  Future<void> announceError(String message) {
    return _enqueue(message);
  }

  @override
  Future<void> announcePage(String message) {
    return _enqueue(message);
  }

  @override
  Future<void> announceStatusChange(String message) {
    return _enqueue(message);
  }
}
