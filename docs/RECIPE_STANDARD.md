# Recipe Standard

## Required layout

```text
recipes/<recipe-name>/
  README.md
  schema.sql
  policies.sql
  seed.sql
  tests.sql
```

`reset.sql` and `notes.md` are optional. A recipe must not depend on another recipe.

## README contract

In this order, explain:

1. Problem solved.
2. Threat model and actors.
3. Assumptions and non-goals.
4. Schema and trusted relationships.
5. Authorization matrix by actor and operation.
6. Policy explanation, including effective composition.
7. Expected allow cases.
8. Expected deny cases and their observable form.
9. Reproduction commands from a clean local environment.
10. Common mistakes.
11. Limitations.
12. Production considerations, grants, indexes, drift, and version-sensitive behavior.

## SQL file responsibilities

- `schema.sql`: tables, constraints, indexes, grants needed for reachability, and explicit RLS enablement.
- `policies.sql`: policies and only narrowly justified authorization helpers.
- `seed.sql`: deterministic fictional users, tenants, memberships, resources, and boundary data.
- `tests.sql`: executable positive and negative assertions with explicit actor context and state verification.
- `reset.sql`: recipe-scoped cleanup only; never presented as a production procedure.

## Quality requirements

- Use lowercase SQL style consistently once phase 01 selects formatting rules.
- Name policies by actor/operation/scope rather than vague labels.
- Use explicit `TO` roles and operation clauses.
- Include `WITH CHECK` wherever proposed values need authorization.
- Index foreign keys and policy lookup columns when justified by access patterns.
- Document grants separately from policies.
- Avoid user-editable metadata, exposed privileged functions, and frontend privileged keys.
- Include exact expected results for each matrix row.

## Acceptance

The recipe checklist passes, all SQL applies from clean state, every deny case leaves protected state unchanged, documentation matches observed behavior, and the security review finds no unexplained access path.
