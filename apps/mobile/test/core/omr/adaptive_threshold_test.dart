import 'package:flutter_test/flutter_test.dart';
import 'package:omr_mobile_app/core/omr/adaptive_threshold.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AdaptiveOMRThresholdEngine engine;

  setUp(() {
    engine = const AdaptiveOMRThresholdEngine();
  });

  group('AdaptiveOMRThresholdEngine Tests', () {
    test(
        'computeGlobalThreshold detects bimodal split between dark pen ink and white paper',
        () {
      // 10 filled marks (intensities 30 to 60) and 90 blank bubbles (intensities 190 to 240)
      final List<double> values = [];
      for (int i = 0; i < 10; i++) {
        values.add(30.0 + i * 3);
      }
      for (int i = 0; i < 90; i++) {
        values.add(190.0 + (i % 30));
      }

      final threshold = engine.computeGlobalThreshold(values);
      expect(threshold, greaterThan(60.0));
      expect(threshold, lessThan(190.0));
    });

    test(
        'computeLocalThreshold suppresses threshold on all-white unattempted row',
        () {
      const globalThr = 125.0;
      final row = [215.0, 218.0, 214.0, 216.0];

      final localThr = engine.computeLocalThreshold(row, globalThr);
      // Suppressed below minimum so none of the 4 bubbles trigger
      expect(localThr, lessThan(214.0));
    });

    test(
        'computeLocalThreshold sets optimal threshold when single bubble is marked',
        () {
      const globalThr = 125.0;
      final row = [42.0, 218.0, 214.0, 216.0];

      final localThr = engine.computeLocalThreshold(row, globalThr);
      expect(localThr, greaterThan(42.0));
      expect(localThr, lessThan(214.0));
    });

    test('scoreRow correctly classifies single confident mark', () {
      final scores = [
        {'option': '1', 'score': 210.0},
        {'option': '2', 'score': 38.0},
        {'option': '3', 'score': 215.0},
        {'option': '4', 'score': 208.0},
      ];

      final decision = engine.scoreRow(
        bubbleScores: scores,
        localThreshold: 125.0,
        globalThreshold: 125.0,
      );

      expect(decision.detectedOption, equals('2'));
      expect(decision.confidence, greaterThan(0.80));
      expect(decision.isMultiple, isFalse);
      expect(decision.needsReview, isFalse);
    });

    test('scoreRow correctly identifies unattempted blank row', () {
      final scores = [
        {'option': '1', 'score': 210.0},
        {'option': '2', 'score': 214.0},
        {'option': '3', 'score': 215.0},
        {'option': '4', 'score': 208.0},
      ];

      final decision = engine.scoreRow(
        bubbleScores: scores,
        localThreshold: 125.0,
        globalThreshold: 125.0,
      );

      expect(decision.detectedOption, isNull);
      expect(decision.confidence, equals(1.0));
      expect(decision.isMultiple, isFalse);
      expect(decision.needsReview, isFalse);
    });

    test('scoreRow flags multiple-marked row for staff review', () {
      final scores = [
        {'option': '1', 'score': 45.0},
        {'option': '2', 'score': 210.0},
        {'option': '3', 'score': 52.0},
        {'option': '4', 'score': 215.0},
      ];

      final decision = engine.scoreRow(
        bubbleScores: scores,
        localThreshold: 125.0,
        globalThreshold: 125.0,
      );

      expect(decision.detectedOption, isNull);
      expect(decision.isMultiple, isTrue);
      expect(decision.needsReview, isTrue);
    });
  });
}
