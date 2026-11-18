import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme.dart';
import '../../../../core/state/app_state.dart';

class HomeDashboardPage extends ConsumerWidget {
  const HomeDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeExam = ref.watch(activeExamProvider);
    final exams = ref.watch(examsProvider);
    final reviewQueue = ref.watch(reviewQueueProvider);
    final scanResults = ref.watch(scanResultsProvider);
    final emailLogs = ref.watch(emailDeliveryProvider);

    final activeExamResults = scanResults.where((r) => r.examId == activeExam?.id).toList();
    final evaluatedCount = activeExamResults.where((r) => r.isReviewed).length;
    final inReviewCount = reviewQueue.where((r) => r.examId == activeExam?.id).length;
    final emailedCount = emailLogs.where((e) => e.status == 'delivered').length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Apex International Academy',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              'Grade 10 & 12 Assessment Portal',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.tertiary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () => context.push('/notifications'),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () => context.push('/profile'),
              child: const CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primaryContainer,
                child: Text('AS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Active Exam Summary Hero Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, Color(0xFF005313)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.28),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.fiber_manual_record, color: Color(0xFF78DC77), size: 10),
                            SizedBox(width: 6),
                            Text(
                              'ACTIVE EXAM',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text('Today', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    activeExam?.title ?? 'Mathematics Weekly Assessment 04',
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${activeExam?.className ?? "Grade 10"} • ${activeExam?.questionsCount ?? 50} Questions • Max ${(activeExam?.questionsCount ?? 50) * 4} Marks',
                    style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatItem(val: '${activeExam?.scannedCount ?? 48}', label: 'Scanned'),
                        const _StatDivider(),
                        _StatItem(val: '$evaluatedCount', label: 'Evaluated'),
                        const _StatDivider(),
                        _StatItem(val: '$inReviewCount', label: 'In Review', highlight: inReviewCount > 0),
                        const _StatDivider(),
                        _StatItem(val: '$emailedCount', label: 'Emailed'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Quick Operations Grid
            Text('Quick Operations', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ActionCard(
                    icon: Icons.camera_alt_rounded,
                    title: 'Scan OMR',
                    subtitle: 'Camera or Gallery',
                    color: AppColors.primary,
                    onTap: () => context.push('/scan'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionCard(
                    icon: Icons.rule_folder_rounded,
                    title: 'Review Queue',
                    subtitle: '$inReviewCount ambiguous',
                    color: const Color(0xFFC05621),
                    badgeCount: inReviewCount,
                    onTap: () => context.push('/review-queue'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ActionCard(
                    icon: Icons.add_circle_outline_rounded,
                    title: 'New Exam',
                    subtitle: 'Setup & answer key',
                    color: AppColors.secondary,
                    onTap: () => context.push('/create-exam'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionCard(
                    icon: Icons.mark_email_read_outlined,
                    title: 'Email Delivery',
                    subtitle: 'Parent reports',
                    color: AppColors.tertiary,
                    onTap: () => context.push('/email-history'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Recent Assessments Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Recent Assessments', style: Theme.of(context).textTheme.titleLarge),
                TextButton(
                  onPressed: () => context.go('/exams'),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            ...exams.take(3).map((exam) {
              return _ExamTile(
                title: exam.title,
                batch: exam.className,
                date: exam.date,
                scanned: exam.scannedCount,
                total: exam.totalStudents,
                onTap: () {
                  ref.read(activeExamIdProvider.notifier).state = exam.id;
                  if (exam.status == 'draft') {
                    context.push('/answer-key-setup');
                  } else {
                    context.push('/exam-results-summary');
                  }
                },
              );
            }),

            const SizedBox(height: 90),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String val;
  final String label;
  final bool highlight;
  const _StatItem({required this.val, required this.label, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          val,
          style: TextStyle(
            color: highlight ? const Color(0xFFFFD54F) : Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11),
        ),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();
  @override
  Widget build(BuildContext context) {
    return Container(height: 24, width: 1, color: Colors.white.withOpacity(0.2));
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final int? badgeCount;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.badgeCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.surfaceContainerHigh),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(height: 14),
                Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16)),
                const SizedBox(height: 4),
                Text(subtitle, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12)),
              ],
            ),
            if (badgeCount != null && badgeCount! > 0)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$badgeCount',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ExamTile extends StatelessWidget {
  final String title;
  final String batch;
  final String date;
  final int scanned;
  final int total;
  final VoidCallback onTap;

  const _ExamTile({
    required this.title,
    required this.batch,
    required this.date,
    required this.scanned,
    required this.total,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text('$batch • $date', style: TextStyle(color: AppColors.onSurfaceVariant.withOpacity(0.8), fontSize: 13)),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('$scanned/$total Scanned', style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary, fontSize: 13)),
            const SizedBox(height: 2),
            const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.outline),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
