class PlaceSuggestion {
  const PlaceSuggestion({
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  final String name;
  final String address;
  final double latitude;
  final double longitude;

  String get summary => address.isEmpty ? name : '$name · $address';
}
