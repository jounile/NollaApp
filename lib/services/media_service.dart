import 'dart:async';
import 'dart:convert';
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
  static const String _uploadUrl = 'https://nolla.net/media/api/upload';

  Future<UploadResult> uploadFile(
    XFile file,
    bool isVideo,
    String authToken,
  ) async {
    final fileName = file.path.split('/').last;
    final contentType = isVideo ? 'video' : 'image';
    AppLogger.log('Upload started: $fileName ($contentType)');

    try {
      final request = http.MultipartRequest('POST', Uri.parse(_uploadUrl));
      request.headers['Authorization'] = 'Bearer $authToken';
      request.fields['content_type'] = contentType;
      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      final streamed = await request.send().timeout(const Duration(minutes: 5));
      final response = await http.Response.fromStream(streamed);

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
}
