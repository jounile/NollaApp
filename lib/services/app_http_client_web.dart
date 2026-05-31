import 'package:http/browser_client.dart';
import 'package:http/http.dart' as http;

// withCredentials = true sends the nolla.net session cookie on cross-origin
// API requests. Requires the server to return Access-Control-Allow-Credentials: true
// with a specific origin (not wildcard) — confirmed on /api/v1/*.
final http.Client appHttpClient = BrowserClient()..withCredentials = true;
