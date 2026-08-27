import 'dart:async';

import 'package:alpha_plus/features/auth/data/driver_biometric_controller.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/driver_biometric_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late BiometricFixture fixture;
  setUp(() => fixture = BiometricFixture());
  tearDown(() => fixture.dispose());

  test(
    'quick unlock starts off without prompting or storing a grant',
    () async {
      await fixture.start();
      expect(fixture.controller.coverApp, isFalse);
      expect(fixture.controller.enabled, isFalse);
      expect(fixture.device.prompts, 0);
      expect(fixture.preferences.writes, 0);
    },
  );

  test(
    'unavailable, unenrolled, cancelled and failed checks never enable',
    () async {
      await fixture.start();
      for (final DriverBiometricResult result in <DriverBiometricResult>[
        DriverBiometricResult.unsupported,
        DriverBiometricResult.notEnrolled,
      ]) {
        fixture.device.available = result;
        expect(await fixture.controller.enable(), result);
      }
      expect(fixture.device.prompts, 0);
      fixture.device.available = DriverBiometricResult.success;
      for (final DriverBiometricResult result in <DriverBiometricResult>[
        DriverBiometricResult.cancelled,
        DriverBiometricResult.failed,
        DriverBiometricResult.lockedOut,
      ]) {
        fixture.device.result = result;
        expect(await fixture.controller.enable(), result);
      }
      expect(fixture.preferences.writes, 0);
      expect(fixture.controller.enabled, isFalse);
      expect(fixture.controller.coverApp, isFalse);
    },
  );

  test(
    'enable waits for device approval and persistence and prevents double taps',
    () async {
      await fixture.start();
      fixture.device.authentication = Completer<DriverBiometricResult>();
      fixture.preferences.pendingWrite = Completer<void>();
      final Future<DriverBiometricResult> operation = fixture.controller
          .enable();
      await Future<void>.delayed(Duration.zero);
      expect(await fixture.controller.enable(), DriverBiometricResult.busy);
      expect(fixture.preferences.writes, 0);
      expect(fixture.controller.enabled, isFalse);
      fixture.device.authentication!.complete(DriverBiometricResult.success);
      await Future<void>.delayed(Duration.zero);
      expect(fixture.preferences.writes, 1);
      expect(fixture.controller.enabled, isFalse);
      fixture.preferences.pendingWrite!.complete();
      expect(await operation, DriverBiometricResult.success);
      expect(fixture.controller.enabled, isTrue);
      expect(fixture.controller.coverApp, isFalse);
      expect(fixture.device.prompts, 1);

      final DriverBiometricController restarted = DriverBiometricController(
        device: fixture.device,
        preferences: fixture.preferences,
        currentUserId: () => fixture.uid,
      );
      await restarted.bindAccount(fixture.uid);
      expect(restarted.mustUnlock, isTrue);
      restarted.dispose();
    },
  );

  test(
    'background locks but the native prompt inactive event does not loop',
    () async {
      await fixture.start();
      await fixture.controller.enable();
      fixture.controller.handleLifecycle(AppLifecycleState.paused);
      fixture.controller.handleLifecycle(AppLifecycleState.resumed);
      expect(fixture.controller.mustUnlock, isTrue);

      fixture.device.authentication = Completer<DriverBiometricResult>();
      final Future<DriverBiometricResult> unlock = fixture.controller.unlock();
      await Future<void>.delayed(Duration.zero);
      fixture.controller.handleLifecycle(AppLifecycleState.inactive);
      expect(fixture.controller.coverApp, isTrue);
      fixture.controller.handleLifecycle(AppLifecycleState.resumed);
      fixture.device.authentication!.complete(DriverBiometricResult.success);
      expect(await unlock, DriverBiometricResult.success);
      expect(fixture.controller.coverApp, isFalse);
      expect(fixture.device.cancellations, 0);
      expect(fixture.device.prompts, 2);
    },
  );

  test('a late biometric success after backgrounding cannot unlock', () async {
    await fixture.start(enabled: true);
    fixture.device.authentication = Completer<DriverBiometricResult>();
    final Future<DriverBiometricResult> unlock = fixture.controller.unlock();
    await Future<void>.delayed(Duration.zero);
    fixture.controller.handleLifecycle(AppLifecycleState.paused);
    fixture.controller.handleLifecycle(AppLifecycleState.resumed);
    fixture.device.authentication!.complete(DriverBiometricResult.success);
    expect(await unlock, DriverBiometricResult.interrupted);
    expect(fixture.controller.mustUnlock, isTrue);
    expect(fixture.device.cancellations, greaterThan(0));
    fixture.device.authentication = null;
    expect(await fixture.controller.unlock(), DriverBiometricResult.success);
    expect(fixture.controller.mustUnlock, isFalse);
  });

  test('account replacement invalidates a pending biometric result', () async {
    await fixture.start(enabled: true);
    fixture.device.authentication = Completer<DriverBiometricResult>();
    final Future<DriverBiometricResult> unlock = fixture.controller.unlock();
    await Future<void>.delayed(Duration.zero);
    fixture.uid = 'driver-b';
    await fixture.controller.bindAccount(fixture.uid);
    fixture.device.authentication!.complete(DriverBiometricResult.success);
    expect(await unlock, DriverBiometricResult.interrupted);
    expect(fixture.controller.uid, 'driver-b');
    expect(fixture.controller.enabled, isFalse);
    fixture.controller.confirmPhoneSignIn('driver-a');
    expect(fixture.preferences.values['driver-a'], isTrue);
    expect(fixture.preferences.values.containsKey('driver-b'), isFalse);
  });

  test(
    'preference read and write failures keep access locked until rechecked',
    () async {
      fixture.preferences.failRead = true;
      await fixture.start(enabled: true);
      expect(fixture.controller.loadFailed, isTrue);
      expect(fixture.controller.mustUnlock, isTrue);
      fixture.preferences.failRead = false;
      await fixture.controller.retryLoading();
      expect(fixture.controller.loadFailed, isFalse);
      expect(fixture.controller.mustUnlock, isTrue);
      await fixture.controller.unlock();
      fixture.preferences.failWrite = true;
      expect(
        await fixture.controller.disable(),
        DriverBiometricResult.storageError,
      );
      expect(fixture.controller.enabled, isTrue);
      expect(fixture.controller.mustUnlock, isTrue);
    },
  );

  test(
    'an enable write finishing in the background is reloaded under the lock',
    () async {
      await fixture.start();
      fixture.preferences.pendingWrite = Completer<void>();
      final Future<DriverBiometricResult> enable = fixture.controller.enable();
      await Future<void>.delayed(Duration.zero);
      fixture.controller.handleLifecycle(AppLifecycleState.paused);
      fixture.preferences.pendingWrite!.complete();
      expect(await enable, DriverBiometricResult.interrupted);
      fixture.controller.handleLifecycle(AppLifecycleState.resumed);
      expect(fixture.controller.enabled, isTrue);
      expect(fixture.controller.mustUnlock, isTrue);
    },
  );

  test(
    'fresh phone proof unlocks once and can turn off unavailable biometrics',
    () async {
      await fixture.start(enabled: true);
      fixture.controller.confirmPhoneSignIn('driver-b');
      expect(fixture.controller.mustUnlock, isTrue);
      fixture.controller.confirmPhoneSignIn('driver-a');
      expect(fixture.controller.mustUnlock, isFalse);
      expect(fixture.controller.enabled, isTrue);
      fixture.controller.handleLifecycle(AppLifecycleState.paused);
      fixture.controller.handleLifecycle(AppLifecycleState.resumed);
      expect(fixture.controller.mustUnlock, isTrue);
      fixture.controller.confirmPhoneSignIn('driver-a');
      fixture.device.available = DriverBiometricResult.notEnrolled;
      expect(await fixture.controller.disable(), DriverBiometricResult.success);
      expect(fixture.preferences.values['driver-a'], isFalse);
      expect(fixture.device.prompts, 0);
    },
  );

  test(
    'fresh phone proof before account binding survives the preference load',
    () async {
      fixture.preferences.values['driver-a'] = true;
      fixture.controller.confirmPhoneSignIn('driver-a');
      await fixture.controller.bindAccount('driver-a');
      expect(fixture.controller.enabled, isTrue);
      expect(fixture.controller.mustUnlock, isFalse);
    },
  );

  test(
    'stale preference loads cannot change the replacement account',
    () async {
      fixture.preferences.pendingReads['driver-a'] = Completer<bool>();
      final Future<void> oldLoad = fixture.controller.bindAccount('driver-a');
      fixture.uid = 'driver-b';
      await fixture.controller.bindAccount('driver-b');
      fixture.preferences.pendingReads['driver-a']!.complete(true);
      await oldLoad;
      expect(fixture.controller.uid, 'driver-b');
      expect(fixture.controller.enabled, isFalse);
    },
  );

  test(
    'local preferences are separate for each UID and survive a new store',
    () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final LocalDriverBiometricPreferences preferences =
          LocalDriverBiometricPreferences();
      await preferences.setEnabled('driver-a', true);
      final LocalDriverBiometricPreferences reloaded =
          LocalDriverBiometricPreferences();
      expect(await reloaded.isEnabled('driver-a'), isTrue);
      expect(await reloaded.isEnabled('driver-b'), isFalse);
      await reloaded.setEnabled('driver-a', false);
      expect(await preferences.isEnabled('driver-a'), isFalse);
    },
  );
}
