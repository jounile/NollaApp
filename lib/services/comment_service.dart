import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/comment.dart';
import 'app_logger.dart';

enum CommentContentType { media, article }

class CommentsResult {
  final bool success;
  final String? message;
  final List<Comment> comments;

  const CommentsResult({required this.success, this.message, this.comments = const []});
}

class CommentService {
  static String _endpoint(int contentId, CommentContentType type) {
    final segment = type == CommentContentType.article ? 'articles' : 'media';
    return 'https://nolla.net/api/v1/$segment/$contentId/comments';
  }

  static Map<String, String> _headers(String authToken) => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $authToken',
      };

  static Future<CommentsResult> fetchComments(
    int contentId,
    String authToken, {
    CommentContentType type = CommentContentType.media,
  }) async {
    try {
      final uri = Uri.parse(_endpoint(contentId, type));
      AppLogger.log('[CommentService] GET $uri');
      final response = await http.get(uri, headers: _headers(authToken)).timeout(const Duration(seconds: 10));
      AppLogger.log('[CommentService] fetchComments status=${response.statusCode} body=${response.body}');
      if (response.statusCode == 200) {
        if (response.body.isEmpty) {
          return const CommentsResult(success: true);
        }
        final dynamic decoded;
        try {
          decoded = jsonDecode(response.body);
        } on FormatException {
          AppLogger.log('[CommentService] fetchComments parse error — body=${response.body}');
          return const CommentsResult(success: false, message: 'Server returned an invalid response');
        }
        final List<dynamic> list;
        if (decoded is List) {
          list = decoded;
        } else if (decoded is Map<String, dynamic>) {
          final raw = decoded['comments'] ?? decoded['data'] ?? decoded['items'];
          if (raw is List) {
            list = raw;
          } else {
            AppLogger.log('[CommentService] fetchComments: no known list key in response keys: ${decoded.keys}');
            list = [];
          }
        } else {
          return const CommentsResult(success: true);
        }
        final comments = <Comment>[];
        for (final e in list) {
          try {
            final comment = Comment.fromJson(e as Map<String, dynamic>);
            if (comment.published) comments.add(comment);
          } catch (_) {}
        }
        return CommentsResult(success: true, comments: comments);
      }
      return CommentsResult(
        success: false,
        message: 'Failed to load comments (${response.statusCode})',
      );
    } catch (e) {
      AppLogger.log('[CommentService] fetchComments exception: $e');
      return const CommentsResult(success: false, message: 'Network error');
    }
  }

  static Future<Comment?> addComment(
    int contentId,
    String body,
    String authToken, {
    CommentContentType type = CommentContentType.media,
  }) async {
    try {
      final uri = Uri.parse(_endpoint(contentId, type));
      AppLogger.log('[CommentService] POST $uri');
      final response = await http
          .post(
            uri,
            headers: _headers(authToken),
            body: jsonEncode({'body': body}),
          )
          .timeout(const Duration(seconds: 10));
      AppLogger.log('[CommentService] addComment status=${response.statusCode}');
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.body.isNotEmpty) {
          try {
            final decoded = jsonDecode(response.body);
            if (decoded is! Map<String, dynamic>) {
              AppLogger.log('[CommentService] addComment unexpected response type: ${decoded.runtimeType}');
              return null;
            }
            final data = (decoded['comment'] ?? decoded['data'] ?? decoded) as Map<String, dynamic>;
            return Comment.fromJson(data);
          } catch (_) {}
        }
        return null;
      }
      return null;
    } catch (e) {
      AppLogger.log('[CommentService] addComment exception: $e');
      return null;
    }
  }
}
