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
drop policy if exists "public can view machine part images" on storage.objects;
create policy "Sweksha admin can list machine part images"
on storage.objects for select to authenticated
using (
  bucket_id = 'machine-part-images'
  and lower(coalesce((select auth.jwt()) ->> 'email','')) = 'kamatrajukumar2000@gmail.com'
);

create policy "Sweksha admin can delete machine part images"
on storage.objects for delete to authenticated
using (bucket_id='machine-part-images'
  and lower(coalesce(auth.jwt() ->> 'email','')) = 'kamatrajukumar2000@gmail.com');
