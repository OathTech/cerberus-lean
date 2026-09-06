# Validation-foundations audit repair evidence

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
