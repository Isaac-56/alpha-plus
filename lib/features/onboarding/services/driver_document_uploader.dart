import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

abstract class DriverDocumentUploader {
  Future<void> uploadLicence({
    required String driverId,
    required String frontImagePath,
    required String backImagePath,
  });
}

class FirebaseDriverDocumentUploader implements DriverDocumentUploader {
  FirebaseDriverDocumentUploader({
    FirebaseStorage? storage,
    FirebaseFirestore? firestore,
  }) : _storage = storage ?? FirebaseStorage.instance,
       _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseStorage _storage;
  final FirebaseFirestore _firestore;

  @override
  Future<void> uploadLicence({
    required String driverId,
    required String frontImagePath,
    required String backImagePath,
  }) async {
    final Reference licenceFolder = _storage.ref(
      'drivers/$driverId/documents/driver_licence',
    );
    final Reference frontReference = licenceFolder.child('front.jpg');
    final Reference backReference = licenceFolder.child('back.jpg');
    final SettableMetadata frontMetadata = SettableMetadata(
      contentType: 'image/jpeg',
      customMetadata: <String, String>{
        'driverId': driverId,
        'documentType': 'driver_licence',
        'side': 'front',
        'qualityChecked': 'true',
      },
    );
    final SettableMetadata backMetadata = SettableMetadata(
      contentType: 'image/jpeg',
      customMetadata: <String, String>{
        'driverId': driverId,
        'documentType': 'driver_licence',
        'side': 'back',
        'qualityChecked': 'true',
      },
    );

    await Future.wait<void>(<Future<void>>[
      frontReference
          .putFile(File(frontImagePath), frontMetadata)
          .then<void>((_) {}),
      backReference
          .putFile(File(backImagePath), backMetadata)
          .then<void>((_) {}),
    ]);

    await _firestore.collection('drivers').doc(driverId).set(<String, dynamic>{
      'documents': <String, dynamic>{
        'driverLicence': <String, dynamic>{
          'frontStoragePath': frontReference.fullPath,
          'backStoragePath': backReference.fullPath,
          'qualityChecked': true,
          'status': 'uploaded',
          'uploadedAt': FieldValue.serverTimestamp(),
        },
      },
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
