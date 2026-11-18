import 'template_model.dart';

/// Complete Ground Truth Coordinate Blueprint for Universal 200Q Sheet.
/// Calibrated to exact printed oval bubble geometry (Options 1, 2, 3, 4).
class Universal200QBlueprint {
  static const int totalQuestions = 200;
  static const int maxQuestions = 200;
  
  // Exact Oval Radius (Normalized)
  static const double bubbleRxNorm = 0.0070; // Oval horizontal radius
  static const double bubbleRyNorm = 0.0055; // Oval vertical radius

  // 6-Digit Student Code Block (Normalized - Calibrated to Scanned Photos)
  static const List<double> codeColXNorm = [
    0.19205, 0.20955, 0.22705, 0.24455, 0.26205, 0.27955,
  ];
  static const double codeStartYNorm = 0.13867;
  static const double codePitchYNorm = 0.01260;

  // 6 Column Starting Coordinates [Q_start, Q_end, Opt1_X_Norm, Start_Y_Norm]
  static const double optStepXNorm = 0.01781;
  static const double rowPitchYNorm = 0.01390;

  // Code grid definitions
  static final List<CodeColumnDefinition> codeGrid = List.generate(6, (colIdx) {
    return CodeColumnDefinition(
      columnIndex: colIdx + 1,
      cxNorm: codeColXNorm[colIdx],
      digits: List.generate(10, (digit) {
        return BubbleLocation(
          label: digit.toString(),
          index: digit,
          cxNorm: codeColXNorm[colIdx],
          cyNorm: codeStartYNorm + digit * codePitchYNorm,
          radiusNorm: bubbleRxNorm,
        );
      }),
    );
  });

  static final Map<int, QuestionDefinition> allQuestions = {
    for (final entry in questionGrid.entries)
      entry.key: QuestionDefinition(
        questionNumber: entry.key,
        columnIndex: _getColumnForQuestion(entry.key),
        rowIndex: _getRowForQuestion(entry.key),
        options: [
          for (int i = 0; i < 4; i++)
            BubbleLocation(
              label: (i + 1).toString(), // '1', '2', '3', '4'
              index: i + 1,
              cxNorm: entry.value.optXNorm[i],
              cyNorm: entry.value.yNorm,
              radiusNorm: bubbleRxNorm,
            ),
        ],
      ),
  };

  static int _getColumnForQuestion(int q) {
    if (q <= 26) return 0;
    if (q <= 52) return 1;
    if (q <= 89) return 2;
    if (q <= 126) return 3;
    if (q <= 163) return 4;
    return 5;
  }

  static int _getRowForQuestion(int q) {
    if (q <= 26) return q - 1;
    if (q <= 52) return q - 27;
    if (q <= 89) return q - 53;
    if (q <= 126) return q - 90;
    if (q <= 163) return q - 127;
    return q - 164;
  }

  // Exact 200 Questions Grid with [1, 2, 3, 4] bubble centers
  static final Map<int, QuestionCoords> questionGrid = _generateQuestionGrid();

  static Map<int, QuestionCoords> _generateQuestionGrid() {
    final Map<int, QuestionCoords> grid = {};
    const cols = [
      (1, 26, 0.20959, 0.28200),
      (27, 52, 0.32750, 0.28200),
      (53, 89, 0.45700, 0.13800),
      (90, 126, 0.57500, 0.13800),
      (127, 163, 0.70400, 0.13800),
      (164, 200, 0.82200, 0.13800),
    ];

    for (final col in cols) {
      final int qStart = col.$1;
      final int qEnd = col.$2;
      final double opt1X = col.$3;
      final double y0 = col.$4;

      for (int i = 0; i <= qEnd - qStart; i++) {
        final int q = qStart + i;
        final double cy = y0 + i * rowPitchYNorm;
        final List<double> optsX = [
          opt1X,
          opt1X + optStepXNorm,
          opt1X + optStepXNorm * 2,
          opt1X + optStepXNorm * 3,
        ];

        grid[q] = QuestionCoords(
          questionNumber: q,
          optXNorm: optsX,
          yNorm: cy,
          rxNorm: bubbleRxNorm,
          ryNorm: bubbleRyNorm,
        );
      }
    }
    return grid;
  }
}

final universal200qMasterBlueprint = MasterTemplateBlueprint(
  templateId: 'universal_200q_master',
  name: 'Universal 200Q Master Sheet',
  aspectRatio: 730.0 / 1024.0,
  fiducials: const {
    'TL': NormalizedPoint(x: 0.05, y: 0.03),
    'TR': NormalizedPoint(x: 0.95, y: 0.03),
    'BL': NormalizedPoint(x: 0.05, y: 0.97),
    'BR': NormalizedPoint(x: 0.95, y: 0.97),
  },
  codeGrid: Universal200QBlueprint.codeGrid,
  allQuestions: Universal200QBlueprint.allQuestions,
);

class QuestionCoords {
  final int questionNumber;
  final List<double> optXNorm;
  final double yNorm;
  final double rxNorm;
  final double ryNorm;

  const QuestionCoords({
    required this.questionNumber,
    required this.optXNorm,
    required this.yNorm,
    this.rxNorm = 0.0070,
    this.ryNorm = 0.0055,
  });
}
