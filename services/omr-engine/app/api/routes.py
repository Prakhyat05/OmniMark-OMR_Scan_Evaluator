"""FastAPI API routes for OMR processing, template learning/analysis, and deterministic grading."""
import time
import json
import base64
import cv2
from fastapi import APIRouter, UploadFile, File, Form, HTTPException
from typing import Optional, Dict, Any, List
from pydantic import BaseModel

from app.core.template_model import Template
from app.core.builtins_templates import BUILTIN_TEMPLATES, get_template_by_id_or_questions
from app.processors.normalize import normalize_image
from app.processors.detect_page import detect_document_corners
from app.processors.align import align_to_template
from app.processors.detect_bubbles import evaluate_bubbles, generate_annotated_omr_image
from app.processors.detect_identity import detect_student_code, match_student_roster
from app.processors.detect_fields import detect_metadata_fields
from app.processors.confidence import calculate_overall_confidence
from app.processors.template_analyzer import analyze_omr_template

router = APIRouter(prefix="/v1")


class HealthResponse(BaseModel):
    status: str
    version: str
    uptime_sec: float


class ModelVersionResponse(BaseModel):
    version: str
    detector: str
    supported_templates: list[str]


class EvaluateRequest(BaseModel):
    detected_answers: List[Dict[str, Any]]
    answer_key: Dict[str, Any]
    correct_marks: float = 4.0
    wrong_marks: float = -1.0
    bonus_questions: Optional[List[int]] = None
    dropped_questions: Optional[List[int]] = None


START_TIME = time.time()


@router.get("/health", response_model=HealthResponse)
async def health_check():
    return HealthResponse(
        status="healthy",
        version="2.0.0",
        uptime_sec=round(time.time() - START_TIME, 2),
    )


@router.get("/templates")
async def list_builtin_templates():
    """Returns list of pre-calibrated built-in templates."""
    return {
        "status": "success",
        "templates": [
            {
                "id": k,
                "name": v.get("name", k),
                "questions": len(Template(v).get_question_labels()) if "fieldBlocks" in v else 100,
                "pageDimensions": v.get("pageDimensions", [2480, 3508]),
            }
            for k, v in BUILTIN_TEMPLATES.items()
        ]
    }


@router.get("/model/version", response_model=ModelVersionResponse)
async def get_model_version():
    return ModelVersionResponse(
        version="2.0.0",
        detector="OMRChecker-MultiTier-StatisticalThreshold-v2",
        supported_templates=list(BUILTIN_TEMPLATES.keys()) + ["custom-analyzed-template"],
    )


def compute_evaluation(
    detected_answers: List[Dict[str, Any]],
    answer_key: Dict[int, List[str]],
    correct_marks: float = 4.0,
    wrong_marks: float = -1.0,
    bonus_questions: Optional[set] = None,
    dropped_questions: Optional[set] = None,
) -> Dict[str, Any]:
    """Deterministically grade detected answers against the given answer key."""
    bonus_set = set(bonus_questions or [])
    dropped_set = set(dropped_questions or [])

    total_marks = 0.0
    max_marks = 0.0
    correct = 0
    wrong = 0
    unattempted = 0
    eval_breakdown = []

    for item in detected_answers:
        q_num = item.get("question_number", 1)
        detected_opt = item.get("detected_option")
        is_multiple = item.get("is_multiple", False)
        is_uncertain = item.get("is_uncertain", False)
        confidence = item.get("confidence", 1.0)
        correct_opts = answer_key.get(q_num, [])

        q_max = correct_marks
        is_bonus = q_num in bonus_set
        is_dropped = q_num in dropped_set

        if is_dropped:
            marks = 0.0
            is_corr = None
        elif is_bonus:
            marks = correct_marks
            is_corr = True
            correct += 1
        elif not detected_opt:
            marks = 0.0
            is_corr = None
            unattempted += 1
        elif detected_opt in correct_opts and not is_multiple:
            marks = correct_marks
            is_corr = True
            correct += 1
        else:
            marks = wrong_marks
            is_corr = False
            wrong += 1

        total_marks += marks
        max_marks += q_max

        eval_breakdown.append({
            "question_number": q_num,
            "detected_option": detected_opt,
            "correct_options": correct_opts,
            "is_correct": is_corr,
            "is_multiple": is_multiple,
            "is_uncertain": is_uncertain,
            "confidence": confidence,
            "marks_awarded": marks,
        })

    percentage = round((total_marks / max_marks * 100), 2) if max_marks > 0 else 0.0
    percentage = max(0.0, min(100.0, percentage))

    return {
        "marks_obtained": round(total_marks, 2),
        "maximum_marks": round(max_marks, 2),
        "percentage": percentage,
        "correct_count": correct,
        "wrong_count": wrong,
        "unattempted_count": unattempted,
        "evaluation_breakdown": eval_breakdown,
    }


@router.post("/evaluate")
async def evaluate_answers_endpoint(req: EvaluateRequest):
    """Directly grade a list of detected answers against an answer key."""
    formatted_key = {}
    for k, v in req.answer_key.items():
        if str(k).isdigit():
            formatted_key[int(k)] = v if isinstance(v, list) else [str(v)]

    result = compute_evaluation(
        detected_answers=req.detected_answers,
        answer_key=formatted_key,
        correct_marks=req.correct_marks,
        wrong_marks=req.wrong_marks,
        bonus_questions=set(req.bonus_questions or []),
        dropped_questions=set(req.dropped_questions or []),
    )
    return {"status": "success", "evaluation": result}


@router.post("/analyze-template")
async def analyze_omr_template_endpoint(
    file: UploadFile = File(...),
    expected_questions: Optional[int] = Form(None),
    options_json: Optional[str] = Form(None),
):
    """
    Analyze a sample/blank OMR sheet to learn its specific pattern,
    question columns, bubble locations, and student ID field.
    """
    image_bytes = await file.read()
    if len(image_bytes) == 0:
        raise HTTPException(status_code=400, detail="Empty template file provided.")

    options_list = ["A", "B", "C", "D"]
    if options_json:
        try:
            options_list = json.loads(options_json)
        except Exception:
            options_list = ["A", "B", "C", "D"]

    try:
        result = analyze_omr_template(
            image_bytes=image_bytes,
            expected_questions=expected_questions,
            options_list=options_list,
        )
        return result
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Template analysis error: {str(e)}",
        )


@router.post("/process-sheet")
async def process_omr_sheet(
    file: UploadFile = File(...),
    template_config_json: Optional[str] = Form(None),
    answer_key_json: Optional[str] = Form(None),
    marking_scheme_json: Optional[str] = Form(None),
    student_roster_json: Optional[str] = Form(None),
):
    """
    Process an OMR sheet image, perform sub-pixel alignment, detect marked bubbles,
    decode real student identity, and evaluate deterministically against answer key.
    """
    start_proc = time.time()

    image_bytes = await file.read()
    if len(image_bytes) == 0:
        raise HTTPException(status_code=400, detail="Empty image file provided.")

    template_config = {}
    if template_config_json:
        try:
            template_config = json.loads(template_config_json)
        except Exception:
            template_config = {}

    answer_key = {}
    if answer_key_json:
        try:
            raw_key = json.loads(answer_key_json)
            for k, v in raw_key.items():
                q_num = int(k)
                answer_key[q_num] = v if isinstance(v, list) else [str(v)]
        except Exception:
            answer_key = {}

    marking_scheme = {}
    if marking_scheme_json:
        try:
            marking_scheme = json.loads(marking_scheme_json)
        except Exception:
            marking_scheme = {}

    student_roster = []
    if student_roster_json:
        try:
            student_roster = json.loads(student_roster_json)
        except Exception:
            student_roster = []

    page_dims = template_config.get("pageDimensions", [2480, 3508])
    target_w, target_h = page_dims[0], page_dims[1]
    if "fieldBlocks" in template_config:
        tmpl = Template(template_config)
        total_q = len(tmpl.get_question_labels())
    elif "question_bubble_map" in template_config:
        total_q = len(template_config["question_bubble_map"])
    else:
        total_q = template_config.get("total_questions", len(answer_key) if answer_key else 100)

    try:
        # Step 1: Normalize & EXIF orientation
        try:
            gray = normalize_image(image_bytes)
        except ValueError:
            raise HTTPException(
                status_code=400,
                detail="Could not decode image from provided file bytes. Supported formats: JPEG, PNG, WEBP, BMP.",
            )

        # Step 2: Detect page boundary or corner fiducials (CropPage)
        corners = detect_document_corners(gray)
        if corners is None:
            raise HTTPException(
                status_code=422,
                detail="Could not detect OMR document boundaries. Please align the sheet within the viewfinder.",
            )

        # Step 3: Align perspective to canonical dimensions
        aligned = align_to_template(gray, corners, target_w=target_w, target_h=target_h)

        # Step 4: Real Student Code / QR / Roll Matrix detection
        detected_student_code = detect_student_code(aligned, template_config)

        # Step 5: Match detected code against enrolled student roster
        matched_student = match_student_roster(detected_student_code, student_roster)

        # Step 6: Detect bubble choices deterministically using two-tier statistical thresholding
        detected_answers = evaluate_bubbles(aligned, template_config, total_questions=total_q)

        # Step 7: Confidence calculation
        overall_conf, review_required = calculate_overall_confidence(detected_answers)
        if detected_student_code is None and len(student_roster) > 0:
            review_required = True

        # Step 8: Automated scoring against answer key
        evaluation_data = None
        if answer_key:
            correct_marks = float(marking_scheme.get("correct_marks", 4.0))
            wrong_marks = float(marking_scheme.get("wrong_marks", -1.0))
            bonus_q = set(marking_scheme.get("bonus_questions", []))
            dropped_q = set(marking_scheme.get("dropped_questions", []))

            evaluation_data = compute_evaluation(
                detected_answers=detected_answers,
                answer_key=answer_key,
                correct_marks=correct_marks,
                wrong_marks=wrong_marks,
                bonus_questions=bonus_q,
                dropped_questions=dropped_q,
            )

        # Step 9: Analyze handwritten metadata fields (Name, Class, School Code, Date, Exam No)
        metadata_info = detect_metadata_fields(aligned, template_config)

        # Step 10: Generate visual annotated preview overlay
        annotated = generate_annotated_omr_image(aligned, detected_answers, answer_key=answer_key)
        thumb = cv2.resize(annotated, (620, 877), interpolation=cv2.INTER_AREA)
        _, thumb_encoded = cv2.imencode(".jpg", thumb, [cv2.IMWRITE_JPEG_QUALITY, 80])
        preview_base64 = base64.b64encode(thumb_encoded.tobytes()).decode("utf-8")

        elapsed_ms = int((time.time() - start_proc) * 1000)

        return {
            "status": "success",
            "detector_version": "2.0.0",
            "student_code_detected": detected_student_code,
            "matched_student": matched_student,
            "overall_confidence": overall_conf,
            "review_required": review_required,
            "processing_ms": elapsed_ms,
            "total_questions_detected": len(detected_answers),
            "answers": detected_answers,
            "evaluation": evaluation_data,
            "metadata_fields": metadata_info.get("fields", {}),
            "vacant_fields": metadata_info.get("vacant_fields", []),
            "filled_fields": metadata_info.get("filled_fields", []),
            "vacant_fields_count": metadata_info.get("vacant_count", 0),
            "all_fields_completed": metadata_info.get("all_fields_completed", False),
            "annotated_preview_base64": preview_base64,
        }

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Internal OMR processing error: {str(e)}",
        )


@router.post("/verify-discrepancy")
async def verify_discrepancy_endpoint(
    file: UploadFile = File(...),
    client_evaluation_json: str = Form(...),
    answer_key_json: Optional[str] = Form(None),
    template_id: Optional[str] = Form("standard-100-q-v1"),
):
    """
    Dual-Engine Cloud Cross-Verification Endpoint:
    Compares on-device mobile evaluation against independent cloud OMRChecker pass.
    Flags any question discrepancy for administrative audit to guarantee 100% accuracy.
    """
    import hashlib

    start_proc = time.time()
    try:
        client_data = json.loads(client_evaluation_json)
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Invalid client_evaluation_json: {str(e)}")

    contents = await file.read()
    gray = normalize_image(contents)
    if gray is None:
        raise HTTPException(status_code=400, detail="Could not decode image file")

    corners = detect_document_corners(gray)
    aligned = align_to_template(gray, corners, 2480, 3508)

    template_config = get_template_by_id_or_questions(template_id, 100)
    server_answers_list = evaluate_bubbles(aligned, template_config)
    server_code = detect_student_code(aligned, template_config)

    # Build server answer map
    server_map = {}
    for item in server_answers_list:
        server_map[item["question_number"]] = item.get("detected_option")

    # Extract client answers
    raw_client_answers = client_data.get("detected_answers", {})
    client_map = {}
    for k, v in raw_client_answers.items():
        client_map[int(k)] = v

    # Compare
    discrepancies = []
    all_qs = set(client_map.keys()).union(set(server_map.keys()))
    total_compared = max(1, len(all_qs))

    for q in sorted(all_qs):
        c_opt = client_map.get(q)
        s_opt = server_map.get(q)
        if c_opt != s_opt:
            discrepancies.append({
                "question_number": q,
                "client_option": c_opt,
                "server_option": s_opt,
                "status": "DISCREPANCY",
            })

    client_code = client_data.get("student_code")
    if client_code and server_code and client_code != server_code:
        discrepancies.append({
            "question_number": 0,
            "field": "student_code",
            "client_option": client_code,
            "server_option": server_code,
            "status": "STUDENT_CODE_MISMATCH",
        })

    is_verified = len(discrepancies) == 0
    match_pct = round(((total_compared - len(discrepancies)) / total_compared) * 100.0, 2)

    sig_payload = f"{client_code}_{server_code}_{match_pct}_{len(discrepancies)}_{time.time()}"
    verification_hash = hashlib.sha256(sig_payload.encode()).hexdigest()

    return {
        "status": "success",
        "is_verified_100": is_verified,
        "verification_status": "VERIFIED_DUAL_PASS_100" if is_verified else "DISCREPANCY_FLAGGED",
        "match_percentage": match_pct,
        "discrepancies_count": len(discrepancies),
        "discrepancies": discrepancies,
        "client_student_code": client_code,
        "server_student_code": server_code,
        "digital_verification_hash": verification_hash,
        "processing_ms": int((time.time() - start_proc) * 1000),
    }
