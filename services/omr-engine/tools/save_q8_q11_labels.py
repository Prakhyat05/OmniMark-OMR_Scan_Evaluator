import cv2

img = cv2.imread(r"C:\Users\prakh\.gemini\antigravity-ide\brain\392984a1-a503-4623-8270-82e8602f1fbf\.user_uploaded\media_1788415714038.jpg")
# Crop just the question labels for Q8, Q9, Q10, Q11
q8_lbl = img[380:388, 130:144]
q9_lbl = img[392:400, 130:144]
q10_lbl = img[403:412, 130:144]
q11_lbl = img[418:427, 130:144]

cv2.imwrite("q8_lbl.png", q8_lbl)
cv2.imwrite("q9_lbl.png", q9_lbl)
cv2.imwrite("q10_lbl.png", q10_lbl)
cv2.imwrite("q11_lbl.png", q11_lbl)
print("Saved q8_lbl..q11_lbl")
