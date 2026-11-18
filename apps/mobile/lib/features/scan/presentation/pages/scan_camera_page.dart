import 'dart:convert';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../app/theme.dart';
import '../../../../core/utils/navigation_utils.dart';
import '../../../../core/utils/evaluation_engine.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/omr/offline_scan_engine.dart';
import '../../../../core/database/local_database.dart';

class ScanCameraPage extends ConsumerStatefulWidget {
  const ScanCameraPage({super.key});

  @override
  ConsumerState<ScanCameraPage> createState() => _ScanCameraPageState();
}

class _ScanCameraPageState extends ConsumerState<ScanCameraPage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isCameraInitialized = false;
  bool _isPermissionDenied = false;

  final ImagePicker _picker = ImagePicker();
  late AnimationController _laserController;
  late Animation<double> _laserAnimation;

  bool _isFlashOn = false;
  bool _isProcessing = false;
  String _processingStatus = '';

  final OfflineOMRScanEngine _scanEngine = OfflineOMRScanEngine();
  final LocalOMRDatabase _localDb = LocalOMRDatabase();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _laserAnimation = Tween<double>(begin: 0.08, end: 0.92).animate(
      CurvedAnimation(parent: _laserController, curve: Curves.easeInOut),
    );

    _initCameraWithPermission();
  }

  Future<void> _initCameraWithPermission() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      try {
        _cameras = await availableCameras();
        if (_cameras.isNotEmpty) {
          final camera = _cameras.firstWhere(
            (c) => c.lensDirection == CameraLensDirection.back,
            orElse: () => _cameras.first,
          );

          _cameraController = CameraController(
            camera,
            ResolutionPreset.high,
            enableAudio: false,
            imageFormatGroup: ImageFormatGroup.jpeg,
          );

          await _cameraController!.initialize();
          if (mounted) {
            setState(() {
              _isCameraInitialized = true;
              _isPermissionDenied = false;
            });
          }
        }
      } catch (e) {
        debugPrint('Camera init error: $e');
      }
    } else {
      if (mounted) {
        setState(() => _isPermissionDenied = true);
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _laserController.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _toggleFlash() async {
    if (_cameraController != null && _cameraController!.value.isInitialized) {
      setState(() => _isFlashOn = !_isFlashOn);
      await _cameraController!
          .setFlashMode(_isFlashOn ? FlashMode.torch : FlashMode.off);
    }
  }

  /// Master On-Device Processing Pipeline
  Future<void> _processImageBytes(Uint8List bytes, String imagePath) async {
    final activeExam = ref.read(activeExamProvider);
    if (activeExam == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No active assessment selected'),
            backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
      _processingStatus = 'Aligning & Grading On-Device...';
    });

    try {
      final int totalQs = activeExam.questionsCount;

      // Extract simplified answer key map [Q: Option]
      final Map<int, String> cleanKey = {};
      activeExam.answerKey.forEach((k, v) {
        if (v.isNotEmpty) cleanKey[k] = v.first;
      });

      // Execute On-Device Scan Engine (< 50ms)
      final scanResult = await _scanEngine.processImageBytes(
        imageBytes: bytes,
        totalQuestions: totalQs,
        answerKey: cleanKey,
      );

      // Match student by 6-digit roll code
      final students = ref.read(studentsProvider);
      final matchedStudent = students.firstWhere(
        (s) =>
            s.code == scanResult.studentCode ||
            s.roll == scanResult.studentCode,
        orElse: () => StudentModel(
          id: 'temp_${scanResult.studentCode}',
          name: 'Student ${scanResult.studentCode}',
          code: scanResult.studentCode,
          roll: scanResult.studentCode,
          className: activeExam.className,
          parentName: 'Parent of ${scanResult.studentCode}',
          parentEmail: 'parent@example.com',
          parentPhone: '+91 98765 43210',
        ),
      );

      final summary = scanResult.evaluationSummary;
      final double totalScore = summary?.totalScore ?? 0.0;
      final double maxScore =
          summary?.maxPossibleScore ?? (totalQs * activeExam.correctMarks);
      final double percentage = summary?.percentage ?? 0.0;
      final int correctCount = summary?.correctCount ?? 0;
      final int wrongCount = summary?.wrongCount ?? 0;
      final int unattemptedCount = summary?.unattemptedCount ?? 0;
      final bool needsReview = scanResult.needsReviewQuestions.isNotEmpty;

      final newResultId = 'res_${DateTime.now().millisecondsSinceEpoch}';

      // Build AnswerItemResult list
      final List<AnswerItemResult> answers = [];
      for (int q = 1; q <= totalQs; q++) {
        final detected = scanResult.detectedAnswers[q];
        final isFlagged = scanResult.needsReviewQuestions.contains(q);
        final correctOpt = cleanKey[q];
        final bool? isCorrect =
            detected == null ? null : (detected == correctOpt);
        final double marks = isCorrect == true
            ? activeExam.correctMarks
            : (detected == null ? 0.0 : activeExam.wrongMarks);

        answers.add(AnswerItemResult(
          questionNumber: q,
          detectedOption: detected,
          correctOptions: correctOpt != null ? [correctOpt] : [],
          isCorrect: isCorrect,
          isMultiple: isFlagged,
          isUncertain: isFlagged,
          confidence: isFlagged ? 0.65 : 0.99,
          marksAwarded: marks,
        ));
      }

      final String? base64Annotated = scanResult.annotatedImageBytes != null
          ? base64Encode(scanResult.annotatedImageBytes!)
          : null;

      // Construct ScanResultModel
      final resultModel = ScanResultModel(
        id: newResultId,
        examId: activeExam.id,
        studentCode: scanResult.studentCode,
        studentName: matchedStudent.name,
        studentRoll: matchedStudent.roll,
        studentClass: activeExam.className,
        parentEmail: matchedStudent.parentEmail,
        marksObtained: totalScore,
        maximumMarks: maxScore,
        percentage: percentage,
        correctCount: correctCount,
        wrongCount: wrongCount,
        unattemptedCount: unattemptedCount,
        reviewRequired: needsReview,
        isReviewed: !needsReview,
        scannedAt: DateTime.now().toIso8601String(),
        answers: answers,
        annotatedPreviewBase64: base64Annotated,
      );

      // Save to Riverpod State
      ref.read(scanResultsProvider.notifier).addScanResult(resultModel);
      ref.read(examsProvider.notifier).incrementScannedCount(activeExam.id);

      // Save to Offline SQLite Database
      if (summary != null) {
        await _localDb.saveScanResult(
          id: newResultId,
          examId: activeExam.id,
          studentCode: scanResult.studentCode,
          studentName: matchedStudent.name,
          summary: summary,
          imagePath: imagePath,
          needsReview: needsReview,
        );
      }

      if (mounted) {
        _showInstantResultModal(resultModel, scanResult.processingDurationMs,
            scanResult.needsReviewQuestions, scanResult.annotatedImageBytes);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Processing failed: $e'),
              backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _captureFromCamera() async {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized ||
        _isProcessing) return;

    try {
      final XFile photo = await _cameraController!.takePicture();
      final bytes = await photo.readAsBytes();
      await _processImageBytes(bytes, photo.path);
    } catch (e) {
      debugPrint('Capture error: $e');
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
          source: ImageSource.gallery, imageQuality: 100);
      if (image != null) {
        final bytes = await image.readAsBytes();
        await _processImageBytes(bytes, image.path);
      }
    } catch (e) {
      debugPrint('Gallery pick error: $e');
    }
  }

  /// Instant Evaluation Overlay Dialog with Visual Evaluated Sheet Preview
  void _showInstantResultModal(ScanResultModel result, int durationMs,
      Set<int> flaggedQs, Uint8List? annotatedBytes) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade300),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded,
                            color: AppColors.primary, size: 14),
                        const SizedBox(width: 6),
                        Text('Processed in ${durationMs}ms (On-Device)',
                            style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Text(result.studentName,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              Text('Roll / Code: ${result.studentCode}',
                  style:
                      const TextStyle(color: AppColors.tertiary, fontSize: 13)),
              const SizedBox(height: 14),

              // Score Summary Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _scoreItem(
                        'TOTAL SCORE',
                        '${result.marksObtained.toStringAsFixed(1)}/${result.maximumMarks.toInt()}',
                        Colors.white),
                    _scoreItem(
                        'PERCENTAGE',
                        '${result.percentage.toStringAsFixed(1)}%',
                        const Color(0xFF78DC77)),
                    _scoreItem(
                        'CORRECT', '${result.correctCount}', Colors.white),
                    _scoreItem('WRONG', '${result.wrongCount}',
                        const Color(0xFFFFB4AB)),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Visual Evaluated OMR Sheet Preview Card
              if (annotatedBytes != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Evaluated OMR Sheet (Visual Ground Truth)',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: InteractiveViewer(
                          maxScale: 4.0,
                          child: Image.memory(
                            annotatedBytes,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _legendDot(Colors.green, 'Correct'),
                        const SizedBox(width: 16),
                        _legendDot(Colors.red, 'Incorrect'),
                        const SizedBox(width: 16),
                        _legendDot(Colors.amber, 'Review'),
                      ],
                    ),
                    const SizedBox(height: 14),
                  ],
                ),

              if (flaggedQs.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          color: Color(0xFFD97706), size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${flaggedQs.length} ambiguous questions flagged for staff review.',
                          style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF92400E),
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        context.push('/exam-results-summary');
                      },
                      child: const Text('View All Results'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.camera_alt_rounded),
                      label: const Text('Scan Next'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(
                fontSize: 11,
                color: AppColors.tertiary,
                fontWeight: FontWeight.w600)),
      ],
    );
  }

  static Widget _scoreItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 9,
                color: Colors.white70,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeExam = ref.watch(activeExamProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.5),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => context.safePop('/dashboard'),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('100% Offline OMR Scanner',
                style: TextStyle(color: Colors.white, fontSize: 16)),
            Text(
              activeExam != null
                  ? '${activeExam.title} (${activeExam.questionsCount} Qs)'
                  : 'No Exam Selected',
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
                _isFlashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                color: Colors.white),
            onPressed: _toggleFlash,
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. Camera Preview
          if (_isCameraInitialized && _cameraController != null)
            Center(child: CameraPreview(_cameraController!))
          else if (_isPermissionDenied)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Camera permission required for scanning.\nPlease enable camera in Settings or use Gallery Upload.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white),
                ),
              ),
            )
          else
            const Center(child: CircularProgressIndicator(color: Colors.white)),

          // 2. Viewfinder Frame Guide & Laser Animation
          Center(
            child: AspectRatio(
              aspectRatio: 730.0 / 1024.0, // Fixed Standard Sheet Aspect Ratio
              child: Container(
                margin:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.primary, width: 2.5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Stack(
                  children: [
                    // Corner tick guides
                    Positioned(top: 8, left: 8, child: _cornerMarker()),
                    Positioned(top: 8, right: 8, child: _cornerMarker()),
                    Positioned(bottom: 8, left: 8, child: _cornerMarker()),
                    Positioned(bottom: 8, right: 8, child: _cornerMarker()),

                    // Scanning Laser
                    if (!_isProcessing)
                      AnimatedBuilder(
                        animation: _laserAnimation,
                        builder: (context, child) {
                          return Positioned(
                            top: MediaQuery.of(context).size.height *
                                0.5 *
                                _laserAnimation.value,
                            left: 0,
                            right: 0,
                            child: Container(
                              height: 2.5,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    AppColors.primary,
                                    Colors.transparent
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                      color: AppColors.primary.withOpacity(0.8),
                                      blurRadius: 8),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),

          // 3. Processing HUD Overlay
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: AppColors.primary),
                      const SizedBox(height: 16),
                      Text(_processingStatus,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                ),
              ),
            ),

          // 4. Bottom Capture Controls
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Gallery Upload Button
                IconButton(
                  iconSize: 32,
                  icon: const Icon(Icons.photo_library_rounded,
                      color: Colors.white),
                  onPressed: _pickFromGallery,
                ),

                // Main Shutter Button
                GestureDetector(
                  onTap: _captureFromCamera,
                  child: Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      color: AppColors.primary,
                      boxShadow: [
                        BoxShadow(
                            color: AppColors.primary.withOpacity(0.5),
                            blurRadius: 16),
                      ],
                    ),
                    child: const Icon(Icons.camera_alt_rounded,
                        color: Colors.white, size: 36),
                  ),
                ),

                // Active Exam Results Button
                IconButton(
                  iconSize: 32,
                  icon:
                      const Icon(Icons.analytics_outlined, color: Colors.white),
                  onPressed: () => context.push('/exam-results-summary'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _cornerMarker() {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        shape: BoxShape.circle,
      ),
    );
  }
}
