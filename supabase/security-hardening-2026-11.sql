-- SWEKSHA storage hardening migration — 2026-11
-- Apply this migration in the Supabase SQL Editor for project xotqafgkubodqpirfpfb.
-- It does not delete existing listings or image objects.
-- Public image reads remain enabled; public uploads are limited to random UUID .webp objects.
-- Bucket-level limits enforce a maximum of 5 MiB and image/webp content type.

begin;

update storage.buckets
set public = true,
    file_size_limit = 5242880,
    allowed_mime_types = array['image/webp']
where id in ('machine-listing-images', 'diamond-trade-images', 'machine-part-images');

-- Restrictive policies are combined with existing permissive policies using AND.
-- They add hard boundaries even if another permissive policy exists.

-- Customer enquiries: submissions are always new; only the admin can read/update.
alter table public.enquiries enable row level security;

drop policy if exists "Sweksha restrict enquiry submissions" on public.enquiries;
create policy "Sweksha restrict enquiry submissions"
on public.enquiries as restrictive
for insert to anon, authenticated
with check (
  status = 'new'
  and length(trim(name)) between 2 and 120
  and (email is null or length(trim(email)) <= 254)
  and length(trim(whatsapp)) between 5 and 50
  and length(trim(subject)) between 2 and 300
  and length(trim(message)) between 5 and 5000
);

drop policy if exists "Sweksha restrict enquiry reads" on public.enquiries;
create policy "Sweksha restrict enquiry reads"
on public.enquiries as restrictive
for select to anon, authenticated
using (
  auth.role() = 'authenticated'
  and lower(coalesce(auth.jwt() ->> 'email', '')) = 'kamatrajukumar2000@gmail.com'
);

drop policy if exists "Sweksha restrict enquiry updates" on public.enquiries;
create policy "Sweksha restrict enquiry updates"
on public.enquiries as restrictive
for update to authenticated
using (lower(coalesce(auth.jwt() ->> 'email', '')) = 'kamatrajukumar2000@gmail.com')
with check (lower(coalesce(auth.jwt() ->> 'email', '')) = 'kamatrajukumar2000@gmail.com');

-- Job seeker profiles are private; approved vacancies expose only public fields.
alter table public.job_applications enable row level security;
alter table public.job_vacancies enable row level security;

drop policy if exists "Sweksha restrict candidate profile submissions" on public.job_applications;
create policy "Sweksha restrict candidate profile submissions"
on public.job_applications as restrictive
for insert to anon, authenticated
with check (
  status = 'pending'
  and length(trim(full_name)) between 2 and 120
  and length(trim(role_skills)) between 2 and 500
  and length(trim(preferred_location)) between 2 and 200
  and length(trim(phone)) between 5 and 40
  and (experience_qualifications is null or length(experience_qualifications) <= 2000)
);

drop policy if exists "Sweksha restrict candidate profile reads" on public.job_applications;
create policy "Sweksha restrict candidate profile reads"
on public.job_applications as restrictive
for select to anon, authenticated
using (
  auth.role() = 'authenticated'
  and lower(coalesce(auth.jwt() ->> 'email', '')) = 'kamatrajukumar2000@gmail.com'
);

drop policy if exists "Sweksha restrict candidate profile updates" on public.job_applications;
create policy "Sweksha restrict candidate profile updates"
on public.job_applications as restrictive
for update to authenticated
using (lower(coalesce(auth.jwt() ->> 'email', '')) = 'kamatrajukumar2000@gmail.com')
with check (lower(coalesce(auth.jwt() ->> 'email', '')) = 'kamatrajukumar2000@gmail.com');

drop policy if exists "Sweksha restrict vacancy submissions" on public.job_vacancies;
create policy "Sweksha restrict vacancy submissions"
on public.job_vacancies as restrictive
for insert to anon, authenticated
with check (
  status = 'pending'
  and length(trim(company_name)) between 2 and 160
  and length(trim(job_title)) between 2 and 160
  and length(trim(coalesce(description, responsibilities_skills, ''))) between 2 and 3000
  and length(trim(coalesce(location, work_location, ''))) between 2 and 200
  and length(trim(contact_details)) between 5 and 160
);

drop policy if exists "Sweksha restrict vacancy reads" on public.job_vacancies;
create policy "Sweksha restrict vacancy reads"
on public.job_vacancies as restrictive
for select to anon, authenticated
using (
  (auth.role() = 'anon' and status = 'approved')
  or (auth.role() = 'authenticated'
      and lower(coalesce(auth.jwt() ->> 'email', '')) = 'kamatrajukumar2000@gmail.com')
);

drop policy if exists "Sweksha restrict vacancy updates" on public.job_vacancies;
create policy "Sweksha restrict vacancy updates"
on public.job_vacancies as restrictive
for update to authenticated
using (lower(coalesce(auth.jwt() ->> 'email', '')) = 'kamatrajukumar2000@gmail.com')
with check (lower(coalesce(auth.jwt() ->> 'email', '')) = 'kamatrajukumar2000@gmail.com');

-- Prevent direct public reads of job applicant contact details and employer contacts.
revoke select on public.job_applications from anon;
revoke select on public.job_vacancies from anon;
grant select (id, company_name, job_title, description, location, employment_type, salary_range, created_at)
  on public.job_vacancies to anon;


-- Marketplace rows: public can read approved listings only; anonymous submissions
-- must remain pending; only the authorised admin can review or change records.
alter table public.machine_sales_listings enable row level security;
alter table public.machine_part_listings enable row level security;
alter table public.diamond_trade_listings enable row level security;

-- Do not expose seller/buyer phone numbers, email addresses, or admin notes
-- through the public PostgREST role. Admin sessions retain their existing full
-- table grants and are still constrained by the admin-only RLS branch.
revoke select on public.machine_sales_listings from anon;
grant select (id, machine_category, transaction_type, condition, brand_model_year, application_details, expected_price, location, photo_urls, created_at)
  on public.machine_sales_listings to anon;

revoke select on public.machine_part_listings from anon;
grant select (id, transaction_type, part_name, category, condition, expected_price, quantity, location, photo_url, details, created_at)
  on public.machine_part_listings to anon;

revoke select on public.diamond_trade_listings from anon;
grant select (id, transaction_type, product_type, description, expected_price, quantity, location, photo_url, created_at)
  on public.diamond_trade_listings to anon;

drop policy if exists "Sweksha restrict machine listing reads" on public.machine_sales_listings;
create policy "Sweksha restrict machine listing reads"
on public.machine_sales_listings as restrictive
for select to anon, authenticated
using (
  (auth.role() = 'anon' and status = 'approved')
  or (auth.role() = 'authenticated'
      and lower(coalesce(auth.jwt() ->> 'email', '')) = 'kamatrajukumar2000@gmail.com')
);

drop policy if exists "Sweksha restrict machine listing submissions" on public.machine_sales_listings;
create policy "Sweksha restrict machine listing submissions"
on public.machine_sales_listings as restrictive
for insert to anon, authenticated
with check (
  status = 'pending' and admin_notes is null
  and length(trim(machine_category)) between 2 and 80
  and length(trim(brand_model_year)) between 2 and 140
  and length(trim(location)) between 2 and 120
  and length(trim(seller_name)) between 2 and 120
  and length(trim(seller_phone)) between 5 and 40
  and (seller_email is null or length(trim(seller_email)) <= 160)
  and (application_details is null or length(application_details) <= 1500)
  and (additional_details is null or length(additional_details) <= 1500)
  and (expected_price is null or length(trim(expected_price)) <= 100)
);

drop policy if exists "Sweksha restrict machine listing updates" on public.machine_sales_listings;
create policy "Sweksha restrict machine listing updates"
on public.machine_sales_listings as restrictive
for update to authenticated
using (lower(coalesce(auth.jwt() ->> 'email', '')) = 'kamatrajukumar2000@gmail.com')
with check (lower(coalesce(auth.jwt() ->> 'email', '')) = 'kamatrajukumar2000@gmail.com');

drop policy if exists "Sweksha restrict machine part reads" on public.machine_part_listings;
create policy "Sweksha restrict machine part reads"
on public.machine_part_listings as restrictive
for select to anon, authenticated
using (
  (auth.role() = 'anon' and status = 'approved')
  or (auth.role() = 'authenticated'
      and lower(coalesce(auth.jwt() ->> 'email', '')) = 'kamatrajukumar2000@gmail.com')
);

drop policy if exists "Sweksha restrict machine part submissions" on public.machine_part_listings;
create policy "Sweksha restrict machine part submissions"
on public.machine_part_listings as restrictive
for insert to anon, authenticated
with check (
  status = 'pending' and admin_notes is null
  and length(trim(part_name)) between 2 and 120
  and length(trim(category)) between 2 and 80
  and length(trim(location)) between 2 and 120
  and length(trim(contact_name)) between 2 and 120
  and length(trim(contact_phone)) between 5 and 40
  and quantity between 1 and 10000
  and (details is null or length(details) <= 1500)
  and (expected_price is null or length(trim(expected_price)) <= 100)
);

drop policy if exists "Sweksha restrict machine part updates" on public.machine_part_listings;
create policy "Sweksha restrict machine part updates"
on public.machine_part_listings as restrictive
for update to authenticated
using (lower(coalesce(auth.jwt() ->> 'email', '')) = 'kamatrajukumar2000@gmail.com')
with check (lower(coalesce(auth.jwt() ->> 'email', '')) = 'kamatrajukumar2000@gmail.com');

drop policy if exists "Sweksha restrict diamond listing reads" on public.diamond_trade_listings;
create policy "Sweksha restrict diamond listing reads"
on public.diamond_trade_listings as restrictive
for select to anon, authenticated
using (
  (auth.role() = 'anon' and status = 'approved')
  or (auth.role() = 'authenticated'
      and lower(coalesce(auth.jwt() ->> 'email', '')) = 'kamatrajukumar2000@gmail.com')
);

drop policy if exists "Sweksha restrict diamond listing submissions" on public.diamond_trade_listings;
create policy "Sweksha restrict diamond listing submissions"
on public.diamond_trade_listings as restrictive
for insert to anon, authenticated
with check (
  status = 'pending' and admin_notes is null
  and length(trim(product_type)) between 2 and 100
  and length(trim(contact_name)) between 2 and 120
  and length(trim(contact_phone)) between 5 and 40
  and (description is null or length(description) <= 1500)
  and (expected_price is null or length(trim(expected_price)) <= 100)
  and (quantity is null or length(trim(quantity)) <= 100)
  and (location is null or length(trim(location)) <= 120)
);

drop policy if exists "Sweksha restrict diamond listing updates" on public.diamond_trade_listings;
create policy "Sweksha restrict diamond listing updates"
on public.diamond_trade_listings as restrictive
for update to authenticated
using (lower(coalesce(auth.jwt() ->> 'email', '')) = 'kamatrajukumar2000@gmail.com')
with check (lower(coalesce(auth.jwt() ->> 'email', '')) = 'kamatrajukumar2000@gmail.com');
drop policy if exists "Sweksha secure image upload constraints" on storage.objects;
create policy "Sweksha secure image upload constraints"
on storage.objects
as restrictive
for insert
to anon, authenticated
with check (
  bucket_id not in ('machine-listing-images', 'diamond-trade-images', 'machine-part-images')
  or (
    bucket_id in ('machine-listing-images', 'diamond-trade-images', 'machine-part-images')
    and name ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}[.]webp$'
  )
);

-- Prevent replacement of public listing images by anonymous or ordinary authenticated users.
drop policy if exists "Sweksha prevent image replacement" on storage.objects;
create policy "Sweksha prevent image replacement"
on storage.objects
as restrictive
for update
to anon, authenticated
using (bucket_id not in ('machine-listing-images', 'diamond-trade-images', 'machine-part-images'))
with check (bucket_id not in ('machine-listing-images', 'diamond-trade-images', 'machine-part-images'));

-- Preserve image deletion only for the authorised Sweksha admin account.
-- This permissive policy pairs with the restrictive admin-only delete boundary below.
drop policy if exists "Sweksha admin delete secured listing images" on storage.objects;
create policy "Sweksha admin delete secured listing images"
on storage.objects
for delete
to authenticated
using (
  bucket_id in ('machine-listing-images', 'diamond-trade-images', 'machine-part-images')
  and lower(coalesce(auth.jwt() ->> 'email', '')) = 'kamatrajukumar2000@gmail.com'
);

drop policy if exists "Sweksha admin-only image deletion" on storage.objects;
create policy "Sweksha admin-only image deletion"
on storage.objects
as restrictive
for delete
to anon, authenticated
using (
  bucket_id not in ('machine-listing-images', 'diamond-trade-images', 'machine-part-images')
  or lower(coalesce(auth.jwt() ->> 'email', '')) = 'kamatrajukumar2000@gmail.com'
);

commit;
