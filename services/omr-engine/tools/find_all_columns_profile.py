import cv2
import numpy as np

sample2_path = r"C:\Users\prakh\.gemini\antigravity-ide\brain\392984a1-a503-4623-8270-82e8602f1fbf\.user_uploaded\media_1788415714038.jpg"
img = cv2.imread(sample2_path)
h, w = img.shape[:2]
gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)

# Let's inspect a horizontal slice across all 6 columns at y = 350 px:
# At y = 350 px:
# Col 1 is around Row 6 (Q6 - marked 1)
# Col 2 is around Row 32 (Q32 - marked 2)
# Col 3 is around Row 68 (Q68 - marked 3)
# Col 4 is around Row 105 (Q105 - BLANK)
# Col 5 is around Row 142 (Q142 - BLANK)
# Col 6 is around Row 179 (Q179 - BLANK)

slice_y = 355
row = gray[slice_y-3:slice_y+4, :]
profile = np.mean(row, axis=0)

# Let's find all peaks of ink across the 730 width at y=355
print(f"Profile at y={slice_y}:")
for x in range(50, 700):
    val = profile[x]
    if val < 190:
        # local minimum
        if val <= profile[x-1] and val <= profile[x+1]:
            print(f"  Dark point at x={x:3d} (norm={x/w:.4f}): val={val:.1f}")
