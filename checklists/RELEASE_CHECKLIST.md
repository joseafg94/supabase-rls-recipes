# Release Checklist

- [ ] SQL syntax and clean rebuild verified on documented tool versions.
- [ ] Every published recipe passes `RECIPE_CHECKLIST.md`.
- [ ] Every recipe has positive and negative tests.
- [ ] Bidirectional cross-tenant isolation passes where applicable.
- [ ] Storage authorization tests cover declared operations.
- [ ] Catalog verification matches intended grants, RLS flags, policies, roles, and indexes.
- [ ] Security checklist and independent security review pass.
- [ ] Secret/data scan passes, including generated artifacts.
- [ ] README, local reproduction, limitations, and architecture docs match behavior.
- [ ] Internal links and recipe commands are verified.
- [ ] Migration/drift guidance remains non-destructive and current.
- [ ] CI strategy and evidence are documented.
- [ ] MIT license, 2026 Fontesio attribution, version, and release notes are present.
- [ ] No unresolved high-risk finding or failed deny case remains.
