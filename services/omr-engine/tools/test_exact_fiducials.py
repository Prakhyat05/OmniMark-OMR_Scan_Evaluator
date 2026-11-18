import cv2
import numpy as np

sample2_path = r"C:\Users\prakh\.gemini\antigravity-ide\brain\392984a1-a503-4623-8270-82e8602f1fbf\.user_uploaded\media_1788415714038.jpg"
img = cv2.imread(sample2_path)
h, w = img.shape[:2]
gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)

# The leftmost fiducial markers are strictly on the outer left margin: x < 0.17 * w
# The rightmost fiducial markers are strictly on the outer right margin: x > 0.83 * w
left_strip = gray[:, :int(0.17 * w)]
right_strip = gray[:, int(0.83 * w):]

# Find solid black squares
_, thresh_l = cv2.threshold(left_strip, 60, 255, cv2.THRESH_BINARY_INV)
_, thresh_r = cv2.threshold(right_strip, 60, 255, cv2.THRESH_BINARY_INV)

cnts_l, _ = cv2.findContours(thresh_l, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
cnts_r, _ = cv2.findContours(thresh_r, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)

left_x = []
left_pts = []
for c in cnts_l:
    x, y, bw, bh = cv2.boundingRect(c)
    if 5 <= bw <= 18 and 5 <= bh <= 18 and 0.65 <= bw/bh <= 1.5:
        left_x.append(x + bw/2.0)
        left_pts.append((x + bw/2.0, y + bh/2.0))

right_x = []
right_pts = []
for c in cnts_r:
    x, y, bw, bh = cv2.boundingRect(c)
    if 5 <= bw <= 18 and 5 <= bh <= 18 and 0.65 <= bw/bh <= 1.5:
        right_x.append(int(0.83 * w) + x + bw/2.0)
        right_pts.append((int(0.83 * w) + x + bw/2.0, y + bh/2.0))

med_left_x = float(np.median(left_x))
med_right_x = float(np.median(right_x))
print(f"Leftmost fiducial column X:  {med_left_x:.1f} px (norm={med_left_x/w:.4f}) with {len(left_x)} markers")
print(f"Rightmost fiducial column X: {med_right_x:.1f} px (norm={med_right_x/w:.4f}) with {len(right_x)} markers")

grid_w = med_right_x - med_left_x
print(f"Grid width: {grid_w:.1f} px")

# Canonical column offsets from leftmost fiducial:
# Col 1: (103.25 - 84.06) / 438.96 = 0.0437 -> 113.0 + 0.0437 * 511.0 = 135.3 px!
# Col 2: (169.00 - 84.06) / 438.96 = 0.1935 -> 113.0 + 0.1935 * 511.0 = 211.9 px!
# Col 3: (239.50 - 84.06) / 438.96 = 0.3541 -> 113.0 + 0.3541 * 511.0 = 294.0 px!
# Col 4: (310.20 - 84.06) / 438.96 = 0.5152 -> 113.0 + 0.5152 * 511.0 = 376.3 px!
# Col 5: (380.80 - 84.06) / 438.96 = 0.6760 -> 113.0 + 0.6760 * 511.0 = 458.5 px!
# Col 6: (451.50 - 84.06) / 438.96 = 0.8371 -> 113.0 + 0.8371 * 511.0 = 540.8 px!
print("\nPredicted Column label X coordinates from fiducials:")
for idx, r in enumerate([0.0437, 0.1935, 0.3541, 0.5152, 0.6760, 0.8371], 1):
    col_x = med_left_x + r * grid_w
    print(f"  Col {idx}: x = {col_x:.1f} px (norm={col_x/w:.4f})")
