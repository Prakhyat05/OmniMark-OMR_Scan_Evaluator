"""Image normalization processor for OMR sheets with EXIF rotation handling and portrait enforcement."""
import io
import cv2
import numpy as np
from PIL import Image, ImageOps


def normalize_image(image_bytes: bytes) -> np.ndarray:
    """
    Decode raw image bytes, correct EXIF orientation tags from mobile cameras,
    enforce portrait layout (height >= width), and apply CLAHE contrast enhancement.
    """
    img = None

    # 1. Correct EXIF orientation from mobile phone cameras using PIL
    try:
        pil_img = Image.open(io.BytesIO(image_bytes))
        pil_img = ImageOps.exif_transpose(pil_img)
        img = cv2.cvtColor(np.array(pil_img.convert("RGB")), cv2.COLOR_RGB2BGR)
    except Exception:
        nparr = np.frombuffer(image_bytes, np.uint8)
        img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)

    if img is None:
        raise ValueError("Could not decode image from provided bytes.")

    # 2. Enforce Portrait Orientation (Height >= Width)
    h, w = img.shape[:2]
    if w > h:
        img = cv2.rotate(img, cv2.ROTATE_90_CLOCKWISE)

    # 3. Convert to Grayscale
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)

    # 4. Adaptive Contrast Normalization using CLAHE
    clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8, 8))
    enhanced = clahe.apply(gray)

    # 5. Gentle Gaussian blur to remove noise while preserving circle outlines
    blurred = cv2.GaussianBlur(enhanced, (3, 3), 0)

    return blurred
