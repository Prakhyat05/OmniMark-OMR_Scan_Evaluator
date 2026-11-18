import fitz

doc = fitz.open("services/omr-engine/assets/vishwas_200q_master.pdf")
page = doc[0]
w_pt, h_pt = page.rect.width, page.rect.height

words = page.get_text("words")

# Find all words in the top left header area (x: 90..180, y: 40..110)
header_words = [w for w in words if 90 <= w[0] <= 180 and 30 <= w[1] <= 110]
for w in sorted(header_words, key=lambda x: (x[1], x[0])):
    print(f"Header word: '{w[4]}' (x={w[0]:.1f}, y={w[1]:.1f})")

# Look at the drawings / vector rects in page
drawings = page.get_drawings()
code_boxes = [d for d in drawings if 95 <= d['rect'].x0 <= 170 and 50 <= d['rect'].y0 <= 100]
print(f"\nFound {len(code_boxes)} vector rectangles/drawings in the code header box area.")
for b in code_boxes[:10]:
    print(f"Drawing rect: x={b['rect'].x0:.1f}..{b['rect'].x1:.1f}, y={b['rect'].y0:.1f}..{b['rect'].y1:.1f}")
