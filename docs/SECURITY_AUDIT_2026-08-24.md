# Security Audit — 2026-08-24

- **Report version:** 1.0
- **Reviewed revision:** `dac5ba3` plus the remediations recorded below
- **Reviewer:** Codex security review pass; independent of recipe implementation, not a substitute for human production sign-off
- **Scope:** grants, exposed schemas, RLS state and composition, relationships, Storage APIs, privileged access, indexes/foreign keys, migrations, tests, CI, dependencies, and credential exposure
- **Result:** no unresolved critical or high findings

## Method and current platform context

The review derived each effective condition from grants plus every policy matching role and command, inspected the source and runtime catalogs, composed all seven recipes in one local database, ran pgTAP/API adversarial matrices, lint, security/performance advisors, clean resets, and a source credential scan. No hosted project or production credential was accessed.

Current Supabase guidance confirms that exposed tables require both grants and RLS, UPDATE needs visibility plus a proposed-row check, Storage upsert needs INSERT/SELECT/UPDATE, `owner_id` is the supported Storage ownership field, and secret/service credentials bypass RLS. The 2026 Data API default change does not break these recipes because every app-role grant is explicit. Sources: [RLS](https://supabase.com/docs/guides/database/postgres/row-level-security), [Storage access control](https://supabase.com/docs/guides/storage/security/access-control), [Storage ownership](https://supabase.com/docs/guides/storage/security/ownership), [API key behavior](https://supabase.com/docs/guides/getting-started/api-keys), and [breaking-change catalog](https://supabase.com/changelog?types=breaking-change).

## Effective authorization conditions

| Recipe/path | Effective condition |
| --- | --- |
| User-owned data | SELECT/DELETE require existing `owner_id = auth.uid()`; INSERT requires proposed owner equality; UPDATE requires both existing and proposed owner equality. |
| Organization membership | Organization/resource access requires a normalized membership for the caller and row tenant; membership rows expose only the caller's relationship; relationship mutation has no app-role grant. |
| Roles and permissions | Any member reads; owner/admin insert and update resources; only owner deletes resources or updates/deletes organizations; membership facts are read-only to app roles. |
| Public read/private write | Anonymous SELECT is `published`; authenticated SELECT is `published OR owner`; every mutation is owner-only and UPDATE checks old and new rows. |
| Multi-tenant SaaS | Membership permits reads; owner/admin permits INSERT/UPDATE; owner permits DELETE; the item composite FK requires project and item tenant equality; membership mutation is inaccessible. |
| Storage | Object SELECT/UPDATE/DELETE require the private bucket, Storage `owner_id`, owner path segment, and database membership; INSERT requires bucket, owner path, and membership; UPDATE repeats the full condition for the resulting row. |
| Admin boundary | User JWTs remain owner-scoped; the backend secret path bypasses RLS and therefore depends on separate server authorization and credential custody. |

All recipe policies are permissive. The only overlapping role/command pair is authenticated SELECT on public content, whose final expression is intentionally `published OR owner_id = auth.uid()`.

## Findings and remediation

| ID | Severity | Status | Evidence | Remediation |
| --- | --- | --- | --- | --- |
| SA-01 | Medium | Remediated | `scripts/scan-secrets.mjs` previously inspected only a fixed extension allowlist, so a privileged value in an arbitrary textual file could evade CI. | The scanner now checks every non-binary file outside exact generated/runtime directories. `scan-secrets.test.mjs` proves detection in an unusual text path and runs in `verify:ci`. |
| SA-02 | Low | Remediated | `actions/checkout@v4` persists its token by default, leaving it accessible to later repository scripts despite read-only workflow permissions. [Official checkout documentation](https://github.com/actions/checkout/blob/main/README.md) documents the default and opt-out. | CI now sets `persist-credentials: false`; action commits, Node, Supabase CLI, and npm lock data remain pinned. |
| SA-03 | Low | Remediated | No single runtime regression proved the aggregate RLS/grant/index catalog across all independent fixtures. | Added a 10-assertion composed catalog test covering RLS, exact policy sets, UPDATE checks, relationship grants, anonymous grants, indexed FKs, and absence of public views/functions; CI runs advisors against that composed state. |

## Residual risk and disposition

| ID | Severity | Disposition | Residual risk |
| --- | --- | --- | --- |
| SR-01 | Medium | Accepted and documented | RLS does not constrain table owners, superusers, `BYPASSRLS`, secret, or legacy `service_role` contexts. The admin recipe documents that privileged backends require independent authorization, auditing, and credential custody. |
| SR-02 | Medium | Accepted and documented | Membership/role/SaaS UPDATE policies validate authority in source and destination but permit tenant reassignment when one caller has write authority in both. Each affected README now states that tenant immutability is a separate production invariant. |
| SR-03 | Low | Accepted | The advisor reports the two intentional permissive SELECT branches on public content as a performance warning. Their OR composition is required and tested; production cardinalities should determine whether consolidation is worthwhile. |
| SR-04 | Informational | Accepted | Thirteen indexes report unused in empty audit fixtures. They back RLS lookups or foreign keys; removal is not justified without representative production statistics and plans. |
| SR-05 | Informational | Accepted | Local configuration exposes development ports and generates local credentials under ignored `supabase/.temp`; it is not a production network model. The source scanner excludes only these exact Git-ignored runtime paths. |

## Verification evidence

- Clean CI sequence: `npm ci`, local start, `npm run verify:ci`, local stop.
- Static negative catalog: 7 recipes and 28 operations.
- Database: 4 foundation assertions, 276 recipe assertions, and 10 composed security-catalog assertions.
- APIs: 27 Storage assertions and 8 admin-boundary assertions.
- Tooling: schema lint passed; combined security/performance advisors returned no error-level issue, one intentional permissive-policy warning, and thirteen fixture-only unused-index informational notices.
- Credential controls: scanner self-regression passed and the final repository scan found no privileged value.
- Catalog inspection: 14 public recipe tables have RLS, 36 public policies plus 4 Storage object policies are exact, every UPDATE policy has `WITH CHECK`, relationship mutation grants are absent, every foreign key is indexed, and no recipe view or function is exposed.

## Conclusion

The implemented access paths match their documented threat models after remediation. No critical/high item remains; all medium/low residual risks have an explicit acceptance and production boundary above.
