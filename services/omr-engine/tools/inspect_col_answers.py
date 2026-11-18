import cv2
import numpy as np

# Print Col 1 Q1..26 detected vs key
# Using our python script from test_final_ground_truth_eval.py
from test_final_ground_truth_eval import detected_answers, testing_key

print("Col 1 (Q1..26):")
for q in range(1, 27):
    print(f"  Q{q:2d}: detected={detected_answers[q]}, key={testing_key[q]}")

print("\nCol 2 (Q27..52):")
for q in range(27, 53):
    print(f"  Q{q:2d}: detected={detected_answers[q]}, key={testing_key[q]}")

print("\nCol 3 (Q53..89):")
for q in range(53, 90):
    print(f"  Q{q:2d}: detected={detected_answers[q]}, key={testing_key[q]}")

print("\nCol 4 (Q90..126):")
for q in range(90, 127):
    print(f"  Q{q:2d}: detected={detected_answers[q]}, key={testing_key[q]}")
