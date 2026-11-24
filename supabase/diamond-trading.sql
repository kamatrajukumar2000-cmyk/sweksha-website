-- Sweksha Diamond Trading Marketplace schema
-- Run this file in the SQL Editor of the existing Trading project: xotqafgkubodqpirfpfb (https://xotqafgkubodqpirfpfb.supabase.co). Existing listing rows are retained.
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
drop policy if exists "public can view diamond trade images" on storage.objects;
create policy "public can upload diamond-trade-images objects"
on storage.objects for insert to anon, authenticated
with check (
  bucket_id = 'diamond-trade-images'
  and name ~* '^(?:[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}[.]webp|[0-9]{13}-[a-z0-9]{8,16}([.](webp|jpg|jpeg|png)|-(webp|jpg|jpeg|png)))
);

create policy "Sweksha admin can list diamond trade images"
on storage.objects for select to authenticated
using (
  bucket_id = 'diamond-trade-images'
  and lower(coalesce((select auth.jwt()) ->> 'email','')) = 'kamatrajukumar2000@gmail.com'
);

create policy "Sweksha admin can delete diamond trade images"
on storage.objects for delete to authenticated
using (bucket_id='diamond-trade-images'
  and lower(coalesce(auth.jwt() ->> 'email',''))='kamatrajukumar2000@gmail.com');

-- Required for public approved-status filters; no private contact columns are exposed.
grant select (status) on public.diamond_trade_listings to anon;

);

create policy "Sweksha admin can list diamond trade images"
on storage.objects for select to authenticated
using (
  bucket_id = 'diamond-trade-images'
  and lower(coalesce((select auth.jwt()) ->> 'email','')) = 'kamatrajukumar2000@gmail.com'
);

create policy "Sweksha admin can delete diamond trade images"
on storage.objects for delete to authenticated
using (bucket_id='diamond-trade-images'
  and lower(coalesce(auth.jwt() ->> 'email',''))='kamatrajukumar2000@gmail.com');

-- Required for public approved-status filters; no private contact columns are exposed.
grant select (status) on public.diamond_trade_listings to anon;
