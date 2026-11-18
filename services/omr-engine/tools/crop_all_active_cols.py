import cv2
import numpy as np

sample2_path = r"C:\Users\prakh\.gemini\antigravity-ide\brain\392984a1-a503-4623-8270-82e8602f1fbf\.user_uploaded\media_1788415714038.jpg"
img = cv2.imread(sample2_path)
h, w = img.shape[:2]
gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)

# Let's crop Column 2 from y=270 to y=620, x=200 to 285
col2_crop = gray[270:620, 200:285]
cv2.imwrite("col2_crop.jpg", col2_crop)

# Let's crop Column 3 from y=125 to y=620, x=280 to 375
col3_crop = gray[125:620, 280:375]
cv2.imwrite("col3_crop.jpg", col3_crop)

# Let's crop Column 4 from y=125 to y=620, x=365 to 455
col4_crop = gray[125:620, 365:455]
cv2.imwrite("col4_crop.jpg", col4_crop)

print("Saved col2_crop.jpg, col3_crop.jpg, col4_crop.jpg")
