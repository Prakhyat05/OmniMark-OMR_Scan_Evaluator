import cv2
import numpy as np

# Load Sample 2 (Amar Singh)
sample2_path = r"C:\Users\prakh\.gemini\antigravity-ide\brain\392984a1-a503-4623-8270-82e8602f1fbf\.user_uploaded\media_1788415714038.jpg"
img = cv2.imread(sample2_path)
h, w = img.shape[:2]
gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)

overlay = img.copy()

# Answer key for Col 1: say all '1' except Q10 which is '4'
answer_key = {q: '1' for q in range(1, 27)}
answer_key[10] = '4'

col1_x_start = 0.200 * w
col1_x_end = 0.272 * w
slot_w = (col1_x_end - col1_x_start) / 4.0

for q in range(1, 27):
    y_center = (0.275 + (q - 1) * 0.0136) * h
    y1 = int(y_center - 0.006 * h)
    y2 = int(y_center + 0.006 * h)
    
    # Check all 4 option slots in this row
    slot_mins = []
    slot_coords = []
    for opt_idx in range(4):
        sx1 = int(col1_x_start + opt_idx * slot_w)
        sx2 = int(col1_x_start + (opt_idx + 1) * slot_w)
        crop = gray[y1:y2, sx1:sx2]
        if crop.size == 0:
            slot_mins.append(255)
            slot_coords.append((int((sx1+sx2)/2), int((y1+y2)/2)))
            continue
        min_val, _, min_loc, _ = cv2.minMaxLoc(crop)
        slot_mins.append(min_val)
        slot_coords.append((sx1 + min_loc[0], y1 + min_loc[1]))
    
    # Darkest slot
    best_slot = int(np.argmin(slot_mins))
    best_val = slot_mins[best_slot]
    sorted_mins = sorted(slot_mins)
    contrast = sorted_mins[1] - sorted_mins[0]
    
    detected = None
    if best_val < 140 and contrast > 30:
        detected = str(best_slot + 1)
        det_cx, det_cy = slot_coords[best_slot]
    
    correct = answer_key.get(q)
    correct_idx = int(correct) - 1 if correct else None
    
    # Draw DOT ONLY:
    # If student marked an option
    if detected is not None:
        is_correct = (detected == correct)
        color = (0, 200, 0) if is_correct else (0, 0, 230) # Green or Red (BGR)
        # Draw clean solid dot with radius 4 px
        cv2.circle(overlay, (det_cx, det_cy), 4, color, -1)
        # Subtle outer halo ring
        cv2.circle(overlay, (det_cx, det_cy), 5, (255, 255, 255), 1)
    
    # If wrong or unattempted, show correct key as small green ring
    if correct_idx is not None and (detected != correct):
        k_cx, k_cy = slot_coords[correct_idx]
        cv2.circle(overlay, (k_cx, k_cy), 4, (0, 200, 0), 1)

crop = overlay[int(0.26*h):int(0.62*h), int(0.15*w):int(0.35*w)]
cv2.imwrite("clean_dot_overlay_preview.jpg", crop)
print("Saved clean_dot_overlay_preview.jpg")
