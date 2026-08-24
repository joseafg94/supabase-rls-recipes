# Phase 04 — Multi-Tenant SaaS Recipe

## Objective

Build the flagship realistic organization/membership/project/resource recipe and prove tenant isolation for reads and writes.

## Allowed scope

Create only `recipes/multi-tenant-saas/` using Alice/Org A, Bob/Org B, and Carol for a documented admin/member scenario.

## Forbidden scope

No Storage, frontend, billing, invitations, service-role shortcut, generic RBAC engine, or production deployment.

## Expected files

Recipe `README.md`, `schema.sql`, `policies.sql`, `seed.sql`, and `tests.sql`.

## Verification

Test both tenant directions for SELECT/INSERT/UPDATE/DELETE, membership/role differences, forged tenant IDs, row reassignment, direct membership access, related-table paths, policy composition, and exact final state.

## Completion criteria

The mandatory authorization matrix passes from clean state; the README demonstrates why browser-provided `tenant_id` is insufficient and documents index/performance assumptions.

## Stop condition

Stop after the flagship recipe and review evidence; do not begin Storage.
