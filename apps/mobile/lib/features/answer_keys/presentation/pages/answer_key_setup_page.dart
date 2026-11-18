import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/theme.dart';
import '../../../../core/utils/navigation_utils.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/omr/offline_scan_engine.dart';

class AnswerKeySetupPage extends ConsumerStatefulWidget {
  const AnswerKeySetupPage({super.key});

  @override
  ConsumerState<AnswerKeySetupPage> createState() => _AnswerKeySetupPageState();
}

class _AnswerKeySetupPageState extends ConsumerState<AnswerKeySetupPage> {
  final Map<int, String> _answers = {};
  final Set<int> _bonusQuestions = {};
  final Set<int> _droppedQuestions = {};
  bool _initialized = false;
  bool _isScanningKey = false;
  final ImagePicker _picker = ImagePicker();
  final OfflineOMRScanEngine _scanEngine = OfflineOMRScanEngine();

  void _initFromExam(ExamModel exam) {
    if (_initialized) return;
    _initialized = true;

    const sampleOpts = ['1', '2', '3', '4'];
    for (int i = 1; i <= exam.questionsCount; i++) {
      if (exam.answerKey.containsKey(i) && exam.answerKey[i]!.isNotEmpty) {
        final opt = exam.answerKey[i]!.first;
        // Convert legacy A..D to 1..4 if present
        if (opt == 'A') {
          _answers[i] = '1';
        } else if (opt == 'B') {
          _answers[i] = '2';
        } else if (opt == 'C') {
          _answers[i] = '3';
        } else if (opt == 'D') {
          _answers[i] = '4';
        } else {
          _answers[i] = opt;
        }
      } else {
        _answers[i] = sampleOpts[(i * 3 + 1) % 4];
      }
    }
    _bonusQuestions.addAll(exam.bonusQuestions);
    _droppedQuestions.addAll(exam.droppedQuestions);
  }

  void _saveAnswerKey({bool publish = true}) {
    final activeExam = ref.read(activeExamProvider);
    if (activeExam == null) return;

    final Map<int, List<String>> formatted = {};
    _answers.forEach((q, opt) {
      formatted[q] = [opt];
    });

    ref.read(examsProvider.notifier).updateAnswerKey(
          activeExam.id,
          formatted,
          bonus: _bonusQuestions,
          dropped: _droppedQuestions,
          publish: publish,
        );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(publish
            ? 'Answer Key locked & Exam published!'
            : 'Draft answer key saved.'),
        backgroundColor: AppColors.primary,
      ),
    );
    context.go('/exams');
  }

  /// Scans a physical master answer sheet using On-Device Offline Engine to auto-populate all answers
  Future<void> _scanMasterAnswerSheet(ImageSource source) async {
    final activeExam = ref.read(activeExamProvider);
    if (activeExam == null) return;

    try {
      final XFile? image =
          await _picker.pickImage(source: source, imageQuality: 100);
      if (image == null) return;

      setState(() => _isScanningKey = true);

      final Uint8List bytes = await image.readAsBytes();
      final scanResult = await _scanEngine.processImageBytes(
        imageBytes: bytes,
        totalQuestions: activeExam.questionsCount,
      );

      int filledCount = 0;
      setState(() {
        for (int q = 1; q <= activeExam.questionsCount; q++) {
          final detected = scanResult.detectedAnswers[q];
          if (detected != null && detected.isNotEmpty) {
            _answers[q] = detected;
            filledCount++;
          }
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Auto-filled $filledCount / ${activeExam.questionsCount} answers from Master Sheet!'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to read master sheet: $e'),
              backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isScanningKey = false);
      }
    }
  }

  void _bulkSetAnswers(String option) {
    final activeExam = ref.read(activeExamProvider);
    if (activeExam == null) return;

    setState(() {
      for (int i = 1; i <= activeExam.questionsCount; i++) {
        _answers[i] = option;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Set all ${activeExam.questionsCount} questions to Option $option'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeExam = ref.watch(activeExamProvider);

    if (activeExam == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Answer Key Setup')),
        body: const Center(child: Text('No active exam selected')),
      );
    }

    _initFromExam(activeExam);

    final totalQs = activeExam.questionsCount;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Answer Key Setup'),
            Text(
              '${activeExam.title} ($totalQs Questions)',
              style: const TextStyle(fontSize: 11, color: AppColors.tertiary),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.safePop('/create-exam'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_alt_rounded),
            tooltip: 'Scan Master OMR Sheet',
            onPressed: () => _scanMasterAnswerSheet(ImageSource.camera),
          ),
          IconButton(
            icon: const Icon(Icons.photo_library_rounded),
            tooltip: 'Upload Master Sheet Image',
            onPressed: () => _scanMasterAnswerSheet(ImageSource.gallery),
          ),
        ],
      ),
      body: _isScanningKey
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Analyzing Master Answer Sheet on-device...',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            )
          : Column(
              children: [
                // Quick Action Bar
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  color: AppColors.surfaceContainerLow,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Quick Pattern:',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold)),
                      Row(
                        children: ['1', '2', '3', '4'].map((opt) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10),
                              ),
                              onPressed: () => _bulkSetAnswers(opt),
                              child: Text(opt,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),

                // Question Grid List
                Expanded(
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                    itemCount: totalQs,
                    itemBuilder: (context, idx) {
                      final qNum = idx + 1;
                      final currentOpt = _answers[qNum] ?? '1';
                      final isBonus = _bonusQuestions.contains(qNum);
                      final isDropped = _droppedQuestions.contains(qNum);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Q$qNum',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14),
                                ),
                              ),
                              Expanded(
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: ['1', '2', '3', '4'].map((opt) {
                                    final isPicked = currentOpt == opt &&
                                        !isBonus &&
                                        !isDropped;
                                    return GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _answers[qNum] = opt;
                                          _bonusQuestions.remove(qNum);
                                          _droppedQuestions.remove(qNum);
                                        });
                                      },
                                      child: Container(
                                        width: 38,
                                        height: 38,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: isPicked
                                              ? AppColors.primary
                                              : AppColors.surfaceContainerLow,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: isPicked
                                                ? AppColors.primary
                                                : Colors.grey.shade400,
                                            width: isPicked ? 2 : 1,
                                          ),
                                        ),
                                        child: Text(
                                          opt,
                                          style: TextStyle(
                                            color: isPicked
                                                ? Colors.white
                                                : AppColors.onSurface,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, -4)),
          ],
        ),
        child: SizedBox(
          height: 48,
          child: ElevatedButton.icon(
            onPressed: () => _saveAnswerKey(publish: true),
            icon: const Icon(Icons.check_circle_outline_rounded),
            label: const Text('Lock Answer Key & Publish Exam',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }
}
