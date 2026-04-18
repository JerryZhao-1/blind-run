import 'dart:io';

import 'package:amap_flutter_base/amap_flutter_base.dart';
import 'package:aidrun_demo/core/services/native_runtime_service.dart';
import 'package:flutter/foundation.dart';

class AMapConfig {
  const AMapConfig({
    required this.androidKey,
    required this.iosKey,
    required this.webKey,
  });

  factory AMapConfig.fromEnvironment() {
    return const AMapConfig(
      androidKey: String.fromEnvironment('AMAP_ANDROID_KEY'),
      iosKey: String.fromEnvironment('AMAP_IOS_KEY'),
      webKey: String.fromEnvironment('AMAP_WEB_KEY'),
    );
  }

  static const empty = AMapConfig(
    androidKey: '',
    iosKey: '',
    webKey: '',
  );

  static Future<AMapConfig> load() async {
    final compileTimeConfig = AMapConfig.fromEnvironment();
    final runtimeValues = await NativeRuntimeService.readAMapConfig();
    return compileTimeConfig.mergedWith(runtimeValues);
  }

  final String androidKey;
  final String iosKey;
  final String webKey;

  AMapConfig mergedWith(Map<String, String> runtimeValues) {
    return AMapConfig(
      androidKey: _firstNonEmpty(runtimeValues['androidKey'], androidKey),
      iosKey: _firstNonEmpty(runtimeValues['iosKey'], iosKey),
      webKey: _firstNonEmpty(runtimeValues['webKey'], webKey),
    );
  }

  bool get hasAndroidKey => androidKey.isNotEmpty;
  bool get hasIosKey => iosKey.isNotEmpty;
  bool get hasNativeKeys => hasAndroidKey || hasIosKey;
  bool get hasWebKey => webKey.isNotEmpty;

  bool get supportsNativeMap {
    if (kIsWeb) {
      return false;
    }
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      return false;
    }
    if (Platform.isAndroid) {
      return hasAndroidKey;
    }
    if (Platform.isIOS) {
      return hasIosKey;
    }
    return false;
  }

  AMapApiKey? get apiKey {
    if (!supportsNativeMap) {
      return null;
    }
    return AMapApiKey(
      androidKey: hasAndroidKey ? androidKey : null,
      iosKey: hasIosKey ? iosKey : null,
    );
  }

  static const privacyStatement = AMapPrivacyStatement(
    hasAgree: true,
    hasContains: true,
    hasShow: true,
  );

  static String _firstNonEmpty(String? preferred, String fallback) {
    if (preferred != null && preferred.isNotEmpty) {
      return preferred;
    }
    return fallback;
  }
}
