// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'api_headers.dart';

class SessionService {
  static const _keyToken = 'nolla_auth_token';
  static const _keyUsername = 'nolla_auth_username';
  static const _keyCookie = 'nolla_auth_cookie';

  static Future<void> save(String username, String token) async {
    html.window.localStorage[_keyToken] = token;
    html.window.localStorage[_keyUsername] = username;
    final cookie = ApiHeaders.sessionCookie;
    if (cookie != null && cookie.isNotEmpty) {
      html.window.localStorage[_keyCookie] = cookie;
    } else {
      html.window.localStorage.remove(_keyCookie);
    }
  }

  static Future<({String username, String token})?> load() async {
    final token = html.window.localStorage[_keyToken];
    final username = html.window.localStorage[_keyUsername];
    if (token != null && token.isNotEmpty && username != null && username.isNotEmpty) {
      ApiHeaders.sessionCookie = html.window.localStorage[_keyCookie];
      return (username: username, token: token);
    }
    return null;
  }

  static Future<void> clear() async {
    html.window.localStorage.remove(_keyToken);
    html.window.localStorage.remove(_keyUsername);
    html.window.localStorage.remove(_keyCookie);
    ApiHeaders.sessionCookie = null;
  }
}
