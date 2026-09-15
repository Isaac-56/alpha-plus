import 'package:alpha_plus/features/rides/data/driver_active_ride_service.dart';
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
}
