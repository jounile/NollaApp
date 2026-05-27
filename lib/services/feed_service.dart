import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/media_item.dart';
import '../utils/mock_data.dart';
import 'app_logger.dart';

class FeedResult {
  final bool success;
  final String? message;
  final List<MediaItem> items;
  final bool hasMore;
  final bool isMockData;

  const FeedResult({
    required this.success,
    this.message,
    this.items = const [],
    this.hasMore = false,
    this.isMockData = false,
  });
}

class FeedService {
  static const String _mediaUrl = 'https://nolla.net/api/v1/media';

  static Map<String, String> _headers(String authToken) => {
        'Accept': 'application/json',
        'Authorization': 'Bearer $authToken',
      };

  static bool _isCors(Object e) =>
      kIsWeb && (e.toString().contains('XMLHttpRequest') || e.toString().contains('Load failed'));

  static Future<FeedResult> fetchFeed(String authToken, {int page = 1, int limit = 20}) async {
    try {
      final uri = Uri.parse(_mediaUrl).replace(queryParameters: {
        'page': page.toString(),
        'per_page': limit.toString(),
      });
      AppLogger.log('[FeedService] GET $uri');
      final response = await http.get(uri, headers: _headers(authToken)).timeout(const Duration(seconds: 10));
      AppLogger.log('[FeedService] status=${response.statusCode}');
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final List<dynamic> list;
        bool hasMore = false;
        if (body is List) {
          list = body;
        } else if (body is Map<String, dynamic>) {
          final raw = body['media'] ?? body['items'] ?? body['data'] ?? body['results'];
          list = raw is List ? raw : [];
          // API wraps pagination info in a 'meta' object: {page, per_page, total, pages}
          final meta = body['meta'] as Map<String, dynamic>?;
          final total = (meta?['total'] as num?)?.toInt() ?? (body['total'] as num?)?.toInt();
          final pages = (meta?['pages'] as num?)?.toInt();
          if (pages != null) {
            hasMore = page < pages;
          } else if (total != null) {
            hasMore = page * limit < total;
          }
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
      if (_isCors(e)) {
        AppLogger.log('[FeedService] CORS error — returning mock data for web preview');
        return FeedResult(success: true, items: List.unmodifiable(mockFeedItems), isMockData: true);
      }
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
        final List<dynamic> list;
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
