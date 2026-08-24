/-
  RelSem.PerStepTacSmoke — arc-16 S3 (2026-08-24): THE TACTIC SMOKE —
  the economics measurement (charter: proof text per fixture on the
  order of tens of lines).

  Three exercises:

  1. `t1_wpK_tac` — S1's T1 smoke client RE-PROVED BY TACTICS: the
     eleven manual WP steps (S1: 11 × ⟨iapply; iframe; iintro⟩ ≈ 47
     tactic lines, each step hand-fed its `app` equation) become a
     SHORT script — `wp_pures` self-computes every deterministic
     stage; only the loop atom's proved equation (`driver2_iter`, the
     committed T1AppEq theorem, REUSED) is fed by hand. Statement
     byte-identical to `t1_wpK`; `T1_perStep_tac : T1Statement` lands
     the committed statement through the tactic route.

  2. PARKED (see §2 below and the S3 record §5/§7): the fully
     self-computing end-to-end walk through the PEELED harness
     `callK2` at fixture scale — blocked by a measured
     term-representation cost wall (whnf state-inlining), not by
     structure; the peel and its adequacy bridge are proved and
     consumed by part 2 at named states.

  3. `two_alloc_frame_tac` — the S2 framing demo re-proved with the
     heap tactics (`wp_store`/`wp_load` consume S2's rules unmodified;
     side conditions self-discharge).

  House rules: no sorry, no new axioms. Under the in-build audit.
-/

import RelSem.PerStepTactics
import RelSem.PerStepSmoke
import RelSem.CerbHeapDemo

set_option autoImplicit false

namespace RelSem.T1

open RelSem.Cerb
open Iris Iris.ProgramLogic Iris.BI

/-! ## 1. The T1 smoke, tactic route (statements identical to S1's) -/

/-- T1's WP over the per-step instance, BY TACTICS: compare `t1_wpK`
    (RelSem/PerStepSmoke.lean) — eleven manual lifting steps, one per
    stage, each hand-fed its equation. Here `wp_pures` self-computes
    stages 1–7 and the post-loop read; THREE equations stay hand-fed
    (all REUSED committed lemmas, zero new per-fixture text): the
    errno composite `k8_errno`, the thread setup `k9_update` (its
    proj-state→named-state defeq bridge is the measured cost cliff —
    S3 record §7), and the loop atom `driver2_iter` (T1's whole loop;
    the peeled per-step route through the loop is exercise 2's parked
    wall). -/
theorem t1_wpK_tac {GF : BundledGFunctors} [CerbGpreS GF]
    [CerbGS .hasLC GF] (x : Int) (hx : intRange x) :
    (stateIs (GF := GF) (initial_driver_state t1File t1Fs)) ⊢
      WP (callK t1File.tagDefs t1File "id" [intValue x])
        @ Stuckness.NotStuck ; ⊤
        {{ o, ⌜∃ r : driver_result, o = Outcome.value r ∧ t1Spec x r⌝ }} := by
  iintro Hst
  wp_pures Hst
  wp_step (k8_errno x) Hst
  wp_step (k9_update x _ (by rfl)) Hst
  wp_step (driver2_iter x hx.1 hx.2) Hst
  wp_pures Hst
  wp_done
  ipureintro
  exact ⟨_, rfl, t1_result_eq x⟩

/-- T1 through the tactic route: the committed statement, unchanged. -/
theorem T1_perStep_tac : T1Statement := by
  intro x hx
  refine kCallHarnessAdequate_of_wp (GF := CerbS)
    t1File.tagDefs t1File "id" [intValue x] t1Fs (t1Spec x) ?_
  intro η
  exact t1_wpK_tac x hx

/-! ## 2. End-to-end by tactics alone, through the PEELED loop —
    PARKED (measured wall, S3 record §7).

    The attempted theorem (T1 at concrete argument 5 through `callK2`,
    stepping the driver iteration per Core step with `wp_pures` alone,
    concluding the committed `CallHarnessAdequate` form via
    `kCallHarnessAdequate_of_wpK2`) is BLOCKED by the compute-forward
    tactic style's cost at fixture-scale states: each self-computed
    step whnf-inlines a full `driver_state` (which carries the whole
    program term in `core_file`), and stepping into the loop exceeds
    the default heartbeat budget inside a single `whnf`
    ((deterministic) timeout at `whnf`, 200000 — measured in
    isolation; the full-module attempt grew past the 64G blast-radius
    cap). Per the heartbeat doctrine this is a DESIGN INPUT, not a
    budget problem: the named canonical fixes (part 2) are per-fixture
    NAMED STATE definitions (the committed T1AppEq pattern — constants
    stay folded, so terms stay small) fed to `wp_step`, or the donor's
    Qq-computed stepping with let-bound states (HeapLang
    `wp_load`-style tactics computing the successor state ONCE,
    outside the goal). The peel itself, its adequacy bridge
    (`kCallHarnessAdequate_of_wpK2`), and the law library are proved
    and unaffected; part 2's T5-by-invariant is their consumer. -/

/-! ## 3. The heap tactics on the framing demo -/

/-- The S2 framing demonstration re-proved with the heap tactics:
    `wp_store`/`wp_load` fire S2's resource rules with their side
    conditions self-discharged; the footprint routing (whose names
    the caller owns) is all that remains. -/
theorem two_alloc_frame_tac {GF : BundledGFunctors} [CerbHeapGS GF]
    {s : Stuckness} {E : CoPset} {Φ : DriveVal → IProp GF}
    {locA : CerbLocation.Loc} {tyA : ctype} {aidA addrA : Int}
    {alA : CerbMem.Allocation} {mvA : CerbMem.MemValue}
    {oldA newA : List CerbMem.AbsByte} {dqaA : DFrac}
    {locB : CerbLocation.Loc} {tyB : ctype} {aidB addrB : Int}
    {alB : CerbMem.Allocation} {bsB : List CerbMem.AbsByte}
    {mvB : CerbMem.MemValue} {dqaB dqbB : DFrac}
    {r : driver_state} {dqr : DFrac}
    {k : CerbMem.Footprint × CerbMem.MemValue → KDriveExpr}
    (hcompatA : CerbMem.ctypeMemCompatible tyA
      (CerbMem.typeofMval mvA) = true)
    (hboundsA : CerbMem.isInBounds alA addrA
      (CerbMem.sizeofCtype tyA) = true)
    (hroA : alA.isReadonly = .IsWritable)
    (hatomicA : CerbMem.isAtomicMemberAccess alA tyA addrA = false)
    (hbytesA : CerbMem.memValueToBytes r.layout_state.funptrmap mvA
      = (r.layout_state.funptrmap, newA))
    (hlenA : newA.length = oldA.length)
    (hboundsB : CerbMem.isInBounds alB addrB
      (CerbMem.sizeofCtype tyB) = true)
    (hatomicB : CerbMem.isAtomicMemberAccess alB tyB addrB = false)
    (hlenB : bsB.length = CerbMem.sizeofCtype tyB)
    (hreconB : CerbMem.reconstructValue
        r.layout_state.lastUsedUnionMembers r.layout_state.funptrmap
        addrB tyB bsB = mvB)
    (hnotboolB : Kit.isBoolTy tyB = false) :
    (restIs (GF := GF) dqr r
        ∗ allocIs aidA dqaA alA ∗ pointsToBytes addrA (.own 1) oldA
        ∗ allocIs aidB dqaB alB ∗ pointsToBytes addrB dqbB bsB) ∗
      ((restIs dqr r
          ∗ allocIs aidA dqaA alA ∗ pointsToBytes addrA (.own 1) newA
          ∗ allocIs aidB dqaB alB ∗ pointsToBytes addrB dqbB bsB)
        -∗ WP (k (.FP .R addrB (CerbMem.sizeofCtype tyB), mvB))
              @ s ; E {{ Φ }}) ⊢
      WP (KExpr.seq (liftMem (CerbMem.storeM locA tyA false
            (.PV (.Prov_some aidA) (.PVconcrete none addrA)) mvA))
          (fun _ => KExpr.seq (liftMem (CerbMem.loadM locB tyB
            (.PV (.Prov_some aidB) (.PVconcrete none addrB)))) k)
        : KDriveExpr) @ s ; E {{ Φ }} := by
  iintro ⟨⟨Hr, HaA, HpA, HaB, HpB⟩, Hcont⟩
  wp_store
  isplitl [Hr HaA HpA]
  · iframe Hr HaA HpA
  iintro ⟨Hr, HaA, HpA⟩
  wp_load
  isplitl [Hr HaB HpB]
  · iframe Hr HaB HpB
  iintro ⟨Hr, HaB, HpB⟩
  iapply Hcont
  iframe Hr HaA HpA HaB HpB

end RelSem.T1
