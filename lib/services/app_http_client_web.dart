import 'package:http/browser_client.dart';
import 'package:http/http.dart' as http;

// withCredentials = true sends the nolla.net session cookie on cross-origin
// requests. Requires Access-Control-Allow-Credentials: true with a specific
// origin on the server — confirmed for /api/v1/*.
final http.Client appHttpClient = BrowserClient()..withCredentials = true;
