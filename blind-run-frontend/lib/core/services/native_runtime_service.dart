import 'dart:io';

import 'package:flutter/services.dart';

class NativeRuntimeService {
  NativeRuntimeService._();

  static const MethodChannel _deviceChannel = MethodChannel('aidrun/device');
  static const String _androidKeyField = 'androidKey';
  static const String _iosKeyField = 'iosKey';
  static const String _webKeyField = 'webKey';

  static Future<Map<String, String>> readAMapConfig() async {
    if (!Platform.isAndroid &&
        !Platform.isIOS &&
        !Platform.environment.containsKey('FLUTTER_TEST')) {
      return const {};
    }

    try {
      final result = await _deviceChannel.invokeMapMethod<String, Object?>(
        'getAMapConfig',
      );
      if (result == null) {
        return const {};
      }

      return {
        _androidKeyField: (result[_androidKeyField] as String?) ?? '',
        _iosKeyField: (result[_iosKeyField] as String?) ?? '',
        _webKeyField: (result[_webKeyField] as String?) ?? '',
      };
    } catch (_) {
      return const {};
    }
  }

  static Future<bool> isAndroidEmulator() async {
    if (!Platform.isAndroid) {
      return false;
    }

    try {
      return await _deviceChannel.invokeMethod<bool>('isAndroidEmulator') ?? false;
    } catch (_) {
      return false;
    }
  }
}
