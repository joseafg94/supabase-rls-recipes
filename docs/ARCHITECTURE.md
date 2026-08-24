# Architecture

## Repository layers

1. **Shared doctrine:** threat model, authorization model, RLS principles, testing strategy, and operational guidance.
2. **Recipe fixtures:** independent schema, policy, seed, and test units following one contract.
3. **Verification:** local reconstruction, authorization matrices, static/security checks, and future CI.
4. **Delivery controls:** contribution, review, drift, and release checklists.

## Recipe isolation

Each recipe owns its objects and deterministic fixture data. A recipe must not depend on another recipe's schema or execution order. The test harness applies one recipe fixture to clean local state; recipe SQL remains outside global migrations.

## Database boundaries

- Exposed schemas are an intentional API surface. Object grants decide reachability; RLS decides row access.
- Internal authorization helpers belong in a non-exposed schema.
- Auth identities are represented with fictional stable UUIDs and request context compatible with local testing.
- Storage metadata policies are tested separately; object mutations use the Storage API in implementation tests where metadata-only SQL would be misleading.
- Privileged backend flows are isolated from browser/app-user flows and never used to validate ordinary RLS.

## Policy shape

Prefer operation-specific policies (`SELECT`, `INSERT`, `UPDATE`, `DELETE`) with explicit `TO` roles. `USING` limits existing target rows; `WITH CHECK` validates proposed row values. Authorization predicates should resolve through trusted ownership or membership rows and have supporting indexes.

## Dependencies

The local stack is Supabase CLI 2.115.0, installed as an exact npm development dependency, plus its Docker-managed PostgreSQL services. Database tests use the CLI's native pgTAP runner and explicit actor context. No application framework or hosted Supabase project is required.

## Source of truth

Committed migrations, recipe SQL, tests, and docs are authoritative. Dashboard state is observable runtime state and may reveal drift, but it is never the sole definition of expected authorization.
