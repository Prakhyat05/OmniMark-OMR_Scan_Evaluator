import cv2
import numpy as np

sample2_path = r"C:\Users\prakh\.gemini\antigravity-ide\brain\392984a1-a503-4623-8270-82e8602f1fbf\.user_uploaded\media_1788415714038.jpg"
img = cv2.imread(sample2_path)
h, w = img.shape[:2]
gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)

# In Col 3 (Q53..89):
# Let's inspect rows 62 to 78 with fixed label X = 295 px!
# And search ONLY vertical Y in [-3..+3]
print("Testing Q62..78 with fixed column X (eliminating timing mark snap):")
bubble_pitch = 14
y0 = 140
dy = 12.75

for q in range(62, 78):
    idx = q - 53
    expected_y = int(y0 + idx * dy)
    label_x = 295
    
    # Search vertical y only near label_x (x in [293..297])
    crop_y = gray[max(0, expected_y-3):min(h, expected_y+4), label_x-1:label_x+3]
    _, _, min_loc, _ = cv2.minMaxLoc(crop_y)
    actual_y = expected_y - 3 + min_loc[1]
    
    b1_x = label_x + int(1.25 * bubble_pitch)
    
    scores = []
    for opt in range(4):
        bx = b1_x + opt * bubble_pitch
        by = actual_y
        roi = gray[max(0, by-4):min(h, by+5), max(0, bx-5):min(w, bx+6)]
        min_v = np.min(roi)
        mean_v = np.mean(roi)
        scores.append(round(0.5 * min_v + 0.5 * mean_v, 1))
    
    best_opt = np.argmin(scores)
    sorted_s = sorted(scores)
    gap = sorted_s[1] - sorted_s[0]
    
    # Detected
    det = None
    if scores[best_opt] < 110 and gap > 16:
        det = str(best_opt + 1)
        
    print(f"Q{q:2d}: actual_y={actual_y} | scores={scores} | detected={det}")
