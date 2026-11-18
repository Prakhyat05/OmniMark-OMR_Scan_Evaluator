import cv2
import numpy as np
import fitz

# 1. Master PDF fiducials
doc = fitz.open("services/omr-engine/assets/vishwas_200q_master.pdf")
page = doc[0]
w_pt, h_pt = page.rect.width, page.rect.height

print(f"Master PDF size: {w_pt:.2f} x {h_pt:.2f} pt")

# Find all black drawings in PDF (drawings with fill black or rect)
drawings = page.get_drawings()
solid_rects = []
for d in drawings:
    r = d['rect']
    bw = r.x1 - r.x0
    bh = r.y1 - r.y0
    if 4 <= bw <= 20 and 4 <= bh <= 20 and abs(bw - bh) < 3:
        solid_rects.append((r.x0, r.y0, r.x1, r.y1, bw, bh))

print(f"Total solid square markers in PDF: {len(solid_rects)}")

# Find min x (leftmost) and max x (rightmost) solid markers
leftmost_in_pdf = min(solid_rects, key=lambda x: x[0])
rightmost_in_pdf = max(solid_rects, key=lambda x: x[0])

print(f"Leftmost marker in PDF: x0={leftmost_in_pdf[0]:.2f} (norm={leftmost_in_pdf[0]/w_pt:.4f}), y0={leftmost_in_pdf[1]:.2f}")
print(f"Rightmost marker in PDF: x0={rightmost_in_pdf[0]:.2f} (norm={rightmost_in_pdf[0]/w_pt:.4f}), y0={rightmost_in_pdf[1]:.2f}")

# 2. Inspect Sample 2 image
sample2_path = r"C:\Users\prakh\.gemini\antigravity-ide\brain\392984a1-a503-4623-8270-82e8602f1fbf\.user_uploaded\media_1788415714038.jpg"
img = cv2.imread(sample2_path)
h, w = img.shape[:2]
gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)

# Look at x < 130 for leftmost markers:
crop_left = gray[:, :130]
_, thresh_l = cv2.threshold(crop_left, 80, 255, cv2.THRESH_BINARY_INV)
cnts_l, _ = cv2.findContours(thresh_l, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
left_markers = []
for c in cnts_l:
    x, y, bw, bh = cv2.boundingRect(c)
    if 5 <= bw <= 20 and 5 <= bh <= 20 and 0.7 <= bw/bh <= 1.4:
        left_markers.append((x, y, bw, bh))

print(f"\nSample 2 Leftmost markers count: {len(left_markers)}")
if left_markers:
    mean_left_x = np.mean([m[0] + m[2]/2.0 for m in left_markers])
    print(f"Sample 2 Leftmost column center X: {mean_left_x:.2f} px (norm={mean_left_x/w:.4f})")

# Look at x > 550 for rightmost markers:
crop_right = gray[:, 550:]
_, thresh_r = cv2.threshold(crop_right, 80, 255, cv2.THRESH_BINARY_INV)
cnts_r, _ = cv2.findContours(thresh_r, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
right_markers = []
for c in cnts_r:
    x, y, bw, bh = cv2.boundingRect(c)
    if 5 <= bw <= 20 and 5 <= bh <= 20 and 0.7 <= bw/bh <= 1.4:
        right_markers.append((550 + x, y, bw, bh))

print(f"Sample 2 Rightmost markers count: {len(right_markers)}")
if right_markers:
    mean_right_x = np.mean([m[0] + m[2]/2.0 for m in right_markers])
    print(f"Sample 2 Rightmost column center X: {mean_right_x:.2f} px (norm={mean_right_x/w:.4f})")
