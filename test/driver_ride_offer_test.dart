import 'package:alpha_plus/features/rides/data/driver_ride_offer_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('driver ride offer parses trusted backend fields', () {
    final DateTime expiry = DateTime.utc(2026, 9, 3, 20);

    final DriverRideOffer offer = DriverRideOffer.fromMap(
      rideId: 'ride-123',
      data: <String, dynamic>{
        'status': 'pending',
        'pickup': <String, dynamic>{'address': 'Juba Airport'},
        'destination': <String, dynamic>{'address': 'Hai Malakal'},
        'rideOptionId': 'standard',
        'requiredVehicleType': 'standard',
        'paymentMethod': 'cash',
        'estimatedFare': 15000,
        'currencyCode': 'SSP',
        'distanceToPickupMeters': 850,
        'expiresAt': expiry,
      },
    );

    expect(offer.rideId, 'ride-123');
    expect(offer.pickupAddress, 'Juba Airport');
    expect(offer.destinationAddress, 'Hai Malakal');
    expect(offer.estimatedFare, 15000);
    expect(
      offer.isPendingAt(expiry.subtract(const Duration(seconds: 1))),
      isTrue,
    );
    expect(offer.isPendingAt(expiry), isFalse);
  });

  test('malformed or untrusted offers are rejected', () {
    expect(
      () => DriverRideOffer.fromMap(
        rideId: 'ride-123',
        data: <String, dynamic>{
          'status': 'pending',
          'pickup': <String, dynamic>{'address': ''},
          'destination': <String, dynamic>{'address': 'Hai Malakal'},
          'rideOptionId': 'standard',
          'requiredVehicleType': 'standard',
          'paymentMethod': 'cash',
          'estimatedFare': 15000,
          'currencyCode': 'SSP',
          'distanceToPickupMeters': 850,
          'expiresAt': DateTime.utc(2026, 9, 3, 20),
        },
      ),
      throwsFormatException,
    );
  });
}
