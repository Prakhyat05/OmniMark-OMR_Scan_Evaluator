import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme.dart';
import '../../../../core/utils/navigation_utils.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/database/local_database.dart';

class ReviewQueuePage extends ConsumerWidget {
  const ReviewQueuePage({super.key});

  void _resolveItem(BuildContext context, WidgetRef ref,
      ReviewQueueItemModel item, String chosenOption) {
    final activeExam = ref.read(activeExamProvider);
    if (activeExam != null) {
      ref.read(scanResultsProvider.notifier).resolveReviewItem(
            item.resultId,
            item.questionNumber,
            chosenOption,
            activeExam,
          );

      // Record tamper-proof audit log
      LocalOMRDatabase().logAuditResolution(
        scanResultId: item.resultId,
        questionNumber: item.questionNumber,
        originalOption: item.detectedOption,
        resolvedOption: chosenOption,
        reviewerId: 'staff_examiner',
        reason: 'Verified by examiner from Review Required queue',
      );
    }
    ref.read(reviewQueueProvider.notifier).removeItem(item.id);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Resolved Question ${item.questionNumber} for ${item.studentName} (${chosenOption.toUpperCase()})'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queue = ref.watch(reviewQueueProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Review Required Queue'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.safePop('/dashboard'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            tooltip: 'Guidelines',
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('OMR Review Guidelines'),
                  content: const Text(
                    'Ambiguous marks occur when students erase improperly or mark multiple options. Staff verification permanently logs the reviewer ID and updates official marks.',
                  ),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Got it')),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            color: const Color(0xFFFEF3C7),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: Color(0xFFD97706), size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${queue.length} ambiguous items require manual staff verification before results can be finalized.',
                    style: const TextStyle(
                        color: Color(0xFF92400E),
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),

          // Flagged items list
          Expanded(
            child: queue.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle_outline_rounded,
                            size: 64, color: AppColors.primary),
                        const SizedBox(height: 16),
                        const Text(
                          'All Flagged Sheets Resolved!',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'You can now email finalized report cards to parents.',
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 13),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () =>
                              context.safePop('/exam-results-summary'),
                          child: const Text('Back to Results Summary'),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                    itemCount: queue.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final item = queue[index];

                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.studentName,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15),
                                        ),
                                        Text(
                                          '${item.studentCode} • ${item.examName}',
                                          style: const TextStyle(
                                              color: AppColors.tertiary,
                                              fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEE2E2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'Q${item.questionNumber}',
                                      style: const TextStyle(
                                        color: AppColors.error,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceContainerLow,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.help_outline_rounded,
                                        size: 18, color: AppColors.tertiary),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Issue: ${item.reason} (Confidence: ${item.confidence.toStringAsFixed(1)}%)',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text('Select Verified Bubble Option:',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 8),
                              StatefulBuilder(
                                builder: (ctx, setLocalState) {
                                  return Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children: ['1', '2', '3', '4', 'Blank']
                                        .map((opt) {
                                      final isPicked =
                                          item.selectedOption == opt;
                                      return ChoiceChip(
                                        label: Text(opt),
                                        selected: isPicked,
                                        onSelected: (val) {
                                          setLocalState(() {
                                            item.selectedOption = opt;
                                          });
                                        },
                                        selectedColor: AppColors.primary,
                                        labelStyle: TextStyle(
                                          color: isPicked
                                              ? Colors.white
                                              : AppColors.onSurface,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      );
                                    }).toList(),
                                  );
                                },
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () => _resolveItem(
                                          context, ref, item, 'Blank'),
                                      child: const Text('Mark as Blank'),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () => _resolveItem(context,
                                          ref, item, item.selectedOption),
                                      child: const Text('Approve Choice'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
