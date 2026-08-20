/-
  RelSem.T5Prefix — arc-9 S2 (2026-08-20): T5 GROUNDWORK, banked
  toward the PARKED T5 climb (S2 record §4: the T5 proof is parked
  with findings + pricing; everything here is green and load-bearing
  for the resumption).

  Contents:
  * the T5 PREFIX WALK (callND stages through errno onto the sum-body
    thread) — the T1 prefix pattern ported verbatim to the t5 file,
    now through the kit's `app_liftMem_active` crossing;
  * the conv_loaded_int LADDER PORTABILITY lemmas: the T1 residual
    ladder's steps hold at the t5 file GENERIC IN THE ENVIRONMENT AND
    MEMORY (s1/s2/s3 by rfl; s4 — the range check — by the
    hypothesis-mediated chain). These are the T5 iteration's
    store-operand eval crossings; their env-genericity is what makes
    the parked St-family design (hypothesis-mediated env lookups)
    workable on resumption.

  House rules: no sorry, no axioms. Under the in-build audit.
-/

import RelSem.T5Fixture
import RelSem.Kit.Round
import RelSem.Kit.Mem

set_option autoImplicit false

namespace RelSem.T5

open RelSem RelSem.Cerb RelSem.Slate RelSem.Kit
open RelSem.T1 (aU intCty loadedV xIntV xPtrV thG memInj memD3 errPtr
  allocErr_eq storeErr_eq z0 z1 z2 z3 z4)

/-! ## The prefix walk (T1's prefix_a/prefix_b at the t5 file) -/

/-- Prefix, part 1: callND's resolution/injection stages at `sum`. -/
theorem prefix5_a (n : Int) :
    app (callND t5File.tagDefs t5File "sum" [intValue n])
        (initial_driver_state t5File CerbFS.fs_initial_state)
      = app (callFinish t5File.tagDefs 0 sumT5Sym sumBody [(symN, xPtrV)])
          (mkDr5 thG (memInj n) rsD5 [] 0) := by
  refine (app_bind_active rfl).trans ?_   -- driver_globals
  refine (app_bind_active rfl).trans ?_   -- nd_get
  refine (app_bind_active rfl).trans ?_   -- resolveFunSym
  refine (app_bind_active rfl).trans ?_   -- lookupFunBody
  refine (app_bind_active rfl).trans ?_   -- lookupParamTys
  refine (app_bind_active rfl).trans ?_   -- injectArgs
  rfl

/-- Prefix, part 2: callFinish's thread setup up to driver2 (the errno
    alloc/store through the kit's memory-lens crossing; the T1 memory
    lemmas apply verbatim — the t5 prefix is byte-identical). -/
theorem prefix5_b (n : Int) :
    app (callFinish t5File.tagDefs 0 sumT5Sym sumBody [(symN, xPtrV)])
        (mkDr5 thG (memInj n) rsD5 [] 0)
      = app (nd_bind (driver2 t5File.tagDefs false) finTail5)
          (mkDr5 th0T5 (memD3 n) rsD5 [] 0) := by
  refine (app_bind_active
    (v := (mkDr5 thG (memInj n) rsD5 [] 0).core_state0.thread_states)
    (st' := mkDr5 thG (memInj n) rsD5 [] 0) rfl).trans ?_
  apply (app_bind_active (app_liftMem_active ?hσ ?hmem)).trans
  case hσ => rfl
  case hmem =>
    refine (app_bind_active (allocErr_eq n)).trans ?_
    refine (app_bind_active (storeErr_eq n)).trans ?_
    exact app_nd_return errPtr (memD3 n)
  refine (app_bind_active rfl).trans ?_  -- driver_update_thread_state
  rfl

/-- THE T5 PREFIX WALK, composed. -/
theorem prefix5_walk (n : Int) :
    app (callND t5File.tagDefs t5File "sum" [intValue n])
        (initial_driver_state t5File CerbFS.fs_initial_state)
      = app (nd_bind (driver2 t5File.tagDefs false) finTail5)
          (mkDr5 th0T5 (memD3 n) rsD5 [] 0) :=
  (prefix5_a n).trans (prefix5_b n)

/-! ## conv_loaded_int ladder portability (T1's z-residuals at t5,
    ENV- and MEM-generic) -/

theorem s1_t5 (v : Int) (env : List (Fmap sym value))
    (mem : CerbMem.MemState) :
    step_eval_pexpr t5File.tagDefs 0 CerbLocation.Loc.unknown
      (some (CerbLocation.other "RelSem.callND")) (create_extern_symmap t5File)
      env (some mem) t5File false (z0 v) = Result (Defined (z1 v)) := rfl

theorem s2_t5 (v : Int) (env : List (Fmap sym value))
    (mem : CerbMem.MemState) :
    step_eval_pexpr t5File.tagDefs 0 CerbLocation.Loc.unknown
      (some (CerbLocation.other "RelSem.callND")) (create_extern_symmap t5File)
      env (some mem) t5File false (z1 v) = Result (Defined (z2 v)) := rfl

theorem s3_t5 (v : Int) (env : List (Fmap sym value))
    (mem : CerbMem.MemState) :
    step_eval_pexpr t5File.tagDefs 0 CerbLocation.Loc.unknown
      (some (CerbLocation.other "RelSem.callND")) (create_extern_symmap t5File)
      env (some mem) t5File false (z2 v) = Result (Defined (z3 v)) := rfl

/-- s4 — the range check (where the slate's bound hypotheses enter),
    env/mem-generic at the t5 file. -/
theorem s4_t5 (x : Int) (h1 : -2147483648 ≤ x) (h2 : x ≤ 2147483647)
    (env : List (Fmap sym value)) (mem : CerbMem.MemState) :
    step_eval_pexpr t5File.tagDefs 0 CerbLocation.Loc.unknown
      (some (CerbLocation.other "RelSem.callND")) (create_extern_symmap t5File)
      env (some mem) t5File false (z3 x) = Result (Defined (z4 x)) := by
  have hd1 : decide ((-2147483648:Int) ≤ x) = true := decide_eq_true h1
  have hd2 : decide (x ≤ (2147483647:Int)) = true := decide_eq_true h2
  change exception_undef_bind _ _ = _
  refine (eubind_defined
    (z := (PEval (loadedV x) : generic_pexpr_ Unit sym)) ?hBody).trans ?_
  case hBody =>
    change exception_undef_bind _ _ = _
    refine (eubind_defined
      (z := [(Pexpr [] () (PEval (xIntV x)) : generic_pexpr Unit sym)])
      ?hMap).trans ?_
    case hMap =>
      apply eumapM_one ?hIf
      case hIf =>
        change exception_undef_bind _ _ = _
        refine (eubind_defined
          (z := (PEval (xIntV x) : generic_pexpr_ Unit sym)) ?hIfBody).trans ?_
        case hIfBody =>
          change exception_undef_bind _ _ = _
          refine (eubind_defined
            (z := (Pexpr [] () (PEval Vtrue) : generic_pexpr Unit sym))
            ?hCond).trans ?_
          case hCond =>
            change exception_undef_bind _ _ = _
            refine (eubind_defined
              (z := (PEval Vtrue : generic_pexpr_ Unit sym)) ?hCondBody).trans ?_
            case hCondBody =>
              change exception_undef_bind _ _ = _
              refine (eubind_defined
                (z := (Pexpr [] () (PEval Vtrue) : generic_pexpr Unit sym))
                ?hLe1).trans ?_
              case hLe1 =>
                show step_eval_pexpr_lemFuel 999997 t5File.tagDefs (0+1+1+1)
                  CerbLocation.Loc.unknown (some (CerbLocation.other "RelSem.callND"))
                  (create_extern_symmap t5File) env (some mem) t5File false
                  (Pexpr [] () (PEop OpLe
                    (Pexpr [] () (PEctor Civmin [Pexpr aU () (PEval (Vctype intCty))]))
                    (Pexpr [] () (PEval (xIntV x)))))
                  = Result (Defined (Pexpr [] () (PEval Vtrue)))
                have harm : (if (decide ((-2147483648:Int) ≤ x)) = true
                    then Vtrue else Vfalse) = Vtrue := by rw [hd1]; simp
                conv => rhs; rw [← harm]
                rfl
              change exception_undef_bind _ _ = _
              refine (eubind_defined
                (z := (Pexpr [] () (PEval Vtrue) : generic_pexpr Unit sym))
                ?hLe2).trans ?_
              case hLe2 =>
                show step_eval_pexpr_lemFuel 999997 t5File.tagDefs (0+1+1+1)
                  CerbLocation.Loc.unknown (some (CerbLocation.other "RelSem.callND"))
                  (create_extern_symmap t5File) env (some mem) t5File false
                  (Pexpr [] () (PEop OpLe
                    (Pexpr [] () (PEval (xIntV x)))
                    (Pexpr [] () (PEctor Civmax [Pexpr aU () (PEval (Vctype intCty))]))))
                  = Result (Defined (Pexpr [] () (PEval Vtrue)))
                have harm : (if (decide (x ≤ (2147483647:Int))) = true
                    then Vtrue else Vfalse) = Vtrue := by rw [hd2]; simp
                conv => rhs; rw [← harm]
                rfl
              rfl
            rfl
          rfl
        rfl
    rfl
  rfl

end RelSem.T5
