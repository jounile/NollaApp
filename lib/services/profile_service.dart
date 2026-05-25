import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/profile.dart';
import 'app_logger.dart';

class ProfileResult {
  final bool success;
  final String? message;
  final Profile? profile;

  const ProfileResult({required this.success, this.message, this.profile});
}

class ProfileService {
  static const String _profileUrl = 'https://nolla.net/api/v1/profile';

  static Map<String, String> _headers(String authToken) => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'Authorization': 'Bearer $authToken',
  };

  static Future<ProfileResult> fetchProfile(String authToken) async {
    try {
      AppLogger.log('[ProfileService] GET $_profileUrl');
      final response = await http
          .get(Uri.parse(_profileUrl), headers: _headers(authToken))
          .timeout(const Duration(seconds: 10));
      AppLogger.log('[ProfileService] status=${response.statusCode} body=${response.body}');

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final Map<String, dynamic> data;
        if (body is Map<String, dynamic>) {
          // Unwrap common envelope keys
          data = (body['profile'] ?? body['user'] ?? body['data'] ?? body) as Map<String, dynamic>;
        } else {
          return const ProfileResult(success: false, message: 'Unexpected response format');
        }
        return ProfileResult(success: true, profile: Profile.fromJson(data));
      } else if (response.statusCode == 401) {
        return const ProfileResult(success: false, message: 'Session expired — please log in again');
      } else {
        return ProfileResult(success: false, message: 'Failed to load profile (${response.statusCode})');
      }
    } catch (e) {
      AppLogger.log('[ProfileService] exception: $e');
      return ProfileResult(success: false, message: 'Network error. Please check your connection.');
    }
  }

  static Future<ProfileResult> updateProfile(String authToken, Profile profile) async {
    try {
      AppLogger.log('[ProfileService] PUT $_profileUrl');
      final response = await http
          .put(
            Uri.parse(_profileUrl),
            headers: _headers(authToken),
            body: jsonEncode(profile.toJson()),
          )
          .timeout(const Duration(seconds: 10));
      AppLogger.log('[ProfileService] status=${response.statusCode} body=${response.body}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        // Some APIs return the updated profile, others return 204 No Content
        if (response.body.isNotEmpty) {
          try {
            final body = jsonDecode(response.body);
            if (body is Map<String, dynamic>) {
              final data = (body['profile'] ?? body['user'] ?? body['data'] ?? body) as Map<String, dynamic>;
              return ProfileResult(success: true, profile: Profile.fromJson(data));
            }
          } catch (_) {}
        }
        return ProfileResult(success: true, profile: profile);
      } else if (response.statusCode == 401) {
        return const ProfileResult(success: false, message: 'Session expired — please log in again');
      } else {
        return ProfileResult(success: false, message: 'Failed to save profile (${response.statusCode})');
      }
    } catch (e) {
      AppLogger.log('[ProfileService] exception: $e');
      return ProfileResult(success: false, message: 'Network error. Please check your connection.');
    }
  }
}
