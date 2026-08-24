create policy "owners can read their records"
on public.admin_boundary_records
for select
to authenticated
using ((select auth.uid()) = owner_id);

create policy "owners can update their records"
on public.admin_boundary_records
for update
to authenticated
using ((select auth.uid()) = owner_id)
with check ((select auth.uid()) = owner_id);

