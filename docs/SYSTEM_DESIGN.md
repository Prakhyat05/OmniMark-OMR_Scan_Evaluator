# System Design — OMR Scan, Evaluation & Parent Email Platform

## 1. Design Principles

1. Simple for non-technical operators.
2. Secure by default.
3. Database authorization is enforced server-side.
4. Original scanned evidence is immutable.
5. Every result change is auditable.
6. Heavy processing is isolated from the transactional database.
7. Email is triggered only after finalization.
8. Every operation is idempotent where possible.
9. Every production feature is versioned where output correctness matters.

## 2. Mobile App Screen Map

```text
Splash
  |
  +-- Sign In
  |
  +-- Forgot Password
  |
  +-- Organization Select
         |
         +-- Dashboard
              |
              +-- Exams
              |     +-- Exam Detail
              |     +-- Answer Key
              |     +-- Students
              |     +-- Scan
              |     +-- Results
              |
              +-- Students
              |
              +-- Scan Queue
              |
              +-- Review Queue
              |
              +-- Email Delivery
              |
              +-- Profile/Settings
```

## 3. Scan Session State Machine

```text
IDLE
  -> CAPTURING
  -> PREVIEW
  -> UPLOADING
  -> QUEUED
  -> PROCESSING
  ->
     +--> NEEDS_REVIEW
     |       -> CORRECTED
     |       -> FINALIZED
     |
     +--> READY_TO_FINALIZE
             -> FINALIZED

Failure from CAPTURING/UPLOADING/PROCESSING
  -> RETRY or FAILED
```

## 4. Result State Machine

```text
DRAFT
  -> NEEDS_REVIEW
  -> APPROVED
  -> FINALIZED
  -> VOID
```

Only authorized staff may move a result to `FINALIZED`.

## 5. OMR Template Design

Each template should define:

```json
{
  "page": {
    "width": 2480,
    "height": 3508
  },
  "registrationMarkers": [
    {"x": 120, "y": 120, "type": "circle"}
  ],
  "identityRegion": {
    "x": 200,
    "y": 250,
    "width": 500,
    "height": 400
  },
  "questions": {
    "start": 1,
    "count": 100,
    "options": ["A", "B", "C", "D"]
  },
  "thresholds": {
    "selected": 0.55,
    "uncertainLow": 0.30,
    "multipleDelta": 0.08
  }
}
```

Actual coordinates must be calibrated against printed/scanned samples, not assumed from the example.

## 6. OMR Recognition Algorithm

### Step 1 — File validation

- Check MIME type.
- Check file size.
- Check image dimensions.
- Reject corrupted input.

### Step 2 — Normalize

- Convert to grayscale.
- Reduce sensor/scanner noise.
- Normalize contrast.

### Step 3 — Detect page

- Detect document boundary.
- Crop background.
- Estimate perspective.

### Step 4 — Align

Use registration markers to compute a homography and map the image to the template coordinate space.

### Step 5 — Detect bubbles

For each configured bubble region:

- Extract ROI.
- Calculate fill ratio.
- Calculate mean darkness.
- Compare with calibration baseline.
- Compare options in the same question.

### Step 6 — Classify

Possible states:

- `empty`
- `selected`
- `multiple`
- `uncertain`

### Step 7 — Identity

Read the student identity field and/or QR/barcode.

### Step 8 — Confidence

Set per-answer confidence and overall page confidence.

## 7. Review Design

Review screen should show:

```text
+-----------------------------+
| Original OMR image          |
|                             |
|   Q1: A B C D              |
|   Q2: A B C D              |
|   Q3: A B C D              |
|                             |
+-----------------------------+
| Detected: Q3 = B           |
| Confidence: 42%             |
|                             |
| [A] [B] [C] [D]             |
|                             |
| [Save Correction]            |
+-----------------------------+
```

The user should be able to jump directly to uncertain questions.

## 8. Result Calculation

For each answer:

```text
if dropped:
    marks = 0
elif selected option matches accepted options:
    marks = correct_marks
elif unanswered:
    marks = 0
else:
    marks = wrong_marks
```

The calculation engine must use the answer-key version associated with the result.

## 9. Ranking

Ranking should happen only after all eligible results are considered complete.

Avoid updating ranks permanently on each individual result if the exam is still processing.

At completion:

1. Gather finalized results.
2. Sort by marks descending.
3. Apply tie rule.
4. Persist rank.
5. Optionally compute percentile.

## 10. Report Design

### Page 1

- Institute header.
- Student name/ID.
- Exam information.
- Score summary.
- Correct/wrong/unattempted.
- Rank/percentile.

### Page 2+ if needed

- Subject/section analysis.
- Question-wise answer table.
- Teacher remark.

Report must not expose internal storage paths or internal IDs.

## 11. Email Design

### Subject Example

`Your Child's Result — Mathematics Weekly Test`

### Email Body

- Student name.
- Exam name.
- Marks.
- Percentage.
- Rank if configured.
- Link to detailed report.
- Attachment if configured.
- Institute support contact.

Do not put sensitive internal data such as database IDs in the email.

## 12. Email Idempotency

Create an idempotency key:

`organization_id + result_id + report_id + parent_contact_id + template_version`

Before sending, check `email_deliveries` for an existing successful send.

If already sent successfully, return existing status instead of sending a duplicate.

## 13. Email Provider Integration

The Edge Function should:

1. Authenticate caller.
2. Validate that result is finalized.
3. Validate user has permission.
4. Fetch parent email using RLS-scoped access or a privileged, tightly controlled server operation.
5. Generate signed report URL.
6. Call Resend.
7. Record provider message ID.
8. Return delivery state.

Provider secrets remain in the Edge Function secret store. Supabase's official email example uses Resend from Edge Functions and stores the provider key as a secret. citeturn969800search2

## 14. Database Transaction Design

Result finalization should be transactional:

```text
BEGIN
  validate authorization
  validate result state
  validate answer key version
  update result -> finalized
  insert result_event
  enqueue report job
COMMIT
```

Email must not be sent inside the same database transaction. Report and email are asynchronous follow-up operations.

## 15. Queue Design

Recommended jobs:

- `omr.process_page`
- `omr.retry_page`
- `report.generate`
- `email.send`
- `email.retry`
- `analytics.refresh`

Each job has:

- job ID.
- entity ID.
- attempt count.
- status.
- next retry time.
- last error.

## 16. Retry Policy

Example exponential backoff:

- Attempt 1: immediate.
- Attempt 2: +15 seconds.
- Attempt 3: +1 minute.
- Attempt 4: +5 minutes.
- Attempt 5: +30 minutes.

Permanent failures go to a dead-letter/error state for operator review.

## 17. Security-by-Design Controls

### Mobile

- Use TLS.
- Avoid storing parent email exports locally.
- Clear temporary images after successful upload according to retention rules.
- Use platform-secure local storage for sensitive session-adjacent data.
- Detect screenshots/screen recording only if justified by a later privacy requirement.

### Backend

- RLS on exposed application tables.
- Minimal database grants.
- JWT verification on authenticated functions.
- Role checks on privileged operations.
- Rate limits.
- Audit logs.

Supabase documents that Edge Functions can verify caller JWTs and provide an RLS-scoped client. citeturn969800search12turn969800search9

### Storage

- Private buckets.
- Organization-scoped paths.
- Signed URLs with short expiry.
- Restrict object operations by ownership/organization.

### Reports

- Random UUID report IDs.
- Short-lived signed links.
- Optional authentication on future parent portal.
- No public directory listing.

## 18. Data Privacy

The system processes student and parent information. Product design should follow applicable Indian privacy/data-protection requirements and the institute's own data-retention policies. Legal compliance settings should be reviewed with counsel before production rollout.

## 19. Offline Behavior

The app should allow limited offline capture:

- Capture image.
- Store encrypted/local temporary file.
- Add to pending upload queue.
- Show `Waiting for internet`.
- Upload automatically when connectivity returns.

Do not perform final server-side evaluation offline in MVP unless the OMR engine is deliberately packaged on-device.

## 20. Concurrency Controls

Prevent double-finalization using:

- Database state checks.
- Optimistic concurrency or `updated_at` check.
- Server-side idempotency.
- Unique constraints on result and delivery records.

## 21. Disaster Recovery

The production runbook should define:

- Database backup strategy.
- Storage backup/retention strategy.
- Supabase project recovery process.
- OMR service redeployment process.
- Email provider key rotation.
- Secret rotation.
- Incident communication.

## 22. Production Readiness Checklist

- [ ] RLS tests passing.
- [ ] Private Storage policies verified.
- [ ] Service-role keys absent from Flutter.
- [ ] Email provider domain verified.
- [ ] Email sending limits tested.
- [ ] OMR benchmark corpus passed.
- [ ] Review flow tested with ambiguous sheets.
- [ ] Duplicate-email prevention tested.
- [ ] Report access isolation tested between organizations.
- [ ] Audit logs verified.
- [ ] Backups and restore procedure documented.
- [ ] Sentry/error monitoring active.
- [ ] CI/CD protected branch rules active.
