create policy "members can select their organizations"
on public.membership_organizations
for select
to authenticated
using (
  exists (
    select 1
    from public.membership_organization_members as membership
    where membership.organization_id = id
      and membership.user_id = (select auth.uid())
  )
);

create policy "members can select their own memberships"
on public.membership_organization_members
for select
to authenticated
using (user_id = (select auth.uid()));

create policy "members can select organization resources"
on public.membership_resources
for select
to authenticated
using (
  exists (
    select 1
    from public.membership_organization_members as membership
    where membership.organization_id = membership_resources.organization_id
      and membership.user_id = (select auth.uid())
  )
);

create policy "members can insert organization resources"
on public.membership_resources
for insert
to authenticated
with check (
  exists (
    select 1
    from public.membership_organization_members as membership
    where membership.organization_id = membership_resources.organization_id
      and membership.user_id = (select auth.uid())
  )
);

create policy "members can update organization resources"
on public.membership_resources
for update
to authenticated
using (
  exists (
    select 1
    from public.membership_organization_members as membership
    where membership.organization_id = membership_resources.organization_id
      and membership.user_id = (select auth.uid())
  )
)
with check (
  exists (
    select 1
    from public.membership_organization_members as membership
    where membership.organization_id = membership_resources.organization_id
      and membership.user_id = (select auth.uid())
  )
);

create policy "members can delete organization resources"
on public.membership_resources
for delete
to authenticated
using (
  exists (
    select 1
    from public.membership_organization_members as membership
    where membership.organization_id = membership_resources.organization_id
      and membership.user_id = (select auth.uid())
  )
);
