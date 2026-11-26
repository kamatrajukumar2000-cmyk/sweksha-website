# SWEKSHA Website Audit — 27 November 2026

## Scope and safety
- Audited repository: `kamatrajukumar2000-cmyk/sweksha-website`, default branch `main`.
- Production `main` was not modified.
- A separate branch `audit/seo-sitemap-repair-2026-11-27` was created from `main`.
- No deployment was triggered; this work is not live until reviewed and merged.
- Supabase inspection used read-only table, policy, row-count and advisor queries. No database schema, records, credentials, policies, storage objects or auth settings were changed.

## Completed repair on isolated branch
### Sitemap coverage
- Original sitemap contained 26 URLs.
- Repository contains 42 HTML files. Ten additional public, indexable pages were missing from the sitemap: International Sourcing, Diamond Laser Machine Information, Diamond Polishing Machine Information, Team Expertise, and six public team/legal profile pages.
- Added those ten existing pages to `sitemap.xml`.
- Added page-specific canonical URLs and explicit `index, follow` directives to all ten newly listed pages.
- Validation after the change: 36 sitemap URLs, no duplicate URLs, no URL pointing to a missing repository file.
- Deliberately excluded admin pages, Google verification file, image viewer and machine image-preview page from sitemap.

## Confirmed repository / runtime findings
### P1 — Customer review flow is not connected to shared database
- Homepage review form currently prepares a WhatsApp message; displayed reviews use browser Local Storage / initial JSON.
- Primary Supabase project has a `reviews` table with columns `name`, `rating`, `review`, `status`; RLS policies permit pending submissions and approved-only public reads, with admin read/update policies.
- This is a safe next candidate for repair, but implementation must map the current form fields to this exact schema and verify public insert/read behavior before release.
- A separate project named `Sweksha Reviews` exists, but its table inspection failed with a database authentication error. Its live schema is not certified.

### P1 — Supabase Auth password protection warning
- Supabase Security Advisor reports leaked-password protection is disabled.
- Recommended: enable it in Auth password/security settings after checking the current sign-in experience. This setting was not changed during this audit.

### P2 — Legacy database schema pollution
- The legacy `public.marketplace_listings` table has an unexpected column named `iPhone 13` with comment `Good condition, used phone`.
- This table currently has zero rows and browser access is explicitly denied by RLS. Do not drop the column/table until confirming no hidden dependency or required archival value.

### P2 — Database performance notice
- Advisor reports one unused index: `public.enquiries.enquiries_status_created_at_idx`.
- Do not drop it solely from this observation; first confirm workload and intended admin filtering.

### RLS overview
- All inspected public tables had RLS enabled.
- Public insert policies constrain new records to pending/new states and validate key fields.
- Public reads for jobs, marketplace listings, parts and diamond listings are restricted to approved rows.
- Admin reads/updates are scoped to the configured admin email claim.
- The live policies were inspected read-only; end-to-end browser tests have not yet been completed.

### Live data summary (counts only)
- Job vacancies: 2 approved.
- Machine sales listings: 7 approved, 1 pending.
- Machine part listings: 6 approved.
- Diamond trade listings: 1 approved.
- Job applications: 1 shortlisted.
- Reviews: no rows returned in the primary project.

### External runtime limitations
- GitHub Pages build/deployment run #501 completed successfully on 26 November 2026.
- DNS lookup from the audit runtime failed, and web search did not return an indexed result for the domain. This does not prove the domain is down; direct HTTP, DNS, TLS, Google Search Console and mobile-browser checks remain unverified.

## Phase 2 repairs completed on isolated branch
### Homepage reviews
- Confirmed primary project `reviews` schema: `id` (identity), `created_at`, `name`, `rating`, `review`, `status`.
- Confirmed RLS permits anonymous inserts only as `pending`, and anonymous reads only for `approved` reviews.
- Replaced the WhatsApp-only review form and browser Local Storage display with Supabase REST submission and approved-only database reads.
- Simplified the review form to fields that match the actual database schema; submissions are not displayed until an administrator approves them.
- The public API key used in the page is a publishable key, not a service-role secret.
- End-to-end browser/API insert and approval testing is still required before production release.

### Service enquiry validation
- Added browser-side length limits aligned with the live `enquiries` insert policy: name 2–120, company 120, machine 150, problem 5–2,500, recent changes 1,000, contact 40 characters.
- Capped the generated subject at 300 characters and message at 5,000 characters to match the database policy exactly.
- Kept the existing WhatsApp handoff and Supabase insert behavior; no enquiry records were created during this code change.

### Other public form and storage checks
- Compared Job Seeker and Vacancy payloads with live `job_applications` and `job_vacancies` schemas and RLS limits; added matching browser-side length constraints.
- Compared Machine Parts BUY/SELL forms with `machine_part_listings` constraints; added quantity, contact, description, name, price, location and photo MIME restrictions matching the database policy.
- Compared Machine BUY/SELL form with `machine_sales_listings` constraints; existing input and photo caps already fit the policy.
- Compared Diamond BUY/SELL forms with `diamond_trade_listings` constraints; added matching text/contact/photo input limits.
- Confirmed three public image buckets exist (machine parts, machine listings, diamond trade), each with a 5 MB limit and JPG/PNG/WEBP MIME allow-list. Their public upload policies restrict bucket and generated filename pattern; admin delete/list policies are scoped to the configured admin email.
- Fixed the Diamond SELL image-processing error path so an image compression/upload exception no longer leaves the submit button stuck or silently prevents the WhatsApp fallback.
- No test listings, applications, enquiries or uploaded files were created.

### Homepage JavaScript integrity
- Found two literal escaped newline sequences inside the image-protection script that caused JavaScript syntax failure.
- Replaced them with real line breaks.
- Validation: all 12 inline JavaScript blocks parsed successfully and all 3 JSON-LD blocks parsed successfully.

## Phase 3 — Admin and security work
### Customer operations dashboard
- Added `admin-dashboard.html`, marked `noindex, nofollow` and excluded from the public sitemap.
- Added Supabase Auth sign-in using the project's publishable key; no service-role/secret key is embedded.
- Restricts the dashboard UI to the configured administrator email and relies on existing database RLS admin read/update policies for actual access control.
- Added review moderation (pending / approved / rejected) and service-enquiry tracking (new / contacted / in_progress / resolved / spam).
- Added navigation to the existing Jobs & Hiring Admin and Marketplace Admin pages.
- Confirmed the selected fields exist in the live `reviews` and `enquiries` schemas and inspected their admin RLS policies.
- JavaScript syntax check passed. Full sign-in and real record update still require a browser session.

### Security and performance advisor
- Re-ran Supabase Security, Performance and Health advisors.
- Health advisor: no findings.
- Security advisor: one warning remains — leaked-password protection is disabled. Current available project tools do not expose this Auth setting, so it must be enabled in Supabase Dashboard > Authentication > Password Security (Pro plan or above).
- Performance advisor: one informational finding remains — `enquiries_status_created_at_idx` is currently unused. It is intentionally retained pending workload review; no destructive index/schema changes were made.

## Next repair order
1. Complete real-browser login, review moderation, enquiry status update, jobs admin and marketplace admin workflow tests using a controlled test account; do not create fake customer data in production.
2. Enable leaked-password protection in Supabase Authentication > Password Security (requires eligible plan) and re-run Security Advisor.
3. Finish route-by-route internal-link audit and improve remaining short team-profile meta descriptions; verify unique title/description/canonical tags.
4. Review the legacy `iPhone 13` column and unused index before any destructive cleanup.
5. Verify DNS, HTTPS, robots, sitemap fetch, Google Search Console indexing, PageSpeed/Lighthouse, mobile layouts, accessibility and analytics events.
6. Review all changes and deployment checks before merging into protected `main`.

## Verification status
- Sitemap repair: verified against the GitHub repository tree.
- Existing latest Pages build: successful.
- Supabase schema and policies: inspected read-only for primary project.
- Live forms, admin login, storage uploads, DNS/TLS, Google indexing, browser/mobile visual tests: not yet certified.
