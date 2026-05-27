class MediaItem {
  final int id;
  final String url;
  final String? thumbnailUrl;
  final String mediaType;
  final String uploaderUsername;
  final String uploaderDisplayName;
  final int? spotId;
  final String? spotName;
  final String? description;
  final int likeCount;
  final int commentCount;
  final bool isLikedByMe;
  final String? createdAt;

  const MediaItem({
    required this.id,
    required this.url,
    this.thumbnailUrl,
    required this.mediaType,
    required this.uploaderUsername,
    required this.uploaderDisplayName,
    this.spotId,
    this.spotName,
    this.description,
    this.likeCount = 0,
    this.commentCount = 0,
    this.isLikedByMe = false,
    this.createdAt,
  });

  MediaItem copyWith({bool? isLikedByMe, int? likeCount, int? commentCount}) => MediaItem(
        id: id,
        url: url,
        thumbnailUrl: thumbnailUrl,
        mediaType: mediaType,
        uploaderUsername: uploaderUsername,
        uploaderDisplayName: uploaderDisplayName,
        spotId: spotId,
        spotName: spotName,
        description: description,
        likeCount: likeCount ?? this.likeCount,
        commentCount: commentCount ?? this.commentCount,
        isLikedByMe: isLikedByMe ?? this.isLikedByMe,
        createdAt: createdAt,
      );

  factory MediaItem.fromJson(Map<String, dynamic> json) {
    final uploader = json['uploader'] ?? json['user'] ?? json['author'];
    String uploaderUsername = '';
    String uploaderDisplayName = '';
    if (uploader is Map<String, dynamic>) {
      uploaderUsername = uploader['username'] as String? ?? '';
      uploaderDisplayName = uploader['display_name'] as String? ??
          uploader['displayName'] as String? ??
          uploader['name'] as String? ??
          uploaderUsername;
    } else {
      // API uses 'owner' as a plain username string
      uploaderUsername = json['owner'] as String? ?? json['username'] as String? ?? json['uploader_username'] as String? ?? '';
      uploaderDisplayName = json['display_name'] as String? ?? json['uploader_name'] as String? ?? uploaderUsername;
    }

    final spot = json['spot'];
    int? spotId;
    String? spotName;
    if (spot is Map<String, dynamic>) {
      spotId = (spot['id'] as num?)?.toInt();
      spotName = spot['name'] as String?;
    } else {
      spotId = (json['spot_id'] as num?)?.toInt();
      spotName = json['spot_name'] as String?;
    }

    return MediaItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      url: json['url'] as String? ?? json['file_url'] as String? ?? '',
      thumbnailUrl: json['thumbnail_url'] as String? ?? json['thumbnail'] as String?,
      // API uses mediatype_id: 1=image/photo, 2=video
      mediaType: json['media_type'] as String? ?? json['type'] as String? ?? _mediaTypeFromId(json['mediatype_id']),
      uploaderUsername: uploaderUsername,
      uploaderDisplayName: uploaderDisplayName,
      spotId: spotId,
      spotName: spotName,
      description: json['description'] as String?,
      likeCount: (json['like_count'] as num?)?.toInt() ?? (json['likes'] as num?)?.toInt() ?? 0,
      commentCount: (json['comment_count'] as num?)?.toInt() ?? (json['comments'] as num?)?.toInt() ?? 0,
      isLikedByMe: json['is_liked_by_me'] as bool? ?? json['liked'] as bool? ?? false,
      createdAt: json['created_at'] as String? ?? json['createdAt'] as String?,
    );
  }

  static String _mediaTypeFromId(dynamic id) {
    if (id == null) return 'photo';
    final n = id is num ? id.toInt() : int.tryParse(id.toString());
    return n == 2 ? 'video' : 'photo';
  }
}
