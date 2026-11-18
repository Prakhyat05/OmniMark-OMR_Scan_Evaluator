import cv2
import numpy as np

samples = [
    (r"C:\Users\prakh\.gemini\antigravity-ide\brain\392984a1-a503-4623-8270-82e8602f1fbf\.user_uploaded\media_1788415707484.jpg", "224567"), # Vedehi
    (r"C:\Users\prakh\.gemini\antigravity-ide\brain\392984a1-a503-4623-8270-82e8602f1fbf\.user_uploaded\media_1788415714038.jpg", "342105"), # Amar
    (r"C:\Users\prakh\.gemini\antigravity-ide\brain\392984a1-a503-4623-8270-82e8602f1fbf\.user_uploaded\media_1788415720046.jpg", "134767"), # Vaibhav
]

# Exact code grid parameters
col1_x_norm = 0.19205
pitch_x_norm = 0.01750
y0_norm = 0.13867
pitch_y_norm = 0.01260

print("=== VERIFYING EXACT 6-DIGIT CODE FORMULA ===")
for path, expected in samples:
    img = cv2.imread(path)
    h, w = img.shape[:2]
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    
    extracted = []
    for c_idx in range(6):
        cx = int((col1_x_norm + c_idx * pitch_x_norm) * w)
        digit_scores = []
        for d in range(10):
            cy = int((y0_norm + d * pitch_y_norm) * h)
            r = int(0.0055 * w)
            roi = gray[max(0, cy-r):min(h, cy+r+1), max(0, cx-r):min(w, cx+r+1)]
            val = cv2.mean(roi)[0] if roi.size > 0 else 255.0
            digit_scores.append((d, round(val, 1)))
        
        min_d, min_val = min(digit_scores, key=lambda x: x[1])
        extracted.append(str(min_d))
    
    res = "".join(extracted)
    status = "[PASS]" if res == expected else f"[FAIL] (expected {expected})"
    print(f"Extracted: {res} | Expected: {expected} -> {status}")
