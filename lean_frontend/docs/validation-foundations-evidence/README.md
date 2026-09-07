# Validation-foundations evidence

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
> directory (14 files; bytes derived from the source-branch blobs, total
> 161,123,767): `capture-repair-fast.tar.gz` (4,018,753), `capture-repairs-development.tar.gz` (11,846,509), `expanded-instruments.tar.gz` (40,092,033), `final-checkpoint-fast.json` (1,210,388), `final-checkpoint-fast.tar.gz` (4,034,055), `final-full.json` (14,286,343), `final-full.tar.gz` (37,821,363), `final-provider-failures.tar.gz` (659,838), `final-reporting.json` (3,430,809), `final-reporting.tar.gz` (1,513,416), `first-full-candidate.tar.gz` (37,051,845), `foundations-development-fast.tar.gz` (3,940,044), `initial-instruments.tar.gz` (564,305), `provider-failures-development.tar.gz` (654,066).
>
> Their SHA-256 identities are kept, line for line and unchanged, in
> [SHA256SUMS.dropped](SHA256SUMS.dropped). [SHA256SUMS](SHA256SUMS) lists
> present files only, so `sha256sum -c SHA256SUMS` passes in this directory.
> Each dropped line was checked against the source-branch blob before the
> split. The original bytes exist only on the local, never-pushed source
> branch `arc/validation-foundations` (head `d607409f9`) until it is pruned.

> **Reconstruction.** Each archive was the raw output of one runner
> invocation at one commit. Load the project environment first (`source scripts/env.sh`, or prefix each command with `scripts/ce`); run from the repo root; the checkpoints of record ran with `CERB_MEM_MAX=32G` and `DUNE_CACHE=disabled` (document-review record) — use the same. Commit column: source SHA on `arc/validation-foundations`, then the byte-identical replayed commit on the landing branch in parentheses. Reconstructed runs reproduce verdicts/classifications; timings, version-bearing artifact hashes and process identifiers differ, as the records themselves note.
>
> | Archive (dropped) | Commit | Recipe |
> |---|---|---|
> | `final-full` (+ inventory `final-full.json`): the 32/32 Tier A+B run | functional `1066d89ee` (`4aa61a95e`) | `python3 scripts/release.py --mode full --out .validation-foundations/final-full` — raw captures land in `<out>/<lane>/observations` (the runner sets `CERB_OBSERVATION_DIR`); [final-full-summary.json](final-full-summary.json) is the retained per-lane summary with the report hash |
> | `final-reporting` (+ `final-reporting.json`): C1/C4 | `1066d89ee` (`4aa61a95e`) | `python3 scripts/release.py --mode reporting --lane C1 --lane C4 --out .validation-foundations/final-reporting`; [final-reporting-summary.json](final-reporting-summary.json) retains every row; [reporting-inputs.json](reporting-inputs.json) the input hashes |
> | `final-provider-failures` | `1066d89ee` (`4aa61a95e`) | `python3 scripts/build_provider_smoke.py --cerberus-rev "$(git rev-parse HEAD)" --lem-repo <lem-lean checkout> --out .validation-foundations/provider-cold`, then `python3 scripts/run_failure_probes.py --provider-manifest .validation-foundations/provider-cold/manifest.json --out .validation-foundations/failure-probes` and `python3 scripts/run_failure_census.py --provider-manifest .validation-foundations/provider-cold/manifest.json --out .validation-foundations/failure-census` ([provider record](../2026-09-06_provider-smoke.md), [census record](../2026-09-06_failure-census-and-correspondence.md)); [final-provider-failures.json](final-provider-failures.json) (inventory) and [final-provider-summary.json](final-provider-summary.json) are retained |
> | `final-checkpoint-fast` (+ `final-checkpoint-fast.json`): Tier A on the documentation checkpoint | `6d6cfa858` (`a192c1392`), parent `1066d89ee` | `python3 scripts/release.py --mode fast --out .validation-foundations/final-checkpoint-fast`; [final-checkpoint-source.json](final-checkpoint-source.json) is retained |
> | `initial-instruments` | `e0fc7ad34` (`43b2a75dd`) | `bash scripts/ci_lean.sh --mode fast` (= `release.py --mode fast`); the run is described in [the execution record](../2026-09-05_validation-foundations-execution.md) |
> | `expanded-instruments` | `5d2f380de` (`bc2a1a278`) | `release.py --mode fast` plus the independent-oracle build: `python3 scripts/build_independent_oracle.py --lem-repo <lem-lean checkout> --cerberus-repo <cerberus-lean checkout> --out .validation-foundations/independent-oracle-v2`, then `python3 scripts/test_upstream_oracle.py` and `python3 scripts/test_upstream_oracle.py --plant` ([record](../2026-09-06_independent-oracle-and-fork-pins.md)) |
> | `provider-failures-development`, `foundations-development-fast` | `5c28b3b24` (`7347d2acb`) | the provider/probe/census recipe above (inventory [provider-failures-development.json](provider-failures-development.json) retained); `release.py --mode fast` ([foundations-development-source.json](foundations-development-source.json) retained) |
> | `first-full-candidate` (the FAILED first full run), `capture-repairs-development`, `capture-repair-fast` | introduced at `1066d89ee` (`4aa61a95e`); the failed run was on the pre-repair source (its patch was inside the archive) | `release.py --mode full` at the pre-repair commit `5c28b3b24` (`7347d2acb`) reproduces the failure class described in [the capture repair record](../2026-09-06_capture-composition-repair.md); `release.py --mode fast` at `1066d89ee` for the repaired fast run ([capture-repair-fast-source.json](capture-repair-fast-source.json) retained) |

2026-09-06 [AGENT]. Start with the
[delivery record](../2026-09-06_validation-foundations-delivery.md) and its
G1–G7 acceptance table. These are identified measurements, not universal
conformance or customer-adoption evidence. Original relative paths are
preserved in archives; extract into an owned checkout to read the recorded
report/raw-capture paths. No legacy-run artifact is included.

| Evidence | Purpose |
|---|---|
| `final-full.tar.gz` + inventory `final-full.json` (dropped; identities in [SHA256SUMS.dropped](SHA256SUMS.dropped)), [summary](final-full-summary.json) | Complete 32/32 A+B on clean `1066d89ee`, all raw captures and before/after source/artifact manifests |
| `final-reporting.tar.gz` + inventory `final-reporting.json` (dropped; identities in [SHA256SUMS.dropped](SHA256SUMS.dropped)), [comparison](final-reporting-summary.json) | C1: 242 rows; C4: all 2,186 rows/15 suites, input hashes, fresh TSVs, all movements and raw outcomes; old default scoreboards unchanged |
| `final-provider-failures.tar.gz` (dropped; identity in [SHA256SUMS.dropped](SHA256SUMS.dropped)), [inventory](final-provider-failures.json), [summary](final-provider-summary.json) | Final unprimed compiler/runtime/build/proof and direct final strictness/census reproduction; rebuildable binaries identified by hashes |
| [provider-adoption.json](provider-adoption.json) | Provider pins, interface changes, theorem hypotheses and remaining customer/release exits |
| [provider-evidence-comparison.json](provider-evidence-comparison.json) | Development/final source comparison and direct final reproduction, without assuming identical compiler binaries |
| [final-branch-map.json](final-branch-map.json) | Bases, functional commits, private instrument scope and shared-file identity |
| `final-checkpoint-fast.tar.gz` + inventory `final-checkpoint-fast.json` (dropped; identities in [SHA256SUMS.dropped](SHA256SUMS.dropped)), [source record](final-checkpoint-source.json) | Required Tier A on the final documentation/evidence checkpoint; exact tested source retained |

Development archives remain separately identified: `initial-instruments`,
`expanded-instruments`, `provider-failures-development`,
`foundations-development-fast`, the failed `first-full-candidate`,
`capture-repairs-development` (failed and repaired focused attempts), and
`capture-repair-fast`. See the [execution history](../2026-09-05_validation-foundations-execution.md)
and [capture repair record](../2026-09-06_capture-composition-repair.md).
The private concurrency branch has its own evidence and candidate manifests
at `eb926f8d`; those archives are committed there.

[SHA256SUMS](SHA256SUMS) covers the present inventories and final
machine-readable summaries; [SHA256SUMS.dropped](SHA256SUMS.dropped) covers
the dropped archives and inventories (landing note above). Per-file inventories allow checking extracted
raw bytes. The separate historical audit archive retains its original
checksums and explicitly lists twelve missing logs; this archive does not
reconstruct or relabel those historical runs.
