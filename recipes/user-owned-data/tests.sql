begin;

\ir schema.sql
\ir policies.sql
\ir seed.sql

select plan(35);

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

select is(
  (select auth.uid()),
  '00000000-0000-4000-8000-000000000001'::uuid,
  'Alice identity is active'
);
select is(
  (select count(*) from public.user_owned_notes),
  2::bigint,
  'Alice selects only her seeded notes'
);
select is(
  (
    select count(*)
    from public.user_owned_notes
    where id = '20000000-0000-4000-8000-000000000002'
  ),
  0::bigint,
  '[deny:select] Alice cannot select Bob note'
);
select lives_ok(
  $$
    insert into public.user_owned_notes (id, owner_id, body)
    values (
      '20000000-0000-4000-8000-000000000005',
      '00000000-0000-4000-8000-000000000001',
      'Alice inserted note'
    )
  $$,
  'Alice inserts her own note'
);
select is(
  (
    select count(*)
    from public.user_owned_notes
    where id = '20000000-0000-4000-8000-000000000005'
  ),
  1::bigint,
  'Alice sees her inserted note'
);
select throws_ok(
  $$
    insert into public.user_owned_notes (id, owner_id, body)
    values (
      '20000000-0000-4000-8000-000000000006',
      '00000000-0000-4000-8000-000000000002',
      'Forged Bob ownership'
    )
  $$,
  '42501',
  'new row violates row-level security policy for table "user_owned_notes"',
  '[deny:insert] Alice cannot forge Bob ownership on insert'
);
select lives_ok(
  $$
    update public.user_owned_notes
    set body = 'Alice updated note'
    where id = '20000000-0000-4000-8000-000000000001'
  $$,
  'Alice updates her own note'
);
select is(
  (
    select body
    from public.user_owned_notes
    where id = '20000000-0000-4000-8000-000000000001'
  ),
  'Alice updated note',
  'Alice sees her update'
);
select throws_ok(
  $$
    update public.user_owned_notes
    set owner_id = '00000000-0000-4000-8000-000000000002'
    where id = '20000000-0000-4000-8000-000000000001'
  $$,
  '42501',
  'new row violates row-level security policy for table "user_owned_notes"',
  'Alice cannot reassign her note to Bob'
);
select is_empty(
  $$
    update public.user_owned_notes
    set body = 'Alice changed Bob note'
    where id = '20000000-0000-4000-8000-000000000002'
    returning 1
  $$,
  '[deny:update] Alice update of Bob note affects no rows'
);
select is_empty(
  $$
    delete from public.user_owned_notes
    where id = '20000000-0000-4000-8000-000000000004'
    returning 1
  $$,
  '[deny:delete] Alice delete of Bob note affects no rows'
);
select results_eq(
  $$
    delete from public.user_owned_notes
    where id = '20000000-0000-4000-8000-000000000003'
    returning 1
  $$,
  $$values (1)$$,
  'Alice deletes her own note'
);

reset role;
select set_config(
  'request.jwt.claim.sub',
  '00000000-0000-4000-8000-000000000002',
  true
);
select set_config(
  'request.jwt.claims',
  '{"sub":"00000000-0000-4000-8000-000000000002","role":"authenticated"}',
  true
);
set local role authenticated;

select is(
  (select auth.uid()),
  '00000000-0000-4000-8000-000000000002'::uuid,
  'Bob identity is active'
);
select is(
  (select count(*) from public.user_owned_notes),
  2::bigint,
  'Bob selects only his seeded notes'
);
select is(
  (
    select count(*)
    from public.user_owned_notes
    where owner_id = '00000000-0000-4000-8000-000000000001'
  ),
  0::bigint,
  'Bob cannot select Alice notes'
);
select lives_ok(
  $$
    insert into public.user_owned_notes (id, owner_id, body)
    values (
      '20000000-0000-4000-8000-000000000007',
      '00000000-0000-4000-8000-000000000002',
      'Bob inserted note'
    )
  $$,
  'Bob inserts his own note'
);
select is(
  (
    select count(*)
    from public.user_owned_notes
    where id = '20000000-0000-4000-8000-000000000007'
  ),
  1::bigint,
  'Bob sees his inserted note'
);
select lives_ok(
  $$
    update public.user_owned_notes
    set body = 'Bob updated note'
    where id = '20000000-0000-4000-8000-000000000002'
  $$,
  'Bob updates his own note'
);
select is(
  (
    select body
    from public.user_owned_notes
    where id = '20000000-0000-4000-8000-000000000002'
  ),
  'Bob updated note',
  'Bob sees his update'
);
select is_empty(
  $$
    update public.user_owned_notes
    set body = 'Bob changed Alice note'
    where id = '20000000-0000-4000-8000-000000000005'
    returning 1
  $$,
  'Bob update of Alice note affects no rows'
);
select is_empty(
  $$
    delete from public.user_owned_notes
    where id = '20000000-0000-4000-8000-000000000005'
    returning 1
  $$,
  'Bob delete of Alice note affects no rows'
);
select results_eq(
  $$
    delete from public.user_owned_notes
    where id = '20000000-0000-4000-8000-000000000004'
    returning 1
  $$,
  $$values (1)$$,
  'Bob deletes his own note'
);

reset role;
select set_config('request.jwt.claim.sub', '', true);
select set_config('request.jwt.claims', '{}', true);
set local role anon;

select throws_ok(
  $$select * from public.user_owned_notes$$,
  '42501',
  'permission denied for table user_owned_notes',
  'Anonymous select is denied by grants'
);
select throws_ok(
  $$
    insert into public.user_owned_notes (id, owner_id, body)
    values (
      '20000000-0000-4000-8000-000000000008',
      '00000000-0000-4000-8000-000000000001',
      'Anonymous insert'
    )
  $$,
  '42501',
  'permission denied for table user_owned_notes',
  'Anonymous insert is denied by grants'
);
select throws_ok(
  $$
    update public.user_owned_notes
    set body = 'Anonymous update'
    where id = '20000000-0000-4000-8000-000000000001'
  $$,
  '42501',
  'permission denied for table user_owned_notes',
  'Anonymous update is denied by grants'
);
select throws_ok(
  $$
    delete from public.user_owned_notes
    where id = '20000000-0000-4000-8000-000000000001'
  $$,
  '42501',
  'permission denied for table user_owned_notes',
  'Anonymous delete is denied by grants'
);

reset role;

select is(
  (
    select count(*)
    from public.user_owned_notes
    where id in (
      '20000000-0000-4000-8000-000000000006',
      '20000000-0000-4000-8000-000000000008'
    )
  ),
  0::bigint,
  'Denied inserts created no rows'
);
select is(
  (
    select owner_id
    from public.user_owned_notes
    where id = '20000000-0000-4000-8000-000000000001'
  ),
  '00000000-0000-4000-8000-000000000001'::uuid,
  'Denied reassignment preserved Alice ownership'
);
select is(
  (
    select body
    from public.user_owned_notes
    where id = '20000000-0000-4000-8000-000000000001'
  ),
  'Alice updated note',
  'Denied cross-owner and anonymous updates preserved Alice note'
);
select is(
  (
    select body
    from public.user_owned_notes
    where id = '20000000-0000-4000-8000-000000000002'
  ),
  'Bob updated note',
  'Denied cross-owner operations preserved Bob note'
);
select is(
  (
    select count(*)
    from public.user_owned_notes
    where id in (
      '20000000-0000-4000-8000-000000000003',
      '20000000-0000-4000-8000-000000000004'
    )
  ),
  0::bigint,
  'Authorized deletes removed only their targets'
);
select is(
  (select count(*) from public.user_owned_notes),
  4::bigint,
  'Final state contains only allowed surviving rows'
);
select is((select count(*) from pg_class c join pg_namespace n on n.oid = c.relnamespace where n.nspname = 'public' and c.relname = 'user_owned_notes' and c.relrowsecurity), 1::bigint, 'Catalog confirms RLS on the recipe table');
select is((select count(*) from pg_policies where schemaname = 'public' and tablename = 'user_owned_notes'), 4::bigint, 'Catalog has one policy per CRUD command');
select is((select count(*) from pg_policies where schemaname = 'public' and tablename = 'user_owned_notes' and cmd = 'UPDATE' and with_check is not null), 1::bigint, 'Catalog confirms UPDATE WITH CHECK');

select * from finish();

rollback;
