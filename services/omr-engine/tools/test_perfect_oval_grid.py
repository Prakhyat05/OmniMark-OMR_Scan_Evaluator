import cv2
import numpy as np
import json

# Let's verify the starting X of all 6 columns on the real scanned sheet
# Col 1: Q1..26   -> opt1_x = 0.20959, y0 = 0.28200, dy = 0.01390
# Col 2: Q27..52  -> opt1_x = 0.32750, y0 = 0.28200, dy = 0.01390
# Col 3: Q53..89  -> opt1_x = 0.45700, y0 = 0.13800, dy = 0.01390
# Col 4: Q90..126 -> opt1_x = 0.57500, y0 = 0.13800, dy = 0.01390
# Col 5: Q127..163-> opt1_x = 0.70400, y0 = 0.13800, dy = 0.01390
# Col 6: Q164..200-> opt1_x = 0.82200, y0 = 0.13800, dy = 0.01390

# Let's test on Sample 1 (Vedehi)
sample1_path = r"C:\Users\prakh\.gemini\antigravity-ide\brain\392984a1-a503-4623-8270-82e8602f1fbf\.user_uploaded\media_1788415707484.jpg"
img1 = cv2.imread(sample1_path)
h1, w1 = img1.shape[:2]
gray1 = cv2.cvtColor(img1, cv2.COLOR_BGR2GRAY)

cols = [
    (1, 26, 0.20959, 0.28200),
    (27, 52, 0.32750, 0.28200),
    (53, 89, 0.45700, 0.13800),
    (90, 126, 0.57500, 0.13800),
    (127, 163, 0.70400, 0.13800),
    (164, 200, 0.82200, 0.13800),
]

dx = 0.01781
dy = 0.01390

grid = {}
for q_start, q_end, opt1_x, y0 in cols:
    for idx in range(q_end - q_start + 1):
        q = q_start + idx
        cy = y0 + idx * dy
        opts_x = [round(opt1_x + i * dx, 5) for i in range(4)]
        grid[q] = {
            'q': q,
            'opt_x_norm': opts_x,
            'y_norm': round(cy, 5),
            'rx_norm': 0.0070, # oval radius x
            'ry_norm': 0.0055, # oval radius y
        }

# Test sample 1 (Vedehi) with these coordinates
print("=== SAMPLE 1 (VEDEHI) REAL EVALUATION (Q1..50) ===")
for q in range(1, 51):
    g = grid[q]
    cy = int(g['y_norm'] * h1)
    vals = []
    for opt_idx, opt_char in enumerate(['1', '2', '3', '4']):
        cx = int(g['opt_x_norm'][opt_idx] * w1)
        rx = int(g['rx_norm'] * w1)
        ry = int(g['ry_norm'] * h1)
        mask = np.zeros((ry*2+1, rx*2+1), dtype=np.uint8)
        cv2.ellipse(mask, (rx, ry), (rx-1, ry-1), 0, 0, 360, 255, -1)
        roi = gray1[max(0, cy-ry):min(h1, cy+ry+1), max(0, cx-rx):min(w1, cx+rx+1)]
        val = cv2.mean(roi, mask=mask)[0] if roi.shape == mask.shape else 255.0
        vals.append((opt_char, round(val, 1)))
    
    min_opt, min_val = min(vals, key=lambda x: x[1])
    sorted_v = sorted([v[1] for v in vals])
    gap = sorted_v[1] - sorted_v[0]
    if min_val < 165.0 and gap > 25.0:
        print(f"Q{q:2d}: Detected Option '{min_opt}' (min={min_val}, gap={gap:.1f})")

# Also draw overlay on Sample 1
overlay1 = img1.copy()
for q in range(1, 51):
    g = grid[q]
    cy = int(g['y_norm'] * h1)
    rx = int(g['rx_norm'] * w1)
    ry = int(g['ry_norm'] * h1)
    for opt_idx in range(4):
        cx = int(g['opt_x_norm'][opt_idx] * w1)
        cv2.ellipse(overlay1, (cx, cy), (rx, ry), 0, 0, 360, (0, 255, 0), 1)

crop1 = overlay1[int(0.25*h1):int(0.62*h1), int(0.15*w1):int(0.40*w1)]
cv2.imwrite("sample1_perfect_oval_overlay.jpg", crop1)
print("\nSaved sample1_perfect_oval_overlay.jpg")
