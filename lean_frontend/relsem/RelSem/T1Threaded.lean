/-
  RelSem.T1Threaded — arc-16 S4 (2026-08-24): T1 AT THE THREADED
  ∀-SEED STATE, re-proved through the S1–S3 machinery (charter S4 +
  the [USER] effect-state amendment).

  Statement: for EVERY fresh-symbol supply seed and every int-range x,
  outcomes of callND(t1_id, [intValue x]) from the seed-parametric
  initial state = {Specified(x)}, no UB — STRONGER than the committed
  ambient `T1Statement` (which is the seed-instantiated image at the
  ambient draw; RelSem/Threaded.lean bridge). Axiom cones: EXACTLY the
  classical trio {propext, Classical.choice, Quot.sound} — no
  `runEffectful` (pinned in Audit.lean).

  Recipe provenance: statement shapes and the seed-free memory-op
  equations follow the parked spike (branch effect-spike @ 7f4100a5c,
  RelSem/T1Threaded.lean there); the proofs are re-derived — the spike
  consumed frozen chase machinery for the driver rounds, which this
  file replaces with ∀-run-state ROUND LEMMAS in the committed
  T3AppEq hand-chain style (the arc-7 pattern; these are the T1
  mechanical-round lemmas the walker had absorbed, restored in
  frame-parametric form). The recorded spike hazard is honored
  everywhere: with the seed ∀-quantified the driver state is OPEN, so
  memory stages route through the kit equations
  (`app_liftND_active` + the memory-level ops), never whole-stage
  whnf.

  The statement-facing discharge is the S1–S3 route: the per-step WP
  walk over the reified harness `callK` (S1 language instance), the
  S3 `wp_step`/`wp_pures`/`wp_done` tactics feeding named-state
  equations (the S3 record's economical regime), landing the threaded
  faces via RelSem/Threaded.lean's adequacy bridges.

  House rules: no sorry, no axioms. Under the in-build audit.
-/

import RelSem.Threaded
import RelSem.PerStepTactics
import RelSem.CerbHeapWalk
import RelSem.T1

set_option autoImplicit false

namespace RelSem.T1

open RelSem RelSem.Cerb

/-! ## The threaded T1 run states (seed-parametric twins of
    rsD3/rsR6/drDone; thread states, memories and traces are seed-free
    on the T1 path and are consumed from RelSem.T1AppEq unchanged).
    Arc-17 S0: emitted through `derive_state` (RelSem/DeriveState.lean
    — abbrev hints + realizations + `_def` equation lemmas; the
    donor-pattern named-state regime). Names and definition bodies are
    byte-identical to the hand `def`s they replace. -/

/-- Post-globals run-state at seed (twin of `rsD3`; the seed is
    carried, never read, on the T1 path). -/
derive_state rsD3_thr (seed : Nat) : core_run_state :=
  { initial_core_run_state_threaded seed
      (collect_labeled_continuations_NEW t1File) with tid_supply := 1 }

/-- The run-state after the load's action-id draw (twin of `rsR6`). -/
derive_state rsR6_thr (seed : Nat) : core_run_state :=
  { rsD3_thr seed with aid_supply := (rsD3_thr seed).aid_supply + 1 }

/-- The final driver state of the threaded harness run (twin of
    `drDone`). -/
derive_state drDone_thr (seed : Nat) (x : Int) : driver_state :=
  mkDr (thDone x) (memD3 x) (rsR6_thr seed) [meLoad x] 7

/-! ## The argument-injection memory ops (seed-free: memory states are
    closed on the T1 path; spike recipe). The ambient route computed
    this stage by whole-stage whnf at the closed ambient state; at the
    open threaded state the stage must route through the kit — these
    are the memory-level equations it consumes. -/

/-- The memValue the caller protocol computes for the T1 argument
    (memValueFromValue's Basic-Integer arm; state-free). -/
theorem memValueFromValue_t1_eq (x : Int) :
    memValueFromValue t1File.tagDefs signed_int (intValue x)
      = some (CerbMem.integerValueMval (Signed Int_)
          (CerbMem.integerIval x)) := rfl

/-- injectArg's pointer arm at the T1 argument, exposed (state-free
    unfolding to the liftMem crossing). -/
theorem injectArg_t1_eq (x : Int) :
    injectArg t1File.tagDefs 0 (BTy_object OTy_pointer) signed_int
        (intValue x)
      = liftMem (nd_bind
          (CerbMem.allocateObject 0 (PrefOther "callND arg")
            (CerbMem.alignofIval signed_int) signed_int none none)
          (fun ptr => nd_bind
            (CerbMem.storeM (CerbLocation.other "callND arg init")
              signed_int false ptr
              (CerbMem.integerValueMval (Signed Int_)
                (CerbMem.integerIval x)))
            (fun _ => nd_return (Vobject (OVpointer ptr))))) := rfl

/-- The post-argument-alloc bytemap (x's object uninitialized). -/
def bmArgAlloc : Std.TreeMap Int CerbMem.AbsByte :=
  (((Std.TreeMap.empty.insert xAddr uninitByte).insert
    (xAddr+1) uninitByte).insert (xAddr+2) uninitByte).insert
    (xAddr+3) uninitByte

/-- Memory after the argument allocation, before its store. -/
def memArgAlloc : CerbMem.MemState :=
  { CerbMem.initialMemState with
    nextAllocId := 1, lastAddress := xAddr,
    allocations := Std.TreeMap.empty.insert 0 allocX,
    bytemap := bmArgAlloc }

/-- The argument object's allocation step (mirror of `allocErr_eq` at
    the empty initial memory). -/
theorem allocArg_eq :
    app (CerbMem.allocateObject 0 (PrefOther "callND arg")
      (CerbMem.alignofIval signed_int) signed_int none none)
      CerbMem.initialMemState
    = (NDactive xPtr, memArgAlloc) := by
  simp only [CerbMem.allocateObject, CerbMem.alignofIval,
    CerbMem.integerIval, app, memArgAlloc, bmArgAlloc, sizeof_int_eq,
    alignof_int_eq, xPtr, xAddr, allocX, uninitByte,
    CerbMem.initialMemState]
  simp [CerbMem.alignDown, CerbMem.writeBytesTo, List.replicate, intCty]
  rfl

-- closed side-facts for the argument store (kernel-trivial; mirror of
-- the errStore facts)
theorem argStore_bytes_fact (x : Int) :
    CerbMem.memValueToBytes []
      (CerbMem.integerValueMval (Signed Int_) (CerbMem.integerIval x))
    = ([], [mkByte x 0, mkByte x 1, mkByte x 2, mkByte x 3]) := rfl
theorem argStore_get_fact :
    ((Std.TreeMap.empty.insert 0 allocX :
        Std.TreeMap Int CerbMem.Allocation)).get? 0 = some allocX := rfl
theorem argStore_compat_fact (x : Int) :
    CerbMem.ctypeMemCompatible signed_int
      (CerbMem.typeofMval (CerbMem.integerValueMval (Signed Int_)
        (CerbMem.integerIval x))) = true := rfl
theorem argStore_bounds_fact :
    CerbMem.isInBounds allocX xAddr 4 = true := rfl
theorem argStore_atomic_fact :
    CerbMem.isAtomicMemberAccess allocX signed_int xAddr = false := rfl

/-- The argument store step (mirror of `storeErr_eq`; lands on the
    `memInj x` the rest of the chain consumes). -/
theorem storeArg_eq (x : Int) :
    app (CerbMem.storeM (CerbLocation.other "callND arg init")
      signed_int false xPtr
      (CerbMem.integerValueMval (Signed Int_) (CerbMem.integerIval x)))
      memArgAlloc
    = (NDactive (CerbMem.Footprint.FP .W xAddr 4), memInj x) := by
  simp only [CerbMem.storeM, app, memArgAlloc, memInj, bmArgAlloc,
    sizeof_int_eq, xPtr, CerbMem.initialMemState,
    argStore_bytes_fact, argStore_get_fact, argStore_compat_fact,
    argStore_atomic_fact]
  simp [CerbMem.writeBytesTo, CerbMem.isInBounds, List.foldl, allocX,
    xAddr]
  rfl

/-! ## The per-stage `app` equations at the threaded states (the WP
    walk's feed; states NAMED — the S3 record's cheap regime). The
    non-memory stages close by `rfl` even at the open state (the spike
    finding: only stages whose whnf crosses the memory lens at an open
    driver state need the kit). -/

/-- The post-globals driver state at seed (the named twin of the S1
    smoke's projection state `sGlob`). -/
def dG_thr (seed : Nat) : driver_state :=
  mkDr thG CerbMem.initialMemState (rsD3_thr seed) [] 0

/-- Stage 1: the globals run (T1 has none; thread 0 is spawned),
    yielding tid 0. -/
theorem k1_thr (seed : Nat) :
    app (driver_globals t1File.tagDefs false t1File)
        (initial_driver_state_threaded seed t1File t1Fs)
      = (NDactive 0, dG_thr seed) := rfl

/-- Stage 3: name resolution (state untouched). -/
theorem k3_thr (seed : Nat) :
    app (resolveFunSym (dG_thr seed).core_file "id") (dG_thr seed)
      = (NDactive idT1Sym, dG_thr seed) := rfl

/-- Stage 4: the designated function's parameters and body. -/
theorem k4_thr (seed : Nat) :
    app (lookupFunBody (dG_thr seed).core_file idT1Sym) (dG_thr seed)
      = (NDactive ([(symX, BTy_object OTy_pointer)], arena0),
         dG_thr seed) := rfl

/-- Stage 5: the funinfo-declared parameter C types. -/
theorem k5_thr (seed : Nat) :
    app (lookupParamTys (dG_thr seed).core_file idT1Sym) (dG_thr seed)
      = (NDactive [signed_int], dG_thr seed) := rfl

/-- The injectArg stage equation at the threaded post-globals state:
    the liftMem crossing by `app_liftND_active` + the two memory
    equations (fully concrete statement — no deferred metavariables;
    spike recipe). -/
theorem injectArg_stage_thr (seed : Nat) (x : Int) :
    app (injectArg t1File.tagDefs 0 (BTy_object OTy_pointer) signed_int
          (intValue x))
        (dG_thr seed)
      = (NDactive (Vobject (OVpointer xPtr)),
         { dG_thr seed with layout_state := memInj x }) := by
  rw [injectArg_t1_eq x]
  exact app_liftND_active _ _ _ _
    ((app_bind_active allocArg_eq).trans
      ((app_bind_active (storeArg_eq x)).trans
        (app_nd_return (Vobject (OVpointer xPtr)) (memInj x))))

/-- Stage 6: THE ARGUMENT INJECTION through the kit (the spike's
    central mechanical finding: at the open state this stage cannot
    close by whole-stage whnf — the memory ops go through
    `app_liftND_active` + the memory-level equations above). -/
theorem k6_thr (seed : Nat) (x : Int) :
    app (injectArgs t1File.tagDefs 0
          [(symX, BTy_object OTy_pointer)] [signed_int] [intValue x])
        (dG_thr seed)
      = (NDactive [(symX, xPtrV)],
         mkDr thG (memInj x) (rsD3_thr seed) [] 0) := by
  show app (nd_bind
      (injectArg t1File.tagDefs 0 (BTy_object OTy_pointer) signed_int
        (intValue x))
      (fun cval => nd_bind (injectArgs t1File.tagDefs 0 [] [] [])
        (fun rest => nd_return ((symX, cval) :: rest))))
    (dG_thr seed) = _
  refine (app_bind_active (injectArg_stage_thr seed x)).trans ?_
  refine (app_bind_active rfl).trans ?_    -- injectArgs [] [] []
  rfl                                      -- nd_return of the bound list

/-- Stage 7: the thread-states read (the singleton pool). -/
theorem k7_thr (seed : Nat) (x : Int) :
    app get_thread_states (mkDr thG (memInj x) (rsD3_thr seed) [] 0)
      = (NDactive [(0, (none, thG))],
         mkDr thG (memInj x) (rsD3_thr seed) [] 0) := rfl

/-- Stage 8: the errno allocate+store through the memory lens (REUSED:
    T1AppEq's `allocErr_eq`/`storeErr_eq`, seed-free memory states). -/
theorem k8_thr (seed : Nat) (x : Int) :
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
      (mkDr thG (memInj x) (rsD3_thr seed) [] 0)
      = (NDactive errPtr, mkDr thG (memD3 x) (rsD3_thr seed) [] 0) := by
  have hmem : app errAllocM (memInj x) = (NDactive errPtr, memD3 x) :=
    (app_bind_active (allocErr_eq x)).trans
      ((app_bind_active (storeErr_eq x)).trans
        (app_nd_return errPtr (memD3 x)))
  exact app_liftND_active _ _ _ _ hmem

/-- Stage 9: the thread setup (arena ← the designated body, params
    bound, errno wired) — the state lands on the committed `th0`. -/
theorem k9_thr (seed : Nat) (x : Int) (th : thread_state)
    (hth : th = th0) :
    app (driver_update_thread_state 0 th : driverM Unit)
        (mkDr thG (memD3 x) (rsD3_thr seed) [] 0)
      = (NDactive (), mkDr th0 (memD3 x) (rsD3_thr seed) [] 0) := by
  subst hth; rfl

end RelSem.T1

namespace RelSem.T1
open RelSem RelSem.Cerb RelSem.Kit
open Iris Iris.ProgramLogic Iris.BI

/-! ## The T1 driver rounds, frame-parametric (∀-run-state, T3AppEq
    hand-chain style). These are the mechanical-round lemmas the
    arc-9 walker had absorbed (their arc-7 predecessors were deleted
    then), restored because the ∀-seed chain needs walker-free
    proofs; the intermediate arenas/threads are transcribed from the
    kernel's own reduction (session goal display). R3 (the load) and
    R6 (the conv eval) are the committed `round3`/`round6` (both ∀-rs,
    reused as-is; round6 via the arc-17 S1 `erun_jump_m` construct
    law — its `round6_thr` twin is dissolved). -/

/-- Arena after R0 (the Ewseq's left operand evaluated). -/
def arena1 : RExpr :=
  Expr aU (Esseq patA500
    (Expr aU (Ebound (Expr aU (Ewseq patA499
      (Expr aU (Epure (Pexpr [] () (PEval xPtrV))))
      (loadE (Pexpr aU () (PEval (Vctype intCty)))
             (Pexpr aU () (PEsym symA524)))))))
    bodyTail)

def th1 : thread_state := mkTh arena1 env0

/-- R0: the Ewseq's left pure operand evaluates (a_524's value). -/
theorem round0_thr (x : Int) (fuel : Nat) (rs : core_run_state)
    (tr : List trace_event) (n : Nat) :
    app (dnms (fuel+1) fmapEmpty [0]) (mkDr th0 (memD3 x) rs tr n)
      = app (dnms fuel fmapEmpty [0]) (mkDr th1 (memD3 x) rs tr (n+1)) := by
  refine (app_bind_active rfl).trans ?_
  refine (app_bind_active rfl).trans ?_
  rfl

/-- Arena after R1 (the Ewseq binds a_524; the Load remains). -/
def arena2 : RExpr :=
  Expr aU (Esseq patA500
    (Expr aU (Ebound (loadE (Pexpr aU () (PEval (Vctype intCty)))
                            (Pexpr aU () (PEsym symA524)))))
    bodyTail)

def th2 : thread_state := mkTh arena2 env2

/-- R1: the Ewseq tau — a_524 bound, the Load exposed. -/
theorem round1_thr (x : Int) (fuel : Nat) (rs : core_run_state)
    (tr : List trace_event) (n : Nat) :
    app (dnms (fuel+1) fmapEmpty [0]) (mkDr th1 (memD3 x) rs tr n)
      = app (dnms fuel fmapEmpty [0]) (mkDr th2 (memD3 x) rs tr (n+1)) := by
  refine (app_bind_active rfl).trans ?_
  refine (app_bind_active rfl).trans ?_
  rfl

/-- R2: the Load's operand pexprs evaluate (lands on the committed
    `th3`/`arena3`). -/
theorem round2_thr (x : Int) (fuel : Nat) (rs : core_run_state)
    (tr : List trace_event) (n : Nat) :
    app (dnms (fuel+1) fmapEmpty [0]) (mkDr th2 (memD3 x) rs tr n)
      = app (dnms fuel fmapEmpty [0]) (mkDr th3 (memD3 x) rs tr (n+1)) := by
  refine (app_bind_active rfl).trans ?_
  refine (app_bind_active rfl).trans ?_
  rfl

/-- Arena after R4 (the Eannot/Ebound around the loaded value
    stripped). -/
def arena5 (v : Int) : RExpr :=
  Expr aU (Esseq patA500
    (Expr [] (Epure (Pexpr [] () (PEval (loadedV v)))))
    bodyTail)

def th5 (v : Int) : thread_state := mkTh (arena5 v) env2

/-- R4: the annotation wrapper around the loaded value strips. -/
theorem round4_thr (x : Int) (fuel : Nat) (rs : core_run_state)
    (tr : List trace_event) (n : Nat) :
    app (dnms (fuel+1) fmapEmpty [0]) (mkDr (th4 x) (memD3 x) rs tr n)
      = app (dnms fuel fmapEmpty [0]) (mkDr (th5 x) (memD3 x) rs tr (n+1)) := by
  refine (app_bind_active rfl).trans ?_
  refine (app_bind_active rfl).trans ?_
  rfl

/-- R5: the Esseq binds a_525 — the body tail is exposed (lands on
    the committed `th6`). -/
theorem round5_thr (x : Int) (fuel : Nat) (rs : core_run_state)
    (tr : List trace_event) (n : Nat) :
    app (dnms (fuel+1) fmapEmpty [0]) (mkDr (th5 x) (memD3 x) rs tr n)
      = app (dnms fuel fmapEmpty [0]) (mkDr (th6 x) (memD3 x) rs tr (n+1)) := by
  refine (app_bind_active rfl).trans ?_
  refine (app_bind_active rfl).trans ?_
  rfl

/-- R7: a_526 evaluates (lands on the committed `th8`). -/
theorem round7_thr (x : Int) (fuel : Nat) (rs : core_run_state)
    (tr : List trace_event) (n : Nat) :
    app (dnms (fuel+1) fmapEmpty [0]) (mkDr (th7 x) (memD3 x) rs tr n)
      = app (dnms fuel fmapEmpty [0]) (mkDr (th8 x) (memD3 x) rs tr (n+1)) := by
  refine (app_bind_active rfl).trans ?_
  refine (app_bind_active rfl).trans ?_
  rfl

/-- R8 (terminal): the fully-evaluated thread offers exactly the done
    step; no thread can advance, the offer accumulates, the round
    returns. -/
theorem round8_thr (x : Int) (fuel : Nat) (rs : core_run_state)
    (tr : List trace_event) (n : Nat) :
    app (dnms (fuel+2) fmapEmpty [0]) (mkDr (th8 x) (memD3 x) rs tr n)
      = (NDactive (accDone x), mkDr (th8 x) (memD3 x) rs tr n) := by
  refine (app_bind_active rfl).trans ?_
  rfl

/-! R6 needs NO twin (arc-17 S1): the committed `round6` is ∀-run-state
    through the `erun_jump_m` construct law — the chain below consumes
    it at `rsR6_thr seed` with the `hlab` hypothesis discharged by
    `rfl` (the twin this dissolved: `round6_thr`, arc-16 S4). -/

/-! ## Composition: the nine rounds chained (walker-free), the
    scheduler pick, the driver2 iteration, THE THREADED T1 APP
    EQUATION -/

/-- The full dnms run at the threaded state (twin of the committed
    `dnms_chain`; the T3AppEq hand-chain composition — `round3` is
    the committed ∀-rs lemma, consumed as-is). -/
theorem dnms_chain_thr (seed : Nat) (x : Int)
    (h1 : -2147483648 ≤ x) (h2 : x ≤ 2147483647) :
    app (dnms lemDefaultFuel fmapEmpty [0])
        (mkDr th0 (memD3 x) (rsD3_thr seed) [] 0)
      = (NDactive (accDone x),
         mkDr (th8 x) (memD3 x) (rsR6_thr seed) [meLoad x] 7) :=
  (round0_thr x 999999 (rsD3_thr seed) [] 0).trans
  ((round1_thr x 999998 (rsD3_thr seed) [] 1).trans
  ((round2_thr x 999997 (rsD3_thr seed) [] 2).trans
  ((round3 x h1 h2 999996 (rsD3_thr seed) [] 3).trans
  ((round4_thr x 999995 (rsR6_thr seed) [meLoad x] 3).trans
  ((round5_thr x 999994 (rsR6_thr seed) [meLoad x] 4).trans
  ((round6 x h1 h2 999993 (memD3 x) (rsR6_thr seed) rfl [meLoad x] 5).trans
  ((round7_thr x 999992 (rsR6_thr seed) [meLoad x] 6).trans
  (round8_thr x 999990 (rsR6_thr seed) [meLoad x] 7))))))))

/-- The scheduler sees exactly the done step (arc-17 S1: through the
    `ndct_offer1` construct law — the per-fixture scheduler text is
    gone). -/
theorem ndct_eq_thr (seed : Nat) (x : Int)
    (h1 : -2147483648 ≤ x) (h2 : x ≤ 2147483647) :
    app (new_drive_core_threads t1File.tagDefs ())
        (mkDr th0 (memD3 x) (rsD3_thr seed) [] 0)
      = (NDactive [(0, some (Step_done2 (loadedV x)))],
         mkDr (th8 x) (memD3 x) (rsR6_thr seed) [meLoad x] 7) :=
  RelSem.Laws.ndct_offer1 rfl
    ((dnms_chain_thr seed x h1 h2).trans (by rfl))

/-- ONE driver2 iteration does the whole run (arc-17 S1: through the
    `driver2_done` construct law — the per-fixture execution-mode
    `cases` dance is gone). -/
theorem driver2_iter_thr (seed : Nat) (x : Int)
    (h1 : -2147483648 ≤ x) (h2 : x ≤ 2147483647) :
    app (driver2 t1File.tagDefs false)
        (mkDr th0 (memD3 x) (rsD3_thr seed) [] 0)
      = (NDactive (), drDone_thr seed x) := by
  show app (driver2_lemFuel (999999+1) t1File.tagDefs false)
    (mkDr th0 (memD3 x) (rsD3_thr seed) [] 0)
    = (NDactive (), drDone_thr seed x)
  exact RelSem.Laws.driver2_done
    (ndct_eq_thr seed x h1 h2) (by rfl)

/-- THE THREADED T1 HARNESS APP EQUATION (twin of `t1_app_eq`,
    ∀-quantified over the supply seed; composed from the k-stage
    equations the WP walk also consumes). -/
theorem t1_app_eq_thr (seed : Nat) (x : Int)
    (h1 : -2147483648 ≤ x) (h2 : x ≤ 2147483647) :
    app (callND t1File.tagDefs t1File "id" [intValue x])
        (initial_driver_state_threaded seed t1File t1Fs)
      = (NDactive (finalize t1File.tagDefs "callND" (drDone_thr seed x)),
         drDone_thr seed x) := by
  refine (app_bind_active (k1_thr seed)).trans ?_       -- driver_globals
  refine (app_bind_active (app_nd_get (dG_thr seed))).trans ?_
  refine (app_bind_active (k3_thr seed)).trans ?_       -- resolveFunSym
  refine (app_bind_active (k4_thr seed)).trans ?_       -- lookupFunBody
  refine (app_bind_active (k5_thr seed)).trans ?_       -- lookupParamTys
  refine (app_bind_active (k6_thr seed x)).trans ?_     -- injectArgs (kit)
  refine (app_bind_active (k7_thr seed x)).trans ?_     -- thread states
  refine (app_bind_active (k8_thr seed x)).trans ?_     -- errno (kit)
  refine (app_bind_active (k9_thr seed x _ (by rfl))).trans ?_
  refine (app_bind_active (driver2_iter_thr seed x h1 h2)).trans ?_
  refine (app_bind_active rfl).trans ?_          -- finTail's nd_get
  rfl                                            -- nd_return finalize

/-- The finalize result carries the injected integer, Specified (twin
    of `t1_result_eq`). -/
theorem t1_result_eq_thr (seed : Nat) (x : Int) :
    (finalize t1File.tagDefs "callND" (drDone_thr seed x)).dres_core_value
      = intValue x := rfl

/-! ## The statement-facing route (arc-18 C2, THE ONE ROUTE): the
    per-step WP walk over `CerbMemInterp` — the equation supply in
    OPEN-MEMORY form (heap maps free variables, pinned only by
    footprint resources; the C2 probes: the generated code never
    forces the maps except through the memory lens, so the pure
    stages' `rfl` proofs survive verbatim), discharged through the
    heap-route adequacy bridges. The walk carries REST states + the
    footprints it mints; no whole state appears anywhere. -/

/-! ### The rest ladder (the walk's carried state) -/

abbrev rInit (seed : Nat) : driver_state :=
  restOf (initial_driver_state_threaded seed t1File t1Fs)
abbrev rGlob (seed : Nat) : driver_state := restOf (dG_thr seed)
abbrev rArg (seed : Nat) : driver_state := restAllocR (rGlob seed) xAddr
abbrev rErr (seed : Nat) : driver_state := restAllocR (rArg seed) errAddr
abbrev rD3 (seed : Nat) : driver_state :=
  restOf (mkDr th0 (memD3 0) (rsD3_thr seed) [] 0)
abbrev rDone (seed : Nat) (x : Int) : driver_state :=
  restOf (drDone_thr seed x)

/-- The stored byte image of the injected argument. -/
def argBytes (x : Int) : List CerbMem.AbsByte :=
  [mkByte x 0, mkByte x 1, mkByte x 2, mkByte x 3]

/-- The argument object's allocation record, rule-shaped (defeq to
    the committed `allocX`). -/
def allocXW : CerbMem.Allocation :=
  { base := xAddr, size := 4, ty := some signed_int,
    prefix_ := PrefOther "callND arg" }

/-- The errno object's allocation record, rule-shaped (defeq to the
    committed `allocErr`). -/
def allocErrW : CerbMem.Allocation :=
  { base := errAddr, size := 4, ty := some signed_int,
    prefix_ := PrefOther "errno" }

/-! ### The open-memory stage equations (pure stages: the same `rfl`
    at free maps; memory stages: the construct laws + Kit blocks) -/

theorem k1_o (seed : Nat) : ∀ bm am,
    app (driver_globals t1File.tagDefs false t1File)
        (setMaps (rInit seed) bm am)
      = (NDactive 0, setMaps (rGlob seed) bm am) := fun _ _ => rfl

theorem k3_o (seed : Nat) : ∀ bm am,
    app (resolveFunSym (dG_thr seed).core_file "id")
        (setMaps (rGlob seed) bm am)
      = (NDactive idT1Sym, setMaps (rGlob seed) bm am) := fun _ _ => rfl

theorem k4_o (seed : Nat) : ∀ bm am,
    app (lookupFunBody (dG_thr seed).core_file idT1Sym)
        (setMaps (rGlob seed) bm am)
      = (NDactive ([(symX, BTy_object OTy_pointer)], arena0),
         setMaps (rGlob seed) bm am) := fun _ _ => rfl

theorem k5_o (seed : Nat) : ∀ bm am,
    app (lookupParamTys (dG_thr seed).core_file idT1Sym)
        (setMaps (rGlob seed) bm am)
      = (NDactive [signed_int], setMaps (rGlob seed) bm am) :=
  fun _ _ => rfl

/-- The argument-object address arithmetic (the alloc rule's ground
    fact at the concrete rest). -/
theorem argAddr_fact (seed : Nat) :
    ((CerbMem.alignDown
        ((rGlob seed).layout_state.lastAddress - 4).toNat
        ((4 : Int).toNat.max 1) : Nat) : Int) = xAddr := by
  rw [show (rGlob seed).layout_state.lastAddress
    = (281474976710655 : Int) from rfl]
  decide

/-- Stage 6, THE ARGUMENT INJECTION at open maps: the compound's app
    equation through `Laws.inject_ptr_arg1` + the Kit mem blocks. -/
theorem k6_o (seed : Nat) (x : Int) : ∀ bm am,
    app (injectArgs t1File.tagDefs 0
          [(symX, BTy_object OTy_pointer)] [signed_int] [intValue x])
        (setMaps (rGlob seed) bm am)
      = (NDactive [(symX, xPtrV)],
         allocStoreState (restAllocR (rGlob seed) xAddr) bm am xAddr 4
           (argBytes x) 0 allocXW) := by
  intro bm am
  refine Laws.inject_ptr_arg1 (σ := setMaps (rGlob seed) bm am)
    (hmv := memValueFromValue_t1_eq x)
    (halloc := Kit.mem_alloc_block (sz := 4) (a := xAddr)
      (by exact rfl) (argAddr_fact seed) (by exact rfl))
    (hstore := Kit.mem_store_block (ty := signed_int)
      (mv := CerbMem.integerValueMval (Signed Int_)
        (CerbMem.integerIval x))
      (allocId := 0) (addr := xAddr) (alloc := allocXW)
      (fpm := []) (bytes := argBytes x)
      (hcompat := by exact rfl)
      (hget := by
        rw [Kit.writeBytesTo_allocations]
        show (am.insert 0 allocXW).get? 0 = some allocXW
        simp [Std.TreeMap.get?_eq_getElem?, Std.TreeMap.getElem?_insert])
      (hbounds := by exact rfl) (hro := rfl)
      (hatomic := by exact rfl)
      (hbytes := by
        rw [Kit.writeBytesTo_funptrmap]
        exact argStore_bytes_fact x))
    (hout := by
      simp only [writeBytesTo_eq]
      rfl)

theorem k7_o (seed : Nat) : ∀ bm am,
    app get_thread_states (setMaps (rArg seed) bm am)
      = (NDactive [(0, (none, thG))], setMaps (rArg seed) bm am) :=
  fun _ _ => rfl

/-- The errno address arithmetic. -/
theorem errAddr_fact (seed : Nat) :
    ((CerbMem.alignDown
        ((rArg seed).layout_state.lastAddress - 4).toNat
        ((4 : Int).toNat.max 1) : Nat) : Int) = errAddr := by
  rw [show (rArg seed).layout_state.lastAddress = xAddr from rfl]
  decide

/-- Stage 8, THE ERRNO BLOCK at open maps. -/
theorem k8_o (seed : Nat) : ∀ bm am,
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
      (setMaps (rArg seed) bm am)
      = (NDactive errPtr,
         allocStoreState (restAllocR (rArg seed) errAddr) bm am errAddr
           4 [zeroByte, zeroByte, zeroByte, zeroByte]
           1 allocErrW) := by
  intro bm am
  refine Laws.callND_errno (σ := setMaps (rArg seed) bm am)
    (halloc := Kit.mem_alloc_block (sz := 4) (a := errAddr)
      (by exact rfl) (errAddr_fact seed) (by exact rfl))
    (hstore := Kit.mem_store_block (ty := signed_int)
      (mv := CerbMem.integerValueMval (Signed Int_)
        (CerbMem.integerIval 0))
      (allocId := 1) (addr := errAddr)
      (alloc := allocErrW)
      (fpm := []) (bytes := [zeroByte, zeroByte, zeroByte, zeroByte])
      (hcompat := by exact rfl)
      (hget := by
        rw [Kit.writeBytesTo_allocations]
        show (am.insert 1 allocErrW).get? 1 = some allocErrW
        simp [Std.TreeMap.get?_eq_getElem?, Std.TreeMap.getElem?_insert])
      (hbounds := by exact rfl) (hro := rfl)
      (hatomic := by exact rfl)
      (hbytes := by
        rw [Kit.writeBytesTo_funptrmap]
        exact errStore_bytes_fact))
    (hout := by
      simp only [writeBytesTo_eq]
      rfl)

/-- Stage 9, the thread setup (rest-only). -/
theorem k9_o (seed : Nat) (th : thread_state) (hth : th = th0) :
    ∀ bm am,
    app (driver_update_thread_state 0 th : driverM Unit)
        (setMaps (rErr seed) bm am)
      = (NDactive (), setMaps (rD3 seed) bm am) := by
  subst hth; exact fun _ _ => rfl

/-! ### The driver loop at open maps: the dnms rounds re-derived with
    the memory maps FREE (pure rounds: the identical `rfl`s; the load
    round: `Kit.mem_load_block` + the pointwise footprint facts). -/

theorem round0_o (fuel : Nat) (ms : CerbMem.MemState)
    (rs : core_run_state) (tr : List trace_event) (n : Nat) :
    app (dnms (fuel+1) fmapEmpty [0]) (mkDr th0 ms rs tr n)
      = app (dnms fuel fmapEmpty [0]) (mkDr th1 ms rs tr (n+1)) := by
  refine (app_bind_active rfl).trans ?_
  refine (app_bind_active rfl).trans ?_
  rfl

theorem round1_o (fuel : Nat) (ms : CerbMem.MemState)
    (rs : core_run_state) (tr : List trace_event) (n : Nat) :
    app (dnms (fuel+1) fmapEmpty [0]) (mkDr th1 ms rs tr n)
      = app (dnms fuel fmapEmpty [0]) (mkDr th2 ms rs tr (n+1)) := by
  refine (app_bind_active rfl).trans ?_
  refine (app_bind_active rfl).trans ?_
  rfl

theorem round2_o (fuel : Nat) (ms : CerbMem.MemState)
    (rs : core_run_state) (tr : List trace_event) (n : Nat) :
    app (dnms (fuel+1) fmapEmpty [0]) (mkDr th2 ms rs tr n)
      = app (dnms fuel fmapEmpty [0]) (mkDr th3 ms rs tr (n+1)) := by
  refine (app_bind_active rfl).trans ?_
  refine (app_bind_active rfl).trans ?_
  rfl

/-- R3, THE LOAD ROUND at open maps: memory pinned only by the
    argument object's POINTWISE footprint facts (the byte range + the
    allocation record — exactly what the walk's `allocIs`/
    `pointsToBytes` fragments certify). -/
theorem round3_o (x : Int)
    (h1 : -2147483648 ≤ x) (h2 : x ≤ 2147483647) (fuel : Nat)
    (bm : Std.TreeMap Int CerbMem.AbsByte)
    (am : Std.TreeMap Int CerbMem.Allocation)
    (rs : core_run_state) (tr : List trace_event) (n : Nat)
    (hget : am.get? 0 = some allocXW)
    (hb : ∀ i : Nat, (hi : i < (argBytes x).length) →
      bm.get? (xAddr + (i : Int)) = some ((argBytes x)[i])) :
    app (dnms (fuel+1) fmapEmpty [0])
        (mkDr th3 { memRest (memD3 0) with
          bytemap := bm, allocations := am } rs tr n)
      = app (dnms fuel fmapEmpty [0]) (mkDr (th4 x)
          { memRest (memD3 0) with bytemap := bm, allocations := am }
          { rs with aid_supply := rs.aid_supply + 1 }
          (meLoad x :: tr) n) := by
  have hload : app (CerbMem.loadM CerbLocation.Loc.unknown intCty xPtr)
      { memRest (memD3 0) with bytemap := bm, allocations := am }
      = (NDactive (CerbMem.Footprint.FP .R xAddr 4,
          CerbMem.MemValue.MVinteger (Signed Int_) (.IV .Prov_none x)),
         { memRest (memD3 0) with bytemap := bm, allocations := am }) := by
    have hbytes : CerbMem.readBytesFrom
        { memRest (memD3 0) with bytemap := bm, allocations := am }
        xAddr (CerbMem.sizeofCtype intCty)
        = argBytes x := by
      refine readBytesFrom_of_pointwise (by rfl) ?_
      intro i hi
      show bm.get? (xAddr + (i : Int)) = _
      exact hb i hi
    have := Kit.mem_load_block (loc := CerbLocation.Loc.unknown)
      (ty := intCty) (allocId := 0) (addr := xAddr) (um := none)
      (alloc := allocXW)
      (mem := { memRest (memD3 0) with
        bytemap := bm, allocations := am })
      (mv := CerbMem.MemValue.MVinteger (Signed Int_) (.IV .Prov_none x))
      (hdead := rfl) (hget := hget)
      (hbounds := by exact rfl) (hatomic := by exact rfl)
      (hbytes := hbytes)
      (hrecon := reconX_eq x h1 h2)
      (hnotbool := rfl)
    simpa [xPtr, sizeof_intCty_eq] using this
  refine (app_bind_active rfl).trans ?_               -- nd_read (step_ctx)
  apply (app_bind_active ?hadv).trans
  case hadv =>
    apply (app_bind_active ?hreq).trans
    case hreq =>
      refine (app_bind_active rfl).trans ?_           -- liftCore_run
      rw [Kit.perform_unfold]
      refine (app_bind_active rfl).trans ?_           -- aid draw
      rw [Kit.ars_load_unfold]
      apply (app_bind_active (app_liftND_active _ _ _ _ ?hload)).trans
      case hload => exact hload
      apply (app_bind_active (app_liftND_active _ _ _ _ ?hpref)).trans
      case hpref => rfl                               -- prefixOfPointer
      rfl                                             -- nd_update
    rfl                                               -- nd_return NOWAKEUP
  rfl                                                 -- recursion states match

theorem round4_o (x : Int) (fuel : Nat) (ms : CerbMem.MemState)
    (rs : core_run_state) (tr : List trace_event) (n : Nat) :
    app (dnms (fuel+1) fmapEmpty [0]) (mkDr (th4 x) ms rs tr n)
      = app (dnms fuel fmapEmpty [0]) (mkDr (th5 x) ms rs tr (n+1)) := by
  refine (app_bind_active rfl).trans ?_
  refine (app_bind_active rfl).trans ?_
  rfl

theorem round5_o (x : Int) (fuel : Nat) (ms : CerbMem.MemState)
    (rs : core_run_state) (tr : List trace_event) (n : Nat) :
    app (dnms (fuel+1) fmapEmpty [0]) (mkDr (th5 x) ms rs tr n)
      = app (dnms fuel fmapEmpty [0]) (mkDr (th6 x) ms rs tr (n+1)) := by
  refine (app_bind_active rfl).trans ?_
  refine (app_bind_active rfl).trans ?_
  rfl

theorem round7_o (x : Int) (fuel : Nat) (ms : CerbMem.MemState)
    (rs : core_run_state) (tr : List trace_event) (n : Nat) :
    app (dnms (fuel+1) fmapEmpty [0]) (mkDr (th7 x) ms rs tr n)
      = app (dnms fuel fmapEmpty [0]) (mkDr (th8 x) ms rs tr (n+1)) := by
  refine (app_bind_active rfl).trans ?_
  refine (app_bind_active rfl).trans ?_
  rfl

theorem round8_o (x : Int) (fuel : Nat) (ms : CerbMem.MemState)
    (rs : core_run_state) (tr : List trace_event) (n : Nat) :
    app (dnms (fuel+2) fmapEmpty [0]) (mkDr (th8 x) ms rs tr n)
      = (NDactive (accDone x), mkDr (th8 x) ms rs tr n) := by
  refine (app_bind_active rfl).trans ?_
  rfl

/-- THE DRIVER LOOP at open maps: the whole `driver2` atom
    characterized by the rest + the argument object's footprint (the
    errno object is NEVER mentioned — in the walk it rides the frame
    across this entire step: the framing dividend, landed). -/
theorem driver2_o (seed : Nat) (x : Int)
    (h1 : -2147483648 ≤ x) (h2 : x ≤ 2147483647) : ∀ bm am,
    am.get? 0 = some allocXW →
    (∀ i : Nat, (hi : i < (argBytes x).length) →
      bm.get? (xAddr + (i : Int)) = some ((argBytes x)[i])) →
    app (driver2 t1File.tagDefs false) (setMaps (rD3 seed) bm am)
      = (NDactive (), setMaps (rDone seed x) bm am) := by
  intro bm am hget hb
  have hchain : app (dnms lemDefaultFuel fmapEmpty [0])
      (mkDr th0 { memRest (memD3 0) with
        bytemap := bm, allocations := am } (rsD3_thr seed) [] 0)
      = (NDactive (accDone x),
         mkDr (th8 x) { memRest (memD3 0) with
           bytemap := bm, allocations := am }
           (rsR6_thr seed) [meLoad x] 7) :=
    (round0_o 999999 _ (rsD3_thr seed) [] 0).trans
    ((round1_o 999998 _ (rsD3_thr seed) [] 1).trans
    ((round2_o 999997 _ (rsD3_thr seed) [] 2).trans
    ((round3_o x h1 h2 999996 bm am (rsD3_thr seed) [] 3 hget hb).trans
    ((round4_o x 999995 _ (rsR6_thr seed) [meLoad x] 3).trans
    ((round5_o x 999994 _ (rsR6_thr seed) [meLoad x] 4).trans
    ((round6 x h1 h2 999993 _ (rsR6_thr seed) rfl [meLoad x] 5).trans
    ((round7_o x 999992 _ (rsR6_thr seed) [meLoad x] 6).trans
    (round8_o x 999990 _ (rsR6_thr seed) [meLoad x] 7))))))))
  have hndct : app (new_drive_core_threads t1File.tagDefs ())
      (setMaps (rD3 seed) bm am)
      = (NDactive [(0, some (Step_done2 (loadedV x)))],
         mkDr (th8 x) { memRest (memD3 0) with
           bytemap := bm, allocations := am }
           (rsR6_thr seed) [meLoad x] 7) :=
    RelSem.Laws.ndct_offer1 rfl (hchain.trans (by rfl))
  show app (driver2_lemFuel (999999+1) t1File.tagDefs false)
    (setMaps (rD3 seed) bm am) = (NDactive (), setMaps (rDone seed x) bm am)
  exact RelSem.Laws.driver2_done hndct (by rfl)

/-- The terminal readout, uniform over the rest fiber: `finalize`'s
    result projection reads only the rest. -/
theorem t1_post_o (seed : Nat) (x : Int) : ∀ bm am,
    ∃ r : driver_result,
      (Outcome.value (finalize t1File.tagDefs "callND"
          (setMaps (rDone seed x) bm am)) : DriveVal)
        = Outcome.value r ∧ t1Spec x r :=
  fun _ _ => ⟨_, rfl, rfl⟩

/-- T1's WP over the per-step instance at the THREADED initial state,
    ON THE HEAP ROUTE: the walk carries the rest half and the
    footprints it mints; the driver-loop step consumes ONLY the
    argument object's footprint — the errno object's fragments
    (`HalE`/`HptE`) ride the frame across it, untouched. -/
theorem t1_wpK_thr {GF : BundledGFunctors} [CerbHeapGS GF]
    (seed : Nat) (x : Int) (hx : intRange x) :
    (restIs (GF := GF) restHalf (rInit seed)) ⊢
      WP (callK t1File.tagDefs t1File "id" [intValue x])
        @ Stuckness.NotStuck ; ⊤
        {{ o, ⌜∃ r : driver_result, o = Outcome.value r ∧ t1Spec x r⌝ }} := by
  iintro Hst
  wp_rest (k1_o seed) Hst
  wp_get (dG_thr seed) Hst
  wp_rest (k3_o seed) Hst
  wp_rest (k4_o seed) Hst
  wp_rest (k5_o seed) Hst
  wp_argobj (k6_o seed x) (argAddr_fact seed) Hst HalX HptX
  wp_rest (k7_o seed) Hst
  wp_argobj (k8_o seed) (errAddr_fact seed) Hst HalE HptE
  wp_rest (k9_o seed _ (by rfl)) Hst
  wp_read1 (driver2_o seed x hx.1 hx.2) Hst HalX HptX
  wp_fin (t1_post_o seed x) Hst

/-! ## THE THREADED STATEMENTS (the committed conclusion forms at the
    seed-parametric state, ∀-seed in front — STRONGER than the
    ambient originals) -/

/-- THE T1 THREADED HEADLINE (fuel opsem only): for EVERY supply seed
    and every int-range x, every outcome the production runner
    enumerates for `callND(id, [intValue x])` from the threaded
    initial state is `Active r` with `r.dres_core_value = intValue x`. -/
def T1ThreadedStatement : Prop :=
  ∀ (seed : Nat) (x : Int), intRange x →
    CallHarnessAdequateThr seed t1File.tagDefs t1File "id" [intValue x]
      t1Fs (t1Spec x)

/-- **T1 THREADED, UNCONDITIONAL** (through the S1–S3 WP route; cone
    exactly the classical trio). -/
theorem T1Threaded : T1ThreadedStatement := by
  intro seed x hx
  refine kCallHarnessAdequateThrHeap_of_wp (GF := CerbHeapS) seed
    t1File.tagDefs t1File "id" [intValue x] t1Fs (t1Spec x) ?_
  intro η
  exact t1_wpK_thr seed x hx

/-- **T1 THREADED UB-freedom** (same route). -/
theorem T1Threaded_ubFree :
    ∀ (seed : Nat) (x : Int), intRange x →
      CallHarnessUBFreeThr seed t1File.tagDefs t1File "id" [intValue x]
        t1Fs := by
  intro seed x hx
  refine kCallHarnessUBFreeThrHeap_of_wp (GF := CerbHeapS) seed
    t1File.tagDefs t1File "id" [intValue x] t1Fs (t1Spec x) ?_
  intro η
  exact t1_wpK_thr seed x hx

/-- T1's threaded outcome-SET companion: the enumeration is EXACTLY
    the `Active` singleton, for every seed. -/
def T1ThreadedOutcomesStatement : Prop :=
  ∀ (seed : Nat) (x : Int), intRange x →
    CerbND.runND (callND t1File.tagDefs t1File "id" [intValue x])
        (initial_driver_state_threaded seed t1File t1Fs)
      = [(Active (finalize t1File.tagDefs "callND" (drDone_thr seed x)),
          [], drDone_thr seed x)]

/-- **T1's threaded outcome-set singleton** (the `runND_active`
    corollary of the threaded app equation). -/
theorem T1ThreadedOutcomes : T1ThreadedOutcomesStatement :=
  fun seed x hx => runND_active (t1_app_eq_thr seed x hx.1 hx.2)

/-- SANITY, nothing lost (DELIBERATELY impure — consumes the ambient
    bridge, so it and only it here wears `runEffectful`; pinned
    labeled in Audit.lean): the committed ambient `T1Statement` is a
    corollary of the threaded family at the ambient draw. -/
theorem T1_of_threaded : T1Statement := fun x hx =>
  callHarnessAdequate_of_thr (fun seed => T1Threaded seed x hx)

end RelSem.T1
