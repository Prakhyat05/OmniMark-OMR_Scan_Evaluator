"""
Perspective alignment and homography transformation module based on OMRChecker:
- Four-point perspective warp
- CropOnMarkers 4-quadrant multi-scale template matching
- Vertical morphological column shift alignment
"""
import cv2
import numpy as np
from typing import Optional, List, Tuple, Dict, Any
from app.processors.detect_page import order_points


def four_point_transform(image: np.ndarray, pts: np.ndarray, target_w: int, target_h: int) -> np.ndarray:
    """Warp quadrilateral region into canonical rectangle (target_w, target_h)."""
    rect = order_points(pts.astype("float32"))
    dst = np.array([
        [0.0, 0.0],
        [float(target_w - 1), 0.0],
        [float(target_w - 1), float(target_h - 1)],
        [0.0, float(target_h - 1)]
    ], dtype="float32")

    matrix = cv2.getPerspectiveTransform(rect, dst)
    warped = cv2.warpPerspective(image, matrix, (target_w, target_h), flags=cv2.INTER_CUBIC)
    return warped


def align_to_template(
    image: np.ndarray,
    corners: np.ndarray,
    target_w: int = 2480,
    target_h: int = 3508,
) -> np.ndarray:
    """Warp input perspective into canonical template dimensions with fiducial anchoring."""
    ordered = order_points(corners.astype("float32"))
    h, w = image.shape[:2]

    # Check if corners are fiducials (inset from image margins)
    is_fiducial = (
        ordered[0][0] > 0.02 * w and ordered[0][1] > 0.02 * h and
        ordered[1][0] < 0.98 * w and ordered[1][1] > 0.02 * h and
        ordered[2][0] < 0.98 * w and ordered[2][1] < 0.98 * h and
        ordered[3][0] > 0.02 * w and ordered[3][1] < 0.98 * h
    )

    if is_fiducial:
        # Standard fiducial centers in canonical space
        dst = np.array([
            [150.0, 150.0],
            [float(target_w - 150), 150.0],
            [float(target_w - 150), float(target_h - 150)],
            [150.0, float(target_h - 150)]
        ], dtype="float32")
    else:
        dst = np.array([
            [0.0, 0.0],
            [float(target_w - 1), 0.0],
            [float(target_w - 1), float(target_h - 1)],
            [0.0, float(target_h - 1)]
        ], dtype="float32")

    matrix = cv2.getPerspectiveTransform(ordered, dst)
    warped = cv2.warpPerspective(image, matrix, (target_w, target_h), flags=cv2.INTER_CUBIC)
    return warped


def crop_on_markers(
    image: np.ndarray,
    marker_img: np.ndarray,
    target_w: int = 2480,
    target_h: int = 3508,
    min_matching_threshold: float = 0.30,
    max_matching_variation: float = 0.45,
    rescale_range: Tuple[int, int] = (35, 100),
    rescale_steps: int = 10,
) -> Optional[np.ndarray]:
    """
    OMRChecker CropOnMarkers Algorithm:
    Splits image into 4 quadrants (TL, TR, BL, BR), performs multi-scale template matching
    against marker_img, locates marker centers in each quadrant, and warps with four-point transform.
    """
    if len(image.shape) == 3:
        gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    else:
        gray = image.copy()

    norm = cv2.normalize(gray, None, 0, 255, cv2.NORM_MINMAX)
    h, w = norm.shape[:2]
    mid_h, mid_w = h // 2, w // 2

    quads = {
        0: norm[0:mid_h, 0:mid_w],
        1: norm[0:mid_h, mid_w:w],
        2: norm[mid_h:h, 0:mid_w],
        3: norm[mid_h:h, mid_w:w],
    }
    origins = [[0, 0], [mid_w, 0], [0, mid_h], [mid_w, mid_h]]

    mh, mw = marker_img.shape[:2]
    descent_step = max(1, (rescale_range[1] - rescale_range[0]) // rescale_steps)

    best_scale = None
    all_max_t = 0.0

    for r in range(rescale_range[1], rescale_range[0] - 1, -descent_step):
        s = float(r / 100.0)
        cur_h = int(mh * s)
        if cur_h <= 5:
            continue
        cur_marker = cv2.resize(marker_img, (int(mw * s), cur_h), interpolation=cv2.INTER_AREA)
        res = cv2.matchTemplate(norm, cur_marker, cv2.TM_CCOEFF_NORMED)
        max_t = float(res.max())
        if max_t > all_max_t:
            all_max_t = max_t
            best_scale = s

    if best_scale is None or all_max_t < min_matching_threshold:
        return None

    opt_marker = cv2.resize(marker_img, (int(mw * best_scale), int(mh * best_scale)), interpolation=cv2.INTER_AREA)
    opt_h, opt_w = opt_marker.shape[:2]

    centres = []
    for k in range(4):
        res = cv2.matchTemplate(quads[k], opt_marker, cv2.TM_CCOEFF_NORMED)
        max_t = float(res.max())
        if max_t < min_matching_threshold or abs(all_max_t - max_t) >= max_matching_variation:
            return None
        loc = np.argwhere(res == max_t)[0]
        pt = [loc[1] + origins[k][0], loc[0] + origins[k][1]]
        centres.append([pt[0] + opt_w / 2.0, pt[1] + opt_h / 2.0])

    return four_point_transform(image, np.array(centres, dtype="float32"), target_w, target_h)


def align_column_shifts(
    gray_image: np.ndarray,
    col_x_list: List[int],
    start_y: int,
    height: int,
    col_width: int,
    max_shift: int = 20,
) -> List[int]:
    """
    OMRChecker Morphological Column Alignment:
    Uses a vertical morphological structuring element (2, 10) to detect vertical column
    dividers and compute exact horizontal shifts per column strip.
    """
    h, w = gray_image.shape[:2]
    shifts = [0] * len(col_x_list)

    try:
        v_kernel = cv2.getStructuringElement(cv2.MORPH_RECT, (2, 10))
        morph_v = cv2.morphologyEx(gray_image, cv2.MORPH_OPEN, v_kernel, iterations=2)
        _, morph_v = cv2.threshold(morph_v, 200, 200, cv2.THRESH_TRUNC)
        morph_v = cv2.normalize(morph_v, None, 0, 255, cv2.NORM_MINMAX)
        morph_v = 255 - morph_v

        _, morph_v = cv2.threshold(morph_v, 60, 255, cv2.THRESH_BINARY)
        morph_v = cv2.erode(morph_v, np.ones((3, 3), np.uint8), iterations=1)

        for idx, cx in enumerate(col_x_list):
            best_shift = 0
            max_left_density = 0.0

            y1 = max(0, start_y)
            y2 = min(h, start_y + height)

            for s in range(-max_shift, max_shift + 1, 2):
                x_check = cx + s
                if 0 <= x_check < w:
                    strip = morph_v[y1:y2, max(0, x_check - 3) : min(w, x_check + 4)]
                    density = float(np.mean(strip)) if strip.size > 0 else 0.0
                    if density > max_left_density:
                        max_left_density = density
                        best_shift = s

            shifts[idx] = best_shift
    except Exception:
        pass

    return shifts
