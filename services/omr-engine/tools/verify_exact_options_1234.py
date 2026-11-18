import cv2
import numpy as np

img = cv2.imread(r"C:\Users\prakh\.gemini\antigravity-ide\brain\392984a1-a503-4623-8270-82e8602f1fbf\.user_uploaded\media_1788415714038.jpg")
h, w = img.shape[:2]
gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)

# Let's inspect the column starting X positions across the page for all 6 columns!
# On the 730x1024 sheet:
# In each column, there is [Q_Label] [Opt1] [Opt2] [Opt3] [Opt4]

# Let's find the exact center of Option 1 for all 6 columns:
# Col 1: Q1..26   -> Opt1 is at x_norm = 0.20959, y_start = 0.28200
# Col 2: Q27..52  -> Opt1 is at x_norm = 0.32750, y_start = 0.28200
# Col 3: Q53..89  -> Opt1 is at x_norm = 0.45700, y_start = 0.13800
# Col 4: Q90..126 -> Opt1 is at x_norm = 0.57500, y_start = 0.13800
# Col 5: Q127..163-> Opt1 is at x_norm = 0.70400, y_start = 0.13800
# Col 6: Q164..200-> Opt1 is at x_norm = 0.82200, y_start = 0.13800

# Let's verify by checking Row 20 (where Amar marked Option 4):
# In Col 1, Q20 is at y = 0.28200 + 19 * 0.01390 = 0.54610 * h
y_q20 = int(0.54610 * h)
for opt_idx, opt_char in enumerate(['1', '2', '3', '4']):
    cx = int((0.20959 + opt_idx * 0.01826) * w)
    val = np.mean(gray[y_q20-3:y_q20+4, cx-3:cx+4])
    print(f"Q20 Option {opt_char} at x={cx} (x_norm={cx/w:.5f}): intensity={val:.1f}")

# And let's check Q14 (where Amar marked Option 1):
y_q14 = int((0.28200 + 13 * 0.01390) * h)
print(f"\nQ14:")
for opt_idx, opt_char in enumerate(['1', '2', '3', '4']):
    cx = int((0.20959 + opt_idx * 0.01826) * w)
    val = np.mean(gray[y_q14-3:y_q14+4, cx-3:cx+4])
    print(f"Q14 Option {opt_char} at x={cx} (x_norm={cx/w:.5f}): intensity={val:.1f}")
