class SpotType {
  final int id;
  final String name;

  const SpotType({required this.id, required this.name});

  factory SpotType.fromJson(Map<String, dynamic> json) {
    return SpotType(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? 'unknown',
    );
  }
}
