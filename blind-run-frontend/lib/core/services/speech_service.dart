import 'package:flutter_tts/flutter_tts.dart';

abstract class SpeechService {
  Future<void> speak(String text);
  Future<void> stop();
}

class DeviceSpeechService implements SpeechService {
  final FlutterTts _tts = FlutterTts();
  Future<void>? _setupFuture;

  Future<void> _ensureSetup() {
    return _setupFuture ??= () async {
      await _tts.setLanguage('zh-CN');
      await _tts.setSpeechRate(0.48);
      await _tts.setPitch(1.0);
      await _tts.awaitSpeakCompletion(true);
      await _tts.setQueueMode(1);
    }();
  }

  @override
  Future<void> speak(String text) async {
    try {
      await _ensureSetup();
      await _tts.stop();
      await _tts.speak(text);
    } catch (_) {}
  }

  @override
  Future<void> stop() async {
    try {
      await _ensureSetup();
      await _tts.stop();
    } catch (_) {}
  }
}
