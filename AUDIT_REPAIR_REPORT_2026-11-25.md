# SWEKSHA Website & Supabase Audit / Repair Report — 25 November 2026

## Project and release safety
- GitHub repository: `kamatrajukumar2000-cmyk/sweksha-website`
- Production branch: `main`
- Repair branch: `security-performance-hardening-2026-11`
- Backup branch: `backup/pre-audit-2026-11-25`
- Supabase project: `sweksha-cvd-service` (`xotqafgkubodqpirfpfb`)
- Supabase status: `ACTIVE_HEALTHY`, PostgreSQL 17.11.
- The backup branch is based on the exact production baseline commit `80ff301ec546545badb25a5b93657bdf9a2732e3`.
- The website repair branch is still isolated; production `main` has not been changed or deployed.
- Live database changes below were applied as non-destructive policy/grant migrations. No existing table rows were deleted or rewritten.
- A full provider-level database backup/export was not created by this audit. The GitHub backup branch is a code backup, not a database backup.

## Live Supabase findings
### Initial findings
- All 9 public application tables had RLS enabled.
- Security advisor: leaked-password protection disabled.
- Performance advisor initially reported 13 RLS auth-initplan warnings, 8 multiple-permissive-policy warnings, and one unused index.
- Browser-facing roles inherited excessive table privileges, including `TRUNCATE` and other destructive/maintenance privileges that bypass RLS.
- Anonymous users could read private contact columns from approved machine, machine-part, diamond and job-vacancy rows if querying the Data API directly.
- Public job application/vacancy policies did not consistently force new submissions to `pending`.
- Enquiry insert policy accepted arbitrary values without field-length/status checks.
- Homepage review form used WhatsApp only and did not save to the shared Reviews table; there was no admin moderation UI for database reviews.
- `marketplace_listings` contains an unusual extra column named `iPhone 13` (array type, comment: “Good condition, used phone”). It was not changed or deleted; investigate its origin before cleanup.

### Live database changes applied and verified
1. Revoked browser-role `DELETE`, `TRUNCATE`, `REFERENCES`, `TRIGGER`, and PostgreSQL 17 `MAINTAIN` privileges on public tables; revoked anonymous `UPDATE`.
2. Tightened default privileges for future public tables/sequences created by the `postgres` role; anonymous users retain only the needed read/insert access, and authenticated admin sessions retain update access. Default privileges owned by `supabase_admin` were not changed.
3. Restricted anonymous SELECT to public columns on machine sales, machine parts, diamond listings, job vacancies, and reviews. Seller/buyer phone numbers, email addresses, contact details, and admin notes are no longer selectable by the anonymous API role.
4. Removed anonymous SELECT from candidate profiles and job applications.
5. Enforced `status='pending'` for public job applications and vacancy submissions; kept compatibility with the current vacancy form's legacy field names.
6. Added enquiry validation and required new enquiries to use `status='new'`.
7. Removed an obsolete enquiry admin policy with a non-matching UUID and removed a duplicate vacancy policy.
8. Optimized admin JWT policy evaluation using `(select auth.jwt())`; merged approved-row visibility into admin read policies to remove redundant policy evaluation.
9. Added admin-only review read/update policies; public reviews remain pending until approved.
10. Recorded four Supabase migrations in the project's migration history.

### Verification performed
- Rechecked table privileges: anonymous DELETE/TRUNCATE/UPDATE are false; authenticated TRUNCATE is false.
- Rechecked anonymous column privileges: machine seller phone/admin notes, diamond contact phone/admin notes, parts contact phone, vacancy contact details and job applicant phone are not selectable.
- Simulated an authorized admin JWT: admin can read all 4 machine listings and the existing 1 job application; admin machine-listing update policy test updated one row inside a transaction and rolled back.
- Simulated public vacancy submission: an `approved` submission was blocked; a `pending` submission succeeded inside a transaction and was rolled back.
- Simulated review workflow: public pending submission, admin moderation, and anonymous read after approval succeeded inside a transaction and was rolled back.
- Simulated enquiry, job application and vacancy submissions through the anonymous database role and verified admin visibility; test rows were rolled back.
- Confirmed no temporary audit test rows remain.
- Final advisors: no remaining RLS initplan or multiple-permissive-policy warnings; one informational unused index remains. The security advisor still reports leaked-password protection disabled. The Supabase organization is on the Free plan; Supabase documentation says leaked-password protection is available on Pro and above, so this warning cannot be cleared on the current plan without upgrading.
- All three public image buckets are already limited to 5 MiB and JPG/PNG/WebP. UUID-WebP path restrictions are prepared in the website repair branch but were not applied to live Storage policies because the current production site has not yet been replaced.

## Live row counts observed
These are direct database counts from this project at audit time:
| Table | Rows |
|---|---:|
| machine_sales_listings | 4 (all approved) |
| job_applications | 1 (shortlisted) |
| enquiries | 0 |
| reviews | 0 |
| job_vacancies | 0 |
| candidate_profiles | 0 |
| machine_part_listings | 0 |
| diamond_trade_listings | 0 |
| marketplace_listings | 0 |

No records were removed by the audit. If the admin dashboard previously showed other enquiry/review/marketplace records, confirm whether they were in another Supabase project or an earlier database state before any cleanup or migration.

## Website repair branch changes prepared
- Added Supabase-backed customer review submission and approved-review display.
- Added admin review moderation (approve/reject/hide) to the private dashboard.
- Kept WhatsApp as a parallel customer-feedback path.
- Fixed malformed meta-description markup on three pages.
- Improved homepage carousel accessibility, touch targets, contrast/heading structure, and image loading priority.
- Improved machine listing image layout stability.
- Fixed the Jobs page publishable-key fallback.
- Preserved seller WhatsApp fallback if diamond image compression/upload fails.
- Prepared UUID WebP uploads, image size/type constraints, security disclosure files, and SQL updates.
- Removed redundant duplicate parts/diamond loading in the admin dashboard.

## Remaining items before production deployment
1. Enable Supabase Auth leaked-password protection in Authentication → Settings → Password Security. This setting could not be changed through the available project tools.
2. Take/verify a provider-level database backup before the next production schema or deployment change.
3. Reconcile the unusual `marketplace_listings."iPhone 13"` column with the site's intended schema; do not delete until its origin is known.
4. Review default privileges for objects created by `supabase_admin`; the current audit could only change defaults for `postgres`.
5. Test the actual site in desktop and mobile browsers: service enquiry, machine listing, parts BUY/SELL, diamond BUY/SELL, jobs, admin login/moderation, and reviews.
6. Verify the custom domain, HTTPS, sitemap, robots, Search Console, GA4/GTM, and image performance after the candidate branch is deployed.
7. Confirm the admin dashboard can load all current records and approve/reject them using the real signed-in browser session.
8. Merge/deploy the repair branch only after those checks pass.

## Release status
**Supabase hardening migrations applied and verified. Website repair branch not yet deployed.** No live website files were replaced, and no existing business records were deleted.
