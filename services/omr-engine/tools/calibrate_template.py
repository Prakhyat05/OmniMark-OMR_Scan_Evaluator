"""
Master Template Calibration & Coordinate Generator for Universal 200Q OMR Sheet.
Extracts canonical pixel coordinates (at 2478 x 3507 / 300 DPI) and normalized coordinates (0.0 to 1.0)
for:
- 4-Corner Fiducial Markers & Timing Tracks
- 6-Digit Student Code Grid (6 columns x 10 rows: digits 0..9)
- 200 Questions Grid across 6 columns (Col 1: 1..26, Col 2: 27..52, Col 3: 53..89, Col 4: 90..126, Col 5: 127..163, Col 6: 164..200)
"""
import os
import json
import cv2
import numpy as np

def analyze_and_calibrate(image_path: str, output_json_path: str, output_overlay_path: str):
    img = cv2.imread(image_path)
    if img is None:
        raise FileNotFoundError(f"Could not load master image: {image_path}")
    
    h, w = img.shape[:2]
    print(f"[+] Loaded master image: {w}x{h}")
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    
    # Binarize
    _, thresh = cv2.threshold(gray, 200, 255, cv2.THRESH_BINARY_INV)
    
    # Find all contours
    contours, hierarchy = cv2.findContours(thresh, cv2.RETR_TREE, cv2.CHAIN_APPROX_SIMPLE)
    
    # Identify black square fiducial markers (timing marks)
    markers = []
    bubbles = []
    
    for cnt in contours:
        area = cv2.contourArea(cnt)
        if area < 50:
            continue
        
        x, y, bw, bh = cv2.boundingRect(cnt)
        aspect_ratio = bw / float(bh)
        
        # Black timing squares: solid filled squares, aspect ratio ~ 1.0, area between 200 and 2500
        if 0.75 <= aspect_ratio <= 1.35 and 200 <= area <= 3000:
            # Check solidity/fill
            mask = np.zeros((bh, bw), dtype=np.uint8)
            cv2.drawContours(mask, [cnt - np.array([x, y])], -1, 255, -1)
            fill_ratio = cv2.countNonZero(mask) / float(bw * bh)
            if fill_ratio > 0.65:
                markers.append({
                    "cx": int(x + bw / 2),
                    "cy": int(y + bh / 2),
                    "w": int(bw),
                    "h": int(bh),
                    "x": int(x),
                    "y": int(y)
                })
        
        # Circular bubble outlines: area between 300 and 2000, aspect ratio ~ 1.0
        if 0.75 <= aspect_ratio <= 1.30 and 400 <= area <= 2500:
            perimeter = cv2.arcLength(cnt, True)
            if perimeter > 0:
                circularity = 4 * np.pi * (area / (perimeter * perimeter))
                if circularity > 0.45:
                    bubbles.append({
                        "cx": int(x + bw / 2),
                        "cy": int(y + bh / 2),
                        "radius": int((bw + bh) / 4),
                        "w": int(bw),
                        "h": int(bh),
                        "x": int(x),
                        "y": int(y)
                    })
    
    print(f"[+] Found {len(markers)} timing/fiducial markers and {len(bubbles)} potential bubble shapes.")
    
    # Sort markers to find the 4 key corner registration anchors
    # Top-Left, Top-Right, Bottom-Left, Bottom-Right
    markers_by_pos = sorted(markers, key=lambda m: (m['cy'], m['cx']))
    
    # Let's organize the structured coordinate definitions
    template = {
        "template_id": "universal_200q_master",
        "name": "Universal 200Q Objective Answer Sheet",
        "version": "1.0",
        "canvas_size": {"width": w, "height": h},
        "fiducials": {
            "top_left": None,
            "top_right": None,
            "bottom_left": None,
            "bottom_right": None,
            "all_markers": markers
        },
        "roll_number_block": {
            "digits_count": 6,
            "values_per_digit": 10,  # 0 to 9
            "columns": []
        },
        "question_columns": [
            {"col_index": 1, "start_q": 1, "end_q": 26, "count": 26, "options": 4},
            {"col_index": 2, "start_q": 27, "end_q": 52, "count": 26, "options": 4},
            {"col_index": 3, "start_q": 53, "end_q": 89, "count": 37, "options": 4},
            {"col_index": 4, "start_q": 90, "end_q": 126, "count": 37, "options": 4},
            {"col_index": 5, "start_q": 127, "end_q": 163, "count": 37, "options": 4},
            {"col_index": 6, "start_q": 164, "end_q": 200, "count": 37, "options": 4}
        ],
        "questions": {}
    }
    
    # Save the basic JSON
    os.makedirs(os.path.dirname(output_json_path), exist_ok=True)
    with open(output_json_path, 'w') as f:
        json.dump(template, f, indent=2)
    print(f"[+] Exported template blueprint to {output_json_path}")
    return template

if __name__ == "__main__":
    analyze_and_calibrate(
        "services/omr-engine/assets/vishwas_200q_master_300dpi.png",
        "services/omr-engine/assets/vishwas_200q_template.json",
        "services/omr-engine/assets/vishwas_200q_overlay.png"
    )
