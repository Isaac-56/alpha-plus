import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../../services/notification_alerts.dart';

/// Keeps the active driver's Firebase Messaging token registered with the
/// dispatch backend. Notification payloads are displayed by Android/iOS while
/// Alpha Plus is backgrounded; the existing Firestore offer stream remains the
/// source of truth for the in-app request card.
class DriverPushNotificationService {
  DriverPushNotificationService({
    FirebaseMessaging? messaging,
    FirebaseFunctions? functions,
  }) : _messagingOverride = messaging,
       _functionsOverride = functions;

  static final DriverPushNotificationService instance =
      DriverPushNotificationService();

  final FirebaseMessaging? _messagingOverride;
  final FirebaseFunctions? _functionsOverride;

  FirebaseMessaging get _messaging =>
      _messagingOverride ?? FirebaseMessaging.instance;
  FirebaseFunctions get _functions =>
      _functionsOverride ??
      FirebaseFunctions.instanceFor(region: 'africa-south1');

  StreamSubscription<String>? _tokenSubscription;
  StreamSubscription<RemoteMessage>? _messageSubscription;
  String? _driverId;
  String? _registeredToken;

  Future<void> start(String driverId) async {
    final String normalizedDriverId = driverId.trim();
    if (normalizedDriverId.isEmpty) return;
    if (_driverId == normalizedDriverId && _tokenSubscription != null) return;

    await _tokenSubscription?.cancel();
    await _messageSubscription?.cancel();
    _messageSubscription = null;
    _tokenSubscription = null;
    _driverId = normalizedDriverId;

    try {
      final NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;

      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
      _messageSubscription = FirebaseMessaging.onMessage.listen((
        RemoteMessage message,
      ) {
        if (_driverId != normalizedDriverId) return;
        final bool rideOffer = message.data['type'] == 'ride_offer';
        final String eventId = rideOffer
            ? 'ride_offer:${message.data['rideId']}'
            : message.data['eventId'] ??
                  message.messageId ??
                  'update:${message.sentTime}';
        unawaited(
          NotificationAlerts.show(
            eventId: eventId,
            title: message.notification?.title ?? 'Alpha Plus update',
            body: message.notification?.body ?? '',
            urgent: rideOffer,
          ),
        );
      });
      final String? token = await _messaging.getToken();
      if (token != null && token.trim().isNotEmpty) {
        await _register(normalizedDriverId, token.trim());
      }

      _tokenSubscription = _messaging.onTokenRefresh.listen(
        (String refreshedToken) {
          unawaited(
            _register(normalizedDriverId, refreshedToken).catchError((
              Object error,
            ) {
              debugPrint('Unable to refresh driver push token: $error');
            }),
          );
        },
        onError: (Object error) {
          debugPrint('Driver push token stream failed: $error');
        },
      );
    } on Object catch (error) {
      debugPrint('Unable to enable driver ride notifications: $error');
    }
  }

  Future<void> _register(String driverId, String token) async {
    if (_driverId != driverId || token == _registeredToken) return;
    await _functions.httpsCallable('registerDriverPushToken').call<void>(
      <String, dynamic>{'token': token},
    );
    if (_driverId == driverId) _registeredToken = token;
  }

  Future<void> stop({bool unregister = false}) async {
    final String? token = _registeredToken;
    _driverId = null;
    _registeredToken = null;
    await _tokenSubscription?.cancel();
    _tokenSubscription = null;
    await _messageSubscription?.cancel();
    _messageSubscription = null;

    if (!unregister || token == null) return;
    try {
      await _functions.httpsCallable('unregisterDriverPushToken').call<void>(
        <String, dynamic>{'token': token},
      );
    } on Object catch (error) {
      debugPrint('Unable to unregister driver push token: $error');
    }
  }
}
