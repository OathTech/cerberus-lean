/-
  RelSem.T1 — arc-7 S4 (2026-08-20): T1 THROUGH THE FULL WP ROUTE.

  The slate's smoke theorem (charter T1):

    ∀ x : int-range, outcomes of callND(t1_id, [intValue x])
                       = {Specified(x)}, no UB

  stated as `T1Statement` below (statement-TCB: fuel opsem only — the
  production runner on the pinned Core program term, RelSem/T1File.lean;
  no Iris, no Step, no seqModel in the statement).

  STATUS (S4 record §6): the D5 WP-route derivation and the adequacy
  discharge are PROVED end-to-end below (`t1_wp`, `t1_of_app_eq`),
  together with the direct-route twin (`t1_of_app_eq_direct`, the
  cross-check D5 mandates) and the UB-freedom face — all from ONE
  ∀-quantified Layer-2 hypothesis `T1AppEq`: the harness app equation.
  T1AppEq itself is the app-equation computation (S3's plan), and it is
  BLOCKED this slice on the arc-3 F8 residue: `partial def`s in
  non-slice GENERATED modules on the exec spine's kernel path — probed
  and enumerated this slice (S4 record, escalation event 2):
  Annot.get_loc, Ctype.ctypeEqual, State_exception_undefined
  .stExceptUndef_foldM/_mapM, Core.eq_core_object_type,
  Utils.assoc_adjust/insert/remove (+closure). Partial defs have no
  kernel equations, so NO computation can cross them; totalizing them
  is lem-side work (the arc-3 B1/B2 fuel machinery, .lem/backend —
  outside this slice's zero-lem-changes mandate). The hand-written half
  (CerbMem) WAS totalized this slice, unblocking every memory-model
  step. When the F8 sweep lands, `T1AppEq`'s proof is a Layer-2
  computation and T1 falls out of `t1_of_app_eq` with NO change to
  anything in this file.

  What the conditional theorems VALIDATE now (the smoke-test purpose):
  the entire bridge — language instance, SC state interpretation, the
  lifting rule, iris-lean's adequacy, the behavior discharge — is
  exercised end-to-end by `t1_of_app_eq`'s proof, kernel-checked, with
  the exact axiom pins in RelSem/Audit.lean.

  House rules: no sorry, no axioms. Under the in-build audit.
-/

import RelSem.IrisAdequacy
import RelSem.T1File

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
    (stateIs (hlc := .hasLC) (GF := GF)
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

/-- UB-FREEDOM face ("no UB" in the slate row), through the WP route. -/
theorem t1_ubFree_of_app_eq (happ : T1AppEq) :
    ∀ x : Int, intRange x →
      CallUBFree t1File.tagDefs t1File "id" [intValue x] t1Fs := by
  intro x hx
  refine callUBFree_of_wp (GF := CerbS)
    t1File.tagDefs t1File "id" [intValue x] t1Fs (t1Spec x) ?_
  intro η
  exact t1_wp happ x hx

end RelSem.T1
