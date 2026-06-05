class NewSpot {
  final String name;
  final int typeId;
  final double latitude;
  final double longitude;
  final String? description;
  final String? address;

  const NewSpot({
    required this.name,
    required this.typeId,
    required this.latitude,
    required this.longitude,
    this.description,
    this.address,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'type_id': typeId,
        'latlon': '$latitude,$longitude',
        if (description != null && description!.isNotEmpty) 'description': description,
        if (address != null && address!.isNotEmpty) 'address': address,
      };
}
