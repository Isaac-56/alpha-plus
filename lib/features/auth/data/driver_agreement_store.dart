import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'driver_legal_content.dart';

abstract class DriverAgreementStore {
  Future<void> saveAcknowledgement({
    required bool accepted,
    required bool productUpdates,
  });
}

class DriverAgreementSessionExpired implements Exception {
  const DriverAgreementSessionExpired();
}

class FirebaseDriverAgreementStore implements DriverAgreementStore {
  FirebaseDriverAgreementStore({this._auth, this._firestore});

  final FirebaseAuth? _auth;
  final FirebaseFirestore? _firestore;

  @override
  Future<void> saveAcknowledgement({
    required bool accepted,
    required bool productUpdates,
  }) async {
    if (!accepted) {
      throw ArgumentError('The driver summaries must be acknowledged first.');
    }

    final FirebaseAuth auth = _auth ?? FirebaseAuth.instance;
    final String? uid = auth.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      throw const DriverAgreementSessionExpired();
    }

    final FirebaseFirestore firestore =
        _firestore ?? FirebaseFirestore.instance;
    // Update the existing UID-owned draft/pending profile only. Do not create
    // an orphan profile or overwrite its identity, review state, or other prefs.
    // The current onboarding rules permit this update for draft/pending drivers.
    await firestore
        .collection('drivers')
        .doc(uid)
        .update(<String, dynamic>{
          'onboardingAcknowledgement': <String, dynamic>{
            'documentKind': 'onboarding_summary',
            'version': DriverLegalContent.summaryVersion,
            'acknowledged': true,
            'recordedAt': FieldValue.serverTimestamp(),
          },
          'communicationPreferences.productUpdates': productUpdates,
          'communicationPreferences.updatedAt': FieldValue.serverTimestamp(),
        })
        .timeout(const Duration(seconds: 20));

    // Do not advance this flow if the account changed while saving.
    if (auth.currentUser?.uid != uid) {
      throw const DriverAgreementSessionExpired();
    }
  }
}
