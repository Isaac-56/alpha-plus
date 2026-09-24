import 'package:alpha_plus/features/onboarding/models/driver_registration.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'driver registration serializes vehicle body separately from Alpha class',
    () {
      final DriverRegistration registration = DriverRegistration()
        ..serviceType = DriverRegistration.ridesService
        ..vehicleType = 'Sedan'
        ..vehicleClass = 'comfort'
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
      expect(map['vehicleType'], 'Sedan');
      expect(map['vehicleClass'], 'comfort');
      expect(registration.effectiveVehicleClass, 'comfort');
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
          'vehicleType': 'SUV / 4x4',
          'vehicleClass': 'premium',
          'make': 'Toyota',
          'model': 'Land Cruiser',
          'color': 'White',
          'manufactureYear': '2020',
          'plateNumber': 'SSD 1234',
          'licenceCountry': 'South Sudan',
          'licenceFirstName': 'Test',
          'licenceLastName': 'Driver',
          'licenceNumber': 'DL-12345',
          'licenceIssueDate': '24/08/2026',
        });

    expect(registration.serviceComplete, isTrue);
    expect(registration.vehicleType, 'SUV / 4x4');
    expect(registration.vehicleClass, 'premium');
    expect(registration.effectiveVehicleClass, 'premium');
    expect(registration.requiresAdminVehicleClass, isTrue);
    expect(registration.vehicleComplete, isTrue);
    expect(registration.licenceComplete, isTrue);
  });

  test('fixed local vehicle categories cannot choose a commercial car tier', () {
    final Map<String, String> expected = <String, String>{
      'Boda boda (motorcycle)': 'boda',
      'Bajaj / Tuk-tuk (three-wheeler)': 'rickshaw',
      'Scooter': 'boda',
    };

    for (final MapEntry<String, String> entry in expected.entries) {
      final DriverRegistration registration = DriverRegistration()
        ..vehicleType = entry.key
        ..vehicleClass = 'premium';

      expect(registration.fixedVehicleClass, entry.value);
      expect(registration.effectiveVehicleClass, entry.value);
      expect(registration.requiresAdminVehicleClass, isFalse);
    }
  });

  test('new regular vehicles wait for an Alpha administrator class', () {
    final DriverRegistration registration = DriverRegistration()
      ..vehicleType = 'Sedan';

    expect(registration.requiresAdminVehicleClass, isTrue);
    expect(registration.effectiveVehicleClass, isEmpty);
    expect(registration.vehicleClassLabel, 'Assigned after Alpha review');
  });

  test('legacy Car registrations remain Standard until reclassified', () {
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
    expect(registration.vehicleClass, 'standard');
    expect(registration.effectiveVehicleClass, 'standard');
    expect(registration.vehicleComplete, isTrue);
    expect(registration.licenceComplete, isTrue);
  });

  test('empty registration remains incomplete except default service', () {
    final DriverRegistration registration = DriverRegistration();

    expect(registration.serviceComplete, isTrue);
    expect(registration.vehicleComplete, isFalse);
    expect(registration.licenceComplete, isFalse);
    expect(registration.effectiveVehicleClass, isEmpty);
  });
}
