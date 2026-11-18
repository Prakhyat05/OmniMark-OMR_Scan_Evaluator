import cv2
import numpy as np

sample2_path = r"C:\Users\prakh\.gemini\antigravity-ide\brain\392984a1-a503-4623-8270-82e8602f1fbf\.user_uploaded\media_1788415714038.jpg"
img = cv2.imread(sample2_path)
h, w = img.shape[:2]
gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)

# The "TESTING" exam answer key:
# Q1..26:   '1'
# Q27..52:  '2'
# Q53..89:  '3'
# Q90..126: '4'
# Q127..163:'1'
# Q164..200:'2'
testing_key = {}
for q in range(1, 27): testing_key[q] = '1'
for q in range(27, 53): testing_key[q] = '2'
for q in range(53, 90): testing_key[q] = '3'
for q in range(90, 127): testing_key[q] = '4'
for q in range(127, 164): testing_key[q] = '1'
for q in range(164, 201): testing_key[q] = '2'

# Ground truth from user:
# Only [10, 20, 30, 40, 50, 60, 70, 71, 80] are incorrect!
# Total 93 questions marked (Q1..93). Q94..200 are BLANK.
expected_incorrect = {10, 20, 30, 40, 50, 60, 70, 71, 80}

# Exact column blueprints with row_pitch = 0.01270 (13.0 px):
# Col 1: Q1..26   label_x = 0.184, y0 = 0.2750
# Col 2: Q27..52  label_x = 0.290, y0 = 0.2750
# Col 3: Q53..89  label_x = 0.403, y0 = 0.1357
# Col 4: Q90..126 label_x = 0.516, y0 = 0.1357
# Col 5: Q127..163label_x = 0.630, y0 = 0.1357
# Col 6: Q164..200label_x = 0.742, y0 = 0.1357

cols = [
    (1, 26, 0.184, 0.2750, 0.01270, 0.0185),
    (27, 52, 0.290, 0.2750, 0.01270, 0.0185),
    (53, 89, 0.403, 0.1357, 0.01270, 0.0185),
    (90, 126, 0.516, 0.1357, 0.01270, 0.0185),
    (127, 163, 0.630, 0.1357, 0.01270, 0.0185),
    (164, 200, 0.742, 0.1357, 0.01270, 0.0185),
]

detected_answers = {}

for q_start, q_end, label_x_norm, y0_norm, dy_norm, bp_norm in cols:
    bubble_pitch = int(bp_norm * w)
    
    for idx in range(q_end - q_start + 1):
        q = q_start + idx
        expected_y = int((y0_norm + idx * dy_norm) * h)
        expected_label_x = int(label_x_norm * w)
        
        # Look for local label ink
        q_crop = gray[expected_y-3:expected_y+4, expected_label_x-6:expected_label_x+7]
        _, _, min_loc, _ = cv2.minMaxLoc(q_crop)
        actual_label_x = expected_label_x - 6 + min_loc[0]
        actual_y = expected_y - 3 + min_loc[1]
        
        b1_x = actual_label_x + int(1.25 * bubble_pitch)
        
        scores = []
        for opt_idx in range(4):
            bx = b1_x + opt_idx * bubble_pitch
            by = actual_y
            
            rx = int(bubble_pitch * 0.38)
            ry = int(dy_norm * h * 0.38)
            
            roi = gray[by-ry:by+ry+1, bx-rx:bx+rx+1]
            if roi.size == 0:
                scores.append(255)
                continue
            min_v = np.min(roi)
            mean_v = np.mean(roi)
            scores.append(0.5 * min_v + 0.5 * mean_v)
        
        best_opt = int(np.argmin(scores))
        best_score = scores[best_opt]
        sorted_scores = sorted(scores)
        contrast = sorted_scores[1] - sorted_scores[0]
        
        # Detect marked bubble: ink is dark (< 150) and contrast > 20
        if best_score < 150 and contrast > 20:
            detected_answers[q] = str(best_opt + 1)
        else:
            detected_answers[q] = None

correct = []
incorrect = []
unattempted = []

for q in range(1, 201):
    det = detected_answers[q]
    key = testing_key[q]
    if det is None:
        unattempted.append(q)
    elif det == key:
        correct.append(q)
    else:
        incorrect.append((q, det, key))

print("=== GROUND TRUTH EVALUATION TEST ===")
print(f"Total Correct:     {len(correct)} (Expected: 84)")
print(f"Total Incorrect:   {len(incorrect)} (Expected: 9)")
print(f"Total Unattempted: {len(unattempted)} (Expected: 107)")
print(f"\nDetected Incorrect questions: {[q for q, _, _ in incorrect]}")
print(f"Expected Incorrect:           {sorted(list(expected_incorrect))}")
