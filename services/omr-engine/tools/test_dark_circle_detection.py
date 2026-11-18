import cv2
import numpy as np

# Load Sample 2 (Amar Singh)
sample2_path = r"C:\Users\prakh\.gemini\antigravity-ide\brain\392984a1-a503-4623-8270-82e8602f1fbf\.user_uploaded\media_1788415714038.jpg"
img = cv2.imread(sample2_path)
h, w = img.shape[:2]
gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)

print(f"Sample 2 image size: {w}x{h}")

# In Column 1 (Questions 1 to 26):
# The question numbers are at x ~ 0.165 to 0.195
# The 4 options are located between x_start ~ 0.200 and x_end ~ 0.275
# The row vertical positions for Q1..26 are roughly between y ~ 0.270 and 0.610

# Let's inspect each of the 26 rows in Column 1:
# For each question row, let's find the minimum intensity (darkest spot) inside the option zone [0.200*w .. 0.275*w]
# and see its exact (x, y) coordinates and which option slot it falls into!

row_pitch = (0.610 - 0.270) / 25.0 # ~0.0136

print("\n=== DETECTING DARK CIRCLES IN COLUMN 1 (Q1..26) ===")

for q in range(1, 27):
    # Vertical band for this question
    y_center = 0.275 + (q - 1) * 0.0136
    y1 = int((y_center - 0.006) * h)
    y2 = int((y_center + 0.006) * h)
    
    # Option zone horizontally
    x1 = int(0.200 * w)
    x2 = int(0.275 * w)
    
    row_crop = gray[y1:y2, x1:x2]
    if row_crop.size == 0:
        continue
    
    # Find darkest point in this row crop
    min_val, max_val, min_loc, max_loc = cv2.minMaxLoc(row_crop)
    dark_x_local, dark_y_local = min_loc
    dark_x = x1 + dark_x_local
    dark_y = y1 + dark_y_local
    
    # Horizontal span of options: 4 equal slots of width (x2 - x1) / 4
    slot_width = (x2 - x1) / 4.0
    slot_idx = int((dark_x - x1) / slot_width)
    slot_idx = max(0, min(3, slot_idx))
    detected_option = str(slot_idx + 1)
    
    # Is it actually a dark circle or blank paper?
    # Blank paper in this region is typically > 180 intensity
    # A marked bubble is typically < 140 intensity
    # Let's also check the contrast against local average
    avg_val = np.mean(row_crop)
    contrast = avg_val - min_val
    
    status = detected_option if (min_val < 130 and contrast > 40) else "BLANK"
    
    print(f"Q{q:2d}: Detected {status:5s} | min_val={min_val:3.0f}, avg={avg_val:3.0f}, contrast={contrast:3.0f} | slot={slot_idx+1} at x={dark_x} (x_norm={dark_x/w:.4f}), y={dark_y}")
