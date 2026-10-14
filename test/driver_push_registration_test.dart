import 'dart:async';

import 'package:alpha_plus/features/notifications/data/driver_push_notification_service.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';

class _Settings extends Fake implements NotificationSettings {
  @override
  AuthorizationStatus get authorizationStatus => AuthorizationStatus.authorized;
}

class _Messaging extends Fake implements FirebaseMessaging {
  final tokens = StreamController<String>.broadcast();
  @override
  Stream<String> get onTokenRefresh => tokens.stream;
  @override
  Future<String?> getToken({
    String? vapidKey,
    String? serviceWorkerScriptPath,
  }) async => 'device-token';
  @override
  Future<NotificationSettings> getNotificationSettings() async => _Settings();
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #requestPermission) {
      return Future<NotificationSettings>.value(_Settings());
    }
    if (invocation.memberName ==
        #setForegroundNotificationPresentationOptions) {
      return Future<void>.value();
    }
    return super.noSuchMethod(invocation);
  }
}

class _Result<T> extends Fake implements HttpsCallableResult<T> {}

class _Callable extends Fake implements HttpsCallable {
  _Callable(this.owner);
  final _Functions owner;
  @override
  Future<HttpsCallableResult<T>> call<T>([dynamic parameters]) async {
    owner.attempts++;
    if (owner.fail) throw StateError('Temporary network outage');
    return _Result<T>();
  }
}

class _Functions extends Fake implements FirebaseFunctions {
  int attempts = 0;
  bool fail = true;
  @override
  HttpsCallable httpsCallable(String name, {HttpsCallableOptions? options}) =>
      _Callable(this);
}

void main() {
  testWidgets('failed registration retries while driver stays in the app', (
    tester,
  ) async {
    final messaging = _Messaging();
    final functions = _Functions();
    final service = DriverPushNotificationService(
      messaging: messaging,
      functions: functions,
    );
    await service.start('driver');
    expect(functions.attempts, 1);
    functions.fail = false;
    await tester.pump(const Duration(seconds: 30));
    await tester.pump();
    expect(functions.attempts, 2);
    await tester.pump(const Duration(seconds: 30));
    expect(functions.attempts, 2);
    await service.stop();
    await tester.pump(const Duration(minutes: 5));
    expect(functions.attempts, 2);
    await messaging.tokens.close();
  });

  testWidgets('same token is registered again for a different driver account', (
    tester,
  ) async {
    final messaging = _Messaging();
    final functions = _Functions()..fail = false;
    final service = DriverPushNotificationService(
      messaging: messaging,
      functions: functions,
    );
    await service.start('driver-one');
    await service.start('driver-two');
    expect(functions.attempts, 2);
    await service.stop();
    await messaging.tokens.close();
  });
}
