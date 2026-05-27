import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/spot.dart';
import '../models/spot_detail.dart';
import '../models/new_spot.dart';
import '../utils/mock_data.dart';
import 'app_logger.dart';

class SpotResult {
  final bool success;
  final String? message;
  final Spot? spot;
  const SpotResult({required this.success, this.message, this.spot});
}

class SpotDetailResult {
  final bool success;
  final String? message;
  final SpotDetail? spot;
  const SpotDetailResult({required this.success, this.message, this.spot});
}

class SpotService {
  static const String _spotsUrl = 'https://nolla.net/api/v1/spots';
  static bool lastFetchWasMock = false;

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
          if (longitude != null) 'lon': longitude.toString(),
          if (radius != null) 'radius': radius.toString(),
          'limit': '100',
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
        lastFetchWasMock = false;
        final body = jsonDecode(response.body);
        final List<dynamic> list;
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
      final isCors = kIsWeb && (e.toString().contains('XMLHttpRequest') || e.toString().contains('Load failed'));
      AppLogger.log(isCors
          ? '[SpotService] CORS error — returning mock spots for web preview'
          : '[SpotService] exception: $e');
      if (isCors) {
        lastFetchWasMock = true;
        return List<Spot>.unmodifiable(mockSpots);
      }
      lastFetchWasMock = false;
      return null;
    }
  }

  static Future<SpotDetailResult> fetchSpotDetail(int spotId, String authToken) async {
    try {
      final uri = Uri.parse('$_spotsUrl/$spotId');
      final headers = <String, String>{
        'Accept': 'application/json',
        'Authorization': 'Bearer $authToken',
      };
      AppLogger.log('[SpotService] GET $uri');
      final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 10));
      AppLogger.log('[SpotService] detail status=${response.statusCode} body=${response.body}');
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body is! Map<String, dynamic>) {
          return const SpotDetailResult(success: false, message: 'Unexpected response format');
        }
        final raw = body['spot'] ?? body['data'] ?? body;
        if (raw is! Map<String, dynamic>) {
          return const SpotDetailResult(success: false, message: 'Unexpected response format');
        }
        return SpotDetailResult(success: true, spot: SpotDetail.fromJson(raw));
      }
      return SpotDetailResult(success: false, message: 'Failed to load spot (${response.statusCode})');
    } catch (e) {
      final isCors = kIsWeb && (e.toString().contains('XMLHttpRequest') || e.toString().contains('Load failed'));
      AppLogger.log(isCors
          ? '[SpotService] CORS error on detail fetch'
          : '[SpotService] fetchSpotDetail exception: $e');
      return SpotDetailResult(
        success: false,
        message: isCors ? 'CORS error — API must allow web requests' : 'Network error',
      );
    }
  }

  static Future<SpotResult> createSpot(NewSpot spot, String authToken) async {
    try {
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $authToken',
      };
      AppLogger.log('[SpotService] POST $_spotsUrl');
      final response = await http
          .post(Uri.parse(_spotsUrl), headers: headers, body: jsonEncode(spot.toJson()))
          .timeout(const Duration(seconds: 10));
      AppLogger.log('[SpotService] create status=${response.statusCode} body=${response.body}');
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.body.isNotEmpty) {
          try {
            final body = jsonDecode(response.body);
            if (body is Map<String, dynamic>) {
              final data = (body['spot'] ?? body['data'] ?? body) as Map<String, dynamic>;
              return SpotResult(success: true, spot: Spot.fromJson(data));
            }
          } catch (_) {}
        }
        return const SpotResult(success: true);
      }
      return SpotResult(success: false, message: 'Failed to create spot (${response.statusCode})');
    } catch (e) {
      AppLogger.log('[SpotService] createSpot exception: $e');
      return const SpotResult(success: false, message: 'Network error');
    }
  }

  static Future<List<Spot>?> searchSpots(String query, String authToken, {double? lat, double? lon}) async {
    try {
      final params = <String, String>{'q': query, 'limit': '20'};
      if (lat != null) params['lat'] = lat.toString();
      if (lon != null) params['lon'] = lon.toString();
      final uri = Uri.parse(_spotsUrl).replace(queryParameters: params);
      final headers = <String, String>{
        'Accept': 'application/json',
        'Authorization': 'Bearer $authToken',
      };
      AppLogger.log('[SpotService] GET $uri (search)');
      final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final List<dynamic> list;
        if (body is List) {
          list = body;
        } else if (body is Map<String, dynamic>) {
          final raw = body['spots'] ?? body['data'] ?? body['results'] ?? body['items'];
          list = raw is List ? raw : [];
        } else {
          return [];
        }
        final spots = <Spot>[];
        for (final e in list) {
          try {
            spots.add(Spot.fromJson(e as Map<String, dynamic>));
          } catch (_) {}
        }
        return spots;
      }
      return null;
    } catch (e) {
      AppLogger.log('[SpotService] searchSpots exception: $e');
      return null;
    }
  }
}
