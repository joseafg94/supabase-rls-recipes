create table public.membership_organizations (
  id uuid primary key,
  name text not null unique
);

create table public.membership_organization_members (
  organization_id uuid not null
    references public.membership_organizations (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  joined_at timestamptz not null,
  primary key (organization_id, user_id)
);

create index membership_organization_members_user_id_idx
  on public.membership_organization_members (user_id, organization_id);

create table public.membership_resources (
  id uuid primary key,
  organization_id uuid not null
    references public.membership_organizations (id) on delete cascade,
  name text not null
);

create index membership_resources_organization_id_idx
  on public.membership_resources (organization_id);

alter table public.membership_organizations enable row level security;
alter table public.membership_organization_members enable row level security;
alter table public.membership_resources enable row level security;

revoke all on table public.membership_organizations from anon, authenticated;
revoke all on table public.membership_organization_members from anon, authenticated;
revoke all on table public.membership_resources from anon, authenticated;

grant select on table public.membership_organizations to authenticated;
grant select on table public.membership_organization_members to authenticated;
grant select, insert, update, delete
  on table public.membership_resources
  to authenticated;
