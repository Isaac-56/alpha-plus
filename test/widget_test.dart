import 'package:alpha_plus/main.dart';
import 'package:alpha_plus/core/theme/app_theme.dart';
import 'package:alpha_plus/features/auth/data/driver_auth_service.dart';
import 'package:alpha_plus/features/auth/presentation/phone_login_screen.dart';
import 'package:alpha_plus/features/auth/presentation/splash_screen.dart';
import 'package:alpha_plus/features/dashboard/presentation/driver_shell.dart';
import 'package:alpha_plus/features/onboarding/models/driver_registration.dart';
import 'package:alpha_plus/features/onboarding/presentation/stage_one_complete_screen.dart';
import 'package:alpha_plus/features/profile/models/driver_profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
  }) async {}
}
