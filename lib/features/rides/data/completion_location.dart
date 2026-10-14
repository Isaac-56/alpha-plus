import 'dart:async';

import 'package:geolocator/geolocator.dart';

/// Uses only recent precise fixes; never substitutes the planned destination.
Future<Position?> resolveCompletionLocation({
  required Position? Function() trackedPosition,
  required Future<Position> Function() currentPosition,
  required Future<Position?> Function() lastKnownPosition,
  DateTime Function()? clock,
}) async {
  final DateTime Function() now = clock ?? DateTime.now;
  bool usable(Position? position) {
    if (position == null) return false;
    final Duration age = now().difference(position.timestamp);
    return !age.isNegative &&
        age <= const Duration(seconds: 15) &&
        position.accuracy.isFinite &&
        position.accuracy >= 0 &&
        position.accuracy <= 100 &&
        position.latitude.isFinite &&
        position.latitude.abs() <= 90 &&
        position.longitude.isFinite &&
        position.longitude.abs() <= 180;
  }

  Position? position = trackedPosition();
  if (usable(position)) return position;
  try {
    position = await currentPosition().timeout(const Duration(seconds: 12));
    if (usable(position)) return position;
  } on Object {
    // A stream fix may have arrived while the one-shot GPS request was pending.
  }
  position = trackedPosition();
  if (usable(position)) return position;
  try {
    position = await lastKnownPosition().timeout(const Duration(seconds: 1));
    if (usable(position)) return position;
  } on Object {
    // Preserve the active trip when no trustworthy completion point is available.
  }
  return null;
}
