-- SWEKSHA live database hardening — 25 November 2026
-- This is the current-state SQL record for project xotqafgkubodqpirfpfb.
-- The changes are already recorded in the Supabase migration history.
-- No existing rows are deleted or rewritten by this script.
-- Review the live schema before replaying it on another project.

begin;

-- Remove browser-role powers that bypass RLS or are not needed by the website.
revoke delete, truncate, references, trigger
on all tables in schema public from anon, authenticated;
revoke update on all tables in schema public from anon;
revoke maintain on all tables in schema public from anon, authenticated;

-- Apply safe defaults for future tables/sequences created by postgres in public.
alter default privileges in schema public
  revoke delete, truncate, references, trigger, maintain on tables from anon, authenticated;
alter default privileges in schema public
  revoke update on tables from anon;
revoke update on all sequences in schema public from anon, authenticated;
alter default privileges in schema public
  revoke update on sequences from anon, authenticated;

-- Public website reads only the fields required to render approved records.
revoke select on public.machine_sales_listings from anon;
grant select (id, machine_category, transaction_type, condition, brand_model_year,
              application_details, expected_price, location, photo_urls, seller_name, created_at)
on public.machine_sales_listings to anon;

revoke select on public.machine_part_listings from anon;
grant select (id, transaction_type, part_name, category, condition, expected_price,
              quantity, location, photo_url, details, created_at)
on public.machine_part_listings to anon;

revoke select on public.diamond_trade_listings from anon;
grant select (id, transaction_type, product_type, description, expected_price,
              quantity, location, photo_url, created_at)
on public.diamond_trade_listings to anon;

revoke select on public.job_vacancies from anon;
grant select (id, company_name, job_title, description, location, employment_type,
              salary_range, created_at)
on public.job_vacancies to anon;

revoke select on public.candidate_profiles from anon;
revoke select on public.job_applications from anon;

-- Public submissions enter moderation only; validate their input.
alter policy "Public can submit job vacancies" on public.job_vacancies
with check (
  status = 'pending'
  and length(trim(coalesce(company_name,''))) between 2 and 160
  and length(trim(coalesce(job_title,''))) between 2 and 160
  and length(trim(coalesce(description, responsibilities_skills,''))) between 2 and 3000
  and length(trim(coalesce(location, work_location,''))) between 2 and 200
  and length(trim(coalesce(contact_details,''))) between 5 and 160
);

alter policy "Public can submit job applications" on public.job_applications
with check (
  status = 'pending'
  and length(trim(coalesce(full_name,''))) between 2 and 120
  and length(trim(coalesce(role_skills,''))) between 2 and 500
  and length(trim(coalesce(preferred_location,''))) between 2 and 200
  and length(trim(coalesce(phone,''))) between 5 and 40
);

alter policy "Public can insert enquiries" on public.enquiries
with check (
  status = 'new'
  and length(trim(coalesce(name,''))) between 2 and 120
  and length(trim(coalesce(email,''))) <= 254
  and length(trim(coalesce(whatsapp,''))) <= 40
  and length(trim(coalesce(subject,''))) <= 160
  and length(trim(coalesce(message,''))) between 5 and 5000
);

-- Remove obsolete/duplicate policies. Existing admin access is email-verified.
drop policy if exists admin_read_enquiries on public.enquiries;
drop policy if exists "Public can submit pending job vacancies" on public.job_vacancies;
drop policy if exists "Public can read approved job vacancies" on public.job_vacancies;

-- Cache JWT evaluation once per statement.
alter policy "Sweksha admin read enquiries" on public.enquiries
using (lower(coalesce((select auth.jwt()) ->> 'email','')) = 'kamatrajukumar2000@gmail.com');
alter policy "Sweksha admin update enquiries" on public.enquiries
using (lower(coalesce((select auth.jwt()) ->> 'email','')) = 'kamatrajukumar2000@gmail.com')
with check (lower(coalesce((select auth.jwt()) ->> 'email','')) = 'kamatrajukumar2000@gmail.com');

alter policy "Sweksha admin read machine listings" on public.machine_sales_listings
using (status = 'approved' or lower(coalesce((select auth.jwt()) ->> 'email','')) = 'kamatrajukumar2000@gmail.com');
alter policy "Sweksha admin update machine listings" on public.machine_sales_listings
using (lower(coalesce((select auth.jwt()) ->> 'email','')) = 'kamatrajukumar2000@gmail.com')
with check (lower(coalesce((select auth.jwt()) ->> 'email','')) = 'kamatrajukumar2000@gmail.com');
alter policy "public can view approved machine listings" on public.machine_sales_listings to anon;

alter policy "Sweksha admin can read job applications" on public.job_applications
using (lower(coalesce((select auth.jwt()) ->> 'email','')) = 'kamatrajukumar2000@gmail.com');
alter policy "Sweksha admin can update job applications" on public.job_applications
using (lower(coalesce((select auth.jwt()) ->> 'email','')) = 'kamatrajukumar2000@gmail.com')
with check (lower(coalesce((select auth.jwt()) ->> 'email','')) = 'kamatrajukumar2000@gmail.com');

alter policy "Sweksha admin can read job vacancies" on public.job_vacancies
using (status = 'approved' or lower(coalesce((select auth.jwt()) ->> 'email','')) = 'kamatrajukumar2000@gmail.com');
alter policy "Sweksha admin can update job vacancies" on public.job_vacancies
using (lower(coalesce((select auth.jwt()) ->> 'email','')) = 'kamatrajukumar2000@gmail.com')
with check (lower(coalesce((select auth.jwt()) ->> 'email','')) = 'kamatrajukumar2000@gmail.com');
alter policy "Public can read approved jobs" on public.job_vacancies to anon;

alter policy "Sweksha admin read machine part listings" on public.machine_part_listings
using (status = 'approved' or lower(coalesce((select auth.jwt()) ->> 'email','')) = 'kamatrajukumar2000@gmail.com');
alter policy "Sweksha admin update machine part listings" on public.machine_part_listings
using (lower(coalesce((select auth.jwt()) ->> 'email','')) = 'kamatrajukumar2000@gmail.com')
with check (lower(coalesce((select auth.jwt()) ->> 'email','')) = 'kamatrajukumar2000@gmail.com');
alter policy "public can view approved machine part listings" on public.machine_part_listings to anon;

alter policy "Sweksha admin read diamond listings" on public.diamond_trade_listings
using (status = 'approved' or lower(coalesce((select auth.jwt()) ->> 'email','')) = 'kamatrajukumar2000@gmail.com');
alter policy "Sweksha admin update diamond listings" on public.diamond_trade_listings
using (lower(coalesce((select auth.jwt()) ->> 'email','')) = 'kamatrajukumar2000@gmail.com')
with check (lower(coalesce((select auth.jwt()) ->> 'email','')) = 'kamatrajukumar2000@gmail.com');
alter policy "public can view approved diamond listings" on public.diamond_trade_listings to anon;

-- Review moderation: public submissions are pending, public reads are approved,
-- and only the authorised admin can see the moderation queue or change status.
do $$
begin
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='reviews' and policyname='Sweksha admin read reviews') then
    create policy "Sweksha admin read reviews" on public.reviews
    for select to authenticated
    using (status = 'approved' or lower(coalesce((select auth.jwt()) ->> 'email','')) = 'kamatrajukumar2000@gmail.com');
  end if;
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='reviews' and policyname='Sweksha admin update reviews') then
    create policy "Sweksha admin update reviews" on public.reviews
    for update to authenticated
    using (lower(coalesce((select auth.jwt()) ->> 'email','')) = 'kamatrajukumar2000@gmail.com')
    with check (lower(coalesce((select auth.jwt()) ->> 'email','')) = 'kamatrajukumar2000@gmail.com');
  end if;
end $$;
alter policy "Public can read approved reviews" on public.reviews to anon;
revoke select on public.reviews from anon;
grant select (id, created_at, name, rating, review) on public.reviews to anon;

commit;
