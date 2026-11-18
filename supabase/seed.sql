-- supabase/seed.sql
-- Development and staging seed data

-- 1. Insert Standard 100-Question OMR Template
insert into public.omr_templates (
  id,
  name,
  version,
  page_width_px,
  page_height_px,
  question_count,
  options_per_question,
  configuration,
  status
) values (
  '11111111-1111-1111-1111-111111111111',
  'Standard Academic 100-Question OMR (A4)',
  '1.0.0',
  2480,
  3508,
  100,
  4,
  '{
    "page": {"width": 2480, "height": 3508},
    "registrationMarkers": [
      {"x": 120, "y": 120, "type": "black_square", "size": 60},
      {"x": 2360, "y": 120, "type": "black_square", "size": 60},
      {"x": 120, "y": 3388, "type": "black_square", "size": 60},
      {"x": 2360, "y": 3388, "type": "black_square", "size": 60}
    ],
    "identityRegion": {
      "x": 200,
      "y": 280,
      "width": 640,
      "height": 380,
      "digits": 6
    },
    "grid": {
      "columns": 4,
      "rowsPerColumn": 25,
      "startX": 180,
      "startY": 780,
      "columnWidth": 520,
      "rowHeight": 100,
      "bubbleRadius": 22,
      "options": ["A", "B", "C", "D"]
    },
    "thresholds": {
      "selected": 0.55,
      "uncertainLow": 0.30,
      "multipleDelta": 0.08
    }
  }'::jsonb,
  'active'
) on conflict (id) do nothing;

-- 2. Insert Demo Organization
insert into public.organizations (
  id,
  name,
  slug,
  contact_email,
  phone,
  address,
  status
) values (
  '22222222-2222-2222-2222-222222222222',
  'Apex International Academy',
  'apex-academy',
  'admin@apexacademy.edu',
  '+91 98765 43210',
  '42 Knowledge Park, Tech City, New Delhi',
  'active'
) on conflict (id) do nothing;

-- 3. Insert Demo Classes
insert into public.classes (
  id,
  organization_id,
  name,
  section,
  academic_year,
  status
) values 
  ('33333333-3333-3333-3333-333333333331', '22222222-2222-2222-2222-222222222222', 'Grade 10', 'A', '2026-2027', 'active'),
  ('33333333-3333-3333-3333-333333333332', '22222222-2222-2222-2222-222222222222', 'Grade 12', 'Science', '2026-2027', 'active')
on conflict (id) do nothing;

-- 4. Insert Demo Students
insert into public.students (
  id,
  organization_id,
  student_code,
  roll_number,
  full_name,
  class_id,
  status
) values
  ('44444444-4444-4444-4444-444444444441', '22222222-2222-2222-2222-222222222222', 'STU1001', '101', 'Aarav Sharma', '33333333-3333-3333-3333-333333333331', 'active'),
  ('44444444-4444-4444-4444-444444444442', '22222222-2222-2222-2222-222222222222', 'STU1002', '102', 'Priya Patel', '33333333-3333-3333-3333-333333333331', 'active'),
  ('44444444-4444-4444-4444-444444444443', '22222222-2222-2222-2222-222222222222', 'STU1003', '103', 'Rohan Gupta', '33333333-3333-3333-3333-333333333331', 'active'),
  ('44444444-4444-4444-4444-444444444444', '22222222-2222-2222-2222-222222222222', 'STU1004', '104', 'Ananya Verma', '33333333-3333-3333-3333-333333333331', 'active'),
  ('44444444-4444-4444-4444-444444444445', '22222222-2222-2222-2222-222222222222', 'STU1005', '105', 'Vikramaditya Singh', '33333333-3333-3333-3333-333333333331', 'active')
on conflict (id) do nothing;

-- 5. Insert Parent Contacts
insert into public.parent_contacts (
  id,
  organization_id,
  student_id,
  name,
  email,
  relationship,
  is_primary,
  status
) values
  ('55555555-5555-5555-5555-555555555551', '22222222-2222-2222-2222-222222222222', '44444444-4444-4444-4444-444444444441', 'Rajesh Sharma', 'rajesh.sharma@example.com', 'Father', true, 'active'),
  ('55555555-5555-5555-5555-555555555552', '22222222-2222-2222-2222-222222222222', '44444444-4444-4444-4444-444444444442', 'Sunita Patel', 'sunita.patel@example.com', 'Mother', true, 'active'),
  ('55555555-5555-5555-5555-555555555553', '22222222-2222-2222-2222-222222222222', '44444444-4444-4444-4444-444444444443', 'Sanjay Gupta', 'sanjay.gupta@example.com', 'Father', true, 'active'),
  ('55555555-5555-5555-5555-555555555554', '22222222-2222-2222-2222-222222222222', '44444444-4444-4444-4444-444444444444', 'Meenakshi Verma', 'meenakshi.verma@example.com', 'Mother', true, 'active'),
  ('55555555-5555-5555-5555-555555555555', '22222222-2222-2222-2222-222222222222', '44444444-4444-4444-4444-444444444445', 'Digvijay Singh', 'digvijay.singh@example.com', 'Father', true, 'active')
on conflict (id) do nothing;

-- 6. Insert Demo Exam
insert into public.exams (
  id,
  organization_id,
  class_id,
  name,
  subject,
  exam_date,
  template_id,
  total_questions,
  default_correct_marks,
  default_wrong_marks,
  status
) values (
  '66666666-6666-6666-6666-666666666666',
  '22222222-2222-2222-2222-222222222222',
  '33333333-3333-3333-3333-333333333331',
  'Mathematics Weekly Assessment 04',
  'Mathematics',
  current_date,
  '11111111-1111-1111-1111-111111111111',
  50,
  4.00,
  -1.00,
  'published'
) on conflict (id) do nothing;

-- 7. Insert Answer Key
insert into public.answer_keys (
  id,
  exam_id,
  version,
  status,
  locked_at
) values (
  '77777777-7777-7777-7777-777777777777',
  '66666666-6666-6666-6666-666666666666',
  1,
  'active',
  now()
) on conflict (id) do nothing;

-- Insert 50 Answer Key Items
do $$
declare
  opts text[] := array['A', 'B', 'C', 'D'];
  i integer;
begin
  for i in 1..50 loop
    insert into public.answer_key_items (
      answer_key_id,
      question_number,
      correct_options,
      correct_marks,
      wrong_marks,
      is_bonus,
      is_dropped
    ) values (
      '77777777-7777-7777-7777-777777777777',
      i,
      array[opts[1 + ((i * 3 + 1) % 4)]],
      4.00,
      -1.00,
      false,
      false
    ) on conflict (answer_key_id, question_number) do nothing;
  end loop;
end;
$$;
