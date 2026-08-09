import 'dart:math';

class Store {
  final int id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;

  Store({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  factory Store.fromJson(Map<String, dynamic> json) {
    return Store(
      id: json['id'],
      name: json['name'],
      address: json['address'],
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }

  // Distance in km using Haversine formula (no external API, free)
  double distanceFrom(double lat, double lng) {
    const R = 6371.0; // Earth radius in km
    final dLat = _deg2rad(latitude - lat);
    final dLng = _deg2rad(longitude - lng);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(lat)) *
            cos(_deg2rad(latitude)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _deg2rad(double deg) => deg * (pi / 180);
}
