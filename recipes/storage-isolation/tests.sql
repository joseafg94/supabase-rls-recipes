begin;

\ir schema.sql
\ir policies.sql
\ir seed.sql

select plan(14);

select set_config('request.jwt.claim.sub', '00000000-0000-4000-8000-000000000001', true);
select set_config('request.jwt.claims', '{"sub":"00000000-0000-4000-8000-000000000001","role":"authenticated"}', true);
set local role authenticated;

select is((select count(*) from public.storage_recipe_memberships), 1::bigint, 'Alice sees only her storage membership');
select is((select organization_id from public.storage_recipe_memberships), '10000000-0000-4000-8000-000000000001'::uuid, 'Alice membership resolves to Org A');
select is((select count(*) from public.storage_recipe_memberships where user_id = '00000000-0000-4000-8000-000000000002'), 0::bigint, 'Alice cannot read Bob membership');

reset role;
select set_config('request.jwt.claim.sub', '00000000-0000-4000-8000-000000000002', true);
select set_config('request.jwt.claims', '{"sub":"00000000-0000-4000-8000-000000000002","role":"authenticated"}', true);
set local role authenticated;

select is((select count(*) from public.storage_recipe_memberships), 1::bigint, 'Bob sees only his storage membership');
select is((select organization_id from public.storage_recipe_memberships), '10000000-0000-4000-8000-000000000002'::uuid, 'Bob membership resolves to Org B');
select is((select count(*) from public.storage_recipe_memberships where user_id = '00000000-0000-4000-8000-000000000001'), 0::bigint, 'Bob cannot read Alice membership');

reset role;
set local role anon;

select throws_ok($$select * from public.storage_recipe_memberships$$, '42501', 'permission denied for table storage_recipe_memberships', 'Anonymous membership read is denied');

reset role;

select is((select count(*) from pg_policies where schemaname = 'storage' and tablename = 'objects' and policyname like 'users can % scoped storage objects'), 4::bigint, 'Four command-specific Storage policies exist');
select is((select count(*) from pg_policies where schemaname = 'storage' and tablename = 'objects' and policyname like 'users can % scoped storage objects' and roles = array['authenticated'::name]), 4::bigint, 'Every Storage policy targets authenticated');
select is((select count(*) from pg_policies where schemaname = 'storage' and tablename = 'objects' and cmd = 'SELECT' and policyname = 'users can select scoped storage objects'), 1::bigint, 'Storage SELECT policy is explicit');
select is((select count(*) from pg_policies where schemaname = 'storage' and tablename = 'objects' and cmd = 'UPDATE' and with_check is not null), 1::bigint, 'Storage UPDATE policy has WITH CHECK');
select is((select count(*) from pg_policies where schemaname = 'storage' and tablename = 'objects' and cmd = 'DELETE'), 1::bigint, 'Storage DELETE policy is explicit');
select is((select count(*) from pg_class c join pg_namespace n on n.oid = c.relnamespace where n.nspname = 'public' and c.relname = 'storage_recipe_memberships' and c.relrowsecurity), 1::bigint, 'Catalog confirms RLS on Storage memberships');
select is((select count(*) from pg_policies where schemaname = 'public' and tablename = 'storage_recipe_memberships' and cmd = 'SELECT'), 1::bigint, 'Catalog confirms the membership SELECT policy');

select * from finish();
rollback;
