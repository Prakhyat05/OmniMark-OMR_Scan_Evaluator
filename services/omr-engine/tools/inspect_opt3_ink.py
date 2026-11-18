import cv2
import numpy as np

img = cv2.imread("crop87_89.jpg", 0)
for y, q in [(7, 87), (20, 88), (34, 89)]:
    row = img[y, 50:70]
    min_x = np.argmin(row) + 50
    print(f"Q{q}: Option 3 ink at x={min_x} is {img[y, min_x]}")
