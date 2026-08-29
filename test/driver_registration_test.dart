import 'package:alpha_plus/features/onboarding/models/driver_registration.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'driver registration serializes service with vehicle and licence data',
    () {
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

      final Map<String, dynamic> map = registration.toMap();

      expect(map['serviceType'], DriverRegistration.ridesService);

      expect(map['vehicleType'], 'Car');
      expect(map['make'], 'Toyota');
      expect(map['model'], 'Corolla');
      expect(map['color'], 'White');
      expect(map['manufactureYear'], '2020');
      expect(map['plateNumber'], 'SSD 1234');

      expect(map['licenceCountry'], 'South Sudan');
      expect(map['licenceFirstName'], 'Test');
      expect(map['licenceLastName'], 'Driver');
      expect(map['licenceNumber'], 'DL-12345');
      expect(map['licenceIssueDate'], '24/08/2026');
    },
  );

  test('driver registration restores complete persisted registration', () {
    final DriverRegistration registration =
        DriverRegistration.fromMap(<String, dynamic>{
          'serviceType': DriverRegistration.ridesService,
          'vehicleType': 'Car',
          'make': 'Toyota',
          'model': 'Corolla',
          'color': 'White',
          'manufactureYear': '2020',
          'plateNumber': 'SSD 1234',
          'licenceCountry': 'South Sudan',
          'licenceFirstName': 'Test',
          'licenceLastName': 'Driver',
          'licenceNumber': 'DL-12345',
          'licenceIssueDate': '24/08/2026',
        });

    expect(registration.serviceType, DriverRegistration.ridesService);

    expect(registration.serviceComplete, isTrue);

    expect(registration.vehicleType, 'Car');
    expect(registration.make, 'Toyota');
    expect(registration.model, 'Corolla');
    expect(registration.color, 'White');
    expect(registration.manufactureYear, '2020');
    expect(registration.plateNumber, 'SSD 1234');
    expect(registration.vehicleComplete, isTrue);

    expect(registration.licenceCountry, 'South Sudan');
    expect(registration.licenceFirstName, 'Test');
    expect(registration.licenceLastName, 'Driver');
    expect(registration.licenceNumber, 'DL-12345');
    expect(registration.licenceIssueDate, '24/08/2026');
    expect(registration.licenceComplete, isTrue);
  });

  test('older registrations without service type safely default to rides', () {
    final DriverRegistration registration =
        DriverRegistration.fromMap(<String, dynamic>{
          'vehicleType': 'Car',
          'make': 'Toyota',
          'model': 'Corolla',
          'color': 'White',
          'manufactureYear': '2020',
          'plateNumber': 'SSD 1234',
          'licenceCountry': 'South Sudan',
          'licenceFirstName': 'Test',
          'licenceLastName': 'Driver',
          'licenceNumber': 'DL-12345',
          'licenceIssueDate': '24/08/2026',
        });

    expect(registration.serviceType, DriverRegistration.ridesService);

    expect(registration.serviceComplete, isTrue);
    expect(registration.vehicleComplete, isTrue);
    expect(registration.licenceComplete, isTrue);
  });

  test('empty registration remains incomplete except default service', () {
    final DriverRegistration registration = DriverRegistration();

    expect(registration.serviceType, DriverRegistration.ridesService);

    expect(registration.serviceComplete, isTrue);
    expect(registration.vehicleComplete, isFalse);
    expect(registration.licenceComplete, isFalse);
  });
}
