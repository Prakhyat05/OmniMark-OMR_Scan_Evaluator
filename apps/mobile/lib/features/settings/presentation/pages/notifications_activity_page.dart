import 'package:flutter/material.dart';
import '../../../../app/theme.dart';
import '../../../../core/utils/navigation_utils.dart';

class NotificationsActivityPage extends StatefulWidget {
  const NotificationsActivityPage({super.key});

  @override
  State<NotificationsActivityPage> createState() =>
      _NotificationsActivityPageState();
}

class _NotificationsActivityPageState extends State<NotificationsActivityPage> {
  final List<Map<String, dynamic>> _activities = [
    {
      'title': '48 Parent Report Emails Dispatched',
      'subtitle': 'Mathematics Assessment 04 delivery completed successfully',
      'time': '10 mins ago',
      'icon': Icons.mark_email_read_rounded,
      'color': AppColors.primary,
    },
    {
      'title': '3 Sheets Sent to Review Queue',
      'subtitle': 'Low confidence/multiple bubbles flagged in batch scan',
      'time': '35 mins ago',
      'icon': Icons.warning_amber_rounded,
      'color': const Color(0xFFD97706),
    },
    {
      'title': 'Batch Scan Completed (48 Pages)',
      'subtitle': 'Camera session processed and evaluated by OMR service',
      'time': '42 mins ago',
      'icon': Icons.document_scanner_rounded,
      'color': AppColors.secondary,
    },
    {
      'title': 'Answer Key Locked for Exam',
      'subtitle': 'Answer Key Version 1 locked for Mathematics Assessment 04',
      'time': '2 hours ago',
      'icon': Icons.lock_outline_rounded,
      'color': AppColors.tertiary,
    },
  ];

  void _clearAll() {
    setState(() {
      _activities.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notifications cleared')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Activity & Notifications'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.safePop('/dashboard'),
        ),
        actions: [
          if (_activities.isNotEmpty)
            TextButton(
              onPressed: _clearAll,
              child: const Text('Clear All'),
            ),
        ],
      ),
      body: _activities.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined,
                      size: 54, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  const Text('No recent notifications',
                      style:
                          TextStyle(color: AppColors.tertiary, fontSize: 15)),
                ],
              ),
            )
          : ListView.separated(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              itemCount: _activities.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final act = _activities[index];
                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (act['color'] as Color).withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(act['icon'] as IconData,
                          color: act['color'] as Color, size: 22),
                    ),
                    title: Text(act['title'] as String,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(act['subtitle'] as String,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.tertiary)),
                    ),
                    trailing: Text(act['time'] as String,
                        style: Theme.of(context).textTheme.labelSmall),
                  ),
                );
              },
            ),
    );
  }
}
