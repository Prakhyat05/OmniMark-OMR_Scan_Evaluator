"""
OMR Template and FieldBlock Data Models
Ported and adapted from OMRChecker architecture for deterministic coordinate calculation,
custom labels, question numbering, and bubble matrix mapping.
"""
import re
from typing import Dict, Any, List, Tuple, Optional, Set


def parse_field_range(field_str: str) -> List[str]:
    """
    Parses label ranges like 'q1..25' into ['q1', 'q2', ..., 'q25']
    or 'roll1..6' into ['roll1', 'roll2', ..., 'roll6'].
    Also handles lists or comma-separated strings.
    """
    field_str = str(field_str).strip()
    match = re.match(r"^([a-zA-Z_-]+)(\d+)\.\.(\d+)$", field_str)
    if match:
        prefix = match.group(1)
        start_idx = int(match.group(2))
        end_idx = int(match.group(3))
        step = 1 if start_idx <= end_idx else -1
        return [f"{prefix}{i}" for i in range(start_idx, end_idx + step, step)]

    # Match numeric ranges like '1..50'
    match_num = re.match(r"^(\d+)\.\.(\d+)$", field_str)
    if match_num:
        start_idx = int(match_num.group(1))
        end_idx = int(match_num.group(2))
        step = 1 if start_idx <= end_idx else -1
        return [str(i) for i in range(start_idx, end_idx + step, step)]

    return [field_str]


def parse_fields_list(fields_raw: Any) -> List[str]:
    """Parse list of field strings or range definitions."""
    if isinstance(fields_raw, list):
        result = []
        for item in fields_raw:
            result.extend(parse_field_range(str(item)))
        return result
    elif isinstance(fields_raw, str):
        if "," in fields_raw:
            result = []
            for part in fields_raw.split(","):
                result.extend(parse_field_range(part.strip()))
            return result
        return parse_field_range(fields_raw)
    return [str(fields_raw)]


class Bubble:
    """Represents a single circular bubble on the canonical OMR sheet."""
    def __init__(
        self,
        x: int,
        y: int,
        w: int,
        h: int,
        field_label: str,
        field_value: str,
        field_block_name: str,
    ):
        self.x = int(x)
        self.y = int(y)
        self.w = int(w)
        self.h = int(h)
        self.field_label = field_label
        self.field_value = field_value
        self.field_block_name = field_block_name

    @property
    def center(self) -> Tuple[int, int]:
        return (self.x + self.w // 2, self.y + self.h // 2)

    @property
    def radius(self) -> int:
        return min(self.w, self.h) // 2

    def to_dict(self) -> Dict[str, Any]:
        cx, cy = self.center
        return {
            "x": cx,
            "y": cy,
            "r": self.radius,
            "w": self.w,
            "h": self.h,
            "field_label": self.field_label,
            "field_value": self.field_value,
            "field_block": self.field_block_name,
        }


class FieldBlock:
    """
    Represents a contiguous block of question or identity bubbles.
    Supports vertical (column-first) and horizontal (row-first) layouts.
    """
    FIELD_TYPES = {
        "QTYPE_MCQ4": {"bubbleValues": ["A", "B", "C", "D"]},
        "QTYPE_MCQ5": {"bubbleValues": ["A", "B", "C", "D", "E"]},
        "QTYPE_INT": {"bubbleValues": ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]},
        "QTYPE_BOOL": {"bubbleValues": ["T", "F"]},
    }

    def __init__(self, name: str, block_config: Dict[str, Any], global_bubble_dims: Tuple[int, int]):
        self.name = name
        self.shift = 0

        field_type = block_config.get("fieldType", "__CUSTOM__")
        type_defaults = self.FIELD_TYPES.get(field_type, {})

        self.bubble_values = block_config.get("bubbleValues", type_defaults.get("bubbleValues", ["A", "B", "C", "D"]))
        self.direction = block_config.get("direction", "vertical")
        self.empty_val = block_config.get("emptyValue", None)
        self.origin = block_config.get("origin", [0, 0])
        self.bubble_dimensions = block_config.get("bubbleDimensions", global_bubble_dims)
        self.bubbles_gap = block_config.get("bubblesGap", self.bubble_dimensions[0] + 10)
        self.labels_gap = block_config.get("labelsGap", self.bubble_dimensions[1] + 15)

        raw_labels = block_config.get("fieldLabels", [name])
        self.parsed_field_labels = parse_fields_list(raw_labels)

        self._build_bubble_matrix()

    def _build_bubble_matrix(self):
        """Pre-compute the exact bounding boxes for every bubble in this field block."""
        self.traverse_bubbles: List[List[Bubble]] = []
        self.all_bubbles: List[Bubble] = []

        box_w, box_h = self.bubble_dimensions
        ox, oy = self.origin

        num_labels = len(self.parsed_field_labels)
        num_values = len(self.bubble_values)

        if self.direction == "vertical":
            # For each field label (e.g. question row or roll column)
            for l_idx, label in enumerate(self.parsed_field_labels):
                label_bubbles: List[Bubble] = []
                for v_idx, val in enumerate(self.bubble_values):
                    bx = int(ox + (v_idx * self.bubbles_gap))
                    by = int(oy + (l_idx * self.labels_gap))
                    b = Bubble(bx, by, box_w, box_h, label, val, self.name)
                    label_bubbles.append(b)
                    self.all_bubbles.append(b)
                self.traverse_bubbles.append(label_bubbles)

            self.dimensions = [
                int((num_values - 1) * self.bubbles_gap + box_w),
                int((num_labels - 1) * self.labels_gap + box_h),
            ]
        else:
            # Horizontal direction
            for l_idx, label in enumerate(self.parsed_field_labels):
                label_bubbles: List[Bubble] = []
                for v_idx, val in enumerate(self.bubble_values):
                    bx = int(ox + (l_idx * self.labels_gap))
                    by = int(oy + (v_idx * self.bubbles_gap))
                    b = Bubble(bx, by, box_w, box_h, label, val, self.name)
                    label_bubbles.append(b)
                    self.all_bubbles.append(b)
                self.traverse_bubbles.append(label_bubbles)

            self.dimensions = [
                int((num_labels - 1) * self.labels_gap + box_w),
                int((num_values - 1) * self.bubbles_gap + box_h),
            ]


def natural_sort_key(s: str):
    return [int(text) if text.isdigit() else text.lower() for text in re.split(r"(\d+)", str(s))]


class Template:
    """
    Full OMR Template containing page dimensions, bubble dimensions,
    field blocks, custom label groupings, preprocessors, and output column order.
    """
    def __init__(self, template_dict: Dict[str, Any]):
        self.raw_config = template_dict
        self.page_dimensions = template_dict.get("pageDimensions", [2480, 3508])
        self.bubble_dimensions = template_dict.get("bubbleDimensions", [36, 36])
        self.global_empty_val = template_dict.get("emptyValue", None)
        self.pre_processors = template_dict.get("preProcessors", [
            {"name": "CropPage", "options": {"morphKernel": [10, 10]}},
            {"name": "CropOnMarkers", "options": {"sheetToMarkerWidthRatio": 17}},
        ])

        # Setup field blocks
        self.field_blocks: List[FieldBlock] = []
        self.field_blocks_map: Dict[str, FieldBlock] = {}
        self.all_parsed_labels: Set[str] = set()

        raw_blocks = template_dict.get("fieldBlocks", {})
        for block_name, block_cfg in raw_blocks.items():
            fb = FieldBlock(block_name, block_cfg, self.bubble_dimensions)
            self.field_blocks.append(fb)
            self.field_blocks_map[block_name] = fb
            for label in fb.parsed_field_labels:
                self.all_parsed_labels.add(label)

        # Setup custom labels (grouping multi-digit blocks like Roll -> ['roll1..6'])
        self.custom_labels: Dict[str, List[str]] = {}
        raw_custom = template_dict.get("customLabels", {})
        for custom_name, label_defs in raw_custom.items():
            self.custom_labels[custom_name] = parse_fields_list(label_defs)

        # Output columns
        raw_output_cols = template_dict.get("outputColumns", [])
        if raw_output_cols:
            self.output_columns = parse_fields_list(raw_output_cols)
        else:
            custom_keys = list(self.custom_labels.keys())
            custom_targets = set()
            for sublist in self.custom_labels.values():
                custom_targets.update(sublist)
            non_custom = [l for l in sorted(self.all_parsed_labels, key=natural_sort_key) if l not in custom_targets]
            self.output_columns = custom_keys + non_custom

    def get_question_labels(self) -> List[str]:
        """Returns natural-sorted question labels (e.g. q1, q2, ..., q100)."""
        q_labels = []
        for l in self.output_columns:
            if re.match(r"^q\d+$", l, re.IGNORECASE) or l.isdigit() or l.startswith("Q_"):
                q_labels.append(l)
        if not q_labels:
            for l in self.output_columns:
                if "roll" not in l.lower() and "id" not in l.lower():
                    q_labels.append(l)
        q_labels.sort(key=natural_sort_key)
        return q_labels

    def to_question_bubble_map(self) -> List[Dict[str, Any]]:
        """Exports question bubble layout for mobile preview and fast reading."""
        q_map = []
        q_counter = 1

        for fb in self.field_blocks:
            if "roll" in fb.name.lower() or "id" in fb.name.lower():
                continue
            for strip in fb.traverse_bubbles:
                opts = []
                for b in strip:
                    cx, cy = b.center
                    opts.append({
                        "option": b.field_value,
                        "x": cx,
                        "y": cy,
                        "r": b.radius,
                    })
                first_label = strip[0].field_label
                match_num = re.search(r"\d+", first_label)
                q_num = int(match_num.group(0)) if match_num else q_counter
                q_map.append({
                    "question_number": q_num,
                    "field_label": first_label,
                    "options": opts,
                })
                q_counter += 1

        q_map.sort(key=lambda item: item["question_number"])
        return q_map
