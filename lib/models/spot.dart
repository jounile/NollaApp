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
    double? lat = _toDouble(json['latitude'] ?? json['lat']);
    double? lon = _toDouble(json['longitude'] ?? json['lng'] ?? json['lon']);

    // Handle combined latlon / lat_lon field — string "lat,lon" or list [lat, lon]
    if (lat == null || lon == null) {
      final raw = json['latlon'] ?? json['lat_lon'];
      if (raw is String) {
        final parts = raw.split(',');
        if (parts.length == 2) {
          lat ??= double.tryParse(parts[0].trim());
          lon ??= double.tryParse(parts[1].trim());
        }
      } else if (raw is List && raw.length >= 2) {
        lat ??= _toDouble(raw[0]);
        lon ??= _toDouble(raw[1]);
      }
    }

    // Handle nested location object: {lat, lon} or {latitude, longitude}
    // Also handles GeoJSON Point {type, coordinates: [lon, lat]}
    if (lat == null || lon == null) {
      final loc = json['location'];
      if (loc is Map<String, dynamic>) {
        final coords = loc['coordinates'];
        if (coords is List && coords.length >= 2) {
          // GeoJSON: coordinates are [longitude, latitude]
          lon ??= _toDouble(coords[0]);
          lat ??= _toDouble(coords[1]);
        } else {
          lat ??= _toDouble(loc['lat'] ?? loc['latitude']);
          lon ??= _toDouble(loc['lon'] ?? loc['lng'] ?? loc['longitude']);
        }
      }
    }

    return Spot(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? 'Unknown',
      latitude: lat ?? 0.0,
      longitude: lon ?? 0.0,
      type: json['type'] as String? ?? 'place',
      // API returns distance_km in kilometres; convert to metres for display.
      distance: _distanceMeters(json),
    );
  }

  static double? _distanceMeters(Map<String, dynamic> json) {
    final km = _toDouble(json['distance_km']);
    if (km != null) return km * 1000;
    return _toDouble(json['distance']);
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}
