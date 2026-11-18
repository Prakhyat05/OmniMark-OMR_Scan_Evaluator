-- 0007_results.sql
-- Results, Result Answers, and Result Events (Audit Log)

create table public.results (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  exam_id uuid not null references public.exams(id) on delete cascade,
  student_id uuid not null references public.students(id) on delete cascade,
  scan_page_id uuid references public.scan_pages(id) on delete set null,
  answer_key_id uuid not null references public.answer_keys(id),
  status text not null default 'draft' check (status in ('draft', 'needs_review', 'approved', 'finalized', 'void')),
  marks_obtained numeric(10,2) not null default 0.00,
  maximum_marks numeric(10,2) not null default 0.00,
  percentage numeric(6,3) null,
  correct_count integer not null default 0,
  wrong_count integer not null default 0,
  unattempted_count integer not null default 0,
  rank integer null,
  percentile numeric(7,3) null,
  teacher_remark text null,
  finalized_at timestamptz null,
  finalized_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (exam_id, student_id)
);

create table public.result_answers (
  id uuid primary key default gen_random_uuid(),
  result_id uuid not null references public.results(id) on delete cascade,
  question_number integer not null,
  detected_option text null,
  correct_options text[] null,
  is_correct boolean null,
  is_multiple boolean not null default false,
  is_uncertain boolean not null default false,
  confidence numeric(6,5) null,
  marks_awarded numeric(8,2) not null default 0.00,
  detection_metadata jsonb null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (result_id, question_number)
);

create table public.result_events (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  result_id uuid not null references public.results(id) on delete cascade,
  actor_user_id uuid references public.profiles(id) on delete set null,
  event_type text not null, -- 'created', 'auto_evaluated', 'answer_corrected', 'approved', 'finalized', 'voided'
  before_state jsonb null,
  after_state jsonb null,
  reason text null,
  created_at timestamptz not null default now()
);
