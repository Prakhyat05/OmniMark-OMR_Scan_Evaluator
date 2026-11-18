import 'package:flutter/material.dart';
import '../../../../app/theme.dart';
import '../../../../core/utils/navigation_utils.dart';

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Help & Scanning Guide'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.safePop('/settings'),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tips Banner
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.softMint,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.secondaryContainer),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb_outline_rounded, color: AppColors.primary, size: 24),
                      SizedBox(width: 8),
                      Text('Best OMR Capture Practices', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.secondary)),
                    ],
                  ),
                  SizedBox(height: 12),
                  _TipBullet(text: 'Place the OMR sheet on a dark, non-reflective flat surface.'),
                  _TipBullet(text: 'Ensure the 4 black square registration markers are within the on-screen camera frame.'),
                  _TipBullet(text: 'Avoid harsh phone shadows by holding the camera slightly angled with good ambient lighting.'),
                  _TipBullet(text: 'Use dark blue or black ballpoint pens for cleanest bubble fill density recognition.'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Text('Frequently Asked Questions', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),

            const _FaqTile(
              question: 'How does the automated bubble scoring work?',
              answer: 'The system uses computer vision to detect the 4 registration markers, warps perspective into a standard grid, and calculates the darkness and circular fill ratio for each bubble ROI.',
            ),
            const _FaqTile(
              question: 'What happens if a student marks two bubbles?',
              answer: 'The sheet is automatically routed to the Review Required Queue with a low-confidence alert for teacher verification before results are finalized.',
            ),
            const _FaqTile(
              question: 'Are report card emails sent automatically?',
              answer: 'No, report card emails are only dispatched after an authorized teacher or admin approves and finalizes the exam result session.',
            ),
            const _FaqTile(
              question: 'Can I import answer keys and student lists from Excel/CSV?',
              answer: 'Yes! Both student rosters and answer keys support 1-tap bulk CSV upload formats.',
            ),
            const SizedBox(height: 24),

            // Contact Support
            Text('Need Technical Assistance?', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    _SupportRow(icon: Icons.email_outlined, label: 'Email Support', val: 'support@omrplatform.edu'),
                    Divider(height: 24),
                    _SupportRow(icon: Icons.phone_outlined, label: 'Helpline', val: '+91 1800 123 4567'),
                    Divider(height: 24),
                    _SupportRow(icon: Icons.forum_outlined, label: 'Live Chat', val: 'Mon-Sat 9:00 AM - 6:00 PM IST'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _TipBullet extends StatelessWidget {
  final String text;
  const _TipBullet({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 16)),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13, height: 1.35))),
        ],
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  final String question;
  final String answer;

  const _FaqTile({required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        title: Text(question, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(answer, style: const TextStyle(color: AppColors.tertiary, fontSize: 13, height: 1.4)),
          ),
        ],
      ),
    );
  }
}

class _SupportRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String val;

  const _SupportRow({required this.icon, required this.label, required this.val});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.tertiary)),
            const SizedBox(height: 2),
            Text(val, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }
}
