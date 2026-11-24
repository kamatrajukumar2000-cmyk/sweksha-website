# SWEKSHA Website Audit & Safe Repair Report — 25 November 2026

## Scope
Repository: `kamatrajukumar2000-cmyk/sweksha-website`
Production branch: `main`
Active database project identified in site code: `sweksha-cvd-service`
Repair branch: `security-performance-hardening-2026-11`
Backup branch: `backup/pre-audit-2026-11-25`

## Backup and production safety
- Created `backup/pre-audit-2026-11-25` from `main`.
- Verified backup and `main` both point to baseline commit `80ff301ec546545badb25a5b93657bdf9a2732e3`.
- All repair work remains isolated on the repair branch / draft PR #29.
- No changes have been pushed to `main`.
- No Supabase SQL has been executed; no live rows, tables, buckets, or policies were changed.

## Findings and repairs prepared
1. **Marketplace privacy and RLS hardening**
   - Draft migration adds restrictive policies so public visitors can read approved listings only.
   - Public column grants omit seller/buyer contact details and admin notes.
   - Candidate job applications remain private; public vacancy reads expose only approved/public fields.
   - Customer enquiries are restricted to new submissions and admin-only reads/updates.
2. **Image upload hardening**
   - Listing uploads are converted to WebP and assigned random UUID filenames.
   - Proposed storage policy limits new files to UUID WebP names and 5 MiB.
   - Public image viewing remains enabled; public replacement is blocked; deletion is admin-only.
3. **SQL correctness**
   - Repaired incomplete/duplicated storage-policy statements in machine listings, machine parts, and diamond-trading SQL.
   - Corrected Jobs public-column grants to match the table definition.
   - Removed automatic rewriting of existing job status values from the compatibility migration.
   - New workflow checks use `NOT VALID` so legacy rows are not rewritten or rejected during migration; new/updated rows are constrained.
4. **Frontend reliability and accessibility**
   - Jobs page now retains the known publishable-key fallback if browser storage is unavailable.
   - Diamond seller form now restores the WhatsApp fallback and re-enables the submit button if image compression/upload fails.
   - Fixed malformed meta-description markup on diamond trading, CVD machine information, and microwave/RF power fault pages.
   - Homepage carousel improvements include inert inactive slides, larger touch targets, contrast/heading refinements, and hero-image preload.
   - Machine listing cards reserve image space to reduce layout shift.
5. **Security reporting**
   - Added a responsible-disclosure policy and `/.well-known/security.txt`.

## Static verification completed
- Inspected key homepage, marketplace, jobs, machine-listing, diamond-trading, and admin source files.
- Checked all six SQL files for balanced parentheses/quotes and complete `CREATE POLICY` statements.
- Verified the backup branch still points to the exact production baseline.
- Verified repair branch is ahead of `main` and has no commits behind the current production baseline.
- These are static checks only; they do not replace database execution or real browser testing.

## Items not yet certified
- Live Supabase table definitions, existing data values, RLS policies, Storage bucket settings, and admin authentication/MFA.
- Public anonymous form submissions, approved-only reads, admin moderation, image upload/delete, and row privacy in real sessions.
- Homepage review moderation: current homepage review display is browser-local/WhatsApp-based; shared Supabase review workflow is not verified.
- Domain DNS/HTTPS and real mobile/desktop rendering. The live domain could not be independently loaded by the available page-check tool in this run; that does not prove the site is down.
- Physical WebP/AVIF conversion of the two large homepage source images.
- Live GTM/GA4 configuration, CAPTCHA/rate limiting, and backup schedule.

## Required safe rollout
1. Connect the active Supabase project and take a database/storage backup.
2. Read the actual live schema, RLS policies, storage buckets, and existing job/listing statuses.
3. Reconcile the draft SQL against that live state before execution; do not run compatibility or hardening migrations blindly.
4. Test with separate anonymous and admin sessions.
5. Preview and test the website on mobile and desktop, then merge/deploy only after the database tests pass.

## Current release state
**Not deployed.** The production branch and live database remain unchanged. Draft PR #29 contains the isolated candidate changes and must remain unmerged until the live Supabase review and end-to-end tests are complete.
