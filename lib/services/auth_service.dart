import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class AuthResult {
  final bool success;
  final String message;
  final String? token;

  const AuthResult({required this.success, required this.message, this.token});
}

class AuthService {
  static const String _loginUrl = 'https://nolla.net/api/v1/auth/login';

  Future<AuthResult> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse(_loginUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final message = data['message'] as String? ?? 'Login successful';
        final rawToken = data['token'] ?? data['access_token'] ?? data['jwt'] ?? data['auth_token'] ?? data['key'];
        final token = rawToken is String ? rawToken : null;
        return AuthResult(success: true, message: message, token: token);
      } else {
        final data = jsonDecode(response.body) as Map<String, dynamic>? ?? {};
        final message = data['message'] as String? ?? 'Invalid credentials';
        return AuthResult(success: false, message: message);
      }
    } catch (e) {
      final isCors = kIsWeb && (e.toString().contains('XMLHttpRequest') || e.toString().contains('Load failed'));
      return AuthResult(
        success: false,
        message: isCors
            ? 'Cannot reach server from web — CORS policy blocked the login request'
            : 'Network error. Please check your connection.',
      );
    }
  }
}
