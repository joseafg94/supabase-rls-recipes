create table public.public_content_items (
  id uuid primary key,
  owner_id uuid not null references auth.users (id) on delete cascade,
  title text not null,
  published boolean not null default false,
  created_at timestamptz not null default now()
);

create index public_content_items_owner_id_idx
  on public.public_content_items (owner_id);
create index public_content_items_published_idx
  on public.public_content_items (published)
  where published;

alter table public.public_content_items enable row level security;

revoke all on table public.public_content_items from anon, authenticated;
grant select on table public.public_content_items to anon;
grant select, insert, update, delete
  on table public.public_content_items
  to authenticated;
