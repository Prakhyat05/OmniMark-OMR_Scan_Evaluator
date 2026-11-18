import cv2
import numpy as np

# Load Sample 1 (Vedehi - 224567)
sample1_path = r"C:\Users\prakh\.gemini\antigravity-ide\brain\392984a1-a503-4623-8270-82e8602f1fbf\.user_uploaded\media_1788415707484.jpg"
img1 = cv2.imread(sample1_path)
h1, w1 = img1.shape[:2]
gray1 = cv2.cvtColor(img1, cv2.COLOR_BGR2GRAY)

print("=== SAMPLE 1 (VEDEHI: Expected 224567) 6-DIGIT CODE DETAIL ===")
cols_x = [0.17353, 0.19168, 0.21025, 0.22881, 0.24737, 0.26553]

# Let's inspect digit intensities for each of the 6 columns
for c_idx, cx_norm in enumerate(cols_x):
    cx = int(cx_norm * w1)
    print(f"\n--- Col {c_idx+1} (cx={cx}) ---")
    vals = []
    for d in range(10):
        cy = int((0.12180 + d * 0.01302) * h1)
        r = int(0.0055 * w1)
        roi = gray1[max(0, cy-r):min(h1, cy+r+1), max(0, cx-r):min(w1, cx+r+1)]
        val = cv2.mean(roi)[0] if roi.size > 0 else 255.0
        vals.append((d, round(val, 1), cy))
    
    sorted_v = sorted(vals, key=lambda x: x[1])
    print(f"Top 3 darkest digits in Col {c_idx+1}: {sorted_v[:3]}")

# Crop the 6-digit code block and save with annotated dots
vis = img1.copy()
for c_idx, cx_norm in enumerate(cols_x):
    cx = int(cx_norm * w1)
    for d in range(10):
        cy = int((0.12180 + d * 0.01302) * h1)
        cv2.circle(vis, (cx, cy), int(0.0055 * w1), (0, 0, 255), 1)

code_crop = vis[int(0.10*h1):int(0.26*h1), int(0.15*w1):int(0.29*w1)]
cv2.imwrite("code_grid_debug.jpg", code_crop)
print("\nSaved code_grid_debug.jpg")
