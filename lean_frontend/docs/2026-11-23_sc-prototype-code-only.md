# SC prototype: code-only copy of `arc/sc-prototype`

This branch, `arc/sc-prototype-code`, is a copy of the failed SC prototype
branch `arc/sc-prototype` with evidence files removed, published on
2026-11-23 so that the prototype remains available as the quarry described in
`SC-CONCURRENCY.md` section 5 on `mdd/cerberus-lean`. The original branch was
not published and no longer exists after the retirement of the machine it was
developed on. [USER 2026-09-24] ruled the prototype failed; that standing is
unchanged.

The 30 commits were rebuilt one for one on the same base (`5407597d9`, on
`mdd/cerberus-lean`), with authors, dates and messages unchanged and two
changes to every tree:

- `lean_frontend/docs/2026-09-21_sc-prototype-evidence/` is removed. It held
  run evidence (up to 2,103 files and about 840 MB across the history) and had
  already been deleted before the pinned implementation commit.
- `tests/libc/libc.core` is held at the base version. The prototype
  regenerated it at 48 MB; the base file is 4 MB. Regenerate it from the
  prototype's sources if a prototype build is needed.

Nothing else differs: at the tip, the only difference from the original tree
is `tests/libc/libc.core`. Documents inside the branch that link to the
evidence directory now have dead links.

Because the trees changed, the commit hashes changed. Documents on the mainline
cite the original hashes; use this table to find them here.

| Original | Here | Date | Subject |
| --- | --- | --- | --- |
| `d8a1284bf` | `3e12b5a89` | 2026-09-21 | docs: charter faithful SC prototype and prepare long-cycle work |
| `4bba2b458` | `45edb60fe` | 2026-09-21 | Add passive memory observations and checked ND lifting for SC |
| `06681abd3` | `6c9339879` | 2026-09-22 | Add SC scheduling and occurrence-preserving execution protocol |
| `fb72dd9fb` | `47a58a369` | 2026-09-22 | Implement SC compare-exchange phases and preserve float representations |
| `7c2887012` | `6f2a211bb` | 2026-09-22 | Expose ordinary SC RMW phases and physical byte sources |
| `3864dbb1f` | `6288789c7` | 2026-09-22 | Make SC helper services resumable with typed failures |
| `8427b42e7` | `8f481250d` | 2026-09-22 | Record SC semantic boundaries and preserve complete source-order graphs |
| `efb39628c` | `9c3a3bdd5` | 2026-09-22 | Implement indivisible SC atomic updates and C lowering |
| `3f9705c9b` | `e7124276d` | 2026-09-23 | Implement SC atomic interfaces and preserve libc source locations |
| `f93530586` | `e2e4a64c6` | 2026-09-23 | Add lossless SC values and variadic metadata queries |
| `3c7173732` | `c99f0b3d6` | 2026-09-23 | Complete SC atomic argument interfaces and document configuration boundaries |
| `d0d41f4b2` | `76f49fb98` | 2026-09-23 | Retain SC call scopes and prefix obligations; repair Cmm equality selection |
| `0215b4f74` | `b9c2ed46c` | 2026-09-23 | test: pin the explicit directory filesystem coverage error |
| `4afc1877b` | `ab3877b66` | 2026-09-23 | Preserve checked filesystem faults and failure-time state |
| `d3d4825d9` | `b6766f0b0` | 2026-09-23 | Preserve spawned lexical owners and add lossless action/HB queries |
| `074c7348a` | `cd0408cc9` | 2026-09-23 | Record successful SC global bindings at the existing initializer update |
| `df6659ba8` | `ff1fec4ae` | 2026-09-23 | Add physical atomic-source and reference synchronization queries |
| `b6543c6a6` | `196c0e9c6` | 2026-09-24 | Consolidate SC pruning and delivery into one execution roadmap |
| `03f7c5f32` | `36d2a2f41` | 2026-09-24 | Clarify SC scheduling, reference coverage and consumer API obligations |
| `0e6947988` | `d2f757a50` | 2026-09-24 | Prune SC proof campaigns and consolidate operational tests |
| `8a350e2a1` | `b7b660917` | 2026-09-24 | Connect scalar SC candidate classification to public drivers |
| `86f49affa` | `09eab2647` | 2026-09-24 | Scope exhaustive SC exploration to very small C probes |
| `0f437971a` | `09cfd09f5` | 2026-09-24 | Interpret SC cursor conflicts, array elements and signed views |
| `307ac0d3e` | `b7c6d440b` | 2026-09-24 | Preserve ordered unspecified array initialization in SC projection |
| `fad4c0428` | `9aafc782a` | 2026-09-24 | Expose initialized whole-program SC continuations for consumers |
| `e5a6d6be9` | `14eab439b` | 2026-09-24 | Index SC occurrence ancestry without changing the relation |
| `601b6b9df` | `7f90409bc` | 2026-09-24 | Interpret whole SC values and compatible enum parameter reads |
| `69dfd52ed` | `f8631bfd0` | 2026-09-24 | Exercise SC prefix findings through faults and looping continuations |
| `631382a9d` | `05000ce68` | 2026-09-24 | Record ordered representation composition decision and concrete C probes |
| `4860f0ef0` | `ff982afae` | 2026-09-24 | docs: freeze SC prototype with independent review and migration inventory |

The pinned implementation `631382a9d` is `05000ce68` here, and the
documentation-only handoff `4860f0ef0` is `ff982afae`.

No build or test was run on the rebuilt commits.

[USER 2026-11-23] Publish the prototype as a stripped code-only branch.
