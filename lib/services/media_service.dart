import 'dart:async';
import 'dart:convert';
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
    AppLogger.log('Upload started: $fileName ($contentType)');

    try {
      final bytes = await file.readAsBytes();

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

      // Buffer the full multipart body before sending to avoid iOS
      // NSURLSession failures when streaming an async-generator body.
      // Get headers (content-type with boundary + content-length) and add auth.
      final headers = multipart.headers;
      headers['Authorization'] = 'Bearer $authToken';
      final body = await multipart.finalize().toBytes();

      final response = await http
          .post(Uri.parse(_uploadUrl), headers: headers, body: body)
          .timeout(const Duration(minutes: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final url = data['url'] as String?;
        AppLogger.log('Upload succeeded: $fileName → $url');
        return UploadResult(success: true, message: 'Uploaded', url: url);
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>? ?? {};
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
