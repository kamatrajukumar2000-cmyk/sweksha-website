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
where id in ('machine-listing-images', 'diamond-trade-images');

-- Restrictive policies are combined with existing permissive policies using AND.
-- They add a hard boundary even if another permissive INSERT policy exists.
drop policy if exists "Sweksha secure image upload constraints" on storage.objects;
create policy "Sweksha secure image upload constraints"
on storage.objects
as restrictive
for insert
to anon, authenticated
with check (
  bucket_id not in ('machine-listing-images', 'diamond-trade-images')
  or (
    bucket_id in ('machine-listing-images', 'diamond-trade-images')
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
using (bucket_id not in ('machine-listing-images', 'diamond-trade-images'))
with check (bucket_id not in ('machine-listing-images', 'diamond-trade-images'));

-- Preserve image deletion only for the authorised Sweksha admin account.
drop policy if exists "Sweksha admin-only image deletion" on storage.objects;
create policy "Sweksha admin-only image deletion"
on storage.objects
as restrictive
for delete
to anon, authenticated
using (
  bucket_id not in ('machine-listing-images', 'diamond-trade-images')
  or lower(coalesce(auth.jwt() ->> 'email', '')) = 'kamatrajukumar2000@gmail.com'
);

commit;
