create policy "owners can select their notes"
on public.user_owned_notes
for select
to authenticated
using ((select auth.uid()) = owner_id);

create policy "owners can insert their notes"
on public.user_owned_notes
for insert
to authenticated
with check ((select auth.uid()) = owner_id);

create policy "owners can update their notes"
on public.user_owned_notes
for update
to authenticated
using ((select auth.uid()) = owner_id)
with check ((select auth.uid()) = owner_id);

create policy "owners can delete their notes"
on public.user_owned_notes
for delete
to authenticated
using ((select auth.uid()) = owner_id);
