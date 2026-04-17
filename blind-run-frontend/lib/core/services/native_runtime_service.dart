import 'dart:io';

import 'package:flutter/services.dart';

class NativeRuntimeService {
  NativeRuntimeService._();

  static const MethodChannel _deviceChannel = MethodChannel('aidrun/device');

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
