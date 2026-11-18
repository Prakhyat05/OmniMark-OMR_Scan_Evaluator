import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme.dart';
import '../../../../core/utils/navigation_utils.dart';
import '../../../../core/utils/evaluation_engine.dart';
import '../../../../core/state/app_state.dart';

enum QuestionFilter { all, correct, incorrect, unattempted }

class StudentResultDetailPage extends ConsumerStatefulWidget {
  const StudentResultDetailPage({super.key});

  @override
  ConsumerState<StudentResultDetailPage> createState() =>
      _StudentResultDetailPageState();
}

class _StudentResultDetailPageState
    extends ConsumerState<StudentResultDetailPage> {
  QuestionFilter _selectedFilter = QuestionFilter.all;

  @override
  Widget build(BuildContext context) {
    final result = ref.watch(selectedResultProvider);
    final activeExam = ref.watch(activeExamProvider);

    if (result == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Result Breakdown')),
        body: const Center(child: Text('No student result selected')),
      );
    }

    final totalQuestions = result.answers.isNotEmpty
        ? result.answers.length
        : (activeExam?.questionsCount ?? 180);

    final filteredAnswers = result.answers.where((a) {
      final isUnatt = a.detectedOption == null || a.detectedOption!.isEmpty;
      final isCorr = a.isCorrect == true;
      switch (_selectedFilter) {
        case QuestionFilter.all:
          return true;
        case QuestionFilter.correct:
          return isCorr;
        case QuestionFilter.incorrect:
          return !isCorr && !isUnatt;
        case QuestionFilter.unattempted:
          return isUnatt;
      }
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('OMR Evaluation Breakdown'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.safePop('/exam-results-summary'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: 'View Report Card',
            onPressed: () => context.push('/report-card-preview'),
          ),
          IconButton(
            icon: const Icon(Icons.send_rounded),
            tooltip: 'Email to Parent',
            onPressed: () => context.push('/email-report-card'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Student Score Hero Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.surfaceContainerHigh),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              result.studentName,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Roll #${result.studentRoll} • Code: ${result.studentCode} • ${result.studentClass}',
                              style: const TextStyle(
                                  color: AppColors.tertiary, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: result.percentage >= 70
                              ? AppColors.softMint
                              : (result.percentage >= 40
                                  ? const Color(0xFFFEF3C7)
                                  : AppColors.errorContainer),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          '${result.percentage.toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: result.percentage >= 70
                                ? AppColors.primary
                                : (result.percentage >= 40
                                    ? const Color(0xFFD97706)
                                    : AppColors.error),
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: _BreakdownStat(
                          val:
                              '${result.marksObtained.toStringAsFixed(1)} / ${result.maximumMarks.toInt()}',
                          label: 'Marks',
                          color: AppColors.primary,
                        ),
                      ),
                      Expanded(
                        child: _BreakdownStat(
                          val: '${result.percentage.toStringAsFixed(1)}%',
                          label: 'Percentage',
                          color: AppColors.secondary,
                        ),
                      ),
                      Expanded(
                        child: _BreakdownStat(
                          val:
                              '${((result.percentage * 1.05).clamp(0, 99.8)).toStringAsFixed(1)}%',
                          label: 'Percentile',
                          color: const Color(0xFF0284C7),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _CountTag(
                          count: result.correctCount,
                          label: 'Correct',
                          color: AppColors.primary,
                        ),
                      ),
                      Expanded(
                        child: _CountTag(
                          count: result.wrongCount,
                          label: 'Wrong',
                          color: AppColors.error,
                        ),
                      ),
                      Expanded(
                        child: _CountTag(
                          count: result.unattemptedCount,
                          label: 'Unattempted',
                          color: AppColors.tertiary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // OMRChecker High-Res Marked Sheet Inspector
            if (result.annotatedPreviewBase64 != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.document_scanner_rounded,
                          size: 18, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text('OMR Sheet Visual Matrix',
                          style: Theme.of(context).textTheme.titleLarge),
                    ],
                  ),
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => _openFullscreenInspector(context, result),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.zoom_in_rounded,
                              size: 14, color: AppColors.primary),
                          SizedBox(width: 4),
                          Text(
                            'Inspect Overlay',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => _openFullscreenInspector(context, result),
                child: Container(
                  width: double.infinity,
                  height: 420,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.surfaceContainerHigh),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Center(
                          child: InteractiveViewer(
                            panEnabled: true,
                            scaleEnabled: true,
                            minScale: 0.8,
                            maxScale: 3.5,
                            child: Image.memory(
                              base64Decode(result.annotatedPreviewBase64!),
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.80),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.fullscreen_rounded,
                                    color: Colors.white, size: 16),
                                SizedBox(width: 5),
                                Text(
                                  'Tap to Zoom & Pan',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Question Breakdown Filter Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Question-wise Analysis',
                    style: Theme.of(context).textTheme.titleLarge),
                Text('$totalQuestions Total',
                    style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
            const SizedBox(height: 12),

            // Filter Chips Bar
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _FilterChip(
                    label: 'All ($totalQuestions)',
                    isSelected: _selectedFilter == QuestionFilter.all,
                    onTap: () =>
                        setState(() => _selectedFilter = QuestionFilter.all),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Correct (${result.correctCount})',
                    color: AppColors.primary,
                    isSelected: _selectedFilter == QuestionFilter.correct,
                    onTap: () => setState(
                        () => _selectedFilter = QuestionFilter.correct),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Incorrect (${result.wrongCount})',
                    color: AppColors.error,
                    isSelected: _selectedFilter == QuestionFilter.incorrect,
                    onTap: () => setState(
                        () => _selectedFilter = QuestionFilter.incorrect),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Unattempted (${result.unattemptedCount})',
                    color: AppColors.tertiary,
                    isSelected: _selectedFilter == QuestionFilter.unattempted,
                    onTap: () => setState(
                        () => _selectedFilter = QuestionFilter.unattempted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Questions List
            if (filteredAnswers.isEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.surfaceContainerHigh),
                ),
                child: Center(
                  child: Text(
                    'No questions in this category',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ),
              ),
            ] else ...[
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredAnswers.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final a = filteredAnswers[index];
                  final isUnatt =
                      a.detectedOption == null || a.detectedOption!.isEmpty;
                  final isCorr = a.isCorrect == true;

                  return _QuestionTile(
                    qNum: a.questionNumber,
                    markedOpt: a.detectedOption ?? '-',
                    correctOpt: a.correctOptions.isNotEmpty
                        ? a.correctOptions.first
                        : '-',
                    isCorrect: isCorr,
                    isUnattempted: isUnatt,
                    isMultiple: a.isMultiple,
                    confidence: a.confidence,
                    marks: a.marksAwarded,
                    onTap: () => _showTeacherOverrideDialog(context, a),
                  );
                },
              ),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _openFullscreenInspector(BuildContext context, ScanResultModel result) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog.fullscreen(
        child: Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            title: Text('${result.studentName} - Marked OMR'),
            actions: [
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(ctx),
              ),
            ],
          ),
          body: Center(
            child: InteractiveViewer(
              panEnabled: true,
              scaleEnabled: true,
              minScale: 0.5,
              maxScale: 5.0,
              child: Image.memory(
                base64Decode(result.annotatedPreviewBase64!),
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showTeacherOverrideDialog(
      BuildContext context, AnswerItemResult answer) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Teacher Override: Question ${answer.questionNumber}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
            const SizedBox(height: 4),
            Text(
              'Detected: ${answer.detectedOption ?? "None"} • Key: ${answer.correctOptions.join(", ")}',
              style: const TextStyle(color: AppColors.tertiary, fontSize: 13),
            ),
            const SizedBox(height: 20),
            const Text(
              'Select Correct Marked Option:',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: ['1', '2', '3', '4', 'None'].map((opt) {
                final isCurr = (answer.detectedOption == opt) ||
                    (opt == 'None' && answer.detectedOption == null);
                return InkWell(
                  onTap: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              'Updated Q${answer.questionNumber} to $opt')),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isCurr
                          ? AppColors.primary
                          : AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      opt,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isCurr ? Colors.white : AppColors.onSurface,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? AppColors.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? activeColor : AppColors.surfaceContainerHigh,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.onSurface,
          ),
        ),
      ),
    );
  }
}

class _QuestionTile extends StatelessWidget {
  final int qNum;
  final String markedOpt;
  final String correctOpt;
  final bool isCorrect;
  final bool isUnattempted;
  final bool isMultiple;
  final double confidence;
  final double? marks;
  final VoidCallback onTap;

  const _QuestionTile({
    required this.qNum,
    required this.markedOpt,
    required this.correctOpt,
    required this.isCorrect,
    required this.isUnattempted,
    this.isMultiple = false,
    this.confidence = 1.0,
    this.marks,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final awarded = marks != null
        ? (marks! > 0 ? '+$marks' : '$marks')
        : (isCorrect ? '+4.0' : (isUnattempted ? '0.0' : '-1.0'));
    final isWrong = !isCorrect && !isUnattempted;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isMultiple
                ? const Color(0xFFF59E0B)
                : (isWrong
                    ? AppColors.errorContainer
                    : isUnattempted
                        ? AppColors.surfaceContainerHigh
                        : AppColors.softMint),
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 38,
              child: Text(
                'Q$qNum',
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
            const Spacer(),
            Flexible(
              child: Text(
                isMultiple ? 'Multiple' : 'Marked: $markedOpt',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: isMultiple
                      ? const Color(0xFFD97706)
                      : (isWrong ? AppColors.error : AppColors.onSurface),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                'Key: $correctOpt',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.tertiary, fontSize: 12),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isMultiple
                    ? const Color(0xFFFEF3C7)
                    : (isWrong
                        ? AppColors.errorContainer
                        : (isUnattempted
                            ? AppColors.surfaceContainerLow
                            : AppColors.softMint)),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                awarded,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  color: isMultiple
                      ? const Color(0xFFD97706)
                      : (isWrong
                          ? AppColors.error
                          : (isUnattempted
                              ? AppColors.tertiary
                              : AppColors.primary)),
                ),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.edit_outlined,
                size: 14, color: AppColors.tertiary),
          ],
        ),
      ),
    );
  }
}

class _BreakdownStat extends StatelessWidget {
  final String val;
  final String label;
  final Color color;

  const _BreakdownStat(
      {required this.val, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(val,
            style: TextStyle(
                fontWeight: FontWeight.w800, fontSize: 16, color: color)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(fontSize: 11, color: AppColors.tertiary)),
      ],
    );
  }
}

class _CountTag extends StatelessWidget {
  final int count;
  final String label;
  final Color color;

  const _CountTag(
      {required this.count, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '$count $label',
              style: TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 12, color: color),
            ),
          ),
        ),
      ],
    );
  }
}
