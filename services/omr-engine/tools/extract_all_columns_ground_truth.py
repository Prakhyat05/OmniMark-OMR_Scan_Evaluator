import fitz
import json

doc = fitz.open("services/omr-engine/assets/vishwas_200q_master.pdf")
page = doc[0]
w_pt, h_pt = page.rect.width, page.rect.height

words = page.get_text("words")

# Find the exact coordinates for all 6 columns and 200 questions!
# In Universal 200Q sheet:
# Col 1: Q1..26
# Col 2: Q27..52
# Col 3: Q53..89
# Col 4: Q90..126
# Col 5: Q127..163
# Col 6: Q164..200

# Let's extract the exact Option 1, 2, 3, 4 coordinates for every question from 1 to 200!
q_coords = {}

for q_num in range(1, 201):
    # Find word with this exact number
    matching = [w for w in words if w[4] == str(q_num)]
    if not matching:
        continue
    # Pick the one that is a question label (not student code row)
    # Question labels are all in the lower grid area (y > 90)
    valid_q = [w for w in matching if w[1] > 90]
    if valid_q:
        w_label = valid_q[0]
        lx, ly = w_label[0], w_label[1]
        
        # In this row (ly +/- 3 pt), find options '1', '2', '3', '4' to the right of lx
        opts = [w for w in words if abs(w[1] - ly) < 4 and w[0] > lx and w[4] in ['1', '2', '3', '4']]
        opts_sorted = sorted(opts, key=lambda x: x[0])
        if len(opts_sorted) >= 4:
            q_coords[q_num] = {
                'label_x': lx,
                'label_y': ly,
                'opt1_x': opts_sorted[0][0],
                'opt1_y': opts_sorted[0][1],
                'opt2_x': opts_sorted[1][0],
                'opt3_x': opts_sorted[2][0],
                'opt4_x': opts_sorted[3][0],
                'opt1_x_norm': opts_sorted[0][0] / w_pt,
                'opt1_y_norm': opts_sorted[0][1] / h_pt,
                'step_x_norm': (opts_sorted[3][0] - opts_sorted[0][0]) / 3.0 / w_pt,
            }

print(f"Extracted exact ground truth for {len(q_coords)} questions from PDF!")

# Summarize each column's start coordinates:
cols_summary = {
    'Col 1 (Q1..26)': q_coords[1],
    'Col 2 (Q27..52)': q_coords[27],
    'Col 3 (Q53..89)': q_coords[53],
    'Col 4 (Q90..126)': q_coords[90],
    'Col 5 (Q127..163)': q_coords[127],
    'Col 6 (Q164..200)': q_coords[164],
}

print("\n=== EXACT GROUND TRUTH BLUEPRINT ===")
for col_name, c in cols_summary.items():
    print(f"{col_name}: opt1_x_norm={c['opt1_x_norm']:.5f}, start_y_norm={c['opt1_y_norm']:.5f}, step_x_norm={c['step_x_norm']:.5f}")

# Check row pitch in Col 1 (Q1 to Q26)
pitches_col1 = [(q_coords[q+1]['opt1_y_norm'] - q_coords[q]['opt1_y_norm']) for q in range(1, 26)]
avg_pitch_col1 = sum(pitches_col1) / len(pitches_col1)
print(f"Avg Row Pitch (Col 1 & 2): {avg_pitch_col1:.5f} ({avg_pitch_col1 * h_pt:.2f} pt)")

# Check row pitch in Col 3 (Q53 to Q89)
pitches_col3 = [(q_coords[q+1]['opt1_y_norm'] - q_coords[q]['opt1_y_norm']) for q in range(53, 89)]
avg_pitch_col3 = sum(pitches_col3) / len(pitches_col3)
print(f"Avg Row Pitch (Col 3..6):  {avg_pitch_col3:.5f} ({avg_pitch_col3 * h_pt:.2f} pt)")
