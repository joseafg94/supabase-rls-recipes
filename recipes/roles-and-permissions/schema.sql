create table public.role_organizations (
  id uuid primary key,
  name text not null unique
);

create table public.role_members (
  organization_id uuid not null
    references public.role_organizations (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  role text not null check (role in ('owner', 'admin', 'member')),
  joined_at timestamptz not null,
  primary key (organization_id, user_id)
);

create index role_members_user_id_organization_id_idx
  on public.role_members (user_id, organization_id, role);

create table public.role_resources (
  id uuid primary key,
  organization_id uuid not null
    references public.role_organizations (id) on delete cascade,
  name text not null
);

create index role_resources_organization_id_idx
  on public.role_resources (organization_id);

alter table public.role_organizations enable row level security;
alter table public.role_members enable row level security;
alter table public.role_resources enable row level security;

revoke all on table public.role_organizations from anon, authenticated;
revoke all on table public.role_members from anon, authenticated;
revoke all on table public.role_resources from anon, authenticated;

grant select, update, delete on table public.role_organizations to authenticated;
grant select on table public.role_members to authenticated;
grant select, insert, update, delete on table public.role_resources to authenticated;
