import cv2
import numpy as np

def evaluate_omr_sheet(img_path, name):
    img = cv2.imread(img_path, 0)
    h, w = img.shape
    
    # 1. Detect Outer Fiducials with dense sampling (step 3)
    left_x = []
    for y in range(int(h * 0.15), int(h * 0.85), 3):
        row = img[y, int(w*0.04):int(w*0.18)]
        min_x = np.argmin(row) + int(w*0.04)
        if row[min_x - int(w*0.04)] < 70:
            left_x.append(min_x)
            
    right_x = []
    for y in range(int(h * 0.15), int(h * 0.85), 3):
        row = img[y, int(w*0.80):int(w*0.96)]
        min_x = np.argmin(row) + int(w*0.80)
        if row[min_x - int(w*0.80)] < 70:
            right_x.append(min_x)
            
    med_left = float(np.median(left_x)) if len(left_x) >= 10 else (0.1541 * w)
    med_right = float(np.median(right_x)) if len(right_x) >= 10 else (0.8610 * w)
    grid_w = med_right - med_left
    
    # 2. Dynamic column label positions from fiducial grid
    # Ratios: 0.0437, 0.1935, 0.3541, 0.5152, 0.6760, 0.8371
    col_label_xs = [
        int(med_left + 0.0437 * grid_w),
        int(med_left + 0.1935 * grid_w),
        int(med_left + 0.3541 * grid_w),
        int(med_left + 0.5152 * grid_w),
        int(med_left + 0.6760 * grid_w),
        int(med_left + 0.8371 * grid_w),
    ]
    
    bubble_pitch = max(12, int(round(0.0271 * grid_w)))
    
    # Column metadata: (q_start, q_end, label_x, y0_px, dy_px)
    cols_meta = [
        (1, 26, col_label_xs[0], int(round(0.2744 * h)), 12.70),
        (27, 52, col_label_xs[1], int(round(0.2744 * h)), 12.70),
        (53, 89, col_label_xs[2], int(round(0.1367 * h)), 12.75),
        (90, 126, col_label_xs[3], int(round(0.1367 * h)), 12.75),
        (127, 163, col_label_xs[4], int(round(0.1367 * h)), 12.75),
        (164, 200, col_label_xs[5], int(round(0.1367 * h)), 12.75),
    ]
    
    detected = {}
    multiple = set()
    
    for q_start, q_end, label_x, y0, dy in cols_meta:
        for idx in range(q_end - q_start + 1):
            q = q_start + idx
            expected_y = int(round(y0 + idx * dy))
            
            # Search Y vertically within [-3..+3]
            crop_y = img[max(0, expected_y-3):min(h, expected_y+4), label_x-1:label_x+3]
            _, _, min_loc, _ = cv2.minMaxLoc(crop_y)
            actual_y = expected_y - 3 + min_loc[1]
            
            b1_x = label_x + int(round(1.25 * bubble_pitch))
            
            scores = []
            for opt in range(4):
                bx = b1_x + opt * bubble_pitch
                by = actual_y
                roi = img[max(0, by-4):min(h, by+5), max(0, bx-5):min(w, bx+6)]
                if roi.size == 0:
                    scores.append(255)
                    continue
                min_v = np.min(roi)
                mean_v = np.mean(roi)
                scores.append(0.5 * min_v + 0.5 * mean_v)
                
            sorted_indices = sorted(range(4), key=lambda k: scores[k])
            best_opt = sorted_indices[0]
            second_opt = sorted_indices[1]
            best_score = scores[best_opt]
            second_score = scores[second_opt]
            gap = second_score - best_score
            
            if best_score > 110.0:
                detected[q] = None
            elif second_score < 95.0 and gap < 16.0:
                multiple.add(q)
                detected[q] = None
            elif gap > 16.0:
                detected[q] = str(best_opt + 1)
            else:
                detected[q] = None
                
    attempted = {q: opt for q, opt in detected.items() if opt is not None}
    print(f"\n==================== {name} ====================")
    print(f"Fiducials: left={med_left:.1f}, right={med_right:.1f}, grid_w={grid_w:.1f}")
    print(f"Col Label Xs: {col_label_xs}")
    print(f"Total Attempted Questions: {len(attempted)}")
    print(f"Total Multiple Marked: {len(multiple)}")
    
    # Print first 26
    c1 = {q: opt for q, opt in attempted.items() if q <= 26}
    print(f"Col 1 answers ({len(c1)}/26): {c1}")
    
    return detected

# Run on all 3
d1 = evaluate_omr_sheet(r"C:\Users\prakh\.gemini\antigravity-ide\brain\392984a1-a503-4623-8270-82e8602f1fbf\.user_uploaded\media_1788415707484.jpg", "Sample 1 (Vedehi)")
d2 = evaluate_omr_sheet(r"C:\Users\prakh\.gemini\antigravity-ide\brain\392984a1-a503-4623-8270-82e8602f1fbf\.user_uploaded\media_1788415714038.jpg", "Sample 2 (Amar)")
d3 = evaluate_omr_sheet(r"C:\Users\prakh\.gemini\antigravity-ide\brain\392984a1-a503-4623-8270-82e8602f1fbf\.user_uploaded\media_1788415720046.jpg", "Sample 3 (Vaibhav)")
