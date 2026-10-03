import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../auth/data/driver_account_role_service.dart';
import '../../onboarding/models/driver_registration.dart';
import '../models/driver_profile.dart';

abstract class DriverProfileStore {
  Stream<DriverProfile?> watchProfile(String uid);

  Future<DriverProfile?> fetchProfile(String uid);

  Future<void> saveIdentity({
    required String uid,
    required String phoneNumber,
    required String firstName,
    required String lastName,
  });

  Future<void> completeOnboarding({
    required String uid,
    required DriverRegistration registration,
  });
}

class VerifiedDriverIdentityPolicy {
  const VerifiedDriverIdentityPolicy._();

  static String normalizedPhone(String value) =>
      value.trim().replaceAll(RegExp(r'[\s()-]'), '');

  static bool matches({
    required String expectedUid,
    required String expectedPhoneNumber,
    required String? authenticatedUid,
    required String? authenticatedPhoneNumber,
  }) {
    if (authenticatedUid == null || authenticatedPhoneNumber == null) {
      return false;
    }
    return authenticatedUid == expectedUid &&
        normalizedPhone(authenticatedPhoneNumber) ==
            normalizedPhone(expectedPhoneNumber) &&
        normalizedPhone(authenticatedPhoneNumber).isNotEmpty;
  }
}

class FirebaseDriverProfileStore implements DriverProfileStore {
  FirebaseDriverProfileStore({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  DocumentReference<Map<String, dynamic>> _driver(String uid) =>
      _firestore.collection('drivers').doc(uid);

  @override
  Stream<DriverProfile?> watchProfile(String uid) {
    return _driver(uid).snapshots().map(_profileFromSnapshot);
  }

  @override
  Future<DriverProfile?> fetchProfile(String uid) async {
    final DocumentSnapshot<Map<String, dynamic>> snapshot = await _driver(
      uid,
    ).get();
    return _profileFromSnapshot(snapshot);
  }

  DriverProfile? _profileFromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final Map<String, dynamic>? data = snapshot.data();
    if (!snapshot.exists || data == null) {
      return null;
    }

    return DriverProfile.fromMap(uid: snapshot.id, data: data);
  }

  @override
  Future<void> saveIdentity({
    required String uid,
    required String phoneNumber,
    required String firstName,
    required String lastName,
  }) async {
    final User? authenticatedUser = _auth.currentUser;
    if (!VerifiedDriverIdentityPolicy.matches(
      expectedUid: uid,
      expectedPhoneNumber: phoneNumber,
      authenticatedUid: authenticatedUser?.uid,
      authenticatedPhoneNumber: authenticatedUser?.phoneNumber,
    )) {
      throw StateError(
        'Complete Firebase SMS verification before creating a driver profile.',
      );
    }

    await DriverAccountRoleService.instance.claimDriverRole();

    final DocumentReference<Map<String, dynamic>> driver = _driver(uid);
    await _firestore.runTransaction((Transaction transaction) async {
      final DocumentSnapshot<Map<String, dynamic>> snapshot = await transaction
          .get(driver);
      final Map<String, dynamic> data = <String, dynamic>{
        'uid': uid,
        'phoneNumber': authenticatedUser!.phoneNumber,
        'firstName': firstName.trim(),
        'lastName': lastName.trim(),
        'onboardingCompleted': false,
        'reviewStatus': 'draft',
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (!snapshot.exists) {
        data['createdAt'] = FieldValue.serverTimestamp();
      }
      transaction.set(driver, data, SetOptions(merge: true));
    });
  }

  @override
  Future<void> completeOnboarding({
    required String uid,
    required DriverRegistration registration,
  }) {
    return _driver(uid).set(<String, dynamic>{
      'registration': registration.toMap(),
      'onboardingCompleted': true,
      'reviewStatus': 'pending',
      'onboardingCompletedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
