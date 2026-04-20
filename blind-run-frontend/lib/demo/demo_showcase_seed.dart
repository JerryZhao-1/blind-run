import 'package:aidrun_demo/core/models/place_suggestion.dart';
import 'package:aidrun_demo/core/services/amap_location_service.dart';

const DeviceLocation kDemoShowcaseLocation = DeviceLocation(
  latitude: 23.0785,
  longitude: 114.4127,
);

const String kDemoStoryOrderId = '901';
const String kDemoStoryVolunteerName = '林泽';
const String kDemoStoryVolunteerPhoneMasked = '130****9977';
const String kDemoStoryBlindName = '李明';
const String kDemoStoryBlindPhoneMasked = '138****8000';
const String kDemoStoryMeetingNotes = '请在海湾一号西侧广场集合';
const double kDemoStoryDistanceKm = 5.2;
const int kDemoStoryDurationMinutes = 62;

const PlaceSuggestion kDemoVolunteerPickupPlace = PlaceSuggestion(
  name: '华润小径湾海湾一号',
  address: '广东省惠州市惠阳区大亚湾霞涌街道小径湾1号',
  latitude: 23.0785,
  longitude: 114.4127,
);

const List<PlaceSuggestion> kDemoShowcasePlaces = [
  kDemoVolunteerPickupPlace,
  PlaceSuggestion(
    name: '小径湾沙滩观景台',
    address: '广东省惠州市惠阳区大亚湾霞涌街道小径湾海岸线',
    latitude: 23.0818,
    longitude: 114.4186,
  ),
  PlaceSuggestion(
    name: '小径湾商业街入口',
    address: '广东省惠州市惠阳区大亚湾霞涌街道小径湾商业街',
    latitude: 23.0764,
    longitude: 114.4162,
  ),
  PlaceSuggestion(
    name: '霞涌黄金海岸栈道',
    address: '广东省惠州市惠阳区霞涌街道黄金海岸',
    latitude: 23.0608,
    longitude: 114.4921,
  ),
];

const PlaceSuggestion kDemoStoryPrimaryPlace = kDemoVolunteerPickupPlace;

List<PlaceSuggestion> filterDemoShowcasePlaces(
  String keyword, {
  DeviceLocation? near,
}) {
  final trimmed = keyword.trim().toLowerCase();
  final filtered = trimmed.isEmpty
      ? kDemoShowcasePlaces
      : kDemoShowcasePlaces.where((place) {
          return place.name.toLowerCase().contains(trimmed) ||
              place.address.toLowerCase().contains(trimmed);
        }).toList(growable: false);
  final ranked = (filtered.isEmpty ? kDemoShowcasePlaces : filtered).toList();
  if (near == null) {
    return ranked;
  }
  ranked.sort(
    (left, right) => _distanceScore(left, near).compareTo(
      _distanceScore(right, near),
    ),
  );
  return ranked;
}

double _distanceScore(PlaceSuggestion place, DeviceLocation near) {
  final deltaLat = place.latitude - near.latitude;
  final deltaLng = place.longitude - near.longitude;
  return (deltaLat * deltaLat) + (deltaLng * deltaLng);
}
