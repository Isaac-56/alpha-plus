import 'package:alpha_plus/core/theme/app_theme.dart';
import 'package:alpha_plus/features/onboarding/presentation/service_registration_screen.dart';
import 'package:alpha_plus/features/onboarding/presentation/vehicle_setup_screen.dart';
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
    expect(find.text('Vehicle category'), findsOneWidget);
    expect(find.text('Vehicle plate number'), findsOneWidget);

    final Finder category = find.text('Vehicle category');
    await tester.ensureVisible(category);
    await tester.pumpAndSettle();
    await tester.tap(category);
    await tester.pumpAndSettle();

    expect(find.text('Car'), findsOneWidget);
    expect(find.text('Tuk-tuk (three-wheeler)'), findsOneWidget);
    expect(find.text('Boda (motorcycle)'), findsOneWidget);
    expect(find.text('Sedan'), findsNothing);
    expect(find.text('Scooter'), findsNothing);
    expect(find.text('Standard'), findsNothing);
    expect(find.text('Comfort'), findsNothing);
  });

  testWidgets('vehicle makes and models stay inside the selected category', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const VehicleSetupScreen(driverName: 'Test Driver'),
      ),
    );

    final Finder categoryPicker = find.byKey(
      const Key('vehicleCategoryPicker'),
    );
    await tester.ensureVisible(categoryPicker);
    await tester.pumpAndSettle();
    await tester.tap(categoryPicker);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Car'));
    await tester.pumpAndSettle();

    final Finder makePicker = find.byKey(const Key('vehicleMakePicker'));
    await tester.ensureVisible(makePicker);
    await tester.pumpAndSettle();
    await tester.tap(makePicker);
    await tester.pumpAndSettle();
    expect(find.text('Toyota'), findsOneWidget);
    expect(find.text('Bajaj'), findsNothing);
    await tester.tap(find.text('Toyota'));
    await tester.pumpAndSettle();

    final Finder modelPicker = find.byKey(const Key('vehicleModelPicker'));
    await tester.ensureVisible(modelPicker);
    await tester.pumpAndSettle();
    await tester.tap(modelPicker);
    await tester.pumpAndSettle();
    expect(find.text('Vitz'), findsOneWidget);
    expect(find.text('Boxer 125'), findsNothing);
    expect(find.text('RE'), findsNothing);
  });
}
