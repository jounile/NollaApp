import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/new_spot.dart';
import '../services/spot_service.dart';

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

  String _selectedType = 'terrain';
  double? _lat;
  double? _lon;
  bool _isLocating = false;
  bool _isSaving = false;

  static const _types = ['terrain', 'water', 'park', 'other'];

  @override
  void initState() {
    super.initState();
    if (widget.initialLat != null && widget.initialLon != null) {
      _lat = widget.initialLat;
      _lon = widget.initialLon;
    } else {
      _fetchLocation();
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
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
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_lat == null || _lon == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location not available yet — please wait or try again')),
      );
      return;
    }
    setState(() => _isSaving = true);
    final spot = NewSpot(
      name: _nameCtrl.text.trim(),
      type: _selectedType,
      latitude: _lat!,
      longitude: _lon!,
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      address: _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
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
            Wrap(
              spacing: 8,
              children: _types.map((t) {
                final selected = t == _selectedType;
                return ChoiceChip(
                  label: Text(t[0].toUpperCase() + t.substring(1)),
                  selected: selected,
                  onSelected: (_) => setState(() => _selectedType = t),
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
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
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
                            : const Text('Location unavailable'),
                  ),
                  if (!_isLocating)
                    TextButton(
                      onPressed: _fetchLocation,
                      child: const Text('Update'),
                    ),
                  if (_isLocating)
                    const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
