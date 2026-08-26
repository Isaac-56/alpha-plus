import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Enforces one active Alpha Plus installation for each Firebase driver UID.
///
/// A new successful sign-in replaces the session ID stored in Firestore. Any
/// older installation watching that document signs itself out as soon as the
/// server change arrives. A backgrounded app validates again when it resumes.
class DriverSessionService {
  DriverSessionService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  static final DriverSessionService instance = DriverSessionService();

  static const String _sessionPrefix = 'alpha_plus_active_session_';

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  bool _signInInProgress = false;

  DocumentReference<Map<String, dynamic>> _sessionReference(String uid) {
    return _firestore.collection('driver_sessions').doc(uid);
  }

  String _localSessionKey(String uid) => '$_sessionPrefix$uid';

  void beginSignIn() {
    _signInInProgress = true;
  }

  void cancelSignIn() {
    _signInInProgress = false;
  }

  Future<void> activateSession(User user) async {
    _signInInProgress = true;

    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final String localKey = _localSessionKey(user.uid);
    final String sessionId = _createSessionId();

    try {
      await preferences.setString(localKey, sessionId);

      await _sessionReference(user.uid).set(<String, dynamic>{
        'activeSessionId': sessionId,
        'uid': user.uid,
        'phoneNumber': user.phoneNumber,
        'platform': 'driver',
        'signedInAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'signedOutAt': FieldValue.delete(),
      }, SetOptions(merge: true));
    } on Object {
      await preferences.remove(localKey);
      rethrow;
    } finally {
      _signInInProgress = false;
    }
  }

  /// Checks whether this installation still owns the active cloud session.
  ///
  /// The first app version containing this feature safely creates a missing
  /// session document for an already-authenticated driver. An existing remote
  /// session is never overwritten during startup.
  Future<bool> validateExistingSession({
    required String uid,
    required String phoneNumber,
    bool forceServer = true,
  }) async {
    await _waitForSignInTransition();

    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final String localKey = _localSessionKey(uid);
    final String? localSessionId = preferences.getString(localKey);

    try {
      final DocumentSnapshot<Map<String, dynamic>> snapshot = forceServer
          ? await _sessionReference(
              uid,
            ).get(const GetOptions(source: Source.server))
          : await _sessionReference(uid).get();
      final String? remoteSessionId =
          snapshot.data()?['activeSessionId'] as String?;

      if (!snapshot.exists) {
        final String migratedSessionId = localSessionId ?? _createSessionId();

        await preferences.setString(localKey, migratedSessionId);
        await _sessionReference(uid).set(<String, dynamic>{
          'activeSessionId': migratedSessionId,
          'uid': uid,
          'phoneNumber': phoneNumber,
          'platform': 'driver',
          'signedInAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        return true;
      }

      return localSessionId != null &&
          remoteSessionId != null &&
          localSessionId == remoteSessionId;
    } on FirebaseException catch (error) {
      debugPrint('Unable to validate the Alpha Plus session: $error');

      // Do not log out a legitimate active driver because of a short outage.
      // A server check is repeated automatically when connectivity resumes.
      return localSessionId != null;
    }
  }

  Stream<bool> watchSession({required String uid}) async* {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final String? localSessionId = preferences.getString(_localSessionKey(uid));

    if (localSessionId == null) {
      yield false;
      return;
    }

    while (_auth.currentUser?.uid == uid) {
      try {
        await for (final DocumentSnapshot<Map<String, dynamic>> snapshot
            in _sessionReference(uid).snapshots(includeMetadataChanges: true)) {
          // Never force a logout from an old offline cache entry. Only a
          // server-confirmed session replacement is authoritative.
          if (snapshot.metadata.isFromCache) {
            continue;
          }

          final String? remoteSessionId =
              snapshot.data()?['activeSessionId'] as String?;
          final bool isCurrent =
              snapshot.exists && remoteSessionId == localSessionId;

          yield isCurrent;

          if (!isCurrent) {
            return;
          }
        }

        return;
      } on FirebaseException catch (error) {
        debugPrint('Alpha Plus session listener paused: $error');

        final bool isCurrent = await validateExistingSession(
          uid: uid,
          phoneNumber: _auth.currentUser?.phoneNumber ?? '',
          forceServer: true,
        );

        if (!isCurrent) {
          yield false;
          return;
        }

        await Future<void>.delayed(const Duration(seconds: 1));
      }
    }
  }

  Future<void> signOutCurrentDevice() async {
    final User? user = _auth.currentUser;
    final SharedPreferences preferences = await SharedPreferences.getInstance();

    if (user != null) {
      final String localKey = _localSessionKey(user.uid);
      final String? localSessionId = preferences.getString(localKey);

      if (localSessionId != null) {
        try {
          await _firestore.runTransaction<void>((
            Transaction transaction,
          ) async {
            final DocumentReference<Map<String, dynamic>> reference =
                _sessionReference(user.uid);
            final DocumentSnapshot<Map<String, dynamic>> snapshot =
                await transaction.get(reference);
            final String? remoteSessionId =
                snapshot.data()?['activeSessionId'] as String?;

            if (remoteSessionId == localSessionId) {
              transaction.set(reference, <String, dynamic>{
                'activeSessionId': null,
                'updatedAt': FieldValue.serverTimestamp(),
                'signedOutAt': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true));
            }
          });
        } on FirebaseException catch (error) {
          debugPrint('Unable to close the remote driver session: $error');
        }
      }

      await preferences.remove(localKey);
    }

    await _auth.signOut();
  }

  Future<void> forceLocalSignOut(String uid) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.remove(_localSessionKey(uid));

    if (_auth.currentUser?.uid == uid) {
      await _auth.signOut();
    }
  }

  Future<void> _waitForSignInTransition() async {
    for (int attempt = 0; _signInInProgress && attempt < 300; attempt += 1) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }

  String _createSessionId() {
    final Random random = Random.secure();
    final List<int> bytes = List<int>.generate(
      32,
      (_) => random.nextInt(256),
      growable: false,
    );

    return base64UrlEncode(bytes).replaceAll('=', '');
  }
}
