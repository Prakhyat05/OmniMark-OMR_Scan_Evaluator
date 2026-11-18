-- 0008_reports_email.sql
-- Reports, Email Deliveries, and Audit Logs

create table public.reports (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  result_id uuid not null unique references public.results(id) on delete cascade,
  template_version text not null default '1.0.0',
  storage_path text not null,
  report_version integer not null default 1,
  generated_at timestamptz not null default now(),
  checksum text null,
  status text not null default 'ready' check (status in ('pending', 'ready', 'failed')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.email_deliveries (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  result_id uuid not null references public.results(id) on delete cascade,
  report_id uuid not null references public.reports(id) on delete cascade,
  parent_contact_id uuid not null references public.parent_contacts(id) on delete cascade,
  provider text not null default 'resend',
  provider_message_id text null,
  to_email text not null,
  subject text not null,
  status text not null default 'queued' check (status in ('queued', 'sent', 'delivered', 'bounced', 'failed')),
  attempt_count integer not null default 0,
  last_error text null,
  sent_at timestamptz null,
  delivered_at timestamptz null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (result_id, parent_contact_id, report_id)
);

create table public.audit_logs (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid references public.organizations(id) on delete cascade,
  actor_user_id uuid references public.profiles(id) on delete set null,
  action text not null,
  entity_type text not null,
  entity_id uuid null,
  metadata jsonb null default '{}'::jsonb,
  ip_hash text null,
  user_agent text null,
  created_at timestamptz not null default now()
);
