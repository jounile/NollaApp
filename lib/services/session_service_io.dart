import 'package:shared_preferences/shared_preferences.dart';
import 'api_headers.dart';

class SessionService {
  static const _keyToken = 'nolla_auth_token';
  static const _keyUsername = 'nolla_auth_username';
  static const _keyCookie = 'nolla_auth_cookie';

  static Future<void> save(String username, String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
    await prefs.setString(_keyUsername, username);
    final cookie = ApiHeaders.sessionCookie;
    if (cookie != null && cookie.isNotEmpty) {
      await prefs.setString(_keyCookie, cookie);
    } else {
      await prefs.remove(_keyCookie);
    }
  }

  static Future<({String username, String token})?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_keyToken);
    final username = prefs.getString(_keyUsername);
    if (token != null && token.isNotEmpty && username != null && username.isNotEmpty) {
      ApiHeaders.sessionCookie = prefs.getString(_keyCookie);
      return (username: username, token: token);
    }
    return null;
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyUsername);
    await prefs.remove(_keyCookie);
    ApiHeaders.sessionCookie = null;
  }
}
