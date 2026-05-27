import 'package:flutter/material.dart';
import '../models/spot_detail.dart';
import '../services/spot_service.dart';
import '../utils/spot_utils.dart';
import 'user_profile_screen.dart';

class SpotDetailScreen extends StatefulWidget {
  final int spotId;
  final String spotName;
  final String authToken;
  final String spotType;
  final double? spotDistance;

  const SpotDetailScreen({
    super.key,
    required this.spotId,
    required this.spotName,
    required this.authToken,
    this.spotType = 'place',
    this.spotDistance,
  });

  @override
  State<SpotDetailScreen> createState() => _SpotDetailScreenState();
}

class _SpotDetailScreenState extends State<SpotDetailScreen> {
  SpotDetail? _spot;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final result = await SpotService.fetchSpotDetail(widget.spotId, widget.authToken);
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (result.success) {
        _spot = result.spot;
      } else {
        _error = result.message ?? 'Failed to load spot';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(widget.spotName)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _spot != null
              ? _SpotDetailBody(spot: _spot!, theme: theme, authToken: widget.authToken)
              : _FallbackBody(
                  type: widget.spotType,
                  distance: widget.spotDistance,
                  error: _error ?? 'Failed to load spot',
                  onRetry: _load,
                  theme: theme,
                ),
    );
  }
}

class _FallbackBody extends StatelessWidget {
  final String type;
  final double? distance;
  final String error;
  final VoidCallback onRetry;
  final ThemeData theme;

  const _FallbackBody({
    required this.type,
    this.distance,
    required this.error,
    required this.onRetry,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _TypeBadge(type: type, theme: theme),
        if (distance != null) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.straighten, size: 16, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                formatDistance(distance!),
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ],
        const SizedBox(height: 16),
        Card(
          color: theme.colorScheme.errorContainer,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(Icons.cloud_off_outlined, color: theme.colorScheme.onErrorContainer, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    error,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onErrorContainer),
                  ),
                ),
                TextButton(
                  onPressed: onRetry,
                  child: Text('Retry', style: TextStyle(color: theme.colorScheme.onErrorContainer)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SpotDetailBody extends StatelessWidget {
  final SpotDetail spot;
  final ThemeData theme;
  final String authToken;

  const _SpotDetailBody({required this.spot, required this.theme, required this.authToken});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _TypeBadge(type: spot.type, theme: theme),
        const SizedBox(height: 16),
        if (spot.distance != null) ...[
          Row(
            children: [
              Icon(Icons.straighten, size: 16, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                formatDistance(spot.distance!),
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        if (spot.address != null && spot.address!.isNotEmpty) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.location_on_outlined, size: 16, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  spot.address!,
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        if (spot.createdBy != null && spot.createdBy!.isNotEmpty) ...[
          Row(
            children: [
              Icon(Icons.person_outline, size: 16, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => Navigator.push<void>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => UserProfileScreen(
                      username: spot.createdBy!,
                      authToken: authToken,
                    ),
                  ),
                ),
                child: Text(
                  'Added by ${spot.createdBy}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        if (spot.description != null && spot.description!.isNotEmpty) ...[
          Text('About', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(spot.description!, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 16),
        ],
        if (spot.tags.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: spot.tags
                .map((t) => Chip(label: Text(t), materialTapTargetSize: MaterialTapTargetSize.shrinkWrap))
                .toList(),
          ),
          const SizedBox(height: 16),
        ],
        if (spot.mediaUrls.isNotEmpty) ...[
          Text('Photos', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          SizedBox(
            height: 160,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: spot.mediaUrls.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (ctx, i) => GestureDetector(
                onTap: () => Navigator.push<void>(
                  ctx,
                  MaterialPageRoute(
                    builder: (_) => Scaffold(
                      backgroundColor: Colors.black,
                      appBar: AppBar(backgroundColor: Colors.transparent, foregroundColor: Colors.white),
                      body: Center(
                        child: InteractiveViewer(
                          child: Image.network(spot.mediaUrls[i], fit: BoxFit.contain),
                        ),
                      ),
                    ),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    spot.mediaUrls[i],
                    width: 160,
                    height: 160,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 160,
                      height: 160,
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: const Icon(Icons.broken_image_outlined),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final String type;
  final ThemeData theme;

  const _TypeBadge({required this.type, required this.theme});

  @override
  Widget build(BuildContext context) {
    final icon = spotTypeToIcon(type);
    final label = type.isEmpty ? 'Place' : type[0].toUpperCase() + type.substring(1);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: theme.colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: theme.colorScheme.onSecondaryContainer),
              const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSecondaryContainer),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
