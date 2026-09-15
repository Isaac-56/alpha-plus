import 'package:cloud_firestore/cloud_firestore.dart';

class DriverTripRecord {
  const DriverTripRecord({
    required this.rideId,
    required this.status,
    required this.pickupAddress,
    required this.destinationAddress,
    required this.rideOptionId,
    required this.paymentMethod,
    required this.estimatedFare,
    required this.finalFare,
    required this.currencyCode,
    required this.activityAt,
  });

  final String rideId;
  final String status;
  final String pickupAddress;
  final String destinationAddress;
  final String rideOptionId;
  final String paymentMethod;
  final int estimatedFare;
  final int? finalFare;
  final String currencyCode;
  final DateTime? activityAt;

  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';
  int get grossFare => finalFare ?? estimatedFare;

  factory DriverTripRecord.fromMap({
    required String rideId,
    required Map<String, dynamic> data,
  }) {
    final Map<String, dynamic> pickup = _map(data['pickup']);
    final Map<String, dynamic> destination = _map(data['destination']);
    final String status = _string(data['status']).toLowerCase();
    if (status != 'completed' && status != 'cancelled') {
      throw const FormatException('Ride is not terminal driver activity.');
    }

    return DriverTripRecord(
      rideId: rideId,
      status: status,
      pickupAddress: _string(pickup['address']),
      destinationAddress: _string(destination['address']),
      rideOptionId: _string(data['rideOptionId']).toLowerCase(),
      paymentMethod: _string(data['paymentMethod']).toLowerCase(),
      estimatedFare: _int(data['estimatedFare']),
      finalFare: data['finalFare'] == null ? null : _int(data['finalFare']),
      currencyCode: _string(data['currencyCode'], fallback: 'SSP').toUpperCase(),
      activityAt: _firstDate(<Object?>[
        data['completedAt'],
        data['cancelledAt'],
        data['updatedAt'],
        data['requestedAt'],
      ]),
    );
  }
}

class DriverTripHistoryService {
  DriverTripHistoryService({FirebaseFirestore? firestore})
      : _firestore = firestore;

  static final DriverTripHistoryService instance = DriverTripHistoryService();

  final FirebaseFirestore? _firestore;

  Stream<List<DriverTripRecord>> watchTrips(String driverId) {
    final String normalized = driverId.trim();
    if (normalized.isEmpty) {
      return Stream<List<DriverTripRecord>>.value(
        const <DriverTripRecord>[],
      );
    }

    try {
      final FirebaseFirestore firestore =
          _firestore ?? FirebaseFirestore.instance;
      return firestore
          .collection('rides')
          .where('driverId', isEqualTo: normalized)
          .snapshots()
          .map((QuerySnapshot<Map<String, dynamic>> snapshot) {
        final List<DriverTripRecord> trips = <DriverTripRecord>[];

        for (final QueryDocumentSnapshot<Map<String, dynamic>> document
            in snapshot.docs) {
          try {
            trips.add(
              DriverTripRecord.fromMap(
                rideId: document.id,
                data: document.data(),
              ),
            );
          } on FormatException {
            // Active or malformed rides are not presented as completed activity.
          }
        }

        trips.sort((DriverTripRecord first, DriverTripRecord second) {
          final int firstMs = first.activityAt?.millisecondsSinceEpoch ?? 0;
          final int secondMs = second.activityAt?.millisecondsSinceEpoch ?? 0;
          return secondMs.compareTo(firstMs);
        });
        return List<DriverTripRecord>.unmodifiable(trips);
      });
    } on Object {
      // Widget tests and pre-Firebase startup states should render an empty,
      // truthful view instead of crashing while no Firebase app exists yet.
      return Stream<List<DriverTripRecord>>.value(
        const <DriverTripRecord>[],
      );
    }
  }
}

Map<String, dynamic> _map(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return const <String, dynamic>{};
}

String _string(Object? value, {String fallback = ''}) {
  if (value is! String || value.trim().isEmpty) return fallback;
  return value.trim();
}

int _int(Object? value) {
  if (value is int) return value;
  if (value is num && value.isFinite && value == value.roundToDouble()) {
    return value.toInt();
  }
  throw const FormatException('Fare must be an integer.');
}

DateTime? _firstDate(Iterable<Object?> values) {
  for (final Object? value in values) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
  }
  return null;
}
