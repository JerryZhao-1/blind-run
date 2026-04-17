import 'dart:io';

import 'package:amap_flutter_base/amap_flutter_base.dart';
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

  final String androidKey;
  final String iosKey;
  final String webKey;

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
}
