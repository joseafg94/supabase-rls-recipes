# Recipe Catalog

Each implemented recipe follows [the recipe standard](../docs/RECIPE_STANDARD.md) and remains independently reproducible.

| Recipe | Implementation phase | Focus |
| --- | --- | --- |
| [User-owned data](user-owned-data/README.md) | 02 | Ownership and per-command checks |
| [Organization membership](organization-membership/README.md) | 03 | Relationship-based tenant access |
| [Roles and permissions](roles-and-permissions/README.md) | 03 | Explicit owner/admin/member operations |
| [Public read/private write](public-read-private-write/README.md) | 03 | Published reads and authorized mutations |
| [Multi-tenant SaaS](multi-tenant-saas/README.md) | 04 | Flagship tenant-isolation system |
| [Storage isolation](storage-isolation/README.md) | 05 | Bucket/path/object authorization |
| [Admin access](admin-access/README.md) | 05 | Trusted backend boundary and RLS bypass risks |

No directory is considered complete until its README, schema, policies, seeds, tests, and checklist evidence exist.
