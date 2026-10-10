import 'dart:async';
import 'dart:math';

import 'package:cloud_functions/cloud_functions.dart';
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

class PreparedDriverAvailability {
  const PreparedDriverAvailability({
    required this.vehicleType,
    required this.activeRideId,
  });

  final String vehicleType;
  final String? activeRideId;

  factory PreparedDriverAvailability.fromCallable(Object? value) {
    if (value is! Map<Object?, Object?>) {
      throw const FormatException('Driver availability response is invalid.');
    }
    final String vehicleType = value['vehicleType']?.toString().trim() ?? '';
    final String activeRide = value['activeRideId']?.toString().trim() ?? '';
    if (vehicleType.isEmpty) {
      throw const FormatException('Driver vehicle category is missing.');
    }
    return PreparedDriverAvailability(
      vehicleType: vehicleType,
      activeRideId: activeRide.isEmpty ? null : activeRide,
    );
  }
}

class DriverAvailabilityPolicy {
  const DriverAvailabilityPolicy._();

  // Keep this aligned with PRESENCE_FRESH_MS in the dispatch backend.
  static const Duration presenceFreshnessWindow = Duration(seconds: 90);
  static const Duration heartbeatInterval = Duration(seconds: 15);
  // Match the backend presence window so a quick Online transition never
  // publishes a several-minutes-old position outside the passenger's radius.
  static const Duration cachedPositionMaximumAge = Duration(seconds: 90);
  static const Duration initialPositionTimeout = Duration(seconds: 3);

  static bool canGoOnline(String reviewStatus) =>
      reviewStatus.trim().toLowerCase() == 'approved';

  static bool canChangeOnlineSwitch({
    required bool walletLoaded,
    required bool walletCanGoOnline,
    required bool changing,
    required bool? requestedOnline,
  }) {
    if (!walletLoaded || !walletCanGoOnline) return false;
    return !changing || requestedOnline == true;
  }

  static bool shouldForceWalletOffline({
    required bool isOnline,
    required bool walletLoaded,
    required bool walletCanGoOnline,
  }) =>
      isOnline && walletLoaded && !walletCanGoOnline;

  static bool isPresenceFresh(
    int? updatedAt, {
    int? nowMilliseconds,
  }) {
    if (updatedAt == null) return false;

    final int age =
        (nowMilliseconds ?? DateTime.now().millisecondsSinceEpoch) - updatedAt;
    return age >= 0 && age <= presenceFreshnessWindow.inMilliseconds;
  }

  static bool isCachedPositionFresh(
    DateTime? timestamp, {
    DateTime? now,
  }) {
    if (timestamp == null) return false;
    final Duration age = (now ?? DateTime.now()).difference(timestamp);
    return !age.isNegative && age <= cachedPositionMaximumAge;
  }

  static bool isCurrentPresenceOnline({
    required String driverId,
    required String? activeDriverId,
    required String? activePresenceId,
    required Object? remotePresenceId,
    required Object? rawOnline,
  }) {
    if (driverId.isEmpty ||
        activeDriverId != driverId ||
        activePresenceId == null ||
        remotePresenceId != activePresenceId) {
      return false;
    }

    if (rawOnline is bool) return rawOnline;
    if (rawOnline is num) return rawOnline != 0;

    final String normalized = rawOnline?.toString().toLowerCase().trim() ?? '';
    return normalized == 'true' ||
        normalized == 'online' ||
        normalized == '1';
  }

  static String normalizedVehicleType(String vehicleType) {
    final String normalized = vehicleType.trim().toLowerCase();
    if (normalized.isEmpty) return '';

    if (normalized.contains('rickshaw') ||
        normalized.contains('tuk') ||
        normalized.contains('three') ||
        normalized.contains('bajaj')) {
      return 'rickshaw';
    }
    if (normalized.contains('boda') ||
        normalized.contains('motor') ||
        normalized.contains('scooter')) {
      return 'boda';
    }
    if (normalized == 'standard' || normalized == 'car') return 'standard';
    if (normalized == 'comfort') return 'comfort';
    if (normalized == 'ev' || normalized.contains('electric')) return 'ev';
    if (normalized == 'premium') return 'premium';
    if (normalized == 'corporate') return 'corporate';

    return '';
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
  DriverPresenceService({
    FirebaseAuth? auth,
    FirebaseDatabase? database,
    FirebaseFunctions? functions,
  }) : _auth = auth ?? FirebaseAuth.instance,
      _database = database ?? FirebaseDatabase.instance,
      _functions = functions ??
          FirebaseFunctions.instanceFor(region: 'africa-south1');

  static final DriverPresenceService instance = DriverPresenceService();

  final FirebaseAuth _auth;
  final FirebaseDatabase _database;
  final FirebaseFunctions _functions;

  StreamSubscription<Position>? _positionSubscription;
  StreamSubscription<DatabaseEvent>? _connectionSubscription;
  Timer? _heartbeatTimer;
  bool _reconcilingAvailability = false;
  Timer? _positionRestartTimer;
  int _positionRestartAttempts = 0;
  DatabaseReference? _activeReference;
  String? _activePresenceId;
  String? _activeDriverId;
  Position? _lastPublishedPosition;
  double? _lastPublishedHeading;
  Object? _onlineAttempt;
  PreparedDriverAvailability? _cachedAvailability;
  DateTime? _cachedAvailabilityAt;
  Future<PreparedDriverAvailability>? _availabilityInFlight;
  Position? _prewarmedPosition;

  DatabaseReference _driverReference(String driverId) =>
      _database.ref('driver_locations/$driverId');

  Stream<bool> watchOnlineState(String driverId) {
    if (driverId.isEmpty) return Stream<bool>.value(false);

    return _driverReference(driverId).onValue.map((DatabaseEvent event) {
      final Object? value = event.snapshot.value;
      if (value is! Map<Object?, Object?>) return false;

      final Object? rawOnline = value['isOnline'] ?? value['online'];
      return DriverAvailabilityPolicy.isCurrentPresenceOnline(
        driverId: driverId,
        activeDriverId: _activeDriverId,
        activePresenceId: _activePresenceId,
        remotePresenceId: value['presenceId'],
        rawOnline: rawOnline,
      );
    }).distinct();
  }

  /// Warms the two slow dependencies used by the Online switch while the
  /// driver is already looking at the dashboard.
  Future<void> warmUp({
    required String driverId,
    required String reviewStatus,
  }) async {
    if (!DriverAvailabilityPolicy.canGoOnline(reviewStatus) ||
        _auth.currentUser?.uid != driverId) {
      return;
    }

    await Future.wait<void>(<Future<void>>[
      _availabilityForOnlineAttempt().then<void>((_) {}).catchError(
        (Object error) {
          debugPrint('Unable to preflight driver availability: $error');
        },
      ),
      _prewarmPosition(),
    ]);
  }

  Future<void> _prewarmPosition() async {
    try {
      final Position? cached = await Geolocator.getLastKnownPosition();
      if (cached != null &&
          DriverAvailabilityPolicy.isCachedPositionFresh(cached.timestamp)) {
        _prewarmedPosition = cached;
        return;
      }

      if (!await Geolocator.isLocationServiceEnabled()) return;
      final LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }
      _prewarmedPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: DriverAvailabilityPolicy.initialPositionTimeout,
        ),
      );
    } on Object catch (error) {
      debugPrint('Unable to prewarm the driver location: $error');
    }
  }

  Future<void> goOnline({
    required String driverId,
    required String reviewStatus,
    required String vehicleType,
  }) async {
    final String requestedVehicleType =
        DriverAvailabilityPolicy.normalizedVehicleType(vehicleType);
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

    final Object onlineAttempt = Object();
    _onlineAttempt = onlineAttempt;
    await _clearPresence(cancelOnlineAttempt: false);
    if (_onlineAttempt != onlineAttempt) return;

    // The secure profile check and GPS lookup are independent. Running them
    // together removes the long sequential wait after tapping Online.
    final Future<PreparedDriverAvailability> availabilityFuture =
        _availabilityForOnlineAttempt();
    final Future<Position> positionFuture = _resolveInitialPosition();

    late final PreparedDriverAvailability prepared;
    try {
      prepared = await availabilityFuture;
    } on Object {
      if (_onlineAttempt != onlineAttempt) return;
      rethrow;
    }
    if (_onlineAttempt != onlineAttempt) return;
    final String normalizedVehicleType =
        DriverAvailabilityPolicy.normalizedVehicleType(prepared.vehicleType);
    if (normalizedVehicleType.isEmpty) {
      throw const DriverPresenceException(
        'Alpha must assign your ride category before you can go online.',
      );
    }
    if (requestedVehicleType.isNotEmpty &&
        requestedVehicleType != normalizedVehicleType) {
      debugPrint(
        'Driver category refreshed from server: '
        '$requestedVehicleType -> $normalizedVehicleType',
      );
    }

    final String presenceId = _createPresenceId();
    final DatabaseReference reference = _driverReference(driverId);
    final LocationSettings settings = _onlineLocationSettings();
    late final Position initialPosition;
    try {
      initialPosition = await positionFuture;
    } on Object {
      if (_onlineAttempt != onlineAttempt) return;
      rethrow;
    }
    if (_onlineAttempt != onlineAttempt) return;

    _activeDriverId = driverId;
    _activePresenceId = presenceId;
    _activeReference = reference;
    final double initialHeading = _resolveHeading(initialPosition);

    // Create the complete presence first. Realtime Database validates an
    // onDisconnect update against the current record when it is registered,
    // so registering it against an empty path is rejected by strict rules.
    await _publishPosition(
      reference: reference,
      presenceId: presenceId,
      vehicleType: normalizedVehicleType,
      position: initialPosition,
      heading: initialHeading,
    );
    if (_onlineAttempt != onlineAttempt) return;

    _startHeartbeat(reference: reference, presenceId: presenceId);
    _startConnectionRecovery(
      reference: reference,
      presenceId: presenceId,
      vehicleType: normalizedVehicleType,
    );
    // The authoritative presence is already visible at this point. Register
    // disconnect cleanup and the high-accuracy stream in the background so
    // the switch does not wait on two more network/plugin round trips.
    unawaited(
      reference
          .onDisconnect()
          .update(<String, Object?>{
            'isOnline': false,
            'online': false,
            'updatedAt': ServerValue.timestamp,
            'lastUpdated': ServerValue.timestamp,
          })
          .catchError((Object error) {
            debugPrint('Unable to register driver disconnect cleanup: $error');
          }),
    );
    unawaited(
      _startPositionUpdates(
        reference: reference,
        presenceId: presenceId,
        vehicleType: normalizedVehicleType,
        settings: settings,
      ).catchError((Object error) {
        debugPrint('Unable to start live driver location updates: $error');
      }),
    );
  }

  Future<PreparedDriverAvailability> _prepareAvailability() async {
    try {
      final HttpsCallableResult<dynamic> result = await _functions
          .httpsCallable('prepareDriverAvailability')
          .call<dynamic>()
          .timeout(const Duration(seconds: 12));
      return PreparedDriverAvailability.fromCallable(result.data);
    } on FirebaseFunctionsException catch (error) {
      throw DriverPresenceException(
        error.message ??
            'Alpha Plus could not verify your availability right now.',
      );
    } on TimeoutException {
      throw const DriverPresenceException(
        'Alpha Plus could not verify your availability. Try again.',
      );
    } on FormatException {
      throw const DriverPresenceException(
        'Alpha Plus received an invalid availability response.',
      );
    }
  }

  Future<PreparedDriverAvailability> _availabilityForOnlineAttempt() async {
    final PreparedDriverAvailability? cached = _cachedAvailability;
    final DateTime? cachedAt = _cachedAvailabilityAt;
    if (cached != null &&
        cachedAt != null &&
        DateTime.now().difference(cachedAt) <= const Duration(seconds: 90)) {
      return cached;
    }

    final Future<PreparedDriverAvailability> request =
        _availabilityInFlight ??= _prepareAvailability();
    try {
      final PreparedDriverAvailability prepared = await request;
      _cachedAvailability = prepared;
      _cachedAvailabilityAt = DateTime.now();
      return prepared;
    } finally {
      if (identical(_availabilityInFlight, request)) {
        _availabilityInFlight = null;
      }
    }
  }

  Future<Position> _resolveInitialPosition() async {
    final Position? prewarmed = _prewarmedPosition;
    if (prewarmed != null &&
        DriverAvailabilityPolicy.isCachedPositionFresh(prewarmed.timestamp)) {
      _prewarmedPosition = null;
      return prewarmed;
    }

    final Position? cached = await Geolocator.getLastKnownPosition();
    if (cached != null &&
        DriverAvailabilityPolicy.isCachedPositionFresh(cached.timestamp)) {
      return cached;
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: DriverAvailabilityPolicy.initialPositionTimeout,
        ),
      );
    } on TimeoutException {
      // A balanced fallback normally returns quickly indoors while the high
      // accuracy stream continues improving the live marker afterwards.
      return Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: DriverAvailabilityPolicy.initialPositionTimeout,
        ),
      );
    }
  }

  Future<void> _publishPosition({
    required DatabaseReference reference,
    required String presenceId,
    required String vehicleType,
    required Position position,
    required double heading,
  }) async {
    if (_activePresenceId != presenceId) return;

    // Preserve backend-owned fields such as activeRideId while refreshing the
    // driver's public location and heartbeat data.
    await reference.update(<String, Object?>{
      'driverId': _activeDriverId,
      'presenceId': presenceId,
      'latitude': position.latitude,
      'longitude': position.longitude,
      'heading': DriverHeadingPolicy.normalizedHeading(heading),
      'accuracy': position.accuracy,
      'isOnline': true,
      'online': true,
      'vehicleType': vehicleType,
      'vehicleClass': vehicleType,
      'updatedAt': ServerValue.timestamp,
      'lastUpdated': ServerValue.timestamp,
    });

    if (_activePresenceId != presenceId) {
      await _removePresenceIfOwned(reference, presenceId);
    }
  }

  Future<void> _startPositionUpdates({
    required DatabaseReference reference,
    required String presenceId,
    required String vehicleType,
    required LocationSettings settings,
  }) async {
    final StreamSubscription<Position>? previous = _positionSubscription;
    _positionSubscription = null;
    await previous?.cancel();

    if (_activePresenceId != presenceId) return;

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: settings,
    ).listen(
      (Position position) {
        _positionRestartTimer?.cancel();
        _positionRestartTimer = null;
        _positionRestartAttempts = 0;

        final double heading = _resolveHeading(position);
        unawaited(
          _publishPosition(
            reference: reference,
            presenceId: presenceId,
            vehicleType: vehicleType,
            position: position,
            heading: heading,
          ).catchError((Object error) {
            debugPrint('Unable to publish the driver location: $error');
          }),
        );
      },
      onError: (Object error) {
        debugPrint('Driver location stream paused: $error');
        _schedulePositionRestart(
          reference: reference,
          presenceId: presenceId,
          vehicleType: vehicleType,
          settings: settings,
        );
      },
      onDone: () {
        _schedulePositionRestart(
          reference: reference,
          presenceId: presenceId,
          vehicleType: vehicleType,
          settings: settings,
        );
      },
      cancelOnError: true,
    );
  }

  void _schedulePositionRestart({
    required DatabaseReference reference,
    required String presenceId,
    required String vehicleType,
    required LocationSettings settings,
  }) {
    if (_activePresenceId != presenceId ||
        _positionRestartTimer?.isActive == true) {
      return;
    }

    _positionRestartTimer = Timer(const Duration(seconds: 3), () {
      _positionRestartTimer = null;
      unawaited(
        _recoverPositionUpdates(
          reference: reference,
          presenceId: presenceId,
          vehicleType: vehicleType,
          settings: settings,
        ),
      );
    });
  }

  Future<void> _recoverPositionUpdates({
    required DatabaseReference reference,
    required String presenceId,
    required String vehicleType,
    required LocationSettings settings,
  }) async {
    if (_activePresenceId != presenceId) return;

    try {
      final bool locationEnabled = await Geolocator.isLocationServiceEnabled();
      final LocationPermission permission = await Geolocator.checkPermission();
      if (!locationEnabled ||
          permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw const DriverPresenceException(
          'Location access is unavailable while the driver is online.',
        );
      }

      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );
      if (_activePresenceId != presenceId) return;

      final double heading = _resolveHeading(position);
      await _publishPosition(
        reference: reference,
        presenceId: presenceId,
        vehicleType: vehicleType,
        position: position,
        heading: heading,
      );

      _positionRestartAttempts = 0;
      await _startPositionUpdates(
        reference: reference,
        presenceId: presenceId,
        vehicleType: vehicleType,
        settings: settings,
      );
    } on Object catch (error) {
      if (_activePresenceId != presenceId) return;

      _positionRestartAttempts += 1;
      debugPrint(
        'Unable to restore driver location '
        '(attempt $_positionRestartAttempts): $error',
      );

      // Temporary indoor GPS gaps must not unexpectedly take a working
      // driver offline. Keep the last verified presence and heartbeat alive
      // while the stream continues recovering.
      _positionRestartAttempts = min(_positionRestartAttempts, 10);
      _schedulePositionRestart(
        reference: reference,
        presenceId: presenceId,
        vehicleType: vehicleType,
        settings: settings,
      );
    }
  }

  void _startConnectionRecovery({
    required DatabaseReference reference,
    required String presenceId,
    required String vehicleType,
  }) {
    unawaited(_connectionSubscription?.cancel());
    _connectionSubscription = _database.ref('.info/connected').onValue.listen(
      (DatabaseEvent event) {
        if (event.snapshot.value != true ||
            _activePresenceId != presenceId) {
          return;
        }

        unawaited(
          _restoreConnectedPresence(
            reference: reference,
            presenceId: presenceId,
            vehicleType: vehicleType,
          ).catchError((Object error) {
            debugPrint('Unable to restore driver availability: $error');
          }),
        );
      },
      onError: (Object error) {
        debugPrint('Driver connection monitor paused: $error');
      },
    );
  }

  Future<void> _restoreConnectedPresence({
    required DatabaseReference reference,
    required String presenceId,
    required String vehicleType,
  }) async {
    final Position? position = _lastPublishedPosition;
    if (_activePresenceId != presenceId || position == null) return;

    await reference.onDisconnect().update(<String, Object?>{
      'isOnline': false,
      'updatedAt': ServerValue.timestamp,
    });
    if (_activePresenceId != presenceId) return;

    await _publishPosition(
      reference: reference,
      presenceId: presenceId,
      vehicleType: vehicleType,
      position: position,
      heading: _lastPublishedHeading ?? 0,
    );
    await _refreshHeartbeat(reference, presenceId);
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

    // Reconcile server ride locks while online, including after reconnects.
    // A transient failure leaves presence online and retries next heartbeat.
    if (!_reconcilingAvailability) {
      _reconcilingAvailability = true;
      unawaited(
        _prepareAvailability()
            .then((availability) {
              if (_activePresenceId != presenceId) return;
              _cachedAvailability = availability;
              _cachedAvailabilityAt = DateTime.now();
            })
            .catchError((Object error) {
              debugPrint(
                'Unable to reconcile driver ride availability: $error',
              );
            })
            .whenComplete(() => _reconcilingAvailability = false),
      );
    }

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

  Future<void> goOffline() => _clearPresence(cancelOnlineAttempt: true);

  Future<void> _clearPresence({required bool cancelOnlineAttempt}) async {
    if (cancelOnlineAttempt) _onlineAttempt = null;
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _positionRestartTimer?.cancel();
    _positionRestartTimer = null;
    _positionRestartAttempts = 0;
    await _connectionSubscription?.cancel();
    _connectionSubscription = null;
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
