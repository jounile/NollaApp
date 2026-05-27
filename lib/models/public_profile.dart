class PublicProfile {
  final String username;
  final String displayName;
  final String? bio;
  final String? avatarUrl;
  final int spotCount;
  final int mediaCount;
  final int followerCount;
  final int followingCount;
  final bool isFollowedByMe;

  const PublicProfile({
    required this.username,
    required this.displayName,
    this.bio,
    this.avatarUrl,
    this.spotCount = 0,
    this.mediaCount = 0,
    this.followerCount = 0,
    this.followingCount = 0,
    this.isFollowedByMe = false,
  });

  PublicProfile copyWith({bool? isFollowedByMe, int? followerCount}) => PublicProfile(
        username: username,
        displayName: displayName,
        bio: bio,
        avatarUrl: avatarUrl,
        spotCount: spotCount,
        mediaCount: mediaCount,
        followerCount: followerCount ?? this.followerCount,
        followingCount: followingCount,
        isFollowedByMe: isFollowedByMe ?? this.isFollowedByMe,
      );

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
      followerCount: (json['follower_count'] as num?)?.toInt() ??
          (json['followers_count'] as num?)?.toInt() ??
          (json['followers'] as num?)?.toInt() ??
          0,
      followingCount: (json['following_count'] as num?)?.toInt() ??
          (json['following'] as num?)?.toInt() ??
          0,
      isFollowedByMe: json['is_followed_by_me'] as bool? ?? json['is_following'] as bool? ?? false,
    );
  }
}
