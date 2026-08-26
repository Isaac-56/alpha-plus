import 'package:alpha_plus/features/onboarding/services/document_quality_analyzer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const DocumentQualityMetrics clearPhoto = DocumentQualityMetrics(
    fileBytes: 420000,
    width: 1600,
    height: 1000,
    brightness: 132,
    contrast: 44,
    sharpness: 11,
    darkPixelRatio: 0.08,
    brightPixelRatio: 0.06,
  );

  test('accepts a clear well-lit licence photo', () {
    final DocumentQualityResult result = DocumentQualityPolicy.evaluate(
      clearPhoto,
    );

    expect(result.accepted, isTrue);
    expect(result.issues, isEmpty);
  });

  test('rejects a dark and blurry licence photo', () {
    const DocumentQualityMetrics poorPhoto = DocumentQualityMetrics(
      fileBytes: 420000,
      width: 1600,
      height: 1000,
      brightness: 25,
      contrast: 10,
      sharpness: 2,
      darkPixelRatio: 0.72,
      brightPixelRatio: 0.01,
    );

    final DocumentQualityResult result = DocumentQualityPolicy.evaluate(
      poorPhoto,
    );

    expect(result.accepted, isFalse);
    expect(result.issues, contains(contains('too dark')));
    expect(result.issues, contains(contains('blurry')));
  });

  test('rejects a low-resolution file before upload', () {
    const DocumentQualityMetrics tinyPhoto = DocumentQualityMetrics(
      fileBytes: 12000,
      width: 320,
      height: 240,
      brightness: 130,
      contrast: 38,
      sharpness: 10,
      darkPixelRatio: 0.08,
      brightPixelRatio: 0.06,
    );

    final DocumentQualityResult result = DocumentQualityPolicy.evaluate(
      tinyPhoto,
    );

    expect(result.accepted, isFalse);
    expect(result.issues, contains(contains('too little detail')));
    expect(result.issues, contains(contains('resolution is too low')));
  });
}
