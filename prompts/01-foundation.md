# Phase 01 — Reproducible Foundation

## Objective

Create the minimal local Supabase and test foundation needed for independent SQL recipes.

## Allowed scope

Initialize local Supabase configuration, select a deterministic SQL test approach, define fictional actor UUID conventions, add minimal CI-ready scripts, and document exact clean-start commands.

## Forbidden scope

No domain recipe schemas/policies, hosted project changes, frontend, broad tooling, or production deployment.

## Expected files

Minimal `supabase/` configuration/migrations as required, test harness files, ignore/config files, and updates to README/testing/architecture docs.

## Verification

Discover CLI commands with `--help`; start the local stack, rebuild cleanly, run a smoke assertion as non-privileged actor, and stop it. Pin any installed versions and commit lockfiles.

## Completion criteria

A contributor can reproduce the foundation from source with deterministic exit codes and no hosted credentials.

## Stop condition

Stop before creating any recipe.
