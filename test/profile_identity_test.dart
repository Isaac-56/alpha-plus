import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../lib/features/profile/models/driver_profile.dart';
import '../lib/features/dashboard/presentation/driver_ui_pages.dart';

void main() {
  testWidgets(
    'driver profile header shows the verified phone alongside the name',
    (WidgetTester tester) async {
      final DriverProfile profile = DriverProfile.fromMap(
        uid: 'd1',
        data: <String, dynamic>{
          'phoneNumber': '+211912345678',
          'firstName': 'Alpha',
          'lastName': 'Driver',
          'photoStoragePath': 'drivers/d1/documents/photo_checks/face.jpg',
        },
      );
      expect(
        profile.photoStoragePath,
        'drivers/d1/documents/photo_checks/face.jpg',
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DriverProfilePageUi(
              driverName: profile.fullName,
              phoneNumber: profile.phoneNumber,
              reviewStatus: 'approved',
              registration: profile.registration,
            ),
          ),
        ),
      );
      expect(find.text('+211912345678'), findsOneWidget);
      expect(find.text('Alpha Driver'), findsOneWidget);
    },
  );
}
