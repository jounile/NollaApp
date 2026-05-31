class UserCache {
  UserCache._();

  // Populated from the login response user object; used as profile fallback
  // on web where session cookies can't be forwarded cross-origin.
  static Map<String, dynamic>? loginUserData;
}
