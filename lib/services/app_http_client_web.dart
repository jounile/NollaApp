import 'package:http/browser_client.dart';
import 'package:http/http.dart' as http;

// nolla.net uses Access-Control-Allow-Origin: * which is incompatible with
// withCredentials = true. Use a plain BrowserClient so cross-origin requests
// are not blocked by CORS preflight.
final http.Client appHttpClient = BrowserClient();
