# Common RLS Failure Patterns

## 1. RLS enabled but effectively public

```sql
-- Dangerous on private data.
using (true)
```

Enabling RLS changes the enforcement mechanism; the policy still defines the outcome. Test anonymous and unrelated authenticated actors.

## 2. Authentication mistaken for authorization

`TO authenticated` admits every caller mapped to that role. Add an ownership, membership, or permission predicate.

## 3. Missing `WITH CHECK`

An update policy that can find Alice's row but does not constrain proposed values may permit changing its owner or tenant. Use `USING` and `WITH CHECK`, then test reassignment.

## 4. Client-trusted tenant identifiers

`tenant_id = request.tenant_id` compares two untrusted values. Resolve the tenant through a membership row bound to `(select auth.uid())`.

## 5. Permissive policies unexpectedly combine

Two applicable permissive policies combine with `OR`. A broad public or support policy can make a narrow tenant policy irrelevant for matching rows. Derive and test the complete effective condition.

## 6. Join table left unprotected

An exposed membership table can leak tenant/user relationships or allow self-enrollment and escalation. Review grants, reads, inserts, updates, and deletes on relationship tables.

## 7. Owner access crosses tenants

A resource-level `created_by = auth.uid()` policy may expose a row after it moves to a tenant where the creator has no membership. State whether ownership survives tenant boundaries and compose both predicates when required.

## 8. Storage assumed private

Application-table RLS does not secure Storage. Public buckets and incomplete `storage.objects` policies can expose files independently.

## 9. `service_role` in a frontend

Privileged keys bypass RLS. Browser exposure turns every database policy into a non-boundary. Use only a trusted backend with independent authorization.

## 10. Positive-only tests

Alice reading Alice's row proves functionality, not isolation. Add Alice→Bob, Bob→Alice, anonymous, forged ID, and forbidden mutation cases.

## 11. Production drift

Dashboard edits, manual fixes, and legacy policies can change the effective condition without changing Git. Inspect catalogs and reconcile through controlled migrations.

## 12. Missing migrations

If a policy exists only in a dashboard or SQL history, a clean rebuild cannot reproduce or review it. Capture intentional state in source control.

## 13. Unsafe auth assumptions

`auth.uid()` is null without an authenticated subject. User metadata is editable by the user; app metadata can be stale until JWT refresh. Make identity and freshness assumptions explicit.

## 14. Recursive or expensive policy lookup

Policies querying protected relationship tables can recurse or execute costly lookups per row. Use indexed predicates, measure plans, and introduce narrowly secured internal helpers only when justified.

## 15. Unpublished rows exposed

A public-read policy must include the publication predicate. An owner/editor policy should be a separately reviewed branch, with anonymous and unrelated-user tests for drafts.

## 16. Views and functions bypass expectations

Views can execute with owner semantics unless configured appropriately; functions are governed by execution grants rather than table RLS. Prefer security-invoker views where supported and review every privileged function.

## 17. Update silently changes nothing

An UPDATE requires visibility of the existing row. A missing SELECT policy can produce zero affected rows rather than the expected success. Assert row counts and final state.

## 18. Grants forgotten

RLS policies do not grant access to the object. Platform defaults evolve, so explicitly verify grants for `anon` and `authenticated` in tests and migrations.
