import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/comment.dart';
import 'app_logger.dart';

class CommentsResult {
  final bool success;
  final String? message;
  final List<Comment> comments;

  const CommentsResult({required this.success, this.message, this.comments = const []});
}

class CommentService {
  static Map<String, String> _headers(String authToken) => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $authToken',
      };

  static Future<CommentsResult> fetchComments(int mediaId, String authToken) async {
    try {
      final uri = Uri.parse('https://nolla.net/api/v1/media/$mediaId/comments');
      AppLogger.log('[CommentService] GET $uri');
      final response = await http.get(uri, headers: _headers(authToken)).timeout(const Duration(seconds: 10));
      AppLogger.log('[CommentService] fetchComments status=${response.statusCode}');
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final List<dynamic> list;
        if (body is List) {
          list = body;
        } else if (body is Map<String, dynamic>) {
          final raw = body['comments'] ?? body['data'] ?? body['items'];
          list = raw is List ? raw : [];
        } else {
          return const CommentsResult(success: true);
        }
        final comments = <Comment>[];
        for (final e in list) {
          try {
            comments.add(Comment.fromJson(e as Map<String, dynamic>));
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

  static Future<Comment?> addComment(int mediaId, String body, String authToken) async {
    try {
      final uri = Uri.parse('https://nolla.net/api/v1/media/$mediaId/comments');
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
            final json = jsonDecode(response.body) as Map<String, dynamic>;
            final data = (json['comment'] ?? json['data'] ?? json) as Map<String, dynamic>;
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
