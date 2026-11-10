import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Deduplicates push and live feed alerts unless an active offer requests a repeat.
class NotificationAlerts {
  static const MethodChannel _channel = MethodChannel('alpha/notifications');
  static final Set<String> _delivered = <String>{};

  static Future<void> show({
    required String eventId,
    required String title,
    required String body,
    bool urgent = false,
    bool repeat = false,
    int? timeoutMs,
  }) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    if (!_delivered.add(eventId) && !repeat) return;
    if (_delivered.length > 200) _delivered.remove(_delivered.first);
    try {
      await _channel.invokeMethod<void>('show', <String, Object>{
        'eventId': eventId,
        'title': title,
        'body': body,
        'urgent': urgent,
        if (timeoutMs != null) 'timeoutMs': timeoutMs,
      });
    } on PlatformException catch (error) {
      _delivered.remove(eventId);
      debugPrint('Notification alert unavailable: ${error.code}');
    } on MissingPluginException {
      _delivered.remove(eventId);
    }
  }

  static Future<void> dismiss(String eventId) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _channel.invokeMethod<void>('dismiss', eventId);
    } on PlatformException catch (error) {
      debugPrint('Notification dismissal unavailable: ${error.code}');
    } on MissingPluginException {
      // Platform channel is unavailable in widget tests.
    }
  }
}
