# OMR Sheet Geometry & Scanning Specification

## 1. Overview

This document contains the measured and inferred geometry of the supplied OMR answer sheet. It is intended to serve as a technical reference for an OMR scanning/evaluation model so that the template can be detected, aligned, and evaluated reliably.

> **Source image:** 1130 × 1599 pixels  
> **Assumed paper:** A4 (210 × 297 mm)  
> **Important:** Pixel measurements are directly based on the supplied image. Millimetre values are inferred from the A4 assumption. A production OMR system should primarily use normalized geometry after perspective correction rather than hard-code millimetre dimensions.

---

## 2. Overall OMR Structure

| Parameter | Value |
|---|---:|
| Image size | **1130 × 1599 px** |
| Assumed paper | **A4, 210 × 297 mm** |
| Effective resolution | **≈136.8 DPI** |
| Total questions | **200** |
| Answer choices per question | **4** |
| Total answer bubbles | **800** |
| Question columns | **6** |
| Overall layout | **3 horizontal blocks × 2 question columns** |

### Question-column mapping

| Column | Question range |
|---|---|
| C1 | Q1–Q26 |
| C2 | Q27–Q52 |
| C3 | Q53–Q89 |
| C4 | Q90–Q126 |
| C5 | Q127–Q163 |
| C6 | Q164–Q200 |

The sheet should **not** be treated as one uniform six-column matrix. It is better represented as three horizontal blocks:

```text
BLOCK 1                BLOCK 2                BLOCK 3
┌───────────────┐      ┌───────────────┐      ┌───────────────┐
│ Q1–26  Q27–52 │      │ Q53–89 Q90–126│      │Q127–163 Q164–200│
└───────────────┘      └───────────────┘      └───────────────┘
```

Each question contains:

```text
QUESTION NUMBER   ○1   ○2   ○3   ○4
```

---

## 3. Bubble Dimensions

### Outer bubble

Approximate measured dimensions:

- Bounding box: **≈19–20 px wide × 18–20 px high**
- Nominal diameter: **≈20 px**
- Assuming A4 scaling: **≈3.72 mm diameter**
- Nominal radius: **≈9.5–10 px**
- Physical radius: **≈1.8–1.9 mm**

Recommended detection tolerance at this resolution:

```text
Expected bubble diameter: ~20 px
Acceptable diameter range: ~18–22 px
```

Do not require an exact 19 × 19 or 20 × 20 pixel shape because rasterization, anti-aliasing, scan quality, and JPEG compression can change the apparent boundary by roughly one or more pixels.

---

## 4. Horizontal Distance Between the Four Option Bubbles

Approximate X-centres for the four response bubbles in each question column:

### C1 — Q1–26

```text
Option 1: 221.5 px
Option 2: 242.5 px
Option 3: 263.5 px
Option 4: 284.5 px
```

### C2 — Q27–52

```text
Option 1: 347.0 px
Option 2: 367.5 px
Option 3: 388.5 px
Option 4: 409.5 px
```

### C3 — Q53–89

```text
Option 1: 492.5 px
Option 2: 513.5 px
Option 3: 534.5 px
Option 4: 555.5 px
```

### C4 — Q90–126

```text
Option 1: 618.0 px
Option 2: 638.5 px
Option 3: 659.5 px
Option 4: 680.5 px
```

### C5 — Q127–163

```text
Option 1: 764.0 px
Option 2: 785.0 px
Option 3: 805.5 px
Option 4: 826.5 px
```

### C6 — Q164–200

```text
Option 1: 889.0 px
Option 2: 910.0 px
Option 3: 930.5 px
Option 4: 951.5 px
```

### Nominal option pitch

The horizontal center-to-center spacing is approximately:

- **20.5–21 px**
- **≈3.8–3.9 mm**

Recommended nominal value:

```text
horizontal option pitch ≈ 21 px
```

---

## 5. Distance Between Adjacent Bubbles

Because each bubble is approximately 19–20 px wide while the centre-to-centre pitch is approximately 21 px:

```text
Bubble diameter       ≈ 20 px
Center-to-center      ≈ 21 px
Clear gap             ≈ 1–2 px
```

Approximate physical values:

```text
Bubble diameter       ≈ 3.7 mm
Center-to-center      ≈ 3.9 mm
Gap                   ≈ 0.2–0.4 mm
```

This small gap is important. The system should **not depend solely on connected-component segmentation**, because adjacent circles may appear connected or distorted after printing and scanning.

---

## 6. Vertical Distance Between Successive Questions

Approximate Y-centres in a regular answer column:

```text
Q1 row:   ≈430 px
Q2 row:   ≈451 px
Q3 row:   ≈472 px
Q4 row:   ≈493 px
Q5 row:   ≈514 px
...
```

Nominal vertical pitch:

- **≈20.8–21.0 px**
- **≈3.87–3.90 mm**

Recommended template value:

```text
vertical question pitch ≈ 20.9 px
```

Use a tolerance instead of requiring an exact integer spacing.

---

## 7. Vertical Answer-Row Structure

### Columns C1 and C2

C1 and C2 each contain **26 questions**.

Approximate first answer-row centre:

```text
Y ≈ 430 px
```

Approximate last answer-row centre:

```text
Y ≈ 952 px
```

Conceptually:

```text
Q1  → y ≈ 430
Q2  → y ≈ 451
Q3  → y ≈ 472
...
Q26 → y ≈ 952
```

### Columns C3, C4, C5 and C6

C3–C6 each contain **37 questions**.

Approximate first answer-row centre:

```text
Y ≈ 201 px
```

Approximate last answer-row centre:

```text
Y ≈ 952 px
```

Conceptually:

```text
Q53/Q90/Q127/Q164 → y ≈ 201
Q54/Q91/Q128/Q165 → y ≈ 222
Q55/Q92/Q129/Q166 → y ≈ 243
...
Q89/Q126/Q163/Q200 → y ≈ 952
```

### Important template characteristic

```text
C1/C2:
    start lower because the digit/calibration grid occupies the upper-left region.

C3–C6:
    start much higher and contain 37 response rows.
```

Any model that assumes all six columns begin at the same Y coordinate will mis-map questions.

---

## 8. Distance Between the Six Question Columns

### A. First-bubble center positions

Approximate X-centres of the first bubble in each question column:

```text
C1 → 221.5 px
C2 → 347.0 px
C3 → 492.5 px
C4 → 618.0 px
C5 → 764.0 px
C6 → 889.0 px
```

Successive distances:

```text
C1 → C2 ≈ 125.5 px
C2 → C3 ≈ 145.5 px
C3 → C4 ≈ 125.5 px
C4 → C5 ≈ 146.0 px
C5 → C6 ≈ 125.0 px
```

Approximate physical equivalents:

```text
≈23.3 mm
≈27.0 mm
≈23.3 mm
≈27.1 mm
≈23.2 mm
```

---

## 9. Gap Between Adjacent Four-Bubble Groups

The distance from the final option bubble of one question column to the first option bubble of the next question column is approximately:

```text
C1 → C2 ≈ 62.5 px
C2 → C3 ≈ 83.0–83.5 px
C3 → C4 ≈ 62.5 px
C4 → C5 ≈ 83.5 px
C5 → C6 ≈ 62.5 px
```

Approximate physical values:

```text
≈11.6 mm
≈15.5 mm
≈11.6 mm
≈15.5 mm
≈11.6 mm
```

The alternating pattern corresponds to the three 2-column blocks.

---

## 10. Approximate Six-Column Group Centres

For coarse localization before individual bubble detection:

| Question column | Questions | Approx. bubble-group centre X |
|---|---|---:|
| C1 | 1–26 | **253 px** |
| C2 | 27–52 | **383 px** |
| C3 | 53–89 | **524 px** |
| C4 | 90–126 | **649 px** |
| C5 | 127–163 | **795 px** |
| C6 | 164–200 | **920 px** |

These values should be treated as initial estimates and refined using registration marks and local image geometry.

---

## 11. Registration / Timing Marks

The sheet includes repeated black reference/registration marks that are useful for page alignment.

Approximate vertical timing-marker tracks:

```text
X ≈ 159 px
X ≈ 451 px
X ≈ 722 px
X ≈ 993 px
```

These divide the page into three major horizontal blocks:

```text
Marker       Marker       Marker       Marker
  159          451          722          993
   │------------│------------│------------│
   │  Q1–52     │ Q53–126    │ Q127–200   │
```

Approximate horizontal spacing:

```text
159 → 451 ≈ 292 px
451 → 722 ≈ 271 px
722 → 993 ≈ 271 px
```

Approximate physical equivalents:

```text
≈54.2 mm
≈50.3 mm
≈50.3 mm
```

### Why these are important

These marks should be used for:

- Page registration
- Rotation correction
- Translation correction
- Perspective correction
- Horizontal scaling correction
- Vertical scaling verification
- Detection of the canonical template

They are generally more useful for alignment than relying only on the page boundary.

---

## 12. Timing-Marker Dimensions

Approximate black timing/reference marker dimensions:

```text
Width  ≈ 11–13 px
Height ≈ 12–14 px

Nominal:
≈12 × 12 px
```

Approximate physical size:

```text
≈2.2 × 2.2 mm
```

Vertical repetition is approximately:

```text
≈41.5–42 px
```

This is approximately every two answer rows and provides a useful scale reference.

---

## 13. Top Digit / Calibration Grid

The upper-left part of the page contains a digit grid rather than response bubbles.

### Grid structure

```text
10 rows: digits 0–9
6 columns
Total cells: 10 × 6 = 60
```

Approximate cell geometry:

```text
Cell size          ≈20 × 20 px
Center pitch       ≈21 px
```

This grid is intentionally similar in scale to the answer bubbles. The OMR system must explicitly classify it as a **digit/code calibration area** and not interpret its printed characters as response selections.

There is also a separate:

```text
6-digit code number
```

field above this grid.

---

## 14. Canonical Template Definition

A useful canonical configuration for the OMR model is:

```text
PAGE
Width  = 1130 px
Height = 1599 px
Paper  = A4

REGISTRATION
Vertical marker tracks:
X = [159, 451, 722, 993]

ANSWER STRUCTURE
Number of question columns = 6

Column mapping:
C1 = Q1–26
C2 = Q27–52
C3 = Q53–89
C4 = Q90–126
C5 = Q127–163
C6 = Q164–200

Each question:
4 answer bubbles
options = [1, 2, 3, 4]

BUBBLE
Nominal diameter = ~20 px
Nominal radius   = ~10 px
Expected outer bbox = ~18–22 px

HORIZONTAL OPTION PITCH
≈21 px

VERTICAL ROW PITCH
≈20.9 px

COLUMN BUBBLE X POSITIONS

C1 = [221.5, 242.5, 263.5, 284.5]
C2 = [347.0, 367.5, 388.5, 409.5]
C3 = [492.5, 513.5, 534.5, 555.5]
C4 = [618.0, 638.5, 659.5, 680.5]
C5 = [764.0, 785.0, 805.5, 826.5]
C6 = [889.0, 910.0, 930.5, 951.5]

VERTICAL POSITIONS

C1/C2:
first row ≈ 430 px
26 rows
pitch ≈ 20.9 px

C3/C4/C5/C6:
first row ≈ 201 px
37 rows
pitch ≈ 20.9 px

last row for all columns ≈ 952 px
```

---

## 15. Recommended OMR Scanning Algorithm

### Step 1 — Detect the page

Detect the complete A4 sheet and determine its four corners.

### Step 2 — Perspective correction

Transform the photographed/scanned sheet into the canonical **1130 × 1599** coordinate system.

Do not attempt bubble recognition on the raw camera image.

### Step 3 — Detect registration tracks

Locate the repeated black markers near:

```text
X ≈ 159
X ≈ 451
X ≈ 722
X ≈ 993
```

Use them to refine:

```text
translation
rotation
perspective
horizontal scaling
vertical scaling
```

### Step 4 — Locate the six question columns

Use the known X geometry to establish the six response groups.

### Step 5 — Generate expected bubble centres

Instead of independently detecting every bubble, calculate where each bubble should be located.

For example:

```text
Column C1:
x = [221.5, 242.5, 263.5, 284.5]

Question row 1:
y ≈ 430

Question row 2:
y ≈ 451

Question row 3:
y ≈ 472

...
```

This converts the problem from unconstrained object detection into template validation plus local fill detection.

### Step 6 — Use a local circular ROI

For every expected bubble:

```text
outer radius ≈ 10 px
inner scoring radius ≈ 7–8 px
```

Avoid using the full rectangular neighbourhood for the final fill decision.

### Step 7 — Do not use raw darkness alone

Every printed answer bubble already includes the option number:

```text
1
2
3
4
```

Therefore:

```text
dark pixels ≠ marked bubble
```

A useful approach is:

```text
fill_score =
    observed darkness inside response circle
    - expected darkness from the printed option number
```

An even stronger approach is template/background subtraction after geometric alignment.

### Step 8 — Score all four options

For every question:

```text
Option 1 score
Option 2 score
Option 3 score
Option 4 score
```

Then classify:

```text
none marked
    → unanswered

one clearly marked
    → selected

multiple strongly marked
    → multiple/invalid

scores too close / poor image quality
    → ambiguous / manual review
```

Never force an answer when confidence is low.

---

## 16. Recommended Detection Tolerances

For the supplied image resolution:

```text
Bubble diameter:
    nominal = 20 px
    acceptable = ~17–23 px

Horizontal option pitch:
    nominal = 21 px
    tolerance ≈ ±2 px

Vertical row pitch:
    nominal = 20.9 px
    tolerance ≈ ±2 px

Bubble centre localization:
    target ≈ ±2 px

Timing-marker localization:
    target ≈ ±2–3 px

Perspective/rotation:
    correct globally before response detection
```

For a production system, these should eventually be implemented as **scale-normalized tolerances** rather than fixed pixel tolerances.

---

## 17. Accuracy and Validation Strategy

Knowing the template dimensions alone cannot honestly guarantee 100% accuracy for every possible scan or photograph.

A safer production goal is:

> **100% template recognition where possible, extremely high-confidence bubble classification, and automatic rejection/manual review of ambiguous cases.**

Example of a confident question:

```text
Q17:
Option 1 = 0.02
Option 2 = 0.91
Option 3 = 0.04
Option 4 = 0.03

Result → Option 2
```

Example of an ambiguous question:

```text
Q17:
Option 1 = 0.44
Option 2 = 0.51
Option 3 = 0.03
Option 4 = 0.02

Result → AMBIGUOUS — DO NOT AUTO-MARK
```

This approach is much safer than forcing an answer for every image.

---

## 18. Highest-Priority Geometry Values

The most important template characteristics for the scanner are:

```text
1. Bubble diameter       ≈ 20 px
2. Option pitch          ≈ 21 px
3. Question row pitch    ≈ 20.9 px
4. Six question-column X configurations
5. Four registration-marker X positions
```

Full template structure:

```text
6 question columns
200 questions
4 options/question
800 total response bubbles

C1: Q1–26
C2: Q27–52
C3: Q53–89
C4: Q90–126
C5: Q127–163
C6: Q164–200

C1/C2 start at Y≈430
C3–C6 start at Y≈201
All columns finish at approximately Y≈952
```

---

## 19. Recommended Implementation Principle

The registration marks should be treated as the primary page-alignment reference.

The intended pipeline is:

```text
Raw image
   ↓
Page detection
   ↓
Perspective correction
   ↓
Registration-marker detection
   ↓
Template alignment/refinement
   ↓
Six question-column localization
   ↓
Expected bubble-coordinate generation
   ↓
Local bubble verification
   ↓
Fill/ink scoring
   ↓
Four-option confidence scoring
   ↓
Answer classification
   ↓
Ambiguous-case detection
   ↓
Final OMR result
```

This is preferable to trying to discover every response bubble independently from the image.

---

## 20. Final Technical Summary

```text
SOURCE IMAGE
1130 × 1599 px
A4 layout

QUESTIONS
200

OPTIONS
4 per question

TOTAL RESPONSE BUBBLES
800

QUESTION COLUMNS
6

COLUMN MAPPING
C1 = Q1–26
C2 = Q27–52
C3 = Q53–89
C4 = Q90–126
C5 = Q127–163
C6 = Q164–200

BUBBLE
≈20 px diameter
≈10 px radius

OPTION PITCH
≈21 px

QUESTION ROW PITCH
≈20.9 px

FIRST RESPONSE Y
C1/C2 ≈430 px
C3–C6 ≈201 px

FINAL RESPONSE Y
≈952 px

REGISTRATION X TRACKS
≈159 px
≈451 px
≈722 px
≈993 px

TIMING MARK
≈12 × 12 px

TIMING-MARK VERTICAL PITCH
≈41.5–42 px

UPPER DIGIT GRID
10 × 6 cells
60 cells total
≈20 × 20 px cells
≈21 px centre pitch
```

> **Production note:** The above values are measured from the provided raster image and should be used as a canonical reference. For arbitrary scans, first estimate the transformation to canonical coordinates using page corners and/or registration marks, then evaluate responses in the corrected coordinate system.
