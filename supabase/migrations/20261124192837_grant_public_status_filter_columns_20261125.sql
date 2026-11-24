-- Required for anonymous frontend filters on approved rows.
-- Only the status column is added; private contact fields remain restricted.
grant select (status) on public.machine_sales_listings to anon;
grant select (status) on public.machine_part_listings to anon;
grant select (status) on public.diamond_trade_listings to anon;
grant select (status) on public.job_vacancies to anon;
grant select (status) on public.reviews to anon;
