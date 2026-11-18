import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:omr_mobile_app/core/database/local_database.dart';
import 'package:omr_mobile_app/core/omr/offline_evaluator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Initialize FFI for running sqflite in desktop / unit tests
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late LocalOMRDatabase localDb;

  setUp(() async {
    localDb = LocalOMRDatabase();
    final db = await localDb.database;
    await db.delete('audit_logs');
    await db.delete('email_outbox');
    await db.delete('marked_answers');
    await db.delete('scan_results');
    await db.delete('answer_keys');
    await db.delete('exams');
  });

  tearDown(() async {
    await localDb.close();
  });

  group('Phase 4: Local SQLite Database Tests', () {
    test('Can save and retrieve an Exam and Answer Key', () async {
      const examId = 'test-exam-101';
      final answerKey = {1: 'A', 2: 'B', 3: 'C', 4: 'D', 5: 'A'};

      await localDb.saveExam(
        id: examId,
        title: 'Mid-Term Physics Exam',
        totalQuestions: 5,
        scoringRule: const ScoringRule(correctMarks: 4.0, negativeMarks: 1.0),
        answerKey: answerKey,
      );

      final retrievedKey = await localDb.getAnswerKey(examId);
      expect(retrievedKey.length, equals(5));
      expect(retrievedKey[1], equals('A'));
      expect(retrievedKey[2], equals('B'));
      expect(retrievedKey[3], equals('C'));
      expect(retrievedKey[4], equals('D'));
      expect(retrievedKey[5], equals('A'));
    });

    test('Can save and query a Scan Result and Email Outbox entry', () async {
      const examId = 'test-exam-101';
      const scanId = 'scan-ved-001';

      const evaluator = OfflineExamEvaluator();
      final summary = evaluator.evaluate(
        totalQuestions: 5,
        detectedAnswers: {1: 'A', 2: 'B', 3: 'C', 4: 'A', 5: 'A'},
        answerKey: {1: 'A', 2: 'B', 3: 'C', 4: 'D', 5: 'A'},
      );

      await localDb.saveScanResult(
        id: scanId,
        examId: examId,
        studentCode: '224567',
        studentName: 'Vedehi',
        summary: summary,
        needsReview: false,
      );

      final db = await localDb.database;

      // Verify Scan Result record
      final scanRows = await db.query('scan_results', where: 'id = ?', whereArgs: [scanId]);
      expect(scanRows.length, equals(1));
      expect(scanRows.first['student_code'], equals('224567'));
      expect(scanRows.first['correct_count'], equals(4));
      expect(scanRows.first['wrong_count'], equals(1));
      expect(scanRows.first['status'], equals('FINALIZED'));

      // Queue an outbox email
      await db.insert(
        'email_outbox',
        {
          'id': 'outbox-${DateTime.now().microsecondsSinceEpoch}',
          'scan_result_id': scanId,
          'recipient_email': 'parent@example.com',
          'student_name': 'Vedehi',
          'pdf_path': '/storage/reports/rep_001.pdf',
          'status': 'PENDING',
          'retry_count': 0,
          'created_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      final pending = await localDb.getPendingEmails();
      expect(pending.length, equals(1));
      expect(pending.first['recipient_email'], equals('parent@example.com'));
    });

    test('Can log and retrieve manual audit resolution for review queue', () async {
      const scanId = 'scan-audit-001';

      await localDb.logAuditResolution(
        scanResultId: scanId,
        questionNumber: 14,
        originalOption: null,
        resolvedOption: '3',
        reviewerId: 'staff_examiner_01',
        reason: 'Double bubble resolved in favor of Option 3',
      );

      final logs = await localDb.getAuditLogs(scanId);
      expect(logs.length, equals(1));
      expect(logs.first['scan_result_id'], equals(scanId));
      expect(logs.first['question_number'], equals(14));
      expect(logs.first['resolved_option'], equals('3'));
      expect(logs.first['reviewer_id'], equals('staff_examiner_01'));
      expect(logs.first['reason'], contains('Double bubble'));
    });
  });
}
