import 'dart:async';
import 'dart:math' as math;

import 'package:alpha_plus/main.dart';
import 'package:alpha_plus/core/theme/app_theme.dart';
import 'package:alpha_plus/features/auth/data/driver_auth_service.dart';
import 'package:alpha_plus/features/auth/data/driver_biometric_controller.dart';
import 'package:alpha_plus/features/auth/presentation/biometric_opt_in_screen.dart';
import 'package:alpha_plus/features/auth/presentation/driver_biometric_gate.dart';
import 'package:alpha_plus/features/auth/presentation/driver_biometric_settings_screen.dart';
import 'package:alpha_plus/features/auth/data/driver_agreement_store.dart';
import 'package:alpha_plus/features/auth/data/driver_legal_content.dart';
import 'package:alpha_plus/features/auth/presentation/agreements_screen.dart';
import 'package:alpha_plus/features/auth/presentation/driver_legal_details_screen.dart';
import 'package:alpha_plus/features/auth/presentation/phone_login_screen.dart';
import 'package:alpha_plus/features/auth/presentation/otp_screen.dart';
import 'package:alpha_plus/features/auth/presentation/driver_name_screen.dart';
import 'package:alpha_plus/features/profile/data/driver_profile_repository.dart';
import 'package:alpha_plus/features/auth/presentation/splash_screen.dart';
import 'package:alpha_plus/features/dashboard/presentation/driver_shell.dart';
import 'package:alpha_plus/features/dashboard/presentation/driver_map_camera.dart';
import 'package:alpha_plus/features/onboarding/models/driver_registration.dart';
import 'package:alpha_plus/features/onboarding/presentation/stage_one_complete_screen.dart';
import 'package:alpha_plus/features/profile/models/driver_profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'support/driver_biometric_fakes.dart';

void main() {
  test('driver profile restores UID-owned onboarding data', () {
    final DriverProfile profile = DriverProfile.fromMap(
      uid: 'driver-uid-123',
      data: <String, dynamic>{
        'phoneNumber': '+211912345678',
        'firstName': 'Test',
        'lastName': 'Driver',
        'onboardingCompleted': true,
        'reviewStatus': 'pending',
        'registration': <String, dynamic>{
          'vehicleType': 'Car',
          'make': 'Toyota',
          'model': 'Corolla',
          'color': 'White',
          'manufactureYear': '2020',
          'plateNumber': 'SSD 123 A',
          'licenceCountry': 'South Sudan',
          'licenceFirstName': 'Test',
          'licenceLastName': 'Driver',
          'licenceNumber': 'DL-123',
          'licenceIssueDate': '2026-08-24',
        },
      },
    );

    expect(profile.uid, 'driver-uid-123');
    expect(profile.fullName, 'Test Driver');
    expect(profile.onboardingCompleted, isTrue);
    expect(profile.registration.plateNumber, 'SSD 123 A');
  });

  testWidgets('splash animation completes once', (WidgetTester tester) async {
    bool animationFinished = false;
    await tester.pumpWidget(
      AlphaPlusApp(
        home: SplashScreen(
          automaticallyNavigate: false,
          onFinished: () => animationFinished = true,
        ),
      ),
    );

    expect(find.bySemanticsLabel('Alpha Plus'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 2900));
    expect(animationFinished, isTrue);
  });

  testWidgets('valid South Sudan phone number opens OTP', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: PhoneLoginScreen(authService: _FakeDriverAuthService()),
      ),
    );

    await tester.enterText(find.byKey(const Key('phoneField')), '912345678');
    await tester.ensureVisible(find.byKey(const Key('legalConsentCheckbox')));
    await tester.tap(find.byKey(const Key('legalConsentCheckbox')));
    await tester.pump();

    final ElevatedButton button = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Continue'),
    );
    expect(button.onPressed, isNotNull);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Verify your number'), findsOneWidget);
    expect(find.byKey(const Key('otpField')), findsOneWidget);
  });

  testWidgets('phone verification requires legal consent', (
    WidgetTester tester,
  ) async {
    final _FakeDriverAuthService authService = _FakeDriverAuthService();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: PhoneLoginScreen(authService: authService),
      ),
    );

    await tester.enterText(find.byKey(const Key('phoneField')), '912345678');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
    await tester.pump();

    expect(
      find.text('Please accept the User Agreement and Privacy Policy.'),
      findsOneWidget,
    );
    expect(authService.requestCount, 0);
    expect(find.text('Verify your number'), findsNothing);
  });

  testWidgets('stage one continues to vehicle registration', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const StageOneCompleteScreen(driverName: 'Test Driver'),
      ),
    );

    await tester.tap(
      find.widgetWithText(ElevatedButton, 'Continue to vehicle setup'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Enter your vehicle details'), findsOneWidget);
    expect(find.text('Type of vehicle'), findsOneWidget);
    expect(find.text('Vehicle plate number'), findsOneWidget);
  });

  testWidgets('OTP submits once and restores input after verification fails', (
    WidgetTester tester,
  ) async {
    final _FakeDriverAuthService auth = _FakeDriverAuthService()
      ..verifyCompleter = Completer<void>();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: OtpScreen(
          phoneNumber: '+211 912345678',
          verificationId: 'original-session',
          authService: auth,
        ),
      ),
    );
    await tester.enterText(find.byKey(const Key('otpField')), '12345');
    await tester.pump();
    expect(auth.verifyCount, 0);
    expect(
      tester
          .widget<ElevatedButton>(find.byKey(const Key('verifyOtpButton')))
          .onPressed,
      isNull,
    );

    await tester.enterText(find.byKey(const Key('otpField')), '123456');
    await tester.pump();
    expect(auth.verifyCount, 1);
    expect(auth.lastVerificationId, 'original-session');
    expect(auth.lastSmsCode, '123456');
    expect(
      tester.widget<TextField>(find.byKey(const Key('otpField'))).enabled,
      isFalse,
    );
    await tester.pump(const Duration(seconds: 31));
    expect(
      tester
          .widget<TextButton>(find.byKey(const Key('resendOtpButton')))
          .onPressed,
      isNull,
    );

    auth.verifyCompleter!.completeError(StateError('Code rejected'));
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const Key('otpError')), findsOneWidget);
    final TextField field = tester.widget(find.byKey(const Key('otpField')));
    expect(field.enabled, isTrue);
    expect(field.controller!.text, isEmpty);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('resending clears old digits and uses the renewed session', (
    WidgetTester tester,
  ) async {
    final _FakeDriverAuthService auth = _FakeDriverAuthService()
      ..requestCompleter = Completer<PhoneVerificationSession>();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: OtpScreen(
          phoneNumber: '+211 912345678',
          verificationId: 'original-session',
          resendToken: 4,
          authService: auth,
        ),
      ),
    );
    await tester.enterText(find.byKey(const Key('otpField')), '12');
    await tester.pump(const Duration(seconds: 31));
    await tester.ensureVisible(find.byKey(const Key('resendOtpButton')));
    await tester.tap(find.byKey(const Key('resendOtpButton')));
    await tester.pump();
    expect(auth.requestCount, 1);
    expect(auth.lastResendToken, 4);
    expect(
      tester.widget<TextField>(find.byKey(const Key('otpField'))).enabled,
      isFalse,
    );

    auth.requestCompleter!.complete(
      const PhoneVerificationSession(
        verificationId: 'renewed-session',
        resendToken: 5,
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('otpField')))
          .controller!
          .text,
      isEmpty,
    );
    await tester.enterText(find.byKey(const Key('otpField')), '654321');
    await tester.pump();
    expect(auth.lastVerificationId, 'renewed-session');
    expect(auth.lastSmsCode, '654321');
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'name entry preserves international names and avoids duplicate saves',
    (WidgetTester tester) async {
      final _FakeDriverProfileStore profiles = _FakeDriverProfileStore()
        ..saveCompleter = Completer<void>();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: DriverNameScreen(
            userId: 'driver-uid',
            phoneNumber: '+211912345678',
            profileStore: profiles,
          ),
        ),
      );
      await tester.enterText(
        find.byKey(const Key('firstNameField')),
        '  ናትናኤል  ',
      );
      await tester.enterText(
        find.byKey(const Key('lastNameField')),
        '  José  ',
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('saveDriverName')));
      await tester.pump();
      expect(profiles.savedFirstName, 'ናትናኤል');
      expect(profiles.savedLastName, 'José');
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('firstNameField')))
            .enabled,
        isFalse,
      );
      expect(
        tester
            .widget<ElevatedButton>(find.byKey(const Key('saveDriverName')))
            .onPressed,
        isNull,
      );
      expect(profiles.saveCount, 1);
      profiles.saveCompleter!.complete();
      await tester.pump();
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'auth pages support narrow screens, large text, and an open keyboard',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(280, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      for (final ThemeData theme in <ThemeData>[
        AppTheme.light,
        AppTheme.dark,
      ]) {
        for (final Widget page in <Widget>[
          PhoneLoginScreen(authService: _FakeDriverAuthService()),
          OtpScreen(
            phoneNumber: '+211 912345678',
            verificationId: 'layout-session',
            authService: _FakeDriverAuthService(),
          ),
          DriverNameScreen(
            userId: 'layout-driver',
            phoneNumber: '+211912345678',
            profileStore: _FakeDriverProfileStore(),
          ),
        ]) {
          await tester.pumpWidget(
            MaterialApp(
              key: UniqueKey(),
              theme: theme,
              builder: (BuildContext context, Widget? child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: const TextScaler.linear(1.6),
                  viewInsets: const EdgeInsets.only(bottom: 240),
                ),
                child: child!,
              ),
              home: page,
            ),
          );
          await tester.pump();
          await tester.ensureVisible(find.byType(TextField).last);
          await tester.pump();
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
        }
      }
    },
  );

  test(
    'agreement store rejects an unchecked acknowledgement before Firebase access',
    () async {
      await expectLater(
        FirebaseDriverAgreementStore().saveAcknowledgement(
          accepted: false,
          productUpdates: true,
        ),
        throwsArgumentError,
      );
    },
  );

  testWidgets('agreement details never select consent or save choices', (
    WidgetTester tester,
  ) async {
    final _FakeDriverAgreementStore store = _FakeDriverAgreementStore();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: AgreementsScreen(
          driverName: 'Test Driver',
          agreementStore: store,
        ),
      ),
    );

    for (final (String link, DriverLegalDocument document)
        in <(String, DriverLegalDocument)>[
          ('readDriverAgreement', DriverLegalDocument.service),
          ('readDriverPrivacy', DriverLegalDocument.privacy),
          ('readDriverUpdates', DriverLegalDocument.updates),
        ]) {
      await tester.ensureVisible(find.byKey(Key(link)));
      await tester.tap(find.byKey(Key(link)));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<DriverLegalDetailsScreen>(
              find.byType(DriverLegalDetailsScreen),
            )
            .document,
        document,
      );
      expect(find.byKey(const Key('legalSummaryNotice')), findsOneWidget);
      await tester.tap(find.byKey(const Key('closeLegalDetails')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<Checkbox>(find.byKey(const Key('driverAgreementCheckbox')))
            .value,
        isFalse,
      );
      expect(
        tester
            .widget<Checkbox>(find.byKey(const Key('driverUpdatesCheckbox')))
            .value,
        isFalse,
      );
    }
    expect(store.saveCount, 0);
    expect(
      tester
          .widget<ElevatedButton>(
            find.byKey(const Key('continueDriverAgreements')),
          )
          .onPressed,
      isNull,
    );
  });

  testWidgets('agreements save once and wait before advancing', (
    WidgetTester tester,
  ) async {
    final _FakeDriverAgreementStore store = _FakeDriverAgreementStore()
      ..saveCompleter = Completer<void>();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: AgreementsScreen(
          driverName: 'Test Driver',
          agreementStore: store,
        ),
      ),
    );
    final Finder button = find.byKey(const Key('continueDriverAgreements'));
    await tester.ensureVisible(find.byKey(const Key('driverUpdatesCheckbox')));
    await tester.tap(find.byKey(const Key('driverUpdatesCheckbox')));
    await tester.pump();
    expect(tester.widget<ElevatedButton>(button).onPressed, isNull);

    await tester.ensureVisible(
      find.byKey(const Key('driverAgreementCheckbox')),
    );
    await tester.tap(find.byKey(const Key('driverAgreementCheckbox')));
    await tester.pump();
    await tester.tap(button);
    await tester.pump();
    expect(store.saveCount, 1);
    expect(store.lastAccepted, isTrue);
    expect(store.lastProductUpdates, isTrue);
    expect(tester.widget<ElevatedButton>(button).onPressed, isNull);
    expect(
      tester
          .widget<Checkbox>(find.byKey(const Key('driverAgreementCheckbox')))
          .onChanged,
      isNull,
    );
    expect(
      tester
          .widget<Checkbox>(find.byKey(const Key('driverUpdatesCheckbox')))
          .onChanged,
      isNull,
    );
    expect(find.text('Choose how you’ll earn'), findsNothing);
    await tester.tap(button);
    await tester.pump();
    expect(store.saveCount, 1);

    store.saveCompleter!.complete();
    await tester.pumpAndSettle();
    expect(find.text('Choose how you’ll earn'), findsOneWidget);
    Navigator.of(tester.element(find.text('Choose how you’ll earn'))).pop();
    await tester.pumpAndSettle();
    expect(tester.widget<ElevatedButton>(button).onPressed, isNotNull);
    expect(
      tester
          .widget<Checkbox>(find.byKey(const Key('driverAgreementCheckbox')))
          .value,
      isTrue,
    );
    expect(store.saveCount, 1);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'agreement save failure preserves choices and allows retry without updates',
    (WidgetTester tester) async {
      final _FakeDriverAgreementStore store = _FakeDriverAgreementStore()
        ..saveCompleter = Completer<void>();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: AgreementsScreen(
            driverName: 'Test Driver',
            agreementStore: store,
          ),
        ),
      );
      await tester.ensureVisible(
        find.byKey(const Key('driverAgreementCheckbox')),
      );
      await tester.tap(find.byKey(const Key('driverAgreementCheckbox')));
      await tester.pump();
      final Finder button = find.byKey(const Key('continueDriverAgreements'));
      await tester.tap(button);
      await tester.pump();
      store.saveCompleter!.completeError(StateError('Save failed'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('driverAgreementError')), findsOneWidget);
      expect(
        tester
            .getRect(find.byKey(const Key('driverAgreementError')))
            .overlaps(tester.getRect(find.byType(SingleChildScrollView))),
        isTrue,
      );
      expect(find.text('Choose how you’ll earn'), findsNothing);
      expect(
        tester
            .widget<Checkbox>(find.byKey(const Key('driverAgreementCheckbox')))
            .value,
        isTrue,
      );
      expect(
        tester
            .widget<Checkbox>(find.byKey(const Key('driverUpdatesCheckbox')))
            .value,
        isFalse,
      );
      expect(tester.widget<ElevatedButton>(button).onPressed, isNotNull);

      store.saveCompleter = null;
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(store.saveCount, 2);
      expect(store.lastProductUpdates, isFalse);
      expect(find.text('Choose how you’ll earn'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('phone legal reader leaves SMS and consent unchanged', (
    WidgetTester tester,
  ) async {
    final _FakeDriverAuthService auth = _FakeDriverAuthService();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: PhoneLoginScreen(authService: auth),
      ),
    );
    await tester.ensureVisible(find.byKey(const Key('phoneLegalDetails')));
    await tester.tap(find.byKey(const Key('phoneLegalDetails')));
    await tester.pumpAndSettle();
    expect(find.text('User Agreement & Privacy'), findsOneWidget);
    expect(find.text('Driver service guidelines'), findsOneWidget);
    expect(find.text('Your information'), findsOneWidget);
    await tester.tap(find.byKey(const Key('closeLegalDetails')));
    await tester.pumpAndSettle();
    expect(auth.requestCount, 0);
    expect(
      tester
          .widget<Checkbox>(find.byKey(const Key('legalConsentCheckbox')))
          .value,
      isFalse,
    );
  });

  testWidgets(
    'agreement and legal readers fit narrow screens with large text',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(280, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final ThemeData theme in <ThemeData>[
        AppTheme.light,
        AppTheme.dark,
      ]) {
        final List<Widget> pages = <Widget>[
          AgreementsScreen(
            driverName: 'Test Driver',
            agreementStore: _FakeDriverAgreementStore(),
          ),
          for (final DriverLegalDocument document in DriverLegalDocument.values)
            DriverLegalDetailsScreen(document: document),
        ];
        for (final Widget page in pages) {
          await tester.pumpWidget(
            MaterialApp(
              key: UniqueKey(),
              theme: theme,
              builder: (BuildContext context, Widget? child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: const TextScaler.linear(1.6)),
                child: child!,
              ),
              home: page,
            ),
          );
          await tester.pump();
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
        }
      }
    },
  );

  testWidgets(
    'biometric onboarding can be skipped without enabling or prompting',
    (WidgetTester tester) async {
      final BiometricFixture fixture = BiometricFixture();
      await fixture.start();
      addTearDown(fixture.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: BiometricOptInScreen(
            driverName: 'Test Driver',
            controller: fixture.controller,
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('skipDriverBiometrics')));
      await tester.pumpAndSettle();
      expect(find.text('Agreements'), findsOneWidget);
      expect(fixture.device.prompts, 0);
      expect(fixture.preferences.writes, 0);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'biometric onboarding does not advance on cancel and waits for success',
    (WidgetTester tester) async {
      final BiometricFixture fixture = BiometricFixture();
      await fixture.start();
      addTearDown(fixture.dispose);
      fixture.device.result = DriverBiometricResult.cancelled;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: BiometricOptInScreen(
            driverName: 'Test Driver',
            controller: fixture.controller,
          ),
        ),
      );
      final Finder enable = find.byKey(const Key('enableDriverBiometrics'));
      await tester.tap(enable);
      await tester.pumpAndSettle();
      expect(find.text('Agreements'), findsNothing);
      expect(find.byKey(const Key('biometricOptInMessage')), findsOneWidget);
      expect(fixture.controller.enabled, isFalse);

      fixture.device.authentication = Completer<DriverBiometricResult>();
      await tester.tap(enable);
      await tester.pump();
      expect(tester.widget<ElevatedButton>(enable).onPressed, isNull);
      expect(
        tester
            .widget<TextButton>(find.byKey(const Key('skipDriverBiometrics')))
            .onPressed,
        isNull,
      );
      expect(find.text('Agreements'), findsNothing);
      fixture.device.authentication!.complete(DriverBiometricResult.success);
      await tester.pumpAndSettle();
      expect(find.text('Agreements'), findsOneWidget);
      expect(fixture.preferences.values['driver-a'], isTrue);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'root lock covers pushed pages and logout discards their navigation',
    (WidgetTester tester) async {
      final BiometricFixture fixture = BiometricFixture();
      fixture.preferences.values['driver-a'] = true;
      fixture.controller.confirmPhoneSignIn('driver-a');
      final _MutableDriverAuthService auth = _MutableDriverAuthService(fixture);
      addTearDown(fixture.dispose);
      addTearDown(auth.close);
      await tester.pumpWidget(
        AlphaPlusApp(
          authService: auth,
          biometricController: fixture.controller,
          home: Builder(
            builder: (BuildContext context) => Scaffold(
              body: fixture.uid == null
                  ? const Text('Signed out test home')
                  : ElevatedButton(
                      onPressed: () => Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (_) => const Scaffold(
                            body: Text('Private driver detail'),
                          ),
                        ),
                      ),
                      child: const Text('Open private detail'),
                    ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open private detail'));
      await tester.pumpAndSettle();
      expect(find.text('Private driver detail'), findsOneWidget);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('driverBiometricLock')), findsOneWidget);
      expect(find.text('Private driver detail'), findsNothing);
      expect(
        find.text('Private driver detail', skipOffstage: false),
        findsOneWidget,
      );
      fixture.device.result = DriverBiometricResult.cancelled;
      await tester.tap(find.byKey(const Key('unlockDriverApp')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('driverBiometricLock')), findsOneWidget);
      fixture.device.result = DriverBiometricResult.success;
      await tester.tap(find.byKey(const Key('unlockDriverApp')));
      await tester.pumpAndSettle();
      expect(find.text('Private driver detail'), findsOneWidget);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('biometricPhoneSignIn')));
      await tester.pumpAndSettle();
      expect(auth.signOutCount, 1);
      expect(
        find.text('Private driver detail', skipOffstage: false),
        findsNothing,
      );
      expect(find.text('Signed out test home'), findsOneWidget);
      expect(fixture.preferences.values['driver-a'], isTrue);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('back navigation cannot expose a page under the biometric gate', (
    WidgetTester tester,
  ) async {
    final BiometricFixture fixture = BiometricFixture();
    await fixture.start();
    addTearDown(fixture.dispose);
    final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        theme: AppTheme.light,
        builder: (BuildContext context, Widget? child) => DriverBiometricGate(
          controller: fixture.controller,
          onPhoneSignIn: () async {},
          child: child!,
        ),
        home: const Scaffold(body: Text('Private home')),
      ),
    );
    navigatorKey.currentState!.push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('Private second page')),
      ),
    );
    await tester.pumpAndSettle();
    await fixture.controller.enable();
    fixture.controller.handleLifecycle(AppLifecycleState.paused);
    fixture.controller.handleLifecycle(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    navigatorKey.currentState!.pop();
    await tester.pumpAndSettle();
    expect(find.text('Private home'), findsNothing);
    expect(find.byKey(const Key('driverBiometricLock')), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('quick unlock settings requires confirmation before disabling', (
    WidgetTester tester,
  ) async {
    final BiometricFixture fixture = BiometricFixture();
    await fixture.start(enabled: true);
    await fixture.controller.unlock();
    addTearDown(fixture.dispose);
    fixture.device.result = DriverBiometricResult.cancelled;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: DriverBiometricSettingsScreen(controller: fixture.controller),
      ),
    );
    await tester.tap(find.byKey(const Key('changeQuickUnlock')));
    await tester.pumpAndSettle();
    expect(fixture.controller.enabled, isTrue);
    fixture.device.result = DriverBiometricResult.success;
    await tester.tap(find.byKey(const Key('changeQuickUnlock')));
    await tester.pumpAndSettle();
    expect(fixture.controller.enabled, isFalse);
    expect(find.text('Quick unlock turned off.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('biometric screens support narrow layouts and large text', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(280, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final BiometricFixture fixture = BiometricFixture();
    await fixture.start();
    addTearDown(fixture.dispose);
    for (final ThemeData theme in <ThemeData>[AppTheme.light, AppTheme.dark]) {
      for (final Widget page in <Widget>[
        BiometricOptInScreen(
          driverName: 'Test Driver',
          controller: fixture.controller,
        ),
        DriverBiometricSettingsScreen(controller: fixture.controller),
      ]) {
        await tester.pumpWidget(
          MaterialApp(
            key: UniqueKey(),
            theme: theme,
            builder: (BuildContext context, Widget? child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(1.6)),
              child: child!,
            ),
            home: page,
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      }
      fixture.preferences.values['driver-a'] = true;
      await fixture.controller.bindAccount('driver-a');
      await tester.pumpWidget(
        MaterialApp(
          key: UniqueKey(),
          theme: theme,
          builder: (BuildContext context, Widget? child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(1.6)),
            child: DriverBiometricGate(
              controller: fixture.controller,
              onPhoneSignIn: () async {},
              child: child!,
            ),
          ),
          home: const Scaffold(body: Text('Hidden page')),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });

  testWidgets('map attribution stays clear below the dashboard card', (
    WidgetTester tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final List<(Size, double)> layouts = <(Size, double)>[
      (const Size(390, 844), 1.0),
      (const Size(320, 640), 1.6),
      (const Size(800, 480), 1.3),
    ];
    for (final ThemeData theme in <ThemeData>[AppTheme.light, AppTheme.dark]) {
      for (final (Size size, double textScale) in layouts) {
        tester.view.physicalSize = size;
        await tester.pumpWidget(
          MaterialApp(
            key: UniqueKey(),
            theme: theme,
            builder: (BuildContext context, Widget? child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(textScale),
                padding: const EdgeInsets.only(top: 24, bottom: 24),
              ),
              child: child!,
            ),
            home: DriverShell(
              driverName: 'Test Driver',
              registration: DriverRegistration(),
              mapBuilder: (BuildContext context) => Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  const ColoredBox(
                    key: Key('driverMapTestSurface'),
                    color: Colors.white,
                  ),
                  // A layout proxy only: the real Google logo is drawn by the SDK.
                  Positioned(
                    left: 8,
                    bottom: MediaQuery.paddingOf(context).bottom + 8,
                    child: const SizedBox(
                      key: Key('nativeAttributionTestBounds'),
                      width: 96,
                      height: 32,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump();
        expect(tester.takeException(), isNull);

        final Rect map = tester.getRect(
          find.byKey(const Key('driverMapTestSurface')),
        );
        final Rect card = tester.getRect(
          find.byKey(const Key('driverProgressCard')),
        );
        final Rect clearance = tester.getRect(
          find.byKey(const Key('driverMapAttributionClearance')),
        );
        final Rect attribution = tester.getRect(
          find.byKey(const Key('nativeAttributionTestBounds')),
        );
        expect(card.bottom, lessThanOrEqualTo(clearance.top + 0.1));
        expect(attribution.top, greaterThanOrEqualTo(clearance.top));
        expect(attribution.bottom, lessThanOrEqualTo(map.bottom));
        expect(card.overlaps(attribution), isFalse);

        final Finder scroll = find.byKey(const Key('driverProgressScroll'));
        final ScrollableState scrollState = tester.state<ScrollableState>(
          find.descendant(of: scroll, matching: find.byType(Scrollable)).first,
        );
        if (scrollState.position.maxScrollExtent > 0) {
          await tester.drag(scroll, const Offset(0, -600));
          await tester.pumpAndSettle();
          expect(scrollState.position.pixels, greaterThan(0));
          expect(
            tester.getRect(find.text('Device setup')).overlaps(card),
            isTrue,
          );
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      }
    }
  });

  test(
    'camera framing keeps the location between overlays at different zooms',
    () {
      const LatLng driverLocation = LatLng(4.8517, 31.5825);
      const EdgeInsets viewport = EdgeInsets.only(top: 120, bottom: 380);
      const EdgeInsets nativePadding = EdgeInsets.fromLTRB(8, 120, 8, 8);
      const double mapHeight = 760;

      double projectedY(double latitude) {
        final double radians = latitude * math.pi / 180;
        return (1 - math.log(math.tan(math.pi / 4 + radians / 2)) / math.pi) /
            2;
      }

      for (final double zoom in <double>[12, 16, 17, 20]) {
        final CameraPosition camera = driverMapCameraPosition(
          location: driverLocation,
          zoom: zoom,
          viewportInsets: viewport,
          mapPadding: nativePadding,
        );
        final double worldSize = 256 * math.pow(2, zoom).toDouble();
        final double nativeCenter =
            (mapHeight + nativePadding.top - nativePadding.bottom) / 2;
        final double driverScreenY =
            nativeCenter +
            (projectedY(driverLocation.latitude) -
                    projectedY(camera.target.latitude)) *
                worldSize;
        final double visibleCenter =
            (mapHeight + viewport.top - viewport.bottom) / 2;
        expect(driverScreenY, closeTo(visibleCenter, 0.001));
        expect(camera.target.longitude, driverLocation.longitude);
        expect(camera.zoom, zoom);
      }

      final CameraPosition unshifted = driverMapCameraPosition(
        location: driverLocation,
        zoom: 17,
        viewportInsets: nativePadding,
        mapPadding: nativePadding,
      );
      expect(unshifted.target, driverLocation);
    },
  );

  testWidgets('driver profile actions open their detail pages', (
    WidgetTester tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final DriverRegistration registration = DriverRegistration()
      ..vehicleType = 'Car'
      ..make = 'Toyota'
      ..model = 'Corolla'
      ..color = 'White'
      ..manufactureYear = '2020'
      ..plateNumber = 'SSD 123 A';

    final List<(Size, double)> layouts = <(Size, double)>[
      (const Size(320, 640), 1.6),
      (const Size(390, 844), 1.0),
      (const Size(800, 700), 1.0),
      (const Size(800, 700), 1.6),
    ];
    for (final ThemeData theme in <ThemeData>[AppTheme.light, AppTheme.dark]) {
      for (final (Size size, double textScale) in layouts) {
        tester.view.physicalSize = size;
        await tester.pumpWidget(
          MaterialApp(
            key: UniqueKey(),
            theme: theme,
            builder: (BuildContext context, Widget? child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(textScale)),
              child: child!,
            ),
            home: DriverShell(
              driverName: 'Test Driver',
              registration: registration,
              mapBuilder: (_) => const ColoredBox(color: Colors.white),
            ),
          ),
        );
        await tester.pumpAndSettle();
        // The off-screen Profile page must also lay out without exceptions.
        expect(tester.takeException(), isNull);

        await tester.tap(find.text('Profile'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Promo codes'), findsNothing);

        final Finder services = find.byKey(const Key('driverMyServicesButton'));
        await tester.ensureVisible(services);
        await tester.pumpAndSettle();
        final Rect summary = tester.getRect(
          find.byKey(const Key('driverServicesSummary')),
        );
        final Rect details = tester.getRect(
          find.byKey(const Key('driverServicesDetails')),
        );
        final Rect button = tester.getRect(services);
        expect(button.left, greaterThanOrEqualTo(summary.left));
        expect(button.right, lessThanOrEqualTo(summary.right + 0.1));
        expect(button.height, greaterThanOrEqualTo(48));
        expect(button.overlaps(details), isFalse);
        if (size.width == 320 || textScale > 1.0) {
          expect(button.top, greaterThanOrEqualTo(details.bottom + 11.9));
        } else if (size.width == 800) {
          expect(button.left, greaterThanOrEqualTo(details.right + 15.9));
        }

        await tester.tap(services);
        await tester.pumpAndSettle();
        expect(find.text('Passenger rides'), findsOneWidget);
        expect(find.text('Delivery'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.tap(find.byTooltip('Back'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Payment'));
        await tester.pumpAndSettle();
        expect(find.text('Alpha Plus South Sudan'), findsOneWidget);
        await tester.tap(find.text('Payment'));
        await tester.pumpAndSettle();

        expect(find.text('Cash payments'), findsOneWidget);
        expect(find.text('Card payments'), findsOneWidget);
        expect(find.text('Alpha Wallet'), findsOneWidget);
        expect(find.text('Coming soon'), findsNWidgets(2));
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      }
    }
  });

  testWidgets('money balance limit opens its explanation', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: DriverShell(
          driverName: 'Test Driver',
          registration: DriverRegistration(),
          mapBuilder: (_) => const ColoredBox(color: Colors.white),
        ),
      ),
    );

    await tester.tap(find.text('Money'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Balance limit'));
    await tester.pumpAndSettle();

    expect(find.text('Check your account\nbalance limit'), findsOneWidget);
    expect(find.text('Got it'), findsOneWidget);
  });
}

class _FakeDriverAuthService implements DriverAuthService {
  int requestCount = 0;
  int verifyCount = 0;
  int? lastResendToken;
  String? lastVerificationId;
  String? lastSmsCode;
  Completer<void>? verifyCompleter;
  Completer<PhoneVerificationSession>? requestCompleter;

  @override
  String? get currentPhoneNumber => null;

  @override
  String? get currentUserId => null;

  @override
  Stream<String?> get userIdChanges => const Stream<String?>.empty();

  @override
  Future<PhoneVerificationSession> requestCode({
    required String phoneNumber,
    int? forceResendingToken,
  }) async {
    requestCount += 1;
    lastResendToken = forceResendingToken;
    if (requestCompleter != null) return requestCompleter!.future;
    return const PhoneVerificationSession(
      verificationId: 'test-verification-id',
      resendToken: 1,
    );
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<void> verifyCode({
    required String verificationId,
    required String smsCode,
  }) async {
    verifyCount += 1;
    lastVerificationId = verificationId;
    lastSmsCode = smsCode;
    if (verifyCompleter != null) await verifyCompleter!.future;
  }
}

class _MutableDriverAuthService extends _FakeDriverAuthService {
  _MutableDriverAuthService(this.fixture);
  final BiometricFixture fixture;
  final StreamController<String?> _changes =
      StreamController<String?>.broadcast(sync: true);
  int signOutCount = 0;

  @override
  String? get currentUserId => fixture.uid;

  @override
  Stream<String?> get userIdChanges => _changes.stream;

  @override
  Future<void> signOut() async {
    signOutCount++;
    fixture.uid = null;
    _changes.add(null);
  }

  Future<void> close() => _changes.close();
}

class _FakeDriverAgreementStore implements DriverAgreementStore {
  int saveCount = 0;
  bool? lastAccepted;
  bool? lastProductUpdates;
  Completer<void>? saveCompleter;

  @override
  Future<void> saveAcknowledgement({
    required bool accepted,
    required bool productUpdates,
  }) async {
    saveCount += 1;
    lastAccepted = accepted;
    lastProductUpdates = productUpdates;
    if (saveCompleter != null) await saveCompleter!.future;
  }
}

class _FakeDriverProfileStore implements DriverProfileStore {
  int saveCount = 0;
  String? savedFirstName;
  String? savedLastName;
  Completer<void>? saveCompleter;

  @override
  Future<void> saveIdentity({
    required String uid,
    required String phoneNumber,
    required String firstName,
    required String lastName,
  }) async {
    saveCount += 1;
    savedFirstName = firstName;
    savedLastName = lastName;
    if (saveCompleter != null) await saveCompleter!.future;
  }

  @override
  Stream<DriverProfile?> watchProfile(String uid) =>
      const Stream<DriverProfile?>.empty();

  @override
  Future<DriverProfile?> fetchProfile(String uid) async => null;

  @override
  Future<void> completeOnboarding({
    required String uid,
    required DriverRegistration registration,
  }) async {}
}
