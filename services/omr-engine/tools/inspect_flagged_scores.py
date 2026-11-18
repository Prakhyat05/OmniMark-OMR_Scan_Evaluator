import cv2
import numpy as np

sample2_path = r"C:\Users\prakh\.gemini\antigravity-ide\brain\392984a1-a503-4623-8270-82e8602f1fbf\.user_uploaded\media_1788415714038.jpg"
img = cv2.imread(sample2_path)
h, w = img.shape[:2]
gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)

cols = [
    (53, 89, 294, 140, 12.75),
    (90, 126, 377, 140, 12.75),
]

print("Inspecting flagged questions:")
for q_target in [63, 69, 71, 87, 89, 90, 92]:
    for q_start, q_end, label_x, y0, dy in cols:
        if q_start <= q_target <= q_end:
            idx = q_target - q_start
            expected_y = int(y0 + idx * dy)
            q_crop = gray[max(0, expected_y-3):min(h, expected_y+4), max(0, label_x-6):min(w, label_x+7)]
            _, _, min_loc, _ = cv2.minMaxLoc(q_crop)
            actual_lx = label_x - 6 + min_loc[0]
            actual_ly = expected_y - 3 + min_loc[1]
            b1_x = actual_lx + int(1.25 * 14)
            scores = []
            for opt in range(4):
                bx = b1_x + opt * 14
                by = actual_ly
                roi = gray[max(0, by-4):min(h, by+5), max(0, bx-5):min(w, bx+6)]
                min_v = np.min(roi)
                mean_v = np.mean(roi)
                scores.append(0.5 * min_v + 0.5 * mean_v)
            print(f"Q{q_target}: actual_y={actual_ly} | scores={[round(s,1) for s in scores]}")
