class Spot {
  final int id;
  final String name;
  final double latitude;
  final double longitude;
  final String type;
  final double? distance;

  const Spot({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.type,
    this.distance,
  });

  factory Spot.fromJson(Map<String, dynamic> json) {
    return Spot(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? 'Unknown',
      latitude: _toDouble(json['latitude'] ?? json['lat']) ?? 0.0,
      longitude: _toDouble(json['longitude'] ?? json['lng']) ?? 0.0,
      type: json['type'] as String? ?? 'place',
      distance: _toDouble(json['distance']),
    );
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}
