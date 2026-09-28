# WP1: selected Core stepping with the production lifecycle

[USER, 2026-09-26] Continue WP1. [AGENT] This experiment addresses the first
execution-boundary problem reproduced by the initial diagnostic. It does not
close WP1 or freeze the execution strategy. The governing master plan remains
`SC-CONCURRENCY.md` on `arc/sc-concurrency`; no Iris work is added.

## Integration and budget

`core_reduction.lem` now exposes `step_ctx_at` for one selected context.
Both it and the eager list wrapper `step_contexts` consume the same interpreter
lambda inside `step_ctx`, whose reduction rules are unchanged. Default driver
calls use `step_contexts`, preserving the original eager map and order.
The consumer abstraction keeps the historical native lambda frame; extracting
the body into a differently named function changed six legacy failure
backtraces and failed the independent oracle comparison. The experimental
caller first enumerates structural contexts, then interprets only the selected
one against the current state. It does not run `new_drive_core_threads` for
choice discovery. Invalid indices, no contexts and syntactically waiting
contexts have distinct outcomes; none implies successful termination.

`driver_globals_with` and `drive_with` factor the existing lifecycle over a
Core-body runner. The sequential entry points supply the original `driver2`.
The experiment supplies a singleton `NDstep SK_core_boundary` instead. The
existing ND bind saves the actual remainder of global initialization, main
startup and finalization. A selected Core transition returning `Step_done2`
uses production `prepare_exit`, then resumes that saved lifecycle. No recursive
`driver2` continuation is captured at the boundary. No new ND constructor or
public SC option is introduced.

The shared [Lem driver experiment](../../frontend/model/driver.lem)
uses an explicit schedule containing one context/local-choice index per
available step. `experiment_bounded` returns `Exp_incomplete` with the full
configuration when the schedule runs out, or `Exp_stopped` with the exact
unused suffix. A step is one selected Core reduction, one selected primitive
ND continuation, or one finite lifecycle segment. In particular, startup's
argument preparation and errno initialization are one administrative segment;
zero steps execute neither. An invalid choice or an empty/blocked classification
also consumes one supplied transition attempt; an already terminal configuration
consumes none. This is **not** a constant-work-per-step claim.

Generated-call fuel remains a separate Lean execution parameter. The same
instance is passed to each newly selected reduction; it is not a global
remaining-fuel counter. Any fuel stored inside an existing local ND or
lifecycle continuation remains inside that continuation. The experiment does
not rewrite it. Fuel failure keeps the production `NDkilled` reason, including
the distinguished fuel-exhaustion error, rather than reporting incomplete.
No state-space exploration budget is implemented here.

## Evidence

Run `python3 scripts/test_sc_wp1.py` under the scoped OCaml environment, after
regenerating both source trees. This invokes capped Lean with
`LEAN_ABORT_ON_PANIC=1` and the native executable from the same Lem source.
Both producers check independently specified fixture expectations:

* A cold program with three `Ebound` reductions uses six steps: startup,
  three reductions, program completion, and finalization. A ten-entry schedule
  returns four entries unused and value 42. Zero budget has no thread or errno
  allocation/store effect.
* A real `Esave`/`Erun` singleton loop yields incomplete at budgets 1, 2, 7 and
  4096, with one available context, exactly budget-minus-one Core reductions
  and only the startup errno receipt. Lean passes at call fuels 64 and 128.
* A finite global initializer suspends before main, resumes into main with its
  value in the environment, and finalizes. A global initializer calling a
  looping Core procedure yields at 100 steps without initializing main's errno.
* Two thread contexts are discovered without executing the unchosen malformed
  `Erun`. The selected real Core store changes a byte from 0 to 42 with one
  WP0 receipt. Selecting the malformed context in separate native/Lean
  processes actually fails; this is the negative control for eager discovery.
* A real Core null load retains its UB reason. Waiting, empty, invalid-choice,
  done and incomplete outcomes remain distinguishable. Zero Lean call fuel
  produces the distinguished fuel failure. An actual ordinary `SeqRMW` request
  is refused without a load/store or memory change.

[SCWP1SteppingProofs.lean](../test/Unit/SCWP1SteppingProofs.lean) proves general
kernel laws over the generated production experiment: schedule concatenation
preserves the **entire** configuration and unused schedule, consumed entries
exactly increment the step count, and Core choice discovery is independent of
memory, run-state supplies, filesystem and lifecycle continuation. These are
operational composition/resource laws. They are not the master plan's required
Core-to-reference source-order lemma.

[SCWP1ContextProofs.lean](../test/Unit/SCWP1ContextProofs.lean) also proves that
every `(context, focus)` returned by production `get_ctx` reconstructs the
original expression under `apply_ctx`. This holds for all Core expressions,
including nested unsequenced, weak/strong sequencing and annotation contexts.
It justifies fresh structural decomposition, not suspending a saved context.
The six public laws use only Lean's standard `propext`, `Classical.choice` and
`Quot.sound` axioms.

`python3 scripts/test_sc_wp1_source.py` adds seven C fixtures through the actual
parser, frontend, linker and experimental lifecycle, on Lean native at call
fuels 256/512. Return-42, member reads (`p.a + p.b`), comma sequencing, a global
and `argc` return their independently specified values. A lowered C singleton
loop yields incomplete at budgets 1/2/7/4096; `x++` reaches the exact SeqRMW
refusal with no hidden RMW load/store. These are selected schedules, not complete
enumerations or concurrent-C support. This source probe complements the paired
Core probe; it does not add a native OCaml C-to-experimental-driver lane.

The source harness appends a small consumer to the **current** `Main.lean`,
renaming only its command-line entry, because that executable root is not an
importable library. It compiles and links natively with the normal driver's
actual link inputs; the frontend's native digest functions cannot run via a
plain interpreter `#eval`. It retains source, generated probe, link-input,
binary and command hashes in `sc-wp1-evidence/stepping-source.json`. No copied
frontend implementation or alternate executor is maintained.

The paired run's source hashes, commands, output hashes and timing are retained
in `sc-wp1-evidence/stepping-paired.json`; its Lean/native output and both
negative-control outputs are retained alongside it. Broad validation is
recorded separately in `sc-wp1-evidence/stepping-validation.json` when complete.

## Limits and next work

This is an executable feasibility instrument, **not SC semantics**. It adds no
interthread race detector, atomic policy, causal summaries, fork/join policy or
axiomatic admission; it retains the existing Core unsequenced checks.
Load/store requests bearing a non-NA order, SeqRMW, memops, FS/external services,
spawn/join, constraint guards/branches and actions unsequenced with a C call are
explicit refusals. `Step_error2` is also classified as a refusal in this
instrument. This is not a total error-encoding API: atomic RMW/fence/CAS and
other forms can reach existing pure TODO failures inside the selected Core
interpreter, just as the malformed-Erun control does. Those failures remain
loud process failures. Local ND choices are resumable, but their treatment is
not yet a concurrent helper-service implementation. General source-order
summaries, concurrent C lowering and the accepted API's failure contract remain due.

The next difficult execution experiment is ordinary **non-atomic SeqRMW**:
load, update and store must be separate schedulable phases. Its existing
update closure captures `mem_st` in `step_ctx`'s interpreter; it cannot simply be saved
across a competing write/deallocation and assumed to use current memory.
Make that dependency explicit and test resumption against current memory.
The completion callback also captures the whole `th_st`/Core context. Two
production-callback counterexamples now make these concerns concrete; both run
at fuels 64/128 in
[SCWP1RMWContinuation.lean](../test/Unit/SCWP1RMWContinuation.lean):

* After an unsequenced sibling store completes, installing the saved callback
  resurrects that store expression. Selecting it produces a duplicate write
  receipt. The positive control uses the ordinary unsuspended handler and
  executes the sibling exactly once.
* A real store of a function pointer updates concrete memory's `funptrmap`.
  A saved RMW updater evaluating `PEcfunction` still sees the old map and fails
  with the function-resolution error. The same production updater regenerated
  against current memory returns 1. This is a synthetic Core metadata case,
  not a demonstrated C lowering or a general stale-byte-read claim.

These manually compose existing callbacks with intervening production Core or
memory operations. They reject **naive suspension of those callbacks**, not
the current unsuspended sequential handler. Suspending the entire C thread can
instead remove intra-expression alternatives. The next experiment must retain
live sibling progress and resume against current memory; no strategy is
accepted here. Compare an explicit pending-operation context with a justified
expansion into existing Core load/update/negative-store forms. The historical
CN/BMC expansion in `Core_aux.seq_rmw` is a candidate to investigate, not an
authority: its positive store and missing forwarding case do not discharge the
required source-order and result obligations.
Similarly audit helpers that perform work inside one Core reduction before
accepting them as bounded/resumable services. Do not generalize this loop
witness into a universal primitive-work bound.

The [follow-up measurements](2026-09-26_sc-wp1-followup-measurements.md) retain
nine small complete Core order-set comparisons, a race-before-loop prefix,
two successful hand-built load/negative-store expansion examples and a
fixed-object retention probe. The nested strong/weak case shows why original
action polarity alone cannot determine the completion frontier. Repeated
negative hoisting retains fresh environment bindings (819 at 8,192 scheduler
entries), in addition to the inherited driver trace. These are diagnostic
results, not a summary invariant, general space bound or accepted RMW rewrite.
The reference/domain caveats and exact reproduction commands are recorded there.

The general source-order/frontier experiment, retention measurements including
thread churn and causal-coordinate/reference accounting, and the substantive
Core-to-reference lemma remain open.
The direct Core interleaving strategy remains a proposal pending those results.
Early landing may separate the conservative factoring from the experimental
machine, but neither is being presented for landing by this record. WP0's
overseer still owns its merge; reconcile prerequisites before a WP1 landing.

## Reviewed bookkeeping changes

The experiment is a separate section of the shared driver, generated on both
targets; the native probe is a separate executable. **Review correction,
September 28 (M2):** keeping the upstream module set unchanged was the original
placement rationale, but a gate constraint does not justify production
structure. This placement remains experimental and needs the ruling
reconciliation or isolation recorded in the
[review response](2026-09-28_sc-wp1-review-response.md) before landing.
The web step-kind renderer handles the new lifecycle marker even though the
default driver never emits it.
`fork_drift_manifest.txt` is deliberately refreshed for these exact source and
generated deltas; a changed checksum is not correctness evidence.

**Review correction, September 28 (S1):** factoring `driver2` into a reused
ND value reduces its construction-time `ENTERING Driver.driver2` debug
messages at OCaml debug levels 2 and above (one per drive instead of one per
global/main invocation). The reviewer measured otherwise identical stdout
and normalized stderr on two programs. This is an observable diagnostic
change, not covered by the default-mode comparisons below; it must be
explicitly accepted or preserved with a thunk in any production extraction.

The failure census still contains 239 sites with the same reach classes.
The context interpreter's unchanged failure leaves remain owned by `step_ctx`
in the same lambda positions. The existing register is unchanged, including
its UNKNOWN entries; no new failure exception is added. The earlier extracted
body moved ten owners and five position classes; the final consumer-based
factoring avoids those changes as well as preserving the native backtraces.

## Validation status

[AGENT] The preliminary full run was interrupted after 34/40 successful
commands because the parallel independent three-engine report detected six
changed legacy exception frames. That report failed; it is not passing
evidence. A still earlier preliminary run stopped at A1 before the fixture
fuel-literal and expected-panic placement corrections. Neither interrupted run
is a completed tier. The revised factoring retains the original interpreter
lambda, and the final full comparison reproduces the six original crash traces.
The comparison rules and upstream-difference register remain unchanged.

The final frozen run, `20260926T082145.545117Z`, completed **40/40 A+B commands**
successfully, with unchanged source, complete selection and no artifact issues.
The command times sum to 4,904.114 seconds (derived, about 82 minutes).
The mandatory 872-row three-engine report also passed with unchanged source:
835 pristine/fork semantic agreements, 28 matching failures, 7 reviewed
differences and 2 interface agreements. The report-only Lean column has 830
agreements, 28 differences, 12 both-undecodable rows and 2 not-applicable rows;
its 40 difference/undecodable IDs exactly match the historical recorded list.
This is not 872-way agreement or a claim that historical failures are fixed.

[stepping-validation.json](sc-wp1-evidence/stepping-validation.json) retains
the exact tested source, generated-code and binary identities, all lane
verdicts/summaries and verified log hashes, and the earlier unsuccessful runs.
The paired Core/SeqRMW diagnostics, seven native Lean C fixtures and six
kernel-law checks also passed. The final record and standalone follow-up
evidence were added after the frozen run; those follow-up probes were checked
separately against the same implementation. Production sources, the Unit tests,
proofs and active manifest sections remain exactly those identified by the
full-run record. Final diff review restored one historical manifest-header
comment accidentally overwritten by the pin refresh, above its first section.
All active sections are byte-identical; the fork-drift gate passed again.
The record retains both manifest hashes and the post-run check.
