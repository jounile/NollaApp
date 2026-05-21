import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'app_logger.dart';

class UploadResult {
  final bool success;
  final String message;
  final String? url;

  const UploadResult({required this.success, required this.message, this.url});
}

class MediaService {
  static const String _uploadUrl = 'https://nolla.net/api/v1/media/upload';

  Future<UploadResult> uploadFile(
    XFile file,
    bool isVideo,
    String authToken,
  ) async {
    final fileName = file.name;
    final contentType = isVideo ? 'video' : 'image';
    final mimeType = _mimeType(fileName, isVideo);

    try {
      final bytes = await file.readAsBytes();
      AppLogger.log('Upload started: $fileName ($contentType, ${bytes.length} bytes)');

      final boundary = 'NollaAppBoundary${DateTime.now().millisecondsSinceEpoch}';
      final safeFileName = fileName.replaceAll(r'\', r'\\').replaceAll('"', r'\"');

      final body = <int>[];
      void addStr(String s) => body.addAll(utf8.encode(s));

      addStr('--$boundary\r\n');
      addStr('Content-Disposition: form-data; name="content_type"\r\n\r\n');
      addStr('$contentType\r\n');

      addStr('--$boundary\r\n');
      addStr('Content-Disposition: form-data; name="file"; filename="$safeFileName"\r\n');
      addStr('Content-Type: $mimeType\r\n\r\n');
      body.addAll(bytes);
      addStr('\r\n--$boundary--\r\n');

      final headers = <String, String>{
        'Content-Type': 'multipart/form-data; boundary=$boundary',
        'Authorization': 'Bearer $authToken',
      };

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
      // On Flutter Web a CORS preflight failure throws a ClientException whose
      // message varies by browser:
      //   Chrome/Edge : "XMLHttpRequest error."
      //   Safari      : "Load failed" / "Failed to fetch"
      //   Firefox     : "NetworkError when attempting to fetch resource"
      // The server must handle OPTIONS preflight and respond with:
      //   Access-Control-Allow-Origin: <origin>
      //   Access-Control-Allow-Methods: POST, OPTIONS
      //   Access-Control-Allow-Headers: Authorization, Content-Type
      final errorStr = e.toString();
      final isCors = kIsWeb &&
          (errorStr.contains('XMLHttpRequest') ||
              errorStr.contains('Load failed') ||
              errorStr.contains('Failed to fetch') ||
              errorStr.contains('NetworkError'));
      if (isCors) {
        AppLogger.log(
          'Upload error: CORS blocked — $_uploadUrl needs '
          'Access-Control-Allow-Headers: Authorization, Content-Type '
          'and Access-Control-Allow-Methods: POST, OPTIONS',
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
