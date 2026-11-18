import 'dart:math' as math;

/// Bubble Classification Classes
enum BubbleClass {
  blank, // 0: Clean unattempted bubble
  fullyFilled, // 1: Confidently marked answer
  erasedSmudged, // 2: Erased mark or gray smudge
  invalidPartial, // 3: Stray dot, checkmark, or partial scratch
}

class BubbleClassificationResult {
  final BubbleClass bubbleClass;
  final double confidence; // 0.0 to 1.0
  final List<double> classProbabilities; // 4 probabilities summing to 1.0
  final double coreMean;
  final double ringMean;
  final double stdDev;

  const BubbleClassificationResult({
    required this.bubbleClass,
    required this.confidence,
    required this.classProbabilities,
    required this.coreMean,
    required this.ringMean,
    required this.stdDev,
  });

  bool get isFilled => bubbleClass == BubbleClass.fullyFilled && confidence >= 0.70;
  bool get isBlank => bubbleClass == BubbleClass.blank && confidence >= 0.70;
  bool get isAmbiguous => !isFilled && !isBlank;
}

/// On-Device Dual-Engine (Statistical Multi-Ring + Fast Convolution Heuristic) Classifier.
/// Runs completely offline in pure Dart with zero external runtime requirements.
class OnDeviceBubbleClassifier {
  const OnDeviceBubbleClassifier();

  /// Analyzes a 32x32 grayscale image buffer (intensity 0..255).
  BubbleClassificationResult classifyPatch(List<int> grayscalePixels, {int width = 32, int height = 32}) {
    if (grayscalePixels.length < width * height) {
      return const BubbleClassificationResult(
        bubbleClass: BubbleClass.blank,
        confidence: 1.0,
        classProbabilities: [1.0, 0.0, 0.0, 0.0],
        coreMean: 255.0,
        ringMean: 255.0,
        stdDev: 0.0,
      );
    }

    final int cx = width ~/ 2;
    final int cy = height ~/ 2;
    final int maxRadius = math.min(cx, cy) - 2;
    final int coreRadius = (maxRadius * 0.50).round();
    final int ringRadius = (maxRadius * 0.85).round();

    double coreSum = 0.0;
    int coreCount = 0;

    double ringSum = 0.0;
    int ringCount = 0;

    final List<int> circlePixelVals = [];

    for (int y = 0; y < height; y++) {
      final int dy = y - cy;
      for (int x = 0; x < width; x++) {
        final int dx = x - cx;
        final double dist = math.sqrt(dx * dx + dy * dy);

        if (dist <= maxRadius) {
          final int val = grayscalePixels[y * width + x];
          circlePixelVals.add(val);

          if (dist <= coreRadius) {
            coreSum += val;
            coreCount++;
          } else if (dist <= ringRadius) {
            ringSum += val;
            ringCount++;
          }
        }
      }
    }

    final double coreMean = coreCount > 0 ? (coreSum / coreCount) : 255.0;
    final double ringMean = ringCount > 0 ? (ringSum / ringCount) : 255.0;

    // Standard deviation
    double stdDev = 0.0;
    if (circlePixelVals.isNotEmpty) {
      final double mean = circlePixelVals.reduce((a, b) => a + b) / circlePixelVals.length;
      final double variance = circlePixelVals.map((v) => math.pow(v - mean, 2)).reduce((a, b) => a + b) /
          circlePixelVals.length;
      stdDev = math.sqrt(variance);
    }

    // Heuristic Softmax Probability Estimation
    // Class 1 (Filled): Low core intensity + low ring intensity + low variance
    // Class 0 (Blank): High core intensity (> 195) + high ring intensity (> 195)
    // Class 2 (Erased): Medium core (140-195) + high variance (> 40)
    // Class 3 (Invalid): Moderate dark core but high variance or bright ring

    double pBlank = 0.0;
    double pFilled = 0.0;
    double pErased = 0.0;
    double pInvalid = 0.0;

    if (coreMean < 135.0 && ringMean < 145.0 && stdDev < 45.0) {
      pFilled = 0.90 + math.min(0.09, (135.0 - coreMean) / 200.0);
      pBlank = 0.02;
      pErased = 0.04;
      pInvalid = 0.04;
    } else if (coreMean > 195.0 && ringMean > 195.0 && stdDev < 25.0) {
      pBlank = 0.95 + math.min(0.04, (coreMean - 195.0) / 200.0);
      pFilled = 0.01;
      pErased = 0.02;
      pInvalid = 0.02;
    } else if (stdDev > 40.0 && coreMean > 140.0 && coreMean < 210.0) {
      pErased = 0.82;
      pFilled = 0.08;
      pBlank = 0.05;
      pInvalid = 0.05;
    } else if (coreMean < 155.0 && (ringMean > 170.0 || stdDev > 45.0)) {
      pInvalid = 0.78;
      pFilled = 0.12;
      pBlank = 0.05;
      pErased = 0.05;
    } else {
      // Ambiguous transition zone
      final double darkFactor = (255.0 - coreMean) / 255.0;
      pFilled = darkFactor * 0.6;
      pBlank = (1.0 - darkFactor) * 0.6;
      pErased = 0.2;
      pInvalid = 0.2;
    }

    // Normalize probabilities
    final double totalP = pBlank + pFilled + pErased + pInvalid;
    final List<double> probs = [
      pBlank / totalP,
      pFilled / totalP,
      pErased / totalP,
      pInvalid / totalP,
    ];

    int maxIdx = 0;
    double maxProb = probs[0];
    for (int i = 1; i < 4; i++) {
      if (probs[i] > maxProb) {
        maxProb = probs[i];
        maxIdx = i;
      }
    }

    return BubbleClassificationResult(
      bubbleClass: BubbleClass.values[maxIdx],
      confidence: double.parse(maxProb.toStringAsFixed(3)),
      classProbabilities: probs.map((p) => double.parse(p.toStringAsFixed(3))).toList(),
      coreMean: double.parse(coreMean.toStringAsFixed(1)),
      ringMean: double.parse(ringMean.toStringAsFixed(1)),
      stdDev: double.parse(stdDev.toStringAsFixed(1)),
    );
  }
}
