begin;

\ir schema.sql
\ir policies.sql
\ir seed.sql

select plan(47);

select set_config('request.jwt.claim.sub', '00000000-0000-4000-8000-000000000001', true);
select set_config('request.jwt.claims', '{"sub":"00000000-0000-4000-8000-000000000001","role":"authenticated"}', true);
set local role authenticated;

select is((select auth.uid()), '00000000-0000-4000-8000-000000000001'::uuid, 'Alice owner identity is active');
select is((select count(*) from public.role_organizations), 2::bigint, 'Alice sees her two organizations');
select is((select count(*) from public.role_organizations where id = '10000000-0000-4000-8000-000000000002'), 0::bigint, '[deny:select] Alice cannot see Org B');
select is((select count(*) from public.role_members), 2::bigint, 'Alice sees only her two role rows');
select lives_ok($$update public.role_organizations set name = 'Role Organization A updated' where id = '10000000-0000-4000-8000-000000000001'$$, 'Owner updates her organization');
select is_empty($$update public.role_organizations set name = 'Cross-org update' where id = '10000000-0000-4000-8000-000000000002' returning 1$$, 'Owner cannot update another organization');
select is_empty($$delete from public.role_organizations where id = '10000000-0000-4000-8000-000000000002' returning 1$$, '[deny:delete] Owner cannot delete another organization');
select results_eq($$delete from public.role_organizations where id = '10000000-0000-4000-8000-000000000003' returning 1$$, $$values (1)$$, 'Owner deletes her secondary organization');
select lives_ok($$insert into public.role_resources (id, organization_id, name) values ('40000000-0000-4000-8000-000000000005', '10000000-0000-4000-8000-000000000001', 'Owner insert')$$, 'Owner inserts a resource');
select lives_ok($$update public.role_resources set name = 'Owner updated resource' where id = '40000000-0000-4000-8000-000000000001'$$, 'Owner updates a resource');
select results_eq($$delete from public.role_resources where id = '40000000-0000-4000-8000-000000000002' returning 1$$, $$values (1)$$, 'Owner deletes a resource');
select throws_ok(
  $$insert into public.role_resources (id, organization_id, name) values ('40000000-0000-4000-8000-000000000006', '10000000-0000-4000-8000-000000000002', 'Forged Org B resource')$$,
  '42501',
  'new row violates row-level security policy for table "role_resources"',
  '[deny:insert] Owner cannot insert into another organization'
);

reset role;
select set_config('request.jwt.claim.sub', '00000000-0000-4000-8000-000000000002', true);
select set_config('request.jwt.claims', '{"sub":"00000000-0000-4000-8000-000000000002","role":"authenticated"}', true);
set local role authenticated;

select is((select auth.uid()), '00000000-0000-4000-8000-000000000002'::uuid, 'Bob admin identity is active');
select is((select count(*) from public.role_organizations), 1::bigint, 'Admin sees Org A');
select is((select count(*) from public.role_members), 1::bigint, 'Admin sees only his role row');
select is((select count(*) from public.role_resources), 2::bigint, 'Admin sees Org A resources');
select lives_ok($$insert into public.role_resources (id, organization_id, name) values ('40000000-0000-4000-8000-000000000007', '10000000-0000-4000-8000-000000000001', 'Admin insert')$$, 'Admin inserts a resource');
select lives_ok($$update public.role_resources set name = 'Admin updated owner insert' where id = '40000000-0000-4000-8000-000000000005'$$, 'Admin updates a resource');
select is_empty($$delete from public.role_resources where id = '40000000-0000-4000-8000-000000000001' returning 1$$, 'Admin cannot delete resources');
select is_empty($$update public.role_resources set name = 'Admin cross-org update' where id = '40000000-0000-4000-8000-000000000003' returning 1$$, '[deny:update] Admin cannot update another organization');
select throws_ok(
  $$insert into public.role_members (organization_id, user_id, role, joined_at) values ('10000000-0000-4000-8000-000000000002', '00000000-0000-4000-8000-000000000002', 'owner', '2026-01-02 00:00:00+00')$$,
  '42501',
  'permission denied for table role_members',
  'Admin cannot self-enroll as owner elsewhere'
);
select throws_ok(
  $$update public.role_members set role = 'owner' where organization_id = '10000000-0000-4000-8000-000000000001' and user_id = '00000000-0000-4000-8000-000000000002'$$,
  '42501',
  'permission denied for table role_members',
  'Admin cannot escalate his own role'
);

reset role;
select set_config('request.jwt.claim.sub', '00000000-0000-4000-8000-000000000003', true);
select set_config('request.jwt.claims', '{"sub":"00000000-0000-4000-8000-000000000003","role":"authenticated"}', true);
set local role authenticated;

select is((select auth.uid()), '00000000-0000-4000-8000-000000000003'::uuid, 'Carol member identity is active');
select is((select count(*) from public.role_organizations), 1::bigint, 'Member sees Org A');
select is((select count(*) from public.role_resources), 3::bigint, 'Member reads Org A resources');
select throws_ok(
  $$insert into public.role_resources (id, organization_id, name) values ('40000000-0000-4000-8000-000000000008', '10000000-0000-4000-8000-000000000001', 'Member insert')$$,
  '42501',
  'new row violates row-level security policy for table "role_resources"',
  'Member cannot insert resources'
);
select is_empty($$update public.role_resources set name = 'Member update' where id = '40000000-0000-4000-8000-000000000001' returning 1$$, 'Member cannot update resources');
select is_empty($$delete from public.role_resources where id = '40000000-0000-4000-8000-000000000001' returning 1$$, 'Member cannot delete resources');
select throws_ok(
  $$update public.role_members set role = 'owner' where organization_id = '10000000-0000-4000-8000-000000000001' and user_id = '00000000-0000-4000-8000-000000000003'$$,
  '42501',
  'permission denied for table role_members',
  'Member cannot escalate her own role'
);

reset role;
select set_config('request.jwt.claim.sub', '00000000-0000-4000-8000-000000000004', true);
select set_config('request.jwt.claims', '{"sub":"00000000-0000-4000-8000-000000000004","role":"authenticated"}', true);
set local role authenticated;

select is((select auth.uid()), '00000000-0000-4000-8000-000000000004'::uuid, 'Dave owner identity is active');
select is((select count(*) from public.role_organizations), 1::bigint, 'Dave sees Org B');
select is((select count(*) from public.role_resources), 1::bigint, 'Dave sees Org B resource');
select results_eq($$delete from public.role_resources where id = '40000000-0000-4000-8000-000000000003' returning 1$$, $$values (1)$$, 'Dave deletes an Org B resource');
select results_eq($$delete from public.role_organizations where id = '10000000-0000-4000-8000-000000000002' returning 1$$, $$values (1)$$, 'Dave deletes Org B');

reset role;
select set_config('request.jwt.claim.sub', '', true);
select set_config('request.jwt.claims', '{}', true);
set local role anon;

select throws_ok($$select * from public.role_organizations$$, '42501', 'permission denied for table role_organizations', 'Anonymous organization read is denied');
select throws_ok($$select * from public.role_resources$$, '42501', 'permission denied for table role_resources', 'Anonymous resource read is denied');

reset role;

select is((select count(*) from public.role_resources where id in ('40000000-0000-4000-8000-000000000006', '40000000-0000-4000-8000-000000000008')), 0::bigint, 'Denied resource inserts created no rows');
select is((select name from public.role_organizations where id = '10000000-0000-4000-8000-000000000001'), 'Role Organization A updated', 'Only authorized organization update persisted');
select is((select count(*) from public.role_resources where id = '40000000-0000-4000-8000-000000000001'), 1::bigint, 'Admin and member delete attempts preserved resource');
select is((select count(*) from public.role_organizations where id = '10000000-0000-4000-8000-000000000003'), 0::bigint, 'Alice deleted Org C');
select is((select count(*) from public.role_organizations where id = '10000000-0000-4000-8000-000000000002'), 0::bigint, 'Dave deleted Org B');
select is((select count(*) from public.role_organizations), 1::bigint, 'Only Org A remains');
select is((select count(*) from public.role_resources), 3::bigint, 'Final resources reflect only permitted mutations');
select is((select count(*) from public.role_members), 3::bigint, 'Cascades and denied escalations left correct memberships');
select is((select count(*) from pg_class c join pg_namespace n on n.oid = c.relnamespace where n.nspname = 'public' and c.relname in ('role_organizations', 'role_members', 'role_resources') and c.relrowsecurity), 3::bigint, 'Catalog confirms RLS on all role recipe tables');
select is((select count(*) from pg_policies where schemaname = 'public' and tablename in ('role_organizations', 'role_members', 'role_resources')), 8::bigint, 'Catalog confirms the role policy set');
select is((select count(*) from pg_policies where schemaname = 'public' and tablename in ('role_organizations', 'role_resources') and cmd = 'UPDATE' and with_check is not null), 2::bigint, 'Catalog confirms both UPDATE WITH CHECK policies');

select * from finish();
rollback;
