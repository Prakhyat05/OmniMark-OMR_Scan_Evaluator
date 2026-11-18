import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme.dart';
import '../../../../core/state/app_state.dart';

class InstituteSettingsPage extends ConsumerStatefulWidget {
  const InstituteSettingsPage({super.key});

  @override
  ConsumerState<InstituteSettingsPage> createState() =>
      _InstituteSettingsPageState();
}

class _InstituteSettingsPageState extends ConsumerState<InstituteSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _orgNameController;
  late TextEditingController _slugController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;

  bool _isSaving = false;
  bool _initialized = false;

  @override
  void dispose() {
    _orgNameController.dispose();
    _slugController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _initFields(InstituteSettingsModel settings) {
    if (_initialized) return;
    _initialized = true;

    _orgNameController = TextEditingController(text: settings.orgName);
    _slugController = TextEditingController(text: settings.tenantSlug);
    _emailController = TextEditingController(text: settings.email);
    _phoneController = TextEditingController(text: settings.phone);
    _addressController = TextEditingController(text: settings.address);
  }

  void _saveSettings() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);
    await Future.delayed(const Duration(milliseconds: 500));

    final current = ref.read(settingsProvider);
    final updated = current.copyWith(
      orgName: _orgNameController.text.trim(),
      tenantSlug: _slugController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
    );

    ref.read(settingsProvider.notifier).updateSettings(updated);

    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Institute profile settings updated successfully!'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    _initFields(settings);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Institute Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline_rounded),
            tooltip: 'User Profile',
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo & Brand Box
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.surfaceContainerHigh),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.school_rounded,
                          color: Colors.white, size: 36),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _orgNameController.text.isNotEmpty
                                ? _orgNameController.text
                                : 'Institution Name',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 16),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Tenant Slug: ${_slugController.text}',
                            style: const TextStyle(
                                color: AppColors.tertiary, fontSize: 12),
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Choose institute logo from device gallery')),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                            ),
                            child: const Text('Change Logo',
                                style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Text('Organization Profile',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 14),

              // Institute Name
              Text('Institute Full Name *',
                  style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 6),
              TextFormField(
                controller: _orgNameController,
                decoration: const InputDecoration(
                    hintText: 'e.g. Apex International Academy'),
                validator: (val) {
                  if (val == null || val.trim().isEmpty)
                    return 'Please enter the institute name';
                  return null;
                },
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),

              // Tenant Slug
              Text('Tenant Slug / Workspace Code *',
                  style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 6),
              TextFormField(
                controller: _slugController,
                decoration:
                    const InputDecoration(hintText: 'e.g. apex-academy'),
                validator: (val) {
                  if (val == null || val.trim().isEmpty)
                    return 'Tenant slug is required';
                  return null;
                },
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),

              // Official Email
              Text('Official Contact Email *',
                  style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 6),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  hintText: 'admin@institute.edu',
                  prefixIcon:
                      Icon(Icons.email_outlined, color: AppColors.outline),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty)
                    return 'Contact email is required';
                  final emailRegex =
                      RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                  if (!emailRegex.hasMatch(val.trim()))
                    return 'Please enter a valid email address';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Phone
              Text('Contact Phone Number *',
                  style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 6),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  hintText: '+91 98765 43210',
                  prefixIcon:
                      Icon(Icons.phone_outlined, color: AppColors.outline),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty)
                    return 'Phone number is required';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Address
              Text('Campus / Office Address *',
                  style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 6),
              TextFormField(
                controller: _addressController,
                maxLines: 2,
                decoration: const InputDecoration(
                    hintText: 'Full postal address of campus...'),
                validator: (val) {
                  if (val == null || val.trim().isEmpty)
                    return 'Campus address is required';
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Additional Settings Links
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.mail_outline_rounded,
                          color: AppColors.primary),
                      title: const Text('Email & SMTP Gateway',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14)),
                      subtitle: const Text(
                          'Configure custom outgoing report server',
                          style: TextStyle(fontSize: 12)),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded,
                          size: 14, color: AppColors.outline),
                      onTap: () => context.push('/email-settings'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.history_edu_rounded,
                          color: AppColors.primary),
                      title: const Text('Email Delivery Logs',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14)),
                      subtitle: const Text(
                          'View sent, pending & bounced scorecards',
                          style: TextStyle(fontSize: 12)),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded,
                          size: 14, color: AppColors.outline),
                      onTap: () => context.push('/email-history'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.help_outline_rounded,
                          color: AppColors.primary),
                      title: const Text('Help & Documentation',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14)),
                      subtitle: const Text('OMR sheet templates and guides',
                          style: TextStyle(fontSize: 12)),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded,
                          size: 14, color: AppColors.outline),
                      onTap: () => context.push('/help-support'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveSettings,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.save_rounded),
                  label:
                      Text(_isSaving ? 'Saving Changes...' : 'Save Settings'),
                ),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}
