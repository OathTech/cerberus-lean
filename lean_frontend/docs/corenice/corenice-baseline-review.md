# CoreNice scope review

This records the planning review before implementation. The subsequent
[type-separation result and review](type-separation.md#validation-and-review)
cover the first implemented work package.

Reviewed scope/overview revision: `cc97a792f6b07801a5f6cfceb6824241e850fe8e`,
2026-11-14. [Individual step](corenice-baseline-scope.md),
[design](cerberus-nice-design.md), [roadmap](cerberus-nice-roadmap.md).

Both independent reviewers (`architecture_challenge`, `nice_m1_review`)
consider the proposal ready for bounded research execution, with no outstanding
findings. Their reviews were unrestricted and checked the pinned provider and
Lem sources. A separate source audit investigated the complete dependency and
generation boundary. No implementation or build was performed.

| Finding | Disposition |
|---|---|
| P2: a reported fuzz slice could satisfy completion even if almost all generated cases refused or exhausted limits. | Fixed: the post-pilot campaign manifest specifies completed defined cases, executed feature families, actual branching and both recording directions. Refusals/errors/limits cannot meet those targets. A shortfall is incomplete unless explicitly revised and reviewed. The reviewer confirmed the fix. |
| Clarification: sampled agreement alone does not substantiate an unchanged mechanical copy. | Added the initial source/generated comparison against the fixed originals, allowing only documented packaging/import changes. Residual differences must be fixed or explained, not normalized away. The reviewer confirmed the addition. |

The reviews support provider ownership, the complete target-dependent closure,
separate runtime parser/loaders, explicit shared frontend/services, bidirectional
tapes and actual lowering/reduction mutations. The overview documents now
match this scope; the old driver-only review is historical and is not carried
forward as evidence for the expanded path.

Remaining uncertainty is substantive implementation work: namespace packaging
has not been compiled; the full generated/support closure has not been built;
record/replay and the fuzz instrument do not yet exist; resource throughput is
unmeasured. The first work package tests generation, nominal type separation,
actual dependencies and handwritten/auxiliary bindings before broader work.
Neither review claims Core/CoreNice equivalence or guarantees the time estimate.

Validation of this documentation change: whitespace and local-link-target
checks. No proof build, repository-wide gate or differential campaign was run.
At that review, the documents were on `plan/cerberus-nice-restart` in the
cerberus-caesium parent repository. No implementation branch, provider source
change or dependency re-pin had been created, and nothing had been pushed.
The reviewed revision above belongs to that parent repository. This copy is
transported to the development clone with the repository-location/status edits
listed in [the integration entry point](README.md); it is not a new review of
an implementation or a successful build.
