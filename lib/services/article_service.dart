import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/article.dart';
import '../utils/mock_data.dart';
import 'app_logger.dart';

class ArticleResult {
  final bool success;
  final List<Article> articles;
  final bool isMockData;

  const ArticleResult({
    required this.success,
    this.articles = const [],
    this.isMockData = false,
  });
}

class ArticleService {
  static const String _articlesUrl = 'https://nolla.net/api/v1/articles';

  static bool _isCors(Object e) =>
      kIsWeb && (e.toString().contains('XMLHttpRequest') || e.toString().contains('Load failed'));

  static Future<ArticleResult> fetchArticles({String? authToken, int limit = 10}) async {
    try {
      final uri = Uri.parse(_articlesUrl).replace(queryParameters: {
        'limit': limit.toString(),
        'per_page': limit.toString(),
      });
      AppLogger.log('[ArticleService] GET $uri');
      final headers = {
        'Accept': 'application/json',
        if (authToken != null) 'Authorization': 'Bearer $authToken',
      };
      final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 10));
      AppLogger.log('[ArticleService] status=${response.statusCode}');

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final List<dynamic> list;
        if (body is List) {
          list = body;
        } else if (body is Map<String, dynamic>) {
          final raw = body['articles'] ?? body['data'] ?? body['items'] ?? body['results'];
          list = raw is List ? raw : [];
        } else {
          return ArticleResult(success: true, articles: mockArticles, isMockData: true);
        }
        final articles = <Article>[];
        for (final e in list) {
          try {
            articles.add(Article.fromJson(e as Map<String, dynamic>));
          } catch (err) {
            AppLogger.log('[ArticleService] skipped article: $err');
          }
        }
        if (articles.isEmpty) {
          return ArticleResult(success: true, articles: mockArticles, isMockData: true);
        }
        return ArticleResult(success: true, articles: articles);
      }

      if (kIsWeb) {
        AppLogger.log('[ArticleService] API error (${response.statusCode}) — using mock articles');
        return ArticleResult(success: true, articles: mockArticles, isMockData: true);
      }
      return const ArticleResult(success: false);
    } catch (e) {
      AppLogger.log('[ArticleService] exception: $e');
      if (_isCors(e)) {
        AppLogger.log('[ArticleService] CORS — using mock articles');
        return ArticleResult(success: true, articles: mockArticles, isMockData: true);
      }
      return ArticleResult(success: true, articles: mockArticles, isMockData: true);
    }
  }
}
