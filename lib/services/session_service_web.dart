// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class SessionService {
  static const _keyToken = 'nolla_auth_token';
  static const _keyUsername = 'nolla_auth_username';

  static Future<void> save(String username, String token) async {
    html.window.localStorage[_keyToken] = token;
    html.window.localStorage[_keyUsername] = username;
  }

  static Future<({String username, String token})?> load() async {
    final token = html.window.localStorage[_keyToken];
    final username = html.window.localStorage[_keyUsername];
    if (token != null && token.isNotEmpty && username != null && username.isNotEmpty) {
      return (username: username, token: token);
    }
    return null;
  }

  static Future<void> clear() async {
    html.window.localStorage.remove(_keyToken);
    html.window.localStorage.remove(_keyUsername);
  }
}
