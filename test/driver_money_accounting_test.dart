import 'package:alpha_plus/core/theme/app_theme.dart';
import 'package:alpha_plus/features/rides/data/driver_trip_history_service.dart';
import 'package:alpha_plus/features/rides/presentation/driver_money_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('money page shows prepaid wallet, completed count and driver net', (
    WidgetTester tester,
  ) async {
    final DriverTripRecord trip = DriverTripRecord.fromMap(
      rideId: 'ride-accounted',
      data: <String, dynamic>{
        'status': 'completed',
        'pickup': <String, dynamic>{'address': 'Custom Market'},
        'destination': <String, dynamic>{'address': 'Juba Airport'},
        'rideOptionId': 'standard',
        'paymentMethod': 'cash',
        'estimatedFare': 20000,
        'finalFare': 20000,
        'currencyCode': 'SSP',
        'platformCommissionBps': 1000,
        'platformFee': 2000,
        'driverNetFare': 18000,
        'cashCollectedByDriver': 20000,
        'settlementStatus': 'wallet_deducted',
      },
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: DriverMoneyPage(
            driverId: 'driver-1',
            service: _FakeTripHistoryService(<DriverTripRecord>[trip]),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('1 completed trip'), findsOneWidget);
    expect(find.text('Alpha driver wallet'), findsOneWidget);
    expect(find.text('Gross earnings'), findsOneWidget);
    expect(find.text('20,000 SSP'), findsAtLeastNWidgets(1));
    expect(find.text('Driver net'), findsOneWidget);
    expect(find.text('18,000 SSP'), findsOneWidget);
    expect(find.textContaining('deducts its 10% platform fee'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('money accounting remains usable on a narrow phone', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: DriverMoneyPage(
            driverId: 'driver-1',
            service: _FakeTripHistoryService(const <DriverTripRecord>[]),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Alpha driver wallet'), findsOneWidget);
    expect(find.text('Gross earnings'), findsOneWidget);
    expect(find.text('Driver net'), findsOneWidget);
    expect(find.text('Balance limit'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

class _FakeTripHistoryService extends DriverTripHistoryService {
  _FakeTripHistoryService(this.trips);

  final List<DriverTripRecord> trips;

  @override
  Stream<List<DriverTripRecord>> watchTrips(String driverId) =>
      Stream<List<DriverTripRecord>>.value(trips);
}
