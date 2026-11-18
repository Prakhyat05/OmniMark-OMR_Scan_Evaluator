import cv2
import numpy as np

sample2_path = r"C:\Users\prakh\.gemini\antigravity-ide\brain\392984a1-a503-4623-8270-82e8602f1fbf\.user_uploaded\media_1788415714038.jpg"
img = cv2.imread(sample2_path)
gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)

# In Col 3, Q53 starts at y ~ 138 px, and Q68 is row 16 (y ~ 138 + 15 * 13.9 = 346 px)
# Let's inspect x from 280 to 400 around y = 346 px:
print("Col 3 Row 16 (Q68) profile from x=280 to x=380 (y=346):")
row = gray[344:348, 280:380]
prof = np.mean(row, axis=0)
for idx, val in enumerate(prof):
    x = 280 + idx
    if val < 210:
        print(f"  x={x} (norm={x/730:.4f}): val={val:.1f}")
