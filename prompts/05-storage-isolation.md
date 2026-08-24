# Phase 05 — Storage Isolation and Admin Boundary

## Objective

Implement Storage isolation and document/test the trusted backend boundary without presenting privileged access as RLS.

## Allowed scope

Create `recipes/storage-isolation/` and `recipes/admin-access/`; add minimal local fixtures needed to test Storage APIs and trusted-server separation.

## Forbidden scope

No public deployment, real bucket/data, frontend key handling, broad admin application, or use of `service_role` to make ordinary recipe tests pass.

## Expected files

Required recipe files; optional narrowly scoped Storage test script if SQL alone cannot exercise object semantics.

## Verification

Test Alice/Bob/anonymous paths, forged path and tenant values, list/read/upload/update-upsert/delete requirements, bucket scope, and server-only privileged behavior. Scan client-reachable files for privileged keys.

## Completion criteria

Storage matrix passes through relevant APIs; admin README clearly separates backend authorization, bypass behavior, and credential custody.

## Stop condition

Stop after both recipe checklists pass; do not expand privileged APIs.
