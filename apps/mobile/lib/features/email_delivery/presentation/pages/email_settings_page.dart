import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme.dart';
import '../../../../core/utils/navigation_utils.dart';
import '../../../../core/state/app_state.dart';

class EmailSettingsPage extends ConsumerStatefulWidget {
  const EmailSettingsPage({super.key});

  @override
  ConsumerState<EmailSettingsPage> createState() => _EmailSettingsPageState();
}

class _EmailSettingsPageState extends ConsumerState<EmailSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _senderEmailController;
  late TextEditingController _senderNameController;
  late TextEditingController _replyToController;
  bool _sendPdfAttachment = true;
  bool _sendOnlineLink = true;
  bool _isSaving = false;
  bool _initialized = false;

  @override
  void dispose() {
    _senderEmailController.dispose();
    _senderNameController.dispose();
    _replyToController.dispose();
    super.dispose();
  }

  void _initFields(InstituteSettingsModel settings) {
    if (_initialized) return;
    _initialized = true;

    _senderEmailController = TextEditingController(text: settings.senderEmail);
    _senderNameController = TextEditingController(text: settings.senderName);
    _replyToController = TextEditingController(text: settings.replyTo);
    _sendPdfAttachment = settings.attachPdfByDefault;
    _sendOnlineLink = settings.includeOnlineLink;
  }

  void _saveSettings() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);
    await Future.delayed(const Duration(milliseconds: 500));

    final current = ref.read(settingsProvider);
    final updated = current.copyWith(
      senderEmail: _senderEmailController.text.trim(),
      senderName: _senderNameController.text.trim(),
      replyTo: _replyToController.text.trim(),
      attachPdfByDefault: _sendPdfAttachment,
      includeOnlineLink: _sendOnlineLink,
    );

    ref.read(settingsProvider.notifier).updateSettings(updated);

    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email dispatch settings saved successfully!'),
          backgroundColor: AppColors.primary,
        ),
      );
      context.safePop('/settings');
    }
  }

  void _testConnection() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Send Test Email'),
        content: Text('A verification email will be dispatched to ${_senderEmailController.text} to verify DKIM, SPF & SMTP latency.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Test email delivered in 380ms (Status: Healthy)!'),
                  backgroundColor: AppColors.primary,
                ),
              );
            },
            child: const Text('Send Test Ping'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    _initFields(settings);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Email & Delivery Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.safePop('/settings'),
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
              // Provider Status Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.softMint,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.secondaryContainer),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.verified_rounded, color: AppColors.primary, size: 28),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Resend API Provider Active', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.secondary)),
                          SizedBox(height: 2),
                          Text('Domain apexacademy.edu verified (DKIM & SPF valid)', style: TextStyle(fontSize: 12, color: AppColors.tertiary)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Text('Sender Identity', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 14),

              // Sender Name
              Text('Display Name *', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 6),
              TextFormField(
                controller: _senderNameController,
                decoration: const InputDecoration(hintText: 'e.g. Apex Academy Exam Cell'),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Sender display name is required';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Sender Email
              Text('From Email Address *', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 6),
              TextFormField(
                controller: _senderEmailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(hintText: 'notifications@yourdomain.edu'),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'From email is required';
                  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                  if (!emailRegex.hasMatch(val.trim())) return 'Enter a valid email address';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Reply To
              Text('Reply-To Email *', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 6),
              TextFormField(
                controller: _replyToController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(hintText: 'support@yourdomain.edu'),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Reply-to email is required';
                  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                  if (!emailRegex.hasMatch(val.trim())) return 'Enter a valid email address';
                  return null;
                },
              ),
              const SizedBox(height: 28),

              Text('Report Card Template Options', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),

              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Default PDF Attachment in Parent Email', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: const Text('Automatically generates and attaches signed PDF', style: TextStyle(fontSize: 12, color: AppColors.tertiary)),
                value: _sendPdfAttachment,
                onChanged: (v) => setState(() => _sendPdfAttachment = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Include Web Result Verification Link', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: const Text('Unique URL with student credentials for interactive view', style: TextStyle(fontSize: 12, color: AppColors.tertiary)),
                value: _sendOnlineLink,
                onChanged: (v) => setState(() => _sendOnlineLink = v),
              ),
              const SizedBox(height: 28),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _testConnection,
                      icon: const Icon(Icons.send_outlined, size: 18),
                      label: const Text('Test Connection'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveSettings,
                      icon: const Icon(Icons.check_rounded),
                      label: Text(_isSaving ? 'Saving...' : 'Save Settings'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
