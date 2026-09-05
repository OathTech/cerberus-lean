# Cerberus Lean and Lem Lean: current state and customer readiness

Assessment by Codex [AGENT], 2026-09-05. Recommendations in this document
are proposals, not new operator rulings. The reviewed revisions are pinned
below; generated files and test results are identified separately from
committed source. This is an assessment with targeted verification, not a
full release certification or the independent convergence exercise.

**Work-order update:** [master plan revision 3](2026-09-05_master-plan.md)
now supplies current priorities and ownership. The operator's subsequent
instruction leaves the legacy csmith run entirely with its existing agent
until completion. Observations below remain historical evidence, not an
instruction to monitor or take over that run.

**Judgment:** retain the shared-model architecture and finish its correctness
and consumer contracts. The project is a substantial, useful development
dependency, but an unrestricted stable-release claim is premature. The
concurrency prototype is worth landing after a bounded repair and integration
pass. It should initially be an explicitly scoped SC feature; its current
limitations do not justify a general C11 concurrency claim.

## 1. Orientation and exact state

The requested handoff is
[2026-09-05_orchestrator-handoff.md](2026-09-05_orchestrator-handoff.md).
Read its work order with
[the audit response, section 4](2026-09-05_whole-project-audit-response.md):
that revision supersedes the older ordering still printed in
[the master plan](2026-09-05_master-plan.md).

| Component | Observed revision/state | Role |
|---|---|---|
| `cerberus-lean`, `mdd/cerberus-lean` | `89f7e688530c6910884518811d645e4e892e4507`; clean | Executable C semantics and Lean proof definitions. Handoff commit follows P0 instruments at `0a62dd7f7`; fuel C4 at `56b3c9e90`. |
| `lem-lean`, `mdd/lean-backend` | `f6542f8e6860d12d4655e6648bc4c45dabd1d798`; clean | General Lem-to-Lean compiler backend and LemLib runtime. |
| `deps/lem-pinned`, installed `lem -v`, Cerberus LemLib checkout | All `f6542f8` | Mainline compiler/runtime invariant holds. All three checked Cerberus Lake manifests agree, including speclab and mem-scale micro. |
| `deps/cerberus-upstream` | `b9aeedcb4dd438763b0eef7f95ac19e93875d7de` | Pristine upstream source reference; distinct from the fork OCaml oracle. |
| `feature/concurrency` | `086d8762d`; clean; worktree `worktrees/cerberus-lean-feature/concurrency` | S0–S7 prototype. Fork point with current mainline `31eba718e`; 15 mainline-only and 13 feature-only commits. |
| `refined-cerberus`, `main` | `c2ebeb7`; clean when inspected | First external semantics customer, owned by another agent. Still pins Cerberus `f95ef8d9c317fa6b50cf6691216a8c37b1d3eabf`. |
| `arc/p0-instruments` worktree | `8e5f198c5` | Preserved for the live post-landing csmith sweep; do not delete while that job uses it. |
| General arc worktrees | Cerberus `arc/next` at `89f7e6885`; Lem `arc/next` at `f6542f8` | Available historical working locations, not evidence that a new implementation slice is active. |

No remote fetch was performed. Local tracking refs cannot establish who
pushed a commit or the present server state. The mainline source checkouts
were not edited. This assessment is on its own documentation branch.

The dependency chain is Lem/LemLib → Cerberus Lean → refined-cerberus's
Iris-based logic. `speclab` is a local differential harness consumer.
CN and libxml2 provide useful external test inputs; their presence does
not establish that their verification systems consume this Lean API.
RefinedC, iris-lean, BRiCk and other `deps` projects supply dependencies,
reference designs, or future targets. The older `cerberus-lean-prototype`
and parked reasoning branches are historical records. Reintroducing a
second relational semantics into Cerberus is not the current direction.

The C parsing boundary remains OCaml's Cabs JSON. Lean performs desugaring,
typing, elaboration, and execution, and also parses Core text. The primary
runtime profile is the concrete LP64 memory implementation. The port is
therefore neither an entirely Lean C parser nor a proof of ISO C conformance.
Cerberus uses Lean 4.32.2; standalone LemLib/comprehensive tests pin 4.28.0.
Both toolchain uses need explicit release evidence.

## 2. What has actually been achieved

The fuel-parameter arc is landed across both repositories. There is no
library-wide numeric default fuel: ambient fuel is a quantified `[LemFuel]`
parameter, with the executable choosing a CLI default. Measured wrappers
instead use data-derived sufficient bounds, with kernel-checked obligations.
The current gate, rerun during this assessment, partitions 81 workers as:

| Class | Count | What it establishes |
|---|---:|---|
| Measured | 54 | Worker agrees with wrapper above its measure; seven require registered hypotheses. |
| Kill at zero, currently named `ABSORBING` | 13 | The actual worker at zero returns the distinguished kill. Propagation and general monotonicity are explicitly not proved by this classification. |
| Reachable ambient, pending | 8 | Known unresolved exhaustion contracts, explicitly registered. |
| Ambient, unreachable from the checked entry cone | 6 | Outside that cone; not a universal unreachable-code claim. |

The seven hypotheses comprise six layout/reconstruction obligations using
`CerbTagsWf.Acyclic`/`AcyclicPair`, and one formatting obligation `2 ≤ b`.
The register is reviewed evidence, not a theorem that every frontend output
satisfies its hypotheses. It records the accepted `_Alignas` counterexample.

Lem has also delivered derived computable sizes, structural recursion
annotations, measured recursion with hypotheses, trailing-lambda support,
explicit supply/reader transformations, and `LemLibPmapLaws`. The latter
provides comparator laws, map well-formedness preservation, and lookup
after insertion laws. These directly address earlier consumer requests.
The map/set `join` computation issue has also been addressed by
height-indexed structural recursion, with `join_eq` correspondence theorems
under `heightsOk` in `LemLibTheorems`.
They must still be adopted by refined-cerberus; an old request document
is not evidence that the provider work remains undone.

The earlier effect-projection axiom has been removed. Current unit checks
enforce the declared axiom/sorry/unsafe boundary and totality of 22 generated
execution modules plus CerbND. This is meaningful assurance, but it is scoped:
frontend `partial` definitions and declared native/opaque seams remain.
Zero added axioms does not establish agreement between a pure declaration
and its runtime implementation, correct failure propagation, or C accuracy.

P0 repaired three important instruments: fuel-contract correspondence,
fork-drift locale/prerequisite handling, and whole-`Defined` comparison in
`test_exec.sh`. Their plants and the current unit suite pass in this review.
The fork gate checks 71 oracle-surface filenames and 22 hash-pinned generated
OCaml deltas, comprising 11 semantic and 11 cosmetic manifest entries.
The generated trees are not byte-identical to one another. Hand-written
oracle content is not yet pinned by layer 1.

The test portfolio is substantial. These are distinct populations, not
numbers to add into a single claimed coverage percentage:

| Evidence | Current interpretation |
|---|---|
| Minimal baseline, freshly counted | 106 rows: 85 `MATCH`, 18 `UB_MATCH`, 3 `CERB_SKIP`. |
| Csmith baseline, freshly counted | 1,669 rows: 1,161 `MATCH`, 499 `CERB_SKIP`, 9 `TIMEOUT`. Neither skips nor timeouts are agreements. |
| GCC baseline, freshly counted | 1,963 rows: 1,873 `AGREE`; 12 triaged; 78 skip rows of several classes. |
| Recorded larger lanes | CN 213 programs; libxml2 URI 16 inputs and chvalid 1,354 points; fixture/call tests; five speclab families. See `VALIDATION.md` and `scripts/LADDER.md` for exact comparisons. |
| Lem non-Lean net, freshly rerun | Nine emitters, 893 artifact rows and 216 exit rows unchanged. This is corpus/golden compatibility, not proof of all old APIs or upstream equivalence. |

## 3. Corrections and gaps in the handoff record

**Concurrency's two major fixes already exist.** S7 implements initialization
ordering and restores the original `apply_tree` bodies, using measured fuel
and proofs for Lean totality. The handoff's request to make these fixes is
stale. The remaining work is to verify their integration with current mainline,
not recreate them. The branch still predates C4 and P0; its recorded
83/49/13/15/6 fuel census is not the mainline census.

**The csmith run remains unfinished and now has two timeout regressions.**
At the final check, `.tmp/p0-reverify.log` has completed shards 1/6 and 2/6,
with shard 3/6 running. Shard 1 says:

```text
SUMMARY: total=279 match=127 ub_match=0 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=1 hang=0 cerb_skip=151 cerb_floor=0 cerb_inconsistent=0
Baseline check: 0 regression(s), 0 improvement(s)
BASELINE OK
```

Shard 2 subsequently returned rc=1, verbatim:

```text
REGRESSION: sa_csmith_369.c baseline=MATCH current=TIMEOUT
REGRESSION: sa_csmith_371.c baseline=MATCH current=TIMEOUT
Baseline check: 2 regression(s), 0 improvement(s)
FAILED: regressions vs baseline
```

The process list shows a separate existing session rerunning these two
inputs. This assessment has not observed its result. Do not attribute the
timeouts to load, measure overhead, or the extractor repair without
measurement, and do not rebaseline them away. The final six-shard result
and per-row disposition remain owed. The outer script's `tail -6` also
discarded this shard's SUMMARY line from the top-level log.

The preceding raw battery log includes `test_fuel_plant.sh` rc=1. Its
subsequent correction and successful rerun are recorded in
[P0 section F3.7](2026-09-05_p0-instruments-record.md). Consequently “green”
depends on that separate rerun; the original log alone is not all green.
The script prints `DONE` regardless of earlier command failures and does
not invoke all five standalone speclab family gate commands listed in
LADDER. Its completion marker is not full-battery certification.
Collect each shard's exit status and summary, then have the job owner
archive the evidence and remove their worktree/scratch when finished.

**Overview documents overstate or lag the evidence.** README says shared
semantics “by construction” and no ambient state, while the implementation
still has target-specific lowering and mutable enum/digest seams. TODO
retains pre-C4 pending counts and descriptions of already-repaired gates.
The master plan still prints the superseded ordering. The concurrency
worktree has its own stale Z3 status passages. Prefer one current status
table linking immutable history over more overlapping progress narratives.

**Some supposedly durable audit evidence is absent.** At `89f7e6885`, the
whole-project audit evidence directory's `SHA256SUMS` names 22 files: ten
exist and match their hashes; twelve `.log` files are absent from both the
directory and the committed tree. Its README links to these missing logs.
The preserved reproducers and records still matter, but the archive is
incomplete. Recover exact logs if available, otherwise rerun and label new
evidence honestly; do not fabricate the missing historical output.

## 4. Remaining correctness and reasoning risks

| Surface | What is now true | Required next result |
|---|---|---|
| Pure failure | The earlier audit demonstrates an unused `failwith` that raises in OCaml but is erased in Lean, with an axiom-free `rfl` success theorem. `failwithI` still has the same opaque/implemented-by structure. C reachability of the unused-let case is not established. | Census discardable failure on real entry paths; preserve strict failure or establish actual public preconditions. A register or abort-on-panic alone cannot close the defect. |
| Monadic failure | The existing design counts seven hand-written memory-monad sites and 59 generated monadic sites suitable for typed errors; pure `hack`/`finalize` are a separate problem. | Implement typed failure through the existing monads, with propagation evidence and regressions. Finish the reviewed pure-failure design before freezing the new Lem declaration vocabulary. |
| Fuel | Quantification and measured sufficiency are delivered; eight pending workers and general completion/monotonicity remain. | Distinguish no invented success, completion stability, and sufficiency. Prove the needed contracts per family; do not infer them from the zero equation. |
| Well-formed environments | Layout theorems honestly require acyclicity. Raw Core and some accepted C can violate it. | A checked validator with `check = true → Acyclic`, or a proved frontend/linking invariant, and explicit hypotheses at certified entry points. |
| Byte representations | Generic Lem `string`/`char` still map to Lean Unicode types. `p_str_bytes` and `p_str_escapes` remain bug XFAILs. | Implement the designed byte-string/byte-char representation with explicit text conversion at boundaries; remove the XFAILs. Trace C literal/libc/verdict exposure separately. |
| Semantic state | `CerberusImpl.enumRegistryRef` and native digest reads remain behind pure signatures. Core parser symbols still use hashes with a collision tripwire. MemValue comparison has an opaque implementation boundary. | Carry enum/digest values in the environment and mint interned symbols from explicit supply; provide transparent comparison/correspondence where consumers need it. |
| Oracle independence | Lean usually compares against this fork's OCaml. Shared changes can break both in the same way. | Pristine-upstream versus fork execution/API lane; content-pin hand-written oracle deltas. Preserve an independently identified pristine toolchain as a separate assurance step. |
| Verdict instruments | P0 fixes the main extractor, but five named copies remain value-only in whole or part. `test_ci_sweep` is reporting-only and its record is stale. | One byte-preserving verdict codec, explicit set/sequence/multiplicity contracts, exit-status consistency, and plants in every consuming lane. Re-triage newly exposed changes. |
| Resource behavior | Large zero initialization, byte-list memory cost, native stack overflow before fuel exhaustion, and eager measure cost remain registered. | Measure CPU/RSS/completion on real lanes; define profile limits honestly. The one-row ~7% measure result does not establish the aggregate <10% expectation. |
| Consumer adoption | refined-cerberus's main pin is still before the latest representation/fuel/interface work. | Provider manifests and a concrete candidate pin; consumer-owned re-pin with proofs through `[LemFuel]`, map laws and the acyclicity hypotheses. |

The eight pending workers are `are_compatible_aux_lemFuel`, its two
parameter-list siblings, `hack_lemFuel`, `to_pure_lemFuel`,
`to_pures_lemFuel`, `many_lemFuel`, and `many1_lemFuel`.
The compatibility trio encounters an upstream nontermination bug on legal
cross-TU recursive pointer types; by-value acyclicity does not bound it.
Prepare the upstream remedy and test both compatible and incompatible
recursive types. A local semantic repair needs its own ruling.

Lem's generic fail-closed-generation claim also has a registered exception:
`src/lean_backend.ml:5876` still explicitly accepts a user-written
`target_rep` spelled `sorry`. Cerberus's compiled-source gate catches sorry
tokens, but a separate backend customer should receive a generation refusal.
Concurrency's removal of the dead meta-theory target representations helps
clear the consumer obstacle to this small backend fix (Lem TODO 2).

For pure failure, the proposed theorem
`f_exc xs = .ok v → f xs = v` is a useful **success correspondence**, not
full equivalence. An implementation that always fails satisfies it
vacuously. The design must also establish success preservation on the
supported domain and explain strict failure behavior. The old pure mirror
cannot express a discarded exception that its own reduction erases.
Use a precise strict/fallible specification for that direction, or state
explicitly which part remains differential evidence. Do not present the
one-way theorem as resolving the entire trust question.

`Main.batchEscape` needs the planned exposure trace rather than a blind
rewrite: its comment assumes one Lean character per semantic byte, while
other strings represent normal Unicode text. Verify the producer/consumer
contract at each call before choosing per-character or per-UTF-8-byte escaping.

## 5. Concurrency: concrete landing assessment

The prototype adds an explicit `CM_sequential | CM_sc` selector, memory-action
scheduling, candidate execution construction, race verdicts, an SC consistency
check, and integer compare-exchange including weak spurious failure.
The tests use Cerberus's `{-{ ... ||| ... }-}` parallel syntax. This is not
evidence for arbitrary pthread programs, release/acquire/relaxed atomics,
fences, Linux memory ordering, or a complete weak-memory implementation.

S7's two fixes are visible in source. `apply_tree`/`apply_tree_fp_aux`
again retain their original bodies; new Lean declarations and measure proofs
provide totality. Globals initialization and main are sequenced in the
recorded candidate execution. Thirty litmus rows are recorded, including
the new globals and fence cases. The Python reference independently derives
19 SC-class rows, not every kind of row in the 30-program suite.

**New finding CR-1: the litmus lane loses abnormal termination.** In
`scripts/test_litmus.sh:142`, the oracle return status is ignored. At
145–146, `if ! run_lean ...; then lrc=$?` records the status of the negation,
which is zero when the command failed. The lane can therefore accept a
parsable verdict prefix from a run which did not finish. The sequential
refusal leg also discards exit statuses. This contradicts the lane header's
claim that any timeout or kill is a failure.

[The attached executable probe](2026-09-05_litmus-exit-status-probe.py)
extracts the production `tokens_of`, `run_all`, and `is_cap_kill` helpers
and supplies fake engines. It is a harness counterexample, not a new C
semantics counterexample. The observed failure must be fixed and planted
before trusting this lane at merge: capture the original statuses on both
sides, distinguish expected semantic nonzero exits from timeout/signal/
cap failure, and test verdict-then-timeout/kill as well as no-output failure.

**Known correctness debt cannot be hidden by an SC label.** The branch's
VALIDATION explicitly records a quiet wrong answer *inside* its claimed
fragment: pointer-valued locations fail to detect overlapping accesses of
different sizes. It also records SeqRMW sequencing over-approximation.
Before customer-facing SC support, either repair these or enforce a narrower
domain with a checked precondition/refusal. Merely moving the TODO to Phase 1
does not make the current answer sound. Re-audit the exact fragment
predicate against dynamic memory accesses, not just memory-order syntax.

**The accepted consumer agreement theorem is still owed.** The literal
equality of states is false because SC records additional events. The
candidate weaker claim compares verdict observations under both
`epar_free file = true` and `sc_fragment_ok file = true`; it also needs
an appropriate initial-state invariant, explicit fuel accounting and any
further restrictions revealed by the proof. The six sequential identity
lemmas do not prove it. Single-thread SC consistency and silent race checking
are substantive remaining obligations. Keep this work on the semantics side;
do not silently transfer an accepted provider obligation to refined-cerberus.

The landing sequence I recommend is:

1. Rebase an integration copy onto a frozen current mainline. Preserve C4's
   hypotheses and P0's repaired gates. Resolve the upstream-tray number
   collision: mainline draft 36 is `mk_conv_int`, while this branch also
   uses 36 for `_Atomic` qualification. Recompute all census/pin claims.
2. Repair CR-1 and audit the litmus observation codec: its set projection
   deliberately omits stdout/stderr, UB location, and multiplicity. Keep
   outcome-set expectations, but also compare the complete observations
   needed for port parity. Add abnormal-exit plants.
3. Resolve the mixed-size/SeqRMW domain issues and the agreement-theorem
   disposition explicitly. My preference is provider-side completion of
   the theorem for the supported domain; otherwise an explicitly approved
   experimental landing must not advertise that guarantee.
4. Audit the *whole* final shared-model delta and compatibility surfaces,
   not only the two historical major findings. Default mode now refuses
   parallel spawn, and compare-exchange gains behavior even in sequential
   mode. These are intentional API/behavior changes, not universal
   sequential invariance.
5. Regenerate both targets and test cache-disabled on the rebased candidate;
   run Tier A+B, litmus checks/plants, applicable reporting sweeps, and
   consumer-shaped proof checks. Existing green runs on the old branch
   do not certify the integration head. Then prepare the concrete ff-only
   landing for the operator's normal per-merge review.

General config-as-parameter work should follow this selector integration,
so the same driver surface is not repeatedly redesigned beneath the customer.
General weak memory remains a later, separately scoped project.

## 6. Recommended work order and release exits

The audit response's instrument-first correction is right. I would make
customer-observable behavior and usable proof contracts the unit of progress.

| Order | Deliverable | Owner and acceptance |
|---|---|---|
| 1 | Close P0 evidence and write one current release profile/risk baseline. | Cerberus: collect the existing sweep, reconcile the full lane list and exit codes, repair evidence links. Profile names supported behavior, attributed refusals, inherited upstream defects and open port bugs separately. |
| 2 | Finish the observation instruments and independent oracle comparison. | Cerberus: shared codec including concurrency, content-pinned oracle changes, pristine-versus-fork lane. Plants demonstrate that missing results, byte changes and abnormal exits cannot pass. |
| 3 | Census and settle the pure-failure contract; implement the monadic slice. | Lem + Cerberus: retain the mirror, settle correspondence and failure adequacy before dispatching the larger transform. No shared `.lem` body edits merely for Lean plumbing. |
| 4 | Integrate the scoped concurrency feature through the sequence above. | Cerberus: a bounded near-term deliverable, not postponed until every general backend cleanup. Coordinate its signature change with the consumer pin. |
| 5 | Close byte/state/remaining fuel obligations required by the chosen profile. | Lem byte representation and justified backend lowering; Cerberus environment/symbol purity, checked acyclicity, needed completion/stability proofs. Failures and unsupported inputs must stay distinguishable from successful C outcomes. |
| 6 | Adopt the candidate downstream and measure its cost. | refined-cerberus owns its changes and full proof gate. Providers supply map/comparator laws, measures, reduction lemmas, change manifests, and promptly fix provider defects. Run aggregate timing before performance redesign. |
| 7 | Repeat the risk review, run the fresh adversarial convergence exercise, and cut a supported release. | All claims tied to exact source/compiler/runtime pins and per-lane evidence; no known unguarded wrong answer inside the profile. |

Consolidate Lem's declare families after the failure vocabulary is settled,
and before upstream submission. It improves maintainability and reviewability;
it should not delay fixing observable wrong answers solely to tidy syntax.
Keep Pset/remove laws, constructor-name cleanup, remaining kernel-reduction
issues and emission-state refactoring driven by a concrete consumer need.
The run-loop/large-memory work needs measurements and its existing design
decisions, rather than heartbeat, stack-size or arbitrary-budget increases.

Two practical changes would materially improve release reliability:

* **An executable release runner over the existing lane list.** LADDER
  currently relies on operator procedure; the checked-in GitHub workflows
  are upstream OCaml/CHERI CI, not the Lean release battery, and Lem has no
  `.github` workflow directory. Use one declarative list with per-lane exit
  statuses, source/binary identities and explicit required/reporting status.
  A skip must not serialize as success. This should replace fragile ad-hoc
  chains, not add another parallel set of tests.
* **A clean consumer build rehearsal outside the primed workspace.** The
  current setup depends on generated trees, hand-written copy manifests,
  native objects, local opam/Lake pins, and container tooling. Package or
  document a reproducible bootstrap with no reliance on old artifacts.
  Include a small downstream-shaped proof over the real semantic entry and
  runtime map laws. Keep the complete verification logic downstream.

Use distinct release statements for the sequential supported profile, the
scoped SC feature, and upstream-submission readiness. A sequential consumer
release can proceed without general weak memory or real filesystem support;
it cannot count known wrong answers as absent features unless the unsupported
domain is actually excluded. Upstream submission additionally needs a small
reviewable patch series, non-Lean compatibility evidence, a consolidated
manual, and the operator's filing/publishing actions.

refined-cerberus should not be made to chase each provider commit. Choose
named integration checkpoints and provide exact interface manifests. Its
re-pin and proofs through the final release candidate remain a release exit,
as already ruled. Its C-example scope and E5/E6/E7 implementation remain
that project's responsibility.

## 7. Verification performed for this assessment

Read-only inspection covered both mainlines, the concurrency branch and its
pre-merge audit/S7 response, consumer pin/requests, the release audit and
response, source seams, manifests, test harnesses and the live P0 log.
No agents were delegated and no messages were sent to other projects.

Fresh checks completed on mainline: both binary freshness stamps;
fork-drift gate and ten plants; main verdict extractor plants; execution
totality; fuel census; and `test_unit.sh` including its proof, axiom,
copy/sync, fuel-form, root, and fixture gates. The unit suite exited zero.
All Lean invocations used the repository cap, with `CERB_MEM_MAX=32G`.

On concurrency, both original freshness checks passed and the Python SC
reference derived all 19 SC rows. The new abnormal-exit probe reproduced
CR-1. `test_litmus.sh --check` exited zero after its normal incremental
builds, with this verbatim tail:

```text
SUMMARY: mode=check programs=30 engine_disagreements=0 target_mismatches=0 seq_leg_fail=0 red_classes=none
ALL ROWS AT target
```

The new probe's four verdict-prefix plants all expose CR-1 (the probe exits
1 deliberately when the defect is present):

```text
oracle_rc=0 lean_rc=124 DIFF_FAIL=0 accepted_SET={Specified(0)}
oracle_rc=0 lean_rc=137 DIFF_FAIL=0 accepted_SET={Specified(0)}
oracle_rc=124 lean_rc=0 DIFF_FAIL=0 accepted_SET={Specified(0)}
oracle_rc=137 lean_rc=0 DIFF_FAIL=0 accepted_SET={Specified(0)}
Abnormal-exit plants accepted: 4/4
```

Mainline's `test_exec.sh --check-baseline` also exited zero, verbatim:

```text
SUMMARY: total=106 match=85 ub_match=18 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=3 cerb_floor=0 cerb_inconsistent=0
Baseline check: 0 regression(s), 0 improvement(s)
BASELINE OK
```

On Lem mainline, `LC_ALL=C tests/nonlean-regress/run.sh` through the
project environment wrapper exited zero, verbatim:

```text
nonlean-regress: OK (893 artifact rows, 216 exit rows, 9 emitters, byte-identical to golden)
```

These checks establish the stated sampled behavior and current gate results;
they do not negate the harness counterexample. Ordinary incremental test
builds are not cache-disabled merge certification. Source worktrees remained
clean after testing; the concurrency lane refreshed ignored build products
and driver stamps.

The earlier pure-failure native reproducer and full Lem comprehensive
results are cited from the existing audit; they were not rebuilt in this
assessment. The C-reachable pure-failure census, complete Tier A+B, complete
csmith/CI sweep, clean bootstrap, full concurrency source audit, and actual
consumer re-pin remain work to do. This document does not certify them.
