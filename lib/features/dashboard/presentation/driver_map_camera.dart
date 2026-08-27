import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Frames [location] between dashboard overlays without lifting the native
/// Google attribution away from the map's bottom edge.
///
/// Both inset values are logical pixels. At zoom zero the Google map world is
/// 256 logical pixels wide. The camera is north-up with zero tilt, so a southward
/// Mercator offset moves the driver's on-screen position upward by that amount.
/// Only the camera target changes; the driver's actual coordinates do not.
CameraPosition driverMapCameraPosition({
  required LatLng location,
  required double zoom,
  required EdgeInsets viewportInsets,
  required EdgeInsets mapPadding,
}) {
  final double verticalOffset =
      (mapPadding.top -
          mapPadding.bottom -
          viewportInsets.top +
          viewportInsets.bottom) /
      2;
  if (verticalOffset.abs() < 0.01) {
    return CameraPosition(target: location, zoom: zoom);
  }

  final double latitude = location.latitude.clamp(-85.0, 85.0).toDouble();
  final double sinLatitude = math.sin(latitude * math.pi / 180);
  final double worldY =
      0.5 - math.log((1 + sinLatitude) / (1 - sinLatitude)) / (4 * math.pi);
  final double worldSize = 256 * math.pow(2, zoom).toDouble();
  final double targetY = (worldY + verticalOffset / worldSize)
      .clamp(0.0, 1.0)
      .toDouble();
  final double targetLatitude =
      90 - 360 * math.atan(math.exp((targetY - 0.5) * 2 * math.pi)) / math.pi;

  return CameraPosition(
    target: LatLng(targetLatitude, location.longitude),
    zoom: zoom,
  );
}
