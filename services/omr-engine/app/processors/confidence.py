"""Confidence and review requirement scoring."""
from typing import List, Dict, Any, Tuple


def calculate_overall_confidence(answers: List[Dict[str, Any]]) -> Tuple[float, bool]:
    """Calculate the average confidence score across all questions and flag review requirement."""
    if not answers:
        return 0.0, True

    total_conf = sum(a.get("confidence", 0.0) for a in answers)
    avg_conf = total_conf / len(answers)

    # Flag for manual review if any uncertain/multiple bubble is detected or overall confidence < 85%
    review_required = any(a.get("is_uncertain") or a.get("is_multiple") for a in answers) or (avg_conf < 0.85)

    return round(avg_conf, 4), review_required
