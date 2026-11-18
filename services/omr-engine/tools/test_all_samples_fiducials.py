import cv2
import numpy as np

samples = [
    ("Sample 1 (Vedehi)", r"C:\Users\prakh\.gemini\antigravity-ide\brain\392984a1-a503-4623-8270-82e8602f1fbf\.user_uploaded\media_1788415707484.jpg"),
    ("Sample 2 (Amar)", r"C:\Users\prakh\.gemini\antigravity-ide\brain\392984a1-a503-4623-8270-82e8602f1fbf\.user_uploaded\media_1788415714038.jpg"),
    ("Sample 3 (Vaibhav)", r"C:\Users\prakh\.gemini\antigravity-ide\brain\392984a1-a503-4623-8270-82e8602f1fbf\.user_uploaded\media_1788415720046.jpg"),
]

def test_fiducials_on_sample(name, path):
    img = cv2.imread(path)
    h, w = img.shape[:2]
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    
    print(f"\n==================== {name} ({w}x{h}) ====================")
    
    # Dart fiducial detection logic:
    max_left_x = int(w * 0.18)
    min_right_x = int(w * 0.82)
    
    left_runs = []
    right_runs = []
    
    step_y = max(1, int(h * 0.012))
    for y in range(int(h * 0.10), int(h * 0.90), step_y):
        # Left margin
        dark_start = None
        for x in range(int(w * 0.04), max_left_x):
            luma = gray[y, x]
            if luma < 60:
                if dark_start is None: dark_start = x
            elif dark_start is not None:
                run_len = x - dark_start
                if 5 <= run_len <= 22:
                    left_runs.append(dark_start + run_len / 2.0)
                dark_start = None
                
        # Right margin
        dark_start = None
        for x in range(min_right_x, int(w * 0.96)):
            luma = gray[y, x]
            if luma < 60:
                if dark_start is None: dark_start = x
            elif dark_start is not None:
                run_len = x - dark_start
                if 5 <= run_len <= 22:
                    right_runs.append(dark_start + run_len / 2.0)
                dark_start = None
                
    print(f"Left runs found: {len(left_runs)}, Right runs found: {len(right_runs)}")
    if len(left_runs) >= 8 and len(right_runs) >= 8:
        med_l = float(np.median(left_runs))
        med_r = float(np.median(right_runs))
        grid_w = med_r - med_l
        print(f"Fiducial X: left={med_l:.1f} px (norm={med_l/w:.4f}), right={med_r:.1f} px (norm={med_r/w:.4f}), grid_w={grid_w:.1f} px")
    else:
        print("FAIL: Fiducials NOT DETECTED! (Falling back to defaults)")

for name, path in samples:
    test_fiducials_on_sample(name, path)
