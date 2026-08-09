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

  // Hardcoded fallback — used if backend/server is unreachable so user
  // can still manually pick a store without waiting on the API.
  static List<Store> fallbackStores = [
    Store(
      id: 1,
      name: "V-Mart - Anandvalli",
      address:
          "Menlo Park, Engineer Prakash Chaudhary Marg, Kale Nagar, Balawant Nagar, Anandvalli, Nashik, Maharashtra 422013",
      latitude: 20.0121,
      longitude: 73.7458,
    ),
    Store(
      id: 2,
      name: "V-Mart - Pathardi Phata",
      address:
          "WQRJ+QPW, Pandav Nagari, Pathardi Phata, Nashik, Maharashtra 422009",
      latitude: 19.9420,
      longitude: 73.7818,
    ),
    Store(
      id: 3,
      name: "V-Mart - Trimurti Chowk, Cidco",
      address:
          "Datta Mandir Chowk, near Vishal Petrol Pump, Trimurti Chowk, Cidco, Patil Nagar, Nashik, Maharashtra 422009",
      latitude: 19.9792,
      longitude: 73.7571,
    ),
  ];
}
