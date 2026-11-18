import cv2
import numpy as np

# Load master template image
master_img = cv2.imread("services/omr-engine/assets/vishwas_200q_master.jpg")
if master_img is None:
    print("Could not load master jpg directly, converting from pdf...")
    import fitz # PyMuPDF
    doc = fitz.open("services/omr-engine/assets/vishwas_200q_master.pdf")
    page = doc[0]
    pix = page.get_pixmap(dpi=300)
    pix.save("services/omr-engine/assets/vishwas_200q_master_300dpi.png")
    master_img = cv2.imread("services/omr-engine/assets/vishwas_200q_master_300dpi.png")

h, w = master_img.shape[:2]
print(f"Master image dimensions: {w}x{h}")

# Let's inspect the PDF text objects directly using PyMuPDF (fitz)
import fitz
doc = fitz.open("services/omr-engine/assets/vishwas_200q_master.pdf")
page = doc[0]
text_instances = page.get_text("blocks")
print(f"Total text blocks found: {len(text_instances)}")

print("\n--- First 30 text blocks with coordinates (bbox: x0, y0, x1, y1) ---")
for idx, b in enumerate(text_instances[:35]):
    # b: (x0, y0, x1, y1, text, block_no, block_type)
    x0, y0, x1, y1, text = b[0], b[1], b[2], b[3], b[4].strip().replace('\n', ' ')
    print(f"Block {idx:2d} (x={x0:.1f}..{x1:.1f}, y={y0:.1f}..{y1:.1f}): '{text}'")
