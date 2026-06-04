import '../utils/media_url.dart';

class Profile {
  final String username;
  final String displayName;
  final String bio;
  final String email;
  final String website;
  final String? avatarUrl;
  final int followerCount;
  final int followingCount;
  final int spotCount;
  final int mediaCount;
  final String location;
  final String address;
  final String postnumber;
  final String telephone;
  final String hobbies;
  final String youtube;
  final int? bornyear;
  final int? gender;

  const Profile({
    required this.username,
    required this.displayName,
    required this.bio,
    required this.email,
    required this.website,
    this.avatarUrl,
    this.followerCount = 0,
    this.followingCount = 0,
    this.spotCount = 0,
    this.mediaCount = 0,
    this.location = '',
    this.address = '',
    this.postnumber = '',
    this.telephone = '',
    this.hobbies = '',
    this.youtube = '',
    this.bornyear,
    this.gender,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      username: (json['username'] ?? '').toString(),
      displayName: (json['name'] ?? json['display_name'] ?? json['displayName'] ?? '').toString(),
      bio: (json['info'] ?? json['bio'] ?? json['description'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      website: (json['homepage'] ?? json['website'] ?? json['url'] ?? '').toString(),
      avatarUrl: resolveMediaUrl(_nullableString(json['avatar'] ?? json['avatar_url'] ?? json['avatarUrl'])),
      followerCount: (json['follower_count'] as num?)?.toInt() ??
          (json['followers_count'] as num?)?.toInt() ??
          (json['followers'] as num?)?.toInt() ??
          0,
      followingCount: (json['following_count'] as num?)?.toInt() ??
          (json['following'] as num?)?.toInt() ??
          0,
      spotCount: (json['spot_count'] as num?)?.toInt() ??
          (json['spots_count'] as num?)?.toInt() ??
          0,
      mediaCount: (json['media_count'] as num?)?.toInt() ??
          (json['photos_count'] as num?)?.toInt() ??
          0,
      location: (json['location'] ?? '').toString(),
      address: (json['address'] ?? '').toString(),
      postnumber: (json['postnumber'] ?? '').toString(),
      telephone: (json['telephone'] ?? '').toString(),
      hobbies: (json['hobbies'] ?? '').toString(),
      youtube: (json['youtube'] ?? '').toString(),
      bornyear: (json['bornyear'] as num?)?.toInt(),
      gender: (json['gender'] as num?)?.toInt(),
    );
  }

  static String? _nullableString(dynamic v) {
    if (v == null) return null;
    final s = v.toString();
    return s.isEmpty ? null : s;
  }

  Map<String, dynamic> toJson() => {
    'name': displayName,
    'info': bio,
    'email': email,
    'homepage': website,
    'location': location,
    'address': address,
    'postnumber': postnumber,
    'telephone': telephone,
    'hobbies': hobbies,
    'youtube': youtube,
    if (bornyear != null) 'bornyear': bornyear,
    if (gender != null) 'gender': gender,
  };

  Profile copyWith({
    String? displayName,
    String? bio,
    String? email,
    String? website,
    String? avatarUrl,
    String? location,
    String? address,
    String? postnumber,
    String? telephone,
    String? hobbies,
    String? youtube,
    int? bornyear,
    int? gender,
  }) => Profile(
    username: username,
    displayName: displayName ?? this.displayName,
    bio: bio ?? this.bio,
    email: email ?? this.email,
    website: website ?? this.website,
    avatarUrl: avatarUrl ?? this.avatarUrl,
    followerCount: followerCount,
    followingCount: followingCount,
    spotCount: spotCount,
    mediaCount: mediaCount,
    location: location ?? this.location,
    address: address ?? this.address,
    postnumber: postnumber ?? this.postnumber,
    telephone: telephone ?? this.telephone,
    hobbies: hobbies ?? this.hobbies,
    youtube: youtube ?? this.youtube,
    bornyear: bornyear ?? this.bornyear,
    gender: gender ?? this.gender,
  );
}
