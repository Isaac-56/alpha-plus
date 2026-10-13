import 'dart:io';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import '../../onboarding/services/document_quality_analyzer.dart';

@immutable
class DriverFaceMetrics {
  const DriverFaceMetrics({
    required this.coverage,
    required this.headPitch,
    required this.headYaw,
    required this.headRoll,
    this.leftEyeOpenProbability,
    this.rightEyeOpenProbability,
  });

  final double coverage;
  final double headPitch;
  final double headYaw;
  final double headRoll;
  final double? leftEyeOpenProbability;
  final double? rightEyeOpenProbability;
}

@immutable
class DriverPhotoCheckResult {
  const DriverPhotoCheckResult({
    required this.accepted,
    required this.issues,
    required this.faceCount,
    this.faceMetrics,
    this.imageMetrics,
  });

  final bool accepted;
  final List<String> issues;
  final int faceCount;
  final DriverFaceMetrics? faceMetrics;
  final DocumentQualityMetrics? imageMetrics;
}

abstract class DriverPhotoCheckAnalyzer {
  Future<DriverPhotoCheckResult> analyze(String imagePath);

  Future<void> close();
}

class DriverPhotoCheckPolicy {
  const DriverPhotoCheckPolicy._();

  static DriverPhotoCheckResult evaluate({
    required DocumentQualityResult imageQuality,
    required int faceCount,
    DriverFaceMetrics? faceMetrics,
  }) {
    final List<String> issues = <String>[];
    final DocumentQualityMetrics? metrics = imageQuality.metrics;
    if (metrics == null) {
      issues.add('The photo could not be opened. Please retake it.');
    } else {
      if (metrics.fileBytes < 4096 ||
          metrics.fileBytes > 12 * 1024 * 1024 ||
          math.min(metrics.width, metrics.height) < 240 ||
          math.max(metrics.width, metrics.height) < 320) {
        issues.add(
          'The photo needs a little more detail. Move closer and retake.',
        );
      }
      if ((metrics.brightness < 18 && metrics.darkPixelRatio > 0.92) ||
          (metrics.brightness > 245 && metrics.brightPixelRatio > 0.95)) {
        issues.add(
          'Your face is not visible enough. Try a light nearby without direct glare.',
        );
      }
      if (metrics.sharpness < 0.8) {
        issues.add(
          'The photo is very blurry. Hold the phone steady and retake.',
        );
      }
    }

    if (faceCount == 0) {
      issues.add('No face was found. Look directly at the camera and retake.');
    } else if (faceCount > 1) {
      issues.add(
        'More than one face was found. Only the driver may be visible.',
      );
    } else if (faceMetrics == null) {
      issues.add(
        'The face position could not be checked. Please retake the photo.',
      );
    } else {
      if (faceMetrics.coverage < 0.04) {
        issues.add('Your face is too far away. Move closer to the camera.');
      } else if (faceMetrics.coverage > 0.78) {
        issues.add(
          'Your face is too close. Move the phone slightly farther away.',
        );
      }

      if (faceMetrics.headYaw.abs() > 35 ||
          faceMetrics.headPitch.abs() > 35 ||
          faceMetrics.headRoll.abs() > 30) {
        issues.add('Keep your head straight and look directly at the camera.');
      }

      final double? leftEye = faceMetrics.leftEyeOpenProbability;
      final double? rightEye = faceMetrics.rightEyeOpenProbability;
      if (leftEye != null &&
          rightEye != null &&
          leftEye < 0.12 &&
          rightEye < 0.12) {
        issues.add(
          'Keep both eyes open and remove anything covering your face.',
        );
      }
    }

    final List<String> uniqueIssues = issues.toSet().toList(growable: false);
    return DriverPhotoCheckResult(
      accepted: uniqueIssues.isEmpty,
      issues: List<String>.unmodifiable(uniqueIssues),
      faceCount: faceCount,
      faceMetrics: faceMetrics,
      imageMetrics: imageQuality.metrics,
    );
  }
}

class MlKitDriverPhotoCheckAnalyzer implements DriverPhotoCheckAnalyzer {
  MlKitDriverPhotoCheckAnalyzer({
    DocumentQualityAnalyzer? imageQualityAnalyzer,
    FaceDetector? faceDetector,
  }) : _imageQualityAnalyzer =
           imageQualityAnalyzer ?? const LocalDocumentQualityAnalyzer(),
       _faceDetector =
           faceDetector ??
           FaceDetector(
             options: FaceDetectorOptions(
               performanceMode: FaceDetectorMode.accurate,
               enableClassification: true,
               enableLandmarks: true,
               minFaceSize: 0.10,
             ),
           );

  final DocumentQualityAnalyzer _imageQualityAnalyzer;
  final FaceDetector _faceDetector;

  @override
  Future<DriverPhotoCheckResult> analyze(String imagePath) async {
    try {
      final DocumentQualityResult imageQuality = await _imageQualityAnalyzer
          .analyze(imagePath);
      final List<Face> faces = await _faceDetector.processImage(
        InputImage.fromFilePath(imagePath),
      );
      final DocumentQualityMetrics? imageMetrics = imageQuality.metrics;
      DriverFaceMetrics? faceMetrics;

      if (faces.length == 1 && imageMetrics != null) {
        final Face face = faces.single;
        final double imageArea = math
            .max(1, imageMetrics.width * imageMetrics.height)
            .toDouble();
        final double faceArea = math
            .max(0, face.boundingBox.width * face.boundingBox.height)
            .toDouble();

        faceMetrics = DriverFaceMetrics(
          coverage: faceArea / imageArea,
          headPitch: face.headEulerAngleX ?? 0,
          headYaw: face.headEulerAngleY ?? 0,
          headRoll: face.headEulerAngleZ ?? 0,
          leftEyeOpenProbability: face.leftEyeOpenProbability,
          rightEyeOpenProbability: face.rightEyeOpenProbability,
        );
      }

      return DriverPhotoCheckPolicy.evaluate(
        imageQuality: imageQuality,
        faceCount: faces.length,
        faceMetrics: faceMetrics,
      );
    } on Object {
      return const DriverPhotoCheckResult(
        accepted: false,
        issues: <String>[
          'The automatic face check could not be completed. Retake the photo and try again.',
        ],
        faceCount: 0,
      );
    }
  }

  @override
  Future<void> close() => _faceDetector.close();
}

@immutable
class DriverPhotoCheckSubmission {
  const DriverPhotoCheckSubmission({
    required this.status,
    this.reviewerMessage,
  });

  final String status;
  final String? reviewerMessage;

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';

  factory DriverPhotoCheckSubmission.fromMap(Map<String, dynamic> data) {
    return DriverPhotoCheckSubmission(
      status: data['status'] as String? ?? 'pending',
      reviewerMessage: data['reviewerMessage'] as String?,
    );
  }
}

abstract class DriverPhotoCheckRepository {
  Future<DriverPhotoCheckSubmission?> loadLatest(String driverId);

  Future<DriverPhotoCheckSubmission> submit({
    required String driverId,
    required String imagePath,
  });
}

class FirebaseDriverPhotoCheckRepository implements DriverPhotoCheckRepository {
  FirebaseDriverPhotoCheckRepository({
    FirebaseStorage? storage,
    FirebaseFirestore? firestore,
  }) : _storage = storage ?? FirebaseStorage.instance,
       _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseStorage _storage;
  final FirebaseFirestore _firestore;

  @override
  Future<DriverPhotoCheckSubmission?> loadLatest(String driverId) async {
    final DocumentSnapshot<Map<String, dynamic>> snapshot = await _firestore
        .collection('driver_photo_checks')
        .doc(driverId)
        .get();
    final Map<String, dynamic>? data = snapshot.data();
    return data == null ? null : DriverPhotoCheckSubmission.fromMap(data);
  }

  @override
  Future<DriverPhotoCheckSubmission> submit({
    required String driverId,
    required String imagePath,
  }) async {
    final String captureId = DateTime.now().millisecondsSinceEpoch.toString();
    final Reference imageReference = _storage.ref(
      'drivers/$driverId/documents/photo_checks/$captureId.jpg',
    );
    final SettableMetadata metadata = SettableMetadata(
      contentType: 'image/jpeg',
      customMetadata: <String, String>{
        'driverId': driverId,
        'documentType': 'driver_photo_check',
        'cameraCapture': 'true',
        'automatedScreeningPassed': 'true',
      },
    );

    await imageReference.putFile(File(imagePath), metadata);

    try {
      await _firestore.collection('driver_photo_checks').doc(driverId).set(
        <String, dynamic>{
          'driverId': driverId,
          'storagePath': imageReference.fullPath,
          'status': 'pending',
          'automatedScreeningPassed': true,
          'submittedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } on Object {
      try {
        await imageReference.delete();
      } on Object {
        // The original database error is more useful to the caller. A stale
        // upload can be cleaned by a scheduled backend task if deletion fails.
      }
      rethrow;
    }

    return const DriverPhotoCheckSubmission(status: 'pending');
  }
}
