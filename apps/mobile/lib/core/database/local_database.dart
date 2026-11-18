import 'dart:async';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:omr_mobile_app/core/omr/offline_evaluator.dart';

/// Offline SQLite Database for 100% On-Device Persistence.
class LocalOMRDatabase {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'omr_offline_system.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDb,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS audit_logs (
              id TEXT PRIMARY KEY,
              scan_result_id TEXT NOT NULL,
              question_number INTEGER NOT NULL,
              original_option TEXT,
              resolved_option TEXT NOT NULL,
              reviewer_id TEXT NOT NULL DEFAULT 'staff_examiner',
              reason TEXT,
              created_at TEXT NOT NULL,
              FOREIGN KEY (scan_result_id) REFERENCES scan_results (id) ON DELETE CASCADE
            )
          ''');
        }
      },
    );
  }

  Future<void> _createDb(Database db, int version) async {
    // 1. Exams Table
    await db.execute('''
      CREATE TABLE exams (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        total_questions INTEGER NOT NULL,
        marks_correct REAL NOT NULL DEFAULT 4.0,
        marks_negative REAL NOT NULL DEFAULT 1.0,
        marks_unattempted REAL NOT NULL DEFAULT 0.0,
        status TEXT NOT NULL DEFAULT 'ACTIVE',
        created_at TEXT NOT NULL
      )
    ''');

    // 2. Answer Keys Table
    await db.execute('''
      CREATE TABLE answer_keys (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        exam_id TEXT NOT NULL,
        question_number INTEGER NOT NULL,
        correct_option TEXT NOT NULL,
        FOREIGN KEY (exam_id) REFERENCES exams (id) ON DELETE CASCADE
      )
    ''');

    // 3. Students Table
    await db.execute('''
      CREATE TABLE students (
        id TEXT PRIMARY KEY,
        roll_number TEXT UNIQUE NOT NULL,
        name TEXT NOT NULL,
        parent_email TEXT NOT NULL,
        class_section TEXT NOT NULL
      )
    ''');

    // 4. Scan Results Table
    await db.execute('''
      CREATE TABLE scan_results (
        id TEXT PRIMARY KEY,
        exam_id TEXT NOT NULL,
        student_code TEXT NOT NULL,
        student_name TEXT,
        total_score REAL NOT NULL,
        max_score REAL NOT NULL,
        percentage REAL NOT NULL,
        correct_count INTEGER NOT NULL,
        wrong_count INTEGER NOT NULL,
        unattempted_count INTEGER NOT NULL,
        multiple_marked_count INTEGER NOT NULL,
        status TEXT NOT NULL DEFAULT 'FINALIZED',
        image_path TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (exam_id) REFERENCES exams (id) ON DELETE CASCADE
      )
    ''');

    // 5. Marked Answers Table
    await db.execute('''
      CREATE TABLE marked_answers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        scan_result_id TEXT NOT NULL,
        question_number INTEGER NOT NULL,
        detected_option TEXT,
        correct_option TEXT,
        is_correct INTEGER NOT NULL,
        confidence REAL NOT NULL,
        is_flagged INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (scan_result_id) REFERENCES scan_results (id) ON DELETE CASCADE
      )
    ''');

    // 6. Email Outbox Table
    await db.execute('''
      CREATE TABLE email_outbox (
        id TEXT PRIMARY KEY,
        scan_result_id TEXT NOT NULL,
        recipient_email TEXT NOT NULL,
        student_name TEXT NOT NULL,
        pdf_path TEXT,
        status TEXT NOT NULL DEFAULT 'PENDING',
        retry_count INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        FOREIGN KEY (scan_result_id) REFERENCES scan_results (id) ON DELETE CASCADE
      )
    ''');

    // 7. Audit Logs Table (Tamper-proof manual review overrides)
    await db.execute('''
      CREATE TABLE audit_logs (
        id TEXT PRIMARY KEY,
        scan_result_id TEXT NOT NULL,
        question_number INTEGER NOT NULL,
        original_option TEXT,
        resolved_option TEXT NOT NULL,
        reviewer_id TEXT NOT NULL DEFAULT 'staff_examiner',
        reason TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (scan_result_id) REFERENCES scan_results (id) ON DELETE CASCADE
      )
    ''');
  }

  // --- CRUD Operations ---

  /// Save or Update an Exam
  Future<void> saveExam({
    required String id,
    required String title,
    required int totalQuestions,
    ScoringRule scoringRule = const ScoringRule(),
    required Map<int, String> answerKey,
  }) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.insert(
        'exams',
        {
          'id': id,
          'title': title,
          'total_questions': totalQuestions,
          'marks_correct': scoringRule.correctMarks,
          'marks_negative': scoringRule.negativeMarks,
          'marks_unattempted': scoringRule.unattemptedMarks,
          'status': 'ACTIVE',
          'created_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Save Answer Key
      await txn.delete('answer_keys', where: 'exam_id = ?', whereArgs: [id]);
      for (final entry in answerKey.entries) {
        await txn.insert('answer_keys', {
          'exam_id': id,
          'question_number': entry.key,
          'correct_option': entry.value.toUpperCase(),
        });
      }
    });
  }

  /// Get Answer Key for an Exam
  Future<Map<int, String>> getAnswerKey(String examId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'answer_keys',
      where: 'exam_id = ?',
      whereArgs: [examId],
      orderBy: 'question_number ASC',
    );

    final Map<int, String> key = {};
    for (final row in maps) {
      key[row['question_number'] as int] = row['correct_option'] as String;
    }
    return key;
  }

  /// Save a Completed or Flagged Scan Result
  Future<void> saveScanResult({
    required String id,
    required String examId,
    required String studentCode,
    String? studentName,
    required ExamEvaluationSummary summary,
    String? imagePath,
    bool needsReview = false,
  }) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.insert(
        'scan_results',
        {
          'id': id,
          'exam_id': examId,
          'student_code': studentCode,
          'student_name': studentName,
          'total_score': summary.totalScore,
          'max_score': summary.maxPossibleScore,
          'percentage': summary.percentage,
          'correct_count': summary.correctCount,
          'wrong_count': summary.wrongCount,
          'unattempted_count': summary.unattemptedCount,
          'multiple_marked_count': summary.multipleMarkedCount,
          'status': needsReview ? 'NEEDS_REVIEW' : 'FINALIZED',
          'image_path': imagePath,
          'created_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Save question items
      for (final q in summary.questionResults) {
        await txn.insert('marked_answers', {
          'scan_result_id': id,
          'question_number': q.questionNumber,
          'detected_option': q.markedOption,
          'correct_option': q.correctOption,
          'is_correct': q.isCorrect ? 1 : 0,
          'confidence': q.confidence,
          'is_flagged': (q.confidence < 0.4 || q.isMultipleMarked) ? 1 : 0,
        });
      }
    });
  }

  /// Fetch all pending items in Email Outbox
  Future<List<Map<String, dynamic>>> getPendingEmails() async {
    final db = await database;
    return await db.query(
      'email_outbox',
      where: 'status = ?',
      whereArgs: ['PENDING'],
      orderBy: 'created_at ASC',
    );
  }

  /// Log manual review resolution for tamper-proof audit trail
  Future<void> logAuditResolution({
    required String scanResultId,
    required int questionNumber,
    String? originalOption,
    required String resolvedOption,
    String reviewerId = 'staff_examiner',
    String? reason,
  }) async {
    final db = await database;
    await db.insert('audit_logs', {
      'id': 'audit_${DateTime.now().millisecondsSinceEpoch}_$questionNumber',
      'scan_result_id': scanResultId,
      'question_number': questionNumber,
      'original_option': originalOption,
      'resolved_option': resolvedOption,
      'reviewer_id': reviewerId,
      'reason': reason ?? 'Staff verified ambiguous mark',
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Fetch audit trail for a scan result
  Future<List<Map<String, dynamic>>> getAuditLogs(String scanResultId) async {
    final db = await database;
    return await db.query(
      'audit_logs',
      where: 'scan_result_id = ?',
      whereArgs: [scanResultId],
      orderBy: 'created_at ASC',
    );
  }

  /// Close database
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
