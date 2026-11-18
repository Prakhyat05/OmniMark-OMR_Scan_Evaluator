import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:omr_mobile_app/core/omr/offline_scan_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late OfflineOMRScanEngine scanEngine;

  setUp(() {
    scanEngine = OfflineOMRScanEngine();
  });

  group('Offline OMR Scan Engine Tests with Real Samples', () {
    test('Correctly extracts 6-digit student code 224567 and generates visual overlay for Sample 1 (Vedehi)', () async {
      final file = File('assets/samples/sample_1_vedehi_224567.jpg');
      if (!await file.exists()) {
        return;
      }

      final Uint8List bytes = await file.readAsBytes();
      final result = await scanEngine.processImageBytes(
        imageBytes: bytes,
        totalQuestions: 50,
      );

      expect(result.studentCode, equals('224567'));
      expect(result.detectedAnswers.length, equals(50));
      expect(result.detectedAnswers[1], equals('3'));
      expect(result.detectedAnswers[2], equals('2'));
      expect(result.detectedAnswers[4], equals('2'));
      expect(result.detectedAnswers[5], equals('2'));
      expect(result.detectedAnswers[9], equals('1'));
      expect(result.detectedAnswers[12], equals('1'));
      expect(result.annotatedImageBytes, isNotNull);
      expect(result.annotatedImageBytes!.isNotEmpty, isTrue);
      expect(result.processingDurationMs, lessThan(3000));
    });

    test('Correctly extracts 6-digit student code 342105 and option 1 for Sample 2 (Amar Singh)', () async {
      final file = File('assets/samples/sample_2_amar_342105.jpg');
      if (!await file.exists()) {
        return;
      }

      final Uint8List bytes = await file.readAsBytes();
      final result = await scanEngine.processImageBytes(
        imageBytes: bytes,
        totalQuestions: 100,
      );

      expect(result.studentCode, equals('342105'));
      expect(result.detectedAnswers[4], equals('1'));
      expect(result.detectedAnswers[8], equals('1'));
      // Verify Q63, Q65, Q67, Q69 are not confused by intermediate fiducial squares:
      expect(result.detectedAnswers[63], equals('3'));
      expect(result.detectedAnswers[65], equals('3'));
      expect(result.detectedAnswers[67], equals('3'));
      expect(result.detectedAnswers[69], equals('3'));
    });

    test('Correctly extracts bubbled code 134768 and options for Sample 3 (Vaibhav Shrivastava)', () async {
      final file = File('assets/samples/sample_3_vaibhav_134768.jpg');
      if (!await file.exists()) {
        return;
      }

      final Uint8List bytes = await file.readAsBytes();
      final result = await scanEngine.processImageBytes(
        imageBytes: bytes,
        totalQuestions: 50,
      );

      expect(result.studentCode, equals('134768'));
      expect(result.detectedAnswers[1], equals('3'));
      expect(result.detectedAnswers[3], equals('1'));
      expect(result.detectedAnswers[5], equals('2'));
      expect(result.detectedAnswers[7], equals('3'));
    });
  });
}
