import 'dart:async';

import 'package:alpha_plus/features/auth/data/driver_biometric_controller.dart';

class FakeBiometricDevice implements DriverBiometricDevice {
  DriverBiometricResult available = DriverBiometricResult.success;
  DriverBiometricResult result = DriverBiometricResult.success;
  Completer<DriverBiometricResult>? authentication;
  int availabilityChecks = 0;
  int prompts = 0;
  int cancellations = 0;

  @override
  Future<DriverBiometricResult> availability() async {
    availabilityChecks++;
    return available;
  }

  @override
  Future<DriverBiometricResult> authenticate(String reason) async {
    prompts++;
    if (authentication != null) return authentication!.future;
    return result;
  }

  @override
  Future<void> cancel() async {
    cancellations++;
    // Deliberately don't resolve the future: test late native success after
    // cancellation to ensure it cannot unlock a new/backgrounded session.
  }
}

class FakeBiometricPreferences implements DriverBiometricPreferences {
  final Map<String, bool> values = <String, bool>{};
  final Map<String, Completer<bool>> pendingReads = <String, Completer<bool>>{};
  Completer<void>? pendingWrite;
  bool failRead = false;
  bool failWrite = false;
  int writes = 0;

  @override
  Future<bool> isEnabled(String uid) async {
    if (failRead) throw StateError('Read failed');
    if (pendingReads.containsKey(uid)) return pendingReads[uid]!.future;
    return values[uid] ?? false;
  }

  @override
  Future<void> setEnabled(String uid, bool enabled) async {
    writes++;
    if (failWrite) throw StateError('Write failed');
    if (pendingWrite != null) await pendingWrite!.future;
    values[uid] = enabled;
  }
}

class BiometricFixture {
  String? uid = 'driver-a';
  final FakeBiometricDevice device = FakeBiometricDevice();
  final FakeBiometricPreferences preferences = FakeBiometricPreferences();
  late final DriverBiometricController controller = DriverBiometricController(
    device: device,
    preferences: preferences,
    currentUserId: () => uid,
  );

  Future<void> start({bool enabled = false}) async {
    preferences.values[uid!] = enabled;
    await controller.bindAccount(uid);
  }

  void dispose() => controller.dispose();
}
