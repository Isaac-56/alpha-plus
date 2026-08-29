import 'package:alpha_plus/core/theme/app_theme.dart';
import 'package:alpha_plus/features/onboarding/presentation/service_registration_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'service registration keeps launch choices honest and continues',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const ServiceRegistrationScreen(driverName: 'Test Driver'),
        ),
      );

      expect(find.text('Juba, South Sudan'), findsOneWidget);
      expect(find.text('Passenger rides'), findsOneWidget);
      expect(find.text('Available'), findsOneWidget);
      expect(find.text('Delivery'), findsOneWidget);
      expect(find.text('Coming soon'), findsOneWidget);

      await tester.ensureVisible(find.byKey(const Key('deliveryService')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('deliveryService')));
      await tester.pump();
      expect(find.text('Welcome, Test'), findsNothing);

      await tester.tap(find.byKey(const Key('continueServiceRegistration')));
      await tester.pumpAndSettle();

      expect(find.text('Welcome, Test'), findsOneWidget);
      expect(find.text('Your starting setup'), findsOneWidget);
      expect(find.text('Passenger rides'), findsOneWidget);
      expect(find.text('Juba, South Sudan'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'service and completion pages support narrow large-text layouts',
    (WidgetTester tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(280, 600);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      for (final ThemeData theme in <ThemeData>[
        AppTheme.light,
        AppTheme.dark,
      ]) {
        await tester.pumpWidget(
          MaterialApp(
            key: UniqueKey(),
            theme: theme,
            home: Builder(
              builder: (BuildContext context) {
                return MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: const TextScaler.linear(1.6)),
                  child: const ServiceRegistrationScreen(
                    driverName: 'Test Driver',
                  ),
                );
              },
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byKey(const Key('deliveryService')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        await tester.tap(find.byKey(const Key('continueServiceRegistration')));
        await tester.pumpAndSettle();
        await tester.ensureVisible(
          find.byKey(const Key('stageOneSelectionSummary')),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets('completion page opens the existing vehicle registration flow', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const ServiceRegistrationScreen(driverName: 'Test Driver'),
      ),
    );

    await tester.tap(find.byKey(const Key('continueServiceRegistration')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('continueToVehicleSetup')));
    await tester.pumpAndSettle();

    expect(find.text('Enter your vehicle details'), findsOneWidget);
    expect(find.text('Type of vehicle'), findsOneWidget);
    expect(find.text('Vehicle plate number'), findsOneWidget);
  });
}
