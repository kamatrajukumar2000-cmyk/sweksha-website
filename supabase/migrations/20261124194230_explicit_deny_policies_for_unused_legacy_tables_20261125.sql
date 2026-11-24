-- Keep RLS enabled and add explicit deny policies on the unused legacy tables.
create policy "Deny browser access to unused legacy marketplace"
on public.marketplace_listings for all to anon,authenticated
using (false) with check (false);
create policy "Deny browser access to unused candidate profiles"
on public.candidate_profiles for all to anon,authenticated
using (false) with check (false);
