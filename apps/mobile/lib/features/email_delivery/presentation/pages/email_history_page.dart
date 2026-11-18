import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme.dart';
import '../../../../core/utils/navigation_utils.dart';
import '../../../../core/state/app_state.dart';

class EmailHistoryPage extends ConsumerWidget {
  const EmailHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deliveries = ref.watch(emailDeliveryProvider);
    final hasFailed = deliveries.any((d) => d.status == 'failed');
    final deliveredCount = deliveries.where((d) => d.status == 'delivered').length;
    final failedCount = deliveries.where((d) => d.status == 'failed').length;
    final deliveryRate = deliveries.isNotEmpty ? ((deliveredCount / deliveries.length) * 100).toStringAsFixed(1) : '100.0';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Email Delivery Logs'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.safePop('/settings'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Email Settings',
            onPressed: () => context.push('/email-settings'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overall Stats
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.surfaceContainerHigh),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _EmailStat(val: '${deliveries.length}', label: 'Dispatches', color: AppColors.secondary),
                  _EmailStat(val: '$deliveredCount', label: 'Delivered', color: AppColors.primary),
                  _EmailStat(val: '$failedCount', label: 'Failed', color: hasFailed ? AppColors.error : AppColors.tertiary),
                  _EmailStat(val: '$deliveryRate%', label: 'Delivery Rate', color: const Color(0xFF0369A1)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Recent Dispatches', style: Theme.of(context).textTheme.titleLarge),
                if (hasFailed)
                  TextButton.icon(
                    onPressed: () {
                      ref.read(emailDeliveryProvider.notifier).retryFailed();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Retrying dispatch for failed recipients...'),
                          backgroundColor: AppColors.primary,
                        ),
                      );
                    },
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: Text('Retry Failed ($failedCount)'),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            if (deliveries.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 40),
                alignment: Alignment.center,
                child: const Text('No email delivery history yet.', style: TextStyle(color: AppColors.tertiary)),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: deliveries.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item = deliveries[index];
                  final isDelivered = item.status == 'delivered';
                  final isFailed = item.status == 'failed';

                  return Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDelivered
                              ? AppColors.softMint
                              : isFailed
                                  ? AppColors.errorContainer
                                  : AppColors.surfaceContainerLow,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isDelivered
                              ? Icons.mark_email_read_rounded
                              : isFailed
                                  ? Icons.mail_lock_rounded
                                  : Icons.send_rounded,
                          color: isDelivered
                              ? AppColors.primary
                              : isFailed
                                  ? AppColors.error
                                  : AppColors.secondary,
                          size: 20,
                        ),
                      ),
                      title: Text(item.studentName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 2),
                          Text('${item.email} • ${item.timeStr}', style: const TextStyle(fontSize: 12)),
                          if (isFailed && item.error != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                'Error: ${item.error}',
                                style: const TextStyle(color: AppColors.error, fontSize: 11, fontWeight: FontWeight.w500),
                              ),
                            ),
                        ],
                      ),
                      trailing: isFailed
                          ? IconButton(
                              icon: const Icon(Icons.refresh_rounded, color: AppColors.error),
                              tooltip: 'Resend',
                              onPressed: () {
                                ref.read(emailDeliveryProvider.notifier).resendSingle(item.id);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Resending scorecard to ${item.email}...')),
                                );
                              },
                            )
                          : Text(
                              item.status.toUpperCase(),
                              style: TextStyle(
                                color: isDelivered ? AppColors.primary : AppColors.tertiary,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
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

class _EmailStat extends StatelessWidget {
  final String val;
  final String label;
  final Color color;

  const _EmailStat({required this.val, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(val, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.tertiary)),
      ],
    );
  }
}
