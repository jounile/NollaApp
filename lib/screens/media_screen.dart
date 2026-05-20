import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class MediaScreen extends StatefulWidget {
  const MediaScreen({super.key});

  @override
  State<MediaScreen> createState() => _MediaScreenState();
}

class _MediaScreenState extends State<MediaScreen> {
  final ImagePicker _picker = ImagePicker();
  final List<_MediaItem> _mediaItems = [];

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Media'),
        actions: [
          if (_mediaItems.isNotEmpty)
            TextButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Upload feature coming soon!')),
                );
              },
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
                  onDelete: () => _removeItem(index),
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

class _MediaItem {
  final XFile file;
  final bool isVideo;

  const _MediaItem({required this.file, required this.isVideo});
}

class _MediaTile extends StatelessWidget {
  final _MediaItem item;
  final VoidCallback onDelete;

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
