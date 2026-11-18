import cv2
import numpy as np

for name, path in [
    ("Sample 1 (Vedehi)", r"C:\Users\prakh\.gemini\antigravity-ide\brain\392984a1-a503-4623-8270-82e8602f1fbf\.user_uploaded\media_1788415707484.jpg"),
    ("Sample 2 (Amar)", r"C:\Users\prakh\.gemini\antigravity-ide\brain\392984a1-a503-4623-8270-82e8602f1fbf\.user_uploaded\media_1788415714038.jpg"),
    ("Sample 3 (Vaibhav)", r"C:\Users\prakh\.gemini\antigravity-ide\brain\392984a1-a503-4623-8270-82e8602f1fbf\.user_uploaded\media_1788415720046.jpg"),
]:
    img = cv2.imread(path, 0)
    h, w = img.shape
    
    # 1. Find leftmost fiducial
    left_x = []
    for y in range(int(h * 0.20), int(h * 0.80), 3):
        row = img[y, int(w*0.04):int(w*0.18)]
        min_x = np.argmin(row) + int(w*0.04)
        if row[min_x - int(w*0.04)] < 70:
            left_x.append(min_x)
    med_l = np.median(left_x)
    
    # 2. Find the top timing mark on the left margin (y position where timing marks begin)
    top_timing_y = None
    for y in range(100, 400):
        val = img[y, int(med_l)]
        if val < 60:
            top_timing_y = y
            break
            
    # 3. Find Row 1 (Q1) label near x = med_l + 22 px, around y = 270..295
    col1_label_x = int(med_l + 22)
    crop_q1 = img[265:295, col1_label_x-3:col1_label_x+4]
    row_mins = np.min(crop_q1, axis=1)
    q1_y = 265 + np.argmin(row_mins)
    
    # 4. Find Row 53 (Q53) label near x = med_l + 182 px, around y = 125..155
    col3_label_x = int(med_l + 182)
    crop_q53 = img[125:155, col3_label_x-3:col3_label_x+4]
    row_mins_53 = np.min(crop_q53, axis=1)
    q53_y = 125 + np.argmin(row_mins_53)
    
    print(f"\n{name}:")
    print(f"  Top timing mark Y: {top_timing_y}")
    print(f"  Q1 (Col 1 Row 1) label Y:  {q1_y} (norm={q1_y/h:.4f})")
    print(f"  Q53 (Col 3 Row 1) label Y: {q53_y} (norm={q53_y/h:.4f})")
