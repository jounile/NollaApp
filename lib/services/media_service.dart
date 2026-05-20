import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

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
    try {
      final request = http.MultipartRequest('POST', Uri.parse(_uploadUrl));
      request.headers['Authorization'] = 'Bearer $authToken';
      request.fields['content_type'] = isVideo ? 'video' : 'image';
      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      final streamed = await request.send().timeout(const Duration(minutes: 5));
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return UploadResult(
          success: true,
          message: 'Uploaded',
          url: data['url'] as String?,
        );
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>? ?? {};
      return UploadResult(
        success: false,
        message: data['message'] as String? ?? 'Upload failed',
      );
    } on TimeoutException {
      return const UploadResult(
        success: false,
        message: 'Upload timed out. Please try again.',
      );
    } catch (_) {
      return const UploadResult(
        success: false,
        message: 'Network error. Please check your connection.',
      );
    }
  }
}
