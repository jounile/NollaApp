import 'dart:convert';
import 'app_http_client.dart';
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
    try {
      final response = await appHttpClient
          .post(
            Uri.parse(_loginUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'username': username, 'password': password}),
          )
          .timeout(const Duration(seconds: 15));

      AppLogger.log('[AuthService] status=${response.statusCode} body=${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final message = data['message'] as String? ?? 'Login successful';
        // Try common token field names (API may return a token alongside cookies)
        final token = data['token'] as String? ??
            data['access_token'] as String? ??
            data['jwt'] as String? ??
            data['auth_token'] as String? ??
            data['key'] as String?;
        // For native: also try to capture Set-Cookie manually as fallback
        final rawCookie = response.headers['set-cookie'];
        if (rawCookie != null) {
          ApiHeaders.sessionCookie = ApiHeaders.parseCookies(rawCookie);
        }
        AppLogger.log('[AuthService] token=${token != null ? "present(${token.length} chars)" : "null"}');
        AppLogger.log('[AuthService] sessionCookie=${ApiHeaders.sessionCookie ?? "none (browser handles it)"}');
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
