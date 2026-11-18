/// Strongly typed OMR Template Data Structures for Offline On-Device Processing.
class NormalizedPoint {
  final double x;
  final double y;

  const NormalizedPoint({required this.x, required this.y});

  Map<String, dynamic> toJson() => {'x': x, 'y': y};
  factory NormalizedPoint.fromJson(Map<String, dynamic> json) {
    return NormalizedPoint(
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
    );
  }
}

class BubbleLocation {
  final String label; // "A", "B", "C", "D" or digit "0".."9"
  final int index; // 1..4 or 0..9
  final double cxNorm;
  final double cyNorm;
  final double radiusNorm;

  const BubbleLocation({
    required this.label,
    required this.index,
    required this.cxNorm,
    required this.cyNorm,
    required this.radiusNorm,
  });

  Map<String, dynamic> toJson() => {
        'label': label,
        'index': index,
        'cx_norm': cxNorm,
        'cy_norm': cyNorm,
        'radius_norm': radiusNorm,
      };

  factory BubbleLocation.fromJson(Map<String, dynamic> json) {
    return BubbleLocation(
      label: json['label'] as String,
      index: json['index'] as int,
      cxNorm: (json['cx_norm'] as num).toDouble(),
      cyNorm: (json['cy_norm'] as num).toDouble(),
      radiusNorm: (json['radius_norm'] as num).toDouble(),
    );
  }
}

class QuestionDefinition {
  final int questionNumber;
  final int columnIndex;
  final int rowIndex;
  final List<BubbleLocation> options;

  const QuestionDefinition({
    required this.questionNumber,
    required this.columnIndex,
    required this.rowIndex,
    required this.options,
  });

  Map<String, dynamic> toJson() => {
        'question_number': questionNumber,
        'column_index': columnIndex,
        'row_index': rowIndex,
        'options': options.map((o) => o.toJson()).toList(),
      };
}

class CodeColumnDefinition {
  final int columnIndex; // 1..6
  final double cxNorm;
  final List<BubbleLocation> digits; // 0..9

  const CodeColumnDefinition({
    required this.columnIndex,
    required this.cxNorm,
    required this.digits,
  });
}

class MasterTemplateBlueprint {
  final String templateId;
  final String name;
  final double aspectRatio;
  final Map<String, NormalizedPoint> fiducials;
  final List<CodeColumnDefinition> codeGrid;
  final Map<int, QuestionDefinition> allQuestions;

  const MasterTemplateBlueprint({
    required this.templateId,
    required this.name,
    required this.aspectRatio,
    required this.fiducials,
    required this.codeGrid,
    required this.allQuestions,
  });

  /// Total questions supported by this master layout (e.g. 200)
  int get maxQuestions => allQuestions.length;
}
