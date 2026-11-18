import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ReportPdfGenerator {
  /// Generates a high-resolution A4 official PDF matching the exact report card layout
  static Future<Uint8List> generateReportCardPdf({
    String instituteName = 'APEX INTERNATIONAL ACADEMY',
    String studentName = 'Aarav Sharma',
    String rollNumber = '101',
    String studentCode = 'STU1001',
    String className = 'Grade 10 - Section A',
    String assessmentTitle = 'Mathematics Assessment 04',
    String examDate = '21 August 2026',
    String totalScore = '176 / 200',
    String percentage = '88.0%',
    String classRank = '#03 / 50',
    String percentile = '94.2%',
    int totalQuestions = 50,
    int correctCount = 44,
    int wrongCount = 4,
    int unattemptedCount = 2,
    double netMarks = 176.0,
    String teacherRemark =
        'Excellent analytical performance in algebra and calculus sections. Needs slight attention on trigonometry formulas.',
    String verificationCode = 'OMR-2026-88F4',
  }) async {
    final pdf = pw.Document();

    final primaryColor = PdfColor.fromHex('#006E1C');
    final softMintColor = PdfColor.fromHex('#E8F5E9');
    final secondaryColor = PdfColor.fromHex('#2A6B2C');
    final textDarkColor = PdfColor.fromHex('#1B1C1C');
    final textMutedColor = PdfColor.fromHex('#556158');
    final borderColor = PdfColor.fromHex('#CBD5E1');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(24),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: pw.BorderRadius.circular(12),
              border: pw.Border.all(color: borderColor, width: 1.5),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Container(
                        width: 44,
                        height: 44,
                        decoration: pw.BoxDecoration(
                          color: primaryColor,
                          borderRadius: pw.BorderRadius.circular(10),
                        ),
                        child: pw.Center(
                          child: pw.Text(
                            'OMR',
                            style: pw.TextStyle(
                                color: PdfColors.white,
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 13),
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        instituteName,
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 16,
                            color: primaryColor),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Official Assessment & Performance Report Card',
                        style:
                            pw.TextStyle(color: textMutedColor, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 12),
                pw.Divider(color: borderColor, thickness: 1),
                pw.SizedBox(height: 12),

                // Student & Exam Metadata Grid
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('STUDENT NAME',
                            style: pw.TextStyle(
                                fontSize: 9,
                                color: textMutedColor,
                                fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 2),
                        pw.Text(studentName,
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 13,
                                color: textDarkColor)),
                        pw.SizedBox(height: 8),
                        pw.Text('ROLL NUMBER / ID',
                            style: pw.TextStyle(
                                fontSize: 9,
                                color: textMutedColor,
                                fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 2),
                        pw.Text('$rollNumber ($studentCode) • $className',
                            style: pw.TextStyle(
                                fontSize: 11, color: textDarkColor)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('ASSESSMENT',
                            style: pw.TextStyle(
                                fontSize: 9,
                                color: textMutedColor,
                                fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 2),
                        pw.Text(assessmentTitle,
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 13,
                                color: textDarkColor)),
                        pw.SizedBox(height: 8),
                        pw.Text('DATE OF EXAMINATION',
                            style: pw.TextStyle(
                                fontSize: 9,
                                color: textMutedColor,
                                fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 2),
                        pw.Text(examDate,
                            style: pw.TextStyle(
                                fontSize: 11, color: textDarkColor)),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 18),

                // Score Banner Box
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                      vertical: 14, horizontal: 16),
                  decoration: pw.BoxDecoration(
                    color: softMintColor,
                    borderRadius: pw.BorderRadius.circular(10),
                    border: pw.Border.all(color: primaryColor, width: 1),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                    children: [
                      _buildPdfStatItem(
                          'TOTAL SCORE', totalScore, primaryColor),
                      _buildPdfStatItem(
                          'PERCENTAGE', percentage, secondaryColor),
                      _buildPdfStatItem('CLASS RANK', classRank, primaryColor),
                      _buildPdfStatItem(
                          'PERCENTILE', percentile, secondaryColor),
                    ],
                  ),
                ),
                pw.SizedBox(height: 18),

                // Subject & Question Analysis Table
                pw.Text('Subject & Question Analysis',
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 12,
                        color: textDarkColor)),
                pw.SizedBox(height: 6),
                pw.Table(
                  border: pw.TableBorder.all(color: borderColor, width: 0.5),
                  children: [
                    _buildTableRow(
                        'Category / Metrics', 'Performance Breakdown',
                        isHeader: true),
                    _buildTableRow(
                        'Total Questions in Test', '$totalQuestions'),
                    _buildTableRow('Correct Answers (+4 Marks)',
                        '$correctCount (${correctCount * 4} Marks)'),
                    _buildTableRow('Incorrect Answers (-1 Mark)',
                        '$wrongCount (-${wrongCount * 1} Marks)'),
                    _buildTableRow('Unattempted Questions (0 Marks)',
                        '$unattemptedCount (0 Marks)'),
                    _buildTableRow('Net Obtained Score',
                        '${netMarks.toStringAsFixed(2)} Marks',
                        isBold: true),
                  ],
                ),
                pw.SizedBox(height: 14),

                // Teacher Remark Box
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#F8FAFC'),
                    borderRadius: pw.BorderRadius.circular(8),
                    border: pw.Border.all(color: borderColor, width: 0.5),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Teacher Evaluation Remark:',
                          style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 10,
                              color: primaryColor)),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        teacherRemark,
                        style: pw.TextStyle(
                            fontSize: 10,
                            fontStyle: pw.FontStyle.italic,
                            color: textDarkColor),
                      ),
                    ],
                  ),
                ),
                pw.Spacer(),

                // Verification Footer
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Security Code: $verificationCode',
                            style: pw.TextStyle(
                                fontSize: 9, color: textMutedColor)),
                        pw.Text(
                            'Generated by OMR Precision Grading System on $examDate',
                            style: pw.TextStyle(
                                fontSize: 8, color: textMutedColor)),
                        pw.Text(
                            'Official Digital Verification: https://omr.apexacademy.edu/verify/$verificationCode',
                            style:
                                pw.TextStyle(fontSize: 8, color: primaryColor)),
                      ],
                    ),
                    pw.BarcodeWidget(
                      barcode: pw.Barcode.qrCode(),
                      data:
                          'https://omr.apexacademy.edu/verify/$verificationCode',
                      width: 48,
                      height: 48,
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildPdfStatItem(
      String label, String value, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(label,
            style: pw.TextStyle(
                fontSize: 8, fontWeight: pw.FontWeight.bold, color: color)),
        pw.SizedBox(height: 3),
        pw.Text(value,
            style: pw.TextStyle(
                fontSize: 13, fontWeight: pw.FontWeight.bold, color: color)),
      ],
    );
  }

  static pw.TableRow _buildTableRow(String col1, String col2,
      {bool isHeader = false, bool isBold = false}) {
    return pw.TableRow(
      decoration: pw.BoxDecoration(
          color: isHeader ? PdfColor.fromHex('#F1F5F9') : PdfColors.white),
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: pw.Text(
            col1,
            style: pw.TextStyle(
                fontSize: 9,
                fontWeight: isHeader || isBold
                    ? pw.FontWeight.bold
                    : pw.FontWeight.normal),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: pw.Text(
            col2,
            style: pw.TextStyle(
                fontSize: 9,
                fontWeight: isHeader || isBold
                    ? pw.FontWeight.bold
                    : pw.FontWeight.normal),
          ),
        ),
      ],
    );
  }

  /// Saves the PDF to application / external storage downloads and returns the saved file
  static Future<File> savePdfFile(Uint8List bytes, String fileName) async {
    final outputDir = await getApplicationDocumentsDirectory();
    final file = File('${outputDir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  /// Triggers direct Android / iOS system print / Save-to-PDF spooler
  static Future<void> printOrSavePdf(
      {required Uint8List bytes, required String fileName}) async {
    await Printing.layoutPdf(
      name: fileName,
      onLayout: (PdfPageFormat format) async => bytes,
    );
  }

  /// Triggers native sharing of the PDF document
  static Future<void> sharePdf(
      {required Uint8List bytes,
      required String fileName,
      String? subject}) async {
    await Printing.sharePdf(
      bytes: bytes,
      filename: fileName,
    );
  }
}
