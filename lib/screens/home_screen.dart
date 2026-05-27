import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  final String username;
  final ValueChanged<int>? onNavigate;

  const HomeScreen({super.key, required this.username, this.onNavigate});

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
                    borderRadius: const BorderRadius.circular(16),
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
                        username,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                _FeatureCard(
                  icon: Icons.location_on_outlined,
                  title: 'Spots',
                  description: 'Discover places near you on the map',
                  color: theme.colorScheme.secondaryContainer,
                  onColor: theme.colorScheme.onSecondaryContainer,
                  onTap: onNavigate != null ? () => onNavigate!(2) : null,
                ),
                const SizedBox(height: 12),
                _FeatureCard(
                  icon: Icons.perm_media_outlined,
                  title: 'Media',
                  description: 'Share photos and videos with the community',
                  color: theme.colorScheme.tertiaryContainer,
                  onColor: theme.colorScheme.onTertiaryContainer,
                  onTap: onNavigate != null ? () => onNavigate!(3) : null,
                ),
              ],
            ),
          ),
        ),
      ),
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
      borderRadius: const BorderRadius.circular(12),
      child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.circular(12),
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
