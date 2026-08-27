import 'package:alpha_plus/features/dashboard/data/driver_presence_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DriverAvailabilityPolicy', () {
    test('only approved drivers can go online', () {
      expect(DriverAvailabilityPolicy.canGoOnline('approved'), isTrue);
      expect(DriverAvailabilityPolicy.canGoOnline(' Approved '), isTrue);
      expect(DriverAvailabilityPolicy.canGoOnline('pending'), isFalse);
      expect(DriverAvailabilityPolicy.canGoOnline('rejected'), isFalse);
    });

    test('normalizes passenger-map vehicle categories', () {
      expect(DriverAvailabilityPolicy.normalizedVehicleType('Car'), 'standard');
      expect(
        DriverAvailabilityPolicy.normalizedVehicleType('Alpha Boda'),
        'boda',
      );
      expect(
        DriverAvailabilityPolicy.normalizedVehicleType('Tuk Tuk'),
        'rickshaw',
      );
    });
  });
}
