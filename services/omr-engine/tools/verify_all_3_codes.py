import cv2
import numpy as np

samples = [
    (r"C:\Users\prakh\.gemini\antigravity-ide\brain\392984a1-a503-4623-8270-82e8602f1fbf\.user_uploaded\media_1788415707484.jpg", "224567"), # Vedehi
    (r"C:\Users\prakh\.gemini\antigravity-ide\brain\392984a1-a503-4623-8270-82e8602f1fbf\.user_uploaded\media_1788415714038.jpg", "342105"), # Amar
    (r"C:\Users\prakh\.gemini\antigravity-ide\brain\392984a1-a503-4623-8270-82e8602f1fbf\.user_uploaded\media_1788415720046.jpg", "134767"), # Vaibhav
]

# In the PDF:
# Column 1 at x=103.2 (x_norm=0.17353) is digit '0' of col 1
# Let's check the bubble center for each digit
cols_x = [0.17353, 0.19168, 0.21025, 0.22881, 0.24737, 0.26553]
y0_norm = 0.12180
pitch_norm = 0.01302

print("=== VERIFYING 6-DIGIT CODE EXTRACTION ON ALL 3 SAMPLES ===")
for path, expected in samples:
    img = cv2.imread(path)
    h, w = img.shape[:2]
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    
    extracted_digits = []
    for c_idx, cx_norm in enumerate(cols_x):
        cx = int(cx_norm * w)
        digit_vals = []
        for d in range(10):
            cy = int((y0_norm + d * pitch_norm) * h)
            r = int(0.0055 * w)
            mask = np.zeros((r*2+1, r*2+1), dtype=np.uint8)
            cv2.circle(mask, (r, r), r, 255, -1)
            roi = gray[max(0, cy-r):min(h, cy+r+1), max(0, cx-r):min(w, cx+r+1)]
            val = cv2.mean(roi, mask=mask)[0] if roi.shape == mask.shape else 255.0
            digit_vals.append((d, round(val, 1)))
        
        min_d, min_val = min(digit_vals, key=lambda x: x[1])
        extracted_digits.append(str(min_d))
    
    res = "".join(extracted_digits)
    match = "[PASS]" if res == expected else f"[FAIL] (expected {expected})"
    print(f"Sample: {res} | Expected: {expected} -> {match}")
