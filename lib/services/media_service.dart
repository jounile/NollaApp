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
  static const String _uploadUrl = 'https://nolla.net/api/v1/media/upload';

  Future<UploadResult> uploadFile(
    XFile file,
    bool isVideo,
    String authToken,
  ) async {
    final fileName = file.name;
    final contentType = isVideo ? 'video' : 'image';

    try {
      final bytes = await file.readAsBytes();
      AppLogger.log('[MediaService] Upload started: $fileName ($contentType, ${bytes.length} bytes)');

      final multipart = http.MultipartRequest('POST', Uri.parse(_uploadUrl));
      multipart.fields['content_type'] = contentType;
      multipart.files.add(
        http.MultipartFile.fromBytes(
          'files',
          bytes,
          filename: fileName,
          contentType: MediaType.parse(_mimeType(fileName, isVideo)),
        ),
      );
      multipart.headers['Authorization'] = 'Bearer $authToken';

      final streamedResponse = await multipart.send().timeout(const Duration(minutes: 5));
      final response = await http.Response.fromStream(streamedResponse);

      // API returns 200 (all ok) or 207 (partial success); both count as success.
      if (response.statusCode == 200 || response.statusCode == 207) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        // URL comes from files[0].blob_path, not a top-level 'url' field.
        final files = data['files'] as List<dynamic>?;
        String? blobPath;
        if (files != null && files.isNotEmpty) {
          final first = files.first;
          if (first is Map<String, dynamic>) {
            blobPath = first['blob_path'] as String?;
          }
        }
        final partial = response.statusCode == 207;
        AppLogger.log('[MediaService] Upload ${partial ? "partial " : ""}succeeded: $fileName → $blobPath');
        return UploadResult(
          success: true,
          message: partial ? 'Partially uploaded' : 'Uploaded',
          url: blobPath,
        );
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>? ?? {};
      // Log the full response so we can see which validation failed
      AppLogger.log('[MediaService] Upload failed response: ${response.body}');
      final message = data['message'] as String? ?? data['status'] as String? ?? 'Upload failed';
      AppLogger.log('[MediaService] Upload failed: $fileName — HTTP ${response.statusCode}: $message');
      return UploadResult(success: false, message: message);
    } on TimeoutException {
      AppLogger.log('[MediaService] Upload timed out: $fileName');
      return const UploadResult(
        success: false,
        message: 'Upload timed out. Please try again.',
      );
    } catch (e) {
      final errorStr = e.toString();
      AppLogger.log('[MediaService] Upload error: $fileName — $errorStr');
      // On Flutter Web, CORS preflight failures can appear as various error
      // strings depending on the browser. Surface the real error so we can
      // diagnose instead of showing a generic message.
      if (kIsWeb) {
        return UploadResult(
          success: false,
          message: 'Upload failed: $errorStr',
        );
      }
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
