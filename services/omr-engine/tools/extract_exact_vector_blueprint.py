import fitz
import json

doc = fitz.open("services/omr-engine/assets/vishwas_200q_master.pdf")
page = doc[0]
w_pt, h_pt = page.rect.width, page.rect.height

drawings = page.get_drawings()

# Find all vector bubble paths
all_bubbles = []
for d in drawings:
    r = d['rect']
    bw = r.x1 - r.x0
    bh = r.y1 - r.y0
    if 6.0 <= bw <= 16.0 and 6.0 <= bh <= 16.0:
        cx = (r.x0 + r.x1) / 2.0
        cy = (r.y0 + r.y1) / 2.0
        all_bubbles.append({
            'cx': cx, 'cy': cy, 'w': bw, 'h': bh,
            'cx_norm': round(cx / w_pt, 5),
            'cy_norm': round(cy / h_pt, 5),
            'rx_norm': round((bw / 2.0) / w_pt, 5),
            'ry_norm': round((bh / 2.0) / h_pt, 5),
        })

print(f"Extracted {len(all_bubbles)} vector bubbles from PDF drawings.")

# The 6 columns are:
# Col 1: Q1..26   (4 bubbles * 26 = 104)
# Col 2: Q27..52  (4 bubbles * 26 = 104)
# Col 3: Q53..89  (4 bubbles * 37 = 148)
# Col 4: Q90..126 (4 bubbles * 37 = 148)
# Col 5: Q127..163(4 bubbles * 37 = 148)
# Col 6: Q164..200(4 bubbles * 37 = 148)
# Total question bubbles = 104 + 104 + 148 + 148 + 148 + 148 = 800 bubbles!
# Plus 6-digit code grid = 6 * 10 = 60 bubbles!
# Total = 860 bubbles!

# Separate code grid bubbles (x: 100..170, y: 100..215)
code_bubbles = [b for b in all_bubbles if 100 <= b['cx'] <= 170 and 100 <= b['cy'] <= 215]
q_bubbles = [b for b in all_bubbles if b not in code_bubbles]

print(f"Code grid bubbles: {len(code_bubbles)} (expected 60)")
print(f"Question bubbles:  {len(q_bubbles)} (expected 800)")

# Cluster question bubbles into 6 columns by X coordinate
# Column boundaries:
# Col 1: x in [110..160], y in [220..510] -> Q1..26
# Col 2: x in [175..225], y in [220..510] -> Q27..52
# Col 3: x in [250..300], y in [100..510] -> Q53..89
# Col 4: x in [320..370], y in [100..510] -> Q90..126
# Col 5: x in [395..445], y in [100..510] -> Q127..163
# Col 6: x in [465..515], y in [100..510] -> Q164..200

col_defs = [
    (1, 26, (110, 160), (220, 510)),
    (27, 52, (175, 225), (220, 510)),
    (53, 89, (250, 300), (100, 510)),
    (90, 126, (320, 370), (100, 510)),
    (127, 163, (395, 445), (100, 510)),
    (164, 200, (465, 515), (100, 510)),
]

final_grid = {}

for q_start, q_end, (x_min, x_max), (y_min, y_max) in col_defs:
    col_b = [b for b in q_bubbles if x_min <= b['cx'] <= x_max and y_min <= b['cy'] <= y_max]
    # Group into rows by cy
    rows = {}
    for b in sorted(col_b, key=lambda item: item['cy']):
        matched = False
        for ry in rows:
            if abs(ry - b['cy']) < 3.0:
                rows[ry].append(b)
                matched = True
                break
        if not matched:
            rows[b['cy']] = [b]
    
    rows_sorted = [sorted(b_list, key=lambda it: it['cx']) for ry, b_list in sorted(rows.items(), key=lambda it: it[0])]
    print(f"Col {q_start}..{q_end}: found {len(rows_sorted)} rows (expected {q_end - q_start + 1})")
    
    for idx, row in enumerate(rows_sorted):
        q_num = q_start + idx
        if len(row) == 4:
            final_grid[q_num] = {
                'q': q_num,
                'opt_cx_norm': [r['cx_norm'] for r in row],
                'opt_cy_norm': round(sum([r['cy_norm'] for r in row]) / 4.0, 5),
                'rx_norm': row[0]['rx_norm'],
                'ry_norm': row[0]['ry_norm'],
            }

print(f"Successfully constructed exact vector blueprint for {len(final_grid)} questions!")

# Extract exact 6-digit code grid columns & rows
code_cols = {}
for b in sorted(code_bubbles, key=lambda x: x['cx']):
    cx = b['cx']
    matched = False
    for k in code_cols:
        if abs(k - cx) < 3.0:
            code_cols[k].append(b)
            matched = True
            break
    if not matched:
        code_cols[cx] = [b]

code_grid_final = []
for cx, b_list in sorted(code_cols.items(), key=lambda x: x[0]):
    b_sorted = sorted(b_list, key=lambda it: it['cy'])
    code_grid_final.append({
        'cx_norm': round(cx / w_pt, 5),
        'digits_cy_norm': [round(b['cy_norm'], 5) for b in b_sorted],
        'rx_norm': b_sorted[0]['rx_norm'],
        'ry_norm': b_sorted[0]['ry_norm'],
    })

print(f"Code grid: {len(code_grid_final)} columns, each with {len(code_grid_final[0]['digits_cy_norm'])} digits.")

# Save final vector ground truth json
output_data = {
    'questions': final_grid,
    'code_grid': code_grid_final,
}

with open("services/omr-engine/assets/exact_vector_blueprint.json", "w") as f:
    json.dump(output_data, f, indent=2)

print("Saved exact_vector_blueprint.json")
