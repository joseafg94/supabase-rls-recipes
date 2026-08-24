create policy "anyone can select published content"
on public.public_content_items
for select
to anon, authenticated
using (published);

create policy "owners can select their content"
on public.public_content_items
for select
to authenticated
using ((select auth.uid()) = owner_id);

create policy "owners can insert their content"
on public.public_content_items
for insert
to authenticated
with check ((select auth.uid()) = owner_id);

create policy "owners can update their content"
on public.public_content_items
for update
to authenticated
using ((select auth.uid()) = owner_id)
with check ((select auth.uid()) = owner_id);

create policy "owners can delete their content"
on public.public_content_items
for delete
to authenticated
using ((select auth.uid()) = owner_id);
