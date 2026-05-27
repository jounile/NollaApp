import 'dart:convert';
import 'package:http/http.dart' as http;
import 'app_logger.dart';

class LikeResult {
  final bool success;
  final String? message;
  final int? newCount;

  const LikeResult({required this.success, this.message, this.newCount});
}

class FollowResult {
  final bool success;
  final String? message;

  const FollowResult({required this.success, this.message});
}

class SocialService {
  static Map<String, String> _headers(String authToken) => {
        'Accept': 'application/json',
        'Authorization': 'Bearer $authToken',
      };

  static int? _parseCount(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      if (body is Map) {
        final raw = body['like_count'] ?? body['likes'] ?? body['count'];
        if (raw is int) return raw;
        if (raw is String) return int.tryParse(raw);
      }
    } catch (_) {}
    return null;
  }

  static Future<LikeResult> likeMedia(int mediaId, String authToken) async {
    try {
      final uri = Uri.parse('https://nolla.net/api/v1/media/$mediaId/like');
      AppLogger.log('[SocialService] POST $uri');
      final response = await http.post(uri, headers: _headers(authToken)).timeout(const Duration(seconds: 10));
      AppLogger.log('[SocialService] like status=${response.statusCode}');
      if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 204) {
        return LikeResult(success: true, newCount: _parseCount(response));
      }
      return LikeResult(success: false, message: 'Failed (${response.statusCode})');
    } catch (e) {
      AppLogger.log('[SocialService] likeMedia exception: $e');
      return const LikeResult(success: false, message: 'Network error');
    }
  }

  static Future<LikeResult> unlikeMedia(int mediaId, String authToken) async {
    try {
      final uri = Uri.parse('https://nolla.net/api/v1/media/$mediaId/like');
      AppLogger.log('[SocialService] DELETE $uri');
      final response = await http.delete(uri, headers: _headers(authToken)).timeout(const Duration(seconds: 10));
      AppLogger.log('[SocialService] unlike status=${response.statusCode}');
      if (response.statusCode == 200 || response.statusCode == 204) {
        return LikeResult(success: true, newCount: _parseCount(response));
      }
      return LikeResult(success: false, message: 'Failed (${response.statusCode})');
    } catch (e) {
      AppLogger.log('[SocialService] unlikeMedia exception: $e');
      return const LikeResult(success: false, message: 'Network error');
    }
  }

  static Future<FollowResult> followUser(String username, String authToken) async {
    try {
      final uri = Uri.parse('https://nolla.net/api/v1/users/$username/follow');
      AppLogger.log('[SocialService] POST $uri');
      final response = await http.post(uri, headers: _headers(authToken)).timeout(const Duration(seconds: 10));
      AppLogger.log('[SocialService] follow status=${response.statusCode}');
      if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 204) {
        return const FollowResult(success: true);
      }
      return FollowResult(success: false, message: 'Failed (${response.statusCode})');
    } catch (e) {
      AppLogger.log('[SocialService] followUser exception: $e');
      return const FollowResult(success: false, message: 'Network error');
    }
  }

  static Future<FollowResult> unfollowUser(String username, String authToken) async {
    try {
      final uri = Uri.parse('https://nolla.net/api/v1/users/$username/follow');
      AppLogger.log('[SocialService] DELETE $uri');
      final response = await http.delete(uri, headers: _headers(authToken)).timeout(const Duration(seconds: 10));
      AppLogger.log('[SocialService] unfollow status=${response.statusCode}');
      if (response.statusCode == 200 || response.statusCode == 204) {
        return const FollowResult(success: true);
      }
      return FollowResult(success: false, message: 'Failed (${response.statusCode})');
    } catch (e) {
      AppLogger.log('[SocialService] unfollowUser exception: $e');
      return const FollowResult(success: false, message: 'Network error');
    }
  }
}
