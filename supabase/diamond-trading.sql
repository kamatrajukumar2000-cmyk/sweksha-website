-- Sweksha Diamond Trading Marketplace schema
-- Run this file in the SQL Editor of the ACTIVE project: ftvfumhxcpakskhbcuup
create extension if not exists pgcrypto;

create table if not exists public.diamond_trade_listings (
  id uuid primary key default gen_random_uuid(),
  transaction_type text not null check (transaction_type in ('looking_to_buy','for_sale')),
  product_type text not null,
  description text,
  expected_price text,
  quantity text,
  location text,
  photo_url text,
  contact_name text not null,
  contact_phone text not null,
  status text not null default 'pending'
    check (status in ('pending','approved','rejected','sold','archived')),
  admin_notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.diamond_trade_listings enable row level security;

drop policy if exists "public can submit pending diamond listings" on public.diamond_trade_listings;
drop policy if exists "public can view approved diamond listings" on public.diamond_trade_listings;
drop policy if exists "Sweksha admin read diamond listings" on public.diamond_trade_listings;
drop policy if exists "Sweksha admin update diamond listings" on public.diamond_trade_listings;

create policy "public can submit pending diamond listings"
on public.diamond_trade_listings for insert to anon, authenticated
with check (status = 'pending' and admin_notes is null);

create policy "public can view approved diamond listings"
on public.diamond_trade_listings for select to anon, authenticated
using (status = 'approved');

create policy "Sweksha admin read diamond listings"
on public.diamond_trade_listings for select to authenticated
using (lower(coalesce(auth.jwt() ->> 'email','')) = 'kamatrajukumar2000@gmail.com');

create policy "Sweksha admin update diamond listings"
on public.diamond_trade_listings for update to authenticated
using (lower(coalesce(auth.jwt() ->> 'email','')) = 'kamatrajukumar2000@gmail.com')
with check (lower(coalesce(auth.jwt() ->> 'email','')) = 'kamatrajukumar2000@gmail.com');

grant insert, select on public.diamond_trade_listings to anon;
grant select, update on public.diamond_trade_listings to authenticated;

insert into storage.buckets (id,name,public,file_size_limit,allowed_mime_types)
values ('diamond-trade-images','diamond-trade-images',true,5242880,array['image/jpeg','image/png','image/webp'])
on conflict (id) do update set public=true,file_size_limit=5242880,
  allowed_mime_types=array['image/jpeg','image/png','image/webp'];

drop policy if exists "public can upload diamond trade images" on storage.objects;
drop policy if exists "public can view diamond trade images" on storage.objects;
drop policy if exists "Sweksha admin can delete diamond trade images" on storage.objects;

create policy "public can upload diamond trade images"
on storage.objects for insert to anon, authenticated
with check (bucket_id='diamond-trade-images');

create policy "public can view diamond trade images"
on storage.objects for select to anon, authenticated
using (bucket_id='diamond-trade-images');

create policy "Sweksha admin can delete diamond trade images"
on storage.objects for delete to authenticated
using (bucket_id='diamond-trade-images'
  and lower(coalesce(auth.jwt() ->> 'email',''))='kamatrajukumar2000@gmail.com');
