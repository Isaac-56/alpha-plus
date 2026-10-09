import 'dart:async';

import 'package:alpha_plus/features/rides/data/driver_active_ride_service.dart';
import 'package:alpha_plus/features/rides/data/driver_ride_offer_service.dart';
import 'package:alpha_plus/features/rides/presentation/driver_ride_offer_layer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _Firestore extends Fake implements FirebaseFirestore {}

class _Functions extends Fake implements FirebaseFunctions {}

class _ActiveRides extends DriverActiveRideService {
  _ActiveRides() : super(firestore: _Firestore(), functions: _Functions());
  final StreamController<String?> ids = StreamController<String?>.broadcast();
  final StreamController<DriverActiveRide?> rides =
      StreamController<DriverActiveRide?>.broadcast();
  final Completer<void> completion = Completer<void>();
  int watchedRides = 0;

  @override
  Stream<String?> watchActiveRideId(String driverId) => ids.stream;
  @override
  Stream<DriverActiveRide?> watchRide(String rideId) {
    watchedRides++;
    return rides.stream;
  }

  @override
  Future<void> startProgressTracking(String rideId) async {}
  @override
  Future<void> stopProgressTracking([String? rideId]) async {}
  @override
  Future<void> advanceRide({
    required String rideId,
    required String status,
  }) async {
    // The transaction removes the active pointer before the callable responds.
    ids.add(null);
    await completion.future;
  }

  @override
  Map<String, dynamic>? completionForRide(String rideId) => <String, dynamic>{
        'finalFare': 32700,
        'waitingCharge': 200,
        'platformFee': 3270,
        'driverNetFare': 29430,
        'receiptNumber': 'AR-TEST',
      };
}

class _Offers extends DriverRideOfferService {
  _Offers() : super(firestore: _Firestore(), functions: _Functions());
  @override
  Stream<List<DriverRideOffer>> watchPendingOffers(String driverId) =>
      Stream<List<DriverRideOffer>>.value(<DriverRideOffer>[]);
}

void main() {
  testWidgets(
    'final fare survives active-pointer removal before completion response',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 950));
      final _ActiveRides service = _ActiveRides();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DriverRideOfferLayer(
              driverId: 'driver-1',
              activeRideService: service,
              service: _Offers(),
              child: const Center(child: Text('Ready for requests')),
            ),
          ),
        ),
      );
      service.ids.add('ride-123');
      await tester.pump();
      await tester.pump();
      service.rides.add(
        const DriverActiveRide(
          rideId: 'ride-123',
          status: 'in_progress',
          pickupAddress: 'Pickup',
          destinationAddress: 'Destination',
          rideOptionId: 'standard',
          paymentMethod: 'cash',
          estimatedFare: 100000,
          currencyCode: 'SSP',
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('End trip here'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'End trip here'));
      await tester.pump();
      await tester.pump();
      expect(find.text('Ready for requests'), findsOneWidget);
      service.completion.complete();
      await tester.pumpAndSettle();
      expect(find.text('Trip completed'), findsOneWidget);
      expect(find.text('Final fare: 32700 SSP'), findsOneWidget);
      expect(service.watchedRides, 1);
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox());
      await service.ids.close();
      await service.rides.close();
      await tester.binding.setSurfaceSize(null);
    },
  );
}
