# Security Checklist

- [ ] No secret/service key, password, token, connection string, real identity, or production row exists in files or generated artifacts.
- [ ] No frontend or untrusted client receives a privileged credential.
- [ ] Every exposed object has intentional grants and row/function controls.
- [ ] Every exposed table has RLS; relationship tables receive equal review.
- [ ] `TO authenticated` is paired with actual row authorization.
- [ ] Client-supplied owner, tenant, role, and path values are verified against trusted facts.
- [ ] User-editable metadata is never used for authorization; JWT freshness is documented where relevant.
- [ ] Update policies cover visibility and proposed-row checks.
- [ ] Policy composition was derived per role/command and tested.
- [ ] Views use safe invoker semantics or are inaccessible to app roles.
- [ ] Privileged functions are necessary, outside exposed schemas, identity-checking, fixed-search-path, and execution-restricted.
- [ ] Storage bucket visibility and each object operation are explicit.
- [ ] Cross-tenant and privilege-escalation tests pass with unchanged protected state.
- [ ] Production drift/reconciliation impact is documented.
- [ ] Known limitations and residual risks are visible.
