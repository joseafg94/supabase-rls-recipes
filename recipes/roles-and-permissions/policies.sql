create policy "members can select their organizations"
on public.role_organizations
for select
to authenticated
using (
  exists (
    select 1 from public.role_members as membership
    where membership.organization_id = id
      and membership.user_id = (select auth.uid())
  )
);

create policy "owners can update their organizations"
on public.role_organizations
for update
to authenticated
using (
  exists (
    select 1 from public.role_members as membership
    where membership.organization_id = id
      and membership.user_id = (select auth.uid())
      and membership.role = 'owner'
  )
)
with check (
  exists (
    select 1 from public.role_members as membership
    where membership.organization_id = id
      and membership.user_id = (select auth.uid())
      and membership.role = 'owner'
  )
);

create policy "owners can delete their organizations"
on public.role_organizations
for delete
to authenticated
using (
  exists (
    select 1 from public.role_members as membership
    where membership.organization_id = id
      and membership.user_id = (select auth.uid())
      and membership.role = 'owner'
  )
);

create policy "members can select their own roles"
on public.role_members
for select
to authenticated
using (user_id = (select auth.uid()));

create policy "members can select organization resources"
on public.role_resources
for select
to authenticated
using (
  exists (
    select 1 from public.role_members as membership
    where membership.organization_id = role_resources.organization_id
      and membership.user_id = (select auth.uid())
  )
);

create policy "owners and admins can insert organization resources"
on public.role_resources
for insert
to authenticated
with check (
  exists (
    select 1 from public.role_members as membership
    where membership.organization_id = role_resources.organization_id
      and membership.user_id = (select auth.uid())
      and membership.role in ('owner', 'admin')
  )
);

create policy "owners and admins can update organization resources"
on public.role_resources
for update
to authenticated
using (
  exists (
    select 1 from public.role_members as membership
    where membership.organization_id = role_resources.organization_id
      and membership.user_id = (select auth.uid())
      and membership.role in ('owner', 'admin')
  )
)
with check (
  exists (
    select 1 from public.role_members as membership
    where membership.organization_id = role_resources.organization_id
      and membership.user_id = (select auth.uid())
      and membership.role in ('owner', 'admin')
  )
);

create policy "owners can delete organization resources"
on public.role_resources
for delete
to authenticated
using (
  exists (
    select 1 from public.role_members as membership
    where membership.organization_id = role_resources.organization_id
      and membership.user_id = (select auth.uid())
      and membership.role = 'owner'
  )
);
