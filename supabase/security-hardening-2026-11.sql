-- SWEKSHA current-state security hardening reference, 25 November 2026.
-- Applied changes are recorded in supabase/migrations/. Review schema before replaying.
-- No business rows or existing Storage objects are deleted by this script.
begin;

-- Remove browser-role powers that bypass RLS or are not needed by the website.
revoke delete, truncate, references, trigger on all tables in schema public from anon, authenticated;
revoke update on all tables in schema public from anon;
revoke maintain on all tables in schema public from anon, authenticated;
revoke update on all sequences in schema public from anon, authenticated;

-- Safer defaults for future public tables/sequences created by postgres.
alter default privileges in schema public revoke delete, truncate, references, trigger, maintain on tables from anon, authenticated;
alter default privileges in schema public revoke update on tables from anon;
alter default privileges in schema public revoke update on sequences from anon, authenticated;

-- Public listings expose only the fields required by the website, including status for filtering.
revoke select on public.machine_sales_listings from anon;
grant select (id,machine_category,transaction_type,condition,brand_model_year,application_details,expected_price,location,photo_urls,seller_name,created_at,status) on public.machine_sales_listings to anon;
revoke select on public.machine_part_listings from anon;
grant select (id,transaction_type,part_name,category,condition,expected_price,quantity,location,photo_url,details,created_at,status) on public.machine_part_listings to anon;
revoke select on public.diamond_trade_listings from anon;
grant select (id,transaction_type,product_type,description,expected_price,quantity,location,photo_url,created_at,status) on public.diamond_trade_listings to anon;
revoke select on public.job_vacancies from anon;
grant select (id,company_name,job_title,description,location,employment_type,salary_range,created_at,status) on public.job_vacancies to anon;
revoke select on public.candidate_profiles from anon;
revoke select on public.job_applications from anon;
revoke select on public.reviews from anon;
grant select (id,created_at,name,rating,review,status) on public.reviews to anon;

-- Public submissions must enter moderation in pending/new state and pass basic validation.
alter policy "Public can submit job vacancies" on public.job_vacancies
with check (status='pending'
  and length(trim(coalesce(company_name,''))) between 2 and 160
  and length(trim(coalesce(job_title,''))) between 2 and 160
  and length(trim(coalesce(description,responsibilities_skills,''))) between 2 and 3000
  and length(trim(coalesce(location,work_location,''))) between 2 and 200
  and length(trim(coalesce(contact_details,''))) between 5 and 160);
alter policy "Public can submit job applications" on public.job_applications
with check (status='pending'
  and length(trim(coalesce(full_name,''))) between 2 and 120
  and length(trim(coalesce(role_skills,''))) between 2 and 500
  and length(trim(coalesce(preferred_location,''))) between 2 and 200
  and length(trim(coalesce(phone,''))) between 5 and 40);
alter policy "Public can insert enquiries" on public.enquiries
with check (status='new'
  and length(trim(coalesce(name,''))) between 2 and 120
  and length(trim(coalesce(email,''))) <= 254
  and length(trim(coalesce(whatsapp,''))) <= 40
  and length(trim(coalesce(subject,''))) <= 160
  and length(trim(coalesce(message,''))) between 5 and 5000);

-- Remove obsolete/duplicate policies.
drop policy if exists admin_read_enquiries on public.enquiries;
drop policy if exists "Public can submit pending job vacancies" on public.job_vacancies;
drop policy if exists "Public can read approved job vacancies" on public.job_vacancies;

-- Admin identity checks are evaluated once per statement.
alter policy "Sweksha admin read enquiries" on public.enquiries
using (lower(coalesce((select auth.jwt())->>'email',''))='kamatrajukumar2000@gmail.com');
alter policy "Sweksha admin update enquiries" on public.enquiries
using (lower(coalesce((select auth.jwt())->>'email',''))='kamatrajukumar2000@gmail.com')
with check (lower(coalesce((select auth.jwt())->>'email',''))='kamatrajukumar2000@gmail.com');

alter policy "Sweksha admin read machine listings" on public.machine_sales_listings
using (status='approved' or lower(coalesce((select auth.jwt())->>'email',''))='kamatrajukumar2000@gmail.com');
alter policy "Sweksha admin update machine listings" on public.machine_sales_listings
using (lower(coalesce((select auth.jwt())->>'email',''))='kamatrajukumar2000@gmail.com')
with check (lower(coalesce((select auth.jwt())->>'email',''))='kamatrajukumar2000@gmail.com');
alter policy "public can view approved machine listings" on public.machine_sales_listings to anon;

alter policy "Sweksha admin can read job applications" on public.job_applications
using (lower(coalesce((select auth.jwt())->>'email',''))='kamatrajukumar2000@gmail.com');
alter policy "Sweksha admin can update job applications" on public.job_applications
using (lower(coalesce((select auth.jwt())->>'email',''))='kamatrajukumar2000@gmail.com')
with check (lower(coalesce((select auth.jwt())->>'email',''))='kamatrajukumar2000@gmail.com');
alter policy "Sweksha admin can read job vacancies" on public.job_vacancies
using (status='approved' or lower(coalesce((select auth.jwt())->>'email',''))='kamatrajukumar2000@gmail.com');
alter policy "Sweksha admin can update job vacancies" on public.job_vacancies
using (lower(coalesce((select auth.jwt())->>'email',''))='kamatrajukumar2000@gmail.com')
with check (lower(coalesce((select auth.jwt())->>'email',''))='kamatrajukumar2000@gmail.com');
alter policy "Public can read approved jobs" on public.job_vacancies to anon;

alter policy "Sweksha admin read machine part listings" on public.machine_part_listings
using (status='approved' or lower(coalesce((select auth.jwt())->>'email',''))='kamatrajukumar2000@gmail.com');
alter policy "Sweksha admin update machine part listings" on public.machine_part_listings
using (lower(coalesce((select auth.jwt())->>'email',''))='kamatrajukumar2000@gmail.com')
with check (lower(coalesce((select auth.jwt())->>'email',''))='kamatrajukumar2000@gmail.com');
alter policy "public can view approved machine part listings" on public.machine_part_listings to anon;

alter policy "Sweksha admin read diamond listings" on public.diamond_trade_listings
using (status='approved' or lower(coalesce((select auth.jwt())->>'email',''))='kamatrajukumar2000@gmail.com');
alter policy "Sweksha admin update diamond listings" on public.diamond_trade_listings
using (lower(coalesce((select auth.jwt())->>'email',''))='kamatrajukumar2000@gmail.com')
with check (lower(coalesce((select auth.jwt())->>'email',''))='kamatrajukumar2000@gmail.com');
alter policy "public can view approved diamond listings" on public.diamond_trade_listings to anon;

-- Review moderation: only approved reviews are public; admin can see and moderate all.
drop policy if exists "Sweksha admin read reviews" on public.reviews;
drop policy if exists "Sweksha admin update reviews" on public.reviews;
create policy "Sweksha admin read reviews" on public.reviews for select to authenticated
using (status='approved' or lower(coalesce((select auth.jwt())->>'email',''))='kamatrajukumar2000@gmail.com');
create policy "Sweksha admin update reviews" on public.reviews for update to authenticated
using (lower(coalesce((select auth.jwt())->>'email',''))='kamatrajukumar2000@gmail.com')
with check (lower(coalesce((select auth.jwt())->>'email',''))='kamatrajukumar2000@gmail.com');
alter policy "Public can read approved reviews" on public.reviews to anon;

-- Public Storage image buckets: retain public URL access but block public object listing.
-- Upload names accept current production legacy names and new UUID WebP names.
drop policy if exists "public can upload machine listing images" on storage.objects;
drop policy if exists "public can view machine listing images" on storage.objects;
drop policy if exists "public can upload machine part images" on storage.objects;
drop policy if exists "public can view machine part images" on storage.objects;
drop policy if exists "public can upload diamond trade images" on storage.objects;
drop policy if exists "public can view diamond trade images" on storage.objects;
drop policy if exists "public can upload machine-listing-images objects" on storage.objects;
drop policy if exists "Sweksha admin can list machine listing images" on storage.objects;
drop policy if exists "public can upload machine-part-images objects" on storage.objects;
drop policy if exists "Sweksha admin can list machine part images" on storage.objects;
drop policy if exists "public can upload diamond-trade-images objects" on storage.objects;
drop policy if exists "Sweksha admin can list diamond trade images" on storage.objects;

create policy "public can upload machine-listing-images objects" on storage.objects for insert to anon,authenticated
with check (bucket_id='machine-listing-images' and name ~* '^(?:[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}[.]webp|[0-9]{13}-[a-z0-9]{8,16}([.](webp|jpg|jpeg|png)|-(webp|jpg|jpeg|png)))$');
create policy "Sweksha admin can list machine listing images" on storage.objects for select to authenticated
using (bucket_id='machine-listing-images' and lower(coalesce((select auth.jwt())->>'email',''))='kamatrajukumar2000@gmail.com');

create policy "public can upload machine-part-images objects" on storage.objects for insert to anon,authenticated
with check (bucket_id='machine-part-images' and name ~* '^(?:[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}[.]webp|[0-9]{13}-[a-z0-9]{8,16}([.](webp|jpg|jpeg|png)|-(webp|jpg|jpeg|png)))$');
create policy "Sweksha admin can list machine part images" on storage.objects for select to authenticated
using (bucket_id='machine-part-images' and lower(coalesce((select auth.jwt())->>'email',''))='kamatrajukumar2000@gmail.com');

create policy "public can upload diamond-trade-images objects" on storage.objects for insert to anon,authenticated
with check (bucket_id='diamond-trade-images' and name ~* '^(?:[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}[.]webp|[0-9]{13}-[a-z0-9]{8,16}([.](webp|jpg|jpeg|png)|-(webp|jpg|jpeg|png)))$');
create policy "Sweksha admin can list diamond trade images" on storage.objects for select to authenticated
using (bucket_id='diamond-trade-images' and lower(coalesce((select auth.jwt())->>'email',''))='kamatrajukumar2000@gmail.com');

-- This legacy table is not used by the current site and previously exposed contact columns.
revoke all privileges on table public.marketplace_listings from anon,authenticated;
drop policy if exists "Public can read approved listings" on public.marketplace_listings;

-- Candidate profiles are a legacy table not used by the current Jobs page.
revoke all privileges on table public.candidate_profiles from anon,authenticated;
drop policy if exists "Public can submit pending candidate profiles" on public.candidate_profiles;


-- Enforce conservative maximum input sizes at the database boundary.
alter policy "public can submit pending machine listings" on public.machine_sales_listings
with check (status='pending' and admin_notes is null
  and length(trim(coalesce(machine_category,''))) between 1 and 120
  and length(trim(coalesce(brand_model_year,''))) between 1 and 200
  and length(trim(coalesce(condition,''))) <= 120
  and length(trim(coalesce(application_details,''))) <= 3000
  and length(trim(coalesce(additional_details,''))) <= 3000
  and length(trim(coalesce(expected_price,''))) <= 120
  and length(trim(coalesce(location,''))) between 1 and 200
  and length(trim(coalesce(seller_name,''))) between 1 and 120
  and length(trim(coalesce(seller_phone,''))) between 5 and 40
  and length(trim(coalesce(seller_email,''))) <= 254
  and coalesce(cardinality(photo_urls),0) <= 5);
alter policy "public can submit pending machine part listings" on public.machine_part_listings
with check (status='pending' and admin_notes is null
  and length(trim(coalesce(part_name,''))) between 1 and 160
  and length(trim(coalesce(category,''))) between 1 and 120
  and length(trim(coalesce(condition,''))) <= 120
  and length(trim(coalesce(expected_price,''))) <= 120
  and quantity between 1 and 100000
  and length(trim(coalesce(location,''))) between 1 and 200
  and length(trim(coalesce(details,''))) <= 3000
  and length(trim(coalesce(contact_name,''))) between 1 and 120
  and length(trim(coalesce(contact_phone,''))) between 5 and 40);
alter policy "public can submit pending diamond listings" on public.diamond_trade_listings
with check (status='pending' and admin_notes is null
  and length(trim(coalesce(product_type,''))) between 1 and 160
  and length(trim(coalesce(description,''))) <= 3000
  and length(trim(coalesce(expected_price,''))) <= 120
  and length(trim(coalesce(quantity,''))) <= 120
  and length(trim(coalesce(location,''))) <= 200
  and length(trim(coalesce(contact_name,''))) between 1 and 120
  and length(trim(coalesce(contact_phone,''))) between 5 and 40);
alter policy "Public can submit job applications" on public.job_applications
with check (status='pending'
  and length(trim(coalesce(full_name,''))) between 2 and 120
  and length(trim(coalesce(role_skills,''))) between 2 and 500
  and length(trim(coalesce(experience_qualifications,''))) <= 2000
  and length(trim(coalesce(preferred_location,''))) between 2 and 200
  and length(trim(coalesce(phone,''))) between 5 and 40);
alter policy "Public can submit job vacancies" on public.job_vacancies
with check (status='pending'
  and length(trim(coalesce(company_name,''))) between 2 and 160
  and length(trim(coalesce(job_title,''))) between 2 and 160
  and length(trim(coalesce(description,responsibilities_skills,''))) between 2 and 3000
  and length(trim(coalesce(location,work_location,''))) between 2 and 200
  and length(trim(coalesce(employment_type,''))) <= 80
  and length(trim(coalesce(salary_range,pay_range,''))) <= 120
  and length(trim(coalesce(contact_details,''))) between 5 and 160);
alter policy "Public can submit pending reviews" on public.reviews
with check (status='pending' and rating between 1 and 5
  and length(trim(coalesce(name,''))) between 1 and 120
  and length(trim(coalesce(review,''))) between 1 and 1600);

commit;
