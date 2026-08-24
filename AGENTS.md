# Agent Instructions

## Purpose and boundaries

This repository is a security reference for Supabase/PostgreSQL RLS. Keep it SQL-first. Do not add a frontend, production integration, credentials, real identities, or proprietary data. Examples must use fictional UUIDs and deterministic data.

## Architecture rules

- Treat grants, RLS, Storage policies, functions, views, and privileged backend access as distinct controls.
- Keep authorization facts in normalized ownership, membership, or permission relationships controlled by the database.
- Do not trust client-supplied tenant identifiers or user-editable JWT metadata.
- Prefer explicit policies per operation. Document the final effective condition when permissive policies overlap.
- Put internal helpers outside exposed schemas; use `SECURITY DEFINER` only with a written justification, fixed empty `search_path`, explicit caller identity checks, and revoked default execution.
- Index columns used by RLS predicates, foreign keys, and membership lookups; verify plans when scale assumptions matter.

## Testing rules

- Every recipe needs positive and negative tests for each supported operation.
- Test as `anon`, relevant authenticated identities, a malicious cross-tenant user, and any privileged actor in scope.
- Distinguish empty results, policy errors, and zero-row mutations.
- Test forged ownership/tenant identifiers, reassignment attempts, policy composition, and join-table access.
- A recipe is incomplete until it rebuilds from a clean local database and its matrix passes.

## Documentation rules

- State the threat model, assumptions, authorization rules, limitations, and production concerns.
- Explain why each policy is safe under its assumptions, not only what it does.
- Link claims that depend on Supabase behavior to current official documentation.
- Keep examples minimal and avoid marketing language or unsupported guarantees.

## Workflow

Follow `UNDERSTAND → PLAN → IMPLEMENT → VERIFY → REPORT`. Read the selected phase prompt, modify only its allowed files, and stop at its stop condition. Use migrations and tests as the source of truth; never treat dashboard state or chat history as authoritative.

## Completion criteria

Work is complete only when required files exist, SQL and tests have been executed where applicable, negative cases pass, documentation matches behavior, no secrets or real data are present, and the relevant checklist is satisfied.
