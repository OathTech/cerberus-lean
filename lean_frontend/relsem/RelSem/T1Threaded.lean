/-
  RelSem.T1Threaded — EFFECT-AXIOM ELIMINATION SPIKE (2026-08-24,
  [AGENT] worker on branch effect-spike; park-don't-merge by default).

  DEMONSTRATION: the effect state the boundary axioms hide (here: the
  fresh-symbol supply seed) can be modeled INSIDE the machine state,
  after which a nontrivial theorem about a compiled C program carries a
  transitive axiom cone of EXACTLY the classical trio
  {propext, Classical.choice, Quot.sound} — no runEffectful, no
  with_tagDefs, no forceIO.

  SURVEY RESULT (probe, 2026-08-24, this worktree): on the T1 path,
  `runEffectful` enters theorem cones through EXACTLY ONE definition —
  `initial_core_run_state` (generated/Core_run_aux.lean:395), whose
  `sym_supply` field is seeded by the ambient native counter draw
  `runEffectful (fun () => CerberusFresh.freshIntIO ())`. Everything
  else on the path is already clean (classical trio only):
  `callND`, `driver2`, `finalize`, `t1File`, `CerbND.runND`, and all
  of RelSem.T1AppEq's memory/eval/round lemmas that don't mention the
  initial state. `with_tagDefs`/`forceIO` do not enter the T1 cone at
  all (they enter via Mini_pipeline's const-expr driver and Main's
  per-TU loop — neither referenced by the harness path). The machine
  state ALREADY models the supply: mid-run fresh symbols draw from
  `core_run_state.sym_supply` (generated/Core_run.lean:122-127
  `fresh_symbol'`), not from the process counter; only the SEED of
  that field was ambient.

  MECHANISM: `initial_core_run_state_threaded` mirrors the generated
  initial state with the seed as an explicit parameter (the [USER
  2026-08-24] threading mover, statement-layer analogue of the
  f.tagDefs pattern); the T1 app-equation chain is then re-derived at
  the threaded state, ∀-quantified over the seed. Every lemma of
  RelSem.T1AppEq that is initial-state-generic is consumed as-is
  (round3, the memory equations, the conv chain, the walker); only the
  state-mentioning skeleton (prefix walk, round6's run-state pin, the
  composition) is restated. The bridge lemma at the bottom shows the
  ambient-state definition is the threaded one at the ambient draw
  (`rfl`), so the existing T1 statements are seed-instantiated images
  of the threaded family — nothing is lost.

  Statement shape is IDENTICAL to RelSem.T1.T1OutcomesStatement /
  CallHarnessAdequate with `initial_driver_state` replaced by the
  threaded form and `∀ seed` in front. Cones are pinned in-file
  (#guard_msgs), Audit-style.

  House rules: no sorry, no axioms. Spike module — NOT registered in
  the audit's enumerated statement lists (park-don't-merge).
-/

import RelSem.T1

set_option autoImplicit false

namespace RelSem.T1

open RelSem RelSem.Cerb RelSem.Kit

/-! ## The threaded effect state -/

/-- The initial core-run state with the fresh-symbol supply seed as an
    EXPLICIT parameter. Mirrors generated/Core_run_aux.lean:395
    (`initial_core_run_state`) field-for-field; the single change is
    `sym_supply := seed` in place of the ambient draw
    `runEffectful (fun () => CerberusFresh.freshIntIO ())`. -/
def initial_core_run_state_threaded (seed : Nat)
    (xs : Fmap sym (labeled_continuations core_run_annotation)) :
    core_run_state :=
  { tid_supply := 0, aid_supply := 0, excluded_supply := 0,
    sym_supply := seed, labeled := xs }

/-- The initial driver state over the threaded core-run state. Mirrors
    generated/Driver.lean:435 (`initial_driver_state`) field-for-field;
    the single change is the threaded initial core-run state. -/
def initial_driver_state_threaded (seed : Nat)
    (file1 : file core_run_annotation) (fs_state2 : CerbFS.FsState) :
    driver_state :=
  { core_file := file1,
    core_extern := create_extern_symmap file1,
    core_state0 := initial_core_state,
    core_run_state0 := initial_core_run_state_threaded seed
      (collect_labeled_continuations_NEW file1),
    layout_state := CerbMem.initialMemState,
    concurrency_state := symInitialState symInitialPre,
    fs_state0 := fs_state2,
    trace := [],
    symbolic_assoc := fmapEmpty,
    blocked := false,
    dr_step_counter := 0 }

/-! ## The T1 run states, threaded (the seed-parametric twins of
    rsD3/rsR6/drDone; everything not mentioning the initial state is
    consumed from RelSem.T1AppEq unchanged) -/

/-- Post-globals run-state at seed (twin of `rsD3`; the seed is carried,
    never read, on the T1 path). -/
def rsD3_thr (seed : Nat) : core_run_state :=
  { initial_core_run_state_threaded seed
      (collect_labeled_continuations_NEW t1File) with tid_supply := 1 }

/-- The run-state after the load's action-id draw (twin of `rsR6`). -/
def rsR6_thr (seed : Nat) : core_run_state :=
  { rsD3_thr seed with aid_supply := (rsD3_thr seed).aid_supply + 1 }

/-- The final driver state of the threaded harness run (twin of
    `drDone`). -/
def drDone_thr (seed : Nat) (x : Int) : driver_state :=
  mkDr (thDone x) (memD3 x) (rsR6_thr seed) [meLoad x] 7

/-! ## The prefix walk at the threaded state.

    TELEMETRY (the spike's central mechanical finding): the original
    `prefix_a` closes the injectArgs stage with ONE `app_bind_active
    rfl` — a whole-stage whnf through `liftND`'s matcher. That whnf
    only completes when the carried driver state is CLOSED (the
    ambient axiom-seeded state is closed; the elaborator's
    matcher-discriminant reduction will not delta regular definitions
    once the discriminant carries a free variable — verified by
    minimization: the same rfl passes at `sym_supply := 1048577` and
    fails at `sym_supply := seed` for ANY open field, including fields
    the computation never reads). With the seed ∀-quantified the state
    is open, so the memory stage must go through the kit instead
    (`app_liftND_active` + memory-level equations — the arc-7 pattern
    the errno stage and round3 already use). -/

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
  simp [CerbMem.writeBytesTo, CerbMem.isInBounds,
    CerbMem.isAtomicMemberAccess, List.foldl, allocX, xAddr,
    show allocX.isReadonly = .IsWritable from rfl]
  rfl

/-- Prefix walk, part 1a: callND's resolution stages down to the
    injectArgs stage, states written (the non-memory stages close by
    rfl exactly as in `prefix_a`). -/
theorem prefix_a1_thr (seed : Nat) (x : Int) :
    app (callND t1File.tagDefs t1File "id" [intValue x])
        (initial_driver_state_threaded seed t1File CerbFS.fs_initial_state)
      = app (nd_bind (injectArgs t1File.tagDefs 0
              [(symX, BTy_object OTy_pointer)] [signed_int] [intValue x])
            (fun bound => callFinish t1File.tagDefs 0 idT1Sym arena0 bound))
          (mkDr thG CerbMem.initialMemState (rsD3_thr seed) [] 0) := by
  refine (app_bind_active rfl).trans ?_   -- driver_globals
  refine (app_bind_active rfl).trans ?_   -- nd_get
  refine (app_bind_active rfl).trans ?_   -- resolveFunSym
  refine (app_bind_active rfl).trans ?_   -- lookupFunBody
  refine (app_bind_active rfl).trans ?_   -- lookupParamTys
  rfl

/-- The injectArg stage equation at the threaded S5: the liftMem
    crossing by `app_liftND_active` + the two memory equations
    (fully concrete statement — no deferred metavariables). -/
theorem injectArg_stage_thr (seed : Nat) (x : Int) :
    app (injectArg t1File.tagDefs 0 (BTy_object OTy_pointer) signed_int
          (intValue x))
        (mkDr thG CerbMem.initialMemState (rsD3_thr seed) [] 0)
      = (NDactive (Vobject (OVpointer xPtr)),
         { mkDr thG CerbMem.initialMemState (rsD3_thr seed) [] 0 with
             layout_state := memInj x }) := by
  rw [injectArg_t1_eq x]
  exact app_liftND_active _ _ _ _
    ((app_bind_active allocArg_eq).trans
      ((app_bind_active (storeArg_eq x)).trans
        (app_nd_return (Vobject (OVpointer xPtr)) (memInj x))))

/-- The injectArgs stage equation at the threaded S5, kit-style (the
    remaining crossings have CLOSED monadic values, so their rfls
    survive the open state). -/
theorem injectArgs_stage_thr (seed : Nat) (x : Int) :
    app (injectArgs t1File.tagDefs 0
          [(symX, BTy_object OTy_pointer)] [signed_int] [intValue x])
        (mkDr thG CerbMem.initialMemState (rsD3_thr seed) [] 0)
      = (NDactive [(symX, xPtrV)],
         mkDr thG (memInj x) (rsD3_thr seed) [] 0) := by
  show app (nd_bind
      (injectArg t1File.tagDefs 0 (BTy_object OTy_pointer) signed_int
        (intValue x))
      (fun cval => nd_bind (injectArgs t1File.tagDefs 0 [] [] [])
        (fun rest => nd_return ((symX, cval) :: rest))))
    (mkDr thG CerbMem.initialMemState (rsD3_thr seed) [] 0) = _
  refine (app_bind_active (injectArg_stage_thr seed x)).trans ?_
  refine (app_bind_active rfl).trans ?_    -- injectArgs [] [] []
  rfl                                      -- nd_return of the bound list

/-- Prefix walk, part 1b: the injectArgs stage crossing. -/
theorem prefix_a2_thr (seed : Nat) (x : Int) :
    app (nd_bind (injectArgs t1File.tagDefs 0
            [(symX, BTy_object OTy_pointer)] [signed_int] [intValue x])
          (fun bound => callFinish t1File.tagDefs 0 idT1Sym arena0 bound))
        (mkDr thG CerbMem.initialMemState (rsD3_thr seed) [] 0)
      = app (callFinish t1File.tagDefs 0 idT1Sym arena0 [(symX, xPtrV)])
          (mkDr thG (memInj x) (rsD3_thr seed) [] 0) := by
  refine (app_bind_active (injectArgs_stage_thr seed x)).trans ?_
  rfl

/-- Prefix walk, part 1 (twin of `prefix_a`, composed). -/
theorem prefix_a_thr (seed : Nat) (x : Int) :
    app (callND t1File.tagDefs t1File "id" [intValue x])
        (initial_driver_state_threaded seed t1File CerbFS.fs_initial_state)
      = app (callFinish t1File.tagDefs 0 idT1Sym arena0 [(symX, xPtrV)])
          (mkDr thG (memInj x) (rsD3_thr seed) [] 0) :=
  (prefix_a1_thr seed x).trans (prefix_a2_thr seed x)

/-- Prefix walk, part 2 (twin of `prefix_b`). -/
theorem prefix_b_thr (seed : Nat) (x : Int) :
    app (callFinish t1File.tagDefs 0 idT1Sym arena0 [(symX, xPtrV)])
        (mkDr thG (memInj x) (rsD3_thr seed) [] 0)
      = app (nd_bind (driver2 t1File.tagDefs false) finTail)
          (mkDr th0 (memD3 x) (rsD3_thr seed) [] 0) := by
  refine (app_bind_active
    (v := (mkDr thG (memInj x) (rsD3_thr seed) [] 0).core_state0.thread_states)
    (st' := mkDr thG (memInj x) (rsD3_thr seed) [] 0) rfl).trans ?_
  apply (app_bind_active (app_liftND_active _ _ _ _ ?hmem)).trans
  case hmem =>
    refine (app_bind_active (allocErr_eq x)).trans ?_
    refine (app_bind_active (storeErr_eq x)).trans ?_
    exact app_nd_return errPtr (memD3 x)
  refine (app_bind_active rfl).trans ?_  -- driver_update_thread_state
  rfl

/-- THE PREFIX WALK, threaded (twin of `prefix_walk`). -/
theorem prefix_walk_thr (seed : Nat) (x : Int) :
    app (callND t1File.tagDefs t1File "id" [intValue x])
        (initial_driver_state_threaded seed t1File CerbFS.fs_initial_state)
      = app (nd_bind (driver2 t1File.tagDefs false) finTail)
          (mkDr th0 (memD3 x) (rsD3_thr seed) [] 0) :=
  (prefix_a_thr seed x).trans (prefix_b_thr seed x)

/-! ## The driver rounds at the threaded state. `round3` is run-state
    generic and consumed unchanged; only `round6` (whose statement pins
    the run-state for the label resolution) needs a twin. -/

/-- R6, threaded (twin of `round6`). -/
theorem round6_thr (seed : Nat) (x : Int)
    (h1 : -2147483648 ≤ x) (h2 : x ≤ 2147483647)
    (fuel : Nat) (mem : CerbMem.MemState)
    (tr : List trace_event) (n : Nat) :
    app (dnms (fuel+1) fmapEmpty [0])
        (mkDr (th6 x) mem
          { rsD3_thr seed with aid_supply := (rsD3_thr seed).aid_supply + 1 }
          tr n)
      = app (dnms fuel fmapEmpty [0])
        (mkDr (th7 x) mem
          { rsD3_thr seed with aid_supply := (rsD3_thr seed).aid_supply + 1 }
          tr (n+1)) := by
  refine (app_bind_active rfl).trans ?_    -- nd_read (step_ctx)
  apply (app_bind_active ?hadv).trans
  case hadv =>
    refine (app_bind_active rfl).trans ?_  -- rsk match (RSK_eval)
    apply (app_bind_active (liftCore_run_defined ?hM)).trans
    case hM =>
      change stExceptUndef_bind _ _ _ = _
      apply (stub_defined ?hLab).trans        -- runSE label resolution
      case hLab => rfl
      change stExceptUndef_bind _ _ _ = _
      apply (stub_defined ?hFold).trans       -- the args foldM
      case hFold =>
        change stExceptUndef_bind _ _ _ = _
        apply (stub_defined ?hElem).trans
        case hElem =>
          change stExceptUndef_bind _ _ _ = _
          apply (stub_defined (fullEval_conv_eq x h1 h2 _ _)).trans
          rfl
        rfl
      rfl
    rfl
  rfl

/-- The full dnms run at the threaded state (twin of `dnms_chain`;
    same walker calls, `round3` consumed at `rsD3_thr seed`). -/
theorem dnms_chain_thr (seed : Nat) (x : Int)
    (h1 : -2147483648 ≤ x) (h2 : x ≤ 2147483647) :
    app (dnms lemDefaultFuel fmapEmpty [0])
        (mkDr th0 (memD3 x) (rsD3_thr seed) [] 0)
      = (NDactive (accDone x),
         mkDr (th8 x) (memD3 x) (rsR6_thr seed) [meLoad x] 7) := by
  app_walk
  app_walk_step (round3 x h1 h2 999996 (rsD3_thr seed) [] 3)
  app_walk
  app_walk_step (round6_thr seed x h1 h2 999993 (memD3 x) [meLoad x] 5)
  app_walk

/-- The scheduler sees exactly the done step (twin of `ndct_eq`). -/
theorem ndct_eq_thr (seed : Nat) (x : Int)
    (h1 : -2147483648 ≤ x) (h2 : x ≤ 2147483647) :
    app (new_drive_core_threads t1File.tagDefs ())
        (mkDr th0 (memD3 x) (rsD3_thr seed) [] 0)
      = (NDactive [(0, some (Step_done2 (loadedV x)))],
         mkDr (th8 x) (memD3 x) (rsR6_thr seed) [meLoad x] 7) := by
  refine (app_bind_active rfl).trans ?_          -- nd_get (tids)
  refine (app_bind_active (dnms_chain_thr seed x h1 h2)).trans ?_
  rfl                                            -- nd_mapM pick (singleton)

/-- ONE driver2 iteration does the whole run (twin of `driver2_iter`;
    the execution-mode opaque is dispatched by cases exactly as
    there). -/
theorem driver2_iter_thr (seed : Nat) (x : Int)
    (h1 : -2147483648 ≤ x) (h2 : x ≤ 2147483647) :
    app (driver2 t1File.tagDefs false)
        (mkDr th0 (memD3 x) (rsD3_thr seed) [] 0)
      = (NDactive (), drDone_thr seed x) := by
  show app (driver2_lemFuel (999999+1) t1File.tagDefs false)
    (mkDr th0 (memD3 x) (rsD3_thr seed) [] 0)
    = (NDactive (), drDone_thr seed x)
  change app (nd_bind _ _) _ = _
  refine (app_bind_active (ndct_eq_thr seed x h1 h2)).trans ?_
  refine (app_bind_active rfl).trans ?_          -- nd_get
  cases hmode : Lem_Maybe.maybeEqualBy (fun x y => x == y)
      (CerbGlobal.current_execution_mode ())
      (some CerbGlobal.ExecutionMode.random) with
  | true =>
    simp only [reduceIte, bindExhaustive]
    apply (app_bind_active ?hpickT).trans        -- pick (singleton)
    case hpickT => rfl
    apply (app_bind_active ?hdbgT).trans         -- process: print_debug
    case hdbgT => rfl
    rfl                                          -- nd_update (prepare_exit)
  | false =>
    simp only [reduceIte]
    apply (app_bind_active ?hgrd).trans          -- |non_blocked| guard
    case hgrd => rfl
    apply (app_bind_active ?hpickF).trans        -- pick (singleton)
    case hpickF => rfl
    apply (app_bind_active ?hdbgF).trans         -- process: print_debug
    case hdbgF => rfl
    rfl                                          -- nd_update (prepare_exit)

/-- THE THREADED T1 HARNESS APP EQUATION (twin of `t1_app_eq`,
    ∀-quantified over the supply seed). -/
theorem t1_app_eq_thr (seed : Nat) (x : Int)
    (h1 : -2147483648 ≤ x) (h2 : x ≤ 2147483647) :
    app (callND t1File.tagDefs t1File "id" [intValue x])
        (initial_driver_state_threaded seed t1File CerbFS.fs_initial_state)
      = (NDactive (finalize t1File.tagDefs "callND" (drDone_thr seed x)),
         drDone_thr seed x) := by
  refine (prefix_walk_thr seed x).trans ?_
  refine (app_bind_active (driver2_iter_thr seed x h1 h2)).trans ?_
  refine (app_bind_active rfl).trans ?_          -- finTail's nd_get
  rfl                                            -- nd_return finalize

/-- The finalize result carries the injected integer, Specified (twin
    of `t1_result_eq`). -/
theorem t1_result_eq_thr (seed : Nat) (x : Int) :
    (finalize t1File.tagDefs "callND" (drDone_thr seed x)).dres_core_value
      = intValue x := rfl

/-! ## THE DEMONSTRATION STATEMENTS (statement shape identical to
    T1OutcomesStatement / CallHarnessAdequate, with the ambient initial
    state replaced by the threaded one and `∀ seed` in front) -/

/-- T1's outcome-set singleton over the threaded machine state: for
    EVERY supply seed and every int-range x, the production runner's
    enumeration for the T1 call is exactly the `Active` singleton
    carrying `Specified(x)`. -/
def T1ThreadedOutcomesStatement : Prop :=
  ∀ (seed : Nat) (x : Int), intRange x →
    CerbND.runND (callND t1File.tagDefs t1File "id" [intValue x])
        (initial_driver_state_threaded seed t1File t1Fs)
      = [(Active (finalize t1File.tagDefs "callND" (drDone_thr seed x)), [],
          drDone_thr seed x)]

/-- **THE SPIKE HEADLINE**: the outcome-set singleton, unconditional,
    over the threaded state — axiom cone exactly the classical trio
    (pinned below). -/
theorem T1ThreadedOutcomes : T1ThreadedOutcomesStatement := fun seed x hx =>
  runND_active (t1_app_eq_thr seed x hx.1 hx.2)

/-- The harness-adequate face at the threaded state (the
    `CallHarnessAdequate` shape, spelled out because that definition
    bakes in the ambient `initial_driver_state`): every outcome the
    production runner enumerates is `Active r` with
    `r.dres_core_value = intValue x`. -/
theorem t1_threaded_harnessAdequate (seed : Nat) (x : Int)
    (hx : intRange x) :
    ∀ (out : nd_status driver_result driver_error driver_state)
      (tr : List String) (st' : driver_state),
      (out, tr, st') ∈
        CerbND.runND (callND t1File.tagDefs t1File "id" [intValue x])
          (initial_driver_state_threaded seed t1File t1Fs) →
      ∃ r : driver_result,
        out = Active r ∧ r.dres_core_value = intValue x := by
  intro out tr st' hmem
  rw [show (t1Fs : CerbFS.FsState) = CerbFS.fs_initial_state from rfl,
      runND_active (t1_app_eq_thr seed x hx.1 hx.2)] at hmem
  cases hmem with
  | head => exact ⟨_, rfl, t1_result_eq_thr seed x⟩
  | tail _ h' => cases h'

/-! ## The bridge: the ambient definitions are the threaded ones at the
    ambient draw. DELIBERATELY carries `runEffectful` (it mentions the
    ambient state) — it documents that the existing T1 statements are
    seed-instantiated images of the threaded family. Its cone is pinned
    below, LABELED as the impure side. -/

/-- `initial_core_run_state` IS `initial_core_run_state_threaded` at
    the ambient seed draw — definitionally. -/
theorem initial_core_run_state_eq_threaded_ambient
    (xs : Fmap sym (labeled_continuations core_run_annotation)) :
    initial_core_run_state xs
      = initial_core_run_state_threaded
          (runEffectful (fun () => CerberusFresh.freshIntIO ())) xs := rfl

/-- `initial_driver_state` IS `initial_driver_state_threaded` at the
    ambient seed draw — definitionally. -/
theorem initial_driver_state_eq_threaded_ambient
    (file1 : file core_run_annotation) (fs : CerbFS.FsState) :
    initial_driver_state file1 fs
      = initial_driver_state_threaded
          (runEffectful (fun () => CerberusFresh.freshIntIO ()))
          file1 fs := rfl

/-- SANITY (nothing lost): the existing ambient-state T1 app equation
    is a corollary of the threaded family at the ambient draw. -/
example (x : Int) (h1 : -2147483648 ≤ x) (h2 : x ≤ 2147483647) :
    app (callND t1File.tagDefs t1File "id" [intValue x])
        (initial_driver_state t1File CerbFS.fs_initial_state)
      = (NDactive (finalize t1File.tagDefs "callND" (drDone x)), drDone x) :=
  t1_app_eq_thr (runEffectful (fun () => CerberusFresh.freshIntIO ())) x h1 h2

/-! ## CONE PINS (Audit pattern; build-failing) -/

/-- info: 'RelSem.T1.T1ThreadedOutcomes' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms T1ThreadedOutcomes

/-- info: 'RelSem.T1.T1ThreadedOutcomesStatement' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms T1ThreadedOutcomesStatement

/-- info: 'RelSem.T1.t1_threaded_harnessAdequate' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms t1_threaded_harnessAdequate

/-- info: 'RelSem.T1.t1_app_eq_thr' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms t1_app_eq_thr

-- The impure side, LABELED: the bridge mentions the ambient state, so
-- it (and only it) wears the boundary axiom — by design.
/--
info: 'RelSem.T1.initial_driver_state_eq_threaded_ambient' depends on axioms: [propext,
 runEffectful,
 Classical.choice,
 Quot.sound]
-/
#guard_msgs in #print axioms initial_driver_state_eq_threaded_ambient

end RelSem.T1
