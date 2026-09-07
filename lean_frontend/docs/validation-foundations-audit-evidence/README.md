# Validation foundations audit evidence

> **Landing note, 2026-09-06 [AGENT, orchestrator-directed].** The
> archives and large inventories listed below are NOT in the repository.
> They were dropped at the landing replay (`arc/validation-foundations-land`
> replays `arc/validation-foundations` commit by commit without them) under
> the operator ruling [USER 2026-09-06], verbatim:
>
> > "Agree on all points, and particularly on cleaning up the evidence
> > archives. These should not be git committed, and will not be pushed. I
> > don't actually hold strong value in such data which could be recreated,
> > so I am fine dropping large files like this. The important thing is
> > that runs can be reconstructed. Re ordering of concurrency, I think we
> > should stabilize the core semantics before this, so we should revert to
> > our previous ordering. Re master plan revisions dropping rulings - yes,
> > this should be retained."
>
> Drop rule: every `.tar.gz`/`.tar.zst` under `lean_frontend/docs/` and
> every file there of 1 MiB (1,048,576 bytes) or more. Dropped from this
> directory (3 files; bytes derived from the source-branch blobs, total
> 11,855,230): `audit.tar.gz` (6,652,112), `checkpoint-fast.tar.gz` (3,900,930), `checkpoint-files.json` (1,302,188).
>
> Their SHA-256 identities are kept, line for line and unchanged, in
> [SHA256SUMS.dropped](SHA256SUMS.dropped). [SHA256SUMS](SHA256SUMS) lists
> present files only, so `sha256sum -c SHA256SUMS` passes in this directory.
> Each dropped line was checked against the source-branch blob before the
> split. The original bytes exist only on the local, never-pushed source
> branch `arc/validation-foundations` (head `d607409f9`) until it is pruned.

> **Reconstruction.** Load the project environment first (`source scripts/env.sh`, or prefix each command with `scripts/ce`); run from the repo root; the checkpoints of record ran with `CERB_MEM_MAX=32G` and `DUNE_CACHE=disabled` (document-review record) — use the same. Commit column: source SHA on `arc/validation-foundations`, then the byte-identical replayed commit on the landing branch in parentheses. Reconstructed runs reproduce verdicts/classifications; timings, version-bearing artifact hashes and process identifiers differ, as the records themselves note. What is and is not re-derivable here:
>
> | Dropped | Commit | Recipe / disposition |
> |---|---|---|
> | `audit.tar.gz`: reviewer and coordinator reproducers, command records, raw observations, cold logs | subject `6d6cfa858` (`a192c1392`), functional `1066d89ee` (`4aa61a95e`) | Its complete member list with per-member SHA-256 is RETAINED in [audit-files.json](audit-files.json). The re-runnable parts: the 20 cold provider steps — `python3 scripts/build_provider_smoke.py --cerberus-rev "$(git rev-parse HEAD)" --lem-repo <lem-lean checkout> --out .validation-foundations/provider-cold`, then `python3 scripts/run_failure_probes.py --provider-manifest .validation-foundations/provider-cold/manifest.json --out .validation-foundations/failure-probes` and `python3 scripts/run_failure_census.py --provider-manifest .validation-foundations/provider-cold/manifest.json --out .validation-foundations/failure-census` ([provider record](../2026-09-06_provider-smoke.md), [census record](../2026-09-06_failure-census-and-correspondence.md)); the observation plants — `python3 scripts/test_observation_lanes.py --out .validation-foundations/premerge-audit-20260906/plants`. The reviewers' own scripts (`archive_audit.py`, `row-parser-probe-v1.sh`/`-v2.sh`, the coordinator checkers) existed ONLY inside this archive: their methods, controls and results are described in the four retained records ([observations.md](observations.md), [private-concurrency.md](private-concurrency.md), [release-oracle.md](release-oracle.md), [provider-docs.md](provider-docs.md)); the scripts themselves are not reconstructible from the repository |
> | `checkpoint-fast.tar.gz` + inventory `checkpoint-files.json`: the documentation Tier A checkpoint | `b1aa25796` (`f780a9570`) | `python3 scripts/release.py --mode fast --out .validation-foundations/premerge-audit-20260906/checkpoint-fast`; [checkpoint-summary.json](checkpoint-summary.json) (13/13, 429.371 s, report hash) is retained |

2026-09-06 [AGENT]. Evidence for the
[pre-merge audit](../2026-09-06_validation-foundations-premerge-audit.md).
**Result: HOLD; four P1 and seven P2 findings remain open.**
The subject primary is `6d6cfa858109a42561878db3d939024c5756ad4f`, private
`eb926f8d37187490c34a74bd4ffe74c80acdc77b`. These are audit measurements and
controlled instrument adversaries, not a corrected release candidate.

| Record | Contents |
|---|---|
| [observations.md](observations.md) | Fresh full primary codec/caller review, three P1 findings and controls. |
| [private-concurrency.md](private-concurrency.md) | Fresh full private instrumentation/reference review, shared P1 and three private P2 findings, source preservation. |
| [release-oracle.md](release-oracle.md) | Fresh release/oracle/pin review, process-tree and disappearing-inventory findings. |
| [provider-docs.md](provider-docs.md) | Fresh provider/proof/failure/core-document review and three P2 findings. |
| `audit.tar.gz` (dropped; identity in [SHA256SUMS.dropped](SHA256SUMS.dropped); members listed in [audit-files.json](audit-files.json)) | Reviewer and coordinator reproducers, command records, raw observations, cold logs/manifest/client and selected hash-verified historical inputs. |
| [audit-files.json](audit-files.json) | Every archived member's path, length and SHA-256. |
| [checkpoint-summary.json](checkpoint-summary.json) | Final documentation Tier A: 13/13 pass, 429.371 summed lane seconds; source/external inputs unchanged, no missing/lost artifact entries. |
| `checkpoint-fast.tar.gz` (dropped; identity in [SHA256SUMS.dropped](SHA256SUMS.dropped)) | All checkpoint lane logs/captures, before/after inventories and the exact tested document patch/bytes. |
| `checkpoint-files.json` (dropped, 1,302,188 bytes; identity in [SHA256SUMS.dropped](SHA256SUMS.dropped)) | Every checkpoint archive member's path, length and SHA-256. |
| [SHA256SUMS](SHA256SUMS) | Present-file hashes (inventory, reviewer copies, checkpoint summary); the dropped archive/inventory hashes are in [SHA256SUMS.dropped](SHA256SUMS.dropped). |

Extract `audit.tar.gz` into an owned primary checkout to restore paths under
`.validation-foundations/premerge-audit-20260906/`. Absolute command paths
identify the original workspace; adjust them when reproducing elsewhere.
The archived `archive_audit.py` documents selection and exclusions. Compiled
products, cold checkout trees, `.git` administration and Python caches are
excluded. The cold manifest records source, generated-file, compiler,
runtime, native-object and package hashes. Its three external client source
files and all 20 command log pairs are retained. Rebuild compiled products
from those pinned sources using the shipped cold recipe.

Fresh normal checks include all 20 cold provider steps, the immaculate lane
after removing its controlled override and rebuilding, all 30 private litmus
rows plus the sequential-refusal leg, the private whole-lane corruption/empty
plants and 26 supplied observation plants. The original four abnormal-status
plants, 13 codec tests, 11 runner tests, five oracle-instrument tests and
14 real content-gate plants also pass. These supplied tests miss the new
audit adversaries; their green status does not close the findings.

Coordinator confirmations are in `descendant-oom/`, `actual-exec-ubdiff/`,
`observations/entry-immaculate.*`, `coordinator-timeout-group/`,
`coordinator-missing-inventory/`, `coordinator-private/` and
`coordinator-census-verification.json`. The cold verification checked all
20 log pairs, 1,769 present artifact/tool hashes, and equality of all 207
generated Lean/86 OCaml files with the subject. Expected cold-only absence
of two release freshness stamps is explicitly recorded.

The first coordinator row-parser extraction omitted associative-array
declarations and was invalid; `concurrency/row-parser-probe-v1.sh` is retained
as superseded evidence. Use `row-parser-probe-v2.sh`, its v2 results and the
independent private review/coordinator controls. Two exploratory cold-checker
assertions used incorrect stamp/path assumptions; the final retained checker
and verification explicitly correct them. No subject code was changed to
make these measurements pass.

The historical 32-command A+B and C1/C4 reports are separately preserved in
the [delivery evidence](../validation-foundations-evidence/README.md).
This audit verifies those records and makes targeted new measurements; it
does not claim a newly run full A+B or reporting campaign. The legacy run,
C2/C3 and customer adoption remain outside this execution.

The final checkpoint archive retains 5,804 verified members, alongside the
audit archive's 4,038. Its passing Tier A result is a documentation checkpoint
over the audited functional code. Twenty-nine version/build/library/stamp
artifact entries changed while rebuilding; both inventories of 1,775 entries
are retained. After the test, only checkpoint result statements, archive
records and links were added. All audit findings remain open.
