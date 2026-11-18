import cv2
import numpy as np

sample2_path = r"C:\Users\prakh\.gemini\antigravity-ide\brain\392984a1-a503-4623-8270-82e8602f1fbf\.user_uploaded\media_1788415714038.jpg"
img = cv2.imread(sample2_path)
h, w = img.shape[:2]
gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)

# Find all black squares/rectangles in the image
# Threshold to find pure black regions (val < 60)
_, thresh = cv2.threshold(gray, 60, 255, cv2.THRESH_BINARY_INV)

contours, _ = cv2.findContours(thresh, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)

black_blocks = []
for c in contours:
    x, y, bw, bh = cv2.boundingRect(c)
    area = cv2.contourArea(c)
    # Check if square or rectangle of size ~ 8..30 px
    if 6 <= bw <= 30 and 6 <= bh <= 30 and area > 30:
        aspect = bw / float(bh)
        if 0.7 <= aspect <= 1.4:
            black_blocks.append((x, y, bw, bh, area))

print(f"Total black square blocks found: {len(black_blocks)}")

# Let's group black blocks by X coordinate:
xs = [b[0] for b in black_blocks]
# Cluster xs
clusters = {}
for b in black_blocks:
    x = b[0]
    matched = False
    for cx in clusters:
        if abs(x - cx) < 15:
            clusters[cx].append(b)
            matched = True
            break
    if not matched:
        clusters[x] = [b]

print("\nBlack block columns (clusters by X):")
for cx in sorted(clusters.keys()):
    blocks = clusters[cx]
    mean_x = np.mean([b[0] for b in blocks])
    min_y = min([b[1] for b in blocks])
    max_y = max([b[1] for b in blocks])
    print(f"  Column at x={mean_x:.1f} (norm={mean_x/w:.4f}): count={len(blocks)} blocks, y=[{min_y}..{max_y}]")
