import 'package:flutter_test/flutter_test.dart';
import 'package:omr_mobile_app/core/omr/dynamic_question_slicer.dart';
import 'package:omr_mobile_app/core/omr/offline_evaluator.dart';
import 'package:omr_mobile_app/core/omr/universal_200q_template.dart';

void main() {
  group('Universal 200Q Master Blueprint Tests', () {
    test('Master Blueprint has exact 200 questions', () {
      expect(universal200qMasterBlueprint.maxQuestions, equals(200));
      expect(universal200qMasterBlueprint.allQuestions.length, equals(200));
    });

    test('6-Digit Code Grid has 6 columns with digits 0..9', () {
      expect(universal200qMasterBlueprint.codeGrid.length, equals(6));
      for (final col in universal200qMasterBlueprint.codeGrid) {
        expect(col.digits.length, equals(10));
        expect(col.digits.first.label, equals('0'));
        expect(col.digits.last.label, equals('9'));
      }
    });

    test('Every question has 4 options (1, 2, 3, 4)', () {
      for (int q = 1; q <= 200; q++) {
        final qDef = universal200qMasterBlueprint.allQuestions[q];
        expect(qDef, isNotNull);
        expect(qDef!.options.length, equals(4));
        expect(qDef.options[0].label, equals('1'));
        expect(qDef.options[1].label, equals('2'));
        expect(qDef.options[2].label, equals('3'));
        expect(qDef.options[3].label, equals('4'));
      }
    });
  });

  group('Dynamic Question Slicer Tests', () {
    final slicer = DynamicQuestionSlicer();

    test('Slices exactly 50 questions for a 50-question exam', () {
      final active = slicer.getActiveQuestions(50);
      expect(active.length, equals(50));
      expect(active.first.questionNumber, equals(1));
      expect(active.last.questionNumber, equals(50));
    });

    test('Slices exactly 75 questions for a 75-question exam', () {
      final active = slicer.getActiveQuestions(75);
      expect(active.length, equals(75));
      expect(active.last.questionNumber, equals(75));
    });

    test('Slices exactly 100 questions for a 100-question exam', () {
      final active = slicer.getActiveQuestions(100);
      expect(active.length, equals(100));
      expect(active.last.questionNumber, equals(100));
    });
  });

  group('Offline Evaluator Scoring Tests', () {
    const evaluator = OfflineExamEvaluator(
      scoringRule: ScoringRule(
          correctMarks: 4.0, negativeMarks: 1.0, unattemptedMarks: 0.0),
    );

    test('Calculates perfect score for 50/50 correct answers', () {
      final answerKey = {for (var i = 1; i <= 50; i++) i: 'B'};
      final detected = {for (var i = 1; i <= 50; i++) i: 'B'};

      final result = evaluator.evaluate(
        totalQuestions: 50,
        detectedAnswers: detected,
        answerKey: answerKey,
      );

      expect(result.totalQuestions, equals(50));
      expect(result.correctCount, equals(50));
      expect(result.wrongCount, equals(0));
      expect(result.unattemptedCount, equals(0));
      expect(result.totalScore, equals(200.0));
      expect(result.percentage, equals(100.0));
    });

    test('Applies negative marking correctly for wrong answers', () {
      final answerKey = {1: 'A', 2: 'B', 3: 'C', 4: 'D'};
      // Q1 correct (+4), Q2 wrong (-1), Q3 unattempted (0), Q4 wrong (-1)
      final detected = {1: 'A', 2: 'C', 3: null, 4: 'A'};

      final result = evaluator.evaluate(
        totalQuestions: 4,
        detectedAnswers: detected,
        answerKey: answerKey,
      );

      expect(result.correctCount, equals(1));
      expect(result.wrongCount, equals(2));
      expect(result.unattemptedCount, equals(1));
      expect(result.totalScore, equals(2.0)); // 4 - 1 - 0 - 1 = 2
      expect(result.percentage, equals(12.5)); // 2 / 16 * 100 = 12.5%
    });
  });
}
