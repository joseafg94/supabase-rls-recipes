# Organization Membership

## Problem

This recipe grants CRUD access to organization resources only when the authenticated subject has a database-controlled membership row for that organization.

## Threat model

- **Assets:** tenant resources and membership relationships.
- **Actors:** Alice in Org A, Bob in Org B, an authenticated cross-tenant attacker, and `anon`.
- **Attacker goals:** read/write another tenant, forge `organization_id`, inspect another user's membership, or self-enroll.
- **Controls:** protected membership rows, membership-derived RLS on organizations/resources, explicit grants, and foreign keys.
- **Out of scope:** roles, invitations, membership administration, Storage, and privileged backends.

## Assumptions

Memberships are provisioned by a separate trusted workflow not implemented here. Clients cannot mutate the relationship table. Auth subjects are validated by Supabase and tests run as `anon`/`authenticated`, never table owner.

## Schema

`membership_organizations` owns `membership_resources` and `membership_organization_members` joins users to organizations. Composite and lookup indexes support relationship checks. All three exposed tables have RLS enabled.

## Authorization rules

| Actor | Command | Target | Expected | Reason |
| --- | --- | --- | --- | --- |
| Member | SELECT | Own organization/membership | Allow | Trusted membership matches `auth.uid()` |
| Member | CRUD | Own organization resource | Allow | Membership exists for row organization |
| Member | SELECT/UPDATE/DELETE | Other-organization resource | Empty/zero rows | Membership lookup fails |
| Member | INSERT | Forged other organization | RLS rejection | Proposed organization fails `WITH CHECK` |
| Member | INSERT | Membership table | Permission denied | No relationship mutation grant |
| Anonymous | Any exposed path | Private tenant data | Permission denied | No grants to `anon` |

## Policy explanation

The relationship row, not the browser's `organization_id`, establishes authority. Resource SELECT/UPDATE/DELETE use membership in `USING`; INSERT and the proposed UPDATE row use the same lookup in `WITH CHECK`. Membership SELECT exposes only the caller's own relationship, avoiding policy recursion while allowing resource policies to validate it. There is one permissive policy per resource command, so no broader OR branch widens tenant access.

## Expected allow cases

- [x] Alice performs CRUD within Org A.
- [x] Bob performs CRUD within Org B.
- [x] Each user sees only their organization and own membership row.

## Expected deny cases

- [x] Alice and Bob cannot read, update, or delete across organizations.
- [x] A forged foreign `organization_id` insert is rejected.
- [x] Self-enrollment and anonymous access are denied.
- [x] Final-state assertions prove denied operations had no effect.

## Run locally

```sh
npm ci
npm run db:start
npm run db:reset
npx supabase test db recipes/organization-membership/tests.sql --local
npm run db:stop
```

## Common mistakes

- Comparing a row tenant ID only to a client parameter instead of a trusted membership.
- Leaving the membership table readable or writable without an explicit model.
- Omitting `WITH CHECK`, allowing a resource to move tenants.
- Forgetting indexes on membership/resource lookup columns.

## Limitations

Every member has identical resource permissions. Invitations, suspension, membership lifecycle, roles, public resources, and tenant deletion are intentionally absent.

## Production considerations

Implement membership changes through a separately reviewed authorization flow, apply all objects through migrations, verify explicit Data API grants, monitor lookup performance, and regression-test both tenant directions after any policy or relationship change.
