import 'package:alpha_plus/features/rides/data/driver_active_ride_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('active ride parses trusted backend fields and lifecycle action', () {
    final DriverActiveRide ride = DriverActiveRide.fromMap(
      rideId: 'ride-123',
      data: <String, dynamic>{
        'status': 'accepted',
        'pickup': <String, dynamic>{'address': 'Juba Airport'},
        'destination': <String, dynamic>{'address': 'Hai Malakal'},
        'rideOptionId': 'standard',
        'paymentMethod': 'cash',
        'estimatedFare': 15000,
        'currencyCode': 'SSP',
      },
    );

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
        'estimatedFare': 42000,
        'currencyCode': 'SSP',
        'isWaiting': true,
        'waitingStartedAt': Timestamp.fromDate(
          now.subtract(const Duration(minutes: 3)),
        ),
        'waitingSeconds': 0,
        'billableWaitingSeconds': 0,
        'waitingCharge': 0,
        'waitingGraceSeconds': 120,
        'waitingRatePerMinute': 450,
      },
    );

    expect(ride.waitingSecondsAt(now), 180);
    expect(ride.billableWaitingSecondsAt(now), 60);
    expect(ride.waitingChargeAt(now), 500);
    expect(ride.fareAt(now), 42500);
  });
}