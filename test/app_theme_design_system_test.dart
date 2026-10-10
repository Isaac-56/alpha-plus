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
    expect(
      AppTheme.dark.bottomSheetTheme.dragHandleSize,
      const Size(48, 5),
    );
  });
}
