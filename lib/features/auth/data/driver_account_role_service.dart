import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

bool isTemporaryDriverRoleFailureCode(String code) {
  return const <String>{
    'account-role-unavailable',
    'account-role-deadline-exceeded',
    'account-role-internal',
    'account-role-resource-exhausted',
  }.contains(code);
}

class DriverAccountRoleService {
  DriverAccountRoleService({FirebaseFunctions? functions})
      : _functions =
            functions ?? FirebaseFunctions.instanceFor(region: 'africa-south1');

  static final DriverAccountRoleService instance =
      DriverAccountRoleService();

  final FirebaseFunctions _functions;

  Future<void> preflightDriverRole(String phoneNumber) =>
      _callRoleFunction(
        'preflightAccountRole',
        'driver',
        requireClaim: false,
        phoneNumber: phoneNumber,
      );

  Future<void> ensureDriverEligible() =>
      _callRoleFunction('checkAccountRole', 'driver', requireClaim: false);

  Future<void> claimDriverRole() =>
      _callRoleFunction('claimAccountRole', 'driver', requireClaim: true);

  Future<void> _callRoleFunction(
    String functionName,
    String role, {
    required bool requireClaim,
    String? phoneNumber,
  }) async {
    try {
      final HttpsCallableResult<dynamic> result =
          await _functions.httpsCallable(functionName).call<dynamic>(
        <String, dynamic>{
          'role': role,
          if (phoneNumber != null) 'phoneNumber': phoneNumber,
        },
      );
      final Object? data = result.data;

      if (data is Map) {
        final Object? resolvedRole = data['role'];
        final Object? eligible = data['eligible'];
        final Object? claimed = data['claimed'];

        if (eligible == true &&
            (resolvedRole == null || resolvedRole == role) &&
            (!requireClaim || (resolvedRole == role && claimed == true))) {
          return;
        }
      }

      throw FirebaseAuthException(
        code: 'account-role-response-invalid',
        message: 'Alpha Plus could not confirm your account type.',
      );
    } on FirebaseFunctionsException catch (error) {
      final String? existingRole = _existingRole(error.details);

      final bool namesAlphaRide =
          error.message?.contains('AlphaRide') ?? false;

      if (error.code == 'failed-precondition' &&
          (existingRole == 'passenger' || namesAlphaRide)) {
        throw FirebaseAuthException(
          code: 'account-role-conflict',
          message:
              'This phone number is already registered with AlphaRide. Use a different number for Alpha Plus.',
        );
      }

      throw FirebaseAuthException(
        code: 'account-role-${error.code}',
        message:
            error.message ?? 'Alpha Plus could not confirm your account type.',
      );
    }
  }

  String? _existingRole(Object? details) {
    if (details is Map) {
      final Object? value = details['existingRole'];
      if (value is String) {
        return value;
      }
    }
    return null;
  }
}
