import 'package:alpha_plus/core/theme/app_theme.dart';
import 'package:alpha_plus/features/auth/presentation/phone_login_screen.dart';
import 'package:alpha_plus/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('splash runs once and opens the phone screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const AlphaPlusApp());

    expect(find.bySemanticsLabel('Alpha Plus'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 2700));
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Drive with Alpha+'), findsOneWidget);
    expect(find.byKey(const Key('phoneField')), findsOneWidget);
  });

  testWidgets('valid South Sudan phone number opens OTP', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const PhoneLoginScreen()),
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
}
