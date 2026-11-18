import cv2
import numpy as np

sample2_path = r"C:\Users\prakh\.gemini\antigravity-ide\brain\392984a1-a503-4623-8270-82e8602f1fbf\.user_uploaded\media_1788415714038.jpg"
img = cv2.imread(sample2_path)
h, w = img.shape[:2]

# In sample 2 (Amar Singh), let's crop each row in Col 1 and save as individual images
# Let's find the exact Y position of Q1, Q2, Q8, Q10
# From our previous script:
# start_y = int(0.28906 * h) = 296
# row_pitch = int(0.01401 * h) = 14.34 px
# col1_left = int(0.12 * w) = 87
# col1_right = int(0.28 * w) = 204

rows_vis = []
for q in range(1, 16):
    cy = int(0.28906 * h + (q - 1) * 0.01401 * h)
    row_img = img[max(0, cy - 8):min(h, cy + 8), int(0.13 * w):int(0.28 * w)]
    # Resize for clear visibility
    row_large = cv2.resize(row_img, (row_img.shape[1] * 2, row_img.shape[0] * 2))
    cv2.putText(row_large, f"Row {q}", (5, 14), cv2.FONT_HERSHEY_SIMPLEX, 0.4, (0, 0, 255), 1)
    rows_vis.append(row_large)
    cv2.imwrite(f"q_{q:02d}_crop.jpg", row_large)

combined = np.vstack(rows_vis)
cv2.imwrite("col1_q1_q15_labeled_stack.jpg", combined)
print("Saved col1_q1_q15_labeled_stack.jpg")
