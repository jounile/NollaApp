import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/spot.dart';

class SpotService {
  static const String _spotsUrl = 'https://nolla.net/api/spots';

  static Future<List<Spot>> fetchSpots({
    double? latitude,
    double? longitude,
  }) async {
    try {
      final uri = Uri.parse(_spotsUrl).replace(
        queryParameters: {
          if (latitude != null) 'lat': latitude.toString(),
          if (longitude != null) 'lng': longitude.toString(),
        },
      );
      final response = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final list = data['spots'] as List<dynamic>;
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
