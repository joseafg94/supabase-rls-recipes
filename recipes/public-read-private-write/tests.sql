begin;

\ir schema.sql
\ir policies.sql
\ir seed.sql

select plan(41);

set local role anon;

select is(current_user::text, 'anon', 'Anonymous role is active');
select is((select count(*) from public.public_content_items), 2::bigint, 'Anonymous sees only published rows');
select is((select count(*) from public.public_content_items where not published), 0::bigint, '[deny:select] Anonymous sees no drafts');
select results_eq(
  $$select title from public.public_content_items order by title$$,
  $$values ('Alice published'::text), ('Bob published'::text)$$,
  'Anonymous published row set is exact'
);
select throws_ok(
  $$insert into public.public_content_items (id, owner_id, title) values ('50000000-0000-4000-8000-000000000010', '00000000-0000-4000-8000-000000000001', 'Anonymous insert')$$,
  '42501',
  'permission denied for table public_content_items',
  '[deny:insert] Anonymous insert is denied'
);
select throws_ok($$update public.public_content_items set title = 'Anonymous update' where id = '50000000-0000-4000-8000-000000000001'$$, '42501', 'permission denied for table public_content_items', '[deny:update] Anonymous update is denied');
select throws_ok($$delete from public.public_content_items where id = '50000000-0000-4000-8000-000000000001'$$, '42501', 'permission denied for table public_content_items', '[deny:delete] Anonymous delete is denied');

reset role;
select set_config('request.jwt.claim.sub', '00000000-0000-4000-8000-000000000001', true);
select set_config('request.jwt.claims', '{"sub":"00000000-0000-4000-8000-000000000001","role":"authenticated"}', true);
set local role authenticated;

select is((select auth.uid()), '00000000-0000-4000-8000-000000000001'::uuid, 'Alice identity is active');
select is((select count(*) from public.public_content_items), 4::bigint, 'Alice sees public rows and her drafts');
select is((select count(*) from public.public_content_items where id = '50000000-0000-4000-8000-000000000005'), 0::bigint, 'Alice cannot see Bob draft');
select lives_ok(
  $$insert into public.public_content_items (id, owner_id, title, published) values ('50000000-0000-4000-8000-000000000007', '00000000-0000-4000-8000-000000000001', 'Alice inserted draft', false)$$,
  'Alice inserts her draft'
);
select is((select count(*) from public.public_content_items where id = '50000000-0000-4000-8000-000000000007'), 1::bigint, 'Alice sees her inserted draft');
select throws_ok(
  $$insert into public.public_content_items (id, owner_id, title, published) values ('50000000-0000-4000-8000-000000000008', '00000000-0000-4000-8000-000000000002', 'Forged Bob content', false)$$,
  '42501',
  'new row violates row-level security policy for table "public_content_items"',
  'Alice cannot forge Bob ownership'
);
select lives_ok($$update public.public_content_items set published = true where id = '50000000-0000-4000-8000-000000000002'$$, 'Alice publishes her draft');
select is((select published from public.public_content_items where id = '50000000-0000-4000-8000-000000000002'), true, 'Alice sees the published state');
select throws_ok(
  $$update public.public_content_items set owner_id = '00000000-0000-4000-8000-000000000002' where id = '50000000-0000-4000-8000-000000000001'$$,
  '42501',
  'new row violates row-level security policy for table "public_content_items"',
  'Alice cannot reassign content to Bob'
);
select is_empty($$update public.public_content_items set title = 'Alice changed Bob content' where id = '50000000-0000-4000-8000-000000000004' returning 1$$, 'Alice cannot update Bob published row');
select is_empty($$delete from public.public_content_items where id = '50000000-0000-4000-8000-000000000004' returning 1$$, 'Alice cannot delete Bob published row');
select results_eq($$delete from public.public_content_items where id = '50000000-0000-4000-8000-000000000003' returning 1$$, $$values (1)$$, 'Alice deletes her private target');

reset role;
select set_config('request.jwt.claim.sub', '00000000-0000-4000-8000-000000000002', true);
select set_config('request.jwt.claims', '{"sub":"00000000-0000-4000-8000-000000000002","role":"authenticated"}', true);
set local role authenticated;

select is((select auth.uid()), '00000000-0000-4000-8000-000000000002'::uuid, 'Bob identity is active');
select is((select count(*) from public.public_content_items), 5::bigint, 'Bob sees public rows and his drafts');
select is((select count(*) from public.public_content_items where id = '50000000-0000-4000-8000-000000000007'), 0::bigint, 'Bob cannot see Alice private insert');
select lives_ok(
  $$insert into public.public_content_items (id, owner_id, title, published) values ('50000000-0000-4000-8000-000000000009', '00000000-0000-4000-8000-000000000002', 'Bob inserted draft', false)$$,
  'Bob inserts his draft'
);
select lives_ok($$update public.public_content_items set published = true where id = '50000000-0000-4000-8000-000000000005'$$, 'Bob publishes his draft');
select results_eq($$delete from public.public_content_items where id = '50000000-0000-4000-8000-000000000006' returning 1$$, $$values (1)$$, 'Bob deletes his private target');
select is_empty($$update public.public_content_items set title = 'Bob changed Alice draft' where id = '50000000-0000-4000-8000-000000000007' returning 1$$, 'Bob cannot update Alice private row');
select is_empty($$delete from public.public_content_items where id = '50000000-0000-4000-8000-000000000007' returning 1$$, 'Bob cannot delete Alice private row');

reset role;
select set_config('request.jwt.claim.sub', '', true);
select set_config('request.jwt.claims', '{}', true);
set local role anon;

select is((select count(*) from public.public_content_items), 4::bigint, 'Anonymous sees newly published rows');
select is((select count(*) from public.public_content_items where id = '50000000-0000-4000-8000-000000000007'), 0::bigint, 'Anonymous cannot see Alice inserted draft');
select is((select count(*) from public.public_content_items where not published), 0::bigint, 'Anonymous still sees no unpublished rows');

reset role;

select is((select count(*) from public.public_content_items where id in ('50000000-0000-4000-8000-000000000008', '50000000-0000-4000-8000-000000000010')), 0::bigint, 'Denied inserts created no rows');
select is((select owner_id from public.public_content_items where id = '50000000-0000-4000-8000-000000000001'), '00000000-0000-4000-8000-000000000001'::uuid, 'Denied reassignment preserved ownership');
select is((select title from public.public_content_items where id = '50000000-0000-4000-8000-000000000007'), 'Alice inserted draft', 'Denied cross-owner mutations preserved Alice draft');
select is((select title from public.public_content_items where id = '50000000-0000-4000-8000-000000000004'), 'Bob published', 'Denied cross-owner mutations preserved Bob published row');
select is((select count(*) from public.public_content_items where id in ('50000000-0000-4000-8000-000000000003', '50000000-0000-4000-8000-000000000006')), 0::bigint, 'Authorized deletes removed owner targets');
select is((select count(*) from public.public_content_items), 6::bigint, 'Final state contains only authorized survivors');
select is((select count(*) from public.public_content_items where published), 4::bigint, 'Final state has four published rows');
select is((select count(*) from public.public_content_items where not published), 2::bigint, 'Final state has two private drafts');
select is((select count(*) from pg_class c join pg_namespace n on n.oid = c.relnamespace where n.nspname = 'public' and c.relname = 'public_content_items' and c.relrowsecurity), 1::bigint, 'Catalog confirms RLS on the content table');
select is((select count(*) from pg_policies where schemaname = 'public' and tablename = 'public_content_items'), 5::bigint, 'Catalog confirms public-read and owner policy composition');
select is((select count(*) from pg_policies where schemaname = 'public' and tablename = 'public_content_items' and cmd = 'UPDATE' and with_check is not null), 1::bigint, 'Catalog confirms owner UPDATE WITH CHECK');

select * from finish();
rollback;
