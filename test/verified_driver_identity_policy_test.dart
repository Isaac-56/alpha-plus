import 'package:alpha_plus/features/profile/data/driver_profile_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VerifiedDriverIdentityPolicy', () {
    test('accepts the Firebase-authenticated phone identity', () {
      expect(
        VerifiedDriverIdentityPolicy.matches(
          expectedUid: 'driver-1',
          expectedPhoneNumber: '+211 912 345 678',
          authenticatedUid: 'driver-1',
          authenticatedPhoneNumber: '+211912345678',
        ),
        isTrue,
      );
    });

    test('blocks profile creation before SMS authentication', () {
      expect(
        VerifiedDriverIdentityPolicy.matches(
          expectedUid: 'driver-1',
          expectedPhoneNumber: '+211912345678',
          authenticatedUid: null,
          authenticatedPhoneNumber: null,
        ),
        isFalse,
      );
    });

    test('blocks a different Firebase account or phone number', () {
      expect(
        VerifiedDriverIdentityPolicy.matches(
          expectedUid: 'driver-1',
          expectedPhoneNumber: '+211912345678',
          authenticatedUid: 'driver-2',
          authenticatedPhoneNumber: '+211912345678',
        ),
        isFalse,
      );
      expect(
        VerifiedDriverIdentityPolicy.matches(
          expectedUid: 'driver-1',
          expectedPhoneNumber: '+211912345678',
          authenticatedUid: 'driver-1',
          authenticatedPhoneNumber: '+211987654321',
        ),
        isFalse,
      );
    });

    test('requires a normalized South Sudan E.164 phone identity', () {
      expect(
        VerifiedDriverIdentityPolicy.isVerifiedSouthSudanPhone(
          '+211 912 345 678',
        ),
        isTrue,
      );
      expect(
        VerifiedDriverIdentityPolicy.isVerifiedSouthSudanPhone(
          '+251912345678',
        ),
        isFalse,
      );
      expect(
        VerifiedDriverIdentityPolicy.isVerifiedSouthSudanPhone('+211123'),
        isFalse,
      );
    });
  });
}
