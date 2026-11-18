import cv2
import numpy as np

img = cv2.imread(r"C:\Users\prakh\.gemini\antigravity-ide\brain\392984a1-a503-4623-8270-82e8602f1fbf\.user_uploaded\media_1788415714038.jpg")
gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)

# Col 4 starts at y ~ 140 px, x ~ 377 px
print("Col 4 (Q90..95) bubbles:")
for idx in range(6):
    q = 90 + idx
    y = int(140 + idx * 12.75)
    # Check 4 bubbles
    for opt in range(4):
        bx = int(377 + (1.25 + opt) * 14)
        roi = gray[y-4:y+5, bx-5:bx+6]
        min_v = np.min(roi)
        mean_v = np.mean(roi)
        score = 0.5 * min_v + 0.5 * mean_v
        if score < 100:
            print(f"  Q{q}: Option {opt+1} marked with score={score:.1f}")
