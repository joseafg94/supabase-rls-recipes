# Recipe Catalog

Each phase creates only its named recipe and must follow `docs/RECIPE_STANDARD.md`.

| Directory planned | Implementation phase | Focus |
| --- | --- | --- |
| [user-owned-data/](user-owned-data/) | 02 | Ownership and per-command checks |
| [organization-membership/](organization-membership/) | 03 | Relationship-based tenant access |
| [roles-and-permissions/](roles-and-permissions/) | 03 | Explicit owner/admin/member operations |
| [public-read-private-write/](public-read-private-write/) | 03 | Published reads and authorized mutations |
| [multi-tenant-saas/](multi-tenant-saas/) | 04 | Flagship tenant-isolation system |
| [`storage-isolation/`](storage-isolation/README.md) | 05 | Bucket/path/object authorization |
| [`admin-access/`](admin-access/README.md) | 05 | Trusted backend boundary and RLS bypass risks |

No directory is considered complete until its README, schema, policies, seeds, tests, and checklist evidence exist.
