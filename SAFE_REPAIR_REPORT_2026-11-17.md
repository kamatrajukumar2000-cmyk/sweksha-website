# SWEKSHA Safe Repair Report — 17 November 2026

## Safety boundaries
- Baseline commit: `15e236f036cbfb4ab51388fc53dfef859507d224` (the existing `main` head when this repair began).
- Backup branch: `backup/main-before-safe-repair-2026-11-17`.
- Repair branch: `repair/safe-audit-fixes-2026-11-17`.
- No commits were made to `main`.
- No Supabase SQL was executed and no database rows, tables, policies, or storage objects were changed.

## Changes prepared on the repair branch
1. `index.html`
   - Uses the same Supabase publishable key already present in the existing public marketplace pages, with the browser-saved key still taking precedence.
   - Loads only approved customer reviews from the existing `reviews` table.
   - Submits new reviews with `status: pending`; the WhatsApp message remains a backup path.
   - Corrects WhatsApp review-message newline escaping.
   - Updates the visible review copy to explain admin approval.
2. `jobs.html`
   - Replaces the unconfigured placeholder with the existing project's public publishable key fallback.
3. `jobs-admin.html`
   - Uses the same public key fallback.
   - Preserves the existing `job_applications` workflow, which matches the live Jobs form.
4. `marketplace-admin.html`
   - Uses the existing project's URL and public key by default.
   - Adds a Customer Reviews moderation tab for pending/approved/rejected review records.
   - Avoids writing `updated_at` for review rows, because that column has not been confirmed for the existing reviews table.

## Important finding about draft PR #3
The current `main` branch Jobs form submits candidate records to `job_applications`, and the current `jobs-admin.html` reads and updates `job_applications`. These two live files are aligned. Draft PR #3 changes the admin page to `candidate_profiles`; merging that draft without separately migrating and reconciling existing data would introduce a mismatch. This repair deliberately keeps the current `job_applications` flow.

## Verification still required before production merge
- Confirm the live `reviews` table has `name`, `rating`, `review`, and `status` columns.
- Inspect live RLS policies to confirm: public can insert pending reviews; public can read approved reviews only; authorized admin can read and update review status.
- Test service enquiry insert, Jobs candidate and vacancy submissions, review submission/approval, and marketplace admin status changes in the live project.
- Confirm the publishable key is active for project `xotqafgkubodqpirfpfb`. The same key string is already used in existing public marketplace pages, but runtime API verification has not been performed in this repair.
- Run browser/mobile smoke tests and GitHub Pages deployment checks.

## Production status
This is a review candidate only. Do not merge until the live Supabase policy/schema checks and end-to-end tests above pass.
