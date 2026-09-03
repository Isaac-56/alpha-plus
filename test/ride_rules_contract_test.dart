import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('shared ride collections remain server-write-only', () async {
    final String rules = await File('firestore.rules').readAsString();

    expect(rules, contains('match /rides/{rideId}'));
    expect(rules, contains('allow create, update, delete: if false;'));
    expect(
      rules,
      contains('match /driver_ride_offers/{driverId}/offers/{rideId}'),
    );
  });
}
