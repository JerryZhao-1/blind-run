import 'dart:convert';

import 'package:aidrun_demo/core/models/place_suggestion.dart';
import 'package:aidrun_demo/core/services/amap_config.dart';
import 'package:aidrun_demo/core/services/amap_location_service.dart';
import 'package:http/http.dart' as http;

abstract class PlaceSearchService {
  Future<List<PlaceSuggestion>> search(
    String keyword, {
    DeviceLocation? near,
  });
}

class AMapPlaceSearchService implements PlaceSearchService {
  AMapPlaceSearchService(this._config);

  final AMapConfig _config;

  static const List<PlaceSuggestion> _fallbackPlaces = [
    PlaceSuggestion(
      name: '奥林匹克森林公园南园',
      address: '北京市朝阳区科荟路33号',
      latitude: 40.0150,
      longitude: 116.3900,
    ),
    PlaceSuggestion(
      name: '朝阳公园东门',
      address: '北京市朝阳区朝阳公园路1号',
      latitude: 39.9435,
      longitude: 116.4830,
    ),
    PlaceSuggestion(
      name: '天坛公园北门',
      address: '北京市东城区天坛东里甲1号',
      latitude: 39.8837,
      longitude: 116.4128,
    ),
    PlaceSuggestion(
      name: '小区跑道',
      address: '社区内部健身步道',
      latitude: 39.9100,
      longitude: 116.4100,
    ),
  ];

  @override
  Future<List<PlaceSuggestion>> search(
    String keyword, {
    DeviceLocation? near,
  }) async {
    final trimmed = keyword.trim();
    if (trimmed.isEmpty) {
      return const [];
    }

    if (!_config.hasWebKey) {
      return _searchFallback(trimmed);
    }

    try {
      final queryParameters = <String, String>{
        'key': _config.webKey,
        'keywords': trimmed,
        'datatype': 'poi',
        'city': '北京',
        'citylimit': 'false',
      };
      if (near != null) {
        queryParameters['location'] = '${near.longitude},${near.latitude}';
      }

      final uri = Uri.https(
        'restapi.amap.com',
        '/v3/assistant/inputtips',
        queryParameters,
      );
      final response = await http.get(uri);
      if (response.statusCode != 200) {
        return _searchFallback(trimmed);
      }

      final data = jsonDecode(response.body);
      if (data is! Map<String, dynamic>) {
        return _searchFallback(trimmed);
      }
      final tips = data['tips'];
      if (tips is! List) {
        return _searchFallback(trimmed);
      }

      final results = <PlaceSuggestion>[];
      for (final item in tips) {
        if (item is! Map<String, dynamic>) {
          continue;
        }
        final name = (item['name'] as String?)?.trim() ?? '';
        final address = (item['district'] as String? ?? '') +
            ((item['address'] as String?)?.trim() ?? '');
        final location = (item['location'] as String?)?.trim() ?? '';
        if (name.isEmpty || location.isEmpty || !location.contains(',')) {
          continue;
        }
        final parts = location.split(',');
        if (parts.length != 2) {
          continue;
        }
        final longitude = double.tryParse(parts[0]);
        final latitude = double.tryParse(parts[1]);
        if (latitude == null || longitude == null) {
          continue;
        }
        results.add(
          PlaceSuggestion(
            name: name,
            address: address,
            latitude: latitude,
            longitude: longitude,
          ),
        );
      }

      if (results.isEmpty) {
        return _searchFallback(trimmed);
      }
      return results;
    } catch (_) {
      return _searchFallback(trimmed);
    }
  }

  List<PlaceSuggestion> _searchFallback(String keyword) {
    final lowered = keyword.toLowerCase();
    final filtered = _fallbackPlaces.where((place) {
      return place.name.toLowerCase().contains(lowered) ||
          place.address.toLowerCase().contains(lowered);
    }).toList();
    return filtered.isEmpty ? _fallbackPlaces : filtered;
  }
}
