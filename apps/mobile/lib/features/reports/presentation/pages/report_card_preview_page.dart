import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme.dart';
import '../../../../core/utils/navigation_utils.dart';
import '../../../../core/utils/report_pdf_generator.dart';
import '../../../../core/state/app_state.dart';

class ReportCardPreviewPage extends ConsumerStatefulWidget {
  const ReportCardPreviewPage({super.key});

  @override
  ConsumerState<ReportCardPreviewPage> createState() =>
      _ReportCardPreviewPageState();
}

class _ReportCardPreviewPageState extends ConsumerState<ReportCardPreviewPage> {
  bool _isGenerating = false;

  Future<void> _downloadPdf(ScanResultModel result, ExamModel exam,
      InstituteSettingsModel settings) async {
    setState(() => _isGenerating = true);
    try {
      final pdfBytes = await ReportPdfGenerator.generateReportCardPdf(
        studentName: result.studentName,
        studentCode: result.studentCode,
        rollNumber: result.studentRoll,
        className: result.studentClass,
        assessmentTitle: exam.title,
        examDate: exam.date,
        totalScore:
            '${result.marksObtained.toStringAsFixed(1)} / ${result.maximumMarks.toInt()}',
        percentage: '${result.percentage}%',
        classRank: '#03 / ${exam.totalStudents}',
        percentile:
            '${((result.percentage * 1.05).clamp(0, 99.8)).toStringAsFixed(1)}%',
        totalQuestions: exam.questionsCount,
        correctCount: result.correctCount,
        wrongCount: result.wrongCount,
        unattemptedCount: result.unattemptedCount,
        netMarks: result.marksObtained,
      );

      final fileName =
          '${result.studentName.replaceAll(" ", "_")}_${exam.subject}.pdf';
      final file = await ReportPdfGenerator.savePdfFile(pdfBytes, fileName);

      if (!mounted) return;
      setState(() => _isGenerating = false);

      await ReportPdfGenerator.printOrSavePdf(
          bytes: pdfBytes, fileName: fileName);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                    child: Text('PDF saved: ${file.path.split('/').last}')),
              ],
            ),
            backgroundColor: AppColors.primary,
            action: SnackBarAction(
              label: 'SHARE',
              textColor: Colors.white,
              onPressed: () => _sharePdf(result, exam, settings),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGenerating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to generate PDF: $e'),
              backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _sharePdf(ScanResultModel result, ExamModel exam,
      InstituteSettingsModel settings) async {
    setState(() => _isGenerating = true);
    try {
      final pdfBytes = await ReportPdfGenerator.generateReportCardPdf(
        studentName: result.studentName,
        studentCode: result.studentCode,
        rollNumber: result.studentRoll,
        className: result.studentClass,
        assessmentTitle: exam.title,
        examDate: exam.date,
        totalScore:
            '${result.marksObtained.toStringAsFixed(1)} / ${result.maximumMarks.toInt()}',
        percentage: '${result.percentage}%',
        classRank: '#03 / ${exam.totalStudents}',
        percentile:
            '${((result.percentage * 1.05).clamp(0, 99.8)).toStringAsFixed(1)}%',
        totalQuestions: exam.questionsCount,
        correctCount: result.correctCount,
        wrongCount: result.wrongCount,
        unattemptedCount: result.unattemptedCount,
        netMarks: result.marksObtained,
      );

      if (!mounted) return;
      setState(() => _isGenerating = false);

      final fileName =
          '${result.studentName.replaceAll(" ", "_")}_${exam.subject}.pdf';
      await ReportPdfGenerator.sharePdf(
        bytes: pdfBytes,
        fileName: fileName,
        subject: 'Official Report Card - ${result.studentName} (${exam.title})',
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isGenerating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to share PDF: $e'),
              backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = ref.watch(selectedResultProvider);
    final exam = ref.watch(activeExamProvider);
    final settings = ref.watch(settingsProvider);

    if (result == null || exam == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Report Card Preview')),
        body: const Center(child: Text('No report card data selected')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text('Report Card Preview'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.safePop('/exam-results-summary'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share Report Card',
            onPressed:
                _isGenerating ? null : () => _sharePdf(result, exam, settings),
          ),
          IconButton(
            icon: const Icon(Icons.download_rounded),
            tooltip: 'Download PDF',
            onPressed: _isGenerating
                ? null
                : () => _downloadPdf(result, exam, settings),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          children: [
            // A4 Styled Report Card Container
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 20,
                      offset: const Offset(0, 6)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Institute Header
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.school_rounded,
                              color: Colors.white, size: 28),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          settings.orgName.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              letterSpacing: 0.5),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Official Assessment & Performance Report Card',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: AppColors.tertiary, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Divider(thickness: 1.2),
                  const SizedBox(height: 10),

                  // Student & Exam Metadata Grid
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Student Name',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: AppColors.tertiary,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            Text(result.studentName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 13)),
                            const SizedBox(height: 8),
                            const Text('Roll No / Code',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: AppColors.tertiary,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            Text(
                                '${result.studentRoll} (${result.studentCode}) • ${result.studentClass}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 12)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('Assessment',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: AppColors.tertiary,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            Text(exam.title,
                                textAlign: TextAlign.end,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 13)),
                            const SizedBox(height: 8),
                            const Text('Date of Exam',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: AppColors.tertiary,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            Text(exam.date,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Big Score Banner
                  Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                    decoration: BoxDecoration(
                      color: AppColors.softMint,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.secondaryContainer),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                            child: _ReportStat(
                                label: 'TOTAL SCORE',
                                val:
                                    '${result.marksObtained.toStringAsFixed(1)} / ${result.maximumMarks.toInt()}')),
                        Expanded(
                            child: _ReportStat(
                                label: 'PERCENTAGE',
                                val: '${result.percentage}%')),
                        Expanded(
                            child: _ReportStat(
                                label: 'CLASS RANK',
                                val: '#03 / ${exam.totalStudents}')),
                        Expanded(
                            child: _ReportStat(
                                label: 'PERCENTILE',
                                val:
                                    '${((result.percentage * 1.05).clamp(0, 99.8)).toStringAsFixed(1)}%')),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Section Breakdown Table
                  const Text('Subject & Question Analysis',
                      style:
                          TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.surfaceContainerHigh),
                    ),
                    child: Column(
                      children: [
                        _TableRow(
                            col1: 'Total Questions',
                            col2: '${exam.questionsCount}',
                            isHeader: true),
                        _TableRow(
                            col1: 'Correct Answers (+${exam.correctMarks})',
                            col2:
                                '${result.correctCount} (${(result.correctCount * exam.correctMarks).toStringAsFixed(1)} Marks)'),
                        _TableRow(
                            col1: 'Incorrect Answers (${exam.wrongMarks})',
                            col2:
                                '${result.wrongCount} (${(result.wrongCount * exam.wrongMarks).toStringAsFixed(1)} Marks)'),
                        _TableRow(
                            col1: 'Unattempted (0)',
                            col2: '${result.unattemptedCount} (0 Marks)'),
                        _TableRow(
                            col1: 'Net Obtained Marks',
                            col2: result.marksObtained.toStringAsFixed(2),
                            isBold: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Teacher Remark
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Teacher Remark:',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                color: AppColors.primary)),
                        const SizedBox(height: 3),
                        Text(
                          result.percentage >= 85
                              ? 'Outstanding performance with strong conceptual clarity. Keep up the high standard!'
                              : 'Good effort. Recommend focused review on missed questions to improve accuracy.',
                          style: const TextStyle(
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                              height: 1.3),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Verification Footer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                'Verification Code: OMR-${result.studentCode}-2026',
                                style: const TextStyle(
                                    fontSize: 10, color: AppColors.tertiary)),
                            const SizedBox(height: 2),
                            Text('Generated: ${result.scannedAt}',
                                style: const TextStyle(
                                    fontSize: 9, color: AppColors.tertiary)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black26),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(Icons.qr_code_2_rounded, size: 36),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          border:
              Border(top: BorderSide(color: AppColors.surfaceContainerHigh)),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isGenerating
                    ? null
                    : () => _downloadPdf(result, exam, settings),
                icon: _isGenerating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.primary),
                      )
                    : const Icon(Icons.download_rounded),
                label: const Text('Download PDF'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => context.push('/email-report-card'),
                icon: const Icon(Icons.send_rounded),
                label: const Text('Email to Parent'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportStat extends StatelessWidget {
  final String label;
  final String val;
  const _ReportStat({required this.label, required this.val});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.bold,
                color: AppColors.secondary)),
        const SizedBox(height: 3),
        Text(val,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.primary)),
      ],
    );
  }
}

class _TableRow extends StatelessWidget {
  final String col1;
  final String col2;
  final bool isHeader;
  final bool isBold;

  const _TableRow({
    required this.col1,
    required this.col2,
    this.isHeader = false,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: isHeader ? AppColors.surfaceContainerLow : Colors.transparent,
        border: const Border(
            bottom: BorderSide(color: AppColors.surfaceContainerHigh)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(col1,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: isBold || isHeader
                        ? FontWeight.bold
                        : FontWeight.normal)),
          ),
          const SizedBox(width: 8),
          Text(col2,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: isBold || isHeader
                      ? FontWeight.bold
                      : FontWeight.normal)),
        ],
      ),
    );
  }
}
