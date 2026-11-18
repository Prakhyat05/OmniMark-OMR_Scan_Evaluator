-- 0009_rls.sql
-- Row Level Security (RLS) policies and membership helper functions

-- Helper function to verify user's active membership in an organization
create or replace function public.is_org_member(org_id uuid)
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select exists (
    select 1
    from public.organization_members
    where organization_id = org_id
      and user_id = auth.uid()
      and status = 'active'
  );
$$;

-- Helper function to get user's role in an organization
create or replace function public.get_org_role(org_id uuid)
returns text
language sql
security definer
stable
set search_path = public
as $$
  select role
  from public.organization_members
  where organization_id = org_id
    and user_id = auth.uid()
    and status = 'active'
  limit 1;
$$;

-- Enable RLS on all exposed tables
alter table public.profiles enable row level security;
alter table public.organizations enable row level security;
alter table public.organization_members enable row level security;
alter table public.classes enable row level security;
alter table public.students enable row level security;
alter table public.parent_contacts enable row level security;
alter table public.omr_templates enable row level security;
alter table public.exams enable row level security;
alter table public.exam_sections enable row level security;
alter table public.answer_keys enable row level security;
alter table public.answer_key_items enable row level security;
alter table public.exam_enrollments enable row level security;
alter table public.scan_jobs enable row level security;
alter table public.scan_pages enable row level security;
alter table public.omr_detections enable row level security;
alter table public.results enable row level security;
alter table public.result_answers enable row level security;
alter table public.result_events enable row level security;
alter table public.reports enable row level security;
alter table public.email_deliveries enable row level security;
alter table public.audit_logs enable row level security;

-- 1. profiles
create policy "Users can view own profile or org colleagues"
  on public.profiles for select
  using (
    id = auth.uid() or
    exists (
      select 1 from public.organization_members m1
      join public.organization_members m2 on m1.organization_id = m2.organization_id
      where m1.user_id = auth.uid() and m2.user_id = profiles.id and m1.status = 'active'
    )
  );

create policy "Users can update own profile"
  on public.profiles for update
  using (id = auth.uid());

-- 2. organizations
create policy "Members can view active organization"
  on public.organizations for select
  using (public.is_org_member(id));

create policy "Authenticated users can create organization"
  on public.organizations for insert
  with check (auth.role() = 'authenticated');

create policy "Owners and admins can update organization"
  on public.organizations for update
  using (public.get_org_role(id) in ('owner', 'admin'));

-- 3. organization_members
create policy "Members can view members in their organization"
  on public.organization_members for select
  using (public.is_org_member(organization_id));

create policy "Owners and admins can manage members"
  on public.organization_members for all
  using (public.get_org_role(organization_id) in ('owner', 'admin'));

-- 4. classes & students
create policy "Org members can read classes"
  on public.classes for select
  using (public.is_org_member(organization_id));

create policy "Admins and teachers can manage classes"
  on public.classes for all
  using (public.get_org_role(organization_id) in ('owner', 'admin', 'teacher'));

create policy "Org members can read students"
  on public.students for select
  using (public.is_org_member(organization_id));

create policy "Admins and teachers can manage students"
  on public.students for all
  using (public.get_org_role(organization_id) in ('owner', 'admin', 'teacher'));

-- 5. parent_contacts
create policy "Admins and teachers can access parent contacts"
  on public.parent_contacts for all
  using (public.get_org_role(organization_id) in ('owner', 'admin', 'teacher'));

-- 6. omr_templates
create policy "View system templates or org templates"
  on public.omr_templates for select
  using (organization_id is null or public.is_org_member(organization_id));

create policy "Admins can create/manage org templates"
  on public.omr_templates for all
  using (organization_id is not null and public.get_org_role(organization_id) in ('owner', 'admin'));

-- 7. exams, sections, answer_keys, items, enrollments
create policy "Org members can view exams"
  on public.exams for select
  using (public.is_org_member(organization_id));

create policy "Admins and teachers can manage exams"
  on public.exams for all
  using (public.get_org_role(organization_id) in ('owner', 'admin', 'teacher'));

create policy "Org members can view exam sections"
  on public.exam_sections for select
  using (exists (select 1 from public.exams e where e.id = exam_sections.exam_id and public.is_org_member(e.organization_id)));

create policy "Admins and teachers can manage exam sections"
  on public.exam_sections for all
  using (exists (select 1 from public.exams e where e.id = exam_sections.exam_id and public.get_org_role(e.organization_id) in ('owner', 'admin', 'teacher')));

create policy "Org members can view answer keys"
  on public.answer_keys for select
  using (exists (select 1 from public.exams e where e.id = answer_keys.exam_id and public.is_org_member(e.organization_id)));

create policy "Admins and teachers can manage answer keys"
  on public.answer_keys for all
  using (exists (select 1 from public.exams e where e.id = answer_keys.exam_id and public.get_org_role(e.organization_id) in ('owner', 'admin', 'teacher')));

create policy "Org members can view answer key items"
  on public.answer_key_items for select
  using (exists (
    select 1 from public.answer_keys ak
    join public.exams e on e.id = ak.exam_id
    where ak.id = answer_key_items.answer_key_id and public.is_org_member(e.organization_id)
  ));

create policy "Admins and teachers can manage answer key items"
  on public.answer_key_items for all
  using (exists (
    select 1 from public.answer_keys ak
    join public.exams e on e.id = ak.exam_id
    where ak.id = answer_key_items.answer_key_id and public.get_org_role(e.organization_id) in ('owner', 'admin', 'teacher')
  ));

create policy "Org members can view enrollments"
  on public.exam_enrollments for select
  using (public.is_org_member(organization_id));

create policy "Admins and teachers can manage enrollments"
  on public.exam_enrollments for all
  using (public.get_org_role(organization_id) in ('owner', 'admin', 'teacher'));

-- 8. scan_jobs, scan_pages, omr_detections
create policy "Org members can view scan jobs"
  on public.scan_jobs for select
  using (public.is_org_member(organization_id));

create policy "Org members can create scan jobs"
  on public.scan_jobs for insert
  with check (public.is_org_member(organization_id));

create policy "Org members can update scan jobs"
  on public.scan_jobs for update
  using (public.is_org_member(organization_id));

create policy "Org members can access scan pages"
  on public.scan_pages for all
  using (exists (select 1 from public.scan_jobs j where j.id = scan_pages.scan_job_id and public.is_org_member(j.organization_id)));

create policy "Org members can access omr detections"
  on public.omr_detections for all
  using (exists (
    select 1 from public.scan_pages p
    join public.scan_jobs j on j.id = p.scan_job_id
    where p.id = omr_detections.scan_page_id and public.is_org_member(j.organization_id)
  ));

-- 9. results, answers, events
create policy "Org members can view results"
  on public.results for select
  using (public.is_org_member(organization_id));

create policy "Admins, teachers, operators can update results"
  on public.results for update
  using (public.is_org_member(organization_id));

create policy "Org members can view result answers"
  on public.result_answers for select
  using (exists (select 1 from public.results r where r.id = result_answers.result_id and public.is_org_member(r.organization_id)));

create policy "Admins, teachers, operators can manage result answers"
  on public.result_answers for all
  using (exists (select 1 from public.results r where r.id = result_answers.result_id and public.is_org_member(r.organization_id)));

create policy "Org members can view result events"
  on public.result_events for select
  using (public.is_org_member(organization_id));

create policy "Org members can append result events"
  on public.result_events for insert
  with check (public.is_org_member(organization_id));

-- 10. reports, email_deliveries, audit_logs
create policy "Org members can view reports"
  on public.reports for select
  using (public.is_org_member(organization_id));

create policy "Admins and teachers can view email deliveries"
  on public.email_deliveries for select
  using (public.get_org_role(organization_id) in ('owner', 'admin', 'teacher'));

create policy "Admins can view audit logs"
  on public.audit_logs for select
  using (public.get_org_role(organization_id) in ('owner', 'admin'));

-- Storage Buckets Setup & Security Policies
insert into storage.buckets (id, name, public)
values 
  ('omr-originals', 'omr-originals', false),
  ('omr-processing', 'omr-processing', false),
  ('reports', 'reports', false),
  ('organization-assets', 'organization-assets', false)
on conflict (id) do update set public = false;

create policy "Storage: Org members can access omr-originals"
  on storage.objects for all
  using (
    bucket_id in ('omr-originals', 'omr-processing', 'reports', 'organization-assets')
    and auth.role() = 'authenticated'
  );
