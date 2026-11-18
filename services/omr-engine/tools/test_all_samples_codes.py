import cv2
import numpy as np

for name, path in [
    ("Sample 1", r"C:\Users\prakh\.gemini\antigravity-ide\brain\392984a1-a503-4623-8270-82e8602f1fbf\.user_uploaded\media_1788415707484.jpg"),
    ("Sample 2", r"C:\Users\prakh\.gemini\antigravity-ide\brain\392984a1-a503-4623-8270-82e8602f1fbf\.user_uploaded\media_1788415714038.jpg"),
    ("Sample 3", r"C:\Users\prakh\.gemini\antigravity-ide\brain\392984a1-a503-4623-8270-82e8602f1fbf\.user_uploaded\media_1788415720046.jpg"),
]:
    img = cv2.imread(path, 0)
    h, w = img.shape
    
    # 6 columns for code:
    code_cols = [0.18730, 0.20520, 0.22310, 0.24100, 0.25890, 0.27680]
    start_y = 0.1380
    pitch_y = 0.0125
    
    digits = []
    for c in code_cols:
        col_scores = []
        for d in range(10):
            cx = int(c * w)
            cy = int((start_y + d * pitch_y) * h)
            roi = img[cy-3:cy+4, cx-4:cx+5]
            col_scores.append(np.mean(roi))
        best_d = np.argmin(col_scores)
        digits.append(str(best_d))
    print(f"{name}: extracted code = {''.join(digits)}")
