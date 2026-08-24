# RLS Principles

1. **Start from no policy.** With RLS enabled, grant only documented operations and add policies for intended rows.
2. **Separate reachability from row filtering.** Postgres grants permit access to an object; RLS then constrains rows. Both require review.
3. **Authenticate and authorize.** `TO authenticated` selects a database role but does not establish row ownership or tenant membership.
4. **Use the correct predicate.** `USING` governs existing rows for reads and target rows for updates/deletes. `WITH CHECK` governs inserted or updated row values.
5. **Treat update as read plus write.** PostgreSQL must be able to see the row before updating it; tests must catch zero-row updates.
6. **Assume untrusted inputs.** A tenant UUID, owner UUID, Storage path, or role name supplied by a client is a claim to verify, not authority.
7. **Secure relationships.** Membership and permission tables can be the keys to every tenant row and need at least equal rigor.
8. **Reason about composition.** Applicable permissive policies combine with `OR`; restrictive policies combine with `AND` against the permissive result. Audit the effective expression per command and role.
9. **Keep claims trustworthy and fresh.** Never authorize from user-editable metadata. App metadata can be stale until token refresh and is unsuitable for rapidly changing permissions without compensating controls.
10. **Minimize bypasses.** Table owners, `BYPASSRLS`, `service_role`, secret keys, and many `SECURITY DEFINER` paths sit outside normal app-user RLS.
11. **Index authorization lookups.** Ownership, tenant, foreign-key, and membership predicate columns need indexes; performance failures can become availability failures.
12. **Prove the boundary.** For every allow claim, test the closest forbidden actor, row, payload, and path.

## Tiny composition example

```sql
-- Conceptual only: both are permissive SELECT policies.
using (is_member_of(row_tenant_id))
using (published = true)
-- Effective permissive condition: membership OR published.
```

The second branch intentionally exposes published rows across tenants only if that public surface is part of the model. Otherwise it silently defeats the expected tenant-only rule. Review all policies for the table, command, and role together.

## Current references

- [Supabase Row Level Security](https://supabase.com/docs/guides/database/postgres/row-level-security)
- [Supabase Data API security](https://supabase.com/docs/guides/api/securing-your-api)
- [PostgreSQL row security policies](https://www.postgresql.org/docs/current/ddl-rowsecurity.html)
