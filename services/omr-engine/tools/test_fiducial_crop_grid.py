import cv2
import numpy as np

sample2_path = r"C:\Users\prakh\.gemini\antigravity-ide\brain\392984a1-a503-4623-8270-82e8602f1fbf\.user_uploaded\media_1788415714038.jpg"
img = cv2.imread(sample2_path)
h, w = img.shape[:2]
gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)

# Let's test the fiducial detector on Sample 2
def detect_fiducial_columns(gray_img):
    img_h, img_w = gray_img.shape
    # Left strip: x < 0.25 * img_w
    left_strip = gray_img[:, :int(0.25 * img_w)]
    # Right strip: x > 0.75 * img_w
    right_strip = gray_img[:, int(0.75 * img_w):]
    
    # Threshold for dark blocks
    _, thresh_l = cv2.threshold(left_strip, 70, 255, cv2.THRESH_BINARY_INV)
    _, thresh_r = cv2.threshold(right_strip, 70, 255, cv2.THRESH_BINARY_INV)
    
    cnts_l, _ = cv2.findContours(thresh_l, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    cnts_r, _ = cv2.findContours(thresh_r, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    
    left_x = []
    for c in cnts_l:
        x, y, bw, bh = cv2.boundingRect(c)
        if 5 <= bw <= 25 and 5 <= bh <= 25 and 0.6 <= bw/bh <= 1.6:
            left_x.append(x + bw/2.0)
            
    right_x = []
    for c in cnts_r:
        x, y, bw, bh = cv2.boundingRect(c)
        if 5 <= bw <= 25 and 5 <= bh <= 25 and 0.6 <= bw/bh <= 1.6:
            right_x.append(int(0.75 * img_w) + x + bw/2.0)
            
    # Median is robust against outliers
    med_left_x = float(np.median(left_x)) if left_x else (0.155 * img_w)
    med_right_x = float(np.median(right_x)) if right_x else (0.855 * img_w)
    
    return med_left_x, med_right_x

x_left, x_right = detect_fiducial_columns(gray)
print(f"Detected Fiducials: x_left = {x_left:.1f} px, x_right = {x_right:.1f} px")
grid_w = x_right - x_left
print(f"Grid width = {grid_w:.1f} px (ratio to image = {grid_w/w:.4f})")

# Let's calculate the 6 column label X coordinates based on the detected fiducials:
# In Master PDF:
# Left fiducial = 84.06 pt, Right fiducial = 523.02 pt, width = 438.96 pt
# Col 1: 103.25 pt -> (103.25 - 84.06)/438.96 = 0.0437
# Col 2: 169.00 pt -> (169.00 - 84.06)/438.96 = 0.1935
# Col 3: 239.50 pt -> (239.50 - 84.06)/438.96 = 0.3541
# Col 4: 310.20 pt -> (310.20 - 84.06)/438.96 = 0.5152
# Col 5: 380.80 pt -> (380.80 - 84.06)/438.96 = 0.6760
# Col 6: 451.50 pt -> (451.50 - 84.06)/438.96 = 0.8371

col_ratios = [0.0437, 0.1935, 0.3541, 0.5152, 0.6760, 0.8371]
for idx, r in enumerate(col_ratios, 1):
    col_x = x_left + r * grid_w
    print(f"Col {idx}: label_x = {col_x:.1f} px (norm = {col_x/w:.4f})")
