import cv2

img = cv2.imread(r"C:\Users\prakh\.gemini\antigravity-ide\brain\392984a1-a503-4623-8270-82e8602f1fbf\.user_uploaded\media_1788415714038.jpg")
# Crop Col 3 top rows
crop = img[100:220, 270:380]
cv2.imwrite("col3_top_crop.jpg", crop)
print("Saved col3_top_crop.jpg")

# Also crop Col 1 top rows
crop1 = img[260:350, 110:210]
cv2.imwrite("col1_top_crop.jpg", crop1)
print("Saved col1_top_crop.jpg")
