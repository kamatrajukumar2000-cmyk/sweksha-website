-- Sweksha Laser & Galaxy machine listings
-- Run this SQL in the Supabase SQL Editor after confirming your project is active.
-- Public sellers may submit ONLY pending listings. Public visitors can read ONLY approved listings.
-- Admins are identified through public.admin_users (created by supabase/schema.sql).

create table if not exists public.machine_sales_listings (
  id uuid primary key default gen_random_uuid(),
  machine_category text not null check (machine_category in ('diamond_laser','galaxy','other')),
  transaction_type text not null check (transaction_type in ('for_sale','looking_to_buy','dealer_partnership')),
  condition text not null check (condition in ('new','used','unknown')),
  brand_model_year text not null check (char_length(brand_model_year) between 2 and 140),
  application_details text,
  expected_price text,
  location text not null,
  seller_name text not null,
  seller_phone text not null,
  seller_email text,
  photo_urls text[] not null default '{}',
  additional_details text,
  status text not null default 'pending' check (status in ('pending','approved','rejected','sold','archived')),
  admin_notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists machine_sales_listings_status_created_idx
  on public.machine_sales_listings(status, created_at desc);

alter table public.machine_sales_listings enable row level security;

drop policy if exists "public can submit pending machine listings" on public.machine_sales_listings;
create policy "public can submit pending machine listings"
on public.machine_sales_listings
for insert
to anon, authenticated
with check (status = 'pending' and admin_notes is null);

drop policy if exists "public can view approved machine listings" on public.machine_sales_listings;
create policy "public can view approved machine listings"
on public.machine_sales_listings
for select
to anon, authenticated
using (status = 'approved');

drop policy if exists "admins manage machine sales listings" on public.machine_sales_listings;
create policy "admins manage machine sales listings"
on public.machine_sales_listings
for all
to authenticated
using (exists (select 1 from public.admin_users a where a.user_id = auth.uid()))
with check (exists (select 1 from public.admin_users a where a.user_id = auth.uid()));

-- No public UPDATE or DELETE policy is granted.
-- Do not put the Supabase service-role key in any GitHub Pages HTML or JavaScript.
