import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum DriverBiometricResult {
  success,
  cancelled,
  unsupported,
  notEnrolled,
  lockedOut,
  interrupted,
  failed,
  storageError,
  accountChanged,
  busy,
}

String driverBiometricMessage(DriverBiometricResult result) {
  return switch (result) {
    DriverBiometricResult.success => 'Quick unlock is ready.',
    DriverBiometricResult.cancelled =>
      'Authentication cancelled. You can try again.',
    DriverBiometricResult.unsupported =>
      'Biometric unlock is not available on this device. Use phone verification instead.',
    DriverBiometricResult.notEnrolled =>
      'Add a fingerprint or face in your device settings, then try again.',
    DriverBiometricResult.lockedOut =>
      'Biometrics are locked by your device. Unlock the device normally, or sign in again by phone.',
    DriverBiometricResult.interrupted =>
      'Authentication was interrupted. Return to Alpha Plus and try again.',
    DriverBiometricResult.storageError =>
      'Your quick-unlock preference could not be saved. Please try again.',
    DriverBiometricResult.accountChanged =>
      'Your session changed. Sign in again to continue.',
    DriverBiometricResult.busy =>
      'An authentication check is already in progress.',
    DriverBiometricResult.failed =>
      'Authentication was not completed. Try again or use phone verification.',
  };
}

abstract class DriverBiometricDevice {
  Future<DriverBiometricResult> availability();
  Future<DriverBiometricResult> authenticate(String reason);
  Future<void> cancel();
}

class LocalDriverBiometricDevice implements DriverBiometricDevice {
  LocalDriverBiometricDevice({LocalAuthentication? authentication})
    : _authentication = authentication ?? LocalAuthentication();

  final LocalAuthentication _authentication;

  bool get _supportedPlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  Future<DriverBiometricResult> availability() async {
    if (!_supportedPlatform) return DriverBiometricResult.unsupported;
    try {
      if (!await _authentication.canCheckBiometrics) {
        return DriverBiometricResult.unsupported;
      }
      final List<BiometricType> enrolled = await _authentication
          .getAvailableBiometrics();
      return enrolled.isEmpty
          ? DriverBiometricResult.notEnrolled
          : DriverBiometricResult.success;
    } on LocalAuthException catch (error) {
      return _resultForException(error);
    } on Object {
      return DriverBiometricResult.failed;
    }
  }

  @override
  Future<DriverBiometricResult> authenticate(String reason) async {
    if (!_supportedPlatform) return DriverBiometricResult.unsupported;
    try {
      final bool authenticated = await _authentication.authenticate(
        localizedReason: reason,
        biometricOnly: true,
        sensitiveTransaction: true,
        persistAcrossBackgrounding: false,
      );
      return authenticated
          ? DriverBiometricResult.success
          : DriverBiometricResult.cancelled;
    } on LocalAuthException catch (error) {
      return _resultForException(error);
    } on Object {
      return DriverBiometricResult.failed;
    }
  }

  @override
  Future<void> cancel() async {
    try {
      await _authentication.stopAuthentication();
    } on Object {
      // Invalidated operations cannot unlock, even if native cancellation fails.
    }
  }

  DriverBiometricResult _resultForException(LocalAuthException error) {
    return switch (error.code) {
      LocalAuthExceptionCode.userCanceled ||
      LocalAuthExceptionCode.userRequestedFallback =>
        DriverBiometricResult.cancelled,
      LocalAuthExceptionCode.systemCanceled ||
      LocalAuthExceptionCode.timeout => DriverBiometricResult.interrupted,
      LocalAuthExceptionCode.noBiometricHardware =>
        DriverBiometricResult.unsupported,
      LocalAuthExceptionCode.noBiometricsEnrolled ||
      LocalAuthExceptionCode.noCredentialsSet =>
        DriverBiometricResult.notEnrolled,
      LocalAuthExceptionCode.temporaryLockout ||
      LocalAuthExceptionCode.biometricLockout =>
        DriverBiometricResult.lockedOut,
      LocalAuthExceptionCode.authInProgress => DriverBiometricResult.busy,
      _ => DriverBiometricResult.failed,
    };
  }
}

abstract class DriverBiometricPreferences {
  Future<bool> isEnabled(String uid);
  Future<void> setEnabled(String uid, bool enabled);
}

class LocalDriverBiometricPreferences implements DriverBiometricPreferences {
  static const String _prefix = 'alpha_plus_biometric_unlock_v1_';

  @override
  Future<bool> isEnabled(String uid) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.reload();
    return preferences.getBool('$_prefix$uid') ?? false;
  }

  @override
  Future<void> setEnabled(String uid, bool enabled) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    if (!await preferences.setBool('$_prefix$uid', enabled)) {
      throw StateError('Unable to save the local biometric preference.');
    }
  }
}

enum _BiometricAction { enable, disable, unlock }

/// An optional local UI lock, not Firebase authentication or encrypted storage.
/// Only a preference is persisted. Unlock grants exist in memory for this UID.
class DriverBiometricController extends ChangeNotifier {
  DriverBiometricController({
    required this._device,
    required this._preferences,
    required this._currentUserId,
  });

  static final DriverBiometricController instance = DriverBiometricController(
    device: LocalDriverBiometricDevice(),
    preferences: LocalDriverBiometricPreferences(),
    currentUserId: () => FirebaseAuth.instance.currentUser?.uid,
  );

  final DriverBiometricDevice _device;
  final DriverBiometricPreferences _preferences;
  final String? Function() _currentUserId;

  String? _uid;
  String? _freshPhoneUid;
  bool _ready = false;
  bool _enabled = false;
  bool _locked = true;
  bool _obscured = false;
  bool _backgrounded = false;
  bool _busy = false;
  bool _loadFailed = false;
  bool _disposed = false;
  int _accountEpoch = 0;
  int _operationEpoch = 0;

  String? get uid => _uid;
  bool get ready => _ready;
  bool get enabled => _enabled;
  bool get busy => _busy;
  bool get loadFailed => _loadFailed;
  bool get mustUnlock => _uid != null && (!_ready || _loadFailed || _locked);
  bool get obscured => _uid != null && _obscured && (_enabled || _busy);
  bool get coverApp => mustUnlock || obscured;

  Future<void> bindAccount(String? uid) async {
    final int accountEpoch = ++_accountEpoch;
    _operationEpoch++;
    if (_busy) unawaited(_device.cancel());
    _uid = uid;
    if (_freshPhoneUid != uid) _freshPhoneUid = null;
    _ready = uid == null;
    _enabled = false;
    _locked = uid != null;
    _loadFailed = false;
    _notify();
    if (uid == null) return;
    try {
      final bool enabled = await _preferences.isEnabled(uid);
      if (!_validAccount(uid, accountEpoch)) return;
      _enabled = enabled;
      _locked = enabled && (_freshPhoneUid != uid || _backgrounded);
    } on Object {
      if (!_validAccount(uid, accountEpoch)) return;
      // A storage failure must never silently disable a previously enabled lock.
      _loadFailed = true;
      _locked = true;
    }
    if (!_validAccount(uid, accountEpoch)) return;
    _ready = true;
    _notify();
  }

  Future<void> retryLoading() => bindAccount(_uid);

  /// Called only after a fresh Firebase phone sign-in AND session activation.
  /// This lets SMS recovery unlock the current visit without an endless loop.
  void confirmPhoneSignIn(String uid) {
    if (_disposed || _currentUserId() != uid || _backgrounded) return;
    _freshPhoneUid = uid;
    if (_uid == uid && _ready && !_loadFailed) {
      _locked = false;
      _notify();
    }
  }

  Future<DriverBiometricResult> enable() => _run(_BiometricAction.enable);
  Future<DriverBiometricResult> disable() => _run(_BiometricAction.disable);
  Future<DriverBiometricResult> unlock() => _run(_BiometricAction.unlock);

  Future<DriverBiometricResult> _run(_BiometricAction action) async {
    if (_busy) return DriverBiometricResult.busy;
    final String? uid = _uid;
    if (_disposed || uid == null || _currentUserId() != uid) {
      return DriverBiometricResult.accountChanged;
    }
    if (!_ready || _loadFailed) return DriverBiometricResult.storageError;
    if (_backgrounded) return DriverBiometricResult.interrupted;
    if (action != _BiometricAction.unlock && _locked) {
      return DriverBiometricResult.failed;
    }
    if (action == _BiometricAction.unlock && !_enabled) {
      return DriverBiometricResult.failed;
    }

    _busy = true;
    final int epoch = _operationEpoch;
    _notify();
    try {
      // A just-completed SMS verification can also authorize disabling the lock.
      final bool phoneAuthorized =
          action == _BiometricAction.disable && _freshPhoneUid == uid;
      if (!phoneAuthorized) {
        final DriverBiometricResult availability = await _device.availability();
        if (!_validOperation(uid, epoch)) {
          return DriverBiometricResult.interrupted;
        }
        if (availability != DriverBiometricResult.success) return availability;
        final DriverBiometricResult authentication = await _device.authenticate(
          action == _BiometricAction.disable
              ? 'Confirm to turn off Alpha Plus quick unlock'
              : 'Unlock your Alpha Plus driver account',
        );
        if (!_validOperation(uid, epoch)) {
          return DriverBiometricResult.interrupted;
        }
        if (authentication != DriverBiometricResult.success) {
          return authentication;
        }
      }

      if (!_validOperation(uid, epoch)) {
        return DriverBiometricResult.interrupted;
      }
      if (action != _BiometricAction.unlock) {
        try {
          await _preferences.setEnabled(uid, action == _BiometricAction.enable);
        } on Object {
          if (!_disposed && _uid == uid && _currentUserId() == uid) {
            _loadFailed = true;
            _locked = true;
          }
          return DriverBiometricResult.storageError;
        }
        if (!_validOperation(uid, epoch)) {
          // The preference may have reached disk while the app backgrounded.
          // Reload it under a lock instead of leaving an enabled lock inactive.
          if (!_disposed && _uid == uid && _currentUserId() == uid) {
            await bindAccount(uid);
          }
          return DriverBiometricResult.interrupted;
        }
        _enabled = action == _BiometricAction.enable;
      }
      _locked = false;
      return DriverBiometricResult.success;
    } on Object {
      return DriverBiometricResult.failed;
    } finally {
      _busy = false;
      _notify();
    }
  }

  void prepareForPhoneSignIn() {
    _freshPhoneUid = null;
    _locked = _uid != null;
    _operationEpoch++;
    if (_busy) unawaited(_device.cancel());
    _notify();
  }

  void handleLifecycle(AppLifecycleState state) {
    if (_disposed) return;
    switch (state) {
      case AppLifecycleState.inactive:
        _obscured = true;
        // Native biometric dialogs themselves can make the app inactive.
        // Mask it, but don't invalidate that prompt or create a prompt loop.
        if (_enabled && !_busy) {
          _locked = true;
          _freshPhoneUid = null;
        }
        break;
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _backgrounded = true;
        _obscured = true;
        _freshPhoneUid = null;
        _operationEpoch++;
        if (_enabled) _locked = true;
        if (_busy) unawaited(_device.cancel());
        break;
      case AppLifecycleState.resumed:
        _backgrounded = false;
        _obscured = false;
        break;
    }
    _notify();
  }

  bool _validAccount(String uid, int epoch) =>
      !_disposed &&
      _uid == uid &&
      _accountEpoch == epoch &&
      _currentUserId() == uid;

  bool _validOperation(String uid, int epoch) =>
      !_disposed &&
      !_backgrounded &&
      _uid == uid &&
      _operationEpoch == epoch &&
      _currentUserId() == uid;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _operationEpoch++;
    if (_busy) unawaited(_device.cancel());
    super.dispose();
  }
}
