import cv2
import numpy as np

# Load Sample 2 (Amar Singh)
sample2_path = r"C:\Users\prakh\.gemini\antigravity-ide\brain\392984a1-a503-4623-8270-82e8602f1fbf\.user_uploaded\media_1788415714038.jpg"
img = cv2.imread(sample2_path)
h, w = img.shape[:2]
gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)

print(f"Image size: {w}x{h}")

# Let's crop a window around Q12 to Q16 (x: 50..250 px, y: 400..500 px)
crop = img[400:520, 70:230]
cv2.imwrite("q12_to_q16_detailed_crop.jpg", crop)
print("Saved q12_to_q16_detailed_crop.jpg")

# Let's inspect the horizontal profile of Row 14 (around y = 456 px)
# From x = 70 px to x = 230 px
y_row14 = 456
row_strip = gray[y_row14-2:y_row14+3, 70:230]
mean_profile = np.mean(row_strip, axis=0)

# Print every 2 pixels to see where everything is:
# 1. Timing mark square
# 2. Question number '14'
# 3. Bubble 1 (A)
# 4. Bubble 2 (B)
# 5. Bubble 3 (C)
# 6. Bubble 4 (D)
print("\nHorizontal intensity profile for Row 14 (y=456):")
for idx, val in enumerate(mean_profile):
    x = 70 + idx
    # Only print local minima (dark peaks) or when dark
    if val < 200:
        print(f"  x={x:3d} (x/w={x/w:.4f}): intensity={val:.1f}")
