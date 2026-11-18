import cv2
import numpy as np

sample2_path = r"C:\Users\prakh\.gemini\antigravity-ide\brain\392984a1-a503-4623-8270-82e8602f1fbf\.user_uploaded\media_1788415714038.jpg"
img = cv2.imread(sample2_path)
h, w = img.shape[:2]
gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)

# Check Col 2 (Q27..52)
# Let's inspect rows around Q49, Q50, Q51, Q52
print("Col 2 rows around Q49..Q52:")
for q in [48, 49, 50, 51, 52]:
    expected_y = int((0.2750 + (q - 27) * 0.01270) * h)
    # Search label
    crop = gray[expected_y-4:expected_y+5, 205:220]
    min_v, _, min_loc, _ = cv2.minMaxLoc(crop)
    lx = 205 + min_loc[0]
    ly = expected_y - 4 + min_loc[1]
    
    # Check 4 bubbles
    b1_x = lx + int(1.25 * 13.5)
    b_vals = []
    for opt in range(4):
        bx = b1_x + opt * 14
        roi = gray[ly-5:ly+6, bx-5:bx+6]
        b_vals.append(round(0.5*np.min(roi) + 0.5*np.mean(roi), 1))
    print(f"Q{q}: label at (x={lx}, y={ly}) | bubble scores: {b_vals} | min={min(b_vals)}")
