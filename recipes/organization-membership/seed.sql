insert into auth.users (id, email)
values
  ('00000000-0000-4000-8000-000000000001', 'alice@example.invalid'),
  ('00000000-0000-4000-8000-000000000002', 'bob@example.invalid');

insert into public.membership_organizations (id, name)
values
  ('10000000-0000-4000-8000-000000000001', 'Organization A'),
  ('10000000-0000-4000-8000-000000000002', 'Organization B');

insert into public.membership_organization_members (
  organization_id,
  user_id,
  joined_at
)
values
  (
    '10000000-0000-4000-8000-000000000001',
    '00000000-0000-4000-8000-000000000001',
    '2026-01-01 00:00:00+00'
  ),
  (
    '10000000-0000-4000-8000-000000000002',
    '00000000-0000-4000-8000-000000000002',
    '2026-01-01 00:01:00+00'
  );

insert into public.membership_resources (id, organization_id, name)
values
  (
    '30000000-0000-4000-8000-000000000001',
    '10000000-0000-4000-8000-000000000001',
    'Org A original'
  ),
  (
    '30000000-0000-4000-8000-000000000002',
    '10000000-0000-4000-8000-000000000002',
    'Org B original'
  ),
  (
    '30000000-0000-4000-8000-000000000003',
    '10000000-0000-4000-8000-000000000001',
    'Org A delete target'
  ),
  (
    '30000000-0000-4000-8000-000000000004',
    '10000000-0000-4000-8000-000000000002',
    'Org B delete target'
  );
