# Testing Strategy

## Objective

Tests must falsify authorization claims. A recipe passes only when intended operations succeed and adjacent unauthorized operations fail without changing protected state.

## Layers

1. **Build test:** apply schema, policies, and seeds to a clean local database.
2. **Catalog test:** verify RLS flags, grants, policy commands/roles, and expected indexes.
3. **Behavior test:** execute the authorization matrix under explicit actor context.
4. **State test:** verify denied mutations made no changes and allowed mutations changed only intended rows.
5. **Composition test:** exercise rows matching individual branches of multiple policies.
6. **Drift test:** compare expected source state with the target database before release.

## Required matrix dimensions

Every supported command includes the authorized actor/target pair and its nearest unauthorized counterpart. Multi-tenant recipes test both directions to avoid seed- or predicate-specific false confidence.

| Actor | Action | Target | Expected observation |
| --- | --- | --- | --- |
| Alice / Org A | SELECT | Org A row | Exact allowed row set |
| Alice / Org A | SELECT | Org B row | Empty result |
| Alice / Org A | INSERT | Org B tenant ID | Policy rejection; no row |
| Bob / Org B | UPDATE | Org A row | Zero affected or rejected; unchanged row |
| Anonymous | SELECT | Private row | Empty result |

## Identity setup

Use fixed fictional UUIDs. Each test must explicitly set or obtain the intended Postgres role and JWT claims through the harness selected in phase 01, then reset them between cases. Never run app-user assertions as table owner, superuser, or a role with `BYPASSRLS`.

## Assertions

- Assert exact rows and counts, not only lack of error.
- Assert SQLSTATE/error class for expected policy rejection when stable.
- Assert before/after state for all denied mutations.
- Assert that `auth.uid()` is null for the anonymous fixture and correct for authenticated fixtures.
- Use transactions or deterministic reset so cases do not depend on order.

## Storage

Exercise upload, download/list behavior, update/upsert, and delete through the Storage API where object semantics matter. Remember that upsert requires `INSERT`, `SELECT`, and `UPDATE` policies. Do not manipulate Storage metadata directly as a substitute for object operations.

## CI direction

Phase 06 should create a pinned, reproducible job that starts local Supabase, rebuilds from source, runs all matrices, validates formatting/syntax as selected in phase 01, scans for secrets, and exits nonzero on any missing or failed deny case. CI must not need a hosted project or production credentials.
