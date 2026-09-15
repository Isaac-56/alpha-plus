import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DriverAccountRoleService {
  DriverAccountRoleService({FirebaseFunctions? functions})
      : _functions =
            functions ?? FirebaseFunctions.instanceFor(region: 'africa-south1');

  static final DriverAccountRoleService instance =
      DriverAccountRoleService();

  final FirebaseFunctions _functions;

  Future<void> claimDriverRole() => _claimRole('driver');

  Future<void> _claimRole(String role) async {
    try {
      final HttpsCallableResult<dynamic> result =
          await _functions.httpsCallable('claimAccountRole').call<dynamic>(
        <String, dynamic>{'role': role},
      );
      final Object? data = result.data;
      if (data is Map && data['role'] == role) {
        return;
      }

      throw FirebaseAuthException(
        code: 'account-role-response-invalid',
        message: 'Alpha Plus could not confirm your account type.',
      );
    } on FirebaseFunctionsException catch (error) {
      final String? existingRole = _existingRole(error.details);

      if (error.code == 'failed-precondition' && existingRole == 'passenger') {
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
