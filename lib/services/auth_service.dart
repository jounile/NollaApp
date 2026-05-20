import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthResult {
  final bool success;
  final String message;

  const AuthResult({required this.success, required this.message});
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
        return AuthResult(success: true, message: message);
      } else {
        final data = jsonDecode(response.body) as Map<String, dynamic>? ?? {};
        final message = data['message'] as String? ?? 'Invalid credentials';
        return AuthResult(success: false, message: message);
      }
    } catch (e) {
      return const AuthResult(
        success: false,
        message: 'Network error. Please check your connection.',
      );
    }
  }
}
