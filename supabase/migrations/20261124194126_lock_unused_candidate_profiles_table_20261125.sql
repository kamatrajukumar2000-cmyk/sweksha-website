-- The current Jobs page submits to job_applications, not candidate_profiles.
-- Keep the unused legacy table and its rows intact, but disable browser access until a supported workflow exists.
revoke all privileges on table public.candidate_profiles from anon, authenticated;
drop policy if exists "Public can submit pending candidate profiles" on public.candidate_profiles;
