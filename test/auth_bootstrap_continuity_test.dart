import 'package:alpha_plus/features/auth/data/driver_auth_service.dart';
import 'package:alpha_plus/features/profile/data/driver_profile_repository.dart';
import 'package:alpha_plus/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Auth extends Fake implements DriverAuthService {
  int streamRequests = 0;
  @override
  String? get currentUserId => null;
  @override
  String? get currentPhoneNumber => null;
  @override
  Stream<String?> get userIdChanges {
    streamRequests++;
    return Stream<String?>.value(null);
  }
}

class _Profiles extends Fake implements DriverProfileStore {}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  testWidgets('parent rebuild keeps the existing authentication listener', (
    tester,
  ) async {
    final auth = _Auth();
    final profiles = _Profiles();
    Widget app(bool dark) => MaterialApp(
      theme: dark ? ThemeData.dark() : ThemeData.light(),
      home: AppBootstrap(authService: auth, profileStore: profiles),
    );
    await tester.pumpWidget(app(false));
    await tester.pumpAndSettle();
    expect(auth.streamRequests, 1);
    expect(find.text('Enter your phone number'), findsOneWidget);
    await tester.pumpWidget(app(true));
    await tester.pumpAndSettle();
    expect(auth.streamRequests, 1);
    expect(find.text('Enter your phone number'), findsOneWidget);
  });
}
