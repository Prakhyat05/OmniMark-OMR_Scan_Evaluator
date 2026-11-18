# Database Schema — OMR Scan, Evaluation & Parent Email Platform

## 1. Database Choice

Use **Supabase Postgres** as the system of record.

Supabase Auth owns authentication identities in its protected `auth` schema. Application data should remain in the application schema and reference `auth.users(id)` through profile/membership records. Supabase's Auth architecture is built around Postgres and JWT-based authorization. citeturn969800search5turn969800search11

## 2. Design Principles

- UUID primary keys.
- Every organization-owned table carries `organization_id` unless ownership is inherited safely through a parent relationship.
- Soft delete/archive for business records.
- `created_at`, `updated_at` on mutable tables.
- Use enums sparingly; prefer text/check constraints for values that may change frequently.
- RLS on every exposed table.
- Never trust client-provided organization IDs without membership checks.
- Never expose service-role credentials to Flutter.

## 3. Core Entity Relationship

```text
profiles
   |
   +----< organization_members >---- organizations
                                      |
                                      +----< classes
                                      +----< students
                                      +----< exams
                                      |       |
                                      |       +----< answer_keys
                                      |       +----< exam_sections
                                      |       +----< scan_jobs
                                      |       +----< results
                                      |
                                      +----< omr_templates

students ----< parent_contacts
students ----< exam_enrollments >---- exams
results ----< result_answers
results ----< result_events
results ----< reports ----< email_deliveries
scan_jobs ----< scan_pages
scan_pages ----< omr_detections
```

## 4. Tables

### 4.1 `profiles`

Purpose: application profile linked to `auth.users`.

Columns:

- `id uuid primary key` -> `auth.users.id`
- `full_name text not null`
- `avatar_path text null`
- `timezone text default 'Asia/Kolkata'`
- `created_at timestamptz`
- `updated_at timestamptz`

### 4.2 `organizations`

- `id uuid primary key`
- `name text not null`
- `slug text unique not null`
- `logo_path text null`
- `contact_email text null`
- `phone text null`
- `address text null`
- `status text not null default 'active'`
- `created_by uuid references profiles(id)`
- timestamps

### 4.3 `organization_members`

- `id uuid primary key`
- `organization_id uuid references organizations(id)`
- `user_id uuid references profiles(id)`
- `role text check in ('owner','admin','teacher','operator')`
- `status text check in ('active','invited','suspended','removed')`
- `joined_at timestamptz`
- timestamps
- unique `(organization_id, user_id)`

### 4.4 `classes`

- `id uuid primary key`
- `organization_id uuid not null`
- `name text not null`
- `section text null`
- `academic_year text null`
- `status text default 'active'`
- timestamps

### 4.5 `students`

- `id uuid primary key`
- `organization_id uuid not null`
- `student_code text not null`
- `roll_number text null`
- `full_name text not null`
- `class_id uuid references classes(id)`
- `date_of_birth date null`
- `status text default 'active'`
- timestamps
- unique `(organization_id, student_code)`

### 4.6 `parent_contacts`

- `id uuid primary key`
- `organization_id uuid not null`
- `student_id uuid references students(id)`
- `name text not null`
- `email text not null`
- `relationship text null`
- `is_primary boolean default false`
- `status text default 'active'`
- timestamps

Constraint: only authorized users can read parent email data.

### 4.7 `omr_templates`

- `id uuid primary key`
- `organization_id uuid null` for system templates
- `name text not null`
- `version text not null`
- `page_width_px integer not null`
- `page_height_px integer not null`
- `question_count integer not null`
- `options_per_question integer not null`
- `configuration jsonb not null`
- `status text default 'draft'`
- `created_by uuid references profiles(id)`
- timestamps

`configuration` stores registration marker locations, answer region coordinates, identity regions, threshold configuration, and crop zones.

### 4.8 `exams`

- `id uuid primary key`
- `organization_id uuid not null`
- `class_id uuid null references classes(id)`
- `name text not null`
- `subject text null`
- `exam_date date not null`
- `template_id uuid references omr_templates(id)`
- `total_questions integer not null`
- `default_correct_marks numeric(8,2) not null`
- `default_wrong_marks numeric(8,2) not null default 0`
- `status text check in ('draft','published','processing','completed','archived')`
- `created_by uuid references profiles(id)`
- timestamps

### 4.9 `exam_sections`

- `id uuid primary key`
- `exam_id uuid not null`
- `name text not null`
- `question_start integer not null`
- `question_end integer not null`
- `correct_marks numeric(8,2) not null`
- `wrong_marks numeric(8,2) not null`
- timestamps

### 4.10 `answer_keys`

- `id uuid primary key`
- `exam_id uuid not null`
- `version integer not null`
- `status text default 'draft'`
- `created_by uuid references profiles(id)`
- `locked_at timestamptz null`
- timestamps
- unique `(exam_id, version)`

### 4.11 `answer_key_items`

- `id uuid primary key`
- `answer_key_id uuid not null`
- `question_number integer not null`
- `correct_options text[] not null`
- `correct_marks numeric(8,2) not null`
- `wrong_marks numeric(8,2) not null`
- `is_bonus boolean default false`
- `is_dropped boolean default false`
- timestamps
- unique `(answer_key_id, question_number)`

### 4.12 `exam_enrollments`

- `id uuid primary key`
- `organization_id uuid not null`
- `exam_id uuid not null`
- `student_id uuid not null`
- `external_candidate_code text null`
- `status text default 'active'`
- timestamps
- unique `(exam_id, student_id)`

### 4.13 `scan_jobs`

- `id uuid primary key`
- `organization_id uuid not null`
- `exam_id uuid not null`
- `created_by uuid references profiles(id)`
- `source text check in ('camera','gallery','pdf','import')`
- `status text check in ('queued','uploading','processing','review','completed','failed','cancelled')`
- `total_pages integer default 0`
- `processed_pages integer default 0`
- `error_message text null`
- timestamps

### 4.14 `scan_pages`

- `id uuid primary key`
- `scan_job_id uuid not null`
- `storage_path text not null`
- `mime_type text not null`
- `page_number integer not null`
- `file_size_bytes bigint not null`
- `sha256 text null`
- `status text default 'uploaded'`
- timestamps

### 4.15 `omr_detections`

- `id uuid primary key`
- `scan_page_id uuid not null`
- `template_id uuid not null`
- `detector_version text not null`
- `student_code_detected text null`
- `exam_code_detected text null`
- `overall_confidence numeric(6,5) null`
- `review_required boolean default false`
- `raw_detection jsonb not null`
- `processing_ms integer null`
- timestamps

### 4.16 `results`

- `id uuid primary key`
- `organization_id uuid not null`
- `exam_id uuid not null`
- `student_id uuid not null`
- `scan_page_id uuid null`
- `answer_key_id uuid not null`
- `status text check in ('draft','needs_review','approved','finalized','void')`
- `marks_obtained numeric(10,2) not null default 0`
- `maximum_marks numeric(10,2) not null`
- `percentage numeric(6,3) null`
- `correct_count integer not null default 0`
- `wrong_count integer not null default 0`
- `unattempted_count integer not null default 0`
- `rank integer null`
- `percentile numeric(7,3) null`
- `teacher_remark text null`
- `finalized_at timestamptz null`
- `finalized_by uuid references profiles(id)`
- timestamps
- unique `(exam_id, student_id)`

### 4.17 `result_answers`

- `id uuid primary key`
- `result_id uuid not null`
- `question_number integer not null`
- `detected_option text null`
- `correct_options text[] null`
- `is_correct boolean null`
- `is_multiple boolean default false`
- `is_uncertain boolean default false`
- `confidence numeric(6,5) null`
- `marks_awarded numeric(8,2) not null default 0`
- `detection_metadata jsonb null`
- timestamps
- unique `(result_id, question_number)`

### 4.18 `result_events`

Immutable audit/event history for result lifecycle changes.

- `id uuid primary key`
- `organization_id uuid not null`
- `result_id uuid not null`
- `actor_user_id uuid references profiles(id)`
- `event_type text not null`
- `before_state jsonb null`
- `after_state jsonb null`
- `reason text null`
- `created_at timestamptz not null default now()`

### 4.19 `reports`

- `id uuid primary key`
- `organization_id uuid not null`
- `result_id uuid not null unique`
- `template_version text not null`
- `storage_path text not null`
- `report_version integer default 1`
- `generated_at timestamptz not null`
- `checksum text null`
- `status text default 'ready'`

### 4.20 `email_deliveries`

- `id uuid primary key`
- `organization_id uuid not null`
- `result_id uuid not null`
- `report_id uuid not null`
- `parent_contact_id uuid not null`
- `provider text not null default 'resend'`
- `provider_message_id text null`
- `to_email text not null`
- `subject text not null`
- `status text check in ('queued','sent','delivered','bounced','failed')`
- `attempt_count integer not null default 0`
- `last_error text null`
- `sent_at timestamptz null`
- `delivered_at timestamptz null`
- timestamps
- unique `(result_id, parent_contact_id, report_id)`

### 4.21 `audit_logs`

- `id uuid primary key`
- `organization_id uuid null`
- `actor_user_id uuid null references profiles(id)`
- `action text not null`
- `entity_type text not null`
- `entity_id uuid null`
- `metadata jsonb null`
- `ip_hash text null`
- `user_agent text null`
- `created_at timestamptz not null default now()`

## 5. Recommended Indexes

Create indexes for:

- `organization_members(user_id, status)`
- `students(organization_id, student_code)`
- `students(organization_id, class_id)`
- `parent_contacts(organization_id, student_id)`
- `exams(organization_id, exam_date)`
- `exam_enrollments(exam_id, student_id)`
- `scan_jobs(organization_id, status)`
- `scan_pages(scan_job_id, status)`
- `results(organization_id, exam_id, status)`
- `results(exam_id, marks_obtained desc)`
- `email_deliveries(result_id, status)`
- `audit_logs(organization_id, created_at desc)`

## 6. RLS Model

The general policy pattern is:

`user -> organization_members -> organization_id -> row access`

A user can access a row only when an active membership exists for that row's organization.

Role-sensitive operations:

- owner/admin: all operational management.
- teacher: exams, students, scans, results according to organization policy.
- operator: scan/upload/review but no membership administration and no sensitive exports unless explicitly allowed.

Use security-definer helper functions carefully to centralize membership checks and prevent policy recursion.

## 7. Storage Buckets

Recommended private buckets:

- `omr-originals`
- `omr-processing`
- `reports`
- `organization-assets`

Never make `reports` public.

Storage paths should be namespaced, for example:

`organizations/{organization_id}/exams/{exam_id}/scans/{scan_page_id}.jpg`

and

`organizations/{organization_id}/reports/{report_id}.pdf`

## 8. Data Retention

Suggested configurable defaults:

- Original scans: 180–365 days.
- Processing copies: 7–30 days.
- Reports: 1–3 years depending on institute policy.
- Audit logs: 1–3 years.

Retention must be configurable because education records may have contractual or regulatory retention requirements.

## 9. Example SQL Skeleton

```sql
create extension if not exists pgcrypto;

create table public.organizations (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text not null unique,
  logo_path text,
  contact_email text,
  status text not null default 'active',
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.organization_members (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null check (role in ('owner','admin','teacher','operator')),
  status text not null default 'active',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (organization_id, user_id)
);

alter table public.organizations enable row level security;
alter table public.organization_members enable row level security;
```

The complete migration should be written in `/supabase/migrations/` and tested against a fresh local Supabase environment before deployment.

## 10. Security Validation

Every migration must be checked for:

- RLS enabled.
- Minimal grants.
- Correct foreign keys.
- No public bucket access.
- No unintended views bypassing RLS.
- No secret/API key stored in database tables.
- Safe functions with controlled `search_path` and explicit privileges.
