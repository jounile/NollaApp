import 'package:http/browser_client.dart';
import 'package:http/http.dart' as http;

// Enable withCredentials so the browser sends cookies/auth headers
// in cross-origin requests (needed for JWT auth to nolla.net API).
final http.Client appHttpClient = (BrowserClient()..withCredentials = true);
