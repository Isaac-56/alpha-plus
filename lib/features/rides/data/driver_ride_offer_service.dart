import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

class DriverRideOfferException implements Exception {
  const DriverRideOfferException(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => message;
}

class DriverRideOffer {
  const DriverRideOffer({
    required this.rideId,
    required this.status,
    required this.pickupAddress,
    required this.destinationAddress,
    required this.rideOptionId,
    required this.requiredVehicleType,
    required this.paymentMethod,
    required this.estimatedFare,
    required this.currencyCode,
    required this.distanceToPickupMeters,
    required this.expiresAt,
  });

  final String rideId;
  final String status;
  final String pickupAddress;
  final String destinationAddress;
  final String rideOptionId;
  final String requiredVehicleType;
  final String paymentMethod;
  final int estimatedFare;
  final String currencyCode;
  final int distanceToPickupMeters;
  final DateTime expiresAt;

  bool isPendingAt(DateTime now) =>
      status == 'pending' && expiresAt.isAfter(now);

  factory DriverRideOffer.fromMap({
    required String rideId,
    required Map<String, dynamic> data,
  }) {
    final Map<String, dynamic> pickup = _requiredMap(data['pickup'], 'pickup');
    final Map<String, dynamic> destination = _requiredMap(
      data['destination'],
      'destination',
    );

    final DriverRideOffer offer = DriverRideOffer(
      rideId: rideId.trim(),
      status: _requiredString(data['status'], 'status').toLowerCase(),
      pickupAddress: _requiredString(pickup['address'], 'pickup.address'),
      destinationAddress: _requiredString(
        destination['address'],
        'destination.address',
      ),
      rideOptionId: _requiredString(
        data['rideOptionId'],
        'rideOptionId',
      ).toLowerCase(),
      requiredVehicleType: _requiredString(
        data['requiredVehicleType'],
        'requiredVehicleType',
      ).toLowerCase(),
      paymentMethod: _requiredString(
        data['paymentMethod'],
        'paymentMethod',
      ).toLowerCase(),
      estimatedFare: _requiredPositiveInt(
        data['estimatedFare'],
        'estimatedFare',
      ),
      currencyCode: _requiredString(
        data['currencyCode'],
        'currencyCode',
      ).toUpperCase(),
      distanceToPickupMeters: _requiredNonNegativeInt(
        data['distanceToPickupMeters'],
        'distanceToPickupMeters',
      ),
      expiresAt: _requiredDateTime(data['expiresAt'], 'expiresAt'),
    );

    if (offer.rideId.isEmpty) {
      throw const FormatException('Ride offer ID is missing.');
    }
    return offer;
  }
}

class DriverRideOfferService {
  DriverRideOfferService({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _functions =
           functions ?? FirebaseFunctions.instanceFor(region: 'africa-south1');

  static final DriverRideOfferService instance = DriverRideOfferService();

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  Stream<List<DriverRideOffer>> watchPendingOffers(String driverId) {
    final String normalizedDriverId = driverId.trim();
    if (normalizedDriverId.isEmpty) {
      return Stream<List<DriverRideOffer>>.value(const <DriverRideOffer>[]);
    }

    return _firestore
        .collection('driver_ride_offers')
        .doc(normalizedDriverId)
        .collection('offers')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snapshot) {
          final DateTime now = DateTime.now();
          final List<DriverRideOffer> offers = <DriverRideOffer>[];

          for (final QueryDocumentSnapshot<Map<String, dynamic>> document
              in snapshot.docs) {
            try {
              final DriverRideOffer offer = DriverRideOffer.fromMap(
                rideId: document.id,
                data: document.data(),
              );
              if (offer.isPendingAt(now)) {
                offers.add(offer);
              }
            } on FormatException {
              // Malformed server data is ignored rather than shown to the driver.
            }
          }

          offers.sort(
            (DriverRideOffer first, DriverRideOffer second) => first
                .distanceToPickupMeters
                .compareTo(second.distanceToPickupMeters),
          );
          return offers;
        });
  }

  Future<void> acceptRide(String rideId) => _call('acceptRideOffer', rideId);

  Future<void> rejectRide(String rideId) => _call('rejectRideOffer', rideId);

  Future<void> _call(String functionName, String rideId) async {
    try {
      await _functions.httpsCallable(functionName).call<void>(<String, dynamic>{
        'rideId': rideId,
      });
    } on FirebaseFunctionsException catch (error) {
      throw DriverRideOfferException(
        error.message ?? 'The ride offer could not be updated.',
        code: error.code,
      );
    }
  }
}

Map<String, dynamic> _requiredMap(Object? value, String field) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  throw FormatException('Ride offer field "$field" must be a map.');
}

String _requiredString(Object? value, String field) {
  if (value is! String || value.trim().isEmpty) {
    throw FormatException(
      'Ride offer field "$field" must be a non-empty string.',
    );
  }
  return value.trim();
}

int _requiredPositiveInt(Object? value, String field) {
  final int result = _requiredInt(value, field);
  if (result <= 0) {
    throw FormatException('Ride offer field "$field" must be positive.');
  }
  return result;
}

int _requiredNonNegativeInt(Object? value, String field) {
  final int result = _requiredInt(value, field);
  if (result < 0) {
    throw FormatException('Ride offer field "$field" cannot be negative.');
  }
  return result;
}

int _requiredInt(Object? value, String field) {
  if (value is int) return value;
  if (value is num && value.isFinite && value == value.roundToDouble()) {
    return value.toInt();
  }
  throw FormatException('Ride offer field "$field" must be an integer.');
}

DateTime _requiredDateTime(Object? value, String field) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  throw FormatException('Ride offer field "$field" must be a timestamp.');
}
