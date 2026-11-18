import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme.dart';
import '../../../../core/utils/navigation_utils.dart';
import '../../../../core/state/app_state.dart';

class StudentDetailPage extends ConsumerWidget {
  const StudentDetailPage({super.key});

  void _editStudent(BuildContext context, WidgetRef ref, StudentModel student) {
    final nameController = TextEditingController(text: student.name);
    final emailController = TextEditingController(text: student.parentEmail);
    final phoneController = TextEditingController(text: student.parentPhone);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Edit Student Profile',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration:
                    const InputDecoration(labelText: 'Student Full Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Parent Email'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Parent Phone'),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final updated = student.copyWith(
                      name: nameController.text.trim(),
                      parentEmail: emailController.text.trim(),
                      parentPhone: phoneController.text.trim(),
                    );
                    ref.read(studentsProvider.notifier).updateStudent(updated);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Student profile updated successfully!'),
                        backgroundColor: AppColors.primary,
                      ),
                    );
                  },
                  child: const Text('Save Profile Changes'),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final student = ref.watch(selectedStudentProvider);
    if (student == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Student Profile')),
        body: const Center(child: Text('No student selected')),
      );
    }

    final initials = student.name
        .split(' ')
        .take(2)
        .map((e) => e.isNotEmpty ? e[0] : '')
        .join();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Student Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.safePop('/students'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Profile',
            onPressed: () => _editStudent(context, ref, student),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Student Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.surfaceContainerHigh),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: AppColors.softMint,
                    child: Text(initials,
                        style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 24,
                            fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 12),
                  Text(student.name,
                      style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 4),
                  Text('Roll #${student.roll} • ${student.className}',
                      style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StudentStat(
                          val: student.avgScore,
                          label: 'Avg Score',
                          color: AppColors.primary),
                      Container(
                          height: 30,
                          width: 1,
                          color: AppColors.surfaceContainerHigh),
                      _StudentStat(
                          val: '${student.examsCount}',
                          label: 'Exams Taken',
                          color: AppColors.secondary),
                      Container(
                          height: 30,
                          width: 1,
                          color: AppColors.surfaceContainerHigh),
                      const _StudentStat(
                          val: '#03',
                          label: 'Class Rank',
                          color: Color(0xFF0284C7)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Parent Information Section
            Text('Parent & Communication',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _InfoRow(
                        icon: Icons.person_outline,
                        label: 'Parent Name',
                        val: '${student.parentName} (${student.relationship})'),
                    const Divider(height: 24),
                    _InfoRow(
                        icon: Icons.email_outlined,
                        label: 'Email',
                        val: student.parentEmail),
                    const Divider(height: 24),
                    _InfoRow(
                        icon: Icons.phone_outlined,
                        label: 'Phone',
                        val: student.parentPhone),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Assessment History
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Assessment History',
                    style: Theme.of(context).textTheme.titleLarge),
                TextButton.icon(
                  onPressed: () => context.push('/email-report-card'),
                  icon: const Icon(Icons.send_rounded, size: 16),
                  label: const Text('Email Report'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            _ExamHistoryCard(
              title: 'Mathematics Assessment 04',
              date: '21 Aug 2026',
              score: '176 / 200',
              percentage: '88.0%',
              rank: '#03',
              onTap: () => context.push('/report-card-preview'),
            ),
            _ExamHistoryCard(
              title: 'Physics Mid-Term Exam',
              date: '18 Aug 2026',
              score: '184 / 200',
              percentage: '92.0%',
              rank: '#02',
              onTap: () => context.push('/report-card-preview'),
            ),
            _ExamHistoryCard(
              title: 'Chemistry Organic Quiz',
              date: '14 Aug 2026',
              score: '168 / 200',
              percentage: '84.0%',
              rank: '#05',
              onTap: () => context.push('/report-card-preview'),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _StudentStat extends StatelessWidget {
  final String val;
  final String label;
  final Color color;

  const _StudentStat(
      {required this.val, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(val,
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 18, color: color)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(fontSize: 11, color: AppColors.tertiary)),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String val;

  const _InfoRow({required this.icon, required this.label, required this.val});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style:
                    const TextStyle(fontSize: 11, color: AppColors.tertiary)),
            const SizedBox(height: 2),
            Text(val,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }
}

class _ExamHistoryCard extends StatelessWidget {
  final String title;
  final String date;
  final String score;
  final String percentage;
  final String rank;
  final VoidCallback onTap;

  const _ExamHistoryCard({
    required this.title,
    required this.date,
    required this.score,
    required this.percentage,
    required this.rank,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text('$date • Rank $rank',
            style: const TextStyle(fontSize: 12, color: AppColors.tertiary)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(score,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    fontSize: 14)),
            Text(percentage,
                style:
                    const TextStyle(fontSize: 11, color: AppColors.secondary)),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
