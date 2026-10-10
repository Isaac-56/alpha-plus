import 'package:alpha_plus/features/dashboard/data/driver_photo_check_service.dart';
import 'package:alpha_plus/features/onboarding/services/document_quality_analyzer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const DocumentQualityMetrics clearImageMetrics = DocumentQualityMetrics(
    fileBytes: 480000,
    width: 1600,
    height: 1200,
    brightness: 132,
    contrast: 42,
    sharpness: 10,
    darkPixelRatio: 0.06,
    brightPixelRatio: 0.05,
  );
  const DocumentQualityResult clearImage = DocumentQualityResult(
    accepted: true,
    issues: <String>[],
    metrics: clearImageMetrics,
  );
  const DriverFaceMetrics clearFace = DriverFaceMetrics(
    coverage: 0.18,
    headPitch: 2,
    headYaw: -3,
    headRoll: 1,
    leftEyeOpenProbability: 0.91,
    rightEyeOpenProbability: 0.94,
  );

  test('accepts one clear, front-facing driver photo', () {
    final DriverPhotoCheckResult result = DriverPhotoCheckPolicy.evaluate(
      imageQuality: clearImage,
      faceCount: 1,
      faceMetrics: clearFace,
    );

    expect(result.accepted, isTrue);
    expect(result.issues, isEmpty);
  });

  test('rejects a photo with no face', () {
    final DriverPhotoCheckResult result = DriverPhotoCheckPolicy.evaluate(
      imageQuality: clearImage,
      faceCount: 0,
    );

    expect(result.accepted, isFalse);
    expect(result.issues, contains(contains('No face was found')));
  });

  test('rejects a group photo', () {
    final DriverPhotoCheckResult result = DriverPhotoCheckPolicy.evaluate(
      imageQuality: clearImage,
      faceCount: 2,
    );

    expect(result.accepted, isFalse);
    expect(result.issues, contains(contains('More than one face')));
  });

  test('rejects poor framing and head pose', () {
    const DriverFaceMetrics poorFace = DriverFaceMetrics(
      coverage: 0.03,
      headPitch: 4,
      headYaw: 29,
      headRoll: 2,
      leftEyeOpenProbability: 0.9,
      rightEyeOpenProbability: 0.92,
    );

    final DriverPhotoCheckResult result = DriverPhotoCheckPolicy.evaluate(
      imageQuality: clearImage,
      faceCount: 1,
      faceMetrics: poorFace,
    );

    expect(result.accepted, isFalse);
    expect(result.issues, contains(contains('too far away')));
    expect(result.issues, contains(contains('head straight')));
  });
}
