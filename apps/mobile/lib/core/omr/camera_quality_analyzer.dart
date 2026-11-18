import 'dart:math' as math;
import 'package:image/image.dart' as img;

/// Comprehensive In-Capture Image Quality Assessment
class ImageQualityAssessment {
  /// Whether the image meets all minimum quality gates for accurate OMR evaluation.
  final bool isAcceptable;

  /// Discrete Laplacian variance measuring edge sharpness.
  /// Blurry images typically score < 80, sharp text/bubble sheets score > 120.
  final double sharpnessScore;
  final bool isSharp;

  /// Mean luminance (0..255) across the sampled image.
  final double meanLuma;
  final bool isLightingAdequate;

  /// Difference between brightest and darkest quadrant mean luminance.
  /// High values (> 45) indicate harsh directional shadows (e.g. phone or hand shadow).
  final double quadrantLumaDelta;
  final bool hasExcessiveShadow;

  /// Aspect ratio (height / width in portrait orientation).
  final double aspectRatio;
  final bool isAspectRatioValid;

  /// User-friendly guidance messages for display in the viewfinder UI.
  final List<String> feedbackMessages;

  const ImageQualityAssessment({
    required this.isAcceptable,
    required this.sharpnessScore,
    required this.isSharp,
    required this.meanLuma,
    required this.isLightingAdequate,
    required this.quadrantLumaDelta,
    required this.hasExcessiveShadow,
    required this.aspectRatio,
    required this.isAspectRatioValid,
    required this.feedbackMessages,
  });

  /// Primary human-readable status line for quick UI banner/snackbar display.
  String get primaryStatus {
    if (feedbackMessages.isEmpty) return 'Optimal Quality';
    return feedbackMessages.first;
  }
}

/// Real-Time Hardware & In-Capture Quality Analyzer for OMR scanning.
/// Evaluates frames before passing them to the grading pipeline to guarantee
/// that blurred, severely tilted, or shadowed captures are intercepted.
class CameraQualityAnalyzer {
  final double minSharpnessThreshold;
  final double minMeanLuma;
  final double maxMeanLuma;
  final double maxQuadrantLumaDelta;
  final double minAspectRatio;
  final double maxAspectRatio;

  const CameraQualityAnalyzer({
    this.minSharpnessThreshold = 95.0,
    this.minMeanLuma = 65.0,
    this.maxMeanLuma = 248.0,
    this.maxQuadrantLumaDelta = 45.0,
    this.minAspectRatio = 1.15,
    this.maxAspectRatio = 1.65,
  });

  /// Analyzes an [img.Image] with sub-15ms execution time by using an adaptive sampling grid.
  ImageQualityAssessment analyzeImage(img.Image image) {
    final int w = image.width;
    final int h = image.height;

    // Normalize to portrait orientation for aspect ratio evaluation
    final int majorDim = math.max(w, h);
    final int minorDim = math.min(w, h);
    final double aspectRatio = majorDim / (minorDim > 0 ? minorDim : 1);
    final bool isAspectValid = aspectRatio >= minAspectRatio && aspectRatio <= maxAspectRatio;

    // Use stride to maintain fast processing (< 15ms) on high-resolution camera images (e.g. 12MP/48MP)
    final int step = math.max(1, (math.min(w, h) / 400).floor());

    // 1. Quadrant Luminance Accumulators
    final int midX = w ~/ 2;
    final int midY = h ~/ 2;

    double q1Sum = 0, q2Sum = 0, q3Sum = 0, q4Sum = 0;
    int q1Count = 0, q2Count = 0, q3Count = 0, q4Count = 0;

    double totalLumaSum = 0;
    int totalSampleCount = 0;

    // 2. Laplacian Accumulators for Sharpness
    double laplacianSum = 0.0;
    double laplacianSqSum = 0.0;
    int laplacianCount = 0;

    // Fast inner sampling loop (skipping outer borders where convolution kernels overlap)
    final int startY = step;
    final int endY = h - step - 1;
    final int startX = step;
    final int endX = w - step - 1;

    for (int y = startY; y < endY; y += step) {
      for (int x = startX; x < endX; x += step) {
        final p = image.getPixel(x, y);
        final double luma = p.r * 0.299 + p.g * 0.587 + p.b * 0.114;

        totalLumaSum += luma;
        totalSampleCount++;

        // Accumulate quadrant luma
        if (x < midX) {
          if (y < midY) {
            q1Sum += luma;
            q1Count++;
          } else {
            q3Sum += luma;
            q3Count++;
          }
        } else {
          if (y < midY) {
            q2Sum += luma;
            q2Count++;
          } else {
            q4Sum += luma;
            q4Count++;
          }
        }

        // Discrete Laplacian computation:
        // L(x, y) = I(x+s, y) + I(x-s, y) + I(x, y+s) + I(x, y-s) - 4 * I(x, y)
        final pRight = image.getPixel(x + step, y);
        final pLeft = image.getPixel(x - step, y);
        final pDown = image.getPixel(x, y + step);
        final pUp = image.getPixel(x, y - step);

        final double lumaR = pRight.r * 0.299 + pRight.g * 0.587 + pRight.b * 0.114;
        final double lumaL = pLeft.r * 0.299 + pLeft.g * 0.587 + pLeft.b * 0.114;
        final double lumaD = pDown.r * 0.299 + pDown.g * 0.587 + pDown.b * 0.114;
        final double lumaU = pUp.r * 0.299 + pUp.g * 0.587 + pUp.b * 0.114;

        final double lap = lumaR + lumaL + lumaD + lumaU - (4.0 * luma);

        laplacianSum += lap;
        laplacianSqSum += lap * lap;
        laplacianCount++;
      }
    }

    final double meanLuma = totalSampleCount > 0 ? (totalLumaSum / totalSampleCount) : 0.0;
    final bool isLightingAdequate = meanLuma >= minMeanLuma && meanLuma <= maxMeanLuma;

    // Quadrant mean lumas
    final double q1Mean = q1Count > 0 ? (q1Sum / q1Count) : meanLuma;
    final double q2Mean = q2Count > 0 ? (q2Sum / q2Count) : meanLuma;
    final double q3Mean = q3Count > 0 ? (q3Sum / q3Count) : meanLuma;
    final double q4Mean = q4Count > 0 ? (q4Sum / q4Count) : meanLuma;

    final double maxQ = math.max(math.max(q1Mean, q2Mean), math.max(q3Mean, q4Mean));
    final double minQ = math.min(math.min(q1Mean, q2Mean), math.min(q3Mean, q4Mean));
    final double quadrantDelta = maxQ - minQ;
    final bool hasExcessiveShadow = quadrantDelta > maxQuadrantLumaDelta;

    // Variance of Laplacian: Var(L) = E[L^2] - (E[L])^2
    double sharpnessScore = 0.0;
    if (laplacianCount > 0) {
      final double meanLap = laplacianSum / laplacianCount;
      final double meanSqLap = laplacianSqSum / laplacianCount;
      sharpnessScore = math.max(0.0, meanSqLap - (meanLap * meanLap));
    }
    final bool isSharp = sharpnessScore >= minSharpnessThreshold;

    // Synthesize human-actionable feedback messages
    final List<String> feedback = [];

    if (!isSharp) {
      feedback.add('Image is blurry. Hold camera steady or tap to focus.');
    }
    if (meanLuma < minMeanLuma) {
      feedback.add('Lighting is too dark. Turn on camera flash or increase lighting.');
    } else if (meanLuma > maxMeanLuma) {
      feedback.add('Image is overexposed/washed out. Avoid direct glare.');
    }
    if (hasExcessiveShadow) {
      feedback.add('Uneven shadow detected across sheet. Adjust phone angle.');
    }
    if (!isAspectValid) {
      feedback.add('Camera angle is too steep. Align sheet flat in frame.');
    }

    final bool isAcceptable = isSharp && isLightingAdequate && !hasExcessiveShadow && isAspectValid;

    return ImageQualityAssessment(
      isAcceptable: isAcceptable,
      sharpnessScore: double.parse(sharpnessScore.toStringAsFixed(2)),
      isSharp: isSharp,
      meanLuma: double.parse(meanLuma.toStringAsFixed(1)),
      isLightingAdequate: isLightingAdequate,
      quadrantLumaDelta: double.parse(quadrantDelta.toStringAsFixed(1)),
      hasExcessiveShadow: hasExcessiveShadow,
      aspectRatio: double.parse(aspectRatio.toStringAsFixed(2)),
      isAspectRatioValid: isAspectValid,
      feedbackMessages: feedback,
    );
  }
}
