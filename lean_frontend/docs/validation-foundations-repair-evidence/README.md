# Validation-foundations audit repair evidence

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
> directory (11 files; bytes derived from the source-branch blobs, total
> 224,447,237): `development.json` (6,214,196), `development.tar.zst` (5,694,662), `final-checkpoint.json` (2,268,783), `final-checkpoint.tar.gz` (7,134,217), `full.json` (21,611,945), `full.tar.zst` (80,376,450), `interrupted-full.json` (17,948,386), `interrupted-full.tar.zst` (74,842,295), `provider-failures.tar.zst` (3,182,296), `reporting.json` (4,367,857), `reporting.tar.zst` (806,150).
>
> Their SHA-256 identities are kept, line for line and unchanged, in
> [SHA256SUMS.dropped](SHA256SUMS.dropped). [SHA256SUMS](SHA256SUMS) lists
> present files only, so `sha256sum -c SHA256SUMS` passes in this directory.
> Each dropped line was checked against the source-branch blob before the
> split. The original bytes exist only on the local, never-pushed source
> branch `arc/validation-foundations` (head `d607409f9`) until it is pruned.
>
> This README's own line in `SHA256SUMS` was re-hashed after this note was added; the pre-note README hashed `0f2dd0cb55ddbbf6825e59176d2be676761c9ad388184f38f19965461cea12e0`.

> **Reconstruction.** Load the project environment first (`source scripts/env.sh`, or prefix each command with `scripts/ce`); run from the repo root; the checkpoints of record ran with `CERB_MEM_MAX=32G` and `DUNE_CACHE=disabled` (document-review record) — use the same. Commit column: source SHA on `arc/validation-foundations`, then the byte-identical replayed commit on the landing branch in parentheses. Reconstructed runs reproduce verdicts/classifications; timings, version-bearing artifact hashes and process identifiers differ, as the records themselves note. The retained `*-summary.json` files are the
> per-lane/per-row record of each dropped package ([full-summary.json](full-summary.json)
> with the report hash and 32 lanes; [reporting-summary.json](reporting-summary.json)
> with every C1/C4 row; [provider-summary.json](provider-summary.json);
> [final-checkpoint-summary.json](final-checkpoint-summary.json)), and
> [archive_evidence_zstd.py](archive_evidence_zstd.py) (retained) is the exact
> selection/verification/packaging script that produced the `.tar.zst` packages.
>
> | Package (dropped, with its `.json` inventory) | Commit | Recipe |
> |---|---|---|
> | `full`: the corrected primary's complete Tier A+B | `de9f6d361` (`8be462a89`) | `python3 scripts/release.py --mode full --out .validation-foundations/audit-repairs-20260906/full-functional-v2` (the recorded report path) |
> | `interrupted-full`: first full attempt, intentionally interrupted during B9 | `68de6771c` (`f545cb985`) | `release.py --mode full`, interrupted by design to test lost cancellation — an incomplete run, not a reconstruction target |
> | `reporting`: C1/C4 | `de9f6d361` (`8be462a89`) | `python3 scripts/release.py --mode reporting --lane C1 --lane C4 --out .validation-foundations/audit-repairs-20260906/reporting` |
> | `provider-failures` | `de9f6d361` (`8be462a89`) | `python3 scripts/build_provider_smoke.py --cerberus-rev "$(git rev-parse HEAD)" --lem-repo <lem-lean checkout> --out .validation-foundations/provider-cold`, then `python3 scripts/run_failure_probes.py --provider-manifest .validation-foundations/provider-cold/manifest.json --out .validation-foundations/failure-probes` and `python3 scripts/run_failure_census.py --provider-manifest .validation-foundations/provider-cold/manifest.json --out .validation-foundations/failure-census` ([provider record](../2026-09-06_provider-smoke.md), [census record](../2026-09-06_failure-census-and-correspondence.md)) |
> | `development`: fast gates + hermetic controls + first-audit reproductions | `68de6771c` (`f545cb985`), `de9f6d361` (`8be462a89`) | `release.py --mode fast` at each, plus the hermetic controls `scripts/test_unit.sh` runs (`test_observations.py`, `test_capture_prerequisites.py`, `test_release.py`, `test_failure_census.py`, `test_upstream_oracle_instrument.py`). The loose repair records/reproducers it carried are described in [the repair record](../2026-09-06_validation-foundations-audit-repairs.md); they are not re-derivable by one command |
> | `final-checkpoint` (`.tar.gz`): Tier A on the second-review checkpoint | `05278ae95` (`5317bc5ac`) | `python3 scripts/release.py --mode fast --out .validation-foundations/audit-repairs-20260906/final-checkpoint` |

2026-09-06 [AGENT]. Candidate prepared for a second review at the user's
request. See the [repair record](../2026-09-06_validation-foundations-audit-repairs.md).
Second-review acceptance, landing and customer adoption remain pending.

The measured functional primary is
`de9f6d3612232d581622afcdf0b23cdaf31fa09d` on `arc/validation-foundations`.
The Git commit carrying this final index is its documentation/evidence
checkpoint; the final Tier A snapshot is recorded separately. The private
instrument companion is `86a2aea547804b78eb7f1eae633bb9c24c713b7f` on
`arc/validation-foundations-concurrency`. It remains on the older feature
base and is not a mainline integration. Lem remains at `f6542f8`.

## Review entry points

- `summary.json`: repair/test mapping, source identities and result accounting.
- `full-summary.json`: the corrected primary's complete Tier A+B report.
- `reporting-summary.json`: every C1/C4 row, classifications and movement
  relative to the original candidate, with input hashes checked.
- `provider-summary.json`: cold build/proof, regenerated source checks,
  strictness observations and corrected compiler-range census.
- `census-replay-comparison.json`: 140 erroneous owners corrected, plus one
  valid outer owner refined to its nested helper; 30 execution flags removed.
- `functional-source-preservation-v2.json`, `gate-to-commit.json` and
  `signal-repair-gate-to-commit.json`: exact functional/pin/ancestry checks
  and the pre-commit gates bound to their committed source.
- [final-checkpoint-summary.json](final-checkpoint-summary.json): final Tier A
  **13/13**, 394.135 summed seconds; exact tested snapshot, 29 version-bearing
  artifact rebuilds and post-gate documentation/evidence publication, with the
  corresponding raw archive.
- [publication-summary.json](publication-summary.json): final source boundary,
  preserved historical evidence and local document-link checks.

- `provider-adoption.json`: refreshed source/package/proof manifest and explicit
  consumer ownership and remaining release obligations.

## Raw packages

Each `NAME.tar.zst` has a matching `NAME.json` inventory with every member's
original relative path, byte count and SHA-256. Every archived member was
read back and checked against its source hash. `SHA256SUMS` also hashes the
supplied archives, inventories, summaries and index.

| Package | Contents |
|---|---|
| `development` | Initial and signal-repair fast gates; targeted/hermetic controls; first-audit reproductions; real byte controls; all loose repair records and reproduction/package scripts, including the expected pre-fix cancellation failure. |
| `interrupted-full` | First full attempt at `68de6771c`: 29 passed commands, then intentionally interrupted during B9 to repair lost cancellation. Its status remains incomplete. |
| `full` | Complete corrected Tier A+B run at `de9f6d361`, every raw lane capture and all actual-entry/oracle plants. |
| `reporting` | Complete C1/C4 measurements and proposed outputs. Existing semantic baselines/scoreboards were not overwritten. |
| `provider-failures` | Every cold build/proof command/log, manifest and process-scope record; client source; fresh census and eight strictness probes; outer workflow command records. |

The final checkpoint's smaller raw package uses `.tar.gz` and has the same
per-file inventory convention (8,930 verified files). Its tested diff and
pre-publication metadata snapshots distinguish the gate's source from the
subsequent TODO reporting update and final evidence/result publication.
Executable source and all ladder commands remain unchanged. The private branch contains its own repair
and final-checkpoint archives, including its failed pre-launch scratch
attempt and corrected successful dispatch.

Raw archive members retain paths relative to the original owned checkout.
For example, inspect a package with `tar --zstd -tf full.tar.zst`, or extract
it into an owned scratch directory with `tar --zstd -xf full.tar.zst -C DIR`.
The supplied `archive_evidence_zstd.py` shows the selection/verification format;
its long-window compression preserves the large repetitive Cabs captures.

Cold `.git`, build products and dependency caches are excluded from the
archive. Their hashes are recorded and were checked against the retained
owned cold worktrees; source commits and the committed recipe allow a new
rebuild. Generated Lean/OCaml bytes match the original candidate, while
fresh compiler/runtime binary identity is measured independently.

The first-audit report and historical evidence archives are unchanged.
C2/C3 and the legacy run are outside this repair dispatch; the customer
checkout was not operated on. Reproduced strictness differences and existing
CI exclusions remain semantic/release obligations, not successful comparisons.
