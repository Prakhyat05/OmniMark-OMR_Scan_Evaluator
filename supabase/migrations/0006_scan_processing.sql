-- 0006_scan_processing.sql
-- Scan Jobs, Scan Pages, and OMR Detections

create table public.scan_jobs (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  exam_id uuid not null references public.exams(id) on delete cascade,
  created_by uuid references public.profiles(id) on delete set null,
  source text not null default 'camera' check (source in ('camera', 'gallery', 'pdf', 'import')),
  status text not null default 'queued' check (status in ('queued', 'uploading', 'processing', 'review', 'completed', 'failed', 'cancelled')),
  total_pages integer not null default 0,
  processed_pages integer not null default 0,
  error_message text null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.scan_pages (
  id uuid primary key default gen_random_uuid(),
  scan_job_id uuid not null references public.scan_jobs(id) on delete cascade,
  storage_path text not null,
  mime_type text not null default 'image/jpeg',
  page_number integer not null default 1,
  file_size_bytes bigint not null,
  sha256 text null,
  status text not null default 'uploaded' check (status in ('uploaded', 'processing', 'completed', 'review_required', 'failed')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.omr_detections (
  id uuid primary key default gen_random_uuid(),
  scan_page_id uuid not null references public.scan_pages(id) on delete cascade,
  template_id uuid not null references public.omr_templates(id),
  detector_version text not null default '1.0.0',
  student_code_detected text null,
  exam_code_detected text null,
  overall_confidence numeric(6,5) null,
  review_required boolean not null default false,
  raw_detection jsonb not null default '{}'::jsonb,
  processing_ms integer null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
