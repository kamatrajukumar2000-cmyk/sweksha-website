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

-- Marketplace rows: public can read approved listings only; anonymous submissions
-- must remain pending; only the authorised admin can review or change records.
alter table public.machine_sales_listings enable row level security;
alter table public.machine_part_listings enable row level security;
alter table public.diamond_trade_listings enable row level security;

drop policy if exists "Sweksha restrict machine listing reads" on public.machine_sales_listings;
create policy "Sweksha restrict machine listing reads"
on public.machine_sales_listings as restrictive
for select to anon, authenticated
using (
  status = 'approved'
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
  status = 'approved'
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
  status = 'approved'
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
