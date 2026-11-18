import fitz

doc = fitz.open("services/omr-engine/assets/vishwas_200q_master.pdf")
page = doc[0]
w_pt, h_pt = page.rect.width, page.rect.height
drawings = page.get_drawings()

# Code grid area: x: 100..165, y: 100..210
# Filter drawings with circular/oval aspect ratio in this area
code_b = []
for d in drawings:
    r = d['rect']
    bw = r.x1 - r.x0
    bh = r.y1 - r.y0
    if 7.0 <= bw <= 13.0 and 7.0 <= bh <= 13.0 and 100 <= r.x0 <= 165 and 95 <= r.y0 <= 215:
        cx = (r.x0 + r.x1) / 2.0
        cy = (r.y0 + r.y1) / 2.0
        code_b.append({'cx': cx, 'cy': cy, 'bw': bw, 'bh': bh})

# Deduplicate points within 1.0 pt
dedup = []
for b in code_b:
    if not any(abs(d['cx'] - b['cx']) < 1.0 and abs(d['cy'] - b['cy']) < 1.0 for d in dedup):
        dedup.append(b)

print(f"Total unique bubble circles in 6-digit code grid: {len(dedup)} (expected 60: 6 cols x 10 digits)")

# Group by column X
cols = {}
for b in sorted(dedup, key=lambda x: x['cx']):
    cx = b['cx']
    matched = False
    for k in cols:
        if abs(k - cx) < 3.0:
            cols[k].append(b)
            matched = True
            break
    if not matched:
        cols[cx] = [b]

for col_idx, (cx, items) in enumerate(sorted(cols.items(), key=lambda x: x[0])):
    items_sorted = sorted(items, key=lambda x: x['cy'])
    ys = [f"{it['cy']:.2f}" for it in items_sorted]
    print(f"Col {col_idx+1} at x={cx:.2f} (x_norm={cx/w_pt:.5f}): {len(items)} digits at y={ys}")
