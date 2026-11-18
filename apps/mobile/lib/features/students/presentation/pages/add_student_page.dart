import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme.dart';
import '../../../../core/utils/navigation_utils.dart';
import '../../../../core/state/app_state.dart';

class AddStudentPage extends ConsumerStatefulWidget {
  const AddStudentPage({super.key});

  @override
  ConsumerState<AddStudentPage> createState() => _AddStudentPageState();
}

class _AddStudentPageState extends ConsumerState<AddStudentPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _rollController = TextEditingController();
  final _parentNameController = TextEditingController();
  final _parentEmailController = TextEditingController();
  final _phoneController = TextEditingController();

  String _selectedClass = 'Grade 10 - Section A';
  String _relationship = 'Father';

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _rollController.dispose();
    _parentNameController.dispose();
    _parentEmailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _saveStudent() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final newStudent = StudentModel(
      id: 'stu_${DateTime.now().millisecondsSinceEpoch}',
      name: _nameController.text.trim(),
      code: _codeController.text.trim().toUpperCase(),
      roll: _rollController.text.trim(),
      className: _selectedClass,
      parentName: _parentNameController.text.trim(),
      parentEmail: _parentEmailController.text.trim(),
      parentPhone: _phoneController.text.trim().isNotEmpty
          ? _phoneController.text.trim()
          : '+91 98765 43210',
      relationship: _relationship,
      examsCount: 0,
      avgScore: 'N/A',
    );

    ref.read(studentsProvider.notifier).addStudent(newStudent);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Student "${_nameController.text.trim()}" enrolled successfully!'),
        backgroundColor: AppColors.primary,
      ),
    );
    context.safePop('/students');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Add New Student'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.safePop('/students'),
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
              Text('Student Information',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 14),

              // Student Full Name
              Text('Student Full Name *',
                  style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nameController,
                decoration:
                    const InputDecoration(hintText: 'e.g. Aarav Sharma'),
                validator: (val) {
                  if (val == null || val.trim().isEmpty)
                    return 'Student name is required';
                  if (val.trim().length < 2)
                    return 'Name must be at least 2 characters';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Student ID & Roll Number
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Student ID / Code *',
                            style: Theme.of(context).textTheme.labelLarge),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _codeController,
                          decoration:
                              const InputDecoration(hintText: 'e.g. STU1006'),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty)
                              return 'Student ID is required';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Roll Number *',
                            style: Theme.of(context).textTheme.labelLarge),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _rollController,
                          keyboardType: TextInputType.number,
                          decoration:
                              const InputDecoration(hintText: 'e.g. 106'),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty)
                              return 'Roll number is required';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Class Selection
              Text('Class / Section *',
                  style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _selectedClass,
                items: [
                  'Grade 10 - Section A',
                  'Grade 10 - Section B',
                  'Grade 12 - Science'
                ]
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedClass = v!),
              ),
              const SizedBox(height: 28),

              Text('Parent / Guardian Details',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 6),
              Text(
                'Assessment reports and performance cards will be sent to this email.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 14),

              // Parent Name
              Text('Parent / Guardian Name *',
                  style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 6),
              TextFormField(
                controller: _parentNameController,
                decoration:
                    const InputDecoration(hintText: 'e.g. Rajesh Sharma'),
                validator: (val) {
                  if (val == null || val.trim().isEmpty)
                    return 'Parent name is required';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Parent Email
              Text('Parent Email Address *',
                  style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 6),
              TextFormField(
                controller: _parentEmailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  hintText: 'parent.email@example.com',
                  prefixIcon:
                      Icon(Icons.email_outlined, color: AppColors.outline),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty)
                    return 'Parent email is required';
                  final emailRegex =
                      RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                  if (!emailRegex.hasMatch(val.trim()))
                    return 'Please enter a valid email address';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Phone Number
              Text('Parent Phone Number',
                  style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 6),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  hintText: '+91 98765 11223',
                  prefixIcon:
                      Icon(Icons.phone_outlined, color: AppColors.outline),
                ),
              ),
              const SizedBox(height: 16),

              // Relationship
              Text('Relationship',
                  style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _relationship,
                items: ['Father', 'Mother', 'Guardian', 'Other']
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (v) => setState(() => _relationship = v!),
              ),
              const SizedBox(height: 36),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => context.safePop('/students'),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _saveStudent,
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Save Student Profile'),
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
