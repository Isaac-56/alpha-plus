import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';

@immutable
class DocumentQualityMetrics {
  const DocumentQualityMetrics({
    required this.fileBytes,
    required this.width,
    required this.height,
    required this.brightness,
    required this.contrast,
    required this.sharpness,
    required this.darkPixelRatio,
    required this.brightPixelRatio,
  });

  final int fileBytes;
  final int width;
  final int height;
  final double brightness;
  final double contrast;
  final double sharpness;
  final double darkPixelRatio;
  final double brightPixelRatio;
}

@immutable
class DocumentQualityResult {
  const DocumentQualityResult({
    required this.accepted,
    required this.issues,
    this.metrics,
  });

  final bool accepted;
  final List<String> issues;
  final DocumentQualityMetrics? metrics;
}

abstract class DocumentQualityAnalyzer {
  Future<DocumentQualityResult> analyze(String imagePath);
}

class DocumentQualityPolicy {
  const DocumentQualityPolicy._();

  static const int _minimumFileBytes = 45 * 1024;
  static const int _maximumFileBytes = 12 * 1024 * 1024;
  static const int _minimumShortSide = 540;
  static const int _minimumLongSide = 800;

  static DocumentQualityResult evaluate(DocumentQualityMetrics metrics) {
    final List<String> issues = <String>[];
    final int shortSide = math.min(metrics.width, metrics.height);
    final int longSide = math.max(metrics.width, metrics.height);

    if (metrics.fileBytes < _minimumFileBytes) {
      issues.add(
        'The photo contains too little detail. Move closer and retake it.',
      );
    } else if (metrics.fileBytes > _maximumFileBytes) {
      issues.add('The photo is too large. Retake it using the in-app camera.');
    }

    if (shortSide < _minimumShortSide || longSide < _minimumLongSide) {
      issues.add(
        'The photo resolution is too low. Keep the licence close to the camera.',
      );
    }

    if (metrics.brightness < 42 || metrics.darkPixelRatio > 0.58) {
      issues.add('The photo is too dark. Move to a brighter place.');
    } else if (metrics.brightness > 220 || metrics.brightPixelRatio > 0.62) {
      issues.add('The photo is too bright. Avoid flash glare and direct light.');
    }

    if (metrics.contrast < 17) {
      issues.add(
        'The licence text is difficult to distinguish from the background.',
      );
    }

    if (metrics.sharpness < 4.2) {
      issues.add('The photo looks blurry. Hold the phone steady and retake it.');
    }

    return DocumentQualityResult(
      accepted: issues.isEmpty,
      issues: List<String>.unmodifiable(issues),
      metrics: metrics,
    );
  }
}

class LocalDocumentQualityAnalyzer implements DocumentQualityAnalyzer {
  const LocalDocumentQualityAnalyzer();

  static const int _analysisWidth = 480;

  @override
  Future<DocumentQualityResult> analyze(String imagePath) async {
    try {
      final Uint8List bytes = await File(imagePath).readAsBytes();
      if (bytes.isEmpty) {
        return const DocumentQualityResult(
          accepted: false,
          issues: <String>['The selected photo is empty. Please retake it.'],
        );
      }

      final ui.Codec originalCodec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo originalFrame = await originalCodec.getNextFrame();
      final int originalWidth = originalFrame.image.width;
      final int originalHeight = originalFrame.image.height;
      originalFrame.image.dispose();
      originalCodec.dispose();

      final ui.Codec analysisCodec = originalWidth > _analysisWidth
          ? await ui.instantiateImageCodec(bytes, targetWidth: _analysisWidth)
          : await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo analysisFrame = await analysisCodec.getNextFrame();
      final ui.Image analysisImage = analysisFrame.image;
      final ByteData? rgba = await analysisImage.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );

      if (rgba == null) {
        analysisImage.dispose();
        analysisCodec.dispose();
        return const DocumentQualityResult(
          accepted: false,
          issues: <String>[
            'The photo format could not be checked. Please take a new photo.',
          ],
        );
      }

      final DocumentQualityMetrics metrics = _measurePixels(
        rgba: rgba,
        width: analysisImage.width,
        height: analysisImage.height,
        originalWidth: originalWidth,
        originalHeight: originalHeight,
        fileBytes: bytes.length,
      );
      analysisImage.dispose();
      analysisCodec.dispose();

      return DocumentQualityPolicy.evaluate(metrics);
    } on Object {
      return const DocumentQualityResult(
        accepted: false,
        issues: <String>[
          'This photo could not be checked. Please choose or take another one.',
        ],
      );
    }
  }

  DocumentQualityMetrics _measurePixels({
    required ByteData rgba,
    required int width,
    required int height,
    required int originalWidth,
    required int originalHeight,
    required int fileBytes,
  }) {
    final Float32List previousRow = Float32List(width);
    int sampleCount = 0;
    int darkPixels = 0;
    int brightPixels = 0;
    int gradientCount = 0;
    double mean = 0;
    double squaredDifferenceTotal = 0;
    double gradientTotal = 0;

    for (int y = 0; y < height; y++) {
      double leftGray = 0;
      for (int x = 0; x < width; x++) {
        final int byteIndex = (y * width + x) * 4;
        final int red = rgba.getUint8(byteIndex);
        final int green = rgba.getUint8(byteIndex + 1);
        final int blue = rgba.getUint8(byteIndex + 2);
        final double gray = 0.299 * red + 0.587 * green + 0.114 * blue;

        sampleCount++;
        final double delta = gray - mean;
        mean += delta / sampleCount;
        squaredDifferenceTotal += delta * (gray - mean);

        if (gray < 35) {
          darkPixels++;
        } else if (gray > 235) {
          brightPixels++;
        }

        if (x > 0) {
          gradientTotal += (gray - leftGray).abs();
          gradientCount++;
        }
        if (y > 0) {
          gradientTotal += (gray - previousRow[x]).abs();
          gradientCount++;
        }

        leftGray = gray;
        previousRow[x] = gray;
      }
    }

    final double variance = sampleCount > 1
        ? squaredDifferenceTotal / (sampleCount - 1)
        : 0;

    return DocumentQualityMetrics(
      fileBytes: fileBytes,
      width: originalWidth,
      height: originalHeight,
      brightness: mean,
      contrast: math.sqrt(variance),
      sharpness: gradientCount == 0 ? 0 : gradientTotal / gradientCount,
      darkPixelRatio: sampleCount == 0 ? 1 : darkPixels / sampleCount,
      brightPixelRatio: sampleCount == 0 ? 1 : brightPixels / sampleCount,
    );
  }
}
