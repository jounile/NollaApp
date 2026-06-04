import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'app_http_client.dart';
import 'app_logger.dart';
import 'media_upload_web.dart' if (dart.library.io) 'media_upload_io.dart';

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
    final fileName = _generateFileName(file.name, isVideo);
    final contentType = isVideo ? 'video' : 'image';

    try {
      final bytes = await file.readAsBytes();
      AppLogger.log('[MediaService] Upload started: $fileName ($contentType, ${bytes.length} bytes)');

      final multipart = http.MultipartRequest('POST', Uri.parse(_uploadUrl));
      multipart.fields['content_type'] = contentType;
      // media_topic is required by the DB (NOT NULL). Use filename as default.
      multipart.fields['media_topic'] = fileName;
      multipart.files.add(
        http.MultipartFile.fromBytes(
          'files',
          bytes,
          filename: fileName,
          contentType: MediaType.parse(_mimeType(fileName, isVideo)),
        ),
      );
      multipart.headers['Authorization'] = 'Bearer $authToken';

      // On web, BrowserClient.send() with MultipartRequest fails — it sends
      // raw bytes instead of a browser FormData object. Use dart:html XHR.
      if (kIsWeb) {
        final result = await uploadMultipartWeb(
          url: _uploadUrl,
          fileName: fileName,
          fileBytes: bytes,
          fileFieldName: 'files',
          mimeType: _mimeType(fileName, isVideo),
          fields: {
            'content_type': contentType,
            'media_topic': fileName,
          },
          headers: {'Authorization': 'Bearer $authToken'},
          timeout: const Duration(minutes: 5),
        ).timeout(const Duration(minutes: 5));
        final response = http.Response(result.body, result.statusCode);
        return _parseResponse(response, fileName);
      } else {
        final streamedResponse =
            await multipart.send().timeout(const Duration(minutes: 5));
        final response = await http.Response.fromStream(streamedResponse);
        return _parseResponse(response, fileName);
      }
    } on TimeoutException {
      AppLogger.log('[MediaService] Upload timed out: $fileName');
      return const UploadResult(
        success: false,
        message: 'Upload timed out. Please try again.',
      );
    } catch (e) {
      final errorStr = e.toString();
      AppLogger.log('[MediaService] Upload error: $fileName — $errorStr');
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

  /// Parse the server response (shared by both upload paths).
  UploadResult _parseResponse(http.Response response, String fileName) {
    if (response.statusCode == 200 || response.statusCode == 207) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final files = data['files'] as List<dynamic>?;
      String? blobPath;
      if (files != null && files.isNotEmpty) {
        final first = files.first;
        if (first is Map<String, dynamic>) {
          blobPath = first['blob_path'] as String?;
        }
      }
      final partial = response.statusCode == 207;
      AppLogger.log(
          '[MediaService] Upload ${partial ? "partial " : ""}succeeded: $fileName → $blobPath');
      return UploadResult(
        success: true,
        message: partial ? 'Partially uploaded' : 'Uploaded',
        url: blobPath,
      );
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>? ?? {};
    AppLogger.log('[MediaService] Upload failed response: ${response.body}');
    final message =
        data['message'] as String? ?? data['status'] as String? ?? 'Upload failed';
    AppLogger.log(
        '[MediaService] Upload failed: $fileName — HTTP ${response.statusCode}: $message');
    return UploadResult(success: false, message: message);
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

  /// Generate a readable filename. On web, image_picker gives generic names
  /// like "scaled_image.jpg" — replace with a timestamp-based name while
  /// preserving the original extension.
  static String _generateFileName(String originalName, bool isVideo) {
    final ext = originalName.contains('.')
        ? originalName.split('.').last.toLowerCase()
        : (isVideo ? 'mp4' : 'jpg');
    final now = DateTime.now();
    final ts =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
    return 'upload_$ts.$ext';
  }
}
