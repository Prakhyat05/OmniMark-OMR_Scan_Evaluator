import cv2
import numpy as np
import json

with open("services/omr-engine/assets/exact_vector_blueprint.json") as f:
    data = json.load(f)

qs = data['questions']

# Load Sample 2 (Amar Singh)
sample2_path = r"C:\Users\prakh\.gemini\antigravity-ide\brain\392984a1-a503-4623-8270-82e8602f1fbf\.user_uploaded\media_1788415714038.jpg"
img = cv2.imread(sample2_path)
h, w = img.shape[:2]

overlay = img.copy()

# Draw exact vector oval markers on every bubble of Col 1
for q_num in range(1, 27):
    q_info = qs[str(q_num)]
    cy = int(q_info['opt_cy_norm'] * h)
    rx = int(q_info['rx_norm'] * w)
    ry = int(q_info['ry_norm'] * h)
    
    for opt_idx, opt_char in enumerate(['1', '2', '3', '4']):
        cx = int(q_info['opt_cx_norm'][opt_idx] * w)
        # Draw exact ellipse fitting the printed bubble!
        cv2.ellipse(overlay, (cx, cy), (rx, ry), 0, 0, 360, (0, 255, 0), 1)

crop = overlay[int(0.25*h):int(0.62*h), int(0.15*w):int(0.30*w)]
cv2.imwrite("exact_oval_overlay_crop.jpg", crop)
print("Saved exact_oval_overlay_crop.jpg")
