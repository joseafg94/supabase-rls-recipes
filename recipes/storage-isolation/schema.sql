create table public.storage_recipe_memberships (
  organization_id uuid not null,
  user_id uuid not null references auth.users (id) on delete cascade,
  primary key (organization_id, user_id)
);

create index storage_recipe_memberships_user_scope_idx
  on public.storage_recipe_memberships (user_id, organization_id);

alter table public.storage_recipe_memberships enable row level security;

revoke all on table public.storage_recipe_memberships from anon, authenticated;
grant select on table public.storage_recipe_memberships to authenticated;
