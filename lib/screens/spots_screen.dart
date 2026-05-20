import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class SpotsScreen extends StatefulWidget {
  const SpotsScreen({super.key});

  @override
  State<SpotsScreen> createState() => _SpotsScreenState();
}

class _SpotsScreenState extends State<SpotsScreen> {
  final MapController _mapController = MapController();

  LatLng? _userLocation;
  bool _isLoading = true;

  // Placeholder nearby spots relative to the user's position
  final List<_Spot> _spots = [];

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  static const _defaultLocation = LatLng(60.1699, 24.9384); // Helsinki fallback

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
      // GPS couldn't get a fix in time — try last known position, then default
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
      _isLoading = false;
      _spots.clear();
      _spots.addAll(_generateNearbySpots(_defaultLocation));
    });
    _mapController.move(_defaultLocation, 14);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(label: 'Retry', onPressed: _determinePosition),
      ),
    );
  }

  void _applyPosition(Position position) {
    final userLatLng = LatLng(position.latitude, position.longitude);
    setState(() {
      _userLocation = userLatLng;
      _isLoading = false;
      _spots.clear();
      _spots.addAll(_generateNearbySpots(userLatLng));
    });
    _mapController.move(userLatLng, 14);
  }

  List<_Spot> _generateNearbySpots(LatLng center) {
    return [
      _Spot(
        name: 'Spot Alpha',
        latLng: LatLng(center.latitude + 0.005, center.longitude + 0.007),
        icon: Icons.terrain,
      ),
      _Spot(
        name: 'Spot Beta',
        latLng: LatLng(center.latitude - 0.006, center.longitude + 0.003),
        icon: Icons.water,
      ),
      _Spot(
        name: 'Spot Gamma',
        latLng: LatLng(center.latitude + 0.003, center.longitude - 0.008),
        icon: Icons.park,
      ),
      _Spot(
        name: 'Spot Delta',
        latLng: LatLng(center.latitude - 0.004, center.longitude - 0.005),
        icon: Icons.place,
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
            Text(
              spot.name,
              style: Theme.of(ctx).textTheme.titleLarge,
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
          if (!_isLoading)
            IconButton(
              icon: const Icon(Icons.my_location),
              tooltip: 'Center on my location',
              onPressed: () {
                if (_userLocation != null) {
                  _mapController.move(_userLocation!, 14);
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
                    initialCenter: _userLocation ?? _defaultLocation,
                    initialZoom: 14,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
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
                                border: Border.all(
                                  color: Colors.white,
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: theme.colorScheme.primary.withOpacity(0.5),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                        ..._spots.map(
                          (spot) => Marker(
                            point: spot.latLng,
                            width: 44,
                            height: 44,
                            child: GestureDetector(
                              onTap: () => _showSpotInfo(spot),
                              child: Column(
                                children: [
                                  Container(
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
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Card(
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
                            '${_spots.length} spots nearby',
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

class _Spot {
  final String name;
  final LatLng latLng;
  final IconData icon;

  const _Spot({required this.name, required this.latLng, required this.icon});
}
