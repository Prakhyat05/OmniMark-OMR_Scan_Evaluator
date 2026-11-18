import cv2
import numpy as np

sample2_path = r"C:\Users\prakh\.gemini\antigravity-ide\brain\392984a1-a503-4623-8270-82e8602f1fbf\.user_uploaded\media_1788415714038.jpg"
img = cv2.imread(sample2_path)
gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)

# Check Q9 vs Q10 in Col 1:
# Let's crop Q8, Q9, Q10, Q11 in Col 1 (y: 370..425, x: 125..205)
crop = img[370:425, 125:205]
cv2.imwrite("q8_to_q11_crop.jpg", crop)
print("Saved q8_to_q11_crop.jpg")

# Check Q69, Q70, Q71 in Col 3 (y: 360..400, x: 285..370)
crop3 = img[360:400, 285:370]
cv2.imwrite("q69_to_q71_crop.jpg", crop3)
print("Saved q69_to_q71_crop.jpg")

# Check Col 6 right side (x: 530..620, y: 300..500)
crop6 = img[300:500, 530:620]
cv2.imwrite("col6_crop.jpg", crop6)
print("Saved col6_crop.jpg")
