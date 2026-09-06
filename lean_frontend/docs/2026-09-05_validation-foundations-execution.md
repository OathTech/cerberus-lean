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
| G1 observation contract and lanes | Six required lanes and older callers migrated; 67 actual entry-point plants pass across development runs; complete caller inventory | Final combined plants, ladder and affected reporting evidence |
| G2 concurrency instrument | Committed at `51b855aec`; 14/14 Tier A, 30 rows plus sequential refusal, 26/26 integrated plants and original four-case probe pass; portable source/evidence archive | Include exact branch/source map in final discussion package |
| G3 independent oracle and fork pins | Cold upstream-Lem/pristine-Cerberus recipe and 723 comparisons pass; public OCaml client passes; 76 source pins and 14 plants pass | Final-candidate rerun |
| G4 release runner and CI | Executable LADDER/CI entry; eleven runner tests including signals and missing inventories; external input/artifact identities; initial and expanded Tier A passed 13/13 | Final Tier A+B, reporting and final source/artifact records |
| G5 clean provider client | Cold provider rehearsal passes both targets, all three Lake packages, real-entry/map-law client and standalone Lem runtime/comprehensive; omitted-generation and pin plants pass | Final-candidate rehearsal/archive and adoption manifest |
| G6 failure census/design | Cold census identifies 1,642/1,644 sites; seven memory-monad sites confirmed and generated counts corrected; eight strictness probes measured; correspondence proposal written | Final evidence/archive and operator design discussion |
| G7 profile/evidence | Profile/defect ledger and next charter drafted; current overview/TODO claims corrected; 10 historical artifacts match and 12 logs explicitly missing | Final candidate reports, archive, clean commit series and discussion package |

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

Archive the completed release hardening, clean client, census/design
and risk map, then run final-candidate validation and reporting. Keep the
charter's full G1–G7 scope and final decision package intact. First-slice
Tier A evidence does not discharge final-candidate validation obligations.

## Expanded observation and independent-oracle checkpoint

2026-09-06 [AGENT]. At the uncommitted source fingerprint recorded in
`release-expanded-fast/report.json`, all 13 Tier A commands passed again
through the actual CI entry, with source unchanged and no baseline edits.
The complete independent-oracle lane and its actual-engine difference plant
both passed at the same source state. Its 723 rows comprise 709 semantic
agreements, two CLI agreements, eleven matching frontend failures and one
reviewed, content-pinned diagnostic difference. Both public OCaml package
clients print `42`. The independently compiled pristine engine was produced
by the corrected cold v2 recipe, without fork Lem or shared installation.
See [the G3 record](2026-09-06_independent-oracle-and-fork-pins.md) for
applicability limits and the reviewed diagnostic projections.

The ten additional observation callers contribute 40 passing plants across
the initial run and the corrected fixture rerun. Seven initial test-fixture
failures were resolved: one oracle override missed the bytes bridge, one
byte mutation missed nonempty stdout, and five validators failed to recognize
the family's correct disagreement message. All seven affected lanes were
rerun (28/28); the other three lanes had passed initially (12/12). The
final candidate must run all 67 mainline plants together. The fork gate's
14 plants and five independent-oracle instrument test methods also pass.

The expanded evidence archive contains both older-caller runs, both runner
reports and raw observations, cold-build logs/manifest, and fork-plant logs.
Build trees and binaries are excluded; their hashes and rebuilding recipe
are retained. This is development evidence, not full charter acceptance.

## Cold provider, failure evidence and profile checkpoint

2026-09-06 [AGENT]. The cold provider rehearsal completed from semantic
revision `5d2f380de` with local Lem `f6542f8`, without inherited Cerberus
generated files, native objects or Lake build products. Both targets, all
three Lake packages, the external consumer proof, standalone Lem runtime
and comprehensive suite pass. Existing expected failures remain explicit.
See [the recipe and proof scope](2026-09-06_provider-smoke.md).

The strictness probe measured five forms that fail in OCaml but return 1 in
both Lean execution modes. A mapped-singleton projection fails natively
but its kernel value equation erases the failure. Positive and required-
failure controls behaved as intended. All six counterexample equations have
empty axiom cones. The cold dependency/census instrument confirms 128
handwritten plus 1,516 generated occurrences (copied seams excluded), with
263 whole-tree monadic ascriptions and 77 in the older table's nine modules.
The [census/design record](2026-09-06_failure-census-and-correspondence.md)
separates those counts from actual C/API reachability and the eight fuel
obligations. No broad failure transform is implemented.

The release runner now preserves interrupted/unrun state, records active
process groups and external input identities, and distinguishes a completed
non-gating discrepancy report from a green semantic gate. The documented
CI sweep lacked its mandatory suite selection; `--all-suites` now selects
the 15 registered suites explicitly. Eleven runner tests pass, including
SIGTERM/SIGKILL, a failure after a claimed completion marker, missing inputs,
timeout, source movement and incomplete reporting artifacts. SIGKILL cannot
be caught: its durable report remains running/incomplete with the active
process group identified; no pass is published. Normal interrupt/timeout
cleanup addresses the lane's process group, including descendants that
outlive the shell. Detached daemon processes are outside the lane contract.

Historical archive accounting found ten original artifacts matching their
hashes and twelve missing logs. Original README/checksums remain historical
files; the current inventory/checksum list covers available artifacts and
labels missing originals. The documented producer directories were absent;
the excluded legacy worktree was not inspected. Overview, fuel TODO and
master-plan claims now reflect the supported profile and corrected census.

The private concurrency candidate's first expanded Tier A run passed 13 of
14 lanes, including 30 litmus rows; unit failed on its older fork-manifest
locale defect. The already-landed P0 fork instrument was ported from
`aa5fc06c4`, with local fresh generation validating the compiler metadata
correction to f6542f8 and all existing 23 generated-delta hashes unchanged.
Its unit gate then passed (72 manifested source paths). This is an instrument
port, not a C4/mainline semantic rebase: the feature retains its own older
83-worker fuel inventory. Final private-candidate rerun is recorded separately.

## Advance justification for finite reporting measurements

2026-09-06 [AGENT], before dispatch. Charter G4 authorizes affected C1 and
C4 reporting evidence, including a finite measurement exceeding one hour
when justified by corpus size and per-row limits. The
[hashed input inventory](validation-foundations-evidence/reporting-inputs.json)
contains 2,186 selected C4 files across all 15 registered suites; it applies
the script's syntax-only/exhaust exclusions. C1 selects the same 242
`tests/ci` files in its nolibc lane. These are the committed finite CI
corpora, with no csmith campaign or legacy worktree activity.

C4's published limit is 15 seconds for each of oracle execution, Cabs
bridge and Lean execution, giving a conservative 98,370 seconds across
2,186 rows if every row reaches all three limits. Authorize a 100,800-second
(28-hour) outer measurement ceiling, including ordinary per-row overhead.
C1's 30-second limits give 21,780 seconds for 242 three-phase rows; its
outer measurement ceiling is 25,200 seconds (7 hours). These are bounds,
not expected runtimes or permission to increase per-row resource budgets.
The already validated build steps remain under the ordinary build/proof
tripwire; no extended build or proof search is authorized. One heavy job
runs at a time, and progress/status is reported during either sweep.

Use the release runner's reporting mode, separate new output directories,
and explicit C1/C4 selections. Preserve proposed baseline/scoreboard rows
in the evidence directory; do not update committed baselines automatically.
A complete measurement may contain discrepancies. It is reporting evidence,
not a green semantic comparison or complete release certification. C2/C3
remain unrun under the legacy-run ownership restriction.

The [provider/failure development archive](validation-foundations-evidence/provider-failures-development.tar.gz)
and its [file inventory](validation-foundations-evidence/provider-failures-development.json)
retain the cold build commands/manifests, external client source, generated
strictness probes and raw runs, and cold census source/range evidence.
Compiled products are excluded with hashes retained in the original
manifests. Archive checksums are in the evidence directory's `SHA256SUMS`.

## Foundations development checkpoint

The actual CI entry completed all 13 Tier A commands again, with source and
external inputs unchanged. The
[runner archive](validation-foundations-evidence/foundations-development-fast.tar.gz)
retains the report, logs and raw captures; the
[source manifest](validation-foundations-evidence/foundations-development-source.json)
identifies the tested changed source bytes. Only evidence and documentation
were added afterward for this checkpoint. No baseline changed. Final Tier
A+B and the authorized reporting measurements are still required.

The private concurrency instrument is committed at
`51b855aeca1ab10a3de8eccb07dc2a02d67300a4`, with a clean owned worktree. Its
record is `lean_frontend/docs/2026-09-06_validation-foundations-concurrency.md`
on that branch. All 14 private Tier A commands pass, with 30 individual
litmus matches and the sequential refusal. Its archived 26 integrated plants
and four-case CR-1 probe also pass. Its candidate manifest proves the shared
codec files are byte-identical to primary commit `5d2f380de`; its additional
P0 port preserves all 23 generated delta hashes and the 72-path manifest.
This is a validated instrument series, with no full feature rebase/landing.

Review also identified an inherited reporting omission: CI TSVs record
`LEAN_FUEL`, but the per-suite summary omits that counter. The next small
instrument change will include it and extend the existing fuel plant to
check the summary before final full/reporting validation.
