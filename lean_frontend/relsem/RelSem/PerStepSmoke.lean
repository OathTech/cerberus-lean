/-
  RelSem.PerStepSmoke — arc-16 S1 (2026-08-24): THE SMOKE CLIENT.

  The existence proof that per-step WP reasoning works end to end on
  the new instance: T1 (the pinned fixture, statements untouched)
  walked through `callK` as ELEVEN genuine Iris WP steps — one
  `wpk_seq_active` per harness stage (globals, state read, name
  resolution, body/ptys lookup, the ARGUMENT INJECTION — the
  allocator surface — the thread-states read, the errno
  allocate+store through the memory lens, the thread setup, the
  driver2 loop segment, the final state read) and a `wpk_done`
  discharge; adequacy lands the EXISTING `T1Statement` /
  `CallHarnessUBFree` conclusions through the per-step route.

  HONEST-PREFIX note (per the S1 brief): the per-stage `app`
  equations at concrete states are `rfl` or REUSED committed T1AppEq
  objects (`allocErr_eq`/`storeErr_eq` for the errno pair,
  `driver2_iter` for the loop atom — T1's driver2 loop is genuinely
  ONE iteration, and its equation is a committed theorem; consuming
  it is theorem reuse, not a chase import: this file imports no
  frozen surface). What remains atomic is the INSIDE of that
  iteration (the nine collapsed dnms rounds) — per-Core-step
  peeling is the record §5 design; S3's per-construct laws attach
  there and replace the per-fixture equations wholesale.

  House rules: no sorry, no new axioms. Under the in-build audit.
-/

import RelSem.PerStepCall
import RelSem.PerStepOwnP
import RelSem.T1
import RelSem.T1AppEq

set_option autoImplicit false

open Lem_Basic_classes (ordCompare)

namespace RelSem.T1

open RelSem.Cerb
open Iris Iris.ProgramLogic Iris.BI

/-! ## The per-stage `app` equations (concrete T1 states; values named
    by the committed T1AppEq vocabulary) -/

/-- The post-globals driver state, as a small closed projection term
    (whnf computes it on demand; goals stay compact). -/
def sGlob : driver_state :=
  (app (driver_globals t1File.tagDefs false t1File)
    (initial_driver_state t1File t1Fs)).2

/-- Stage 1: the globals run (T1 has none; thread 0 is spawned),
    yielding tid 0. -/
theorem k1_globals :
    app (driver_globals t1File.tagDefs false t1File)
        (initial_driver_state t1File t1Fs)
      = (NDactive 0, sGlob) := rfl

/-- Stage 3: name resolution (state untouched). -/
theorem k3_resolve :
    app (resolveFunSym sGlob.core_file "id") sGlob
      = (NDactive idT1Sym, sGlob) := rfl

/-- Stage 4: the designated function's parameters and body. -/
theorem k4_body :
    app (lookupFunBody sGlob.core_file idT1Sym) sGlob
      = (NDactive ([(symX, BTy_object OTy_pointer)], arena0), sGlob) := rfl

/-- Stage 5: the funinfo-declared parameter C types. -/
theorem k5_ptys :
    app (lookupParamTys sGlob.core_file idT1Sym) sGlob
      = (NDactive [signed_int], sGlob) := rfl

/-- Stage 6: THE ARGUMENT INJECTION (the caller protocol's allocator
    surface): x's object is allocated and stored; the parameter binds
    to the pointer. -/
theorem k6_inject (x : Int) :
    app (injectArgs t1File.tagDefs 0 [(symX, BTy_object OTy_pointer)]
        [signed_int] [intValue x]) sGlob
      = (NDactive [(symX, xPtrV)], mkDr thG (memInj x) rsD3 [] 0) := rfl

/-- Stage 7: the thread-states read (the singleton pool). -/
theorem k7_ths (x : Int) :
    app get_thread_states (mkDr thG (memInj x) rsD3 [] 0)
      = (NDactive [(0, (none, thG))], mkDr thG (memInj x) rsD3 [] 0) := rfl

/-- Stage 8: the errno allocate+store through the memory lens
    (REUSED: T1AppEq's `allocErr_eq`/`storeErr_eq`, composed exactly
    as the committed prefix walk composes them). -/
theorem k8_errno (x : Int) :
    app (liftMem (nd_bind
        (CerbMem.allocateObject 0 (PrefOther "errno")
          (CerbMem.alignofIval signed_int) signed_int none none)
        (fun (ptr_val : CerbMem.PointerValue) =>
          let zero := CerbMem.integerValueMval (Signed Int_)
            (CerbMem.integerIval (0 : Int))
          nd_bind
            (CerbMem.storeM (CerbLocation.other "errno init")
              signed_int false ptr_val zero)
            (fun (_ : CerbMem.Footprint) => nd_return ptr_val))))
      (mkDr thG (memInj x) rsD3 [] 0)
      = (NDactive errPtr, mkDr thG (memD3 x) rsD3 [] 0) := by
  have hmem : app errAllocM (memInj x) = (NDactive errPtr, memD3 x) :=
    (app_bind_active (allocErr_eq x)).trans
      ((app_bind_active (storeErr_eq x)).trans
        (app_nd_return errPtr (memD3 x)))
  exact app_liftND_active _ _ _ _ hmem

/-- Stage 9: the thread setup (arena ← the designated body, params
    bound, errno wired) — the state lands on the committed `th0`. -/
theorem k9_update (x : Int) (th : thread_state) (hth : th = th0) :
    app (driver_update_thread_state 0 th : driverM Unit)
        (mkDr thG (memD3 x) rsD3 [] 0)
      = (NDactive (), mkDr th0 (memD3 x) rsD3 [] 0) := by
  subst hth; rfl

/-! Stage 10 is REUSED verbatim: `driver2_iter x h1 h2` — one driver2
    iteration (T1's whole loop) from `mkDr th0 (memD3 x) rsD3 [] 0`
    to `drDone x`. Stage 11 is the generic `app_nd_get`. -/

/-! ## The per-step WP proof -/

/-- T1's WP over the PER-STEP instance: eleven lifting steps, one per
    harness stage. Compare the whole-run shell's `t1_wp` (RelSem/
    T1.lean): ONE atomic step consuming the monolithic equation. -/
theorem t1_wpK {GF : BundledGFunctors} [CerbGpreS GF] [CerbGS .hasLC GF]
    (x : Int) (hx : intRange x) :
    (stateIs (GF := GF) (initial_driver_state t1File t1Fs)) ⊢
      WP (callK t1File.tagDefs t1File "id" [intValue x])
        @ Stuckness.NotStuck ; ⊤
        {{ o, ⌜∃ r : driver_result, o = Outcome.value r ∧ t1Spec x r⌝ }} := by
  iintro Hst
  -- 1: globals
  iapply wpk_seq_active k1_globals
  iframe Hst
  iintro Hst
  -- 2: the post-globals state read
  iapply wpk_seq_active (app_nd_get sGlob)
  iframe Hst
  iintro Hst
  -- 3: name resolution
  iapply wpk_seq_active k3_resolve
  iframe Hst
  iintro Hst
  -- 4: body/params lookup
  iapply wpk_seq_active k4_body
  iframe Hst
  iintro Hst
  -- 5: parameter C types
  iapply wpk_seq_active k5_ptys
  iframe Hst
  iintro Hst
  -- 6: the argument injection (allocator surface)
  iapply wpk_seq_active (k6_inject x)
  iframe Hst
  iintro Hst
  -- 7: thread states
  iapply wpk_seq_active (k7_ths x)
  iframe Hst
  iintro Hst
  -- 8: errno allocate+store
  iapply wpk_seq_active (k8_errno x)
  iframe Hst
  iintro Hst
  -- 9: thread setup
  iapply wpk_seq_active (k9_update x _ (by rfl))
  iframe Hst
  iintro Hst
  -- 10: the driver2 loop segment (T1: one iteration; equation REUSED)
  iapply wpk_seq_active (driver2_iter x hx.1 hx.2)
  iframe Hst
  iintro Hst
  -- 11: the final state read
  iapply wpk_seq_active (app_nd_get (drDone x))
  iframe Hst
  iintro Hst
  -- terminal
  iapply wpk_done
  ipureintro
  exact ⟨finalize t1File.tagDefs "callND" (drDone x), rfl, t1_result_eq x⟩

/-! ## The statement-facing conclusions through the per-step route
    (statements UNCHANGED — `T1Statement` and `CallHarnessUBFree` are
    the committed forms; these are NEW theorems beside the old route,
    which stays in place until S4) -/

/-- **T1 through the per-step instance**: same statement, new route. -/
theorem T1_perStep : T1Statement := by
  intro x hx
  refine kCallHarnessAdequate_of_wp (GF := CerbS)
    t1File.tagDefs t1File "id" [intValue x] t1Fs (t1Spec x) ?_
  intro η
  exact t1_wpK x hx

/-- **T1's UB-freedom through the per-step instance**. -/
theorem T1_ubFree_perStep :
    ∀ x : Int, intRange x →
      CallHarnessUBFree t1File.tagDefs t1File "id" [intValue x] t1Fs := by
  intro x hx
  refine kCallHarnessUBFree_of_wp (GF := CerbS)
    t1File.tagDefs t1File "id" [intValue x] t1Fs (t1Spec x) ?_
  intro η
  exact t1_wpK x hx

end RelSem.T1
