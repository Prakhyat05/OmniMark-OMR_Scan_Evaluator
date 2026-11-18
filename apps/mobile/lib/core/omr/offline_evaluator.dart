/// Offline Evaluation & Scoring Engine for On-Device Processing.
class ScoringRule {
  final double correctMarks;
  final double negativeMarks; // Positive number representing penalty (e.g. 1.0 or 0.25)
  final double unattemptedMarks;

  const ScoringRule({
    this.correctMarks = 4.0,
    this.negativeMarks = 1.0,
    this.unattemptedMarks = 0.0,
  });

  Map<String, dynamic> toJson() => {
        'correct_marks': correctMarks,
        'negative_marks': negativeMarks,
        'unattempted_marks': unattemptedMarks,
      };

  factory ScoringRule.fromJson(Map<String, dynamic> json) {
    return ScoringRule(
      correctMarks: (json['correct_marks'] as num?)?.toDouble() ?? 4.0,
      negativeMarks: (json['negative_marks'] as num?)?.toDouble() ?? 1.0,
      unattemptedMarks: (json['unattempted_marks'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class QuestionEvaluationResult {
  final int questionNumber;
  final String? markedOption; // "A", "B", "C", "D" or null
  final String? correctOption; // "A", "B", "C", "D"
  final bool isCorrect;
  final bool isWrong;
  final bool isUnattempted;
  final bool isMultipleMarked;
  final double marksAwarded;
  final double confidence; // 0.0 to 1.0

  const QuestionEvaluationResult({
    required this.questionNumber,
    required this.markedOption,
    required this.correctOption,
    required this.isCorrect,
    required this.isWrong,
    required this.isUnattempted,
    required this.isMultipleMarked,
    required this.marksAwarded,
    required this.confidence,
  });
}

class ExamEvaluationSummary {
  final int totalQuestions;
  final int totalAttempted;
  final int correctCount;
  final int wrongCount;
  final int unattemptedCount;
  final int multipleMarkedCount;
  final double totalScore;
  final double maxPossibleScore;
  final double percentage;
  final List<QuestionEvaluationResult> questionResults;

  const ExamEvaluationSummary({
    required this.totalQuestions,
    required this.totalAttempted,
    required this.correctCount,
    required this.wrongCount,
    required this.unattemptedCount,
    required this.multipleMarkedCount,
    required this.totalScore,
    required this.maxPossibleScore,
    required this.percentage,
    required this.questionResults,
  });
}

class OfflineExamEvaluator {
  final ScoringRule scoringRule;

  const OfflineExamEvaluator({this.scoringRule = const ScoringRule()});

  /// Evaluates detected answers against an answer key map `[QuestionNumber: CorrectOption]`.
  ExamEvaluationSummary evaluate({
    required int totalQuestions,
    required Map<int, String?> detectedAnswers,
    required Map<int, String> answerKey,
    Map<int, double>? answerConfidences,
    Set<int>? multipleMarkedQuestions,
  }) {
    int correctCount = 0;
    int wrongCount = 0;
    int unattemptedCount = 0;
    int multipleMarkedCount = 0;
    double totalScore = 0.0;

    final List<QuestionEvaluationResult> questionResults = [];

    for (int q = 1; q <= totalQuestions; q++) {
      final detected = detectedAnswers[q];
      final correct = answerKey[q]?.toUpperCase();
      final isMultiple = multipleMarkedQuestions?.contains(q) ?? false;
      final confidence = answerConfidences?[q] ?? (detected != null ? 1.0 : 0.0);

      bool isCorrect = false;
      bool isWrong = false;
      bool isUnattempted = false;
      double marks = 0.0;

      if (isMultiple) {
        multipleMarkedCount++;
        isWrong = true;
        marks = -scoringRule.negativeMarks;
      } else if (detected == null || detected.trim().isEmpty) {
        unattemptedCount++;
        isUnattempted = true;
        marks = scoringRule.unattemptedMarks;
      } else if (correct != null && detected.toUpperCase() == correct) {
        correctCount++;
        isCorrect = true;
        marks = scoringRule.correctMarks;
      } else {
        wrongCount++;
        isWrong = true;
        marks = -scoringRule.negativeMarks;
      }

      totalScore += marks;

      questionResults.add(QuestionEvaluationResult(
        questionNumber: q,
        markedOption: detected,
        correctOption: correct,
        isCorrect: isCorrect,
        isWrong: isWrong,
        isUnattempted: isUnattempted,
        isMultipleMarked: isMultiple,
        marksAwarded: marks,
        confidence: confidence,
      ));
    }

    final double maxPossibleScore = totalQuestions * scoringRule.correctMarks;
    final double percentage = maxPossibleScore > 0
        ? ((totalScore / maxPossibleScore) * 100.0).clamp(0.0, 100.0)
        : 0.0;

    return ExamEvaluationSummary(
      totalQuestions: totalQuestions,
      totalAttempted: correctCount + wrongCount,
      correctCount: correctCount,
      wrongCount: wrongCount,
      unattemptedCount: unattemptedCount,
      multipleMarkedCount: multipleMarkedCount,
      totalScore: totalScore,
      maxPossibleScore: maxPossibleScore,
      percentage: double.parse(percentage.toStringAsFixed(2)),
      questionResults: questionResults,
    );
  }
}
