import fitz

doc = fitz.open("services/omr-engine/assets/vishwas_200q_master.pdf")
page = doc[0]
rect = page.rect
print(f"Page size: {rect.width} x {rect.height}")

text_page = page.get_text("words") # list of (x0, y0, x1, y1, word, block_no, line_no, word_no)

# Find all words that start with a number or Q
questions = []
for w in text_page:
    word = w[4]
    x0, y0, x1, y1 = w[0], w[1], w[2], w[3]
    if word.isdigit():
        val = int(word)
        if 1 <= val <= 200:
            questions.append((val, x0, y0, x1, y1))

print(f"Total numeric labels found in range 1..200: {len(questions)}")

# Sort by X then Y to find columns
# Let's cluster by X coordinate
columns = {}
for q, x0, y0, x1, y1 in sorted(questions, key=lambda item: item[1]):
    # Group into columns within 30 pt
    col_found = False
    for col_x in columns:
        if abs(x0 - col_x) < 25:
            columns[col_x].append((q, x0, y0, x1, y1))
            col_found = True
            break
    if not col_found:
        columns[x0] = [(q, x0, y0, x1, y1)]

print(f"\nFound {len(columns)} distinct columns:")
for col_idx, (col_x, items) in enumerate(sorted(columns.items(), key=lambda x: x[0])):
    items_sorted = sorted(items, key=lambda x: x[2]) # sort by Y
    q_nums = [it[0] for it in items_sorted]
    min_y = min([it[2] for it in items_sorted])
    max_y = max([it[2] for it in items_sorted])
    print(f"\nColumn {col_idx+1} at x={col_x:.1f} (y={min_y:.1f}..{max_y:.1f}, count={len(items)}):")
    print(f"  First 5: {q_nums[:5]}")
    print(f"  Last 5:  {q_nums[-5:]}")
    print(f"  All: {q_nums}")
