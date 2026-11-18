import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../app/theme.dart';
import '../../../../core/utils/navigation_utils.dart';
import '../../../../core/state/app_state.dart';

class CreateExamPage extends ConsumerStatefulWidget {
  const CreateExamPage({super.key});

  @override
  ConsumerState<CreateExamPage> createState() => _CreateExamPageState();
}

class _CreateExamPageState extends ConsumerState<CreateExamPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController(text: 'Science Diagnostic Test');
  final _correctMarksController = TextEditingController(text: '4.0');
  final _wrongMarksController = TextEditingController(text: '-1.0');

  String _selectedSubject = 'Science';
  String _selectedClass = 'Grade 10 - Section A';
  int _questionCount = 50; // Default to 50 questions
  String _selectedPreset = '+4 / -1';

  final List<int> _presetQuestionCounts = [20, 45, 50, 75, 90, 100, 150, 180, 200];

  @override
  void dispose() {
    _titleController.dispose();
    _correctMarksController.dispose();
    _wrongMarksController.dispose();
    super.dispose();
  }

  void _applyMarkingPreset(String preset) {
    setState(() {
      _selectedPreset = preset;
      if (preset == '+4 / -1') {
        _correctMarksController.text = '4.0';
        _wrongMarksController.text = '-1.0';
      } else if (preset == '+1 / 0') {
        _correctMarksController.text = '1.0';
        _wrongMarksController.text = '0.0';
      } else if (preset == '+2 / -0.5') {
        _correctMarksController.text = '2.0';
        _wrongMarksController.text = '-0.5';
      }
    });
  }

  void _proceedToAnswerKey() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final newId = 'exam_${DateTime.now().millisecondsSinceEpoch}';
    final sampleOpts = ['1', '2', '3', '4'];
    final Map<int, List<String>> initialKey = {};
    for (int i = 1; i <= _questionCount; i++) {
      initialKey[i] = [sampleOpts[(i * 3 + 1) % 4]];
    }

    final Map<String, dynamic> templateCfg = {
      'template_id': 'universal_200q_master',
      'name': 'Universal 200Q Objective Sheet',
      'total_questions': _questionCount,
      'max_template_questions': 200,
      'slicing_range': '1..$_questionCount',
    };

    final newExam = ExamModel(
      id: newId,
      title: _titleController.text.trim(),
      subject: _selectedSubject,
      className: _selectedClass,
      date: DateFormat('dd MMM yyyy').format(DateTime.now()),
      questionsCount: _questionCount,
      correctMarks: double.tryParse(_correctMarksController.text.trim()) ?? 4.0,
      wrongMarks: double.tryParse(_wrongMarksController.text.trim()) ?? -1.0,
      status: 'draft',
      scannedCount: 0,
      totalStudents: 50,
      answerKey: initialKey,
      templateConfig: templateCfg,
      templatePreviewBase64: null,
    );

    ref.read(examsProvider.notifier).addExam(newExam);
    ref.read(activeExamIdProvider.notifier).state = newId;

    context.push('/answer-key-setup');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Create New Assessment'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.safePop('/exams'),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 60),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Assessment Details', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 14),

              // Exam Title
              Text('Exam / Test Title *', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 6),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  hintText: 'e.g. Mathematics Weekly Assessment 05',
                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Exam title is required';
                  if (val.trim().length < 3) return 'Title must be at least 3 characters';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Subject & Class
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Subject *', style: Theme.of(context).textTheme.labelLarge),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          value: _selectedSubject,
                          isExpanded: true,
                          items: ['Mathematics', 'Physics', 'Chemistry', 'Biology', 'Science', 'English']
                              .map((s) => DropdownMenuItem(value: s, child: Text(s, overflow: TextOverflow.ellipsis)))
                              .toList(),
                          onChanged: (v) => setState(() => _selectedSubject = v!),
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Class / Batch *', style: Theme.of(context).textTheme.labelLarge),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          value: _selectedClass,
                          isExpanded: true,
                          items: ['Grade 10 - Section A', 'Grade 10 - Section B', 'Grade 11 - Science', 'Grade 12 - Science', 'Batch A', 'Batch B']
                              .map((c) => DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis)))
                              .toList(),
                          onChanged: (v) => setState(() => _selectedClass = v!),
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Dynamic Question Count Selector
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total Questions in this Test *', style: Theme.of(context).textTheme.titleMedium),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$_questionCount Questions',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Standard 200Q Sheet is automatically sliced to questions 1..$_questionCount. Unused rows are ignored.',
                style: const TextStyle(color: AppColors.tertiary, fontSize: 12),
              ),
              const SizedBox(height: 12),

              // Preset Chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _presetQuestionCounts.map((count) {
                  final isSelected = _questionCount == count;
                  return ChoiceChip(
                    label: Text('$count Qs'),
                    selected: isSelected,
                    onSelected: (val) {
                      if (val) setState(() => _questionCount = count);
                    },
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.onSurface,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),

              // Custom Slider
              Slider(
                value: _questionCount.toDouble(),
                min: 5,
                max: 200,
                divisions: 39,
                label: '$_questionCount Qs',
                activeColor: AppColors.primary,
                onChanged: (val) => setState(() => _questionCount = val.round()),
              ),
              const SizedBox(height: 24),

              // Marking Scheme Presets
              Text('Marking Scheme *', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: ['+4 / -1', '+1 / 0', '+2 / -0.5', 'Custom'].map((p) {
                  final isSel = _selectedPreset == p;
                  return ChoiceChip(
                    label: Text(p),
                    selected: isSel,
                    onSelected: (val) {
                      if (val) _applyMarkingPreset(p);
                    },
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSel ? Colors.white : AppColors.onSurface,
                      fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Marks for Correct (+)', style: Theme.of(context).textTheme.labelMedium),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _correctMarksController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            suffixText: 'pts',
                          ),
                          onChanged: (_) => setState(() => _selectedPreset = 'Custom'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Penalty for Wrong (-)', style: Theme.of(context).textTheme.labelMedium),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _wrongMarksController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            suffixText: 'pts',
                          ),
                          onChanged: (_) => setState(() => _selectedPreset = 'Custom'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 36),

              // Action Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _proceedToAnswerKey,
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: const Text('Configure Answer Key', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
