import 'package:latlong2/latlong.dart';
import '../models/spot.dart';

enum DeviationType {
  nullIslandCoords,
  invalidLatRange,
  invalidLonRange,
  unknownName,
  unknownType,
  farFromReference,
  missingDistance,
}

String deviationLabel(DeviationType type) {
  switch (type) {
    case DeviationType.nullIslandCoords:
      return 'Null-island coords (0,0)';
    case DeviationType.invalidLatRange:
      return 'Invalid latitude';
    case DeviationType.invalidLonRange:
      return 'Invalid longitude';
    case DeviationType.unknownName:
      return 'Missing name';
    case DeviationType.unknownType:
      return 'Unknown type';
    case DeviationType.farFromReference:
      return 'Far from Helsinki';
    case DeviationType.missingDistance:
      return 'No distance';
  }
}

class SpotDeviation {
  final Spot spot;
  final List<DeviationType> deviations;

  const SpotDeviation({required this.spot, required this.deviations});
}

const _knownTypes = {'terrain', 'water', 'park', 'other', 'place'};

/// Checks [spots] for data quality issues relative to [reference].
/// [reference] defaults to Helsinki so this can be reused for other cities.
List<SpotDeviation> detectDeviations(
  List<Spot> spots, {
  LatLng reference = const LatLng(60.1699, 24.9384),
  double farThresholdKm = 100.0,
}) {
  const distCalc = Distance();
  final result = <SpotDeviation>[];

  for (final spot in spots) {
    final issues = <DeviationType>[];

    if (spot.latitude == 0.0 && spot.longitude == 0.0) {
      issues.add(DeviationType.nullIslandCoords);
    } else {
      if (spot.latitude < -90 || spot.latitude > 90) {
        issues.add(DeviationType.invalidLatRange);
      }
      if (spot.longitude < -180 || spot.longitude > 180) {
        issues.add(DeviationType.invalidLonRange);
      }
      final distKm = distCalc.as(
        LengthUnit.Kilometer,
        reference,
        LatLng(spot.latitude, spot.longitude),
      );
      if (distKm > farThresholdKm) {
        issues.add(DeviationType.farFromReference);
      }
    }

    if (spot.name == 'Unknown') issues.add(DeviationType.unknownName);
    if (!_knownTypes.contains(spot.type)) issues.add(DeviationType.unknownType);
    if (spot.distance == null) issues.add(DeviationType.missingDistance);

    if (issues.isNotEmpty) {
      result.add(SpotDeviation(spot: spot, deviations: issues));
    }
  }

  return result;
}
