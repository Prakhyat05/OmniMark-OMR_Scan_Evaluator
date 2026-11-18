import cv2
import numpy as np

for name, path in [
    ("Sample 1 (Vedehi)", r"C:\Users\prakh\.gemini\antigravity-ide\brain\392984a1-a503-4623-8270-82e8602f1fbf\.user_uploaded\media_1788415707484.jpg"),
    ("Sample 2 (Amar)", r"C:\Users\prakh\.gemini\antigravity-ide\brain\392984a1-a503-4623-8270-82e8602f1fbf\.user_uploaded\media_1788415714038.jpg"),
    ("Sample 3 (Vaibhav)", r"C:\Users\prakh\.gemini\antigravity-ide\brain\392984a1-a503-4623-8270-82e8602f1fbf\.user_uploaded\media_1788415720046.jpg"),
]:
    img = cv2.imread(path, 0)
    h, w = img.shape
    
    # Left margin: x in [0.05*w .. 0.18*w]
    left_x = []
    for y in range(int(h * 0.20), int(h * 0.80), 3):
        row = img[y, int(w*0.04):int(w*0.18)]
        min_x = np.argmin(row) + int(w*0.04)
        if row[min_x - int(w*0.04)] < 70:
            left_x.append(min_x)
            
    # Right margin: x in [0.80*w .. 0.96*w]
    right_x = []
    for y in range(int(h * 0.20), int(h * 0.80), 3):
        row = img[y, int(w*0.80):int(w*0.96)]
        min_x = np.argmin(row) + int(w*0.80)
        if row[min_x - int(w*0.80)] < 70:
            right_x.append(min_x)
            
    med_l = np.median(left_x)
    med_r = np.median(right_x)
    print(f"\n{name} ({w}x{h}):")
    print(f"  Leftmost fiducial X:  {med_l:.1f} px (norm={med_l/w:.4f}), count={len(left_x)}")
    print(f"  Rightmost fiducial X: {med_r:.1f} px (norm={med_r/w:.4f}), count={len(right_x)}")
    print(f"  Grid width: {med_r - med_l:.1f} px")
