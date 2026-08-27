import 'dart:async';
import 'dart:math' as math;

import 'package:alpha_plus/main.dart';
import 'package:alpha_plus/core/theme/app_theme.dart';
import 'package:alpha_plus/features/auth/data/driver_auth_service.dart';
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
    final DriverRegistration registration = DriverRegistration()
      ..vehicleType = 'Car'
      ..make = 'Toyota'
      ..model = 'Corolla'
      ..color = 'White'
      ..manufactureYear = '2020'
      ..plateNumber = 'SSD 123 A';

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: DriverShell(
          driverName: 'Test Driver',
          registration: registration,
          mapBuilder: (_) => const ColoredBox(color: Colors.white),
        ),
      ),
    );

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    expect(find.text('Alpha Plus South Sudan'), findsOneWidget);
    expect(find.text('Promo codes'), findsNothing);

    await tester.tap(find.text('Payment'));
    await tester.pumpAndSettle();

    expect(find.text('Cash payments'), findsOneWidget);
    expect(find.text('Card payments'), findsOneWidget);
    expect(find.text('Alpha Wallet'), findsOneWidget);
    expect(find.text('Coming soon'), findsNWidgets(2));
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
