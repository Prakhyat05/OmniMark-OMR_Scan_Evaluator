import cv2
import numpy as np

img = cv2.imread(r"C:\Users\prakh\.gemini\antigravity-ide\brain\392984a1-a503-4623-8270-82e8602f1fbf\.user_uploaded\media_1788415720046.jpg", 0)
h, w = img.shape

# Let's inspect Column 1 (Q1 to Q26) for Sample 3
# In Sample 3: Left fiducial = 115.0, Right = 630.0, Grid width = 515.0
# Col 1 label_x = 115.0 + 0.0437 * 515.0 = 137.5 px
y0 = int(round(0.2744 * h))
dy = 12.70
bp = 14

print("Sample 3 (Vaibhav) Col 1 inspection (Q1..26):")
for q in range(1, 27):
    idx = q - 1
    expected_y = int(round(y0 + idx * dy))
    label_x = 137
    
    crop_y = img[expected_y-3:expected_y+4, label_x-1:label_x+3]
    _, _, min_loc, _ = cv2.minMaxLoc(crop_y)
    actual_y = expected_y - 3 + min_loc[1]
    
    b1_x = label_x + int(round(1.25 * bp))
    scores = []
    for opt in range(4):
        bx = b1_x + opt * bp
        by = actual_y
        roi = img[by-4:by+5, bx-5:bx+6]
        min_v = np.min(roi)
        mean_v = np.mean(roi)
        scores.append(round(0.5 * min_v + 0.5 * mean_v, 1))
        
    sorted_s = sorted(scores)
    gap = sorted_s[1] - sorted_s[0]
    best_opt = np.argmin(scores)
    
    det = None
    if scores[best_opt] < 110.0 and gap > 16.0:
        det = str(best_opt + 1)
    elif sorted_s[0] < 95.0 and sorted_s[1] < 95.0 and gap < 16.0:
        det = "MULTIPLE"
        
    print(f"Q{q:2d}: actual_y={actual_y} | scores={scores} | min={min(scores)} | detected={det}")
