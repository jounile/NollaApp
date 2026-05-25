import 'package:http/http.dart' as http;
import 'app_logger.dart';

class LikeResult {
  final bool success;
  final String? message;
  final int? newCount;

  const LikeResult({required this.success, this.message, this.newCount});
}

class SocialService {
  static Map<String, String> _headers(String authToken) => {
        'Accept': 'application/json',
        'Authorization': 'Bearer $authToken',
      };

  static Future<LikeResult> likeMedia(int mediaId, String authToken) async {
    try {
      final uri = Uri.parse('https://nolla.net/api/v1/media/$mediaId/like');
      AppLogger.log('[SocialService] POST $uri');
      final response = await http.post(uri, headers: _headers(authToken)).timeout(const Duration(seconds: 10));
      AppLogger.log('[SocialService] like status=${response.statusCode}');
      if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 204) {
        return const LikeResult(success: true);
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
        return const LikeResult(success: true);
      }
      return LikeResult(success: false, message: 'Failed (${response.statusCode})');
    } catch (e) {
      AppLogger.log('[SocialService] unlikeMedia exception: $e');
      return const LikeResult(success: false, message: 'Network error');
    }
  }
}
