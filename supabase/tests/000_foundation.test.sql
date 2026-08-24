begin;

create extension if not exists pgtap with schema extensions;

select plan(4);

set local role anon;

select is(current_user::text, 'anon', 'smoke test runs as anon');
select is((select auth.uid()), null::uuid, 'anon has no authenticated subject');

reset role;

select set_config(
  'request.jwt.claim.sub',
  '00000000-0000-4000-8000-000000000001',
  true
);
select set_config(
  'request.jwt.claims',
  '{"sub":"00000000-0000-4000-8000-000000000001","role":"authenticated"}',
  true
);

set local role authenticated;

select is(current_user::text, 'authenticated', 'smoke test runs as authenticated');
select is(
  (select auth.uid()),
  '00000000-0000-4000-8000-000000000001'::uuid,
  'authenticated smoke actor resolves to Alice'
);

select * from finish();

rollback;
