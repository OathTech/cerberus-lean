# SC prototype: progress and resumption record

Governing document: [SC prototype charter](2026-09-21_charter-sc-prototype.md).
This file records evidence and next actions; it does not replace the charter.

## Current status

**2026-09-22: SC protocol checkpoint validated after exact diagnostic review. Fresh Tier A and three-engine checks pass; earlier unaffected Tier B checks retain identical executable inputs. Atomic/fault integration continues under the user's fail-closed policy.**
Branch `arc/sc-prototype`, worktree
`/home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-arc/sc-prototype`.
Implementation base: `5407597d9eeba0259d65b728e86a860ad4614ab3`.

| Package | Status | Next evidence |
|---|---|---|
| S0 reference/baseline/instruments | Full pre-change baseline passed (39/39 commands); contract, inventory and repaired harness implemented | Fresh tests and integration gates for the changes |
| S1 driver/scheduler/threads | Production protocol, paired controls, connection plants and diagnostic repair validated | Retain checkpoint and continue atomic phases |
| S2 effects/representation/sequencing | Passive journal, checked lift and annotated requests integrated; paired controls pass | Remaining representation/location/lifetime composition and correspondence |
| S3 SC atomics/races/verdicts | Fence draft passes paired controls; padding-CAS upstream gap will fail closed | Atomic/fault paths, races, C entry and diagnostic families |
| S4 operational API/laws | Checked ND lifting and same-fuel erasure integrated and compiled | Importable production definitions and driver laws |
| S5 integrated completion | Not started | Final inventory, fresh gates and reproducible report |

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

Checkpoint the validated protocol slice, then promote and integrate the paired
fence draft. Continue atomic requests with separate expected-read, atomic-object
and failed-write-back phases, representation comparison, and fault/race checking.
The [user's fail-closed policy](2026-09-21_sc-upstream-gap-policy.md) is resolved;
no further padding decision is pending. The remaining work is implementation,
reference checking and validation, not routine user approval.

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
