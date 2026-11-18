import cv2
import numpy as np

# Let's verify our exact slot detection on Sample 2, Sample 1, Sample 3
samples = [
    ("Sample 1 (Vedehi)", r"C:\Users\prakh\.gemini\antigravity-ide\brain\392984a1-a503-4623-8270-82e8602f1fbf\.user_uploaded\media_1788415707484.jpg"),
    ("Sample 2 (Amar)", r"C:\Users\prakh\.gemini\antigravity-ide\brain\392984a1-a503-4623-8270-82e8602f1fbf\.user_uploaded\media_1788415714038.jpg"),
    ("Sample 3 (Vaibhav)", r"C:\Users\prakh\.gemini\antigravity-ide\brain\392984a1-a503-4623-8270-82e8602f1fbf\.user_uploaded\media_1788415720046.jpg"),
]

# Grid definition
cols = [
    (1, 26, 0.20959, 0.28200),
    (27, 52, 0.32750, 0.28200),
    (53, 89, 0.45700, 0.13800),
    (90, 126, 0.57500, 0.13800),
    (127, 163, 0.70400, 0.13800),
    (164, 200, 0.82200, 0.13800),
]
opt_step = 0.01781
row_pitch = 0.01390

for name, path in samples:
    img = cv2.imread(path)
    h, w = img.shape[:2]
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    
    detected = {}
    
    for q_start, q_end, opt1_x, y0 in cols:
        for idx in range(q_end - q_start + 1):
            q = q_start + idx
            cy = int((y0 + idx * row_pitch) * h)
            
            # Check 4 option bubbles
            slot_scores = []
            for opt_idx in range(4):
                cx = int((opt1_x + opt_idx * opt_step) * w)
                rx = int(0.0075 * w)
                ry = int(0.0055 * h)
                
                roi = gray[max(0, cy-ry):min(h, cy+ry+1), max(0, cx-rx):min(w, cx+rx+1)]
                if roi.size == 0:
                    slot_scores.append(255)
                    continue
                # Local minimum (darkest ink)
                min_val = np.min(roi)
                mean_val = np.mean(roi)
                # Combined score: mean + min
                score = 0.5 * min_val + 0.5 * mean_val
                slot_scores.append(score)
            
            best_opt = int(np.argmin(slot_scores))
            best_score = slot_scores[best_opt]
            sorted_scores = sorted(slot_scores)
            contrast = sorted_scores[1] - sorted_scores[0]
            
            if best_score < 155 and contrast > 22:
                detected[q] = str(best_opt + 1)
    
    print(f"{name}: Detected {len(detected)} answered questions.")
    if name.startswith("Sample 2"):
        col1_opts = {q: opt for q, opt in detected.items() if q <= 26}
        print(f"Sample 2 Col 1: {col1_opts}")
