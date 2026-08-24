/-
  RelSem.T2AppEq — arc-7 S5a (2026-08-20): THE T2 HARNESS APP EQUATION,
  by the same compositional stage/round discipline as RelSem/T1AppEq
  (D7/D8: no whole-run kernel reductions, no budget bumps).

  Discovery record (SlateProbe walk of `callND t2File "add"
  [intValue 7, intValue 35]`): prefix (globals → resolve/lookup →
  injectArgs (TWO argument objects: a@…648, b@…644) → errno@…640 →
  thread update) + ONE driver2 iteration whose new_drive_core_threads
  performs FIFTEEN dnms rounds:
    R0  eval PEsym b (unseq 2nd el)   R1  Ewseq tau (a_536)
    R2  eval b-load operands          R3  LoadRequest b   (aid 0→1)
    R4  eval PEsym a (unseq 1st el)   R5  Ewseq tau (a_535)
    R6  eval a-load operands          R7  LoadRequest a   (aid 1→2)
    R8  Eunseq collapse (tuple)       R9  Ewseq tau (a_530,a_531)
    R10 eval PEcase/catch_add — THE OVERFLOW CHECK (x+y range)
    R11 Ebound/Eannot strip           R12 Esseq tau (a_537)
    R13 eval Erun conv_loaded_int (range check again)
    R14 eval PEsym a_538              R15 terminal [Step_done2 (x+y)]
  then pick → process (Step_done2) → prepare_exit → finalize.
  x/y-sensitivity: R3/R7 (byte roundtrips), R10 (the catch_add check —
  where the no-signed-overflow PRECONDITION enters), R13 (conv range).

  House rules: no sorry, no axioms, no Iris imports. Under the in-build
  audit (imported by RelSem.T2).
-/

import RelSem.SlateFiles
import RelSem.T1AppEq
import RelSem.ConstructLaws

set_option autoImplicit false

namespace RelSem.T2

open RelSem RelSem.Cerb RelSem.Slate
open RelSem.T1 (aU intCty loadedV xIntV mkByte roundtrip_arith zeroByte
  uninitByte patUnit loadE RExpr
  sizeof_int_eq alignof_int_eq sizeof_intCty_eq z0 z1 z2 z3 z4
  convLoadedIntSym convIntSym isReprIntegerSym errStore_bytes_fact)
-- (arc-9 S2: the generic eval/round crossings moved to the Kit)
open RelSem.Kit (eubind_defined stub_defined eumapM_one
  liftCore_run_defined aux2_step aux2_done perform_unfold ars_load_unfold)

/-! ## Pinned symbols (from the pinned t2 Core program) -/

def symA : sym := Symbol "" 15917291556903334389 (SD_Id "a")
def symB : sym := Symbol "" 15817570140490810055 (SD_Id "b")
def symA530 : sym := Symbol "" 4915778119994869450 (SD_Id "a_530")
def symA531 : sym := Symbol "" 17653705816563834534 (SD_Id "a_531")
def symA532 : sym := Symbol "" 1342427191597093029 (SD_Id "a_532")
def symA533 : sym := Symbol "" 18213349194842787190 (SD_Id "a_533")
def symA535 : sym := Symbol "" 15754218577363027919 (SD_Id "a_535")
def symA536 : sym := Symbol "" 6464411467923874555 (SD_Id "a_536")
def symA537 : sym := Symbol "" 6477419756603697776 (SD_Id "a_537")
def symRet529 : sym := Symbol "" 18125140908934492201 (SD_Id "ret_529")
def symA538 : sym := Symbol "" 18319030617476695216 (SD_Id "a_538")

/-! ## Addresses / pointers (deterministic allocations on the empty
    initial state: a first, b second, errno third) -/

def aAddr : Int := 281474976710648
def bAddr : Int := 281474976710644
def errAddr : Int := 281474976710640

def aPtr : CerbMem.PointerValue := .PV (.Prov_some 0) (.PVconcrete none aAddr)
def bPtr : CerbMem.PointerValue := .PV (.Prov_some 1) (.PVconcrete none bAddr)
def errPtr : CerbMem.PointerValue := .PV (.Prov_some 2) (.PVconcrete none errAddr)

def aPtrV : value := Vobject (OVpointer aPtr)
def bPtrV : value := Vobject (OVpointer bPtr)

/-! ## Patterns -/

def patA509 : generic_pattern sym :=
  Pattern aU (CaseBase (some symA535, BTy_object OTy_pointer))
def patA510 : generic_pattern sym :=
  Pattern aU (CaseBase (some symA536, BTy_object OTy_pointer))
def patTup : generic_pattern sym :=
  Pattern aU (CaseCtor Ctuple
    [Pattern aU (CaseBase (some symA530, BTy_loaded OTy_integer)),
     Pattern aU (CaseBase (some symA531, BTy_loaded OTy_integer))])
def patA511 : generic_pattern sym :=
  Pattern aU (CaseBase (some symA537, BTy_loaded OTy_integer))

/-! ## The add body's sub-expressions (probe-transcribed; the round
    rfls validate every transcription) -/

/-- The case-of-two-loaded pexpr computing catch_add (the body of the
    Ewseq continuation). -/
def casePE : generic_pexpr Unit sym :=
  Pexpr aU () (PEcase
    (Pexpr aU () (PEctor Ctuple
      [Pexpr aU () (PEsym symA530), Pexpr aU () (PEsym symA531)]))
    [(Pattern aU (CaseCtor Ctuple
        [Pattern aU (CaseCtor Cspecified
          [Pattern aU (CaseBase (some symA532, BTy_object OTy_integer))]),
         Pattern aU (CaseCtor Cspecified
          [Pattern aU (CaseBase (some symA533, BTy_object OTy_integer))])]),
      Pexpr aU () (PEctor Cspecified
        [Pexpr aU () (PEcatch_exceptional_condition (Signed Int_) IOpAdd
          (Pexpr aU () (PEconv_int (Signed Int_)
            (Pexpr aU () (PEsym symA532))))
          (Pexpr aU () (PEconv_int (Signed Int_)
            (Pexpr aU () (PEsym symA533)))))])),
     (Pattern aU (CaseBase (none,
        BTy_tuple [BTy_loaded OTy_integer, BTy_loaded OTy_integer])),
      Pexpr aU () (PEundef CerbLocation.Loc.unknown
        UB036_exceptional_condition))])

/-- The body tail (Erun ret_529 conv_loaded_int(a_537) → Esave). -/
def bodyTail : RExpr :=
  Expr aU (Esseq patUnit
    (Expr aU (Erun empty_annotation symRet529
      [Pexpr aU () (PEcall (Sym convLoadedIntSym)
        [Pexpr aU () (PEval (Vctype intCty)),
         Pexpr aU () (PEsym symA537)])]))
    (Expr aU (Esseq patUnit
      (Expr aU (Epure (Pexpr aU () (PEval Vunit))))
      (Expr aU (Esave (symRet529, BTy_loaded OTy_integer)
        [(symA538, ((BTy_loaded OTy_integer, none),
          Pexpr aU () (PEundef CerbLocation.Loc.unknown
            UB088_reached_end_of_function)))]
        (Expr aU (Epure (Pexpr aU () (PEsym symA538)))))))))

/-! ### The unseq load-branch stages (b steps first: R0–R3; a: R4–R7) -/

/-- Branch stage 0: Ewseq (pure sym) (load). -/
def br0 (s : sym) (pat : generic_pattern sym) (ls : sym) : RExpr :=
  Expr aU (Ewseq pat
    (Expr aU (Epure (Pexpr aU () (PEsym s))))
    (loadE (Pexpr aU () (PEval (Vctype intCty)))
           (Pexpr aU () (PEsym ls))))

/-- Branch stage 1: the pointer evaluated. -/
def br1 (pv : value) (pat : generic_pattern sym) (ls : sym) : RExpr :=
  Expr aU (Ewseq pat
    (Expr aU (Epure (Pexpr [] () (PEval pv))))
    (loadE (Pexpr aU () (PEval (Vctype intCty)))
           (Pexpr aU () (PEsym ls))))

/-- Branch stage 2: Ewseq collapsed (load with sym operand). -/
def br2 (ls : sym) : RExpr :=
  loadE (Pexpr aU () (PEval (Vctype intCty))) (Pexpr aU () (PEsym ls))

/-- Branch stage 3: load operands evaluated. -/
def br3 (pv : value) : RExpr :=
  loadE (Pexpr [] () (PEval (Vctype intCty))) (Pexpr [] () (PEval pv))

/-- Branch stage 4: loaded (Eannot-wrapped value). -/
def br4 (addr : Int) (v : Int) : RExpr :=
  Expr [] (Eannot [DA_pos [] (CerbMem.Footprint.FP .R addr 4)]
    (Expr [] (Epure (Pexpr [] () (PEval (loadedV v))))))

/-- Arena skeleton for the unseq phase (states 0–8). -/
def mkArenaU (ea eb : RExpr) : RExpr :=
  Expr aU (Esseq patA511
    (Expr aU (Ebound (Expr aU (Ewseq patTup
      (Expr aU (Eunseq [ea, eb]))
      (Expr aU (Epure casePE))))))
    bodyTail)

def aBr0 : RExpr := br0 symA patA509 symA535
def bBr0 : RExpr := br0 symB patA510 symA536
def bBr1 : RExpr := br1 bPtrV patA510 symA536
def aBr1 : RExpr := br1 aPtrV patA509 symA535

def arena0 : RExpr := mkArenaU aBr0 bBr0
def arena1 : RExpr := mkArenaU aBr0 bBr1
def arena2 : RExpr := mkArenaU aBr0 (br2 symA536)
def arena3 : RExpr := mkArenaU aBr0 (br3 bPtrV)
def arena4 (y : Int) : RExpr := mkArenaU aBr0 (br4 bAddr y)
def arena5 (y : Int) : RExpr := mkArenaU aBr1 (br4 bAddr y)
def arena6 (y : Int) : RExpr := mkArenaU (br2 symA535) (br4 bAddr y)
def arena7 (y : Int) : RExpr := mkArenaU (br3 aPtrV) (br4 bAddr y)
def arena8 (x y : Int) : RExpr := mkArenaU (br4 aAddr x) (br4 bAddr y)

/-- The merged unseq annotation list (b's footprint first). -/
def fpsBA : List dyn_annotation :=
  [DA_pos [] (CerbMem.Footprint.FP .R bAddr 4),
   DA_pos [] (CerbMem.Footprint.FP .R aAddr 4)]

/-- Arena after R8 (unseq collapsed to the annotated tuple value;
    the annot wrapper keeps the unseq's aU — probe a09). -/
def arena9 (x y : Int) : RExpr :=
  Expr aU (Esseq patA511
    (Expr aU (Ebound (Expr aU (Ewseq patTup
      (Expr aU (Eannot fpsBA (Expr [] (Epure (Pexpr [] () (PEval
        (Vtuple [loadedV x, loadedV y])))))))
      (Expr aU (Epure casePE))))))
    bodyTail)

/-- Arena after R9 (Ewseq tau: tuple bound; annots wrap the case). -/
def arena10 : RExpr :=
  Expr aU (Esseq patA511
    (Expr aU (Ebound (Expr [] (Eannot fpsBA
      (Expr aU (Epure casePE))))))
    bodyTail)

/-- Arena after R10 (the case/catch evaluated to x+y). -/
def arena11 (x y : Int) : RExpr :=
  Expr aU (Esseq patA511
    (Expr aU (Ebound (Expr [] (Eannot fpsBA
      (Expr aU (Epure (Pexpr [] () (PEval (loadedV (x+y))))))))))
    bodyTail)

/-- Arena after R11 (Ebound/Eannot stripped). -/
def arena12 (x y : Int) : RExpr :=
  Expr aU (Esseq patA511
    (Expr aU (Epure (Pexpr [] () (PEval (loadedV (x+y))))))
    bodyTail)

-- (Arena after R12 = bodyTail; a_537 bound.)

/-- Arena after R13 (Erun evaluated + jump to ret_529's Esave body). -/
def arena14 : RExpr :=
  Expr aU (Epure (Pexpr aU () (PEsym symA538)))

/-- Arena after R14. -/
def arena15 (x y : Int) : RExpr :=
  Expr aU (Epure (Pexpr [] () (PEval (loadedV (x+y)))))

/-! ## Environments (spelled as the runtime builds them) -/

def env0 : List (Fmap sym value) :=
  [(List.foldl (fun (m : Fmap sym value) (pv : sym × value) =>
      fmapAddBy (fun (s1 s2 : sym) => Lem_Basic_classes.ordCompare s1 s2)
        pv.1 pv.2 m)
    fmapEmpty [(symA, aPtrV), (symB, bPtrV)])]
def env2 : List (Fmap sym value) := update_env patA510 bPtrV env0
def env6 : List (Fmap sym value) := update_env patA509 aPtrV env2
def env10 (x y : Int) : List (Fmap sym value) :=
  update_env patTup (Vtuple [loadedV x, loadedV y]) env6
def env13 (x y : Int) : List (Fmap sym value) :=
  update_env patA511 (loadedV (x+y)) (env10 x y)
def env14 (x y : Int) : List (Fmap sym value) :=
  update_env (mk_sym_pat symA538 (BTy_loaded OTy_integer))
    (loadedV (x+y)) (env13 x y)

/-! ## Thread / driver-state frames -/

def mkTh (arena : RExpr) (env : List (Fmap sym value)) : thread_state :=
  { arena := arena, stack0 := Stack_empty, errno := errPtr,
    current_loc := CerbLocation.Loc.unknown,
    exec_loc := ELoc_normal [(addT2Sym, CerbLocation.other "RelSem.callND")],
    env := env, current_proc_opt := some addT2Sym }

def th0 : thread_state :=
  { mkTh arena0 env0 with current_loc := CerbLocation.other "RelSem.callND" }
def th1 : thread_state := mkTh arena1 env0
def th2 : thread_state := mkTh arena2 env2
def th3 : thread_state := mkTh arena3 env2
def th4 (y : Int) : thread_state := mkTh (arena4 y) env2
def th5 (y : Int) : thread_state := mkTh (arena5 y) env2
def th6 (y : Int) : thread_state := mkTh (arena6 y) env6
def th7 (y : Int) : thread_state := mkTh (arena7 y) env6
def th8 (x y : Int) : thread_state := mkTh (arena8 x y) env6
def th9 (x y : Int) : thread_state := mkTh (arena9 x y) env6
def th10 (x y : Int) : thread_state := mkTh arena10 (env10 x y)
def th11 (x y : Int) : thread_state := mkTh (arena11 x y) (env10 x y)
def th12 (x y : Int) : thread_state := mkTh (arena12 x y) (env10 x y)
def th13 (x y : Int) : thread_state := mkTh bodyTail (env13 x y)
def th14 (x y : Int) : thread_state := mkTh arena14 (env14 x y)
def th15 (x y : Int) : thread_state := mkTh (arena15 x y) (env14 x y)

def accDone (v : Int) : Fmap thread_id (List core_step2) :=
  fmapAddBy defaultCompare 0 [Step_done2 (loadedV v)] fmapEmpty

def mkDr (th : thread_state) (mem : CerbMem.MemState)
    (rs : core_run_state) (tr : List trace_event) (n : Nat) : driver_state :=
  { core_file := t2File,
    core_extern := create_extern_symmap t2File,
    core_state0 := { thread_states := [(0, (none, th))], io := initial_io_state },
    core_run_state0 := rs,
    layout_state := mem,
    concurrency_state := symInitialState symInitialPre,
    fs_state0 := CerbFS.fs_initial_state,
    trace := tr,
    symbolic_assoc := fmapEmpty,
    blocked := false,
    dr_step_counter := n }

abbrev dnms (fuel : Nat) (acc : Fmap thread_id (List core_step2))
    (tids : List Nat) :=
  drive_nonmemory_steps_aux2_lemFuel fuel t2File.tagDefs acc tids

/-! ## Prefix states (globals thread, run state, memories) -/

def thG : thread_state :=
  { arena := Expr [] (Epure (Pexpr [] () (PEval Vunit))),
    stack0 := Stack_empty,
    errno := .PV .Prov_none (.PVnull intCty),
    current_loc := CerbLocation.Loc.unknown,
    exec_loc := ELoc_globals,
    env := [fmapEmpty],
    current_proc_opt := none }

def rsD3 : core_run_state :=
  { initial_core_run_state (collect_labeled_continuations_NEW t2File)
      with tid_supply := 1 }

def allocA : CerbMem.Allocation :=
  { base := aAddr, size := 4, ty := some signed_int, prefix_ := PrefOther "callND arg" }
def allocB : CerbMem.Allocation :=
  { base := bAddr, size := 4, ty := some signed_int, prefix_ := PrefOther "callND arg" }
def allocErr : CerbMem.Allocation :=
  { base := errAddr, size := 4, ty := some signed_int, prefix_ := PrefOther "errno" }

/-! Every bytemap below is spelled as the OVERWRITE CHAIN the
    computation produces (allocate writes uninitialized bytes, store
    overwrites them) — the defeq-faithful shape. -/

/-- Bytemap after a's allocation (uninitialized). -/
def bmAllocA : Std.TreeMap Int CerbMem.AbsByte :=
  (((Std.TreeMap.empty.insert aAddr uninitByte).insert
    (aAddr+1) uninitByte).insert (aAddr+2) uninitByte).insert
    (aAddr+3) uninitByte

/-- Bytemap after a's argument store. -/
def bmA (x : Int) : Std.TreeMap Int CerbMem.AbsByte :=
  (((bmAllocA.insert aAddr (mkByte x 0)).insert
    (aAddr+1) (mkByte x 1)).insert (aAddr+2) (mkByte x 2)).insert
    (aAddr+3) (mkByte x 3)

/-- Bytemap after b's allocation. -/
def bmAllocB (x : Int) : Std.TreeMap Int CerbMem.AbsByte :=
  ((((bmA x).insert bAddr uninitByte).insert
    (bAddr+1) uninitByte).insert (bAddr+2) uninitByte).insert
    (bAddr+3) uninitByte

/-- Bytemap after b's argument store. -/
def bmInj (x y : Int) : Std.TreeMap Int CerbMem.AbsByte :=
  ((((bmAllocB x).insert bAddr (mkByte y 0)).insert
    (bAddr+1) (mkByte y 1)).insert (bAddr+2) (mkByte y 2)).insert
    (bAddr+3) (mkByte y 3)

/-- Memory after a's allocation. -/
def memAllocA : CerbMem.MemState :=
  { CerbMem.initialMemState with
    nextAllocId := 1, lastAddress := aAddr,
    allocations := Std.TreeMap.empty.insert 0 allocA,
    bytemap := bmAllocA }

/-- Memory after a's store. -/
def memA (x : Int) : CerbMem.MemState :=
  { CerbMem.initialMemState with
    nextAllocId := 1, lastAddress := aAddr,
    allocations := Std.TreeMap.empty.insert 0 allocA,
    bytemap := bmA x }

/-- Memory after b's allocation. -/
def memAllocB (x : Int) : CerbMem.MemState :=
  { CerbMem.initialMemState with
    nextAllocId := 2, lastAddress := bAddr,
    allocations := (Std.TreeMap.empty.insert 0 allocA).insert 1 allocB,
    bytemap := bmAllocB x }

/-- Memory after the two argument injections. -/
def memInj (x y : Int) : CerbMem.MemState :=
  { CerbMem.initialMemState with
    nextAllocId := 2, lastAddress := bAddr,
    allocations := (Std.TreeMap.empty.insert 0 allocA).insert 1 allocB,
    bytemap := bmInj x y }

/-- Bytemap after the errno allocation (uninitialized). -/
def bmErrAlloc (x y : Int) : Std.TreeMap Int CerbMem.AbsByte :=
  ((((bmInj x y).insert errAddr uninitByte).insert
    (errAddr+1) uninitByte).insert (errAddr+2) uninitByte).insert
    (errAddr+3) uninitByte

def memErrAlloc (x y : Int) : CerbMem.MemState :=
  { CerbMem.initialMemState with
    nextAllocId := 3, lastAddress := errAddr,
    allocations := ((Std.TreeMap.empty.insert 0 allocA).insert 1 allocB).insert
      2 allocErr,
    bytemap := bmErrAlloc x y }

/-- Memory at D3 (errno zero-initialized) — the run's fixed memory. -/
def memD3 (x y : Int) : CerbMem.MemState :=
  { CerbMem.initialMemState with
    nextAllocId := 3, lastAddress := errAddr,
    allocations := ((Std.TreeMap.empty.insert 0 allocA).insert 1 allocB).insert
      2 allocErr,
    bytemap := ((((bmErrAlloc x y).insert errAddr zeroByte).insert
      (errAddr+1) zeroByte).insert (errAddr+2) zeroByte).insert
      (errAddr+3) zeroByte }

/-! ## Memory-op equations (controlled simp; the T1 recipe) -/

theorem allocErr_eq (x y : Int) :
    app (CerbMem.allocateObject 0 (PrefOther "errno")
      (CerbMem.alignofIval signed_int) signed_int none none) (memInj x y)
    = (NDactive errPtr, memErrAlloc x y) := by
  simp only [CerbMem.allocateObject, CerbMem.alignofIval, CerbMem.integerIval,
    app, memInj, memErrAlloc, bmErrAlloc, bmInj, bmAllocB, bmA, bmAllocA,
    sizeof_int_eq, alignof_int_eq, errPtr, errAddr, bAddr, aAddr,
    allocA, allocB, allocErr, uninitByte, CerbMem.initialMemState]
  simp [CerbMem.alignDown, CerbMem.writeBytesTo, List.replicate]

theorem errStore_get_fact :
    ((((Std.TreeMap.empty.insert 0 allocA).insert 1 allocB).insert 2 allocErr :
        Std.TreeMap Int CerbMem.Allocation)).get? 2 = some allocErr := rfl
theorem errStore_compat_fact :
    CerbMem.ctypeMemCompatible signed_int
      (CerbMem.typeofMval (CerbMem.integerValueMval (Signed Int_)
        (CerbMem.integerIval 0))) = true := rfl
theorem errStore_bounds_fact :
    CerbMem.isInBounds allocErr errAddr 4 = true := rfl
theorem errStore_atomic_fact :
    CerbMem.isAtomicMemberAccess allocErr signed_int errAddr = false := rfl

theorem storeErr_eq (x y : Int) :
    app (CerbMem.storeM (CerbLocation.other "errno init") signed_int false
      errPtr (CerbMem.integerValueMval (Signed Int_) (CerbMem.integerIval 0)))
      (memErrAlloc x y)
    = (NDactive (CerbMem.Footprint.FP .W errAddr 4), memD3 x y) := by
  simp only [CerbMem.storeM, app, memErrAlloc, memD3, sizeof_int_eq,
    errPtr, CerbMem.initialMemState, errStore_bytes_fact, errStore_get_fact,
    errStore_compat_fact, errStore_bounds_fact, errStore_atomic_fact]
  simp [CerbMem.writeBytesTo, CerbMem.isInBounds, CerbMem.isAtomicMemberAccess,
    List.foldl, allocErr, errAddr,
    show allocErr.isReadonly = .IsWritable from rfl]

/-! ### The two loads (R3: b, R7: a) -/

theorem loadB_get_fact (x y : Int) :
    (memD3 x y).allocations[(1 : Int)]? = some allocB := rfl
theorem loadA_get_fact (x y : Int) :
    (memD3 x y).allocations[(0 : Int)]? = some allocA := rfl

theorem bm_getB0 (x y : Int) :
    (memD3 x y).bytemap[(281474976710644 : Int)]? = some (mkByte y 0) := by
  simp +decide only [memD3, bmErrAlloc, bmInj, bmAllocB, bmA, bmAllocA,
    aAddr, bAddr, errAddr, Std.TreeMap.getElem?_insert,
    Std.TreeMap.getElem?_insert_self, if_true, if_false]
theorem bm_getB1 (x y : Int) :
    (memD3 x y).bytemap[(281474976710645 : Int)]? = some (mkByte y 1) := by
  simp +decide only [memD3, bmErrAlloc, bmInj, bmAllocB, bmA, bmAllocA,
    aAddr, bAddr, errAddr, Std.TreeMap.getElem?_insert,
    Std.TreeMap.getElem?_insert_self, if_true, if_false]
theorem bm_getB2 (x y : Int) :
    (memD3 x y).bytemap[(281474976710646 : Int)]? = some (mkByte y 2) := by
  simp +decide only [memD3, bmErrAlloc, bmInj, bmAllocB, bmA, bmAllocA,
    aAddr, bAddr, errAddr, Std.TreeMap.getElem?_insert,
    Std.TreeMap.getElem?_insert_self, if_true, if_false]
theorem bm_getB3 (x y : Int) :
    (memD3 x y).bytemap[(281474976710647 : Int)]? = some (mkByte y 3) := by
  simp +decide only [memD3, bmErrAlloc, bmInj, bmAllocB, bmA, bmAllocA,
    aAddr, bAddr, errAddr, Std.TreeMap.getElem?_insert,
    Std.TreeMap.getElem?_insert_self, if_true, if_false]
theorem bm_getA0 (x y : Int) :
    (memD3 x y).bytemap[(281474976710648 : Int)]? = some (mkByte x 0) := by
  simp +decide only [memD3, bmErrAlloc, bmInj, bmAllocB, bmA, bmAllocA,
    aAddr, bAddr, errAddr, Std.TreeMap.getElem?_insert,
    Std.TreeMap.getElem?_insert_self, if_true, if_false]
theorem bm_getA1 (x y : Int) :
    (memD3 x y).bytemap[(281474976710649 : Int)]? = some (mkByte x 1) := by
  simp +decide only [memD3, bmErrAlloc, bmInj, bmAllocB, bmA, bmAllocA,
    aAddr, bAddr, errAddr, Std.TreeMap.getElem?_insert,
    Std.TreeMap.getElem?_insert_self, if_true, if_false]
theorem bm_getA2 (x y : Int) :
    (memD3 x y).bytemap[(281474976710650 : Int)]? = some (mkByte x 2) := by
  simp +decide only [memD3, bmErrAlloc, bmInj, bmAllocB, bmA, bmAllocA,
    aAddr, bAddr, errAddr, Std.TreeMap.getElem?_insert,
    Std.TreeMap.getElem?_insert_self, if_true, if_false]
theorem bm_getA3 (x y : Int) :
    (memD3 x y).bytemap[(281474976710651 : Int)]? = some (mkByte x 3) := by
  simp +decide only [memD3, bmErrAlloc, bmInj, bmAllocB, bmA, bmAllocA,
    aAddr, bAddr, errAddr, Std.TreeMap.getElem?_insert,
    Std.TreeMap.getElem?_insert_self, if_true, if_false]

theorem loadB_bytes_fact (x y : Int) :
    CerbMem.readBytesFrom (memD3 x y) 281474976710644 4
    = [mkByte y 0, mkByte y 1, mkByte y 2, mkByte y 3] := by
  simp [CerbMem.readBytesFrom, List.range, List.range.loop,
    bm_getB0 x y, bm_getB1 x y, bm_getB2 x y, bm_getB3 x y]

theorem loadA_bytes_fact (x y : Int) :
    CerbMem.readBytesFrom (memD3 x y) 281474976710648 4
    = [mkByte x 0, mkByte x 1, mkByte x 2, mkByte x 3] := by
  simp [CerbMem.readBytesFrom, List.range, List.range.loop,
    bm_getA0 x y, bm_getA1 x y, bm_getA2 x y, bm_getA3 x y]

theorem loadB_bounds_fact :
    CerbMem.isInBounds allocB 281474976710644 4 = true := rfl
theorem loadA_bounds_fact :
    CerbMem.isInBounds allocA 281474976710648 4 = true := rfl
theorem loadB_atomic_fact :
    CerbMem.isAtomicMemberAccess allocB (Ctype [] (Basic (Integer (Signed Int_))))
      281474976710644 = false := rfl
theorem loadA_atomic_fact :
    CerbMem.isAtomicMemberAccess allocA (Ctype [] (Basic (Integer (Signed Int_))))
      281474976710648 = false := rfl
theorem loadB_dead_fact (x y : Int) :
    (memD3 x y).deadAllocations.contains 1 = false := rfl
theorem loadA_dead_fact (x y : Int) :
    (memD3 x y).deadAllocations.contains 0 = false := rfl

theorem reconB_eq (x y : Int) (hy1 : -2147483648 ≤ y) (hy2 : y ≤ 2147483647) :
    CerbMem.reconstructValue (memD3 x y).lastUsedUnionMembers
      (memD3 x y).funptrmap 281474976710644 intCty
      [mkByte y 0, mkByte y 1, mkByte y 2, mkByte y 3]
    = .MVinteger (Signed Int_) (.IV .Prov_none y) := by
  show CerbMem.reconstructValue_lemFuel (999999+1) _ _ _
    (Ctype [] (Basic (Integer (Signed Int_)))) _ = _
  rw [CerbMem.reconstructValue_lemFuel]
  simp only [CerberusImpl.is_signed_ity]
  rw [roundtrip_arith y hy1 hy2]
  simp [CerbMem.provFromIntegerBytes, CerbMem.combineProv, mkByte]

theorem reconA_eq (x y : Int) (hx1 : -2147483648 ≤ x) (hx2 : x ≤ 2147483647) :
    CerbMem.reconstructValue (memD3 x y).lastUsedUnionMembers
      (memD3 x y).funptrmap 281474976710648 intCty
      [mkByte x 0, mkByte x 1, mkByte x 2, mkByte x 3]
    = .MVinteger (Signed Int_) (.IV .Prov_none x) := by
  show CerbMem.reconstructValue_lemFuel (999999+1) _ _ _
    (Ctype [] (Basic (Integer (Signed Int_)))) _ = _
  rw [CerbMem.reconstructValue_lemFuel]
  simp only [CerberusImpl.is_signed_ity]
  rw [roundtrip_arith x hx1 hx2]
  simp [CerbMem.provFromIntegerBytes, CerbMem.combineProv, mkByte]

theorem loadB_eq (x y : Int) (hy1 : -2147483648 ≤ y) (hy2 : y ≤ 2147483647) :
    app (CerbMem.loadM CerbLocation.Loc.unknown intCty bPtr) (memD3 x y)
    = (NDactive (CerbMem.Footprint.FP .R bAddr 4,
        CerbMem.MemValue.MVinteger (Signed Int_) (.IV .Prov_none y)),
       memD3 x y) := by
  simp only [CerbMem.loadM, app, bPtr, bAddr, sizeof_intCty_eq,
    loadB_dead_fact x y, loadB_bytes_fact x y, reconB_eq x y hy1 hy2]
  simp [loadB_get_fact x y, loadB_bounds_fact, loadB_atomic_fact, intCty]

theorem loadA_eq (x y : Int) (hx1 : -2147483648 ≤ x) (hx2 : x ≤ 2147483647) :
    app (CerbMem.loadM CerbLocation.Loc.unknown intCty aPtr) (memD3 x y)
    = (NDactive (CerbMem.Footprint.FP .R aAddr 4,
        CerbMem.MemValue.MVinteger (Signed Int_) (.IV .Prov_none x)),
       memD3 x y) := by
  simp only [CerbMem.loadM, app, aPtr, aAddr, sizeof_intCty_eq,
    loadA_dead_fact x y, loadA_bytes_fact x y, reconA_eq x y hx1 hx2]
  simp [loadA_get_fact x y, loadA_bounds_fact, loadA_atomic_fact, intCty]

/-! ## The prefix walk -/

def finTail : Unit → driverM driver_result :=
  fun _ => nd_bind nd_get (fun (dr_st' : driver_state) =>
    nd_return (finalize t2File.tagDefs "callND" dr_st'))

/-! ### The two argument injections at the memory level (T2 has TWO
    caller-protocol allocations — one rfl exceeds the default budget,
    so each alloc/store goes through the memory lens like errno) -/

theorem storeArg_bytes_fact (v : Int) :
    CerbMem.memValueToBytes []
      (CerbMem.MemValue.MVinteger (Signed Int_)
        (CerbMem.IntegerValue.IV .Prov_none v))
    = ([], [mkByte v 0, mkByte v 1, mkByte v 2, mkByte v 3]) := rfl

theorem allocA_eq :
    app (CerbMem.allocateObject 0 (PrefOther "callND arg")
      (CerbMem.alignofIval signed_int) signed_int none none)
      CerbMem.initialMemState
    = (NDactive aPtr, memAllocA) := by
  simp only [CerbMem.allocateObject, CerbMem.alignofIval, CerbMem.integerIval,
    app, memAllocA, bmAllocA, sizeof_int_eq, alignof_int_eq, aPtr, aAddr,
    allocA, uninitByte, CerbMem.initialMemState]
  simp [CerbMem.alignDown, CerbMem.writeBytesTo, List.replicate]

theorem storeA_get_fact :
    ((Std.TreeMap.empty.insert 0 allocA :
        Std.TreeMap Int CerbMem.Allocation)).get? 0 = some allocA := rfl
theorem storeArg_compat_fact (v : Int) :
    CerbMem.ctypeMemCompatible signed_int
      (CerbMem.typeofMval (CerbMem.MemValue.MVinteger (Signed Int_)
        (CerbMem.IntegerValue.IV .Prov_none v))) = true := rfl
theorem storeA_bounds_fact :
    CerbMem.isInBounds allocA aAddr 4 = true := rfl
theorem storeA_atomic_fact :
    CerbMem.isAtomicMemberAccess allocA signed_int aAddr = false := rfl

theorem writeA_fact (x : Int) :
    CerbMem.writeBytesTo memAllocA aAddr
      [mkByte x 0, mkByte x 1, mkByte x 2, mkByte x 3]
    = { memAllocA with bytemap := bmA x } := rfl

theorem storeA_eq (x : Int) :
    app (CerbMem.storeM (CerbLocation.other "callND arg init") signed_int false
      aPtr (CerbMem.MemValue.MVinteger (Signed Int_)
        (CerbMem.IntegerValue.IV .Prov_none x))) memAllocA
    = (NDactive (CerbMem.Footprint.FP .W aAddr 4), memA x) := by
  simp +decide only [CerbMem.storeM, app, sizeof_int_eq, aPtr,
    storeArg_bytes_fact, storeA_get_fact, storeArg_compat_fact]
  rfl

theorem allocB_eq (x : Int) :
    app (CerbMem.allocateObject 0 (PrefOther "callND arg")
      (CerbMem.alignofIval signed_int) signed_int none none) (memA x)
    = (NDactive bPtr, memAllocB x) := by
  simp only [CerbMem.allocateObject, CerbMem.alignofIval, CerbMem.integerIval,
    app, memA, memAllocB, bmAllocB, bmA, bmAllocA, sizeof_int_eq,
    alignof_int_eq, bPtr, bAddr, aAddr,
    allocA, allocB, uninitByte, CerbMem.initialMemState]
  simp [CerbMem.alignDown, CerbMem.writeBytesTo, List.replicate]

theorem storeB_get_fact :
    (((Std.TreeMap.empty.insert 0 allocA).insert 1 allocB :
        Std.TreeMap Int CerbMem.Allocation)).get? 1 = some allocB := rfl
theorem storeB_bounds_fact :
    CerbMem.isInBounds allocB bAddr 4 = true := rfl
theorem storeB_atomic_fact :
    CerbMem.isAtomicMemberAccess allocB signed_int bAddr = false := rfl

theorem writeB_fact (x y : Int) :
    CerbMem.writeBytesTo (memAllocB x) bAddr
      [mkByte y 0, mkByte y 1, mkByte y 2, mkByte y 3]
    = { memAllocB x with bytemap := bmInj x y } := rfl

theorem storeB_eq (x y : Int) :
    app (CerbMem.storeM (CerbLocation.other "callND arg init") signed_int false
      bPtr (CerbMem.MemValue.MVinteger (Signed Int_)
        (CerbMem.IntegerValue.IV .Prov_none y))) (memAllocB x)
    = (NDactive (CerbMem.Footprint.FP .W bAddr 4), memInj x y) := by
  simp +decide only [CerbMem.storeM, app, sizeof_int_eq, bPtr,
    storeArg_bytes_fact, storeB_get_fact, storeArg_compat_fact]
  rfl

/-- The argument-injection value conversion, closed (the injectArg
    match scrutinee — reduced once here so the walk's unifier never
    re-derives it). -/
theorem mvvA_fact (v : Int) :
    memValueFromValue t2File.tagDefs signed_int (intValue v)
      = some (CerbMem.MemValue.MVinteger (Signed Int_)
          (CerbMem.IntegerValue.IV .Prov_none v)) := rfl

/-- The injectArgs computation with everything resolved (the shape the
    resolution stages leave in the bind). -/
def injPhase (x y : Int) : driverM driver_result :=
  nd_bind (injectArgs t2File.tagDefs 0
      [(symA, BTy_object OTy_pointer), (symB, BTy_object OTy_pointer)]
      [signed_int, signed_int] [intValue x, intValue y])
    (fun (bound : List (sym × value)) =>
      callFinish t2File.tagDefs 0 addT2Sym arena0 bound)

/-- Prefix part 0: the resolution stages land on the spelled pre-inject
    state (memory still initial). -/
theorem prefix_a0 (x y : Int) :
    app (callND t2File.tagDefs t2File "add" [intValue x, intValue y])
        (initial_driver_state t2File CerbFS.fs_initial_state)
      = app (injPhase x y)
          (mkDr thG CerbMem.initialMemState rsD3 [] 0) := by
  refine (app_bind_active rfl).trans ?_   -- driver_globals
  refine (app_bind_active rfl).trans ?_   -- nd_get
  refine (app_bind_active rfl).trans ?_   -- resolveFunSym
  refine (app_bind_active rfl).trans ?_   -- lookupFunBody
  refine (app_bind_active rfl).trans ?_   -- lookupParamTys
  rfl

/-- Prefix part 1: the two argument injections, walked at the spelled
    state through the memory lens. -/
theorem prefix_a1 (x y : Int) :
    app (injPhase x y) (mkDr thG CerbMem.initialMemState rsD3 [] 0)
      = app (callFinish t2File.tagDefs 0 addT2Sym arena0
          [(symA, aPtrV), (symB, bPtrV)])
          (mkDr thG (memInj x y) rsD3 [] 0) := by
  apply (app_bind_active ?hinj).trans
  case hinj =>
    simp only [injectArgs, injectArg, mvvA_fact]
    apply (app_bind_active (app_liftND_active _ _ _ _ ?hma)).trans
    case hma =>
      refine (app_bind_active allocA_eq).trans ?_
      refine (app_bind_active (storeA_eq x)).trans ?_
      exact app_nd_return (Vobject (OVpointer aPtr)) (memA x)
    apply (app_bind_active ?hinjb).trans
    case hinjb =>
      apply (app_bind_active (app_liftND_active _ _ _ _ ?hmb)).trans
      case hmb =>
        refine (app_bind_active (allocB_eq x)).trans ?_
        refine (app_bind_active (storeB_eq x y)).trans ?_
        exact app_nd_return (Vobject (OVpointer bPtr)) (memInj x y)
      refine (app_bind_active rfl).trans ?_   -- injectArgs []
      rfl
    rfl
  rfl

theorem prefix_a (x y : Int) :
    app (callND t2File.tagDefs t2File "add" [intValue x, intValue y])
        (initial_driver_state t2File CerbFS.fs_initial_state)
      = app (callFinish t2File.tagDefs 0 addT2Sym arena0
          [(symA, aPtrV), (symB, bPtrV)])
          (mkDr thG (memInj x y) rsD3 [] 0) :=
  (prefix_a0 x y).trans (prefix_a1 x y)

theorem prefix_b (x y : Int) :
    app (callFinish t2File.tagDefs 0 addT2Sym arena0
        [(symA, aPtrV), (symB, bPtrV)])
        (mkDr thG (memInj x y) rsD3 [] 0)
      = app (nd_bind (driver2 t2File.tagDefs false) finTail)
          (mkDr th0 (memD3 x y) rsD3 [] 0) := by
  refine (app_bind_active
    (v := (mkDr thG (memInj x y) rsD3 [] 0).core_state0.thread_states)
    (st' := mkDr thG (memInj x y) rsD3 [] 0) rfl).trans ?_
  apply (app_bind_active (app_liftND_active _ _ _ _ ?hmem)).trans
  case hmem =>
    refine (app_bind_active (allocErr_eq x y)).trans ?_
    refine (app_bind_active (storeErr_eq x y)).trans ?_
    exact app_nd_return errPtr (memD3 x y)
  refine (app_bind_active rfl).trans ?_  -- driver_update_thread_state
  rfl

theorem prefix_walk (x y : Int) :
    app (callND t2File.tagDefs t2File "add" [intValue x, intValue y])
        (initial_driver_state t2File CerbFS.fs_initial_state)
      = app (nd_bind (driver2 t2File.tagDefs false) finTail)
          (mkDr th0 (memD3 x y) rsD3 [] 0) :=
  (prefix_a x y).trans (prefix_b x y)

/-! ## Round lemmas (frame-parametric where payload-opaque) -/

theorem round0 (fuel : Nat) (mem : CerbMem.MemState) (rs : core_run_state)
    (tr : List trace_event) (n : Nat) :
    app (dnms (fuel+1) fmapEmpty [0]) (mkDr th0 mem rs tr n)
      = app (dnms fuel fmapEmpty [0]) (mkDr th1 mem rs tr (n+1)) := by
  refine (app_bind_active rfl).trans ?_
  refine (app_bind_active rfl).trans ?_
  rfl

theorem round1 (fuel : Nat) (mem : CerbMem.MemState) (rs : core_run_state)
    (tr : List trace_event) (n : Nat) :
    app (dnms (fuel+1) fmapEmpty [0]) (mkDr th1 mem rs tr n)
      = app (dnms fuel fmapEmpty [0]) (mkDr th2 mem rs tr (n+1)) := by
  refine (app_bind_active rfl).trans ?_
  refine (app_bind_active rfl).trans ?_
  rfl

theorem round2 (fuel : Nat) (mem : CerbMem.MemState) (rs : core_run_state)
    (tr : List trace_event) (n : Nat) :
    app (dnms (fuel+1) fmapEmpty [0]) (mkDr th2 mem rs tr n)
      = app (dnms fuel fmapEmpty [0]) (mkDr th3 mem rs tr (n+1)) := by
  refine (app_bind_active rfl).trans ?_
  refine (app_bind_active rfl).trans ?_
  rfl

/-- R3's trace event: the load of b's object. -/
def meLoadB (y : Int) : trace_event :=
  ME_load CerbLocation.Loc.unknown none intCty bPtr
    (CerbMem.MemValue.MVinteger (Signed Int_)
      (CerbMem.IntegerValue.IV .Prov_none y))

/-- R7's trace event: the load of a's object. -/
def meLoadA (x : Int) : trace_event :=
  ME_load CerbLocation.Loc.unknown none intCty aPtr
    (CerbMem.MemValue.MVinteger (Signed Int_)
      (CerbMem.IntegerValue.IV .Prov_none x))

/-- R3: the b-load round (aid drawn; counter NOT bumped). -/
theorem round3 (x y : Int) (hy1 : -2147483648 ≤ y) (hy2 : y ≤ 2147483647)
    (fuel : Nat) (rs : core_run_state) (tr : List trace_event) (n : Nat) :
    app (dnms (fuel+1) fmapEmpty [0]) (mkDr th3 (memD3 x y) rs tr n)
      = app (dnms fuel fmapEmpty [0]) (mkDr (th4 y) (memD3 x y)
          { rs with aid_supply := rs.aid_supply + 1 } (meLoadB y :: tr) n) := by
  refine (app_bind_active rfl).trans ?_
  apply (app_bind_active ?hadv).trans
  case hadv =>
    apply (app_bind_active ?hreq).trans
    case hreq =>
      refine (app_bind_active rfl).trans ?_
      rw [perform_unfold]
      refine (app_bind_active rfl).trans ?_
      rw [ars_load_unfold]
      apply (app_bind_active (app_liftND_active _ _ _ _ ?hload)).trans
      case hload => exact loadB_eq x y hy1 hy2
      apply (app_bind_active (app_liftND_active _ _ _ _ ?hpref)).trans
      case hpref => rfl
      rfl
    rfl
  rfl

theorem round4 (y : Int) (fuel : Nat) (mem : CerbMem.MemState)
    (rs : core_run_state) (tr : List trace_event) (n : Nat) :
    app (dnms (fuel+1) fmapEmpty [0]) (mkDr (th4 y) mem rs tr n)
      = app (dnms fuel fmapEmpty [0]) (mkDr (th5 y) mem rs tr (n+1)) := by
  refine (app_bind_active rfl).trans ?_
  refine (app_bind_active rfl).trans ?_
  rfl

theorem round5 (y : Int) (fuel : Nat) (mem : CerbMem.MemState)
    (rs : core_run_state) (tr : List trace_event) (n : Nat) :
    app (dnms (fuel+1) fmapEmpty [0]) (mkDr (th5 y) mem rs tr n)
      = app (dnms fuel fmapEmpty [0]) (mkDr (th6 y) mem rs tr (n+1)) := by
  refine (app_bind_active rfl).trans ?_
  refine (app_bind_active rfl).trans ?_
  rfl

theorem round6 (y : Int) (fuel : Nat) (mem : CerbMem.MemState)
    (rs : core_run_state) (tr : List trace_event) (n : Nat) :
    app (dnms (fuel+1) fmapEmpty [0]) (mkDr (th6 y) mem rs tr n)
      = app (dnms fuel fmapEmpty [0]) (mkDr (th7 y) mem rs tr (n+1)) := by
  refine (app_bind_active rfl).trans ?_
  refine (app_bind_active rfl).trans ?_
  rfl

/-- R7: the a-load round. -/
theorem round7 (x y : Int) (hx1 : -2147483648 ≤ x) (hx2 : x ≤ 2147483647)
    (fuel : Nat) (rs : core_run_state) (tr : List trace_event) (n : Nat) :
    app (dnms (fuel+1) fmapEmpty [0]) (mkDr (th7 y) (memD3 x y) rs tr n)
      = app (dnms fuel fmapEmpty [0]) (mkDr (th8 x y) (memD3 x y)
          { rs with aid_supply := rs.aid_supply + 1 } (meLoadA x :: tr) n) := by
  refine (app_bind_active rfl).trans ?_
  apply (app_bind_active ?hadv).trans
  case hadv =>
    apply (app_bind_active ?hreq).trans
    case hreq =>
      refine (app_bind_active rfl).trans ?_
      rw [perform_unfold]
      refine (app_bind_active rfl).trans ?_
      rw [ars_load_unfold]
      apply (app_bind_active (app_liftND_active _ _ _ _ ?hload)).trans
      case hload => exact loadA_eq x y hx1 hx2
      apply (app_bind_active (app_liftND_active _ _ _ _ ?hpref)).trans
      case hpref => rfl
      rfl
    rfl
  rfl

theorem round8 (x y : Int) (fuel : Nat) (mem : CerbMem.MemState)
    (rs : core_run_state) (tr : List trace_event) (n : Nat) :
    app (dnms (fuel+1) fmapEmpty [0]) (mkDr (th8 x y) mem rs tr n)
      = app (dnms fuel fmapEmpty [0]) (mkDr (th9 x y) mem rs tr (n+1)) := by
  refine (app_bind_active rfl).trans ?_
  refine (app_bind_active rfl).trans ?_
  rfl

theorem round9 (x y : Int) (fuel : Nat) (mem : CerbMem.MemState)
    (rs : core_run_state) (tr : List trace_event) (n : Nat) :
    app (dnms (fuel+1) fmapEmpty [0]) (mkDr (th9 x y) mem rs tr n)
      = app (dnms fuel fmapEmpty [0]) (mkDr (th10 x y) mem rs tr (n+1)) := by
  refine (app_bind_active rfl).trans ?_
  refine (app_bind_active rfl).trans ?_
  rfl

/-! ## R10 — THE OVERFLOW-CHECK EVAL (the case/catch_add chain) -/

/-- casePE in pull-normal form (top + scrutinee annots stripped). -/
def casePE_p : generic_pexpr Unit sym :=
  Pexpr [] () (PEcase
    (Pexpr [] () (PEctor Ctuple
      [Pexpr aU () (PEsym symA530), Pexpr aU () (PEsym symA531)]))
    [(Pattern aU (CaseCtor Ctuple
        [Pattern aU (CaseCtor Cspecified
          [Pattern aU (CaseBase (some symA532, BTy_object OTy_integer))]),
         Pattern aU (CaseCtor Cspecified
          [Pattern aU (CaseBase (some symA533, BTy_object OTy_integer))])]),
      Pexpr aU () (PEctor Cspecified
        [Pexpr aU () (PEcatch_exceptional_condition (Signed Int_) IOpAdd
          (Pexpr aU () (PEconv_int (Signed Int_)
            (Pexpr aU () (PEsym symA532))))
          (Pexpr aU () (PEconv_int (Signed Int_)
            (Pexpr aU () (PEsym symA533)))))])),
     (Pattern aU (CaseBase (none,
        BTy_tuple [BTy_loaded OTy_integer, BTy_loaded OTy_integer])),
      Pexpr aU () (PEundef CerbLocation.Loc.unknown
        UB036_exceptional_condition))])

theorem pull_casePE : pull_constrained 0 casePE = casePE_p := rfl

/-- The matched arm with the loaded operands substituted (raw output of
    the case step; probe-transcribed). -/
def zCatch (x y : Int) : generic_pexpr Unit sym :=
  Pexpr [] () (PEctor Cspecified
    [Pexpr aU () (PEcatch_exceptional_condition (Signed Int_) IOpAdd
      (Pexpr aU () (PEconv_int (Signed Int_)
        (Pexpr aU () (PEval (xIntV x)))))
      (Pexpr aU () (PEconv_int (Signed Int_)
        (Pexpr aU () (PEval (xIntV y))))))])

theorem pull_zCatch (x y : Int) :
    pull_constrained 0 (zCatch x y) = zCatch x y := rfl

/-! ### Closed value-level facts (small rfl leaves — no big simp
    unfoldings, which blow the recursion budget on the 2^31 pow) -/

theorem eval_iv_fact (v : Int) :
    eval_integer_value (CerbMem.IntegerValue.IV .Prov_none v) = some v := rfl
theorem eval_min_fact :
    eval_integer_value (CerbMem.minIval (Signed Int_))
      = some (-2147483648) := rfl
theorem eval_max_fact :
    eval_integer_value (CerbMem.maxIval (Signed Int_))
      = some (2147483647) := rfl
theorem iteq_bool_fact : integerTypeEqual (Signed Int_) Bool0 = false := rfl
theorem opAdd_fact (x y : Int) :
    CerbMem.opIval IntAdd (CerbMem.IntegerValue.IV .Prov_none x)
      (CerbMem.IntegerValue.IV .Prov_none y)
      = CerbMem.IntegerValue.IV .Prov_none (x + y) := rfl

theorem intLteb_true {a b : Int} (h : a ≤ b) : intLteb a b = true := by
  simp only [intLteb, decide_eq_true_eq]; exact h

/-- Closed fact: signed-int conv on an in-range integer is the identity. -/
theorem mk_conv_int_id (x : Int)
    (h1 : -2147483648 ≤ x) (h2 : x ≤ 2147483647) :
    mk_conv_int (Signed Int_) (CerbMem.IntegerValue.IV .Prov_none x)
      = CerbMem.IntegerValue.IV .Prov_none x := by
  unfold mk_conv_int
  rw [eval_iv_fact]
  simp only [iteq_bool_fact, Bool.false_eq_true, if_false,
    eval_min_fact, eval_max_fact, intLteb_true h1, intLteb_true h2,
    Bool.and_self, if_true]
  rfl

/-- THE OVERFLOW-CHECK FACT: catch_add on plain in-range operand IVs
    with an in-range sum yields the sum (this is where the T2
    precondition enters). -/
theorem catch_add_fact (x y : Int)
    (hs1 : -2147483648 ≤ x + y) (hs2 : x + y ≤ 2147483647) :
    mk_call_catch_exceptional_condition (Signed Int_) IOpAdd
      (CerbMem.IntegerValue.IV .Prov_none x)
      (CerbMem.IntegerValue.IV .Prov_none y)
      = some (CerbMem.IntegerValue.IV .Prov_none (x + y)) := by
  unfold mk_call_catch_exceptional_condition
  simp only [mk_iop, opAdd_fact, eval_iv_fact, eval_min_fact, eval_max_fact,
    intLteb_true hs1, intLteb_true hs2, Bool.and_self, if_true]

/-- The one-step case evaluation: scrutinee tuple evaluated, arm
    matched, operands substituted (payloads opaque). -/
theorem s0case_eq (x y : Int) (mem : CerbMem.MemState) :
    step_eval_pexpr t2File.tagDefs 0 CerbLocation.Loc.unknown
      (some (CerbLocation.other "RelSem.callND")) (create_extern_symmap t2File)
      (env10 x y) (some mem) t2File false casePE_p
      = Result (Defined (zCatch x y)) := rfl

/-- s1: the catch_add step — THE OVERFLOW CHECK (all preconditions
    enter: the conv legs need the per-operand ranges, the catch needs
    the sum range). -/
theorem s1case_eq (x y : Int)
    (hx1 : -2147483648 ≤ x) (hx2 : x ≤ 2147483647)
    (hy1 : -2147483648 ≤ y) (hy2 : y ≤ 2147483647)
    (hs1 : -2147483648 ≤ x + y) (hs2 : x + y ≤ 2147483647)
    (mem : CerbMem.MemState) :
    step_eval_pexpr t2File.tagDefs 0 CerbLocation.Loc.unknown
      (some (CerbLocation.other "RelSem.callND")) (create_extern_symmap t2File)
      (env10 x y) (some mem) t2File false (zCatch x y)
      = Result (Defined (Pexpr [] () (PEval (loadedV (x+y))))) := by
  have hcx := mk_conv_int_id x hx1 hx2
  have hcy := mk_conv_int_id y hy1 hy2
  have hcatch := catch_add_fact x y hs1 hs2
  change exception_undef_bind _ _ = _
  refine (eubind_defined
    (z := (PEval (loadedV (x+y)) : generic_pexpr_ Unit sym)) ?hCtor).trans ?_
  case hCtor =>
    change exception_undef_bind _ _ = _
    refine (eubind_defined
      (z := [(Pexpr [] () (PEval (xIntV (x+y))) : generic_pexpr Unit sym)])
      ?hMap).trans ?_
    case hMap =>
      apply eumapM_one ?hInner
      case hInner =>
        change exception_undef_bind _ _ = _
        refine (eubind_defined
          (z := (PEval (xIntV (x+y)) : generic_pexpr_ Unit sym)) ?hCatch).trans ?_
        case hCatch =>
          change exception_undef_bind _ _ = _
          refine (eubind_defined
            (z := (Pexpr [] () (PEval (xIntV x)) : generic_pexpr Unit sym))
            ?hC1).trans ?_
          case hC1 =>
            conv => rhs; rw [show (xIntV x : value)
              = Vobject (OVinteger (mk_conv_int (Signed Int_)
                  (CerbMem.IntegerValue.IV .Prov_none x))) by rw [hcx]; rfl]
            rfl
          change exception_undef_bind _ _ = _
          refine (eubind_defined
            (z := (Pexpr [] () (PEval (xIntV y)) : generic_pexpr Unit sym))
            ?hC2).trans ?_
          case hC2 =>
            conv => rhs; rw [show (xIntV y : value)
              = Vobject (OVinteger (mk_conv_int (Signed Int_)
                  (CerbMem.IntegerValue.IV .Prov_none y))) by rw [hcy]; rfl]
            rfl
          simp only [valueFromPexpr, xIntV]
          rw [hcatch]
          rfl
        rfl
    rfl
  rfl

/-- The case/catch aux2 chain: two steps. -/
theorem caseCore_eq (x y : Int)
    (hx1 : -2147483648 ≤ x) (hx2 : x ≤ 2147483647)
    (hy1 : -2147483648 ≤ y) (hy2 : y ≤ 2147483647)
    (hs1 : -2147483648 ≤ x + y) (hs2 : x + y ≤ 2147483647)
    (mem : CerbMem.MemState) :
    eval_pexpr_aux2 t2File.tagDefs CerbLocation.Loc.unknown
      (some (CerbLocation.other "RelSem.callND"))
      (create_extern_symmap t2File) (env10 x y) (some mem) t2File casePE
    = Result (Defined (Sum.inr (loadedV (x+y)))) :=
  (aux2_step 999999 _ _ _ _ _ _ _ (pull_casePE)
      (by intro a xs h; simp [casePE_p] at h) (s0case_eq x y mem) (by rfl)).trans
  (aux2_done 999998 _ _ _ _ _ _ _ (pull_zCatch x y)
      (by intro a xs h; simp [zCatch] at h)
      (s1case_eq x y hx1 hx2 hy1 hy2 hs1 hs2 mem) (by rfl))

theorem caseStep_eq (x y : Int)
    (hx1 : -2147483648 ≤ x) (hx2 : x ≤ 2147483647)
    (hy1 : -2147483648 ≤ y) (hy2 : y ≤ 2147483647)
    (hs1 : -2147483648 ≤ x + y) (hs2 : x + y ≤ 2147483647)
    (mem : CerbMem.MemState) (rs : core_run_state) :
    E.eval_pexpr20 t2File.tagDefs (th10 x y) (create_extern_symmap t2File)
      mem t2File casePE rs
    = Result (Defined (Sum.inr (loadedV (x+y))), rs) := by
  simp only [E.eval_pexpr20, th10, mkTh]
  rw [caseCore_eq x y hx1 hx2 hy1 hy2 hs1 hs2 mem]
  rfl

/-- The Epure round evaluates through full_eval_pexpr (one_step0's
    full_eval_pexpr' — probe/goal-shape finding). -/
theorem fullEvalCase_eq (x y : Int)
    (hx1 : -2147483648 ≤ x) (hx2 : x ≤ 2147483647)
    (hy1 : -2147483648 ≤ y) (hy2 : y ≤ 2147483647)
    (hs1 : -2147483648 ≤ x + y) (hs2 : x + y ≤ 2147483647)
    (mem : CerbMem.MemState) (rs : core_run_state) :
    full_eval_pexpr t2File.tagDefs (th10 x y) (create_extern_symmap t2File)
      mem t2File casePE rs
    = Result (Defined (loadedV (x+y)), rs) := by
  change stExceptUndef_bind _ _ _ = _
  refine (stub_defined
    (caseStep_eq x y hx1 hx2 hy1 hy2 hs1 hs2 mem rs)).trans ?_
  rfl

/-- R10: the overflow-check eval round. -/
theorem round10 (x y : Int)
    (hx1 : -2147483648 ≤ x) (hx2 : x ≤ 2147483647)
    (hy1 : -2147483648 ≤ y) (hy2 : y ≤ 2147483647)
    (hs1 : -2147483648 ≤ x + y) (hs2 : x + y ≤ 2147483647)
    (fuel : Nat) (rs : core_run_state)
    (tr : List trace_event) (n : Nat) :
    app (dnms (fuel+1) fmapEmpty [0]) (mkDr (th10 x y) (memD3 x y) rs tr n)
      = app (dnms fuel fmapEmpty [0])
          (mkDr (th11 x y) (memD3 x y) rs tr (n+1)) := by
  refine (app_bind_active rfl).trans ?_    -- nd_read (step_ctx)
  apply (app_bind_active ?hadv).trans
  case hadv =>
    refine (app_bind_active rfl).trans ?_  -- rsk match (RSK_eval)
    apply (app_bind_active (liftCore_run_defined ?hM)).trans
    case hM =>
      change stExceptUndef_bind _ _ _ = _
      apply (stub_defined ?hEv).trans
      case hEv =>
        change stExceptUndef_bind _ _ _ = _
        refine (stub_defined
          (fullEvalCase_eq x y hx1 hx2 hy1 hy2 hs1 hs2 _ _)).trans ?_
        rfl
      rfl
    rfl
  rfl

theorem round11 (x y : Int) (fuel : Nat) (mem : CerbMem.MemState)
    (rs : core_run_state) (tr : List trace_event) (n : Nat) :
    app (dnms (fuel+1) fmapEmpty [0]) (mkDr (th11 x y) mem rs tr n)
      = app (dnms fuel fmapEmpty [0]) (mkDr (th12 x y) mem rs tr (n+1)) := by
  refine (app_bind_active rfl).trans ?_
  refine (app_bind_active rfl).trans ?_
  rfl

theorem round12 (x y : Int) (fuel : Nat) (mem : CerbMem.MemState)
    (rs : core_run_state) (tr : List trace_event) (n : Nat) :
    app (dnms (fuel+1) fmapEmpty [0]) (mkDr (th12 x y) mem rs tr n)
      = app (dnms fuel fmapEmpty [0]) (mkDr (th13 x y) mem rs tr (n+1)) := by
  refine (app_bind_active rfl).trans ?_
  refine (app_bind_active rfl).trans ?_
  rfl

/-! ## R13 — the Erun conv_loaded_int eval (the T1 R6 chain at x+y) -/

/-- The conv-call pexpr (the Erun argument). -/
def convPE : generic_pexpr Unit sym :=
  Pexpr aU () (PEcall (Sym convLoadedIntSym)
    [Pexpr aU () (PEval (Vctype intCty)), Pexpr aU () (PEsym symA537)])

/-- convPE in pull-normal form. -/
def convPE_p : generic_pexpr Unit sym :=
  Pexpr [] () (PEcall (Sym convLoadedIntSym)
    [Pexpr aU () (PEval (Vctype intCty)), Pexpr aU () (PEsym symA537)])

theorem pull_convPE : pull_constrained 0 convPE = convPE_p := rfl
theorem pull_z0 (v : Int) : pull_constrained 0 (z0 v) = z0 v := rfl
theorem pull_z1 (v : Int) : pull_constrained 0 (z1 v) = z1 v := rfl
theorem pull_z2 (v : Int) : pull_constrained 0 (z2 v) = z2 v := rfl
theorem pull_z3 (v : Int) : pull_constrained 0 (z3 v) = z3 v := rfl

theorem s0_eq (x y : Int) (mem : CerbMem.MemState) :
    step_eval_pexpr t2File.tagDefs 0 CerbLocation.Loc.unknown
      (some (CerbLocation.other "RelSem.callND")) (create_extern_symmap t2File)
      (env13 x y) (some mem) t2File false convPE_p
      = Result (Defined (z0 (x+y))) := rfl

theorem s1_eq (x y : Int) (mem : CerbMem.MemState) :
    step_eval_pexpr t2File.tagDefs 0 CerbLocation.Loc.unknown
      (some (CerbLocation.other "RelSem.callND")) (create_extern_symmap t2File)
      (env13 x y) (some mem) t2File false (z0 (x+y))
      = Result (Defined (z1 (x+y))) := rfl

theorem s2_eq (x y : Int) (mem : CerbMem.MemState) :
    step_eval_pexpr t2File.tagDefs 0 CerbLocation.Loc.unknown
      (some (CerbLocation.other "RelSem.callND")) (create_extern_symmap t2File)
      (env13 x y) (some mem) t2File false (z1 (x+y))
      = Result (Defined (z2 (x+y))) := rfl

theorem s3_eq (x y : Int) (mem : CerbMem.MemState) :
    step_eval_pexpr t2File.tagDefs 0 CerbLocation.Loc.unknown
      (some (CerbLocation.other "RelSem.callND")) (create_extern_symmap t2File)
      (env13 x y) (some mem) t2File false (z2 (x+y))
      = Result (Defined (z3 (x+y))) := rfl

/-- s4: the conv range check on x+y. -/
theorem s4_eq (x y : Int)
    (hs1 : -2147483648 ≤ x + y) (hs2 : x + y ≤ 2147483647)
    (mem : CerbMem.MemState) :
    step_eval_pexpr t2File.tagDefs 0 CerbLocation.Loc.unknown
      (some (CerbLocation.other "RelSem.callND")) (create_extern_symmap t2File)
      (env13 x y) (some mem) t2File false (z3 (x+y))
      = Result (Defined (z4 (x+y))) := by
  have hd1 : decide ((-2147483648:Int) ≤ x + y) = true := decide_eq_true hs1
  have hd2 : decide (x + y ≤ (2147483647:Int)) = true := decide_eq_true hs2
  change exception_undef_bind _ _ = _
  refine (eubind_defined
    (z := (PEval (loadedV (x+y)) : generic_pexpr_ Unit sym)) ?hBody).trans ?_
  case hBody =>
    change exception_undef_bind _ _ = _
    refine (eubind_defined
      (z := [(Pexpr [] () (PEval (xIntV (x+y))) : generic_pexpr Unit sym)])
      ?hMap).trans ?_
    case hMap =>
      apply eumapM_one ?hIf
      case hIf =>
        change exception_undef_bind _ _ = _
        refine (eubind_defined
          (z := (PEval (xIntV (x+y)) : generic_pexpr_ Unit sym)) ?hIfBody).trans ?_
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
                show step_eval_pexpr_lemFuel 999997 t2File.tagDefs (0+1+1+1)
                  CerbLocation.Loc.unknown (some (CerbLocation.other "RelSem.callND"))
                  (create_extern_symmap t2File) (env13 x y) (some mem) t2File false
                  (Pexpr [] () (PEop OpLe
                    (Pexpr [] () (PEctor Civmin [Pexpr aU () (PEval (Vctype intCty))]))
                    (Pexpr [] () (PEval (xIntV (x+y))))))
                  = Result (Defined (Pexpr [] () (PEval Vtrue)))
                have harm : (if (decide ((-2147483648:Int) ≤ x + y)) = true
                    then Vtrue else Vfalse) = Vtrue := by rw [hd1]; simp
                conv => rhs; rw [← harm]
                rfl
              change exception_undef_bind _ _ = _
              refine (eubind_defined
                (z := (Pexpr [] () (PEval Vtrue) : generic_pexpr Unit sym))
                ?hLe2).trans ?_
              case hLe2 =>
                show step_eval_pexpr_lemFuel 999997 t2File.tagDefs (0+1+1+1)
                  CerbLocation.Loc.unknown (some (CerbLocation.other "RelSem.callND"))
                  (create_extern_symmap t2File) (env13 x y) (some mem) t2File false
                  (Pexpr [] () (PEop OpLe
                    (Pexpr [] () (PEval (xIntV (x+y))))
                    (Pexpr [] () (PEctor Civmax [Pexpr aU () (PEval (Vctype intCty))]))))
                  = Result (Defined (Pexpr [] () (PEval Vtrue)))
                have harm : (if (decide (x + y ≤ (2147483647:Int))) = true
                    then Vtrue else Vfalse) = Vtrue := by rw [hd2]; simp
                conv => rhs; rw [← harm]
                rfl
              rfl
            rfl
          rfl
        rfl
    rfl
  rfl

theorem convCore_eq (x y : Int)
    (hs1 : -2147483648 ≤ x + y) (hs2 : x + y ≤ 2147483647)
    (mem : CerbMem.MemState) :
    eval_pexpr_aux2 t2File.tagDefs CerbLocation.Loc.unknown
      (some (CerbLocation.other "RelSem.callND"))
      (create_extern_symmap t2File) (env13 x y) (some mem) t2File convPE
    = Result (Defined (Sum.inr (loadedV (x+y)))) :=
  (aux2_step 999999 _ _ _ _ _ _ _ (pull_convPE)
      (by intro a xs h; simp [convPE_p] at h) (s0_eq x y mem) (by rfl)).trans
  ((aux2_step 999998 _ _ _ _ _ _ _ (pull_z0 (x+y))
      (by intro a xs h; simp [z0] at h) (s1_eq x y mem) (by rfl)).trans
  ((aux2_step 999997 _ _ _ _ _ _ _ (pull_z1 (x+y))
      (by intro a xs h; simp [z1] at h) (s2_eq x y mem) (by rfl)).trans
  ((aux2_step 999996 _ _ _ _ _ _ _ (pull_z2 (x+y))
      (by intro a xs h; simp [z2] at h) (s3_eq x y mem) (by rfl)).trans
  (aux2_done 999995 _ _ _ _ _ _ _ (pull_z3 (x+y))
      (by intro a xs h; simp [z3] at h) (s4_eq x y hs1 hs2 mem) (by rfl)))))

theorem convStep_eq (x y : Int)
    (hs1 : -2147483648 ≤ x + y) (hs2 : x + y ≤ 2147483647)
    (mem : CerbMem.MemState) (rs : core_run_state) :
    E.eval_pexpr20 t2File.tagDefs (th13 x y) (create_extern_symmap t2File)
      mem t2File convPE rs
    = Result (Defined (Sum.inr (loadedV (x+y))), rs) := by
  simp only [E.eval_pexpr20, th13, mkTh]
  rw [convCore_eq x y hs1 hs2 mem]
  rfl

theorem fullEval_conv_eq (x y : Int)
    (hs1 : -2147483648 ≤ x + y) (hs2 : x + y ≤ 2147483647)
    (mem : CerbMem.MemState) (rs : core_run_state) :
    full_eval_pexpr t2File.tagDefs (th13 x y) (create_extern_symmap t2File)
      mem t2File convPE rs
    = Result (Defined (loadedV (x+y)), rs) := by
  change stExceptUndef_bind _ _ _ = _
  refine (stub_defined (convStep_eq x y hs1 hs2 mem rs)).trans ?_
  rfl

/-- The run-state after both loads' action-id draws. -/
def rsB : core_run_state := { rsD3 with aid_supply := rsD3.aid_supply + 1 }
def rsAB : core_run_state := { rsB with aid_supply := rsB.aid_supply + 1 }

/-- R13: the Erun eval round, ∀-run-state through the `erun_jump_m`
    construct law (arc-17 S1; was pinned to the concrete `rsAB` — the
    label resolution now enters as the `hlab` projection hypothesis,
    which every state ladder, ambient or threaded ∀-seed, discharges
    by `rfl`). -/
theorem round13 (x y : Int)
    (hs1 : -2147483648 ≤ x + y) (hs2 : x + y ≤ 2147483647)
    (fuel : Nat) (mem : CerbMem.MemState) (rs : core_run_state)
    (hlab : rs.labeled = collect_labeled_continuations_NEW t2File)
    (tr : List trace_event) (n : Nat) :
    app (dnms (fuel+1) fmapEmpty [0])
        (mkDr (th13 x y) mem rs tr n)
      = app (dnms fuel fmapEmpty [0])
        (mkDr (th14 x y) mem rs tr (n+1)) := by
  refine (app_bind_active rfl).trans ?_    -- nd_read (step_ctx)
  apply (app_bind_active ?hadv).trans
  case hadv =>
    refine (app_bind_active rfl).trans ?_  -- rsk match (RSK_eval)
    apply (app_bind_active (liftCore_run_defined ?hM)).trans
    case hM =>
      change stExceptUndef_bind _ _ _ = _
      apply RelSem.Laws.erun_jump_m ?hres ?hk  -- label-jump construct law
      case hres => simp only [mkDr, hlab]; rfl -- label resolution
      case hk =>
        change stExceptUndef_bind _ _ _ = _
        apply (stub_defined ?hFold).trans       -- the args foldM
        case hFold =>
          change stExceptUndef_bind _ _ _ = _
          apply (stub_defined ?hElem).trans
          case hElem =>
            change stExceptUndef_bind _ _ _ = _
            apply (stub_defined (fullEval_conv_eq x y hs1 hs2 _ _)).trans
            rfl
          rfl
        rfl
    rfl
  rfl

theorem round14 (x y : Int) (fuel : Nat) (mem : CerbMem.MemState)
    (rs : core_run_state) (tr : List trace_event) (n : Nat) :
    app (dnms (fuel+1) fmapEmpty [0]) (mkDr (th14 x y) mem rs tr n)
      = app (dnms fuel fmapEmpty [0]) (mkDr (th15 x y) mem rs tr (n+1)) := by
  refine (app_bind_active rfl).trans ?_
  refine (app_bind_active rfl).trans ?_
  rfl

/-- R15 (terminal): thread 0 offers only Step_done2. -/
theorem round15 (x y : Int) (fuel : Nat) (mem : CerbMem.MemState)
    (rs : core_run_state) (tr : List trace_event) (n : Nat) :
    app (dnms (fuel+2) fmapEmpty [0]) (mkDr (th15 x y) mem rs tr n)
      = (NDactive (accDone (x+y)), mkDr (th15 x y) mem rs tr n) := by
  refine (app_bind_active rfl).trans ?_
  rfl

/-! ## Composition -/

def tr1 (y : Int) : List trace_event := [meLoadB y]
def tr2 (x y : Int) : List trace_event := [meLoadA x, meLoadB y]

/-- The full dnms run at the default budget: fifteen rounds + terminal. -/
theorem dnms_chain (x y : Int)
    (hx1 : -2147483648 ≤ x) (hx2 : x ≤ 2147483647)
    (hy1 : -2147483648 ≤ y) (hy2 : y ≤ 2147483647)
    (hs1 : -2147483648 ≤ x + y) (hs2 : x + y ≤ 2147483647) :
    app (dnms lemDefaultFuel fmapEmpty [0]) (mkDr th0 (memD3 x y) rsD3 [] 0)
      = (NDactive (accDone (x+y)),
         mkDr (th15 x y) (memD3 x y) rsAB (tr2 x y) 13) :=
  (round0 999999 (memD3 x y) rsD3 [] 0).trans
  ((round1 999998 (memD3 x y) rsD3 [] 1).trans
  ((round2 999997 (memD3 x y) rsD3 [] 2).trans
  ((round3 x y hy1 hy2 999996 rsD3 [] 3).trans
  ((round4 y 999995 (memD3 x y) rsB (tr1 y) 3).trans
  ((round5 y 999994 (memD3 x y) rsB (tr1 y) 4).trans
  ((round6 y 999993 (memD3 x y) rsB (tr1 y) 5).trans
  ((round7 x y hx1 hx2 999992 rsB (tr1 y) 6).trans
  ((round8 x y 999991 (memD3 x y) rsAB (tr2 x y) 6).trans
  ((round9 x y 999990 (memD3 x y) rsAB (tr2 x y) 7).trans
  ((round10 x y hx1 hx2 hy1 hy2 hs1 hs2 999989 rsAB (tr2 x y) 8).trans
  ((round11 x y 999988 (memD3 x y) rsAB (tr2 x y) 9).trans
  ((round12 x y 999987 (memD3 x y) rsAB (tr2 x y) 10).trans
  ((round13 x y hs1 hs2 999986 (memD3 x y) rsAB rfl (tr2 x y) 11).trans
  ((round14 x y 999985 (memD3 x y) rsAB (tr2 x y) 12).trans
  (round15 x y 999983 (memD3 x y) rsAB (tr2 x y) 13)))))))))))))))

/-- The scheduler sees exactly the done step. -/
theorem ndct_eq (x y : Int)
    (hx1 : -2147483648 ≤ x) (hx2 : x ≤ 2147483647)
    (hy1 : -2147483648 ≤ y) (hy2 : y ≤ 2147483647)
    (hs1 : -2147483648 ≤ x + y) (hs2 : x + y ≤ 2147483647) :
    app (new_drive_core_threads t2File.tagDefs ())
        (mkDr th0 (memD3 x y) rsD3 [] 0)
      = (NDactive [(0, some (Step_done2 (loadedV (x+y))))],
         mkDr (th15 x y) (memD3 x y) rsAB (tr2 x y) 13) := by
  refine (app_bind_active rfl).trans ?_
  refine (app_bind_active
    (dnms_chain x y hx1 hx2 hy1 hy2 hs1 hs2)).trans ?_
  rfl

/-- The post-exit thread (prepare_exit's rebuild). -/
def thDone (x y : Int) : thread_state :=
  { th15 x y with stack0 := Stack_empty, arena := mk_value_e (loadedV (x+y)) }

/-- The final driver state of the harness run. -/
def drDone (x y : Int) : driver_state :=
  mkDr (thDone x y) (memD3 x y) rsAB (tr2 x y) 13

/-- ONE driver2 iteration does the whole run (T1's opaque
    execution-mode dispatch, verbatim). -/
theorem driver2_iter (x y : Int)
    (hx1 : -2147483648 ≤ x) (hx2 : x ≤ 2147483647)
    (hy1 : -2147483648 ≤ y) (hy2 : y ≤ 2147483647)
    (hs1 : -2147483648 ≤ x + y) (hs2 : x + y ≤ 2147483647) :
    app (driver2 t2File.tagDefs false) (mkDr th0 (memD3 x y) rsD3 [] 0)
      = (NDactive (), drDone x y) := by
  show app (driver2_lemFuel (999999+1) t2File.tagDefs false)
    (mkDr th0 (memD3 x y) rsD3 [] 0) = (NDactive (), drDone x y)
  change app (nd_bind _ _) _ = _
  refine (app_bind_active
    (ndct_eq x y hx1 hx2 hy1 hy2 hs1 hs2)).trans ?_
  refine (app_bind_active rfl).trans ?_          -- nd_get
  cases hmode : Lem_Maybe.maybeEqualBy (fun x y => x == y)
      (CerbGlobal.current_execution_mode ())
      (some CerbGlobal.ExecutionMode.random) with
  | true =>
    simp only [reduceIte, bindExhaustive]
    apply (app_bind_active ?hpickT).trans
    case hpickT => rfl
    apply (app_bind_active ?hdbgT).trans
    case hdbgT => rfl
    rfl
  | false =>
    simp only [reduceIte]
    apply (app_bind_active ?hgrd).trans
    case hgrd => rfl
    apply (app_bind_active ?hpickF).trans
    case hpickF => rfl
    apply (app_bind_active ?hdbgF).trans
    case hdbgF => rfl
    rfl

/-- THE T2 HARNESS APP EQUATION, composed. -/
theorem t2_app_eq (x y : Int)
    (hx1 : -2147483648 ≤ x) (hx2 : x ≤ 2147483647)
    (hy1 : -2147483648 ≤ y) (hy2 : y ≤ 2147483647)
    (hs1 : -2147483648 ≤ x + y) (hs2 : x + y ≤ 2147483647) :
    app (callND t2File.tagDefs t2File "add" [intValue x, intValue y])
        (initial_driver_state t2File CerbFS.fs_initial_state)
      = (NDactive (finalize t2File.tagDefs "callND" (drDone x y)),
         drDone x y) := by
  refine (prefix_walk x y).trans ?_
  refine (app_bind_active
    (driver2_iter x y hx1 hx2 hy1 hy2 hs1 hs2)).trans ?_
  refine (app_bind_active rfl).trans ?_          -- finTail's nd_get
  rfl                                            -- nd_return finalize

/-- The finalize result carries the sum, Specified. -/
theorem t2_result_eq (x y : Int) :
    (finalize t2File.tagDefs "callND" (drDone x y)).dres_core_value
      = intValue (x+y) := rfl

end RelSem.T2
