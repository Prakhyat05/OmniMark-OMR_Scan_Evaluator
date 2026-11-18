import cv2
import numpy as np

img = cv2.imread("verified_relative_overlay_sample2.jpg")
h, w = img.shape[:2]

# Let's inspect Row 10 (which was made deliberately wrong to test red dot + green ring)
# In cropped image, Row 10 is around y = 145 px
# Check where the red pixels and green pixels are in Row 10
# Red in BGR: high R, low G, low B
red_mask = (img[:, :, 2] > 200) & (img[:, :, 1] < 50) & (img[:, :, 0] < 50)
green_mask = (img[:, :, 1] > 180) & (img[:, :, 2] < 50) & (img[:, :, 0] < 50)

red_y, red_x = np.where(red_mask)
green_y, green_x = np.where(green_mask)

print(f"Total red pixels (wrong answers marked): {len(red_x)}")
print(f"Total green pixels (correct markings & key rings): {len(green_x)}")

# Find clusters of red pixels
if len(red_x) > 0:
    for ry in np.unique(red_y):
        xs = red_x[red_y == ry]
        print(f"Red dot at y={ry}, x in [{min(xs)}..{max(xs)}]")
