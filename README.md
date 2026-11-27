# Sweksha Foundation Club

SWEKSHA is a static website hosted with GitHub Pages. The published site is served from the repository files; no Node.js build step is required.

## Customer reviews

Review submissions are sent to the Supabase `public.reviews` table with status `pending`. They are shown publicly only after an administrator approves them. The private Admin Dashboard can review and update review status.

## Service enquiries

The main CVD Service Request form and the consultancy enquiry form save submitted details to the Supabase `public.enquiries` table. The customer is offered a WhatsApp follow-up after the database save succeeds.

The floating **Sweksha Service Help** widget prepares a WhatsApp message only; it does not create a database enquiry record.

## Administration

Open `admin-dashboard.html` for authorised administrator sign-in and customer review/service-enquiry management. Access is controlled by Supabase authentication and database row-level security (RLS). Never place a Supabase service-role or secret key in website files.

## Deployment

GitHub Actions deploys the repository to GitHub Pages using `.github/workflows/deploy-pages.yml`. Static validation runs separately through `.github/workflows/website-static-checks.yml`.
