import 'package:alpha_plus/features/rides/data/driver_active_ride_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'running fare uses trusted distance fare, including zero, and waiting',
    () {
      for (final int distanceFare in <int>[0, 1700, 25000]) {
        final ride = DriverActiveRide.fromMap(
          rideId: 'ride',
          data: <String, dynamic>{
            'status': 'in_progress',
            'driverId': 'driver',
            'driverSummary': null,
            'pickup': <String, dynamic>{'address': 'Pickup'},
            'destination': <String, dynamic>{'address': 'Destination'},
            'rideOptionId': 'standard',
            'paymentMethod': 'cash',
            'estimatedFare': 20000,
            'finalFare': null,
            'currencyCode': 'SSP',
            'liveDistanceFare': distanceFare,
            'waitingCharge': 300,
          },
        );
        expect(ride.fareAt(DateTime(2026)), distanceFare + 300);
      }
    },
  );

  test('active ride parses trusted backend fields and lifecycle action', () {
    final DriverActiveRide ride = DriverActiveRide.fromMap(
      rideId: 'ride-123',
      data: <String, dynamic>{
        'status': 'accepted',
        'customerPhotoUrl': 'https://example.com/passenger.jpg',
        'pickup': <String, dynamic>{'address': 'Juba Airport'},
        'destination': <String, dynamic>{'address': 'Hai Malakal'},
        'rideOptionId': 'standard',
        'paymentMethod': 'cash',
        'estimatedFare': 15000,
        'currencyCode': 'SSP',
      },
    );

    expect(ride.customerPhotoUrl, 'https://example.com/passenger.jpg');
    expect(ride.isActive, isTrue);
    expect(ride.nextStatus, 'driver_arriving');
    expect(ride.actionLabel, 'Start pickup route');
    expect(ride.pickupAddress, 'Juba Airport');
    expect(ride.destinationAddress, 'Hai Malakal');
  });

  test('lifecycle action advances through every driver stage', () {
    DriverActiveRide rideFor(String status) => DriverActiveRide.fromMap(
      rideId: 'ride-123',
      data: <String, dynamic>{
        'status': status,
        'pickup': <String, dynamic>{'address': 'Pickup'},
        'destination': <String, dynamic>{'address': 'Destination'},
        'rideOptionId': 'boda',
        'paymentMethod': 'cash',
        'estimatedFare': 4000,
        'currencyCode': 'SSP',
      },
    );

    expect(rideFor('driver_arriving').nextStatus, 'arrived');
    expect(rideFor('arrived').nextStatus, 'in_progress');
    expect(rideFor('in_progress').nextStatus, 'completed');
    expect(rideFor('in_progress').actionLabel, 'End trip here');
    expect(rideFor('completed').isActive, isFalse);
  });

  test('malformed active ride data is rejected', () {
    expect(
      () => DriverActiveRide.fromMap(
        rideId: 'ride-123',
        data: <String, dynamic>{
          'status': 'accepted',
          'pickup': <String, dynamic>{'address': ''},
          'destination': <String, dynamic>{'address': 'Destination'},
          'rideOptionId': 'standard',
          'paymentMethod': 'cash',
          'estimatedFare': 15000,
          'currencyCode': 'SSP',
        },
      ),
      throwsFormatException,
    );
  });

  test('active customer waiting projects proportional fare', () {
    final DateTime now = DateTime.utc(2026, 9, 20, 12, 5);
    final DriverActiveRide ride = DriverActiveRide.fromMap(
      rideId: 'ride-waiting',
      data: <String, dynamic>{
        'status': 'in_progress',
        'pickup': <String, dynamic>{'address': 'Pickup'},
        'destination': <String, dynamic>{'address': 'Destination'},
        'rideOptionId': 'standard',
        'paymentMethod': 'cash',
        'estimatedFare': 100000,
        'currencyCode': 'SSP',
        'isWaiting': true,
        'waitingStartedAt': Timestamp.fromDate(
          now.subtract(const Duration(minutes: 3)),
        ),
        'waitingSeconds': 0,
        'billableWaitingSeconds': 0,
        'waitingCharge': 0,
        'waitingGraceSeconds': 0,
        'waitingRatePerMinute': 100,
      },
    );

    expect(ride.waitingSecondsAt(now), 180);
    expect(ride.billableWaitingSecondsAt(now), 180);
    expect(ride.waitingChargeAt(now), 300);
    expect(ride.fareAt(now), 100300);
  });

  test('phone booking exposes contact only on the assigned active ride', () {
    final DriverActiveRide ride = DriverActiveRide.fromMap(
      rideId: 'call-ride',
      data: <String, dynamic>{
        'status': 'accepted',
        'bookingSource': 'call_center',
        'customerName': 'Mary James',
        'customerPhone': '+211921234567',
        'customerNote': 'Blue gate',
        'pickup': <String, dynamic>{'address': 'Juba Airport'},
        'destination': <String, dynamic>{'address': 'Hai Malakal'},
        'rideOptionId': 'standard',
        'paymentMethod': 'cash',
        'estimatedFare': 15000,
        'currencyCode': 'SSP',
      },
    );

    expect(ride.isPhoneBooking, isTrue);
    expect(ride.customerName, 'Mary James');
    expect(ride.customerPhone, '+211921234567');
    expect(ride.customerNote, 'Blue gate');
  });

  test('app booking exposes passenger phone after assignment', () {
    final DriverActiveRide ride = DriverActiveRide.fromMap(
      rideId: 'app-ride',
      data: <String, dynamic>{
        'status': 'accepted',
        'customerPhone': '+211912345678',
        'pickup': <String, dynamic>{'address': 'Juba Airport'},
        'destination': <String, dynamic>{'address': 'Hai Malakal'},
        'rideOptionId': 'standard',
        'paymentMethod': 'cash',
        'estimatedFare': 15000,
        'currencyCode': 'SSP',
      },
    );

    expect(ride.isPhoneBooking, isFalse);
    expect(ride.customerPhone, '+211912345678');
  });
}
