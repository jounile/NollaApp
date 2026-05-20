class Spot {
  final int id;
  final String name;
  final double latitude;
  final double longitude;
  final String type;

  const Spot({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.type,
  });

  factory Spot.fromJson(Map<String, dynamic> json) => Spot(
        id: json['id'] as int,
        name: json['name'] as String,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        type: json['type'] as String? ?? 'place',
      );
}
