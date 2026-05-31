import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_headers.dart';
import 'app_logger.dart';

class AuthResult {
  final bool success;
  final String message;
  final String? token;

  const AuthResult({required this.success, required this.message, this.token});
}

class AuthService {
  static const String _loginUrl = 'https://nolla.net/auth/api/login';

  Future<AuthResult> login(String username, String password) async {
    return kIsWeb
        ? _loginWeb(username, password)
        : _loginNative(username, password);
  }

  // On native: use dart:io directly so response.cookies is accessible.
  // The http package wraps dart:io but doesn't always surface Set-Cookie.
  Future<AuthResult> _loginNative(String username, String password) async {
    final client = io.HttpClient();
    try {
      final request = await client.postUrl(Uri.parse(_loginUrl));
      request.headers.contentType = io.ContentType.json;
      request.write(jsonEncode({'username': username, 'password': password}));
      final ioResponse = await request.close();

      final bodyBytes = <int>[];
      await ioResponse.forEach(bodyBytes.addAll);
      final body = utf8.decode(bodyBytes);

      AppLogger.log('[AuthService] status=${ioResponse.statusCode} body=$body');

      // dart:io parses Set-Cookie headers into response.cookies
      final cookies = ioResponse.cookies;
      AppLogger.log('[AuthService] cookies=${cookies.map((c) => "${c.name}=${c.value}").join(", ")}');

      if (cookies.isNotEmpty) {
        ApiHeaders.sessionCookie = cookies.map((c) => '${c.name}=${c.value}').join('; ');
      } else {
        // Fallback: try raw Set-Cookie header string
        final raw = ioResponse.headers['set-cookie'];
        AppLogger.log('[AuthService] raw set-cookie header=$raw');
        if (raw != null) {
          ApiHeaders.sessionCookie = ApiHeaders.parseCookies(raw.join(', '));
        }
      }

      AppLogger.log('[AuthService] sessionCookie=${ApiHeaders.sessionCookie ?? "null"}');

      if (ioResponse.statusCode == 200) {
        final data = jsonDecode(body) as Map<String, dynamic>;
        final message = data['message'] as String? ?? 'Login successful';
        final token = data['token'] as String? ??
            data['access_token'] as String? ??
            data['jwt'] as String? ??
            data['auth_token'] as String? ??
            data['key'] as String?;
        AppLogger.log('[AuthService] token=${token != null ? "present(${token.length} chars)" : "null"}');
        return AuthResult(success: true, message: message, token: token);
      } else {
        final data = jsonDecode(body) as Map<String, dynamic>? ?? {};
        final message = data['message'] as String? ?? 'Invalid credentials';
        return AuthResult(success: false, message: message);
      }
    } catch (e) {
      AppLogger.log('[AuthService] exception: $e');
      return const AuthResult(success: false, message: 'Network error. Please check your connection.');
    } finally {
      client.close(force: false);
    }
  }

  // On web: use the http package; the browser handles cookies automatically.
  Future<AuthResult> _loginWeb(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse(_loginUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );

      AppLogger.log('[AuthService] web status=${response.statusCode} body=${response.body}');
      AppLogger.log('[AuthService] web set-cookie=${response.headers['set-cookie'] ?? "null"}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final message = data['message'] as String? ?? 'Login successful';
        final token = data['token'] as String? ??
            data['access_token'] as String? ??
            data['jwt'] as String? ??
            data['auth_token'] as String? ??
            data['key'] as String?;
        final rawCookie = response.headers['set-cookie'];
        if (rawCookie != null) {
          ApiHeaders.sessionCookie = ApiHeaders.parseCookies(rawCookie);
        }
        AppLogger.log('[AuthService] token=${token != null ? "present(${token.length} chars)" : "null"}');
        AppLogger.log('[AuthService] sessionCookie=${ApiHeaders.sessionCookie ?? "null"}');
        return AuthResult(success: true, message: message, token: token);
      } else {
        final data = jsonDecode(response.body) as Map<String, dynamic>? ?? {};
        final message = data['message'] as String? ?? 'Invalid credentials';
        return AuthResult(success: false, message: message);
      }
    } catch (e) {
      AppLogger.log('[AuthService] exception: $e');
      return const AuthResult(success: false, message: 'Network error. Please check your connection.');
    }
  }
}
