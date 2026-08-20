/-
  RelSem.T1AppEq — arc-7 S5a (2026-08-20): THE T1 HARNESS APP EQUATION,
  by compositional stage/round lemmas (D7/D8 discipline: no whole-run
  kernel reductions, no budget bumps — every lemma is a small closed
  reduction at default budgets).

  Discovery record: the #eval walk (compiled evaluator) of
  `callND t1File "id" [intValue 7]` shows the execution is
    prefix (driver_globals → resolve/lookup → injectArgs → errno →
    thread update)  +  ONE driver2 iteration whose
    new_drive_core_threads performs NINE dnms rounds
      R0 eval Epure(PEsym x)      R1 tau Ewseq-bind a_499
      R2 eval Load operands       R3 LoadRequest (the memory read)
      R4 tau Ebound/Eannot strip  R5 tau Esseq-bind a_500
      R6 eval Erun (conv_loaded_int chain — the range check)
      R7 eval Epure(PEsym a_501)  R8 terminal [Step_done2 v]
  then pick → process_core_step2 (Step_done2) → prepare_exit → finalize.
  x-sensitivity is confined to R3 (byte roundtrip) and R6 (the
  is_representable range check); everywhere else the payloads carrying
  x are constructor-opaque and the rounds prove by rfl with the frame
  (memory, run-state, trace, counter) universally quantified.

  House rules: no sorry, no axioms, no Iris imports. Under the in-build
  audit (imported by RelSem.T1).
-/

import RelSem.T1File
import RelSem.Machine
import RelSem.Cerberus
import RelSem.Call
import RelSem.Kit.Eval
import RelSem.Kit.Round
import RelSem.Kit.AppEq
import RelSem.Tactics.AppWalk

set_option autoImplicit false

namespace RelSem.T1

open RelSem RelSem.Cerb RelSem.Kit

/-! ## Shared pinned terms (from the pinned Core program + the caller
    protocol; addresses are the deterministic first/second allocations
    of the concrete memory model on the empty initial state) -/

abbrev aU : List annot := [Aloc CerbLocation.Loc.unknown]

def symX : sym := Symbol "" 16562859848569467201 (SD_Id "x")
def symA499 : sym := Symbol "" 14539597331447198605 (SD_Id "a_499")
def symA500 : sym := Symbol "" 18166180104677201841 (SD_Id "a_500")
def symA501 : sym := Symbol "" 17257815879318811304 (SD_Id "a_501")
def symRet : sym := Symbol "" 9907641387098162999 (SD_Id "ret_498")

def intCty : ctype := Ctype [] (Basic (Integer (Signed Int_)))

/-- x's parameter object: first allocation. -/
def xAddr : Int := 281474976710648
/-- errno object: second allocation. -/
def errAddr : Int := 281474976710644

def xPtr : CerbMem.PointerValue :=
  .PV (.Prov_some 0) (.PVconcrete none xAddr)
def errPtr : CerbMem.PointerValue :=
  .PV (.Prov_some 1) (.PVconcrete none errAddr)

def xPtrV : value := Vobject (OVpointer xPtr)

/-- The loaded specified integer value (the load result / a_500's
    binding / the final Core value). -/
def loadedV (v : Int) : value :=
  Vloaded (LVspecified (OVinteger (CerbMem.IntegerValue.IV .Prov_none v)))

/-! ### The id body's sub-expressions (converted, runtime-annotation
    form — transcribed from the emit-instrument dump of the walk;
    every rfl below validates the transcription) -/

def patA499 : generic_pattern sym :=
  Pattern aU (CaseBase (some symA499, BTy_object OTy_pointer))
def patA500 : generic_pattern sym :=
  Pattern aU (CaseBase (some symA500, BTy_loaded OTy_integer))
def patUnit : generic_pattern sym :=
  Pattern [] (CaseBase (none, BTy_unit))

abbrev RExpr := generic_expr core_run_annotation Unit sym

/-- The Load action with operand pexprs `pc` (ctype) and `pp` (pointer). -/
def loadE (pc pp : generic_pexpr Unit sym) : RExpr :=
  Expr aU (Eaction (Paction Pos (Action CerbLocation.Loc.unknown
    empty_annotation (Load0 pc pp NA))))

/-- The body tail: Esseq unit (Erun ret_498 [conv_loaded_int(int, a_500)])
    (Esseq unit (pure unit) (Esave ret_498 …)). -/
def bodyTail : RExpr :=
  Expr aU (Esseq patUnit
    (Expr aU (Erun empty_annotation symRet
      [Pexpr aU () (PEcall (Sym convLoadedIntSym)
        [Pexpr aU () (PEval (Vctype intCty)),
         Pexpr aU () (PEsym symA500)])]))
    (Expr aU (Esseq patUnit
      (Expr aU (Epure (Pexpr aU () (PEval Vunit))))
      (Expr aU (Esave (symRet, BTy_loaded OTy_integer)
        [(symA501, ((BTy_loaded OTy_integer, none),
          Pexpr aU () (PEundef CerbLocation.Loc.unknown
            (DUMMY "UB088_reached_end_of_function"))))]
        (Expr aU (Epure (Pexpr aU () (PEsym symA501)))))))))

/-- Arena at R0 entry (the converted id body). -/
def arena0 : RExpr :=
  Expr aU (Esseq patA500
    (Expr aU (Ebound (Expr aU (Ewseq patA499
      (Expr aU (Epure (Pexpr aU () (PEsym symX))))
      (loadE (Pexpr aU () (PEval (Vctype intCty)))
             (Pexpr aU () (PEsym symA499)))))))
    bodyTail)

/-- Arena after R2 (Load operands evaluated). -/
def arena3 : RExpr :=
  Expr aU (Esseq patA500
    (Expr aU (Ebound (loadE (Pexpr [] () (PEval (Vctype intCty)))
                            (Pexpr [] () (PEval xPtrV)))))
    bodyTail)

/-- Arena after R3 (the load: Eannot-wrapped loaded value). -/
def arena4 (v : Int) : RExpr :=
  Expr aU (Esseq patA500
    (Expr aU (Ebound (Expr [] (Eannot
      [DA_pos [] (CerbMem.Footprint.FP .R xAddr 4)]
      (Expr [] (Epure (Pexpr [] () (PEval (loadedV v)))))))))
    bodyTail)

-- (Arena after R5 = bodyTail; a_500 bound in env.)

/-- Arena after R6 (Erun evaluated + jumped to ret_498's Esave body). -/
def arena7 : RExpr :=
  Expr aU (Epure (Pexpr aU () (PEsym symA501)))

/-- Arena after R7 (a_501 evaluated). -/
def arena8 (v : Int) : RExpr :=
  Expr aU (Epure (Pexpr [] () (PEval (loadedV v))))

/-! ### Environments (spelled as the runtime builds them) -/

/-- The post-callFinish environment: EXACTLY the term callFinish builds
    (RelSem/Call.lean `callFinish`: the spawned thread's env head is
    `fmapEmpty`, so the foldl-over-bound branch fires). Spelling matters:
    a `fromList` variant is propositionally equal but NOT defeq (TreeMap
    insertion shape). -/
def envPlaceholderMarker : Unit := ()  -- (position marker, removed below)
def env0 : List (Fmap sym value) :=
  [(List.foldl (fun (m : Fmap sym value) (pv : sym × value) =>
      fmapAddBy (fun (s1 s2 : sym) => Lem_Basic_classes.ordCompare s1 s2)
        pv.1 pv.2 m)
    fmapEmpty [(symX, xPtrV)])]
def env2 : List (Fmap sym value) := update_env patA499 xPtrV env0
def env5 (v : Int) : List (Fmap sym value) :=
  update_env patA500 (loadedV v) env2
/-- After the Erun/Esave jump: a_501 bound by the SAVE tau's foldl
    (Core_reduction one_step0 "SAVE (tau part)"). -/
def env7 (v : Int) : List (Fmap sym value) :=
  update_env (mk_sym_pat symA501 (BTy_loaded OTy_integer)) (loadedV v)
    (env5 v)

/-! ### Thread states (fixed fields shared; only arena/env vary) -/

def mkTh (arena : RExpr) (env : List (Fmap sym value)) : thread_state :=
  { arena := arena, stack0 := Stack_empty, errno := errPtr,
    current_loc := CerbLocation.Loc.unknown,
    exec_loc := ELoc_normal [(idT1Sym, CerbLocation.other "RelSem.callND")],
    env := env, current_proc_opt := some idT1Sym }

/-- Thread at R0 entry: current_loc is still the callND marker. -/
def th0 : thread_state :=
  { mkTh arena0 env0 with current_loc := CerbLocation.other "RelSem.callND" }
def th3 : thread_state := mkTh arena3 env2
def th4 (v : Int) : thread_state := mkTh (arena4 v) env2
def th6 (v : Int) : thread_state := mkTh bodyTail (env5 v)
def th7 (v : Int) : thread_state := mkTh arena7 (env7 v)
def th8 (v : Int) : thread_state := mkTh (arena8 v) (env7 v)

/-- The terminal dnms accumulator: thread 0 offers exactly the done step. -/
def accDone (v : Int) : Fmap thread_id (List core_step2) :=
  fmapAddBy defaultCompare 0 [Step_done2 (loadedV v)] fmapEmpty

/-! ### Driver-state frame (only the thread, memory, run-state, trace and
    step counter vary across rounds; everything else is pinned) -/

def mkDr (th : thread_state) (mem : CerbMem.MemState)
    (rs : core_run_state) (tr : List trace_event) (n : Nat) : driver_state :=
  { core_file := t1File,
    core_extern := create_extern_symmap t1File,
    core_state0 := { thread_states := [(0, (none, th))], io := initial_io_state },
    core_run_state0 := rs,
    layout_state := mem,
    concurrency_state := symInitialState symInitialPre,
    fs_state0 := CerbFS.fs_initial_state,
    trace := tr,
    symbolic_assoc := fmapEmpty,
    blocked := false,
    dr_step_counter := n }

/-- dnms: the driver's non-memory advancing loop at the T1 tagDefs. -/
abbrev dnms (fuel : Nat) (acc : Fmap thread_id (List core_step2))
    (tids : List Nat) :=
  drive_nonmemory_steps_aux2_lemFuel fuel t1File.tagDefs acc tids

/-! ## Round lemmas (fused step_ctx+advance, frame-parametric).
    Payload-opaque rounds prove by rfl. -/

/-! ## R3 — the load round (the x-sensitive memory read).
    Structure: an arithmetic byte-roundtrip lemma + a generic
    reconstruct-integer helper + the walk. -/

/-- The AbsByte the store writes for byte `i` of the injected int
    (memValueToBytes MVinteger arm over intToBytes; spelled to be defeq
    to the stored term). -/
def mkByte (x : Int) (i : Nat) : CerbMem.AbsByte :=
  { prov := .Prov_none, copyOffset := none,
    value := some ((((if x < 0 then (1 <<< 32) + x else x) >>> (i * 8)).toNat % 256).toUInt8) }

/-- THE BYTE ROUNDTRIP: 4 little-endian bytes of an int-range integer
    recombine (signed) to the integer. -/
theorem roundtrip_arith (x : Int) (h1 : -2147483648 ≤ x) (h2 : x ≤ 2147483647) :
    CerbMem.bytesToInt [mkByte x 0, mkByte x 1, mkByte x 2, mkByte x 3] true
      = some x := by
  unfold CerbMem.bytesToInt mkByte
  simp only [List.any, Option.isNone, Bool.or_false, CerbMem.bytesToInt.go]
  by_cases hx : x < 0
  · have hy0 : (0:Int) ≤ 4294967296 + x := by omega
    have hy1 : (0:Int) ≤ (4294967296 + x) / 256 := by omega
    have hy2 : (0:Int) ≤ (4294967296 + x) / 65536 := by omega
    have hy3 : (0:Int) ≤ (4294967296 + x) / 16777216 := by omega
    have d1 : (4294967296 + x) / 256 / 256 = (4294967296 + x) / 65536 := by omega
    have d2 : (4294967296 + x) / 65536 / 256 = (4294967296 + x) / 16777216 := by omega
    have d3 : (4294967296 + x) / 16777216 / 256 = 0 := by omega
    simp only [hx, if_true, if_false, reduceIte]
    simp [Int.shiftLeft_eq, Int.shiftRight_eq_div_pow, Int.toNat_of_nonneg hy0,
      Int.toNat_of_nonneg hy1, Int.toNat_of_nonneg hy2, Int.toNat_of_nonneg hy3]
    split <;> refine congrArg some ?_ <;> omega
  · have hx0 : (0:Int) ≤ x := by omega
    have hx1 : (0:Int) ≤ x / 256 := by omega
    have hx2 : (0:Int) ≤ x / 65536 := by omega
    have hx3 : (0:Int) ≤ x / 16777216 := by omega
    have d1 : x / 256 / 256 = x / 65536 := by omega
    have d2 : x / 65536 / 256 = x / 16777216 := by omega
    have d3 : x / 16777216 / 256 = 0 := by omega
    simp only [hx, if_true, if_false, reduceIte]
    simp [Int.shiftLeft_eq, Int.shiftRight_eq_div_pow, Int.toNat_of_nonneg hx0,
      Int.toNat_of_nonneg hx1, Int.toNat_of_nonneg hx2, Int.toNat_of_nonneg hx3]
    split <;> refine congrArg some ?_ <;> omega


/-! ### The prefix states, EXPLICIT (validated by the prefix-walk rfls;
    opaque-but-never-read fields are spelled as lazy projections of the
    initial values) -/

/-- The globals thread (driver_globals' spawned thread 0). -/
def thG : thread_state :=
  { arena := Expr [] (Epure (Pexpr [] () (PEval Vunit))),
    stack0 := Stack_empty,
    errno := .PV .Prov_none (.PVnull intCty),
    current_loc := CerbLocation.Loc.unknown,
    exec_loc := ELoc_globals,
    env := [fmapEmpty],
    current_proc_opt := none }

/-- Post-globals run-state: one tid drawn; sym_supply stays the opaque
    initial draw (never read on the T1 path). -/
def rsD3 : core_run_state :=
  { initial_core_run_state (collect_labeled_continuations_NEW t1File)
      with tid_supply := 1 }

def allocX : CerbMem.Allocation :=
  { base := xAddr, size := 4, ty := some intCty, prefix_ := PrefOther "callND arg" }
def allocErr : CerbMem.Allocation :=
  { base := errAddr, size := 4, ty := some signed_int, prefix_ := PrefOther "errno" }

/-- Memory after the argument injection (allocation 0 = x's object). -/
def memInj (x : Int) : CerbMem.MemState :=
  { CerbMem.initialMemState with
    nextAllocId := 1, lastAddress := xAddr,
    allocations := Std.TreeMap.empty.insert 0 allocX,
    bytemap := ((((Std.TreeMap.empty.insert xAddr (mkByte x 0)).insert
      (xAddr+1) (mkByte x 1)).insert (xAddr+2) (mkByte x 2)).insert
      (xAddr+3) (mkByte x 3)) }

/-- The errno alloc/store chain at the MEMORY level (callFinish's inner
    computation, verbatim). -/
def errAllocM : CerbMem.memM CerbMem.PointerValue :=
  nd_bind
    (CerbMem.allocateObject 0 (PrefOther "errno")
      (CerbMem.alignofIval signed_int) signed_int none none)
    (fun (ptr_val : CerbMem.PointerValue) =>
      let zero := CerbMem.integerValueMval (Signed Int_)
        (CerbMem.integerIval (0 : Int))
      nd_bind
        (CerbMem.storeM (CerbLocation.other "errno init")
          signed_int false ptr_val zero)
        (fun (_ : CerbMem.Footprint) => nd_return ptr_val))

/-- The zero byte the errno store writes. -/
def zeroByte : CerbMem.AbsByte :=
  { prov := .Prov_none, copyOffset := none, value := some 0 }

theorem sizeof_int_eq : CerbMem.sizeofCtype signed_int = 4 := rfl
theorem alignof_int_eq : CerbMem.alignofCtype signed_int = 4 := rfl

/-- The uninitialized byte allocateObject writes (init = none). -/
def uninitByte : CerbMem.AbsByte :=
  { prov := .Prov_none, copyOffset := none, value := none }

/-- The post-errno-alloc bytemap (x's bytes + uninitialized errno). -/
def bmErrAlloc (x : Int) : Std.TreeMap Int CerbMem.AbsByte :=
  (((((((( Std.TreeMap.empty.insert xAddr (mkByte x 0)).insert
    (xAddr+1) (mkByte x 1)).insert (xAddr+2) (mkByte x 2)).insert
    (xAddr+3) (mkByte x 3)).insert errAddr uninitByte).insert
    (errAddr+1) uninitByte).insert (errAddr+2) uninitByte).insert
    (errAddr+3) uninitByte)

/-- Memory after the errno allocation, before its zero-store. -/
def memErrAlloc (x : Int) : CerbMem.MemState :=
  { CerbMem.initialMemState with
    nextAllocId := 2, lastAddress := errAddr,
    allocations := (Std.TreeMap.empty.insert 0 allocX).insert 1 allocErr,
    bytemap := bmErrAlloc x }

/-- Memory at D3 (errno allocated and zero-initialized; the bytemap is
    spelled as the store's OVERWRITE of the uninitialized cells — the
    shape the computation produces). -/
def memD3 (x : Int) : CerbMem.MemState :=
  { CerbMem.initialMemState with
    nextAllocId := 2, lastAddress := errAddr,
    allocations := (Std.TreeMap.empty.insert 0 allocX).insert 1 allocErr,
    bytemap := ((((bmErrAlloc x).insert errAddr zeroByte).insert
      (errAddr+1) zeroByte).insert (errAddr+2) zeroByte).insert
      (errAddr+3) zeroByte }

-- tiny closed layout facts (kernel-trivial; feed the simp evaluations)

/-- errno's allocation step, by controlled simp evaluation. -/
theorem allocErr_eq (x : Int) :
    app (CerbMem.allocateObject 0 (PrefOther "errno")
      (CerbMem.alignofIval signed_int) signed_int none none) (memInj x)
    = (NDactive errPtr, memErrAlloc x) := by
  simp only [CerbMem.allocateObject, CerbMem.alignofIval, CerbMem.integerIval,
    app, memInj, memErrAlloc, bmErrAlloc, sizeof_int_eq,
    alignof_int_eq, errPtr, errAddr, xAddr,
    allocX, allocErr, uninitByte, CerbMem.initialMemState]
  simp [CerbMem.alignDown, CerbMem.writeBytesTo, List.replicate]

-- closed side-facts for the errno store (kernel-trivial)
theorem errStore_bytes_fact :
    CerbMem.memValueToBytes []
      (CerbMem.integerValueMval (Signed Int_) (CerbMem.integerIval 0))
    = ([], [zeroByte, zeroByte, zeroByte, zeroByte]) := rfl
theorem errStore_get_fact :
    (((Std.TreeMap.empty.insert 0 allocX).insert 1 allocErr :
        Std.TreeMap Int CerbMem.Allocation)).get? 1 = some allocErr := rfl
theorem errStore_compat_fact :
    CerbMem.ctypeMemCompatible signed_int
      (CerbMem.typeofMval (CerbMem.integerValueMval (Signed Int_)
        (CerbMem.integerIval 0))) = true := rfl
theorem errStore_bounds_fact :
    CerbMem.isInBounds allocErr errAddr 4 = true := rfl
theorem errStore_atomic_fact :
    CerbMem.isAtomicMemberAccess allocErr signed_int errAddr = false := rfl

/-- errno's zero-store step, by controlled simp evaluation. -/
theorem storeErr_eq (x : Int) :
    app (CerbMem.storeM (CerbLocation.other "errno init") signed_int false
      errPtr (CerbMem.integerValueMval (Signed Int_) (CerbMem.integerIval 0)))
      (memErrAlloc x)
    = (NDactive (CerbMem.Footprint.FP .W errAddr 4), memD3 x) := by
  simp only [CerbMem.storeM, app, memErrAlloc, memD3, sizeof_int_eq,
    errPtr, CerbMem.initialMemState, errStore_bytes_fact, errStore_get_fact,
    errStore_compat_fact, errStore_bounds_fact, errStore_atomic_fact]
  simp [CerbMem.writeBytesTo, CerbMem.isInBounds, CerbMem.isAtomicMemberAccess,
    List.foldl, allocErr, errAddr,
    show allocErr.isReadonly = .IsWritable from rfl]



/-! ### The x-load (R3's memory read): reconstructValue via the byte
    roundtrip, then the loadM equation by the same controlled-simp
    recipe as the errno ops. -/

theorem loadX_get_fact (x : Int) :
    (memD3 x).allocations[(0 : Int)]? = some allocX := rfl

-- per-key byte fetches (each a single tree walk, under the default
-- budget; the whole-list fact in one rfl is 4 walks and exceeds it)
theorem bmD3_get0 (x : Int) :
    (memD3 x).bytemap[(281474976710648 : Int)]? = some (mkByte x 0) := rfl
theorem bmD3_get1 (x : Int) :
    (memD3 x).bytemap[(281474976710649 : Int)]? = some (mkByte x 1) := rfl
theorem bmD3_get2 (x : Int) :
    (memD3 x).bytemap[(281474976710650 : Int)]? = some (mkByte x 2) := rfl
theorem bmD3_get3 (x : Int) :
    (memD3 x).bytemap[(281474976710651 : Int)]? = some (mkByte x 3) := rfl

/-- The bytes fetched at x's object (assembled from the per-key
    fetches). -/
theorem loadX_bytes_fact (x : Int) :
    CerbMem.readBytesFrom (memD3 x) 281474976710648 4
    = [mkByte x 0, mkByte x 1, mkByte x 2, mkByte x 3] := by
  simp [CerbMem.readBytesFrom, List.range, List.range.loop,
    bmD3_get0 x, bmD3_get1 x, bmD3_get2 x, bmD3_get3 x]

theorem sizeof_intCty_eq : CerbMem.sizeofCtype intCty = 4 := rfl
theorem loadX_bounds_fact :
    CerbMem.isInBounds allocX 281474976710648 4 = true := rfl
theorem loadX_atomic_fact :
    CerbMem.isAtomicMemberAccess allocX (Ctype [] (Basic (Integer (Signed Int_))))
      281474976710648 = false := rfl
theorem loadX_dead_fact (x : Int) :
    (memD3 x).deadAllocations.contains 0 = false := rfl

/-- reconstructValue on the fetched bytes = the injected integer
    (THE roundtrip payoff; fuel handled by the literal-successor jump). -/
theorem reconX_eq (x : Int) (h1 : -2147483648 ≤ x) (h2 : x ≤ 2147483647) :
    CerbMem.reconstructValue (memD3 x).lastUsedUnionMembers
      (memD3 x).funptrmap 281474976710648 intCty
      [mkByte x 0, mkByte x 1, mkByte x 2, mkByte x 3]
    = .MVinteger (Signed Int_) (.IV .Prov_none x) := by
  show CerbMem.reconstructValue_lemFuel (999999+1) _ _ _
    (Ctype [] (Basic (Integer (Signed Int_)))) _ = _
  rw [CerbMem.reconstructValue_lemFuel]
  simp only [CerberusImpl.is_signed_ity]
  rw [roundtrip_arith x h1 h2]
  simp [CerbMem.provFromIntegerBytes, CerbMem.combineProv, mkByte]

/-- The load of x's object on the D3 memory (state unchanged). -/
theorem loadX_eq (x : Int) (h1 : -2147483648 ≤ x) (h2 : x ≤ 2147483647) :
    app (CerbMem.loadM CerbLocation.Loc.unknown intCty xPtr) (memD3 x)
    = (NDactive (CerbMem.Footprint.FP .R xAddr 4,
        CerbMem.MemValue.MVinteger (Signed Int_) (.IV .Prov_none x)),
       memD3 x) := by
  simp only [CerbMem.loadM, app, xPtr, xAddr, sizeof_intCty_eq,
    loadX_dead_fact x, loadX_bytes_fact x, reconX_eq x h1 h2]
  simp [loadX_get_fact x, loadX_bounds_fact, loadX_atomic_fact, intCty]

/-- The finalization tail of callFinish (the continuation after driver2). -/
def finTail : Unit → driverM driver_result :=
  fun _ => nd_bind nd_get (fun (dr_st' : driver_state) =>
    nd_return (finalize t1File.tagDefs "callND" dr_st'))

/-- Prefix walk, part 1: callND's resolution/injection stages. -/
theorem prefix_a (x : Int) :
    app (callND t1File.tagDefs t1File "id" [intValue x])
        (initial_driver_state t1File CerbFS.fs_initial_state)
      = app (callFinish t1File.tagDefs 0 idT1Sym arena0 [(symX, xPtrV)])
          (mkDr thG (memInj x) rsD3 [] 0) := by
  refine (app_bind_active rfl).trans ?_   -- driver_globals
  refine (app_bind_active rfl).trans ?_   -- nd_get
  refine (app_bind_active rfl).trans ?_   -- resolveFunSym
  refine (app_bind_active rfl).trans ?_   -- lookupFunBody
  refine (app_bind_active rfl).trans ?_   -- lookupParamTys
  refine (app_bind_active rfl).trans ?_   -- injectArgs
  rfl

/-- Prefix walk, part 2: callFinish's thread setup up to driver2 (the
    memory ops go through `with_unfolding_all` — the elaborator's default
    whnf leaves their guard `Decidable.rec`s stuck behind un-delta'd
    instances). -/
theorem prefix_b (x : Int) :
    app (callFinish t1File.tagDefs 0 idT1Sym arena0 [(symX, xPtrV)])
        (mkDr thG (memInj x) rsD3 [] 0)
      = app (nd_bind (driver2 t1File.tagDefs false) finTail)
          (mkDr th0 (memD3 x) rsD3 [] 0) := by
  refine (app_bind_active
    (v := (mkDr thG (memInj x) rsD3 [] 0).core_state0.thread_states)
    (st' := mkDr thG (memInj x) rsD3 [] 0) rfl).trans ?_
  -- errno alloc/store through the memory lens, composed from the two
  -- simp-evaluated memory-op equations
  apply (app_bind_active (app_liftND_active _ _ _ _ ?hmem)).trans
  case hmem =>
    refine (app_bind_active (allocErr_eq x)).trans ?_
    refine (app_bind_active (storeErr_eq x)).trans ?_
    exact app_nd_return errPtr (memD3 x)
  refine (app_bind_active rfl).trans ?_  -- driver_update_thread_state
  rfl

/-- THE PREFIX WALK: callND's stages up to the driver2 iteration land on
    the mkDr-shaped D3 state. -/
theorem prefix_walk (x : Int) :
    app (callND t1File.tagDefs t1File "id" [intValue x])
        (initial_driver_state t1File CerbFS.fs_initial_state)
      = app (nd_bind (driver2 t1File.tagDefs false) finTail)
          (mkDr th0 (memD3 x) rsD3 [] 0) :=
  (prefix_a x).trans (prefix_b x)


/-- R3's trace event: the load of x's object. -/
def meLoad (x : Int) : trace_event :=
  ME_load CerbLocation.Loc.unknown none intCty xPtr
    (CerbMem.MemValue.MVinteger (Signed Int_)
      (CerbMem.IntegerValue.IV .Prov_none x))

/-- R3: the load round — the request is drawn (aid), the load performed
    (loadX_eq through the memory lens), the loaded value lands in the
    arena's Eannot context, ME_load is traced. The step counter is NOT
    bumped (action requests don't; the walk's rfl checks all of this). -/
theorem round3 (x : Int) (h1 : -2147483648 ≤ x) (h2 : x ≤ 2147483647)
    (fuel : Nat) (rs : core_run_state) (tr : List trace_event) (n : Nat) :
    app (dnms (fuel+1) fmapEmpty [0]) (mkDr th3 (memD3 x) rs tr n)
      = app (dnms fuel fmapEmpty [0]) (mkDr (th4 x) (memD3 x)
          { rs with aid_supply := rs.aid_supply + 1 } (meLoad x :: tr) n) := by
  refine (app_bind_active rfl).trans ?_               -- nd_read (step_ctx)
  apply (app_bind_active ?hadv).trans
  case hadv =>
    -- advance_step's action-request arm
    apply (app_bind_active ?hreq).trans
    case hreq =>
      refine (app_bind_active rfl).trans ?_           -- liftCore_run m_request
      rw [perform_unfold]
      refine (app_bind_active rfl).trans ?_           -- aid draw
      rw [ars_load_unfold]
      apply (app_bind_active (app_liftND_active _ _ _ _ ?hload)).trans
      case hload => exact loadX_eq x h1 h2            -- THE LOAD
      apply (app_bind_active (app_liftND_active _ _ _ _ ?hpref)).trans
      case hpref => rfl                               -- prefixOfPointer
      rfl                                             -- nd_update
    rfl                                               -- nd_return NOWAKEUP
  rfl                                                 -- recursion states match

/-! ## R6's pure eval: `eval_pexpr20` fully evaluates the
    conv_loaded_int chain in ONE call (the probe's finding); the range
    check is the only x-branch, discharged via hx bridging facts. -/

/-- The conv-call pexpr (the Erun argument). -/
def convPE : generic_pexpr Unit sym :=
  Pexpr aU () (PEcall (Sym convLoadedIntSym)
    [Pexpr aU () (PEval (Vctype intCty)), Pexpr aU () (PEsym symA500)])

/-! ### Eval-monad crossing lemmas (the `app_bind_active` pattern at the
    exception/state-exception monads — generic, proved once) -/


/-! The aux2 loop's residuals for the conv chain (probe-discovered;
    each crossing's payload is supplied EXPLICITLY in this small normal
    form so the walk never carries the unnormalized substitution). -/

def xIntV (x : Int) : value :=
  Vobject (OVinteger (CerbMem.IntegerValue.IV .Prov_none x))

def z0 (x : Int) : generic_pexpr Unit sym :=
  Pexpr [] () (PEcase (Pexpr [] () (PEval (loadedV x)))
    [(Pattern aU (CaseCtor Cspecified [Pattern aU (CaseBase (some (Symbol "" 8148669997605808657 (SD_Id "n")), BTy_object OTy_integer))]),
      Pexpr aU () (PEctor Cspecified [Pexpr aU () (PEcall (Sym convIntSym)
        [Pexpr aU () (PEval (Vctype intCty)),
         Pexpr aU () (PEsym (Symbol "" 8148669997605808657 (SD_Id "n")))])])),
     (Pattern aU (CaseCtor Cunspecified [Pattern aU (CaseBase (none, BTy_ctype))]),
      Pexpr aU () (PEctor Cunspecified [Pexpr aU () (PEval (Vctype intCty))]))])

def z1 (x : Int) : generic_pexpr Unit sym :=
  Pexpr [] () (PEctor Cspecified [Pexpr aU () (PEcall (Sym convIntSym)
    [Pexpr aU () (PEval (Vctype intCty)), Pexpr aU () (PEval (xIntV x))])])

def convElse (x : Int) : generic_pexpr Unit sym :=
  Pexpr aU () (PEif
    (Pexpr aU () (PEis_unsigned (Pexpr aU () (PEval (Vctype intCty)))))
    (Pexpr aU () (PEcall (Sym (Symbol "" 14671517598387306907 (SD_Id "wrapI")))
      [Pexpr aU () (PEval (Vctype intCty)), Pexpr aU () (PEval (xIntV x))]))
    (Pexpr aU () (PEcall (Impl Integer__conv_nonrepresentable_signed_integer)
      [Pexpr aU () (PEval (Vctype intCty)), Pexpr aU () (PEval (xIntV x))])))

def z2 (x : Int) : generic_pexpr Unit sym :=
  Pexpr [] () (PEctor Cspecified [Pexpr [] () (PEif
    (Pexpr aU () (PEop OpEq (Pexpr aU () (PEval (Vctype intCty)))
      (Pexpr aU () (PEval (Vctype (Ctype [] (Basic (Integer Bool0))))))))
    (Pexpr aU () (PEif
      (Pexpr aU () (PEop OpEq (Pexpr aU () (PEval (xIntV x)))
        (Pexpr aU () (PEval (xIntV 0)))))
      (Pexpr aU () (PEval (xIntV 0)))
      (Pexpr aU () (PEval (xIntV 1)))))
    (Pexpr aU () (PEif
      (Pexpr aU () (PEcall (Sym isReprIntegerSym)
        [Pexpr aU () (PEval (xIntV x)), Pexpr aU () (PEval (Vctype intCty))]))
      (Pexpr aU () (PEval (xIntV x)))
      (convElse x))))])

def z3 (x : Int) : generic_pexpr Unit sym :=
  Pexpr [] () (PEctor Cspecified [Pexpr [] () (PEif
    (Pexpr [] () (PEop OpAnd
      (Pexpr [] () (PEop OpLe
        (Pexpr [] () (PEctor Civmin [Pexpr aU () (PEval (Vctype intCty))]))
        (Pexpr [] () (PEval (xIntV x)))))
      (Pexpr [] () (PEop OpLe
        (Pexpr [] () (PEval (xIntV x)))
        (Pexpr [] () (PEctor Civmax [Pexpr aU () (PEval (Vctype intCty))]))))))
    (Pexpr aU () (PEval (xIntV x)))
    (convElse x))])

def z4 (x : Int) : generic_pexpr Unit sym :=
  Pexpr [] () (PEval (loadedV x))


/-- convPE in pull-normal form (top annots stripped). -/
def convPE_p : generic_pexpr Unit sym :=
  Pexpr [] () (PEcall (Sym convLoadedIntSym)
    [Pexpr aU () (PEval (Vctype intCty)), Pexpr aU () (PEsym symA500)])

theorem pull_convPE : pull_constrained 0 convPE = convPE_p := rfl
theorem pull_z0 (x : Int) : pull_constrained 0 (z0 x) = z0 x := rfl
theorem pull_z1 (x : Int) : pull_constrained 0 (z1 x) = z1 x := rfl
theorem pull_z2 (x : Int) : pull_constrained 0 (z2 x) = z2 x := rfl
theorem pull_z3 (x : Int) : pull_constrained 0 (z3 x) = z3 x := rfl

/-- The five one-step evaluations of the aux2 loop on the conv chain
    (probe-discovered residuals; s4 carries the range check). -/
theorem s0_eq (x : Int) (mem : CerbMem.MemState) :
    step_eval_pexpr t1File.tagDefs 0 CerbLocation.Loc.unknown
      (some (CerbLocation.other "RelSem.callND")) (create_extern_symmap t1File)
      (env5 x) (some mem) t1File false convPE_p = Result (Defined (z0 x)) := rfl

theorem s1_eq (x : Int) (mem : CerbMem.MemState) :
    step_eval_pexpr t1File.tagDefs 0 CerbLocation.Loc.unknown
      (some (CerbLocation.other "RelSem.callND")) (create_extern_symmap t1File)
      (env5 x) (some mem) t1File false (z0 x) = Result (Defined (z1 x)) := rfl

theorem s2_eq (x : Int) (mem : CerbMem.MemState) :
    step_eval_pexpr t1File.tagDefs 0 CerbLocation.Loc.unknown
      (some (CerbLocation.other "RelSem.callND")) (create_extern_symmap t1File)
      (env5 x) (some mem) t1File false (z1 x) = Result (Defined (z2 x)) := rfl

theorem s3_eq (x : Int) (mem : CerbMem.MemState) :
    step_eval_pexpr t1File.tagDefs 0 CerbLocation.Loc.unknown
      (some (CerbLocation.other "RelSem.callND")) (create_extern_symmap t1File)
      (env5 x) (some mem) t1File false (z2 x) = Result (Defined (z3 x)) := rfl


/-- s4: the range check (hx enters). -/
theorem s4_eq (x : Int) (h1 : -2147483648 ≤ x) (h2 : x ≤ 2147483647)
    (mem : CerbMem.MemState) :
    step_eval_pexpr t1File.tagDefs 0 CerbLocation.Loc.unknown
      (some (CerbLocation.other "RelSem.callND")) (create_extern_symmap t1File)
      (env5 x) (some mem) t1File false (z3 x) = Result (Defined (z4 x)) := by
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
                show step_eval_pexpr_lemFuel 999997 t1File.tagDefs (0+1+1+1)
                  CerbLocation.Loc.unknown (some (CerbLocation.other "RelSem.callND"))
                  (create_extern_symmap t1File) (env5 x) (some mem) t1File false
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
                show step_eval_pexpr_lemFuel 999997 t1File.tagDefs (0+1+1+1)
                  CerbLocation.Loc.unknown (some (CerbLocation.other "RelSem.callND"))
                  (create_extern_symmap t1File) (env5 x) (some mem) t1File false
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

theorem convCore_eq (x : Int) (h1 : -2147483648 ≤ x) (h2 : x ≤ 2147483647)
    (mem : CerbMem.MemState) :
    eval_pexpr_aux2 t1File.tagDefs CerbLocation.Loc.unknown
      (some (CerbLocation.other "RelSem.callND"))
      (create_extern_symmap t1File) (env5 x) (some mem) t1File convPE
    = Result (Defined (Sum.inr (loadedV x))) :=
  (aux2_step 999999 _ _ _ _ _ _ _ (pull_convPE)
      (by intro a xs h; simp [convPE_p] at h) (s0_eq x mem) (by rfl)).trans
  ((aux2_step 999998 _ _ _ _ _ _ _ (pull_z0 x)
      (by intro a xs h; simp [z0] at h) (s1_eq x mem) (by rfl)).trans
  ((aux2_step 999997 _ _ _ _ _ _ _ (pull_z1 x)
      (by intro a xs h; simp [z1] at h) (s2_eq x mem) (by rfl)).trans
  ((aux2_step 999996 _ _ _ _ _ _ _ (pull_z2 x)
      (by intro a xs h; simp [z2] at h) (s3_eq x mem) (by rfl)).trans
  (aux2_done 999995 _ _ _ _ _ _ _ (pull_z3 x)
      (by intro a xs h; simp [z3] at h) (s4_eq x h1 h2 mem) (by rfl)))))

theorem convStep_eq (x : Int) (h1 : -2147483648 ≤ x) (h2 : x ≤ 2147483647)
    (mem : CerbMem.MemState) (rs : core_run_state) :
    E.eval_pexpr20 t1File.tagDefs (th6 x) (create_extern_symmap t1File)
      mem t1File convPE rs
    = Result (Defined (Sum.inr (loadedV x)), rs) := by
  simp only [E.eval_pexpr20, th6, mkTh]
  rw [convCore_eq x h1 h2 mem]
  rfl


/-- full_eval on the conv pexpr (the aux2 loop's verdict lifted into the
    state monad; rs generic — nothing on this path reads it). -/
theorem fullEval_conv_eq (x : Int) (h1 : -2147483648 ≤ x)
    (h2 : x ≤ 2147483647) (mem : CerbMem.MemState) (rs : core_run_state) :
    full_eval_pexpr t1File.tagDefs (th6 x) (create_extern_symmap t1File)
      mem t1File convPE rs
    = Result (Defined (loadedV x), rs) := by
  change stExceptUndef_bind _ _ _ = _
  refine (stub_defined (convStep_eq x h1 h2 mem rs)).trans ?_
  rfl

/-- R6: the Erun eval round — the conv chain evaluates (fullEval_conv_eq),
    the jump to ret_498's continuation binds a_501. rs must be concrete
    enough for the label resolution; the round is stated at the chain's
    actual run-state (rsD3 with the load's aid drawn). -/
theorem round6 (x : Int) (h1 : -2147483648 ≤ x) (h2 : x ≤ 2147483647)
    (fuel : Nat) (mem : CerbMem.MemState)
    (tr : List trace_event) (n : Nat) :
    app (dnms (fuel+1) fmapEmpty [0])
        (mkDr (th6 x) mem { rsD3 with aid_supply := rsD3.aid_supply + 1 } tr n)
      = app (dnms fuel fmapEmpty [0])
        (mkDr (th7 x) mem { rsD3 with aid_supply := rsD3.aid_supply + 1 }
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

/-! ## Composition: the nine rounds chained, the scheduler pick, the
    driver2 iteration, and THE T1 APP EQUATION -/

/-- The run-state after the load's action-id draw. -/
def rsR6 : core_run_state := { rsD3 with aid_supply := rsD3.aid_supply + 1 }

/-- The full dnms run at the default budget: nine rounds — the
    mechanical seven through `app_walk` (arc-9 S2 calibration; the
    round0-2/4-5/7-8 hand lemmas and the arena1/2/5–th1/2/5
    intermediate transcriptions are DELETED), the two semantic rounds
    (R3 load, R6 conv-chain) as explicit `app_walk_step`s. Statement
    and axiom cone IDENTICAL to the arc-7 hand chain. -/
theorem dnms_chain (x : Int) (h1 : -2147483648 ≤ x) (h2 : x ≤ 2147483647) :
    app (dnms lemDefaultFuel fmapEmpty [0]) (mkDr th0 (memD3 x) rsD3 [] 0)
      = (NDactive (accDone x), mkDr (th8 x) (memD3 x) rsR6 [meLoad x] 7) := by
  app_walk
  app_walk_step (round3 x h1 h2 999996 rsD3 [] 3)
  app_walk
  app_walk_step (round6 x h1 h2 999993 (memD3 x) [meLoad x] 5)
  app_walk

/-- The scheduler sees exactly the done step. -/
theorem ndct_eq (x : Int) (h1 : -2147483648 ≤ x) (h2 : x ≤ 2147483647) :
    app (new_drive_core_threads t1File.tagDefs ())
        (mkDr th0 (memD3 x) rsD3 [] 0)
      = (NDactive [(0, some (Step_done2 (loadedV x)))],
         mkDr (th8 x) (memD3 x) rsR6 [meLoad x] 7) := by
  refine (app_bind_active rfl).trans ?_          -- nd_get (tids)
  refine (app_bind_active (dnms_chain x h1 h2)).trans ?_
  rfl                                            -- nd_mapM pick (singleton)

/-- The post-exit thread (prepare_exit's rebuild). -/
def thDone (x : Int) : thread_state :=
  { th8 x with stack0 := Stack_empty, arena := mk_value_e (loadedV x) }

/-- The final driver state of the harness run. -/
def drDone (x : Int) : driver_state :=
  mkDr (thDone x) (memD3 x) rsR6 [meLoad x] 7

/-- ONE driver2 iteration does the whole run (Step_done2 exits). The
    execution-mode read is an OPAQUE global (CerbGlobal); both the
    random and the exhaustive scheduling branches take the same singleton
    step, so the opaque Bool is dispatched by cases — no axiom, no
    assumption on the runtime configuration. -/
theorem driver2_iter (x : Int) (h1 : -2147483648 ≤ x) (h2 : x ≤ 2147483647) :
    app (driver2 t1File.tagDefs false) (mkDr th0 (memD3 x) rsD3 [] 0)
      = (NDactive (), drDone x) := by
  show app (driver2_lemFuel (999999+1) t1File.tagDefs false)
    (mkDr th0 (memD3 x) rsD3 [] 0) = (NDactive (), drDone x)
  change app (nd_bind _ _) _ = _
  refine (app_bind_active (ndct_eq x h1 h2)).trans ?_
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

/-- THE T1 HARNESS APP EQUATION, composed. -/
theorem t1_app_eq (x : Int) (h1 : -2147483648 ≤ x) (h2 : x ≤ 2147483647) :
    app (callND t1File.tagDefs t1File "id" [intValue x])
        (initial_driver_state t1File CerbFS.fs_initial_state)
      = (NDactive (finalize t1File.tagDefs "callND" (drDone x)), drDone x) := by
  refine (prefix_walk x).trans ?_
  refine (app_bind_active (driver2_iter x h1 h2)).trans ?_
  refine (app_bind_active rfl).trans ?_          -- finTail's nd_get
  rfl                                            -- nd_return finalize

/-- The finalize result carries the injected integer, Specified. -/
theorem t1_result_eq (x : Int) :
    (finalize t1File.tagDefs "callND" (drDone x)).dres_core_value
      = intValue x := rfl

end RelSem.T1
