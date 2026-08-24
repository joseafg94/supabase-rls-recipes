# Project Context

## Problem

RLS guidance often presents one policy without its grants, related tables, interacting policies, test identities, or failure cases. Developers then copy syntax while missing the actual authorization boundary. This repository makes the boundary and its evidence the unit of documentation.

## Audience

Solo developers, SaaS teams, agencies, product studios, backend engineers, and Supabase users who already understand basic SQL and need reviewable application patterns.

## Deliverable model

Each recipe is an isolated fixture with schema, policies, seed data, tests, and an explanation tied to a shared threat model. Recipes optimize for clarity and falsifiability rather than feature completeness.

## Vocabulary

- **Authentication:** establishing the caller's identity or database role.
- **Authorization:** deciding whether that actor may perform an operation on a target.
- **Tenant:** an organization-level isolation domain.
- **Trusted relationship:** an ownership, membership, or permission row that the caller cannot freely forge.
- **Allow case:** an operation that must succeed with defined effects.
- **Deny case:** an operation that must return no rows, affect no rows, or raise the expected authorization error.
- **Effective policy:** the complete Boolean condition produced by applicable grants, roles, commands, and policy composition.

## Current phase

Only planning, standards, templates, checklists, and scoped prompts are included. Recipe SQL, Supabase initialization, dependencies, and CI workflow are deferred.

The current repository/tooling audit is recorded in [AUDIT_2026-08-24.md](AUDIT_2026-08-24.md).

## Decision record

- SQL-first and framework-neutral.
- One self-contained fixture per recipe.
- Multi-tenant SaaS is the flagship integration recipe.
- Negative tests are release-blocking.
- Official Supabase/PostgreSQL behavior is rechecked during implementation because platform defaults evolve.
