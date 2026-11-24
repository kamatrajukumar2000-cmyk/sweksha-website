-- SWEKSHA Diamond Trading Marketplace.
-- Safe to run after reviewing the current project. Existing rows are retained.
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
  status text not null default 'pending' check (status in ('pending','approved','rejected','sold','archived')),
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
on public.diamond_trade_listings for insert to anon,authenticated
with check (
  status='pending' and admin_notes is null
  and length(trim(coalesce(product_type,''))) between 1 and 160
  and length(trim(coalesce(description,''))) <= 3000
  and length(trim(coalesce(expected_price,''))) <= 120
  and length(trim(coalesce(quantity,''))) <= 120
  and length(trim(coalesce(location,''))) <= 200
  and length(trim(coalesce(contact_name,''))) between 1 and 120
  and length(trim(coalesce(contact_phone,''))) between 5 and 40
);
create policy "public can view approved diamond listings"
on public.diamond_trade_listings for select to anon using (status='approved');
create policy "Sweksha admin read diamond listings"
on public.diamond_trade_listings for select to authenticated
using (status='approved' or lower(coalesce((select auth.jwt())->>'email',''))='kamatrajukumar2000@gmail.com');
create policy "Sweksha admin update diamond listings"
on public.diamond_trade_listings for update to authenticated
using (lower(coalesce((select auth.jwt())->>'email',''))='kamatrajukumar2000@gmail.com')
with check (lower(coalesce((select auth.jwt())->>'email',''))='kamatrajukumar2000@gmail.com');

revoke select on public.diamond_trade_listings from anon;
grant insert on public.diamond_trade_listings to anon,authenticated;
grant select (id,transaction_type,product_type,description,expected_price,quantity,location,photo_url,created_at,status)
on public.diamond_trade_listings to anon;
grant select,update on public.diamond_trade_listings to authenticated;

insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values('diamond-trade-images','diamond-trade-images',true,5242880,array['image/jpeg','image/png','image/webp'])
on conflict(id) do update set public=true,file_size_limit=5242880,allowed_mime_types=array['image/jpeg','image/png','image/webp'];

drop policy if exists "public can upload diamond trade images" on storage.objects;
drop policy if exists "public can view diamond trade images" on storage.objects;
drop policy if exists "Sweksha admin can delete diamond trade images" on storage.objects;
drop policy if exists "public can upload diamond-trade-images objects" on storage.objects;
drop policy if exists "Sweksha admin can list diamond trade images" on storage.objects;
drop policy if exists "Sweksha admin can delete diamond trade images" on storage.objects;

create policy "public can upload diamond-trade-images objects"
on storage.objects for insert to anon,authenticated
with check (bucket_id='diamond-trade-images' and name ~* '^(?:[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}[.]webp|[0-9]{13}-[a-z0-9]{8,16}([.](webp|jpg|jpeg|png)|-(webp|jpg|jpeg|png)))$');
create policy "Sweksha admin can list diamond trade images"
on storage.objects for select to authenticated
using (bucket_id='diamond-trade-images' and lower(coalesce((select auth.jwt())->>'email',''))='kamatrajukumar2000@gmail.com');
create policy "Sweksha admin can delete diamond trade images"
on storage.objects for delete to authenticated
using (bucket_id='diamond-trade-images' and lower(coalesce((select auth.jwt())->>'email',''))='kamatrajukumar2000@gmail.com');
