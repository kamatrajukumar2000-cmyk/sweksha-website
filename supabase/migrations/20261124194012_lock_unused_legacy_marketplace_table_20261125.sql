-- The legacy marketplace_listings table is not used by the current website.
-- It contained public-readable contact columns and an unexplained iPhone 13 column.
-- Keep the table and its rows intact, but remove browser-role access until its intended use is verified.
revoke all privileges on table public.marketplace_listings from anon, authenticated;
drop policy if exists "Public can read approved listings" on public.marketplace_listings;
