import 'package:alpha_plus/features/rides/data/driver_trip_history_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('completed trip prefers final fare when available', () {
    final DriverTripRecord trip = DriverTripRecord.fromMap(
      rideId: 'ride-1',
      data: <String, dynamic>{
        'status': 'completed',
        'pickup': <String, dynamic>{'address': 'Imperial Plaza'},
        'destination': <String, dynamic>{'address': 'Juba Airport'},
        'rideOptionId': 'standard',
        'paymentMethod': 'cash',
        'estimatedFare': 10000,
        'finalFare': 10500,
        'currencyCode': 'SSP',
        'completedAt': Timestamp.fromMillisecondsSinceEpoch(2000),
      },
    );

    expect(trip.isCompleted, true);
    expect(trip.grossFare, 10500);
    expect(trip.pickupAddress, 'Imperial Plaza');
    expect(trip.destinationAddress, 'Juba Airport');
  });

  test('completed trip falls back to trusted estimated fare', () {
    final DriverTripRecord trip = DriverTripRecord.fromMap(
      rideId: 'ride-2',
      data: <String, dynamic>{
        'status': 'completed',
        'pickup': <String, dynamic>{'address': 'A'},
        'destination': <String, dynamic>{'address': 'B'},
        'rideOptionId': 'boda',
        'paymentMethod': 'cash',
        'estimatedFare': 4500,
        'finalFare': null,
        'currencyCode': 'SSP',
      },
    );

    expect(trip.grossFare, 4500);
  });

  test('active rides cannot appear as terminal trip activity', () {
    for (final String status in <String>[
      'requested',
      'offered',
      'accepted',
      'driver_arriving',
      'arrived',
      'in_progress',
    ]) {
      expect(
        () => DriverTripRecord.fromMap(
          rideId: 'ride-$status',
          data: <String, dynamic>{
            'status': status,
            'estimatedFare': 10000,
          },
        ),
        throwsFormatException,
      );
    }
  });

  test('cancelled ride remains activity but not completed income', () {
    final DriverTripRecord trip = DriverTripRecord.fromMap(
      rideId: 'ride-cancelled',
      data: <String, dynamic>{
        'status': 'cancelled',
        'pickup': <String, dynamic>{'address': 'A'},
        'destination': <String, dynamic>{'address': 'B'},
        'rideOptionId': 'standard',
        'paymentMethod': 'cash',
        'estimatedFare': 12000,
        'currencyCode': 'SSP',
      },
    );

    expect(trip.isCancelled, true);
    expect(trip.isCompleted, false);
  });
}
