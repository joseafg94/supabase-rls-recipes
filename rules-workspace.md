# Durable Workspace Rules

1. Read `PROJECT_PROFILE.md`, `AGENTS.md`, the relevant design document, and the active phase prompt before changing files.
2. Do not implement work from a later phase or expand scope to a frontend, hosted project, or production database.
3. Confirm current Supabase and PostgreSQL behavior from primary documentation before adding security-sensitive examples.
4. Make schema and policy changes through source-controlled migrations once local iteration is verified; do not leave dashboard-only state.
5. Never store service keys, secret keys, passwords, tokens, connection strings, real tenant data, or client identifiers.
6. Use fixed fictional UUIDs consistently across seeds, matrices, and assertions.
7. Treat `anon`, authenticated users, tenant outsiders, tenant roles, and privileged backends as separate actors.
8. Require an explicit reason for every grant, policy, public bucket, view, function, or RLS bypass.
9. Run positive and negative tests after every authorization change. A query that merely executes is not proof of correct isolation.
10. Record assumptions and unresolved decisions in the relevant recipe or architecture document.
11. Inspect live/production state before reconciliation; never recommend destructive production resets.
12. Stop when the active prompt's completion criteria are met and report only verified results.
