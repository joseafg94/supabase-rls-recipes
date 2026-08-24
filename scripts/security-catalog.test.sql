begin;

select plan(10);

select is(
  (
    select count(*)
    from pg_class as relation
    join pg_namespace as namespace on namespace.oid = relation.relnamespace
    where namespace.nspname = 'public'
      and relation.relname = any (array[
        'user_owned_notes',
        'membership_organizations', 'membership_organization_members', 'membership_resources',
        'role_organizations', 'role_members', 'role_resources',
        'public_content_items',
        'saas_organizations', 'saas_organization_members', 'saas_projects', 'saas_items',
        'storage_recipe_memberships',
        'admin_boundary_records'
      ])
      and relation.relrowsecurity
  ),
  14::bigint,
  'Every recipe table in public has RLS enabled'
);

select is(
  (select count(*) from pg_policies where schemaname = 'public'),
  36::bigint,
  'The composed public policy catalog is exact'
);

select is(
  (select count(*) from pg_policies where schemaname = 'storage' and tablename = 'objects' and policyname like 'users can % scoped storage objects'),
  4::bigint,
  'The composed Storage policy catalog is exact'
);

select is(
  (select count(*) from pg_policies where schemaname in ('public', 'storage') and cmd = 'UPDATE' and with_check is null),
  0::bigint,
  'Every UPDATE policy has a proposed-row check'
);

select is(
  (select count(*) from pg_policies where schemaname in ('public', 'storage') and roles @> array['public'::name]),
  0::bigint,
  'No recipe policy targets the implicit PUBLIC role'
);

select is(
  (
    select count(*)
    from information_schema.role_table_grants
    where table_schema = 'public'
      and table_name in ('membership_organization_members', 'role_members', 'saas_organization_members', 'storage_recipe_memberships')
      and grantee in ('anon', 'authenticated')
      and privilege_type <> 'SELECT'
  ),
  0::bigint,
  'Authorization relationship tables have no app-user mutation grants'
);

select is(
  (
    select count(*)
    from information_schema.role_table_grants
    where table_schema = 'public'
      and table_name = 'public_content_items'
      and grantee = 'anon'
      and privilege_type = 'SELECT'
  ),
  1::bigint,
  'Anonymous receives only the intended public-content SELECT grant'
);

select is(
  (
    select count(*)
    from pg_constraint as constraint_record
    where constraint_record.contype = 'f'
      and constraint_record.conrelid = any (array[
        'public.user_owned_notes'::regclass,
        'public.membership_organization_members'::regclass,
        'public.membership_resources'::regclass,
        'public.role_members'::regclass,
        'public.role_resources'::regclass,
        'public.public_content_items'::regclass,
        'public.saas_organization_members'::regclass,
        'public.saas_projects'::regclass,
        'public.saas_items'::regclass,
        'public.storage_recipe_memberships'::regclass,
        'public.admin_boundary_records'::regclass
      ])
      and not exists (
        select 1
        from pg_index as index_record
        where index_record.indrelid = constraint_record.conrelid
          and index_record.indisvalid
          and constraint_record.conkey <@ (index_record.indkey::smallint[])
      )
  ),
  0::bigint,
  'Every recipe foreign key is backed by a valid index'
);

select is(
  (select count(*) from pg_class as relation join pg_namespace as namespace on namespace.oid = relation.relnamespace where namespace.nspname = 'public' and relation.relkind in ('v', 'm')),
  0::bigint,
  'Recipes expose no views or materialized views'
);

select is(
  (select count(*) from pg_proc as procedure join pg_namespace as namespace on namespace.oid = procedure.pronamespace where namespace.nspname = 'public'),
  0::bigint,
  'Recipes expose no public functions'
);

select * from finish();
rollback;
