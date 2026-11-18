import fitz

doc = fitz.open("services/omr-engine/assets/vishwas_200q_master.pdf")
page = doc[0]
w_pt, h_pt = page.rect.width, page.rect.height

words = page.get_text("words")

# Digits 0..9 in the 6 digit code area (x: 100..170, y: 90..215)
code_digits = [w for w in words if 95 <= w[0] <= 175 and 95 <= w[1] <= 215]

# Group by column X
cols = {}
for w in sorted(code_digits, key=lambda x: x[0]):
    cx = w[0]
    matched = False
    for k in cols:
        if abs(k - cx) < 4:
            cols[k].append(w)
            matched = True
            break
    if not matched:
        cols[cx] = [w]

print(f"Found {len(cols)} columns in 6-digit code grid:")
for col_idx, (cx, items) in enumerate(sorted(cols.items(), key=lambda x: x[0])):
    items_sorted = sorted(items, key=lambda x: x[1])
    digits = [it[4] for it in items_sorted]
    y_coords = [it[1] for it in items_sorted]
    print(f"Column {col_idx+1} at x={cx:.1f} (x_norm={cx/w_pt:.5f}):")
    print(f"  Digits: {digits}")
    print(f"  Y0={y_coords[0]:.1f} (y0_norm={y_coords[0]/h_pt:.5f}), Y_last={y_coords[-1]:.1f}")
    if len(y_coords) > 1:
        pitch = (y_coords[-1] - y_coords[0]) / (len(y_coords) - 1)
        print(f"  Pitch: {pitch:.2f} pt (pitch_norm={pitch/h_pt:.5f})")
