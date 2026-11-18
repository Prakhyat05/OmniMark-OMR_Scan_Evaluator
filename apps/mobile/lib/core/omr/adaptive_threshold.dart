import 'dart:math' as math;

/// Concentric multi-ring circular decomposition result for an individual bubble.
class ConcentricAnalysis {
  final double coreMean;
  final double ringMean;
  final double marginMean;
  final double stdDev;
  final double concentricFillRatio;
  final bool isFilled;
  final bool isErased;
  final bool isInvalid;

  const ConcentricAnalysis({
    required this.coreMean,
    required this.ringMean,
    required this.marginMean,
    required this.stdDev,
    required this.concentricFillRatio,
    required this.isFilled,
    required this.isErased,
    required this.isInvalid,
  });
}

/// Evaluation decision for a 4-bubble question row.
class RowDecision {
  final String? detectedOption; // '1' | '2' | '3' | '4' | null
  final double confidence; // 0.0 .. 1.0
  final bool isMultiple;
  final bool isUncertain;
  final bool needsReview;
  final double localThreshold;
  final double gap;

  const RowDecision({
    required this.detectedOption,
    required this.confidence,
    required this.isMultiple,
    required this.isUncertain,
    required this.needsReview,
    required this.localThreshold,
    required this.gap,
  });
}

/// Adaptive Bimodal Gap Thresholding & Tri-Signal Bubble State Engine.
/// Replaces static hardcoded cutoffs with sheet-adaptive bimodal separation,
/// local row standard-deviation gating, and concentric multi-ring fill analysis.
class AdaptiveOMRThresholdEngine {
  const AdaptiveOMRThresholdEngine();

  /// OMRChecker 'First Large Gap' Algorithm:
  /// Sorts all bubble intensities across the entire sheet and finds the maximum
  /// intensity jump that cleanly separates dark ink deposits from blank paper.
  double computeGlobalThreshold(
    List<double> allBubbleValues, {
    int looseness = 1,
    double minJump = 25.0,
    double defaultThreshold = 120.0,
  }) {
    if (allBubbleValues.isEmpty) return defaultThreshold;

    final sorted = List<double>.from(allBubbleValues)..sort();
    final int ls = math.max(1, (looseness + 1) ~/ 2);
    final int l = sorted.length - ls;

    double maxJump = minJump;
    double threshold = defaultThreshold;

    for (int i = ls; i < l; i++) {
      final double jump = sorted[i + ls] - sorted[i - ls];
      if (jump > maxJump) {
        maxJump = jump;
        threshold = sorted[i - ls] + jump / 2.0;
      }
    }

    // Clamp within reasonable physical bounds
    return threshold.clamp(75.0, 165.0);
  }

  /// OMRChecker Local Question-Row Thresholding:
  /// Uses row standard deviation to check if any bubble in the row is filled.
  /// If all bubbles are blank paper (low standard deviation), suppresses false marks.
  double computeLocalThreshold(
    List<double> rowValues,
    double globalThreshold, {
    double minStdThresh = 14.0,
  }) {
    if (rowValues.isEmpty) return globalThreshold;

    final double mean = rowValues.reduce((a, b) => a + b) / rowValues.length;
    final double variance = rowValues.map((v) => math.pow(v - mean, 2)).reduce((a, b) => a + b) / rowValues.length;
    final double stdDev = math.sqrt(variance);

    final double minVal = rowValues.reduce(math.min);
    final double maxVal = rowValues.reduce(math.max);

    // All White or All Gray case (no marked bubble in this question row)
    if (stdDev < minStdThresh || (maxVal - minVal) < 24.0) {
      return math.min(globalThreshold, minVal - 10.0);
    }

    // Question row has a filled bubble: set local threshold between lowest and runner-up
    final sorted = List<double>.from(rowValues)..sort();
    final double localGap = sorted[1] - sorted[0];
    if (localGap >= 20.0) {
      return sorted[0] + localGap / 2.0;
    }

    return globalThreshold;
  }

  /// Decides question row state based on adaptive local threshold,
  /// minimum intensity, runner-up gap, and certainty thresholds.
  RowDecision scoreRow({
    required List<Map<String, dynamic>> bubbleScores,
    required double localThreshold,
    required double globalThreshold,
  }) {
    // Sort ascending by score (lowest intensity = darkest = candidate marked)
    final sorted = List<Map<String, dynamic>>.from(bubbleScores)
      ..sort((a, b) => (a['score'] as double).compareTo(b['score'] as double));

    final top = sorted[0];
    final runnerUp = sorted[1];

    final double topScore = top['score'] as double;
    final double runnerUpScore = runnerUp['score'] as double;
    final double gap = runnerUpScore - topScore;

    // Check if any bubble meets mark criteria
    final List<Map<String, dynamic>> markedBubbles = [];
    for (final b in sorted) {
      final double score = b['score'] as double;
      if (score < localThreshold) {
        markedBubbles.add(b);
      }
    }

    // Unattempted / Blank Case
    // Either topScore is above the threshold, or difference between top and paper is negligible
    if (topScore >= localThreshold || markedBubbles.isEmpty) {
      return RowDecision(
        detectedOption: null,
        confidence: 1.0,
        isMultiple: false,
        isUncertain: false,
        needsReview: false,
        localThreshold: localThreshold,
        gap: gap,
      );
    }

    // Multiple-Marked Case: Two bubbles both significantly darker than threshold
    if (markedBubbles.length > 1 && gap < 18.0) {
      return RowDecision(
        detectedOption: null,
        confidence: 0.20,
        isMultiple: true,
        isUncertain: true,
        needsReview: true,
        localThreshold: localThreshold,
        gap: gap,
      );
    }

    // Single Mark Case
    final String option = top['option'] as String;

    // Calculate normalized confidence based on separation gap and margin below threshold
    final double deltaToThresh = math.max(0.0, localThreshold - topScore);
    final double confidence = ((gap / 40.0) * 0.7 + (deltaToThresh / 50.0) * 0.3).clamp(0.0, 1.0);

    final bool isUncertain = gap < 16.0 || confidence < 0.35;

    return RowDecision(
      detectedOption: option,
      confidence: double.parse(confidence.toStringAsFixed(2)),
      isMultiple: false,
      isUncertain: isUncertain,
      needsReview: isUncertain,
      localThreshold: localThreshold,
      gap: double.parse(gap.toStringAsFixed(1)),
    );
  }
}
