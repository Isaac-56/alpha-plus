import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

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

  bool get isActive => activeStatuses.contains(status);

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
        'in_progress' => 'Complete trip',
        _ => 'Update ride',
      };

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
    return _firestore
        .collection('rides')
        .doc(rideId)
        .snapshots()
        .map((DocumentSnapshot<Map<String, dynamic>> snapshot) {
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
      await _functions.httpsCallable('updateRideStatus').call<dynamic>(
        <String, dynamic>{
          'rideId': rideId,
          'status': status,
        },
      );
    } on FirebaseFunctionsException catch (error) {
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
