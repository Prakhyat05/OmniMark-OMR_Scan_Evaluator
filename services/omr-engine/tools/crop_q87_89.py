import cv2

img = cv2.imread(r"C:\Users\prakh\.gemini\antigravity-ide\brain\392984a1-a503-4623-8270-82e8602f1fbf\.user_uploaded\media_1788415714038.jpg")
# Crop Q87 and Q89 (Col 3 rows near the bottom: y ~ 565..605, x ~ 285..365)
crop87_89 = img[565:605, 285:365]
cv2.imwrite("crop87_89.jpg", crop87_89)
print("Saved crop87_89.jpg")
