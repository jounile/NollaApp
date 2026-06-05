import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../models/new_spot.dart';
import '../models/spot_type.dart';
import '../services/spot_service.dart';
import '../utils/spot_utils.dart';

class CreateSpotScreen extends StatefulWidget {
  final String authToken;
  final double? initialLat;
  final double? initialLon;

  const CreateSpotScreen({
    super.key,
    required this.authToken,
    this.initialLat,
    this.initialLon,
  });

  @override
  State<CreateSpotScreen> createState() => _CreateSpotScreenState();
}

class _CreateSpotScreenState extends State<CreateSpotScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  List<SpotType> _types = [];
  String? _selectedTypeName;
  double? _lat;
  double? _lon;
  bool _isLocating = false;
  bool _isSaving = false;
  bool _isLoadingTypes = true;

  static const _defaultLocation = LatLng(60.1699, 24.9384);

  @override
  void initState() {
    super.initState();
    if (widget.initialLat != null && widget.initialLon != null) {
      _lat = widget.initialLat;
      _lon = widget.initialLon;
    } else {
      _fetchLocation();
    }
    _loadTypes();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadTypes() async {
    final result = await SpotService.fetchSpotTypes(authToken: widget.authToken);
    if (!mounted) return;
    setState(() {
      _isLoadingTypes = false;
      if (result != null && result.isNotEmpty) {
        _types = result;
        _selectedTypeName = result.first.name;
      }
    });
  }

  Future<void> _fetchLocation() async {
    setState(() => _isLocating = true);
    try {
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium)
          .timeout(const Duration(seconds: 10));
      if (!mounted) return;
      setState(() {
        _lat = pos.latitude;
        _lon = pos.longitude;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not get location — use GPS or pick on map')),
      );
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  Future<void> _pickLocationOnMap() async {
    final initial = _lat != null && _lon != null
        ? LatLng(_lat!, _lon!)
        : _defaultLocation;
    final result = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (_) => _LocationPickerPage(initial: initial),
        fullscreenDialog: true,
      ),
    );
    if (result != null && mounted) {
      setState(() {
        _lat = result.latitude;
        _lon = result.longitude;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_lat == null || _lon == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location not set — use GPS or pick on map')),
      );
      return;
    }
    if (_selectedTypeName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a spot type')),
      );
      return;
    }
    setState(() => _isSaving = true);
    final spot = NewSpot(
      name: _nameCtrl.text.trim(),
      typeId: _types.firstWhere((t) => t.name == _selectedTypeName).id,
      latitude: _lat!,
      longitude: _lon!,
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      address: _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
      countryId: 1, // Default to Finland (maa_id=1)
      townId: 1,    // Default to Helsinki (paikkakunta_id=1, maa_id=1)
    );
    final result = await SpotService.createSpot(spot, widget.authToken);
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (result.success) {
      Navigator.pop(context, result.spot);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message ?? 'Failed to create spot')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Spot'),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            TextButton(
              onPressed: _save,
              child: const Text('Save'),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Name *', border: OutlineInputBorder()),
              textCapitalization: TextCapitalization.words,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
            ),
            const SizedBox(height: 16),
            Text('Type', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            if (_isLoadingTypes)
              const Center(child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(strokeWidth: 2),
              ))
            else if (_types.isEmpty)
              Text(
                'Could not load spot types. Check your connection and try again.',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _types.map((t) {
                  final selected = t.name == _selectedTypeName;
                  return ChoiceChip(
                    avatar: Icon(spotTypeToIcon(t.name), size: 16),
                    label: Text(t.name[0].toUpperCase() + t.name.substring(1)),
                    selected: selected,
                    onSelected: (_) => setState(() => _selectedTypeName = t.name),
                  );
                }).toList(),
              ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descCtrl,
              decoration: const InputDecoration(labelText: 'Description (optional)', border: OutlineInputBorder()),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressCtrl,
              decoration: const InputDecoration(labelText: 'Address (optional)', border: OutlineInputBorder()),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            Text('Location', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: theme.colorScheme.outline),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
                    child: Row(
                      children: [
                        const Icon(Icons.gps_fixed, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _isLocating
                              ? const Text('Getting location…')
                              : _lat != null
                                  ? Text(
                                      '${_lat!.toStringAsFixed(5)}, ${_lon!.toStringAsFixed(5)}',
                                      style: theme.textTheme.bodySmall,
                                    )
                                  : Text(
                                      'No location set',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                        ),
                        if (_isLocating)
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                          )
                        else
                          TextButton(
                            onPressed: _fetchLocation,
                            child: const Text('GPS'),
                          ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  InkWell(
                    onTap: _pickLocationOnMap,
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(7)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.map_outlined, size: 18, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Pick location on map',
                            style: TextStyle(color: theme.colorScheme.primary),
                          ),
                        ],
                      ),
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
}

class _LocationPickerPage extends StatefulWidget {
  final LatLng initial;

  const _LocationPickerPage({required this.initial});

  @override
  State<_LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<_LocationPickerPage> {
  late LatLng _center;

  @override
  void initState() {
    super.initState();
    _center = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick Location'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, _center),
            child: const Text('Select'),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: widget.initial,
              initialZoom: 15,
              minZoom: 3,
              maxZoom: 19,
              onPositionChanged: (camera, _) {
                final c = camera.center;
                if (c == null) return;
                if (!c.latitude.isFinite || !c.longitude.isFinite) return;
                setState(() => _center = c);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.nolla_app',
              ),
            ],
          ),
          // Center pin — bottom padding equal to icon size shifts pin tip to map center
          Center(
            child: IgnorePointer(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 36),
                child: Icon(Icons.location_on, size: 36, color: theme.colorScheme.error),
              ),
            ),
          ),
          // Instruction banner at top
          Positioned(
            top: 8,
            left: 16,
            right: 16,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                ),
                child: Text(
                  'Pan the map to position the pin, then tap Select',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ),
          ),
          // Coordinates display at bottom
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2))],
                ),
                child: Text(
                  '${_center.latitude.toStringAsFixed(5)}, ${_center.longitude.toStringAsFixed(5)}',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
