create table public.admin_boundary_records (
  id uuid primary key,
  owner_id uuid not null references auth.users (id),
  body text not null
);

create index admin_boundary_records_owner_id_idx
  on public.admin_boundary_records (owner_id);

alter table public.admin_boundary_records enable row level security;

revoke all on table public.admin_boundary_records from anon, authenticated;
grant select, update on table public.admin_boundary_records to authenticated;
grant select, update on table public.admin_boundary_records to service_role;

