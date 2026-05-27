import 'package:flutter/material.dart';
import '../models/spot.dart';
import '../services/app_logger.dart';
import '../services/spot_service.dart';
import '../utils/spot_deviation_detector.dart';
import '../utils/spot_utils.dart';

class SpotDeviationsScreen extends StatefulWidget {
  final String authToken;

  const SpotDeviationsScreen({super.key, required this.authToken});

  @override
  State<SpotDeviationsScreen> createState() => _SpotDeviationsScreenState();
}

class _SpotDeviationsScreenState extends State<SpotDeviationsScreen> {
  static const _helsinkiLat = 60.1699;
  static const _helsinkiLon = 24.9384;
  static const _fetchRadiusMeters = 50000;

  bool _isLoading = true;
  String? _error;
  int _totalFetched = 0;
  List<SpotDeviation> _deviations = [];

  @override
  void initState() {
    super.initState();
    _fetchAndAnalyze();
  }

  Future<void> _fetchAndAnalyze() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    AppLogger.log('[SpotDeviations] fetching spots around Helsinki');
    final spots = await SpotService.fetchSpots(
      latitude: _helsinkiLat,
      longitude: _helsinkiLon,
      radius: _fetchRadiusMeters,
      authToken: widget.authToken,
    );

    if (!mounted) return;

    if (spots == null) {
      setState(() {
        _isLoading = false;
        _error = 'Failed to load spots. Check your connection and try again.';
      });
      AppLogger.log('[SpotDeviations] fetch failed');
      return;
    }

    final deviations = detectDeviations(spots);
    AppLogger.log('[SpotDeviations] ${deviations.length} deviation(s) in ${spots.length} spots');

    setState(() {
      _isLoading = false;
      _totalFetched = spots.length;
      _deviations = deviations;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Deviations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _isLoading ? null : _fetchAndAnalyze,
          ),
        ],
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _ErrorView(message: _error!, onRetry: _fetchAndAnalyze);
    }

    if (_deviations.isEmpty) {
      return _EmptyView(totalFetched: _totalFetched);
    }

    return _DeviationList(
      deviations: _deviations,
      totalFetched: _totalFetched,
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final int totalFetched;

  const _EmptyView({required this.totalFetched});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline, size: 48, color: Colors.green.shade600),
            const SizedBox(height: 16),
            Text(
              'No deviations found',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'All $totalFetched spot(s) passed quality checks.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _DeviationList extends StatelessWidget {
  final List<SpotDeviation> deviations;
  final int totalFetched;

  const _DeviationList({required this.deviations, required this.totalFetched});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Chip(
            avatar: Icon(Icons.warning_amber, size: 16, color: Colors.amber.shade800),
            label: Text(
              '${deviations.length} deviation(s) in $totalFetched spot(s)',
              style: theme.textTheme.bodySmall,
            ),
            backgroundColor: Colors.amber.shade50,
            side: BorderSide(color: Colors.amber.shade200),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            itemCount: deviations.length,
            itemBuilder: (context, i) => _DeviationCard(
              deviation: deviations[i],
            ),
          ),
        ),
      ],
    );
  }
}

class _DeviationCard extends StatelessWidget {
  final SpotDeviation deviation;

  const _DeviationCard({required this.deviation});

  bool get _hasCoordIssue => deviation.deviations.any((d) =>
      d == DeviationType.nullIslandCoords ||
      d == DeviationType.invalidLatRange ||
      d == DeviationType.invalidLonRange);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spot = deviation.spot;
    final color = _hasCoordIssue ? theme.colorScheme.error : Colors.amber.shade800;
    final icon = _hasCoordIssue ? Icons.error_outline : Icons.warning_amber;
    final labels = deviation.deviations.map(deviationLabel).join(', ');

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(spot.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ID ${spot.id} · (${spot.latitude.toStringAsFixed(4)}, ${spot.longitude.toStringAsFixed(4)})',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 2),
            Text(labels, style: TextStyle(color: color, fontSize: 12)),
          ],
        ),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _showDetail(context, spot, deviation.deviations),
      ),
    );
  }

  void _showDetail(BuildContext context, Spot spot, List<DeviationType> issues) {
    final theme = Theme.of(context);
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(spotTypeToIcon(spot.type), size: 32, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(spot.name, style: theme.textTheme.titleLarge),
                      Text('ID: ${spot.id}', style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _field(theme, 'Latitude', spot.latitude.toString()),
            _field(theme, 'Longitude', spot.longitude.toString()),
            _field(theme, 'Type', spot.type),
            _field(
              theme,
              'Distance',
              spot.distance != null ? formatDistance(spot.distance!) : 'N/A',
            ),
            const SizedBox(height: 12),
            Text('Issues', style: theme.textTheme.labelLarge),
            const SizedBox(height: 6),
            ...issues.map(
              (d) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    const Icon(Icons.circle, size: 6),
                    const SizedBox(width: 8),
                    Text(deviationLabel(d), style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: theme.textTheme.labelMedium),
          ),
          Expanded(
            child: Text(value, style: theme.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
