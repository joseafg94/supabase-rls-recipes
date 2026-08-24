# Roles and Permissions

## Problem

This recipe composes organization membership with explicit `owner`, `admin`, and `member` operation rules instead of treating role names as vague authority.

## Threat model

- **Assets:** organizations, resources, and role assignments.
- **Actors:** Alice as owner, Bob as admin, Carol as member, Dave as another-organization owner, and `anon`.
- **Attacker goals:** self-enroll, escalate a role, cross organizations, or perform a destructive operation beyond the assigned role.
- **Controls:** immutable client-facing memberships, role-specific RLS predicates, grants, constraints, and negative tests.
- **Out of scope:** membership invitation/administration, billing, global roles, Storage, and privileged APIs.

## Assumptions

A separate trusted workflow provisions roles. App users can read only their own membership rows and cannot mutate the relationship table. Role changes require fresh database state because policies query rows rather than JWT metadata.

## Schema

`role_organizations`, `role_members`, and `role_resources` model the boundary. The role column is constrained to `owner`, `admin`, or `member`; membership and resource lookup columns are indexed. Every exposed table has RLS.

## Authorization rules

| Actor | Operation | Expected |
| --- | --- | --- |
| Any member | Select own organization and its resources | Allow |
| Owner | Update/delete own organization; CRUD own resources | Allow |
| Admin | Insert/update own resources | Allow |
| Admin | Delete resources or mutate organizations | Deny |
| Member | Read resources | Allow |
| Member | Insert/update/delete resources | Deny |
| Any app user | Insert/update/delete memberships | Permission denied |
| Any role | Cross-organization operation | Deny |
| Anonymous | Private tables | Permission denied |

## Policy explanation

Organization and resource predicates query the caller's protected membership row. Owner policies cover organization update/delete and resource delete; owner/admin policies cover resource insert/update; all members share resource SELECT. UPDATE uses matching `USING` and `WITH CHECK`, preventing tenant reassignment. Membership SELECT is limited to the caller and has no mutation grants or policies, so self-enrollment and self-escalation fail before they can alter authorization facts.

Applicable policies are separated by command. Owner/admin membership checks coexist inside a single policy for insert/update, so there is no broader permissive policy that accidentally grants members write access.

## Expected allow cases

- [x] Owners manage organizations and resources in their scope.
- [x] Admins create and update, but do not delete, resources.
- [x] Members read resources.

## Expected deny cases

- [x] Admin/member destructive differences are enforced.
- [x] Self-enrollment and role escalation are rejected.
- [x] Cross-organization and anonymous operations are denied.
- [x] Final-state assertions confirm denied writes changed nothing.

## Run locally

```sh
npm ci
npm run db:start
npm run db:reset
npx supabase test db recipes/roles-and-permissions/tests.sql --local
npm run db:stop
```

## Common mistakes

- Using `TO authenticated` as the entire role check.
- Storing mutable authorization roles in user metadata.
- Adding a second broad permissive policy that ORs around the role predicate.
- Allowing users to update the row that grants their own role.

## Limitations

Membership administration is intentionally closed rather than partially modeled. A caller with write authority in both source and destination organizations may reassign a resource because both UPDATE predicates pass; tenant immutability requires a separate rule. The recipe has no invitations, last-owner invariant, custom permissions, resource ownership, or global administrator.

## Production considerations

Design a separate tested membership lifecycle before enabling relationship mutations. Apply constraints, grants, indexes, and policies together; test role changes immediately against database state; and audit every new policy as part of the final combined condition.
