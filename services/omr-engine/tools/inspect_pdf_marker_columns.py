import fitz
import numpy as np

doc = fitz.open("services/omr-engine/assets/vishwas_200q_master.pdf")
page = doc[0]
w_pt, h_pt = page.rect.width, page.rect.height

drawings = page.get_drawings()
solid_rects = []
for d in drawings:
    r = d['rect']
    bw = r.x1 - r.x0
    bh = r.y1 - r.y0
    if 4 <= bw <= 12 and 4 <= bh <= 12 and abs(bw - bh) < 2:
        solid_rects.append(((r.x0+r.x1)/2.0, (r.y0+r.y1)/2.0))

print(f"Total small square markers in PDF: {len(solid_rects)}")

# Group by X:
clusters = {}
for x, y in solid_rects:
    matched = False
    for cx in clusters:
        if abs(x - cx) < 5:
            clusters[cx].append((x, y))
            matched = True
            break
    if not matched:
        clusters[x] = [(x, y)]

print("Marker columns in PDF (X positions):")
for cx in sorted(clusters.keys()):
    pts = clusters[cx]
    mean_x = np.mean([p[0] for p in pts])
    print(f"  Column at x={mean_x:.2f} pt (norm={mean_x/w_pt:.4f}): count={len(pts)} markers")
