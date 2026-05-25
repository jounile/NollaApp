class Profile {
  final String username;
  final String displayName;
  final String bio;
  final String email;
  final String website;
  final String? avatarUrl;

  const Profile({
    required this.username,
    required this.displayName,
    required this.bio,
    required this.email,
    required this.website,
    this.avatarUrl,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      username: (json['username'] ?? json['user'] ?? '').toString(),
      displayName: (json['display_name'] ?? json['displayName'] ?? json['name'] ?? json['full_name'] ?? '').toString(),
      bio: (json['bio'] ?? json['description'] ?? json['about'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      website: (json['website'] ?? json['url'] ?? json['web'] ?? '').toString(),
      avatarUrl: (json['avatar_url'] ?? json['avatarUrl'] ?? json['avatar'] ?? json['profile_picture']) as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'display_name': displayName,
    'bio': bio,
    'email': email,
    'website': website,
  };

  Profile copyWith({
    String? displayName,
    String? bio,
    String? email,
    String? website,
  }) => Profile(
    username: username,
    displayName: displayName ?? this.displayName,
    bio: bio ?? this.bio,
    email: email ?? this.email,
    website: website ?? this.website,
    avatarUrl: avatarUrl,
  );
}
