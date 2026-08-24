# Admin access boundary

## Goal

Show the difference between ordinary RLS authorization and a trusted backend credential that bypasses RLS.

## Threat model

Browser and mobile callers are untrusted even when authenticated. A backend holding a secret key is trusted to authenticate the end user, authorize the requested administrative action, constrain inputs, and audit the result before accessing data. Possession of that key is not an RLS decision.

## Authorization rules

- Alice and Bob use user JWTs and can read or update only rows they own.
- `WITH CHECK` prevents an owner from reassigning a row.
- Anonymous callers have no table grant.
- The local secret key demonstrates backend-only access across owner boundaries because its database role bypasses RLS.

## RLS is not admin authorization

A secret or legacy `service_role` key bypasses RLS. The backend therefore needs its own authorization rule for every privileged operation; accepting an arbitrary user ID or tenant ID and forwarding a privileged query would be an authorization flaw. This recipe deliberately provides no general admin endpoint or RBAC framework.

## Files

- `schema.sql` defines the protected records, grants, owner index, and RLS.
- `policies.sql` defines owner read and update rules.
- `seed.sql` inserts fictional actors and records.
- `tests.sql` proves ordinary isolation, reassignment denial, and the local bypass property.
- `api-tests.mjs` contrasts user JWT responses with one narrowly scoped backend-only request.

## Run from a clean local stack

```sh
npm ci
npm run db:start
npm run db:reset
npx supabase test db recipes/admin-access/tests.sql --local
npm run db:reset
node recipes/admin-access/api-tests.mjs
npm run db:stop
```

The API test reads local credentials from `supabase status -o json` in memory and never prints them. Alice and Bob requests use user JWTs. The secret is used only for the named bypass assertion.

[`tests.sql`](tests.sql) contains 14 catalog, ordinary-user isolation, reassignment-denial, and bypass assertions. [`api-tests.mjs`](api-tests.mjs) adds 8 API assertions contrasting user JWT behavior with the single backend-only bypass case.

## Credential custody

Keep secret keys in a server-side secret manager or protected environment, never source control, client bundles, logs, URLs, screenshots, or browser storage. Use separate, least-privilege backend services where possible, restrict network access, rotate exposed credentials, and audit every privileged action. Production code must not substitute a client-supplied identity for a verified caller.

## Assumptions and limitations

- This is a boundary demonstration, not an admin application.
- The backend authorization and audit layer is described but intentionally not implemented.
- Direct database owner/superuser contexts can also bypass RLS and require equivalent operational controls.
- Grants and RLS are separate: a caller needs the table privilege before an RLS policy can permit rows.

## Official references

- [API keys and bypass behavior](https://supabase.com/docs/guides/getting-started/api-keys)
- [Securing the Data API](https://supabase.com/docs/guides/api/securing-your-api)
- [PostgreSQL row security](https://www.postgresql.org/docs/current/ddl-rowsecurity.html)
