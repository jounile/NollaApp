import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../models/spot.dart';
import '../services/spot_service.dart';

class SpotsScreen extends StatefulWidget {
  final String authToken;

  const SpotsScreen({super.key, required this.authToken});

  @override
  State<SpotsScreen> createState() => _SpotsScreenState();
}

class _SpotsScreenState extends State<SpotsScreen> {
  final MapController _mapController = MapController();

  static const _defaultLocation = LatLng(60.1699, 24.9384);

  LatLng? _userLocation;
  LatLng _mapCenter = _defaultLocation;
  bool _isLoading = true;
  bool _hasApiError = false;
  bool _showSearchHere = false;
  bool _useFallbackSpots = true;

  final List<_Spot> _spots = [];

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    setState(() {
      _isLoading = true;
      _showSearchHere = false;
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
    _loadSpots(_defaultLocation);
  }

  void _applyPosition(Position position) {
    final userLatLng = LatLng(position.latitude, position.longitude);
    setState(() {
      _userLocation = userLatLng;
      _mapCenter = userLatLng;
    });
    _loadSpots(userLatLng);
  }

  Future<void> _loadSpots(LatLng center) async {
    setState(() {
      _isLoading = true;
      _hasApiError = false;
      _showSearchHere = false;
    });

    final result = await SpotService.fetchSpots(
      latitude: center.latitude,
      longitude: center.longitude,
      authToken: widget.authToken,
    );

    if (!mounted) return;
    setState(() {
      _spots.clear();
      if (result == null) {
        _hasApiError = true;
        if (_useFallbackSpots) _spots.addAll(_fallbackSpots(center));
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
      } else if (_useFallbackSpots) {
        _spots.addAll(_fallbackSpots(center));
      }
      _isLoading = false;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _mapController.move(center, 14);
    });
  }

  List<_Spot> _fallbackSpots(LatLng center) {
    return [
      _Spot(
        name: 'Spot Alpha',
        latLng: LatLng(center.latitude + 0.005, center.longitude + 0.007),
        icon: Icons.terrain,
        distanceMeters: 690,
      ),
      _Spot(
        name: 'Spot Beta',
        latLng: LatLng(center.latitude - 0.006, center.longitude + 0.003),
        icon: Icons.water,
        distanceMeters: 735,
      ),
      _Spot(
        name: 'Spot Gamma',
        latLng: LatLng(center.latitude + 0.003, center.longitude - 0.008),
        icon: Icons.park,
        distanceMeters: 830,
      ),
      _Spot(
        name: 'Spot Delta',
        latLng: LatLng(center.latitude - 0.004, center.longitude - 0.005),
        icon: Icons.place,
        distanceMeters: 645,
      ),
    ];
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Spots'),
        actions: [
          IconButton(
            icon: Icon(_useFallbackSpots ? Icons.layers : Icons.layers_clear),
            tooltip: _useFallbackSpots ? 'Hide example spots' : 'Show example spots',
            onPressed: () {
              setState(() => _useFallbackSpots = !_useFallbackSpots);
              _loadSpots(_mapCenter);
            },
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
                  _loadSpots(_userLocation!);
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
                          _showSearchHere = true;
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

                // "Search this area" button — appears after user pans the map
                if (_showSearchHere)
                  Positioned(
                    top: 16,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: FilledButton.icon(
                        icon: const Icon(Icons.search, size: 18),
                        label: const Text('Search this area'),
                        onPressed: () => _loadSpots(_mapCenter),
                      ),
                    ),
                  ),

                // Bottom status card — error, empty, or spot count
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
                                    _useFallbackSpots
                                        ? 'Could not reach API — showing example spots'
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
                                Icon(
                                  Icons.location_on,
                                  color: theme.colorScheme.secondary,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _spots.isEmpty
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
