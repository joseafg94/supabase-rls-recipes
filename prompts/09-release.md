# Phase 09 — Release

## Objective

Prepare a traceable first open-source release after all quality gates pass.

## Allowed scope

Run release checks, finalize version/release notes, verify license/attribution, record test/audit evidence, and prepare repository metadata.

## Forbidden scope

No feature work, new recipes, policy redesign, production database changes, credential use, or bypassing a failed gate.

## Expected files

Release notes/changelog and minimal metadata updates required by the chosen hosting platform.

## Verification

Execute clean rebuild, full authorization suite, Storage tests, catalog checks, CI-equivalent job, link validation, license check, and secret/data scan; confirm known limitations are published.

## Completion criteria

Every item in `checklists/RELEASE_CHECKLIST.md` has linked evidence and no blocking security finding remains.

## Stop condition

If authorized to publish, create only the approved release/tag; otherwise stop with a release-ready report and exact manual next action.
