import cv2
import numpy as np
import json

with open("services/omr-engine/assets/exact_vector_blueprint.json") as f:
    data = json.load(f)

qs = data['questions']

# Load Sample 2 (Amar Singh)
sample2_path = r"C:\Users\prakh\.gemini\antigravity-ide\brain\392984a1-a503-4623-8270-82e8602f1fbf\.user_uploaded\media_1788415714038.jpg"
img = cv2.imread(sample2_path)
h, w = img.shape[:2]
gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)

print("=== EVALUATION OF SAMPLE 2 (AMAR SINGH) WITH 1, 2, 3, 4 OPTIONS ===")
for q_num in range(1, 27):
    q_info = qs[str(q_num)]
    cy = int(q_info['opt_cy_norm'] * h)
    rx = int(q_info['rx_norm'] * w)
    ry = int(q_info['ry_norm'] * h)
    
    vals = []
    for opt_idx, opt_char in enumerate(['1', '2', '3', '4']):
        cx = int(q_info['opt_cx_norm'][opt_idx] * w)
        # Sample ellipse mask
        mask = np.zeros((ry*2+1, rx*2+1), dtype=np.uint8)
        cv2.ellipse(mask, (rx, ry), (rx-1, ry-1), 0, 0, 360, 255, -1)
        roi = gray[max(0, cy-ry):min(h, cy+ry+1), max(0, cx-rx):min(w, cx+rx+1)]
        val = cv2.mean(roi, mask=mask)[0] if roi.shape == mask.shape else 255.0
        vals.append((opt_char, round(val, 1)))
    
    min_opt, min_val = min(vals, key=lambda x: x[1])
    sorted_v = sorted([v[1] for v in vals])
    gap = sorted_v[1] - sorted_v[0]
    res = min_opt if (min_val < 165.0 and gap > 25.0) else "-"
    print(f"Q{q_num:2d}: Detected '{res}' (min={min_val}, gap={gap:.1f}) | {vals}")
