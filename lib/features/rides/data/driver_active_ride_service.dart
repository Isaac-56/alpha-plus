import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class DriverRideLifecycleException implements Exception {
  const DriverRideLifecycleException(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => message;
}

class DriverActiveRide {
  const DriverActiveRide({
    required this.rideId,
    required this.status,
    required this.pickupAddress,
    required this.destinationAddress,
    required this.rideOptionId,
    required this.paymentMethod,
    required this.estimatedFare,
    required this.currencyCode,
    this.bookingSource = 'app',
    this.customerName = '',
    this.customerPhone = '',
    this.customerNote = '',
    this.customerPhotoUrl = '',
    this.isWaiting = false,
    this.waitingStartedAt,
    this.waitingSeconds = 0,
    this.billableWaitingSeconds = 0,
    this.waitingCharge = 0,
    this.waitingGraceSeconds = 120,
    this.waitingRatePerMinute = 0,
  });

  static const Set<String> activeStatuses = <String>{
    'accepted',
    'driver_arriving',
    'arrived',
    'in_progress',
  };

  final String rideId;
  final String status;
  final String pickupAddress;
  final String destinationAddress;
  final String rideOptionId;
  final String paymentMethod;
  final int estimatedFare;
  final String currencyCode;
  final String bookingSource;
  final String customerName;
  final String customerPhone;
  final String customerNote;
  final String customerPhotoUrl;
  final bool isWaiting;
  final DateTime? waitingStartedAt;
  final int waitingSeconds;
  final int billableWaitingSeconds;
  final int waitingCharge;
  final int waitingGraceSeconds;
  final int waitingRatePerMinute;

  bool get isActive => activeStatuses.contains(status);
  bool get isPhoneBooking => bookingSource == 'call_center';

  String? get nextStatus => switch (status) {
        'accepted' => 'driver_arriving',
        'driver_arriving' => 'arrived',
        'arrived' => 'in_progress',
        'in_progress' => 'completed',
        _ => null,
      };

  String get statusLabel => switch (status) {
        'accepted' => 'Ride accepted',
        'driver_arriving' => 'Driving to pickup',
        'arrived' => 'At the pickup point',
        'in_progress' => 'Trip in progress',
        'completed' => 'Trip completed',
        _ => 'Ride update',
      };

  String get actionLabel => switch (status) {
        'accepted' => 'Start pickup route',
        'driver_arriving' => "I've arrived",
        'arrived' => 'Start trip',
        'in_progress' => 'End trip here',
        _ => 'Update ride',
      };

  int waitingSecondsAt(DateTime now) {
    if (!isWaiting || waitingStartedAt == null) return waitingSeconds;
    final int activeSeconds = now
        .difference(waitingStartedAt!)
        .inSeconds
        .clamp(0, 4 * 60 * 60)
        .toInt();
    return waitingSeconds + activeSeconds;
  }

  int billableWaitingSecondsAt(DateTime now) {
    if (!isWaiting || waitingStartedAt == null) {
      return billableWaitingSeconds;
    }
    final int activeSeconds = now
        .difference(waitingStartedAt!)
        .inSeconds
        .clamp(0, 4 * 60 * 60)
        .toInt();
    return billableWaitingSeconds +
        (activeSeconds - waitingGraceSeconds).clamp(0, 4 * 60 * 60).toInt();
  }

  int waitingChargeAt(DateTime now) {
    final int seconds = billableWaitingSecondsAt(now);
    if (seconds == 0 || waitingRatePerMinute <= 0) return waitingCharge;
    final double raw = seconds / 60 * waitingRatePerMinute;
    return (raw / 100).ceil() * 100;
  }

  int fareAt(DateTime now) => estimatedFare + waitingChargeAt(now);

  factory DriverActiveRide.fromMap({
    required String rideId,
    required Map<String, dynamic> data,
  }) {
    final Map<String, dynamic> pickup = _requiredMap(data['pickup'], 'pickup');
    final Map<String, dynamic> destination = _requiredMap(
      data['destination'],
      'destination',
    );

    return DriverActiveRide(
      rideId: _requiredValue(rideId, 'rideId'),
      status: _requiredValue(data['status'], 'status').toLowerCase(),
      pickupAddress: _requiredValue(pickup['address'], 'pickup.address'),
      destinationAddress: _requiredValue(
        destination['address'],
        'destination.address',
      ),
      rideOptionId: _requiredValue(
        data['rideOptionId'],
        'rideOptionId',
      ).toLowerCase(),
      paymentMethod: _requiredValue(
        data['paymentMethod'],
        'paymentMethod',
      ).toLowerCase(),
      estimatedFare: _positiveInt(data['estimatedFare'], 'estimatedFare'),
      currencyCode: _requiredValue(
        data['currencyCode'],
        'currencyCode',
      ).toUpperCase(),
      bookingSource: _optionalValue(
        data['bookingSource'],
        fallback: 'app',
      ).toLowerCase(),
      customerName: _optionalValue(data['customerName']),
      customerPhone: _optionalValue(data['customerPhone']),
      customerNote: _optionalValue(data['customerNote']),
      customerPhotoUrl: _optionalValue(data['customerPhotoUrl']),
      isWaiting: data['isWaiting'] == true,
      waitingStartedAt: _optionalTimestamp(data['waitingStartedAt']),
      waitingSeconds: _nonNegativeInt(data['waitingSeconds']),
      billableWaitingSeconds: _nonNegativeInt(data['billableWaitingSeconds']),
      waitingCharge: _nonNegativeInt(data['waitingCharge']),
      waitingGraceSeconds: _nonNegativeInt(
        data['waitingGraceSeconds'],
        fallback: 120,
      ),
      waitingRatePerMinute: _nonNegativeInt(data['waitingRatePerMinute']),
    );
  }
}

class DriverActiveRideService {
  DriverActiveRideService({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _functions =
            functions ?? FirebaseFunctions.instanceFor(region: 'africa-south1');

  static final DriverActiveRideService instance = DriverActiveRideService();

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;
  StreamSubscription<Position>? _trackingSubscription;
  String? _trackedRideId;
  Position? _lastTrackedPosition;
  bool _progressUpdateInFlight = false;
  String? _completedRideId;
  Map<String, dynamic>? _completion;

  Map<String, dynamic>? completionForRide(String rideId) =>
      _completedRideId == rideId ? _completion : null;

  Stream<String?> watchActiveRideId(String driverId) {
    final String normalized = driverId.trim();
    if (normalized.isEmpty) return Stream<String?>.value(null);

    return _firestore
        .collection('active_driver_rides')
        .doc(normalized)
        .snapshots()
        .map((DocumentSnapshot<Map<String, dynamic>> snapshot) {
      if (!snapshot.exists) return null;
      final Object? value = snapshot.data()?['rideId'];
      return value is String && value.trim().isNotEmpty ? value.trim() : null;
    });
  }

  Stream<DriverActiveRide?> watchRide(String rideId) {
    return _firestore.collection('rides').doc(rideId).snapshots().map((
      DocumentSnapshot<Map<String, dynamic>> snapshot,
    ) {
      final Map<String, dynamic>? data = snapshot.data();
      if (!snapshot.exists || data == null) return null;
      try {
        return DriverActiveRide.fromMap(rideId: snapshot.id, data: data);
      } on FormatException {
        return null;
      }
    });
  }

  Future<void> advanceRide({
    required String rideId,
    required String status,
  }) async {
    try {
      final Map<String, dynamic> request = <String, dynamic>{
        'rideId': rideId,
        'status': status,
      };
      if (status == 'completed') {
        final Position? position = await _completionPosition();
        if (position != null) {
          request['completionPoint'] = _pointFromPosition(position);
        }
      }
      final HttpsCallableResult<dynamic> result = await _functions
          .httpsCallable('updateRideStatus')
          .call<dynamic>(request);
      if (status == 'completed' && result.data is Map) {
        _completedRideId = rideId;
        _completion = Map<String, dynamic>.from(result.data as Map);
      }
      if (status == 'completed') await stopProgressTracking(rideId);
    } on FirebaseFunctionsException catch (error) {
      // A lost callable response must not hide a trip already committed by the server.
      if (status == 'completed') {
        try {
          final DocumentSnapshot<Map<String, dynamic>> snapshot =
              await _firestore
                  .collection('rides')
                  .doc(rideId)
                  .get(const GetOptions(source: Source.server));
          final Map<String, dynamic>? data = snapshot.data();
          if (data?['status'] == 'completed' && data?['finalFare'] is num) {
            _completedRideId = rideId;
            _completion = data;
            await stopProgressTracking(rideId);
            return;
          }
        } on Object {
          // Preserve the original callable error if the connection is still unavailable.
        }
      }
      final String message = switch (error.code) {
        'unauthenticated' => 'Sign in again before updating the ride.',
        'permission-denied' =>
          error.message ?? 'Only the assigned driver can update this ride.',
        'failed-precondition' =>
          error.message ?? 'This ride cannot move to that stage yet.',
        'not-found' => 'This ride no longer exists.',
        _ => error.message ?? 'The ride could not be updated right now.',
      };
      throw DriverRideLifecycleException(message, code: error.code);
    }
  }

  Future<void> startProgressTracking(String rideId) async {
    final String normalized = rideId.trim();
    if (normalized.isEmpty || _trackedRideId == normalized) return;
    await stopProgressTracking();
    _trackedRideId = normalized;

    _trackingSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen(
      (Position position) {
        _lastTrackedPosition = position;
        unawaited(_recordProgress(normalized, position));
      },
      onError: (Object error) {
        debugPrint('Active trip distance tracking paused: $error');
      },
    );
  }

  Future<void> stopProgressTracking([String? rideId]) async {
    if (rideId != null && _trackedRideId != rideId) return;
    _trackedRideId = null;
    _lastTrackedPosition = null;
    final StreamSubscription<Position>? subscription = _trackingSubscription;
    _trackingSubscription = null;
    await subscription?.cancel();
  }

  Future<void> _recordProgress(String rideId, Position position) async {
    if (_trackedRideId != rideId || _progressUpdateInFlight) return;
    if (!position.accuracy.isFinite || position.accuracy > 100) return;
    _progressUpdateInFlight = true;
    try {
      await _functions.httpsCallable('recordRideProgress').call<dynamic>(
        <String, dynamic>{
          'rideId': rideId,
          'point': _pointFromPosition(position),
        },
      );
    } on Object catch (error) {
      debugPrint('Unable to record active trip distance: $error');
    } finally {
      _progressUpdateInFlight = false;
    }
  }

  Future<Position?> _completionPosition() async {
    final Position? trackedPosition = _lastTrackedPosition;
    if (trackedPosition != null &&
        DateTime.now().difference(trackedPosition.timestamp).inSeconds <= 5 &&
        trackedPosition.accuracy <= 100) {
      return trackedPosition;
    }
    try {
      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 3),
        ),
      );
      if (!position.accuracy.isFinite || position.accuracy > 100) {
        throw const DriverRideLifecycleException(
            'Location is not accurate enough to end this trip.');
      }
      return position;
    } on Object {
      throw const DriverRideLifecycleException(
        'A current location is needed to calculate the final fare. Enable location and try again.',
      );
    }
  }

  static Map<String, dynamic> _pointFromPosition(Position position) =>
      <String, dynamic>{
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
      };

  Future<void> setCustomerWaiting({
    required String rideId,
    required bool isWaiting,
  }) async {
    try {
      await _functions.httpsCallable('setRideWaiting').call<dynamic>(
        <String, dynamic>{'rideId': rideId, 'isWaiting': isWaiting},
      );
    } on FirebaseFunctionsException catch (error) {
      final String message = switch (error.code) {
        'unauthenticated' => 'Sign in again before updating waiting time.',
        'permission-denied' =>
          error.message ?? 'Only the assigned driver can manage waiting.',
        'failed-precondition' =>
          error.message ?? 'Waiting cannot be changed at this ride stage.',
        'not-found' => 'This ride no longer exists.',
        _ => error.message ?? 'Waiting time could not be updated right now.',
      };
      throw DriverRideLifecycleException(message, code: error.code);
    }
  }
}

Map<String, dynamic> _requiredMap(Object? value, String field) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  throw FormatException('Ride field "$field" must be a map.');
}

String _requiredValue(Object? value, String field) {
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('Ride field "$field" must be a non-empty string.');
  }
  return value.trim();
}

String _optionalValue(Object? value, {String fallback = ''}) {
  return value is String && value.trim().isNotEmpty ? value.trim() : fallback;
}

int _positiveInt(Object? value, String field) {
  if (value is int && value > 0) return value;
  if (value is num &&
      value.isFinite &&
      value > 0 &&
      value == value.roundToDouble()) {
    return value.toInt();
  }
  throw FormatException('Ride field "$field" must be a positive integer.');
}

int _nonNegativeInt(Object? value, {int fallback = 0}) {
  if (value == null) return fallback;
  if (value is int && value >= 0) return value;
  if (value is num && value.isFinite && value >= 0) return value.round();
  return fallback;
}

DateTime? _optionalTimestamp(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return null;
}
