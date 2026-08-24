# Changelog

All notable changes to this project are documented in this file.

## [0.1.0] — 2026-08-24

### Added

- A pinned local Supabase and pgTAP foundation with CI-equivalent verification.
- Seven independent RLS recipes covering ownership, organization membership, explicit roles, public content, multi-tenancy, Storage isolation, and the trusted admin boundary.
- Positive, negative, catalog, Storage API, credential-scanning, and combined security-audit checks.
- Threat model, architecture, testing, migration/drift, contribution, and security-review documentation.

### Security

- The first independent access-path audit found no critical or high-severity issue. Accepted residual risks and production limitations are documented in the [security audit](docs/SECURITY_AUDIT_2026-08-24.md).

[0.1.0]: docs/RELEASE_0.1.0.md
