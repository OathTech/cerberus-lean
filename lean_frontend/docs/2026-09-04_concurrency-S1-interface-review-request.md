# Request to refined-cerberus: review the concurrency model parameter surface before it lands (2026-09-04)

From: the cerberus-lean concurrency branch (`feature/concurrency`), [AGENT],
relayed by the operator. Charter: `2026-09-04_concurrency-phase0-sc-charter.md`
(APPROVED [USER 2026-09-04]); this request discharges its D5 ("consumer
review of §4.1/§4.6 gates S1") and §8 ("handle carefully"). Please reply
in your own repo's dated-record style; the operator relays it back and it
is recorded verbatim in our `docs/` before S1 is coded.

## 1. Why you are being asked

[USER 2026-09-04], verbatim: "I take your point about iris /
refined-cerberus. This is something we should handle carefully." The
charter's §8 names the risk: the semantics side can keep the model a
parameter, but the commitment to SC lives in a logic — Iris's stock heap
and a stable points-to are SC-specific. Nothing below designs your logic;
it fixes the semantics-side facts you will state theorems over, and asks
whether their SHAPE serves you before it exists.

## 2. What changes for you (semantics side, slice S1; nothing lands before your reply)

### 2.1 The selector replaces the bool

Today (generated `Driver.lean:555`):

    drive (tagDefs) (with_concurrency : Bool) (file) (arg_strs) : ndM …

Every one of your production statements is stated over `drive fmapEmpty
false …` (your README :611-616). After S1:

    drive (tagDefs) (model : concurrency_model) (file) (arg_strs) : ndM …

with a new Lem type in `driver.lem`, generated to both targets:

    type concurrency_model =
      | CM_sequential   (* today's single-thread driver; thread spawn REFUSED *)
      | CM_sc           (* Phase 0: SC interleaving over the concrete memory, F_SC only *)

`false` becomes `CM_sequential` — a one-token rewrite in your statements.
`driver2`, `driver_globals`, `process_core_step2`, `perform_action_request2`
thread the selector exactly where they thread the bool today
(`driver.lem:747, :1321-1432, :1564, :1727`). The selector is a plain
inductive: kernel-transparent, `cases`-able, no process state.

### 2.2 `using_concurrency` leaves your cones

Your 2026-09-02 sweep found `CerbGlobal.using_concurrency` reached by 11
exports through the shipped driver (`Core_run_aux.lean:447,457,466,476`
— the `add_to_sb`/`add_to_asw` guards). S1 replaces those reads by the
threaded selector (charter D3: explicit threading through the
`Core_run`/`Core_reduction`/`Core_run_aux` signatures in the `.lem`; no
lem-lean mechanism). One fewer opaque in the reasoning surface
(reasoning-artifact audit row A, step 2, for this constant).

### 2.3 New outcome arms under `CM_sequential`

- Thread spawn (`Step_spawn_threads2`, i.e. Core `Epar`) under
  `CM_sequential` becomes a KILL in the driver monad —
  `kill (Other (DErr_concurrency "…"))` — a typed failure OUTCOME in the
  run's outcome list, never a panic. For your fragment (no `Epar`) the arm
  is unreachable, but your per-redex round classification (`Round.lean`)
  will see a new arm in `process_core_step2`/`advance_step` and may need a
  re-proof of the affected round equation.
- Behaviour under `CM_sequential` for `Epar`-free programs is intended to
  be step-identical to today's `false`. We cannot state that as a theorem
  inside one tree (it relates two versions of a definition); the evidence
  we will supply is (i) the full sequential battery at zero movement,
  (ii) the litmus pin `tests/litmus/before_baseline.txt` re-checked, (iii)
  the generated `Driver.lean`/`Core_run*.lean` textual diff in the S1
  change manifest — please say if you want a fourth form.

### 2.4 What `CM_sc` looks like (Phase 0), if you ever instantiate it

- Scheduler live: `can_advance` marks memory actions non-advanceable, so
  `driver2` picks among threads at every memory action (`ND.pick`, exhaustively
  enumerated by `runND`). Your DECISIONS reading "the scheduler is
  degenerate, we never see schedule changes" stays true under
  `CM_sequential` and becomes FALSE under `CM_sc`.
- Read values are available at issue (the concrete memory is the value
  store). This is the charter's §4.6 RECORDED NON-PARAMETRIC POINT: the
  C11 operational instance (Phase 1) must defer a read's value to commit
  time and the interface does not yet admit that. Any rule you state over
  `CM_sc` that uses "a load returns the current heap value" is an
  SC-instance rule, and we ask that it be labelled as such (§3 Q4).
- Data race ⇒ the trace's outcome is `Undef UB005_data_race` (a kill
  outcome, the library predicate `cmm_csem.lem:1431` deciding it at trace
  end). Programs in F_SC with no race behave exactly as SC interleavings.
- The in-run bridge check (the constructed execution must satisfy the
  library's SC consistency tree) is an internal invariant; its violation
  is fail-noisy. See Q2 for the outcome class we should give it.

### 2.5 A refinement we intend for S1, subject to your view (Q3)

Memory orders in Core are constants after elaboration
(`translation.lem` `translate_memory_order` accepts constant arguments
only), and fences/Linux ops are syntactically visible. So F_SC membership
is DECIDABLE BY A SYNTACTIC SCAN of the Core file. We propose a generated
predicate

    val sc_fragment_ok : Core.file 'a -> bool     (* all atomic orders Seq_cst; no Fence/Linux*; *)

used by `drive … CM_sc …` to REFUSE at entry (a kill with a message naming
the first offending action) — so the refusal is a property of the program,
not of the trace explored — with the per-action dynamic check kept as a
defensive invariant. For you: the DRF-SC hypothesis on a program splits
into (a) `sc_fragment_ok file = true` (computable, `decide`/`rfl`) and
(b) race-freedom (semantic; your logic's job or a premise). We will ship
(a) if you want it.

## 3. Questions

- **Q1 (names, shape).** `concurrency_model` / `CM_sequential` / `CM_sc`
  as an explicit argument of `drive` (charter D3). Any objection to the
  names, the position in the argument list, or the explicit-argument form
  versus a reader-lifted parameter like `tagDefs`? (Explicit is our
  recommendation: it is the plain-Lem reading and needs no lem-lean work.)
- **Q2 (outcome classes).** The spawn refusal and the out-of-fragment
  refusal are `Other (DErr_concurrency <string>)` kills today's error type
  admits. The bridge-check violation is an INTERNAL error class. Do you
  want distinguished constructors (e.g. `DErr_model_refused of …`,
  `DErr_model_inconsistent of …`) instead of the string-carrying
  `DErr_concurrency`, so a theorem can exclude them by constructor rather
  than by string? We lean yes, and would add them in S1 if you agree —
  the cost is a change to `driver_error` your statements may mention.
- **Q3 (§2.5).** Do you want `sc_fragment_ok` shipped as a generated,
  total, `decide`-able predicate? Its exact scope (orders, fences, Linux
  ops; anything else you would want excluded, e.g. `Ewait` shapes)?
- **Q4 (labelling).** Charter §8.3 proposes that any rule or adequacy
  result you state over `CM_sc` carries F_SC membership as an explicit
  premise and is labelled as the SC instance, with adequacy stated over
  the selector where it can be. Does that match how you would want to
  present it, and is there a semantics-side fact that would make it
  easier (e.g. a lemma that `CM_sequential` and `CM_sc` agree on
  `Epar`-free programs — statable inside one tree, and we would prove it)?
- **Q5 (re-pin timing).** S1 cannot be built until the fuel arc's C1
  merges (the tree does not regenerate under lem `742506d` before that).
  Your re-pin onto the concurrency arc will be a forced-semantics-change
  slice on your side (the `drive` argument). Do you want it announced as a
  single re-pin after Phase 0 merges, or staged (S1's signature change
  first, then the rest)?

## 4. What we are NOT asking

Nothing about Iris, your WP, your rules, or Phase 1's weak-memory design.
Phase 1–2 (C11-op / RC11 / LKMM) is out of scope by the charter; the
only Phase-1-facing item here is §2.4's recorded non-parametric point,
so that no `CM_sc` shape is mistaken for the general one.

## 5. Provenance

[USER 2026-09-04]: the charter approval and the "handle carefully"
ruling. [AGENT]: the interface as drafted (§2), the refinement (§2.5),
the questions (§3). Measured cites are from `feature/concurrency` @ S0
(`fc6561a83`) and your `cerberus-heaplang/README.md`, `docs/2026-09-02_p6.1-notes.md`,
`docs/DECISIONS.md` (read-only). Docs-only; nothing coded, merged or pushed.
