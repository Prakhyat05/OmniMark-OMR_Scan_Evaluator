import cv2
import numpy as np

sample2_path = r"C:\Users\prakh\.gemini\antigravity-ide\brain\392984a1-a503-4623-8270-82e8602f1fbf\.user_uploaded\media_1788415714038.jpg"
img = cv2.imread(sample2_path)
gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)

# Let's check 10 completely blank questions in Col 5 (Q127..136):
# These are guaranteed 100% blank!
print("Scores for guaranteed BLANK questions (Col 5 Q127..136):")
for idx in range(10):
    q = 127 + idx
    y = int(140 + idx * 12.75)
    # 4 bubbles for Col 5: x ~ 480, 494, 508, 522
    scores = []
    for b in range(4):
        bx = int(478 + b * 14)
        roi = gray[y-4:y+5, bx-5:bx+6]
        min_v = np.min(roi)
        mean_v = np.mean(roi)
        scores.append(0.5 * min_v + 0.5 * mean_v)
    sorted_s = sorted(scores)
    gap = sorted_s[1] - sorted_s[0]
    print(f"Q{q}: scores={[round(s,1) for s in scores]} | min={round(min(scores),1)}, gap={round(gap,1)}")

# Now let's check 10 FILLED questions in Col 1 (Q1..10):
print("\nScores for guaranteed FILLED questions (Col 1 Q1..10):")
for idx in range(10):
    q = 1 + idx
    y = int(281 + idx * 12.75)
    scores = []
    for b in range(4):
        bx = int(152 + b * 14)
        roi = gray[y-4:y+5, bx-5:bx+6]
        min_v = np.min(roi)
        mean_v = np.mean(roi)
        scores.append(0.5 * min_v + 0.5 * mean_v)
    sorted_s = sorted(scores)
    gap = sorted_s[1] - sorted_s[0]
    print(f"Q{q}: scores={[round(s,1) for s in scores]} | min={round(min(scores),1)}, gap={round(gap,1)}")
