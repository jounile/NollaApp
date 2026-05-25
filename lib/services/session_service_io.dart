import 'package:shared_preferences/shared_preferences.dart';

class SessionService {
  static const _keyToken = 'nolla_auth_token';
  static const _keyUsername = 'nolla_auth_username';

  static Future<void> save(String username, String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
    await prefs.setString(_keyUsername, username);
  }

  static Future<({String username, String token})?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_keyToken);
    final username = prefs.getString(_keyUsername);
    if (token != null && token.isNotEmpty && username != null && username.isNotEmpty) {
      return (username: username, token: token);
    }
    return null;
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyUsername);
  }
}
