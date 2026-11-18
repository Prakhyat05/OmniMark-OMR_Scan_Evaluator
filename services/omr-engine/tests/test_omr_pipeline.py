"""
Unit and integration tests for the deterministic OMRChecker-based engine.
"""
import os
import cv2
import json
import asyncio
import numpy as np
import pytest

from app.core.template_model import Template, FieldBlock, parse_field_range
from app.core.builtins_templates import BUILTIN_TEMPLATES, get_template_by_id_or_questions
from app.processors.normalize import normalize_image
from app.processors.detect_page import detect_document_corners, order_points, detect_fiducial_markers
from app.processors.align import align_to_template
from app.processors.detect_bubbles import evaluate_bubbles, generate_annotated_omr_image, get_global_threshold, get_local_threshold
from app.processors.detect_identity import detect_student_code, decode_roll_number_grid, match_student_roster
from app.processors.confidence import calculate_overall_confidence
from app.processors.template_analyzer import analyze_omr_template
from app.api.routes import compute_evaluation, process_omr_sheet, analyze_omr_template_endpoint, verify_discrepancy_endpoint


class FakeUploadFile:
    def __init__(self, filename: str, content_bytes: bytes, content_type: str = "image/jpeg"):
        self.filename = filename
        self._bytes = content_bytes
        self.content_type = content_type

    async def read(self):
        return self._bytes


def create_synthetic_omr_sheet(
    w=2480,
    h=3508,
    mark_q1_b=True,
    mark_q2_unanswered=True,
    mark_q3_multiple=False,
    roll_code_digits="102",
    total_q=100
):
    """Generate a clean synthetic OMR image with marked bubbles, unanswered questions, and roll code."""
    img = np.ones((h, w, 3), dtype=np.uint8) * 255

    # Registration fiducials at standard canonical positions
    cv2.rectangle(img, (120, 120), (180, 180), (0, 0, 0), -1)
    cv2.rectangle(img, (2300, 120), (2360, 180), (0, 0, 0), -1)
    cv2.rectangle(img, (120, 3328), (180, 3388), (0, 0, 0), -1)
    cv2.rectangle(img, (2300, 3328), (2360, 3388), (0, 0, 0), -1)

    if total_q == 180:
        # NEET 180-Question grid:
        # Physics Q1: origin [255, 600], bubblesGap 100, labelsGap 56
        # Option B = idx 1: x = 255 + 100 = 355, y = 600 + 14 = 614
        if mark_q1_b:
            cv2.circle(img, (355, 614), 12, (0, 0, 0), -1)
        # Q3: Multiple marks (Option A & Option C)
        # y = 600 + 2 * 56 + 14 = 726
        if mark_q3_multiple:
            cv2.circle(img, (255, 726), 12, (0, 0, 0), -1)  # Opt A
            cv2.circle(img, (455, 726), 12, (0, 0, 0), -1)  # Opt C
    else:
        # Standard 100-Question grid:
        # MCQ_Col1: origin [300, 780], bubblesGap 95, labelsGap 95, bubbleDimensions [32, 32]
        # Q1 Option B = idx 1: x = 300 + 95 + 16 = 411, y = 780 + 16 = 796
        if mark_q1_b:
            cv2.circle(img, (411, 796), 14, (0, 0, 0), -1)
        if mark_q3_multiple:
            # Q3: y = 780 + 2 * 95 + 16 = 986
            cv2.circle(img, (316, 986), 14, (0, 0, 0), -1)  # Opt A
            cv2.circle(img, (506, 986), 14, (0, 0, 0), -1)  # Opt C

    # Roll Number bubble grid:
    # Standard template: origin [1550, 260], bubblesGap 48, labelsGap 80, direction horizontal
    # For col_idx (digit column 0..5): x = 1550 + col_idx * 80 + 18
    # For digit (0..9): y = 260 + digit * 48 + 18
    if roll_code_digits:
        start_x = 1550
        start_y = 260
        col_spacing = 80
        row_spacing = 48
        for col_idx, char_digit in enumerate(roll_code_digits):
            if char_digit.isdigit():
                d = int(char_digit)
                bx = start_x + (col_idx * col_spacing) + 18
                by = start_y + (d * row_spacing) + 18
                cv2.circle(img, (bx, by), 16, (0, 0, 0), -1)

    _, encoded = cv2.imencode(".jpg", img)
    return encoded.tobytes()


def test_parse_field_range():
    assert parse_field_range("q1..5") == ["q1", "q2", "q3", "q4", "q5"]
    assert parse_field_range("roll1..4") == ["roll1", "roll2", "roll3", "roll4"]
    assert parse_field_range("1..3") == ["1", "2", "3"]
    assert parse_field_range("single") == ["single"]


def test_template_model():
    tmpl_dict = get_template_by_id_or_questions("standard-100-q-v1")
    tmpl = Template(tmpl_dict)
    assert len(tmpl.field_blocks) == 5  # Roll + 4 MCQ columns
    q_labels = tmpl.get_question_labels()
    assert len(q_labels) == 100
    assert q_labels[0] == "q1"
    assert q_labels[-1] == "q100"


def test_normalization():
    raw_bytes = create_synthetic_omr_sheet()
    gray = normalize_image(raw_bytes)
    assert gray is not None
    assert len(gray.shape) == 2
    assert gray.shape[0] >= gray.shape[1]


def test_fiducials_detection():
    raw_bytes = create_synthetic_omr_sheet()
    gray = normalize_image(raw_bytes)
    fiducials = detect_fiducial_markers(gray)
    assert fiducials is not None
    assert len(fiducials) == 4


def test_order_points():
    pts = np.array([[100, 100], [500, 100], [500, 800], [100, 800]], dtype="float32")
    ordered = order_points(pts)
    assert np.array_equal(ordered[0], [100, 100])
    assert np.array_equal(ordered[1], [500, 100])
    assert np.array_equal(ordered[2], [500, 800])
    assert np.array_equal(ordered[3], [100, 800])


def test_bubble_evaluation():
    raw_bytes = create_synthetic_omr_sheet(total_q=100, mark_q1_b=True, mark_q3_multiple=True)
    gray = normalize_image(raw_bytes)
    corners = detect_document_corners(gray)
    assert corners is not None
    aligned = align_to_template(gray, corners, 2480, 3508)

    results = evaluate_bubbles(aligned, BUILTIN_TEMPLATES["standard-100-q-v1"], total_questions=100)
    assert len(results) == 100

    # Q1 was marked as Option B
    q1 = results[0]
    assert q1["question_number"] == 1
    assert q1["detected_option"] == "B"
    assert q1["is_multiple"] is False
    assert q1["confidence"] > 0.8

    # Q2 was left completely unanswered -> MUST return None (Unanswered)
    q2 = results[1]
    assert q2["question_number"] == 2
    assert q2["detected_option"] is None
    assert q2["is_multiple"] is False
    assert q2["confidence"] == 1.0

    # Q3 was multiple marked -> is_multiple True
    q3 = results[2]
    assert q3["question_number"] == 3
    assert q3["is_multiple"] is True
    assert q3["is_uncertain"] is True


def test_180_questions_evaluation():
    """Verify precision alignment and evaluation for 180 questions (NEET layout)."""
    raw_bytes = create_synthetic_omr_sheet(total_q=180, mark_q1_b=True, mark_q3_multiple=True)
    gray = normalize_image(raw_bytes)
    corners = detect_document_corners(gray)
    aligned = align_to_template(gray, corners, 2480, 3508)

    results = evaluate_bubbles(aligned, BUILTIN_TEMPLATES["neet-180-q-v1"], total_questions=180)
    assert len(results) == 180

    # Q1: Marked Option B
    q1 = results[0]
    assert q1["question_number"] == 1
    assert q1["detected_option"] == "B"
    assert q1["confidence"] > 0.8

    # Q2: Unanswered -> None
    q2 = results[1]
    assert q2["question_number"] == 2
    assert q2["detected_option"] is None

    # Q3: Multiple bubbles marked -> is_multiple True
    q3 = results[2]
    assert q3["question_number"] == 3
    assert q3["is_multiple"] is True


def test_roll_number_grid_decoding():
    raw_bytes = create_synthetic_omr_sheet(roll_code_digits="102")
    gray = normalize_image(raw_bytes)
    corners = detect_document_corners(gray)
    aligned = align_to_template(gray, corners, 2480, 3508)

    detected_code = detect_student_code(aligned, BUILTIN_TEMPLATES["standard-100-q-v1"])
    assert detected_code == "102"


def test_detect_student_code_empty_and_barcode_fallback():
    blank = np.ones((500, 500, 3), dtype=np.uint8) * 255
    code = detect_student_code(blank, {})
    assert code is None


def test_student_roster_matching():
    roster = [
        {"id": "s1", "name": "Aarav Sharma", "code": "STU1001", "roll": "101", "className": "Grade 10 - Section A"},
        {"id": "s2", "name": "Priya Patel", "code": "STU1002", "roll": "102", "className": "Grade 10 - Section A"},
    ]
    matched = match_student_roster("102", roster)
    assert matched is not None
    assert matched["name"] == "Priya Patel"

    matched2 = match_student_roster("STU1001", roster)
    assert matched2 is not None
    assert matched2["name"] == "Aarav Sharma"


def test_template_analyzer_endpoint():
    raw_bytes = create_synthetic_omr_sheet(total_q=100)
    fake_file = FakeUploadFile("blank_template_100.jpg", raw_bytes)

    result = asyncio.run(analyze_omr_template_endpoint(
        file=fake_file,
        expected_questions=100,
    ))

    assert result["status"] == "success"
    assert result["total_questions_detected"] == 100
    assert "template_config" in result
    assert "preview_base64" in result


def test_compute_evaluation_logic():
    detected = [
        {"question_number": 1, "detected_option": "B", "is_multiple": False, "is_uncertain": False, "confidence": 1.0},
        {"question_number": 2, "detected_option": "A", "is_multiple": False, "is_uncertain": False, "confidence": 1.0},
        {"question_number": 3, "detected_option": "C", "is_multiple": False, "is_uncertain": False, "confidence": 1.0},
        {"question_number": 4, "detected_option": None, "is_multiple": False, "is_uncertain": False, "confidence": 0.0},
    ]
    key = {1: ["B"], 2: ["A"], 3: ["D"], 4: ["A"]}

    res = compute_evaluation(
        detected_answers=detected,
        answer_key=key,
        correct_marks=4.0,
        wrong_marks=-1.0,
    )

    assert res["marks_obtained"] == 7.0
    assert res["maximum_marks"] == 16.0
    assert res["correct_count"] == 2
    assert res["wrong_count"] == 1
    assert res["unattempted_count"] == 1
    assert res["percentage"] == 43.75


def test_process_omr_sheet_endpoint():
    raw_bytes = create_synthetic_omr_sheet(roll_code_digits="102", mark_q1_b=True)
    fake_file = FakeUploadFile("test_student_102.jpg", raw_bytes, "image/jpeg")

    roster = [
        {"id": "s1", "name": "Aarav Sharma", "code": "STU1001", "roll": "101", "className": "Grade 10 - Section A"},
        {"id": "s2", "name": "Priya Patel", "code": "STU1002", "roll": "102", "className": "Grade 10 - Section A"},
    ]

    result = asyncio.run(process_omr_sheet(
        file=fake_file,
        template_config_json=json.dumps(BUILTIN_TEMPLATES["standard-100-q-v1"]),
        answer_key_json=json.dumps({"1": "B", "2": "C"}),
        marking_scheme_json=json.dumps({"correct_marks": 4.0, "wrong_marks": -1.0}),
        student_roster_json=json.dumps(roster),
    ))

    assert result["status"] == "success"
    assert result["student_code_detected"] == "102"
    assert result["matched_student"] is not None
    assert result["matched_student"]["name"] == "Priya Patel"
    assert result["total_questions_detected"] == 100
    assert result["evaluation"] is not None
    assert "annotated_preview_base64" in result


def test_real_omrchecker_sample1():
    """Verify evaluating a real-world camera scanned sheet from OMRChecker sample1 dataset."""
    fixtures_dir = os.path.join(os.path.dirname(__file__), "..", "assets", "fixtures", "omrchecker_sample1")
    img_path = os.path.join(fixtures_dir, "sheet1.jpg")
    tmpl_path = os.path.join(fixtures_dir, "template.json")

    if os.path.exists(img_path) and os.path.exists(tmpl_path):
        with open(img_path, "rb") as f:
            img_bytes = f.read()
        with open(tmpl_path, "r") as f:
            tmpl_dict = json.load(f)

        fake_file = FakeUploadFile("sheet1.jpg", img_bytes)
        result = asyncio.run(process_omr_sheet(
            file=fake_file,
            template_config_json=json.dumps(tmpl_dict),
            answer_key_json=json.dumps({"1": "A", "2": "B", "3": "C"}),
        ))

        assert result["status"] == "success"
        assert result["total_questions_detected"] > 0
        assert "answers" in result
        assert "annotated_preview_base64" in result


def test_universal_200_q_evaluation_with_answer_key():
    """Verify evaluation of the 200-Question Universal template against the exact answer key."""
    tmpl = BUILTIN_TEMPLATES["universal-200-q-v1"]
    assert tmpl is not None

    # Construct user answer key: Q1-26: A, Q27-52: B, Q53-89: C, Q90-126: D, Q127-163: A, Q164-200: B
    answer_key = {}
    for q in range(1, 27):
        answer_key[str(q)] = "A"
    for q in range(27, 53):
        answer_key[str(q)] = "B"
    for q in range(53, 90):
        answer_key[str(q)] = "C"
    for q in range(90, 127):
        answer_key[str(q)] = "D"
    for q in range(127, 164):
        answer_key[str(q)] = "A"
    for q in range(164, 201):
        answer_key[str(q)] = "B"

    assert len(answer_key) == 200

    raw_bytes = create_synthetic_omr_sheet(total_q=100)
    fake_file = FakeUploadFile("test_universal_200.jpg", raw_bytes)

    result = asyncio.run(process_omr_sheet(
        file=fake_file,
        template_config_json=json.dumps(tmpl),
        answer_key_json=json.dumps(answer_key),
    ))

    assert result["status"] == "success"
    assert result["total_questions_detected"] == 200
    assert result["evaluation"] is not None
    assert result["evaluation"]["maximum_marks"] == 800.0  # 200 * 4.0
    assert "metadata_fields" in result
    assert "vacant_fields" in result


def test_detect_metadata_fields():
    """Verify vacant field detection on clean canvas vs inked canvas."""
    from app.processors.detect_fields import detect_metadata_fields
    
    # Blank canvas -> all fields vacant
    blank = np.ones((3508, 2480), dtype=np.uint8) * 255
    res_blank = detect_metadata_fields(blank)
    assert res_blank["vacant_count"] == 11
    assert "Student Name" in res_blank["vacant_fields"]
    assert "School Code No" in res_blank["vacant_fields"]
    assert "Roll Number (Boxes)" in res_blank["vacant_fields"]

    # Canvas with handwriting in student name field
    inked = blank.copy()
    # Name region: y: 2475..2545, x: 1450..2300
    cv2.putText(inked, "PRAKHAR VERMA", (1500, 2520), cv2.FONT_HERSHEY_SIMPLEX, 1.5, 0, 3)
    res_inked = detect_metadata_fields(inked)
    assert "Student Name" not in res_inked["vacant_fields"]
    assert res_inked["vacant_count"] == 10
    assert res_inked["fields"]["student_name"]["has_handwriting"] is True


def test_verify_discrepancy_endpoint():
    """Verify dual-engine cross-verification flags discrepancies and approves matching results."""
    # Synthetic sheet where Q1 is marked Option B and Roll is '102'
    raw_bytes = create_synthetic_omr_sheet(total_q=100, mark_q1_b=True, roll_code_digits="102")
    file_upload = FakeUploadFile("synthetic_verify.jpg", raw_bytes)

    # 1. Matching evaluation from mobile client
    matching_client_eval = {
        "student_code": "102",
        "detected_answers": {1: "B", 2: None},
    }

    res_matching = asyncio.run(verify_discrepancy_endpoint(
        file=file_upload,
        client_evaluation_json=json.dumps(matching_client_eval),
        template_id="standard-100-q-v1",
    ))

    assert res_matching["status"] == "success"
    assert "digital_verification_hash" in res_matching

    # 2. Intentionally divergent evaluation (Client claims Q1 was 'A')
    file_upload_div = FakeUploadFile("synthetic_verify_div.jpg", raw_bytes)
    divergent_client_eval = {
        "student_code": "102",
        "detected_answers": {1: "A", 2: None},
    }

    res_div = asyncio.run(verify_discrepancy_endpoint(
        file=file_upload_div,
        client_evaluation_json=json.dumps(divergent_client_eval),
        template_id="standard-100-q-v1",
    ))

    assert res_div["status"] == "success"
    assert res_div["is_verified_100"] is False
    assert res_div["verification_status"] == "DISCREPANCY_FLAGGED"
    assert res_div["discrepancies_count"] >= 1
    # Check that Q1 discrepancy was captured
    q1_disc = next(d for d in res_div["discrepancies"] if d["question_number"] == 1)
    assert q1_disc["client_option"] == "A"
    assert q1_disc["server_option"] == "B"

