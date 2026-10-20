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

class _Rides extends DriverActiveRideService {
  _Rides() : super(firestore: _Firestore(), functions: _Functions());
  final StreamController<String?> ids = StreamController<String?>.broadcast();
  final StreamController<DriverActiveRide?> rides =
      StreamController<DriverActiveRide?>.broadcast();
  @override
  Stream<String?> watchActiveRideId(String driverId) => ids.stream;
  @override
  Stream<DriverActiveRide?> watchRide(String id) => rides.stream;
  @override
  Future<String?> getAssignedPassengerPhoto(String id) async => null;
  @override
  Future<void> stopProgressTracking([String? id]) async {}
}

class _Offers extends DriverRideOfferService {
  _Offers() : super(firestore: _Firestore(), functions: _Functions());
  final StreamController<List<DriverRideOffer>> offers =
      StreamController<List<DriverRideOffer>>.broadcast();
  @override
  Stream<List<DriverRideOffer>> watchPendingOffers(String id) => offers.stream;
}

class _DelayedOffers extends _Offers {
  final Completer<void> first = Completer<void>();
  final Completer<void> second = Completer<void>();
  final List<String> accepted = <String>[];
  @override
  Future<void> acceptRide(String id, {int? dispatchRound}) {
    accepted.add(id);
    return id == 'first' ? first.future : second.future;
  }
}

class _Counts {
  int mounts = 0;
  int disposals = 0;
}

class _Dashboard extends StatefulWidget {
  const _Dashboard(this.counts);
  final _Counts counts;
  @override
  State<_Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<_Dashboard> {
  @override
  void initState() {
    super.initState();
    widget.counts.mounts++;
  }

  @override
  void dispose() {
    widget.counts.disposals++;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      const Center(child: Text('Persistent driver map'));
}

DriverRideOffer offer(String id) => DriverRideOffer(
  rideId: id,
  status: 'pending',
  pickupAddress: 'Pickup',
  destinationAddress: 'Destination',
  rideOptionId: 'boda',
  requiredVehicleType: 'boda',
  paymentMethod: 'cash',
  estimatedFare: 1000,
  currencyCode: 'SSP',
  distanceToPickupMeters: 20,
  expiresAt: DateTime.now().add(const Duration(minutes: 2)),
);
DriverActiveRide ride(String id, String status) => DriverActiveRide(
  rideId: id,
  status: status,
  pickupAddress: 'Pickup',
  destinationAddress: 'Destination',
  rideOptionId: 'boda',
  paymentMethod: 'cash',
  estimatedFare: 1000,
  currencyCode: 'SSP',
);

void main() {
  testWidgets(
    'dashboard and map remain mounted through request, acceptance, completion and the next request',
    (WidgetTester tester) async {
      final _Rides rides = _Rides();
      final _Offers offers = _Offers();
      final _Counts counts = _Counts();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DriverRideOfferLayer(
              driverId: 'driver',
              activeRideService: rides,
              service: offers,
              child: _Dashboard(counts),
            ),
          ),
        ),
      );
      await tester.pump();
      offers.offers.add(<DriverRideOffer>[offer('first')]);
      await tester.pump();
      await tester.pump();
      expect(find.text('Accept ride'), findsOneWidget);
      rides.ids.add('first');
      await tester.pump();
      await tester.pump();
      rides.rides.add(ride('first', 'accepted'));
      await tester.pump();
      await tester.pump();
      expect(find.text('Start pickup route'), findsOneWidget);
      rides.rides.add(ride('first', 'completed'));
      rides.ids.add(null);
      offers.offers.add(<DriverRideOffer>[offer('second')]);
      await tester.pump();
      await tester.pump();
      expect(find.text('Accept ride'), findsOneWidget);
      expect(counts.mounts, 1);
      expect(counts.disposals, 0);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await rides.ids.close();
      await rides.rides.close();
      await offers.offers.close();
    },
  );
  testWidgets('a late previous request response cannot block or reset the next acceptance', (WidgetTester tester) async {
    final _Rides rides = _Rides();
    final _DelayedOffers offers = _DelayedOffers();
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: DriverRideOfferLayer(
      driverId: 'driver', activeRideService: rides, service: offers, child: const SizedBox(),
    ))));
    await tester.pump();
    offers.offers.add(<DriverRideOffer>[offer('first')]);
    await tester.pump(); await tester.pump();
    await tester.tap(find.byKey(const Key('acceptRideOffer')));
    await tester.pump();
    rides.ids.add('first');
    await tester.pump(); await tester.pump();
    rides.rides.add(ride('first', 'accepted'));
    await tester.pump(); await tester.pump();
    rides.ids.add(null);
    offers.offers.add(<DriverRideOffer>[offer('second')]);
    await tester.pump(); await tester.pump();
    await tester.tap(find.byKey(const Key('acceptRideOffer')));
    await tester.pump();
    expect(offers.accepted, <String>['first', 'second']);
    offers.first.completeError(const DriverRideOfferException('Old response failed'));
    await tester.pump(); await tester.pump();
    expect(find.text('Old response failed'), findsNothing);
    expect(tester.widget<ElevatedButton>(find.byKey(const Key('acceptRideOffer'))).onPressed, isNull);
    offers.second.complete();
    await tester.pump(); await tester.pump();
    await tester.pumpWidget(const SizedBox());
    await rides.ids.close(); await rides.rides.close(); await offers.offers.close();
    expect(tester.takeException(), isNull);
  });

}
