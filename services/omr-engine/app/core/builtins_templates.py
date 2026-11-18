"""
Pre-calibrated built-in standard OMR templates conforming to OMRChecker JSON format:
1. standard-20-q-v1 (20 Questions, 4 options A-D, Roll No block)
2. standard-50-q-v1 (50 Questions, 2 columns of 25, 4 options A-D, Roll No block)
3. standard-100-q-v1 (100 Questions, 4 columns of 25, 4 options A-D, Roll No block)
4. neet-180-q-v1 (180 Questions, 4 columns of 45, Physics/Chemistry/Biology sections, Roll No block)
5. neet-200-q-v1 (200 Questions, 4 columns of 50, Section A + B options, Roll No block)
"""
from typing import Dict, Any, Optional

STANDARD_20_Q_TEMPLATE: Dict[str, Any] = {
    "template_id": "standard-20-q-v1",
    "name": "Standard 20 Questions Assessment",
    "pageDimensions": [2480, 3508],
    "bubbleDimensions": [38, 38],
    "customLabels": {
        "Roll": ["roll1..6"]
    },
    "fieldBlocks": {
        "Roll": {
            "fieldType": "QTYPE_INT",
            "fieldLabels": ["roll1..6"],
            "direction": "horizontal",
            "bubblesGap": 48,
            "labelsGap": 80,
            "origin": [1550, 260]
        },
        "MCQ_Col1": {
            "fieldType": "QTYPE_MCQ4",
            "fieldLabels": ["q1..20"],
            "direction": "vertical",
            "bubblesGap": 110,
            "labelsGap": 95,
            "origin": [600, 750]
        }
    },
    "preProcessors": [
        {"name": "CropPage", "options": {"morphKernel": [10, 10]}},
        {"name": "CropOnMarkers", "options": {"sheetToMarkerWidthRatio": 17}}
    ]
}

STANDARD_50_Q_TEMPLATE: Dict[str, Any] = {
    "template_id": "standard-50-q-v1",
    "name": "Standard 50 Questions Assessment (2 Columns)",
    "pageDimensions": [2480, 3508],
    "bubbleDimensions": [36, 36],
    "customLabels": {
        "Roll": ["roll1..6"]
    },
    "fieldBlocks": {
        "Roll": {
            "fieldType": "QTYPE_INT",
            "fieldLabels": ["roll1..6"],
            "direction": "horizontal",
            "bubblesGap": 48,
            "labelsGap": 80,
            "origin": [1550, 260]
        },
        "MCQ_Col1": {
            "fieldType": "QTYPE_MCQ4",
            "fieldLabels": ["q1..25"],
            "direction": "vertical",
            "bubblesGap": 105,
            "labelsGap": 92,
            "origin": [320, 720]
        },
        "MCQ_Col2": {
            "fieldType": "QTYPE_MCQ4",
            "fieldLabels": ["q26..50"],
            "direction": "vertical",
            "bubblesGap": 105,
            "labelsGap": 92,
            "origin": [1320, 720]
        }
    },
    "preProcessors": [
        {"name": "CropPage", "options": {"morphKernel": [10, 10]}},
        {"name": "CropOnMarkers", "options": {"sheetToMarkerWidthRatio": 17}}
    ]
}

STANDARD_100_Q_TEMPLATE: Dict[str, Any] = {
    "template_id": "standard-100-q-v1",
    "name": "Standard 100 Questions Assessment (4 Columns)",
    "pageDimensions": [2480, 3508],
    "bubbleDimensions": [32, 32],
    "customLabels": {
        "Roll": ["roll1..6"]
    },
    "fieldBlocks": {
        "Roll": {
            "fieldType": "QTYPE_INT",
            "fieldLabels": ["roll1..6"],
            "direction": "horizontal",
            "bubblesGap": 48,
            "labelsGap": 80,
            "origin": [1550, 260]
        },
        "MCQ_Col1": {
            "fieldType": "QTYPE_MCQ4",
            "fieldLabels": ["q1..25"],
            "direction": "vertical",
            "bubblesGap": 95,
            "labelsGap": 95,
            "origin": [300, 780]
        },
        "MCQ_Col2": {
            "fieldType": "QTYPE_MCQ4",
            "fieldLabels": ["q26..50"],
            "direction": "vertical",
            "bubblesGap": 95,
            "labelsGap": 95,
            "origin": [820, 780]
        },
        "MCQ_Col3": {
            "fieldType": "QTYPE_MCQ4",
            "fieldLabels": ["q51..75"],
            "direction": "vertical",
            "bubblesGap": 95,
            "labelsGap": 95,
            "origin": [1340, 780]
        },
        "MCQ_Col4": {
            "fieldType": "QTYPE_MCQ4",
            "fieldLabels": ["q76..100"],
            "direction": "vertical",
            "bubblesGap": 95,
            "labelsGap": 95,
            "origin": [1860, 780]
        }
    },
    "preProcessors": [
        {"name": "CropPage", "options": {"morphKernel": [10, 10]}},
        {"name": "CropOnMarkers", "options": {"sheetToMarkerWidthRatio": 17}}
    ]
}

NEET_180_Q_TEMPLATE: Dict[str, Any] = {
    "template_id": "neet-180-q-v1",
    "name": "NEET Standard 180 Questions (4 Columns of 45)",
    "pageDimensions": [2480, 3508],
    "bubbleDimensions": [28, 28],
    "customLabels": {
        "Roll": ["roll1..7"]
    },
    "fieldBlocks": {
        "Roll": {
            "fieldType": "QTYPE_INT",
            "fieldLabels": ["roll1..7"],
            "direction": "horizontal",
            "bubblesGap": 42,
            "labelsGap": 70,
            "origin": [1550, 200]
        },
        "Physics": {
            "fieldType": "QTYPE_MCQ4",
            "fieldLabels": ["q1..45"],
            "direction": "vertical",
            "bubblesGap": 100,
            "labelsGap": 56,
            "origin": [255, 600]
        },
        "Chemistry": {
            "fieldType": "QTYPE_MCQ4",
            "fieldLabels": ["q46..90"],
            "direction": "vertical",
            "bubblesGap": 100,
            "labelsGap": 56,
            "origin": [795, 600]
        },
        "Botany": {
            "fieldType": "QTYPE_MCQ4",
            "fieldLabels": ["q91..135"],
            "direction": "vertical",
            "bubblesGap": 100,
            "labelsGap": 56,
            "origin": [1335, 600]
        },
        "Zoology": {
            "fieldType": "QTYPE_MCQ4",
            "fieldLabels": ["q136..180"],
            "direction": "vertical",
            "bubblesGap": 100,
            "labelsGap": 56,
            "origin": [1875, 600]
        }
    },
    "preProcessors": [
        {"name": "CropPage", "options": {"morphKernel": [10, 10]}},
        {"name": "CropOnMarkers", "options": {"sheetToMarkerWidthRatio": 17}}
    ]
}

UNIVERSAL_200_Q_TEMPLATE: Dict[str, Any] = {
    "template_id": "universal-200-q-v1",
    "name": "Universal 200 Questions Dedicated OMR Assessment",
    "pageDimensions": [2480, 3508],
    "bubbleDimensions": [24, 24],
    "customLabels": {
        "Roll": ["roll1..6"]
    },
    "fieldBlocks": {
        "Roll": {
            "fieldType": "QTYPE_INT",
            "fieldLabels": ["roll1..6"],
            "direction": "horizontal",
            "bubblesGap": 45.75,
            "labelsGap": 44.0,
            "origin": [447, 442]
        },
        "Col1": {
            "fieldType": "QTYPE_MCQ4",
            "fieldLabels": ["q1..26"],
            "direction": "vertical",
            "bubblesGap": 46.0,
            "labelsGap": 45.68,
            "origin": [480, 944]
        },
        "Col2": {
            "fieldType": "QTYPE_MCQ4",
            "fieldLabels": ["q27..52"],
            "direction": "vertical",
            "bubblesGap": 46.0,
            "labelsGap": 45.68,
            "origin": [758, 944]
        },
        "Col3": {
            "fieldType": "QTYPE_MCQ4",
            "fieldLabels": ["q53..89"],
            "direction": "vertical",
            "bubblesGap": 46.0,
            "labelsGap": 45.68,
            "origin": [1060, 441]
        },
        "Col4": {
            "fieldType": "QTYPE_MCQ4",
            "fieldLabels": ["q90..126"],
            "direction": "vertical",
            "bubblesGap": 46.0,
            "labelsGap": 45.68,
            "origin": [1336, 441]
        },
        "Col5": {
            "fieldType": "QTYPE_MCQ4",
            "fieldLabels": ["q127..163"],
            "direction": "vertical",
            "bubblesGap": 46.0,
            "labelsGap": 45.68,
            "origin": [1657, 441]
        },
        "Col6": {
            "fieldType": "QTYPE_MCQ4",
            "fieldLabels": ["q164..200"],
            "direction": "vertical",
            "bubblesGap": 46.0,
            "labelsGap": 45.68,
            "origin": [1932, 441]
        }
    },
    "preProcessors": [
        {"name": "CropPage", "options": {"morphKernel": [10, 10]}},
        {"name": "CropOnMarkers", "options": {"sheetToMarkerWidthRatio": 17}}
    ]
}

UNIVERSAL_OMR_TEMPLATE = UNIVERSAL_200_Q_TEMPLATE

NEET_200_Q_TEMPLATE: Dict[str, Any] = {
    "template_id": "neet-200-q-v1",
    "name": "NEET Standard 200 Questions (4 Columns of 50)",
    "pageDimensions": [2480, 3508],
    "bubbleDimensions": [26, 26],
    "customLabels": {
        "Roll": ["roll1..7"]
    },
    "fieldBlocks": {
        "Roll": {
            "fieldType": "QTYPE_INT",
            "fieldLabels": ["roll1..7"],
            "direction": "horizontal",
            "bubblesGap": 40,
            "labelsGap": 65,
            "origin": [1550, 180]
        },
        "Section1": {
            "fieldType": "QTYPE_MCQ4",
            "fieldLabels": ["q1..50"],
            "direction": "vertical",
            "bubblesGap": 100,
            "labelsGap": 53,
            "origin": [255, 580]
        },
        "Section2": {
            "fieldType": "QTYPE_MCQ4",
            "fieldLabels": ["q51..100"],
            "direction": "vertical",
            "bubblesGap": 100,
            "labelsGap": 53,
            "origin": [795, 580]
        },
        "Section3": {
            "fieldType": "QTYPE_MCQ4",
            "fieldLabels": ["q101..150"],
            "direction": "vertical",
            "bubblesGap": 100,
            "labelsGap": 53,
            "origin": [1335, 580]
        },
        "Section4": {
            "fieldType": "QTYPE_MCQ4",
            "fieldLabels": ["q151..200"],
            "direction": "vertical",
            "bubblesGap": 100,
            "labelsGap": 53,
            "origin": [1875, 580]
        }
    },
    "preProcessors": [
        {"name": "CropPage", "options": {"morphKernel": [10, 10]}},
        {"name": "CropOnMarkers", "options": {"sheetToMarkerWidthRatio": 17}}
    ]
}

BUILTIN_TEMPLATES: Dict[str, Dict[str, Any]] = {
    "standard-20-q-v1": STANDARD_20_Q_TEMPLATE,
    "standard-50-q-v1": STANDARD_50_Q_TEMPLATE,
    "standard-100-q-v1": STANDARD_100_Q_TEMPLATE,
    "neet-180-q-v1": NEET_180_Q_TEMPLATE,
    "neet-200-q-v1": NEET_200_Q_TEMPLATE,
    "universal-200-q-v1": UNIVERSAL_200_Q_TEMPLATE,
}


def get_template_by_id_or_questions(template_id: Optional[str] = None, total_questions: Optional[int] = None) -> Dict[str, Any]:
    """Retrieve pre-calibrated template by template_id or question count."""
    if template_id and template_id in BUILTIN_TEMPLATES:
        return BUILTIN_TEMPLATES[template_id]

    tq = total_questions or 100
    if tq <= 25:
        return STANDARD_20_Q_TEMPLATE
    elif tq <= 50:
        return STANDARD_50_Q_TEMPLATE
    elif tq <= 100:
        return STANDARD_100_Q_TEMPLATE
    elif tq <= 180:
        return NEET_180_Q_TEMPLATE
    else:
        return UNIVERSAL_200_Q_TEMPLATE

