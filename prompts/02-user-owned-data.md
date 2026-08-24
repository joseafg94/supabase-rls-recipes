# Phase 02 — User-Owned Data Recipe

## Objective

Implement the smallest complete ownership recipe demonstrating `auth.uid()`, all CRUD commands, `USING`, and `WITH CHECK`.

## Allowed scope

Create only `recipes/user-owned-data/` and update catalog links. Use Alice and Bob fixtures plus anonymous context.

## Forbidden scope

No organizations, roles, Storage, admin APIs, shared abstractions, or changes to unrelated foundation behavior.

## Expected files

Recipe `README.md`, `schema.sql`, `policies.sql`, `seed.sql`, and `tests.sql`.

## Verification

Rebuild cleanly; test Alice→Alice allow, Alice→Bob deny, Bob→Bob allow, anonymous deny, forged owner insert, owner reassignment, and deletes; assert final state.

## Completion criteria

Recipe and security checklists pass and documentation explains why `USING` alone is insufficient.

## Stop condition

Stop after this recipe passes; do not implement organization recipes.
