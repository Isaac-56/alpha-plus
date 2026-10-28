import 'dart:async';

import 'package:alpha_plus/features/dashboard/data/driver_online_preparation.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'a failing GPS request is observed while server preparation is pending',
    () async {
      final Completer<String> server = Completer<String>();
      final Completer<int> gps = Completer<int>();
      final Future<(String, int)> result = prepareDriverOnline(
        server.future,
        gps.future,
      );
      final Future<void> assertion = expectLater(result, throwsStateError);
      gps.completeError(StateError('GPS unavailable'));
      await assertion;
      // A second failure must also be consumed, rather than escape asynchronously.
      server.completeError(StateError('connection interrupted'));
      await Future<void>.delayed(Duration.zero);
    },
  );

  test(
    'slow preparation does not report success until both dependencies finish',
    () async {
      final Completer<String> server = Completer<String>();
      final Completer<int> gps = Completer<int>();
      bool completed = false;
      final Future<(String, int)> result =
          prepareDriverOnline(server.future, gps.future).then((value) {
            completed = true;
            return value;
          });
      gps.complete(42);
      await Future<void>.delayed(Duration.zero);
      expect(completed, isFalse);
      server.complete('standard');
      expect(await result, ('standard', 42));
    },
  );

  test(
    'transport failure retries once and preserves a successful second response',
    () async {
      int attempts = 0;
      final String response = await retryDriverAvailability(() async {
        if (++attempts == 1)
          throw FirebaseFunctionsException(code: 'unavailable');
        return 'approved';
      }, beforeRetry: () async {});
      expect(response, 'approved');
      expect(attempts, 2);
    },
  );

  test(
    'permission and approval failures never retry or become success',
    () async {
      for (final String code in <String>[
        'permission-denied',
        'failed-precondition',
        'unauthenticated',
      ]) {
        int attempts = 0;
        await expectLater(
          retryDriverAvailability(() async {
            attempts++;
            throw FirebaseFunctionsException(code: code);
          }, beforeRetry: () async {}),
          throwsA(isA<FirebaseFunctionsException>()),
        );
        expect(attempts, 1);
      }
    },
  );

  test('repeated transport failure stops after two calls', () async {
    int attempts = 0;
    await expectLater(
      retryDriverAvailability(() async {
        attempts++;
        throw TimeoutException('network timeout');
      }, beforeRetry: () async {}),
      throwsA(isA<TimeoutException>()),
    );
    expect(attempts, 2);
  });
}
