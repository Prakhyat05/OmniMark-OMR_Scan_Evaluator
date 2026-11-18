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

# User ground truth:
# Q1..93 are marked.
# Only [10, 20, 30, 40, 50, 60, 70, 71, 80] are incorrect!
# Remaining (Q94..200) are unattempted.
expected_incorrect = {10, 20, 30, 40, 50, 60, 70, 71, 80}

def get_row_peaks(col_img_crop, y_offset, expected_count):
    # Darkness profile in question label area
    darkness = np.mean(255.0 - col_img_crop[:, 5:35], axis=1)
    smoothed = cv2.GaussianBlur(darkness, (1, 5), 1.0).flatten()
    peaks = []
    for y in range(2, len(smoothed)-2):
        if smoothed[y] > smoothed[y-1] and smoothed[y] > smoothed[y+1] and smoothed[y] > 15:
            if not peaks or (y - peaks[-1]) >= 9:
                peaks.append(y)
    
    # If peaks count doesn't match, linearly interpolate from first to last peak
    if len(peaks) != expected_count:
        first_y = peaks[0] if peaks else 10
        last_y = peaks[-1] if len(peaks) > 1 else (first_y + (expected_count - 1) * 12.75)
        step = (last_y - first_y) / (expected_count - 1)
        orig_peaks = [int(y_offset + first_y + i * step) for i in range(expected_count)]
    else:
        orig_peaks = [y_offset + p for p in peaks]
    return orig_peaks

# Process each column
# Column horizontal boundaries and label x:
col_configs = [
    # col_idx, q_start, q_end, (crop_x1, crop_x2), label_x, y_start, (crop_y1, crop_y2)
    (1, 1, 26, (110, 210), 135, 270, (270, 620)),
    (2, 27, 52, (195, 290), 212, 270, (270, 620)),
    (3, 53, 89, (275, 375), 294, 125, (125, 620)),
    (4, 90, 126, (360, 455), 377, 125, (125, 620)),
    (5, 127, 163, (445, 540), 460, 125, (125, 620)),
    (6, 164, 200, (525, 625), 542, 125, (125, 620)),
]

detected_answers = {}

for col_idx, q_start, q_end, (cx1, cx2), label_x, y_start, (cy1, cy2) in col_configs:
    q_count = q_end - q_start + 1
    crop = gray[cy1:cy2, cx1:cx2]
    row_ys = get_row_peaks(crop, cy1, q_count)
    bubble_pitch = 14
    
    for i in range(q_count):
        q = q_start + i
        ry = row_ys[i]
        
        # Search label near label_x, ry
        crop_label = gray[max(0, ry-3):min(h, ry+4), max(0, label_x-6):min(w, label_x+7)]
        if crop_label.size == 0:
            detected_answers[q] = None
            continue
        _, _, min_loc, _ = cv2.minMaxLoc(crop_label)
        actual_lx = label_x - 6 + min_loc[0]
        actual_ly = ry - 3 + min_loc[1]
        
        b1_x = actual_lx + int(1.25 * bubble_pitch)
        
        scores = []
        for opt in range(4):
            bx = b1_x + opt * bubble_pitch
            by = actual_ly
            roi = gray[max(0, by-4):min(h, by+5), max(0, bx-5):min(w, bx+6)]
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
        
        # True marked bubble detection
        if best_score < 145 and contrast > 22:
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

print("=== FINAL GROUND TRUTH EVALUATION TEST ===")
print(f"Total Correct:     {len(correct)} (Expected: 84)")
print(f"Total Incorrect:   {len(incorrect)} (Expected: 9)")
print(f"Total Unattempted: {len(unattempted)} (Expected: 107)")
print(f"\nDetected Incorrect: {[q for q, _, _ in incorrect]}")
print(f"Expected Incorrect: {sorted(list(expected_incorrect))}")
print(f"\nAttempted questions count: {200 - len(unattempted)} (Expected: 93)")
