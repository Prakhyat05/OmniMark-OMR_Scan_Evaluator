"""
Industrial-Grade OMR Bubble Detection & Evaluation Engine based on OMRChecker Architecture:
- Two-Tier Statistical Intensity Thresholding ('First Large Gap' global + Local Std-Dev)
- Subpixel Circular Mask Sample Extraction
- Deterministic Question Numbering & Option Mapping
- High-Precision Unanswered Suppression & Multi-Mark Flagging
- Visual Annotated Overlay Generation (Green/Red/Orange bounding boxes & labels)
"""
import re
import cv2
import numpy as np
from typing import Dict, Any, List, Tuple, Optional, Set

from app.core.template_model import Template, FieldBlock, Bubble
from app.core.builtins_templates import get_template_by_id_or_questions
from app.processors.align import align_column_shifts


def get_global_threshold(
    q_vals_orig: List[float],
    looseness: int = 1,
    min_jump: float = 25.0,
    default_thr: float = 140.0,
) -> float:
    """
    OMRChecker 'First Large Gap' Global Thresholding Algorithm:
    Sorts all bubble mean intensities on the entire sheet and finds the maximum
    intensity jump that cleanly separates dark filled bubbles from white paper.
    """
    if not q_vals_orig:
        return default_thr

    q_vals = sorted(q_vals_orig)
    ls = max(1, (looseness + 1) // 2)
    l = len(q_vals) - ls

    max_jump = min_jump
    thr = default_thr

    for i in range(ls, l):
        jump = q_vals[i + ls] - q_vals[i - ls]
        if jump > max_jump:
            max_jump = jump
            thr = float(q_vals[i - ls] + jump / 2.0)

    return float(thr)


def get_local_threshold(
    q_strip_vals: List[float],
    global_thr: float,
    global_std_thresh: float,
) -> float:
    """
    OMRChecker Local Question-Row Thresholding Algorithm:
    Uses standard deviation to check if any bubble in the row is filled.
    If all bubbles are blank paper (low std-dev), enforces global threshold to prevent false marks.
    """
    row_std = float(np.std(q_strip_vals))
    row_min = float(np.min(q_strip_vals))
    row_max = float(np.max(q_strip_vals))

    # All White or All Gray case (no marked bubble in this question row)
    if row_std < global_std_thresh or (row_max - row_min) < 30.0:
        return min(global_thr, row_min - 10.0)

    # Question row has a filled bubble -> Set local threshold between min and second-lowest
    sorted_row = sorted(q_strip_vals)
    local_gap = sorted_row[1] - sorted_row[0]
    if local_gap >= 25.0:
        return float(sorted_row[0] + local_gap / 2.0)

    return global_thr


def sample_bubble_intensity(gray_image: np.ndarray, cx: int, cy: int, radius: int) -> float:
    """
    Extracts mean intensity within the circular mask of a bubble.
    Avoids square bounding box corners and printed outer boundaries.
    """
    h, w = gray_image.shape[:2]
    inner_r = max(3, radius - 2)

    y1 = max(0, cy - inner_r)
    y2 = min(h, cy + inner_r + 1)
    x1 = max(0, cx - inner_r)
    x2 = min(w, cx + inner_r + 1)

    roi = gray_image[y1:y2, x1:x2]
    if roi.size == 0:
        return 255.0

    mask = np.zeros(roi.shape, dtype=np.uint8)
    center = (roi.shape[1] // 2, roi.shape[0] // 2)
    cv2.circle(mask, center, inner_r, 255, -1)

    mean_val = cv2.mean(roi, mask=mask)[0]
    return float(mean_val)


def evaluate_bubbles(
    aligned_image: np.ndarray,
    template_config: Optional[Dict[str, Any]] = None,
    total_questions: Optional[int] = None,
) -> List[Dict[str, Any]]:
    """
    OMRChecker Deterministic Bubble Evaluation Pipeline.
    Supports Template object models, custom learned question_bubble_maps, and built-in templates.
    """
    if template_config is None:
        template_config = {}

    if len(aligned_image.shape) == 3:
        gray = cv2.cvtColor(aligned_image, cv2.COLOR_BGR2GRAY)
    else:
        gray = aligned_image.copy()

    h, w = gray.shape[:2]
    target_questions = total_questions or template_config.get("total_questions", 100)

    # 1. Check if template_config has standard OMRChecker fieldBlocks
    if "fieldBlocks" in template_config:
        tmpl = Template(template_config)
        return _evaluate_with_template_model(gray, tmpl, target_questions)

    # 2. Check if a custom question_bubble_map exists
    custom_map = template_config.get("question_bubble_map")
    if custom_map and isinstance(custom_map, list) and len(custom_map) > 0:
        return _evaluate_with_bubble_map(gray, custom_map)

    # 3. Fallback to built-in template
    template_id = template_config.get("template_id")
    builtin_dict = get_template_by_id_or_questions(template_id, target_questions)
    tmpl = Template(builtin_dict)
    return _evaluate_with_template_model(gray, tmpl, target_questions)


def _evaluate_with_template_model(
    gray: np.ndarray,
    template: Template,
    target_questions: int,
) -> List[Dict[str, Any]]:
    """Evaluate bubbles using standard OMRChecker Template and FieldBlocks."""
    # Step: Morphological column shift alignment (matching OMRChecker auto_align)
    vert_blocks = [fb for fb in template.field_blocks if fb.direction == "vertical"]
    if vert_blocks:
        try:
            col_x_list = [fb.origin[0] for fb in vert_blocks]
            first_fb = vert_blocks[0]
            shifts = align_column_shifts(
                gray,
                col_x_list,
                start_y=first_fb.origin[1],
                height=first_fb.dimensions[1],
                col_width=first_fb.dimensions[0],
                max_shift=15,
            )
            for idx, fb in enumerate(vert_blocks):
                if idx < len(shifts):
                    fb.shift = shifts[idx]
        except Exception:
            pass

    all_q_vals = []
    question_strips_data = []

    q_idx = 1
    for fb in template.field_blocks:
        if "roll" in fb.name.lower() or "id" in fb.name.lower():
            continue

        box_w, box_h = fb.bubble_dimensions
        r = min(box_w, box_h) // 2

        for strip in fb.traverse_bubbles:
            if q_idx > target_questions:
                break

            strip_vals = []
            strip_options = []

            for b in strip:
                cx = b.x + fb.shift + b.w // 2
                cy = b.y + b.h // 2
                val = sample_bubble_intensity(gray, cx, cy, r)
                strip_vals.append(val)
                all_q_vals.append(val)
                strip_options.append({
                    "option": b.field_value,
                    "intensity": val,
                    "center": {"x": cx, "y": cy, "r": r},
                    "field_label": b.field_label,
                })

            first_label = strip[0].field_label
            match_num = re.search(r"\d+", first_label)
            question_num = int(match_num.group(0)) if match_num else q_idx

            question_strips_data.append({
                "question_number": question_num,
                "field_label": first_label,
                "options": strip_options,
                "vals": strip_vals,
            })
            q_idx += 1

    question_strips_data.sort(key=lambda item: item["question_number"])

    global_thr = get_global_threshold(all_q_vals)
    all_stds = [float(np.std(item["vals"])) for item in question_strips_data]
    global_std_thresh = float(np.median(all_stds)) if all_stds else 15.0
    global_std_thresh = max(12.0, min(25.0, global_std_thresh))

    results = []
    for item in question_strips_data:
        q_num = item["question_number"]
        row_vals = item["vals"]
        local_thr = get_local_threshold(row_vals, global_thr, global_std_thresh)

        option_scores = []
        for opt in item["options"]:
            intensity = opt["intensity"]
            fill_darkness = round(max(0.0, min(1.0, (255.0 - intensity) / 255.0)), 4)
            is_marked = intensity < local_thr

            option_scores.append({
                "option": opt["option"],
                "intensity": intensity,
                "fill_ratio": fill_darkness,
                "is_marked": is_marked,
                "center": opt["center"],
            })

        first_center = item["options"][0]["center"] if item["options"] else {"x": 0, "y": 0}
        results.append(_score_omrchecker_row(
            q_num, option_scores, local_thr, first_center["x"], first_center["y"]
        ))

    return results


def _evaluate_with_bubble_map(
    gray: np.ndarray,
    question_map: List[Dict[str, Any]],
) -> List[Dict[str, Any]]:
    """Evaluate bubbles from explicit question_bubble_map structure."""
    all_q_vals = []
    q_strip_arrs = []

    for q_item in question_map:
        raw_options = q_item.get("options", [])
        row_vals = []
        for opt in raw_options:
            bx = opt.get("x", 0)
            by = opt.get("y", 0)
            r = opt.get("r", 10)
            val = sample_bubble_intensity(gray, bx, by, r)
            row_vals.append(val)
            all_q_vals.append(val)
        q_strip_arrs.append(row_vals)

    global_thr = get_global_threshold(all_q_vals)
    all_stds = [float(np.std(r)) for r in q_strip_arrs]
    global_std_thresh = float(np.median(all_stds)) if all_stds else 15.0
    global_std_thresh = max(12.0, min(25.0, global_std_thresh))

    results = []
    for idx, q_item in enumerate(question_map):
        q_num = q_item.get("question_number", idx + 1)
        raw_options = q_item.get("options", [])
        row_vals = q_strip_arrs[idx]

        local_thr = get_local_threshold(row_vals, global_thr, global_std_thresh)
        option_scores = []

        for o_idx, opt in enumerate(raw_options):
            opt_char = opt.get("option", chr(ord("A") + o_idx))
            bx = opt.get("x", 0)
            by = opt.get("y", 0)
            r = opt.get("r", 10)
            intensity = row_vals[o_idx]
            fill_darkness = round(max(0.0, min(1.0, (255.0 - intensity) / 255.0)), 4)
            is_marked = intensity < local_thr

            option_scores.append({
                "option": opt_char,
                "intensity": intensity,
                "fill_ratio": fill_darkness,
                "is_marked": is_marked,
                "center": {"x": int(bx), "y": int(by), "r": int(r)},
            })

        first_cx = raw_options[0].get("x", 0) if raw_options else 0
        first_cy = raw_options[0].get("y", 0) if raw_options else 0
        results.append(_score_omrchecker_row(q_num, option_scores, local_thr, first_cx, first_cy))

    return results


def _score_omrchecker_row(
    q_num: int,
    option_scores: List[Dict[str, Any]],
    local_thr: float,
    col_x: int = 0,
    row_y: int = 0,
) -> Dict[str, Any]:
    """
    OMRChecker Row Decision Scorer.
    Determines single answer, multiple marks, unattempted, and confidence score.
    """
    marked_options = [o for o in option_scores if o["is_marked"]]

    is_multiple = len(marked_options) > 1
    is_uncertain = False
    detected_option = None

    if len(marked_options) == 1:
        detected_option = marked_options[0]["option"]
        delta = local_thr - marked_options[0]["intensity"]
        confidence = round(min(1.0, 0.85 + (delta / 100.0) * 0.15), 3)
    elif is_multiple:
        detected_option = None
        confidence = 0.35
        is_uncertain = True
    else:
        # Unanswered question
        detected_option = None
        confidence = 1.0

    return {
        "question_number": q_num,
        "detected_option": detected_option,
        "is_multiple": is_multiple,
        "is_uncertain": is_uncertain,
        "confidence": confidence,
        "options_breakdown": option_scores,
        "roi_center": {"x": int(col_x), "y": int(row_y)},
    }


def generate_annotated_omr_image(
    aligned_image: np.ndarray,
    detected_answers: List[Dict[str, Any]],
    answer_key: Optional[Dict[int, List[str]]] = None,
) -> np.ndarray:
    """
    OMRChecker-Style 'final_marked' Overlay:
    Draws translucent bounding rectangles, clean status colors, and option labels.
    - Green = Correct
    - Red = Incorrect
    - Orange = Multiple Marks
    """
    if len(aligned_image.shape) == 2:
        annotated = cv2.cvtColor(aligned_image, cv2.COLOR_GRAY2BGR)
    else:
        annotated = aligned_image.copy()

    overlay = annotated.copy()

    for item in detected_answers:
        q_num = item.get("question_number", 0)
        detected_opt = item.get("detected_option")
        is_multiple = item.get("is_multiple", False)
        correct_opts = answer_key.get(q_num, []) if answer_key else []

        for opt_data in item.get("options_breakdown", []):
            opt_char = opt_data.get("option")
            is_marked = opt_data.get("is_marked", False)
            center = opt_data.get("center", {})
            cx = center.get("x", 0)
            cy = center.get("y", 0)
            cr = center.get("r", 10)

            if not cx or not cy:
                continue

            x1, y1 = cx - cr - 2, cy - cr - 2
            x2, y2 = cx + cr + 2, cy + cr + 2

            if is_multiple and is_marked:
                cv2.rectangle(overlay, (x1, y1), (x2, y2), (0, 165, 255), -1)
                cv2.rectangle(annotated, (x1, y1), (x2, y2), (0, 140, 255), 2)
            elif opt_char == detected_opt:
                if correct_opts:
                    if opt_char in correct_opts:
                        cv2.rectangle(overlay, (x1, y1), (x2, y2), (0, 200, 0), -1)
                        cv2.rectangle(annotated, (x1, y1), (x2, y2), (0, 180, 0), 2)
                    else:
                        cv2.rectangle(overlay, (x1, y1), (x2, y2), (0, 0, 255), -1)
                        cv2.rectangle(annotated, (x1, y1), (x2, y2), (0, 0, 220), 2)
                else:
                    cv2.rectangle(overlay, (x1, y1), (x2, y2), (0, 200, 0), -1)
                    cv2.rectangle(annotated, (x1, y1), (x2, y2), (0, 180, 0), 2)

    cv2.addWeighted(overlay, 0.45, annotated, 0.55, 0, annotated)
    return annotated
