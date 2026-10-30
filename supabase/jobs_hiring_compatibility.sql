-- Sweksha Jobs & Hiring compatibility + secure public listing migration
-- Run once in Supabase SQL Editor AFTER the existing schema.sql and jobs_hiring.sql.
-- Does not drop tables or existing submissions.

create extension if not exists pgcrypto;

create table if not exists public.job_applications (
  id uuid primary key default gen_random_uuid(),
  full_name text not null,
  role_skills text not null,
  experience_qualifications text,
  preferred_location text not null,
  phone text not null,
  status text not null default 'pending',
  created_at timestamptz not null default now()
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
  status text not null default 'pending',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Add the columns needed by both earlier schema versions so either execution
-- order is supported. Existing records are retained.
alter table public.job_applications
  add column if not exists experience_qualifications text,
  add column if not exists phone text,
  add column if not exists preferred_location text,
  add column if not exists role_skills text,
  add column if not exists full_name text,
  add column if not exists status text default 'pending',
  add column if not exists created_at timestamptz default now();

alter table public.job_vacancies
  add column if not exists description text,
  add column if not exists location text,
  add column if not exists salary_range text,
  add column if not exists contact_name text,
  add column if not exists contact_details text,
  add column if not exists responsibilities_skills text,
  add column if not exists work_location text,
  add column if not exists pay_range text,
  add column if not exists employment_type text,
  add column if not exists status text default 'pending',
  add column if not exists created_at timestamptz default now(),
  add column if not exists updated_at timestamptz default now();

-- Remove only status CHECK constraints, then apply one shared status vocabulary.
do $$
declare c record;
begin
  for c in
    select conname, conrelid::regclass as tbl
    from pg_constraint
    where contype='c'
      and conrelid in ('public.job_applications'::regclass,'public.job_vacancies'::regclass)
      and pg_get_constraintdef(oid) ilike '%status%'
  loop
    execute format('alter table %s drop constraint %I', c.tbl, c.conname);
  end loop;
end $$;

update public.job_applications set status='pending' where status is null or status not in ('pending','reviewed','shortlisted','closed','rejected');
update public.job_vacancies set status='pending' where status is null or status not in ('pending','approved','rejected','filled','archived');

alter table public.job_applications alter column status set default 'pending';
alter table public.job_vacancies alter column status set default 'pending';
alter table public.job_applications add constraint job_applications_status_check
  check (status in ('pending','reviewed','shortlisted','closed','rejected'));
alter table public.job_vacancies add constraint job_vacancies_status_check
  check (status in ('pending','approved','rejected','filled','archived'));

alter table public.job_applications enable row level security;
alter table public.job_vacancies enable row level security;

-- Public visitors can submit forms, but cannot read candidate profiles.
drop policy if exists "Public can submit job applications" on public.job_applications;
create policy "Public can submit job applications"
on public.job_applications for insert to anon, authenticated
with check (
  length(trim(coalesce(full_name,''))) between 2 and 120
  and length(trim(coalesce(role_skills,''))) between 2 and 500
  and length(trim(coalesce(preferred_location,''))) between 2 and 200
  and length(trim(coalesce(phone,''))) between 5 and 40
);

-- Public can submit vacancies; only approved vacancies are publicly readable.
drop policy if exists "Public can submit job vacancies" on public.job_vacancies;
create policy "Public can submit job vacancies"
on public.job_vacancies for insert to anon, authenticated
with check (
  length(trim(coalesce(company_name,''))) between 2 and 160
  and length(trim(coalesce(job_title,''))) between 2 and 160
  and length(trim(coalesce(description,responsibilities_skills,''))) between 2 and 3000
  and length(trim(coalesce(location,work_location,''))) between 2 and 200
  and length(trim(coalesce(contact_details,''))) between 5 and 160
);

drop policy if exists "Public can read approved job vacancies" on public.job_vacancies;
create policy "Public can read approved job vacancies"
on public.job_vacancies for select to anon, authenticated
using (status='approved');

-- Admin-only access is restricted to the Sweksha admin email.
drop policy if exists "Sweksha admin can read job applications" on public.job_applications;
create policy "Sweksha admin can read job applications"
on public.job_applications for select to authenticated
using (lower(coalesce(auth.jwt()->>'email',''))='kamatrajukumar2000@gmail.com');

drop policy if exists "Sweksha admin can update job applications" on public.job_applications;
create policy "Sweksha admin can update job applications"
on public.job_applications for update to authenticated
using (lower(coalesce(auth.jwt()->>'email',''))='kamatrajukumar2000@gmail.com')
with check (lower(coalesce(auth.jwt()->>'email',''))='kamatrajukumar2000@gmail.com');

drop policy if exists "Sweksha admin can read job vacancies" on public.job_vacancies;
create policy "Sweksha admin can read job vacancies"
on public.job_vacancies for select to authenticated
using (lower(coalesce(auth.jwt()->>'email',''))='kamatrajukumar2000@gmail.com');

drop policy if exists "Sweksha admin can update job vacancies" on public.job_vacancies;
create policy "Sweksha admin can update job vacancies"
on public.job_vacancies for update to authenticated
using (lower(coalesce(auth.jwt()->>'email',''))='kamatrajukumar2000@gmail.com')
with check (lower(coalesce(auth.jwt()->>'email',''))='kamatrajukumar2000@gmail.com');

grant insert on public.job_applications to anon, authenticated;
grant select, update on public.job_applications to authenticated;
grant insert, select on public.job_vacancies to anon, authenticated;
grant update on public.job_vacancies to authenticated;
