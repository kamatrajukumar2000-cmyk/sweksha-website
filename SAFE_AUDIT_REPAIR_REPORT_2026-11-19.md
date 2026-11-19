# SWEKSHA Safe Audit & Repair Report — 19 November 2026

## Safety boundaries
- Production/default branch: `main`.
- Baseline commit: `6c1f80b767736a51650f435e7fc1ac66f8314477`.
- Backup branch: `backup/main-before-safe-repair-2026-11-19`.
- Repair branch: `repair/safe-audit-fixes-2026-11-19`.
- The backup branch was verified to point to the exact same commit as `main` at the start of this work.
- No commits were made to `main`.
- No Supabase SQL was executed. No database rows, tables, policies, buckets, or storage objects were changed.
- Existing open PRs #3, #13, #15, and #16 were not merged or modified.

## Repairs prepared on the isolated repair branch
1. `index.html`
   - Service enquiry submission now falls back to the same Supabase publishable key already used by the live public marketplace pages when browser local storage has no saved key.
   - Existing WhatsApp fallback and database response handling are retained.
2. `jobs.html`
   - Candidate and vacancy forms now use the same existing public publishable-key fallback instead of an unconfigured placeholder.
3. `jobs-admin.html`
   - The public key field is prefilled from the browser-saved key or the existing project publishable key.
   - The existing `job_applications` table workflow is preserved; it was not changed to `candidate_profiles`.

These are client-side publishable keys only. A publishable key is not an admin credential; Supabase RLS and authenticated admin policies remain essential.

## Findings requiring further verification
### P1 — Custom-domain SEO consistency
- Root `CNAME` currently contains `swekshacvd.com`.
- Homepage canonical URL, Open Graph URL/image, Twitter image, `sitemap.xml`, and `robots.txt` still point to the GitHub Pages URL.
- The custom domain could not be confirmed reachable through the available live check during this audit. Do not change canonical/sitemap URLs until DNS and HTTPS are confirmed working.

### P1 — Live Supabase schema and RLS are not inspectable from repository files
- Public forms depend on the live project's actual tables, columns, grants, and RLS policies.
- `supabase/schema.sql` explicitly states it does not create public submission policies; the feature-specific SQL files contain separate policies.
- The live Supabase project's actual policies and table definitions were not queried. Therefore public inserts, approved-only reads, and admin-only reads/updates are not yet certified.

### P2 — Reviews are not yet connected to shared moderation
- The current homepage review flow remains WhatsApp-only and its displayed review data uses browser-local storage/initial content.
- Do not add database review reads/writes or an admin moderation tab until the live `reviews` table columns and RLS policies are verified.

### P2 — Jobs compatibility migration needs review before execution
- `supabase/jobs_hiring_compatibility.sql` is not a purely additive migration: it updates invalid status values and drops/recreates status CHECK constraints.
- It does not drop tables, but it should not be run against production until the live schema, existing constraints, policies, and data are inspected and a database backup is confirmed.

### P2 — Storage policies need live inspection
- Machine-parts and diamond-trading SQL files configure public upload/read policies for their image buckets.
- Actual live bucket settings and storage policies were not inspected. Do not change them without checking the existing project first.

## Verification status
- Git branch isolation: verified.
- Backup points to starting `main` commit: verified.
- Repair branch diff against `main`: limited to the three intended HTML files plus this report.
- Supabase runtime inserts, admin sign-in, RLS, storage upload, and browser/mobile end-to-end tests: not yet performed.
- Domain DNS/HTTPS: not confirmed.
- Production deployment: unchanged; repair branch is not live.

## Next safe steps
1. Inspect the live Supabase schema and RLS policies in read-only mode.
2. Test forms and admin workflows without deleting or rewriting existing records.
3. Verify `swekshacvd.com` DNS and HTTPS, then update canonical/social/sitemap/robots URLs on this repair branch.
4. Run browser/mobile smoke tests and review the branch diff before opening or merging a PR.
