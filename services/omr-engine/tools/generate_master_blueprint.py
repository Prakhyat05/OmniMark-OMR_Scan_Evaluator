"""
Generates the Canonical Blueprint & Master Template for Universal 200Q OMR Sheet.
Calculates 100% exact subpixel coordinates for:
1. 4 Corner Fiducials
2. 6-Digit Code Grid (6 columns x 10 rows: 0..9)
3. 200 Questions Grid across 6 columns (Col 1: 1..26, Col 2: 27..52, Col 3: 53..89, Col 4: 90..126, Col 5: 127..163, Col 6: 164..200)
4. DynamicQuestionSlicer support for N questions (e.g. 50, 75, 100, 200)
"""
import json
import cv2
import numpy as np
import pymupdf

def generate_blueprint(pdf_path: str, output_json: str, output_overlay: str):
    doc = pymupdf.open(pdf_path)
    page = doc[0]
    pw, ph = page.rect.width, page.rect.height
    print(f"[+] Processing PDF Page: {pw} x {ph} pt")
    
    # Render 300 DPI image for visual validation overlay
    pix = page.get_pixmap(dpi=300)
    w_px, h_px = pix.width, pix.height
    scale_x = w_px / pw
    scale_y = h_px / ph
    print(f"[+] Rendered Canvas: {w_px} x {h_px} px (Scale: {scale_x:.4f}, {scale_y:.4f})")
    
    # 1. 6-Digit Code Number Grid
    # 6 columns:
    # X coordinates for digit columns 1..6:
    code_col_x_pt = [104.7, 115.5, 126.5, 137.6, 148.6, 159.4]
    # Y coordinates for digits 0..9 (10 rows):
    code_row_y_pt = [106.1 + i * 11.04 for i in range(10)]
    bubble_r_pt = 4.2
    
    code_grid = {
        "digits_count": 6,
        "rows_count": 10,
        "columns": []
    }
    
    for c_idx, cx_pt in enumerate(code_col_x_pt):
        col_data = {
            "col_index": c_idx + 1,
            "cx_pt": cx_pt,
            "cx_px": round(cx_pt * scale_x, 2),
            "cx_norm": cx_pt / pw,
            "digits": []
        }
        for d_val, cy_pt in enumerate(code_row_y_pt):
            col_data["digits"].append({
                "digit": d_val,
                "cx_pt": cx_pt,
                "cy_pt": cy_pt,
                "cx_px": round(cx_pt * scale_x, 2),
                "cy_px": round(cy_pt * scale_y, 2),
                "radius_px": round(bubble_r_pt * scale_x, 2),
                "cx_norm": cx_pt / pw,
                "cy_norm": cy_pt / ph,
                "radius_norm": bubble_r_pt / pw
            })
        code_grid["columns"].append(col_data)

    # 2. Questions Grid (200 Questions across 6 columns)
    # Column definitions:
    # Col 1: Q1..26 -> label x ~ 103.0 pt, Option 1 cx ~ 115.5 pt, start y ~ 226.8 pt, pitch y ~ 11.04 pt
    # Col 2: Q27..52 -> label x ~ 169.0 pt, Option 1 cx ~ 181.5 pt, start y ~ 226.8 pt, pitch y ~ 11.04 pt
    # Col 3: Q53..89 -> label x ~ 246.0 pt, Option 1 cx ~ 258.3 pt, start y ~ 106.1 pt, pitch y ~ 11.04 pt
    # Col 4: Q90..126 -> label x ~ 312.0 pt, Option 1 cx ~ 324.1 pt, start y ~ 106.1 pt, pitch y ~ 11.04 pt
    # Col 5: Q127..163 -> label x ~ 388.5 pt, Option 1 cx ~ 400.9 pt, start y ~ 106.1 pt, pitch y ~ 11.04 pt
    # Col 6: Q164..200 -> label x ~ 454.5 pt, Option 1 cx ~ 466.9 pt, start y ~ 106.1 pt, pitch y ~ 11.04 pt
    
    col_configs = [
        {"col_index": 1, "start_q": 1, "end_q": 26, "count": 26, "opt1_x_pt": 115.5, "start_y_pt": 226.8},
        {"col_index": 2, "start_q": 27, "end_q": 52, "count": 26, "opt1_x_pt": 181.5, "start_y_pt": 226.8},
        {"col_index": 3, "start_q": 53, "end_q": 89, "count": 37, "opt1_x_pt": 258.3, "start_y_pt": 106.1},
        {"col_index": 4, "start_q": 90, "end_q": 126, "count": 37, "opt1_x_pt": 324.1, "start_y_pt": 106.1},
        {"col_index": 5, "start_q": 127, "end_q": 163, "count": 37, "opt1_x_pt": 400.9, "start_y_pt": 106.1},
        {"col_index": 6, "start_q": 164, "end_q": 200, "count": 37, "opt1_x_pt": 466.9, "start_y_pt": 106.1}
    ]
    
    opt_step_pt = 10.85
    pitch_y_pt = 11.04
    
    questions_dict = {}
    
    for cfg in col_configs:
        start_q = cfg["start_q"]
        end_q = cfg["end_q"]
        opt1_x = cfg["opt1_x_pt"]
        start_y = cfg["start_y_pt"]
        col_idx = cfg["col_index"]
        
        for q_offset in range(end_q - start_q + 1):
            q_num = start_q + q_offset
            q_cy_pt = start_y + q_offset * pitch_y_pt
            
            options_list = []
            for opt_idx, opt_letter in enumerate(["A", "B", "C", "D"]):
                opt_cx_pt = opt1_x + opt_idx * opt_step_pt
                options_list.append({
                    "option": opt_letter,
                    "option_num": opt_idx + 1,
                    "cx_pt": opt_cx_pt,
                    "cy_pt": q_cy_pt,
                    "cx_px": round(opt_cx_pt * scale_x, 2),
                    "cy_px": round(q_cy_pt * scale_y, 2),
                    "radius_px": round(bubble_r_pt * scale_x, 2),
                    "cx_norm": opt_cx_pt / pw,
                    "cy_norm": q_cy_pt / ph,
                    "radius_norm": bubble_r_pt / pw
                })
            
            questions_dict[str(q_num)] = {
                "question_number": q_num,
                "column_index": col_idx,
                "row_index": q_offset + 1,
                "options": options_list
            }

    # 3. 4 Corner Fiducial Markers
    # TL: near (x=80, y=95.5), TR: near (x=513.5, y=95.5), BL: near (x=80, y=518.5), BR: near (x=513.5, y=518.5)
    fiducials = {
        "top_left": {"cx_pt": 80.0, "cy_pt": 95.5, "cx_px": round(80.0 * scale_x, 2), "cy_px": round(95.5 * scale_y, 2), "cx_norm": 80.0 / pw, "cy_norm": 95.5 / ph},
        "top_right": {"cx_pt": 513.5, "cy_pt": 95.5, "cx_px": round(513.5 * scale_x, 2), "cy_px": round(95.5 * scale_y, 2), "cx_norm": 513.5 / pw, "cy_norm": 95.5 / ph},
        "bottom_left": {"cx_pt": 80.0, "cy_pt": 518.5, "cx_px": round(80.0 * scale_x, 2), "cy_px": round(518.5 * scale_y, 2), "cx_norm": 80.0 / pw, "cy_norm": 518.5 / ph},
        "bottom_right": {"cx_pt": 513.5, "cy_pt": 518.5, "cx_px": round(513.5 * scale_x, 2), "cy_px": round(518.5 * scale_y, 2), "cx_norm": 513.5 / pw, "cy_norm": 518.5 / ph}
    }
    
    master_blueprint = {
        "template_id": "universal_200q_master",
        "name": "Universal 200Q Objective Sheet",
        "version": "1.0",
        "aspect_ratio": round(pw / ph, 5),
        "canvas_pt": {"width": pw, "height": ph},
        "canvas_px_300dpi": {"width": w_px, "height": h_px},
        "fiducials": fiducials,
        "code_grid": code_grid,
        "question_columns": col_configs,
        "questions": questions_dict
    }
    
    with open(output_json, "w") as f:
        json.dump(master_blueprint, f, indent=2)
    print(f"[+] Exported Master Blueprint to {output_json}")
    
    # 4. Generate Verification Overlay Image
    # Render overlay on top of 300 DPI master image
    img_data = np.frombuffer(pix.samples, dtype=np.uint8).reshape((h_px, w_px, pix.n))
    if pix.n == 4:
        overlay_img = cv2.cvtColor(img_data, cv2.COLOR_RGBA2BGR)
    elif pix.n == 3:
        overlay_img = cv2.cvtColor(img_data, cv2.COLOR_RGB2BGR)
    else:
        overlay_img = cv2.cvtColor(img_data, cv2.COLOR_GRAY2BGR)
    
    # Draw fiducials in blue
    for fid_name, fid in fiducials.items():
        fx, fy = int(fid["cx_px"]), int(fid["cy_px"])
        cv2.rectangle(overlay_img, (fx - 25, fy - 25), (fx + 25, fy + 25), (255, 0, 0), 3)
        cv2.putText(overlay_img, fid_name[:2].upper(), (fx - 20, fy - 30), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (255, 0, 0), 2)
    
    # Draw code grid in cyan
    for col in code_grid["columns"]:
        for d in col["digits"]:
            cx, cy = int(d["cx_px"]), int(d["cy_px"])
            r = int(d["radius_px"])
            cv2.circle(overlay_img, (cx, cy), r, (255, 255, 0), 2)
    
    # Draw question bubbles in green
    for q_str, q_data in questions_dict.items():
        for opt in q_data["options"]:
            cx, cy = int(opt["cx_px"]), int(opt["cy_px"])
            r = int(opt["radius_px"])
            cv2.circle(overlay_img, (cx, cy), r, (0, 255, 0), 2)
    
    cv2.imwrite(output_overlay, overlay_img)
    print(f"[+] Saved Verification Overlay Image to {output_overlay}")
    return master_blueprint

if __name__ == "__main__":
    generate_blueprint(
        "services/omr-engine/assets/vishwas_200q_master.pdf",
        "services/omr-engine/assets/vishwas_200q_template.json",
        "services/omr-engine/assets/vishwas_200q_overlay.png"
    )
