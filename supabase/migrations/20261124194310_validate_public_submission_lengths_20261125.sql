-- Add server-side length/shape validation to public submissions.
-- This does not rewrite existing records.
alter policy "public can submit pending machine listings" on public.machine_sales_listings
with check (
  status='pending' and admin_notes is null
  and length(trim(coalesce(machine_category,''))) between 1 and 120
  and length(trim(coalesce(brand_model_year,''))) between 1 and 200
  and length(trim(coalesce(condition,''))) <= 120
  and length(trim(coalesce(application_details,''))) <= 3000
  and length(trim(coalesce(additional_details,''))) <= 3000
  and length(trim(coalesce(expected_price,''))) <= 120
  and length(trim(coalesce(location,''))) between 1 and 200
  and length(trim(coalesce(seller_name,''))) between 1 and 120
  and length(trim(coalesce(seller_phone,''))) between 5 and 40
  and length(trim(coalesce(seller_email,''))) <= 254
  and coalesce(cardinality(photo_urls),0) <= 5
);
alter policy "public can submit pending machine part listings" on public.machine_part_listings
with check (
  status='pending' and admin_notes is null
  and length(trim(coalesce(part_name,''))) between 1 and 160
  and length(trim(coalesce(category,''))) between 1 and 120
  and length(trim(coalesce(condition,''))) <= 120
  and length(trim(coalesce(expected_price,''))) <= 120
  and quantity between 1 and 100000
  and length(trim(coalesce(location,''))) between 1 and 200
  and length(trim(coalesce(details,''))) <= 3000
  and length(trim(coalesce(contact_name,''))) between 1 and 120
  and length(trim(coalesce(contact_phone,''))) between 5 and 40
);
alter policy "public can submit pending diamond listings" on public.diamond_trade_listings
with check (
  status='pending' and admin_notes is null
  and length(trim(coalesce(product_type,''))) between 1 and 160
  and length(trim(coalesce(description,''))) <= 3000
  and length(trim(coalesce(expected_price,''))) <= 120
  and length(trim(coalesce(quantity,''))) <= 120
  and length(trim(coalesce(location,''))) <= 200
  and length(trim(coalesce(contact_name,''))) between 1 and 120
  and length(trim(coalesce(contact_phone,''))) between 5 and 40
);
alter policy "Public can submit job applications" on public.job_applications
with check (
  status='pending'
  and length(trim(coalesce(full_name,''))) between 2 and 120
  and length(trim(coalesce(role_skills,''))) between 2 and 500
  and length(trim(coalesce(experience_qualifications,''))) <= 2000
  and length(trim(coalesce(preferred_location,''))) between 2 and 200
  and length(trim(coalesce(phone,''))) between 5 and 40
);
alter policy "Public can submit job vacancies" on public.job_vacancies
with check (
  status='pending'
  and length(trim(coalesce(company_name,''))) between 2 and 160
  and length(trim(coalesce(job_title,''))) between 2 and 160
  and length(trim(coalesce(description,responsibilities_skills,''))) between 2 and 3000
  and length(trim(coalesce(location,work_location,''))) between 2 and 200
  and length(trim(coalesce(employment_type,''))) <= 80
  and length(trim(coalesce(salary_range,pay_range,''))) <= 120
  and length(trim(coalesce(contact_details,''))) between 5 and 160
);
alter policy "Public can submit pending reviews" on public.reviews
with check (
  status='pending' and rating between 1 and 5
  and length(trim(coalesce(name,''))) between 1 and 120
  and length(trim(coalesce(review,''))) between 1 and 1600
);
