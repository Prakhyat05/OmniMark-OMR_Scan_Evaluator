import cv2
import numpy as np

# Load Sample 2 (Amar Singh)
sample2_path = r"C:\Users\prakh\.gemini\antigravity-ide\brain\392984a1-a503-4623-8270-82e8602f1fbf\.user_uploaded\media_1788415714038.jpg"
img = cv2.imread(sample2_path)
h, w = img.shape[:2]
gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)

overlay = img.copy()

# Answer key: All '1', except Q10 which is '2' (to test wrong answer display!)
answer_key = {q: '1' for q in range(1, 27)}
answer_key[10] = '2' # Make Q10 deliberately wrong to test red dot + green ring!

cols = [
    (1, 26, 0.185, 0.278, 0.01365, 0.0195),
]

for q_start, q_end, label_x_norm, y0_norm, dy_norm, bp_norm in cols:
    for idx in range(q_end - q_start + 1):
        q = q_start + idx
        expected_y = int((y0_norm + idx * dy_norm) * h)
        expected_label_x = int(label_x_norm * w)
        bubble_pitch = int(bp_norm * w)
        
        search_x1 = max(0, expected_label_x - 8)
        search_x2 = min(w, expected_label_x + 8)
        search_y1 = max(0, expected_y - 4)
        search_y2 = min(h, expected_y + 4)
        
        q_crop = gray[search_y1:search_y2, search_x1:search_x2]
        if q_crop.size == 0:
            continue
        
        _, _, min_loc, _ = cv2.minMaxLoc(q_crop)
        actual_label_x = search_x1 + min_loc[0]
        actual_y = search_y1 + min_loc[1]
        
        b1_x = int(actual_label_x + 1.25 * bubble_pitch)
        
        bubble_scores = []
        bubble_coords = []
        for opt_idx in range(4):
            bx = b1_x + opt_idx * bubble_pitch
            by = actual_y
            bubble_coords.append((bx, by))
            
            rx = max(3, int(bubble_pitch * 0.40))
            ry = max(3, int(dy_norm * h * 0.40))
            
            roi = gray[max(0, by-ry):min(h, by+ry+1), max(0, bx-rx):min(w, bx+rx+1)]
            if roi.size == 0:
                bubble_scores.append(255)
                continue
            min_v = np.min(roi)
            mean_v = np.mean(roi)
            score = 0.5 * min_v + 0.5 * mean_v
            bubble_scores.append(score)
        
        best_opt = int(np.argmin(bubble_scores))
        best_score = bubble_scores[best_opt]
        sorted_scores = sorted(bubble_scores)
        contrast = sorted_scores[1] - sorted_scores[0]
        
        detected = None
        if best_score < 160 and contrast > 22:
            detected = str(best_opt + 1)
        
        correct = answer_key.get(q)
        correct_idx = int(correct) - 1 if correct else None
        
        # Draw clean dot on student's marked bubble
        if detected is not None:
            det_idx = int(detected) - 1
            bx, by = bubble_coords[det_idx]
            is_correct = (detected == correct)
            color = (0, 200, 0) if is_correct else (0, 0, 230) # Green or Red
            # Outer white halo
            cv2.circle(overlay, (bx, by), 5, (255, 255, 255), 1)
            # Inner solid dot
            cv2.circle(overlay, (bx, by), 4, color, -1)
        
        # Draw green ring on correct answer key bubble if student was wrong or unattempted
        if correct_idx is not None and (detected != correct):
            kbx, kby = bubble_coords[correct_idx]
            cv2.circle(overlay, (kbx, kby), 5, (0, 200, 0), 2)

crop = overlay[int(0.26*h):int(0.62*h), int(0.14*w):int(0.32*w)]
cv2.imwrite("verified_relative_overlay_sample2.jpg", crop)
print("Saved verified_relative_overlay_sample2.jpg")
