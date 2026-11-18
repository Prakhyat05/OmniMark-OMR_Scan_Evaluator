import cv2
import numpy as np

# Load Sample 1 code crop
crop1 = cv2.imread("code_crop_sample_1.jpg")
gray1 = cv2.cvtColor(crop1, cv2.COLOR_BGR2GRAY)
ch, cw = gray1.shape[:2]

# In sample 1, we expect 224567.
# Let's find the 6 darkest spots in the crop!
# We can find the 6 columns by summing vertical projections or finding dark bubble centers
# Apply threshold
_, thresh = cv2.threshold(gray1, 100, 255, cv2.THRESH_BINARY_INV)

# Find contours of filled bubbles
contours, _ = cv2.findContours(thresh, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
filled_bubbles = []
for cnt in contours:
    area = cv2.contourArea(cnt)
    if 10 < area < 500: # bubble size
        (x, y), radius = cv2.minEnclosingCircle(cnt)
        if 2 < radius < 15:
            filled_bubbles.append((int(x), int(y), int(radius), area))

print(f"Found {len(filled_bubbles)} candidate filled bubbles in Sample 1 code crop:")
for fb in sorted(filled_bubbles, key=lambda b: b[0]): # sort by x
    print(f"  Bubble at x={fb[0]}, y={fb[1]}, r={fb[2]}, area={fb[3]}")
