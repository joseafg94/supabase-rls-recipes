# Contributing Recipes

## Before proposing a recipe

Open an issue or design note that states the authorization problem, why an existing recipe does not cover it, actors, trusted relationships, operations, threats, and intended limitations. A recipe should teach one coherent boundary.

## Authoring process

1. Copy the recipe, threat-model, and test-matrix templates.
2. Define the matrix before writing policies.
3. Implement the smallest schema that makes the relationship realistic.
4. Add grants and RLS explicitly, then tests for every matrix row.
5. Rebuild from clean local state and execute all tests.
6. Complete recipe and security checklists; request security-focused review.

## Pull request evidence

Include the recipe purpose, changed access paths, exact verification commands, test output summary, assumptions, known limitations, and any version-sensitive Supabase behavior. Never attach secrets, production dumps, or real tenant data.

## Review expectations

Reviewers inspect the effective policy set rather than policy names, attempt cross-tenant and forged-value attacks, check related tables and Storage, confirm grants and RLS flags, and compare prose to observed database behavior.

## Changes to existing recipes

An authorization change is breaking unless proven otherwise. Update the matrix and threat model first, add regression tests reproducing the old/new boundary, document migration implications, and note the change for release.
