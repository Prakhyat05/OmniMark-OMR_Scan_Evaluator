import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:omr_mobile_app/core/omr/camera_quality_analyzer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CameraQualityAnalyzer analyzer;

  setUp(() {
    analyzer = const CameraQualityAnalyzer();
  });

  group('CameraQualityAnalyzer Tests', () {
    test('Accepts high-quality real scan sample 1 (Vedehi)', () async {
      final file = File('assets/samples/sample_1_vedehi_224567.jpg');
      if (!await file.exists()) return;

      final Uint8List bytes = await file.readAsBytes();
      final img.Image? decoded = img.decodeImage(bytes);
      final assessment = analyzer.analyzeImage(decoded!);

      expect(assessment.isSharp, isTrue,
          reason:
              'Real sample should be sharp (score: ${assessment.sharpnessScore})');
      expect(assessment.isLightingAdequate, isTrue,
          reason: 'Luma: ${assessment.meanLuma}');
      expect(assessment.hasExcessiveShadow, isFalse,
          reason: 'Shadow: ${assessment.quadrantLumaDelta}');
      expect(assessment.isAspectRatioValid, isTrue,
          reason: 'Aspect: ${assessment.aspectRatio}');
      expect(assessment.isAcceptable, isTrue,
          reason: 'Feedback: ${assessment.feedbackMessages}');
      expect(assessment.feedbackMessages, isEmpty);
    });

    test('Rejects artificially blurred/uniform image', () {
      // Create a solid gray image with no edges
      final blankImage = img.Image(width: 400, height: 600);
      img.fill(blankImage, color: img.ColorRgb8(200, 200, 200));

      final assessment = analyzer.analyzeImage(blankImage);

      expect(assessment.sharpnessScore, lessThan(10.0));
      expect(assessment.isSharp, isFalse);
      expect(assessment.isAcceptable, isFalse);
      expect(
          assessment.feedbackMessages.any((m) => m.contains('blurry')), isTrue);
    });

    test('Detects harsh directional shadow across quadrants', () {
      final image = img.Image(width: 400, height: 600);
      // Fill Top-Left with bright paper
      for (int y = 0; y < 300; y++) {
        for (int x = 0; x < 200; x++) {
          image.setPixel(x, y, img.ColorRgb8(230, 230, 230));
        }
      }
      // Fill Top-Right with bright paper
      for (int y = 0; y < 300; y++) {
        for (int x = 200; x < 400; x++) {
          image.setPixel(x, y, img.ColorRgb8(230, 230, 230));
        }
      }
      // Fill Bottom-Left with deep shadow (e.g. phone shadow, luma 80)
      for (int y = 300; y < 600; y++) {
        for (int x = 0; x < 200; x++) {
          image.setPixel(x, y, img.ColorRgb8(80, 80, 80));
        }
      }
      // Fill Bottom-Right with bright paper
      for (int y = 300; y < 600; y++) {
        for (int x = 200; x < 400; x++) {
          image.setPixel(x, y, img.ColorRgb8(230, 230, 230));
        }
      }

      final assessment = analyzer.analyzeImage(image);

      expect(assessment.hasExcessiveShadow, isTrue);
      expect(assessment.quadrantLumaDelta, greaterThan(60.0));
      expect(
          assessment.feedbackMessages.any((m) => m.contains('shadow')), isTrue);
    });

    test('Flags severely dark or overexposed frames', () {
      final darkImage = img.Image(width: 400, height: 600);
      img.fill(darkImage, color: img.ColorRgb8(30, 30, 30));

      final assessment = analyzer.analyzeImage(darkImage);
      expect(assessment.isLightingAdequate, isFalse);
      expect(
          assessment.feedbackMessages.any((m) => m.contains('dark')), isTrue);
    });
  });
}
