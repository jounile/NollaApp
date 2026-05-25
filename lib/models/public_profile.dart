class PublicProfile {
  final String username;
  final String displayName;
  final String? bio;
  final String? avatarUrl;
  final int spotCount;
  final int mediaCount;

  const PublicProfile({
    required this.username,
    required this.displayName,
    this.bio,
    this.avatarUrl,
    this.spotCount = 0,
    this.mediaCount = 0,
  });

  factory PublicProfile.fromJson(Map<String, dynamic> json) {
    return PublicProfile(
      username: json['username'] as String? ?? '',
      displayName: json['display_name'] as String? ??
          json['displayName'] as String? ??
          json['name'] as String? ??
          json['username'] as String? ??
          '',
      bio: json['bio'] as String?,
      avatarUrl: json['avatar_url'] as String? ?? json['avatarUrl'] as String?,
      spotCount: (json['spot_count'] as num?)?.toInt() ?? (json['spots_count'] as num?)?.toInt() ?? 0,
      mediaCount: (json['media_count'] as num?)?.toInt() ?? (json['photos_count'] as num?)?.toInt() ?? 0,
    );
  }
}
