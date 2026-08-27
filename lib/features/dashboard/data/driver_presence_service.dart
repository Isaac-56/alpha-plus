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

  static bool canGoOnline(String reviewStatus) =>
      reviewStatus.trim().toLowerCase() == 'approved';

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
  DatabaseReference? _activeReference;
  String? _activePresenceId;
  String? _activeDriverId;

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
      final bool fresh =
          updatedAt != null &&
          DateTime.now().millisecondsSinceEpoch - updatedAt <= 90000;

      if (!fresh) return false;
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

    final String presenceId = _createPresenceId();
    final DatabaseReference reference = _driverReference(driverId);
    final String normalizedVehicleType =
        DriverAvailabilityPolicy.normalizedVehicleType(vehicleType);
    final LocationSettings settings = _onlineLocationSettings();

    final Position initialPosition = await Geolocator.getCurrentPosition(
      locationSettings: settings,
    );

    _activeDriverId = driverId;
    _activePresenceId = presenceId;
    _activeReference = reference;

    await reference.onDisconnect().update(<String, Object?>{
      'isOnline': false,
      'updatedAt': ServerValue.timestamp,
    });

    await _publishPosition(
      reference: reference,
      presenceId: presenceId,
      vehicleType: normalizedVehicleType,
      position: initialPosition,
    );

    _positionSubscription =
        Geolocator.getPositionStream(locationSettings: settings).listen(
          (Position position) {
            unawaited(
              _publishPosition(
                reference: reference,
                presenceId: presenceId,
                vehicleType: normalizedVehicleType,
                position: position,
              ),
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
  }) async {
    if (_activePresenceId != presenceId) return;

    await reference.set(<String, Object?>{
      'driverId': _activeDriverId,
      'presenceId': presenceId,
      'latitude': position.latitude,
      'longitude': position.longitude,
      'heading': position.heading.isFinite && position.heading >= 0
          ? position.heading
          : 0,
      'accuracy': position.accuracy,
      'isOnline': true,
      'vehicleType': vehicleType,
      'updatedAt': ServerValue.timestamp,
    });
  }

  Future<void> goOffline() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;

    final DatabaseReference? reference = _activeReference;
    final String? presenceId = _activePresenceId;

    _activeReference = null;
    _activePresenceId = null;
    _activeDriverId = null;

    if (reference == null || presenceId == null) return;

    await reference.onDisconnect().cancel();
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

  LocationSettings _onlineLocationSettings() {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 8,
        intervalDuration: const Duration(seconds: 8),
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
      distanceFilter: 8,
    );
  }
}
