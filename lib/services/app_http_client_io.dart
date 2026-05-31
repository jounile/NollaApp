import 'package:http/http.dart' as http;

// On native, a shared Client carries the dart:io cookie store across requests,
// so the session cookie from login is automatically forwarded to the API.
final http.Client appHttpClient = http.Client();
