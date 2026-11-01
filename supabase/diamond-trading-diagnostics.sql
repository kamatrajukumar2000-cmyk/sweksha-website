-- READ-ONLY diagnostics for Sweksha Diamond Trading.
-- Run in Supabase SQL Editor for project: ftvfumhxcpakskhbcuup.
-- These queries do not insert, update, or delete any records.

-- 1) Confirm the Diamond Trading table exists.
select table_schema, table_name
from information_schema.tables
where table_schema = 'public'
  and table_name = 'diamond_trade_listings';

-- 2) Inspect the current table columns.
select column_name, data_type, is_nullable, column_default
from information_schema.columns
where table_schema = 'public'
  and table_name = 'diamond_trade_listings'
order by ordinal_position;

-- 3) Count existing listings by status and type (preserves and reports all rows).
select status, transaction_type, count(*) as listing_count
from public.diamond_trade_listings
group by status, transaction_type
order by status, transaction_type;

-- 4) Inspect row-level security policies on the listing table.
select policyname, cmd, roles, qual, with_check
from pg_policies
where schemaname = 'public'
  and tablename = 'diamond_trade_listings'
order by policyname;

-- 5) Confirm the product image bucket exists.
select id, name, public, file_size_limit, allowed_mime_types
from storage.buckets
where id = 'diamond-trade-images';
