# Phase 06 — Negative Testing and CI

## Objective

Strengthen adversarial coverage across all implemented recipes and run it reproducibly in CI.

## Allowed scope

Add missing deny cases, catalog assertions, clean rebuild orchestration, pinned GitHub Actions workflow, and concise testing documentation.

## Forbidden scope

No new recipes/features, hosted Supabase dependency, production credentials, or refactoring unrelated policy logic.

## Expected files

Recipe test updates, minimal test runner/config, `.github/workflows/` verification job, and documentation updates.

## Verification

Run the same clean CI sequence locally; deliberately perturb one policy to prove a deny test fails, restore it, then confirm the full suite and secret scan pass.

## Completion criteria

Every recipe has explicit negative coverage by operation; CI is deterministic, pinned, and requires no secrets.

## Stop condition

Stop after CI evidence is recorded; do not perform release work.
