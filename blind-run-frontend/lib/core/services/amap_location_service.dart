import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

import 'package:aidrun_demo/core/services/amap_config.dart';
import 'package:aidrun_demo/core/services/native_runtime_service.dart';
import 'package:amap_flutter_location/amap_flutter_location.dart';
import 'package:amap_flutter_location/amap_location_option.dart';
import 'package:permission_handler/permission_handler.dart';

class DeviceLocation {
  const DeviceLocation({
    required this.latitude,
    required this.longitude,
  });

  final double latitude;
  final double longitude;
}

enum DeviceLocationFailureReason {
  permissionDenied,
  unavailable,
}

class DeviceLocationLookup {
  const DeviceLocationLookup({
    this.location,
    this.failureReason,
    this.errorMessage,
    this.errorCode,
    this.rawResult,
  });

  final DeviceLocation? location;
  final DeviceLocationFailureReason? failureReason;
  final String? errorMessage;
  final String? errorCode;
  final Map<String, Object?>? rawResult;
}

abstract class AppLocationService {
  Future<DeviceLocationLookup> locate();

  Future<DeviceLocation?> locateOnce() async {
    return (await locate()).location;
  }
}

class AMapLocationService implements AppLocationService {
  AMapLocationService(this._config);

  final AMapConfig _config;

  @override
  Future<DeviceLocation?> locateOnce() async {
    return (await locate()).location;
  }

  @override
  Future<DeviceLocationLookup> locate() async {
    if (!_config.supportsNativeMap) {
      return const DeviceLocationLookup(
        failureReason: DeviceLocationFailureReason.unavailable,
      );
    }
    if (Platform.isAndroid && await NativeRuntimeService.isAndroidEmulator()) {
      return const DeviceLocationLookup(
        failureReason: DeviceLocationFailureReason.unavailable,
      );
    }

    var status = await Permission.locationWhenInUse.status;
    if (!status.isGranted) {
      status = await Permission.locationWhenInUse.request();
    }
    if (!status.isGranted) {
      return const DeviceLocationLookup(
        failureReason: DeviceLocationFailureReason.permissionDenied,
        errorCode: 'permission_handler_denied',
      );
    }

    final plugin = AMapFlutterLocation();
    final completer = Completer<DeviceLocationLookup>();
    StreamSubscription<Map<String, Object>>? subscription;

    try {
      AMapFlutterLocation.updatePrivacyShow(true, true);
      AMapFlutterLocation.updatePrivacyAgree(true);
      AMapFlutterLocation.setApiKey(_config.androidKey, _config.iosKey);

      final option = AMapLocationOption()
        ..onceLocation = true
        // Volunteer/order readiness only needs coordinates. Avoid coupling one-shot
        // location to reverse-geocode/network success on iOS.
        ..needAddress = false
        ..locationMode = AMapLocationMode.Hight_Accuracy
        ..desiredLocationAccuracyAuthorizationMode =
            AMapLocationAccuracyAuthorizationMode.FullAndReduceAccuracy
        ..geoLanguage = GeoLanguage.DEFAULT;
      plugin.setLocationOption(option);

      subscription = plugin.onLocationChanged().listen((result) {
        debugPrint('AMap locate result: $result');
        final latitude = _readCoordinate(result['latitude']);
        final longitude = _readCoordinate(result['longitude']);
        final errorCode = result['errorCode']?.toString();
        final rawResult = Map<String, Object?>.from(result);
        if (latitude != null &&
            longitude != null &&
            !completer.isCompleted) {
          completer.complete(
            DeviceLocationLookup(
              location: DeviceLocation(latitude: latitude, longitude: longitude),
              errorCode: errorCode,
              rawResult: rawResult,
            ),
          );
          return;
        }
        final errorInfo = result['errorInfo'];
        if (errorInfo is String &&
            errorInfo.trim().isNotEmpty &&
            !completer.isCompleted) {
          completer.complete(
            DeviceLocationLookup(
              failureReason: DeviceLocationFailureReason.unavailable,
              errorMessage: errorInfo,
              errorCode: errorCode,
              rawResult: rawResult,
            ),
          );
        }
      });

      plugin.startLocation();
      final timeout = Platform.isIOS
          // On iOS the one-shot callback can arrive noticeably later than the
          // actual location timestamp. Give the native SDK more headroom before
          // declaring the request timed out.
          ? const Duration(seconds: 15)
          : const Duration(seconds: 8);
      return await completer.future.timeout(
        timeout,
        onTimeout: () => const DeviceLocationLookup(
          failureReason: DeviceLocationFailureReason.unavailable,
          errorCode: 'timeout',
        ),
      );
    } catch (_) {
      return const DeviceLocationLookup(
        failureReason: DeviceLocationFailureReason.unavailable,
        errorCode: 'exception',
      );
    } finally {
      await subscription?.cancel();
      plugin.stopLocation();
      plugin.destroy();
    }
  }

  double? _readCoordinate(dynamic value) {
    if (value is double) {
      return value;
    }
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }
}
