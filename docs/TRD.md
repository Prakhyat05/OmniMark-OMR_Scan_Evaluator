# TRD — Technical Requirements & Technology Decisions

## 1. Objective

Define the technology stack, technical constraints, integrations, performance goals, deployment strategy, and engineering rules for the OMR Scan, Evaluation & Parent Email Platform.

## 2. Recommended Stack

| Layer | Technology | Decision |
|---|---|---|
| Mobile | Flutter + Dart | Primary app framework |
| State management | Riverpod | Recommended for testability and explicit dependency management |
| Routing | go_router | Declarative routing + deep-link support |
| UI | Flutter Material 3 | Simple, accessible UI |
| Local persistence | Drift/SQLite or Hive for cache; secure storage for secrets/session adjuncts | Offline queue and temporary state |
| Camera | `camera` + image processing packages | OMR capture |
| Backend platform | Supabase | Auth, Postgres, Storage, Edge Functions |
| DB | PostgreSQL via Supabase | System of record |
| OMR engine | Python + OpenCV + NumPy | Image processing |
| OMR API | FastAPI | Thin service interface for OMR processing |
| Async processing | Redis + worker, or managed queue | Scale beyond simple synchronous processing |
| Email | Resend API through Supabase Edge Function | Transactional email |
| Reports | HTML/CSS -> PDF using a dedicated rendering service/library | Stable report output |
| Monitoring | Sentry + structured logs | App + function + OMR service monitoring |
| CI/CD | GitHub Actions | Test/build/deploy pipelines |
| Infrastructure | Supabase + managed container platform for OMR API | Low-ops initial deployment |

Supabase provides official Flutter support via `supabase_flutter`, and its Flutter client can interact with Postgres, invoke Edge Functions, authenticate users and work with storage. citeturn969800search0turn969800search4

## 3. Why Supabase

Supabase is a good fit when the application needs relational data, authentication, storage and a Flutter client in one platform. Its architecture integrates Auth with Postgres and supports row-level authorization through RLS. citeturn969800search3turn969800search5turn969800search8

Recommended use:

- Auth: Supabase Auth.
- Relational data: Supabase Postgres.
- Files: Supabase Storage.
- Small secure server operations: Supabase Edge Functions.
- Email orchestration: Edge Function calling Resend.
- OMR computation: separate Python service.

Do not place heavy OMR image-processing workloads inside Edge Functions. Edge Functions are designed for short-lived server-side logic; Supabase specifically recommends moving heavy long-running jobs to background workers. citeturn969800search6

## 4. Flutter Technical Requirements

### 4.1 Flutter Architecture

Use feature-first architecture with a clean separation between:

- Presentation.
- Application/state.
- Domain models/use cases.
- Data repositories/data sources.
- Infrastructure integrations.

Avoid direct Supabase calls from widgets.

### 4.2 State Management

Use Riverpod providers for:

- Authentication state.
- Current organization.
- Exam state.
- Scan session.
- Upload queue.
- Processing jobs.
- Review queue.
- Result details.
- Email status.

### 4.3 Networking

Use Supabase SDK for normal database/auth/storage operations. Use a typed HTTP client for the OMR API only when the API is not fronted by a Supabase Edge Function.

### 4.4 Local Capture

Camera workflow:

1. Open camera.
2. Guide user to place the sheet inside an on-screen frame.
3. Capture image.
4. Detect basic quality problems locally if feasible.
5. Ask user to retake if the sheet is too blurry/dark/poorly positioned.
6. Upload after confirmation.

### 4.5 Image Quality Rules

Target scan image characteristics:

- Prefer 300 DPI-equivalent image detail where possible.
- JPEG/PNG for image uploads.
- PDF input accepted when each page can be rendered reliably.
- Keep original image untouched in private storage.
- Generate a normalized processing copy separately.

Do not silently downscale to a size that harms bubble detection.

## 5. OMR Processing Service

### 5.1 API

FastAPI service with endpoints such as:

- `POST /v1/process-sheet`
- `POST /v1/process-batch`
- `GET /v1/health`
- `GET /v1/model/version`

### 5.2 Processing Pipeline

1. Validate input MIME type and size.
2. Decode image.
3. Detect page.
4. Detect registration markers.
5. Calculate homography/perspective correction.
6. Normalize image.
7. Detect template version.
8. Extract answer regions.
9. Measure fill density.
10. Classify each question as selected/empty/multiple/uncertain.
11. Read student/exam identity from configured region or QR/barcode.
12. Return structured detection results.
13. Persist processing metadata through the application backend.

### 5.3 Confidence

Each answer should return:

- selected option.
- confidence score.
- fill metrics.
- detection rule/version.
- review flag.

Never hide low confidence from the reviewer.

## 6. Evaluation Engine

The evaluation service accepts:

- Answer key version.
- Detection result.
- Scoring rules.

Outputs:

- total marks.
- correct.
- wrong.
- unattempted.
- section marks.
- percentage.
- ranking statistics where the exam is complete.

Evaluation must be deterministic and versioned.

## 7. Report Generation

Prefer generating reports on the server after result finalization.

Pipeline:

`Result Finalized -> HTML template -> PDF -> private storage -> signed access URL`

Use a stable report template version so that historical reports can be reproduced.

## 8. Email Architecture

The Flutter app must never contain:

- Resend API key.
- SMTP password.
- Service-role key.
- Supabase secret key.

Email must be triggered by authenticated server-side code.

Recommended flow:

`Flutter -> Edge Function -> authorize result -> create signed report URL -> call Resend -> record provider response -> audit log`

Supabase documents using Edge Functions with Resend for email sending and recommends keeping provider credentials in function secrets. citeturn969800search2turn969800search6

Supabase's default SMTP service is not intended for production transactional delivery; use a custom email provider for production. citeturn969800search7

## 9. Security Requirements

### 9.1 Authentication

- Email verification.
- Strong password policy.
- Password reset.
- Session expiration/refresh.
- Account deactivation support.
- Optional MFA in future phase.

### 9.2 Authorization

Every tenant-owned record must be scoped to `organization_id`.

Authorization is enforced by:

1. Supabase Auth identity.
2. Membership table.
3. RLS policies.
4. Server-side role validation for privileged actions.

### 9.3 RLS

All public/exposed tables must use RLS. Policies must be written for organization membership and role. Supabase recommends enabling RLS on exposed tables and granting only required privileges. citeturn969800search8turn969800search13

### 9.4 Storage Security

Store scans and reports in private buckets. Access should be controlled by Storage RLS/policies or signed URLs. Supabase Storage supports Postgres RLS-based access control. citeturn969800search10

### 9.5 Secrets

Secrets belong only in:

- Supabase Edge Function secrets.
- Deployment platform secret manager.
- Local `.env` files excluded from Git.

Never commit credentials.

### 9.6 Data Security

- HTTPS/TLS everywhere.
- Least privilege.
- Database backups.
- Audit logging.
- Secure file naming.
- Avoid public bucket URLs for report documents.
- Use random IDs/UUIDs.
- Never expose database primary keys as sequential business identifiers.

### 9.7 Abuse Controls

- Per-user and per-organization rate limiting.
- Upload size limits.
- MIME verification.
- PDF/image content validation.
- Email send quotas.
- Duplicate job protection.
- Idempotency keys.
- Brute-force protection through Supabase Auth configuration.

## 10. Technical Performance Targets

- App launch: target < 3 seconds on representative mid-range devices.
- Upload start: < 1 second after user confirms on normal network.
- Single-sheet server processing: target < 5 seconds excluding network under ordinary load.
- Report generation: target < 5 seconds.
- Email request initiation: target < 2 seconds after report creation.

These are engineering targets and require benchmarking.

## 11. Scalability

MVP design target:

- 100 organizations.
- 50,000 students.
- 250,000 exam attempts/month.
- Batch processing of at least 500 sheets per job.

Scale path:

1. Queue uploads.
2. Run multiple OMR workers.
3. Separate report workers.
4. Add managed Redis/queue.
5. Partition high-volume processing tables if required.

## 12. Environment Strategy

- `development`
- `staging`
- `production`

Each environment should have separate Supabase projects and separate email provider credentials where practical.

## 13. Testing Requirements

### Flutter

- Unit tests.
- Widget tests.
- Repository tests.
- Golden tests for critical report-related UI.
- Integration tests for login, scan, upload and review flow.

### Backend

- RLS policy tests.
- API tests.
- Edge Function tests.
- Email idempotency tests.

### OMR Engine

Maintain a versioned benchmark corpus containing:

- clean sheets.
- rotated sheets.
- low light.
- shadows.
- faint marks.
- erased marks.
- double marks.
- off-center photos.
- different phone cameras.

Every OMR engine release must pass this corpus before production deployment.

## 14. CI/CD

Pull request checks:

1. Flutter formatting.
2. Flutter analyzer.
3. Flutter tests.
4. TypeScript lint/test.
5. Python lint/test.
6. Database migration checks.
7. Security/static analysis.
8. Build verification.

Deployment:

- Staging on merge to `develop`.
- Production only from protected release branch/tag.
- Database migrations reviewed before deployment.

## 15. Technology Decision Summary

### Use Supabase

Yes, for this application, provided it is used for the workloads it handles well: Auth, Postgres, Storage, RLS, and short-lived Edge Functions.

### Do not use Supabase alone for OMR image processing

Keep heavy/CPU-intensive OMR processing in a dedicated Python service. This prevents the database/API platform from becoming coupled to computationally heavy image processing.

### Recommended production stack

`Flutter + Riverpod + Supabase Auth + Supabase Postgres + Supabase Storage + Supabase Edge Functions + Python FastAPI/OpenCV + Redis/Queue + Resend + Sentry + GitHub Actions`
