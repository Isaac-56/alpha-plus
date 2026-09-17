import 'dart:async';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class DriverPresenceException implements Exception {
  const DriverPresenceException(this.message);

  final String message;

  @override
  String toString() => message;
}

class DriverAvailabilityPolicy {
  const DriverAvailabilityPolicy._();

  // Keep this aligned with PRESENCE_FRESH_MS in the dispatch backend.
  static const Duration presenceFreshnessWindow = Duration(seconds: 90);
  static const Duration heartbeatInterval = Duration(seconds: 30);

  static bool canGoOnline(String reviewStatus) =>
      reviewStatus.trim().toLowerCase() == 'approved';

  static bool isPresenceFresh(
    int? updatedAt, {
    int? nowMilliseconds,
  }) {
    if (updatedAt == null) return false;

    final int age =
        (nowMilliseconds ?? DateTime.now().millisecondsSinceEpoch) - updatedAt;
    return age >= 0 && age <= presenceFreshnessWindow.inMilliseconds;
  }

  static String normalizedVehicleType(String vehicleType) {
    final String normalized = vehicleType.trim().toLowerCase();

    if (normalized.contains('boda') || normalized.contains('motor')) {
      return 'boda';
    }
    if (normalized.contains('rickshaw') ||
        normalized.contains('tuk') ||
        normalized.contains('three')) {
      return 'rickshaw';
    }

    return 'standard';
  }
}

class DriverHeadingPolicy {
  const DriverHeadingPolicy._();

  static const int locationDistanceFilterMeters = 2;
  static const Duration locationUpdateInterval = Duration(seconds: 2);
  static const double minimumBearingMovementMeters = 1.5;
  static const double maximumUsefulHeadingAccuracyDegrees = 60;

  static double normalizedHeading(double value) {
    return ((value % 360) + 360) % 360;
  }

  static double resolve({
    required double reportedHeading,
    required double reportedHeadingAccuracy,
    required double movementMeters,
    required double movementBearing,
    double? previousHeading,
  }) {
    final bool hasPreviousHeading =
        previousHeading != null && previousHeading.isFinite;
    final bool movedEnough = movementMeters.isFinite &&
        movementMeters >= minimumBearingMovementMeters;
    final bool hasReliableReportedHeading = reportedHeading.isFinite &&
        reportedHeading >= 0 &&
        reportedHeading <= 360 &&
        reportedHeadingAccuracy.isFinite &&
        reportedHeadingAccuracy >= 0 &&
        reportedHeadingAccuracy <= maximumUsefulHeadingAccuracyDegrees;

    if (!movedEnough && hasPreviousHeading) {
      return normalizedHeading(previousHeading);
    }
    if (hasReliableReportedHeading) {
      return normalizedHeading(reportedHeading);
    }
    if (movedEnough && movementBearing.isFinite) {
      return normalizedHeading(movementBearing);
    }
    if (hasPreviousHeading) {
      return normalizedHeading(previousHeading);
    }

    return 0;
  }
}

/// Publishes the active driver's public, short-lived map presence.
///
/// Only coordinates needed for dispatch are written. Phone numbers, licence
/// information, names and other private profile fields never leave the private
/// `drivers/{uid}` document.
class DriverPresenceService {
  DriverPresenceService({FirebaseAuth? auth, FirebaseDatabase? database})
    : _auth = auth ?? FirebaseAuth.instance,
      _database = database ?? FirebaseDatabase.instance;

  static final DriverPresenceService instance = DriverPresenceService();

  final FirebaseAuth _auth;
  final FirebaseDatabase _database;

  StreamSubscription<Position>? _positionSubscription;
  Timer? _heartbeatTimer;
  DatabaseReference? _activeReference;
  String? _activePresenceId;
  String? _activeDriverId;
  Position? _lastPublishedPosition;
  double? _lastPublishedHeading;
  Object? _onlineAttempt;

  DatabaseReference _driverReference(String driverId) =>
      _database.ref('driver_locations/$driverId');

  Stream<bool> watchOnlineState(String driverId) {
    if (driverId.isEmpty) return Stream<bool>.value(false);

    return _driverReference(driverId).onValue.map((DatabaseEvent event) {
      final Object? value = event.snapshot.value;
      if (value is! Map<Object?, Object?>) return false;

      final Object? rawOnline = value['isOnline'] ?? value['online'];
      final Object? rawUpdatedAt = value['updatedAt'] ?? value['lastUpdated'];
      final int? updatedAt = rawUpdatedAt is num
          ? rawUpdatedAt.toInt()
          : int.tryParse(rawUpdatedAt?.toString() ?? '');
      if (!DriverAvailabilityPolicy.isPresenceFresh(updatedAt)) return false;
      if (rawOnline is bool) return rawOnline;
      if (rawOnline is num) return rawOnline != 0;

      final String normalized = rawOnline?.toString().toLowerCase() ?? '';
      return normalized == 'true' || normalized == 'online';
    });
  }

  Future<void> goOnline({
    required String driverId,
    required String reviewStatus,
    required String vehicleType,
  }) async {
    if (!DriverAvailabilityPolicy.canGoOnline(reviewStatus)) {
      throw const DriverPresenceException(
        'Your driver account must be approved before you can go online.',
      );
    }

    final User? user = _auth.currentUser;
    if (user == null || user.uid != driverId) {
      throw const DriverPresenceException(
        'Your secure driver session has expired. Please sign in again.',
      );
    }

    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const DriverPresenceException(
        'Turn on device location before going online.',
      );
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw const DriverPresenceException(
        'Location permission is required while you are online.',
      );
    }
    if (permission == LocationPermission.deniedForever) {
      throw const DriverPresenceException(
        'Location permission is blocked. Enable it in device settings.',
      );
    }

    await goOffline();

    final Object onlineAttempt = Object();
    _onlineAttempt = onlineAttempt;
    final String presenceId = _createPresenceId();
    final DatabaseReference reference = _driverReference(driverId);
    final String normalizedVehicleType =
        DriverAvailabilityPolicy.normalizedVehicleType(vehicleType);
    final LocationSettings settings = _onlineLocationSettings();

    final Position initialPosition = await Geolocator.getCurrentPosition(
      locationSettings: settings,
    );
    if (_onlineAttempt != onlineAttempt) return;

    _activeDriverId = driverId;
    _activePresenceId = presenceId;
    _activeReference = reference;
    final double initialHeading = _resolveHeading(initialPosition);

    await reference.onDisconnect().update(<String, Object?>{
      'isOnline': false,
      'updatedAt': ServerValue.timestamp,
    });
    if (_onlineAttempt != onlineAttempt) return;

    await _publishPosition(
      reference: reference,
      presenceId: presenceId,
      vehicleType: normalizedVehicleType,
      position: initialPosition,
      heading: initialHeading,
    );
    if (_onlineAttempt != onlineAttempt) return;

    _startHeartbeat(reference: reference, presenceId: presenceId);

    _positionSubscription =
        Geolocator.getPositionStream(locationSettings: settings).listen(
          (Position position) {
            final double heading = _resolveHeading(position);
            unawaited(
              _publishPosition(
                reference: reference,
                presenceId: presenceId,
                vehicleType: normalizedVehicleType,
                position: position,
                heading: heading,
              ).catchError((Object error) {
                debugPrint('Unable to publish the driver location: $error');
              }),
            );
          },
          onError: (_) {
            unawaited(goOffline());
          },
        );
  }

  Future<void> _publishPosition({
    required DatabaseReference reference,
    required String presenceId,
    required String vehicleType,
    required Position position,
    required double heading,
  }) async {
    if (_activePresenceId != presenceId) return;

    await reference.set(<String, Object?>{
      'driverId': _activeDriverId,
      'presenceId': presenceId,
      'latitude': position.latitude,
      'longitude': position.longitude,
      'heading': DriverHeadingPolicy.normalizedHeading(heading),
      'accuracy': position.accuracy,
      'isOnline': true,
      'vehicleType': vehicleType,
      'updatedAt': ServerValue.timestamp,
    });

    if (_activePresenceId != presenceId) {
      await _removePresenceIfOwned(reference, presenceId);
    }
  }

  void _startHeartbeat({
    required DatabaseReference reference,
    required String presenceId,
  }) {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(
      DriverAvailabilityPolicy.heartbeatInterval,
      (_) {
        unawaited(
          _refreshHeartbeat(reference, presenceId).catchError((Object error) {
            debugPrint('Unable to refresh driver availability: $error');
          }),
        );
      },
    );
  }

  Future<void> _refreshHeartbeat(
    DatabaseReference reference,
    String presenceId,
  ) async {
    if (_activePresenceId != presenceId) return;

    await reference.runTransaction((Object? currentValue) {
      if (_activePresenceId != presenceId ||
          currentValue is! Map<Object?, Object?> ||
          currentValue['presenceId'] != presenceId) {
        return Transaction.abort();
      }

      return Transaction.success(<Object?, Object?>{
        ...currentValue,
        'isOnline': true,
        'updatedAt': ServerValue.timestamp,
      });
    });
  }

  Future<void> goOffline() async {
    _onlineAttempt = null;
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    await _positionSubscription?.cancel();
    _positionSubscription = null;

    final DatabaseReference? reference = _activeReference;
    final String? presenceId = _activePresenceId;

    _activeReference = null;
    _activePresenceId = null;
    _activeDriverId = null;
    _lastPublishedPosition = null;
    _lastPublishedHeading = null;

    if (reference == null || presenceId == null) return;

    await reference.onDisconnect().cancel();
    await _removePresenceIfOwned(reference, presenceId);
  }

  Future<void> _removePresenceIfOwned(
    DatabaseReference reference,
    String presenceId,
  ) async {
    await reference.runTransaction((Object? currentValue) {
      if (currentValue is! Map<Object?, Object?> ||
          currentValue['presenceId'] != presenceId) {
        return Transaction.abort();
      }

      return Transaction.success(null);
    });
  }

  String _createPresenceId() {
    final Random random = Random.secure();
    final int randomPart = random.nextInt(1 << 32);
    return '${DateTime.now().microsecondsSinceEpoch}-$randomPart';
  }

  double _resolveHeading(Position position) {
    final Position? previousPosition = _lastPublishedPosition;
    double movementMeters = 0;
    double movementBearing = _lastPublishedHeading ?? 0;

    if (previousPosition != null) {
      movementMeters = Geolocator.distanceBetween(
        previousPosition.latitude,
        previousPosition.longitude,
        position.latitude,
        position.longitude,
      );
      if (movementMeters >= DriverHeadingPolicy.minimumBearingMovementMeters) {
        movementBearing = Geolocator.bearingBetween(
          previousPosition.latitude,
          previousPosition.longitude,
          position.latitude,
          position.longitude,
        );
      }
    }

    final double heading = DriverHeadingPolicy.resolve(
      reportedHeading: position.heading,
      reportedHeadingAccuracy: position.headingAccuracy,
      movementMeters: movementMeters,
      movementBearing: movementBearing,
      previousHeading: _lastPublishedHeading,
    );

    _lastPublishedPosition = position;
    _lastPublishedHeading = heading;
    return heading;
  }

  LocationSettings _onlineLocationSettings() {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: DriverHeadingPolicy.locationDistanceFilterMeters,
        intervalDuration: DriverHeadingPolicy.locationUpdateInterval,
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'Alpha Plus is online',
          notificationText: 'Sharing location for nearby trip requests',
          enableWakeLock: true,
          setOngoing: true,
        ),
      );
    }

    return const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: DriverHeadingPolicy.locationDistanceFilterMeters,
    );
  }
}
