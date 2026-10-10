import 'package:alpha_plus/core/theme/app_theme.dart';
import 'package:alpha_plus/features/onboarding/models/driver_registration.dart';
import 'package:alpha_plus/features/onboarding/presentation/device_setup_screen.dart';
import 'package:alpha_plus/features/profile/data/driver_profile_repository.dart';
import 'package:alpha_plus/features/profile/models/driver_profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('device setup supports short narrow large-text layouts', (
    WidgetTester tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(280, 480);

    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final DriverRegistration registration = DriverRegistration()
      ..serviceType = DriverRegistration.ridesService
      ..vehicleType = 'Car'
      ..make = 'Toyota'
      ..model = 'Corolla'
      ..color = 'White'
      ..manufactureYear = '2020'
      ..plateNumber = 'SSD 1234'
      ..licenceCountry = 'South Sudan'
      ..licenceFirstName = 'Test'
      ..licenceLastName = 'Driver'
      ..licenceNumber = 'DL-12345'
      ..licenceIssueDate = '24/08/2026';

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (BuildContext context) {
            return MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(2)),
              child: DeviceSetupScreen(
                driverName: 'Test Driver',
                registration: registration,
                userId: 'driver-test-123',
                profileStore: _FakeDriverProfileStore(),
              ),
            );
          },
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byKey(const Key('deviceSetupPanel')), findsOneWidget);

    expect(find.text('Set up your device'), findsOneWidget);

    expect(find.text('Screen overlay'), findsOneWidget);

    expect(find.text('Background location access'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('completeDeviceSetup')));

    await tester.pumpAndSettle();

    expect(find.byKey(const Key('completeDeviceSetup')), findsOneWidget);

    expect(tester.takeException(), isNull);
  });
}

class _FakeDriverProfileStore implements DriverProfileStore {
  @override
  Stream<DriverProfile?> watchProfile(String uid) {
    return Stream<DriverProfile?>.empty();
  }

  @override
  Future<DriverProfile?> fetchProfile(String uid) async {
    return null;
  }

  @override
  Future<void> saveIdentity({
    required String uid,
    required String phoneNumber,
    required String firstName,
    required String lastName,
  }) async {}

  @override
  Future<void> completeOnboarding({
    required String uid,
    required DriverRegistration registration,
  }) async {}
}
