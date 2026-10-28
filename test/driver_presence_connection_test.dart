import 'dart:async';

import 'package:alpha_plus/features/dashboard/data/driver_presence_service.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';

class _User extends Fake implements User {
  @override
  String get uid => 'driver';
}

class _Auth extends Fake implements FirebaseAuth {
  @override
  User get currentUser => _User();
}

class _Result<T> extends Fake implements HttpsCallableResult<T> {
  _Result(this.data);
  @override
  final T data;
}

class _Callable extends Fake implements HttpsCallable {
  @override
  Future<HttpsCallableResult<T>> call<T>([dynamic parameters]) async =>
      _Result<T>(
        <String, Object?>{'vehicleType': 'standard', 'activeRideId': null} as T,
      );
}

class _Functions extends Fake implements FirebaseFunctions {
  @override
  HttpsCallable httpsCallable(String name, {HttpsCallableOptions? options}) =>
      _Callable();
}

class _Snapshot extends Fake implements DataSnapshot {
  _Snapshot(this.value);
  @override
  final Object? value;
}

class _Event extends Fake implements DatabaseEvent {
  _Event(Object? value) : snapshot = _Snapshot(value);
  @override
  final DataSnapshot snapshot;
}

class _TransactionResult extends Fake implements TransactionResult {}

class _Disconnect extends Fake implements OnDisconnect {
  @override
  Future<void> update(Map<String, Object?> value) async {}
  @override
  Future<void> cancel() async {}
}

class _Reference extends Fake implements DatabaseReference {
  final StreamController<DatabaseEvent> events =
      StreamController<DatabaseEvent>.broadcast();
  Map<String, Object?> value = <String, Object?>{};
  Completer<void>? nextAcknowledgement;
  int writes = 0;
  @override
  Stream<DatabaseEvent> get onValue => events.stream;
  @override
  Future<void> update(Map<String, Object?> data) {
    writes++;
    value.addAll(data);
    events.add(_Event(Map<String, Object?>.from(value)));
    final Completer<void>? acknowledgement = nextAcknowledgement;
    nextAcknowledgement = null;
    return acknowledgement?.future ?? Future<void>.value();
  }

  @override
  OnDisconnect onDisconnect() => _Disconnect();
  @override
  Future<TransactionResult> runTransaction(
    TransactionHandler transactionHandler, {
    bool applyLocally = true,
  }) async => _TransactionResult();
}

class _Database extends Fake implements FirebaseDatabase {
  final _Reference presence = _Reference();
  final _Reference connection = _Reference();
  @override
  DatabaseReference ref([String? path]) =>
      path == '.info/connected' ? connection : presence;
  Future<void> close() async {
    await presence.events.close();
    await connection.events.close();
  }
}

class _Location extends GeolocatorPlatform {
  Completer<LocationPermission>? permission;
  final StreamController<Position> positions =
      StreamController<Position>.broadcast();
  Position get position => Position(
    latitude: 4.85,
    longitude: 31.57,
    timestamp: DateTime.now(),
    accuracy: 8,
    altitude: 0,
    altitudeAccuracy: 1,
    heading: 0,
    headingAccuracy: 1,
    speed: 0,
    speedAccuracy: 1,
  );
  @override
  Future<bool> isLocationServiceEnabled() async => true;
  @override
  Future<LocationPermission> checkPermission() =>
      permission?.future ??
      Future<LocationPermission>.value(LocationPermission.whileInUse);
  @override
  Future<Position?> getLastKnownPosition({
    bool forceLocationManager = false,
  }) async => position;
  @override
  Stream<Position> getPositionStream({LocationSettings? locationSettings}) =>
      positions.stream;
}

void main() {
  test('queued writes are not LIVE; a slow acknowledgement and reconnect retain online intent', () async {
    final GeolocatorPlatform original = GeolocatorPlatform.instance;
    final _Location location = _Location();
    GeolocatorPlatform.instance = location;
    final _Database database = _Database();
    final DriverPresenceService service = DriverPresenceService(
      auth: _Auth(),
      database: database,
      functions: _Functions(),
    );
    final List<bool> states = <bool>[];
    final StreamSubscription<bool> subscription = service
        .watchOnlineState('driver')
        .listen(states.add);
    final Completer<void> acknowledgement = Completer<void>();
    database.presence.nextAcknowledgement = acknowledgement;
    final Future<void> startup = service.goOnline(
      driverId: 'driver',
      reviewStatus: 'approved',
      vehicleType: 'standard',
    );
    await Future<void>.delayed(Duration.zero);
    expect(database.presence.writes, 1);
    expect(
      states.last,
      isFalse,
      reason: 'An optimistic local database event is not server confirmation.',
    );
    await Future<void>.delayed(const Duration(seconds: 21));
    expect(service.wantsOnline, isTrue);
    expect(states.last, isFalse);
    acknowledgement.complete();
    await Future<void>.delayed(Duration.zero);
    await startup;
    expect(states.last, isTrue);
    database.connection.events.add(_Event(false));
    await Future<void>.delayed(Duration.zero);
    expect(states.last, isFalse);
    expect(
      service.wantsOnline,
      isTrue,
      reason: 'A network gap must not cancel the driver’s choice.',
    );
    database.connection.events.add(_Event(true));
    await Future<void>.delayed(Duration.zero);
    expect(states.last, isTrue);
    expect(database.presence.writes, 2);
    await service.goOffline();
    await Future<void>.delayed(Duration.zero);
    expect(service.wantsOnline, isFalse);
    expect(states.last, isFalse);
    await subscription.cancel();
    await database.close();
    await location.positions.close();
    GeolocatorPlatform.instance = original;
  }, timeout: const Timeout(Duration(seconds: 45)));

  test(
    'cancelling during permission check prevents a late online write',
    () async {
      final GeolocatorPlatform original = GeolocatorPlatform.instance;
      final _Location location = _Location()
        ..permission = Completer<LocationPermission>();
      GeolocatorPlatform.instance = location;
      final _Database database = _Database();
      final DriverPresenceService service = DriverPresenceService(
        auth: _Auth(),
        database: database,
        functions: _Functions(),
      );
      final Future<void> startup = service.goOnline(
        driverId: 'driver',
        reviewStatus: 'approved',
        vehicleType: 'standard',
      );
      await Future<void>.delayed(Duration.zero);
      await service.goOffline();
      location.permission!.complete(LocationPermission.whileInUse);
      await Future<void>.delayed(Duration.zero);
      await startup;
      expect(service.wantsOnline, isFalse);
      expect(database.presence.writes, 0);
      await database.close();
      await location.positions.close();
      GeolocatorPlatform.instance = original;
    },
    timeout: const Timeout(Duration(seconds: 45)),
  );
}
