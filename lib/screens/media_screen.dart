import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/app_logger.dart';
import '../services/media_service.dart';

enum UploadStatus { pending, uploading, uploaded, failed }

class _MediaItem {
  final XFile file;
  final bool isVideo;
  UploadStatus uploadStatus;
  String? uploadedUrl;

  _MediaItem({required this.file, required this.isVideo})
      : uploadStatus = UploadStatus.pending;
}

class MediaScreen extends StatefulWidget {
  final String authToken;

  const MediaScreen({super.key, required this.authToken});

  @override
  State<MediaScreen> createState() => _MediaScreenState();
}

class _MediaScreenState extends State<MediaScreen> {
  final ImagePicker _picker = ImagePicker();
  final MediaService _mediaService = MediaService();
  final List<_MediaItem> _mediaItems = [];
  bool _isUploading = false;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        imageQuality: 85,
      );
      if (file != null && mounted) {
        setState(() {
          _mediaItems.insert(0, _MediaItem(file: file, isVideo: false));
        });
      }
    } catch (e) {
      if (!mounted) return;
      _showError('Could not pick image. Please check permissions.');
    }
  }

  Future<void> _pickVideo(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickVideo(source: source);
      if (file != null && mounted) {
        setState(() {
          _mediaItems.insert(0, _MediaItem(file: file, isVideo: true));
        });
      }
    } catch (e) {
      if (!mounted) return;
      _showError('Could not pick video. Please check permissions.');
    }
  }

  Future<void> _uploadAll() async {
    if (_isUploading) return;
    setState(() => _isUploading = true);

    final pending = _mediaItems
        .where((i) =>
            i.uploadStatus == UploadStatus.pending ||
            i.uploadStatus == UploadStatus.failed)
        .toList();

    for (final item in pending) {
      setState(() => item.uploadStatus = UploadStatus.uploading);
      final result = await _mediaService.uploadFile(
        item.file,
        item.isVideo,
        widget.authToken,
      );
      if (!mounted) return;
      setState(() {
        if (result.success) {
          item.uploadStatus = UploadStatus.uploaded;
          item.uploadedUrl = result.url;
        } else {
          item.uploadStatus = UploadStatus.failed;
        }
      });
    }

    if (mounted) setState(() => _isUploading = false);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  void _showPickerSheet() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                'Add Media',
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _PickerOption(
                icon: Icons.photo_library_outlined,
                label: 'Photo from Gallery',
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
              _PickerOption(
                icon: Icons.camera_alt_outlined,
                label: 'Take Photo',
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              _PickerOption(
                icon: Icons.video_library_outlined,
                label: 'Video from Gallery',
                onTap: () {
                  Navigator.pop(ctx);
                  _pickVideo(ImageSource.gallery);
                },
              ),
              _PickerOption(
                icon: Icons.videocam_outlined,
                label: 'Record Video',
                onTap: () {
                  Navigator.pop(ctx);
                  _pickVideo(ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _removeItem(int index) {
    setState(() => _mediaItems.removeAt(index));
  }

  void _showLogs() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final entries = AppLogger.entries;
          return DraggableScrollableSheet(
            initialChildSize: 0.6,
            maxChildSize: 0.92,
            minChildSize: 0.3,
            expand: false,
            builder: (_, scrollController) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
                  child: Row(
                    children: [
                      const Icon(Icons.terminal, size: 20),
                      const SizedBox(width: 8),
                      const Text('Logs', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          AppLogger.clear();
                          setModalState(() {});
                        },
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: entries.isEmpty
                      ? const Center(child: Text('No logs yet'))
                      : ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          itemCount: entries.length,
                          itemBuilder: (_, i) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Text(
                              entries[i].formatted,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasPending = _mediaItems.any((i) =>
        i.uploadStatus == UploadStatus.pending ||
        i.uploadStatus == UploadStatus.failed);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Media'),
        actions: [
          IconButton(
            icon: const Icon(Icons.terminal),
            tooltip: 'View logs',
            onPressed: _showLogs,
          ),
          if (_mediaItems.isNotEmpty)
            _isUploading
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : TextButton.icon(
                    onPressed: hasPending ? _uploadAll : null,
                    icon: const Icon(Icons.cloud_upload_outlined),
                    label: const Text('Upload'),
                  ),
        ],
      ),
      body: _mediaItems.isEmpty
          ? _EmptyState(onAdd: _showPickerSheet)
          : GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemCount: _mediaItems.length,
              itemBuilder: (ctx, index) {
                final item = _mediaItems[index];
                return _MediaTile(
                  item: item,
                  onDelete: item.uploadStatus == UploadStatus.uploading
                      ? null
                      : () => _removeItem(index),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showPickerSheet,
        tooltip: 'Add media',
        child: const Icon(Icons.add_a_photo),
      ),
    );
  }
}

class _MediaTile extends StatelessWidget {
  final _MediaItem item;
  final VoidCallback? onDelete;

  const _MediaTile({required this.item, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: item.isVideo
              ? Container(
                  color: Colors.black87,
                  child: const Center(
                    child: Icon(Icons.play_circle_outline,
                        color: Colors.white, size: 40),
                  ),
                )
              : Image.file(
                  File(item.file.path),
                  fit: BoxFit.cover,
                ),
        ),
        if (item.isVideo)
          const Positioned(
            bottom: 4,
            left: 4,
            child: Icon(Icons.videocam, color: Colors.white, size: 16),
          ),
        if (item.uploadStatus == UploadStatus.uploading)
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Container(
              color: Colors.black45,
              child: const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            ),
          ),
        if (item.uploadStatus == UploadStatus.uploaded)
          Positioned(
            bottom: 4,
            right: 4,
            child: Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.green,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 14),
            ),
          ),
        if (item.uploadStatus == UploadStatus.failed)
          Positioned(
            bottom: 4,
            right: 4,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red[700],
              ),
              child: const Icon(Icons.refresh, color: Colors.white, size: 14),
            ),
          ),
        if (onDelete != null)
          Positioned(
            top: 2,
            right: 2,
            child: GestureDetector(
              onTap: onDelete,
              child: Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black54,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 14),
              ),
            ),
          ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.perm_media_outlined,
              size: 80,
              color: theme.colorScheme.outlineVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No media yet',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add photos and videos to share with the community',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_a_photo),
              label: const Text('Add Media'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PickerOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PickerOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(label),
      onTap: onTap,
    );
  }
}
