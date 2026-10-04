import 'package:alpha_plus/core/theme/app_theme.dart';
import 'package:alpha_plus/core/widgets/alpha_components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('driver flow components support light and dark workspaces', (
    WidgetTester tester,
  ) async {
    for (final ThemeData theme in <ThemeData>[AppTheme.light, AppTheme.dark]) {
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: const Scaffold(
            body: AlphaMapSheet(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  AlphaFlowHeader(
                    title: 'New ride request',
                    subtitle: '3 min to pickup',
                    compact: true,
                  ),
                  SizedBox(height: 12),
                  AlphaSurfaceCard(
                    child: AlphaMetricChip(
                      icon: Icons.payments_outlined,
                      label: '25,000 SSP',
                      emphasized: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('New ride request'), findsOneWidget);
      expect(find.text('25,000 SSP'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });
}
