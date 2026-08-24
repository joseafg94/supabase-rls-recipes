create policy "users can select their storage membership"
on public.storage_recipe_memberships
for select
to authenticated
using (user_id = (select auth.uid()));

create policy "users can select scoped storage objects"
on storage.objects
for select
to authenticated
using (
  bucket_id = 'storage-recipe-private'
  and owner_id = (select auth.uid()::text)
  and (storage.foldername(name))[2] = (select auth.uid()::text)
  and exists (
    select 1 from public.storage_recipe_memberships as membership
    where membership.user_id = (select auth.uid())
      and membership.organization_id::text = (storage.foldername(name))[1]
  )
);

create policy "users can insert scoped storage objects"
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'storage-recipe-private'
  and (storage.foldername(name))[2] = (select auth.uid()::text)
  and exists (
    select 1 from public.storage_recipe_memberships as membership
    where membership.user_id = (select auth.uid())
      and membership.organization_id::text = (storage.foldername(name))[1]
  )
);

create policy "users can update scoped storage objects"
on storage.objects
for update
to authenticated
using (
  bucket_id = 'storage-recipe-private'
  and owner_id = (select auth.uid()::text)
  and (storage.foldername(name))[2] = (select auth.uid()::text)
  and exists (
    select 1 from public.storage_recipe_memberships as membership
    where membership.user_id = (select auth.uid())
      and membership.organization_id::text = (storage.foldername(name))[1]
  )
)
with check (
  bucket_id = 'storage-recipe-private'
  and owner_id = (select auth.uid()::text)
  and (storage.foldername(name))[2] = (select auth.uid()::text)
  and exists (
    select 1 from public.storage_recipe_memberships as membership
    where membership.user_id = (select auth.uid())
      and membership.organization_id::text = (storage.foldername(name))[1]
  )
);

create policy "users can delete scoped storage objects"
on storage.objects
for delete
to authenticated
using (
  bucket_id = 'storage-recipe-private'
  and owner_id = (select auth.uid()::text)
  and (storage.foldername(name))[2] = (select auth.uid()::text)
  and exists (
    select 1 from public.storage_recipe_memberships as membership
    where membership.user_id = (select auth.uid())
      and membership.organization_id::text = (storage.foldername(name))[1]
  )
);
