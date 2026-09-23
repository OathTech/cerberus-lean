# SC prototype: progress and resumption record

Governing document: [SC prototype charter](2026-09-21_charter-sc-prototype.md).
This file records evidence and next actions; it does not replace the charter.

## Current status

**2026-09-23: eight evidenced boundaries are registered. SC-G01/G04/G05 and
the runtime SC-G06 query have validated producers. The atomic interface
completion passes all 39 Tier A+B commands and the 864-case three-engine
comparison, preserving all prior observations/classifications and the same
40 Lean discrepancy/undecodable IDs. Numeric G06 preprocessing and precise
G02/G03/G07/G08 guards remain open. Public SC checking and the whole prototype
remain incomplete.** Lossless value keys and variadic queries are committed at
`f93530586`; this component's [review](2026-09-23_sc-atomic-completion-review.md)
and [evidence](2026-09-21_sc-prototype-evidence/atomic-completion/README.md)
record its validation and the unpromoted location/scope/prefix drafts.
Branch `arc/sc-prototype`, worktree
`/home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-arc/sc-prototype`.
Implementation base: `5407597d9eeba0259d65b728e86a860ad4614ab3`.

| Package | Status | Next evidence |
|---|---|---|
| S0 reference/baseline/instruments | Baseline, contract, inventory and repaired harness retained; current slice passes fresh integration | Continue reference and location interpretation review |
| S1 driver/scheduler/threads | Protocol, owned CAS/ordinary-RMW phases and complete resumable service machine validated | Final scheduler/interface review and complete C entry |
| S2 effects/representation/sequencing | Journal, float representation, physical byte sources, helper ordering and resumption validated | Location/lifetime composition and external correspondence |
| S3 SC atomics/races/verdicts | CAS/fences and unconditional atomic updates validated; exchange/operators/qualifiers covered; unspecified CAS bytes explicitly unsupported | Race/consistency checking, remaining atomic frontend paths and C entry |
| S4 operational API/laws | Checked lifting, choices, recorder, byte-accounting and resumption laws; separate import example passes | Complete public interface, conservativity domains and remaining correspondence |
| S5 integrated completion | Intermediate slices validated; prototype incomplete | Final inventory, complete SC integration and reproducible report |

## Setup record

[USER] approved the SC prototype development plan, requested work in a worktree
and a charter for long-cycle work with minimal interaction. Fidelity overrides
reasoning convenience; customer logic is out of scope and the customer remains
strictly read-only.

[AGENT] created the worktree using:

```sh
/home/dev/projects/cerberus-lean-proj/scripts/new-worktree.sh \
  cerberus-lean arc/sc-prototype \
  5407597d9eeba0259d65b728e86a860ad4614ab3
```

Result: exit 0. The script copied local Lake/build/generated/native state,
created the shared-switch symlink, and built the worktree-local pristine oracle.
Its ensure step reported `BUILT+VALID` for
`.validation-foundations/independent-oracle-v2/manifest.json`, using Cerberus
`b9aeedcb4` and upstream Lem `3802cb0`. This is instrument setup evidence,
not an SC result or a full sequential test certification.

The two September 20 research documents were copied byte-for-byte from Git
commit `02a6adc9091f72cecac6c5ff15845f93fa81fa84`. No legacy implementation
was copied or merged. The mainline, parked donors and customer were not edited.

Fresh setup checks are retained in
[setup-checks.json](2026-09-21_sc-prototype-evidence/setup-checks.json).
OCaml/Lean Lem generation stamps, all 49 hand-written/generated seam copies,
both driver freshness checks, and pristine-oracle validation pass. Lem reports
`38f87d5`; Lean from the owning `lean_frontend` package reports `4.32.2`.

Two setup findings were resolved:

- The copied OCaml driver failed its source freshness check. It was rebuilt
  locally, with cache disabled, using the actual `build_cerberus` helper:

  ```sh
  DUNE_CACHE=disabled /home/dev/projects/cerberus-lean-proj/scripts/ce \
    bash -euo pipefail -c 'source scripts/common.sh
  build_cerberus'
  ```

  The helper exited 0, installed the runtime worktree-locally, and recorded a
  fresh stamp. No freshness override was used. The subsequent combined check
  passes; the already-fresh Lean driver did not require rebuilding.
- An initial `lean --version` from the repository root selected ambient Lean
  `4.33.1`. The owning-package check selected the pinned `4.32.2`. Both outputs
  are retained, with the ambient probe classified separately. Run Lean/Lake
  from the owning package under `scripts/capped`; no global toolchain was changed.

Documentation links, fences, whitespace and exact research-snapshot copies were
checked. The full sequential baseline and all SC implementation tests remain
for S0 onward; these setup checks do not claim those results.

## Next action

The service slice's [review](2026-09-22_sc-service-slice-review.md) and
[evidence](2026-09-21_sc-prototype-evidence/services/README.md) are complete.
[USER, 2026-09-22] selected the first option in the historical
[reference proposal](2026-09-21_sc-prototype-evidence/reference-followup/location-reference-decision.md)
and generalized it: fail closed on evidenced unresolved semantic boundaries,
documenting every case. The [policy](2026-09-21_sc-upstream-gap-policy.md), charter
and [boundary register](2026-09-22_sc-boundary-register.md) record the decision.
No additional reference was adopted. The preserved proposal's pending-question
and source-freeze wording is historical, superseded by this entry.

Continue the substantial location/value/RF/HB and prefix-observation slice.
The dependency builtin, character aliases and runtime lock-free query boundary
now pass full integration. Connect the retained byte, access-group and call-scope
drafts to the actual per-alternative machine state and precise boundary guards.
Source-order paths through all journal vertices have a validated adapter, but
the graph alone does not settle full happens-before. Keep interpretation
obligations separate from independent Core faults, and internal arena completion
separate from the outer C execution. Finish G06 preprocessing and the public
operational/C entry without inventing a target configuration or shrinking runtime
coverage to the scalar checker's domain.
The [independent investigations](2026-09-21_sc-prototype-evidence/reference-followup/README.md)
also retain concrete stream-lock and floating-value adapter findings. Missing
implementation mechanisms remain work, not new coverage exclusions. SC-G01/G04/G05
and runtime G06 have validated producers; the register tracks the remaining
precise guards. All 21 typed SC fault constructors at the initial register
checkpoint were accounted for; their categories must not all
be interpreted as upstream semantic gaps.
The customer remains strictly read-only; no build or migration was performed.

## General gap policy and source graph: validated checkpoint

[USER, 2026-09-22] generalized fail-closed handling of evidenced unresolved
semantic boundaries, requiring every case to be documented. The new
[register](2026-09-22_sc-boundary-register.md) records SC-G01 unspecified CAS,
SC-G02 location/RF composition and SC-G03 stream synchronization. It separately
accounts for implementation obligations and all existing typed diagnostics.
This resolves the previous reference decision; no further confirmation is needed.

[AGENT] added `Sc_graph`, a pure query over the actual recorded state, with
closure through every effect/fence before projecting to access endpoints. It
retains malformed graph data with typed diagnostics, and never derives source
ordering from execution order. The [slice review](2026-09-22_sc-source-graph-review.md)
records the reference and limitations: source-order closure is not full hb,
location interpretation or a public SC verdict.

The isolated 12 paired graph controls pass. Eight actual C recorder executions
agree with an independent reachability traversal; their original outcomes are
unchanged. Shared journal fields differ only at the copied source-location
paths, retained in raw captures. Production generation and fork-manifest checks
pass. The new production executable passes the 12 controls plus four actual
driver controls (fences, unsequenced alternatives, nested spawn/join and a fault
prefix), and its unit gate suite passes. Three compiled semantic-disconnection
plants fail their designated controls. All 39 full Tier A/B lanes pass, with
source unchanged and no artifact issues. The 864-row three-engine comparison
retains the preceding exact classifications, decoded tokens and 40 discrepancy
IDs. [Evidence](2026-09-21_sc-prototype-evidence/source-graph/README.md) includes
verified raw-observation archives. First-generation,
test-compilation and omitted-libc-linking attempts remain explicit failures in
the working evidence. No SC-G02/03 guard is claimed by this slice.

## S0 working evidence

[AGENT] The full pre-change baseline at `d8a1284bf` completed all 39 selected
commands with source unchanged and no artifact issue. The retained
[s0/baseline-report.json](2026-09-21_sc-prototype-evidence/s0/baseline-report.json)
and lane logs record original statuses, parameters and identities. The report
correctly leaves release certification incomplete; existing unsupported and
incomplete corpus cases are not SC support evidence.

The [operational contract](2026-09-21_sc-operational-contract.md) and
[effect inventory](2026-09-21_sc-effect-inventory.md) distinguish runtime coverage,
reference domains, theorem hypotheses and test bounds. The all-SC fence seed
remains explicitly pending. Hermetic harness plants exercise actual bridge
capture, nonzero exits, partial observations, duplicates and the independent
scalar projection; they do not exercise a working SC driver yet.

`CerbMem.loadM` now retains `lastUsed` on a trap, matching concrete OCaml memory.
The valid before probe fails precisely the three state-preservation controls;
the independent OCaml component observes `before=1 after=0 killed=true`.
Five controls were added to `MonadicFailstop.lean`. The fresh post-change probe passes all controls, and the normal caller-fuel
2/17 fail-stop executable passes. Full integration gates remain pending.

Current C-level sequential and atomic frontend probes are retained beneath
[s0/](2026-09-21_sc-prototype-evidence/s0). In particular, `_Atomic int`
qualifier syntax currently loses atomicity upstream, whereas `_Atomic(int)`
retains it. Typed atomic postfix increment, exchange and CAS/fence paths expose
individual upstream gaps. These are not scheduler test passes. Preserve exact
frontend failures and classify each source path when implementing S3.

## Checkpoint template

For subsequent entries record:

- Date, package/task, source revision and relevant tool/artifact identities.
- Changes and rationale, with [AGENT]/[USER] provenance.
- Exact commands, original statuses, evidence locations and claim boundaries.
- Open semantic issues, port gaps and proof limitations as separate lists.
- Next concrete task and any specific decision/capability required.

Do not mark a package complete on historical measurements or copied artifacts.

## Passive observations and checked lifting: implementation in progress

[AGENT] Integrated the passive journal into the shared memory interface and
paired concrete implementations. Default sequential state keeps it disabled.
Reads, equal-value stores, supplied initialization, allocation/deallocation and
varargs metadata are recorded directly; helper operations compose those effects.
The driver still uses its original lift, so this is not yet a concurrency path.
Other memory implementations explicitly report an unavailable observer rather
than a fabricated empty log; this does not change their existing execution.

Both targets regenerated from the shared definitions and both drivers built.
The actual Lean memory component passes 19 controls at each caller-selected
fuel 17 and 64; the actual installed OCaml component passes 11. The checked ND
lift passes three OCaml controls and has production kernel laws for exact
same-fuel erasure when disabled, original-failure preservation, failure-time
state and stopping a live branch. These are local adapter laws, not scheduler,
whole-memory erasure or ISO correspondence theorems. Evidence and source hashes:
[observations/component-manifest.json](2026-09-21_sc-prototype-evidence/observations/component-manifest.json).

The new module exposed an assumption in the fork-drift instrument that the two
generated trees always had identical file sets. Added an exact, content-pinned
`[expected-added]` section; missing pristine files remain errors. Eight new
full-gate plants cover registered additions and changed/missing/duplicate/extra
entries, removal and symlinks. All 22 plants and the real control passed. The
manifest's `mem.ml` row moves from cosmetic to semantic because it now contains
the shared observation type alias; `mem_common.ml` and `nd_observe.ml` carry the
new schema and lift. Existing shared-model deltas retain their prior hashes.

The first integrated unit run passed its executables and earlier checks, then
correctly failed because the two new fuel wrappers lacked parametricity pins.
The generated universal-fuel equations and module import are now included.
Full sequential integration validation is next. No local code commit or S2
completion is claimed before those required checks.


## Validated observer checkpoint (S0 and initial S2)

[AGENT] With parent `d8a1284bf`, the current observer/checked-lift source slice
passes the complete A+B selection: **39/39 commands**, unchanged sources,
complete selection, and no artifact issues. The exact command was:

```sh
DUNE_CACHE=disabled /home/dev/projects/cerberus-lean-proj/scripts/ce \
  python3 scripts/release.py --mode full \
  --out .tmp/sc-prototype/observations-full-20260921-r2
```

[Report and original lane logs](2026-09-21_sc-prototype-evidence/observations/integration/report.json)
retain source/tool/artifact identities and original statuses. This certifies the
selected gates, not release adoption/audit completion or SC support. The first
attempt (`observations-full-20260921`) was incomplete: a scratch-file copy had
lost `test_unit.sh`'s executable bit; after restoring its original mode, the
fresh `r2` run completed. The incomplete first attempt is not counted as a pass.

The mandatory shared-model report also completed, with unchanged sources:

```sh
DUNE_CACHE=disabled /home/dev/projects/cerberus-lean-proj/scripts/ce \
  python3 scripts/test_upstream_oracle.py --with-lean \
  --out .tmp/sc-prototype/observations-three-way-20260921
```

Its [859-case report](2026-09-21_sc-prototype-evidence/observations/integration/three-way/report.json)
records 822 pristine/fork semantic agreements, 28 matching failures, seven
reviewed differences and two interface agreements. The report-only Lean column
has 817 agreements, 28 differences, 12 both-undecodable cases and two
not-applicable cases. The 40 differing/undecodable case IDs exactly match the
September 16 instrument record; the owning sequential gates passed their
existing pins. These 40 cases are not reclassified as agreement. Original
process output bytes are retained in a verified archive with a per-file hash
manifest beside the report. No discrepancy register or frozen corpus was
re-recorded for this slice.

## S1 draft prepared during validation

[AGENT] Ignored worktree-local drafts under `.tmp/sc-prototype/protocol-draft`
now implement the current Core request protocol, explicit SC step/choice API,
structured spawn/completion/join, child errno, startup ownership, and scoped
source-order propagation. The public SC driver still has an explicit
atomic/race/fence integration gap. No production SC CLI or C-to-Core SC
integration has yet passed.

Both Lem targets typecheck/generate (generation 20). An isolated Lean overlay,
using pinned 4.32.2 and the package's `-DautoImplicit=false`, compiles Driver,
the ordering termination proofs, the existing memory failure laws, and the
unchanged-statement fuel/address-space exemplar theorem. Eight new provider
laws cover the actual definitions, including disabled-lift equality and
membership in the scheduler's actual Core choices. These are not an ISO or
axiomatic-SC correspondence theorem.

Eighteen constructed-Core/control groups pass at caller fuel 64, covering
startup, six two-child schedules, nested joins, blocking, unsequenced versus
weak/strong ordering, C calls versus Core procedures, additional-synchronization
edges, and completed helper effects before failure. Two actual-driver mutants
(disconnected observations and serializing all thread history) compile and are
detected by these controls. They are draft-component evidence, not final paired
C execution or race checking. The production tree stayed frozen throughout the
sequential validation and three-engine report.

Next: use the prepared `promote_protocol.py` after the observer commit; it
excludes stale generated files from the annotation draft and preserves existing
file modes. Review generated/source manifests, both builds and gate registers.
CLI plumbing, atomics, races, representation/lifetime composition, fences,
program outcomes, final semantic laws and integrated closure remain unfinished.


## S1 promotion in progress

[AGENT] The validated observer slice is committed locally as `4bba2b458`.
Its 42 full-diff whitespace findings are exclusively preserved raw stdout/stderr
bytes; source/documentation checks are clean. The SC protocol drafts were then
promoted onto that commit, with stale generated files excluded. Both new Lem
modules and their auxiliary/handwritten proof roots are included in generation
and gates. The earlier passing A+B result belongs to the observer commit, not
this new working source. Continue integration and the remaining charter packages.

Production regeneration (`protocol-generation-production-3.log`) and both full
builds pass. Two OCaml portability repairs were necessary: remove a redundant
record update (fatal warning 23), and rename the local `effect` binding because
OCaml 5 reserves that word. No semantic behavior changed in those repairs.
Fresh production binary SHA-256 values:

- OCaml: `12016ba2923c6adb7b310f36ca7a37d44c17c3a9f2a0ed066e88173febc0f1dc`.
- Lean: `a5dee983301bc0e22a6eea0c86d809c0ee71b58cae2d2013eb1d70bf1401c2e3`.

The production `sc-protocol-test 64` passes all 18 controls. The standalone
OCaml component instrument `protocol_ocaml.ml`, linked against the worktree's
fresh installed concrete library and using the actual `Smt2.runND` exhaustive
runner, passes the same 13 execution/order groups with the same alternative
counts (21 total alternatives). These are constructed-Core component tests,
not evidence of C frontend integration or complete SC checking. The five
additional Lean checks cover checked-lift failure and observation retention.
Production `sc-prototype-test 17 64`, `monadic-failstop-test 2 17`, and
`fuel-exemplar-test` also pass. Logs are under `.tmp/sc-prototype/protocol-*`.

The first full unit run passes all 14 executables, axiom checks, and fuel-form
checks (64 measured, 15 absorbing, no reachable ambient worker). It stops at
the failure-register selftest's unplanted control: 13 existing failure sites
moved into renamed shared helpers, and four sites need new explicit reviews
(join comparison, two completion invariants, runtime completion shape).
Next: review/seal those rows and the fork-drift manifest, then run the complete
required integration checks for this protocol slice. Atomics, races, fences,
CLI integration and the remainder of S3–S5 remain unfinished.

## User clarification and completed protocol validation run

[USER] resolved the unspecified-padding CAS decision: fail closed and match
upstream's lack of support until it is resolved. The
[recorded policy](2026-09-21_sc-upstream-gap-policy.md) distinguishes this outcome
from C undefined behavior, CAS failure and an impossible execution. No padding
comparison extension is authorized. General CAS support is not claimed.

[AGENT] The protocol full run has finished: **38/39 selected commands passed**,
source unchanged throughout the run, no artifact issues. The sole failing lane
is B10.1, pristine versus fork OCaml. All seven new differences preserve exit
125 and identical stdout. After the already-approved diagnostic projection,
each differs in exactly one renamed backtrace frame: six `step_ctx_with` and
one `perform_memop_with`. The actual comparison instrument still reports them
as differences; no projection or expectation was changed. The failed report
remains `.tmp/sc-prototype/protocol-full-20260921/report.json`, and the exact
read-only review is `.tmp/sc-prototype/protocol-upstream-diagnostic-review.json`.
The mandatory protocol three-engine report has not run. This slice is not yet
certified or committed.

The completed independent checks extend the earlier entries: both production
engines now pass all 18 component groups; both fresh production connection
mutants are detected. Four C programs pass through the actual frontends into
the production recorder via isolated entry instruments (startup, child
store/join/load, nested join, two empty children), preserving full duplicate
output sequences of 1/6/6/6 alternatives. Those are unchecked recorder outcomes,
not SC definedness verdicts or a shipped SC CLI. The fence draft also passes
the same seven added groups in OCaml and Lean, but is unpromoted.

Final inspection found 287 historical comment lines missing from the refreshed
fork manifest despite the earlier preservation attempt. A prepared restoration
preserves the complete non-comment payload; it is not applied yet. Restore
these comments and correct the review's premature preservation claim before
the next checkpoint. This does not require changing semantic pins or classes.
The ignored `.tmp/sc-prototype/decision-checkpoint.md` retains detailed paths
and instruments; its original frozen-source packaging script now requires new
passing validation identities, since the original full run failed and the user
policy has subsequently updated documentation. Do not bypass those assertions.

## Protocol diagnostic repair and retained checkpoint, 2026-09-22

[AGENT] The seven frame renames are now exact `diagnostic-text` rows in the
existing registry, with both engine signatures and cited original captures.
The comparison projection and fixture baselines are unchanged. All 287 missing
historical manifest comments are restored; the non-comment payload is identical.
The [diagnostic review](2026-09-21_sc-protocol-diagnostic-review.md) records the
failure and repair without recategorizing crashes as semantic agreement.

Fresh validation on unchanged sources:

- `release.py --mode fast`: all 16 Tier A commands pass.
- `test_upstream_oracle.py --with-lean`: 859 cases, upstream gate passes;
  822 semantic agreements, 21 matching failures, 14 reviewed differences and
  two interface agreements. Lean has 817 agreements, 28 differences, 12
  both-undecodable and two inapplicable rows. The 40 discrepancy IDs exactly
  match the observer checkpoint and its September 16 instrument comparison.
- Fresh pristine-comparator plants: 53 rows pass their expected classifications;
  the real fork-drift gate also passes.

The full run's 38 passing commands remain evidence on identical executable
inputs: all 1,808 artifact records and both external input inventories are
equal before/after that run and the fresh fast run. The intervening repair
changes only the diagnostic registry/citation, manifest comments and documents.
The affected pristine comparison and its plant battery were rerun, as was all
Tier A. No unaffected slow lane was rerun solely for those non-executable edits.
The original full report still says **failed**, 38/39; no newly green full-run
report is claimed. A fresh full run remains required at final completion.

[Retained protocol evidence](2026-09-21_sc-prototype-evidence/protocol/integration/README.md)
includes both original reports, all lane logs, the fresh three-engine report,
5,150 original process stdout/stderr captures with verified archive hashes,
paired 18-group component controls, two detected production connection plants,
and the four C-to-recorder controls. The latter retain 1/6/6/6 full duplicate
result sequences and are unchecked recording, not SC verdicts. Paired fence
drafts and the [CAS reproductions](2026-09-21_sc-prototype-evidence/cas-representations/decision.md)
are explicitly separated from production certification.

Independent next-slice work in `.tmp/sc-prototype/sc-representation-draft`
generates both targets and passes 11 representation-comparison controls in each.
Five kernel laws over the generated Lean operation include specified-byte
decoding and refusal when either equal-sized representation contains an
unspecified byte, regardless of other differences. These are pure comparison
laws, not an integrated CAS proof. The paired byte-accessor source draft has
not yet been built or promoted. Upstream BMC `bmc_incremental.ml` supplies the
CAS phase edges at `do_po_e` and actions at `intermediate_to_bmc_actions`; the
draft must preserve those edges and the indivisible object RMW while allowing
interleavings around expected reads/write-back. No production CAS success is
claimed by this checkpoint.

## Atomic foundations promoted; CAS phases in draft

[AGENT] After local protocol commit `06681abd3`, promoted the reviewed fence
request/receipt and weak-order refusal paths, the shared representation
comparison, five kernel laws, and the paired memory-byte projection. The
projection reads existing byte bits and preserves absence; it does not perform
another memory access or alter provenance/copy metadata. Non-concrete adapters
explicitly return unavailable. Protocol test helpers are shared by the two
test entries without changing the 18 original controls.

Both production targets regenerate with shared source hash
`5c43f8af980629af5bb2b849c9197a7792cd35a5f98ecbeddf76653f9aa09954`;
all 54 handwritten copies match. Both production builds pass (Lean 412 jobs).
The test build passes (277 jobs), followed by the 18 protocol controls, seven
fence/weak-order groups, and 11 representation controls. Logs and the guarded
promotion manifest are `.tmp/sc-prototype/atomic-foundations-*`. This new slice
is uncommitted and has not run its integration ladder or register reviews.

The separate `.tmp/sc-prototype/sc-cas-draft` adds scheduler-owned suspended
Core requests for three CAS phases, actual completed-read byte extraction,
strong comparison, weak spurious failure and failure write-back. Only the
object read/conditional store is indivisible. Completion retains all phase
predecessors and footprints; phase source edges follow upstream BMC's CAS
`do_po_e` edges. Both Lem targets generate (attempt 3), but compile checks,
the scheduler-choice law update and actual execution controls remain. The first
generation attempt exposed unsupported Lem or-pattern syntax; the second used
an incorrect basename-only dependency resolver. Attempt 3 preserves original
dependency paths. These were draft instrumentation failures, not C outcomes.
Do not promote the CAS sources or claim CAS support on generation alone.

## CAS execution controls and floating-point representation repair

[AGENT, 2026-09-22] CAS draft generation attempt 4 and both target compilation
pass. The scheduler membership theorem now characterizes exactly the offered
pending request or runnable ordinary Core step of each active thread. The paired
original 18 protocol controls and nine integer/failure/interleaving CAS groups
pass; the concurrency witnesses enumerate 175 and 210 alternatives. These remain
unchecked recording controls, not completed SC race/consistency verdicts.

Three double CAS controls exposed an inherited Lean NaN payload loss: eleven
of twelve CAS groups pass, while unequal-NaN failure write-back loses the
object's payload. Both the interpreter and a fresh native closure reproduce it.
Actual native OCaml passes all twelve. Two sequential C copy reproductions give
pristine/fork `Specified(1)` versus Lean `Specified(0)`. This is a port defect
with known upstream behavior, so the upstream-gap fail-closed policy does not
excuse leaving it unimplemented.

The [float repair record](2026-09-22_sc-float-representation-repair.md) details
the evidence, failed probe attempts and isolated `.tmp/sc-prototype/sc-float-draft`.
The draft retains binary64 bits in a transparent value carrier, with two kernel
round-trip laws. All 784 rows of an actual OCaml arithmetic matrix match the
interpreted draft. Both Lem targets generate; leaf modules compile. Next: check
the full frontend closure and native memory/CAS behavior, promote only after
those checks, then continue atomic/race checker integration. Production remains
the uncommitted atomic foundations; neither CAS nor the float draft is promoted.

## CAS and float repair promoted; production controls pass

[AGENT] The fresh native float-repair frontend matches both references on all
five C regressions. The combined CAS draft passes all twelve groups, including
the previously failing NaN write-back. The repair and CAS are now promoted under
a source-hash guard (`cas-float-promotion.json`). Both targets regenerate and
both production builds pass; all 55 handwritten copies match. Lean builds all
415 jobs. All seven native component executables pass, including the 784-row
arithmetic reference table, 42 literal pins and repaired formatting controls.
Five C regressions are added to the existing float lane with new MATCH entries.

The [atomic slice review](2026-09-22_sc-atomic-slice-review.md) explains shared
semantics, oracle drift and the 240-site failure census (173 invariant-unreachable,
48 reachable, 19 unknown; zero discardable). Ten old failure arms preserve their
classes under a helper rename; two internal CAS phase arms have source-invariant
reviews. Historical fork-manifest comments and renumber metadata are retained.
Next: fresh integration gates/three-engine report and C-to-CAS controls, then
continue SC race/consistency and remaining atomic integration. This slice is
still uncommitted and the public SC entry remains explicitly incomplete.


Integration attempt status: `cas-float-fast-20260922` is an environment-launch
failure (no `scripts/ce`, all lanes refused). `cas-float-fast-env-20260922` found
an F5 notation guard collision on the numeric anonymous constructor in
`CerbFloatValue.binary`; this has been replaced by the definitionally equal
named `ofBits` call, with the guard unchanged. The direct guard passes. The
runner was stopped and retained its report before sources changed; production
Lean rebuild 2 is underway. Do not count either attempt as Tier A certification.


The F5 repair rebuild passes all 415 jobs and leaves the native executable
byte-identical. Seven actual C-to-Core recording controls now agree exhaustively
between the native engines, preserving full duplicate token sequences; three
NaN/signed-zero C controls agree as selected traces only. Original larger
exhaustive timeouts remain recorded. Pristine/fork/Lean all reject the `_Atomic
double` qualifier spelling used by an initial fixture; the accepted
`_Atomic(double)` form reaches CAS. See the atomic slice review for this separate
upstream frontend gap. Next integration attempt uses the loaded project environment
and the unchanged fuel-notation guard; no current Tier A success is claimed.

## Current integration and next scheduling drafts

`cas-float-fast-repair-20260922` passes all 16 Tier A lanes with unchanged
sources. The full run passes its first 28 lanes, including Tier A, libxml2,
fixture checks and all spec-lab families. B7 then finds a new disagreement in
`109-nan-arithmetic.c`: native GCC selects the other NaN operand's payload at
`-O0`. The runner was stopped through normal SIGTERM cleanup before any source
edit; its report is **incomplete**, with B7 interrupted and source unchanged.
The original mismatch and partial captures are retained, not counted as a pass.

The [float repair record](2026-09-22_sc-float-representation-repair.md) records
the minimized diagnostic: GCC prints payload 2 at `-O0` and payload 1 at `-O2`;
pristine/fork/Lean consistently implement the pinned OCaml choice. The new
ordinary C fixture now gives both NaNs the same sign and payload, retaining a
signaling operand to test quieting. It returns zero at both GCC optimization
levels and on pristine/fork/Lean. The earlier native recorder still returns
one on the refined input, so it continues to detect the old payload-loss defect.
The 784-row exact OCaml matrix retains distinct operand signs/payloads. No
semantic implementation, expected result, comparator or triage ledger changes.
Fresh integration and the mandatory three-engine report are required after
this fixture edit. Scratch evidence: `nan-gcc-fixture-review/`.

Independent next-slice sources remain under `.tmp/sc-prototype/`:
`sc-byte-sources-draft` now generates both targets, but is not compiled or
promoted; `sc-seq-rmw-draft` splits ordinary read/modify/write only in the SC
scheduler and retains the sequential handler byte-for-byte, but is not yet
generated or tested. Its source rationale is Memarian's thesis pp. 64/67:
ordinary RMW is indivisible against indeterminate calls within its own thread,
while another thread can interleave between read and write. `helper-resumption-review.md`
records the remaining general helper/FS resumption issues, not a claimed solution.
`remaining-atomic-paths/` retains seven pristine/fork/Lean frontend probes,
including the existing failures for atomic postfix/exchange/fetch/signal-fence
paths and the successful upstream `atomic_init` SC-store elaboration. These
refusals and failures are not counted as feature support. `plant_atomic_production.py`
is prepared for fresh production-connection mutation tests.

## CAS/float checkpoint validation completed

The fresh `cas-float-full-fixture-repair-20260922` run passes all 39 required
Tier A/B commands; every exit is zero, the complete tier is selected, sources
are unchanged and there are no artifact issues. B7 passes 2,006 GCC cases with
no baseline regression; B9 passes 93 observation mutation checks. The mandatory
three-engine run passes 864 rows: pristine/fork 827 semantic agreements, 14
reviewed differences, 21 matching failures and two interface agreements; Lean
822 agreements, 28 differences, 12 both-undecodable and two inapplicable rows.
All 40 discrepancy IDs are unchanged from the protocol checkpoint. These
classifications are preserved, not relabeled as agreements. The earlier failed
and incomplete release attempts remain retained with their original statuses.

Six fresh production controls/mutations pass: positive CAS and fence controls,
then removal of weak spurious failure, invention of an unspecified-representation
mismatch, removal of CAS phase edges and admission of weaker orders. Two selected
pointer-CAS C traces also pass, including dereferencing the pointer written back
to expected on failure; their original exhaustive timeout remains incomplete.
The legacy `Driver.trace` review is resolved: it is an existing lossy diagnostic
summary. The complete SC occurrence journal is the interface for checking and
reasoning; optional legacy CAS display entries are not a missing memory effect.

The [atomic evidence index](2026-09-21_sc-prototype-evidence/atomic/README.md)
retains reports, commands, raw execution observations, source identities,
component controls, plants and failed attempts. Archive members are verified by
size and hash. Successful Cabs AST exports are inventoried generated inputs;
all execution stdout/stderr remains byte-exact. Release certification is still
incomplete: passing the command ladder does not complete this charter's
semantic, interface and final-review obligations.

The next ordinary-RMW draft now generates both targets and passes seven native
control groups in each engine, including inter-thread read/write interleaving,
same-thread call exclusion, weak-order refusal, failed writes and intervening
lifetime end. The same Lean implementation passes protocol/CAS/fence regressions.
Six C inputs parse/elaborate; the OCaml recording entry builds. Its Lean entry
has one pending native Main compilation after a short scratch timeout, which
remains incomplete. Resume that compile and run the actual paired C controls.

The byte-source draft's first generation and five Lean memory controls/laws
pass; the OCaml keyword collision has a source repair awaiting generation 2,
with three additional memory controls prepared. The helper-order candidate
remains ungenerated and requires a source-order review before promotion.
Separate resumption notes retain the concrete filesystem snapshot hazards.
Three kernel recorder-retention laws pass on current production definitions;
they are not yet exported or a claim of ISO correspondence. No follow-up draft
is included in this checkpoint's executable-source certification.

## Ordinary RMW and physical byte sources promoted

The [RMW/byte-source review](2026-09-22_sc-rmw-byte-source-review.md) records the
source rationale, actual changes, native controls and kernel laws. The six C
RMW selected-trace controls pass in both engines. Five also agree exhaustively
on full observations (1, 1, 48, 48 and 336 alternatives); the parallel increment
case times out in both engines at 12 seconds and remains incomplete.

Byte-source generation 2 and both paired eight-group memory controls pass;
the OCaml keyword failure remains historical evidence. Both features are now
production sources. Their fresh OCaml build and 442-job Lean build pass, as do
five native production control executables. Three previously probed recorder
retention laws are now exported from `CerbSCOperational` and compile in the
production package. Six native production connection controls/mutations pass.

The failure register adds only the reviewed internal RMW phase guard (241 total,
zero discardable); all prior rows are byte-identical. The fork manifest retains
all historical review text and metadata, adding the new shared accounting leaf
and only the intended changed-source hashes. Fresh full integration and the
mandatory three-engine comparison follow on frozen sources. These accounting
laws do not decide the still-unresolved C memory-location interpretation.

## Ordinary RMW and byte-source validation completed

The frozen `rmw-byte-full-20260922` run passes every one of the 39 selected
Tier A/B commands, with source unchanged and no artifact issue. The mandatory
three-engine run passes 864 rows with exactly the prior 40 discrepancy IDs.
Five production native executables and six production connection controls pass;
all current control binaries match their captures after the proof rebuild.

The [retained checkpoint](2026-09-21_sc-prototype-evidence/rmw-byte-sources/README.md)
contains full reports, raw observations, verified archives, source identities,
component and real C controls, register reviews and original failed/incomplete
attempts. Five C controls agree exhaustively and six pass selected execution;
the parallel exhaustive timeout stays incomplete. No public SC verdict or
whole-program definedness follows from these recording controls.

Prepared follow-up code remains isolated and uncompiled at this checkpoint:
typed helper suspension, explicit memory suspension mode, same-request helper
ordering, typed fault identities and a separate consumer import example. Source
review covers current-state resumption, filesystem snapshot ownership, the
unchanged primitive bodies and missing location interpretations. This is
continuing work, not a new authorization or completion barrier.


## Additional reference audit retained with the source graph

The [varargs audit](2026-09-21_sc-prototype-evidence/varargs/README.md) records
four actual C traces. Shared-list and concurrent copy/advance executions expose
unordered abstract metadata updates; independent-copy and join-ordered controls
do not. This is SC-P05 implementation guidance, not a new upstream gap.
The atomic follow-up also records literal-only memory-order decoding and
`atomic_init`'s current assignment macro as implementation obligations. No
atomic draft result is claimed by this graph checkpoint.


## Unconditional atomic updates validated

The [atomic-update review](2026-09-22_sc-atomic-update-review.md) records the
new Core action, indivisible driver service and actual exchange/operator
lowering. The qualifier and compatible-aggregate CAS repairs are included.
Seventeen paired Core groups, four kernel statements, parser/roundtrip checks,
37 actual C journals and five compiled disconnection plants pass. Thirty-one
positive selected C cases and six exact negative outcomes have paired evidence.
Only one of eight bounded exhaustive cases completed; the remaining seven
timeouts remain incomplete. The correction to the parameter-case expectation
and the accidentally stale diagnostic run remain explicit in the record.

The frozen 39-lane full run passes, and the 864-row three-engine comparison
retains every prior classification, decoded token and the same 40 discrepancy
IDs. [Raw evidence](2026-09-21_sc-prototype-evidence/atomic-updates/README.md),
including generation/build failures and mutation results, is retained with
verified hashes. No whole-program safety result follows from recorder outputs.

Follow-up drafts for init/flags, runtime orders, signal fences, integer fetch,
logical values and a separate instantiation of the unchanged Cmm predicates
remain unbuilt/unpromoted at this checkpoint. They need review and validation;
they are not part of this slice's support claim. Public race/consistency
checking, precise boundary guards and the full operational interface remain
mandatory charter work. No customer or pin change was made.


## Atomic interface follow-up underway

After efb39628c's validated checkpoint, the combined init/flag/fetch/signal/order
implementation was promoted from its isolated draft. Both Lem targets generated and native/Lean compilation passes. Eighteen paired
Core groups, seven kernel laws, 134 native C outcome controls, seven additional
native flag-function controls and six paired C sequencing controls have passed
their stated checks. Parser/plants, broader paired C work and full integration
remain outstanding. The
[current review](2026-09-22_sc-atomic-surface-review.md) records exact scope,
SC-G04/05, argument conversion repair, public fence wrappers and the unresolved
lock-free preprocessing/query work. No whole-SC completion claim is made.

The public fence path now uses actual C wrapper calls: a retained trace exposed
missing function-call ordering in the draft's direct-name rewrite. Fence and
flag wrappers use order-parameter types compatible with the pinned public enum,
avoiding the native serialized-libc enum-registration failure. The public flag
functions remain callable with macro suppression and through pointers. The
six-body libc fixture addition was reviewed against the original: all existing
bodies remain unchanged. See the interface review for current evidence limits.

### Atomic interfaces and libc location transport — validation preparation

The runtime-order/init/flag/integer-fetch/signal-fence work now has eighteen
paired Core groups, seven kernel laws, actual C controls, prefix assertions and
compiled sensitivity plants. Two genuine libc diagnostic-location discrepancies
were repaired through source-bearing Core transport (SC-P07), with exact paired
C reruns and 322 parser checks. Details and retained local evidence are in the
[interface review](2026-09-22_sc-atomic-surface-review.md). This is not completed
SC coverage. Prepare a frozen full/three-engine checkpoint for this substantial
interface/transport slice, then continue lock-free configuration/query handling
and the remaining location/stream/fault/correspondence obligations.

The lock-free follow-up found C17 DR458 (preprocessor constant expressions) and
DR465 (type-consistent queries, including null pointers). Therefore a query must
not read the object or reject a null pointer. The pinned Cerberus still supplies
neither lock-free configuration values nor query implementation. No invented
all-lock-free policy or new lock-free guard has been installed. The existing
reference probe showing silent zero in `#if` remains an open defect, not an
accepted configuration. Sources: [DR458](https://www9.open-std.org/JTC1/SC22/WG14/issues/c11c17/issue0458.html),
[DR465](https://www9.open-std.org/JTC1/SC22/WG14/issues/c11c17/issue0465.html).

## Atomic interfaces and location transport validated

2026-09-23. The frozen third full campaign passes all 39 Tier A+B commands
with unchanged source and no artifact issue. The mandatory 864-case three-engine
report passes with exactly the previous case identities, classifications,
projected observations and 40 discrepancy/undecodable IDs. The failed first
two full attempts and focused metadata rerun remain retained, with original
statuses and channels. [Verified archives and reports](2026-09-21_sc-prototype-evidence/atomic-surface/README.md)
include component controls, failed setup/builds, five plants, seven laws,
eighteen paired Core groups, actual C inputs and source-location repairs.
No public SC verdict or completed-charter claim follows from this checkpoint.

The [boundary register](2026-09-22_sc-boundary-register.md) now records SC-G06
(missing lock-free target configuration), SC-G07 (C atomic sequencing versus
the pinned Cmm function-call assumption), and SC-G08 (missing protection of
shared library internals). [Raw follow-up evidence](2026-09-21_sc-prototype-evidence/boundary-followup/README.md)
includes five atomic-ordering C controls and actual parallel/ordered
`at_quick_exit` registrations. Four open/close probes timed out without journals
and remain incomplete. No dedicated guard for these three cases is installed;
the numeric lock-free preprocessing fallback remains an open defect.

Implementation continues on the logical-value/reference adapter and varargs
metadata conflicts. Ignored drafts have native generation/control evidence;
their Lean laws and actual driver integration remain unfinished. They are not
part of this validated slice. Available-guidance atomic work, including
`kill_dependency` and remaining public aliases, remains required. Customer and
dependency pins are unchanged; the customer repository remains read-only.

## Value and varargs adapters — integration preparation

The [current adapter review](2026-09-23_sc-value-metadata-review.md) records
eighteen paired value groups, ten paired metadata groups, eight exact paired C
queries, fifteen kernel laws, nine compiled positive/mutation controls and nine
derivation checks. Both targets generate and build. Initial native-name, proof,
diagnostic JSON/link and control-syntax failures remain retained as failures.
The new reference instance preserves predicate bodies; raw keys retain bits and
provenance without changing ordinary memory equality. Varargs witnesses retain
actual journal identity. At this preparation stage frozen integration was still
pending; the following checkpoint records its completed validation.

The full source-only query is not yet full happens-before, and raw value identity
does not settle cross-view reads-from. Public prefix checking and precise gap
guards remain unfinished. The completed full ladder and mandatory three-engine
report validate this adapter slice; they do not complete the whole SC charter.


## S2/S3 value and metadata component checkpoint, September 23

Parent `3f9705c9b`; the [component review](2026-09-23_sc-value-metadata-review.md)
and [evidence summary](2026-09-21_sc-prototype-evidence/value-metadata/summary.json)
record the frozen 39-command full pass and unchanged 864-case three-engine
comparison. Eighteen paired value groups, ten metadata groups, fifteen kernel
laws, nine derivation checks, nine compiled controls/mutations and eight actual
C metadata comparisons pass. Failed and interrupted predecessors are retained.

Raw keys are lossless values, not final cross-view RF equality. Source-only
ordering is not full HB. Additional actual-C diagnostics expose both limits,
preserve independent faults, and show why ordinary declaration-plus-atomic_init
uses the already reviewed fence-aware condition. Five publication controls
separate the native full-HB diagnostic from paired source-only recorder evidence.
Allocation/child-errno initialization composition is a recorded question, not a
new runtime refusal. SC-G07's follow-up includes ordinary/atomic mixed pairs
and existing UB035 prefixes; no dedicated guard is claimed.

Next: promote and compile the prepared atomic-interface completion: the
`kill_dependency`/character aliases and available runtime lock-free query rules.
The combined thirteen-file draft preserves all ten unresolved preprocessor
constant definitions and adds no numeric configuration. Validate actual builtin
behavior against complete paired observations and meaningful source-order/effect
controls, then continue final location/HB/RF, fault and public-interface
integration. The ignored draft's
generation and identity-macro tests do not certify its actual builtin/query. No
customer write, mainline merge, push, dependency change or new reference is
authorized by this checkpoint.


## Atomic interface completion — component validation, September 23

Parent `f93530586`; the [review](2026-09-23_sc-atomic-completion-review.md)
records available `kill_dependency`, character alias and runtime lock-free query
rules. Reached configuration queries retain argument effects and prior faults
and report a precise typed gap without loading the object. The preprocessor
constant definitions are unchanged; their silent numeric fallback remains an
open SC-G06 defect. Component evidence includes 31 paired dependency C cases,
17 paired query runtime cases, eight reviewed malformed calls, six alias cases,
25 paired Core groups, both parser suites, compiled internal-evaluator transport
and three production-lowering mutations with their unchanged control.
Failed instrument/expectation attempts remain retained. An existing atomic
initializer conversion defect is recorded separately as SC-D05 and local draft
45; no new concurrency refusal or sequential repair is adopted.

Next: complete manifest/freshness review, normal rebuilding and frozen full
39-command validation plus the 864-case three-engine comparison. This is an
intermediate component slice. Continue location/value/RF composition, full HB,
prefix faults, remaining precise guards and the public C/operational interface.


## Atomic interface component checkpoint, September 23

Parent `f93530586`; [review](2026-09-23_sc-atomic-completion-review.md) and
[retained evidence](2026-09-21_sc-prototype-evidence/atomic-completion/README.md).
All 39 Tier A+B commands pass on frozen sources with no artifact issue. The
mandatory 864-case three-engine report exactly preserves the prior observations,
classifications and 40 discrepancy/undecodable IDs. The mistaken 8 GiB per-test
invocation, its correctly failed kill plant, interruption and full retry at the
standard 4 GiB per-test cap remain retained. No baseline, semantic source or
resource bound was changed to conceal a failed result.

Runtime G06, dependency evaluation and character aliases have completed this
component validation. G06 numeric preprocessing remains an open defect. The
default zapping claim in E05/P04 is corrected from actual paired memory-body
evidence: target lifetime ends but stored pointer bytes remain unchanged under
the existing disabled switch. Lossless byte identity is not universal RF
equivalence; actual byte copying can change copy metadata without changing the
pointer value.

Independent frozen-period drafts are retained, not promoted: byte keys and
access grouping, actual definition/call/parameter identity, shared per-branch
call scopes, and prefix sequencing queries. Their source, kernel laws, actual
native C/Core controls, paired component controls and failed predecessors have
explicitly bounded claims. A real-service counterexample requires keeping
interpretation obligations separately from later Core faults. An internal arena
completion during startup is not a public C completion. See the current boundary
register and evidence follow-up notes.

Continue the substantial location/value/RF/HB and prefix-observation integration
slice, including precise G02/G03/G07/G08 guards, G06 preprocessing, and the public
operational/C interface. Do not stop at this component commit or call the SC
prototype complete. The customer remains strictly read-only; no merge, push,
dependency or reference change follows from this checkpoint.
