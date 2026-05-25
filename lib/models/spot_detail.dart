class SpotDetail {
  final int id;
  final String name;
  final double latitude;
  final double longitude;
  final String type;
  final double? distance;
  final String? description;
  final String? address;
  final String? createdBy;
  final List<String> mediaUrls;
  final List<String> tags;

  const SpotDetail({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.type,
    this.distance,
    this.description,
    this.address,
    this.createdBy,
    this.mediaUrls = const [],
    this.tags = const [],
  });

  factory SpotDetail.fromJson(Map<String, dynamic> json) {
    double? lat = _toDouble(json['latitude'] ?? json['lat']);
    double? lon = _toDouble(json['longitude'] ?? json['lng'] ?? json['lon']);

    if (lat == null || lon == null) {
      final loc = json['location'];
      if (loc is Map<String, dynamic>) {
        final coords = loc['coordinates'];
        if (coords is List && coords.length >= 2) {
          lon ??= _toDouble(coords[0]);
          lat ??= _toDouble(coords[1]);
        } else {
          lat ??= _toDouble(loc['lat'] ?? loc['latitude']);
          lon ??= _toDouble(loc['lon'] ?? loc['lng'] ?? loc['longitude']);
        }
      }
    }

    final rawMedia = json['media'] ?? json['images'] ?? json['photos'] ?? [];
    final mediaUrls = <String>[];
    if (rawMedia is List) {
      for (final m in rawMedia) {
        if (m is String) {
          mediaUrls.add(m);
        } else if (m is Map<String, dynamic>) {
          final url = m['url'] ?? m['src'] ?? m['image_url'];
          if (url is String) mediaUrls.add(url);
        }
      }
    }

    final rawTags = json['tags'] ?? [];
    final tags = <String>[];
    if (rawTags is List) {
      for (final t in rawTags) {
        if (t is String) tags.add(t);
      }
    }

    return SpotDetail(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? 'Unknown',
      latitude: lat ?? 0.0,
      longitude: lon ?? 0.0,
      type: json['type'] as String? ?? 'place',
      distance: _toDouble(json['distance']),
      description: json['description'] as String?,
      address: json['address'] as String?,
      createdBy: json['created_by'] as String? ?? json['createdBy'] as String? ?? json['author'] as String?,
      mediaUrls: mediaUrls,
      tags: tags,
    );
  }

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }
}
