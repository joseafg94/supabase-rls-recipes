# Storage Security

Supabase Storage is a separate authorization surface. RLS on an application table does not automatically protect `storage.objects`, and a public bucket bypasses authenticated download controls by design.

## Model requirements

- Name the bucket and state whether it is public or private.
- Define a canonical object path, such as `<tenant_uuid>/<object_uuid>/<filename>`.
- Validate every security-relevant path segment against trusted database relationships; path text alone is not authority.
- Scope policies by `bucket_id` as well as owner or tenant.
- Define list, read/download, insert/upload, update/upsert, and delete separately.
- Decide whether object ownership (`owner_id`) or tenant membership controls access, and document service-created objects whose owner may be null.

## Mandatory cases

| Case | Expected result |
| --- | --- |
| Alice accesses authorized Alice/Org A path | Allow |
| Alice accesses Bob/Org B path | Deny |
| Bob accesses authorized Bob/Org B path | Allow |
| Anonymous accesses private object | Deny |
| Client forges authorized-looking foreign path | Deny |
| Upsert lacks any required operation policy | Deterministic denial documented |

## Public and signed delivery

Public buckets make object delivery public and should be selected only for intentionally public assets; object policies do not make public download URLs private. Signed URLs provide time-limited access but their issuance endpoint is itself an authorization boundary and must verify the caller.

## Operational rules

Use Storage APIs for object mutations. The `storage` schema is managed by Supabase; do not alter its tables or delete metadata directly. Custom indexes supporting policy predicates may be considered and measured during implementation.

## References

- [Storage access control](https://supabase.com/docs/guides/storage/security/access-control)
- [Storage ownership](https://supabase.com/docs/guides/storage/security/ownership)
- [Storage schema](https://supabase.com/docs/guides/storage/schema/design)
