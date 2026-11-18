import cv2
import numpy as np

# Load Sample 2 (Amar Singh)
sample2_path = r"C:\Users\prakh\.gemini\antigravity-ide\brain\392984a1-a503-4623-8270-82e8602f1fbf\.user_uploaded\media_1788415714038.jpg"
img = cv2.imread(sample2_path)
h, w = img.shape[:2]
gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)

# For each row from 1 to 26 in Col 1:
# Let's find:
# 1. The y-coordinate of the row
# 2. The x-coordinate of the question number label
# 3. The x-coordinate of the marked bubble (bubble 1)
print("Row analysis for Col 1 (Q1..26):")
for q in range(1, 27):
    # Search band around expected y
    expected_y = int((0.278 + (q - 1) * 0.01365) * h)
    
    # 1. Question number is between x=125 and x=145
    q_patch = gray[expected_y-5:expected_y+6, 125:145]
    min_q_val, _, min_q_loc, _ = cv2.minMaxLoc(q_patch)
    q_x = 125 + min_q_loc[0]
    q_y = expected_y - 5 + min_q_loc[1]
    
    # 2. Option zone is between x=145 and x=205
    opt_patch = gray[expected_y-5:expected_y+6, 145:205]
    min_opt_val, _, min_opt_loc, _ = cv2.minMaxLoc(opt_patch)
    opt_x = 145 + min_opt_loc[0]
    opt_y = expected_y - 5 + min_opt_loc[1]
    
    # Distance from Question Number to Marked Bubble:
    dist = opt_x - q_x
    print(f"Q{q:2d}: Question Label at (x={q_x}, y={q_y}) | Marked Bubble at (x={opt_x}, y={opt_y}, val={min_opt_val}) | dist={dist} px (norm={dist/w:.4f})")
