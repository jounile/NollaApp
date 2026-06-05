class NewSpot {
  final String name;
  final int typeId;
  final double latitude;
  final double longitude;
  final String? description;
  final String? address;
  final int countryId;
  final int townId;

  const NewSpot({
    required this.name,
    required this.typeId,
    required this.latitude,
    required this.longitude,
    this.description,
    this.address,
    this.countryId = 1,  // Default to Finland
    this.townId = 1,     // Default to Helsinki (first town in DB)
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'type_id': typeId,
        'country_id': countryId,
        'town_id': townId,
        'latlon': '$latitude,$longitude',
        if (description != null && description!.isNotEmpty) 'description': description,
        if (address != null && address!.isNotEmpty) 'address': address,
      };
}
