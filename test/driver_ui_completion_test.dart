import 'package:alpha_plus/core/theme/app_theme.dart';
import 'package:alpha_plus/features/dashboard/presentation/driver_ui_pages.dart';
import 'package:alpha_plus/features/onboarding/models/driver_registration.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  DriverRegistration completeRegistration() {
    return DriverRegistration()
      ..serviceType = DriverRegistration.ridesService
      ..vehicleType = 'Car'
      ..make = 'Toyota'
      ..model = 'Corolla'
      ..color = 'White'
      ..manufactureYear = '2020'
      ..plateNumber = 'SSD 123 A'
      ..licenceCountry = 'South Sudan'
      ..licenceFirstName = 'Test'
      ..licenceLastName = 'Driver'
      ..licenceNumber = 'DL-12345'
      ..licenceIssueDate = '2025-01-20';
  }

  Future<void> pumpPage(
    WidgetTester tester,
    Widget page, {
    Size size = const Size(390, 844),
    double textScale = 1,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        builder: (BuildContext context, Widget? child) {
          return MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          );
        },
        home: page,
      ),
    );
    await tester.pump();
  }

  testWidgets('pool UI reports real readiness without fake requests', (
    WidgetTester tester,
  ) async {
    await pumpPage(
      tester,
      DriverPoolPageUi(
        reviewStatus: 'pending',
        registration: completeRegistration(),
      ),
      size: const Size(320, 640),
      textScale: 1.4,
    );

    expect(find.text('Order pool'), findsOneWidget);
    expect(find.text('Account review in progress'), findsOneWidget);
    expect(find.text('Request readiness'), findsOneWidget);
    expect(find.text('How a request will work'), findsOneWidget);
    expect(find.textContaining('fake trips'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('money UI keeps unverified values blank', (
    WidgetTester tester,
  ) async {
    await pumpPage(tester, const DriverMoneyPageUi());

    expect(find.text('Money'), findsOneWidget);
    expect(find.text('Earnings not available yet'), findsOneWidget);
    expect(find.text('— SSP'), findsNWidgets(2));
    expect(find.text('Balance limit'), findsOneWidget);
    expect(find.text('SSP 0'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('inbox UI has complete navigation surfaces without fake unread', (
    WidgetTester tester,
  ) async {
    await pumpPage(tester, const DriverInboxPageUi());

    expect(find.text('Inbox'), findsOneWidget);
    expect(find.text('No unread service alerts'), findsOneWidget);
    expect(find.text('Safety center'), findsOneWidget);
    expect(find.text('Help center'), findsOneWidget);
    expect(find.text('Notifications'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('profile exposes complete driver page navigation', (
    WidgetTester tester,
  ) async {
    await pumpPage(
      tester,
      DriverProfilePageUi(
        driverName: 'Test Driver',
        reviewStatus: 'pending',
        registration: completeRegistration(),
      ),
      size: const Size(320, 640),
      textScale: 1.4,
    );

    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Account under review'), findsOneWidget);
    expect(find.byKey(const Key('driverMyServicesButton')), findsOneWidget);
    expect(find.text('Trips'), findsOneWidget);

    await tester.ensureVisible(find.text('Account status'));
    expect(find.text('Account status'), findsOneWidget);

    await tester.ensureVisible(find.text('Documents'));
    expect(find.text('Documents'), findsOneWidget);

    await tester.ensureVisible(find.text('Payment'));
    expect(find.text('Payment'), findsOneWidget);

    await tester.ensureVisible(find.text('Safety center'));
    expect(find.text('Safety center'), findsOneWidget);

    await tester.ensureVisible(find.text('Settings'));
    expect(find.text('Settings'), findsOneWidget);

    expect(tester.takeException(), isNull);
  });

  testWidgets('licence details show current registration values', (
    WidgetTester tester,
  ) async {
    await pumpPage(
      tester,
      DriverLicenceDetailsScreen(registration: completeRegistration()),
    );

    expect(find.text('Licence information'), findsOneWidget);
    expect(find.text('South Sudan'), findsOneWidget);
    expect(find.text('DL-12345'), findsOneWidget);
    expect(find.text('2025-01-20'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('activity page never invents trip metrics', (
    WidgetTester tester,
  ) async {
    await pumpPage(tester, const DriverActivityScreen());

    expect(find.text('Trip activity'), findsOneWidget);
    expect(find.text('No verified trip history yet'), findsOneWidget);
    expect(find.text('Completed trips'), findsOneWidget);
    expect(find.text('—'), findsNWidgets(3));
    expect(tester.takeException(), isNull);
  });
}
