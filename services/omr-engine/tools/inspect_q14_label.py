import cv2
import numpy as np

img = cv2.imread(r"C:\Users\prakh\.gemini\antigravity-ide\brain\392984a1-a503-4623-8270-82e8602f1fbf\.user_uploaded\media_1788415714038.jpg")
h, w = img.shape[:2]
gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)

# Look at Row 14 between x=80 and x=150, y=450 to 462
q14_patch = gray[450:462, 80:150]
print("Patch around Q14 label (y=450..462, x=80..150):")
for r in range(q14_patch.shape[0]):
    row_str = "".join(["#" if p < 150 else "." for p in q14_patch[r]])
    print(f"  y={450+r}: {row_str}")

# Find columns where ink is present (text of '14')
col_min = np.min(q14_patch, axis=0)
for idx, val in enumerate(col_min):
    x = 80 + idx
    if val < 180:
        print(f"  x={x} (x/w={x/w:.4f}): min_val={val}")
