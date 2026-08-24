# Migration and Production Drift

## Drift sources

- Dashboard policy or schema edits.
- Legacy/duplicate policies from prior migrations.
- Emergency SQL fixes not committed to Git.
- Changed grants, default privileges, exposed schemas, functions, or views.
- Storage policies and bucket settings altered independently.
- Historical migrations that no longer reconstruct expected state.

## Safe reconciliation workflow

1. Inventory the target's schemas, grants, RLS flags, policies, roles, views/functions, and Storage configuration with read-only queries.
2. Rebuild source-controlled state in an isolated environment.
3. Produce and review a semantic diff, including the effective policy condition per command and role.
4. Classify drift as intended, obsolete, or unknown; preserve an evidence record.
5. Write a forward-only controlled migration with explicit rollback/mitigation notes.
6. Test the migration on a production-like copy and run authorization regressions.
7. Apply through the normal deployment process, monitor, and repeat the catalog/behavior checks.
8. Commit any accepted source-of-truth changes and close the drift record.

## Safety rules

- Never reset or destructively recreate production to make it match local state.
- Do not drop an unknown policy because its name looks obsolete; determine which traffic depends on it.
- Back up and rehearse when reconciliation changes destructive permissions or membership data.
- Avoid dashboard-only fixes. If an emergency requires one, immediately capture and review the equivalent migration.
- Check current Supabase CLI help and documentation before using diff/pull commands; command behavior changes over time.

## Verification record

Record target/environment, inspection timestamp, source revision, observed drift, reviewer, migration identifier, matrix results, monitoring outcome, and unresolved risks. Do not place credentials or sensitive production rows in the report.
