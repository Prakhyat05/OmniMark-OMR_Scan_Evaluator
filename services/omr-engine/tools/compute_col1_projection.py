import cv2
import numpy as np

# Load Sample 2 (Amar Singh)
sample2_path = r"C:\Users\prakh\.gemini\antigravity-ide\brain\392984a1-a503-4623-8270-82e8602f1fbf\.user_uploaded\media_1788415714038.jpg"
img = cv2.imread(sample2_path)
h, w = img.shape[:2]
gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)

# Let's take the vertical projection in the lower half of the page (y = 0.30*h to 0.60*h)
# where Column 1 and Column 2 are active!
strip = gray[int(0.30*h):int(0.60*h), :]
# Dark pixels = (255 - pixel)
darkness = 255.0 - strip
proj = np.mean(darkness, axis=0) # shape (w,)

print(f"Horizontal profile across width {w} px:")
# In Col 1 region (x = 80 to 220 px):
# Let's print local peaks (maxima) in darkness:
for x in range(80, 220):
    val = proj[x]
    is_peak = (val > proj[x-1] and val > proj[x+1] and val > 15.0)
    if is_peak:
        print(f"  Dark Peak at x={x:3d} (x/w={x/w:.4f}) with darkness={val:.1f}")
