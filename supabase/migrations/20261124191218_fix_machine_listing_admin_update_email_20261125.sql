
alter policy "Sweksha admin update machine listings" on public.machine_sales_listings
using (lower(coalesce((select auth.jwt()) ->> 'email','')) = 'kamatrajukumar2000@gmail.com')
with check (lower(coalesce((select auth.jwt()) ->> 'email','')) = 'kamatrajukumar2000@gmail.com');
