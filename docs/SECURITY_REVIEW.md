# Security Review

## Review scope

Review every reachable table, view, function/RPC, sequence, relationship table, Storage bucket/object path, and privileged backend operation introduced or affected by a change.

## Method

1. Enumerate actors, commands, objects, and trusted relationships.
2. Inspect grants and RLS enable/force state.
3. List applicable policies by role and command; derive the effective Boolean condition.
4. Trace writes through foreign keys, triggers, functions, views, and Storage.
5. Challenge identity, claim freshness, membership lifecycle, and tenant-move assumptions.
6. Run the complete matrix plus adversarial payloads and verify final state.
7. Review indexes/query plans for authorization lookups that could create availability risks.
8. Scan repository/history artifacts for credentials and real data.

## High-risk findings

Block release for unexplained `USING (true)`, missing RLS on an exposed table, frontend privileged keys, writable membership without escalation tests, cross-tenant leakage, public buckets without intentional public semantics, unreviewed `SECURITY DEFINER`, or failed negative tests.

## Vulnerability reporting

Do not open a public issue containing a working exploit against a deployed system. Contact the maintainers privately through the security contact published in the repository hosting settings. Maintainers should acknowledge, reproduce, assess affected recipes/releases, prepare a regression test and fix, coordinate disclosure, and publish remediation notes without exposing private reporter data.

## Disclaimer

Passing review establishes that the documented fixtures behaved as tested under stated assumptions. It is not certification of an adopting application's schema, code, deployment, secrets, or operations.
