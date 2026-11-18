-- 0005_exams.sql
-- OMR Templates, Exams, Sections, Answer Keys, Items and Enrollments

create table public.omr_templates (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid references public.organizations(id) on delete cascade, -- null indicates global system template
  name text not null,
  version text not null,
  page_width_px integer not null,
  page_height_px integer not null,
  question_count integer not null,
  options_per_question integer not null default 4,
  configuration jsonb not null default '{}'::jsonb,
  status text not null default 'active' check (status in ('draft', 'active', 'archived')),
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.exams (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  class_id uuid references public.classes(id) on delete set null,
  name text not null,
  subject text null,
  exam_date date not null,
  template_id uuid not null references public.omr_templates(id),
  total_questions integer not null,
  default_correct_marks numeric(8,2) not null default 4.00,
  default_wrong_marks numeric(8,2) not null default -1.00,
  status text not null default 'draft' check (status in ('draft', 'published', 'processing', 'completed', 'archived')),
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.exam_sections (
  id uuid primary key default gen_random_uuid(),
  exam_id uuid not null references public.exams(id) on delete cascade,
  name text not null,
  question_start integer not null,
  question_end integer not null,
  correct_marks numeric(8,2) not null default 4.00,
  wrong_marks numeric(8,2) not null default -1.00,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.answer_keys (
  id uuid primary key default gen_random_uuid(),
  exam_id uuid not null references public.exams(id) on delete cascade,
  version integer not null default 1,
  status text not null default 'draft' check (status in ('draft', 'active', 'locked')),
  created_by uuid references public.profiles(id) on delete set null,
  locked_at timestamptz null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (exam_id, version)
);

create table public.answer_key_items (
  id uuid primary key default gen_random_uuid(),
  answer_key_id uuid not null references public.answer_keys(id) on delete cascade,
  question_number integer not null,
  correct_options text[] not null, -- e.g. ARRAY['A'] or ARRAY['B','C']
  correct_marks numeric(8,2) not null default 4.00,
  wrong_marks numeric(8,2) not null default -1.00,
  is_bonus boolean not null default false,
  is_dropped boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (answer_key_id, question_number)
);

create table public.exam_enrollments (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  exam_id uuid not null references public.exams(id) on delete cascade,
  student_id uuid not null references public.students(id) on delete cascade,
  external_candidate_code text null,
  status text not null default 'active' check (status in ('active', 'absent', 'exempted')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (exam_id, student_id)
);
