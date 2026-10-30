-- Sweksha Jobs & Hiring: run once in Supabase SQL Editor.
-- Creates separate tables; does not alter the existing enquiries table.

create table if not exists public.job_applications (
  id uuid primary key default gen_random_uuid(),
  full_name text not null,
  role_skills text not null,
  experience_qualifications text,
  preferred_location text not null,
  phone text not null,
  status text not null default 'pending' check (status in ('pending','reviewed','shortlisted','closed','rejected')),
  created_at timestamptz not null default now()
);

create table if not exists public.job_vacancies (
  id uuid primary key default gen_random_uuid(),
  company_name text not null,
  job_title text not null,
  responsibilities_skills text not null,
  work_location text not null,
  employment_type text not null default 'Full-time',
  pay_range text,
  contact_details text not null,
  status text not null default 'pending' check (status in ('pending','approved','rejected','closed')),
  created_at timestamptz not null default now()
);

alter table public.job_applications enable row level security;
alter table public.job_vacancies enable row level security;

-- Anyone may submit a job application or vacancy, but public users cannot read records.
drop policy if exists "Public can submit job applications" on public.job_applications;
create policy "Public can submit job applications"
on public.job_applications for insert to anon, authenticated
with check (
  length(trim(full_name)) between 2 and 120
  and length(trim(role_skills)) between 2 and 500
  and length(trim(preferred_location)) between 2 and 200
  and length(trim(phone)) between 5 and 40
);

drop policy if exists "Public can submit job vacancies" on public.job_vacancies;
create policy "Public can submit job vacancies"
on public.job_vacancies for insert to anon, authenticated
with check (
  length(trim(company_name)) between 2 and 160
  and length(trim(job_title)) between 2 and 160
  and length(trim(responsibilities_skills)) between 2 and 3000
  and length(trim(work_location)) between 2 and 200
  and length(trim(contact_details)) between 5 and 160
);

-- Only the designated Sweksha admin account can read and manage submissions.
drop policy if exists "Sweksha admin can read job applications" on public.job_applications;
create policy "Sweksha admin can read job applications"
on public.job_applications for select to authenticated
using (lower(coalesce(auth.jwt() ->> 'email','')) = 'kamatrajukumar2000@gmail.com');

drop policy if exists "Sweksha admin can update job applications" on public.job_applications;
create policy "Sweksha admin can update job applications"
on public.job_applications for update to authenticated
using (lower(coalesce(auth.jwt() ->> 'email','')) = 'kamatrajukumar2000@gmail.com')
with check (lower(coalesce(auth.jwt() ->> 'email','')) = 'kamatrajukumar2000@gmail.com');

drop policy if exists "Sweksha admin can read job vacancies" on public.job_vacancies;
create policy "Sweksha admin can read job vacancies"
on public.job_vacancies for select to authenticated
using (lower(coalesce(auth.jwt() ->> 'email','')) = 'kamatrajukumar2000@gmail.com');

drop policy if exists "Sweksha admin can update job vacancies" on public.job_vacancies;
create policy "Sweksha admin can update job vacancies"
on public.job_vacancies for update to authenticated
using (lower(coalesce(auth.jwt() ->> 'email','')) = 'kamatrajukumar2000@gmail.com')
with check (lower(coalesce(auth.jwt() ->> 'email','')) = 'kamatrajukumar2000@gmail.com');

grant insert on public.job_applications to anon, authenticated;
grant insert on public.job_vacancies to anon, authenticated;
grant select, update on public.job_applications to authenticated;
grant select, update on public.job_vacancies to authenticated;
