import cv2

for name in ["q8_lbl.png", "q9_lbl.png", "q10_lbl.png", "q11_lbl.png"]:
    img = cv2.imread(name, 0)
    print(f"\n--- {name} ---")
    for r in range(img.shape[0]):
        line = "".join(["#" if p < 160 else " " for p in img[r]])
        print(line)
