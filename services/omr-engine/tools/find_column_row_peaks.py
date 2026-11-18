import cv2
import numpy as np

for col_name, crop_file, y_offset, q_start, q_count in [
    ("Col 2", "col2_crop.jpg", 270, 27, 26),
    ("Col 3", "col3_crop.jpg", 125, 53, 37),
    ("Col 4", "col4_crop.jpg", 125, 90, 37),
]:
    img = cv2.imread(crop_file, 0)
    h, w = img.shape
    # Profile of darkness vertically
    darkness = np.mean(255.0 - img[:, 10:40], axis=1) # question label area
    
    # Smooth profile
    smoothed = cv2.GaussianBlur(darkness, (1, 5), 1.0).flatten()
    
    # Find local peaks separated by at least 10 pixels
    peaks = []
    for y in range(2, h-2):
        if smoothed[y] > smoothed[y-1] and smoothed[y] > smoothed[y+1] and smoothed[y] > 15:
            if not peaks or (y - peaks[-1]) >= 9:
                peaks.append(y)
    
    print(f"\n{col_name} (Expected {q_count} rows): found {len(peaks)} row peaks:")
    orig_peaks = [y_offset + p for p in peaks]
    print(f"  y values: {orig_peaks[:10]} ... {orig_peaks[-5:]}")
    if len(orig_peaks) >= 2:
        diffs = np.diff(orig_peaks)
        print(f"  mean diff: {np.mean(diffs):.2f}, min: {np.min(diffs)}, max: {np.max(diffs)}")
