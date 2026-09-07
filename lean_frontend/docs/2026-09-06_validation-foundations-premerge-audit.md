# Validation foundations — pre-merge audit

2026-09-06 [AGENT]. **HOLD: the audited candidates are not ready to merge.**
The agreed six-area fresh audit found **four P1 and seven P2 findings**.
The ordinary supplied checks pass, but independent plants demonstrate false
agreement, incomplete process cleanup and inaccurate evidence attribution.
G1, G2, G4, G6 and G7 need correction and renewed acceptance. G3 and G5 remain
supported within their documented scope. No functional fix, baseline change,
merge, push or customer adoption is included in this audit.

The [delivery record](2026-09-06_validation-foundations-delivery.md) remains
the dated account of what was delivered and measured. This report supersedes
its readiness assessment and recommendation to proceed directly to SC work.
The following severities and recommended repairs are agent judgments; they
are not additional user rulings.

## Subjects, ownership and coverage

| Subject | Frozen revision |
|---|---|
| Primary `arc/validation-foundations` | `6d6cfa858109a42561878db3d939024c5756ad4f` |
| Last functional primary change | `1066d89eea16f55a0f204f95c351731629df296a` |
| Assessed Cerberus mainline | `89f7e688530c6910884518811d645e4e892e4507` |
| Private `arc/validation-foundations-concurrency` | `eb926f8d37187490c34a74bd4ffe74c80acdc77b` |
| Original feature base | `086d8762d382eff375c101f5f0c64d3ffe9bccc7` |
| Lem mainline/compiler/runtime/package pin | `f6542f8e6860d12d4655e6648bc4c45dabd1d798` |

Three fresh reviewers covered the complete assigned implementations and core
documents. The coordinator read the reports/source and independently
reproduced the blocking instrument failures and census result. Work ran in
owned worktrees and audit scratch, with one heavy job at a time and capped
Lean/Lake. The legacy csmith run and its worktree/logs, refined-cerberus, and
the original feature worktree were left alone. Private preservation checks
read immutable Git objects through the owned private checkout.

| Agreed audit area | Review and independent evidence |
|---|---|
| 1. Observations and callers | Full codec/helper and all migrated callers; all 27 changed shell files syntax-checked; 13 codec tests; byte/framing/order controls; actual cap/exec/immaculate reproductions. Findings VF-01–03. |
| 2. Independent oracle and pins | Full builder/instrument/applicability review; 76 content/mode pins and unchanged 22 generated deltas checked; 14 fork plants; five oracle-instrument tests; prepared build manifest and pristine source archive hashes independently verified. No new finding in this bounded reference surface. |
| 3. Release and CI | Full LADDER/CI/runner and archived reporting review; 11 supplied tests; actual runner with nested GNU timeout and actual inventory with disappearing fixture resources. Findings VF-04–05. |
| 4. Cold provider and proof | New unprimed build at exact primary HEAD; all 20 steps pass. Actual entry/completion and map-law hypotheses reviewed; 1,769 present file/tool hashes and all command logs checked. No new G5 finding. |
| 5. Private concurrency instrument | Full private helpers/reference readers and 18-path delta; 72-path/23-generated-delta manifest preserved; 30-row corpus/reference bijection checked; source preservation, original status probe, supplied plants and new adversaries. Findings VF-01 and VF-09–11. |
| 6. Failure account and fresh core-doc review | Full master plan, profile, failure proposal, charter, delivery/execution and core overviews; provider/failure archive hashes checked; census rerun and compiler-range cross-check. Findings VF-06–08. |

The [evidence index](validation-foundations-audit-evidence/README.md) gives
reviewer reports, exact commands, raw captures, source hashes and archive
inventories. Paths below are relative to the extracted audit evidence root.

## Findings requiring repair

### VF-01 — P1: successful status can hide a confirmed descendant OOM

`scripts/observations.py:139,165` recognizes `capped: OOM-KILLED` but misses
the other positive witness emitted by `scripts/capped:76–78`:
`capped: OOM event recorded in cgroup ... though the command exited rc=0`.
A parent can return a valid Defined/status-0 record after its child was
killed. The codec reports a complete observation and accepts agreement.

The coordinator ran the actual shipped cap at 128M around an owned Python
parent whose 256MiB child was killed with status -9. The parent waited for
its child, returned 0, and the real positive cap diagnostic was accepted by
the real codec. This establishes wrapper/codec composition, without claiming
that a tested C program launches that child. It affects both candidates.

**Repair:** reject every positive cap witness before any policy exception,
regardless of direct-command status; share the witness protocol with native
classification. Require a composed descendant-OOM plant and ordinary
diagnostic/semantic-payload controls. Evidence: `descendant-oom/`,
`reproduce_descendant_oom.py`, reviewer O3 in `observations/REPORT.md`.

### VF-02 — P1: immaculate's crash exception accepts fuel failure and malformed output

`scripts/test_immaculate.sh:105–108` classifies broad 125/134 panic forms as
CRASH before the codec's fuel, framing and narrow failure checks. Eight
baseline rows expect `MATCH | L=CRASH`. Replacing only the Lean result for
`g2-memcmp-uninit` with a fuel-exhaustion panic preserves that baseline.

The **whole unmodified lane** exited 0 and printed MATCH for that planted
row. All other engine calls delegated to the real executables. A subsequent
whole healthy lane, without the override and with normal rebuild, passed.
Production-helper controls also accept garbage stdout and an unrelated
panic; a valid batch prefix correctly rejects. Coarse historical crash pins
are already declared; bypassing failure validation is the defect.

**Repair:** validate resource, fuel and framing conditions before projecting
to CRASH; encode any additional reviewed crash grammar centrally. Plant the
actual pinned-crash path. Evidence: `observations/entry-immaculate.*`,
`observations/entry-immaculate-raw/`, `immaculate-healthy.*`,
`immaculate-command-record.json`; reviewer O1.

### VF-03 — P1: UB differences can yield exit 0 and a 100% agreement headline

`scripts/test_exec.sh:754–760,824–829,973–985` increments UB_CODE_DIFF without
making default mode fail. Its comparison denominator also omits those rows.
An actual-entry controlled run with one MATCH and one UB-location difference
reports `ub_diff=1`, **100%**, and status 0. A supplied baseline containing
only the healthy control also accepts the new UB_DIFF row as nonfatal
(`:917–924`). Both engines, captures and the real codec/control flow were
used through loud instrument overrides.

A fixed MATCH/UB_MATCH baseline moving to UB_DIFF does fail the rank check;
this is not evidence that the existing fixed Tier A baseline silently
accepts that movement. The defect affects default comparison, its headline,
and the new-row baseline policy.

**Repair:** include every compared difference in the denominator and fail
default mode for UB_DIFF; make new-row/baseline policy explicit and test it.
Require mixed and all-UB_DIFF controls. Evidence: `actual-exec-ubdiff/`,
`reproduce_exec_ubdiff.py`; reviewer O2.

### VF-04 — P1: release cancellation leaves ordinary nested timeout work running

`scripts/release.py:221–230,274–285` stops only the original lane process
group. GNU `timeout`, used by normal lanes, creates another group. The
actual runner times out a synthetic lane containing `timeout 30 ... sleep
30`, records it incomplete, and leaves the nested child running. Both the
reviewer and coordinator reproduced this; each explicitly killed its owned
descendant group afterward and verified that no running child remained.

The runner may then start another lane, allowing overlapping heavy work and
late artifact/log writes. No malicious daemon or TERM-resistant process is
needed. There is no evidence that the historical completed full run orphaned
work; the cancellation guarantee itself is false.

**Repair:** contain and terminate the complete lane process tree, including
nested process groups, before finalization or further dispatch. Plant a real
nested timeout and a capped descendant, checking descendants as well as the
leader. Evidence: `coordinator-timeout-group/`,
`release-oracle/reproduce_timeout_group.py`; reviewer F1.

### VF-05 — P2: disappearing required artifacts can still produce a passing release

`scripts/release.py:149–155,198–199,369–383` dynamically enumerates existing
runtime/library/native files. Missing trees disappear from the inventory;
final checks do not reject lost keys. The actual runner/inventory, in an
isolated Git fixture, returned `passed`, exit 0 and no artifact issues after
its final lane deleted staged libc, library and native-object resources.
Only fixture discovery/tool lookup was controlled; inventory logic was real.

The normal pre-build libc guard does not cover disappearance after the last
lane. The historical final full report has **no lost before/after entries**;
this is a runner defect, not a claim of missing historical resources.

**Repair:** inventory and require mandatory roots/resources even when absent,
and distinguish documented rebuild changes from lost entries. Plant actual
file removal, rather than mocking the inventory validator. Evidence:
`coordinator-missing-inventory/`,
`release-oracle/reproduce_missing_inventory.py`; reviewer F2.

### VF-06 — P2: census sites inherit the wrong declaration and execution flag

`scripts/failure_census.py:57–58,86–87,165–177` misses anonymous instance
headers and accepts a preceding lexical name without checking compiler-range
containment. Hash-matched compiler evidence shows **140 of 1,644 sites**
assigned to the wrong declaration, with unambiguous containing ranges.
Thirty execution-dependency flags change true to false; no frontend flags
change. Generated pure execution occurrences change **156 → 126**; all
execution occurrences change **335 → 305**. Total sites and monadic counts
are unchanged. One additional valid outer name refines to its nested helper
without changing flags; it is not part of the 140 errors.

Examples are Cmm_csem:440 attributed to `aid_of` instead of
`instBEqPre_execution`, and Core_reduction:331 attributed to
`combine_dyn_annotations` instead of `instBEqOne_step`. The shipped census
rerun reproduces the old data; independent range checking fails as expected.
This corrects attribution/overcounting, not branch-level C reachability.

**Repair:** require range containment for every chosen name, resolve anonymous
declarations unambiguously, preserve unresolved cases, and regenerate the
dated census/account. Add a named-used-def followed by unused-failing-instance
plant. Preserve the original raw measurement. Evidence:
`provider-docs/range-mapping-reproduction.json`,
`coordinator-census-verification.json`; reviewer F-PD1.

### VF-07 — P2: TODO prescribes a disproved modeled-IO byte conversion

`lean_frontend/TODO.md:149–162` claims every non-ASCII captured byte diverges,
claims no corpus coverage, and recommends UTF-8 iteration in batchEscape.
Modeled IO carries one byte per Char. Existing stdout C3 A9 and stderr FF
fixtures already agree in the final B5 archive; all eight capture/status
hashes were verified. A blanket UTF-8 conversion would double-encode this
representation. Generic Lem String/Unicode debt is separate and remains.

**Repair:** replace the diagnosis/remedy with the traced producer-specific
boundary, existing controls and remaining unsupported producers. Evidence:
`provider-docs/byte-overview-counterevidence.json`; reviewer F-PD2.

### VF-08 — P2: current overviews contradict the delivered validation state

`VALIDATION.md:613,625–626` still says there is no runner and that value-only
copies await migration; `:337–338` is similarly stale. `README.md:122–124`
headlines 1,316 comparable CI rows and zero mismatches without dating them.
Final C4 instead records 1,359 agreements, one UB-location difference, three
filesystem refusals, two Lean timeouts and 821 oracle-side non-comparisons.
The detailed reporting record is accurate; the current overview is not.

**Repair:** reconcile current runner/comparison/reporting prose and date any
retained older counts. Also reconcile the contract matrix's claimed exact
libc printer spelling with its canonical-token implementation. Evidence:
`provider-docs/report.md` F-PD3; `observations/REPORT.md` ancillary note.

### VF-09 — P2: litmus internal-failure parsing drops payload and bypasses fatal checks

The shared `observations.py:148–164` litmus exception keeps only the first
failure-message line, ignores extra stderr and returns before the fatal
guard. Actual private helpers agree on different continuation payloads and
accept an extra `Fatal error: exception ...` only on Lean. A differing first
line correctly fails. The current 30 pinned rows have no INTERNAL_ERROR
target, so a current row transitioning to this class still fails its target.

**Repair:** define the message/trace envelope, preserve the entire message and
reject extra fatal records or ambiguous unsupported forms. Diagnostic trace
normalization cannot silently discard arbitrary payload. Evidence:
`observations/private/internal-*`; reviewer G2-1. This is an incomplete
repair of inherited first-line parsing, not a concurrent semantics change.

### VF-10 — P2: both litmus reference readers silently overwrite duplicate rows

Private `test_litmus.sh:119–126` and `sc_reference.py:229–240` accept a wrong
row followed by a correct row for the same name. Both production helpers
and the unmodified mechanical SC checker pass the contradictory input.
Reversing the order or keeping only the wrong row fails. Today's actual
expectations/baseline each contain 30 unique names covering the corpus.

**Repair:** reject identical or contradictory duplicates in both readers,
with line diagnostics; retain missing/orphan/reordered controls. Evidence:
`observations/private/duplicate-*`, `reference-*`; reviewer G2-2. This is
inherited instrument debt newly confirmed by the audit.

### VF-11 — P2: a valid refusal followed by a different Error passes refusal guards

Private `test_litmus.sh:143–144,169–171,192–194` checks only the first Error
message after the coarse ERROR-set projection. Two properly framed Error
records—spawn refusal followed by unrelated evaluator failure—at the correct
multi-execution status 0 satisfy both REFUSE and the sequential-refusal leg
when both engines emit them. Reversing the order fails. Full engine-set
equality is real but does not establish the required refusal domain.

**Repair:** check the complete decoded collection against the declared
singleton refusal requirement (or explicitly reviewed singleton distinct
set), including its message. Plant the extra distinct Error in both guards.
Evidence: `observations/private/refusal-plus-unrelated-error.*` and controls;
reviewer G2-3. This is inherited and is not the intended duplicate-insensitive
treatment of identical executions.

## Evidence that remains valid, and limits

The fresh cold run reconstructed the exact primary candidate with an owned
Lem compiler/runtime, absent generated trees, all three Lake packages and the
external proof client. All 20 commands passed, including standalone Lem's
comprehensive suite. All 207 generated Lean and 86 OCaml hashes match the
subject. Two release-only freshness stamps are explicitly absent because
the cold recipe builds directly; this is provider smoke, not a release-runner
certification. Compiler/tool hashes and all present artifact hashes were
independently checked. See `cold-provider-verification.json`.

The client proves completion of a fixed closed Core fixture using actual
drive/runND at fuel k+2 and a shipped map law under Pmap.WF. It is nonvacuous
and appropriately scoped; it proves neither general runtime/logical equality
nor customer adoption. The failure proposal correctly retains strict success
and failure obligations. Its eventual stable-failure fuel quantifier should
be made explicit at the reserved design discussion.

The historical full A+B report remains 32/32 passing at clean functional
1066d89ee, with unchanged source/external inputs, no lost artifact keys and
29 documented rebuild-related changes among 1,775 entries. The 67 supplied
primary plants, fixed GCC B7, independent 723-case reference and C1/C4 results
remain dated measurements. The new adversaries show why those green checks
do not close the uncovered boundaries. This audit does not reclassify their
actual corpus rows based on synthetic outputs.

Fresh private normal/plant results and the documentation checkpoint are
recorded in the evidence index. Private source comparison confirms no change
to semantics, C fixtures, reference enumerator/sets, S7 initialization or the
measured original apply_tree bodies. Full concurrency integration, its
observer-agreement theorem, mixed-size/SeqRMW work and a current-mainline
rebase remain future work.

No new full A+B or C1/C4 measurement is claimed by this audit; the full
functional-candidate evidence was rechecked, with targeted fresh reproductions
and a new cold build. C2/C3 and customer adoption remain unrun. Known pure
failure, byte/state/fuel and runtime/logical correspondence debt remains
explicitly open; it is not counted again as newly discovered audit findings.

Ancillary concerns retained in the reviewer reports include discarded Cabs
bridge diagnostics, inherited spec-lab generator build-status suppression,
the missing native O2 killed classification branch and the private missing
observation-contract document. Their impact was not established with new
whole-lane plants here; do not silently promote them to proved regressions
or silently close them. Assess them during the bounded repair.

## Recommended next action and landing boundary

Repair the validation foundations on owned branches before starting the SC
integration charter. Keep the work bounded to these instruments, census and
current documentation; no broad failure representation transform is needed
to fix these findings. Each fix needs its positive control and the concrete
adversary above, applied to every affected caller/candidate. Preserve raw
historical evidence and explain any changed classification or baseline.

Then run the relevant full A+B gates on the corrected functional candidate,
recheck reporting where its classifier changed, repeat affected cold/provider
checks, and obtain fresh review of the repairs and their composition. Reopen
G1/G2/G4/G6/G7 against that evidence. Only after that should the final
discussion decide readiness, the failure-design proposal, the SC charter and
an exact ff-only merge. The user's separate landing discussion remains
required; this audit authorizes no merge or push.

## Audit documentation checkpoint

The final Tier A run passed **13/13 commands** (429.371 summed lane seconds)
with source and external inputs unchanged during the run. Both artifact
inventories contain 1,775 entries, with no missing or lost entries. Twenty-nine
version/build/library/stamp entries changed during normal rebuilding; artifact
byte identity is not claimed. The
[checkpoint summary](validation-foundations-audit-evidence/checkpoint-summary.json)
and raw archive (`checkpoint-fast.tar.gz`, dropped at landing [USER 2026-09-06]; identity in [SHA256SUMS.dropped](validation-foundations-audit-evidence/SHA256SUMS.dropped))
retain both inventories, all lane logs and the exact tested documentation
patch/file hashes. The archive has 5,804 individually verified members; the
separate audit archive has 4,038.

This checkpoint tests the audit documentation over frozen primary 6d6cfa858;
the only subsequent edits add these result/archive statements and links.
It changes no functional source, package pin or semantic baseline. The
four P1/seven P2 findings remain open. Mainline, Lem pins and the original
feature ref remain unchanged; the private worktree is clean.
