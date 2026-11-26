import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:alpha_plus/core/widgets/resume_future_builder.dart';

void main() {
  testWidgets('permission reads survive rebuilds and refresh after settings', (tester) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    var calls = 0;
    Widget app() => MaterialApp(home: ResumeFutureBuilder<int>(
      load: () async => ++calls,
      builder: (_, snapshot) => Text('${snapshot.data}'),
    ));
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    expect(calls, 1);
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    expect(calls, 1);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(find.text('2'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
