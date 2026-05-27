import 'package:flutter/material.dart';
import '../models/media_item.dart';
import '../services/app_logger.dart';
import '../services/feed_service.dart';
import '../services/social_service.dart';
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
  bool _isLoading = true;
  bool _isFetchingMore = false;
  bool _hasMore = false;
  bool _isMockData = false;
  int _page = 1;
  String? _error;

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
        _isMockData = result.isMockData;
      } else {
        _error = result.message;
      }
    });
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
            onPressed: () => showLogViewer(context, filter: const ['[FeedService]', '[SocialService]']),
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
          if (_isMockData)
            MaterialBanner(
              content: const Text('Demo mode — showing sample data (web preview)'),
              leading: const Icon(Icons.info_outline),
              actions: [TextButton(onPressed: () => setState(() => _isMockData = false), child: const Text('Dismiss'))],
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
                      child: ListView.builder(
                        itemCount: _items.length + (_hasMore ? 1 : 0),
                        itemBuilder: (ctx, i) {
                          if (i == _items.length) {
                            _loadMore();
                            return const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
                          return _MediaCard(
                            item: _items[i],
                            onLike: () => _toggleLike(i),
                            isLiking: _likingIds.contains(_items[i].id),
                            theme: theme,
                            authToken: widget.authToken,
                          );
                        },
                      ),
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
              borderRadius: const BorderRadius.circular(16),
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
  final bool isLiking;
  final ThemeData theme;
  final String authToken;

  const _MediaCard({required this.item, required this.onLike, required this.isLiking, required this.theme, required this.authToken});

  @override
  Widget build(BuildContext context) {
    final displayUrl = item.thumbnailUrl ?? item.url;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (displayUrl.isNotEmpty)
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                displayUrl,
                fit: BoxFit.cover,
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
          if (item.description != null && item.description!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Text(item.description!, style: theme.textTheme.bodyMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
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
                Icon(Icons.comment_outlined, size: 20, color: theme.colorScheme.onSurfaceVariant),
                if (item.commentCount > 0) ...[
                  const SizedBox(width: 4),
                  Text('${item.commentCount}', style: theme.textTheme.bodySmall),
                ],
              ],
            ),
          ),
        ],
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
