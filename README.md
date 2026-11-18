# OmniMark — Mobile OMR Scanner, Automated Evaluation & Cloud Analytics Platform

[![Flutter Tests](https://img.shields.io/badge/Flutter%20Tests-36%2F36%20Passed-brightgreen.svg?style=flat-square)](apps/mobile/test)
[![Python Tests](https://img.shields.io/badge/Pytest-17%2F17%20Passed-brightgreen.svg?style=flat-square)](services/omr-engine/tests)
[![Architecture](https://img.shields.io/badge/Architecture-100%25%20On--Device%20Offline%20Hybrid%20CV-blue.svg?style=flat-square)](docs/SYSTEM_ARCHITECTURE.md)
[![Template](https://img.shields.io/badge/Template-Universal%20200Q%20Standard-orange.svg?style=flat-square)](docs/OMR_Sheet_Geometry_and_Scanning_Specification.md)
[![License](https://img.shields.io/badge/License-MIT-green.svg?style=flat-square)](#license)

A high-precision, mobile-first **Optical Mark Recognition (OMR)** scanning, instant evaluation, report card generation, and automated cloud communication platform.

Engineered specifically for educational institutions, academies, and examination boards, the platform provides **100% on-device offline evaluation** in pure Dart (< 35 ms per sheet), backed by a Python FastAPI microservice for template calibration and PyTorch Micro-CNN training, with automated cloud synchronization and transactional email dispatch via Supabase and Resend.

---

## About The Project

Traditional OMR assessment workflows rely heavily on dedicated, expensive optical scanning machines (\$3,000–\$10,000+) and proprietary pre-printed forms. For schools, competitive coaching academies, and independent tutors, this creates high operational costs, logistical delays, and hours of tedious manual grading.

**OmniMark** was built to modernize and democratize exam evaluation:
- **Zero Expensive Hardware**: Turns any standard Android or iOS smartphone into an industrial-grade OMR reader.
- **100% On-Device Offline Autonomy**: Evaluates answer sheets in under **35 milliseconds** with zero server roundtrips, allowing teachers to grade full classrooms in minutes even in areas with zero internet connectivity.
- **Dynamic Exam Slicing**: Uses a standardized Universal 200-Question A4 format that dynamically adapts to 25, 50, 75, 100, or 200 questions without needing custom sheet designs for every exam.
- **Subpixel Ink Precision**: Combines mathematical image convolution, Otsu gradient thresholding, and a lightweight PyTorch Micro-CNN to distinguish confident ballpoint pen fills from light erasures, paper grain, and smudges.
- **Automated Parent Communication**: Automatically compiles official A4 PDF student report cards (with ranks, percentiles, and question-level breakdowns) and queues them for delivery to parents via Supabase Edge Functions and Resend.

---

## Table of Contents

1. [About The Project](#about-the-project)
2. [Key Highlights & Architecture](#key-highlights--architecture)
3. [Monorepo Directory Structure](#monorepo-directory-structure)
4. [Core Components](#core-components)
   - [Mobile Application (`apps/mobile`)](#1-mobile-application-appsmobile)
   - [OMR Processing Engine (`services/omr-engine`)](#2-omr-processing-engine-servicesomr-engine)
   - [Cloud Backend & Edge Functions (`supabase`)](#3-cloud-backend--edge-functions-supabase)
5. [OMR Computer Vision & ML Pipeline](#omr-computer-vision--ml-pipeline)
6. [Getting Started & Local Setup](#getting-started--local-setup)
   - [Flutter Mobile App](#flutter-mobile-app)
   - [Python OMR Engine](#python-omr-engine)
   - [Docker Deployment](#docker-deployment)
   - [Supabase Setup](#supabase-setup)
7. [Testing & Verification](#testing--verification)
8. [Environment Configuration](#environment-configuration)
9. [Documentation Links](#documentation-links)
10. [License](#license)

---

## Key Highlights & Architecture

```text
┌─────────────────────────────────────────────────────────────────────────────────┐
│                           ON-DEVICE MOBILE WORKFLOW                             │
│                                                                                 │
│   [Camera / Gallery] ──► [Fiducial Warp & Auto-Scale] ──► [Label Anchor Search]  │
│                                                                 │               │
│   [Outbox Sync Worker] ◄── [Local SQLite DB] ◄── [Instant Score] ◄── [Bubble CV]│
│            │                                                                    │
└────────────┼────────────────────────────────────────────────────────────────────┘
             ▼ (When Online)
┌─────────────────────────────────────────────────────────────────────────────────┐
│                           SUPABASE & CLOUD BACKEND                              │
│                                                                                 │
│   [Supabase Auth] ──► [PostgreSQL + RLS] ──► [Edge Functions] ──► [Resend Email]│
│                                                                                 │
└─────────────────────────────────────────────────────────────────────────────────┘
```

- **100% On-Device Offline Processing**: The primary evaluation pipeline runs completely inside the mobile application using pure Dart image processing and mathematical convolutions. Zero server roundtrips required for grading.
- **Universal 200Q Master Sheet Standardization**: Standardized on a 200-question universal A4 format with dynamic $1..N$ question slicing (e.g. 25, 50, 75, 100, or 200 questions).
- **Sub-50ms Processing Latency**: Full sheet perspective warp, 6-digit student code recognition, and 200-bubble evaluation executes in **~35 ms** on modern mobile hardware.
- **Question-Label Anchored Detection**: Eliminates cumulative geometric drift and option misclassification by locating each printed question number label on the physical column before sampling adjacent bubbles.
- **Intermediate Timing-Mark Isolation**: Specifically engineered algorithms isolate internal black timing blocks (found on rows 63, 65, 67, 69, etc.), locking horizontal alignment to the true column vector.
- **False Multiple-Mark Elimination**: Dual-engine statistical gradient analysis separates real carbon/ballpoint pen ink (< 110 intensity) from paper fibers or light print artifacts (> 135 intensity).
- **Clean-Dot Visualization Overlay**: Centered, high-contrast colored indicators with subtle halos show marked bubbles and correct answer rings without obscuring printed question text.
- **Transactional Offline Outbox**: Scan results and report cards are saved immediately to local SQLite (`sqflite`). When internet connectivity is detected, pending reports sync automatically with Supabase.

---

## Monorepo Directory Structure

The repository is organized into a clean, modular monorepo layout:

```text
omr-platform/
│
├── README.md                           # Primary technical manual (this document)
├── docker-compose.yml                  # Docker orchestration for OMR engine microservice
├── .env.example                        # Blueprint environment variables
├── .gitignore                          # Git ignore specification
├── .editorconfig                       # Workspace formatting rules
│
├── docs/                               # Central architectural & technical specifications
│   ├── PRD.md                          # Product Requirements Document
│   ├── TRD.md                          # Technical Requirements Document
│   ├── SYSTEM_ARCHITECTURE.md          # Architecture overview & data flow diagrams
│   ├── SYSTEM_DESIGN.md                # Processing state machines & security specifications
│   ├── DATABASE_SCHEMA.md              # Relational database schema & RLS policies
│   ├── FOLDER_STRUCTURE.md             # Monorepo organizational guidelines
│   ├── TASK_PROGRESS.md                # 12-Phase development & calibration history
│   ├── MASTER_TEST_PLAN.md             # Automated test matrix & specifications
│   └── OMR_Sheet_Geometry_and_Scanning_Specification.md  # Physical sheet geometry spec
│
├── apps/
│   └── mobile/                         # Flutter Mobile Application (iOS & Android)
│       ├── lib/
│       │   ├── main.dart               # Flutter application entrypoint
│       │   ├── app/                    # Routing, theme tokens, navigation scaffolding
│       │   ├── core/                   # On-device OMR engine, SQLite, sync, PDF generator
│       │   └── features/               # 11 UI modules (Auth, Exams, Scan, Review, etc.)
│       ├── assets/                     # Icons, app images, PyTorch models, sample scans
│       ├── test/                       # Automated unit and widget tests (100% pass)
│       └── pubspec.yaml                # Flutter dependencies & metadata
│
├── services/
│   └── omr-engine/                     # Python 3.10+ FastAPI OMR Microservice
│       ├── app/
│       │   ├── main.py                 # FastAPI microservice entrypoint
│       │   ├── api/                    # REST routes (/v1/health, /v1/process, etc.)
│       │   ├── core/                   # Pydantic schemas & built-in template definitions
│       │   └── processors/             # OpenCV pipeline (homography, bubbles, student code)
│       ├── assets/                     # Master sheet templates, vector blueprints, models
│       │   └── fixtures/               # Isolated test fixtures
│       ├── tools/                      # PyTorch training harness, dataset generator, calibration
│       ├── tests/                      # Pytest unit & integration test suite (100% pass)
│       ├── Dockerfile                  # Container definition
│       └── pyproject.toml              # Python project metadata & dependencies
│
└── supabase/                           # Cloud Backend & Database Configurations
    ├── config.toml                     # Supabase CLI configuration
    ├── seed.sql                        # Demonstration institutions, teachers, and exams
    ├── migrations/                     # 10 incremental SQL database migrations
    └── functions/                      # Deno TypeScript Edge Functions (Email, Ranks, Links)
```

---

## Core Components

### 1. Mobile Application (`apps/mobile`)

Built with **Flutter 3.x**, **Dart 3**, and **Riverpod**, the mobile client handles the complete teacher workflow:
- **Scan Camera Viewfinder**: Real-time laser guide, flash toggle, and photo capture/upload.
- **On-Device Engine (`core/omr`)**: Pure Dart implementation of fiducial detection, subpixel bubble sampling, dynamic question slicing, and instant scoring.
- **Local SQLite Database (`core/database`)**: Offline relational storage for exams, rosters, answer keys, scan results, and queued emails.
- **PDF Report Card Generator (`core/report`)**: Produces official A4 student report cards with performance badges, rank, percentile, and question matrix.
- **11 Feature Modules**:
  - `auth`: Splash, onboarding, credentials, password recovery.
  - `dashboard`: Quick actions, statistics, active exam feeds.
  - `exams`: Exam creation with dynamic $1..N$ question count and scoring presets (+4/-1, +1/0, +2/-0.5).
  - `answer_keys`: 1-Tap camera scan answer key setup & manual 1, 2, 3, 4 matrix editor.
  - `scan`: High-speed camera scanner with instant bottom-sheet score preview.
  - `review`: Teacher review queue for ambiguous or multiple-marked answers.
  - `results`: Exam analytics, class score distribution, student score breakdowns.
  - `reports`: Interactive A4 PDF report card preview, sharing, and printing.
  - `email_delivery`: Automated dispatch, delivery history, bounce audit trail.
  - `students`: Roster management, student enrollment, historical academic trends.
  - `settings`: Institutional branding, grading scales, account settings.

### 2. OMR Processing Engine (`services/omr-engine`)

A **Python 3.10+ FastAPI** service utilized for heavy template calibration, dataset synthesis, and cloud-based sheet evaluation:
- **Endpoints**:
  - `GET /v1/health`: Health status and uptime telemetry.
  - `GET /v1/templates`: Lists built-in pre-calibrated templates (`universal-200-q-v1`, `standard-100-q-v1`, etc.).
  - `POST /v1/process`: End-to-end sheet image processing, student code extraction, bubble detection, and visual overlay generation.
  - `POST /v1/analyze-template`: Analyzes blank sheet templates to deduce coordinates automatically.
  - `POST /v1/evaluate`: Deterministic grading of detected answers against an answer key.
- **PyTorch Micro-CNN Pipeline (`tools/train_micro_cnn.py`)**:
  - Compact CNN (< 100 KB, ~25k parameters) trained on 10,000 augmented $32 \times 32$ bubble crops.
  - Achieves **99.95% accuracy** across 4 bubble states: `0_blank`, `1_filled`, `2_erased_smudged`, `3_invalid_partial`.

### 3. Cloud Backend & Edge Functions (`supabase`)

- **PostgreSQL Database**:
  - 10 migration files establish multi-tenant schema with strict Row Level Security (RLS).
  - Tables: `profiles`, `organizations`, `students`, `exams`, `scans`, `results`, `marked_answers`, `email_outbox`.
- **Deno Edge Functions**:
  - `send-report-email`: Formats and sends branded student report cards via Resend API.
  - `finalize-result`: Calculates exam percentiles, class ranks, and locks result records.
  - `create-report-link`: Generates signed, time-limited URLs for parent report card access.
  - `email-webhook`: Ingests delivery, open, and bounce webhooks to maintain an audit trail.

---

## OMR Computer Vision & ML Pipeline

The on-device offline scanning pipeline operates through five sequential stages:

```text
[Captured Image]
       │
       ▼
1. Fiducial Discovery & Auto-Grid Scaling
   - Detects outer black square fiducial markers (x < 0.18 and x > 0.82)
   - Computes sheet scaling ratio and performs perspective warp
       │
       ▼
2. 6-Digit Student Code Recognition
   - Crops identity grid (6 columns × 10 rows: digits 0..9)
   - Samples bubble centers and resolves marked student identity
       │
       ▼
3. Question-Label Anchored Parallel Bubble Sampling
   - Locates exact printed question numbers along the vertical column line
   - Isolates internal timing marks on odd rows (e.g. Q63, Q65, Q67, Q69)
   - Samples 4 candidate bubbles (1, 2, 3, 4) at exact physical horizontal offsets
       │
       ▼
4. Dual-Engine Classification & Intensity Thresholding
   - Evaluates core density vs outer ring luminance
   - Compares pen ink (< 110) vs paper background (> 135)
   - Flags multiple marks or low-confidence smudges for teacher review
       │
       ▼
5. Instant Offline Evaluation & Overlay Generation
   - Evaluates marks against the active answer key (+correct, -negative, 0 unattempted)
   - Renders non-overlapping clean-dot visualization overlay with halos
```

---

## Getting Started & Local Setup

### Prerequisites
- **Flutter SDK**: `>= 3.2.0`
- **Dart SDK**: `>= 3.2.0`
- **Python**: `>= 3.10`
- **Docker & Docker Compose** (optional, for microservice containerization)
- **Supabase CLI** (optional, for local database & edge function development)

---

### Flutter Mobile App

1. Navigate to the mobile app directory:
   ```bash
   cd apps/mobile
   ```

2. Fetch Flutter package dependencies:
   ```bash
   flutter pub get
   ```

3. Run the automated test suite:
   ```bash
   flutter test
   ```

4. Launch the application on a connected device or emulator:
   ```bash
   flutter run
   ```

5. Build a standalone release APK:
   ```bash
   flutter build apk --release
   ```
   *(Compiled binary is output to `build/app/outputs/flutter-apk/app-release.apk`)*

---

### Python OMR Engine

1. Navigate to the OMR engine directory:
   ```bash
   cd services/omr-engine
   ```

2. Create and activate a Python virtual environment:
   ```bash
   python -m venv .venv
   # Windows:
   .venv\Scripts\activate
   # Linux/macOS:
   source .venv/bin/activate
   ```

3. Install dependencies:
   ```bash
   pip install -e .
   pip install pytest httpx
   ```

4. Run the automated test suite:
   ```bash
   pytest tests
   ```

5. Start the FastAPI development server:
   ```bash
   uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
   ```
   Interactive OpenAPI documentation will be available at: `http://localhost:8000/docs`.

---

### Docker Deployment

To launch the Python OMR Engine microservice using Docker:

```bash
docker-compose up --build -d
```

Check service health:
```bash
curl http://localhost:8000/v1/health
```

---

### Supabase Setup

1. Initialize and start local Supabase containers:
   ```bash
   supabase start
   ```

2. Apply database migrations and seed data:
   ```bash
   supabase db reset
   ```

3. Test Deno edge functions locally:
   ```bash
   supabase functions serve send-report-email --env-file .env
   ```

---

## Testing & Verification

The repository enforces strict test suites across both the Flutter client and the Python microservice:

### Flutter Test Suite (`apps/mobile`)
Execute with:
```bash
cd apps/mobile && flutter test
```
- **Total Tests**: 36 passed
- **Pass Rate**: 100%
- **Coverage**:
  - `universal_200q_template` & `omr_core_test.dart`: Master template geometry and dynamic question slicer tests.
  - `local_database_test.dart`: SQLite CRUD operations for exams, answer keys, results, and outbox.
  - `offline_scan_engine_test.dart`: Full offline evaluation of real student sheets.
  - `perspective_transformer_test.dart`: Fiducial corner discovery and homography warp.
  - `adaptive_threshold_test.dart`: Otsu thresholding, core-vs-ring density, and smudge separation.
  - `camera_quality_analyzer_test.dart`: Lighting, glare, blur, and skew detection.
  - `pdf_report_generator_test.dart`: Validates A4 report card PDF byte streams.
  - `evaluation_test.dart`: Scoring rules, negative marking, bonus, and dropped questions.
  - `widget_test.dart`: Application mount and navigation smoke test.

### Python Test Suite (`services/omr-engine`)
Execute with:
```bash
pytest services/omr-engine/tests
```
- **Total Tests**: 17 passed
- **Pass Rate**: 100%
- **Coverage**:
  - FastAPI health check & model version telemetry.
  - Built-in template schema validation (`universal-200-q-v1`, `neet-200-q-v1`, etc.).
  - Corner fiducial detection and homography alignment.
  - Full pipeline evaluation of sample scans with ground-truth answer keys.
  - Backward compatibility with community OMRChecker templates.

---

## Environment Configuration

Copy `.env.example` to `.env` in your deployment environment:

```env
# Supabase Configuration
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_PUBLISHABLE_KEY=your-publishable-key
SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key-do-not-expose

# Email Dispatch (Resend)
RESEND_API_KEY=re_your_resend_api_key
RESEND_FROM_EMAIL=reports@yourinstitution.edu

# Python OMR Service
OMR_SERVICE_URL=http://localhost:8000
OMR_SERVICE_API_KEY=local-omr-secret-key-32chars-min

# Monitoring & Logging
SENTRY_DSN=
ENVIRONMENT=development
LOG_LEVEL=info
```

---

## Documentation Links

For detailed architectural, database, and scanning specifications, consult the documents in the `docs/` folder:

- [Product Requirements Document (PRD)](docs/PRD.md) — Product vision, personas, and feature milestones.
- [Technical Requirements Document (TRD)](docs/TRD.md) — Architecture requirements, security, and SLAs.
- [System Architecture](docs/SYSTEM_ARCHITECTURE.md) — Monorepo services, data flows, and sync boundaries.
- [System Design](docs/SYSTEM_DESIGN.md) — State machines, processing stages, and security models.
- [Database Schema & RLS](docs/DATABASE_SCHEMA.md) — Complete relational schema, indexes, and RLS policies.
- [Sheet Geometry & Scanning Specification](docs/OMR_Sheet_Geometry_and_Scanning_Specification.md) — Blueprint coordinates for the Universal 200Q format.
- [Task Progress Tracker](docs/TASK_PROGRESS.md) — Historical breakdown of completed implementation phases.
- [Master Test Plan](docs/MASTER_TEST_PLAN.md) — Regression test matrix and verification criteria.

---

## License

This project is open-source and available under the terms of the MIT License.
