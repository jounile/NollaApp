import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../models/media_item.dart';
import '../services/app_logger.dart';
import '../services/feed_service.dart';
import '../services/social_service.dart';
import '../widgets/comments_sheet.dart';
import 'user_profile_screen.dart';

class FeedScreen extends StatefulWidget {
  final String username;
  final String authToken;

  const FeedScreen({super.key, required this.username, required this.authToken});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final List<MediaItem> _items = [];
  final Set<int> _likingIds = {};
  final Set<int> _expandedIds = {};
  bool _isLoading = true;
  bool _isFetchingMore = false;
  bool _hasMore = false;
  int _page = 1;
  String? _error;
  int? _selectedMediatypeId;
  int? _serverTotal;

  @override
  void initState() {
    super.initState();
    _loadFeed(refresh: true);
  }

  Future<void> _loadFeed({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _isLoading = true;
        _page = 1;
        _error = null;
        _serverTotal = null;
      });
    }
    final result = await FeedService.fetchFeed(widget.authToken, page: _page);
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _isFetchingMore = false;
      if (result.success) {
        if (refresh) _items.clear();
        _items.addAll(result.items);
        _hasMore = result.hasMore;
        if (result.total != null) _serverTotal = result.total;
      } else {
        _error = result.message;
      }
    });
  }

  // -1 is a sentinel for "Other" (items with null mediatypeId)
  static const int _otherFilterId = -1;

  List<MediaItem> get _filteredItems {
    if (_selectedMediatypeId == null) return _items;
    if (_selectedMediatypeId == _otherFilterId) {
      return _items.where((e) => e.mediatypeId == null).toList();
    }
    return _items.where((e) => e.mediatypeId == _selectedMediatypeId).toList();
  }

  List<int> get _availableMediatypeIds {
    final ids = _items.map((e) => e.mediatypeId).whereType<int>().toSet().toList()..sort();
    return ids;
  }

  bool get _hasOtherItems => _items.any((e) => e.mediatypeId == null);

  int get _displayCount => _selectedMediatypeId == null
      ? _serverTotal ?? _items.length
      : _filteredItems.length;

  String _mediatypeLabel(int id) {
    switch (id) {
      case 1: return 'Photos (1)';
      case 5: return 'Video (5)';
      case 6: return 'Video (6)';
      default: return 'Type $id';
    }
  }

  Future<void> _loadMore() async {
    if (_isFetchingMore || !_hasMore) return;
    setState(() {
      _isFetchingMore = true;
      _page++;
    });
    await _loadFeed();
  }

  void _toggleLike(int index) {
    final item = _items[index];
    if (_likingIds.contains(item.id)) return;
    final optimistic = item.copyWith(
      isLikedByMe: !item.isLikedByMe,
      likeCount: item.likeCount + (item.isLikedByMe ? -1 : 1),
    );
    setState(() {
      _items[index] = optimistic;
      _likingIds.add(item.id);
    });

    final future = optimistic.isLikedByMe
        ? SocialService.likeMedia(item.id, widget.authToken)
        : SocialService.unlikeMedia(item.id, widget.authToken);

    future.then((result) {
      if (!mounted) return;
      setState(() => _likingIds.remove(item.id));
      if (result.success) {
        if (result.newCount != null) {
          final i = _items.indexWhere((e) => e.id == item.id);
          if (i != -1) setState(() => _items[i] = _items[i].copyWith(likeCount: result.newCount!));
        }
      } else {
        final i = _items.indexWhere((e) => e.id == item.id);
        if (i != -1) setState(() => _items[i] = item);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message ?? 'Could not update like')),
        );
      }
    });
  }

  Future<void> _openComments(int index) async {
    final item = _items[index];
    final newCount = await showCommentsSheet(
      context,
      item.id,
      item.commentCount,
      widget.authToken,
      currentUsername: widget.username,
    );
    if (!mounted) return;
    if (newCount != null && newCount != item.commentCount) {
      final i = _items.indexWhere((e) => e.id == item.id);
      if (i != -1) setState(() => _items[i] = _items[i].copyWith(commentCount: newCount));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feed'),
        actions: [
          IconButton(
            icon: const Icon(Icons.terminal),
            tooltip: 'View logs',
            onPressed: () => showLogViewer(context, filter: const ['[FeedService]', '[SocialService]', '[CommentService]']),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => _loadFeed(refresh: true),
          ),
        ],
      ),
      body: Column(
        children: [
          if (!_isLoading && (_availableMediatypeIds.isNotEmpty || _hasOtherItems))
            SizedBox(
              height: 48,
              child: Row(
                children: [
                  Expanded(
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: const Text('All'),
                            selected: _selectedMediatypeId == null,
                            onSelected: (_) => setState(() => _selectedMediatypeId = null),
                          ),
                        ),
                        ..._availableMediatypeIds.map((id) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(_mediatypeLabel(id)),
                                selected: _selectedMediatypeId == id,
                                onSelected: (_) => setState(() => _selectedMediatypeId = id),
                              ),
                            )),
                        if (_hasOtherItems)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: const Text('Other'),
                              selected: _selectedMediatypeId == _otherFilterId,
                              onSelected: (_) => setState(() => _selectedMediatypeId = _otherFilterId),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (_selectedMediatypeId == null)
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Text(
                        '$_displayCount',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ),
                ],
              ),
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null && _items.isEmpty
                    ? _ErrorView(message: _error!, onRetry: () => _loadFeed(refresh: true))
                    : _items.isEmpty
                        ? _EmptyView(username: widget.username, theme: theme)
                        : RefreshIndicator(
                            onRefresh: () => _loadFeed(refresh: true),
                            child: Builder(builder: (context) {
                              final filtered = _filteredItems;
                              return ListView.builder(
                                itemCount: filtered.length + (_hasMore ? 1 : 0),
                                itemBuilder: (ctx, i) {
                                  if (i == filtered.length) {
                                    _loadMore();
                                    return const Padding(
                                      padding: EdgeInsets.all(16),
                                      child: Center(child: CircularProgressIndicator()),
                                    );
                                  }
                                  final item = filtered[i];
                                  final srcIndex = _items.indexOf(item);
                                  return _MediaCard(
                                    item: item,
                                    onLike: () => _toggleLike(srcIndex),
                                    onComments: () => _openComments(srcIndex),
                                    isLiking: _likingIds.contains(item.id),
                                    isExpanded: _expandedIds.contains(item.id),
                                    onExpandToggle: () => setState(() {
                                      if (_expandedIds.contains(item.id)) {
                                        _expandedIds.remove(item.id);
                                      } else {
                                        _expandedIds.add(item.id);
                                      }
                                    }),
                                    theme: theme,
                                    authToken: widget.authToken,
                                    currentUsername: widget.username,
                                  );
                                },
                              );
                            }),
                          ),
          ),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final String username;
  final ThemeData theme;

  const _EmptyView({required this.username, required this.theme});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(Icons.waving_hand, size: 40, color: theme.colorScheme.onPrimaryContainer),
                const SizedBox(height: 12),
                Text('Welcome back,',
                    style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onPrimaryContainer)),
                Text(username,
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onPrimaryContainer)),
              ],
            ),
          ),
          const SizedBox(height: 40),
          Icon(Icons.dynamic_feed_outlined, size: 64, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(height: 16),
          Text('No posts yet', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Be the first to share a photo or video from a spot!',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off, size: 48, color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _MediaCard extends StatelessWidget {
  final MediaItem item;
  final VoidCallback onLike;
  final VoidCallback onComments;
  final bool isLiking;
  final bool isExpanded;
  final VoidCallback onExpandToggle;
  final ThemeData theme;
  final String authToken;
  final String currentUsername;

  const _MediaCard({
    required this.item,
    required this.onLike,
    required this.onComments,
    required this.isLiking,
    required this.isExpanded,
    required this.onExpandToggle,
    required this.theme,
    required this.authToken,
    required this.currentUsername,
  });

  @override
  Widget build(BuildContext context) {
    final displayUrl = item.feedUrl;
    final hasLongDescription = item.description != null && item.description!.isNotEmpty;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (displayUrl.isNotEmpty)
            GestureDetector(
              onTap: () => _openMediaView(context, item, authToken),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  displayUrl,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.medium,
                  loadingBuilder: (ctx, child, progress) => progress == null
                      ? child
                      : Container(
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: const Center(child: CircularProgressIndicator()),
                        ),
                  errorBuilder: (_, __, ___) => Container(
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: const Center(child: Icon(Icons.broken_image_outlined, size: 40)),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: Row(
              children: [
                GestureDetector(
                  onTap: item.uploaderUsername.isNotEmpty
                      ? () => Navigator.push<void>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => UserProfileScreen(
                                username: item.uploaderUsername,
                                authToken: authToken,
                                currentUsername: currentUsername,
                              ),
                            ),
                          )
                      : null,
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Text(
                      item.uploaderDisplayName.isNotEmpty
                          ? item.uploaderDisplayName[0].toUpperCase()
                          : '?',
                      style: TextStyle(fontSize: 14, color: theme.colorScheme.onPrimaryContainer),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: item.uploaderUsername.isNotEmpty
                        ? () => Navigator.push<void>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => UserProfileScreen(
                                  username: item.uploaderUsername,
                                  authToken: authToken,
                                  currentUsername: currentUsername,
                                ),
                              ),
                            )
                        : null,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.uploaderDisplayName.isNotEmpty ? item.uploaderDisplayName : item.uploaderUsername,
                          style: theme.textTheme.labelLarge,
                        ),
                        if (item.spotName != null)
                          Text(
                            item.spotName!,
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                        if (item.createdAt != null)
                          Text(
                            _relativeTime(item.createdAt),
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                      ],
                    ),
                  ),
                ),
                if (item.mediaType == 'video')
                  Icon(Icons.videocam_outlined, size: 18, color: theme.colorScheme.onSurfaceVariant),
              ],
            ),
          ),
          if (hasLongDescription)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.description!,
                    style: theme.textTheme.bodyMedium,
                    maxLines: isExpanded ? null : 2,
                    overflow: isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                  ),
                  if (!isExpanded)
                    GestureDetector(
                      onTap: onExpandToggle,
                      child: Text(
                        'more',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 12, 8),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    item.isLikedByMe ? Icons.favorite : Icons.favorite_border,
                    color: item.isLikedByMe ? theme.colorScheme.error : null,
                  ),
                  onPressed: isLiking ? null : onLike,
                  iconSize: 20,
                ),
                if (item.likeCount > 0)
                  Text('${item.likeCount}', style: theme.textTheme.bodySmall),
                const SizedBox(width: 8),
                InkWell(
                  onTap: onComments,
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Row(
                      children: [
                        Icon(Icons.comment_outlined, size: 20, color: theme.colorScheme.onSurfaceVariant),
                        if (item.commentCount > 0) ...[
                          const SizedBox(width: 4),
                          Text('${item.commentCount}', style: theme.textTheme.bodySmall),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

void _openMediaView(BuildContext context, MediaItem item, String authToken) {
  if (item.mediaType == 'video') {
    Navigator.of(context).push<void>(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => _VideoPlayerView(url: item.viewUrl, rawUrl: item.url, authToken: authToken),
    ));
  } else {
    showDialog<void>(
      context: context,
      builder: (_) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: Image.network(
                  item.viewUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (ctx, child, progress) => progress == null
                      ? child
                      : const Center(child: CircularProgressIndicator(color: Colors.white)),
                  errorBuilder: (_, __, ___) =>
                      const Center(child: Icon(Icons.broken_image_outlined, size: 48, color: Colors.white54)),
                ),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VideoPlayerView extends StatefulWidget {
  final String url;
  final String rawUrl;
  final String authToken;
  const _VideoPlayerView({required this.url, required this.rawUrl, required this.authToken});

  @override
  State<_VideoPlayerView> createState() => _VideoPlayerViewState();
}

class _VideoPlayerViewState extends State<_VideoPlayerView> {
  late VideoPlayerController _controller;
  bool _initialized = false;
  String? _error;
  bool _triedFallback = false;

  @override
  void initState() {
    super.initState();
    _startPlayback(widget.url);
  }

  void _startPlayback(String url) {
    AppLogger.log('[VideoPlayer] loading $url');
    _controller = VideoPlayerController.networkUrl(
      Uri.parse(url),
      // web: <video> element cannot send custom headers, so omit them and rely
      // on the media files being publicly accessible static assets.
      httpHeaders: kIsWeb ? {} : {'Authorization': 'Bearer ${widget.authToken}'},
    )
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() => _initialized = true);
        _controller.play();
      }).catchError((Object e) {
        AppLogger.log('[VideoPlayer] failed url=$url error=$e');
        if (!mounted) return;
        if (!_triedFallback && widget.rawUrl.isNotEmpty && widget.rawUrl != url) {
          _triedFallback = true;
          AppLogger.log('[VideoPlayer] retrying with rawUrl=${widget.rawUrl}');
          _controller.dispose();
          _startPlayback(widget.rawUrl);
        } else {
          setState(() => _error = 'Could not load video');
        }
      });
    _controller.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            if (_initialized)
              Center(
                child: GestureDetector(
                  onTap: () {
                    _controller.value.isPlaying ? _controller.pause() : _controller.play();
                  },
                  child: AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: VideoPlayer(_controller),
                  ),
                ),
              )
            else if (_error != null)
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.videocam_off, color: Colors.white54, size: 48),
                    const SizedBox(height: 12),
                    Text(_error!, style: const TextStyle(color: Colors.white70)),
                  ],
                ),
              )
            else
              const Center(child: CircularProgressIndicator(color: Colors.white)),
            if (_initialized && !_controller.value.isPlaying)
              Center(
                child: IgnorePointer(
                  child: Icon(Icons.play_circle_outline, size: 72, color: Colors.white.withOpacity(0.7)),
                ),
              ),
            if (_initialized)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: VideoProgressIndicator(
                  _controller,
                  allowScrubbing: true,
                  colors: const VideoProgressColors(
                    playedColor: Colors.white,
                    bufferedColor: Colors.white38,
                    backgroundColor: Colors.white12,
                  ),
                ),
              ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _relativeTime(String? iso) {
  if (iso == null) return '';
  final dt = DateTime.tryParse(iso);
  if (dt == null) return '';
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inHours < 1) return '${diff.inMinutes}m ago';
  if (diff.inDays < 1) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return '${dt.day}/${dt.month}/${dt.year}';
}
