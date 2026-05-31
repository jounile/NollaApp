import 'package:flutter/material.dart';

IconData spotTypeToIcon(String type) {
  switch (type) {
    case 'skatepark':
      return Icons.skateboarding;
    case 'street':
      return Icons.location_city;
    case 'bowl':
      return Icons.lens;
    case 'rail':
      return Icons.fence;
    case 'ledge':
      return Icons.horizontal_rule;
    case 'stairs':
      return Icons.stairs;
    case 'bank':
      return Icons.terrain;
    case 'diy':
      return Icons.construction;
    // legacy API types kept for backward compatibility
    case 'park':
      return Icons.park;
    case 'water':
      return Icons.water;
    case 'terrain':
      return Icons.terrain;
    default:
      return Icons.place;
  }
}

String formatDistance(double meters) {
  if (meters < 1000) {
    return '${meters.round()} m away';
  }
  return '${(meters / 1000).toStringAsFixed(1)} km away';
}
