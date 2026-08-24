# Authorization Model

## Decision sequence

For each operation, answer in order:

1. Which database role can reach the object through grants?
2. Which actor identity is present, and is it required?
3. Which trusted relationship connects the actor to the target row?
4. Which operation is allowed for that relationship and role?
5. For writes, are both the existing row and proposed new row authorized?
6. Which other applicable policies widen or restrict the final condition?
7. Does any view, function, Storage endpoint, or privileged client provide another access path?

## Actor dimensions

Do not collapse these into one “user” case:

- Postgres role: `anon`, `authenticated`, or privileged server role.
- Subject: the authenticated UUID, if any.
- Tenant relationship: outsider, member, admin, or owner.
- Resource relationship: creator, owner, assignee, publisher, or none.
- Operation: select, insert, update, delete, or privileged administration.

## Trusted facts

Authorization may derive from database-controlled owner columns, foreign keys, active membership rows, validated application metadata with an explicit freshness model, or server-side privileged logic. A request body's `tenant_id`, object path segment, or user-editable `user_metadata` is never sufficient by itself.

## Baseline operation contract

| Command | Existing-row predicate | Proposed-row predicate | Typical failure |
| --- | --- | --- | --- |
| SELECT | `USING` | — | Empty result |
| INSERT | — | `WITH CHECK` | RLS violation |
| UPDATE | `USING` plus SELECT visibility | `WITH CHECK` | Zero rows or RLS violation |
| DELETE | `USING` plus required visibility | — | Zero rows |

Tests must assert both the observable result and the database state after the operation.

## Role semantics

Owner, admin, and member are names only until their operations are enumerated. Each recipe defines a matrix. A default starting model is:

- Owner: manage organization settings and memberships, plus resource operations.
- Admin: operational resource management; no owner transfer or organization deletion.
- Member: normal resource reads/writes explicitly assigned to members.

Recipes may differ, but differences must be stated and tested.

## Privileged access

`service_role` and secret keys are trusted-backend credentials that bypass RLS. Their use belongs behind a server-side API with its own authorization, auditability, and least privilege. They are never a workaround for incomplete app-user policies and never appear in frontend code or fixtures.
