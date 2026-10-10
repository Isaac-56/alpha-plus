import 'package:alpha_plus/features/dashboard/data/driver_presence_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PreparedDriverAvailability', () {
    test('uses the server vehicle category and optional active ride', () {
      final PreparedDriverAvailability prepared =
          PreparedDriverAvailability.fromCallable(<Object?, Object?>{
        'vehicleType': 'boda',
        'activeRideId': '',
      });

      expect(prepared.vehicleType, 'boda');
      expect(prepared.activeRideId, isNull);
    });

    test('rejects availability responses without a vehicle category', () {
      expect(
        () => PreparedDriverAvailability.fromCallable(<Object?, Object?>{}),
        throwsFormatException,
      );
    });
  });

  group('DriverAvailabilityPolicy', () {
    test('only approved drivers can go online', () {
      expect(DriverAvailabilityPolicy.canGoOnline('approved'), isTrue);
      expect(DriverAvailabilityPolicy.canGoOnline(' Approved '), isTrue);
      expect(DriverAvailabilityPolicy.canGoOnline('pending'), isFalse);
      expect(DriverAvailabilityPolicy.canGoOnline('rejected'), isFalse);
    });

    test('online switch can cancel a pending online attempt', () {
      expect(
        DriverAvailabilityPolicy.canChangeOnlineSwitch(
          walletLoaded: true,
          walletCanGoOnline: true,
          changing: true,
          requestedOnline: true,
        ),
        isTrue,
      );
      expect(
        DriverAvailabilityPolicy.canChangeOnlineSwitch(
          walletLoaded: true,
          walletCanGoOnline: true,
          changing: true,
          requestedOnline: false,
        ),
        isFalse,
      );
    });

    test('wallet cannot force a driver offline before it finishes loading', () {
      expect(
        DriverAvailabilityPolicy.shouldForceWalletOffline(
          isOnline: true,
          walletLoaded: false,
          walletCanGoOnline: false,
        ),
        isFalse,
      );
      expect(
        DriverAvailabilityPolicy.shouldForceWalletOffline(
          isOnline: true,
          walletLoaded: true,
          walletCanGoOnline: false,
        ),
        isTrue,
      );
    });

    test('normalizes only supported dispatch vehicle classes', () {
      expect(DriverAvailabilityPolicy.normalizedVehicleType('Car'), 'standard');
      expect(
        DriverAvailabilityPolicy.normalizedVehicleType('Alpha Boda'),
        'boda',
      );
      expect(
        DriverAvailabilityPolicy.normalizedVehicleType('Tuk Tuk'),
        'rickshaw',
      );
      expect(
        DriverAvailabilityPolicy.normalizedVehicleType('Scooter'),
        'boda',
      );
      expect(
        DriverAvailabilityPolicy.normalizedVehicleType('Comfort'),
        'comfort',
      );
      expect(
        DriverAvailabilityPolicy.normalizedVehicleType('SUV / 4x4'),
        isEmpty,
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

    test('uses a recent cached location to publish online immediately', () {
      final DateTime now = DateTime(2026, 10, 4, 9);
      expect(
        DriverAvailabilityPolicy.isCachedPositionFresh(
          now.subtract(const Duration(minutes: 1)),
          now: now,
        ),
        isTrue,
      );
      expect(
        DriverAvailabilityPolicy.isCachedPositionFresh(
          now.subtract(const Duration(minutes: 2)),
          now: now,
        ),
        isFalse,
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
