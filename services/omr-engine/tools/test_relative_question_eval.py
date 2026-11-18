import cv2
import numpy as np

def evaluate_sheet_relative(image_path, name):
    img = cv2.imread(image_path)
    h, w = img.shape[:2]
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    
    print(f"\n==================== {name} ({w}x{h}) ====================")
    
    # 6 Columns definition:
    # (q_start, q_end, approx_label_x_norm, y0_norm, row_pitch_norm, bubble_pitch_norm)
    cols = [
        (1, 26, 0.185, 0.278, 0.01365, 0.0195),
        (27, 52, 0.298, 0.278, 0.01365, 0.0195),
        (53, 89, 0.428, 0.133, 0.01365, 0.0195),
        (90, 126, 0.548, 0.133, 0.01365, 0.0195),
        (127, 163, 0.678, 0.133, 0.01365, 0.0195),
        (164, 200, 0.798, 0.133, 0.01365, 0.0195),
    ]
    
    results = {}
    
    for q_start, q_end, label_x_norm, y0_norm, dy_norm, bp_norm in cols:
        for idx in range(q_end - q_start + 1):
            q = q_start + idx
            expected_y = int((y0_norm + idx * dy_norm) * h)
            expected_label_x = int(label_x_norm * w)
            bubble_pitch = int(bp_norm * w)
            
            # 1. Locate question number ink in a tight search window
            # Look for question number within [-8..+8 px x, -4..+4 px y]
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
            
            # 2. Check each of the 4 bubbles parallel to the question label
            # Bubble 1 starts at actual_label_x + 1.2 * bubble_pitch
            # Bubble 2 at + 2.2 * bubble_pitch
            # Bubble 3 at + 3.2 * bubble_pitch
            # Bubble 4 at + 4.2 * bubble_pitch
            b1_x = int(actual_label_x + 1.25 * bubble_pitch)
            
            bubble_scores = []
            for opt_idx in range(4):
                bx = b1_x + opt_idx * bubble_pitch
                by = actual_y
                
                rx = max(3, int(bubble_pitch * 0.40))
                ry = max(3, int(dy_norm * h * 0.40))
                
                roi = gray[max(0, by-ry):min(h, by+ry+1), max(0, bx-rx):min(w, bx+rx+1)]
                if roi.size == 0:
                    bubble_scores.append(255)
                    continue
                min_v = np.min(roi)
                mean_v = np.mean(roi)
                # Hybrid ink score
                score = 0.5 * min_v + 0.5 * mean_v
                bubble_scores.append(score)
            
            best_opt = int(np.argmin(bubble_scores))
            best_score = bubble_scores[best_opt]
            sorted_scores = sorted(bubble_scores)
            contrast = sorted_scores[1] - sorted_scores[0]
            
            # Is it a real marked bubble?
            if best_score < 160 and contrast > 22:
                results[q] = str(best_opt + 1)
    
    print(f"Total answers detected: {len(results)}")
    if name.startswith("Sample 2"):
        c1 = {q: opt for q, opt in results.items() if q <= 26}
        print(f"Sample 2 (Amar Singh) Column 1: {c1}")
    elif name.startswith("Sample 1"):
        c1 = {q: opt for q, opt in results.items() if q <= 20}
        print(f"Sample 1 (Vedehi) First 20: {c1}")
    return results

# Test all 3
evaluate_sheet_relative(r"C:\Users\prakh\.gemini\antigravity-ide\brain\392984a1-a503-4623-8270-82e8602f1fbf\.user_uploaded\media_1788415714038.jpg", "Sample 2 (Amar)")
evaluate_sheet_relative(r"C:\Users\prakh\.gemini\antigravity-ide\brain\392984a1-a503-4623-8270-82e8602f1fbf\.user_uploaded\media_1788415707484.jpg", "Sample 1 (Vedehi)")
evaluate_sheet_relative(r"C:\Users\prakh\.gemini\antigravity-ide\brain\392984a1-a503-4623-8270-82e8602f1fbf\.user_uploaded\media_1788415720046.jpg", "Sample 3 (Vaibhav)")
