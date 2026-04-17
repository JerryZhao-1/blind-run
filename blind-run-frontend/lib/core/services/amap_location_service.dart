import 'dart:async';
import 'dart:io';

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

abstract class AppLocationService {
  Future<DeviceLocation?> locateOnce();
}

class AMapLocationService implements AppLocationService {
  AMapLocationService(this._config);

  final AMapConfig _config;

  @override
  Future<DeviceLocation?> locateOnce() async {
    if (!_config.supportsNativeMap) {
      return null;
    }
    if (Platform.isAndroid && await NativeRuntimeService.isAndroidEmulator()) {
      return null;
    }

    final status = await Permission.location.request();
    if (!status.isGranted) {
      return null;
    }

    final plugin = AMapFlutterLocation();
    final completer = Completer<DeviceLocation?>();
    StreamSubscription<Map<String, Object>>? subscription;

    try {
      AMapFlutterLocation.updatePrivacyShow(true, true);
      AMapFlutterLocation.updatePrivacyAgree(true);
      AMapFlutterLocation.setApiKey(_config.androidKey, _config.iosKey);

      final option = AMapLocationOption()
        ..onceLocation = true
        ..needAddress = true
        ..locationMode = AMapLocationMode.Hight_Accuracy
        ..geoLanguage = GeoLanguage.DEFAULT;
      plugin.setLocationOption(option);

      subscription = plugin.onLocationChanged().listen((result) {
        final latitude = result['latitude'];
        final longitude = result['longitude'];
        if (latitude is double && longitude is double && !completer.isCompleted) {
          completer.complete(
            DeviceLocation(latitude: latitude, longitude: longitude),
          );
        }
      });

      plugin.startLocation();
      return await completer.future.timeout(
        const Duration(seconds: 8),
        onTimeout: () => null,
      );
    } catch (_) {
      return null;
    } finally {
      await subscription?.cancel();
      plugin.stopLocation();
      plugin.destroy();
    }
  }
}
