# Public Read, Private Write

## Problem

This recipe exposes explicitly published content to everyone while limiting draft visibility and all mutations to the authenticated owner.

## Threat model

- **Assets:** unpublished content, publication state, and ownership integrity.
- **Actors:** anonymous readers, Alice, Bob, and a malicious authenticated non-owner.
- **Attacker goals:** read drafts, mutate public content, forge ownership, or expose another user's draft.
- **Controls:** a publication SELECT policy, owner SELECT/CRUD policies, least-privilege grants, and final-state tests.
- **Out of scope:** editorial teams, moderation, scheduled publishing, Storage, and privileged backends.

## Assumptions

`published = true` is the complete public-release decision. Owners may publish/unpublish only their own content. Supabase Auth supplies `auth.uid()` and no client-provided owner value is trusted without policy validation.

## Schema

`public_content_items` stores owner, title, publication flag, and timestamp. Owner lookups and the public published subset are indexed. RLS is enabled; `anon` receives SELECT only, while `authenticated` receives CRUD subject to policies.

## Authorization rules

| Actor | Command | Target | Expected | Reason |
| --- | --- | --- | --- | --- |
| Anonymous | SELECT | Published row | Allow | Public policy matches |
| Anonymous | SELECT | Draft | Empty | Public policy fails |
| Anonymous | Mutation | Any row | Permission denied | No write grants |
| Owner | SELECT | Own published/draft | Allow | Public OR owner policy |
| Owner | INSERT/UPDATE/DELETE | Own row | Allow | Ownership policy |
| Authenticated non-owner | SELECT | Published row | Allow | Public policy matches |
| Authenticated non-owner | Draft or mutation | Deny | Owner predicate fails |

## Policy explanation

Two permissive SELECT policies apply to `authenticated`: `published OR owner_id = auth.uid()`. This is intentional—signed-in users see all public rows plus their own drafts. Anonymous callers receive only the published branch. Mutation policies apply only to owners; INSERT and UPDATE use `WITH CHECK` so a client cannot forge or reassign `owner_id`.

The tests reason about the final OR condition, including public rows owned by another user and private rows that must remain hidden.

## Expected allow cases

- [x] Anonymous readers see the exact published set.
- [x] Alice and Bob see their drafts and mutate their own content.
- [x] Publishing a user's own draft changes anonymous visibility.

## Expected deny cases

- [x] Anonymous mutation attempts fail.
- [x] Drafts remain hidden from anonymous and other authenticated users.
- [x] Forged ownership, reassignment, and cross-owner mutations fail without state changes.

## Run locally

```sh
npm ci
npm run db:start
npm run db:reset
npx supabase test db recipes/public-read-private-write/tests.sql --local
npm run db:stop
```

## Common mistakes

- Using `USING (true)` for public reads and exposing drafts.
- Granting mutation privileges to `anon` even when no policy is intended.
- Forgetting that permissive SELECT policies combine with OR.
- Omitting `WITH CHECK` and allowing ownership reassignment.

## Limitations

Publication is a single Boolean without moderation, embargoes, audiences, soft deletion, or tenant scope. Public rows are intentionally visible to every reader.

## Production considerations

Define who may change publication state before adding editors, verify grants and policies together, preserve partial-index usefulness with measured queries, migrate changes from source control, and test the full effective SELECT condition whenever another public or owner policy is added.
