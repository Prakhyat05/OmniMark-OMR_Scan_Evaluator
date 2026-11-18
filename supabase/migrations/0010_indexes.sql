-- 0010_indexes.sql
-- Performance indexes for tenant queries, joins, and search

create index if not exists idx_org_members_user on public.organization_members(user_id, status);
create index if not exists idx_org_members_org on public.organization_members(organization_id, status);

create index if not exists idx_classes_org on public.classes(organization_id, status);
create index if not exists idx_students_org_code on public.students(organization_id, student_code);
create index if not exists idx_students_org_class on public.students(organization_id, class_id);
create index if not exists idx_parent_contacts_student on public.parent_contacts(organization_id, student_id);

create index if not exists idx_exams_org_date on public.exams(organization_id, exam_date desc);
create index if not exists idx_exams_status on public.exams(organization_id, status);
create index if not exists idx_exam_enrollments_exam_student on public.exam_enrollments(exam_id, student_id);

create index if not exists idx_scan_jobs_org_status on public.scan_jobs(organization_id, status);
create index if not exists idx_scan_pages_job on public.scan_pages(scan_job_id, status);
create index if not exists idx_omr_detections_page on public.omr_detections(scan_page_id);

create index if not exists idx_results_org_exam on public.results(organization_id, exam_id, status);
create index if not exists idx_results_rank on public.results(exam_id, marks_obtained desc);
create index if not exists idx_result_answers_result on public.result_answers(result_id);
create index if not exists idx_result_events_result on public.result_events(result_id, created_at desc);

create index if not exists idx_reports_result on public.reports(result_id);
create index if not exists idx_email_deliveries_result_status on public.email_deliveries(result_id, status);
create index if not exists idx_audit_logs_org_created on public.audit_logs(organization_id, created_at desc);
