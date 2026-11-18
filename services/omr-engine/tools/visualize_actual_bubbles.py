import cv2
import numpy as np

# Load Sample 2 (Amar Singh)
sample2_path = r"C:\Users\prakh\.gemini\antigravity-ide\brain\392984a1-a503-4623-8270-82e8602f1fbf\.user_uploaded\media_1788415714038.jpg"
img2 = cv2.imread(sample2_path)
h, w = img2.shape[:2]

# Let's crop Column 1 (from Q1 down to Q26)
# In image coordinates, let's crop x from 0.12*w to 0.32*w and y from 0.25*h to 0.65*h
col1_crop = img2[int(0.26*h):int(0.65*h), int(0.12*w):int(0.32*w)]
cv2.imwrite("col1_full_visual_crop.jpg", col1_crop)
print(f"Saved col1_full_visual_crop.jpg ({col1_crop.shape[1]}x{col1_crop.shape[0]})")

# Load Sample 1 (Vedehi)
sample1_path = r"C:\Users\prakh\.gemini\antigravity-ide\brain\392984a1-a503-4623-8270-82e8602f1fbf\.user_uploaded\media_1788415707484.jpg"
img1 = cv2.imread(sample1_path)
h1, w1 = img1.shape[:2]
col1_crop1 = img1[int(0.26*h1):int(0.65*h1), int(0.12*w1):int(0.32*w1)]
cv2.imwrite("col1_sample1_visual_crop.jpg", col1_crop1)
print(f"Saved col1_sample1_visual_crop.jpg ({col1_crop1.shape[1]}x{col1_crop1.shape[0]})")
