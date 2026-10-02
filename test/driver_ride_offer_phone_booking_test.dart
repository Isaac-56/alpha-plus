import 'package:alpha_plus/features/rides/data/driver_ride_offer_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('phone booking offer is labelled without customer contact details', () {
    final DriverRideOffer offer = DriverRideOffer.fromMap(
      rideId: 'ride-phone',
      data: <String, dynamic>{
        'status': 'pending',
        'bookingSource': 'call_center',
        'pickup': <String, dynamic>{'address': 'Juba Airport'},
        'destination': <String, dynamic>{'address': 'Hai Malakal'},
        'rideOptionId': 'standard',
        'requiredVehicleType': 'standard',
        'paymentMethod': 'cash',
        'estimatedFare': 15000,
        'currencyCode': 'SSP',
        'distanceToPickupMeters': 850,
        'expiresAt': Timestamp.fromDate(
          DateTime.now().add(const Duration(minutes: 1)),
        ),
      },
    );

    expect(offer.isPhoneBooking, isTrue);
    expect(offer.bookingSource, 'call_center');
  });
}
