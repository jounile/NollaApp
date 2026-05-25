import 'package:flutter/material.dart';
import '../models/spot_detail.dart';
import '../services/spot_service.dart';

class SpotDetailScreen extends StatefulWidget {
  final int spotId;
  final String spotName;
  final String authToken;

  const SpotDetailScreen({
    super.key,
    required this.spotId,
    required this.spotName,
    required this.authToken,
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
          : _error != null
              ? _ErrorView(message: _error!, onRetry: _load)
              : _spot == null
                  ? const Center(child: Text('Spot not found'))
                  : _SpotDetailBody(spot: _spot!, theme: theme),
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

class _SpotDetailBody extends StatelessWidget {
  final SpotDetail spot;
  final ThemeData theme;

  const _SpotDetailBody({required this.spot, required this.theme});

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
                spot.distance! < 1000
                    ? '${spot.distance!.round()} m away'
                    : '${(spot.distance! / 1000).toStringAsFixed(1)} km away',
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
              Text(
                'Added by ${spot.createdBy}',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
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
              itemBuilder: (ctx, i) => ClipRRect(
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
    final icon = switch (type) {
      'terrain' => Icons.terrain,
      'water' => Icons.water,
      'park' => Icons.park,
      _ => Icons.place,
    };
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
                type[0].toUpperCase() + type.substring(1),
                style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSecondaryContainer),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
