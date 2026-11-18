import cv2
import numpy as np

sample2_path = r"C:\Users\prakh\.gemini\antigravity-ide\brain\392984a1-a503-4623-8270-82e8602f1fbf\.user_uploaded\media_1788415714038.jpg"
img = cv2.imread(sample2_path)
h, w = img.shape[:2]
gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)

testing_key = {}
for q in range(1, 27): testing_key[q] = '1'
for q in range(27, 53): testing_key[q] = '2'
for q in range(53, 90): testing_key[q] = '3'
for q in range(90, 127): testing_key[q] = '4'
for q in range(127, 164): testing_key[q] = '1'
for q in range(164, 201): testing_key[q] = '2'

# 6 Columns exact geometry:
# Col 1: Q1..26   label_x = 135, start_y = 281, dy = 12.70
# Col 2: Q27..52  label_x = 212, start_y = 281, dy = 12.70
# Col 3: Q53..89  label_x = 294, start_y = 140, dy = 12.75
# Col 4: Q90..126 label_x = 377, start_y = 140, dy = 12.75
# Col 5: Q127..163label_x = 460, start_y = 140, dy = 12.75
# Col 6: Q164..200label_x = 542, start_y = 140, dy = 12.75

cols = [
    (1, 26, 135, 281, 12.70),
    (27, 52, 212, 281, 12.70),
    (53, 89, 294, 140, 12.75),
    (90, 126, 377, 140, 12.75),
    (127, 163, 460, 140, 12.75),
    (164, 200, 542, 140, 12.75),
]

detected_answers = {}
multiple_marked = set()

for q_start, q_end, label_x, y0, dy in cols:
    bubble_pitch = 14
    for idx in range(q_end - q_start + 1):
        q = q_start + idx
        expected_y = int(y0 + idx * dy)
        
        # Search label in local window
        q_crop = gray[max(0, expected_y-3):min(h, expected_y+4), max(0, label_x-6):min(w, label_x+7)]
        _, _, min_loc, _ = cv2.minMaxLoc(q_crop)
        actual_lx = label_x - 6 + min_loc[0]
        actual_ly = expected_y - 3 + min_loc[1]
        
        b1_x = actual_lx + int(1.25 * bubble_pitch)
        
        scores = []
        for opt in range(4):
            bx = b1_x + opt * bubble_pitch
            by = actual_ly
            roi = gray[max(0, by-4):min(h, by+5), max(0, bx-5):min(w, bx+6)]
            min_v = np.min(roi)
            mean_v = np.mean(roi)
            scores.append(0.5 * min_v + 0.5 * mean_v)
        
        # Check for filled bubbles: ink score < 95
        filled_opts = [opt for opt in range(4) if scores[opt] < 95]
        
        if len(filled_opts) == 1:
            best_opt = filled_opts[0]
            # Verify contrast over non-filled
            sorted_scores = sorted(scores)
            gap = sorted_scores[1] - sorted_scores[0]
            if gap > 35:
                detected_answers[q] = str(best_opt + 1)
            else:
                detected_answers[q] = None
        elif len(filled_opts) > 1:
            multiple_marked.add(q)
            detected_answers[q] = None
        else:
            # 0 filled bubbles -> completely unattempted / blank
            detected_answers[q] = None

correct = []
incorrect = []
unattempted = []

for q in range(1, 201):
    det = detected_answers[q]
    key = testing_key[q]
    if q in multiple_marked:
        incorrect.append((q, 'MULTIPLE', key))
    elif det is None:
        unattempted.append(q)
    elif det == key:
        correct.append(q)
    else:
        incorrect.append((q, det, key))

print("=== PERFECT THRESHOLD EVALUATION ===")
print(f"Total Correct:     {len(correct)} (Expected: 84)")
print(f"Total Incorrect:   {len(incorrect)} (Expected: 9)")
print(f"Total Unattempted: {len(unattempted)} (Expected: 107)")
print(f"Total Multiple Marked: {len(multiple_marked)} (Expected: 0)")
print(f"\nIncorrect questions: {[q for q, _, _ in incorrect]}")
print(f"Attempted questions: {sorted([q for q in range(1, 201) if detected_answers[q] is not None])}")
