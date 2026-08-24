begin;

\ir schema.sql
\ir policies.sql
\ir seed.sql

select plan(87);

select set_config('request.jwt.claim.sub', '00000000-0000-4000-8000-000000000001', true);
select set_config('request.jwt.claims', '{"sub":"00000000-0000-4000-8000-000000000001","role":"authenticated"}', true);
set local role authenticated;

select is((select auth.uid()), '00000000-0000-4000-8000-000000000001'::uuid, 'Alice owner identity is active');
select is((select count(*) from public.saas_organizations), 1::bigint, 'Alice sees only Org A');
select is((select count(*) from public.saas_organization_members), 1::bigint, 'Alice sees only her membership');
select is((select role from public.saas_organization_members), 'owner', 'Alice sees her owner role');
select is((select count(*) from public.saas_projects), 2::bigint, 'Alice sees Org A projects');
select is((select count(*) from public.saas_projects where organization_id = '10000000-0000-4000-8000-000000000002'), 0::bigint, '[deny:select] Alice cannot select Org B projects');
select is((select count(*) from public.saas_items), 3::bigint, 'Alice sees Org A items');
select is((select count(*) from public.saas_items where organization_id = '10000000-0000-4000-8000-000000000002'), 0::bigint, 'Alice cannot select Org B items');
select lives_ok($$insert into public.saas_projects (id, organization_id, name) values ('60000000-0000-4000-8000-000000000005', '10000000-0000-4000-8000-000000000001', 'Alice inserted project')$$, 'Alice inserts an Org A project');
select throws_ok(
  $$insert into public.saas_projects (id, organization_id, name) values ('60000000-0000-4000-8000-000000000008', '10000000-0000-4000-8000-000000000002', 'Alice forged Org B project')$$,
  '42501',
  'new row violates row-level security policy for table "saas_projects"',
  '[deny:insert] Alice cannot forge Org B on project insert'
);
select lives_ok($$update public.saas_projects set name = 'Alice updated project' where id = '60000000-0000-4000-8000-000000000001'$$, 'Alice updates an Org A project');
select is_empty($$update public.saas_projects set name = 'Alice cross-tenant update' where id = '60000000-0000-4000-8000-000000000003' returning 1$$, '[deny:update] Alice cannot update Org B project');
select throws_ok(
  $$update public.saas_projects set organization_id = '10000000-0000-4000-8000-000000000002' where id = '60000000-0000-4000-8000-000000000005'$$,
  '42501',
  'new row violates row-level security policy for table "saas_projects"',
  'Alice cannot reassign a project to Org B'
);
select results_eq($$delete from public.saas_projects where id = '60000000-0000-4000-8000-000000000002' returning 1$$, $$values (1)$$, 'Alice deletes an Org A project');
select is_empty($$delete from public.saas_projects where id = '60000000-0000-4000-8000-000000000004' returning 1$$, '[deny:delete] Alice cannot delete Org B project');
select lives_ok($$insert into public.saas_items (id, organization_id, project_id, name) values ('70000000-0000-4000-8000-000000000007', '10000000-0000-4000-8000-000000000001', '60000000-0000-4000-8000-000000000001', 'Alice inserted item')$$, 'Alice inserts an Org A item');
select throws_ok(
  $$insert into public.saas_items (id, organization_id, project_id, name) values ('70000000-0000-4000-8000-000000000010', '10000000-0000-4000-8000-000000000002', '60000000-0000-4000-8000-000000000003', 'Alice forged Org B item')$$,
  '42501',
  'new row violates row-level security policy for table "saas_items"',
  'Alice cannot forge Org B on item insert'
);
select throws_ok(
  $$insert into public.saas_items (id, organization_id, project_id, name) values ('70000000-0000-4000-8000-000000000011', '10000000-0000-4000-8000-000000000001', '60000000-0000-4000-8000-000000000003', 'Mismatched project tenant')$$,
  '23503',
  'insert or update on table "saas_items" violates foreign key constraint "saas_items_project_tenant_fkey"',
  'Composite foreign key rejects an Org B project under Org A'
);
select lives_ok($$update public.saas_items set name = 'Alice updated item' where id = '70000000-0000-4000-8000-000000000001'$$, 'Alice updates an Org A item');
select is_empty($$update public.saas_items set name = 'Alice cross-tenant item update' where id = '70000000-0000-4000-8000-000000000004' returning 1$$, 'Alice cannot update Org B item');
select throws_ok(
  $$update public.saas_items set organization_id = '10000000-0000-4000-8000-000000000002', project_id = '60000000-0000-4000-8000-000000000003' where id = '70000000-0000-4000-8000-000000000007'$$,
  '42501',
  'new row violates row-level security policy for table "saas_items"',
  'Alice cannot reassign an item to Org B'
);
select results_eq($$delete from public.saas_items where id = '70000000-0000-4000-8000-000000000003' returning 1$$, $$values (1)$$, 'Alice deletes an Org A item');
select is_empty($$delete from public.saas_items where id = '70000000-0000-4000-8000-000000000006' returning 1$$, 'Alice cannot delete Org B item');

reset role;
select set_config('request.jwt.claim.sub', '00000000-0000-4000-8000-000000000002', true);
select set_config('request.jwt.claims', '{"sub":"00000000-0000-4000-8000-000000000002","role":"authenticated"}', true);
set local role authenticated;

select is((select auth.uid()), '00000000-0000-4000-8000-000000000002'::uuid, 'Bob owner identity is active');
select is((select count(*) from public.saas_organizations), 1::bigint, 'Bob sees only Org B');
select is((select count(*) from public.saas_organization_members), 1::bigint, 'Bob sees only his membership');
select is((select role from public.saas_organization_members), 'owner', 'Bob sees his owner role');
select is((select count(*) from public.saas_projects), 2::bigint, 'Bob sees Org B projects');
select is((select count(*) from public.saas_projects where organization_id = '10000000-0000-4000-8000-000000000001'), 0::bigint, 'Bob cannot select Org A projects');
select is((select count(*) from public.saas_items), 3::bigint, 'Bob sees Org B items');
select is((select count(*) from public.saas_items where organization_id = '10000000-0000-4000-8000-000000000001'), 0::bigint, 'Bob cannot select Org A items');
select lives_ok($$insert into public.saas_projects (id, organization_id, name) values ('60000000-0000-4000-8000-000000000006', '10000000-0000-4000-8000-000000000002', 'Bob inserted project')$$, 'Bob inserts an Org B project');
select throws_ok(
  $$insert into public.saas_projects (id, organization_id, name) values ('60000000-0000-4000-8000-000000000009', '10000000-0000-4000-8000-000000000001', 'Bob forged Org A project')$$,
  '42501',
  'new row violates row-level security policy for table "saas_projects"',
  'Bob cannot forge Org A on project insert'
);
select lives_ok($$update public.saas_projects set name = 'Bob updated project' where id = '60000000-0000-4000-8000-000000000003'$$, 'Bob updates an Org B project');
select is_empty($$update public.saas_projects set name = 'Bob cross-tenant update' where id = '60000000-0000-4000-8000-000000000001' returning 1$$, 'Bob cannot update Org A project');
select throws_ok(
  $$update public.saas_projects set organization_id = '10000000-0000-4000-8000-000000000001' where id = '60000000-0000-4000-8000-000000000006'$$,
  '42501',
  'new row violates row-level security policy for table "saas_projects"',
  'Bob cannot reassign a project to Org A'
);
select results_eq($$delete from public.saas_projects where id = '60000000-0000-4000-8000-000000000004' returning 1$$, $$values (1)$$, 'Bob deletes an Org B project');
select is_empty($$delete from public.saas_projects where id = '60000000-0000-4000-8000-000000000005' returning 1$$, 'Bob cannot delete Org A project');
select lives_ok($$insert into public.saas_items (id, organization_id, project_id, name) values ('70000000-0000-4000-8000-000000000008', '10000000-0000-4000-8000-000000000002', '60000000-0000-4000-8000-000000000003', 'Bob inserted item')$$, 'Bob inserts an Org B item');
select throws_ok(
  $$insert into public.saas_items (id, organization_id, project_id, name) values ('70000000-0000-4000-8000-000000000012', '10000000-0000-4000-8000-000000000001', '60000000-0000-4000-8000-000000000001', 'Bob forged Org A item')$$,
  '42501',
  'new row violates row-level security policy for table "saas_items"',
  'Bob cannot forge Org A on item insert'
);
select lives_ok($$update public.saas_items set name = 'Bob updated item' where id = '70000000-0000-4000-8000-000000000004'$$, 'Bob updates an Org B item');
select is_empty($$update public.saas_items set name = 'Bob cross-tenant item update' where id = '70000000-0000-4000-8000-000000000001' returning 1$$, 'Bob cannot update Org A item');
select throws_ok(
  $$update public.saas_items set organization_id = '10000000-0000-4000-8000-000000000001', project_id = '60000000-0000-4000-8000-000000000001' where id = '70000000-0000-4000-8000-000000000008'$$,
  '42501',
  'new row violates row-level security policy for table "saas_items"',
  'Bob cannot reassign an item to Org A'
);
select results_eq($$delete from public.saas_items where id = '70000000-0000-4000-8000-000000000006' returning 1$$, $$values (1)$$, 'Bob deletes an Org B item');
select is_empty($$delete from public.saas_items where id = '70000000-0000-4000-8000-000000000007' returning 1$$, 'Bob cannot delete Org A item');

reset role;
select set_config('request.jwt.claim.sub', '00000000-0000-4000-8000-000000000003', true);
select set_config('request.jwt.claims', '{"sub":"00000000-0000-4000-8000-000000000003","role":"authenticated"}', true);
set local role authenticated;

select is((select auth.uid()), '00000000-0000-4000-8000-000000000003'::uuid, 'Carol identity is active');
select is((select count(*) from public.saas_organizations), 2::bigint, 'Carol sees both member organizations');
select is((select count(*) from public.saas_organization_members), 2::bigint, 'Carol sees only her two memberships');
select results_eq($$select role from public.saas_organization_members order by role$$, $$values ('admin'::text), ('member'::text)$$, 'Carol has admin in Org A and member in Org B');
select is((select count(*) from public.saas_projects), 4::bigint, 'Carol reads projects in both organizations');
select is((select count(*) from public.saas_items), 4::bigint, 'Carol reads items in both organizations');
select lives_ok($$insert into public.saas_projects (id, organization_id, name) values ('60000000-0000-4000-8000-000000000007', '10000000-0000-4000-8000-000000000001', 'Carol admin project')$$, 'Carol inserts project as Org A admin');
select lives_ok($$update public.saas_projects set name = 'Carol admin updated project' where id = '60000000-0000-4000-8000-000000000005'$$, 'Carol updates project as Org A admin');
select is_empty($$delete from public.saas_projects where id = '60000000-0000-4000-8000-000000000005' returning 1$$, 'Carol admin cannot delete Org A project');
select throws_ok(
  $$insert into public.saas_projects (id, organization_id, name) values ('60000000-0000-4000-8000-000000000010', '10000000-0000-4000-8000-000000000002', 'Carol member project')$$,
  '42501',
  'new row violates row-level security policy for table "saas_projects"',
  'Carol member cannot insert Org B project'
);
select is_empty($$update public.saas_projects set name = 'Carol member update' where id = '60000000-0000-4000-8000-000000000006' returning 1$$, 'Carol member cannot update Org B project');
select is_empty($$delete from public.saas_projects where id = '60000000-0000-4000-8000-000000000006' returning 1$$, 'Carol member cannot delete Org B project');
select lives_ok($$insert into public.saas_items (id, organization_id, project_id, name) values ('70000000-0000-4000-8000-000000000009', '10000000-0000-4000-8000-000000000001', '60000000-0000-4000-8000-000000000007', 'Carol admin item')$$, 'Carol inserts item as Org A admin');
select lives_ok($$update public.saas_items set name = 'Carol admin updated item' where id = '70000000-0000-4000-8000-000000000007'$$, 'Carol updates item as Org A admin');
select is_empty($$delete from public.saas_items where id = '70000000-0000-4000-8000-000000000007' returning 1$$, 'Carol admin cannot delete Org A item');
select throws_ok(
  $$insert into public.saas_items (id, organization_id, project_id, name) values ('70000000-0000-4000-8000-000000000013', '10000000-0000-4000-8000-000000000002', '60000000-0000-4000-8000-000000000006', 'Carol member item')$$,
  '42501',
  'new row violates row-level security policy for table "saas_items"',
  'Carol member cannot insert Org B item'
);
select is_empty($$update public.saas_items set name = 'Carol member item update' where id = '70000000-0000-4000-8000-000000000008' returning 1$$, 'Carol member cannot update Org B item');
select is_empty($$delete from public.saas_items where id = '70000000-0000-4000-8000-000000000008' returning 1$$, 'Carol member cannot delete Org B item');
select throws_ok(
  $$insert into public.saas_items (id, organization_id, project_id, name) values ('70000000-0000-4000-8000-000000000014', '10000000-0000-4000-8000-000000000001', '60000000-0000-4000-8000-000000000006', 'Carol mismatched related path')$$,
  '23503',
  'insert or update on table "saas_items" violates foreign key constraint "saas_items_project_tenant_fkey"',
  'Related path cannot mix Carol admin tenant with Org B project'
);
select throws_ok(
  $$insert into public.saas_organization_members (organization_id, user_id, role, joined_at) values ('10000000-0000-4000-8000-000000000002', '00000000-0000-4000-8000-000000000001', 'owner', '2026-01-02 00:00:00+00')$$,
  '42501',
  'permission denied for table saas_organization_members',
  'Direct membership self-enrollment is denied'
);
select throws_ok(
  $$update public.saas_organization_members set role = 'owner' where organization_id = '10000000-0000-4000-8000-000000000002' and user_id = '00000000-0000-4000-8000-000000000003'$$,
  '42501',
  'permission denied for table saas_organization_members',
  'Direct membership role escalation is denied'
);

reset role;
select set_config('request.jwt.claim.sub', '', true);
select set_config('request.jwt.claims', '{}', true);
set local role anon;

select throws_ok($$select * from public.saas_organizations$$, '42501', 'permission denied for table saas_organizations', 'Anonymous organization read is denied');
select throws_ok($$select * from public.saas_organization_members$$, '42501', 'permission denied for table saas_organization_members', 'Anonymous membership read is denied');
select throws_ok($$select * from public.saas_projects$$, '42501', 'permission denied for table saas_projects', 'Anonymous project read is denied');
select throws_ok($$select * from public.saas_items$$, '42501', 'permission denied for table saas_items', 'Anonymous item read is denied');

reset role;

select is((select count(*) from public.saas_organizations), 2::bigint, 'Final organization set is unchanged');
select is((select count(*) from public.saas_organization_members), 4::bigint, 'Final membership set is unchanged');
select is((select count(*) from public.saas_projects), 5::bigint, 'Final project count is exact');
select is((select count(*) from public.saas_items), 5::bigint, 'Final item count is exact');
select is((select count(*) from public.saas_projects where id in ('60000000-0000-4000-8000-000000000008', '60000000-0000-4000-8000-000000000009', '60000000-0000-4000-8000-000000000010')), 0::bigint, 'Denied project inserts created no rows');
select is((select count(*) from public.saas_items where id in ('70000000-0000-4000-8000-000000000010', '70000000-0000-4000-8000-000000000011', '70000000-0000-4000-8000-000000000012', '70000000-0000-4000-8000-000000000013', '70000000-0000-4000-8000-000000000014')), 0::bigint, 'Denied item inserts created no rows');
select is((select organization_id from public.saas_projects where id = '60000000-0000-4000-8000-000000000005'), '10000000-0000-4000-8000-000000000001'::uuid, 'Alice project reassignment was denied');
select is((select organization_id from public.saas_projects where id = '60000000-0000-4000-8000-000000000006'), '10000000-0000-4000-8000-000000000002'::uuid, 'Bob project reassignment was denied');
select is((select name from public.saas_projects where id = '60000000-0000-4000-8000-000000000005'), 'Carol admin updated project', 'Carol admin update persisted in Org A');
select is((select name from public.saas_projects where id = '60000000-0000-4000-8000-000000000006'), 'Bob inserted project', 'Carol member update did not change Org B');
select is((select name from public.saas_items where id = '70000000-0000-4000-8000-000000000007'), 'Carol admin updated item', 'Carol admin item update persisted in Org A');
select is((select name from public.saas_items where id = '70000000-0000-4000-8000-000000000008'), 'Bob inserted item', 'Carol member mutations did not change Org B item');
select is((select count(*) from public.saas_projects where id in ('60000000-0000-4000-8000-000000000002', '60000000-0000-4000-8000-000000000004')), 0::bigint, 'Owner project deletes removed both tenant targets');
select is((select count(*) from public.saas_items where id in ('70000000-0000-4000-8000-000000000002', '70000000-0000-4000-8000-000000000003', '70000000-0000-4000-8000-000000000005', '70000000-0000-4000-8000-000000000006')), 0::bigint, 'Owner deletes and project cascades removed exact item targets');
select is((select count(*) from pg_class c join pg_namespace n on n.oid = c.relnamespace where n.nspname = 'public' and c.relname in ('saas_organizations', 'saas_organization_members', 'saas_projects', 'saas_items') and c.relrowsecurity), 4::bigint, 'Catalog confirms RLS on all SaaS recipe tables');
select is((select count(*) from pg_policies where schemaname = 'public' and tablename in ('saas_organizations', 'saas_organization_members', 'saas_projects', 'saas_items')), 10::bigint, 'Catalog confirms the complete SaaS policy set');
select is((select count(*) from pg_policies where schemaname = 'public' and tablename in ('saas_projects', 'saas_items') and cmd = 'UPDATE' and with_check is not null), 2::bigint, 'Catalog confirms project and item UPDATE WITH CHECK policies');

select * from finish();
rollback;
