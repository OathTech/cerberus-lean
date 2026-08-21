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
import RelSem.Kit.Map
import RelSem.Kit.Loop
import RelSem.Tactics.AppWalk

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

/-! ## Arc-9 S3: THE St-v2 FAMILY (design §11.2 — recursive,
    computation-mirroring; drawn ids closed in k under the pinned
    seed). All components are structure LITERALS over recursive
    bytemap/env/trace families, so constant fields project by rfl at
    symbolic k. -/

open RelSem.T1 (mkByte xPtr allocX allocErr)

/-- The loop's running sum, computation-mirroring recursion
    (`sV (k+1)` is DEFINITIONALLY `sV k + k` — the iteration's add). -/
def sV : Nat → Int
  | 0 => 0
  | k + 1 => sV k + (k : Int)

/-- The doubling identity (the closed-form engine; k*k rides as an
    omega atom). -/
theorem sV_double (n : Nat) : 2 * sV n = (n : Int) * ((n : Int) - 1) := by
  induction n with
  | zero => rfl
  | succ k ih =>
    show 2 * (sV k + (k : Int)) = _
    have hc : ((k + 1 : Nat) : Int) = (k : Int) + 1 := by omega
    rw [Int.mul_add, ih, hc]
    have h1 : ((k : Int) + 1) - 1 = (k : Int) := by omega
    rw [h1, Int.add_mul, Int.one_mul, Int.mul_sub, Int.mul_one]
    omega

/-- `sV` in the statement's Int-division closed form. -/
theorem sV_closed (n : Nat) : sV n = (n : Int) * ((n : Int) - 1) / 2 := by
  rw [← sV_double n, Int.mul_ediv_cancel_left _ (by omega : (2:Int) ≠ 0)]

/-- Loaded specified integer (value form). -/
abbrev ldi (v : Int) : value := loadedV v

/-- One env insert in the exact `update_env_aux` reduced spelling
    (the `@mapKeyCompare` passed comparator; the tree's CAPTURED
    comparator stays the callFinish `ordCompare` closure). -/
abbrev eIns (s : sym) (v : value) (m : Fmap sym value) : Fmap sym value :=
  fmapAddBy (@Lem_Map.mapKeyCompare sym _) s v m

/-- The entry environment's base (env0T5's head map, verbatim
    spelling). -/
def e0 : Fmap sym value :=
  List.foldl (fun (m : Fmap sym value) (pv : sym × value) =>
      fmapAddBy (fun (s1 s2 : sym) => Lem_Basic_classes.ordCompare s1 s2)
        pv.1 pv.2 m)
    fmapEmpty [(symN, xPtrV)]

/-- The iteration's 23-insert env chain (executing with i-value `k`;
    census-ordered oldest→newest; the two NEG unit binders are the
    closed-id fresh symbols). -/
def envIter (n : Int) (k : Nat) (e : Fmap sym value) : Fmap sym value :=
  eIns symS sPtrV <| eIns symI iPtrV <|
  eIns (unitSym (2*k+1)) (ldi ((k : Int) + 1)) <|
  eIns symA528 iPtrV <| eIns symA535 (ldi ((k : Int) + 1)) <|
  eIns symA529 (ldi k) <| eIns symA530 (ldi 1) <|
  eIns symA534 iPtrV <|
  eIns (unitSym (2*k)) (ldi (sV k + (k : Int))) <|
  eIns symA519 sPtrV <| eIns symA527 (ldi (sV k + (k : Int))) <|
  eIns symA521 (ldi k) <| eIns symA520 (ldi (sV k)) <|
  eIns symA525 sPtrV <| eIns symA526 iPtrV <|
  eIns symA502 Vtrue <| eIns symA505 (ldi 0) <|
  eIns symA507 (ldi 1) <| eIns symA508 (ldi 0) <|
  eIns symA514 (ldi k) <| eIns symA515 (ldi n) <|
  eIns symA512 iPtrV <| eIns symA513 xPtrV <| e

/-- THE ENV FAMILY: entry chain at 0 (bind order: s at its create,
    a_503, i at its create, a_504, then the Esave REBINDS i and s —
    seven inserts, the S3 boundary-diag finding); iteration chains
    above. -/
def envL (n : Int) : Nat → Fmap sym value
  | 0 => eIns symS sPtrV <| eIns symI iPtrV <|
         eIns symA504 (ldi 0) <| eIns symI iPtrV <|
         eIns symA503 (ldi 0) <| eIns symS sPtrV <| e0
  | k + 1 => envIter n k (envL n k)

/-- THE BYTEMAP FAMILY: base = post-entry (n, errno zeroed, s cell 0,
    i cell 0); iteration k overwrites the s cell (store s) then the i
    cell (store i), census order. -/
def bmL (n : Int) : Nat → Std.TreeMap Int CerbMem.AbsByte
  | 0 =>
    ((((((((memD3 n).bytemap.insert sAddr (mkByte 0 0)).insert
      (sAddr+1) (mkByte 0 1)).insert (sAddr+2) (mkByte 0 2)).insert
      (sAddr+3) (mkByte 0 3)).insert iAddr (mkByte 0 0)).insert
      (iAddr+1) (mkByte 0 1)).insert (iAddr+2) (mkByte 0 2)).insert
      (iAddr+3) (mkByte 0 3)
  | k + 1 =>
    ((((((((bmL n k).insert sAddr (mkByte (sV k + (k : Int)) 0)).insert
      (sAddr+1) (mkByte (sV k + (k : Int)) 1)).insert
      (sAddr+2) (mkByte (sV k + (k : Int)) 2)).insert
      (sAddr+3) (mkByte (sV k + (k : Int)) 3)).insert
      iAddr (mkByte ((k : Int) + 1) 0)).insert
      (iAddr+1) (mkByte ((k : Int) + 1) 1)).insert
      (iAddr+2) (mkByte ((k : Int) + 1) 2)).insert
      (iAddr+3) (mkByte ((k : Int) + 1) 3)

def allocS : CerbMem.Allocation :=
  { base := sAddr, size := 4, ty := some intCty, prefix_ := PrefOther "Core" }
def allocI : CerbMem.Allocation :=
  { base := iAddr, size := 4, ty := some intCty, prefix_ := PrefOther "Core" }

/-- THE MEMORY FAMILY: only the bytemap varies with k; every other
    field is literal, so projections are rfl at symbolic k. -/
def memL (n : Int) (k : Nat) : CerbMem.MemState :=
  { CerbMem.initialMemState with
    nextAllocId := 4, lastAddress := iAddr,
    allocations := (((Std.TreeMap.empty.insert 0 allocX).insert
      1 allocErr).insert 2 allocS).insert 3 allocI,
    bytemap := bmL n k }

/-- An integer memory value (the trace events' payload form). -/
abbrev mvi (v : Int) : CerbMem.MemValue :=
  CerbMem.MemValue.MVinteger (Signed Int_) (CerbMem.IntegerValue.IV .Prov_none v)

/-- Iteration k's 7 trace events (newest first; census order —
    the prefix strings are placeholders validated by the walks). -/
def trIter (n : Int) (k : Nat) (tr : List trace_event) : List trace_event :=
  ME_store CerbLocation.Loc.unknown none intCty false iPtr
      (mvi ((k : Int) + 1))
    :: ME_load CerbLocation.Loc.unknown none intCty iPtr (mvi k)
    :: ME_store CerbLocation.Loc.unknown none intCty false sPtr
      (mvi (sV k + (k : Int)))
    :: ME_load CerbLocation.Loc.unknown none intCty sPtr (mvi (sV k))
    :: ME_load CerbLocation.Loc.unknown none intCty iPtr (mvi k)
    :: ME_load CerbLocation.Loc.unknown none intCty iPtr (mvi k)
    :: ME_load CerbLocation.Loc.unknown none intCty xPtr (mvi n)
    :: tr

/-- THE TRACE FAMILY (base = the entry block's 4 events, newest
    first: store i 0, alloc i, store s 0, alloc s). -/
def trL (n : Int) : Nat → List trace_event
  | 0 =>
    [ME_store CerbLocation.Loc.unknown none intCty false iPtr (mvi 0),
     ME_allocate_object 0 (PrefOther "Core")
        (CerbMem.alignofIval intCty) intCty none iPtr,
     ME_store CerbLocation.Loc.unknown none intCty false sPtr (mvi 0),
     ME_allocate_object 0 (PrefOther "Core")
        (CerbMem.alignofIval intCty) intCty none sPtr]
  | k + 1 => trIter n k (trL n k)

/-- THE RUN-STATE FAMILY (pinned-seed closed forms; the labeled map is
    the pinned continuations, constant). -/
def rsL (k : Nat) : core_run_state :=
  { tid_supply := 1, aid_supply := 4 + 7*k,
    excluded_supply := 2*k, sym_supply := seedT5 + 2*k,
    labeled := rsD5.labeled }

/-- The k=0 loop-head arena: the post-Esave state carries the entry
    stores' dynamic annotations (boundary-diag finding); from k ≥ 1
    the Erun jump installs the bare continuation body. -/
def arenaL : Nat → generic_expr core_run_annotation Unit sym
  | 0 => Expr [] (Eannot
      [DA_pos [] (CerbMem.Footprint.FP .W sAddr 4),
       DA_pos [] (CerbMem.Footprint.FP .W iAddr 4)] whileBody)
  | _ + 1 => whileBody

/-- THE THREAD FAMILY: arena = the loop-head arena family, env = the
    env family. -/
def thL (n : Int) (k : Nat) : thread_state :=
  { arena := arenaL k, stack0 := Stack_empty, errno := errPtr,
    current_loc := CerbLocation.Loc.unknown,
    exec_loc := ELoc_normal [(sumT5Sym, CerbLocation.other "RelSem.callND")],
    env := [envL n k], current_proc_opt := some sumT5Sym }

/-- THE INVARIANT FAMILY St-v2: the loop-head driver state at
    iteration k (counter 17 + 72k; census-derived closed forms). -/
def StT5 (n : Int) (k : Nat) : driver_state :=
  mkDr5 (thL n k) (memL n k) (rsL k) (trL n k) (17 + 72*k)

end RelSem.T5

