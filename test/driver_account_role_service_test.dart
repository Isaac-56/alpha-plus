import 'package:alpha_plus/features/auth/data/driver_account_role_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('temporary driver role failures preserve an existing session', () {
    expect(isTemporaryDriverRoleFailureCode('account-role-unavailable'), isTrue);
    expect(
      isTemporaryDriverRoleFailureCode('account-role-deadline-exceeded'),
      isTrue,
    );
    expect(isTemporaryDriverRoleFailureCode('account-role-internal'), isTrue);
    expect(
      isTemporaryDriverRoleFailureCode('account-role-resource-exhausted'),
      isTrue,
    );
  });

  test('driver role conflicts fail closed', () {
    expect(isTemporaryDriverRoleFailureCode('account-role-conflict'), isFalse);
    expect(
      isTemporaryDriverRoleFailureCode('account-role-failed-precondition'),
      isFalse,
    );
    expect(
      isTemporaryDriverRoleFailureCode('account-role-response-invalid'),
      isFalse,
    );
  });
}
