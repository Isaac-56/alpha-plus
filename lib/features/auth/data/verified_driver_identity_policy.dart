/// Security policy for the Firebase phone identity used by Alpha Plus.
///
/// A driver account is valid only when Firebase Authentication supplies the
/// same UID and a normalized South Sudan E.164 phone number. UI fields are
/// never treated as proof that the phone number was verified.
class VerifiedDriverIdentityPolicy {
  const VerifiedDriverIdentityPolicy._();

  static String normalizedPhone(String value) =>
      value.trim().replaceAll(RegExp(r'[\s()-]'), '');

  static bool isVerifiedSouthSudanPhone(String? value) {
    if (value == null) return false;
    return RegExp(r'^\+211\d{9}$').hasMatch(normalizedPhone(value));
  }

  static bool matches({
    required String expectedUid,
    required String expectedPhoneNumber,
    required String? authenticatedUid,
    required String? authenticatedPhoneNumber,
  }) {
    if (authenticatedUid == null ||
        !isVerifiedSouthSudanPhone(authenticatedPhoneNumber)) {
      return false;
    }

    return authenticatedUid == expectedUid &&
        normalizedPhone(authenticatedPhoneNumber!) ==
            normalizedPhone(expectedPhoneNumber);
  }
}
