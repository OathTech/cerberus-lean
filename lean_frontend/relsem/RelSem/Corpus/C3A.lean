/-
  RelSem.Corpus.C3A — arc-18 R6 batch 2 (2026-08-27): CENSUS-tier c3a.

  tests/verify/c3a_accguard.c — `int acc10(int p, int d)`: the
  digit-accumulate OVERFLOW GUARDS of uri.c:350–355 (census row L5's
  arithmetic half; the scan-loop half is c3b). TWO ARGUMENTS — the
  first two-argument corpus fixture: the double injection through
  `inject_ptr_arg2` (argobj2, the T2Threaded shape) and the READ2
  driver atom (both argument objects read-only; maps unchanged).

  House rules: no sorry, no axioms. Under the in-build audit.
-/

import RelSem.Threaded
import RelSem.PerStepTactics
import RelSem.DeriveState
import RelSem.RoundEval
import RelSem.ConstructLaws
import RelSem.SlateFiles
import RelSem.CerbHeapWalk
import RelSem.SegmentFaces

set_option autoImplicit false

namespace RelSem.C3A

open RelSem RelSem.Cerb RelSem.Slate RelSem.Kit
open Lem_Basic_classes (ordCompare)

/-! ## Statement data -/

/-- c3a's filesystem state (initial, as every slate fixture). -/
def c3aFs : CerbFS.FsState := CerbFS.fs_initial_state

/-- c3a's pure spec on driver results: acc10(21474836, 5) =
    214748365, Specified. -/
def c3aSpec (r : driver_result) : Prop :=
  r.dres_core_value = intValue 214748365

/-! ## Fixture data -/

/-- `acc10`'s parameter symbols (the emitted decl's binders). -/
def symP : sym := Symbol "" 7187156974425934 (SD_Id "p")
def symD : sym := Symbol "" 13210364986222294696 (SD_Id "d")

def pAddr : Int := 281474976710648
def dAddr : Int := 281474976710644
def errAddr : Int := 281474976710640

def pPtr : CerbMem.PointerValue := .PV (.Prov_some 0) (.PVconcrete none pAddr)
def dPtr : CerbMem.PointerValue := .PV (.Prov_some 1) (.PVconcrete none dAddr)
def errPtr : CerbMem.PointerValue := .PV (.Prov_some 2) (.PVconcrete none errAddr)

def allocP : CerbMem.Allocation :=
  { base := pAddr, size := 4, ty := some signed_int,
    prefix_ := PrefOther "callND arg" }
def allocD : CerbMem.Allocation :=
  { base := dAddr, size := 4, ty := some signed_int,
    prefix_ := PrefOther "callND arg" }
def allocErr : CerbMem.Allocation :=
  { base := errAddr, size := 4, ty := some signed_int,
    prefix_ := PrefOther "errno" }

/-- Little-endian byte `i` of an int-range integer. -/
def mkByte (x : Int) (i : Nat) : CerbMem.AbsByte :=
  { prov := .Prov_none, copyOffset := none,
    value := some ((((if x < 0 then (1 <<< 32) + x else x) >>> (i * 8)).toNat % 256).toUInt8) }

/-- The int byte image as a list. -/
def i32 (v : Int) : List CerbMem.AbsByte :=
  [mkByte v 0, mkByte v 1, mkByte v 2, mkByte v 3]

def uninitByte : CerbMem.AbsByte :=
  { prov := .Prov_none, copyOffset := none, value := none }

/-- The argument objects' byte images (p = 21474836, d = 5). -/
def argBytesP : List CerbMem.AbsByte := i32 21474836
def argBytesD : List CerbMem.AbsByte := i32 5

/-- The memory ladder (both injections then errno; anchor data). -/
def memAllocP : CerbMem.MemState :=
  CerbMem.writeBytesTo
    { CerbMem.initialMemState with
      nextAllocId := 1, lastAddress := pAddr,
      allocations := Std.TreeMap.empty.insert 0 allocP }
    pAddr (List.replicate 4 uninitByte)

def memInjP : CerbMem.MemState :=
  CerbMem.writeBytesTo { memAllocP with funptrmap := [] } pAddr argBytesP

def memAllocD : CerbMem.MemState :=
  CerbMem.writeBytesTo
    { memInjP with
      nextAllocId := 2, lastAddress := dAddr,
      allocations := (Std.TreeMap.empty.insert 0 allocP).insert 1 allocD }
    dAddr (List.replicate 4 uninitByte)

def memInj : CerbMem.MemState :=
  CerbMem.writeBytesTo { memAllocD with funptrmap := [] } dAddr argBytesD

def memErrAlloc : CerbMem.MemState :=
  CerbMem.writeBytesTo
    { memInj with
      nextAllocId := 3, lastAddress := errAddr,
      allocations :=
        (((Std.TreeMap.empty.insert 0 allocP).insert 1 allocD).insert
          2 allocErr) }
    errAddr (List.replicate 4 uninitByte)

def memD3 : CerbMem.MemState :=
  CerbMem.writeBytesTo { memErrAlloc with funptrmap := [] } errAddr (i32 0)

/-- `acc10`'s Core body, projected from the emitted (drift-gated)
    declaration. -/
def acc10Body : generic_expr core_run_annotation Unit sym :=
  match fmapLookupBy (fun (s1 s2 : sym) => ordCompare s1 s2) accguardC3ASym
      c3aFile.funs with
  | some (Proc _ _ _ _ e) => e
  | _ => Expr [] (Epure (Pexpr [] () (PEval Vunit)))

/-- The ready thread (both arguments bound, runtime fold spelling). -/
def thRdy : thread_state :=
  { arena := acc10Body,
    stack0 := Stack_empty,
    errno := errPtr,
    current_loc := CerbLocation.other "RelSem.callND",
    exec_loc := ELoc_normal [(accguardC3ASym, CerbLocation.other "RelSem.callND")],
    env := [fmapAddBy (fun (s1 s2 : sym) => ordCompare s1 s2) symD
      (Vobject (OVpointer dPtr))
      (fmapAddBy (fun (s1 s2 : sym) => ordCompare s1 s2) symP
        (Vobject (OVpointer pPtr)) fmapEmpty)],
    current_proc_opt := some accguardC3ASym }

/-! ## The named-state ladder (minted) -/

derive_state_step dG (seed : Nat)
  from (driver_globals c3aFile.tagDefs false c3aFile)
  at (initial_driver_state_threaded seed c3aFile c3aFs)

derive_state dInj (seed : Nat) : driver_state :=
  { dG seed with layout_state := memInj }

derive_state dErr (seed : Nat) : driver_state :=
  { dG seed with layout_state := memD3 }

derive_state dRdy (seed : Nat) : driver_state :=
  { dErr seed with
    core_state0 := update_thread_state 0 thRdy (dErr seed).core_state0 }

/-! ### The rest ladder -/

abbrev rInit (seed : Nat) : driver_state :=
  restOf (initial_driver_state_threaded seed c3aFile c3aFs)
abbrev rGlob (seed : Nat) : driver_state := restOf (dG seed)
abbrev rInj (seed : Nat) : driver_state :=
  restAllocR (restAllocR (rGlob seed) pAddr) dAddr
abbrev rErr (seed : Nat) : driver_state :=
  restAllocR (rInj seed) errAddr
abbrev rRdy (seed : Nat) : driver_state := restOf (dRdy seed)

/-! ## The open-memory harness spine -/

@[seg_eq rest]
theorem k1_o (seed : Nat) : ∀ bm am,
    app (driver_globals c3aFile.tagDefs false c3aFile)
        (setMaps (rInit seed) bm am)
      = (NDactive 0, setMaps (rGlob seed) bm am) := fun _ _ => rfl

/-- The post-globals canonical representative (`nd_get` joint). -/
@[seg_canon]
theorem c3a_canon (seed : Nat) : Seg.CanonAt (rGlob seed) (dG seed) :=
  rfl

@[seg_eq rest]
theorem k3_o (seed : Nat) : ∀ bm am,
    app (resolveFunSym (dG seed).core_file "acc10")
        (setMaps (rGlob seed) bm am)
      = (NDactive accguardC3ASym, setMaps (rGlob seed) bm am) :=
  fun _ _ => rfl

@[seg_eq rest]
theorem k4_o (seed : Nat) : ∀ bm am,
    app (lookupFunBody (dG seed).core_file accguardC3ASym)
        (setMaps (rGlob seed) bm am)
      = (NDactive ([(symP, BTy_object OTy_pointer),
                    (symD, BTy_object OTy_pointer)], acc10Body),
         setMaps (rGlob seed) bm am) := fun _ _ => rfl

@[seg_eq rest]
theorem k5_o (seed : Nat) : ∀ bm am,
    app (lookupParamTys (dG seed).core_file accguardC3ASym)
        (setMaps (rGlob seed) bm am)
      = (NDactive [signed_int, signed_int], setMaps (rGlob seed) bm am) :=
  fun _ _ => rfl

/-- The first argument-object address arithmetic. -/
@[seg_fact]
theorem argAddrP_fact (seed : Nat) :
    ((CerbMem.alignDown
        ((rGlob seed).layout_state.lastAddress - 4).toNat
        ((4 : Int).toNat.max 1) : Nat) : Int) = pAddr := by
  rw [show (rGlob seed).layout_state.lastAddress
    = (281474976710655 : Int) from rfl]
  decide

/-- The second argument-object address arithmetic. -/
@[seg_fact]
theorem argAddrD_fact :
    ((CerbMem.alignDown ((pAddr : Int) - 4).toNat
        ((4 : Int).toNat.max 1) : Nat) : Int) = dAddr := by
  decide

/-- The memValues the caller protocol computes for the arguments. -/
theorem memValueFromValue_c3aP_eq :
    memValueFromValue c3aFile.tagDefs signed_int (intValue 21474836)
      = some (CerbMem.integerValueMval (Signed Int_)
          (CerbMem.integerIval 21474836)) := rfl
theorem memValueFromValue_c3aD_eq :
    memValueFromValue c3aFile.tagDefs signed_int (intValue 5)
      = some (CerbMem.integerValueMval (Signed Int_)
          (CerbMem.integerIval 5)) := rfl

/-- Stage 6, BOTH ARGUMENT INJECTIONS at open maps (the
    `inject_ptr_arg2` construct law — the T2Threaded argobj2 shape). -/
@[seg_eq argobj2]
theorem k6_o (seed : Nat) : ∀ bm am,
    app (injectArgs c3aFile.tagDefs 0
          [(symP, BTy_object OTy_pointer), (symD, BTy_object OTy_pointer)]
          [signed_int, signed_int] [intValue 21474836, intValue 5])
        (setMaps (rGlob seed) bm am)
      = (NDactive [(symP, Vobject (OVpointer pPtr)),
                   (symD, Vobject (OVpointer dPtr))],
         allocStoreState (restAllocR (restAllocR (rGlob seed) pAddr) dAddr)
           (allocStoreBytes bm pAddr 4 argBytesP) (am.insert 0 allocP)
           dAddr 4 argBytesD 1 allocD) := by
  intro bm am
  refine Laws.inject_ptr_arg2 (σ := setMaps (rGlob seed) bm am)
    (hmvA := memValueFromValue_c3aP_eq) (hmvB := memValueFromValue_c3aD_eq)
    (hallocA := Kit.mem_alloc_block (sz := 4) (a := pAddr)
      (by exact rfl) (argAddrP_fact seed) (by exact rfl))
    (hstoreA := Kit.mem_store_block (ty := signed_int)
      (mv := CerbMem.integerValueMval (Signed Int_)
        (CerbMem.integerIval 21474836))
      (allocId := 0) (addr := pAddr) (alloc := allocP)
      (fpm := []) (bytes := argBytesP)
      (hcompat := by exact rfl)
      (hget := by
        rw [Kit.writeBytesTo_allocations]
        show (am.insert 0 allocP).get? 0 = some allocP
        simp [Std.TreeMap.get?_eq_getElem?])
      (hbounds := by exact rfl) (hro := rfl)
      (hatomic := by exact rfl)
      (hbytes := by
        rw [Kit.writeBytesTo_funptrmap]
        exact rfl))
    (hallocB := Kit.mem_alloc_block (sz := 4) (a := dAddr)
      (by exact rfl)
      (by
        rw [Kit.writeBytesTo_lastAddress, Kit.writeBytesTo_lastAddress]
        exact argAddrD_fact)
      (by exact rfl))
    (hstoreB := Kit.mem_store_block (ty := signed_int)
      (mv := CerbMem.integerValueMval (Signed Int_)
        (CerbMem.integerIval 5))
      (allocId := 1) (addr := dAddr) (alloc := allocD)
      (fpm := []) (bytes := argBytesD)
      (hcompat := by exact rfl)
      (hget := by
        simp only [Kit.writeBytesTo_allocations]
        show ((am.insert 0 allocP).insert 1 allocD).get? 1 = some allocD
        simp [Std.TreeMap.get?_eq_getElem?])
      (hbounds := by exact rfl) (hro := rfl)
      (hatomic := by exact rfl)
      (hbytes := by
        simp only [Kit.writeBytesTo_funptrmap]
        exact rfl))
    (hout := by
      simp only [writeBytesTo_eq]
      rfl)

@[seg_eq rest]
theorem k7_o (seed : Nat) : ∀ bm am,
    app get_thread_states (setMaps (rInj seed) bm am)
      = (NDactive ((dG seed).core_state0.thread_states),
         setMaps (rInj seed) bm am) :=
  fun _ _ => rfl

/-- The errno address arithmetic. -/
@[seg_fact]
theorem errAddr_fact (seed : Nat) :
    ((CerbMem.alignDown
        ((rInj seed).layout_state.lastAddress - 4).toNat
        ((4 : Int).toNat.max 1) : Nat) : Int) = errAddr := by
  rw [show (rInj seed).layout_state.lastAddress = dAddr from rfl]
  decide

/-- Stage 8, THE ERRNO BLOCK at open maps. -/
@[seg_eq argobj]
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
      (setMaps (rInj seed) bm am)
      = (NDactive errPtr,
         allocStoreState (restAllocR (rInj seed) errAddr) bm am errAddr
           4 (i32 0) 2 allocErr) := by
  intro bm am
  refine Laws.callND_errno (σ := setMaps (rInj seed) bm am)
    (halloc := Kit.mem_alloc_block (sz := 4) (a := errAddr)
      (by exact rfl) (errAddr_fact seed) (by exact rfl))
    (hstore := Kit.mem_store_block (ty := signed_int)
      (mv := CerbMem.integerValueMval (Signed Int_)
        (CerbMem.integerIval 0))
      (allocId := 2) (addr := errAddr) (alloc := allocErr)
      (fpm := []) (bytes := i32 0)
      (hcompat := by exact rfl)
      (hget := by
        rw [Kit.writeBytesTo_allocations]
        show (am.insert 2 allocErr).get? 2 = some allocErr
        simp [Std.TreeMap.get?_eq_getElem?])
      (hbounds := by exact rfl) (hro := rfl)
      (hatomic := by exact rfl)
      (hbytes := by
        rw [Kit.writeBytesTo_funptrmap]
        exact rfl))
    (hout := by
      simp only [writeBytesTo_eq]
      rfl)

/-- Stage 9, the thread setup (rest-only). -/
@[seg_eq rest]
theorem k9_o (seed : Nat) (th : thread_state) (hth : th = thRdy) :
    ∀ bm am,
    app (driver_update_thread_state 0 th : driverM Unit)
        (setMaps (rErr seed) bm am)
      = (NDactive (), setMaps (rRdy seed) bm am) := by
  subst hth; exact fun _ _ => rfl

/-! ## THE DRIVER RUN at open maps -/

/-- The ready memory at open maps (literal scalar fields). -/
def memRdy (bm : Std.TreeMap Int CerbMem.AbsByte)
    (am : Std.TreeMap Int CerbMem.Allocation) : CerbMem.MemState :=
  { CerbMem.initialMemState with
    nextAllocId := 3, lastAddress := errAddr,
    bytemap := bm, allocations := am }

/-- THE READY BUILDER. -/
def mkRdy (bm : Std.TreeMap Int CerbMem.AbsByte)
    (am : Std.TreeMap Int CerbMem.Allocation)
    (tr : List trace_event) (aid exc symc ctr : Nat) : driver_state :=
  { core_file := c3aFile,
    core_extern := create_extern_symmap c3aFile,
    core_state0 :=
      { thread_states := [(0, (none, thRdy))],
        io := initial_io_state },
    core_run_state0 :=
      { tid_supply := 1, aid_supply := aid, excluded_supply := exc,
        sym_supply := symc,
        labeled := (initial_core_run_state_threaded 0
          (collect_labeled_continuations_NEW c3aFile)).labeled },
    layout_state := memRdy bm am,
    concurrency_state := symInitialState symInitialPre,
    fs_state0 := CerbFS.fs_initial_state,
    trace := tr,
    symbolic_assoc := fmapEmpty,
    blocked := false,
    dr_step_counter := ctr }

set_option Elab.async false in
derive_rounds ro
  (bm : Std.TreeMap Int CerbMem.AbsByte)
  (am : Std.TreeMap Int CerbMem.Allocation)
  (tr : List trace_event) (aid exc symc ctr : Nat)
  (halP : am.get? 0 = some allocP)
  (halD : am.get? 1 = some allocD)
  (hrdP : CerbMem.readBytesFrom (memRdy bm am) pAddr 4 = argBytesP)
  (hrdD : CerbMem.readBytesFrom (memRdy bm am) dAddr 4 = argBytesD)
  assuming halP halD hrdP hrdD
  fencing CerbMem.writeBytesTo Std.TreeMap.insert Std.TreeMap.get? Std.TreeMap.erase
  using (c3aFile.tagDefs) 0 from (mkRdy bm am tr aid exc symc ctr) upto 250 chain builder

/-! ## The final state and the driver atom (READ2: both argument
    objects read-only; maps unchanged) -/

/-- The run's terminal value (Specified 214748365). -/
def vRes : value :=
  Vloaded (LVspecified (OVinteger
    (CerbMem.IntegerValue.IV .Prov_none 214748365)))

/-- The final driver state at zeroed maps, post `prepare_exit`. -/
noncomputable abbrev roFin0 (seed : Nat) : driver_state :=
  { ro163 Std.TreeMap.empty Std.TreeMap.empty [] 0 0 seed 0 with
    core_state0 := prepare_exit
      (ro163 Std.TreeMap.empty Std.TreeMap.empty [] 0 0 seed 0).core_state0
      vRes }

/-- The final rest. -/
noncomputable abbrev rDone (seed : Nat) : driver_state := restOf (roFin0 seed)

/-- THE DRIVER LOOP at open maps: BOTH argument objects' footprints;
    the errno object rides the frame. -/
@[seg_eq read2]
theorem driver2_o (seed : Nat) : ∀ bm am,
    am.get? 0 = some allocP → am.get? 1 = some allocD →
    (∀ i : Nat, (hi : i < argBytesP.length) →
      bm.get? (pAddr + (i : Int)) = some (argBytesP[i])) →
    (∀ i : Nat, (hi : i < argBytesD.length) →
      bm.get? (dAddr + (i : Int)) = some (argBytesD[i])) →
    app (driver2 c3aFile.tagDefs false) (setMaps (rRdy seed) bm am)
      = (NDactive (), setMaps (rDone seed) bm am) := by
  intro bm am hgP hgD hbP hbD
  have hrdP : CerbMem.readBytesFrom (memRdy bm am) pAddr 4
      = argBytesP :=
    readBytesFrom_of_pointwise rfl (fun i hi => hbP i hi)
  have hrdD : CerbMem.readBytesFrom (memRdy bm am) dAddr 4
      = argBytesD :=
    readBytesFrom_of_pointwise rfl (fun i hi => hbD i hi)
  have hchain := ro_chainrel bm am [] 0 0 seed 0 hgP hgD hrdP hrdD 999835
  have hndct : app (new_drive_core_threads c3aFile.tagDefs ())
      (mkRdy bm am [] 0 0 seed 0)
      = (NDactive [(0, some (Step_done2 vRes))],
         ro163 bm am [] 0 0 seed 0) :=
    RelSem.Laws.ndct_offer1 rfl hchain
  have h6 : app (driver2 c3aFile.tagDefs false)
      (mkRdy bm am [] 0 0 seed 0)
      = (NDactive (), setMaps (rDone seed) bm am) := by
    show app (driver2_lemFuel (999999+1) c3aFile.tagDefs false)
      (mkRdy bm am [] 0 0 seed 0) = _
    exact RelSem.Laws.driver2_done hndct (by rfl)
  have halign : setMaps (rRdy seed) bm am
      = mkRdy bm am [] 0 0 seed 0 := rfl
  rw [halign]
  exact h6

/-- c3a's FnSpec ([F9], role 1). -/
abbrev accSpec : Seg.FnSpec Unit :=
  { fname := "acc10", args := fun _ => [intValue 21474836, intValue 5],
    post := fun _ => c3aSpec }

/-! ## THE THREADED STATEMENTS (fuel-opsem faces, ∀-seed) -/

/-- THE c3a HEADLINE. -/
def C3AThreadedStatement : Prop :=
  ∀ (seed : Nat),
    CallHarnessAdequateThr seed c3aFile.tagDefs c3aFile "acc10"
      [intValue 21474836, intValue 5] c3aFs c3aSpec

/-- **c3a THREADED, UNCONDITIONAL** (trio cone; through the layer). -/
theorem C3AThreaded : C3AThreadedStatement := by
  verify_fn accSpec
  seg_auto

/-- **c3a THREADED UB-freedom** (the safety twin). -/
theorem C3AThreaded_ubFree :
    ∀ (seed : Nat),
      CallHarnessUBFreeThr seed c3aFile.tagDefs c3aFile "acc10"
        [intValue 21474836, intValue 5] c3aFs := by
  verify_fn accSpec
  seg_auto

end RelSem.C3A
