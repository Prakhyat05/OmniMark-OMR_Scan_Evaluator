import cv2
import numpy as np

# Test across all 3 samples with dark spot / zone detection
samples = [
    ("Sample 1 (Vedehi)", r"C:\Users\prakh\.gemini\antigravity-ide\brain\392984a1-a503-4623-8270-82e8602f1fbf\.user_uploaded\media_1788415707484.jpg"),
    ("Sample 2 (Amar)", r"C:\Users\prakh\.gemini\antigravity-ide\brain\392984a1-a503-4623-8270-82e8602f1fbf\.user_uploaded\media_1788415714038.jpg"),
    ("Sample 3 (Vaibhav)", r"C:\Users\prakh\.gemini\antigravity-ide\brain\392984a1-a503-4623-8270-82e8602f1fbf\.user_uploaded\media_1788415720046.jpg"),
]

cols = [
    (1, 26, 0.200, 0.272, 0.275),
    (27, 52, 0.318, 0.388, 0.275),
    (53, 89, 0.448, 0.518, 0.132),
    (90, 126, 0.565, 0.635, 0.132),
    (127, 163, 0.695, 0.765, 0.132),
    (164, 200, 0.812, 0.882, 0.132),
]

for name, path in samples:
    img = cv2.imread(path)
    h, w = img.shape[:2]
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    
    print(f"\n================ {name} ================")
    detected_answers = {}
    
    for q_start, q_end, x1_norm, x2_norm, y0_norm in cols:
        col_w = (x2_norm - x1_norm) * w
        slot_w = col_w / 4.0
        
        for idx in range(q_end - q_start + 1):
            q = q_start + idx
            y_center = (y0_norm + idx * 0.0136) * h
            y1 = int(y_center - 0.006 * h)
            y2 = int(y_center + 0.006 * h)
            
            slot_mins = []
            for opt_idx in range(4):
                sx1 = int(x1_norm * w + opt_idx * slot_w)
                sx2 = int(x1_norm * w + (opt_idx + 1) * slot_w)
                crop = gray[y1:y2, sx1:sx2]
                if crop.size == 0:
                    slot_mins.append(255)
                    continue
                min_val, _, _, _ = cv2.minMaxLoc(crop)
                slot_mins.append(min_val)
            
            best_slot = int(np.argmin(slot_mins))
            best_val = slot_mins[best_slot]
            sorted_mins = sorted(slot_mins)
            contrast = sorted_mins[1] - sorted_mins[0]
            
            if best_val < 140 and contrast > 30:
                detected_answers[q] = str(best_slot + 1)
    
    marked = [f"Q{q}:{opt}" for q, opt in sorted(detected_answers.items())[:20]]
    print(f"Total marked detected: {len(detected_answers)}")
    print(f"First 20 detections: {', '.join(marked)}")
