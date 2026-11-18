import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:omr_mobile_app/core/omr/universal_200q_template.dart';

/// On-Device Evaluated OMR Sheet Image Annotator.
/// Draws neat, compact dots (radius 4 px) directly onto the detected bubble centers
/// without filling or obscuring the pre-existing printed bubble numbers (1, 2, 3, 4).
class AnnotatedSheetPainter {
  const AnnotatedSheetPainter();

  /// Maps any option format ('1'..'4' or 'A'..'D') to 0-based option index (0..3).
  static int? getOptionIndex(String? opt) {
    if (opt == null || opt.isEmpty) return null;
    final clean = opt.trim().toUpperCase();
    if (clean == '1' || clean == 'A') return 0;
    if (clean == '2' || clean == 'B') return 1;
    if (clean == '3' || clean == 'C') return 2;
    if (clean == '4' || clean == 'D') return 3;
    return null;
  }

  /// Generates annotated JPEG bytes with clean, compact dots.
  static Uint8List generateAnnotatedImageBytes({
    required img.Image originalImage,
    required int totalQuestions,
    required Map<int, String?> detectedAnswers,
    required Map<int, String> answerKey,
    required Set<int> needsReviewQuestions,
    Map<int, List<int>>?
        detectedBubbleCenters, // Optional exact (cx, cy) pixel coordinates
    Map<int, List<List<int>>>?
        allOptionCenters, // Optional exact (cx, cy) for each of the 4 options
  }) {
    final annotated = img.Image.from(originalImage);
    final int w = annotated.width;
    final int h = annotated.height;

    final greenColor = img.ColorRgba8(34, 197, 94, 255); // Emerald Green
    final redColor = img.ColorRgba8(239, 68, 68, 255); // Crimson Red
    final yellowColor = img.ColorRgba8(234, 179, 8, 255); // Amber Yellow
    final whiteHalo = img.ColorRgba8(255, 255, 255, 230);

    for (int q = 1; q <= totalQuestions; q++) {
      final qCoords = Universal200QBlueprint.questionGrid[q];
      if (qCoords == null) continue;

      final detected = detectedAnswers[q];
      final correctOpt = answerKey[q];
      final isFlagged = needsReviewQuestions.contains(q);

      final detectedIdx = getOptionIndex(detected);
      final correctIdx = getOptionIndex(correctOpt);

      final int defaultCy = (qCoords.yNorm * h).round();

      // Draw student's marked bubble with a crisp, centered dot
      if (detectedIdx != null &&
          detectedIdx >= 0 &&
          detectedIdx < qCoords.optXNorm.length) {
        int cx = (qCoords.optXNorm[detectedIdx] * w).round();
        int cy = defaultCy;

        // If exact detected dark-spot center was supplied, use it
        if (detectedBubbleCenters != null &&
            detectedBubbleCenters.containsKey(q)) {
          final pt = detectedBubbleCenters[q]!;
          cx = pt[0];
          cy = pt[1];
        } else if (allOptionCenters != null &&
            allOptionCenters.containsKey(q) &&
            detectedIdx < allOptionCenters[q]!.length) {
          final pt = allOptionCenters[q]![detectedIdx];
          cx = pt[0];
          cy = pt[1];
        }

        final bool isCorrect = correctIdx != null && detectedIdx == correctIdx;
        final markColor =
            isFlagged ? yellowColor : (isCorrect ? greenColor : redColor);

        // Draw clean centered dot with white halo
        _drawRing(annotated, cx, cy, 5, whiteHalo);
        _drawFilledDot(annotated, cx, cy, 4, markColor);
      }

      // If student was wrong or unattempted, indicate the correct answer key with a neat green ring
      if (correctIdx != null &&
          detectedIdx != correctIdx &&
          correctIdx >= 0 &&
          correctIdx < qCoords.optXNorm.length) {
        int keyCx = (qCoords.optXNorm[correctIdx] * w).round();
        int keyCy = defaultCy;

        if (allOptionCenters != null &&
            allOptionCenters.containsKey(q) &&
            correctIdx < allOptionCenters[q]!.length) {
          final pt = allOptionCenters[q]![correctIdx];
          keyCx = pt[0];
          keyCy = pt[1];
        }

        _drawRing(annotated, keyCx, keyCy, 5, greenColor);
      }
    }

    return Uint8List.fromList(img.encodeJpg(annotated, quality: 85));
  }

  /// Draws a clean solid filled dot.
  static void _drawFilledDot(
      img.Image image, int cx, int cy, int radius, img.Color color) {
    for (int dy = -radius; dy <= radius; dy++) {
      for (int dx = -radius; dx <= radius; dx++) {
        if (dx * dx + dy * dy <= radius * radius) {
          final int px = cx + dx;
          final int py = cy + dy;
          if (px >= 0 && px < image.width && py >= 0 && py < image.height) {
            image.setPixel(px, py, color);
          }
        }
      }
    }
  }

  /// Draws a clean 1-pixel perimeter ring.
  static void _drawRing(
      img.Image image, int cx, int cy, int radius, img.Color color) {
    final int rInnerSq = (radius - 1) * (radius - 1);
    final int rOuterSq = radius * radius;
    for (int dy = -radius; dy <= radius; dy++) {
      for (int dx = -radius; dx <= radius; dx++) {
        final int distSq = dx * dx + dy * dy;
        if (distSq >= rInnerSq && distSq <= rOuterSq) {
          final int px = cx + dx;
          final int py = cy + dy;
          if (px >= 0 && px < image.width && py >= 0 && py < image.height) {
            image.setPixel(px, py, color);
          }
        }
      }
    }
  }
}
