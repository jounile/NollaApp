// dart:html is web-only by design — this file is only imported on web builds.
// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:html';
import 'dart:typed_data';

/// Result of a web multipart upload.
class WebUploadResponse {
  final int statusCode;
  final String body;
  WebUploadResponse(this.statusCode, this.body);
}

/// Upload a file via multipart/form-data using the browser's native
/// HttpRequest + FormData. This is the only reliable way to send
/// multipart uploads from Flutter Web — BrowserClient.send() fails
/// because it sends raw bytes instead of a FormData object.
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
  final completer = Completer<WebUploadResponse>();

  final formData = FormData();
  // Add file as Blob with correct MIME type
  final blob = Blob([fileBytes], mimeType);
  formData.appendBlob(fileFieldName, blob, fileName);

  // Add form fields
  for (final entry in fields.entries) {
    formData.append(entry.key, entry.value);
  }

  final xhr = HttpRequest();
  xhr.open('POST', url);
  xhr.withCredentials = true;
  xhr.responseType = 'text';

  // Set headers (can't set Content-Type — browser sets it automatically
  // with the correct multipart boundary when using FormData)
  for (final entry in headers.entries) {
    xhr.setRequestHeader(entry.key, entry.value);
  }

  xhr.timeout = timeout.inMilliseconds;

  xhr.onLoad.listen((_) {
    final status = xhr.status ?? 0;
    final body = xhr.responseText ?? '';
    completer.complete(WebUploadResponse(status, body));
  });

  xhr.onError.listen((_) {
    completer.completeError(
      Exception('Upload failed: network error (CORS or connectivity)'),
    );
  });

  xhr.onTimeout.listen((_) {
    completer.completeError(Exception('Upload timed out'));
  });

  xhr.send(formData);

  return completer.future;
}
