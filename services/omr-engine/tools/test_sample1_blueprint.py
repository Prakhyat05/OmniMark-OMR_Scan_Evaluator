import cv2
import numpy as np
import fitz
import json

doc = fitz.open("services/omr-engine/assets/vishwas_200q_master.pdf")
page = doc[0]
w_pt, h_pt = page.rect.width, page.rect.height
words = page.get_text("words")

# Build exact ground truth dictionary for all 200 questions
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
                'opt_x_norm': [o[0] / w_pt for o in opts_sorted[:4]],
                'y_norm': ly / h_pt,
            }

sample1_path = r"C:\Users\prakh\.gemini\antigravity-ide\brain\392984a1-a503-4623-8270-82e8602f1fbf\.user_uploaded\media_1788415707484.jpg"
img1 = cv2.imread(sample1_path)
h1, w1 = img1.shape[:2]
gray1 = cv2.cvtColor(img1, cv2.COLOR_BGR2GRAY)

print("\n--- SAMPLE 1 (VEDEHI) EXACT EVALUATION (Q1..50) ---")
detected_all = {}
for q in range(1, 51):
    bp = master_blueprint[q]
    cy = int(bp['y_norm'] * h1)
    vals = []
    for opt_idx, opt_char in enumerate(['A', 'B', 'C', 'D']):
        cx = int(bp['opt_x_norm'][opt_idx] * w1)
        r = int(0.0055 * w1)
        mask = np.zeros((r*2+1, r*2+1), dtype=np.uint8)
        cv2.circle(mask, (r, r), r, 255, -1)
        roi = gray1[max(0, cy-r):min(h1, cy+r+1), max(0, cx-r):min(w1, cx+r+1)]
        val = cv2.mean(roi, mask=mask)[0] if roi.shape == mask.shape else 255.0
        vals.append((opt_char, round(val, 1)))
    
    min_opt, min_val = min(vals, key=lambda x: x[1])
    sorted_v = sorted([v[1] for v in vals])
    gap = sorted_v[1] - sorted_v[0]
    is_filled = gap > 25.0
    res = min_opt if is_filled else "-"
    detected_all[q] = res
    if res != "-":
        print(f"Q{q:2d}: {res} (min={min_val}, gap={gap:.1f})")

print(f"\nTotal questions marked in Q1..50: {sum(1 for v in detected_all.values() if v != '-')}")
