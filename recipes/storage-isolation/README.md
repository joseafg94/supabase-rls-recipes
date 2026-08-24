# Storage isolation

## Goal

Isolate private Storage objects by organization and owner while keeping authorization facts in database-controlled memberships.

## Threat model

An authenticated user may choose any bucket, object path, organization UUID, upload body, or upsert option. Anonymous callers and authenticated users from another organization are untrusted. The local setup key is trusted only for test fixture lifecycle.

## Actors and data

- Alice: `00000000-0000-4000-8000-000000000001`, member of Org A.
- Bob: `00000000-0000-4000-8000-000000000002`, member of Org B.
- Private bucket: `storage-recipe-private`.
- Object path: `<organization_id>/<owner_user_id>/<filename>`.

## Authorization rules

| Operation | Effective rule |
| --- | --- |
| List/read | Authenticated caller is a member of the organization in folder 1, folder 2 equals `auth.uid()`, and `owner_id` equals `auth.uid()` |
| Upload | Same bucket and path checks; membership must exist for the caller |
| Update/upsert | Existing row must satisfy the read-side rule and the resulting row must still satisfy the upload-side rule |
| Delete | Existing row must satisfy the read-side rule |

Every policy is restricted to `storage-recipe-private`. A valid-looking path in another bucket is not authorized.

## Why the path is not trusted

The organization UUID in a browser-provided path is only an input. The policy extracts it with `storage.foldername(name)` and verifies a normalized membership row controlled by the database. The owner folder and Storage `owner_id` provide separate checks, so copying Alice's organization or user UUID into a forged path does not grant access.

## Files

- `schema.sql` defines the membership relationship, grants, index, and RLS.
- `policies.sql` defines explicit Storage policies for each operation.
- `seed.sql` inserts fictional actors and memberships.
- `tests.sql` checks policy shape and direct membership isolation with pgTAP.
- `api-tests.mjs` exercises object behavior through the local Storage API.

## Run from a clean local stack

```sh
npm run db:start
npm run db:reset
npx supabase test db recipes/storage-isolation/tests.sql --local
npm run db:reset
node recipes/storage-isolation/api-tests.mjs
npm run db:stop
```

The API test obtains local-only credentials from `supabase status -o json` without printing or persisting them. Its privileged key is used only to create and remove test buckets and objects; Alice, Bob, and anonymous requests prove the authorization matrix.

## What the API matrix proves

The test covers private-bucket upload, list, download, update, upsert, and delete; both Alice and Bob; anonymous reads; cross-user requests; forged organization and owner folders; bucket scope; and an exact empty final object set. Upsert is intentionally checked because it requires `SELECT` and `UPDATE` in addition to `INSERT`.

## Assumptions and limitations

- The first two path segments remain organization and owner UUIDs.
- Object ownership is assigned by the authenticated Storage API request, not by direct SQL inserts.
- Membership administration is outside this recipe; ordinary actors can only read their own membership row.
- SQL tests cannot reproduce all Storage service semantics, so the object matrix runs through the API.
- Bucket MIME, size, rate, malware, retention, and lifecycle controls are production concerns outside this example.

## Production notes

Keep the bucket private, validate file constraints independently, index every relationship used by policies, and monitor denials and privileged operations. Never expose a secret or legacy `service_role` key to a browser. Privileged credentials bypass RLS and belong only in trusted server infrastructure.

## Official references

- [Storage access control](https://supabase.com/docs/guides/storage/security/access-control)
- [Storage schema design](https://supabase.com/docs/guides/storage/schema/design)
- [Storage helper functions](https://supabase.com/docs/guides/storage/schema/helper-functions)
- [Storage buckets](https://supabase.com/docs/guides/storage/buckets/fundamentals)
- [API keys and credential custody](https://supabase.com/docs/guides/api/api-keys)
