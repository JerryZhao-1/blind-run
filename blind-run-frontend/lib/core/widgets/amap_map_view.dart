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
  });

  final String id;
  final double latitude;
  final double longitude;
  final String title;
  final String? snippet;
}

class AMapMapView extends StatefulWidget {
  const AMapMapView({
    super.key,
    required this.config,
    required this.centerLatitude,
    required this.centerLongitude,
    required this.markers,
    this.zoom = 13,
    this.showMyLocation = false,
    this.cameraMoveRequestKey,
    this.cameraMoveLatitude,
    this.cameraMoveLongitude,
    this.cameraMoveZoom,
    this.onTap,
    this.fallbackMessage,
  });

  final AMapConfig config;
  final double centerLatitude;
  final double centerLongitude;
  final double zoom;
  final bool showMyLocation;
  final List<AMapMarkerViewData> markers;
  final int? cameraMoveRequestKey;
  final double? cameraMoveLatitude;
  final double? cameraMoveLongitude;
  final double? cameraMoveZoom;
  final ValueChanged<LatLng>? onTap;
  final String? fallbackMessage;

  @override
  State<AMapMapView> createState() => _AMapMapViewState();
}

class _AMapMapViewState extends State<AMapMapView> {
  AMapController? _controller;
  int? _lastAppliedCameraMoveRequestKey;

  @override
  void didUpdateWidget(covariant AMapMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _moveCameraIfNeeded();
  }

  @override
  Widget build(BuildContext context) {
    final config = widget.config;
    if (!config.supportsNativeMap) {
      return _MapFallback(
        message: widget.fallbackMessage ?? '未配置高德地图 Key，当前显示地图占位状态。',
      );
    }

    if (Platform.isAndroid) {
      return FutureBuilder<bool>(
        future: NativeRuntimeService.isAndroidEmulator(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return _MapFallback(
              message: widget.fallbackMessage ?? '地图初始化中，请稍候。',
            );
          }
          if (snapshot.data == true) {
            return _MapFallback(
              message:
                  widget.fallbackMessage ??
                  'Android 模拟器上的高德原生地图不稳定，当前显示地图占位。请使用真机查看真实地图效果。',
            );
          }
          return _buildNativeMap();
        },
      );
    }

    return _buildNativeMap();
  }

  Widget _buildNativeMap() {
    final mappedMarkers = widget.markers.map((item) {
      return Marker(
        position: LatLng(item.latitude, item.longitude),
        infoWindow: InfoWindow(title: item.title, snippet: item.snippet),
      );
    }).toSet();

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: AMapWidget(
        apiKey: widget.config.apiKey,
        privacyStatement: AMapConfig.privacyStatement,
        onMapCreated: (controller) {
          _controller = controller;
          _moveCameraIfNeeded();
        },
        initialCameraPosition: CameraPosition(
          target: LatLng(widget.centerLatitude, widget.centerLongitude),
          zoom: widget.zoom,
        ),
        myLocationStyleOptions: widget.showMyLocation
            ? MyLocationStyleOptions(
                true,
                circleFillColor: Colors.lightBlue.withAlpha(50),
                circleStrokeColor: Colors.lightBlue,
                circleStrokeWidth: 1,
              )
            : null,
        markers: mappedMarkers,
        onTap: widget.onTap,
      ),
    );
  }

  void _moveCameraIfNeeded() {
    final controller = _controller;
    final requestKey = widget.cameraMoveRequestKey;
    final latitude = widget.cameraMoveLatitude;
    final longitude = widget.cameraMoveLongitude;
    if (controller == null ||
        requestKey == null ||
        requestKey == _lastAppliedCameraMoveRequestKey ||
        latitude == null ||
        longitude == null) {
      return;
    }
    _lastAppliedCameraMoveRequestKey = requestKey;
    controller.moveCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(latitude, longitude),
        widget.cameraMoveZoom ?? widget.zoom,
      ),
    );
  }
}

class _MapFallback extends StatelessWidget {
  const _MapFallback({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4F7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFD0D5DD)),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF344054),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
