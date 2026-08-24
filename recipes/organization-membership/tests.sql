begin;

\ir schema.sql
\ir policies.sql
\ir seed.sql

select plan(38);

select set_config('request.jwt.claim.sub', '00000000-0000-4000-8000-000000000001', true);
select set_config('request.jwt.claims', '{"sub":"00000000-0000-4000-8000-000000000001","role":"authenticated"}', true);
set local role authenticated;

select is((select auth.uid()), '00000000-0000-4000-8000-000000000001'::uuid, 'Alice identity is active');
select is((select count(*) from public.membership_organizations), 1::bigint, 'Alice sees only Org A');
select is((select count(*) from public.membership_organizations where id = '10000000-0000-4000-8000-000000000002'), 0::bigint, 'Alice cannot see Org B');
select is((select count(*) from public.membership_organization_members), 1::bigint, 'Alice sees only her membership row');
select is((select count(*) from public.membership_organization_members where user_id = '00000000-0000-4000-8000-000000000002'), 0::bigint, 'Alice cannot read Bob membership directly');
select is((select count(*) from public.membership_resources), 2::bigint, 'Alice sees only Org A resources');
select is((select count(*) from public.membership_resources where id = '30000000-0000-4000-8000-000000000002'), 0::bigint, '[deny:select] Alice cannot see Org B resource');
select lives_ok(
  $$insert into public.membership_resources (id, organization_id, name) values ('30000000-0000-4000-8000-000000000005', '10000000-0000-4000-8000-000000000001', 'Alice Org A insert')$$,
  'Alice inserts an Org A resource'
);
select is((select count(*) from public.membership_resources where id = '30000000-0000-4000-8000-000000000005'), 1::bigint, 'Alice sees her Org A insert');
select throws_ok(
  $$insert into public.membership_resources (id, organization_id, name) values ('30000000-0000-4000-8000-000000000006', '10000000-0000-4000-8000-000000000002', 'Forged Org B insert')$$,
  '42501',
  'new row violates row-level security policy for table "membership_resources"',
  '[deny:insert] Alice cannot forge Org B on insert'
);
select lives_ok(
  $$update public.membership_resources set name = 'Org A updated' where id = '30000000-0000-4000-8000-000000000001'$$,
  'Alice updates an Org A resource'
);
select is_empty(
  $$update public.membership_resources set name = 'Cross-org update' where id = '30000000-0000-4000-8000-000000000002' returning 1$$,
  '[deny:update] Alice update of Org B affects no rows'
);
select results_eq(
  $$delete from public.membership_resources where id = '30000000-0000-4000-8000-000000000003' returning 1$$,
  $$values (1)$$,
  'Alice deletes an Org A resource'
);
select is_empty(
  $$delete from public.membership_resources where id = '30000000-0000-4000-8000-000000000004' returning 1$$,
  '[deny:delete] Alice delete of Org B affects no rows'
);
select throws_ok(
  $$insert into public.membership_organization_members (organization_id, user_id, joined_at) values ('10000000-0000-4000-8000-000000000002', '00000000-0000-4000-8000-000000000001', '2026-01-02 00:00:00+00')$$,
  '42501',
  'permission denied for table membership_organization_members',
  'Alice cannot self-enroll into Org B'
);

reset role;
select set_config('request.jwt.claim.sub', '00000000-0000-4000-8000-000000000002', true);
select set_config('request.jwt.claims', '{"sub":"00000000-0000-4000-8000-000000000002","role":"authenticated"}', true);
set local role authenticated;

select is((select auth.uid()), '00000000-0000-4000-8000-000000000002'::uuid, 'Bob identity is active');
select is((select count(*) from public.membership_organizations), 1::bigint, 'Bob sees only Org B');
select is((select count(*) from public.membership_organization_members), 1::bigint, 'Bob sees only his membership row');
select is((select count(*) from public.membership_resources), 2::bigint, 'Bob sees only Org B resources');
select is((select count(*) from public.membership_resources where organization_id = '10000000-0000-4000-8000-000000000001'), 0::bigint, 'Bob cannot see Org A resources');
select lives_ok(
  $$insert into public.membership_resources (id, organization_id, name) values ('30000000-0000-4000-8000-000000000007', '10000000-0000-4000-8000-000000000002', 'Bob Org B insert')$$,
  'Bob inserts an Org B resource'
);
select lives_ok(
  $$update public.membership_resources set name = 'Org B updated' where id = '30000000-0000-4000-8000-000000000002'$$,
  'Bob updates an Org B resource'
);
select is_empty(
  $$update public.membership_resources set name = 'Cross-org Bob update' where id = '30000000-0000-4000-8000-000000000005' returning 1$$,
  'Bob update of Org A affects no rows'
);
select results_eq(
  $$delete from public.membership_resources where id = '30000000-0000-4000-8000-000000000004' returning 1$$,
  $$values (1)$$,
  'Bob deletes an Org B resource'
);
select is_empty(
  $$delete from public.membership_resources where id = '30000000-0000-4000-8000-000000000005' returning 1$$,
  'Bob delete of Org A affects no rows'
);

reset role;
select set_config('request.jwt.claim.sub', '', true);
select set_config('request.jwt.claims', '{}', true);
set local role anon;

select throws_ok($$select * from public.membership_organizations$$, '42501', 'permission denied for table membership_organizations', 'Anonymous organization read is denied');
select throws_ok($$select * from public.membership_organization_members$$, '42501', 'permission denied for table membership_organization_members', 'Anonymous membership read is denied');
select throws_ok($$select * from public.membership_resources$$, '42501', 'permission denied for table membership_resources', 'Anonymous resource read is denied');
select throws_ok(
  $$insert into public.membership_resources (id, organization_id, name) values ('30000000-0000-4000-8000-000000000008', '10000000-0000-4000-8000-000000000001', 'Anonymous insert')$$,
  '42501',
  'permission denied for table membership_resources',
  'Anonymous resource insert is denied'
);

reset role;

select is((select count(*) from public.membership_resources where id in ('30000000-0000-4000-8000-000000000006', '30000000-0000-4000-8000-000000000008')), 0::bigint, 'Denied inserts created no rows');
select is((select count(*) from public.membership_organization_members), 2::bigint, 'Denied self-enrollment preserved membership set');
select is((select name from public.membership_resources where id = '30000000-0000-4000-8000-000000000001'), 'Org A updated', 'Org A row kept only its authorized update');
select is((select name from public.membership_resources where id = '30000000-0000-4000-8000-000000000002'), 'Org B updated', 'Org B row kept only its authorized update');
select is((select count(*) from public.membership_resources where id in ('30000000-0000-4000-8000-000000000003', '30000000-0000-4000-8000-000000000004')), 0::bigint, 'Authorized deletes removed their targets');
select is((select count(*) from public.membership_resources), 4::bigint, 'Final resource state contains only authorized survivors');
select is((select count(*) from pg_class c join pg_namespace n on n.oid = c.relnamespace where n.nspname = 'public' and c.relname in ('membership_organizations', 'membership_organization_members', 'membership_resources') and c.relrowsecurity), 3::bigint, 'Catalog confirms RLS on all membership recipe tables');
select is((select count(*) from pg_policies where schemaname = 'public' and tablename in ('membership_organizations', 'membership_organization_members', 'membership_resources')), 6::bigint, 'Catalog confirms the membership policy set');
select is((select count(*) from pg_policies where schemaname = 'public' and tablename = 'membership_resources' and cmd = 'UPDATE' and with_check is not null), 1::bigint, 'Catalog confirms resource UPDATE WITH CHECK');

select * from finish();
rollback;
