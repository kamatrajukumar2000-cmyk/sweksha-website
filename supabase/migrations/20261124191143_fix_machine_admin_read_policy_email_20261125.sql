
alter policy "Sweksha admin read machine listings" on public.machine_sales_listings
using (status = 'approved' or lower(coalesce((select auth.jwt()) ->> 'email','')) = 'kamatrajukumar2000@gmail.com');
