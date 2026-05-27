import 'package:flutter/material.dart';

IconData spotTypeToIcon(String type) {
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

String formatDistance(double meters) {
  if (meters < 1000) {
    return '${meters.round()} m away';
  }
  return '${(meters / 1000).toStringAsFixed(1)} km away';
}
