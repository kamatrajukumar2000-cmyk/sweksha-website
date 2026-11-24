# SWEKSHA Website & Supabase Audit / Repair Report — 25 November 2026

## Project and release safety
- GitHub repository: `kamatrajukumar2000-cmyk/sweksha-website`
- Production branch: `main`
- Repair branch: `security-performance-hardening-2026-11`
- Backup branch: `backup/pre-audit-2026-11-25`
- Supabase project: `sweksha-cvd-service` (`xotqafgkubodqpirfpfb`), status `ACTIVE_HEALTHY`, PostgreSQL 17.11.
- Backup branch points to the production baseline commit `80ff301ec546545badb25a5b93657bdf9a2732e3`.
- The repair branch is isolated. Production `main` has not been changed or deployed.
- Live database policy/grant migrations were applied and verified. No existing table rows were deleted or rewritten.
- A provider-level database backup/export was not created by this audit. The GitHub backup branch is a code backup, not a database backup.

## Live Supabase findings
- All 9 public application tables had RLS enabled.
- Browser-facing roles had excessive table privileges, including destructive/maintenance privileges that bypass RLS.
- Anonymous users could query private contact columns from approved machine, parts, diamond and job-vacancy rows.
- Public job application/vacancy policies did not consistently force new submissions to `pending`.
- Enquiry insert policy lacked adequate field-length and status validation.
- Reviews had a database table and public pending-insert policy, but the homepage review form used WhatsApp only and the admin dashboard had no review moderation UI.
- Initial public Storage upload policies allowed anonymous uploads under any object name and public listing of object metadata. Buckets were already capped at 5 MiB and restricted to JPG/PNG/WebP; this policy weakness has now been fixed.
- `marketplace_listings` was unused by the current website, had anonymous-readable contact columns, and contained an unexplained `iPhone 13` array column. The table has zero rows; browser-role access was revoked and its public-read policy removed. The table/column were retained, not deleted.
- `candidate_profiles` is also unused by the current Jobs page (which submits to `job_applications`), had no admin processing UI, and had zero rows. Browser-role access and its public insert policy were revoked; the table was retained.

## Live database changes applied and verified
1. Revoked browser-role `DELETE`, `TRUNCATE`, `REFERENCES`, `TRIGGER`, and PostgreSQL 17 `MAINTAIN` privileges on public tables; revoked anonymous `UPDATE`.
2. Tightened default privileges for future public tables/sequences created by the `postgres` role. Default privileges owned by `supabase_admin` were not changed.
3. Restricted anonymous SELECT to the fields required for public listings; private seller/buyer phone, email, contact details, candidate contact data and admin notes are not selectable by the anonymous API role.
4. Added a separate public `status` column grant for the five tables whose frontend queries filter approved records by status. This follow-up was necessary to keep the public listing/review queries working without granting access to private columns.
5. Removed anonymous SELECT from candidate profiles and job applications.
6. Enforced `status='pending'` for public job applications and vacancy submissions, and added field validation.
7. Added enquiry validation and required new enquiries to use `status='new'`.
8. Removed an obsolete enquiry admin policy and a duplicate vacancy policy; optimized admin JWT policy evaluation.
9. Added admin-only review read/update policies; public reviews remain pending until approved.
10. Eleven Supabase migrations are recorded and mirrored under `supabase/migrations/` on the repair branch.
11. Locked down unused legacy `marketplace_listings`: revoked all browser-role privileges and removed its public-read policy; zero rows were present and the table/column were retained.
12. Locked down unused legacy `candidate_profiles`: revoked all browser-role privileges and its public insert policy; zero rows were present. The active Jobs page continues to use `job_applications`.
13. Added server-side length and field-count validation to public machine, parts, diamond, job application, vacancy and review submissions; no existing rows were rewritten.
14. Added explicit deny-all RLS policies to the two unused legacy tables so the security advisor no longer reports RLS-enabled tables without policies.

## Verification performed
- Anonymous DELETE/TRUNCATE/UPDATE privileges are false; authenticated TRUNCATE is false.
- Private contact/admin columns are not selectable by the anonymous role.
- Verified `marketplace_listings` has zero rows, no remaining RLS policies, and no SELECT/INSERT privilege for anon or authenticated roles.
- Verified `candidate_profiles` has zero rows, no remaining public submission policy, and no SELECT/INSERT privilege for anon or authenticated roles.
- Public approved-status queries were individually tested for machine sales, machine parts, diamond listings, job vacancies and reviews; they succeeded after the additional `status` column grant.
- Storage object listing is now blocked for anonymous users; the authorised admin can list all existing objects (18 machine, 2 parts, 4 diamond). Existing object counts did not change.
- Tested Storage RLS in a rolled-back transaction: a valid legacy-style image filename was accepted, while an arbitrary text filename was rejected.
- Tested valid public submissions and invalid oversized/short-field submissions for machine listings, parts, diamond listings, job applications, vacancies and reviews; valid examples passed, invalid examples were blocked, and all test rows were rolled back.
- Ran all five standalone marketplace/jobs SQL setup scripts inside database transactions and rolled them back successfully. Also ran the consolidated security SQL reference inside a transaction and rolled it back successfully.
- Parsed inline JavaScript in the key website/admin pages; no syntax errors were found. Three malformed meta-description tags were corrected.
- Simulated authorized admin access: admin can read all 4 machine listings and the existing 1 job application.
- Admin machine-listing update and job application status update tests ran inside transactions and were rolled back.
- A temporary job vacancy was inserted as admin, approved, verified, then rolled back.
- Public approved vacancy submission was blocked; pending vacancy submission succeeded inside a rolled-back transaction.
- Review pending submission, admin moderation and public visibility after approval were tested inside a rolled-back transaction.
- Enquiry, job application and vacancy public submission tests were rolled back. No audit test records remain.
- Final Supabase advisors show no RLS initplan or multiple-permissive-policy warnings. One informational unused index remains: `enquiries_status_created_at_idx`. It was retained.
- Security advisor still reports leaked-password protection disabled. The Supabase organization is on the Free plan; this feature requires Pro or above.
- Database functions/views/triggers audit found no custom public-schema functions or views. Storage's own managed functions/triggers remain.

## Live row counts observed
| Table | Rows |
|---|---:|
| machine_sales_listings | 4 (all approved) |
| job_applications | 1 (shortlisted) |
| enquiries | 0 |
| reviews | 0 |
| job_vacancies | 0 |
| candidate_profiles | 0 (browser access revoked; legacy table) |
| machine_part_listings | 0 |
| diamond_trade_listings | 0 |
| marketplace_listings | 0 |

No records were removed. If previous enquiries/reviews were expected in these zero-count tables, verify whether they belonged to another Supabase project or earlier database state before cleanup.

## Website repair branch changes prepared
- Homepage review form now saves feedback to Supabase as `pending`, while keeping WhatsApp as a parallel contact path. Only approved reviews load publicly.
- Added admin review moderation (approve/reject/hide).
- Added Job Seeker Applications and Employer Vacancies panels to the private admin dashboard, with status moderation.
- Improved homepage carousel accessibility, touch targets, contrast/heading structure and image loading priority.
- Improved machine listing image layout stability.
- Fixed malformed meta-description markup on three pages.
- Fixed Jobs page publishable-key fallback and Diamond Seller WhatsApp fallback after image compression/upload failure.
- Hardened live Storage policies: uploads must use the current timestamp/random image filename pattern or UUID-v4 WebP; public object listing is blocked; only the authorised admin can list/delete. Existing public image URLs remain directly readable by design.
- Removed duplicate parts/diamond loading in the admin dashboard.
- Added `SECURITY.md` and `.well-known/security.txt`.

## Storage status
- Live Storage now accepts both the current production timestamp/random filenames (including existing `.jpg`, `.png`, `.webp` and legacy `-jpg`/`-png` forms) and UUID-v4 `.webp` filenames for the new repair-branch uploader.
- Public object listing is disabled; the authorised admin can still list/delete objects. Direct public image URLs remain accessible because the buckets are intentionally public.
- Existing objects were retained; counts remain 18 machine, 2 parts and 4 diamond images.
- The current website still uses the legacy timestamp/random upload naming. The new repair branch changes this to UUID-v4 WebP; both filename patterns are currently accepted so this can be deployed without a separate Storage-policy window.

## Remaining items before production deployment
1. Take/verify a provider-level database backup.
2. Review the unusual `marketplace_listings."iPhone 13"` column and `supabase_admin` default privileges; do not delete or change them without confirmation.
3. Deploy the UUID-WebP uploader already prepared in the repair branch; the live Storage policy now accepts both old and new filename patterns.
4. Test all real forms, admin login/moderation, reviews, job applications and vacancies on desktop/mobile.
5. Verify custom domain, HTTPS, sitemap, robots, Search Console, GA4/GTM and performance after deployment.
6. Confirm the admin dashboard loads all current records using the real signed-in browser session.

## Release status
**Supabase RLS, column grants, legacy-table lock-down, Storage policies and input validation applied and verified. Website repair branch not deployed.** Production `main` remains unchanged. No existing business records were deleted.
