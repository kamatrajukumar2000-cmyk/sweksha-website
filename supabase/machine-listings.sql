-- Sweksha all-diamond-machine marketplace
-- Run once in Supabase SQL Editor. Supports CVD/MPCVD and all diamond-processing machines.
-- Public sellers can INSERT pending listings; visitors can SELECT approved listings only.
-- Only the authorized Sweksha admin email can review and update listings.

create extension if not exists pgcrypto;

create table if not exists public.machine_sales_listings (
  id uuid primary key default gen_random_uuid(),
  machine_category text not null,
  transaction_type text not null default 'for_sale',
  condition text not null default 'used',
  brand_model_year text not null,
  application_details text,
  expected_price text,
  location text not null,
  seller_name text not null,
  seller_phone text not null,
  seller_email text,
  photo_urls text[] not null default '{}',
  additional_details text,
  status text not null default 'pending',
  admin_notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Upgrade older marketplace table versions without deleting existing records.
alter table public.machine_sales_listings add column if not exists seller_email text;
alter table public.machine_sales_listings add column if not exists photo_urls text[] not null default '{}';
alter table public.machine_sales_listings add column if not exists application_details text;
alter table public.machine_sales_listings add column if not exists additional_details text;
alter table public.machine_sales_listings add column if not exists admin_notes text;
alter table public.machine_sales_listings add column if not exists updated_at timestamptz not null default now();

-- Remove old narrow category checks (e.g. only diamond_laser / galaxy / other).
do $$
declare c record;
begin
  for c in
    select conname
    from pg_constraint
    where conrelid = 'public.machine_sales_listings'::regclass
      and contype = 'c'
      and pg_get_constraintdef(oid) ilike '%machine_category%'
  loop
    execute format('alter table public.machine_sales_listings drop constraint %I', c.conname);
  end loop;
end $$;

-- Keep transaction/status values constrained to supported workflow values.
alter table public.machine_sales_listings drop constraint if exists machine_sales_listings_transaction_type_check;
alter table public.machine_sales_listings add constraint machine_sales_listings_transaction_type_check
  check (transaction_type in ('for_sale','looking_to_buy','dealer_partnership'));

alter table public.machine_sales_listings drop constraint if exists machine_sales_listings_status_check;
alter table public.machine_sales_listings add constraint machine_sales_listings_status_check
  check (status in ('pending','approved','rejected','sold','archived'));

create index if not exists machine_sales_listings_status_created_idx
  on public.machine_sales_listings(status, created_at desc);

alter table public.machine_sales_listings enable row level security;

drop policy if exists "public can submit pending machine listings" on public.machine_sales_listings;
drop policy if exists "public can view approved machine listings" on public.machine_sales_listings;
drop policy if exists "admins manage machine sales listings" on public.machine_sales_listings;
drop policy if exists "Sweksha admin read machine listings" on public.machine_sales_listings;
drop policy if exists "Sweksha admin update machine listings" on public.machine_sales_listings;

create policy "public can submit pending machine listings"
on public.machine_sales_listings
for insert to anon, authenticated
with check (status = 'pending' and admin_notes is null);

create policy "public can view approved machine listings"
on public.machine_sales_listings
for select to anon, authenticated
using (status = 'approved');

create policy "Sweksha admin read machine listings"
on public.machine_sales_listings
for select to authenticated
using (lower(coalesce(auth.jwt() ->> 'email','')) = 'kamatrajukumar2000@gmail.com');

create policy "Sweksha admin update machine listings"
on public.machine_sales_listings
for update to authenticated
using (lower(coalesce(auth.jwt() ->> 'email','')) = 'kamatrajukumar2000@gmail.com')
with check (lower(coalesce(auth.jwt() ->> 'email','')) = 'kamatrajukumar2000@gmail.com');

grant insert, select on public.machine_sales_listings to anon;
grant select, update on public.machine_sales_listings to authenticated;

-- Public image bucket: uploads are public-read, but no public update/delete access.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('machine-listing-images','machine-listing-images',true,5242880,array['image/jpeg','image/png','image/webp'])
on conflict (id) do update set public = true, file_size_limit = 5242880,
  allowed_mime_types = array['image/jpeg','image/png','image/webp'];

drop policy if exists "public can upload machine listing images" on storage.objects;
drop policy if exists "public can view machine listing images" on storage.objects;
drop policy if exists "Sweksha admin can delete machine listing images" on storage.objects;

create policy "public can upload machine listing images"
on storage.objects for insert to anon, authenticated
with check (bucket_id = 'machine-listing-images');

create policy "public can view machine listing images"
on storage.objects for select to anon, authenticated
using (bucket_id = 'machine-listing-images');

create policy "Sweksha admin can delete machine listing images"
on storage.objects for delete to authenticated
using (bucket_id = 'machine-listing-images'
  and lower(coalesce(auth.jwt() ->> 'email','')) = 'kamatrajukumar2000@gmail.com');

-- No public UPDATE or DELETE policy is granted on listing records.
