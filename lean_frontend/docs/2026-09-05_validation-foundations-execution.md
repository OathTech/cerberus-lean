# Validation foundations — execution record

2026-09-05 [AGENT], under the operator's adopted
[charter](2026-09-05_validation-foundations-charter.md). Work in progress;
none of the charter goals is certified complete by this entry record.

## Entry and owned branches

[Entry manifest](validation-foundations-evidence/entry.json) records the
source heads and configuration. Cerberus mainline remains `89f7e6885`;
the primary `arc/validation-foundations` starts at planning commit
`6f17c8844`. The private concurrency branch starts at `086d8762d`.
Lem/compiler/runtime pins remain `f6542f8`. No other agent's worktree has
been changed. The legacy csmith run has not been monitored or operated.

## Current acceptance ledger

| Goal | State | Evidence still required |
|---|---|---|
| G1 observation contract and lanes | All six mainline lanes migrated; 27/27 actual entry-point plants pass | Additional caller inventory/migration, final ladder and affected reporting evidence |
| G2 concurrency instrument | Original statuses captured; full verdict-set parity and reference projection separated; 30 rows and sequential refusal passed; 26/26 integrated plants and original four-case probe pass | Final candidate report and portable commits |
| G3 independent oracle and fork pins | Upstream Lem compiler and OCaml libraries built and installed in an owned prefix | Pristine Cerberus comparisons, reproducible recipe, content pins and plants |
| G4 release runner and CI | Executable LADDER reader and actual CI entry; eight hermetic runner tests; first Tier A run passed 13/13 | Final Tier A+B, reporting, interruption hardening and final source/artifact records |
| G5 clean provider client | Not implemented; shared-switch install defect removed from owned build helper | Clean generation/build/client proof, pin and missing-artifact plants |
| G6 failure census/design | Not implemented | Current site census, probes, worked correspondence proposal |
| G7 profile/evidence | Entry recorded; reconciliation pending | Risk map, missing historical evidence accounting, current docs and final archive |

## Development checks (not candidate certification)

The primed worktree's initial `test_unit.sh` passed before instrument edits.
After their respective migrations:

- Minimal execution baseline: `total=106 match=85 ub_match=18`, three oracle
  skips, no other classifications; baseline unchanged.
- Multi-TU: two cases passed, including 31 ordered executions in `basic`.
- CN: 213 rows, 207 MATCH and six UB_MATCH; exact baseline unchanged.
- Verify: `127 passed, 0 failed (25 fixtures, 28 call points, 14 corpus
  fixtures, 21 corpus points)`. The older 117-check description is stale.
- Concurrency: 30 programs, zero engine disagreements, zero reference
  mismatches, zero sequential-leg failures under the repaired instrument.
- Shared codec: 11 test methods with byte/status/framing adversaries and
  actual subprocess capture; the updated historical extractor selftest passed.
- Mainline integration: 27/27 plants through the six actual entry points;
  concurrency integration: 26/26. The original CR-1 probe accepts its valid
  control and rejects all four abnormal engine pairs.
- First complete Tier A through `ci_lean.sh --mode fast`: 13/13 commands
  passed on 2026-09-06, source fingerprint unchanged. No baseline moved.
  This checks the initial implementation slice, not the final candidate.
  The [initial evidence archive](validation-foundations-evidence/initial-instruments.tar.gz)
  contains its report/logs/raw captures and the mainline integration plants.
  Paths inside the original reports are relative to this owned checkout;
  extract the archive here to restore the `.tmp/` paths. The archive's
  [checksum](validation-foundations-evidence/SHA256SUMS) identifies the bytes.

These were run at intermediate uncommitted source states. Retained logs are
under the owned worktrees' `.validation-foundations/`; raw engine captures
are under their `.tmp/scripts/observations/`. Final reports will identify
the final candidate and publish the relevant evidence with checksums.

## Instrument findings and routine decisions

- The existing `build_cerberus` helper installed `cerberus-lib` into the
  shared opam switch. The owned helper now installs into its own
  `_build/local-install`; engines retain their explicit build-tree runtime.
  Explicit Dune roots also avoid ancestor-directory traversal warnings.
- Verify discarded pipeline statuses and truncated call outcomes at the
  first line. It now compares complete, status-checked captures before
  projecting the committed call-point pin.
- CN previously called any pair of Error records REJECT_MATCH regardless
  of message/status. It now requires identical complete refusal observations.
  Current CN baseline has no such rows, so this introduces no baseline change.
- UB_DIFF remains a visible classification but is no longer described in
  agreement tallies as equal observations.
- GCC's first ten selected rows all compared successfully, but the lane
  then rejected all 12 triage entries outside that explicit selection.
  Subset runs now check selected triage entries; full release runs still
  require every entry. A subset report is explicitly not certification.
- The byte codec preserves the existing printer's observational limits:
  plain Error omits internal stderr, and the protocol lacks a total outcome
  count. See the [contract](2026-09-05_observation-contract.md); these are
  not claims of full-state equivalence.

## Pending next actions

Finish the caller/header inventory and older execution-harness migrations;
complete G3/G4 and the clean client, census/design and risk map. Keep the
charter's full G1–G7 scope and final decision package intact. First-slice
Tier A evidence does not discharge final-candidate validation obligations.
