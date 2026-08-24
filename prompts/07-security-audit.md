# Phase 07 — Security Audit

## Objective

Perform an independent, evidence-based audit of all access paths and correct confirmed findings within existing recipe scope.

## Allowed scope

Inspect grants, policies, RLS state, views/functions, relationships, Storage, tests, indexes, migrations, CI, and secret exposure; add regression tests and minimal fixes for confirmed issues.

## Forbidden scope

No new features/recipes, production access, speculative rewrites, or weakening tests to accept current behavior.

## Expected files

Targeted fixes/tests plus a versioned audit report containing severity, evidence, remediation, residual risk, and reviewer.

## Verification

Derive effective policy conditions, run adversarial matrices, advisors/tools selected by the foundation, clean rebuild, CI, and secret scan.

## Completion criteria

No unresolved critical/high finding; medium/low residual risks are documented and accepted or tracked.

## Stop condition

Stop after publishing the audit report; do not polish or release.
