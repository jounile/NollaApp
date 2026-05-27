import 'package:flutter/material.dart';
import '../models/profile.dart';
import '../services/profile_service.dart';

class HomeScreen extends StatefulWidget {
  final String username;
  final String authToken;
  final ValueChanged<int>? onNavigate;

  const HomeScreen({
    super.key,
    required this.username,
    required this.authToken,
    this.onNavigate,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Profile? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final result = await ProfileService.fetchProfile(widget.authToken);
    if (!mounted) return;
    if (result.success && result.profile != null) {
      setState(() => _profile = result.profile);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'nolla.net',
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Skateboarding Community',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 40),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.waving_hand,
                        size: 40,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Welcome back,',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                      Text(
                        widget.username,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                      if (_profile != null) ...[
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _StatItem(
                              label: 'Followers',
                              count: _profile!.followerCount,
                              onColor: theme.colorScheme.onPrimaryContainer,
                              theme: theme,
                            ),
                            _StatItem(
                              label: 'Following',
                              count: _profile!.followingCount,
                              onColor: theme.colorScheme.onPrimaryContainer,
                              theme: theme,
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                _FeatureCard(
                  icon: Icons.dynamic_feed_outlined,
                  title: 'Feed',
                  description: 'See the latest posts from the community',
                  color: theme.colorScheme.primaryContainer.withOpacity(0.5),
                  onColor: theme.colorScheme.onSurface,
                  onTap: widget.onNavigate != null ? () => widget.onNavigate!(1) : null,
                ),
                const SizedBox(height: 12),
                _FeatureCard(
                  icon: Icons.location_on_outlined,
                  title: 'Spots',
                  description: 'Discover places near you on the map',
                  color: theme.colorScheme.secondaryContainer,
                  onColor: theme.colorScheme.onSecondaryContainer,
                  onTap: widget.onNavigate != null ? () => widget.onNavigate!(2) : null,
                ),
                const SizedBox(height: 12),
                _FeatureCard(
                  icon: Icons.perm_media_outlined,
                  title: 'Media',
                  description: 'Share photos and videos with the community',
                  color: theme.colorScheme.tertiaryContainer,
                  onColor: theme.colorScheme.onTertiaryContainer,
                  onTap: widget.onNavigate != null ? () => widget.onNavigate!(3) : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final int count;
  final Color onColor;
  final ThemeData theme;

  const _StatItem({
    required this.label,
    required this.count,
    required this.onColor,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$count',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: onColor,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(color: onColor.withOpacity(0.7)),
        ),
      ],
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final Color onColor;
  final VoidCallback? onTap;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 32, color: onColor),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: onColor,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(color: onColor, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
