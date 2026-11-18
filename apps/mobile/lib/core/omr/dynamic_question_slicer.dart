import 'package:omr_mobile_app/core/omr/template_model.dart';
import 'package:omr_mobile_app/core/omr/universal_200q_template.dart';

/// Dynamic Question Slicer for Single Fixed OMR Sheet.
/// Dynamically slices active question regions 1..N based on exam configuration.
class DynamicQuestionSlicer {
  final MasterTemplateBlueprint masterBlueprint;

  DynamicQuestionSlicer({MasterTemplateBlueprint? blueprint})
      : masterBlueprint = blueprint ?? universal200qMasterBlueprint;

  /// Returns active question definitions for an exam configured with [totalQuestions] (e.g. 50, 75, 100).
  List<QuestionDefinition> getActiveQuestions(int totalQuestions) {
    if (totalQuestions <= 0) {
      throw ArgumentError('totalQuestions must be greater than 0');
    }
    final int effectiveLimit =
        totalQuestions.clamp(1, masterBlueprint.maxQuestions);

    final List<QuestionDefinition> active = [];
    for (int q = 1; q <= effectiveLimit; q++) {
      final qDef = masterBlueprint.allQuestions[q];
      if (qDef != null) {
        active.add(qDef);
      }
    }
    return active;
  }

  /// Returns the column breakdown for active questions (e.g. which columns are active).
  Map<int, int> getActiveQuestionsPerColumn(int totalQuestions) {
    final active = getActiveQuestions(totalQuestions);
    final Map<int, int> counts = {};
    for (final q in active) {
      counts[q.columnIndex] = (counts[q.columnIndex] ?? 0) + 1;
    }
    return counts;
  }
}
