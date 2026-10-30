-- Sweksha Admin Dashboard: secure enquiry access and status management
-- Run this once in Supabase SQL Editor for project sweksha-cvd-service.
-- Keeps public enquiry INSERT access intact; removes public/anon SELECT policies.
-- Only the authenticated admin email below can read and update enquiries.

alter table public.enquiries
  add column if not exists status text not null default 'new';

alter table public.enquiries
  add column if not exists updated_at timestamptz not null default now();

create index if not exists enquiries_status_created_at_idx
  on public.enquiries (status, created_at desc);

alter table public.enquiries enable row level security;

-- Remove any public/anonymous SELECT or ALL policy that could expose customer details.
do $$
declare p record;
begin
  for p in
    select policyname
    from pg_policies
    where schemaname = 'public'
      and tablename = 'enquiries'
      and cmd in ('SELECT', 'ALL')
      and roles && array['anon'::name, 'public'::name]
  loop
    execute format('drop policy if exists %I on public.enquiries', p.policyname);
  end loop;
end $$;

drop policy if exists "Sweksha admin read enquiries" on public.enquiries;
create policy "Sweksha admin read enquiries"
on public.enquiries
for select
to authenticated
using (lower(coalesce(auth.jwt() ->> 'email', '')) = 'kamatrajukumar2000@gmail.com');

drop policy if exists "Sweksha admin update enquiries" on public.enquiries;
create policy "Sweksha admin update enquiries"
on public.enquiries
for update
to authenticated
using (lower(coalesce(auth.jwt() ->> 'email', '')) = 'kamatrajukumar2000@gmail.com')
with check (lower(coalesce(auth.jwt() ->> 'email', '')) = 'kamatrajukumar2000@gmail.com');

-- Public visitors can submit enquiries, but cannot read or update them.
revoke all on table public.enquiries from anon;
grant insert on table public.enquiries to anon;
grant select, update on table public.enquiries to authenticated;
