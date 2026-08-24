insert into auth.users (id, email)
values
  ('00000000-0000-4000-8000-000000000001', 'alice@example.invalid'),
  ('00000000-0000-4000-8000-000000000002', 'bob@example.invalid');

insert into public.storage_recipe_memberships (organization_id, user_id)
values
  ('10000000-0000-4000-8000-000000000001', '00000000-0000-4000-8000-000000000001'),
  ('10000000-0000-4000-8000-000000000002', '00000000-0000-4000-8000-000000000002');
