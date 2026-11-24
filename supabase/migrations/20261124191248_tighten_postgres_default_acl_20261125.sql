
-- Keep future public-schema tables safe when created by the postgres role.
alter default privileges in schema public
  revoke delete, truncate, references, trigger, maintain on tables from anon, authenticated;
alter default privileges in schema public
  revoke update on tables from anon;
-- Public form inserts may use generated identity values, but must not reset sequences.
revoke update on all sequences in schema public from anon, authenticated;
alter default privileges in schema public
  revoke update on sequences from anon, authenticated;
