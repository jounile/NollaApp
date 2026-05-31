import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_headers.dart';

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
      final response = await http.post(
        Uri.parse(_loginUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final message = data['message'] as String? ?? 'Login successful';
        // Try common token field names
        final token = data['token'] as String? ??
            data['access_token'] as String? ??
            data['jwt'] as String? ??
            data['auth_token'] as String? ??
            data['key'] as String?;
        // Capture session cookie for cookie-based auth
        ApiHeaders.sessionCookie = ApiHeaders.parseCookies(response.headers['set-cookie']);
        return AuthResult(success: true, message: message, token: token);
      } else {
        final data = jsonDecode(response.body) as Map<String, dynamic>? ?? {};
        final message = data['message'] as String? ?? 'Invalid credentials';
        return AuthResult(success: false, message: message);
      }
    } catch (_) {
      return const AuthResult(
        success: false,
        message: 'Network error. Please check your connection.',
      );
    }
  }
}
