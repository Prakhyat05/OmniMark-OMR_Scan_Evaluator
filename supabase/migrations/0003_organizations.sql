-- 0003_organizations.sql
-- Multi-tenant organizations and memberships

create table public.organizations (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text not null unique,
  logo_path text null,
  contact_email text null,
  phone text null,
  address text null,
  status text not null default 'active' check (status in ('active', 'suspended', 'archived')),
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.organization_members (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  role text not null check (role in ('owner', 'admin', 'teacher', 'operator')),
  status text not null default 'active' check (status in ('active', 'invited', 'suspended', 'removed')),
  joined_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (organization_id, user_id)
);
