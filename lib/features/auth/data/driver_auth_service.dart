import '../../../services/phone_verification_error.dart';

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';

import '../../../services/whatsapp_auth_service.dart';
import 'driver_session_service.dart';
import 'driver_biometric_controller.dart';
import 'verified_driver_identity_policy.dart';

class PhoneVerificationSession {
  const PhoneVerificationSession({
    required this.verificationId,
    this.resendToken,
    this.automaticallyVerified = false,
  });

  final String verificationId;
  final int? resendToken;
  final bool automaticallyVerified;
}

abstract class DriverAuthService {
  String? get currentUserId;

  String? get currentPhoneNumber;

  Stream<String?> get userIdChanges;

  Future<PhoneVerificationSession> requestCode({
    required String phoneNumber,
    int? forceResendingToken,
  });

  Future<void> verifyCode({
    required String verificationId,
    required String smsCode,
  });

  Future<void> signOut();
}

class FirebaseDriverAuthService implements DriverAuthService {
  FirebaseDriverAuthService({
    FirebaseAuth? auth,
    DriverSessionService? sessionService,
    DriverBiometricController? biometricController,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _sessionService = sessionService ?? DriverSessionService.instance,
       _biometricController =
           biometricController ?? DriverBiometricController.instance;

  final FirebaseAuth _auth;
  final DriverSessionService _sessionService;
  final DriverBiometricController _biometricController;
  Completer<void>? _activationTransition;

  @override
  String? get currentUserId => _auth.currentUser?.uid;

  @override
  String? get currentPhoneNumber => _auth.currentUser?.phoneNumber;

  @override
  Stream<String?> get userIdChanges => _auth.userChanges().asyncMap((
    User? observedUser,
  ) async {
    // Firebase emits a signed-in user before Alpha's role and device-session
    // checks finish. Keep the login UI mounted until that whole transition has
    // succeeded so a rejected passenger account can display its warning.
    final Completer<void>? transition = _activationTransition;
    if (transition != null) {
      await transition.future;
    }

    final User? currentUser = _auth.currentUser;
    return currentUser?.uid == observedUser?.uid ? currentUser?.uid : null;
  }).distinct();

  @override
  Future<PhoneVerificationSession> requestCode({
    required String phoneNumber,
    int? forceResendingToken,
  }) async {
    final id = await WhatsAppAuthService().requestCode(phoneNumber, 'driver');
    return PhoneVerificationSession(verificationId: id);
  }

  @override
  Future<void> verifyCode({
    required String verificationId,
    required String smsCode,
  }) async {
    final token = await WhatsAppAuthService().verifyCode(verificationId, smsCode);
    await _signInAndActivateSession(token);
  }

  @override
  Future<void> signOut() => _sessionService.signOutCurrentDevice();

  Future<void> _signInAndActivateSession(String customToken) async {
    _sessionService.beginSignIn();
    final Completer<void> transition = Completer<void>();
    _activationTransition = transition;

    try {
      final UserCredential result = await _auth.signInWithCustomToken(
        customToken,
      );
      final User? user = result.user;

      if (user == null) {
        throw StateError('Firebase did not return a signed-in driver.');
      }

      if (!VerifiedDriverIdentityPolicy.isVerifiedSouthSudanPhone(
        user.phoneNumber,
      )) {
        throw FirebaseAuthException(
          code: 'phone-number-not-verified',
          message: 'Firebase did not verify this South Sudan phone number.',
        );
      }

      // Refresh before calling protected backend services so the callable
      // receives the newly issued `phone_number` claim on the first attempt.
      await user.getIdToken(true);

      await _sessionService.activateSession(user);
      _biometricController.confirmPhoneSignIn(user.uid);
    } on Object {
      _sessionService.cancelSignIn();
      await _auth.signOut();
      rethrow;
    } finally {
      if (!transition.isCompleted) {
        transition.complete();
      }
      if (identical(_activationTransition, transition)) {
        _activationTransition = null;
      }
    }
  }
}

String readableAuthError(Object error) {
  if (error is FirebaseAuthException) {
    final serviceError = phoneVerificationServiceError(
      error.code,
      error.message,
    );
    if (serviceError != null) return serviceError;
    switch (error.code) {
      case 'invalid-phone-number':
        return 'Enter a valid South Sudan phone number.';
      case 'invalid-verification-code':
        return 'That verification code is incorrect. Try again.';
      case 'session-expired':
        return 'This code expired. Request a new WhatsApp code.';
      case 'too-many-requests':
        return 'Too many attempts. Wait a moment before trying again.';
      case 'network-request-failed':
        return 'Check your internet connection and try again.';
      case 'quota-exceeded':
        return 'WhatsApp verification is temporarily unavailable. Try again later.';
      case 'app-not-authorized':
        return 'This app is not authorized for Firebase phone sign-in.';
      case 'phone-number-not-verified':
        return 'Firebase could not verify this phone number. Request a new WhatsApp code.';
      default:
        return error.message ?? 'Phone verification failed. Please try again.';
    }
  }

  return 'Something went wrong. Please try again.';
}
