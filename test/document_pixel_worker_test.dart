import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:alpha_plus/features/onboarding/services/document_quality_analyzer.dart';

void main() {
  test('pixel worker crosses isolates and preserves source dimensions and metrics', () async {
    final bytes = Uint8List.fromList(<int>[
      0, 0, 0, 255, 255, 255, 255, 255,
      255, 255, 255, 255, 0, 0, 0, 255,
    ]);
    final result = await compute(measureDocumentPixels, (
      rgba: ByteData.sublistView(bytes), width: 2, height: 2,
      originalWidth: 1200, originalHeight: 1800, fileBytes: 100000,
    ));
    expect(result.width, 1200);
    expect(result.height, 1800);
    expect(result.fileBytes, 100000);
    expect(result.brightness, closeTo(127.5, 0.01));
    expect(result.sharpness, closeTo(255, 0.01));
    expect(result.darkPixelRatio, 0.5);
    expect(result.brightPixelRatio, 0.5);
  });
}
