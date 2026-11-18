import fitz
import json

doc = fitz.open("services/omr-engine/assets/vishwas_200q_master.pdf")
page = doc[0]
w_pt, h_pt = page.rect.width, page.rect.height

# Get all drawings (vector paths/circles/rectangles)
drawings = page.get_drawings()
print(f"Total vector drawings on PDF: {len(drawings)}")

# Find all circular/oval bubble paths
# A bubble drawing usually has a width between 5 pt and 15 pt and height between 5 pt and 15 pt
bubble_rects = []
for d in drawings:
    r = d['rect'] # Rect(x0, y0, x1, y1)
    bw = r.x1 - r.x0
    bh = r.y1 - r.y0
    # Check if it looks like a bubble
    if 4.0 <= bw <= 18.0 and 4.0 <= bh <= 18.0:
        cx = (r.x0 + r.x1) / 2.0
        cy = (r.y0 + r.y1) / 2.0
        bubble_rects.append({
            'x0': r.x0, 'y0': r.y0, 'x1': r.x1, 'y1': r.y1,
            'cx': cx, 'cy': cy, 'w': bw, 'h': bh,
            'cx_norm': cx / w_pt, 'cy_norm': cy / h_pt,
            'w_norm': bw / w_pt, 'h_norm': bh / h_pt,
        })

print(f"Found {len(bubble_rects)} candidate bubble vector drawings on the page!")

# Let's inspect bubble drawings in Column 1 (x: 100..160, y: 220..510)
col1_bubbles = [b for b in bubble_rects if 100 <= b['cx'] <= 160 and 220 <= b['cy'] <= 510]
print(f"Found {len(col1_bubbles)} bubbles in Col 1 area (Q1..26 × 4 = 104 expected):")

# Group by Y coordinate
rows = {}
for b in sorted(col1_bubbles, key=lambda x: x['cy']):
    matched = False
    for ry in rows:
        if abs(ry - b['cy']) < 3.0:
            rows[ry].append(b)
            matched = True
            break
    if not matched:
        rows[b['cy']] = [b]

print(f"Found {len(rows)} distinct question rows in Col 1:")
for row_idx, (ry, b_list) in enumerate(sorted(rows.items(), key=lambda x: x[0])):
    b_sorted = sorted(b_list, key=lambda x: x['cx'])
    xs = [f"{b['cx']:.2f}" for b in b_sorted]
    bw = b_sorted[0]['w']
    bh = b_sorted[0]['h']
    print(f"Row {row_idx+1:2d} (y={ry:.2f}): {len(b_sorted)} bubbles at x={xs}, size={bw:.2f}x{bh:.2f} pt")
