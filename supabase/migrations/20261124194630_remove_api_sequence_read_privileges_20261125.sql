-- Keep sequence usage for INSERT-generated IDs, but do not expose sequence reads.
revoke select on all sequences in schema public from anon, authenticated;
alter default privileges for role postgres in schema public
  revoke select on sequences from anon, authenticated;
