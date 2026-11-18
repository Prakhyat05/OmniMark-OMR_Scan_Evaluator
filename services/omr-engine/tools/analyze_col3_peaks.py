import cv2
import numpy as np

img = cv2.imread("col3_top_crop.jpg", 0)
h, w = img.shape

# Let's find every row where text or bubbles exist in col3_top_crop
# The crop is y=100..220 in original image
row_darkness = np.mean(255.0 - img, axis=1)

# Find peaks in row_darkness
print("Row peaks in col3_top_crop (y in original image = 100 + y_crop):")
for y in range(1, h-1):
    if row_darkness[y] > row_darkness[y-1] and row_darkness[y] > row_darkness[y+1] and row_darkness[y] > 20:
        orig_y = 100 + y
        # Find x of darkest point in this row
        min_x = np.argmin(img[y, :])
        min_v = img[y, min_x]
        print(f"  Row peak at y_crop={y:2d} (orig_y={orig_y:3d}, norm={orig_y/1024:.4f}) | darkest at x_crop={min_x} (orig_x={270+min_x}) with val={min_v}")
