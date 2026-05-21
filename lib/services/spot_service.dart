import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/spot.dart';

class SpotService {
  static const String _spotsUrl = 'https://nolla.net/api/v1/spots';

  static Future<List<Spot>> fetchSpots({
    double? latitude,
    double? longitude,
    String? authToken,
  }) async {
    try {
      final uri = Uri.parse(_spotsUrl).replace(
        queryParameters: {
          if (latitude != null) 'lat': latitude.toString(),
          if (longitude != null) 'lng': longitude.toString(),
        },
      );
      final headers = <String, String>{'Accept': 'application/json'};
      if (authToken != null && authToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $authToken';
      }
      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        List<dynamic> list;
        if (body is List) {
          list = body;
        } else if (body is Map<String, dynamic>) {
          list = (body['spots'] ?? body['data'] ?? body['results'] ?? []) as List<dynamic>;
        } else {
          return [];
        }
        return list
            .map((e) => Spot.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }
}
