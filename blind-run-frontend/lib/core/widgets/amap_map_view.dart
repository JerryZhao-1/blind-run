import 'dart:io';

import 'package:aidrun_demo/core/services/amap_config.dart';
import 'package:aidrun_demo/core/services/native_runtime_service.dart';
import 'package:amap_flutter_base/amap_flutter_base.dart';
import 'package:amap_flutter_map/amap_flutter_map.dart';
import 'package:flutter/material.dart';

class AMapMarkerViewData {
  const AMapMarkerViewData({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.title,
    this.snippet,
    this.onTap,
  });

  final String id;
  final double latitude;
  final double longitude;
  final String title;
  final String? snippet;
  final VoidCallback? onTap;
}

class AMapMapView extends StatelessWidget {
  const AMapMapView({
    super.key,
    required this.config,
    required this.centerLatitude,
    required this.centerLongitude,
    required this.markers,
    this.zoom = 13,
    this.showMyLocation = false,
    this.onTap,
    this.fallbackMessage,
  });

  final AMapConfig config;
  final double centerLatitude;
  final double centerLongitude;
  final double zoom;
  final bool showMyLocation;
  final List<AMapMarkerViewData> markers;
  final ValueChanged<LatLng>? onTap;
  final String? fallbackMessage;

  @override
  Widget build(BuildContext context) {
    if (!config.supportsNativeMap) {
      return _MapFallback(
        message: _missingNativeMapMessage(),
        markers: markers,
      );
    }

    if (Platform.isAndroid) {
      return FutureBuilder<bool>(
        future: NativeRuntimeService.isAndroidEmulator(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return _MapFallback(
              message: fallbackMessage ?? '地图初始化中，请稍候。',
              markers: markers,
            );
          }
          if (snapshot.data == true) {
            return _MapFallback(
              message:
                  fallbackMessage ?? 'Android 模拟器上的高德原生地图不稳定，当前显示地图占位。请使用真机查看真实地图效果。',
              markers: markers,
            );
          }
          return _buildNativeMap();
        },
      );
    }

    return _buildNativeMap();
  }

  Widget _buildNativeMap() {
    final mappedMarkers = markers.map((item) {
      return Marker(
        position: LatLng(item.latitude, item.longitude),
        infoWindow: InfoWindow(
          title: item.title,
          snippet: item.snippet,
        ),
        onTap: (_) => item.onTap?.call(),
      );
    }).toSet();

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: AMapWidget(
        apiKey: config.apiKey,
        privacyStatement: AMapConfig.privacyStatement,
        initialCameraPosition: CameraPosition(
          target: LatLng(centerLatitude, centerLongitude),
          zoom: zoom,
        ),
        myLocationStyleOptions: showMyLocation
            ? MyLocationStyleOptions(
                true,
                circleFillColor: Colors.lightBlue.withAlpha(50),
                circleStrokeColor: Colors.lightBlue,
                circleStrokeWidth: 1,
              )
            : null,
        markers: mappedMarkers,
        onTap: onTap,
      ),
    );
  }

  String _missingNativeMapMessage() {
    final keySummary =
        'native keys: android=${config.hasAndroidKey ? "yes" : "no"}, ios=${config.hasIosKey ? "yes" : "no"}';
    if (fallbackMessage != null) {
      final diagnosis = switch (Platform.operatingSystem) {
        'android' when !config.hasAndroidKey => '缺少 Android 高德 Key',
        'ios' when !config.hasIosKey => '缺少 iOS 高德 Key',
        _ when !config.hasNativeKeys => '缺少高德原生 Key',
        _ => '当前环境不支持原生高德地图',
      };
      return '$fallbackMessage\n$diagnosis\n$keySummary';
    }

    if (Platform.isAndroid && !config.hasAndroidKey) {
      return '未配置 Android 高德 Key，当前显示地图占位状态。\n$keySummary';
    }
    if (Platform.isIOS && !config.hasIosKey) {
      return '未配置 iOS 高德 Key，当前显示地图占位状态。\n$keySummary';
    }
    return '当前环境不支持原生高德地图，当前显示地图占位状态。\n$keySummary';
  }
}

class _MapFallback extends StatelessWidget {
  const _MapFallback({
    required this.message,
    required this.markers,
  });

  final String message;
  final List<AMapMarkerViewData> markers;

  @override
  Widget build(BuildContext context) {
    final tappableMarkers = markers.where((marker) => marker.onTap != null).toList();

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4F7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFD0D5DD)),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF344054),
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (tappableMarkers.isNotEmpty) ...[
                const SizedBox(height: 16),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final marker in tappableMarkers)
                      OutlinedButton(
                        key: ValueKey('fallback-marker-${marker.id}'),
                        onPressed: marker.onTap,
                        child: Text(marker.title),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
