import cv2
import numpy as np
import fitz

doc = fitz.open("services/omr-engine/assets/vishwas_200q_master.pdf")
page = doc[0]

# Extract all text words with exact positions in Col 1
words = page.get_text("words")
col1_words = [w for w in words if 90 <= w[0] <= 180 and 200 <= w[1] <= 550]

print("=== Col 1 Words (x0=90..180, y0=200..550) ===")
# Group by Y coordinate (within 5 pt)
lines = {}
for w in sorted(col1_words, key=lambda x: x[1]):
    y0 = w[1]
    matched = False
    for ly in lines:
        if abs(y0 - ly) < 4:
            lines[ly].append(w)
            matched = True
            break
    if not matched:
        lines[y0] = [w]

for ly in sorted(lines):
    line_w = sorted(lines[ly], key=lambda x: x[0])
    txt = "  ".join([f"'{w[4]}' (x={w[0]:.1f}, y={w[1]:.1f})" for w in line_w])
    print(f"y={ly:.1f}: {txt}")
