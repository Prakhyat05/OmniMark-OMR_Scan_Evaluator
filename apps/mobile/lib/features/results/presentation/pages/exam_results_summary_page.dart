import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../app/theme.dart';
import '../../../../core/utils/navigation_utils.dart';
import '../../../../core/state/app_state.dart';

class ExamResultsSummaryPage extends ConsumerStatefulWidget {
  const ExamResultsSummaryPage({super.key});

  @override
  ConsumerState<ExamResultsSummaryPage> createState() => _ExamResultsSummaryPageState();
}

class _ExamResultsSummaryPageState extends ConsumerState<ExamResultsSummaryPage> {
  Future<File> _generateCsvFile(List<ScanResultModel> results, String examTitle) async {
    final buffer = StringBuffer();
    buffer.writeln('Rank,Student Name,Student Code,Score,Max Marks,Percentage,Correct,Wrong,Unattempted');
    for (int i = 0; i < results.length; i++) {
      final r = results[i];
      buffer.writeln('${i + 1},"${r.studentName}",${r.studentCode},${r.marksObtained},${r.maximumMarks},${r.percentage}%,${r.correctCount},${r.wrongCount},${r.unattemptedCount}');
    }
    final dir = await getApplicationDocumentsDirectory();
    final sanitizedTitle = examTitle.replaceAll(' ', '_');
    final file = File('${dir.path}/${sanitizedTitle}_Results.csv');
    await file.writeAsString(buffer.toString());
    return file;
  }

  Future<void> _exportCsv(List<ScanResultModel> results, String examTitle) async {
    final file = await _generateCsvFile(results, examTitle);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.table_chart_outlined, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Text('Saved: ${file.path.split('/').last}')),
            ],
          ),
          backgroundColor: AppColors.primary,
          action: SnackBarAction(
            label: 'SHARE',
            textColor: Colors.white,
            onPressed: () => Share.shareXFiles([XFile(file.path, mimeType: 'text/csv')]),
          ),
        ),
      );
    }
  }

  void _shareResultsSummary(List<ScanResultModel> results, ExamModel exam, double avgScore) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Share Assessment Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(
              'Batch: ${exam.className} • ${exam.title}\nTotal Evaluated: ${results.length}/${exam.totalStudents} • Average: ${avgScore.toStringAsFixed(1)}%',
              style: const TextStyle(color: AppColors.tertiary, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.share_rounded, color: AppColors.primary),
              title: const Text('Share Summary Text'),
              subtitle: const Text('Export rank list to WhatsApp/Messages'),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
              onTap: () {
                Navigator.pop(ctx);
                final topPerformers = results.take(3).map((r) => '${r.studentName} - ${r.marksObtained.toStringAsFixed(1)}/${r.maximumMarks.toInt()} (${r.percentage}%)').join('\n');
                Share.share(
                  '📊 *${exam.title} - Results Summary*\nBatch: ${exam.className}\nAverage: ${avgScore.toStringAsFixed(1)}% | Evaluated: ${results.length}\n\nTop Performers:\n$topPerformers\n\nFull roster exported from OMR Scan System.',
                  subject: '${exam.title} - Batch Summary',
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.download_rounded, color: AppColors.primary),
              title: const Text('Export Excel / CSV Sheet'),
              subtitle: const Text('Full student-wise marks and question breakdown'),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
              onTap: () {
                Navigator.pop(ctx);
                _exportCsv(results, exam.title);
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _sendAllReports(List<ScanResultModel> results, ExamModel exam) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Email All Report Cards?'),
        content: Text(
          'This will trigger background email delivery of personalized PDF scorecards to all ${results.length} evaluated students\' parents.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              for (var r in results) {
                ref.read(emailDeliveryProvider.notifier).queueEmail(
                  EmailLogModel(
                    id: 'mail_${DateTime.now().millisecondsSinceEpoch}_${r.studentCode}',
                    studentName: r.studentName,
                    email: r.parentEmail,
                    examTitle: exam.title,
                    status: 'delivered',
                    timeStr: 'Just now',
                  ),
                );
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${results.length} parent report emails queued for delivery!'),
                  backgroundColor: AppColors.primary,
                ),
              );
            },
            child: const Text('Send to All Parents'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeExam = ref.watch(activeExamProvider);
    final allResults = ref.watch(scanResultsProvider);

    if (activeExam == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Assessment Results')),
        body: const Center(child: Text('No active exam')),
      );
    }

    final examResults = allResults.where((r) => r.examId == activeExam.id).toList();
    examResults.sort((a, b) => b.marksObtained.compareTo(a.marksObtained));

    final avgPercentage = examResults.isNotEmpty
        ? examResults.map((r) => r.percentage).reduce((a, b) => a + b) / examResults.length
        : 0.0;
    final highestMarks = examResults.isNotEmpty
        ? examResults.map((r) => r.marksObtained).reduce((a, b) => a > b ? a : b)
        : 0.0;
    final passCount = examResults.where((r) => r.percentage >= 40.0).length;
    final passRate = examResults.isNotEmpty ? (passCount / examResults.length * 100) : 0.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Assessment Results'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.safePop('/exams'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share Summary',
            onPressed: () => _shareResultsSummary(examResults, activeExam, avgPercentage),
          ),
          IconButton(
            icon: const Icon(Icons.download_rounded),
            tooltip: 'Export CSV',
            onPressed: () => _exportCsv(examResults, activeExam.title),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header stats card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.surfaceContainerHigh),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(activeExam.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
                  const SizedBox(height: 4),
                  Text('${activeExam.className} • ${activeExam.questionsCount} Questions • Max ${(activeExam.questionsCount * activeExam.correctMarks).toInt()} Marks', style: const TextStyle(color: AppColors.tertiary, fontSize: 12)),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatColumn(label: 'Avg Score', val: '${avgPercentage.toStringAsFixed(1)}%', color: AppColors.primary),
                      _StatColumn(label: 'Highest', val: '${highestMarks.toStringAsFixed(0)} / ${(activeExam.questionsCount * activeExam.correctMarks).toInt()}', color: AppColors.secondary),
                      _StatColumn(label: 'Evaluated', val: '${examResults.length} / ${activeExam.totalStudents}', color: AppColors.onSurface),
                      _StatColumn(label: 'Pass Rate', val: '${passRate.toStringAsFixed(1)}%', color: const Color(0xFF0369A1)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Section Header & Batch Email Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Student Merit List', style: Theme.of(context).textTheme.titleLarge),
                OutlinedButton.icon(
                  onPressed: () => _sendAllReports(examResults, activeExam),
                  icon: const Icon(Icons.send_rounded, size: 16),
                  label: const Text('Email All', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Students Rank List
            if (examResults.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 40),
                alignment: Alignment.center,
                child: const Column(
                  children: [
                    Icon(Icons.document_scanner_outlined, size: 48, color: AppColors.outline),
                    SizedBox(height: 12),
                    Text('No sheets scanned yet for this assessment.', style: TextStyle(color: AppColors.tertiary)),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: examResults.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item = examResults[index];
                  final rank = index + 1;

                  return Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: rank <= 3 ? AppColors.softMint : AppColors.surfaceContainerLow,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: rank <= 3 ? AppColors.primary : AppColors.outlineVariant,
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '#$rank',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: rank <= 3 ? AppColors.primary : AppColors.tertiary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      title: Text(item.studentName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                      subtitle: Text('ID: ${item.studentCode} • ${item.correctCount} Correct, ${item.wrongCount} Wrong', style: const TextStyle(fontSize: 12)),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('${item.marksObtained.toStringAsFixed(1)} / ${item.maximumMarks.toInt()}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.primary)),
                          Text('${item.percentage}%', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.secondary)),
                        ],
                      ),
                      onTap: () {
                        ref.read(selectedResultIdProvider.notifier).state = item.id;
                        context.push('/student-result-detail');
                      },
                    ),
                  );
                },
              ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String val;
  final Color color;

  const _StatColumn({required this.label, required this.val, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(val, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.tertiary)),
      ],
    );
  }
}
