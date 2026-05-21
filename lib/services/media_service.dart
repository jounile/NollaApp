import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'app_logger.dart';

class UploadResult {
  final bool success;
  final String message;
  final String? url;

  const UploadResult({required this.success, required this.message, this.url});
}

class MediaService {
  static const String _uploadUrl = 'https://nolla.net/media/api/upload';

  Future<UploadResult> uploadFile(
    XFile file,
    bool isVideo,
    String authToken,
  ) async {
    final fileName = file.name;
    final contentType = isVideo ? 'video' : 'image';

    try {
      final bytes = await file.readAsBytes();
      AppLogger.log('Upload started: $fileName ($contentType, ${bytes.length} bytes)');

      final multipart = http.MultipartRequest('POST', Uri.parse(_uploadUrl));
      multipart.fields['content_type'] = contentType;
      multipart.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: fileName,
          contentType: MediaType.parse(_mimeType(fileName, isVideo)),
        ),
      );

      // MultipartRequest.headers returns a computed copy each call, so we
      // capture it once and then inject Authorization into that same map.
      final headers = multipart.headers;
      headers['Authorization'] = 'Bearer $authToken';
      final body = await multipart.finalize().toBytes();

      final response = await http
          .post(Uri.parse(_uploadUrl), headers: headers, body: body)
          .timeout(const Duration(minutes: 5));

      if (response.statusCode == 200) {
        String? url;
        if (response.body.isNotEmpty) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          url = data['url'] as String?;
        }
        AppLogger.log('Upload succeeded: $fileName → $url');
        return UploadResult(success: true, message: 'Uploaded', url: url);
      }
      Map<String, dynamic> data = {};
      if (response.body.isNotEmpty) {
        try {
          data = jsonDecode(response.body) as Map<String, dynamic>? ?? {};
        } on FormatException {
          AppLogger.log('Upload error: non-JSON response body for $fileName');
        }
      }
      final message = data['message'] as String? ?? 'Upload failed';
      AppLogger.log('Upload failed: $fileName — HTTP ${response.statusCode}: $message');
      return UploadResult(success: false, message: message);
    } on TimeoutException {
      AppLogger.log('Upload timed out: $fileName');
      return const UploadResult(
        success: false,
        message: 'Upload timed out. Please try again.',
      );
    } catch (e) {
      // On Flutter Web (especially Safari), a CORS preflight failure for a
      // POST with the Authorization header appears as "Load failed" or
      // "XMLHttpRequest error." — the server needs:
      //   Access-Control-Allow-Headers: Authorization, Content-Type
      //   Access-Control-Allow-Methods: POST, OPTIONS
      final errorStr = e.toString();
      final isCors = kIsWeb &&
          (errorStr.contains('Load failed') ||
              errorStr.contains('XMLHttpRequest'));
      if (isCors) {
        AppLogger.log(
          'Upload error: CORS blocked — server must allow Authorization header '
          'for $_uploadUrl (OPTIONS preflight failed)',
        );
        return const UploadResult(
          success: false,
          message: 'Upload blocked by browser security policy. '
              'Please try the mobile app or contact support.',
        );
      }
      AppLogger.log('Upload error: $fileName — $e');
      return const UploadResult(
        success: false,
        message: 'Network error. Please check your connection.',
      );
    }
  }

  static String _mimeType(String fileName, bool isVideo) {
    final ext = fileName.contains('.') ? fileName.split('.').last.toLowerCase() : '';
    if (isVideo) {
      switch (ext) {
        case 'mov':
          return 'video/quicktime';
        case 'avi':
          return 'video/x-msvideo';
        default:
          return 'video/mp4';
      }
    }
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'heic':
      case 'heif':
        return 'image/heic';
      default:
        return 'image/jpeg';
    }
  }
}
