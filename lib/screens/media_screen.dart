import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/media_item.dart';
import '../services/app_logger.dart';
import '../services/media_service.dart';
import '../services/profile_service.dart';

enum UploadStatus { pending, uploading, uploaded, failed }

class _PendingMediaItem {
  final XFile file;
  final bool isVideo;
  final int fileSize;
  UploadStatus uploadStatus;
  String? uploadedUrl;

  _PendingMediaItem({required this.file, required this.isVideo, required this.fileSize})
      : uploadStatus = UploadStatus.pending;
}

String _formatBytes(int bytes) {
  if (bytes >= 1000000) return '${(bytes / 1000000).toStringAsFixed(1)} MB';
  return '${(bytes / 1000).round()} KB';
}

class MediaScreen extends StatefulWidget {
  final String authToken;
  final String username;

  const MediaScreen({super.key, required this.authToken, required this.username});

  @override
  State<MediaScreen> createState() => _MediaScreenState();
}

class _MediaScreenState extends State<MediaScreen> {
  final ImagePicker _picker = ImagePicker();
  final MediaService _mediaService = MediaService();
  final List<_PendingMediaItem> _pendingItems = [];
  List<MediaItem> _existingMedia = [];
  bool _isUploading = false;
  bool _isLoadingExisting = true;

  @override
  void initState() {
    super.initState();
    _loadExistingMedia();
  }

  Future<void> _loadExistingMedia() async {
    final media = await ProfileService.fetchUserMedia(widget.username, widget.authToken);
    if (!mounted) return;
    setState(() {
      _existingMedia = media;
      _isLoadingExisting = false;
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      if (file != null && mounted) {
        final size = await file.length();
        setState(() {
          _pendingItems.insert(0, _PendingMediaItem(file: file, isVideo: false, fileSize: size));
        });
      }
    } catch (e) {
      AppLogger.log('[MediaScreen] _pickImage error: $e');
      if (!mounted) return;
      final msg = e.toString();
      if (msg.contains('permission') || msg.contains('Permission')) {
        _showError('Permission denied. Please allow photo access.');
      } else if (msg.contains('cancel') || msg.contains('Cancel') || msg.contains('abort') || msg.contains('Abort')) {
        // User cancelled the picker — not an error
      } else {
        _showError('Could not pick image: ${msg.length > 80 ? msg.substring(0, 80) : msg}');
      }
    }
  }

  Future<void> _pickVideo(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickVideo(source: source);
      if (file != null && mounted) {
        final size = await file.length();
        setState(() {
          _pendingItems.insert(0, _PendingMediaItem(file: file, isVideo: true, fileSize: size));
        });
      }
    } catch (e) {
      AppLogger.log('[MediaScreen] _pickVideo error: $e');
      if (!mounted) return;
      final msg = e.toString();
      if (msg.contains('permission') || msg.contains('Permission')) {
        _showError('Permission denied. Please allow video access.');
      } else if (msg.contains('cancel') || msg.contains('Cancel') || msg.contains('abort') || msg.contains('Abort')) {
        // User cancelled the picker — not an error
      } else {
        _showError('Could not pick video: ${msg.length > 80 ? msg.substring(0, 80) : msg}');
      }
    }
  }

  Future<void> _uploadAll() async {
    if (_isUploading) return;
    setState(() => _isUploading = true);

    final pending = _pendingItems
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
      if (!result.success) _showError(result.message);
    }

    if (mounted) setState(() => _isUploading = false);

    // Refresh existing media after uploads complete;
    // remove successfully-uploaded pending items so the grid doesn't
    // show duplicates (local thumb + server entry side-by-side).
    if (pending.any((i) => i.uploadStatus == UploadStatus.uploaded)) {
      await _loadExistingMedia();
      if (mounted) {
        setState(() {
          _pendingItems.removeWhere(
              (i) => i.uploadStatus == UploadStatus.uploaded);
        });
      }
    }
  }

  void _retryItem(int index) {
    setState(() => _pendingItems[index].uploadStatus = UploadStatus.pending);
    _uploadAll();
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
                  color: Theme.of(ctx).colorScheme.outlineVariant,
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

  void _removePendingItem(int index) {
    setState(() => _pendingItems.removeAt(index));
  }

  Future<void> _deleteExistingMedia(int index) async {
    final item = _existingMedia[index];
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this photo?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final success = await ProfileService.deleteMedia(item.id, widget.authToken);
    if (!mounted) return;
    if (success) {
      setState(() => _existingMedia.removeAt(index));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo deleted')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete photo')),
      );
    }
  }

  void _showLogs() => showLogViewer(context, filter: const ['[MediaService]']);

  @override
  Widget build(BuildContext context) {
    final hasPending = _pendingItems.any((i) =>
        i.uploadStatus == UploadStatus.pending ||
        i.uploadStatus == UploadStatus.failed);
    final totalItems = _existingMedia.length + _pendingItems.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Media'),
        actions: [
          IconButton(
            icon: const Icon(Icons.terminal),
            tooltip: 'View logs',
            onPressed: _showLogs,
          ),
          if (_pendingItems.isNotEmpty)
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
      body: _isLoadingExisting
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadExistingMedia,
              child: totalItems == 0
                  ? ListView(
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.7,
                          child: _EmptyState(onAdd: _showPickerSheet),
                        ),
                      ],
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(8),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 4,
                        mainAxisSpacing: 4,
                      ),
                      itemCount: totalItems,
                      itemBuilder: (ctx, index) {
                        // Existing media items first
                        if (index < _existingMedia.length) {
                          final item = _existingMedia[index];
                          final url = item.thumbnailUrl ?? item.url;
                          return _ExistingMediaTile(
                            url: url,
                            isVideo: item.mediaType == 'video',
                            onLongPress: () => _deleteExistingMedia(index),
                            onRefresh: _loadExistingMedia,
                          );
                        }
                        // Pending upload items
                        final pendingIndex = index - _existingMedia.length;
                        final item = _pendingItems[pendingIndex];
                        return _PendingMediaTile(
                          item: item,
                          onDelete: item.uploadStatus == UploadStatus.uploading
                              ? null
                              : () => _removePendingItem(pendingIndex),
                          onRetry: item.uploadStatus == UploadStatus.failed
                              ? () => _retryItem(pendingIndex)
                              : null,
                        );
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showPickerSheet,
        tooltip: 'Add media',
        child: const Icon(Icons.add_a_photo),
      ),
    );
  }
}

class _ExistingMediaTile extends StatefulWidget {
  final String url;
  final bool isVideo;
  final VoidCallback onLongPress;
  final VoidCallback? onRefresh;

  const _ExistingMediaTile({
    required this.url,
    required this.isVideo,
    required this.onLongPress,
    this.onRefresh,
  });

  @override
  State<_ExistingMediaTile> createState() => _ExistingMediaTileState();
}

class _ExistingMediaTileState extends State<_ExistingMediaTile> {
  int _retryCount = 0;

  void _onImageError() {
    // Thumbnail may still be generating — retry a few times with a delay.
    if (_retryCount < 3) {
      _retryCount++;
      Future.delayed(Duration(seconds: _retryCount * 2), () {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onLongPress: widget.onLongPress,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: widget.url.isNotEmpty
                ? Image.network(
                    widget.url,
                    fit: BoxFit.cover,
                    key: ValueKey('${widget.url}_$_retryCount'),
                    errorBuilder: (_, __, ___) {
                      _onImageError();
                      return Container(
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: _retryCount < 3
                            ? const Center(
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.broken_image_outlined),
                      );
                    },
                  )
                : Container(color: theme.colorScheme.surfaceContainerHighest),
          ),
          if (widget.isVideo)
            const Positioned(
              bottom: 4,
              left: 4,
              child: Icon(Icons.videocam, color: Colors.white, size: 16),
            ),
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
        ],
      ),
    );
  }
}

class _PendingMediaTile extends StatelessWidget {
  final _PendingMediaItem item;
  final VoidCallback? onDelete;
  final VoidCallback? onRetry;

  const _PendingMediaTile({required this.item, required this.onDelete, this.onRetry});

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
              : _ThumbnailImage(file: item.file),
        ),
        if (item.isVideo)
          const Positioned(
            bottom: 4,
            left: 4,
            child: Icon(Icons.videocam, color: Colors.white, size: 16),
          ),
        Positioned(
          top: 4,
          left: 4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              _formatBytes(item.fileSize),
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
          ),
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
            child: GestureDetector(
              onTap: onRetry,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).colorScheme.error,
                ),
                child: const Icon(Icons.error_outline, color: Colors.white, size: 14),
              ),
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

class _ThumbnailImage extends StatefulWidget {
  final XFile file;

  const _ThumbnailImage({required this.file});

  @override
  State<_ThumbnailImage> createState() => _ThumbnailImageState();
}

class _ThumbnailImageState extends State<_ThumbnailImage> {
  late final Future<Uint8List> _bytesFuture;

  @override
  void initState() {
    super.initState();
    _bytesFuture = widget.file.readAsBytes();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: _bytesFuture,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Image.memory(
            snapshot.data!,
            fit: BoxFit.cover,
          );
        }
        return const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      },
    );
  }
}
