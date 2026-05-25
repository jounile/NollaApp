class NewSpot {
  final String name;
  final String type;
  final double latitude;
  final double longitude;
  final String? description;
  final String? address;

  const NewSpot({
    required this.name,
    required this.type,
    required this.latitude,
    required this.longitude,
    this.description,
    this.address,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'type': type,
        'latitude': latitude,
        'longitude': longitude,
        if (description != null && description!.isNotEmpty) 'description': description,
        if (address != null && address!.isNotEmpty) 'address': address,
      };
}
