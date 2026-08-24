# Release 0.1.0 — 2026-08-24

## Release identity

- Version: `0.1.0` in `package.json` and `package-lock.json`.
- Intended tag: `v0.1.0` on the commit containing this report.
- Hosting: [GitHub repository](https://github.com/joseafg94/supabase-rls-recipes).
- License and attribution: [MIT License](../LICENSE), copyright 2026 Fontesio.
- Publication status: release-ready candidate; no tag or hosted release was created during Phase 09.

## Contents

This first release contains the reproducible local foundation and all seven [cataloged recipes](../recipes/README.md): user-owned data, organization membership, roles and permissions, public-read/private-write, multi-tenant SaaS, Storage isolation, and the trusted admin boundary. It adds no hosted integration, frontend, production credentials, or claim that the examples form a complete application security model.

## Verification evidence

The release candidate was rebuilt and verified locally on Node.js 24.11.1, npm 10.5.2, Supabase CLI 2.115.0, Docker Engine 29.7.2, and the CLI-managed PostgreSQL stack. The CI-equivalent sequence was:

```sh
npm ci
npm run db:start
npm run verify:ci
npm run db:stop
```

The run passed 4 foundation assertions, 276 recipe SQL assertions, 10 combined security-catalog assertions, 27 Storage API assertions, and 8 admin-boundary API assertions. Schema lint, the 28-operation negative-test catalog, scanner regression, final privileged credential scan, and database advisors also completed. The single advisor warning is the intentional overlapping public/authenticated read model documented in the [security audit](SECURITY_AUDIT_2026-08-24.md).

## Recipe gates

All seven recipe directories contain the required README, schema, policies, seed, and tests files. Their READMEs document actors, threat boundaries, authorization rules, allow/deny evidence, clean-start commands, limitations, and production concerns. The SQL and API matrices cover supported operations, anonymous and unrelated actors, forged identifiers, reassignment, escalation, bidirectional tenant isolation where applicable, and denied-operation final state.

Storage list/read, upload, update, upsert, delete, bucket scope, forged paths, anonymous access, and final object state are exercised through the Storage API. Catalog tests separately verify grants, RLS flags, policy command/role shape, indexes, policy composition, views, functions, and privileged-code exposure.

## Security disposition

The [independent security audit](SECURITY_AUDIT_2026-08-24.md) has no unresolved critical or high-severity finding. Its one intentional advisor warning and medium/low residual risks are accepted for this reference scope; the report records evidence, remediation, reviewer, and production sign-off limits. The [security checklist](../checklists/SECURITY_CHECKLIST.md) is represented by executable catalog, behavior, API, advisor, and credential-scan gates rather than assumed from policy text.

## Documentation, links, and drift

All local Markdown targets, documented npm scripts, recipe command paths, recipe/phase lists, and external reference URLs were checked. The [testing strategy](TESTING_STRATEGY.md) records CI behavior and assertion totals; [migration and drift guidance](MIGRATION_AND_DRIFT.md) remains forward-only and explicitly prohibits destructive production reconciliation.

## Published limitations

The root [security disclaimer](../README.md) and each recipe README publish their assumptions and limitations. In particular:

- These are isolated reference fixtures, not a production application or universal authorization framework.
- Membership and role lifecycle, invitations, billing, frontend key handling, and backend admin authorization are intentionally outside scope.
- `WITH CHECK` validates proposed authorization scope but does not make tenant identifiers immutable when the same caller is authorized in both source and destination tenants.
- Public content is deliberately readable when published; Storage requires separate bucket/path/object controls; privileged credentials bypass RLS and require a trusted server boundary.
- Production deployment still requires environment-specific grants, drift review, operational controls, performance validation, monitoring, and human security sign-off.

Recipe-specific details are in [user-owned data](../recipes/user-owned-data/README.md#limitations), [organization membership](../recipes/organization-membership/README.md#limitations), [roles and permissions](../recipes/roles-and-permissions/README.md#limitations), [public-read/private-write](../recipes/public-read-private-write/README.md#limitations), [multi-tenant SaaS](../recipes/multi-tenant-saas/README.md#limitations), [Storage isolation](../recipes/storage-isolation/README.md#assumptions-and-limitations), and [admin access](../recipes/admin-access/README.md#assumptions-and-limitations).

## Platform review

The [Supabase breaking-change catalog](https://supabase.com/changelog?types=breaking-change), [CLI reference](https://supabase.com/docs/reference/cli/introduction), [RLS guide](https://supabase.com/docs/guides/database/postgres/row-level-security), and [Storage access-control guide](https://supabase.com/docs/guides/storage/security/access-control) were reviewed on 2026-08-24. Relevant 2026 changes do not block this release: grants are explicit despite the Data API default change, extensions are not version-pinned in SQL, and the tests use the pinned project CLI and local stack. Hosted Management API, Realtime, GraphQL, and self-hosted gateway changes are outside the repository's exercised paths.

## Manual publication action

First push the release-preparation commit so GitHub Actions can verify the exact candidate:

```sh
git push origin main
```

After the `Verify RLS recipes` workflow passes for that commit, create and publish only the approved tag and release:

```sh
git tag -a v0.1.0 -m "Supabase RLS Recipes 0.1.0"
git push origin v0.1.0
gh release create v0.1.0 --verify-tag --title "Supabase RLS Recipes 0.1.0" --notes-file docs/RELEASE_0.1.0.md
```
