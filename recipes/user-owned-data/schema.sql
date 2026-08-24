create table public.user_owned_notes (
  id uuid primary key,
  owner_id uuid not null references auth.users (id) on delete cascade,
  body text not null,
  created_at timestamptz not null default now()
);

create index user_owned_notes_owner_id_idx
  on public.user_owned_notes (owner_id);

alter table public.user_owned_notes enable row level security;

revoke all on table public.user_owned_notes from anon, authenticated;
grant select, insert, update, delete
  on table public.user_owned_notes
  to authenticated;
