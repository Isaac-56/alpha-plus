import 'dart:async';

import 'package:alpha_plus/features/rides/data/completion_location.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  final now = DateTime.utc(2026, 10, 14);
  Position fix({int age = 0, double accuracy = 20}) => Position(
    latitude: 4.85,
    longitude: 31.6,
    timestamp: now.subtract(Duration(seconds: age)),
    accuracy: accuracy,
    altitude: 0,
    altitudeAccuracy: 0,
    heading: 0,
    headingAccuracy: 0,
    speed: 0,
    speedAccuracy: 0,
  );

  test('recent stream fix avoids another GPS request', () async {
    final point = fix(age: 10);
    expect(
      await resolveCompletionLocation(
        trackedPosition: () => point,
        currentPosition: () async => throw StateError('must not request'),
        lastKnownPosition: () async => throw StateError('must not request'),
        clock: () => now,
      ),
      same(point),
    );
  });

  test('fresh GPS replaces an old stream position', () async {
    final point = fix();
    expect(
      await resolveCompletionLocation(
        trackedPosition: () => fix(age: 60),
        currentPosition: () async => point,
        lastKnownPosition: () async => null,
        clock: () => now,
      ),
      same(point),
    );
  });

  test('GPS timeout recovers a fix arriving on the trip stream', () async {
    Position? tracked;
    final point = fix();
    expect(
      await resolveCompletionLocation(
        trackedPosition: () => tracked,
        currentPosition: () async {
          tracked = point;
          throw TimeoutException('GPS timeout');
        },
        lastKnownPosition: () async => null,
        clock: () => now,
      ),
      same(point),
    );
  });

  test('GPS failure can use a recent precise last known fix', () async {
    final point = fix(age: 8);
    expect(
      await resolveCompletionLocation(
        trackedPosition: () => null,
        currentPosition: () async => throw TimeoutException('GPS timeout'),
        lastKnownPosition: () async => point,
        clock: () => now,
      ),
      same(point),
    );
  });

  test('stale, future and inaccurate fixes never end the trip', () async {
    for (final point in <Position>[
      fix(age: 16),
      fix(age: -1),
      fix(accuracy: 101),
      fix(accuracy: double.nan),
      fix(accuracy: -1),
    ]) {
      expect(
        await resolveCompletionLocation(
          trackedPosition: () => point,
          currentPosition: () async => point,
          lastKnownPosition: () async => point,
          clock: () => now,
        ),
        isNull,
      );
    }
  });
}
