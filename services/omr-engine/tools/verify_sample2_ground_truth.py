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

# Exact column definitions:
# (q_start, q_end, label_x_norm, start_y_norm, row_pitch_norm, bubble_pitch_norm)
# In 730x1024:
# Col 1: label_x = 135 px (norm = 0.185) | start_y = 280 px (norm = 0.273)
# Col 2: label_x = 212 px (norm = 0.290) | start_y = 280 px (norm = 0.273)
# Col 3: label_x = 294 px (norm = 0.403) | start_y = 136 px (norm = 0.133)
# Col 4: label_x = 377 px (norm = 0.516) | start_y = 136 px (norm = 0.133)
# Col 5: label_x = 460 px (norm = 0.630) | start_y = 136 px (norm = 0.133)
# Col 6: label_x = 542 px (norm = 0.742) | start_y = 136 px (norm = 0.133)

cols = [
    (1, 26, 0.185, 0.273, 0.01365, 0.0185),
    (27, 52, 0.290, 0.273, 0.01365, 0.0185),
    (53, 89, 0.403, 0.133, 0.01365, 0.0185),
    (90, 126, 0.516, 0.133, 0.01365, 0.0185),
    (127, 163, 0.630, 0.133, 0.01365, 0.0185),
    (164, 200, 0.742, 0.133, 0.01365, 0.0185),
]

detected_answers = {}

for q_start, q_end, label_x_norm, y0_norm, dy_norm, bp_norm in cols:
    bubble_pitch = int(bp_norm * w)
    
    for idx in range(q_end - q_start + 1):
        q = q_start + idx
        expected_y = int((y0_norm + idx * dy_norm) * h)
        expected_label_x = int(label_x_norm * w)
        
        # Search for label ink in window [-6..+6 x, -3..+3 y]
        q_crop = gray[expected_y-3:expected_y+4, expected_label_x-6:expected_label_x+7]
        _, _, min_loc, _ = cv2.minMaxLoc(q_crop)
        actual_label_x = expected_label_x - 6 + min_loc[0]
        actual_y = expected_y - 3 + min_loc[1]
        
        # Measure 4 bubbles
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
        
        if best_score < 155 and contrast > 25:
            detected_answers[q] = str(best_opt + 1)
        else:
            detected_answers[q] = None

# Evaluate against TESTING answer key:
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

print("=== EVALUATION SUMMARY ===")
print(f"Total Correct:    {len(correct)}")
print(f"Total Incorrect:  {len(incorrect)}")
print(f"Total Unattempted:{len(unattempted)}")
print(f"\nIncorrect questions: {incorrect}")
print(f"\nAttempted questions: {sorted([q for q in range(1, 201) if detected_answers[q] is not None])}")
