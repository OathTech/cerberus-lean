# Forward note: keeping weak memory reachable from the SC design (2026-09-30)

Status: forward note, not a plan change. Weak memory stays outside the SC MVP
([SC-CONCURRENCY.md](../../SC-CONCURRENCY.md) §2). This note records which later
routes the SC design should keep cheap, and the design disciplines that follow.
Origin: operator–orchestrator discussion, 2026-09-30. [USER 2026-09-30], verbatim:
"If we later want to extend this 'stepped' style of concurrency to weak memory, I
suppose we can do it for some of the stronger models. But it will be hard for full
C11 concurrency with weird causal loops and reordering", and "Another possible
strategy here is the 'triangular-race freedom' idea, where we prove a theorem that
says the program can't exhibit some property under SC, and therefore it can't
exhibit any 'weird' behaviors". The analysis below is [AGENT].

**Citations are from memory and unverified** (no network in this session). Check
each before relying on it in a design or proof record.

## 1. Two routes beyond SC

**Route A: operational (stepped) weak models.** These extend S1's step function with
a richer memory state.

| Model family | Stepped form | Fit |
|---|---|---|
| x86-TSO | per-thread store buffers; a step executes an instruction or flushes one buffer entry | good |
| Release/acquire, and RC11-style relaxed with `po ∪ rf` acyclic (Lahav et al., PLDI 2017) | per-location timestamped message pools plus per-thread views; a read takes any message at or after its view; synchronization joins views (ORC11, Dang et al., POPL 2020) | good: `po ∪ rf` acyclicity means a read never depends on a later write |
| Relaxed atomics allowing load buffering | promises: a thread may promise a future write and must certify it can fulfil it running alone (Kang et al., POPL 2017; Lee et al., PLDI 2020) | hard: certification is a bounded lookahead inside a step, so steps stop being cheap and the S1 purity/budget laws get much harder |
| "Full C11" axiomatic relaxed semantics | only via run-time graph consistency (Nienhuis et al., OOPSLA 2016, Cerberus's existing engine) | not a target: the model admits out-of-thin-air results, and run-time graph admission is rejected by the master plan (§5) |

**Route B: robustness theorems.** These reason under SC and transfer the result.

- Owens (ECOOP 2010): a program with no *triangular races* in any SC execution has
  the same x86-TSO behaviours as SC behaviours.
- Generalisations: robustness against TSO (Bouajjani, Derevenetc, Meyer, ESOP 2013),
  against release/acquire (Lahav, Margalit, PLDI 2019), observational robustness
  against an RC11-style model (Margalit, Lahav, POPL 2021).
- DRF-SC is the degenerate case, and the SC MVP already depends on it: for programs
  using only non-atomic and `seq_cst` accesses, race-free programs have SC
  behaviour and racy ones are UB (Batty et al., POPL 2011, with RC11's repair of SC
  atomics). S2's race monitor is exactly the "no weird behaviour" check for that
  fragment.

Why Route B suits this project:

- The weak side can stay axiomatic. The meta-theorem "robust under SC ⇒
  behaviours(weak model) = behaviours(SC)" is stated against the reference models
  already generated from `frontend/concurrency/cmm_csem.lem`. No operational weak
  executor is needed.
- The proof is done once, as a meta-theorem. Per-program work is showing the
  robustness condition over SC executions, which suits "boring specs, aggressive
  automation" for lock-based and publication-style code.

Limits:

- Robustness quantifies over all SC executions. A single-execution monitor can only
  find violations; establishing robustness needs exhaustive exploration of a finite
  program or a proof.
- Linux uses its own memory model (LKMM: `READ_ONCE`/`WRITE_ONCE`, kernel fences,
  RCU), not C11. For kernel targets the robustness statement would be against LKMM.
- Mixed-size accesses (Flur et al., POPL 2017) complicate the notion of "same
  location" that race and robustness conditions depend on. Cerberus memory is
  byte-level.

## 2. Disciplines for S1–S4 that keep both routes open

These are design checks for slice reviews, not new gates.

1. **Memory state behind the step.** The step function and configuration must not
   assume "one current value per location" outside the memory model. Route A
   replaces that state with buffers or message pools.
2. **Race monitor in views, not scheduler order.** Keep S2's happens-before tracking
   as frontiers/views over source order and synchronization, never "whoever ran
   last". Release/acquire views and robustness conditions are stated in the same
   terms.
3. **Per-access records keep the access kind.** Route B's conditions need the
   memory order and the kind of each access, not just its footprint, on every
   receipt the monitor sees.
4. **Keep the reference comparison generic.** The WP-C relation to
   `SC_memory_model` should be written so a second reference model (release/acquire,
   RC11) can be substituted. A robustness meta-theorem relates two reference models
   and reuses the same projection from executions.

Suggested order after the SC MVP [AGENT]: Route B for the release/acquire fragment
first (a meta-theorem, no new executor), then an RC11-style views model if
programs outside the robust fragment matter, and Promising only as a separate
research effort.
