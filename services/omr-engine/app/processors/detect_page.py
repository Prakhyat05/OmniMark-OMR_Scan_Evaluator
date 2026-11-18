"""
Document boundary and contour detector for OMR sheets matching OMRChecker CropPage.
"""
import cv2
import numpy as np
from typing import Optional, Tuple, List


def order_points(pts: np.ndarray) -> np.ndarray:
    """Order coordinates clockwise: [Top-Left, Top-Right, Bottom-Right, Bottom-Left]."""
    rect = np.zeros((4, 2), dtype="float32")
    s = pts.sum(axis=1)
    rect[0] = pts[np.argmin(s)]
    rect[2] = pts[np.argmax(s)]

    diff = np.diff(pts, axis=1)
    rect[1] = pts[np.argmin(diff)]
    rect[3] = pts[np.argmax(diff)]
    return rect


def angle(p_1, p_2, p_0):
    dx1 = float(p_1[0] - p_0[0])
    dy1 = float(p_1[1] - p_0[1])
    dx2 = float(p_2[0] - p_0[0])
    dy2 = float(p_2[1] - p_0[1])
    return (dx1 * dx2 + dy1 * dy2) / (np.sqrt((dx1 * dx1 + dy1 * dy1) * (dx2 * dx2 + dy2 * dy2)) + 1e-10)


def check_max_cosine(approx):
    """Assumes 4 points present and checks if quadrilateral is roughly rectangular."""
    max_cosine = 0.0
    for i in range(2, 5):
        cosine = abs(angle(approx[i % 4], approx[i - 2], approx[i - 1]))
        max_cosine = max(cosine, max_cosine)
    return max_cosine < 0.45


def detect_document_corners(gray_image: np.ndarray) -> np.ndarray:
    """
    Industrial-Grade OMR Page Boundary Detector (matching OMRChecker CropPage):
    1. First detects physical A4 paper boundaries on camera capture frames.
    2. Validates quad geometry (aspect ratio, rectangle max cosine).
    3. Validates corner fiducials if physical markers span the outer margins (>70% width/height).
    4. Seamlessly falls back to full image bounds for tight crops / digital scans.
    """
    h, w = gray_image.shape[:2]

    # Strategy 1: OMRChecker CropPage paper contour analysis
    try:
        norm = cv2.normalize(gray_image, None, 0, 255, cv2.NORM_MINMAX)
        blurred = cv2.GaussianBlur(norm, (5, 5), 0)
        _, trunc = cv2.threshold(blurred, 205, 255, cv2.THRESH_TRUNC)
        trunc_norm = cv2.normalize(trunc, None, 0, 255, cv2.NORM_MINMAX)

        kernel = cv2.getStructuringElement(cv2.MORPH_RECT, (10, 10))
        closed = cv2.morphologyEx(trunc_norm, cv2.MORPH_CLOSE, kernel)
        edge = cv2.Canny(closed, 35, 140)

        contours, _ = cv2.findContours(edge, cv2.RETR_LIST, cv2.CHAIN_APPROX_SIMPLE)
        if contours:
            hull_cnts = [cv2.convexHull(c) for c in contours]
            hull_cnts = sorted(hull_cnts, key=cv2.contourArea, reverse=True)[:6]

            min_page_area = (w * h) * 0.30
            for c in hull_cnts:
                area = cv2.contourArea(c)
                if area < min_page_area:
                    continue

                peri = cv2.arcLength(c, True)
                approx = cv2.approxPolyDP(c, 0.03 * peri, True)

                if len(approx) == 4:
                    pts = approx.reshape(4, 2)
                    if check_max_cosine(pts):
                        ordered = order_points(pts)
                        ch_w = np.linalg.norm(ordered[1] - ordered[0])
                        ch_h = np.linalg.norm(ordered[3] - ordered[0])
                        aspect = ch_h / ch_w if ch_w > 0 else 0
                        # Check valid portrait/landscape sheet aspect ratio
                        if ch_w > 100 and ch_h > 100 and (0.50 <= aspect <= 2.2):
                            # If contour fills > 92% of image, it's already a full scan crop
                            if area > (w * h) * 0.92:
                                break
                            return ordered
    except Exception:
        pass

    # Strategy 2: 4 Outer Corner Fiducial Markers (strictly validated)
    fiducials = detect_fiducial_markers(gray_image)
    if fiducials is not None and len(fiducials) == 4:
        return order_points(fiducials)

    # Strategy 3: Full Image Boundary Fallback (for direct scan/upload)
    return np.array([
        [0.0, 0.0],
        [float(w - 1), 0.0],
        [float(w - 1), float(h - 1)],
        [0.0, float(h - 1)]
    ], dtype="float32")


def detect_fiducial_markers(gray_image: np.ndarray) -> Optional[np.ndarray]:
    """Find 4 corner registration markers near the outer quadrants with strict geometric validation."""
    h, w = gray_image.shape[:2]
    _, thresh = cv2.threshold(gray_image, 0, 255, cv2.THRESH_BINARY_INV | cv2.THRESH_OTSU)
    contours, _ = cv2.findContours(thresh, cv2.RETR_TREE, cv2.CHAIN_APPROX_SIMPLE)

    candidates = []
    min_area = (w * h) * 0.0001
    max_area = (w * h) * 0.03

    for cnt in contours:
        area = cv2.contourArea(cnt)
        if min_area < area < max_area:
            peri = cv2.arcLength(cnt, True)
            approx = cv2.approxPolyDP(cnt, 0.04 * peri, True)
            if len(approx) == 4:
                x, y, cw, ch = cv2.boundingRect(approx)
                aspect_ratio = float(cw) / float(ch) if ch > 0 else 0
                if 0.70 <= aspect_ratio <= 1.30:
                    M = cv2.moments(cnt)
                    if M["m00"] != 0:
                        cX = float(M["m10"] / M["m00"])
                        cY = float(M["m01"] / M["m00"])
                        candidates.append((cX, cY))

    if len(candidates) < 4:
        return None

    mid_x, mid_y = w / 2.0, h / 2.0
    tl = [c for c in candidates if c[0] < mid_x * 0.7 and c[1] < mid_y * 0.7]
    tr = [c for c in candidates if c[0] >= mid_x * 1.3 and c[1] < mid_y * 0.7]
    br = [c for c in candidates if c[0] >= mid_x * 1.3 and c[1] >= mid_y * 1.3]
    bl = [c for c in candidates if c[0] < mid_x * 0.7 and c[1] >= mid_y * 1.3]

    if tl and tr and br and bl:
        pts = np.array([
            min(tl, key=lambda p: p[0] + p[1]),
            max(tr, key=lambda p: p[0] - p[1]),
            max(br, key=lambda p: p[0] + p[1]),
            min(bl, key=lambda p: p[0] - p[1]),
        ], dtype="float32")

        # Verify markers span at least 70% of width and 70% of height
        xs = [p[0] for p in pts]
        ys = [p[1] for p in pts]
        span_x = (max(xs) - min(xs)) / float(w)
        span_y = (max(ys) - min(ys)) / float(h)
        if span_x >= 0.70 and span_y >= 0.70:
            return pts

    return None
