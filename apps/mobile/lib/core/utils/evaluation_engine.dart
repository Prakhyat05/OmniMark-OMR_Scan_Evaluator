class EvaluationResult {
  final double marksObtained;
  final double maximumMarks;
  final double percentage;
  final int correctCount;
  final int wrongCount;
  final int unattemptedCount;
  final List<AnswerItemResult> answers;

  const EvaluationResult({
    required this.marksObtained,
    required this.maximumMarks,
    required this.percentage,
    required this.correctCount,
    required this.wrongCount,
    required this.unattemptedCount,
    required this.answers,
  });
}

class AnswerItemResult {
  final int questionNumber;
  final String? detectedOption;
  final List<String> correctOptions;
  final bool? isCorrect;
  final bool isMultiple;
  final bool isUncertain;
  final double confidence;
  final double marksAwarded;

  const AnswerItemResult({
    required this.questionNumber,
    required this.detectedOption,
    required this.correctOptions,
    required this.isCorrect,
    required this.isMultiple,
    required this.isUncertain,
    required this.confidence,
    required this.marksAwarded,
  });
}

class EvaluationEngine {
  /// Evaluates detected answers against an answer key configuration
  static EvaluationResult evaluate({
    required Map<int, List<String>> answerKey,
    required Map<int, Map<String, dynamic>> detectedAnswers,
    double defaultCorrectMarks = 4.0,
    double defaultWrongMarks = -1.0,
    Set<int>? droppedQuestions,
    Set<int>? bonusQuestions,
  }) {
    double totalMarks = 0.0;
    double maxMarks = 0.0;
    int correct = 0;
    int wrong = 0;
    int unattempted = 0;
    List<AnswerItemResult> itemResults = [];

    final totalQuestions = answerKey.keys.length;

    for (int q = 1; q <= totalQuestions; q++) {
      final correctOpts = answerKey[q] ?? [];
      final det = detectedAnswers[q];
      final detectedOpt = det?['detected_option'] as String?;
      final isMultiple = det?['is_multiple'] as bool? ?? false;
      final isUncertain = det?['is_uncertain'] as bool? ?? false;
      final confidence = (det?['confidence'] as num?)?.toDouble() ?? 1.0;

      final isDropped = droppedQuestions?.contains(q) ?? false;
      final isBonus = bonusQuestions?.contains(q) ?? false;

      double questionMaxMarks = defaultCorrectMarks;
      double marks = 0.0;
      bool? isCorr;

      if (isDropped) {
        marks = 0.0;
        isCorr = null;
      } else if (isBonus) {
        marks = defaultCorrectMarks;
        isCorr = true;
        correct++;
      } else if (detectedOpt == null || detectedOpt.isEmpty) {
        marks = 0.0;
        isCorr = null;
        unattempted++;
      } else if (correctOpts.contains(detectedOpt) && !isMultiple) {
        marks = defaultCorrectMarks;
        isCorr = true;
        correct++;
      } else {
        marks = defaultWrongMarks;
        isCorr = false;
        wrong++;
      }

      totalMarks += marks;
      maxMarks += questionMaxMarks;

      itemResults.add(AnswerItemResult(
        questionNumber: q,
        detectedOption: detectedOpt,
        correctOptions: correctOpts,
        isCorrect: isCorr,
        isMultiple: isMultiple,
        isUncertain: isUncertain,
        confidence: confidence,
        marksAwarded: marks,
      ));
    }

    final percentage =
        maxMarks > 0 ? ((totalMarks / maxMarks) * 100).clamp(0.0, 100.0) : 0.0;

    return EvaluationResult(
      marksObtained: totalMarks,
      maximumMarks: maxMarks,
      percentage: double.parse(percentage.toStringAsFixed(2)),
      correctCount: correct,
      wrongCount: wrong,
      unattemptedCount: unattempted,
      answers: itemResults,
    );
  }
}
