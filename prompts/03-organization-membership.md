# Phase 03 — Membership, Roles, and Public Content

## Objective

Implement three bounded recipes: organization membership, explicit owner/admin/member permissions, and public-read/private-write.

## Allowed scope

Create `recipes/organization-membership/`, `recipes/roles-and-permissions/`, and `recipes/public-read-private-write/`; update catalog/docs only where newly verified behavior requires it.

## Forbidden scope

No flagship multi-tenant integration, Storage, service-role implementation, frontend, or generalized authorization framework.

## Expected files

The required five files in each recipe directory.

## Verification

Test direct relationship-table access, cross-org reads/writes, self-enrollment/role escalation, destructive-operation differences, anonymous published reads, anonymous mutations, and unpublished-row isolation.

## Completion criteria

Each operation maps to a named rule and every rule has nearest-neighbor deny coverage; all three recipe checklists pass.

## Stop condition

Stop before composing these concepts into the flagship recipe.
