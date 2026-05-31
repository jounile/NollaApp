import 'package:http/http.dart' as http;

// Shared client so the dart:io cookie jar persists across requests.
final http.Client appHttpClient = http.Client();
