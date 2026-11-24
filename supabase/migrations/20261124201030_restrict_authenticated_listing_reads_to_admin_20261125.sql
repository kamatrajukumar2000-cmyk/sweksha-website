-- Approved public listings are read through the anon role and public-column grants.
-- Authenticated users must not gain access to seller/buyer PII just because a listing is approved.
-- Keep authenticated SELECT on these tables exclusively for the named SWEKSHA admin.
alter policy "Sweksha admin read diamond listings" on public.diamond_trade_listings
using (lower(coalesce((select auth.jwt() ->> 'email'),''))='kamatrajukumar2000@gmail.com');

alter policy "Sweksha admin read machine part listings" on public.machine_part_listings
using (lower(coalesce((select auth.jwt() ->> 'email'),''))='kamatrajukumar2000@gmail.com');

alter policy "Sweksha admin read machine listings" on public.machine_sales_listings
using (lower(coalesce((select auth.jwt() ->> 'email'),''))='kamatrajukumar2000@gmail.com');

alter policy "Sweksha admin can read job applications" on public.job_applications
using (lower(coalesce((select auth.jwt() ->> 'email'),''))='kamatrajukumar2000@gmail.com');

alter policy "Sweksha admin can read job vacancies" on public.job_vacancies
using (lower(coalesce((select auth.jwt() ->> 'email'),''))='kamatrajukumar2000@gmail.com');

alter policy "Sweksha admin read reviews" on public.reviews
using (lower(coalesce((select auth.jwt() ->> 'email'),''))='kamatrajukumar2000@gmail.com');
