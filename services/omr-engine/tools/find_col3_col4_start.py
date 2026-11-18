import cv2
import numpy as np

sample2_path = r"C:\Users\prakh\.gemini\antigravity-ide\brain\392984a1-a503-4623-8270-82e8602f1fbf\.user_uploaded\media_1788415714038.jpg"
img = cv2.imread(sample2_path)
h, w = img.shape[:2]
gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)

# The user explicitly said:
# "Q1 - Q93 are marked sequentially"
# "and only this OMR (Q10, 20, 30, 40, 50, 60, 70, 71, 80) is incorrect."
# "A total of 93 questions are marked sequentially (Q1 - Q93), and the rest of the questions till 200 are unanswered."

# Let's verify Q53: where is Question 53 (Row 1 of Column 3)?
# Let's inspect x from 280 to 360, y from 100 to 160:
crop = gray[100:160, 280:360]
print("Finding Q53 (Col 3 Row 1):")
for y in range(110, 150, 2):
    row = gray[y, 285:350]
    min_v = np.min(row)
    if min_v < 100:
        print(f"  y={y} (norm={y/h:.4f}): min_v={min_v} at x={285+np.argmin(row)}")

# And where is Q90 (Col 4 Row 1)?
print("\nFinding Q90 (Col 4 Row 1):")
for y in range(110, 150, 2):
    row = gray[y, 365:430]
    min_v = np.min(row)
    if min_v < 100:
        print(f"  y={y} (norm={y/h:.4f}): min_v={min_v} at x={365+np.argmin(row)}")
