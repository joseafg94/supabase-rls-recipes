# Project Profile

| Field | Value |
| --- | --- |
| Name | Supabase RLS Recipes |
| Ownership | Independent open-source project by Fontesio |
| Project level | M |
| Risk | Medium to High |
| Primary stack | PostgreSQL, Supabase, SQL, Supabase Auth, Supabase Storage |
| Delivery mode | SQL-first documentation, reproducible recipes, authorization tests |
| License | MIT |

## Outcome

Provide auditable reference implementations that help developers prove row and object isolation rather than infer it from policy appearance.

## In scope

- Small fictional schemas, deterministic seed identities, RLS policies, Storage policies, and executable authorization matrices.
- Supabase local development, source-controlled migrations, CI verification, drift review, and release gates.
- User ownership, organization membership, explicit roles, public content, multi-tenancy, Storage, and trusted administration.

## Out of scope

- A production-ready application or frontend.
- A universal policy generator or claim that one model fits every product.
- Production credentials, real tenant data, proprietary SQL, or guidance that exposes privileged keys.
- Protection against compromised trusted backends, leaked credentials, insecure external systems, or authorization logic outside PostgreSQL.

## Success measures

- Each recipe rebuilds from source on a clean local instance.
- Every stated allow and deny case is executable and deterministic.
- Tenant and Storage boundaries have explicit negative tests.
- Reviewers can map each policy predicate to an authorization rule and threat.
- Release checks detect missing RLS, policy drift, secrets, and documentation inconsistencies.

## Constraints

Documentation correctness and security evidence take priority over breadth. Recipes are added only through phased prompts and are never represented as universally safe without their assumptions and limitations.
