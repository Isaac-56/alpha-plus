import 'package:alpha_plus/core/theme/app_theme.dart';
import 'package:alpha_plus/features/onboarding/models/driver_registration.dart';
import 'package:alpha_plus/features/onboarding/presentation/document_submission_screen.dart';
import 'package:alpha_plus/features/onboarding/presentation/licence_information_screen.dart';
import 'package:alpha_plus/features/onboarding/services/driver_document_uploader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('licence page restores existing registration values', (
    WidgetTester tester,
  ) async {
    final DriverRegistration registration = DriverRegistration()
      ..serviceType = DriverRegistration.ridesService
      ..licenceCountry = 'South Sudan'
      ..licenceFirstName = 'Existing'
      ..licenceLastName = 'Driver'
      ..licenceNumber = 'DL-12345'
      ..licenceIssueDate = '24/08/2026';

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: LicenceInformationScreen(
          driverName: 'Different Name',
          registration: registration,
        ),
      ),
    );

    TextField textFieldInside(Key key) {
      return tester.widget<TextField>(
        find.descendant(of: find.byKey(key), matching: find.byType(TextField)),
      );
    }

    expect(
      textFieldInside(const Key('licenceFirstNameField')).controller!.text,
      'Existing',
    );

    expect(
      textFieldInside(const Key('licenceLastNameField')).controller!.text,
      'Driver',
    );

    expect(
      textFieldInside(const Key('licenceNumberField')).controller!.text,
      'DL-12345',
    );

    expect(
      tester
          .widget<TextField>(find.byKey(const Key('licenceIssueDateField')))
          .controller!
          .text,
      '24/08/2026',
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('licence page preserves the registration object into documents', (
    WidgetTester tester,
  ) async {
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

    final _FakeDriverDocumentUploader uploader = _FakeDriverDocumentUploader();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: LicenceInformationScreen(
          driverName: 'Test Driver',
          registration: registration,
          documentUploader: uploader,
        ),
      ),
    );

    await tester.ensureVisible(
      find.byKey(const Key('continueLicenceInformation')),
    );

    await tester.tap(find.byKey(const Key('continueLicenceInformation')));

    await tester.pumpAndSettle();

    expect(find.byType(DocumentSubmissionScreen), findsOneWidget);

    final DocumentSubmissionScreen documentScreen = tester
        .widget<DocumentSubmissionScreen>(
          find.byType(DocumentSubmissionScreen),
        );

    expect(identical(documentScreen.registration, registration), isTrue);

    expect(
      documentScreen.registration.serviceType,
      DriverRegistration.ridesService,
    );

    expect(documentScreen.registration.vehicleType, 'Car');

    expect(documentScreen.registration.plateNumber, 'SSD 1234');

    expect(documentScreen.registration.licenceNumber, 'DL-12345');

    expect(tester.takeException(), isNull);
  });
}

class _FakeDriverDocumentUploader implements DriverDocumentUploader {
  @override
  Future<void> uploadLicence({
    required String driverId,
    required String frontImagePath,
    required String backImagePath,
  }) async {}
}
