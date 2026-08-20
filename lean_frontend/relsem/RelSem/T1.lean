/-
  RelSem.T1 — arc-7 S4 (2026-08-20): T1 THROUGH THE FULL WP ROUTE.

  The slate's smoke theorem (charter T1):

    ∀ x : int-range, outcomes of callND(t1_id, [intValue x])
                       = {Specified(x)}, no UB

  stated as `T1Statement` below (statement-TCB: fuel opsem only — the
  production runner on the pinned Core program term, RelSem/T1File.lean;
  no Iris, no Step, no seqModel in the statement).

  STATUS (arc-7 S5a, 2026-08-20): **T1 IS UNCONDITIONAL.** The F8 fuel
  sweep (frontend/model .lem declares) gave the exec spine kernel
  equations outside the arc-3 11-module boundary, and `T1AppEq` is now
  a THEOREM (`t1AppEq_holds`, discharged by the compositional
  app-equation chain of RelSem/T1AppEq.lean: the prefix walk, nine
  driver rounds — including the byte-roundtrip load and the
  range-checked conv_loaded_int evaluation, where the intRange
  hypothesis enters — and the scheduler/exit glue; every lemma at
  default elaborator budgets). `T1 : T1Statement` goes through the full
  WP route (`t1_of_app_eq`, the D5 ruling); `T1_direct` is the
  direct-route cross-check; `T1_ubFree` is the no-UB face. Exact axiom
  pins in RelSem/Audit.lean: the classical trio + the declared
  boundary (runEffectful; DAEMON deleted in arc-8 S3) — no sorryAx,
  no ofReduce*.

  House rules: no sorry, no axioms. Under the in-build audit.
-/

import RelSem.IrisAdequacy
import RelSem.T1File
import RelSem.T1AppEq

set_option autoImplicit false

namespace RelSem.T1

open RelSem.Cerb
open Iris Iris.ProgramLogic Iris.BI

/-- The C `int` range (LP64 signed int): the slate's T1 precondition
    `P args` — an injected integer must fit the parameter type
    (RelSem/Call.lean fidelity note). -/
def intRange (x : Int) : Prop := -2147483648 ≤ x ∧ x ≤ 2147483647

/-- The harness filesystem state (the driver default, as Main.lean). -/
def t1Fs : CerbFS.FsState := CerbFS.fs_initial_state

/-- T1's pure spec on driver results: the result value is the injected
    integer, Specified. -/
def t1Spec (x : Int) (r : driver_result) : Prop :=
  r.dres_core_value = intValue x

/-- THE T1 HEADLINE STATEMENT (fuel opsem only): every outcome the
    production runner enumerates for `callND(id, [intValue x])` on the
    pinned T1 program is `Active r` with `r.dres_core_value =
    intValue x` — "outcomes = {Specified(x)}, no UB" in the S3
    headline shape. -/
def T1Statement : Prop :=
  ∀ x : Int, intRange x →
    CallHarnessAdequate t1File.tagDefs t1File "id" [intValue x] t1Fs
      (t1Spec x)

/-- THE LAYER-2 RESIDUAL: the ∀-quantified harness app equation (the
    S3 app-equation route's object; see the header for its blocked
    status and the S4 record for pricing). -/
def T1AppEq : Prop :=
  ∀ x : Int, intRange x →
    ∃ (r : driver_result) (st' : driver_state),
      RelSem.app (callND t1File.tagDefs t1File "id" [intValue x])
          (initial_driver_state t1File t1Fs)
        = (NDactive r, st') ∧ t1Spec x r

/-- THE WP DERIVATION (D5's route): from the app equation, the Iris
    weakest-precondition judgment for the T1 harness call — one
    lifting step (`wp_callND` = the R3 rule at the harness), value
    postcondition. -/
theorem t1_wp {GF : BundledGFunctors} [CerbGpreS GF] [CerbGS .hasLC GF]
    (happ : T1AppEq) (x : Int) (hx : intRange x) :
    (stateIs (GF := GF)
        (initial_driver_state t1File t1Fs)) ⊢
      WP (MExpr.running (callND t1File.tagDefs t1File "id" [intValue x])
          : DriveExpr)
        @ Stuckness.NotStuck ; ⊤
        {{ o, ⌜∃ r : driver_result, o = Outcome.value r ∧ t1Spec x r⌝ }} := by
  obtain ⟨r, st', heq, hval⟩ := happ x hx
  iintro Hst
  iapply wp_callND heq
  iframe Hst
  iintro Hst'
  ipureintro
  exact ⟨r, rfl, hval⟩

/-- T1 THROUGH THE FULL WP ROUTE (the D5 ruling, executed): WP
    derivation (`t1_wp`) + adequacy discharge
    (`callHarnessAdequate_of_wp` at the closed functor bundle `CerbS`)
    ⇒ the headline. The conclusion is `T1Statement` — Iris-free. -/
theorem t1_of_app_eq (happ : T1AppEq) : T1Statement := by
  intro x hx
  refine callHarnessAdequate_of_wp (GF := CerbS)
    t1File.tagDefs t1File "id" [intValue x] t1Fs (t1Spec x) ?_
  intro η
  exact t1_wp happ x hx

/-- THE DIRECT-ROUTE TWIN (cross-check scaffolding per D5 — cited, not
    the deliverable route): the same statement discharged through
    `callHarnessAdequate_of_app_active` (S3's terminal-head
    characterization), bypassing Iris entirely. Its agreement with
    `t1_of_app_eq` is the bridge's sanity check: both consume the SAME
    Layer-2 residual. -/
theorem t1_of_app_eq_direct (happ : T1AppEq) : T1Statement := by
  intro x hx
  obtain ⟨r, st', heq, hval⟩ := happ x hx
  exact callHarnessAdequate_of_app_active heq hval

/-! ## THE F8 SWEEP LANDED (arc-7 S5a): `T1AppEq` is now a THEOREM —
    the compositional app-equation chain of RelSem/T1AppEq.lean (prefix
    walk + nine driver rounds incl. the byte-roundtrip load and the
    range-checked conv chain + the scheduler/exit glue). T1 is
    UNCONDITIONAL. -/

/-- THE LAYER-2 RESIDUAL, DISCHARGED. -/
theorem t1AppEq_holds : T1AppEq := by
  intro x hx
  exact ⟨finalize t1File.tagDefs "callND" (drDone x), drDone x,
    t1_app_eq x hx.1 hx.2, t1_result_eq x⟩

/-- **T1, UNCONDITIONAL** (through the full WP route per D5). -/
theorem T1 : T1Statement := t1_of_app_eq t1AppEq_holds

/-- T1's direct-route twin (cross-check scaffolding per D5). -/
theorem T1_direct : T1Statement := t1_of_app_eq_direct t1AppEq_holds

/-- UB-FREEDOM face ("no UB" in the slate row), through the WP route.
    RESTATED CerbND-shaped in arc-7 S5c (audit-1 F2): the conclusion is
    `CallHarnessUBFree` — the production runner's outcome set contains
    no `Undef0` kill; `CallUBFree` (the seqModel form) is now only the
    route's intermediate, never the statement. -/
theorem t1_ubFree_of_app_eq (happ : T1AppEq) :
    ∀ x : Int, intRange x →
      CallHarnessUBFree t1File.tagDefs t1File "id" [intValue x] t1Fs := by
  intro x hx
  refine callHarnessUBFree_of_ubFree ?_
  refine callUBFree_of_wp (GF := CerbS)
    t1File.tagDefs t1File "id" [intValue x] t1Fs (t1Spec x) ?_
  intro η
  exact t1_wp happ x hx

/-- **T1's UB-freedom, UNCONDITIONAL** (WP route; CerbND-shaped
    statement per S5c). -/
theorem T1_ubFree :
    ∀ x : Int, intRange x →
      CallHarnessUBFree t1File.tagDefs t1File "id" [intValue x] t1Fs :=
  t1_ubFree_of_app_eq t1AppEq_holds

/-- T1's outcome-SET companion statement (arc-7 S5c, audit-1 F5): the
    production runner's enumeration for the T1 call is EXACTLY the
    `Active` singleton — "outcomes = {Specified(x)}" literally, as a
    set equation on the fuel opsem. -/
def T1OutcomesStatement : Prop :=
  ∀ x : Int, intRange x →
    CerbND.runND (callND t1File.tagDefs t1File "id" [intValue x])
        (initial_driver_state t1File t1Fs)
      = [(Active (finalize t1File.tagDefs "callND" (drDone x)), [],
          drDone x)]

/-- **T1's outcome-set singleton, UNCONDITIONAL** (the `runND_active`
    corollary of the app equation). -/
theorem T1Outcomes : T1OutcomesStatement := fun x hx =>
  runND_active (t1_app_eq x hx.1 hx.2)

end RelSem.T1
