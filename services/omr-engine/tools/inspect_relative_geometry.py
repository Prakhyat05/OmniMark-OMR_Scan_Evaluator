import fitz

doc = fitz.open("services/omr-engine/assets/vishwas_200q_master.pdf")
page = doc[0]
w_pt, h_pt = page.rect.width, page.rect.height

# Let's inspect Column 1 (Q1 to Q26)
# For each question, extract:
# 1. Question number bounding box
# 2. Bubble 1, 2, 3, 4 center x, y and diameter

words = page.get_text("words")
drawings = page.get_drawings()

for q in [1, 5, 10, 15, 20, 25]:
    # Question label
    q_words = [w for w in words if w[4] == str(q) and w[0] < 112 and w[1] > 200]
    if not q_words:
        continue
    qw = q_words[0]
    qx_center = (qw[0] + qw[2]) / 2.0
    qy_center = (qw[1] + qw[3]) / 2.0
    
    # Bubbles on this row
    row_bubbles = []
    for d in drawings:
        r = d['rect']
        bw = r.x1 - r.x0
        bh = r.y1 - r.y0
        if 8 <= bw <= 13 and 8 <= bh <= 13 and abs(((r.y0+r.y1)/2.0) - qy_center) < 4.0 and 110 <= r.x0 <= 160:
            row_bubbles.append(((r.x0+r.x1)/2.0, (r.y0+r.y1)/2.0, bw, bh))
    
    row_bubbles = sorted(row_bubbles, key=lambda x: x[0])
    if len(row_bubbles) == 4:
        b1, b2, b3, b4 = row_bubbles
        print(f"Q{q:2d} (Label at x={qx_center:.2f}, y={qy_center:.2f}):")
        print(f"   Bubble 1 at x={b1[0]:.2f} (offset={b1[0]-qx_center:.2f} pt)")
        print(f"   Bubble 2 at x={b2[0]:.2f} (offset={b2[0]-qx_center:.2f} pt, gap={b2[0]-b1[0]:.2f} pt)")
        print(f"   Bubble 3 at x={b3[0]:.2f} (offset={b3[0]-qx_center:.2f} pt, gap={b3[0]-b2[0]:.2f} pt)")
        print(f"   Bubble 4 at x={b4[0]:.2f} (offset={b4[0]-qx_center:.2f} pt, gap={b4[0]-b3[0]:.2f} pt)")
        print(f"   Bubble sizes: {b1[2]:.2f}x{b1[3]:.2f} pt")
