import 'package:alpha_plus/core/theme/app_theme.dart';
import 'package:alpha_plus/features/dashboard/presentation/driver_detail_screens.dart';
import 'package:alpha_plus/features/dashboard/presentation/driver_shell.dart';
import 'package:alpha_plus/features/onboarding/models/driver_registration.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'remaining dashboard pages do not present placeholder data as live',
    (WidgetTester tester) async {
      final DriverRegistration registration = DriverRegistration()
        ..serviceType = DriverRegistration.ridesService
        ..vehicleType = 'Car'
        ..make = 'Toyota'
        ..model = 'Corolla'
        ..color = 'White'
        ..manufactureYear = '2020'
        ..plateNumber = 'SSD 1234';

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: DriverShell(
            driverId: 'driver-test-123',
            driverName: 'Test Driver',
            reviewStatus: 'pending',
            registration: registration,
            mapBuilder: (_) => const ColoredBox(color: Color(0xFFE9F7E7)),
          ),
        ),
      );

      await tester.pump();

      expect(find.byType(Badge), findsNothing);

      await tester.tap(find.text('Money'));
      await tester.pump();

      expect(find.text('Earnings not available yet'), findsOneWidget);
      expect(find.text('SSP 0'), findsNothing);

      await tester.tap(find.text('Profile'));
      await tester.pump();

      expect(find.text('Account under review'), findsOneWidget);
      expect(find.text('+100'), findsNothing);
      expect(find.text('5.0'), findsNothing);
      expect(find.text('Trips'), findsOneWidget);
    },
  );

  testWidgets('support page clearly states messaging is not connected', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const SupportConversationScreen(),
      ),
    );

    await tester.pump();

    expect(
      find.text('In-app support messaging is not connected in this build.'),
      findsOneWidget,
    );
    expect(find.byType(TextField), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('privacy page documents implemented boundaries', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const PrivacySecurityScreen()),
    );

    await tester.pump();

    expect(find.text('Active driver session'), findsOneWidget);
    expect(find.text('Quick unlock'), findsOneWidget);
    expect(find.text('Driver location'), findsOneWidget);
    expect(find.text('Documents and photo checks'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
