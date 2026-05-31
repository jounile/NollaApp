class ApiHeaders {
  ApiHeaders._();

  // Set-Cookie value captured from login; cleared on logout.
  static String? sessionCookie;

  static Map<String, String> build(
    String authToken, {
    bool json = false,
  }) {
    final headers = <String, String>{'Accept': 'application/json'};
    if (authToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $authToken';
    }
    if (json) {
      headers['Content-Type'] = 'application/json';
    }
    final cookie = sessionCookie;
    if (cookie != null && cookie.isNotEmpty) {
      headers['Cookie'] = cookie;
    }
    return headers;
  }

  // Parse raw Set-Cookie response header(s) into a Cookie request header value.
  // Strips per-cookie directives (Path, HttpOnly, etc.) and joins all pairs.
  static String? parseCookies(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final pairs = raw
        .split(RegExp(r',\s*(?=[A-Za-z_][A-Za-z0-9_\-]*\s*=)'))
        .map((c) => c.split(';').first.trim())
        .where((c) => c.contains('='))
        .toList();
    return pairs.isEmpty ? null : pairs.join('; ');
  }
}
