# Supabase RLS Recipes

Supabase RLS Recipes is a SQL-first, security-focused reference for designing, reviewing, testing, and deploying Row Level Security in real Supabase and PostgreSQL applications. It favors small reproducible systems over isolated policy snippets.

> RLS is one authorization layer, not a complete application security guarantee. Privileged credentials, backend code, external systems, secrets, and public Storage configuration remain separate security boundaries.

## Why this repository exists

An RLS policy can look correct in isolation while the effective policy set permits cross-tenant access. This project therefore pairs each pattern with an authorization model, threat model, schema, seed identities, positive tests, negative tests, and deployment notes. Security claims must be reproducible from source control.

## Security philosophy

- Deny by default; make each actor, operation, and row scope explicit.
- Treat Postgres grants and RLS as separate gates.
- Derive authorization from trusted ownership or membership relationships, never from an unverified client-supplied tenant identifier.
- Review the effective combination of all policies. Permissive policies for the same command and role combine with `OR`.
- Test cross-tenant reads and writes, forged identifiers, anonymous access, and role changes.
- Keep `service_role` and secret keys in trusted server environments; they bypass RLS.
- Secure `storage.objects` independently from application tables.

## Planned recipes

| Recipe | Boundary demonstrated |
| --- | --- |
| User-owned data | A user can operate only on rows they own |
| Organization membership | Membership controls tenant resource access |
| Roles and permissions | Owner, admin, and member operations are explicit |
| Public read/private write | Published reads are public; mutations remain authorized |
| Multi-tenant SaaS | End-to-end tenant isolation across related tables |
| Storage isolation | Bucket, path, ownership, and tenant controls |
| Admin access | Trusted backend operations remain separate from app-user authorization |

Recipes are intentionally not implemented in this foundation phase. Their required shape is defined in [docs/RECIPE_STANDARD.md](docs/RECIPE_STANDARD.md).

## Quick start

1. Read [docs/PROJECT_CONTEXT.md](docs/PROJECT_CONTEXT.md), [docs/THREAT_MODEL.md](docs/THREAT_MODEL.md), and [docs/AUTHORIZATION_MODEL.md](docs/AUTHORIZATION_MODEL.md).
2. Choose a phase from `prompts/`; do not skip its stop condition.
3. Implement one recipe with `README.md`, `schema.sql`, `policies.sql`, `seed.sql`, and `tests.sql`.
4. Run the recipe from a clean local Supabase database and execute its complete authorization matrix.
5. Review [checklists/RECIPE_CHECKLIST.md](checklists/RECIPE_CHECKLIST.md) before merging.

Local Supabase setup and exact CLI commands are deliberately deferred to the foundation implementation phase. Discover commands from the installed CLI with `supabase --help`; do not rely on remembered syntax.

## Repository map

```text
docs/        Architecture, security model, operations, and standards
recipes/     Planned reproducible SQL recipes
templates/   Required authoring formats
checklists/  Review and release gates
prompts/     Scoped implementation phases with stop conditions
```

## Authorization testing

Every recipe must distinguish:

- a successful query or mutation;
- a successful query returning no rows because RLS filtered them;
- a mutation rejected by RLS;
- a mutation that affects zero rows because the target is invisible.

Positive-only tests do not establish isolation. See [docs/TESTING_STRATEGY.md](docs/TESTING_STRATEGY.md).

## Frequent warnings

- `TO authenticated` authenticates a role; it does not authorize a row.
- `USING` controls existing-row visibility; `WITH CHECK` controls proposed row values.
- `UPDATE` also needs row visibility through a `SELECT` policy.
- Views, functions, grants, join tables, Storage, and privileged keys require separate review.
- Dashboard changes that are absent from migrations create unreviewed production drift.

## Prerequisites

Implementation phases will require PostgreSQL, the Supabase CLI, Docker-compatible local containers, and a SQL test runner selected in phase 01. This planning package installs nothing and contains no production SQL.

## Contributing

Follow [CONTRIBUTING_RECIPES.md](docs/CONTRIBUTING_RECIPES.md), the recipe template, and all security checks. Report suspected vulnerabilities privately through the process in [SECURITY_REVIEW.md](docs/SECURITY_REVIEW.md); do not publish exploit details before triage.

## License and attribution

MIT licensed. Copyright © 2026 Fontesio. See [LICENSE](LICENSE).

Supabase is a trademark of its respective owner. This independent project is not an official Supabase repository and its examples must be reviewed against the current Supabase and PostgreSQL documentation before production use.
