import cv2
import numpy as np

for name, path in [
    ("Sample 1", r"C:\Users\prakh\.gemini\antigravity-ide\brain\392984a1-a503-4623-8270-82e8602f1fbf\.user_uploaded\media_1788415707484.jpg"),
    ("Sample 3", r"C:\Users\prakh\.gemini\antigravity-ide\brain\392984a1-a503-4623-8270-82e8602f1fbf\.user_uploaded\media_1788415720046.jpg"),
]:
    img = cv2.imread(path, 0)
    # Check left margin x: 100..125, y: 250..600
    crop = img[250:600, 100:125]
    print(f"\n{name} left margin min value: {np.min(crop)}, mean value: {np.mean(crop):.1f}")
    
    # Find all rows in crop where min is low
    row_mins = np.min(crop, axis=1)
    dark_rows = np.where(row_mins < 100)[0]
    print(f"{name} rows with pixel < 100: {len(dark_rows)} rows")
    dark_rows_60 = np.where(row_mins < 60)[0]
    print(f"{name} rows with pixel < 60: {len(dark_rows_60)} rows")
