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

    test('keeps presence fresh with a heartbeat before backend expiry', () {
      expect(
        DriverAvailabilityPolicy.heartbeatInterval.inMilliseconds * 2,
        lessThan(
          DriverAvailabilityPolicy.presenceFreshnessWindow.inMilliseconds,
        ),
      );
    });

    test('matches backend presence freshness boundaries', () {
      const int now = 2_000_000;

      expect(
        DriverAvailabilityPolicy.isPresenceFresh(
          now -
              DriverAvailabilityPolicy
                  .presenceFreshnessWindow
                  .inMilliseconds,
          nowMilliseconds: now,
        ),
        isTrue,
      );
      expect(
        DriverAvailabilityPolicy.isPresenceFresh(
          now -
              DriverAvailabilityPolicy
                  .presenceFreshnessWindow
                  .inMilliseconds -
              1,
          nowMilliseconds: now,
        ),
        isFalse,
      );
      expect(
        DriverAvailabilityPolicy.isPresenceFresh(
          now + 1,
          nowMilliseconds: now,
        ),
        isFalse,
      );
    });

    test('online UI follows the active presence, not the phone clock', () {
      expect(
        DriverAvailabilityPolicy.isCurrentPresenceOnline(
          driverId: 'driver-1',
          activeDriverId: 'driver-1',
          activePresenceId: 'presence-1',
          remotePresenceId: 'presence-1',
          rawOnline: true,
        ),
        isTrue,
      );
      expect(
        DriverAvailabilityPolicy.isCurrentPresenceOnline(
          driverId: 'driver-1',
          activeDriverId: 'driver-1',
          activePresenceId: 'presence-1',
          remotePresenceId: 'old-presence',
          rawOnline: true,
        ),
        isFalse,
      );
      expect(
        DriverAvailabilityPolicy.isCurrentPresenceOnline(
          driverId: 'driver-1',
          activeDriverId: 'driver-1',
          activePresenceId: 'presence-1',
          remotePresenceId: 'presence-1',
          rawOnline: false,
        ),
        isFalse,
      );
    });
  });

  group('DriverHeadingPolicy', () {
    test('publishes frequent movement updates for live map rotation', () {
      expect(DriverHeadingPolicy.locationDistanceFilterMeters, 2);
      expect(
        DriverHeadingPolicy.locationUpdateInterval,
        const Duration(seconds: 2),
      );
    });

    test('uses a reliable device heading after movement', () {
      expect(
        DriverHeadingPolicy.resolve(
          reportedHeading: 91,
          reportedHeadingAccuracy: 8,
          movementMeters: 3,
          movementBearing: 87,
          previousHeading: 80,
        ),
        91,
      );
    });

    test('uses movement bearing when device heading is unavailable', () {
      expect(
        DriverHeadingPolicy.resolve(
          reportedHeading: -1,
          reportedHeadingAccuracy: -1,
          movementMeters: 4,
          movementBearing: -10,
          previousHeading: 20,
        ),
        350,
      );
    });

    test('keeps the last direction while stationary', () {
      expect(
        DriverHeadingPolicy.resolve(
          reportedHeading: 0,
          reportedHeadingAccuracy: -1,
          movementMeters: 0.4,
          movementBearing: 0,
          previousHeading: 275,
        ),
        275,
      );
    });
  });
}
