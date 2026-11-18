"""
Student Roll Code / QR / Barcode / Bubble Grid identification processor based on OMRChecker:
- Reads Roll Number integer columns (digits 0 to 9) using FieldBlock geometry and statistical thresholding
- Fast QR code & Barcode decoding
- Student roster matching
"""
import re
import cv2
import numpy as np
from typing import Dict, Any, Optional, Tuple, List

from app.core.template_model import Template, FieldBlock
from app.processors.detect_bubbles import sample_bubble_intensity, get_global_threshold, get_local_threshold


def detect_student_code(
    aligned_image: np.ndarray,
    template_config: Optional[Dict[str, Any]] = None,
) -> Optional[str]:
    """
    Extract and decode the student roll number or ID directly from the OMR sheet.
    Strategy 1: QR Code Detector.
    Strategy 2: 1D Barcode Detector.
    Strategy 3: Template-driven Roll Number Bubble Grid Matrix (vertical columns of digits 0-9).
    Returns the decoded string or None if no identity was marked.
    """
    if template_config is None:
        template_config = {}

    if len(aligned_image.shape) == 3:
        gray = cv2.cvtColor(aligned_image, cv2.COLOR_BGR2GRAY)
    else:
        gray = aligned_image.copy()

    # Strategy 1: QR Code Detector
    try:
        qr_detector = cv2.QRCodeDetector()
        data, bbox, _ = qr_detector.detectAndDecode(gray)
        if data and data.strip():
            return data.strip()
    except Exception:
        pass

    # Strategy 2: 1D Barcode Detector (if OpenCV barcode module available)
    try:
        if hasattr(cv2, "barcode") and hasattr(cv2.barcode, "BarcodeDetector"):
            barcode_detector = cv2.barcode.BarcodeDetector()
            decoded_info, decoded_type, corners = barcode_detector.detectAndDecode(gray)
            if isinstance(decoded_info, (list, tuple)) and decoded_info:
                val = decoded_info[0].strip()
                if val:
                    return val
            elif isinstance(decoded_info, str) and decoded_info.strip():
                return decoded_info.strip()
    except Exception:
        pass

    # Strategy 3: Roll Number / Student ID Bubble Grid
    roll_code = decode_roll_number_grid(gray, template_config)
    if roll_code:
        return roll_code

    return None


def decode_roll_number_grid(
    gray_image: np.ndarray,
    template_config: Dict[str, Any],
) -> Optional[str]:
    """
    Decode vertical columns of digits 0-9 in the Roll Number / Student ID section.
    Uses Template FieldBlocks if available, or identityRegion geometry.
    """
    h, w = gray_image.shape[:2]

    # Check if template has a FieldBlock with 'roll' or 'id'
    if "fieldBlocks" in template_config:
        tmpl = Template(template_config)
        roll_blocks = [fb for fb in tmpl.field_blocks if "roll" in fb.name.lower() or "id" in fb.name.lower()]
        if roll_blocks:
            return _decode_roll_from_field_blocks(gray_image, roll_blocks)

    # Fallback to identityRegion geometry
    id_config = template_config.get("identityRegion", {})
    start_x = id_config.get("startX", 1550)
    start_y = id_config.get("startY", 260)
    digits_count = id_config.get("digits", 6)
    col_spacing = id_config.get("colSpacing", 80)
    row_spacing = id_config.get("rowSpacing", 48)
    bubble_r = id_config.get("bubbleRadius", 16)

    if start_x + (digits_count * col_spacing) > w or start_y + (10 * row_spacing) > h:
        start_x = 240
        start_y = 280

    all_col_vals = []
    col_samples = []

    for col in range(digits_count):
        col_x = start_x + (col * col_spacing)
        digit_vals = []
        for digit in range(10):
            digit_y = start_y + (digit * row_spacing)
            val = sample_bubble_intensity(gray_image, col_x, digit_y, bubble_r)
            digit_vals.append(val)
            all_col_vals.append(val)
        col_samples.append(digit_vals)

    if not all_col_vals:
        return None

    global_thr = get_global_threshold(all_col_vals)
    decoded_digits = []
    has_any_mark = False

    for col_idx, vals in enumerate(col_samples):
        col_std = float(np.std(vals))
        col_min = float(np.min(vals))
        sorted_vals = sorted(vals)
        local_gap = sorted_vals[1] - sorted_vals[0]

        # Check if a digit is filled
        if col_std >= 14.0 and local_gap >= 20.0 and col_min < global_thr:
            best_digit = int(np.argmin(vals))
            decoded_digits.append(str(best_digit))
            has_any_mark = True
        else:
            decoded_digits.append("")

    if has_any_mark:
        result_str = "".join(decoded_digits).strip()
        if result_str:
            return result_str

    return None


def _decode_roll_from_field_blocks(
    gray_image: np.ndarray,
    roll_blocks: List[FieldBlock],
) -> Optional[str]:
    """Decodes roll number from OMRChecker FieldBlock objects."""
    all_vals = []
    column_strips = []

    for fb in roll_blocks:
        box_w, box_h = fb.bubble_dimensions
        r = min(box_w, box_h) // 2
        for strip in fb.traverse_bubbles:
            strip_vals = []
            for b in strip:
                cx = b.x + fb.shift + b.w // 2
                cy = b.y + b.h // 2
                val = sample_bubble_intensity(gray_image, cx, cy, r)
                strip_vals.append((b.field_value, val))
                all_vals.append(val)
            column_strips.append(strip_vals)

    if not all_vals:
        return None

    global_thr = get_global_threshold(all_vals)
    decoded = []
    has_mark = False

    for strip in column_strips:
        raw_vals = [v for _, v in strip]
        col_std = float(np.std(raw_vals))
        col_min = float(np.min(raw_vals))
        sorted_vals = sorted(raw_vals)
        local_gap = sorted_vals[1] - sorted_vals[0] if len(sorted_vals) > 1 else 0.0

        if col_std >= 14.0 and local_gap >= 20.0 and col_min < global_thr:
            best_idx = int(np.argmin(raw_vals))
            best_val = strip[best_idx][0]
            decoded.append(best_val)
            has_mark = True
        else:
            decoded.append("")

    if has_mark:
        res = "".join(decoded).strip()
        if res:
            return res

    return None


def match_student_roster(
    detected_code: Optional[str],
    student_roster: List[Dict[str, Any]],
) -> Optional[Dict[str, Any]]:
    """Match detected roll code string against student roster records."""
    if not detected_code or not student_roster:
        return None

    code_clean = detected_code.strip().lower()
    code_digits_only = re.sub(r"\D", "", code_clean)

    # 1. Exact match on code, roll, id
    for s in student_roster:
        s_code = str(s.get("code", "")).strip().lower()
        s_roll = str(s.get("roll", "")).strip().lower()
        s_id = str(s.get("id", "")).strip().lower()
        if code_clean in [s_code, s_roll, s_id]:
            return s

    # 2. Match on numeric suffixes (e.g. STU1002 matches 102 or 1002)
    if code_digits_only:
        for s in student_roster:
            s_code = re.sub(r"\D", "", str(s.get("code", "")))
            s_roll = re.sub(r"\D", "", str(s.get("roll", "")))
            if code_digits_only == s_roll or code_digits_only == s_code:
                return s
            if s_roll and s_roll.endswith(code_digits_only):
                return s
            if code_digits_only.endswith(s_roll) and len(s_roll) >= 2:
                return s

    return None
