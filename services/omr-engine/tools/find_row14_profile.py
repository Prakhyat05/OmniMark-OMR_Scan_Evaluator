import cv2
import numpy as np

img = cv2.imread(r"C:\Users\prakh\.gemini\antigravity-ide\brain\392984a1-a503-4623-8270-82e8602f1fbf\.user_uploaded\media_1788415714038.jpg")
h, w = img.shape[:2]

# Let's inspect Row 14 (Q14)
# In Row 14, student filled bubble (1).
# Let's find the exact X coordinate of the filled circle center in Row 14!
gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)

# Let's sample a horizontal profile across Row 14 (y = 0.44 * h to 0.45 * h, x = 0.10 * w to 0.30 * w)
y_row14 = int(0.444 * h)
x_start = int(0.12 * w)
x_end = int(0.30 * w)

row_strip = gray[y_row14-3:y_row14+4, x_start:x_end]
mean_profile = np.mean(row_strip, axis=0)

min_x_idx = np.argmin(mean_profile)
darkest_x = x_start + min_x_idx
darkest_x_norm = darkest_x / float(w)

print(f"Row 14 darkest peak at x={darkest_x} (x_norm={darkest_x_norm:.5f}) with intensity={mean_profile[min_x_idx]:.1f}")

# Find all 4 bubble positions across Row 14
print("\nHorizontal intensity profile across Row 14:")
for x in range(x_start, x_end, 5):
    val = np.mean(gray[y_row14-2:y_row14+3, x-2:x+3])
    print(f"  x={x:3d} (x_norm={x/w:.5f}): {val:.1f}")
