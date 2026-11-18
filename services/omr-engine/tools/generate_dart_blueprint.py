import fitz
import json

doc = fitz.open("services/omr-engine/assets/vishwas_200q_master.pdf")
page = doc[0]
w_pt, h_pt = page.rect.width, page.rect.height
words = page.get_text("words")

master_blueprint = {}
for q in range(1, 201):
    matching = [w for w in words if w[4] == str(q) and w[1] > 90]
    if matching:
        w_label = matching[0]
        lx, ly = w_label[0], w_label[1]
        opts = [w for w in words if abs(w[1] - ly) < 4 and w[0] > lx and w[4] in ['1', '2', '3', '4']]
        opts_sorted = sorted(opts, key=lambda x: x[0])
        if len(opts_sorted) >= 4:
            master_blueprint[q] = {
                'q': q,
                'opt_x_norm': [round(o[0] / w_pt, 5) for o in opts_sorted[:4]],
                'y_norm': round(ly / h_pt, 5),
            }

# Save JSON
json_path = "services/omr-engine/assets/vishwas_200q_template.json"
with open(json_path, "w") as f:
    json.dump(master_blueprint, f, indent=2)

print(f"Saved {json_path}")

# Generate Dart file
dart_lines = [
    "import 'template_model.dart';",
    "",
    "/// Complete Ground Truth Coordinate Blueprint for Universal 200Q Sheet.",
    "/// Extracted with subpixel precision from the canonical vector master PDF.",
    "class Universal200QBlueprint {",
    "  static const int totalQuestions = 200;",
    "  static const double bubbleRadiusNorm = 0.0075;",
    "",
    "  // 6-Digit Student Code Block (Normalized)",
    "  static const List<double> codeColXNorm = [",
    "    0.17353, 0.19168, 0.21018, 0.22884, 0.24734, 0.26550,",
    "  ];",
    "  static const double codeStartYNorm = 0.12177;",
    "  static const double codePitchYNorm = 0.01287;",
    "",
    "  // Exact Coordinates for all 200 Questions [Q: (opt_x_norm: [A, B, C, D], y_norm)]",
    "  static final Map<int, QuestionCoords> questionGrid = {",
]

for q in range(1, 201):
    bp = master_blueprint[q]
    opts_str = ", ".join([str(x) for x in bp['opt_x_norm']])
    y_str = str(bp['y_norm'])
    dart_lines.append(f"    {q}: const QuestionCoords(questionNumber: {q}, optXNorm: [{opts_str}], yNorm: {y_str}),")

dart_lines.extend([
    "  };",
    "}",
    "",
    "class QuestionCoords {",
    "  final int questionNumber;",
    "  final List<double> optXNorm;",
    "  final double yNorm;",
    "",
    "  const QuestionCoords({",
    "    required this.questionNumber,",
    "    required this.optXNorm,",
    "    required this.yNorm,",
    "  });",
    "}",
])

dart_code = "\n".join(dart_lines)
with open("apps/mobile/lib/core/omr/universal_200q_template.dart", "w") as f:
    f.write(dart_code)

print("Saved apps/mobile/lib/core/omr/universal_200q_template.dart")
