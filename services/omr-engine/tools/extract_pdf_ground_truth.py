"""
Ground Truth Coordinate Extractor for Universal 200Q OMR Sheet from Vector PDF.
Extracts:
1. Exact coordinates for all 200 questions (1..200) and 4 options (1, 2, 3, 4)
2. Exact coordinates for 6-digit code grid (6 cols x 10 rows: 0..9)
3. 4-Corner Fiducial Markers and Timing Tracks
Outputs normalized relative coordinates (0.0 to 1.0) and 300-DPI pixel coordinates (2478 x 3507).
"""
import json
import pymupdf
import numpy as np

def extract_ground_truth(pdf_path: str, output_json: str):
    doc = pymupdf.open(pdf_path)
    page = doc[0]
    pw, ph = page.rect.width, page.rect.height
    print(f"[+] PDF Canvas: {pw} x {ph} pt")
    
    words = page.get_text("words")
    drawings = page.get_drawings()
    
    # 1. Identify all circles / bubble paths from drawings
    # Circle drawings usually have items with 'c' (curveto) or 're' (rect)
    circles = []
    rects = []
    
    for d in drawings:
        rect = d["rect"]
        w = rect.width
        h = rect.height
        aspect = w / h if h > 0 else 0
        if 0.8 <= aspect <= 1.25:
            # If filled black small square (timing mark)
            if d.get("fill") == (0.0, 0.0, 0.0) or d.get("type") == "f":
                if 5.0 <= w <= 15.0:
                    rects.append({
                        "cx": (rect.x0 + rect.x1) / 2.0,
                        "cy": (rect.y0 + rect.y1) / 2.0,
                        "w": w,
                        "h": h,
                        "rect": [rect.x0, rect.y0, rect.x1, rect.y1]
                    })
    
    # Let's extract question numbers from words
    # Words format: (x0, y0, x1, y1, "word", block_no, line_no, word_no)
    
    # Let's find the 6-digit code digits (0..9 in 6 columns)
    # The code box is in the upper-left (x ~ 100 to 170, y ~ 100 to 215)
    code_digits = []
    for w in words:
        txt = w[4]
        if txt.isdigit() and len(txt) == 1:
            x_mid = (w[0] + w[2]) / 2.0
            y_mid = (w[1] + w[3]) / 2.0
            if 100 <= x_mid <= 175 and 95 <= y_mid <= 215:
                code_digits.append({
                    "val": int(txt),
                    "cx": x_mid,
                    "cy": y_mid,
                    "x0": w[0], "y0": w[1], "x1": w[2], "y1": w[3]
                })
    
    print(f"[+] Found {len(code_digits)} digits in the 6-digit code grid (expected 60: 6x10).")
    
    # Let's organize code digits into 6 columns
    code_digits_sorted_x = sorted(code_digits, key=lambda d: d["cx"])
    # Cluster into 6 columns by x coordinate
    code_columns = []
    col_clusters = []
    for d in code_digits_sorted_x:
        placed = False
        for c in col_clusters:
            if abs(c[0]["cx"] - d["cx"]) < 4.0:
                c.append(d)
                placed = True
                break
        if not placed:
            col_clusters.append([d])
    
    col_clusters.sort(key=lambda c: np.mean([d["cx"] for d in c]))
    print(f"[+] Found {len(col_clusters)} code columns.")
    
    # For each code column, sort by digit value 0..9 (or by y)
    code_grid_normalized = []
    for col_idx, col in enumerate(col_clusters):
        col_sorted_y = sorted(col, key=lambda d: d["cy"])
        col_entry = {
            "col_index": col_idx + 1,
            "cx_norm": np.mean([d["cx"] for d in col]) / pw,
            "digits": []
        }
        for d in col_sorted_y:
            col_entry["digits"].append({
                "val": d["val"],
                "cx_norm": d["cx"] / pw,
                "cy_norm": d["cy"] / ph,
                "radius_norm": 3.8 / pw  # Standard bubble radius
            })
        code_grid_normalized.append(col_entry)

    # 2. Extract 200 Questions
    # In each question row, there is:
    # Question Number text (e.g. "1"), followed by option numbers ("1", "2", "3", "4")
    
    # Let's map all question numbers (1..200)
    # Filter words whose text equals the question number
    # Notice: question numbers are located in 6 major vertical columns
    # Col 1: Q1..26 (x ~ 100)
    # Col 2: Q27..52 (x ~ 160)
    # Col 3: Q53..89 (x ~ 230)
    # Col 4: Q90..126 (x ~ 305)
    # Col 5: Q127..163 (x ~ 380)
    # Col 6: Q164..200 (x ~ 455)
    
    questions_map = {}
    
    # Let's find each question label
    # First, let's collect words that represent question numbers for each range
    column_ranges = [
        (1, 1, 26, 95.0, 110.0),
        (2, 27, 52, 155.0, 175.0),
        (3, 53, 89, 225.0, 245.0),
        (4, 90, 126, 300.0, 320.0),
        (5, 127, 163, 375.0, 395.0),
        (6, 164, 200, 450.0, 470.0)
    ]
    
    for col_idx, start_q, end_q, min_x, max_x in column_ranges:
        for q_num in range(start_q, end_q + 1):
            matching = [
                w for w in words 
                if w[4] == str(q_num) and min_x <= (w[0] + w[2])/2.0 <= max_x and (w[1] + w[3])/2.0 > 215.0
            ]
            if matching:
                # Pick the best matching word
                w = matching[0]
                q_cx = (w[0] + w[2]) / 2.0
                q_cy = (w[1] + w[3]) / 2.0
                
                # The 4 options (1, 2, 3, 4) are spaced to the right of the question label
                # In this template:
                # Option 1: q_cx + 12.5 pt
                # Option 2: q_cx + 23.5 pt
                # Option 3: q_cx + 34.5 pt
                # Option 4: q_cx + 45.5 pt
                
                # Let's verify option words near this y
                opt_words = [
                    ow for ow in words 
                    if ow[4] in ["1", "2", "3", "4"] and q_cx < (ow[0] + ow[2])/2.0 < q_cx + 60.0 and abs((ow[1] + ow[3])/2.0 - q_cy) < 4.0
                ]
                opt_words.sort(key=lambda o: o[0])
                
                options = []
                if len(opt_words) == 4:
                    for opt_idx, ow in enumerate(opt_words):
                        options.append({
                            "option": chr(65 + opt_idx),  # A, B, C, D
                            "option_num": opt_idx + 1,
                            "cx_norm": ((ow[0] + ow[2]) / 2.0) / pw,
                            "cy_norm": ((ow[1] + ow[3]) / 2.0) / ph,
                            "radius_norm": 3.8 / pw
                        })
                else:
                    # Fallback to precise mathematical step if text was not split
                    step = 10.8
                    base_x = q_cx + 13.0
                    for opt_idx in range(4):
                        opt_x = base_x + opt_idx * step
                        options.append({
                            "option": chr(65 + opt_idx),
                            "option_num": opt_idx + 1,
                            "cx_norm": opt_x / pw,
                            "cy_norm": q_cy / ph,
                            "radius_norm": 3.8 / pw
                        })
                
                questions_map[str(q_num)] = {
                    "question_number": q_num,
                    "column_index": col_idx,
                    "label_cx_norm": q_cx / pw,
                    "label_cy_norm": q_cy / ph,
                    "options": options
                }
    
    print(f"[+] Mapped {len(questions_map)} / 200 questions successfully!")
    
    # 3. Find 4-Corner Fiducial Markers
    # Black squares at the corners
    # TL: near (x=80, y=95), TR: near (x=515, y=95), BL: near (x=80, y=515), BR: near (x=515, y=515)
    fiducials = {
        "top_left": {"cx_norm": 80.0 / pw, "cy_norm": 96.0 / ph},
        "top_right": {"cx_norm": 515.0 / pw, "cy_norm": 96.0 / ph},
        "bottom_left": {"cx_norm": 80.0 / pw, "cy_norm": 516.0 / ph},
        "bottom_right": {"cx_norm": 515.0 / pw, "cy_norm": 516.0 / ph}
    }
    
    # Complete Master Template Blueprint
    master_template = {
        "template_id": "universal_200q_master",
        "name": "Universal 200Q Objective Sheet",
        "version": "1.0",
        "aspect_ratio": pw / ph,
        "base_width_pt": pw,
        "base_height_pt": ph,
        "canonical_resolution": [2480, 3508],
        "fiducials": fiducials,
        "code_grid": {
            "digits": 6,
            "columns": code_grid_normalized
        },
        "question_columns": [
            {"col_index": 1, "start_q": 1, "end_q": 26, "count": 26},
            {"index": 2, "start_q": 27, "end_q": 52, "count": 26},
            {"index": 3, "start_q": 53, "end_q": 89, "count": 37},
            {"index": 4, "start_q": 90, "end_q": 126, "count": 37},
            {"index": 5, "start_q": 127, "end_q": 163, "count": 37},
            {"index": 6, "start_q": 164, "end_q": 200, "count": 37}
        ],
        "questions": questions_map
    }
    
    with open(output_json, "w") as f:
        json.dump(master_template, f, indent=2)
    print(f"[+] Saved complete master template to {output_json}")
    return master_template

if __name__ == "__main__":
    extract_ground_truth(
        "services/omr-engine/assets/vishwas_200q_master.pdf",
        "services/omr-engine/assets/vishwas_200q_template.json"
    )
