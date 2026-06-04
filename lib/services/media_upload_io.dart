import 'dart:typed_data';

/// Result of a web multipart upload (stub for native builds).
class WebUploadResponse {
  final int statusCode;
  final String body;
  WebUploadResponse(this.statusCode, this.body);
}

/// Stub — never called on native, but must exist so the conditional import compiles.
Future<WebUploadResponse> uploadMultipartWeb({
  required String url,
  required String fileName,
  required Uint8List fileBytes,
  required String fileFieldName,
  required String mimeType,
  required Map<String, String> fields,
  required Map<String, String> headers,
  required Duration timeout,
}) {
  throw UnsupportedError('uploadMultipartWeb is web-only');
}
