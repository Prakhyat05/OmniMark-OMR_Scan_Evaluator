import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:omr_mobile_app/core/omr/offline_evaluator.dart';

/// Offline PDF Report Card Generator for On-Device Generation.
class OfflinePDFReportGenerator {
  const OfflinePDFReportGenerator();

  /// Generates a PDF Report Card document as bytes.
  Future<Uint8List> generateReportPdf({
    required String instituteName,
    required String examTitle,
    required String studentName,
    required String studentCode,
    required String className,
    required ExamEvaluationSummary evaluationSummary,
    DateTime? examDate,
  }) async {
    final pdf = pw.Document();
    final dateStr = DateFormat('dd MMM yyyy').format(examDate ?? DateTime.now());

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) => [
          // 1. Header
          pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 12),
            decoration: const pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(color: PdfColors.indigo, width: 2)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      instituteName.toUpperCase(),
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.indigo900,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'STUDENT PERFORMANCE REPORT CARD',
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Date: $dateStr', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800)),
                    pw.Text('Exam: $examTitle', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),

          // 2. Student Info & Score Overview Grid
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Student Info Card
              pw.Expanded(
                flex: 3,
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _infoRow('Student Name:', studentName.isNotEmpty ? studentName : 'Student'),
                      _infoRow('Roll / Code:', studentCode),
                      _infoRow('Class / Section:', className.isNotEmpty ? className : 'General'),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(width: 12),

              // Score Card
              pw.Expanded(
                flex: 4,
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.indigo50,
                    borderRadius: pw.BorderRadius.circular(6),
                    border: pw.Border.all(color: PdfColors.indigo200),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                    children: [
                      _metricBadge('SCORE', '${evaluationSummary.totalScore}/${evaluationSummary.maxPossibleScore}', PdfColors.indigo900),
                      _metricBadge('PERCENTAGE', '${evaluationSummary.percentage}%', PdfColors.indigo800),
                      _metricBadge('CORRECT', '${evaluationSummary.correctCount}', PdfColors.green800),
                      _metricBadge('WRONG', '${evaluationSummary.wrongCount}', PdfColors.red800),
                      _metricBadge('UNATTEMPTED', '${evaluationSummary.unattemptedCount}', PdfColors.grey700),
                    ],
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 18),

          // 3. Question-Wise Detailed Answer Matrix
          pw.Text(
            'QUESTION-WISE EVALUATION BREAKDOWN',
            style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800),
          ),
          pw.SizedBox(height: 8),

          _buildQuestionMatrix(evaluationSummary.questionResults),
          pw.SizedBox(height: 16),

          // Footer
          pw.Divider(color: PdfColors.grey300),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Generated securely on-device via OMR Scan System', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
              pw.Text('Confidential Assessment Report', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
            ],
          ),
        ],
      ),
    );

    return await pdf.save();
  }

  static pw.Widget _infoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          pw.SizedBox(width: 80, child: pw.Text(label, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700))),
          pw.Text(value, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
        ],
      ),
    );
  }

  static pw.Widget _metricBadge(String label, String value, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700)),
        pw.SizedBox(height: 2),
        pw.Text(value, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: color)),
      ],
    );
  }

  static pw.Widget _buildQuestionMatrix(List<QuestionEvaluationResult> results) {
    // Organize into rows of 10 items
    const int cols = 5;
    final int rows = (results.length / cols).ceil();

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      children: [
        // Header
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: List.generate(
            cols,
            (c) => pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Text('Q#  Key  Mark  Status', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center),
            ),
          ),
        ),
        // Rows
        for (int r = 0; r < rows; r++)
          pw.TableRow(
            children: List.generate(cols, (c) {
              final int idx = r * cols + c;
              if (idx >= results.length) {
                return pw.Container();
              }
              final q = results[idx];
              PdfColor statusColor = PdfColors.grey600;
              String statusText = '-';

              if (q.isCorrect) {
                statusColor = PdfColors.green700;
                statusText = 'CORRECT';
              } else if (q.isWrong) {
                statusColor = PdfColors.red700;
                statusText = 'WRONG';
              }

              return pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 4),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Q${q.questionNumber}', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
                    pw.Text(q.correctOption ?? "-", style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey800)),
                    pw.Text(q.markedOption ?? "-", style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: statusColor)),
                    pw.Text(statusText, style: pw.TextStyle(fontSize: 6, fontWeight: pw.FontWeight.bold, color: statusColor)),
                  ],
                ),
              );
            }),
          ),
      ],
    );
  }
}
