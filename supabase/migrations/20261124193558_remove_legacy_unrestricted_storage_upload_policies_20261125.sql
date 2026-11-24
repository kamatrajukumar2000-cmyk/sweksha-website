-- Remove the original unrestricted anonymous Storage upload policies.
drop policy if exists "public can upload machine listing images" on storage.objects;
drop policy if exists "public can upload machine part images" on storage.objects;
drop policy if exists "public can upload diamond trade images" on storage.objects;
drop policy if exists "public can upload machine-listing-images objects" on storage.objects;
drop policy if exists "public can upload machine-part-images objects" on storage.objects;
drop policy if exists "public can upload diamond-trade-images objects" on storage.objects;

create policy "public can upload machine-listing-images objects"
on storage.objects for insert to anon, authenticated
with check (bucket_id='machine-listing-images' and name ~* '^(?:[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}[.]webp|[0-9]{13}-[a-z0-9]{8,16}([.](webp|jpg|jpeg|png)|-(webp|jpg|jpeg|png)))$');

create policy "public can upload machine-part-images objects"
on storage.objects for insert to anon, authenticated
with check (bucket_id='machine-part-images' and name ~* '^(?:[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}[.]webp|[0-9]{13}-[a-z0-9]{8,16}([.](webp|jpg|jpeg|png)|-(webp|jpg|jpeg|png)))$');

create policy "public can upload diamond-trade-images objects"
on storage.objects for insert to anon, authenticated
with check (bucket_id='diamond-trade-images' and name ~* '^(?:[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}[.]webp|[0-9]{13}-[a-z0-9]{8,16}([.](webp|jpg|jpeg|png)|-(webp|jpg|jpeg|png)))$');
