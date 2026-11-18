import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme.dart';
import '../../../../core/utils/navigation_utils.dart';
import '../../../../core/state/app_state.dart';

class EmailReportCardPage extends ConsumerStatefulWidget {
  const EmailReportCardPage({super.key});

  @override
  ConsumerState<EmailReportCardPage> createState() =>
      _EmailReportCardPageState();
}

class _EmailReportCardPageState extends ConsumerState<EmailReportCardPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _emailController;
  late TextEditingController _subjectController;
  late TextEditingController _customNoteController;

  bool _attachPdf = true;
  bool _includeLink = true;
  bool _isSending = false;
  bool _initialized = false;

  @override
  void dispose() {
    _emailController.dispose();
    _subjectController.dispose();
    _customNoteController.dispose();
    super.dispose();
  }

  void _initFields(ScanResultModel result, ExamModel exam) {
    if (_initialized) return;
    _initialized = true;

    _emailController = TextEditingController(text: result.parentEmail);
    _subjectController = TextEditingController(
      text: 'Official Assessment Report: ${result.studentName} - ${exam.title}',
    );
    _customNoteController = TextEditingController(
      text:
          'Dear Parent,\n\nPlease find attached the official assessment scorecard for ${result.studentName} in ${exam.title}. ${result.studentName} scored ${result.marksObtained.toStringAsFixed(1)}/${result.maximumMarks.toInt()} (${result.percentage}%).',
    );
  }

  void _sendEmail(ScanResultModel result, ExamModel exam) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSending = true);
    await Future.delayed(const Duration(milliseconds: 700));

    final newLog = EmailLogModel(
      id: 'mail_${DateTime.now().millisecondsSinceEpoch}',
      studentName: result.studentName,
      email: _emailController.text.trim(),
      examTitle: exam.title,
      status: 'delivered',
      timeStr: 'Just now',
    );

    ref.read(emailDeliveryProvider.notifier).queueEmail(newLog);

    if (mounted) {
      setState(() => _isSending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Report successfully emailed to ${_emailController.text.trim()}!'),
          backgroundColor: AppColors.primary,
        ),
      );
      context.safePop('/exam-results-summary');
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = ref.watch(selectedResultProvider);
    final exam = ref.watch(activeExamProvider);

    if (result == null || exam == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Send Report Card Email')),
        body: const Center(child: Text('No student result selected')),
      );
    }

    _initFields(result, exam);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Send Report Card Email'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.safePop('/exam-results-summary'),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Student & Exam Summary Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.surfaceContainerHigh),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: AppColors.softMint,
                      child: Icon(Icons.person, color: AppColors.primary),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${result.studentName} (${result.studentCode})',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 14)),
                          const SizedBox(height: 2),
                          Text(
                              '${exam.title} • ${result.marksObtained.toStringAsFixed(1)}/${result.maximumMarks.toInt()} (${result.percentage}%)',
                              style: const TextStyle(
                                  color: AppColors.tertiary, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Text('Recipient Information',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),

              // Recipient Email
              Text('Parent Email Address *',
                  style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 6),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  prefixIcon:
                      Icon(Icons.email_outlined, color: AppColors.outline),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty)
                    return 'Recipient email is required';
                  final emailRegex =
                      RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                  if (!emailRegex.hasMatch(val.trim()))
                    return 'Please enter a valid email address';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Subject
              Text('Email Subject Line *',
                  style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 6),
              TextFormField(
                controller: _subjectController,
                decoration: const InputDecoration(),
                validator: (val) {
                  if (val == null || val.trim().isEmpty)
                    return 'Subject line is required';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Custom Note
              Text('Message / Note to Parent *',
                  style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 6),
              TextFormField(
                controller: _customNoteController,
                maxLines: 4,
                decoration: const InputDecoration(),
                validator: (val) {
                  if (val == null || val.trim().isEmpty)
                    return 'Message note is required';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Delivery Options
              Text('Attachment Settings',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 10),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Attach Official PDF Report Card',
                    style:
                        TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: const Text(
                    'Includes institutional watermarks and QR code',
                    style: TextStyle(fontSize: 12)),
                value: _attachPdf,
                onChanged: (v) => setState(() => _attachPdf = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Include Web Result Verification Link',
                    style:
                        TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: const Text(
                    'Allows parents to view interactive breakdown online',
                    style: TextStyle(fontSize: 12)),
                value: _includeLink,
                onChanged: (v) => setState(() => _includeLink = v),
              ),
              const SizedBox(height: 32),

              // Send Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSending ? null : () => _sendEmail(result, exam),
                  icon: _isSending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.send_rounded),
                  label: Text(_isSending
                      ? 'Delivering Report...'
                      : 'Send Report Card Now'),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
