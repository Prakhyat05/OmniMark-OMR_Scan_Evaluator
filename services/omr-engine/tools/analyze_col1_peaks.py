import cv2
import numpy as np

img = cv2.imread("col1_top_crop.jpg", 0)
h, w = img.shape
row_darkness = np.mean(255.0 - img, axis=1)

print("Row peaks in col1_top_crop (orig_y = 260 + y_crop):")
for y in range(1, h-1):
    if row_darkness[y] > row_darkness[y-1] and row_darkness[y] > row_darkness[y+1] and row_darkness[y] > 20:
        orig_y = 260 + y
        min_x = np.argmin(img[y, :])
        min_v = img[y, min_x]
        print(f"  Row peak at y_crop={y:2d} (orig_y={orig_y:3d}, norm={orig_y/1024:.4f}) | darkest at x_crop={min_x} (orig_x={110+min_x}) with val={min_v}")
