# Multi-Tenant SaaS

## Problem

This flagship recipe isolates organizations across memberships, projects, and nested items while applying explicit owner/admin/member permissions to every read and write path.

## Threat model

- **Assets:** tenant membership/role facts, project data, nested item data, and tenant ownership of relationships.
- **Actors:** Alice, owner of Org A; Bob, owner of Org B; Carol, admin in Org A and member in Org B; and an unauthenticated caller.
- **Attacker goals:** cross-tenant reads/writes, forged tenant IDs, row reassignment, mismatched project/item paths, self-enrollment, and role escalation.
- **Controls:** database-controlled memberships, command-specific RLS, `WITH CHECK`, composite foreign keys, least-privilege grants, and bidirectional tests.
- **Out of scope:** invitations, billing, Storage, global administrators, `service_role`, frontend behavior, and production deployment.

## Assumptions

- Supabase Auth supplies a validated subject through `auth.uid()`.
- Membership and role rows are provisioned by a separate trusted workflow; application users cannot mutate them.
- Owner may select/insert/update/delete tenant projects/items; admin may select/insert/update but not delete; member may select only.
- Table owners, superusers, `BYPASSRLS`, and privileged keys are not app-user test contexts.
- Supabase Auth anonymous sign-ins are disabled; the `anon` Postgres role represents an unauthenticated request.

## Schema

`saas_organizations` owns `saas_projects`; `saas_organization_members` binds an Auth user and role to an organization; `saas_items` belongs to both a project and its organization.

The composite foreign key `(project_id, organization_id)` on items references the same pair on projects. This prevents an item from claiming Org A while pointing at an Org B project, even when its top-level tenant ID passes an RLS predicate.

## Authorization rules

| Actor/role | Operation | Org A | Org B |
| --- | --- | --- | --- |
| Alice / owner A | SELECT/INSERT/UPDATE/DELETE projects/items | Allow | Deny |
| Bob / owner B | SELECT/INSERT/UPDATE/DELETE projects/items | Deny | Allow |
| Carol / admin A | SELECT/INSERT/UPDATE projects/items | Allow | Read only |
| Carol / admin A | DELETE projects/items | Deny | Deny |
| Carol / member B | SELECT projects/items | Allow | Allow |
| Any app user | Mutate memberships | Deny | Deny |
| Anonymous | Read/write private tenant rows | Deny | Deny |

Operation details:

- SELECT requires any membership in the row's organization.
- INSERT requires owner/admin membership for the proposed `organization_id`.
- UPDATE requires owner/admin membership for both the existing and resulting tenant scope.
- DELETE requires owner membership in the existing tenant scope.
- Item writes must additionally satisfy the project/organization composite foreign key.

## Policy explanation

Each project/item command has one applicable permissive policy. SELECT checks membership; INSERT and UPDATE check owner/admin role; DELETE checks owner role. UPDATE repeats the predicate in `USING` and `WITH CHECK`, so a visible row cannot be moved into a tenant where the actor lacks write authority.

Membership SELECT exposes only the caller's own rows and has no mutation grants. Resource policies can validate that protected relationship without creating policy recursion. Because there is no second broad policy for a command, the final effective condition is the documented membership/role predicate rather than an accidental permissive OR.

## Why a browser `tenant_id` is insufficient

A client controls request payloads and can replace Org A with Org B. Comparing a row only with that submitted value proves consistency with the attacker's claim, not authorization. These policies compare the proposed/existing tenant to a membership row tied to `(select auth.uid())`; the composite foreign key then proves nested project/item consistency. Tests submit forged tenant IDs in both directions and verify no protected state changes.

## Expected allow cases

- [x] Alice performs complete project/item CRUD in Org A.
- [x] Bob performs complete project/item CRUD in Org B.
- [x] Carol creates/updates in Org A as admin and reads Org B as member.
- [x] Owner project deletes cascade only to correctly related items.

## Expected deny cases

- [x] Alice→Org B and Bob→Org A SELECT/INSERT/UPDATE/DELETE paths fail.
- [x] Project and item tenant reassignment fails in both directions.
- [x] Carol cannot delete as admin or write as member.
- [x] Forged tenant IDs and mismatched project/item paths fail.
- [x] Direct membership self-enrollment/escalation and anonymous access fail.
- [x] Final-state assertions prove denied operations created or changed nothing.

## Run locally

```sh
npm ci
npm run db:start
npm run db:reset
npx supabase test db recipes/multi-tenant-saas/tests.sql --local
npm run db:stop
```

The recipe applies schema, policies, and deterministic seeds inside its pgTAP transaction and never connects to a linked project.

## Common mistakes

- Trusting `tenant_id` because it came from a selected tenant in the UI.
- Protecting projects but not memberships or nested items.
- Checking only the existing row on UPDATE and allowing tenant reassignment.
- Storing roles in user-editable metadata or assuming JWT role claims are immediately fresh.
- Omitting the composite relationship constraint and allowing cross-tenant project/item pairs.
- Adding a broad permissive policy that ORs around membership.

## Limitations

Membership lifecycle, invitations, last-owner invariants, per-resource ownership, custom permissions, public data, soft deletion, audit logging, Storage, and privileged administration are intentionally absent.

## Production considerations

The membership primary key supports organization-first lookup; `saas_organization_members_user_scope_idx` supports policy lookups by user/tenant/role. Project and item tenant columns are indexed, and the item composite index supports its foreign key and related queries. Validate these assumptions with representative `EXPLAIN (ANALYZE, BUFFERS)` plans and production cardinalities rather than relying on fixture scale.

Deploy grants, constraints, indexes, RLS enablement, and policies through reviewed migrations. Inspect all policies for each command as a combined authorization expression, run both tenant directions after every change, and reconcile production catalogs against Git without destructive resets.
