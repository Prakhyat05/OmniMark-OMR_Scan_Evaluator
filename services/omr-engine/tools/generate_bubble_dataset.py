"""
Synthetic & Real Bubble Dataset Generator for OMR Micro-CNN Classifier.
Generates 32x32 grayscale image patches across 4 classes:
0: BLANK (Empty printed bubble with letter/digit)
1: FULLY_FILLED (Clean black/blue pen, pencil fill)
2: ERASED_SMUDGED (Erased pencil/pen mark, ghost smudge)
3: INVALID_PARTIAL (Tick ✔, Cross ✖, stray tiny dot, scratch)
"""
import os
import random
import cv2
import numpy as np

def create_base_bubble_patch(size=32, radius=12, label="A", border_thickness=2):
    """Creates a clean blank bubble patch with printed label."""
    patch = np.ones((size, size), dtype=np.uint8) * 255
    cx, cy = size // 2, size // 2
    
    # Draw outer circle
    cv2.circle(patch, (cx, cy), radius, 40, border_thickness, cv2.LINE_AA)
    
    # Draw inner text label
    font = cv2.FONT_HERSHEY_SIMPLEX
    font_scale = 0.35 if len(label) == 1 else 0.28
    text_size, _ = cv2.getTextSize(label, font, font_scale, 1)
    tx = cx - text_size[0] // 2
    ty = cy + text_size[1] // 2
    cv2.putText(patch, label, (tx, ty), font, font_scale, 60, 1, cv2.LINE_AA)
    return patch

def generate_blank_sample(labels):
    label = random.choice(labels)
    r = random.randint(11, 13)
    patch = create_base_bubble_patch(radius=r, label=label)
    
    # Random brightness & noise
    brightness_shift = random.randint(-25, 0)
    noise = np.random.normal(0, random.uniform(1.0, 4.0), patch.shape).astype(np.int16)
    noisy_patch = np.clip(patch.astype(np.int16) + brightness_shift + noise, 0, 255).astype(np.uint8)
    return noisy_patch

def generate_filled_sample(labels):
    label = random.choice(labels)
    r = random.randint(11, 13)
    patch = create_base_bubble_patch(radius=r, label=label)
    cx, cy = 16, 16
    
    fill_type = random.choice(["solid", "spiral", "pencil", "dense_circle"])
    fill_radius = random.randint(r - 1, r + 2)
    fill_color = random.randint(15, 75)
    
    if fill_type == "solid":
        cv2.circle(patch, (cx, cy), fill_radius, fill_color, -1, cv2.LINE_AA)
    elif fill_type == "spiral":
        cv2.circle(patch, (cx, cy), fill_radius, fill_color, -1, cv2.LINE_AA)
        # Add slight spiral texture
        for rad in range(2, fill_radius, 2):
            cv2.circle(patch, (cx, cy), rad, fill_color + random.randint(-10, 15), 1, cv2.LINE_AA)
    elif fill_type == "pencil":
        # Uneven pencil fill
        mask = np.zeros(patch.shape, dtype=np.uint8)
        cv2.circle(mask, (cx, cy), fill_radius, 255, -1)
        pencil_noise = np.random.normal(fill_color + 20, 15, patch.shape).astype(np.uint8)
        patch = np.where(mask == 255, pencil_noise, patch)
    else:
        cv2.circle(patch, (cx, cy), fill_radius, fill_color, -1)
    
    # Slight blur to mimic pen ink absorption
    patch = cv2.GaussianBlur(patch, (3, 3), 0.5)
    return patch

def generate_erased_sample(labels):
    label = random.choice(labels)
    r = random.randint(11, 13)
    patch = create_base_bubble_patch(radius=r, label=label)
    cx, cy = 16, 16
    
    # First fill
    fill_mask = np.zeros(patch.shape, dtype=np.uint8)
    cv2.circle(fill_mask, (cx, cy), r, 255, -1)
    
    # Eraser leaves a hazy, medium gray smudge (150-205 intensity)
    smudge_val = random.randint(155, 205)
    smudge_noise = np.random.normal(smudge_val, random.uniform(8, 18), patch.shape).astype(np.uint8)
    
    # Blended erasure
    erased_patch = np.where(fill_mask == 255, (patch * 0.4 + smudge_noise * 0.6).astype(np.uint8), patch)
    
    # Rubber streak artifacts
    x1, y1 = random.randint(6, 12), random.randint(6, 12)
    x2, y2 = random.randint(20, 26), random.randint(20, 26)
    cv2.line(erased_patch, (x1, y1), (x2, y2), random.randint(160, 210), random.randint(2, 4), cv2.LINE_AA)
    
    return erased_patch

def generate_invalid_sample(labels):
    label = random.choice(labels)
    r = random.randint(11, 13)
    patch = create_base_bubble_patch(radius=r, label=label)
    cx, cy = 16, 16
    
    mark_type = random.choice(["tick", "cross", "dot", "scratch"])
    color = random.randint(20, 70)
    thickness = random.randint(2, 3)
    
    if mark_type == "tick":
        # Checkmark
        pts = np.array([[cx - 6, cy], [cx - 1, cy + 6], [cx + 8, cy - 7]], np.int32)
        cv2.polylines(patch, [pts], False, color, thickness, cv2.LINE_AA)
    elif mark_type == "cross":
        # X mark
        cv2.line(patch, (cx - 6, cy - 6), (cx + 6, cy + 6), color, thickness, cv2.LINE_AA)
        cv2.line(patch, (cx + 6, cy - 6), (cx - 6, cy + 6), color, thickness, cv2.LINE_AA)
    elif mark_type == "dot":
        # Small stray dot
        dx = random.randint(-4, 4)
        dy = random.randint(-4, 4)
        cv2.circle(patch, (cx + dx, cy + dy), random.randint(2, 4), color, -1, cv2.LINE_AA)
    else:
        # Scratch line
        cv2.line(patch, (cx - 8, cy + 2), (cx + 8, cy - 3), color, 2, cv2.LINE_AA)
        
    return patch

def generate_dataset(output_dir="services/omr-engine/dataset", samples_per_class=2500):
    labels = ["1", "2", "3", "4", "A", "B", "C", "D", "0", "5", "6", "7", "8", "9"]
    
    classes = {
        "0_blank": generate_blank_sample,
        "1_filled": generate_filled_sample,
        "2_erased_smudged": generate_erased_sample,
        "3_invalid_partial": generate_invalid_sample
    }
    
    for split in ["train", "test"]:
        count = int(samples_per_class * (0.8 if split == "train" else 0.2))
        for class_name, gen_fn in classes.items():
            class_dir = os.path.join(output_dir, split, class_name)
            os.makedirs(class_dir, exist_ok=True)
            
            for i in range(count):
                img = gen_fn(labels)
                img_path = os.path.join(class_dir, f"{class_name}_{i:05d}.png")
                cv2.imwrite(img_path, img)
            
            print(f"[+] Generated {count} samples for {split}/{class_name}")

if __name__ == "__main__":
    generate_dataset()
