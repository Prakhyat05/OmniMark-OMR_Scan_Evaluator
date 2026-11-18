/// Validation result for a decoded student code
class StudentCodeValidationResult {
  final String rawCode; // e.g. "224567" or "22?567"
  final bool isComplete; // True if all digits were clearly detected
  final bool isChecksumValid;
  final bool isEnrolled;
  final String? matchedStudentId;
  final String? suggestedMatch;
  final double confidence;
  final List<String> errors;

  const StudentCodeValidationResult({
    required this.rawCode,
    required this.isComplete,
    required this.isChecksumValid,
    required this.isEnrolled,
    this.matchedStudentId,
    this.suggestedMatch,
    required this.confidence,
    required this.errors,
  });

  bool get isApproved => isComplete && isEnrolled && errors.isEmpty;
}

/// Student Identity Triangulator & Checksum Hardener for OMR Sheets.
/// Validates student roll numbers against check-digits and enrolled roster
/// to prevent identity misattribution and silent overwrites.
class StudentCodeValidator {
  const StudentCodeValidator();

  /// Calculates Modulo-11 checksum digit for a 5-digit base roll number.
  /// Weights: [7, 6, 5, 4, 3]. Checksum = (sum * 7) % 10.
  static String calculateModulo11CheckDigit(String base5Digits) {
    if (base5Digits.length != 5) return '0';
    const weights = [7, 6, 5, 4, 3];
    int sum = 0;
    for (int i = 0; i < 5; i++) {
      final d = int.tryParse(base5Digits[i]) ?? 0;
      sum += d * weights[i];
    }
    final int check = (sum * 7) % 10;
    return check.toString();
  }

  /// Validates a 6-digit student code against optional Modulo-11 check digit.
  static bool verifyModulo11(String code6Digits) {
    if (code6Digits.length != 6) return false;
    final base5 = code6Digits.substring(0, 5);
    final expectedCheck = calculateModulo11CheckDigit(base5);
    return code6Digits[5] == expectedCheck;
  }

  /// Calculates Levenshtein distance between two strings.
  static int levenshteinDistance(String s1, String s2) {
    if (s1 == s2) return 0;
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    List<int> v0 = List<int>.generate(s2.length + 1, (i) => i);
    List<int> v1 = List<int>.filled(s2.length + 1, 0);

    for (int i = 0; i < s1.length; i++) {
      v1[0] = i + 1;
      for (int j = 0; j < s2.length; j++) {
        final cost = (s1[i] == s2[j]) ? 0 : 1;
        final int m1 = v0[j + 1] + 1;
        final int m2 = v1[j] + 1;
        final int m3 = v0[j] + cost;
        int minVal = m1;
        if (m2 < minVal) minVal = m2;
        if (m3 < minVal) minVal = m3;
        v1[j + 1] = minVal;
      }
      for (int j = 0; j <= s2.length; j++) {
        v0[j] = v1[j];
      }
    }
    return v1[s2.length];
  }

  /// Validates decoded student code against enrolled roster codes.
  StudentCodeValidationResult validate({
    required String rawCode,
    required List<String> enrolledRosterCodes,
    bool enforceModulo11 = false,
  }) {
    final List<String> errors = [];
    final bool isComplete = !rawCode.contains('?') && rawCode.length == 6;

    if (!isComplete) {
      errors.add('Incomplete or missing student code digits ($rawCode)');
    }

    bool isChecksumValid = true;
    if (enforceModulo11 && isComplete) {
      isChecksumValid = verifyModulo11(rawCode);
      if (!isChecksumValid) {
        errors.add('Modulo-11 check digit verification failed for $rawCode');
      }
    }

    final bool isEnrolled = enrolledRosterCodes.contains(rawCode);
    String? suggestedMatch;

    if (!isEnrolled && isComplete && enrolledRosterCodes.isNotEmpty) {
      // Look for a close roster match (distance == 1)
      for (final rosterCode in enrolledRosterCodes) {
        if (levenshteinDistance(rawCode, rosterCode) == 1) {
          suggestedMatch = rosterCode;
          break;
        }
      }
      errors.add('Student roll $rawCode is not enrolled in this assessment');
    }

    double confidence = 1.0;
    if (!isComplete) confidence -= 0.50;
    if (!isChecksumValid) confidence -= 0.30;
    if (!isEnrolled) confidence -= 0.20;

    return StudentCodeValidationResult(
      rawCode: rawCode,
      isComplete: isComplete,
      isChecksumValid: isChecksumValid,
      isEnrolled: isEnrolled,
      suggestedMatch: suggestedMatch,
      confidence: confidence.clamp(0.0, 1.0),
      errors: errors,
    );
  }
}
