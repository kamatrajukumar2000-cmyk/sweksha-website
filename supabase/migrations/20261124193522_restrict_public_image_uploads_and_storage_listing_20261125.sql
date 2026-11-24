-- Restrict public uploads to known image filename patterns and admin-only object listing.
-- Public bucket URLs remain accessible for direct image rendering.
drop policy if exists "public can upload machine-listing-images images" on storage.objects;
drop policy if exists "public can upload machine-listing-images objects" on storage.objects;
drop policy if exists "public can view machine listing images" on storage.objects;
create policy "public can upload machine-listing-images objects" on storage.objects for insert to anon, authenticated
with check (bucket_id='machine-listing-images' and name ~* '^(?:[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}[.]webp|[0-9]{13}-[a-z0-9]{8,16}([.](webp|jpg|jpeg|png)|-(webp|jpg|jpeg|png)))$');
create policy "Sweksha admin can list machine listing images" on storage.objects for select to authenticated
using (bucket_id='machine-listing-images' and lower(coalesce((select auth.jwt()) ->> 'email',''))='kamatrajukumar2000@gmail.com');

drop policy if exists "public can upload machine-part-images images" on storage.objects;
drop policy if exists "public can upload machine-part-images objects" on storage.objects;
drop policy if exists "public can view machine part images" on storage.objects;
create policy "public can upload machine-part-images objects" on storage.objects for insert to anon, authenticated
with check (bucket_id='machine-part-images' and name ~* '^(?:[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}[.]webp|[0-9]{13}-[a-z0-9]{8,16}([.](webp|jpg|jpeg|png)|-(webp|jpg|jpeg|png)))$');
create policy "Sweksha admin can list machine part images" on storage.objects for select to authenticated
using (bucket_id='machine-part-images' and lower(coalesce((select auth.jwt()) ->> 'email',''))='kamatrajukumar2000@gmail.com');

drop policy if exists "public can upload diamond-trade-images images" on storage.objects;
drop policy if exists "public can upload diamond-trade-images objects" on storage.objects;
drop policy if exists "public can view diamond trade images" on storage.objects;
create policy "public can upload diamond-trade-images objects" on storage.objects for insert to anon, authenticated
with check (bucket_id='diamond-trade-images' and name ~* '^(?:[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}[.]webp|[0-9]{13}-[a-z0-9]{8,16}([.](webp|jpg|jpeg|png)|-(webp|jpg|jpeg|png)))$');
create policy "Sweksha admin can list diamond trade images" on storage.objects for select to authenticated
using (bucket_id='diamond-trade-images' and lower(coalesce((select auth.jwt()) ->> 'email',''))='kamatrajukumar2000@gmail.com');
