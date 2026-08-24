create table public.saas_organizations (
  id uuid primary key,
  name text not null unique
);

create table public.saas_organization_members (
  organization_id uuid not null
    references public.saas_organizations (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  role text not null check (role in ('owner', 'admin', 'member')),
  joined_at timestamptz not null,
  primary key (organization_id, user_id)
);

create index saas_organization_members_user_scope_idx
  on public.saas_organization_members (user_id, organization_id, role);

create table public.saas_projects (
  id uuid primary key,
  organization_id uuid not null
    references public.saas_organizations (id) on delete cascade,
  name text not null,
  unique (id, organization_id)
);

create index saas_projects_organization_id_idx
  on public.saas_projects (organization_id);

create table public.saas_items (
  id uuid primary key,
  organization_id uuid not null,
  project_id uuid not null,
  name text not null,
  constraint saas_items_project_tenant_fkey
    foreign key (project_id, organization_id)
    references public.saas_projects (id, organization_id)
    on delete cascade
);

create index saas_items_organization_id_idx
  on public.saas_items (organization_id);
create index saas_items_project_scope_idx
  on public.saas_items (project_id, organization_id);

alter table public.saas_organizations enable row level security;
alter table public.saas_organization_members enable row level security;
alter table public.saas_projects enable row level security;
alter table public.saas_items enable row level security;

revoke all on table public.saas_organizations from anon, authenticated;
revoke all on table public.saas_organization_members from anon, authenticated;
revoke all on table public.saas_projects from anon, authenticated;
revoke all on table public.saas_items from anon, authenticated;

grant select on table public.saas_organizations to authenticated;
grant select on table public.saas_organization_members to authenticated;
grant select, insert, update, delete on table public.saas_projects to authenticated;
grant select, insert, update, delete on table public.saas_items to authenticated;
