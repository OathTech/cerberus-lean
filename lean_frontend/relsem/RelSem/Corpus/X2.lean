/-
  RelSem.Corpus.X2 — arc-18 R6 batch 3 (2026-08-27): EDGE-tier x2.

  tests/verify/x2_break.c — `int cap10(int n)`: BREAK out of the
  loop (edge row x2): cap10(273) runs ONE full iteration (273 → 27)
  to the stored head, then the break arm fires (27 < 100) and the
  exit segment runs break → return n. Two segments, ZERO interior
  iterations.

  House rules: no sorry, no axioms. Under the in-build audit.
-/

import RelSem.Threaded
import RelSem.PerStepTactics
import RelSem.DeriveState
import RelSem.RoundEval
import RelSem.ConstructLaws
import RelSem.SlateFiles
import RelSem.Kit.Map
import RelSem.CerbHeapWalk
import RelSem.SegmentFaces

set_option autoImplicit false

namespace RelSem.X2

open RelSem RelSem.Cerb RelSem.Slate RelSem.Kit
open Lem_Basic_classes (ordCompare)

/-! ## Fixture data (symbols, addresses, byte images) -/

def symN : sym := Symbol "" 8148669997605808657 (SD_Id "n")
def symWhile : sym := Symbol "" 6132300274808402654 (SD_Id "while_529")

def nAddr : Int := 281474976710648
def errAddr : Int := 281474976710644

def nPtr : CerbMem.PointerValue := .PV (.Prov_some 0) (.PVconcrete none nAddr)
def errPtr : CerbMem.PointerValue := .PV (.Prov_some 1) (.PVconcrete none errAddr)

def allocN : CerbMem.Allocation :=
  { base := nAddr, size := 4, ty := some signed_int,
    prefix_ := PrefOther "callND arg" }
def allocErr : CerbMem.Allocation :=
  { base := errAddr, size := 4, ty := some signed_int,
    prefix_ := PrefOther "errno" }

def mkByte (x : Int) (i : Nat) : CerbMem.AbsByte :=
  { prov := .Prov_none, copyOffset := none,
    value := some ((((if x < 0 then (1 <<< 32) + x else x) >>> (i * 8)).toNat % 256).toUInt8) }

def i32 (v : Int) : List CerbMem.AbsByte :=
  [mkByte v 0, mkByte v 1, mkByte v 2, mkByte v 3]

def uninitByte : CerbMem.AbsByte :=
  { prov := .Prov_none, copyOffset := none, value := none }

/-! ## The builders -/

/-- `cap10`'s Core body (fixture-derived — never transcribed). -/
def cap10Body : generic_expr core_run_annotation Unit sym :=
  match fmapLookupBy (fun (s1 s2 : sym) => ordCompare s1 s2) cap10X2Sym
      x2File.funs with
  | some (Proc _ _ _ _ e) => e
  | _ => Expr [] (Epure (Pexpr [] () (PEval Vunit)))

/-- The while_529 labeled-continuation body (fixture-derived). -/
def whileBody : generic_expr core_run_annotation Unit sym :=
  match Lem_Maybe.bind0
      (fmapLookupBy (fun (s1 s2 : sym) => ordCompare s1 s2) cap10X2Sym
        (initial_core_run_state_threaded 0
          (collect_labeled_continuations_NEW x2File)).labeled)
      (fmapLookupBy (fun (s1 s2 : sym) => ordCompare s1 s2) symWhile) with
  | some pb => pb.2
  | none => Expr [] (Epure (Pexpr [] () (PEval Vunit)))

/-- The ready thread (arena = cap10's body; n bound). -/
def thRdy : thread_state :=
  { arena := cap10Body,
    stack0 := Stack_empty,
    errno := errPtr,
    current_loc := CerbLocation.other "RelSem.callND",
    exec_loc := ELoc_normal [(cap10X2Sym, CerbLocation.other "RelSem.callND")],
    env := [fmapAddBy (fun (s1 s2 : sym) => ordCompare s1 s2) symN
      (Vobject (OVpointer nPtr)) fmapEmpty],
    current_proc_opt := some cap10X2Sym }

/-- The ready memory at open maps. -/
def memRdy (bm : Std.TreeMap Int CerbMem.AbsByte)
    (am : Std.TreeMap Int CerbMem.Allocation) : CerbMem.MemState :=
  { CerbMem.initialMemState with
    nextAllocId := 2, lastAddress := errAddr,
    bytemap := bm, allocations := am }

/-- THE READY BUILDER (the entry walk's from-state). -/
def mkRdy (bm : Std.TreeMap Int CerbMem.AbsByte)
    (am : Std.TreeMap Int CerbMem.Allocation)
    (tr : List trace_event) (aid exc symc ctr : Nat) : driver_state :=
  { core_file := x2File,
    core_extern := create_extern_symmap x2File,
    core_state0 :=
      { thread_states := [(0, (none, thRdy))],
        io := initial_io_state },
    core_run_state0 :=
      { tid_supply := 1, aid_supply := aid, excluded_supply := exc,
        sym_supply := symc,
        labeled := (initial_core_run_state_threaded 0
          (collect_labeled_continuations_NEW x2File)).labeled },
    layout_state := memRdy bm am,
    concurrency_state := symInitialState symInitialPre,
    fs_state0 := CerbFS.fs_initial_state,
    trace := tr,
    symbolic_assoc := fmapEmpty,
    blocked := false,
    dr_step_counter := ctr }

/-- THE LOOP-HEAD BUILDER, stored spelling. -/
def mkLH (env : Fmap sym value) (mem : CerbMem.MemState)
    (tr : List trace_event) (aid exc symc ctr : Nat) : driver_state :=
  { core_file := x2File,
    core_extern := create_extern_symmap x2File,
    core_state0 :=
      { thread_states := [(0, (none,
          { arena := whileBody,
            stack0 := Stack_empty,
            errno := errPtr,
            current_loc := CerbLocation.Loc.unknown,
            exec_loc := ELoc_normal
              [(cap10X2Sym, CerbLocation.other "RelSem.callND")],
            env := [env],
            current_proc_opt := some cap10X2Sym }))],
        io := initial_io_state },
    core_run_state0 :=
      { tid_supply := 1, aid_supply := aid, excluded_supply := exc,
        sym_supply := symc,
        labeled := (initial_core_run_state_threaded 0
          (collect_labeled_continuations_NEW x2File)).labeled },
    layout_state := mem,
    concurrency_state := symInitialState symInitialPre,
    fs_state0 := CerbFS.fs_initial_state,
    trace := tr,
    symbolic_assoc := fmapEmpty,
    blocked := false,
    dr_step_counter := ctr }

/-! ## THE ENTRY WALK `e` — mkRdy through the prologue AND iteration 1
    (273 → 27) to the FIRST STORED loop head: 49 rounds. -/

set_option Elab.async false in
derive_rounds e (bm : Std.TreeMap Int CerbMem.AbsByte)
  (am : Std.TreeMap Int CerbMem.Allocation)
  (tr : List trace_event) (aid exc symc ctr : Nat)
  (hdig : CerberusFresh.digest () = "")
  (hscB : symc < 1152921504606846976)
  (hexcB : exc < 1152921504606846976)
  (halN : am.get? 0 = some allocN)
  (hrdN : CerbMem.readBytesFrom (memRdy bm am) nAddr 4 = i32 273)
  (hbuilt : RelSem.Kit.FmapBuilt RelSem.Kit.symCmpO
    (fmapAddBy (fun (s1 s2 : sym) => ordCompare s1 s2) symN
      (Vobject (OVpointer nPtr)) fmapEmpty))
  assuming hdig hscB hexcB halN hrdN hbuilt
  fencing fmapAddBy fmapLookupBy CerbMem.writeBytesTo Std.TreeMap.insert Std.TreeMap.get? mkByte mk_conv_int mk_call_catch_exceptional_condition mk_wrapI
  using (x2File.tagDefs) 0 from (mkRdy bm am tr aid exc symc ctr) upto 71 chain builder

/-! ## THE EXIT WALK (guard TRUE at n = 27, the break arm fires:
    break → return n — to the thread's terminal). -/

set_option Elab.async false in
derive_rounds bx (env : Fmap sym value) (mem : CerbMem.MemState)
  (tr : List trace_event) (aid exc symc ctr : Nat)
  (hdig : CerberusFresh.digest () = "")
  (hbuilt : RelSem.Kit.FmapBuilt RelSem.Kit.symCmpO env)
  (hlkN : fmapLookupBy (fun (s1 s2 : sym) => ordCompare s1 s2) symN env
    = some (Vobject (OVpointer nPtr)))
  (hdd0 : mem.deadAllocations.contains 0 = false)
  (halN : mem.allocations.get? 0 = some allocN)
  (hfpm : mem.funptrmap = [])
  (hlum : mem.lastUsedUnionMembers = [])
  (hscB : symc < 1152921504606846976)
  (hexcB : exc < 1152921504606846976)
  (hrdN : CerbMem.readBytesFrom mem nAddr 4 = i32 27)
  assuming hdig hbuilt hlkN hdd0 halN hfpm hlum hscB hexcB hrdN
  fencing fmapAddBy fmapLookupBy CerbMem.writeBytesTo mkByte mk_conv_int mk_call_catch_exceptional_condition mk_wrapI
  using (x2File.tagDefs) 0 from (mkLH env mem tr aid exc symc ctr) upto 60 chain builder

/-! ## The harness spine (the C3B recipe at the x2 data) -/

/-- x2's filesystem state (initial, as every slate fixture). -/
def x2Fs : CerbFS.FsState := CerbFS.fs_initial_state

/-- Memory after the argument allocation. -/
def memArgAlloc : CerbMem.MemState :=
  CerbMem.writeBytesTo
    { CerbMem.initialMemState with
      nextAllocId := 1, lastAddress := nAddr,
      allocations := Std.TreeMap.empty.insert 0 allocN }
    nAddr (List.replicate 4 uninitByte)

/-- Memory after the argument injection. -/
def memInj : CerbMem.MemState :=
  CerbMem.writeBytesTo { memArgAlloc with funptrmap := [] } nAddr (i32 273)

/-- Memory after the errno allocation. -/
def memErrAlloc : CerbMem.MemState :=
  CerbMem.writeBytesTo
    { memInj with
      nextAllocId := 2, lastAddress := errAddr,
      allocations := (Std.TreeMap.empty.insert 0 allocN).insert 1 allocErr }
    errAddr (List.replicate 4 uninitByte)

/-- Memory after the errno block (the pre-run memory). -/
def memD3 : CerbMem.MemState :=
  CerbMem.writeBytesTo { memErrAlloc with funptrmap := [] } errAddr (i32 0)

/-- Stage 1: driver_globals (x2 has none). -/
derive_state_step dG (seed : Nat)
  from (driver_globals x2File.tagDefs false x2File)
  at (initial_driver_state_threaded seed x2File x2Fs)

derive_state dInj (seed : Nat) : driver_state :=
  { dG seed with layout_state := memInj }

derive_state dErr (seed : Nat) : driver_state :=
  { dG seed with layout_state := memD3 }

derive_state dRdy (seed : Nat) : driver_state :=
  { dErr seed with
    core_state0 := update_thread_state 0 thRdy (dErr seed).core_state0 }

/-! ### The rest ladder -/

abbrev rInit (seed : Nat) : driver_state :=
  restOf (initial_driver_state_threaded seed x2File x2Fs)
abbrev rGlob (seed : Nat) : driver_state := restOf (dG seed)
abbrev rArg (seed : Nat) : driver_state :=
  restAllocR (rGlob seed) nAddr
abbrev rErr (seed : Nat) : driver_state :=
  restAllocR (rArg seed) errAddr
abbrev rRdy (seed : Nat) : driver_state := restOf (dRdy seed)

/-- The argument object's byte image. -/
def argBytes : List CerbMem.AbsByte := i32 273

/-! ### The open-memory stage equations -/

@[seg_eq rest]
theorem k1_o (seed : Nat) : ∀ bm am,
    app (driver_globals x2File.tagDefs false x2File)
        (setMaps (rInit seed) bm am)
      = (NDactive 0, setMaps (rGlob seed) bm am) := fun _ _ => rfl

/-- The post-globals canonical representative (`nd_get` joint). -/
@[seg_canon]
theorem x2_canon (seed : Nat) : Seg.CanonAt (rGlob seed) (dG seed) :=
  rfl

@[seg_eq rest]
theorem k3_o (seed : Nat) : ∀ bm am,
    app (resolveFunSym (dG seed).core_file "cap10")
        (setMaps (rGlob seed) bm am)
      = (NDactive cap10X2Sym, setMaps (rGlob seed) bm am) :=
  fun _ _ => rfl

@[seg_eq rest]
theorem k4_o (seed : Nat) : ∀ bm am,
    app (lookupFunBody (dG seed).core_file cap10X2Sym)
        (setMaps (rGlob seed) bm am)
      = (NDactive ([(symN, BTy_object OTy_pointer)], cap10Body),
         setMaps (rGlob seed) bm am) := fun _ _ => rfl

@[seg_eq rest]
theorem k5_o (seed : Nat) : ∀ bm am,
    app (lookupParamTys (dG seed).core_file cap10X2Sym)
        (setMaps (rGlob seed) bm am)
      = (NDactive [signed_int], setMaps (rGlob seed) bm am) :=
  fun _ _ => rfl

/-- The argument-object address arithmetic. -/
@[seg_fact]
theorem argAddr_fact (seed : Nat) :
    ((CerbMem.alignDown
        ((rGlob seed).layout_state.lastAddress - 4).toNat
        ((4 : Int).toNat.max 1) : Nat) : Int) = nAddr := by
  rw [show (rGlob seed).layout_state.lastAddress
    = (281474976710655 : Int) from rfl]
  decide

/-- The memValue the caller protocol computes for the argument. -/
theorem memValueFromValue_x2_eq :
    memValueFromValue x2File.tagDefs signed_int (intValue 273)
      = some (CerbMem.integerValueMval (Signed Int_)
          (CerbMem.integerIval 273)) := rfl

/-- Stage 6, THE ARGUMENT INJECTION at open maps. -/
@[seg_eq argobj]
theorem k6_o (seed : Nat) : ∀ bm am,
    app (injectArgs x2File.tagDefs 0
          [(symN, BTy_object OTy_pointer)] [signed_int] [intValue 273])
        (setMaps (rGlob seed) bm am)
      = (NDactive [(symN, Vobject (OVpointer nPtr))],
         allocStoreState (restAllocR (rGlob seed) nAddr) bm am nAddr 4
           argBytes 0 allocN) := by
  intro bm am
  refine Laws.inject_ptr_arg1 (σ := setMaps (rGlob seed) bm am)
    (hmv := memValueFromValue_x2_eq)
    (halloc := Kit.mem_alloc_block (sz := 4) (a := nAddr)
      (by exact rfl) (argAddr_fact seed) (by exact rfl))
    (hstore := Kit.mem_store_block (ty := signed_int)
      (mv := CerbMem.integerValueMval (Signed Int_)
        (CerbMem.integerIval 273))
      (allocId := 0) (addr := nAddr) (alloc := allocN)
      (fpm := []) (bytes := argBytes)
      (hcompat := by exact rfl)
      (hget := by
        rw [Kit.writeBytesTo_allocations]
        show (am.insert 0 allocN).get? 0 = some allocN
        simp [Std.TreeMap.get?_eq_getElem?])
      (hbounds := by exact rfl) (hro := rfl)
      (hatomic := by exact rfl)
      (hbytes := by
        rw [Kit.writeBytesTo_funptrmap]
        exact rfl))
    (hout := by
      simp only [writeBytesTo_eq]
      rfl)

@[seg_eq rest]
theorem k7_o (seed : Nat) : ∀ bm am,
    app get_thread_states (setMaps (rArg seed) bm am)
      = (NDactive ((dG seed).core_state0.thread_states),
         setMaps (rArg seed) bm am) :=
  fun _ _ => rfl

/-- The errno address arithmetic. -/
@[seg_fact]
theorem errAddr_fact (seed : Nat) :
    ((CerbMem.alignDown
        ((rArg seed).layout_state.lastAddress - 4).toNat
        ((4 : Int).toNat.max 1) : Nat) : Int) = errAddr := by
  rw [show (rArg seed).layout_state.lastAddress = nAddr from rfl]
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
      (setMaps (rArg seed) bm am)
      = (NDactive errPtr,
         allocStoreState (restAllocR (rArg seed) errAddr) bm am errAddr
           4 (i32 0) 1 allocErr) := by
  intro bm am
  refine Laws.callND_errno (σ := setMaps (rArg seed) bm am)
    (halloc := Kit.mem_alloc_block (sz := 4) (a := errAddr)
      (by exact rfl) (errAddr_fact seed) (by exact rfl))
    (hstore := Kit.mem_store_block (ty := signed_int)
      (mv := CerbMem.integerValueMval (Signed Int_)
        (CerbMem.integerIval 0))
      (allocId := 1) (addr := errAddr) (alloc := allocErr)
      (fpm := []) (bytes := i32 0)
      (hcompat := by exact rfl)
      (hget := by
        rw [Kit.writeBytesTo_allocations]
        show (am.insert 1 allocErr).get? 1 = some allocErr
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

/-! ## Obligation feeds -/

/-- Head thread of a driver state (total; helper). -/
def thOf (σ : driver_state) : thread_state :=
  match σ.core_state0.thread_states with
  | (_, (_, th)) :: _ => th
  | [] => thRdy

/-- envOf (total; the family's env projection). -/
def envOf (σ : driver_state) : Fmap sym value :=
  match (thOf σ).env with
  | e :: _ => e
  | [] => fmapEmpty

section Feeds
variable (bm : Std.TreeMap Int CerbMem.AbsByte)
  (am : Std.TreeMap Int CerbMem.Allocation)
  (env : Fmap sym value) (mem : CerbMem.MemState)
  (tr : List trace_event) (aid exc symc ctr : Nat)

/-- E's endpoint memory, pinned tidy (rfl). -/
theorem e71_mem :
    (e71 bm am tr aid exc symc ctr).layout_state
      = CerbMem.writeBytesTo (memRdy bm am) nAddr (i32 27) := rfl

theorem bx53_mem :
    (bx53 env mem tr aid exc symc ctr).layout_state = mem := rfl

/-- Supply projections (rfl pins). -/
theorem e71_symc :
    (e71 bm am tr aid exc symc ctr).core_run_state0.sym_supply
      = symc + 1 := rfl
theorem e71_exc :
    (e71 bm am tr aid exc symc ctr).core_run_state0.excluded_supply
      = exc + 1 := rfl

end Feeds

/-! ### The stored-spelling alignment -/

section Aligns
variable (bm : Std.TreeMap Int CerbMem.AbsByte)
  (am : Std.TreeMap Int CerbMem.Allocation)

theorem e71_align (tr : List trace_event) (aid exc symc ctr : Nat) :
    e71 bm am tr aid exc symc ctr
      = mkLH (envOf (e71 bm am tr aid exc symc ctr))
          (e71 bm am tr aid exc symc ctr).layout_state
          (e71 bm am tr aid exc symc ctr).trace
          (e71 bm am tr aid exc symc ctr).core_run_state0.aid_supply
          (e71 bm am tr aid exc symc ctr).core_run_state0.excluded_supply
          (e71 bm am tr aid exc symc ctr).core_run_state0.sym_supply
          (e71 bm am tr aid exc symc ctr).dr_step_counter := rfl

end Aligns

/-- The ready builder aligns with the harness rest at the canonical
    supplies. -/
theorem mkRdy_align (seed : Nat)
    (bm : Std.TreeMap Int CerbMem.AbsByte)
    (am : Std.TreeMap Int CerbMem.Allocation) :
    setMaps (rRdy seed) bm am = mkRdy bm am [] 0 0 seed 0 := rfl

/-- A body/exit walk applied at a state's own components. -/
noncomputable def atComps
    (f : Fmap sym value → CerbMem.MemState → List trace_event →
      Nat → Nat → Nat → Nat → driver_state)
    (σ : driver_state) : driver_state :=
  f (envOf σ) σ.layout_state σ.trace
    σ.core_run_state0.aid_supply σ.core_run_state0.excluded_supply
    σ.core_run_state0.sym_supply σ.dr_step_counter

section Sites
variable (bm : Std.TreeMap Int CerbMem.AbsByte)
  (am : Std.TreeMap Int CerbMem.Allocation) (seed : Nat)

/-- The (single) stored loop head + the final state. -/
noncomputable abbrev h1 : driver_state := e71 bm am [] 0 0 seed 0
noncomputable abbrev hFin : driver_state := atComps bx53 (h1 bm am seed)

/-- The run's terminal value (Specified 27). -/
def v27 : value :=
  Vloaded (LVspecified (OVinteger
    (CerbMem.IntegerValue.IV .Prov_none 27)))

/-- SITE 0 — the entry segment's chain (mkRdy → h1). -/
theorem seg_entry (hdig : CerberusFresh.digest () = "")
    (hsB : seed + 16 < 1152921504606846976)
    (halN : am.get? 0 = some allocN)
    (hb : ∀ i : Nat, (hi : i < argBytes.length) →
      bm.get? (nAddr + (i : Int)) = some argBytes[i]) :
    ∀ fuel, app (drive_nonmemory_steps_aux2_lemFuel (fuel + 71)
        x2File.tagDefs fmapEmpty [0]) (mkRdy bm am [] 0 0 seed 0)
      = app (drive_nonmemory_steps_aux2_lemFuel fuel
          x2File.tagDefs fmapEmpty [0]) (h1 bm am seed) :=
  e_chainrel bm am [] 0 0 seed 0 hdig (by omega) (by omega) halN
    (readBytesFrom_of_pointwise rfl (fun i hi => hb i hi))
    Kit.fmapAddBy_built_empty

/-- SITE 1 — the exit segment's terminal chain (h1 → the done offer,
    through the multi-exit arm). -/
theorem seg_exit (hdig : CerberusFresh.digest () = "")
    (hsB : seed + 16 < 1152921504606846976)
    (halN : am.get? 0 = some allocN)
    (hb : ∀ i : Nat, (hi : i < argBytes.length) →
      bm.get? (nAddr + (i : Int)) = some argBytes[i]) :
    ∀ fuel, app (drive_nonmemory_steps_aux2_lemFuel (fuel + 55)
        x2File.tagDefs fmapEmpty [0]) (h1 bm am seed)
      = (NDactive (fmapAddBy defaultCompare 0
          [Step_done2 (Vloaded (LVspecified (OVinteger
            (CerbMem.IntegerValue.IV CerbMem.Provenance.Prov_none
              (Int.ofNat 27)))))] fmapEmpty),
         hFin bm am seed) := by
  have hsymc : (h1 bm am seed).core_run_state0.sym_supply
      = seed + 1 := e71_symc bm am [] 0 0 seed 0
  have halign : h1 bm am seed
      = mkLH (envOf (h1 bm am seed))
          (h1 bm am seed).layout_state
          (h1 bm am seed).trace
          (h1 bm am seed).core_run_state0.aid_supply
          (h1 bm am seed).core_run_state0.excluded_supply
          (h1 bm am seed).core_run_state0.sym_supply
          (h1 bm am seed).dr_step_counter :=
    e71_align bm am [] 0 0 seed 0
  rw [halign]
  refine bx_chainrel _ _ _ _ _ _ _
    hdig ?xbuilt ?xlkN ?xdd0 ?xalN ?xfpm ?xlum ?xscB ?xexcB ?xrdN
  case xbuilt => rfl
  case xlkN => seg_env_lookup
  case xdd0 => rfl
  case xalN => exact halN
  case xfpm => rfl
  case xlum => rfl
  case xscB => show seed + 1 < 1152921504606846976; omega
  case xexcB => show (1 : Nat) < 1152921504606846976; omega
  case xrdN => exact Kit.readBytesFrom_writeBytesTo_hit rfl

end Sites

/-! ## Statement data + THE INVARIANT (one head, zero interior
    iterations — the multi-exit edge composition) -/

/-- x2's pure spec on driver results. -/
def x2Spec (r : driver_result) : Prop :=
  r.dres_core_value = intValue 27

/-- The environment hypothesis (digest pin). -/
def X2EnvHypThr : Prop := CerberusFresh.digest () = ""

/-- Seed apartness (T7SeedApart lineage). -/
def X2SeedApart (seed : Nat) : Prop :=
  seed + 16 < 1152921504606846976

/-- The label's spelling table ([F3]): stored spelling only. -/
def spellX2 : Seg.JoinSpellings Seg.LoopComps where
  entry c := mkLH c.env c.mem c.tr c.aid c.exc c.symc c.ctr
  stored c := mkLH c.env c.mem c.tr c.aid c.exc c.symc c.ctr

/-- Component projection. -/
def compOf (σ : driver_state) : Seg.LoopComps :=
  { env := envOf σ, mem := σ.layout_state, tr := σ.trace,
    aid := σ.core_run_state0.aid_supply,
    exc := σ.core_run_state0.excluded_supply,
    symc := σ.core_run_state0.sym_supply,
    ctr := σ.dr_step_counter }

/-- The components at the (single) stored head. -/
noncomputable def atX2 (bm : Std.TreeMap Int CerbMem.AbsByte)
    (am : Std.TreeMap Int CerbMem.Allocation) (seed : Nat) :
    Nat → Seg.LoopComps
  | _ => compOf (h1 bm am seed)

/-- THE MAP ENTRY: `while_529 ↦` the declared invariant. -/
noncomputable def x2Inv (bm : Std.TreeMap Int CerbMem.AbsByte)
    (am : Std.TreeMap Int CerbMem.Allocation) (seed : Nat) :
    Seg.SegInv :=
  { Comp := Seg.LoopComps, label := symWhile, spell := spellX2,
    at_ := atX2 bm am seed }

/-- The fixture's invariant map. -/
noncomputable def invMapX2 (bm : Std.TreeMap Int CerbMem.AbsByte)
    (am : Std.TreeMap Int CerbMem.Allocation) (seed : Nat) :
    Seg.InvMap :=
  [x2Inv bm am seed]

/-- The driver round computation. -/
abbrev C := Seg.dnmsC x2File.tagDefs 0

/-- The done offer the exit segment reaches. -/
noncomputable abbrev x2Offer (bm : Std.TreeMap Int CerbMem.AbsByte)
    (am : Std.TreeMap Int CerbMem.Allocation) (seed : Nat) :
    nd_action (Fmap thread_id (List core_step2)) step_kind
      driver_error (mem_constraint CerbMem.IntegerValue) driver_state
      × driver_state :=
  (NDactive (fmapAddBy defaultCompare 0 [Step_done2 v27] fmapEmpty),
   hFin bm am seed)

section StAlign
variable (bm : Std.TreeMap Int CerbMem.AbsByte)
  (am : Std.TreeMap Int CerbMem.Allocation) (seed : Nat)

theorem St0_eq : (x2Inv bm am seed).St 0 = h1 bm am seed :=
  (e71_align bm am [] 0 0 seed 0).symm

end StAlign

/-- ENTRY + (zero iterations) + EXIT: the run reaches the done offer
    in ≤ 71 + 55 rounds. -/
theorem x2_run_seg (bm : Std.TreeMap Int CerbMem.AbsByte)
    (am : Std.TreeMap Int CerbMem.Allocation) (seed : Nat)
    (hdig : CerberusFresh.digest () = "")
    (hsB : seed + 16 < 1152921504606846976)
    (halN : am.get? 0 = some allocN)
    (hb : ∀ i : Nat, (hi : i < argBytes.length) →
      bm.get? (nAddr + (i : Int)) = some argBytes[i]) :
    Seg.SegDone C (71 + (1 * 0 + 55))
      (mkRdy bm am [] 0 0 seed 0) (x2Offer bm am seed) := by
  have hentry : Seg.Seg C 71 (mkRdy bm am [] 0 0 seed 0)
      ((x2Inv bm am seed).St 0) := by
    rw [St0_eq]
    exact Seg.Seg.of_chain (seg_entry bm am seed hdig hsB halN hb)
  have hbody : (x2Inv bm am seed).BodyOb C 1 0 := by
    intro k hk
    exact absurd hk (by omega)
  have hexit : (x2Inv bm am seed).ExitOb C 55 0
      (x2Offer bm am seed) := by
    show Seg.SegDone C 55 ((x2Inv bm am seed).St 0) _
    rw [St0_eq]
    exact Seg.SegDone.of_chain (C := C) (k := 55)
      (s := h1 bm am seed) (r := x2Offer bm am seed)
      (seg_exit bm am seed hdig hsB halN hb)
  exact hentry.trans_done
    (Seg.InvMap.while_inv (invMapX2 bm am seed) (l := symWhile) rfl
      hbody hexit)

/-! ## The driver atom (write1: ONE store to n's range) -/

/-- The run's write ladder over n's range. -/
def ws : List (List CerbMem.AbsByte) :=
  [i32 27]

/-- The final state at ZEROED maps, post `prepare_exit`. -/
noncomputable abbrev hFin0 (seed : Nat) : driver_state :=
  { hFin Std.TreeMap.empty Std.TreeMap.empty seed with
    core_state0 := prepare_exit
      (hFin Std.TreeMap.empty Std.TreeMap.empty seed).core_state0 v27 }

/-- The final rest. -/
noncomputable abbrev rDone (seed : Nat) : driver_state :=
  restOf (hFin0 seed)

/-- THE DRIVER LOOP at open maps. -/
@[seg_eq write1]
theorem driver2_o (seed : Nat) (henv : X2EnvHypThr)
    (hap : X2SeedApart seed) : ∀ bm am,
    am.get? 0 = some allocN →
    (∀ i : Nat, (hi : i < argBytes.length) →
      bm.get? (nAddr + (i : Int)) = some argBytes[i]) →
    app (driver2 x2File.tagDefs false) (setMaps (rRdy seed) bm am)
      = (NDactive (), setMaps (rDone seed)
          (writeSeq bm nAddr ws) am) := by
  intro bm am halN hb
  rw [mkRdy_align seed bm am]
  exact Seg.driver2_of_seg rfl
    ((x2_run_seg bm am seed henv hap halN hb).mono (by decide)) rfl

/-- x2's FnSpec ([F9]): the guarded ∀-seed face. -/
abbrev capSpec : Seg.FnSpec Unit :=
  { fname := "cap10", args := fun _ => [intValue 273],
    guard := fun seed => X2EnvHypThr ∧ X2SeedApart seed,
    post := fun _ => x2Spec }

/-! ## THE THREADED STATEMENTS (fuel-opsem faces, guarded ∀-seed) -/

/-- THE x2 HEADLINE (fuel opsem only). -/
def X2ThreadedStatement : Prop :=
  X2EnvHypThr →
  ∀ (seed : Nat), X2SeedApart seed →
    CallHarnessAdequateThr seed x2File.tagDefs x2File "cap10"
      [intValue 273] x2Fs x2Spec

/-- **x2 THREADED** (trio cone; through the segment layer). -/
theorem X2Threaded : X2ThreadedStatement := by
  verify_fn capSpec
  seg_auto

/-- **x2 THREADED UB-freedom** (the safety twin — same route). -/
theorem X2Threaded_ubFree :
    X2EnvHypThr →
    ∀ (seed : Nat), X2SeedApart seed →
      CallHarnessUBFreeThr seed x2File.tagDefs x2File "cap10"
        [intValue 273] x2Fs := by
  verify_fn capSpec
  seg_auto

end RelSem.X2
