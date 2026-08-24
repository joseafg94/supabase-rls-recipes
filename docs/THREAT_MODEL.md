# Repository Threat Model

## Assets

- Private user and tenant rows.
- Membership, ownership, and role assignments.
- Unpublished/publication state.
- Stored objects and their metadata.
- Privileged credentials and migration integrity.
- Confidence that examples match documented behavior.

## Actors

| Actor | Trusted capability | Must not gain |
| --- | --- | --- |
| Anonymous user | Explicit public reads only | Private rows, mutations, private objects |
| Authenticated user | Operations granted to their identity | Another user's data or implicit tenant access |
| Malicious authenticated user | Same credentials as a normal user | Benefits from forged IDs, payloads, or paths |
| Other-tenant member | Access within their own tenant | Cross-tenant reads or writes |
| Organization member/admin/owner | Explicit role operations in their tenant | Undocumented destructive or global privileges |
| Trusted backend/service role | Narrow server-side privileged tasks | Browser exposure or use as app-user authorization |
| Developer/operator | Reviewed migration and operational access | Undocumented production policy changes |

## Threats and required controls

| Threat | Control | Evidence |
| --- | --- | --- |
| Cross-tenant read/write | Membership-derived RLS on every related table | Bidirectional tenant tests for every command |
| Forged owner or tenant ID | `WITH CHECK`, foreign keys, trusted relationship lookup | Attempted foreign insert and reassignment |
| Privilege escalation | Explicit role-operation matrix and protected membership writes | Member/admin escalation tests |
| Join-table exposure | RLS and grants reviewed on relationship tables | Direct join-table access tests |
| Permissive-policy widening | Review final OR/AND expression | Test rows matching each policy branch |
| Accidental public data | Publication predicate plus owner/editor mutation rules | Anonymous private/unpublished tests |
| Storage crossover | Bucket/path/owner/tenant predicates on `storage.objects` | Cross-user and cross-tenant object operations |
| Privileged-key exposure | Server-only handling and secret scanning | Repository scan and architecture review |
| Policy drift | Catalog comparison and controlled reconciliation | Drift report plus regression suite |
| Stale or unsafe claims | Avoid user metadata; document JWT freshness | Claim mutation/refresh assumptions tested if used |

## Trust assumptions

- Supabase Auth correctly signs and validates tokens; `auth.uid()` reflects the authenticated subject when invoked in a supported request context.
- Database owners, superusers, and roles with `BYPASSRLS` are privileged and outside ordinary RLS enforcement.
- The deployment has not leaked service/secret keys and server-side code enforces its own authorization when bypassing RLS.
- Foreign keys and membership mutation paths are configured as documented by each recipe.

## Out of scope

RLS does not prevent credential theft, malicious privileged operators, vulnerable application code running with bypass privileges, insecure third-party systems, denial of service, or public bucket delivery. Recipes reduce specific authorization failures; they do not make an application secure by themselves.

## Review triggers

Revisit this model when adding an actor, role, table, view, RPC/function, exposed schema, bucket, JWT claim, or privileged backend flow.
