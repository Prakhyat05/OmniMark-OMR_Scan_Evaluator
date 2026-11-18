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
        
        sorted_indices = sorted(range(4), key=lambda k: scores[k])
        best_opt = sorted_indices[0]
        second_opt = sorted_indices[1]
        best_score = scores[best_opt]
        second_score = scores[second_opt]
        gap = second_score - best_score
        
        # Classification:
        # 1. Unattempted: best_score > 115 (no real bubble marked)
        if best_score > 115:
            detected_answers[q] = None
        # 2. Multiple marked: second bubble is also dark (< 95) and very close to best (< 16 diff)
        elif second_score < 95 and gap < 16:
            multiple_marked.add(q)
            detected_answers[q] = None
        # 3. Single marked: best bubble is dark and stands out
        elif best_score < 110 and gap > 16:
            detected_answers[q] = str(best_opt + 1)
        else:
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

print("=== REFINED EVALUATION TEST ===")
print(f"Total Correct:     {len(correct)} (Expected: 84)")
print(f"Total Incorrect:   {len(incorrect)} (Expected: 9)")
print(f"Total Unattempted: {len(unattempted)} (Expected: 107)")
print(f"Total Multiple Marked: {len(multiple_marked)} (Expected: 0)")
print(f"\nIncorrect questions: {[q for q, _, _ in incorrect]}")
