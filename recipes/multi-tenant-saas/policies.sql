create policy "members can select their organizations"
on public.saas_organizations
for select
to authenticated
using (
  exists (
    select 1 from public.saas_organization_members as membership
    where membership.organization_id = id
      and membership.user_id = (select auth.uid())
  )
);

create policy "members can select their own memberships"
on public.saas_organization_members
for select
to authenticated
using (user_id = (select auth.uid()));

create policy "members can select tenant projects"
on public.saas_projects
for select
to authenticated
using (
  exists (
    select 1 from public.saas_organization_members as membership
    where membership.organization_id = saas_projects.organization_id
      and membership.user_id = (select auth.uid())
  )
);

create policy "owners and admins can insert tenant projects"
on public.saas_projects
for insert
to authenticated
with check (
  exists (
    select 1 from public.saas_organization_members as membership
    where membership.organization_id = saas_projects.organization_id
      and membership.user_id = (select auth.uid())
      and membership.role in ('owner', 'admin')
  )
);

create policy "owners and admins can update tenant projects"
on public.saas_projects
for update
to authenticated
using (
  exists (
    select 1 from public.saas_organization_members as membership
    where membership.organization_id = saas_projects.organization_id
      and membership.user_id = (select auth.uid())
      and membership.role in ('owner', 'admin')
  )
)
with check (
  exists (
    select 1 from public.saas_organization_members as membership
    where membership.organization_id = saas_projects.organization_id
      and membership.user_id = (select auth.uid())
      and membership.role in ('owner', 'admin')
  )
);

create policy "owners can delete tenant projects"
on public.saas_projects
for delete
to authenticated
using (
  exists (
    select 1 from public.saas_organization_members as membership
    where membership.organization_id = saas_projects.organization_id
      and membership.user_id = (select auth.uid())
      and membership.role = 'owner'
  )
);

create policy "members can select tenant items"
on public.saas_items
for select
to authenticated
using (
  exists (
    select 1 from public.saas_organization_members as membership
    where membership.organization_id = saas_items.organization_id
      and membership.user_id = (select auth.uid())
  )
);

create policy "owners and admins can insert tenant items"
on public.saas_items
for insert
to authenticated
with check (
  exists (
    select 1 from public.saas_organization_members as membership
    where membership.organization_id = saas_items.organization_id
      and membership.user_id = (select auth.uid())
      and membership.role in ('owner', 'admin')
  )
);

create policy "owners and admins can update tenant items"
on public.saas_items
for update
to authenticated
using (
  exists (
    select 1 from public.saas_organization_members as membership
    where membership.organization_id = saas_items.organization_id
      and membership.user_id = (select auth.uid())
      and membership.role in ('owner', 'admin')
  )
)
with check (
  exists (
    select 1 from public.saas_organization_members as membership
    where membership.organization_id = saas_items.organization_id
      and membership.user_id = (select auth.uid())
      and membership.role in ('owner', 'admin')
  )
);

create policy "owners can delete tenant items"
on public.saas_items
for delete
to authenticated
using (
  exists (
    select 1 from public.saas_organization_members as membership
    where membership.organization_id = saas_items.organization_id
      and membership.user_id = (select auth.uid())
      and membership.role = 'owner'
  )
);
