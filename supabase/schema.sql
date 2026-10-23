-- Sweksha marketplace, jobs and enquiry database foundation
-- Run in the Supabase SQL Editor only after creating a Supabase project.
-- This schema intentionally does NOT allow public/anonymous writes.
-- Public form submissions should go through a server-side endpoint with validation and spam protection.

create extension if not exists pgcrypto;

create table if not exists public.admin_users (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

create table if not exists public.marketplace_listings (
  id uuid primary key default gen_random_uuid(),
  listing_type text not null check (listing_type in ('machine_part','diamond_seed','rough_diamond')),
  title text not null,
  description text not null,
  condition text check (condition in ('new','used','not_applicable')),
  price numeric(14,2),
  currency text,
  quantity text,
  location text,
  photo_urls text[] not null default '{}',
  seller_name text not null,
  seller_contact text not null,
  status text not null default 'pending' check (status in ('pending','approved','rejected','sold','archived')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.job_vacancies (
  id uuid primary key default gen_random_uuid(),
  company_name text not null,
  job_title text not null,
  description text not null,
  location text not null,
  employment_type text,
  salary_range text,
  contact_name text,
  contact_details text not null,
  status text not null default 'pending' check (status in ('pending','approved','rejected','filled','archived')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.enquiries (
  id uuid primary key default gen_random_uuid(),
  enquiry_type text not null check (enquiry_type in ('machine_part','diamond_seed','rough_diamond','job_seeker','employer','general')),
  name text not null,
  contact_details text not null,
  message text not null,
  status text not null default 'new' check (status in ('new','in_progress','resolved','spam')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists marketplace_listings_status_created_idx on public.marketplace_listings(status, created_at desc);
create index if not exists job_vacancies_status_created_idx on public.job_vacancies(status, created_at desc);
create index if not exists enquiries_status_created_idx on public.enquiries(status, created_at desc);

alter table public.admin_users enable row level security;
alter table public.marketplace_listings enable row level security;
alter table public.job_vacancies enable row level security;
alter table public.enquiries enable row level security;

-- Admins can see their own admin membership. Add admin membership manually as project owner.
create policy "admins can read own membership"
on public.admin_users for select
to authenticated
using (user_id = auth.uid());

-- Admins can manage listing, job and enquiry records.
create policy "admins manage marketplace listings"
on public.marketplace_listings for all
to authenticated
using (exists (select 1 from public.admin_users a where a.user_id = auth.uid())
)
with check (exists (select 1 from public.admin_users a where a.user_id = auth.uid()));

create policy "admins manage job vacancies"
on public.job_vacancies for all
to authenticated
using (exists (select 1 from public.admin_users a where a.user_id = auth.uid())
)
with check (exists (select 1 from public.admin_users a where a.user_id = auth.uid()));

create policy "admins manage enquiries"
on public.enquiries for all
to authenticated
using (exists (select 1 from public.admin_users a where a.user_id = auth.uid())
)
with check (exists (select 1 from public.admin_users a where a.user_id = auth.uid()));

-- No public policies are created: anon/authenticated visitors cannot directly read or write private submissions.
