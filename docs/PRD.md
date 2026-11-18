# PRD — OMR Scan, Evaluation & Parent Email Platform

## 1. Document Information

- Product: OMR Scan, Evaluation & Parent Email Platform
- Version: 1.0
- Status: Production-oriented MVP specification
- Primary client: Flutter mobile application
- Primary backend platform: Supabase
- OMR processing: Python + FastAPI + OpenCV service
- Parent communication: Email only

## 2. Product Vision

Build a simple mobile-first application that allows a school, coaching institute, teacher, test center, or stationery operator to:

1. Create an exam.
2. Add or import students and parent email addresses.
3. Configure an OMR answer key.
4. Scan OMR sheets using the phone camera or upload existing images/PDF pages.
5. Automatically read marked answers.
6. Evaluate the sheets against the answer key.
7. Generate a student report card.
8. Email the report card to the student's parent automatically.
9. Review and correct ambiguous scans before finalizing results.
10. Search results and resend reports later.

The product is intentionally email-first. SMS/WhatsApp are out of scope for the first release.

## 3. Problem Statement

Small schools and coaching centers often use paper-based tests because printing and classroom administration are inexpensive. Manual checking is slow, error-prone, and provides no automatic parent communication. Dedicated OMR machines can be expensive and restrictive.

The product solves this by making the phone a low-cost OMR capture device and moving the heavy processing, evaluation, reporting, and email delivery to secure backend services.

## 4. Target Users

### 4.1 Institute Admin

Creates exams, manages students, imports data, configures answer keys, reviews results and controls staff access.

### 4.2 Teacher

Creates/uses exams, scans sheets, reviews exceptions and views student performance.

### 4.3 Scan Operator / Stationery Operator

Primarily captures or uploads OMR sheets and monitors processing status. The operator should not automatically gain access to unrelated institute data.

### 4.4 Parent

Does not need the mobile app. Receives a secure report link or PDF by email.

## 5. Goals

- Make OMR checking possible without a dedicated OMR machine.
- Keep the mobile workflow understandable to non-technical staff.
- Achieve reliable answer recognition on controlled OMR templates.
- Generate results quickly after scanning.
- Automatically email reports after approval/finalization.
- Prevent one institute from accessing another institute's data.
- Maintain an audit trail for result changes and report delivery.

## 6. Non-Goals for MVP

- SMS, WhatsApp, push notifications to parents.
- Live online examination.
- AI essay checking.
- Full learning-management system.
- Advanced predictive analytics.
- Desktop-native scanning integrations.
- Arbitrary handwritten answer recognition.

## 7. Core User Journey

1. Sign in.
2. Select/create institute workspace.
3. Create exam.
4. Add/import students.
5. Create or import answer key.
6. Start scan session.
7. Choose `Camera Scan` or `Upload`.
8. Capture/upload one or multiple sheets.
9. App uploads encrypted HTTPS requests to backend storage.
10. Processing service identifies sheet, aligns it, reads bubbles, and returns confidence per answer.
11. Result engine calculates marks.
12. High-confidence results are prepared automatically; low-confidence results go to `Needs Review`.
13. Operator reviews exceptions.
14. Authorized user finalizes result.
15. Report PDF is generated.
16. Secure report link is created.
17. Email service sends report to parent.
18. Delivery status is stored.

## 8. Functional Requirements

### FR-01 Authentication

- Email/password sign in.
- Email verification.
- Password reset.
- Session persistence.
- Logout from current device.
- User profile.
- Organization/workspace membership.
- Roles: owner, admin, teacher, operator.

### FR-02 Organization Management

- Create organization.
- Edit organization profile.
- Invite staff.
- Assign role.
- Deactivate membership.
- Prevent inactive members from using tenant resources.

### FR-03 Student Management

- Create student.
- Edit student.
- Archive student.
- Assign student to class/batch.
- Store parent/guardian name.
- Store parent email.
- Validate email format.
- Import CSV.
- Export student list.
- Prevent duplicate student IDs within an organization.

### FR-04 Exam Management

- Create/edit/archive exam.
- Exam title, subject, date, duration, total questions.
- Positive marks per question.
- Negative marks per question.
- Sections.
- OMR template selection/version.
- Exam status: draft, published, processing, completed, archived.

### FR-05 Answer Key

- Manual entry.
- Bulk import.
- Support A/B/C/D/E.
- Optional multiple correct answers if configured.
- Per-question marks.
- Negative marks.
- Bonus/drop question support.
- Lock answer key after processing starts unless authorized override is used.

### FR-06 OMR Template

- Template name/version.
- Page size.
- Number of questions.
- Bubble geometry.
- Registration markers.
- Student-ID regions.
- QR/barcode region if used.
- Minimum/maximum bubble fill threshold.
- Image alignment parameters.

### FR-07 Scan / Upload

- Camera capture one sheet at a time.
- Multi-image upload from gallery/files.
- PDF upload.
- Crop and retake before upload.
- Local preview.
- Batch upload progress.
- Retry failed uploads.
- Offline queue for files captured without immediate connectivity, with secure local temporary storage.

### FR-08 OMR Processing

- Sheet detection.
- Page alignment.
- Rotation correction.
- Perspective correction.
- Registration marker detection.
- Student/exam identification.
- Bubble detection.
- Multi-mark detection.
- Uncertain mark detection.
- OCR/QR decoding where configured.
- Confidence score.
- Processing status and error reason.

### FR-09 Result Evaluation

- Compare detected answers with answer key.
- Calculate total marks.
- Correct/wrong/unattempted count.
- Section-wise score.
- Percentage.
- Rank when requested.
- Class average.
- Optional percentile.
- Support manual correction before finalization.

### FR-10 Review Queue

A result enters `Needs Review` when any critical condition occurs, including:

- Multiple bubbles detected.
- Confidence below configured threshold.
- Student ID cannot be resolved.
- Template not recognized.
- Required page missing.
- QR/barcode unreadable when required.

Review UI must show the original scan and the interpreted answers side-by-side.

### FR-11 Report Generation

Each finalized result generates a branded report containing:

- Institute name/logo.
- Exam details.
- Student details.
- Total score.
- Correct/wrong/unattempted.
- Section/subject performance.
- Rank/percentile if configured.
- Optional teacher remark.
- Report generation timestamp.
- Verification/report ID.

### FR-12 Parent Email

- Parent email stored on student record.
- Email sent only after result finalization.
- Email template configurable by organization.
- PDF attached or secure report link included.
- Delivery status tracked.
- Retry with exponential backoff on transient provider failures.
- Prevent accidental duplicate sends with idempotency keys.
- Resend manually from result screen if permitted.

### FR-13 Audit Logs

Record critical actions such as:

- Login/security events.
- Student changes.
- Exam changes.
- Answer-key changes.
- Result corrections.
- Result finalization.
- Email send attempts.
- Membership/role changes.
- Report downloads.

## 9. User Stories

### Institute Admin

- As an admin, I want to create an exam so that staff can scan answer sheets against it.
- As an admin, I want to import students so that parent emails are available without manual re-entry.
- As an admin, I want to see which reports were delivered so that I know parents were contacted.

### Teacher

- As a teacher, I want to scan a sheet with the phone camera so I can avoid a dedicated OMR scanner.
- As a teacher, I want to review uncertain sheets so that no incorrect score is published automatically.
- As a teacher, I want to resend a report so parents can receive it again.

### Operator

- As an operator, I want a simple scan queue so I can process many sheets with minimal training.

## 10. Business Rules

1. No result may be emailed before finalization.
2. Only authorized users may finalize results.
3. Every correction after automatic evaluation must be auditable.
4. Deleted students/exams should be soft-deleted or archived unless a retention workflow explicitly removes them.
5. Parent email must belong to the student record used for that report unless an authorized user changes it.
6. A report link must not expose sequential IDs or raw storage paths.
7. Report links should be signed and time-limited, or require an authenticated parent portal in a later phase.
8. The original scan must remain immutable after upload; corrections create result events rather than changing the source image.

## 11. Success Metrics

### Product Metrics

- Median time from scan completion to result ready: < 10 seconds for a single page under normal network conditions.
- Manual review rate: < 5% on approved templates after calibration.
- False-answer rate on validated benchmark set: target < 0.2% per bubble; final release threshold must be validated experimentally.
- Parent email send initiation: < 5 seconds after finalization.
- Report generation success: > 99.5%.
- Email delivery provider acceptance: > 99% of valid requests.

These are targets, not claims; they must be validated during testing.

## 12. MVP Scope

### Included

- Flutter Android/iOS app.
- Supabase Auth.
- Supabase Postgres.
- Supabase Storage.
- OMR templates.
- Camera capture.
- Upload images/PDF.
- Python/OpenCV processing service.
- Result evaluation.
- Manual review queue.
- PDF reports.
- Transactional email via Resend through server-side function.
- Audit logs.

### Post-MVP

- WhatsApp.
- SMS.
- Advanced analytics.
- Parent portal.
- Multi-device operator synchronization improvements.
- Dedicated scanner integrations.
- Organization-level custom domains.

## 13. Acceptance Criteria

The MVP is considered functionally complete when:

1. A staff user can create an exam and answer key.
2. A student with a valid parent email can be linked to the exam.
3. A valid OMR sheet captured by camera can be processed correctly against the approved template.
4. An uploaded image/PDF produces the same result as camera capture for the same source sheet.
5. Ambiguous marks are routed to review.
6. Authorized staff can correct an ambiguous answer and finalize the result.
7. A report is generated and cannot be accessed by a different organization.
8. A parent receives the final report by email.
9. Email delivery status is visible to staff.
10. All sensitive database tables have RLS enabled and tested.
