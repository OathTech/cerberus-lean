# C4 re-review evidence — 2026-09-18

This is fresh reviewer evidence for `2f4898cf7803450965af785412ad657b25a08d6d`, branch `arc/address-space-bound-part-two`. The [audit](../2026-09-18_address-space-bound-part-two-audit-rereview.md) closes F1–F4 and records R1, the paired CLI acceptance mismatch.

The fast and B10 runs completed while the reviewed tree was clean and unchanged. These documentation files were added afterward. Implementation, baselines and branch history were not edited. The primary `mdd/cerberus-lean` checkout was also left unchanged.

## Contents and limits

- `release-summary.json`: selected fields from the fresh fast and B10 release reports, plus the implementer's historical full report. Includes source identities, command statuses, output hashes, report hashes and artifact issues. All 32 fresh fast, 4 fresh B10 and 78 historical full stdout/stderr hashes were checked against the original retained files.
- `fast-console.txt`, `tiny-lane.txt`, `tiny-selftest.txt`: 16/16 fast commands passed; 18 tiny-bound cases and 11 selftest plants/controls passed.
- `oracle-summary.json`, `oracle-console.txt`, `oracle-excerpt.txt`, `oracle-plants.txt`: fresh pristine-versus-fork oracle and plants. The excerpt keeps the witness rows and overall counts; it is not the entire 859-row transcript. B10-only selection is **not** a full release run. This oracle run has no Lean column; the tiny-bound lane separately compares Lean and fork.
- `cli_matrix.py`, `cli-matrix.txt`, `cli-results.json`: 33 paired CLI inputs and retained results. The script asserts full-codec agreement on ordinary valid inputs and records refusals/acceptances for the other spellings. It is an audit recorder: its exit status is not a gate for R1. It reports three unexpectedly accepted separator spellings on Lean.
- `zarith_parse.ml`, `zarith-parse.txt`: direct evaluation of the previous fork converter's parser, establishing that `Z.of_string "6_4"` succeeds.
- `eof_plants.py`, `eof-plants.txt`: eight independent checks against the exact current `check_expectations` function, including the valid unterminated-file control.
- `proof-assertion.lean`, `proof-recheck.txt`: the additional direct-production theorem assertion and the successful fresh re-elaboration transcript. The probe concatenated the entire unchanged current `FuelExemplar.lean` source with this assertion; it did not merely import the exemplar's existing compiled artifact. Compilation used the repository's pinned setup and memory cap.
- `old-body-identity.txt`, `old-allocator-probe.txt`: identity check against the pre-fix allocator and a fresh run of the committed old/fixed schedule probe. The address was executed; the C return value was derived, as explained in the audit.
- `baseline-check.txt`, `historical-full-integrity.txt`: unchanged original expectation rows/register signatures and the historical report integrity check. The approximately 80-minute full battery was **not** rerun by the reviewer.
- `source-and-binary-hashes.json`: identities of the reviewed inputs and executable binaries, including the full fresh proof probe.

The original full reports and raw per-case captures remain under the ignored `.tmp/audit-address-space-part-two-rereview/` directory in the reviewed worktree. These compact extracts are not substitutes for the full runner archives.

## Reproduction

From the reviewed repository root, use the project environment wrapper (absolute path shown for this workspace). The standard lanes build/check their required binaries. Choose unused release output directories when repeating these commands:

```sh
/home/dev/projects/cerberus-lean-proj/scripts/ce python3 scripts/release.py --mode fast --out .tmp/audit-rereview-repeat-fast
/home/dev/projects/cerberus-lean-proj/scripts/ce python3 scripts/release.py --mode full --lane B10 --out .tmp/audit-rereview-repeat-oracle

mkdir -p .tmp/audit-address-space-part-two-rereview
/home/dev/projects/cerberus-lean-proj/scripts/ce python3 lean_frontend/docs/2026-09-18_address-space-bound-part-two-rereview-evidence/cli_matrix.py
/home/dev/projects/cerberus-lean-proj/scripts/ce python3 lean_frontend/docs/2026-09-18_address-space-bound-part-two-rereview-evidence/eof_plants.py
/home/dev/projects/cerberus-lean-proj/scripts/ce opam exec --switch=. -- ocaml -noinit -I _opam/lib/zarith zarith.cma lean_frontend/docs/2026-09-18_address-space-bound-part-two-rereview-evidence/zarith_parse.ml
```

For the proof and old-body probes, start at the repository root, then use the package directory as required by `lean_probe.sh`:

```sh
mkdir -p lean_frontend/.tmp/audit-address-space-part-two-rereview
cat lean_frontend/test/Unit/FuelExemplar.lean lean_frontend/docs/2026-09-18_address-space-bound-part-two-rereview-evidence/proof-assertion.lean > lean_frontend/.tmp/audit-address-space-part-two-rereview/RecheckExemplar.lean
cp lean_frontend/docs/2026-09-17_address-space-bound-part-two-evidence/c4-old-allocator-probe.lean lean_frontend/.tmp/audit-address-space-part-two-rereview/OldAllocatorProbe.lean
cd lean_frontend
/home/dev/projects/cerberus-lean-proj/scripts/ce ../scripts/lean_probe.sh .tmp/audit-address-space-part-two-rereview/RecheckExemplar.lean
/home/dev/projects/cerberus-lean-proj/scripts/ce ../scripts/lean_probe.sh .tmp/audit-address-space-part-two-rereview/OldAllocatorProbe.lean
```

Rerunning after changing the grammar should remove the CLI discrepancy. The retained transcripts describe the reviewed head, not any later repairs.
