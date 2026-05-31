import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/media_item.dart';
import 'app_http_client.dart';
import 'app_logger.dart';

class FeedResult {
  final bool success;
  final String? message;
  final List<MediaItem> items;
  final bool hasMore;
  final int? total;

  const FeedResult({
    required this.success,
    this.message,
    this.items = const [],
    this.hasMore = false,
    this.total,
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
        'per_page': limit.toString(),
      });
      AppLogger.log('[FeedService] GET $uri');
      final response = await appHttpClient.get(uri, headers: _headers(authToken)).timeout(const Duration(seconds: 10));
      AppLogger.log('[FeedService] status=${response.statusCode}');
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final List<dynamic> list;
        bool hasMore = false;
        int? total;
        if (body is List) {
          list = body;
        } else if (body is Map<String, dynamic>) {
          final raw = body['media'] ?? body['items'] ?? body['data'] ?? body['results'];
          list = raw is List ? raw : [];
          final meta = body['meta'] as Map<String, dynamic>?;
          total = (meta?['total'] as num?)?.toInt() ?? (body['total'] as num?)?.toInt();
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
            if ((e['mediatype_id'] as num?)?.toInt() == 5) continue;
            final item = MediaItem.fromJson(e as Map<String, dynamic>);
            AppLogger.log('[FeedService] item id=${item.id} type=${item.mediaType} rawType=${e['media_type'] ?? e['type'] ?? e['mediatype_id']} url=${item.url} viewUrl=${item.viewUrl} thumb=${item.thumbnailUrl}');
            items.add(item);
          } catch (err) {
            AppLogger.log('[FeedService] skipped item: $err');
          }
        }
        AppLogger.log('[FeedService] total=$total hasMore=$hasMore items=${items.length}');
        return FeedResult(success: true, items: items, hasMore: hasMore, total: total);
      }
      if (response.statusCode == 401) {
        return const FeedResult(success: false, message: 'Session expired — please log in again');
      }
      return FeedResult(success: false, message: 'Failed to load feed (${response.statusCode})');
    } catch (e) {
      AppLogger.log('[FeedService] exception: $e');
      final isCors = kIsWeb && (e.toString().contains('Load failed') || e.toString().contains('XMLHttpRequest'));
      if (isCors) {
        return const FeedResult(success: false, message: 'CORS error — API must allow web requests');
      }
      return const FeedResult(success: false, message: 'Network error. Please check your connection.');
    }
  }

  static Future<int?> fetchTotalForType(int mediatypeId, String authToken) async {
    try {
      final uri = Uri.parse(_mediaUrl).replace(queryParameters: {
        'mediatype_id': mediatypeId.toString(),
        'per_page': '1',
        'page': '1',
      });
      AppLogger.log('[FeedService] GET $uri (count probe)');
      final response = await appHttpClient.get(uri, headers: _headers(authToken)).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body is Map<String, dynamic>) {
          final meta = body['meta'] as Map<String, dynamic>?;
          final total = (meta?['total'] as num?)?.toInt() ?? (body['total'] as num?)?.toInt();
          AppLogger.log('[FeedService] type=$mediatypeId total=$total');
          return total;
        }
      }
    } catch (e) {
      AppLogger.log('[FeedService] fetchTotalForType exception: $e');
    }
    return null;
  }

  static Future<FeedResult> fetchSpotMedia(int spotId, String authToken) async {
    try {
      final uri = Uri.parse('https://nolla.net/api/v1/spots/$spotId/media');
      AppLogger.log('[FeedService] GET $uri');
      final response = await appHttpClient.get(uri, headers: _headers(authToken)).timeout(const Duration(seconds: 10));
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
