import cv2
import numpy as np

sample2_path = r"C:\Users\prakh\.gemini\antigravity-ide\brain\392984a1-a503-4623-8270-82e8602f1fbf\.user_uploaded\media_1788415714038.jpg"
img = cv2.imread(sample2_path)
h, w = img.shape[:2]
gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)

print(f"Sample 2 image dimensions: {w}x{h}")

# The user gave us the exact ground truth:
# Q1..Q93 are marked.
# Q94..Q200 are UNANSWERED (BLANK).
# Against TESTING key:
# Incorrect questions: [10, 20, 30, 40, 50, 60, 70, 71, 80] (total 9 incorrect)
# Correct questions: 93 - 9 = 84 correct.
# Unattempted: 107 (Q94..200).

# Let's inspect where the 6 columns are located on this 730x1024 image:
# Col 1: Q1..26   (starts at y ~ 284 px, y_pitch ~ 13.9 px)
# Col 2: Q27..52  (starts at y ~ 284 px, y_pitch ~ 13.9 px)
# Col 3: Q53..89  (starts at y ~ 138 px, y_pitch ~ 13.9 px)
# Col 4: Q90..126 (starts at y ~ 138 px, y_pitch ~ 13.9 px)
# Col 5: Q127..163(starts at y ~ 138 px, y_pitch ~ 13.9 px)
# Col 6: Q164..200(starts at y ~ 138 px, y_pitch ~ 13.9 px)

# Let's find the exact horizontal positions of all 6 columns!
# Take horizontal strip where all columns are present: y = 300 to 500
strip = gray[300:500, :]
darkness = 255.0 - strip
proj = np.mean(darkness, axis=0)

# Save projection visualization
cv2.imwrite("proj_strip.jpg", strip)

print("\n--- Let's inspect Col 2 (Q27..52) ---")
# On Row 27 (Amar should have marked Option 2):
# Let's search x = 200 to 300 around y = 284 px:
for x in range(200, 290, 5):
    val = np.mean(gray[280:290, x:x+5])
    print(f"  Col 2 x={x}..{x+5} (norm={x/w:.4f}): val={val:.1f}")
