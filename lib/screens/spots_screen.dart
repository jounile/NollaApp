import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../models/spot.dart';
import '../services/app_logger.dart';
import '../services/spot_service.dart';

class SpotsScreen extends StatefulWidget {
  final String authToken;

  const SpotsScreen({super.key, required this.authToken});

  @override
  State<SpotsScreen> createState() => _SpotsScreenState();
}

class _SpotsScreenState extends State<SpotsScreen> {
  final MapController _mapController = MapController();
  Timer? _moveDebounce;

  static const _defaultLocation = LatLng(60.1699, 24.9384);

  LatLng? _userLocation;
  LatLng _mapCenter = _defaultLocation;
  double _mapZoom = 14;
  bool _isLoading = true;
  bool _isFetchingSpots = false;
  bool _hasApiError = false;

  final List<_Spot> _spots = [];

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  @override
  void dispose() {
    _moveDebounce?.cancel();
    super.dispose();
  }

  Future<void> _determinePosition() async {
    setState(() {
      _isLoading = true;
    });

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return;
      _applyFallback('Location services are disabled. Showing default location.');
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (!mounted) return;
        _applyFallback('Location permission denied. Showing default location.');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (!mounted) return;
      _applyFallback('Location permission denied. Enable it in settings to use your location.');
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 15));

      if (!mounted) return;
      _applyPosition(position);
    } on TimeoutException {
      final last = await Geolocator.getLastKnownPosition();
      if (!mounted) return;
      if (last != null) {
        _applyPosition(last);
      } else {
        _applyFallback('Could not get your location. Showing default location.');
      }
    } catch (e) {
      if (!mounted) return;
      _applyFallback('Could not get your location. Showing default location.');
    }
  }

  void _applyFallback(String message) {
    setState(() {
      _userLocation = _defaultLocation;
      _mapCenter = _defaultLocation;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(label: 'Retry', onPressed: _determinePosition),
      ),
    );
    _loadSpots(_defaultLocation, initialLoad: true, moveMap: true, zoom: _mapZoom);
  }

  void _applyPosition(Position position) {
    final userLatLng = LatLng(position.latitude, position.longitude);
    setState(() {
      _userLocation = userLatLng;
      _mapCenter = userLatLng;
    });
    _loadSpots(userLatLng, initialLoad: true, moveMap: true, zoom: _mapZoom);
  }

  int _radiusForZoom(double zoom) {
    if (zoom <= 8) return 100000;
    if (zoom <= 10) return 50000;
    if (zoom <= 12) return 10000;
    if (zoom <= 14) return 3000;
    if (zoom <= 16) return 1000;
    return 500;
  }

  Future<void> _loadSpots(LatLng center, {bool initialLoad = false, bool moveMap = false, double? zoom}) async {
    _moveDebounce?.cancel();
    setState(() {
      if (initialLoad) _isLoading = true;
      _isFetchingSpots = true;
      _hasApiError = false;
    });

    final effectiveZoom = zoom ?? _mapZoom;
    final result = await SpotService.fetchSpots(
      latitude: center.latitude,
      longitude: center.longitude,
      radius: _radiusForZoom(effectiveZoom),
      authToken: widget.authToken,
    );

    if (!mounted) return;
    setState(() {
      _spots.clear();
      if (result == null) {
        _hasApiError = true;
      } else if (result.isNotEmpty) {
        final distCalc = const Distance();
        final mapped = result.map((s) {
          final spotLatLng = LatLng(s.latitude, s.longitude);
          final distMeters = s.distance ?? distCalc.as(LengthUnit.Meter, center, spotLatLng);
          return _Spot(
            name: s.name,
            latLng: spotLatLng,
            icon: _spotTypeToIcon(s.type),
            distanceMeters: distMeters,
          );
        }).toList()
          ..sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
        _spots.addAll(mapped);
      }
      if (initialLoad) _isLoading = false;
      _isFetchingSpots = false;
    });

    if (moveMap) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _mapController.move(center, effectiveZoom);
      });
    }
  }

  void _showSpotInfo(_Spot spot) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Icon(spot.icon, size: 40, color: Theme.of(ctx).colorScheme.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(spot.name, style: Theme.of(ctx).textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(
                    spot.distanceMeters < 1000
                        ? '${spot.distanceMeters.round()} m away'
                        : '${(spot.distanceMeters / 1000).toStringAsFixed(1)} km away',
                    style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogs() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final entries = AppLogger.entries;
          return DraggableScrollableSheet(
            initialChildSize: 0.6,
            maxChildSize: 0.92,
            minChildSize: 0.3,
            expand: false,
            builder: (_, scrollController) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
                  child: Row(
                    children: [
                      const Icon(Icons.terminal, size: 20),
                      const SizedBox(width: 8),
                      const Text('Logs', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          AppLogger.clear();
                          setModalState(() {});
                        },
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: entries.isEmpty
                      ? const Center(child: Text('No logs yet'))
                      : ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          itemCount: entries.length,
                          itemBuilder: (_, i) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Text(
                              entries[i].formatted,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Spots'),
        actions: [
          IconButton(
            icon: const Icon(Icons.terminal),
            tooltip: 'View logs',
            onPressed: _showLogs,
          ),
          if (!_isLoading)
            IconButton(
              icon: const Icon(Icons.my_location),
              tooltip: 'Go to my location',
              onPressed: () {
                if (_userLocation != null) {
                  setState(() {
                    _mapCenter = _userLocation!;
                  });
                  _loadSpots(_userLocation!, moveMap: true, zoom: _mapZoom);
                } else {
                  _determinePosition();
                }
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _mapCenter,
                    initialZoom: 14,
                    onPositionChanged: (camera, hasGesture) {
                      if (hasGesture) {
                        final center = camera.center;
                        if (center == null) return;
                        setState(() {
                          _mapCenter = center;
                          _mapZoom = camera.zoom ?? _mapZoom;
                        });
                        _moveDebounce?.cancel();
                        _moveDebounce = Timer(const Duration(milliseconds: 600), () {
                          _loadSpots(_mapCenter, zoom: _mapZoom);
                        });
                      }
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.nolla_app',
                    ),
                    MarkerLayer(
                      markers: [
                        if (_userLocation != null)
                          Marker(
                            point: _userLocation!,
                            width: 48,
                            height: 48,
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: theme.colorScheme.primary,
                                border: Border.all(color: Colors.white, width: 3),
                                boxShadow: [
                                  BoxShadow(
                                    color: theme.colorScheme.primary.withOpacity(0.5),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.person, color: Colors.white, size: 24),
                            ),
                          ),
                        ..._spots.map(
                          (spot) => Marker(
                            point: spot.latLng,
                            width: 44,
                            height: 44,
                            child: GestureDetector(
                              onTap: () => _showSpotInfo(spot),
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: theme.colorScheme.secondary,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  spot.icon,
                                  color: theme.colorScheme.onSecondary,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Bottom status card — error, fetching, empty, or spot count
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: _hasApiError
                      ? Card(
                          color: theme.colorScheme.errorContainer,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.wifi_off,
                                  color: theme.colorScheme.onErrorContainer,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    kIsWeb
                                        ? 'CORS error — API must allow web requests'
                                        : 'Failed to load spots',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onErrorContainer,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => _loadSpots(_mapCenter),
                                  child: Text(
                                    'Retry',
                                    style: TextStyle(color: theme.colorScheme.onErrorContainer),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (_isFetchingSpots)
                                  const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                else
                                  Icon(
                                    Icons.location_on,
                                    color: theme.colorScheme.secondary,
                                    size: 16,
                                  ),
                                const SizedBox(width: 6),
                                Text(
                                  _isFetchingSpots
                                      ? 'Searching for spots...'
                                      : _spots.isEmpty
                                          ? 'No spots found in this area'
                                          : '${_spots.length} spots nearby',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}

IconData _spotTypeToIcon(String type) {
  switch (type) {
    case 'terrain':
      return Icons.terrain;
    case 'water':
      return Icons.water;
    case 'park':
      return Icons.park;
    default:
      return Icons.place;
  }
}

class _Spot {
  final String name;
  final LatLng latLng;
  final IconData icon;
  final double distanceMeters;

  const _Spot({
    required this.name,
    required this.latLng,
    required this.icon,
    this.distanceMeters = 0,
  });
}
