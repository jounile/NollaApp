import 'package:http/browser_client.dart';
import 'package:http/http.dart' as http;

final _client = BrowserClient();
// Enable withCredentials so the browser sends cookies/auth headers
// in cross-origin requests (needed for JWT auth to nolla.net API).
_client.withCredentials = true;
final http.Client appHttpClient = _client;
