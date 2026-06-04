import '../utils/media_url.dart';

class Article {
  final int id;
  final String title;
  final String? imageUrl;
  final String? author;
  final String? excerpt;
  final String? publishedAt;
  final String? articleUrl;
  final int commentCount;

  const Article({
    required this.id,
    required this.title,
    this.imageUrl,
    this.author,
    this.excerpt,
    this.publishedAt,
    this.articleUrl,
    this.commentCount = 0,
  });

  factory Article.fromJson(Map<String, dynamic> json) {
    // Handle nested author object or flat string
    String? author;
    final rawAuthor = json['author'] ?? json['user'];
    if (rawAuthor is Map<String, dynamic>) {
      author = rawAuthor['display_name'] as String? ??
          rawAuthor['displayName'] as String? ??
          rawAuthor['name'] as String? ??
          rawAuthor['username'] as String?;
    } else {
      author = rawAuthor as String?;
    }

    // Image URL: try multiple common field names
    final rawImageUrl = json['image_url'] as String? ??
        json['imageUrl'] as String? ??
        json['cover_image'] as String? ??
        json['featured_image'] as String? ??
        json['thumbnail'] as String?;
    final imageUrl = resolveMediaUrl(rawImageUrl);

    return Article(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title'] as String? ?? '',
      imageUrl: imageUrl,
      author: author,
      excerpt: json['excerpt'] as String? ?? json['summary'] as String? ?? json['description'] as String?,
      publishedAt: json['published_at'] as String? ??
          json['publishedAt'] as String? ??
          json['created_at'] as String?,
      articleUrl: json['url'] as String? ?? json['link'] as String? ?? json['article_url'] as String?,
      commentCount: (json['comment_count'] as num?)?.toInt() ?? (json['comments'] as num?)?.toInt() ?? 0,
    );
  }
}
