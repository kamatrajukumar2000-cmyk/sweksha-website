-- Sweksha Machine Parts Marketplace
-- Run this complete file once in Supabase SQL Editor.
create extension if not exists pgcrypto;

create table if not exists public.machine_part_listings (
  id uuid primary key default gen_random_uuid(),
  transaction_type text not null check (transaction_type in ('looking_to_buy','for_sale')),
  part_name text not null,
  category text not null,
  condition text,
  expected_price text,
  quantity integer not null default 1 check (quantity > 0),
  location text not null,
  photo_url text,
  details text,
  contact_name text not null,
  contact_phone text not null,
  status text not null default 'pending' check (status in ('pending','approved','rejected','sold','archived')),
  admin_notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.machine_part_listings enable row level security;
drop policy if exists "public can submit pending machine part listings" on public.machine_part_listings;
drop policy if exists "public can view approved machine part listings" on public.machine_part_listings;
drop policy if exists "Sweksha admin read machine part listings" on public.machine_part_listings;
drop policy if exists "Sweksha admin update machine part listings" on public.machine_part_listings;

create policy "public can submit pending machine part listings"
on public.machine_part_listings for insert to anon, authenticated
with check (status = 'pending' and admin_notes is null);

create policy "public can view approved machine part listings"
on public.machine_part_listings for select to anon, authenticated
using (status = 'approved');

create policy "Sweksha admin read machine part listings"
on public.machine_part_listings for select to authenticated
using (lower(coalesce(auth.jwt() ->> 'email','')) = 'kamatrajukumar2000@gmail.com');

create policy "Sweksha admin update machine part listings"
on public.machine_part_listings for update to authenticated
using (lower(coalesce(auth.jwt() ->> 'email','')) = 'kamatrajukumar2000@gmail.com')
with check (lower(coalesce(auth.jwt() ->> 'email','')) = 'kamatrajukumar2000@gmail.com');

grant insert, select on public.machine_part_listings to anon;
grant select, update on public.machine_part_listings to authenticated;

insert into storage.buckets (id,name,public,file_size_limit,allowed_mime_types)
values ('machine-part-images','machine-part-images',true,5242880,array['image/jpeg','image/png','image/webp'])
on conflict (id) do update set public=true,file_size_limit=5242880,allowed_mime_types=array['image/jpeg','image/png','image/webp'];

drop policy if exists "public can upload machine part images" on storage.objects;
drop policy if exists "public can view machine part images" on storage.objects;
drop policy if exists "Sweksha admin can delete machine part images" on storage.objects;

create policy "public can upload machine part images"
on storage.objects for insert to anon, authenticated
with check (bucket_id='machine-part-images');

create policy "public can view machine part images"
on storage.objects for select to anon, authenticated
using (bucket_id='machine-part-images');

create policy "Sweksha admin can delete machine part images"
on storage.objects for delete to authenticated
using (bucket_id='machine-part-images'
  and lower(coalesce(auth.jwt() ->> 'email','')) = 'kamatrajukumar2000@gmail.com');
