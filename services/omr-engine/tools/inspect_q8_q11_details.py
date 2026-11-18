import cv2
import numpy as np

img = cv2.imread("q8_to_q11_crop.jpg", 0)
h, w = img.shape

# The crop is y: 370..425 in original image
# Let's find every row with dark text on the left (x: 0..30)
for y in range(h):
    # check label ink (x: 5..20)
    label_darkness = np.min(img[y, 5:20])
    # check bubble ink (x: 20..w)
    bubble_min_x = np.argmin(img[y, 20:]) + 20
    bubble_darkness = img[y, bubble_min_x]
    
    if label_darkness < 150:
        orig_y = 370 + y
        print(f"y_crop={y:2d} (orig_y={orig_y}): label_ink={label_darkness} | darkest bubble at x_crop={bubble_min_x} with ink={bubble_darkness}")
