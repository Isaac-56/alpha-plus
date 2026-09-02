import 'package:alpha_plus/core/theme/app_theme.dart';
import 'package:alpha_plus/core/theme/app_theme_controller.dart';
import 'package:alpha_plus/features/dashboard/presentation/driver_ui_pages.dart';
import 'package:alpha_plus/features/dashboard/presentation/driver_appearance_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    AppThemeController.themeMode.value = ThemeMode.system;
  });

  test('theme defaults to device settings', () async {
    await AppThemeController.initialize();

    expect(AppThemeController.themeMode.value, ThemeMode.system);
  });

  test('saved light and dark choices are restored', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'alpha_plus_theme_mode': 'light',
    });
    await AppThemeController.initialize();
    expect(AppThemeController.themeMode.value, ThemeMode.light);

    SharedPreferences.setMockInitialValues(<String, Object>{
      'alpha_plus_theme_mode': 'dark',
    });
    await AppThemeController.initialize();
    expect(AppThemeController.themeMode.value, ThemeMode.dark);
  });

  test('light theme uses a true white AlphaRide-style canvas', () {
    expect(AppTheme.light.scaffoldBackgroundColor, Colors.white);
    expect(AppTheme.light.colorScheme.surface, Colors.white);
  });

  testWidgets('appearance screen exposes system light and dark choices', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        home: const DriverAppearanceScreen(),
      ),
    );

    expect(find.text('Use device settings'), findsOneWidget);
    expect(find.text('Light mode'), findsOneWidget);
    expect(find.text('Dark mode'), findsOneWidget);
  });

  testWidgets('settings exposes app appearance near the top', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const DriverCompleteSettingsScreen(),
      ),
    );

    expect(find.text('App appearance'), findsOneWidget);
  });
}
