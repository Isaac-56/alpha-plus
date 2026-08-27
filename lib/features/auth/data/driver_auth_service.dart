import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';

import 'driver_session_service.dart';
import 'driver_biometric_controller.dart';

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

  @override
  String? get currentUserId => _auth.currentUser?.uid;

  @override
  String? get currentPhoneNumber => _auth.currentUser?.phoneNumber;

  @override
  Stream<String?> get userIdChanges =>
      _auth.userChanges().map((User? user) => user?.uid).distinct();

  @override
  Future<PhoneVerificationSession> requestCode({
    required String phoneNumber,
    int? forceResendingToken,
  }) {
    final Completer<PhoneVerificationSession> completer =
        Completer<PhoneVerificationSession>();

    _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      forceResendingToken: forceResendingToken,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {
        try {
          await _signInAndActivateSession(credential);
          if (!completer.isCompleted) {
            completer.complete(
              const PhoneVerificationSession(
                verificationId: '',
                automaticallyVerified: true,
              ),
            );
          }
        } on Object catch (error, stackTrace) {
          if (!completer.isCompleted) {
            completer.completeError(error, stackTrace);
          }
        }
      },
      verificationFailed: (FirebaseAuthException error) {
        if (!completer.isCompleted) {
          completer.completeError(error, StackTrace.current);
        }
      },
      codeSent: (String verificationId, int? resendToken) {
        if (!completer.isCompleted) {
          completer.complete(
            PhoneVerificationSession(
              verificationId: verificationId,
              resendToken: resendToken,
            ),
          );
        }
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        if (!completer.isCompleted) {
          completer.complete(
            PhoneVerificationSession(
              verificationId: verificationId,
              resendToken: forceResendingToken,
            ),
          );
        }
      },
    );

    return completer.future;
  }

  @override
  Future<void> verifyCode({
    required String verificationId,
    required String smsCode,
  }) async {
    final PhoneAuthCredential credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    await _signInAndActivateSession(credential);
  }

  @override
  Future<void> signOut() => _sessionService.signOutCurrentDevice();

  Future<void> _signInAndActivateSession(PhoneAuthCredential credential) async {
    _sessionService.beginSignIn();

    try {
      final UserCredential result = await _auth.signInWithCredential(
        credential,
      );
      final User? user = result.user;

      if (user == null) {
        throw StateError('Firebase did not return a signed-in driver.');
      }

      await _sessionService.activateSession(user);
      _biometricController.confirmPhoneSignIn(user.uid);
    } on Object {
      _sessionService.cancelSignIn();
      await _auth.signOut();
      rethrow;
    }
  }
}

String readableAuthError(Object error) {
  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'invalid-phone-number':
        return 'Enter a valid South Sudan phone number.';
      case 'invalid-verification-code':
        return 'That verification code is incorrect. Try again.';
      case 'session-expired':
        return 'This code expired. Request a new SMS code.';
      case 'too-many-requests':
        return 'Too many attempts. Wait a moment before trying again.';
      case 'network-request-failed':
        return 'Check your internet connection and try again.';
      case 'quota-exceeded':
        return 'SMS verification is temporarily unavailable. Try again later.';
      case 'app-not-authorized':
        return 'This app is not authorized for Firebase phone sign-in.';
      default:
        return error.message ?? 'Phone verification failed. Please try again.';
    }
  }

  return 'Something went wrong. Please try again.';
}
