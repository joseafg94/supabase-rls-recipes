begin;

create extension if not exists pgtap with schema extensions;
set search_path = public, extensions;

\ir schema.sql
\ir policies.sql
\ir seed.sql

select plan(10);

set local role authenticated;
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000001', true);
select set_config('request.jwt.claim.role', 'authenticated', true);

select is((select count(*) from public.admin_boundary_records), 1::bigint, 'Alice reads only her record');
select is(
  (select count(*) from public.admin_boundary_records where owner_id = '00000000-0000-0000-0000-000000000002'),
  0::bigint,
  'Alice cannot read Bob record'
);

update public.admin_boundary_records
set body = 'Alice updated record'
where id = '80000000-0000-0000-0000-000000000001';

select is(
  (select body from public.admin_boundary_records where id = '80000000-0000-0000-0000-000000000001'),
  'Alice updated record',
  'Alice updates her record'
);
select lives_ok(
  $$update public.admin_boundary_records set body = 'forged' where id = '80000000-0000-0000-0000-000000000002'$$,
  'Cross-owner update is a zero-row mutation'
);
select throws_ok(
  $$update public.admin_boundary_records set owner_id = '00000000-0000-0000-0000-000000000002' where id = '80000000-0000-0000-0000-000000000001'$$,
  '42501',
  null,
  'Owner reassignment is rejected by WITH CHECK'
);

select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000002', true);
select is((select count(*) from public.admin_boundary_records), 1::bigint, 'Bob reads only his record');

reset role;
set local role anon;
select set_config('request.jwt.claim.sub', '', true);
select set_config('request.jwt.claim.role', 'anon', true);
select throws_ok(
  $$select * from public.admin_boundary_records$$,
  '42501',
  null,
  'Anonymous callers have no table grant'
);

reset role;
select ok((select rolbypassrls from pg_roles where rolname = 'service_role'), 'The local service role bypasses RLS');
select is((select count(*) from public.admin_boundary_records), 2::bigint, 'Trusted database context sees the exact final row count');
select is(
  (select body from public.admin_boundary_records where id = '80000000-0000-0000-0000-000000000002'),
  'Bob private record',
  'Cross-owner zero-row mutation did not change Bob record'
);

select * from finish();
rollback;

