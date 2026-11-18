import 'package:flutter_test/flutter_test.dart';
import 'package:omr_mobile_app/core/utils/evaluation_engine.dart';

void main() {
  group('EvaluationEngine Tests', () {
    test('Correctly calculates 100% score when all answers match', () {
      final answerKey = {1: ['A'], 2: ['B'], 3: ['C'], 4: ['D']};
      final detected = {
        1: {'detected_option': 'A', 'confidence': 0.98},
        2: {'detected_option': 'B', 'confidence': 0.99},
        3: {'detected_option': 'C', 'confidence': 0.95},
        4: {'detected_option': 'D', 'confidence': 0.97},
      };

      final result = EvaluationEngine.evaluate(
        answerKey: answerKey,
        detectedAnswers: detected,
        defaultCorrectMarks: 4.0,
        defaultWrongMarks: -1.0,
      );

      expect(result.marksObtained, 16.0);
      expect(result.maximumMarks, 16.0);
      expect(result.percentage, 100.0);
      expect(result.correctCount, 4);
      expect(result.wrongCount, 0);
      expect(result.unattemptedCount, 0);
    });

    test('Correctly applies negative marking for wrong options', () {
      final answerKey = {1: ['A'], 2: ['B']};
      final detected = {
        1: {'detected_option': 'A', 'confidence': 0.98},
        2: {'detected_option': 'C', 'confidence': 0.95}, // Wrong
      };

      final result = EvaluationEngine.evaluate(
        answerKey: answerKey,
        detectedAnswers: detected,
        defaultCorrectMarks: 4.0,
        defaultWrongMarks: -1.0,
      );

      expect(result.marksObtained, 3.0); // 4 - 1 = 3
      expect(result.correctCount, 1);
      expect(result.wrongCount, 1);
      expect(result.unattemptedCount, 0);
    });

    test('Correctly accounts for bonus and dropped questions', () {
      final answerKey = {1: ['A'], 2: ['B'], 3: ['C']};
      final detected = {
        1: {'detected_option': 'A', 'confidence': 0.98},
        2: {'detected_option': 'D', 'confidence': 0.90}, // Dropped question
        3: {'detected_option': '', 'confidence': 0.0},   // Bonus question
      };

      final result = EvaluationEngine.evaluate(
        answerKey: answerKey,
        detectedAnswers: detected,
        defaultCorrectMarks: 4.0,
        defaultWrongMarks: -1.0,
        droppedQuestions: {2},
        bonusQuestions: {3},
      );

      // Q1: +4, Q2: 0 (dropped), Q3: +4 (bonus) -> 8
      expect(result.marksObtained, 8.0);
      expect(result.maximumMarks, 12.0);
    });
  });
}
