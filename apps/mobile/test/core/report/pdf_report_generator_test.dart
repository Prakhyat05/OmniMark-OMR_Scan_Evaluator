import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:omr_mobile_app/core/omr/offline_evaluator.dart';
import 'package:omr_mobile_app/core/report/pdf_report_generator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Offline PDF Report Generator creates valid PDF bytes', () async {
    const generator = OfflinePDFReportGenerator();
    const evaluator = OfflineExamEvaluator();

    final answerKey = {for (var i = 1; i <= 50; i++) i: 'B'};
    final detectedAnswers = {
      for (var i = 1; i <= 50; i++) i: (i % 5 == 0 ? 'A' : 'B')
    };

    final summary = evaluator.evaluate(
      totalQuestions: 50,
      detectedAnswers: detectedAnswers,
      answerKey: answerKey,
    );

    final Uint8List pdfBytes = await generator.generateReportPdf(
      instituteName: 'Apex International Academy',
      examTitle: 'Physics & Maths Assessment Test',
      studentName: 'Vedehi',
      studentCode: '224567',
      className: 'Class 12',
      evaluationSummary: summary,
    );

    expect(pdfBytes, isNotNull);
    expect(pdfBytes.length, greaterThan(1000));
    // PDF header magic bytes %PDF-
    expect(pdfBytes[0], equals(0x25)); // %
    expect(pdfBytes[1], equals(0x50)); // P
    expect(pdfBytes[2], equals(0x44)); // D
    expect(pdfBytes[3], equals(0x46)); // F
  });
}
