import 'package:alpha_plus/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Alpha Plus supports matching light and dark design systems', () {
    expect(AppTheme.light.brightness, Brightness.light);
    expect(AppTheme.dark.brightness, Brightness.dark);
    expect(AppTheme.light.scaffoldBackgroundColor, Colors.white);
    expect(
      AppTheme.light.colorScheme.surface,
      isNot(AppTheme.dark.colorScheme.surface),
    );
    expect(AppTheme.light.navigationBarTheme.height, 68);
    expect(AppTheme.dark.bottomSheetTheme.dragHandleSize, const Size(48, 5));
  });
  for (final Brightness brightness in Brightness.values) {
    testWidgets('notifications use readable regular text in $brightness', (
      WidgetTester tester,
    ) async {
      final ThemeData theme = brightness == Brightness.light
          ? AppTheme.light
          : AppTheme.dark;
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Builder(
            builder: (BuildContext context) {
              return Scaffold(
                body: TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Connection restored')),
                    );
                  },
                  child: const Text('Show notice'),
                ),
              );
            },
          ),
        ),
      );
      await tester.tap(find.text('Show notice'));
      await tester.pumpAndSettle();
      final BuildContext context = tester.element(
        find.text('Connection restored'),
      );
      final TextStyle style = DefaultTextStyle.of(context).style;
      expect(style.fontSize, 14);
      expect(style.fontWeight, FontWeight.w400);
      expect(style.color, theme.snackBarTheme.contentTextStyle!.color);
      expect(tester.takeException(), isNull);
    });
  }
}
