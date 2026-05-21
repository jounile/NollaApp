import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/spot.dart';
import 'app_logger.dart';

class SpotService {
  static const String _spotsUrl = 'https://nolla.net/api/v1/spots';

  // Returns null on network/API error, empty list when API succeeds but has no spots.
  static Future<List<Spot>?> fetchSpots({
    double? latitude,
    double? longitude,
    int? radius,
    String? authToken,
  }) async {
    try {
      final uri = Uri.parse(_spotsUrl).replace(
        queryParameters: {
          if (latitude != null) 'lat': latitude.toString(),
          if (longitude != null) 'lng': longitude.toString(),
          if (radius != null) 'radius': radius.toString(),
        },
      );
      final headers = <String, String>{'Accept': 'application/json'};
      if (authToken != null && authToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $authToken';
      }
      AppLogger.log('[SpotService] GET $uri');
      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 10));
      AppLogger.log('[SpotService] status=${response.statusCode} body=${response.body}');
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        List<dynamic> list;
        if (body is List) {
          list = body;
        } else if (body is Map<String, dynamic>) {
          // Try common wrapper keys used by REST APIs
          final dynamic raw = body['spots'] ??
              body['data'] ??
              body['results'] ??
              body['nearest'] ??
              body['items'] ??
              body['locations'];
          if (raw is List) {
            list = raw;
          } else if (raw == null) {
            AppLogger.log('[SpotService] no known list key found in response keys: ${body.keys}');
            return [];
          } else {
            list = [];
          }
        } else {
          return [];
        }
        final spots = <Spot>[];
        for (final e in list) {
          try {
            final spot = Spot.fromJson(e as Map<String, dynamic>);
            if (spot.latitude == 0.0 && spot.longitude == 0.0) {
              AppLogger.log('[SpotService] warning: spot "${spot.name}" has 0,0 coords — raw keys: ${e.keys.toList()}');
            }
            spots.add(spot);
          } catch (parseErr) {
            AppLogger.log('[SpotService] skipped malformed spot: $parseErr — data: $e');
          }
        }
        AppLogger.log('[SpotService] parsed ${spots.length} of ${list.length} spots');
        return spots;
      }
      AppLogger.log('[SpotService] non-200 status: ${response.statusCode}');
      return null;
    } catch (e) {
      final isCors = kIsWeb && e.toString().contains('XMLHttpRequest');
      AppLogger.log(isCors
          ? '[SpotService] CORS error — server must add Access-Control-Allow-Origin header'
          : '[SpotService] exception: $e');
      return null;
    }
  }
}
