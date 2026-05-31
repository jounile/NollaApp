import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/profile.dart';
import '../models/public_profile.dart';
import '../models/media_item.dart';
import '../models/spot.dart';
import 'app_http_client.dart';
import 'app_logger.dart';

class ProfileResult {
  final bool success;
  final String? message;
  final Profile? profile;

  const ProfileResult({
    required this.success,
    this.message,
    this.profile,
  });
}

class PublicProfileResult {
  final bool success;
  final String? message;
  final PublicProfile? profile;

  const PublicProfileResult({required this.success, this.message, this.profile});
}

class ProfileService {
  static const String _profileUrl = 'https://nolla.net/api/v1/user';

  static bool _isCors(Object e) =>
      kIsWeb && (e.toString().contains('XMLHttpRequest') || e.toString().contains('Load failed'));

  static Map<String, String> _headers(String authToken) => {
    'Accept': 'application/json',
    if (authToken.isNotEmpty) 'Authorization': 'Bearer $authToken',
  };

  static Map<String, String> _jsonHeaders(String authToken) => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (authToken.isNotEmpty) 'Authorization': 'Bearer $authToken',
  };

  static Future<ProfileResult> fetchProfile(String authToken) async {
    try {
      AppLogger.log('[ProfileService] GET $_profileUrl');
      final response = await appHttpClient
          .get(Uri.parse(_profileUrl), headers: _headers(authToken))
          .timeout(const Duration(seconds: 10));
      AppLogger.log('[ProfileService] status=${response.statusCode} body=${response.body}');

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final Map<String, dynamic> data;
        if (body is Map<String, dynamic>) {
          data = (body['profile'] ?? body['user'] ?? body['data'] ?? body) as Map<String, dynamic>;
        } else {
          return const ProfileResult(success: false, message: 'Unexpected response format');
        }
        return ProfileResult(success: true, profile: Profile.fromJson(data));
      } else if (response.statusCode == 401) {
        return const ProfileResult(success: false, message: 'Session expired — please log in again');
      } else if (response.statusCode == 404) {
        return const ProfileResult(success: false, message: 'Profile endpoint not found');
      } else {
        return ProfileResult(success: false, message: 'Failed to load profile (${response.statusCode})');
      }
    } catch (e) {
      AppLogger.log('[ProfileService] exception: $e');
      return const ProfileResult(success: false, message: 'Network error. Please check your connection.');
    }
  }

  static Future<ProfileResult> updateProfile(String authToken, Profile profile) async {
    try {
      AppLogger.log('[ProfileService] PUT $_profileUrl');
      final response = await appHttpClient
          .put(
            Uri.parse(_profileUrl),
            headers: _jsonHeaders(authToken),
            body: jsonEncode(profile.toJson()),
          )
          .timeout(const Duration(seconds: 10));
      AppLogger.log('[ProfileService] status=${response.statusCode} body=${response.body}');

      if (response.statusCode == 200 || response.statusCode == 204) {
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
      return const ProfileResult(success: false, message: 'Network error. Please check your connection.');
    }
  }

  static Future<ProfileResult> uploadAvatar(String authToken, String filePath) async {
    try {
      final uri = Uri.parse('https://nolla.net/api/v1/user/avatar');
      AppLogger.log('[ProfileService] POST $uri (avatar upload)');
      final request = http.MultipartRequest('POST', uri)
        ..headers.addAll({
          'Accept': 'application/json',
          'Authorization': 'Bearer $authToken',
        });
      final ext = filePath.split('.').last.toLowerCase();
      final mimeType = ext == 'png' ? 'image/png' : 'image/jpeg';
      request.files.add(
        await http.MultipartFile.fromPath(
          'avatar',
          filePath,
          contentType: MediaType.parse(mimeType),
        ),
      );
      final streamed = await appHttpClient.send(request).timeout(const Duration(minutes: 2));
      final response = await http.Response.fromStream(streamed);
      AppLogger.log('[ProfileService] avatar upload status=${response.statusCode}');
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.body.isNotEmpty) {
          try {
            final body = jsonDecode(response.body);
            if (body is Map<String, dynamic>) {
              final data = (body['profile'] ?? body['user'] ?? body['data'] ?? body) as Map<String, dynamic>;
              return ProfileResult(success: true, profile: Profile.fromJson(data));
            }
          } catch (_) {}
        }
        return const ProfileResult(success: true);
      }
      return ProfileResult(success: false, message: 'Upload failed (${response.statusCode})');
    } catch (e) {
      AppLogger.log('[ProfileService] avatar upload exception: $e');
      return const ProfileResult(success: false, message: 'Failed to upload avatar');
    }
  }

  static Future<PublicProfileResult> fetchPublicProfile(String username, String authToken) async {
    try {
      final uri = Uri.parse('https://nolla.net/api/v1/users/$username');
      AppLogger.log('[ProfileService] GET $uri');
      final response = await appHttpClient.get(uri, headers: _headers(authToken)).timeout(const Duration(seconds: 10));
      AppLogger.log('[ProfileService] fetchPublicProfile status=${response.statusCode}');
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final Map<String, dynamic> data;
        if (body is Map<String, dynamic>) {
          data = (body['user'] ?? body['profile'] ?? body['data'] ?? body) as Map<String, dynamic>;
        } else {
          return const PublicProfileResult(success: false, message: 'Unexpected response format');
        }
        return PublicProfileResult(success: true, profile: PublicProfile.fromJson(data));
      }
      if (response.statusCode == 401) {
        return const PublicProfileResult(success: false, message: 'Session expired — please log in again');
      }
      return PublicProfileResult(success: false, message: 'Failed to load profile (${response.statusCode})');
    } catch (e) {
      AppLogger.log('[ProfileService] fetchPublicProfile exception: $e');
      if (_isCors(e)) {
        return const PublicProfileResult(success: false, message: 'CORS error — API must allow web requests');
      }
      return const PublicProfileResult(success: false, message: 'Network error. Please check your connection.');
    }
  }

  static Future<List<Spot>> fetchUserSpots(String username, String authToken) async {
    try {
      final uri = Uri.parse('https://nolla.net/api/v1/users/$username/spots');
      AppLogger.log('[ProfileService] GET $uri');
      final response = await appHttpClient.get(uri, headers: _headers(authToken)).timeout(const Duration(seconds: 10));
      AppLogger.log('[ProfileService] fetchUserSpots status=${response.statusCode}');
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final List<dynamic> list;
        if (body is List) {
          list = body;
        } else if (body is Map<String, dynamic>) {
          final raw = body['spots'] ?? body['data'] ?? body['results'];
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
      AppLogger.log('[ProfileService] fetchUserSpots failed (${response.statusCode})');
      return [];
    } catch (e) {
      AppLogger.log('[ProfileService] fetchUserSpots exception: $e');
      return [];
    }
  }

  static Future<List<MediaItem>> fetchUserMedia(String username, String authToken) async {
    try {
      final uri = Uri.parse('https://nolla.net/api/v1/users/$username/media');
      AppLogger.log('[ProfileService] GET $uri');
      final response = await appHttpClient.get(uri, headers: _headers(authToken)).timeout(const Duration(seconds: 10));
      AppLogger.log('[ProfileService] fetchUserMedia status=${response.statusCode}');
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final List<dynamic> list;
        if (body is List) {
          list = body;
        } else if (body is Map<String, dynamic>) {
          final raw = body['media'] ?? body['items'] ?? body['data'];
          list = raw is List ? raw : [];
        } else {
          return [];
        }
        final items = <MediaItem>[];
        for (final e in list) {
          try {
            items.add(MediaItem.fromJson(e as Map<String, dynamic>));
          } catch (_) {}
        }
        return items;
      }
      AppLogger.log('[ProfileService] fetchUserMedia failed (${response.statusCode})');
      return [];
    } catch (e) {
      AppLogger.log('[ProfileService] fetchUserMedia exception: $e');
      return [];
    }
  }
}
