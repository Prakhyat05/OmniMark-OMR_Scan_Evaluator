import fitz

doc = fitz.open("services/omr-engine/assets/vishwas_200q_master.pdf")
page = doc[0]
w_pt, h_pt = page.rect.width, page.rect.height

# Let's inspect everything on Row 12 (y around 347 pt)
# In PDF: Row 12 is at y ~ 347 pt
words = page.get_text("words")
row12_words = [w for w in words if 340 <= w[1] <= 355 and w[0] < 200]
print(f"Row 12 text words (x0, y0, x1, y1, text):")
for w in sorted(row12_words, key=lambda x: x[0]):
    print(f"  x=[{w[0]:.2f}..{w[2]:.2f}], y=[{w[1]:.2f}..{w[3]:.2f}], text='{w[4]}'")

drawings = page.get_drawings()
row12_drawings = []
for d in drawings:
    r = d['rect']
    if 340 <= r.y0 <= 355 and r.x0 < 200 and 5 <= (r.x1-r.x0) <= 15:
        row12_drawings.append(r)

print(f"\nRow 12 vector circles:")
for r in sorted(row12_drawings, key=lambda x: x.x0):
    cx = (r.x0 + r.x1) / 2.0
    cy = (r.y0 + r.y1) / 2.0
    print(f"  circle at cx={cx:.2f} (norm={cx/w_pt:.5f}), cy={cy:.2f} (norm={cy/h_pt:.5f}), size={r.x1-r.x0:.2f}x{r.y1-r.y0:.2f}")
