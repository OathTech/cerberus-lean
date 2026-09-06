# Validation-foundations evidence

2026-09-06 [AGENT]. Start with the
[delivery record](../2026-09-06_validation-foundations-delivery.md) and its
G1–G7 acceptance table. These are identified measurements, not universal
conformance or customer-adoption evidence. Original relative paths are
preserved in archives; extract into an owned checkout to read the recorded
report/raw-capture paths. No legacy-run artifact is included.

| Evidence | Purpose |
|---|---|
| [final-full.tar.gz](final-full.tar.gz), [inventory](final-full.json), [summary](final-full-summary.json) | Complete 32/32 A+B on clean `1066d89ee`, all raw captures and before/after source/artifact manifests |
| [final-reporting.tar.gz](final-reporting.tar.gz), [inventory](final-reporting.json), [comparison](final-reporting-summary.json) | C1: 242 rows; C4: all 2,186 rows/15 suites, input hashes, fresh TSVs, all movements and raw outcomes; old default scoreboards unchanged |
| [final-provider-failures.tar.gz](final-provider-failures.tar.gz), [inventory](final-provider-failures.json), [summary](final-provider-summary.json) | Final unprimed compiler/runtime/build/proof and direct final strictness/census reproduction; rebuildable binaries identified by hashes |
| [provider-adoption.json](provider-adoption.json) | Provider pins, interface changes, theorem hypotheses and remaining customer/release exits |
| [provider-evidence-comparison.json](provider-evidence-comparison.json) | Development/final source comparison and direct final reproduction, without assuming identical compiler binaries |
| [final-branch-map.json](final-branch-map.json) | Bases, functional commits, private instrument scope and shared-file identity |
| [final-checkpoint-fast.tar.gz](final-checkpoint-fast.tar.gz), [inventory](final-checkpoint-fast.json), [source record](final-checkpoint-source.json) | Required Tier A on the final documentation/evidence checkpoint; exact tested source retained |

Development archives remain separately identified: `initial-instruments`,
`expanded-instruments`, `provider-failures-development`,
`foundations-development-fast`, the failed `first-full-candidate`,
`capture-repairs-development` (failed and repaired focused attempts), and
`capture-repair-fast`. See the [execution history](../2026-09-05_validation-foundations-execution.md)
and [capture repair record](../2026-09-06_capture-composition-repair.md).
The private concurrency branch has its own evidence and candidate manifests
at `eb926f8d`; those archives are committed there.

[SHA256SUMS](SHA256SUMS) covers archives and their inventories plus final
machine-readable summaries. Per-file inventories allow checking extracted
raw bytes. The separate historical audit archive retains its original
checksums and explicitly lists twelve missing logs; this archive does not
reconstruct or relabel those historical runs.
