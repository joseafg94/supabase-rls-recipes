# User-Owned Data

## Problem

This recipe protects private notes so an authenticated user can select, insert, update, and delete only rows whose `owner_id` equals their Supabase Auth subject.

## Threat model

- **Assets:** private note contents and the integrity of note ownership.
- **Actors:** Alice, Bob, an unauthenticated `anon` caller, and a malicious authenticated owner attempting cross-user access.
- **Attacker goals:** read or mutate another user's note, forge `owner_id` during insert, or reassign an existing note.
- **Controls:** explicit table grants, RLS enabled on the table, one policy per command, and ownership checks derived from `auth.uid()`.
- **Out of scope:** organizations, shared notes, delegated access, privileged backends, Storage, and authorization from JWT metadata.

## Assumptions

- Requests reach PostgreSQL as Supabase's `anon` or `authenticated` role with validated JWT context.
- Alice and Bob UUIDs are fictional fixtures; production users are created through Supabase Auth rather than direct SQL.
- Supabase Auth anonymous sign-ins are disabled. Such users use the `authenticated` Postgres role and require an additional product rule if they must be distinguished from permanent users.
- Table owners, superusers, `BYPASSRLS`, and `service_role` are privileged and are not app-user test contexts.

## Schema

`public.user_owned_notes` has a UUID primary key, a required `owner_id` foreign key to `auth.users`, note text, and a creation timestamp. `owner_id` is the trusted relationship and is indexed because every policy filters on it.

The `authenticated` role receives only CRUD privileges required by this recipe. `anon` receives no table privilege, so its requests fail before policy evaluation.

## Authorization rules

| Actor | Command | Target | Expected | Reason |
| --- | --- | --- | --- | --- |
| Alice | SELECT | Alice note | Allow | `auth.uid() = owner_id` |
| Alice | SELECT/UPDATE/DELETE | Bob note | Empty or zero affected rows | Target row fails `USING` |
| Alice | INSERT | Alice `owner_id` | Allow | Proposed row passes `WITH CHECK` |
| Alice | INSERT | Bob `owner_id` | RLS rejection | Proposed row fails `WITH CHECK` |
| Alice | UPDATE | Reassign Alice note to Bob | RLS rejection | Existing row passes `USING`; proposed row fails `WITH CHECK` |
| Bob | CRUD | Bob notes | Allow | Bob's subject equals `owner_id` |
| Bob | SELECT/UPDATE/DELETE | Alice note | Empty or zero affected rows | Target row fails `USING` |
| Anonymous | Any CRUD command | Any note | Permission denied | `anon` has no table grants |

## Policy explanation

The SELECT and DELETE policies use `USING` because they authorize an existing target row. INSERT uses `WITH CHECK` because it authorizes the row proposed by the client. UPDATE needs both: `USING` determines which existing notes can be targeted, while `WITH CHECK` prevents an owner from changing the resulting `owner_id` to another user.

Using only `USING` is insufficient as an authorization design because it does not state the required invariant for proposed UPDATE values. This recipe repeats the ownership predicate in `WITH CHECK` so ownership is explicit and auditable even though PostgreSQL can reuse `USING` when `WITH CHECK` is omitted.

There is one permissive policy per command for `authenticated`; therefore each command's effective RLS condition is exactly its ownership predicate. Grants remain a separate prerequisite and deny `anon` before RLS.

## Expected allow cases

- [x] Alice selects, inserts, updates, and deletes her rows.
- [x] Bob selects, inserts, updates, and deletes his rows.
- [x] Allowed changes have exact row-count and final-state assertions.

## Expected deny cases

- [x] Alice cannot see, update, or delete Bob rows.
- [x] Bob cannot see, update, or delete Alice rows.
- [x] Alice cannot insert a row owned by Bob.
- [x] Alice cannot reassign her row to Bob.
- [x] Anonymous CRUD receives `42501` permission errors.
- [x] Final-state assertions prove denied operations made no changes.

## Run locally

From the repository root:

```sh
npm ci
npm run db:start
npm run db:reset
npx supabase test db recipes/user-owned-data/tests.sql --local
npm run db:stop
```

The test file loads `schema.sql`, `policies.sql`, and `seed.sql` inside one transaction; pgTAP rolls the fixture back after execution. It never uses a linked project.

## Common mistakes

- Granting CRUD to `authenticated` without ownership policies authorizes every signed-in user at the table level.
- Trusting a client-supplied `owner_id` without `WITH CHECK` enables forged ownership.
- Omitting SELECT policy visibility makes UPDATE appear to affect zero rows.
- Testing as `postgres` bypasses the app-user boundary and produces false confidence.
- Treating the `anon` Postgres role as equivalent to an anonymous Supabase Auth user ignores their different role semantics.

## Limitations

- Notes have exactly one immutable owner and cannot be shared.
- The recipe does not distinguish administrators, teams, suspended users, or anonymous Auth users.
- RLS does not protect privileged credentials, backend code that bypasses RLS, or data exported to other systems.

## Production considerations

Apply schema and policies through reviewed migrations and verify grants because Data API exposure defaults vary by project history. Create users through Auth APIs, retain the `owner_id` index, run authorization regressions after policy changes, and compare production catalogs with Git to detect drift. Review current [Supabase RLS documentation](https://supabase.com/docs/guides/database/postgres/row-level-security) before adoption.
