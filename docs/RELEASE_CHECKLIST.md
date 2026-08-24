# Release Gate Overview

A release is allowed only after the executable checklist in `checklists/RELEASE_CHECKLIST.md` is complete and linked evidence exists.

## Required gates

- All SQL rebuilds from clean local state and syntax is verified.
- Every recipe follows the standard and documents assumptions/limitations.
- Positive and negative matrices pass, including bidirectional tenant isolation.
- Storage authorization is tested for every Storage recipe operation.
- Catalog checks confirm intended grants, RLS flags, policies, and indexes.
- Documentation and behavior agree; links and cross-references resolve.
- No secrets, production identifiers, or proprietary data are present.
- Migration/drift and local reproduction workflows are current.
- Security review has no unresolved blocking finding.
- MIT license, attribution, release notes, and version identifier are present.

## Evidence

Archive CI run, local reproduction command set, test summary, security reviewer, known limitations, and source revision. Do not archive credentials or sensitive data.

## Stop rule

Any failed negative test, unexplained policy branch, or undocumented privileged path blocks release even when all positive flows work.
