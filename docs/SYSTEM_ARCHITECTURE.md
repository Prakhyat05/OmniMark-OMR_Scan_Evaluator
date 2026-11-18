# System Architecture — OMR Scan, Evaluation & Parent Email Platform

## 1. Architecture Style

Use a **mobile client + managed backend platform + dedicated OMR processing service**.

This is a modular distributed system, but the MVP should avoid unnecessary microservices. Keep the business platform mostly within Supabase and isolate only the computationally heavy OMR service.

## 2. High-Level Architecture

```text
                         ┌──────────────────────────────┐
                         │          Flutter App         │
                         │                              │
                         │ Auth / Exams / Students     │
                         │ Camera / Upload / Review     │
                         │ Results / Email status       │
                         └──────────────┬───────────────┘
                                        │ HTTPS
                                        ▼
                 ┌───────────────────────────────────────────┐
                 │                Supabase                    │
                 │                                           │
                 │ Auth      Postgres       Storage          │
                 │  │           │              │             │
                 │  └───────────┼──────────────┘             │
                 │              │                            │
                 │        Edge Functions                     │
                 └──────────────┬───────────────┬────────────┘
                                │               │
                                │               │ Email API
                                │               ▼
                                │            Resend
                                │
                                ▼
                       ┌──────────────────┐
                       │   OMR Service    │
                       │ Python/FastAPI   │
                       │ OpenCV/NumPy     │
                       └────────┬─────────┘
                                │
                                ▼
                        Processing Queue
                                │
                                ▼
                          Worker Pool
```

## 3. Component Responsibilities

### Flutter Application

Responsible for:

- Authentication UI.
- Organization selection.
- Exam/student CRUD screens.
- Camera capture.
- Upload queue.
- Scan session state.
- Review UI.
- Results UI.
- Email delivery status.

The mobile app must not contain privileged backend credentials.

### Supabase Auth

Responsible for:

- User identity.
- Login.
- Session lifecycle.
- Email verification.
- Password reset.
- JWT issuance/refresh.

Supabase Auth uses JWTs and integrates authorization with Postgres policies. citeturn969800search5turn969800search11

### Supabase Postgres

System of record for:

- organizations.
- users/profiles.
- members.
- students.
- exams.
- answer keys.
- scan metadata.
- results.
- reports.
- email delivery status.
- audit logs.

### Supabase Storage

Stores:

- Original OMR images.
- Temporary processing copies.
- Generated PDFs.
- Organization logos.

Storage remains private and is accessed through controlled server-side operations or signed URLs. Supabase Storage supports access policies using Postgres RLS. citeturn969800search10

### Supabase Edge Functions

Use for:

- Secure email send orchestration.
- Signed report URL generation.
- Privileged result-finalization actions.
- Webhook processing from the email provider.
- Lightweight validation/orchestration.

Edge Functions are TypeScript/Deno server-side functions intended for short-lived requests and integrations. citeturn969800search6

### OMR Service

Responsible for computational image processing only:

- Image normalization.
- Sheet detection.
- Alignment.
- Bubble detection.
- Confidence calculation.
- QR/barcode detection.

The OMR service should not directly expose unrestricted database access.

## 4. Request Flows

### 4.1 Login

```text
Flutter
  -> Supabase Auth
  -> JWT/session
  -> Flutter stores session using Supabase SDK
```

### 4.2 Create Exam

```text
Flutter
  -> Supabase Data API
  -> RLS verifies membership
  -> Postgres creates exam
```

### 4.3 Scan Upload

```text
Camera/Gallery
  -> Flutter validates image
  -> Supabase Storage upload
  -> scan_page record created
  -> processing job queued
```

### 4.4 OMR Processing

```text
Processing job
  -> OMR API
  -> image fetched with short-lived authorized access
  -> OpenCV processing
  -> detection JSON
  -> application stores detection
  -> result evaluation
```

### 4.5 Review

```text
Needs Review
  -> Flutter loads scan + detection
  -> operator changes answer
  -> result event recorded
  -> result recalculated
```

### 4.6 Finalize + Email

```text
Finalize result
  -> server validates authorization
  -> result status = finalized
  -> report generated
  -> report saved privately
  -> Edge Function creates signed link
  -> Resend API sends email
  -> delivery status recorded
```

Supabase documents using Edge Functions with Resend for sending emails. citeturn969800search2

## 5. Trust Boundaries

### Boundary 1: Mobile Device

Assume the device can be compromised. Never trust local values for authorization.

### Boundary 2: Public APIs

All API requests must authenticate or use a narrow anonymous workflow only where explicitly designed.

### Boundary 3: OMR Service

Treat it as an internal service. It should only accept signed/authenticated processing requests.

### Boundary 4: Email Provider

Only the server knows the email provider API key.

## 6. Security Architecture

### Identity

`Supabase Auth -> JWT -> RLS + Edge Function authorization`

### Data

`Postgres + RLS + tenant-scoped records`

### Files

`Private Storage + signed URLs + storage policies`

### Secrets

`Supabase Secrets / deployment secret manager`

### Audit

`audit_logs + result_events + email_deliveries`

## 7. Multi-Tenant Model

The platform is multi-tenant.

Every institute is an organization. A user can belong to one or more organizations.

A user sees a row only if:

`organization_members.user_id = auth.uid()`

and

`organization_members.status = 'active'`

and

`organization_members.organization_id = row.organization_id`.

This tenant boundary must exist in RLS, not only in the Flutter UI.

## 8. Availability Strategy

MVP:

- Supabase managed availability.
- OMR service deployed in at least one managed region.
- Daily backups.
- Error monitoring.

Later:

- Two OMR service instances.
- Queue-based retry.
- Separate report worker.
- Disaster recovery runbook.

## 9. Failure Handling

### Upload Failure

- Keep local pending state.
- Retry with backoff.
- Do not duplicate scan records.

### OMR Failure

- Mark page failed.
- Keep original scan.
- Allow reprocess.
- Show diagnostic reason to operator.

### Report Failure

- Keep finalized result.
- Retry report generation.
- Do not change score because of report failure.

### Email Failure

- Keep finalized result and report.
- Record failure.
- Retry transient provider errors.
- Allow manual resend.

## 10. Observability

Track:

- mobile crash rate.
- upload success/failure.
- OMR processing latency.
- OMR review rate.
- result correction rate.
- report generation time.
- email send status.
- provider bounce rate.
- queue depth.
- function errors.

Use correlation IDs across:

`scan_job_id -> result_id -> report_id -> email_delivery_id`.

## 11. Architectural Decisions

### Decision A

Use Supabase because the core application is relational and tenant-based.

### Decision B

Keep OMR processing outside Supabase Edge Functions because it is CPU/image heavy.

### Decision C

Use email only for MVP to reduce notification complexity.

### Decision D

Keep original scans immutable so later audits can reconstruct the decision path.

### Decision E

Use server-side report/email processing to protect credentials and ensure consistent outputs.
