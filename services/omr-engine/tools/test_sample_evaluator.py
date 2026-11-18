"""
Sample Evaluator & Benchmark Test Harness for Universal 200Q OMR Sheet.
Tests perspective alignment, 6-digit code detection, and question bubble reading
on the 3 user-provided real marked scans.
"""
import os
import json
import cv2
import numpy as np

def align_sheet_to_template(img: np.ndarray, target_w: int = 2480, target_h: int = 3508) -> np.ndarray:
    """Detects sheet corners / fiducials and warps to canonical canvas."""
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    h, w = gray.shape[:2]
    
    # Threshold to find black timing marks
    _, bin_inv = cv2.threshold(gray, 180, 255, cv2.THRESH_BINARY_INV)
    contours, _ = cv2.findContours(bin_inv, cv2.RETR_TREE, cv2.CHAIN_APPROX_SIMPLE)
    
    markers = []
    for c in contours:
        x, y, bw, bh = cv2.boundingRect(c)
        aspect = bw / float(bh)
        area = cv2.contourArea(c)
        if 5 <= bw <= 65 and 5 <= bh <= 65 and 0.65 <= aspect <= 1.50 and area > 25:
            # Solidity check
            mask = np.zeros((bh, bw), dtype=np.uint8)
            cv2.drawContours(mask, [c - np.array([x, y])], -1, 255, -1)
            fill_ratio = cv2.countNonZero(mask) / float(bw * bh)
            if fill_ratio > 0.55:
                markers.append((int(x + bw/2), int(y + bh/2), bw, bh, x, y))
    
    if len(markers) < 4:
        # If photo is already cropped/aligned, resize directly
        return cv2.resize(img, (target_w, target_h), interpolation=cv2.INTER_CUBIC)
    
    # Separate markers by quadrants to find the 4 extreme fiducial corners
    # Quad 0: Top-Left, Quad 1: Top-Right, Quad 2: Bottom-Left, Quad 3: Bottom-Right
    mid_x, mid_y = w / 2.0, h / 2.0
    
    tl_list = [m for m in markers if m[0] < mid_x and m[1] < mid_y]
    tr_list = [m for m in markers if m[0] >= mid_x and m[1] < mid_y]
    bl_list = [m for m in markers if m[0] < mid_x and m[1] >= mid_y]
    br_list = [m for m in markers if m[0] >= mid_x and m[1] >= mid_y]
    
    if not (tl_list and tr_list and bl_list and br_list):
        return cv2.resize(img, (target_w, target_h), interpolation=cv2.INTER_CUBIC)
    
    # Extreme corners:
    # TL: min (x + y)
    tl = min(tl_list, key=lambda m: m[0] + m[1])
    # TR: max (x - y)
    tr = max(tr_list, key=lambda m: m[0] - m[1])
    # BL: min (x - y)
    bl = min(bl_list, key=lambda m: m[0] - m[1])
    # BR: max (x + y)
    br = max(br_list, key=lambda m: m[0] + m[1])
    
    src_pts = np.array([
        [tl[0], tl[1]],
        [tr[0], tr[1]],
        [br[0], br[1]],
        [bl[0], bl[1]]
    ], dtype="float32")
    
    # Destination fiducials in canonical space
    # (Top-Left marker ~ [333, 398], TR ~ [2139, 398], BR ~ [2139, 2160], BL ~ [333, 2160])
    dst_pts = np.array([
        [333.3, 397.9],
        [2139.6, 397.9],
        [2139.6, 2160.4],
        [333.3, 2160.4]
    ], dtype="float32")
    
    matrix = cv2.getPerspectiveTransform(src_pts, dst_pts)
    warped = cv2.warpPerspective(img, matrix, (target_w, target_h), flags=cv2.INTER_CUBIC)
    return warped


def evaluate_sample(image_path: str, template_json: str, output_debug_img: str):
    with open(template_json, "r") as f:
        tmpl = json.load(f)
    
    raw_img = cv2.imread(image_path)
    if raw_img is None:
        raise FileNotFoundError(f"Could not load {image_path}")
    
    warped = align_sheet_to_template(raw_img, 2478, 3507)
    gray = cv2.cvtColor(warped, cv2.COLOR_BGR2GRAY)
    
    # Sample 6-Digit Code
    detected_digits = []
    code_debug = []
    
    for col in tmpl["code_grid"]["columns"]:
        col_idx = col["col_index"]
        densities = []
        for d in col["digits"]:
            cx, cy = int(d["cx_px"]), int(d["cy_px"])
            r = int(d["radius_px"])
            
            # Mask sample
            mask = np.zeros(gray.shape, dtype=np.uint8)
            cv2.circle(mask, (cx, cy), max(2, r - 3), 255, -1)
            mean_intensity = cv2.mean(gray, mask=mask)[0]
            densities.append((d["digit"], mean_intensity, (cx, cy, r)))
        
        # Invert intensity (lower intensity = darker = filled)
        densities.sort(key=lambda x: x[1])
        darkest_digit = densities[0]
        second_darkest = densities[1]
        
        # Check gap
        gap = second_darkest[1] - darkest_digit[1]
        detected_digits.append(str(darkest_digit[0]))
        code_debug.append({
            "col": col_idx,
            "digit": darkest_digit[0],
            "intensity": darkest_digit[1],
            "gap": gap,
            "coords": darkest_digit[2]
        })
    
    detected_code_str = "".join(detected_digits)
    
    # Sample Questions (1..200)
    detected_answers = {}
    marked_count = 0
    
    for q_str, q_data in tmpl["questions"].items():
        q_num = q_data["question_number"]
        opt_densities = []
        for opt in q_data["options"]:
            cx, cy = int(opt["cx_px"]), int(opt["cy_px"])
            r = int(opt["radius_px"])
            
            mask = np.zeros(gray.shape, dtype=np.uint8)
            cv2.circle(mask, (cx, cy), max(2, r - 3), 255, -1)
            mean_intensity = cv2.mean(gray, mask=mask)[0]
            opt_densities.append((opt["option"], mean_intensity, (cx, cy, r)))
        
        opt_densities.sort(key=lambda x: x[1])
        top_opt = opt_densities[0]
        runner_up = opt_densities[1]
        gap = runner_up[1] - top_opt[1]
        
        # Threshold: if darkest bubble is sufficiently dark (< 140) and has gap > 20
        if top_opt[1] < 155.0 and gap > 18.0:
            detected_answers[q_num] = {
                "option": top_opt[0],
                "intensity": round(top_opt[1], 1),
                "gap": round(gap, 1),
                "confidence": min(1.0, round(gap / 60.0, 2)),
                "coords": top_opt[2]
            }
            marked_count += 1
        else:
            detected_answers[q_num] = {
                "option": None,
                "intensity": round(top_opt[1], 1),
                "gap": round(gap, 1),
                "confidence": 0.0,
                "coords": top_opt[2]
            }
    
    # Draw visual annotations
    annotated = warped.copy()
    # Annotate Code
    for cd in code_debug:
        cx, cy, r = cd["coords"]
        cv2.circle(annotated, (cx, cy), r + 4, (0, 0, 255), 3)
    
    cv2.putText(
        annotated,
        f"Detected Code: {detected_code_str}",
        (400, 320),
        cv2.FONT_HERSHEY_SIMPLEX,
        1.5,
        (0, 0, 255),
        4
    )
    
    # Annotate Questions
    for q_num, ans in detected_answers.items():
        if ans["option"] is not None:
            cx, cy, r = ans["coords"]
            cv2.circle(annotated, (cx, cy), r + 4, (0, 255, 0), 3)
            cv2.putText(
                annotated,
                f"Q{q_num}:{ans['option']}",
                (cx - 15, cy - r - 6),
                cv2.FONT_HERSHEY_SIMPLEX,
                0.45,
                (0, 200, 0),
                2
            )
    
    cv2.imwrite(output_debug_img, annotated)
    
    print(f"\n=======================================================")
    print(f"Results for {os.path.basename(image_path)}:")
    print(f"  -> Detected 6-Digit Student Code: {detected_code_str}")
    print(f"  -> Total Questions Marked: {marked_count} / 200")
    print(f"  -> First 10 Detected Answers: {[(k, v['option']) for k, v in list(detected_answers.items())[:10]]}")
    print(f"  -> Debug image saved: {output_debug_img}")
    print(f"=======================================================")
    
    return detected_code_str, detected_answers

if __name__ == "__main__":
    samples = [
        ("services/omr-engine/assets/samples/sample_1_vedehi_224567.jpg", "224567"),
        ("services/omr-engine/assets/samples/sample_2_amar_342105.jpg", "342105"),
        ("services/omr-engine/assets/samples/sample_3_vaibhav_134768.jpg", "134768")
    ]
    
    for s_path, expected_code in samples:
        code, _ = evaluate_sample(
            s_path,
            "services/omr-engine/assets/vishwas_200q_template.json",
            f"services/omr-engine/assets/samples/debug_{os.path.basename(s_path)}"
        )
        print(f"Expected: {expected_code} | Detected: {code} | Match: {'✅ PASS' if code == expected_code else '❌ FAIL'}")
