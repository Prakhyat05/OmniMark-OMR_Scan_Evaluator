import cv2
import numpy as np

sample_paths = [
    (r"C:\Users\prakh\.gemini\antigravity-ide\brain\392984a1-a503-4623-8270-82e8602f1fbf\.user_uploaded\media_1788415707484.jpg", "Vedehi 224567"),
    (r"C:\Users\prakh\.gemini\antigravity-ide\brain\392984a1-a503-4623-8270-82e8602f1fbf\.user_uploaded\media_1788415714038.jpg", "Amar 342105"),
    (r"C:\Users\prakh\.gemini\antigravity-ide\brain\392984a1-a503-4623-8270-82e8602f1fbf\.user_uploaded\media_1788415720046.jpg", "Vaibhav 134767"),
]

for idx, (p, label) in enumerate(sample_paths):
    img = cv2.imread(p)
    h, w = img.shape[:2]
    # Crop the student code region
    # x: 0.14..0.30, y: 0.08..0.28
    crop = img[int(0.06*h):int(0.28*h), int(0.14*w):int(0.30*w)]
    cv2.imwrite(f"code_crop_sample_{idx+1}.jpg", crop)
    print(f"Saved code_crop_sample_{idx+1}.jpg ({label})")
