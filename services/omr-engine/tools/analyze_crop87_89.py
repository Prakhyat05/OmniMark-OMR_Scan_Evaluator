import cv2
import numpy as np

img = cv2.imread("crop87_89.jpg", 0)
h, w = img.shape
print(f"crop87_89 size: {w}x{h}")
# Find darkest pixels along x across the crop
for y in [7, 20, 34]:
    print(f"y={y}: min_x={np.argmin(img[y, :])}, min_v={np.min(img[y, :])}")
