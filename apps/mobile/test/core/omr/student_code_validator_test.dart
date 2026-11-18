import 'package:flutter_test/flutter_test.dart';
import 'package:omr_mobile_app/core/omr/student_code_validator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StudentCodeValidator validator;

  setUp(() {
    validator = const StudentCodeValidator();
  });

  group('StudentCodeValidator Tests', () {
    const roster = ['224567', '342105', '134768', '551234'];

    test('Approves complete enrolled student roll number', () {
      final result = validator.validate(
        rawCode: '224567',
        enrolledRosterCodes: roster,
      );

      expect(result.isComplete, isTrue);
      expect(result.isEnrolled, isTrue);
      expect(result.isApproved, isTrue);
      expect(result.errors, isEmpty);
      expect(result.confidence, equals(1.0));
    });

    test('Catches missing or unbubbled digit containing question mark', () {
      final result = validator.validate(
        rawCode: '22?567',
        enrolledRosterCodes: roster,
      );

      expect(result.isComplete, isFalse);
      expect(result.isApproved, isFalse);
      expect(result.confidence, lessThan(0.60));
      expect(result.errors.any((e) => e.contains('Incomplete')), isTrue);
    });

    test('Modulo-11 checksum correctly calculates and verifies check digit',
        () {
      const base = '22456';
      final checkDigit = StudentCodeValidator.calculateModulo11CheckDigit(base);
      final validCode = '$base$checkDigit';

      expect(StudentCodeValidator.verifyModulo11(validCode), isTrue);

      // Invalidate by corrupting check digit
      final corrupted = '$base${(int.parse(checkDigit) + 1) % 10}';
      expect(StudentCodeValidator.verifyModulo11(corrupted), isFalse);
    });

    test('Suggests enrolled match when student has single misbubbled digit',
        () {
      // Student marked '224561' instead of '224567'
      final result = validator.validate(
        rawCode: '224561',
        enrolledRosterCodes: roster,
      );

      expect(result.isEnrolled, isFalse);
      expect(result.isApproved, isFalse);
      expect(result.suggestedMatch, equals('224567'));
    });
  });
}
