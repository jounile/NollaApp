import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/media_item.dart';
import 'app_logger.dart';

class FeedResult {
  final bool success;
  final String? message;
  final List<MediaItem> items;
  final bool hasMore;

  const FeedResult({
    required this.success,
    this.message,
    this.items = const [],
    this.hasMore = false,
  });
}

class FeedService {
  static const String _mediaUrl = 'https://nolla.net/api/v1/media';

  static Map<String, String> _headers(String authToken) => {
        'Accept': 'application/json',
        'Authorization': 'Bearer $authToken',
      };

  static Future<FeedResult> fetchFeed(String authToken, {int page = 1, int limit = 20}) async {
    try {
      final uri = Uri.parse(_mediaUrl).replace(queryParameters: {
        'page': page.toString(),
        'limit': limit.toString(),
      });
      AppLogger.log('[FeedService] GET $uri');
      final response = await http.get(uri, headers: _headers(authToken)).timeout(const Duration(seconds: 10));
      AppLogger.log('[FeedService] status=${response.statusCode}');
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        List<dynamic> list;
        bool hasMore = false;
        if (body is List) {
          list = body;
        } else if (body is Map<String, dynamic>) {
          final raw = body['media'] ?? body['items'] ?? body['data'] ?? body['results'];
          list = raw is List ? raw : [];
          final total = (body['total'] as num?)?.toInt();
          if (total != null) hasMore = page * limit < total;
          hasMore = hasMore || (body['has_more'] as bool? ?? body['hasMore'] as bool? ?? false);
        } else {
          return const FeedResult(success: true);
        }
        final items = <MediaItem>[];
        for (final e in list) {
          try {
            items.add(MediaItem.fromJson(e as Map<String, dynamic>));
          } catch (err) {
            AppLogger.log('[FeedService] skipped item: $err');
          }
        }
        return FeedResult(success: true, items: items, hasMore: hasMore);
      }
      return FeedResult(success: false, message: 'Failed to load feed (${response.statusCode})');
    } catch (e) {
      AppLogger.log('[FeedService] exception: $e');
      return FeedResult(success: false, message: 'Network error');
    }
  }

  static Future<FeedResult> fetchSpotMedia(int spotId, String authToken) async {
    try {
      final uri = Uri.parse('https://nolla.net/api/v1/spots/$spotId/media');
      AppLogger.log('[FeedService] GET $uri');
      final response = await http.get(uri, headers: _headers(authToken)).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        List<dynamic> list;
        if (body is List) {
          list = body;
        } else if (body is Map<String, dynamic>) {
          final raw = body['media'] ?? body['items'] ?? body['data'];
          list = raw is List ? raw : [];
        } else {
          return const FeedResult(success: true);
        }
        final items = <MediaItem>[];
        for (final e in list) {
          try {
            items.add(MediaItem.fromJson(e as Map<String, dynamic>));
          } catch (_) {}
        }
        return FeedResult(success: true, items: items);
      }
      return FeedResult(success: false, message: 'Failed to load media (${response.statusCode})');
    } catch (e) {
      AppLogger.log('[FeedService] fetchSpotMedia exception: $e');
      return const FeedResult(success: false, message: 'Network error');
    }
  }
}
