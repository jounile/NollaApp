import 'package:flutter/material.dart';
import '../models/public_profile.dart';
import '../models/spot.dart';
import '../models/media_item.dart';
import '../services/profile_service.dart';
import '../services/social_service.dart';
import '../utils/spot_utils.dart';
import 'spot_detail_screen.dart';

class UserProfileScreen extends StatefulWidget {
  final String username;
  final String authToken;
  final String? currentUsername;

  const UserProfileScreen({
    super.key,
    required this.username,
    required this.authToken,
    this.currentUsername,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> with SingleTickerProviderStateMixin {
  PublicProfile? _profile;
  List<Spot> _spots = [];
  List<MediaItem> _media = [];
  bool _isLoading = true;
  bool _isFollowing = false;
  String? _error;
  late final TabController _tabController;

  bool get _isOwnProfile => widget.currentUsername == widget.username;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final results = await Future.wait([
      ProfileService.fetchPublicProfile(widget.username, widget.authToken),
      ProfileService.fetchUserSpots(widget.username, widget.authToken),
      ProfileService.fetchUserMedia(widget.username, widget.authToken),
    ]);
    if (!mounted) return;
    final profileResult = results[0] as PublicProfileResult;
    setState(() {
      _isLoading = false;
      if (profileResult.success) {
        _profile = profileResult.profile;
        _spots = results[1] as List<Spot>;
        _media = results[2] as List<MediaItem>;
        _isFollowing = _profile?.isFollowedByMe ?? false;
      } else {
        _error = profileResult.message ?? 'Failed to load profile';
      }
    });
  }

  Future<void> _toggleFollow() async {
    final profile = _profile;
    if (profile == null || _isOwnProfile) return;

    final wasFollowing = _isFollowing;
    setState(() {
      _isFollowing = !wasFollowing;
      _profile = profile.copyWith(
        isFollowedByMe: !wasFollowing,
        followerCount: profile.followerCount + (wasFollowing ? -1 : 1),
      );
    });

    final result = wasFollowing
        ? await SocialService.unfollowUser(widget.username, widget.authToken)
        : await SocialService.followUser(widget.username, widget.authToken);

    if (!mounted) return;
    if (!result.success) {
      setState(() {
        _isFollowing = wasFollowing;
        _profile = profile.copyWith(
          isFollowedByMe: wasFollowing,
          followerCount: profile.followerCount,
        );
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message ?? 'Could not update follow status')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text('@${widget.username}')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorView(message: _error!, onRetry: _load)
              : _profile == null
                  ? const Center(child: Text('User not found'))
                  : NestedScrollView(
                      headerSliverBuilder: (_, __) => [
                        SliverToBoxAdapter(
                          child: _ProfileHeader(
                            profile: _profile!,
                            theme: theme,
                            isOwnProfile: _isOwnProfile,
                            isFollowing: _isFollowing,
                            onFollowToggle: _toggleFollow,
                          ),
                        ),
                        SliverPersistentHeader(
                          pinned: true,
                          delegate: _TabBarDelegate(
                            TabBar(
                              controller: _tabController,
                              tabs: [
                                Tab(text: 'Spots (${_spots.length})'),
                                Tab(text: 'Media (${_media.length})'),
                              ],
                            ),
                          ),
                        ),
                      ],
                      body: TabBarView(
                        controller: _tabController,
                        children: [
                          _SpotsList(
                            spots: _spots,
                            theme: theme,
                            authToken: widget.authToken,
                          ),
                          _MediaGrid(media: _media, theme: theme),
                        ],
                      ),
                    ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final PublicProfile profile;
  final ThemeData theme;
  final bool isOwnProfile;
  final bool isFollowing;
  final VoidCallback onFollowToggle;

  const _ProfileHeader({
    required this.profile,
    required this.theme,
    required this.isOwnProfile,
    required this.isFollowing,
    required this.onFollowToggle,
  });

  @override
  Widget build(BuildContext context) {
    final initials = profile.displayName.isNotEmpty ? profile.displayName[0].toUpperCase() : '?';
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: theme.colorScheme.primaryContainer,
            backgroundImage: profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty
                ? NetworkImage(profile.avatarUrl!)
                : null,
            child: profile.avatarUrl == null || profile.avatarUrl!.isEmpty
                ? Text(initials, style: TextStyle(fontSize: 28, color: theme.colorScheme.onPrimaryContainer))
                : null,
          ),
          const SizedBox(height: 12),
          Text(
            profile.displayName,
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          Text(
            '@${profile.username}',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          if (profile.bio != null && profile.bio!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(profile.bio!, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
          ],
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatChip(label: 'Spots', count: profile.spotCount, theme: theme),
              _StatChip(label: 'Media', count: profile.mediaCount, theme: theme),
              _StatChip(label: 'Followers', count: profile.followerCount, theme: theme),
              _StatChip(label: 'Following', count: profile.followingCount, theme: theme),
            ],
          ),
          if (!isOwnProfile) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: isFollowing
                  ? OutlinedButton(
                      onPressed: onFollowToggle,
                      child: const Text('Following'),
                    )
                  : FilledButton(
                      onPressed: onFollowToggle,
                      child: const Text('Follow'),
                    ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final int count;
  final ThemeData theme;

  const _StatChip({required this.label, required this.count, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('$count', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      ],
    );
  }
}

class _SpotsList extends StatelessWidget {
  final List<Spot> spots;
  final ThemeData theme;
  final String authToken;

  const _SpotsList({required this.spots, required this.theme, required this.authToken});

  @override
  Widget build(BuildContext context) {
    if (spots.isEmpty) {
      return const Center(child: Text('No spots added yet'));
    }
    return ListView.builder(
      itemCount: spots.length,
      itemBuilder: (_, i) {
        final s = spots[i];
        return ListTile(
          leading: Icon(spotTypeToIcon(s.type), color: theme.colorScheme.primary),
          title: Text(s.name),
          subtitle: Text(s.type),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push<void>(
            context,
            MaterialPageRoute(
              builder: (_) => SpotDetailScreen(
                spotId: s.id,
                spotName: s.name,
                authToken: authToken,
                spotType: s.type,
                spotDistance: s.distance,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MediaGrid extends StatelessWidget {
  final List<MediaItem> media;
  final ThemeData theme;

  const _MediaGrid({required this.media, required this.theme});

  @override
  Widget build(BuildContext context) {
    if (media.isEmpty) {
      return const Center(child: Text('No media uploaded yet'));
    }
    return GridView.builder(
      padding: const EdgeInsets.all(4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: media.length,
      itemBuilder: (_, i) {
        final item = media[i];
        final url = item.thumbnailUrl ?? item.url;
        return Stack(
          fit: StackFit.expand,
          children: [
            if (url.isNotEmpty)
              Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: const Icon(Icons.broken_image_outlined),
                ),
              )
            else
              Container(color: theme.colorScheme.surfaceContainerHighest),
            if (item.mediaType == 'video')
              const Positioned(
                right: 4,
                bottom: 4,
                child: Icon(Icons.videocam, size: 16, color: Colors.white),
              ),
          ],
        );
      },
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
            Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
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

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _TabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return ColoredBox(color: Theme.of(context).colorScheme.surface, child: tabBar);
  }

  @override
  bool shouldRebuild(_TabBarDelegate old) => old.tabBar != tabBar;
}
