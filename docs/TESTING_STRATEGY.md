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

| Fixture | UUID |
| --- | --- |
| Alice | `00000000-0000-4000-8000-000000000001` |
| Bob | `00000000-0000-4000-8000-000000000002` |
| Carol | `00000000-0000-4000-8000-000000000003` |
| Org A | `10000000-0000-4000-8000-000000000001` |
| Org B | `10000000-0000-4000-8000-000000000002` |

Additional fixture UUIDs use a documented category prefix and monotonically increasing final segment; existing identifiers are never repurposed.

## Local commands

Run the same sequence used by CI: `npm ci`, `npm run db:start`, `npm run verify:ci`, and `npm run db:stop`. `verify:ci` resets between independent SQL/API layers and uses explicit local-only flags; it must never be changed to `--linked`.

## Assertions

- Assert exact rows and counts, not only lack of error.
- Assert SQLSTATE/error class for expected policy rejection when stable.
- Assert before/after state for all denied mutations.
- Assert that `auth.uid()` is null for the anonymous fixture and correct for authenticated fixtures.
- Use transactions or deterministic reset so cases do not depend on order.

## Storage

Exercise upload, download/list behavior, update/upsert, and delete through the Storage API where object semantics matter. Remember that upsert requires `INSERT`, `SELECT`, and `UPDATE` policies. Do not manipulate Storage metadata directly as a substitute for object operations.

## CI

`.github/workflows/verify.yml` pins action commits, Node 24.11.1, and the lockfile-installed Supabase CLI 2.115.0. `scripts/verify-test-catalog.mjs` requires an explicit `[deny:<operation>]` assertion for every supported recipe operation; `scripts/verify-ci.mjs` then rebuilds, lints, runs every SQL/API matrix, and scans source files for privileged credential values. The job has no hosted Supabase dependency or repository secret.

Current CLI guidance confirms that `supabase test db` wraps each pgTAP file in a transaction and that `supabase db reset --local` recreates the local database from committed migrations. See [Supabase automated CI testing](https://supabase.com/docs/guides/deployment/ci/testing) and [CLI testing and linting](https://supabase.com/docs/guides/local-development/cli/testing-and-linting).

## Phase 06 evidence — 2026-08-24

The exact CI sequence completed locally with a clean `npm ci`: 4 foundation assertions, 276 recipe SQL assertions, 27 Storage API assertions, 8 admin boundary API assertions, 28 cataloged negative operations, schema lint, and the privileged credential scan all passed. Temporarily replacing the user-owned `SELECT` ownership predicate with `true` caused the expected 4-of-35 failure, including `[deny:select]`; restoring the predicate and rerunning `verify:ci` returned the full suite to green.
