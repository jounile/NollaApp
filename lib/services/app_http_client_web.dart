import 'package:http/browser_client.dart';
import 'package:http/http.dart' as http;

// withCredentials = true makes the browser send the nolla.net session
// cookie on every cross-origin API request, exactly like a browser page would.
final http.Client appHttpClient = BrowserClient()..withCredentials = true;
