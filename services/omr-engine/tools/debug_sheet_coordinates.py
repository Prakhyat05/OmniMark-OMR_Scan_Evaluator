import cv2
import numpy as np
import json

# Load sample 2 (Amar Singh)
sample_path = r"C:\Users\prakh\.gemini\antigravity-ide\brain\392984a1-a503-4623-8270-82e8602f1fbf\.user_uploaded\media_1788415714038.jpg"
img = cv2.imread(sample_path)
h, w = img.shape[:2]
print(f"Sample image shape: {w}x{h}")

# Check normalized vs pixel coordinates
# Let's crop the Question 1..15 section of Column 1
# Col 1: Q1..26
# Normalized opt1_x = 0.20548, start_y = 0.28906, opt_step = 0.01932, row_pitch = 0.01401

col1_x0 = int(0.20548 * w)
start_y = int(0.28906 * h)
opt_step = int(0.01932 * w)
row_pitch = int(0.01401 * h)
bubble_r = int(0.0055 * w)

print(f"Col1 X0: {col1_x0}, Start Y: {start_y}, Opt Step: {opt_step}, Row Pitch: {row_pitch}, Bubble R: {bubble_r}")

gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)

print("\n--- Column 1 (Q1..20) Analysis ---")
for q in range(1, 21):
    cy = int(start_y + (q - 1) * 0.01401 * h)
    vals = []
    for opt_idx, opt_char in enumerate(['A', 'B', 'C', 'D']):
        cx = int((0.20548 + opt_idx * 0.01932) * w)
        # Sample circular mask
        mask = np.zeros((bubble_r*2+1, bubble_r*2+1), dtype=np.uint8)
        cv2.circle(mask, (bubble_r, bubble_r), bubble_r, 255, -1)
        roi = gray[max(0, cy-bubble_r):min(h, cy+bubble_r+1), max(0, cx-bubble_r):min(w, cx+bubble_r+1)]
        if roi.shape == mask.shape:
            mean_val = cv2.mean(roi, mask=mask)[0]
        else:
            mean_val = 255.0
        vals.append((opt_char, round(mean_val, 1)))
    
    # Check which option is lowest (darkest)
    min_opt, min_val = min(vals, key=lambda x: x[1])
    sorted_vals = sorted([v[1] for v in vals])
    gap = sorted_vals[1] - sorted_vals[0]
    print(f"Q{q:2d} (cy={cy}): {vals} -> Darkest: {min_opt} ({min_val}), Gap: {gap:.1f}")

# Let's also save an annotated crop of Column 1
annotated = img.copy()
for q in range(1, 27):
    cy = int(start_y + (q - 1) * 0.01401 * h)
    for opt_idx, opt_char in enumerate(['A', 'B', 'C', 'D']):
        cx = int((0.20548 + opt_idx * 0.01932) * w)
        cv2.circle(annotated, (cx, cy), bubble_r, (0, 0, 255), 2)
        cv2.putText(annotated, f"Q{q}", (cx - 100, cy + 5), cv2.FONT_HERSHEY_SIMPLEX, 0.4, (255, 0, 0), 1)

cv2.imwrite("col1_debug_overlay.jpg", annotated)
print("\nWrote col1_debug_overlay.jpg")
