-- Match the service enquiry form's bounded company/machine fields.
alter policy "Public can insert enquiries" on public.enquiries
with check (
  status='new'
  and length(trim(coalesce(name,''))) between 2 and 120
  and length(trim(coalesce(email,''))) <= 254
  and length(trim(coalesce(whatsapp,''))) <= 40
  and length(trim(coalesce(subject,''))) <= 300
  and length(trim(coalesce(message,''))) between 5 and 5000
);
