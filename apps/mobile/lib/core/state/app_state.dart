import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/evaluation_engine.dart';

// ==========================================
// 1. DATA MODELS
// ==========================================

class ExamModel {
  final String id;
  final String title;
  final String subject;
  final String className;
  final String date;
  final int questionsCount;
  final double correctMarks;
  final double wrongMarks;
  final String status; // 'draft', 'published', 'completed'
  final int scannedCount;
  final int totalStudents;
  final Map<int, List<String>> answerKey;
  final Set<int> bonusQuestions;
  final Set<int> droppedQuestions;
  final Map<String, dynamic>? templateConfig;
  final String? templatePreviewBase64;

  const ExamModel({
    required this.id,
    required this.title,
    required this.subject,
    required this.className,
    required this.date,
    required this.questionsCount,
    this.correctMarks = 4.0,
    this.wrongMarks = -1.0,
    this.status = 'published',
    this.scannedCount = 0,
    this.totalStudents = 50,
    required this.answerKey,
    this.bonusQuestions = const {},
    this.droppedQuestions = const {},
    this.templateConfig,
    this.templatePreviewBase64,
  });

  ExamModel copyWith({
    String? id,
    String? title,
    String? subject,
    String? className,
    String? date,
    int? questionsCount,
    double? correctMarks,
    double? wrongMarks,
    String? status,
    int? scannedCount,
    int? totalStudents,
    Map<int, List<String>>? answerKey,
    Set<int>? bonusQuestions,
    Set<int>? droppedQuestions,
    Map<String, dynamic>? templateConfig,
    String? templatePreviewBase64,
  }) {
    return ExamModel(
      id: id ?? this.id,
      title: title ?? this.title,
      subject: subject ?? this.subject,
      className: className ?? this.className,
      date: date ?? this.date,
      questionsCount: questionsCount ?? this.questionsCount,
      correctMarks: correctMarks ?? this.correctMarks,
      wrongMarks: wrongMarks ?? this.wrongMarks,
      status: status ?? this.status,
      scannedCount: scannedCount ?? this.scannedCount,
      totalStudents: totalStudents ?? this.totalStudents,
      answerKey: answerKey ?? this.answerKey,
      bonusQuestions: bonusQuestions ?? this.bonusQuestions,
      droppedQuestions: droppedQuestions ?? this.droppedQuestions,
      templateConfig: templateConfig ?? this.templateConfig,
      templatePreviewBase64: templatePreviewBase64 ?? this.templatePreviewBase64,
    );
  }
}

class StudentModel {
  final String id;
  final String name;
  final String code;
  final String roll;
  final String className;
  final String parentName;
  final String parentEmail;
  final String parentPhone;
  final String relationship;
  final int examsCount;
  final String avgScore;

  const StudentModel({
    required this.id,
    required this.name,
    required this.code,
    required this.roll,
    required this.className,
    required this.parentName,
    required this.parentEmail,
    this.parentPhone = '+91 98765 43210',
    this.relationship = 'Father',
    this.examsCount = 8,
    this.avgScore = '88.5%',
  });

  StudentModel copyWith({
    String? id,
    String? name,
    String? code,
    String? roll,
    String? className,
    String? parentName,
    String? parentEmail,
    String? parentPhone,
    String? relationship,
    int? examsCount,
    String? avgScore,
  }) {
    return StudentModel(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      roll: roll ?? this.roll,
      className: className ?? this.className,
      parentName: parentName ?? this.parentName,
      parentEmail: parentEmail ?? this.parentEmail,
      parentPhone: parentPhone ?? this.parentPhone,
      relationship: relationship ?? this.relationship,
      examsCount: examsCount ?? this.examsCount,
      avgScore: avgScore ?? this.avgScore,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'code': code,
    'roll': roll,
    'className': className,
    'parentName': parentName,
    'parentEmail': parentEmail,
    'parentPhone': parentPhone,
  };
}

class ScanResultModel {
  final String id;
  final String examId;
  final String studentCode;
  final String studentName;
  final String studentRoll;
  final String studentClass;
  final String parentEmail;
  final double marksObtained;
  final double maximumMarks;
  final double percentage;
  final int correctCount;
  final int wrongCount;
  final int unattemptedCount;
  final double overallConfidence;
  final bool reviewRequired;
  final bool isReviewed;
  final bool isUnassigned;
  final String scannedAt;
  final List<String> vacantFields;
  final Map<String, dynamic>? metadataFields;
  final List<AnswerItemResult> answers;
  final String? annotatedPreviewBase64;

  const ScanResultModel({
    required this.id,
    required this.examId,
    required this.studentCode,
    required this.studentName,
    required this.studentRoll,
    required this.studentClass,
    required this.parentEmail,
    required this.marksObtained,
    required this.maximumMarks,
    required this.percentage,
    required this.correctCount,
    required this.wrongCount,
    required this.unattemptedCount,
    this.overallConfidence = 0.98,
    this.reviewRequired = false,
    this.isReviewed = false,
    this.isUnassigned = false,
    required this.scannedAt,
    this.vacantFields = const [],
    this.metadataFields,
    required this.answers,
    this.annotatedPreviewBase64,
  });

  ScanResultModel copyWith({
    String? id,
    String? examId,
    String? studentCode,
    String? studentName,
    String? studentRoll,
    String? studentClass,
    String? parentEmail,
    double? marksObtained,
    double? maximumMarks,
    double? percentage,
    int? correctCount,
    int? wrongCount,
    int? unattemptedCount,
    double? overallConfidence,
    bool? reviewRequired,
    bool? isReviewed,
    bool? isUnassigned,
    String? scannedAt,
    List<String>? vacantFields,
    Map<String, dynamic>? metadataFields,
    List<AnswerItemResult>? answers,
    String? annotatedPreviewBase64,
  }) {
    return ScanResultModel(
      id: id ?? this.id,
      examId: examId ?? this.examId,
      studentCode: studentCode ?? this.studentCode,
      studentName: studentName ?? this.studentName,
      studentRoll: studentRoll ?? this.studentRoll,
      studentClass: studentClass ?? this.studentClass,
      parentEmail: parentEmail ?? this.parentEmail,
      marksObtained: marksObtained ?? this.marksObtained,
      maximumMarks: maximumMarks ?? this.maximumMarks,
      percentage: percentage ?? this.percentage,
      correctCount: correctCount ?? this.correctCount,
      wrongCount: wrongCount ?? this.wrongCount,
      unattemptedCount: unattemptedCount ?? this.unattemptedCount,
      overallConfidence: overallConfidence ?? this.overallConfidence,
      reviewRequired: reviewRequired ?? this.reviewRequired,
      isReviewed: isReviewed ?? this.isReviewed,
      isUnassigned: isUnassigned ?? this.isUnassigned,
      scannedAt: scannedAt ?? this.scannedAt,
      vacantFields: vacantFields ?? this.vacantFields,
      metadataFields: metadataFields ?? this.metadataFields,
      answers: answers ?? this.answers,
      annotatedPreviewBase64: annotatedPreviewBase64 ?? this.annotatedPreviewBase64,
    );
  }
}

class ReviewQueueItemModel {
  final String id;
  final String resultId;
  final String examId;
  final String examName;
  final String studentName;
  final String studentCode;
  final int questionNumber;
  final String reason;
  final String detectedOption;
  final double confidence;
  String selectedOption;

  ReviewQueueItemModel({
    required this.id,
    required this.resultId,
    required this.examId,
    required this.examName,
    required this.studentName,
    required this.studentCode,
    required this.questionNumber,
    required this.reason,
    required this.detectedOption,
    required this.confidence,
    required this.selectedOption,
  });
}

class EmailLogModel {
  final String id;
  final String studentName;
  final String email;
  final String examTitle;
  final String status; // 'delivered', 'sent', 'failed'
  final String timeStr;
  final int attempts;
  final String? error;

  const EmailLogModel({
    required this.id,
    required this.studentName,
    required this.email,
    required this.examTitle,
    required this.status,
    required this.timeStr,
    this.attempts = 1,
    this.error,
  });

  EmailLogModel copyWith({
    String? id,
    String? studentName,
    String? email,
    String? examTitle,
    String? status,
    String? timeStr,
    int? attempts,
    String? error,
  }) {
    return EmailLogModel(
      id: id ?? this.id,
      studentName: studentName ?? this.studentName,
      email: email ?? this.email,
      examTitle: examTitle ?? this.examTitle,
      status: status ?? this.status,
      timeStr: timeStr ?? this.timeStr,
      attempts: attempts ?? this.attempts,
      error: error ?? this.error,
    );
  }
}

class InstituteSettingsModel {
  final String orgName;
  final String tenantSlug;
  final String email;
  final String phone;
  final String address;
  final String omrServiceUrl;
  final String senderName;
  final String senderEmail;
  final String replyTo;
  final bool attachPdfByDefault;
  final bool includeOnlineLink;

  const InstituteSettingsModel({
    this.orgName = 'Apex International Academy',
    this.tenantSlug = 'apex-academy',
    this.email = 'admin@apexacademy.edu',
    this.phone = '+91 98765 43210',
    this.address = '42 Knowledge Park, Tech City, New Delhi',
    this.omrServiceUrl = 'http://127.0.0.1:8000',
    this.senderName = 'Apex International Academy Assessments',
    this.senderEmail = 'results@apexacademy.edu',
    this.replyTo = 'principal@apexacademy.edu',
    this.attachPdfByDefault = true,
    this.includeOnlineLink = true,
  });

  InstituteSettingsModel copyWith({
    String? orgName,
    String? tenantSlug,
    String? email,
    String? phone,
    String? address,
    String? omrServiceUrl,
    String? senderName,
    String? senderEmail,
    String? replyTo,
    bool? attachPdfByDefault,
    bool? includeOnlineLink,
  }) {
    return InstituteSettingsModel(
      orgName: orgName ?? this.orgName,
      tenantSlug: tenantSlug ?? this.tenantSlug,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      omrServiceUrl: omrServiceUrl ?? this.omrServiceUrl,
      senderName: senderName ?? this.senderName,
      senderEmail: senderEmail ?? this.senderEmail,
      replyTo: replyTo ?? this.replyTo,
      attachPdfByDefault: attachPdfByDefault ?? this.attachPdfByDefault,
      includeOnlineLink: includeOnlineLink ?? this.includeOnlineLink,
    );
  }
}

// ==========================================
// 2. STATE NOTIFIERS & PROVIDERS
// ==========================================

// --- EXAMS NOTIFIER ---
class ExamsNotifier extends StateNotifier<List<ExamModel>> {
  ExamsNotifier() : super(_initialExams());

  static List<ExamModel> _initialExams() {
    // Dedicated 200-Question Answer Key for 'TESTING' Assessment:
    // (Q1 to Q26 - 1), (Q27 to Q52 - 2), (Q53 to Q89 - 3), (Q90 to Q126 - 4), (Q127 to Q163 - 1), (Q164 to Q200 - 2)
    final Map<int, List<String>> testingKey = {};
    for (int i = 1; i <= 26; i++) {
      testingKey[i] = ['1'];
    }
    for (int i = 27; i <= 52; i++) {
      testingKey[i] = ['2'];
    }
    for (int i = 53; i <= 89; i++) {
      testingKey[i] = ['3'];
    }
    for (int i = 90; i <= 126; i++) {
      testingKey[i] = ['4'];
    }
    for (int i = 127; i <= 163; i++) {
      testingKey[i] = ['1'];
    }
    for (int i = 164; i <= 200; i++) {
      testingKey[i] = ['2'];
    }

    final Map<String, dynamic> universal200TemplateConfig = {
      'template_id': 'universal-200-q-v1',
      'name': 'Universal 200 Questions Dedicated OMR Assessment',
      'pageDimensions': [2480, 3508],
      'bubbleDimensions': [24, 24],
      'total_questions': 200,
      'customLabels': {
        'Roll': ['roll1..6']
      },
      'fieldBlocks': {
        'Roll': {
          'fieldType': 'QTYPE_INT',
          'fieldLabels': ['roll1..6'],
          'direction': 'horizontal',
          'bubblesGap': 45.75,
          'labelsGap': 44.0,
          'origin': [447, 442],
        },
        'Col1': {
          'fieldType': 'QTYPE_MCQ4',
          'fieldLabels': ['q1..26'],
          'direction': 'vertical',
          'bubblesGap': 40.5,
          'labelsGap': 45.68,
          'origin': [490, 944],
        },
        'Col2': {
          'fieldType': 'QTYPE_MCQ4',
          'fieldLabels': ['q27..52'],
          'direction': 'vertical',
          'bubblesGap': 40.5,
          'labelsGap': 45.68,
          'origin': [780, 944],
        },
        'Col3': {
          'fieldType': 'QTYPE_MCQ4',
          'fieldLabels': ['q53..89'],
          'direction': 'vertical',
          'bubblesGap': 40.5,
          'labelsGap': 45.68,
          'origin': [1082, 441],
        },
        'Col4': {
          'fieldType': 'QTYPE_MCQ4',
          'fieldLabels': ['q90..126'],
          'direction': 'vertical',
          'bubblesGap': 40.5,
          'labelsGap': 45.68,
          'origin': [1356, 441],
        },
        'Col5': {
          'fieldType': 'QTYPE_MCQ4',
          'fieldLabels': ['q127..163'],
          'direction': 'vertical',
          'bubblesGap': 40.5,
          'labelsGap': 45.68,
          'origin': [1634, 441],
        },
        'Col6': {
          'fieldType': 'QTYPE_MCQ4',
          'fieldLabels': ['q164..200'],
          'direction': 'vertical',
          'bubblesGap': 40.5,
          'labelsGap': 45.68,
          'origin': [1908, 441],
        },
      },
      'preProcessors': [
        {'name': 'CropPage', 'options': {'morphKernel': [10, 10]}},
        {'name': 'CropOnMarkers', 'options': {'sheetToMarkerWidthRatio': 17}},
      ],
    };

    return [
      ExamModel(
        id: 'exam_testing_200q',
        title: 'TESTING',
        subject: 'Full Assessment (200 Questions)',
        className: 'All Batches',
        date: '02 Sep 2026',
        questionsCount: 200,
        correctMarks: 4.0,
        wrongMarks: -1.0,
        status: 'published',
        scannedCount: 0,
        totalStudents: 100,
        answerKey: testingKey,
        templateConfig: universal200TemplateConfig,
      ),
    ];
  }

  void addExam(ExamModel exam) {
    state = [exam, ...state];
  }

  void updateExam(ExamModel updated) {
    state = state.map((e) => e.id == updated.id ? updated : e).toList();
  }

  void updateAnswerKey(String examId, Map<int, List<String>> answerKey, {Set<int>? bonus, Set<int>? dropped, bool publish = false}) {
    state = state.map((e) {
      if (e.id == examId) {
        return e.copyWith(
          answerKey: answerKey,
          bonusQuestions: bonus ?? e.bonusQuestions,
          droppedQuestions: dropped ?? e.droppedQuestions,
          status: publish ? 'published' : e.status,
        );
      }
      return e;
    }).toList();
  }

  void updateTemplateConfig(String examId, Map<String, dynamic> config, {String? previewBase64}) {
    state = state.map((e) {
      if (e.id == examId) {
        return e.copyWith(
          templateConfig: config,
          templatePreviewBase64: previewBase64 ?? e.templatePreviewBase64,
        );
      }
      return e;
    }).toList();
  }

  void incrementScannedCount(String examId) {
    state = state.map((e) {
      if (e.id == examId) {
        return e.copyWith(scannedCount: e.scannedCount + 1);
      }
      return e;
    }).toList();
  }
}

final examsProvider = StateNotifierProvider<ExamsNotifier, List<ExamModel>>((ref) => ExamsNotifier());

// Default active exam set directly to TESTING (200 Questions)
final activeExamIdProvider = StateProvider<String>((ref) => 'exam_testing_200q');

final activeExamProvider = Provider<ExamModel?>((ref) {
  final exams = ref.watch(examsProvider);
  final activeId = ref.watch(activeExamIdProvider);
  return exams.firstWhere((e) => e.id == activeId, orElse: () => exams.first);
});

// --- STUDENTS NOTIFIER ---
class StudentsNotifier extends StateNotifier<List<StudentModel>> {
  StudentsNotifier() : super(_initialStudents());

  static List<StudentModel> _initialStudents() {
    return [
      const StudentModel(
        id: '44444444-4444-4444-4444-444444444441',
        name: 'Aarav Sharma',
        code: 'STU1001',
        roll: '101',
        className: 'Grade 10 - Section A',
        parentName: 'Rajesh Sharma',
        parentEmail: 'rajesh.sharma@example.com',
        parentPhone: '+91 98765 11223',
        examsCount: 8,
        avgScore: '88.5%',
      ),
      const StudentModel(
        id: '44444444-4444-4444-4444-444444444442',
        name: 'Priya Patel',
        code: 'STU1002',
        roll: '102',
        className: 'Grade 10 - Section A',
        parentName: 'Sunita Patel',
        parentEmail: 'sunita.patel@example.com',
        parentPhone: '+91 98765 11224',
        examsCount: 8,
        avgScore: '94.0%',
      ),
      const StudentModel(
        id: '44444444-4444-4444-4444-444444444443',
        name: 'Rohan Gupta',
        code: 'STU1003',
        roll: '103',
        className: 'Grade 10 - Section A',
        parentName: 'Sanjay Gupta',
        parentEmail: 'sanjay.gupta@example.com',
        parentPhone: '+91 98765 11225',
        examsCount: 7,
        avgScore: '76.2%',
      ),
      const StudentModel(
        id: '44444444-4444-4444-4444-444444444444',
        name: 'Ananya Verma',
        code: 'STU1004',
        roll: '104',
        className: 'Grade 10 - Section A',
        parentName: 'Meenakshi Verma',
        parentEmail: 'meenakshi.verma@example.com',
        parentPhone: '+91 98765 11226',
        examsCount: 8,
        avgScore: '91.8%',
      ),
      const StudentModel(
        id: '44444444-4444-4444-4444-444444444445',
        name: 'Vikramaditya Singh',
        code: 'STU1005',
        roll: '105',
        className: 'Grade 10 - Section A',
        parentName: 'Digvijay Singh',
        parentEmail: 'digvijay.singh@example.com',
        parentPhone: '+91 98765 11227',
        examsCount: 8,
        avgScore: '84.0%',
      ),
    ];
  }

  void addStudent(StudentModel student) {
    state = [student, ...state];
  }

  void updateStudent(StudentModel updated) {
    state = state.map((s) => s.id == updated.id ? updated : s).toList();
  }

  int importFromCsv(String csvContent) {
    final lines = csvContent.split('\n');
    int addedCount = 0;
    for (var line in lines) {
      final parts = line.split(',');
      if (parts.length >= 4 && !parts[0].toLowerCase().contains('name')) {
        final name = parts[0].trim();
        final code = parts[1].trim();
        final roll = parts[2].trim();
        final className = parts[3].trim();
        final email = parts.length > 4 ? parts[4].trim() : 'parent.$code@example.com';
        if (name.isNotEmpty && code.isNotEmpty) {
          addStudent(StudentModel(
            id: 'stu_${DateTime.now().millisecondsSinceEpoch}_$addedCount',
            name: name,
            code: code,
            roll: roll,
            className: className,
            parentName: 'Parent of $name',
            parentEmail: email,
          ));
          addedCount++;
        }
      }
    }
    return addedCount;
  }
}

final studentsProvider = StateNotifierProvider<StudentsNotifier, List<StudentModel>>((ref) => StudentsNotifier());

final selectedStudentIdProvider = StateProvider<String>((ref) => '44444444-4444-4444-4444-444444444441');

final selectedStudentProvider = Provider<StudentModel?>((ref) {
  final students = ref.watch(studentsProvider);
  final selId = ref.watch(selectedStudentIdProvider);
  return students.firstWhere((s) => s.id == selId, orElse: () => students.first);
});

// --- SCAN RESULTS & EVALUATION NOTIFIER ---
class ScanResultsNotifier extends StateNotifier<List<ScanResultModel>> {
  ScanResultsNotifier() : super(_initialResults());

  static List<ScanResultModel> _initialResults() {
    return [
      const ScanResultModel(
        id: 'res_1',
        examId: '66666666-6666-6666-6666-666666666666',
        studentCode: 'STU1002',
        studentName: 'Priya Patel',
        studentRoll: '102',
        studentClass: 'Grade 10 - Section A',
        parentEmail: 'sunita.patel@example.com',
        marksObtained: 188.0,
        maximumMarks: 200.0,
        percentage: 94.0,
        correctCount: 47,
        wrongCount: 0,
        unattemptedCount: 3,
        overallConfidence: 0.99,
        reviewRequired: false,
        isReviewed: true,
        scannedAt: '21 Aug 2026, 12:45 PM',
        answers: [],
      ),
      const ScanResultModel(
        id: 'res_2',
        examId: '66666666-6666-6666-6666-666666666666',
        studentCode: 'STU1004',
        studentName: 'Ananya Verma',
        studentRoll: '104',
        studentClass: 'Grade 10 - Section A',
        parentEmail: 'meenakshi.verma@example.com',
        marksObtained: 184.0,
        maximumMarks: 200.0,
        percentage: 92.0,
        correctCount: 46,
        wrongCount: 2,
        unattemptedCount: 2,
        overallConfidence: 0.98,
        reviewRequired: false,
        isReviewed: true,
        scannedAt: '21 Aug 2026, 12:46 PM',
        answers: [],
      ),
      const ScanResultModel(
        id: 'res_3',
        examId: '66666666-6666-6666-6666-666666666666',
        studentCode: 'STU1001',
        studentName: 'Aarav Sharma',
        studentRoll: '101',
        studentClass: 'Grade 10 - Section A',
        parentEmail: 'rajesh.sharma@example.com',
        marksObtained: 176.0,
        maximumMarks: 200.0,
        percentage: 88.0,
        correctCount: 44,
        wrongCount: 4,
        unattemptedCount: 2,
        overallConfidence: 0.98,
        reviewRequired: false,
        isReviewed: true,
        scannedAt: '21 Aug 2026, 12:47 PM',
        answers: [],
      ),
      const ScanResultModel(
        id: 'res_4',
        examId: '66666666-6666-6666-6666-666666666666',
        studentCode: 'STU1005',
        studentName: 'Vikramaditya Singh',
        studentRoll: '105',
        studentClass: 'Grade 10 - Section A',
        parentEmail: 'digvijay.singh@example.com',
        marksObtained: 168.0,
        maximumMarks: 200.0,
        percentage: 84.0,
        correctCount: 42,
        wrongCount: 6,
        unattemptedCount: 2,
        overallConfidence: 0.95,
        reviewRequired: false,
        isReviewed: true,
        scannedAt: '21 Aug 2026, 12:48 PM',
        answers: [],
      ),
      const ScanResultModel(
        id: 'res_5',
        examId: '66666666-6666-6666-6666-666666666666',
        studentCode: 'STU1003',
        studentName: 'Rohan Gupta',
        studentRoll: '103',
        studentClass: 'Grade 10 - Section A',
        parentEmail: 'sanjay.gupta@example.com',
        marksObtained: 152.0,
        maximumMarks: 200.0,
        percentage: 76.0,
        correctCount: 38,
        wrongCount: 8,
        unattemptedCount: 4,
        overallConfidence: 0.82,
        reviewRequired: true,
        isReviewed: false,
        scannedAt: '21 Aug 2026, 12:49 PM',
        answers: [],
      ),
    ];
  }

  void addScanResult(ScanResultModel result) {
    state = [
      result,
      ...state.where((r) => !(r.examId == result.examId && r.studentCode == result.studentCode && result.studentCode.isNotEmpty)),
    ];
  }

  void assignStudentToResult(String resultId, StudentModel student) {
    state = state.map((r) {
      if (r.id == resultId) {
        return r.copyWith(
          studentCode: student.code,
          studentName: student.name,
          studentRoll: student.roll,
          studentClass: student.className,
          parentEmail: student.parentEmail,
          isUnassigned: false,
        );
      }
      return r;
    }).toList();
  }

  void resolveReviewItem(String resultId, int questionNumber, String chosenOption, ExamModel exam) {
    state = state.map((r) {
      if (r.id == resultId) {
        final Map<int, Map<String, dynamic>> detMap = {};
        for (var a in r.answers) {
          detMap[a.questionNumber] = {
            'detected_option': a.questionNumber == questionNumber ? (chosenOption == 'Blank' ? null : chosenOption) : a.detectedOption,
            'is_multiple': a.questionNumber == questionNumber ? false : a.isMultiple,
            'is_uncertain': a.questionNumber == questionNumber ? false : a.isUncertain,
            'confidence': a.questionNumber == questionNumber ? 1.0 : a.confidence,
          };
        }

        final eval = EvaluationEngine.evaluate(
          answerKey: exam.answerKey,
          detectedAnswers: detMap,
          defaultCorrectMarks: exam.correctMarks,
          defaultWrongMarks: exam.wrongMarks,
          bonusQuestions: exam.bonusQuestions,
          droppedQuestions: exam.droppedQuestions,
        );

        return r.copyWith(
          marksObtained: eval.marksObtained,
          maximumMarks: eval.maximumMarks,
          percentage: eval.percentage,
          correctCount: eval.correctCount,
          wrongCount: eval.wrongCount,
          unattemptedCount: eval.unattemptedCount,
          answers: eval.answers,
          reviewRequired: false,
          isReviewed: true,
        );
      }
      return r;
    }).toList();
  }
}

final scanResultsProvider = StateNotifierProvider<ScanResultsNotifier, List<ScanResultModel>>((ref) => ScanResultsNotifier());

final selectedResultIdProvider = StateProvider<String>((ref) => 'res_3');

final selectedResultProvider = Provider<ScanResultModel?>((ref) {
  final results = ref.watch(scanResultsProvider);
  final selId = ref.watch(selectedResultIdProvider);
  return results.firstWhere((r) => r.id == selId, orElse: () => results.first);
});

// --- REVIEW QUEUE NOTIFIER ---
class ReviewQueueNotifier extends StateNotifier<List<ReviewQueueItemModel>> {
  ReviewQueueNotifier() : super(_initialQueue());

  static List<ReviewQueueItemModel> _initialQueue() {
    return [
      ReviewQueueItemModel(
        id: 'flag_1',
        resultId: 'res_5',
        examId: '66666666-6666-6666-6666-666666666666',
        examName: 'Mathematics Assessment 04',
        studentName: 'Rohan Gupta',
        studentCode: 'STU1003',
        questionNumber: 14,
        reason: 'Multiple Bubbles Marked (B and C)',
        detectedOption: 'Multiple',
        confidence: 42.0,
        selectedOption: 'B',
      ),
      ReviewQueueItemModel(
        id: 'flag_2',
        resultId: 'res_4',
        examId: '66666666-6666-6666-6666-666666666666',
        examName: 'Mathematics Assessment 04',
        studentName: 'Vikramaditya Singh',
        studentCode: 'STU1005',
        questionNumber: 27,
        reason: 'Faint / Incomplete Fill',
        detectedOption: 'C (Uncertain)',
        confidence: 48.5,
        selectedOption: 'C',
      ),
      ReviewQueueItemModel(
        id: 'flag_3',
        resultId: 'res_2',
        examId: '66666666-6666-6666-6666-666666666666',
        examName: 'Mathematics Assessment 04',
        studentName: 'Ananya Verma',
        studentCode: 'STU1004',
        questionNumber: 39,
        reason: 'Partial Erased Bubble',
        detectedOption: 'A (Uncertain)',
        confidence: 54.0,
        selectedOption: 'D',
      ),
    ];
  }

  void addFlaggedItem(ReviewQueueItemModel item) {
    state = [item, ...state];
  }

  void removeItem(String id) {
    state = state.where((item) => item.id != id).toList();
  }
}

final reviewQueueProvider = StateNotifierProvider<ReviewQueueNotifier, List<ReviewQueueItemModel>>((ref) => ReviewQueueNotifier());

// --- EMAIL DELIVERY NOTIFIER ---
class EmailDeliveryNotifier extends StateNotifier<List<EmailLogModel>> {
  EmailDeliveryNotifier() : super(_initialLogs());

  static List<EmailLogModel> _initialLogs() {
    return [
      const EmailLogModel(
        id: 'mail_1',
        studentName: 'Aarav Sharma',
        email: 'rajesh.sharma@example.com',
        examTitle: 'Mathematics Assessment 04',
        status: 'delivered',
        timeStr: 'Today, 12:48 PM',
        attempts: 1,
      ),
      const EmailLogModel(
        id: 'mail_2',
        studentName: 'Priya Patel',
        email: 'sunita.patel@example.com',
        examTitle: 'Mathematics Assessment 04',
        status: 'delivered',
        timeStr: 'Today, 12:47 PM',
        attempts: 1,
      ),
      const EmailLogModel(
        id: 'mail_3',
        studentName: 'Rohan Gupta',
        email: 'sanjay.gupta@example.com',
        examTitle: 'Mathematics Assessment 04',
        status: 'sent',
        timeStr: 'Today, 12:45 PM',
        attempts: 1,
      ),
      const EmailLogModel(
        id: 'mail_4',
        studentName: 'Vikramaditya Singh',
        email: 'digvijay.singh@example.com',
        examTitle: 'Mathematics Assessment 04',
        status: 'failed',
        timeStr: 'Today, 12:40 PM',
        attempts: 2,
        error: 'Invalid recipient domain mx record',
      ),
    ];
  }

  void queueEmail(EmailLogModel log) {
    state = [log, ...state];
  }

  void retryFailed() {
    state = state.map((log) {
      if (log.status == 'failed') {
        return log.copyWith(status: 'sent', timeStr: 'Just now', attempts: log.attempts + 1);
      }
      return log;
    }).toList();
  }

  void resendSingle(String id) {
    state = state.map((log) {
      if (log.id == id) {
        return log.copyWith(status: 'sent', timeStr: 'Just now', attempts: log.attempts + 1);
      }
      return log;
    }).toList();
  }
}

final emailDeliveryProvider = StateNotifierProvider<EmailDeliveryNotifier, List<EmailLogModel>>((ref) => EmailDeliveryNotifier());

// --- SETTINGS NOTIFIER ---
class SettingsNotifier extends StateNotifier<InstituteSettingsModel> {
  SettingsNotifier() : super(const InstituteSettingsModel());

  void updateSettings(InstituteSettingsModel updated) {
    state = updated;
  }

  void updateOmrUrl(String newUrl) {
    state = state.copyWith(omrServiceUrl: newUrl);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, InstituteSettingsModel>((ref) => SettingsNotifier());
