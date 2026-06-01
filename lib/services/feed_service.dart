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
  static const Duration _headTimeout = Duration(seconds: 5);

  static Future<bool> _videoExists(MediaItem item) async {
    try {
      final videoUrl = item.viewUrl;
      AppLogger.log('[FeedService] HEAD $videoUrl');
      final response = await appHttpClient.head(Uri.parse(videoUrl)).timeout(_headTimeout);
      final exists = response.statusCode == 200;
      AppLogger.log('[FeedService] video id=${item.id} exists=$exists status=${response.statusCode}');
      return exists;
    } catch (e) {
      AppLogger.log('[FeedService] video id=${item.id} exists check failed: $e');
      return false;
    }
  }

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
        // Parse all items first
        final parsed = <MediaItem>[];
        for (final e in list) {
          try {
            parsed.add(MediaItem.fromJson(e as Map<String, dynamic>));
          } catch (err) {
            AppLogger.log('[FeedService] skipped item: $err');
          }
        }

        // Check video existence in parallel, then filter
        final existenceFutures = <int, Future<bool>>{};
        for (final item in parsed) {
          if (item.mediaType == 'video') {
            existenceFutures[item.id] = _videoExists(item);
          }
        }
        final existenceResults = <int, bool>{};
        if (existenceFutures.isNotEmpty) {
          final ids = existenceFutures.keys.toList();
          final futures = ids.map((id) => existenceFutures[id]!);
          final results = await Future.wait(futures);
          for (int i = 0; i < ids.length; i++) {
            existenceResults[ids[i]] = results[i];
          }
        }

        final items = <MediaItem>[];
        for (final item in parsed) {
          if (item.mediaType == 'video') {
            final exists = existenceResults[item.id] ?? false;
            if (!exists) {
              AppLogger.log('[FeedService] skipped video without file: id=${item.id}');
              continue;
            }
          }
          items.add(item);
          AppLogger.log('[FeedService] item id=${item.id} type=${item.mediaType} thumb=${item.thumbnailUrl}');
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
            final item = MediaItem.fromJson(e as Map<String, dynamic>);
            if (item.mediaType == 'video' && !await _videoExists(item)) continue;
            items.add(item);
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
