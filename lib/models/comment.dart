class Comment {
  final int id;
  final String authorUsername;
  final String authorDisplayName;
  final String body;
  final String? createdAt;

  const Comment({
    required this.id,
    required this.authorUsername,
    required this.authorDisplayName,
    required this.body,
    this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    final author = json['author'] ?? json['user'];
    String username = '';
    String displayName = '';
    if (author is Map<String, dynamic>) {
      username = author['username'] as String? ?? '';
      displayName = author['display_name'] as String? ??
          author['displayName'] as String? ??
          author['name'] as String? ??
          username;
    } else {
      username = json['username'] as String? ?? json['author_username'] as String? ?? '';
      displayName = json['display_name'] as String? ?? json['author_name'] as String? ?? username;
    }
    return Comment(
      id: (json['id'] as num?)?.toInt() ?? 0,
      authorUsername: username,
      authorDisplayName: displayName,
      body: json['body'] as String? ?? json['text'] as String? ?? json['content'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? json['createdAt'] as String?,
    );
  }
}
