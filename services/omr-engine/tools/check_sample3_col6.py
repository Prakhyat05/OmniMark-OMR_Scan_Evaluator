import cv2
import numpy as np

sample3_path = r"C:\Users\prakh\.gemini\antigravity-ide\brain\392984a1-a503-4623-8270-82e8602f1fbf\.user_uploaded\media_1788415720046.jpg"
img3 = cv2.imread(sample3_path)
h3, w3 = img3.shape[:2]
gray3 = cv2.cvtColor(img3, cv2.COLOR_BGR2GRAY)

col1_x_norm = 0.19205
pitch_x_norm = 0.01750
y0_norm = 0.13867
pitch_y_norm = 0.01260

print("=== SAMPLE 3 COL 6 DIGIT SCORES ===")
c_idx = 5
cx = int((col1_x_norm + c_idx * pitch_x_norm) * w3)
for d in range(10):
    cy = int((y0_norm + d * pitch_y_norm) * h3)
    r = int(0.0055 * w3)
    mask = np.zeros((r*2+1, r*2+1), dtype=np.uint8)
    cv2.circle(mask, (r, r), r, 255, -1)
    roi = gray3[max(0, cy-r):min(h3, cy+r+1), max(0, cx-r):min(w3, cx+r+1)]
    val = cv2.mean(roi, mask=mask)[0] if roi.shape == mask.shape else 255.0
    print(f"Digit {d} (cy={cy}): intensity={val:.1f}")
