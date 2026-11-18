"""
Metadata and handwritten field analysis processor for OMR sheets:
- Detects whether metadata fields (School Code No, Name, Class, Date, Exam No) are vacant or filled in
- Computes ink stroke density and handwriting presence
"""
import cv2
import numpy as np
from typing import Dict, Any, Optional, Tuple, List


def detect_metadata_fields(
    aligned_image: np.ndarray,
    template_config: Optional[Dict[str, Any]] = None,
) -> Dict[str, Any]:
    """
    Analyzes the handwritten/printed metadata fields in the lower section of the OMR sheet.
    Returns vacant/filled status for:
    - school_code
    - student_name
    - class_name
    - date
    - exam_no
    """
    if template_config is None:
        template_config = {}

    if len(aligned_image.shape) == 3:
        gray = cv2.cvtColor(aligned_image, cv2.COLOR_BGR2GRAY)
    else:
        gray = aligned_image.copy()

    h, w = gray.shape[:2]

    # Canonical coordinate definitions relative to canonical sheet dimensions (2480 x 3508)
    # Relative ratio boxes: (x_ratio, y_ratio, w_ratio, h_ratio)
    field_regions = {
        "roll_boxes": {
            "label": "Roll Number (Boxes)",
            "rect": (410 / 2480.0, 230 / 3508.0, 330 / 2480.0, 70 / 3508.0),
        },
        "school_code": {
            "label": "School Code No",
            "rect": (750 / 2480.0, 2475 / 3508.0, 420 / 2480.0, 70 / 3508.0),
        },
        "student_name": {
            "label": "Student Name",
            "rect": (1450 / 2480.0, 2475 / 3508.0, 850 / 2480.0, 70 / 3508.0),
        },
        "class_name": {
            "label": "Class",
            "rect": (480 / 2480.0, 2565 / 3508.0, 650 / 2480.0, 70 / 3508.0),
        },
        "date": {
            "label": "Date",
            "rect": (1420 / 2480.0, 2565 / 3508.0, 450 / 2480.0, 70 / 3508.0),
        },
        "exam_no": {
            "label": "Exam No.",
            "rect": (2150 / 2480.0, 2565 / 3508.0, 290 / 2480.0, 70 / 3508.0),
        },
        "maths_marks": {
            "label": "Maths Marks",
            "rect": (840 / 2480.0, 2890 / 3508.0, 280 / 2480.0, 65 / 3508.0),
        },
        "physics_marks": {
            "label": "Physics Marks",
            "rect": (1400 / 2480.0, 2890 / 3508.0, 280 / 2480.0, 65 / 3508.0),
        },
        "chemistry_marks": {
            "label": "Chemistry Marks",
            "rect": (2000 / 2480.0, 2890 / 3508.0, 240 / 2480.0, 65 / 3508.0),
        },
        "total_marks": {
            "label": "Total Marks",
            "rect": (2320 / 2480.0, 2890 / 3508.0, 140 / 2480.0, 65 / 3508.0),
        },
        "rank": {
            "label": "Rank",
            "rect": (420 / 2480.0, 2980 / 3508.0, 450 / 2480.0, 65 / 3508.0),
        },
    }

    # Override with custom regions if specified in template_config
    if "metadataRegions" in template_config:
        for k, v in template_config["metadataRegions"].items():
            if k in field_regions:
                field_regions[k]["rect"] = v

    results: Dict[str, Any] = {}
    vacant_list: List[str] = []
    filled_list: List[str] = []

    for key, info in field_regions.items():
        rx, ry, rw, rh = info["rect"]
        x1 = int(rx * w)
        y1 = int(ry * h)
        x2 = min(w, int((rx + rw) * w))
        y2 = min(h, int((ry + rh) * h))

        roi = gray[y1:y2, x1:x2]
        if roi.size == 0:
            results[key] = {
                "label": info["label"],
                "is_vacant": True,
                "confidence": 1.0,
                "dark_ratio": 0.0,
            }
            vacant_list.append(info["label"])
            continue

        # Adaptive thresholding to identify pencil/pen strokes
        blur = cv2.GaussianBlur(roi, (3, 3), 0)
        _, dark_mask = cv2.threshold(blur, 175, 255, cv2.THRESH_BINARY_INV)

        dark_pixels = np.sum(dark_mask > 0)
        total_pixels = roi.size
        dark_ratio = float(dark_pixels) / float(total_pixels)

        # Field is vacant if dark stroke ratio is less than 3.5%
        is_vacant = bool(dark_ratio < 0.035)

        if is_vacant:
            vacant_list.append(info["label"])
        else:
            filled_list.append(info["label"])

        results[key] = {
            "label": info["label"],
            "is_vacant": is_vacant,
            "has_handwriting": not is_vacant,
            "dark_ratio": round(dark_ratio, 4),
            "roi_box": {"x": x1, "y": y1, "w": x2 - x1, "h": y2 - y1},
        }

    return {
        "fields": results,
        "vacant_fields": vacant_list,
        "filled_fields": filled_list,
        "vacant_count": len(vacant_list),
        "all_fields_completed": len(vacant_list) == 0,
    }
