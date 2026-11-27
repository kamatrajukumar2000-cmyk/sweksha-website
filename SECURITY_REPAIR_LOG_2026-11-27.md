# SWEKSHA Security Repair Log — 27 November 2026

## Scope and safety
- Repository: `kamatrajukumar2000-cmyk/sweksha-website`
- Production site was not redeployed during this database-only repair.
- A repair branch was created: `security-audit-repairs-2026-11-27`.
- No customer rows, reviews, enquiries, or admin accounts were deleted or edited.

## Completed production database repairs

### 1. Restrict execution of the RLS event-trigger function
- Project: `ftvfumhxcpakskhbcuup` (Reviews project)
- Finding: `public.rls_auto_enable()` is a SECURITY DEFINER event-trigger function attached to event trigger `ensure_rls`, but EXECUTE was inherited by PUBLIC.
- Change: revoked EXECUTE from PUBLIC. The postgres owner retains execute privilege; event trigger remains enabled.
- Verification: anon EXECUTE = false; authenticated EXECUTE = false; postgres EXECUTE = true; event trigger `ensure_rls` remains enabled.
- Supabase Security Advisor returned no findings after the repair.

### 2. Consolidate duplicate approved-review read policies
- Project: `ftvfumhxcpakskhbcuup`
- Finding: two permissive SELECT policies overlapped for anon users and approved reviews.
- Change: replaced the pair with one SELECT policy for anon and authenticated roles using `approved = true`.
- Intended access is preserved: public users can read approved reviews only; unapproved reviews remain excluded.
- Verification: Supabase Performance Advisor returned no findings after the repair. The resulting policies are one approved-only SELECT policy for anon/authenticated plus one pending-only INSERT policy.

## Outstanding items — not yet changed
1. Supabase project `xotqafgkubodqpirfpfb`: leaked-password protection is disabled. Enable it in Supabase Dashboard > Authentication > Settings > Password Security, then verify.
2. Confirm MFA / admin authentication and authorization for every admin page and every write operation.
3. Continue exposed-table and storage review. The service project currently has RLS enabled on all inspected public tables and no Edge Functions. Public SELECT grants inspected for marketplace tables do not expose admin_notes or seller phone/email columns; verify the public page still renders using its explicit safe field list.
4. Run a repository-wide secret scan and dependency review, including git history.
5. Review GitHub branch protection, deployment environment approvals, workflow action pinning and Pages settings.
6. Test forms, uploads, reviews, listings and job applications for spam/rate limits and validation.
7. Run live external HTTP/TLS/DNS checks and browser-based functional testing.
8. Confirm backup/restore and incident recovery.
9. Review client-side admin pages for hard-coded allowlisted email checks, localStorage configuration, third-party CDN integrity, XSS-safe rendering, and ensure database RLS remains the true authorization boundary.
10. Complete a broader stored-XSS pass on all user-controlled URLs and fields. The AI business manager now rejects non-HTTPS photo URLs before using them in admin-page links and image sources.

## CI result
- Pull request #51 is open as a draft; production deployment was not triggered.
- GitHub Actions run 45929581273 completed successfully: HTML and sitemap validation passed, and the preview artifact packaged successfully.

## Important limitations
- This log records only actions actually completed and verified.
- A clean Supabase advisor result is not a full penetration test or a guarantee of security.
- Do not merge or deploy this branch until its checks and full review pass.
