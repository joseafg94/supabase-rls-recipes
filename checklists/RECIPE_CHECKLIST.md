# Recipe Checklist

## Structure and documentation

- [ ] Required five files exist and the recipe is independent.
- [ ] Problem, actors, threats, assumptions, schema, rules, limitations, and production concerns are documented.
- [ ] README commands were executed from clean local state.
- [ ] Fictional stable identities match seeds and tests.

## Authorization design

- [ ] Grants and exposed-schema decisions are explicit.
- [ ] RLS is enabled on every applicable table, including relationship tables.
- [ ] Policies specify command and target roles.
- [ ] `USING` and `WITH CHECK` match existing/proposed-row rules.
- [ ] Authorization derives from trusted ownership/membership/permission facts.
- [ ] All applicable permissive/restrictive policies are analyzed together.
- [ ] Views, functions, triggers, and Storage paths are reviewed.
- [ ] RLS predicate and foreign-key indexes are justified.

## Tests

- [ ] Each supported command has allow and deny coverage.
- [ ] Anonymous, unrelated user, cross-tenant, and role-specific cases are covered.
- [ ] Forged IDs, reassignment, and escalation attempts are covered.
- [ ] Denied mutations leave state unchanged.
- [ ] Assertions run without owner/superuser/`BYPASSRLS` privileges.
- [ ] Full matrix passes deterministically.
