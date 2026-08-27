/-
  RelSem.Corpus.C3B — arc-18 R6 batch 2 (2026-08-27): CENSUS-tier c3b.

  tests/verify/c3b_leaddigit.c — `int lead_digit(int n)`: the scalar
  reduce loop (census row L5's loop half; the guards are c3a). A
  while loop REWRITING THE ARGUMENT OBJECT per iteration — the T7
  write1 shape at a new program: lead_digit(273) runs 273 → 27 → 2,
  two iterations, uniform per-iteration round count (48).

  THE LOOP ROUTE (the house pattern, T7 verbatim): ONE invariant
  declared at the Core label through the SegInv map (value
  trajectory 27, 2 at the stored heads), body/exit obligations
  DERIVED by `InvMap.while_inv`, walks minted at OPEN memory +
  OPEN supplies under the digest pin + seed apartness (the loop's
  save/run draws fresh symbols). Segments: entry 49 (prologue +
  iteration 1 + the loop jump), body 48 (one iteration shape),
  exit 33 + terminal.

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

namespace RelSem.C3B

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

/-- `lead_digit`'s Core body (fixture-derived — never transcribed). -/
def leadBody : generic_expr core_run_annotation Unit sym :=
  match fmapLookupBy (fun (s1 s2 : sym) => ordCompare s1 s2) leaddigitC3BSym
      c3bFile.funs with
  | some (Proc _ _ _ _ e) => e
  | _ => Expr [] (Epure (Pexpr [] () (PEval Vunit)))

/-- The while_529 labeled-continuation body (fixture-derived). -/
def whileBody : generic_expr core_run_annotation Unit sym :=
  match Lem_Maybe.bind0
      (fmapLookupBy (fun (s1 s2 : sym) => ordCompare s1 s2) leaddigitC3BSym
        (initial_core_run_state_threaded 0
          (collect_labeled_continuations_NEW c3bFile)).labeled)
      (fmapLookupBy (fun (s1 s2 : sym) => ordCompare s1 s2) symWhile) with
  | some pb => pb.2
  | none => Expr [] (Epure (Pexpr [] () (PEval Vunit)))

/-- The ready thread (arena = lead_digit's body; n bound). -/
def thRdy : thread_state :=
  { arena := leadBody,
    stack0 := Stack_empty,
    errno := errPtr,
    current_loc := CerbLocation.other "RelSem.callND",
    exec_loc := ELoc_normal [(leaddigitC3BSym, CerbLocation.other "RelSem.callND")],
    env := [fmapAddBy (fun (s1 s2 : sym) => ordCompare s1 s2) symN
      (Vobject (OVpointer nPtr)) fmapEmpty],
    current_proc_opt := some leaddigitC3BSym }

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
  { core_file := c3bFile,
    core_extern := create_extern_symmap c3bFile,
    core_state0 :=
      { thread_states := [(0, (none, thRdy))],
        io := initial_io_state },
    core_run_state0 :=
      { tid_supply := 1, aid_supply := aid, excluded_supply := exc,
        sym_supply := symc,
        labeled := (initial_core_run_state_threaded 0
          (collect_labeled_continuations_NEW c3bFile)).labeled },
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
  { core_file := c3bFile,
    core_extern := create_extern_symmap c3bFile,
    core_state0 :=
      { thread_states := [(0, (none,
          { arena := whileBody,
            stack0 := Stack_empty,
            errno := errPtr,
            current_loc := CerbLocation.Loc.unknown,
            exec_loc := ELoc_normal
              [(leaddigitC3BSym, CerbLocation.other "RelSem.callND")],
            env := [env],
            current_proc_opt := some leaddigitC3BSym }))],
        io := initial_io_state },
    core_run_state0 :=
      { tid_supply := 1, aid_supply := aid, excluded_supply := exc,
        sym_supply := symc,
        labeled := (initial_core_run_state_threaded 0
          (collect_labeled_continuations_NEW c3bFile)).labeled },
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
  using (c3bFile.tagDefs) 0 from (mkRdy bm am tr aid exc symc ctr) upto 49 chain builder

/-! ## THE BODY WALK (stored spelling; the ONE iteration shape at
    n = 27: 27 → 2, 48 rounds). -/

set_option Elab.async false in
derive_rounds b (env : Fmap sym value) (mem : CerbMem.MemState)
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
  using (c3bFile.tagDefs) 0 from (mkLH env mem tr aid exc symc ctr) upto 48 chain builder

/-! ## THE EXIT WALK (guard false at n = 2: the return load, the run
    to the thread's terminal — 34 rounds + terminal chain). -/

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
  (hrdN : CerbMem.readBytesFrom mem nAddr 4 = i32 2)
  assuming hdig hbuilt hlkN hdd0 halN hfpm hlum hscB hexcB hrdN
  fencing fmapAddBy fmapLookupBy CerbMem.writeBytesTo mkByte mk_conv_int mk_call_catch_exceptional_condition mk_wrapI
  using (c3bFile.tagDefs) 0 from (mkLH env mem tr aid exc symc ctr) upto 40 chain builder

/-! ## The harness spine (the E1 recipe at the c3b data) -/

/-- c3b's filesystem state (initial, as every slate fixture). -/
def c3bFs : CerbFS.FsState := CerbFS.fs_initial_state

/-- Memory after the argument allocation. -/
def memArgAlloc : CerbMem.MemState :=
  CerbMem.writeBytesTo
    { CerbMem.initialMemState with
      nextAllocId := 1, lastAddress := nAddr,
      allocations := Std.TreeMap.empty.insert 0 allocN }
    nAddr (List.replicate 4 uninitByte)

/-- Memory after the argument injection (n = 273). -/
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

/-- Stage 1: driver_globals (c3b has none). -/
derive_state_step dG (seed : Nat)
  from (driver_globals c3bFile.tagDefs false c3bFile)
  at (initial_driver_state_threaded seed c3bFile c3bFs)

/-- Post-injection driver state (n = 273). -/
derive_state dInj (seed : Nat) : driver_state :=
  { dG seed with layout_state := memInj }

/-- Post-errno driver state. -/
derive_state dErr (seed : Nat) : driver_state :=
  { dG seed with layout_state := memD3 }

/-- The ready state. -/
derive_state dRdy (seed : Nat) : driver_state :=
  { dErr seed with
    core_state0 := update_thread_state 0 thRdy (dErr seed).core_state0 }

/-! ### The rest ladder -/

abbrev rInit (seed : Nat) : driver_state :=
  restOf (initial_driver_state_threaded seed c3bFile c3bFs)
abbrev rGlob (seed : Nat) : driver_state := restOf (dG seed)
abbrev rArg (seed : Nat) : driver_state :=
  restAllocR (rGlob seed) nAddr
abbrev rErr (seed : Nat) : driver_state :=
  restAllocR (rArg seed) errAddr
abbrev rRdy (seed : Nat) : driver_state := restOf (dRdy seed)

/-- The argument object's byte image (n = 273). -/
def argBytes : List CerbMem.AbsByte := i32 273

/-! ### The open-memory stage equations -/

@[seg_eq rest]
theorem k1_o (seed : Nat) : ∀ bm am,
    app (driver_globals c3bFile.tagDefs false c3bFile)
        (setMaps (rInit seed) bm am)
      = (NDactive 0, setMaps (rGlob seed) bm am) := fun _ _ => rfl

/-- The post-globals canonical representative (`nd_get` joint). -/
@[seg_canon]
theorem c3b_canon (seed : Nat) : Seg.CanonAt (rGlob seed) (dG seed) :=
  rfl

@[seg_eq rest]
theorem k3_o (seed : Nat) : ∀ bm am,
    app (resolveFunSym (dG seed).core_file "lead_digit")
        (setMaps (rGlob seed) bm am)
      = (NDactive leaddigitC3BSym, setMaps (rGlob seed) bm am) :=
  fun _ _ => rfl

@[seg_eq rest]
theorem k4_o (seed : Nat) : ∀ bm am,
    app (lookupFunBody (dG seed).core_file leaddigitC3BSym)
        (setMaps (rGlob seed) bm am)
      = (NDactive ([(symN, BTy_object OTy_pointer)], leadBody),
         setMaps (rGlob seed) bm am) := fun _ _ => rfl

@[seg_eq rest]
theorem k5_o (seed : Nat) : ∀ bm am,
    app (lookupParamTys (dG seed).core_file leaddigitC3BSym)
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
theorem memValueFromValue_c3b_eq :
    memValueFromValue c3bFile.tagDefs signed_int (intValue 273)
      = some (CerbMem.integerValueMval (Signed Int_)
          (CerbMem.integerIval 273)) := rfl

/-- Stage 6, THE ARGUMENT INJECTION at open maps. -/
@[seg_eq argobj]
theorem k6_o (seed : Nat) : ∀ bm am,
    app (injectArgs c3bFile.tagDefs 0
          [(symN, BTy_object OTy_pointer)] [signed_int] [intValue 273])
        (setMaps (rGlob seed) bm am)
      = (NDactive [(symN, Vobject (OVpointer nPtr))],
         allocStoreState (restAllocR (rGlob seed) nAddr) bm am nAddr 4
           argBytes 0 allocN) := by
  intro bm am
  refine Laws.inject_ptr_arg1 (σ := setMaps (rGlob seed) bm am)
    (hmv := memValueFromValue_c3b_eq)
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

/-! ## Obligation feeds (walk endpoints pinned tidy; the T7W shape) -/

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
theorem e49_mem :
    (e49 bm am tr aid exc symc ctr).layout_state
      = CerbMem.writeBytesTo (memRdy bm am) nAddr (i32 27) := rfl

theorem b48_mem :
    (b48 env mem tr aid exc symc ctr).layout_state
      = CerbMem.writeBytesTo
          { mem with funptrmap := [], lastUsedUnionMembers := [] }
          nAddr (i32 2) := rfl

theorem bx33_mem :
    (bx33 env mem tr aid exc symc ctr).layout_state = mem := rfl

/-- Supply projections (rfl pins; the seed-bound transport). -/
theorem e49_symc :
    (e49 bm am tr aid exc symc ctr).core_run_state0.sym_supply
      = symc + 1 := rfl
theorem b48_symc :
    (b48 env mem tr aid exc symc ctr).core_run_state0.sym_supply
      = symc + 1 := rfl
theorem e49_exc :
    (e49 bm am tr aid exc symc ctr).core_run_state0.excluded_supply
      = exc + 1 := rfl
theorem b48_exc :
    (b48 env mem tr aid exc symc ctr).core_run_state0.excluded_supply
      = exc + 1 := rfl

end Feeds

/-! ### The stored-spelling alignments -/

section Aligns
variable (bm : Std.TreeMap Int CerbMem.AbsByte)
  (am : Std.TreeMap Int CerbMem.Allocation)
  (env : Fmap sym value) (mem : CerbMem.MemState)
  (tr : List trace_event) (aid exc symc ctr : Nat)

theorem e49_align :
    e49 bm am tr aid exc symc ctr
      = mkLH (envOf (e49 bm am tr aid exc symc ctr))
          (e49 bm am tr aid exc symc ctr).layout_state
          (e49 bm am tr aid exc symc ctr).trace
          (e49 bm am tr aid exc symc ctr).core_run_state0.aid_supply
          (e49 bm am tr aid exc symc ctr).core_run_state0.excluded_supply
          (e49 bm am tr aid exc symc ctr).core_run_state0.sym_supply
          (e49 bm am tr aid exc symc ctr).dr_step_counter := rfl

theorem b48_align :
    b48 env mem tr aid exc symc ctr
      = mkLH (envOf (b48 env mem tr aid exc symc ctr))
          (b48 env mem tr aid exc symc ctr).layout_state
          (b48 env mem tr aid exc symc ctr).trace
          (b48 env mem tr aid exc symc ctr).core_run_state0.aid_supply
          (b48 env mem tr aid exc symc ctr).core_run_state0.excluded_supply
          (b48 env mem tr aid exc symc ctr).core_run_state0.sym_supply
          (b48 env mem tr aid exc symc ctr).dr_step_counter := rfl

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

/-- The loop heads at the canonical harness supplies. -/
noncomputable abbrev h1 : driver_state := e49 bm am [] 0 0 seed 0
noncomputable abbrev h2 : driver_state := atComps b48 (h1 bm am seed)
noncomputable abbrev hFin : driver_state := atComps bx33 (h2 bm am seed)

/-- The run's terminal value (Specified 2). -/
def v2 : value :=
  Vloaded (LVspecified (OVinteger
    (CerbMem.IntegerValue.IV .Prov_none 2)))

/-- SITE 0 — the entry segment's chain (mkRdy → h1). -/
theorem seg_entry (hdig : CerberusFresh.digest () = "")
    (hsB : seed + 16 < 1152921504606846976)
    (halN : am.get? 0 = some allocN)
    (hb : ∀ i : Nat, (hi : i < argBytes.length) →
      bm.get? (nAddr + (i : Int)) = some argBytes[i]) :
    ∀ fuel, app (drive_nonmemory_steps_aux2_lemFuel (fuel + 49)
        c3bFile.tagDefs fmapEmpty [0]) (mkRdy bm am [] 0 0 seed 0)
      = app (drive_nonmemory_steps_aux2_lemFuel fuel
          c3bFile.tagDefs fmapEmpty [0]) (h1 bm am seed) :=
  e_chainrel bm am [] 0 0 seed 0 hdig (by omega) (by omega) halN
    (readBytesFrom_of_pointwise rfl (fun i hi => hb i hi))
    Kit.fmapAddBy_built_empty

/-- SITE 1 — the body segment's chain (h1 → h2). -/
theorem seg_body0 (hdig : CerberusFresh.digest () = "")
    (hsB : seed + 16 < 1152921504606846976)
    (halN : am.get? 0 = some allocN)
    (hb : ∀ i : Nat, (hi : i < argBytes.length) →
      bm.get? (nAddr + (i : Int)) = some argBytes[i]) :
    ∀ fuel, app (drive_nonmemory_steps_aux2_lemFuel (fuel + 48)
        c3bFile.tagDefs fmapEmpty [0]) (h1 bm am seed)
      = app (drive_nonmemory_steps_aux2_lemFuel fuel
          c3bFile.tagDefs fmapEmpty [0]) (h2 bm am seed) := by
  have hsymc : (h1 bm am seed).core_run_state0.sym_supply
      = seed + 1 := e49_symc bm am [] 0 0 seed 0
  refine b_chainrel (envOf (h1 bm am seed))
    (h1 bm am seed).layout_state (h1 bm am seed).trace
    (h1 bm am seed).core_run_state0.aid_supply
    (h1 bm am seed).core_run_state0.excluded_supply
    (h1 bm am seed).core_run_state0.sym_supply
    (h1 bm am seed).dr_step_counter
    hdig ?hbuilt ?hlkN ?hdd0 ?halN ?hfpm ?hlum ?hscB ?hexcB ?hrdN
  case hbuilt => rfl
  case hlkN => seg_env_lookup
  case hdd0 => rfl
  case halN => exact halN
  case hfpm => rfl
  case hlum => rfl
  case hscB => show seed + 1 < 1152921504606846976; omega
  case hexcB => show (1 : Nat) < 1152921504606846976; omega
  case hrdN => exact Kit.readBytesFrom_writeBytesTo_hit rfl

/-- SITE 2 — the exit segment's terminal chain (h2 → the done
    offer). -/
theorem seg_exit (hdig : CerberusFresh.digest () = "")
    (hsB : seed + 16 < 1152921504606846976)
    (halN : am.get? 0 = some allocN)
    (hb : ∀ i : Nat, (hi : i < argBytes.length) →
      bm.get? (nAddr + (i : Int)) = some argBytes[i]) :
    ∀ fuel, app (drive_nonmemory_steps_aux2_lemFuel (fuel + 35)
        c3bFile.tagDefs fmapEmpty [0]) (h2 bm am seed)
      = (NDactive (fmapAddBy defaultCompare 0
          [Step_done2 (Vloaded (LVspecified (OVinteger
            (CerbMem.IntegerValue.IV CerbMem.Provenance.Prov_none
              (Int.ofNat 2)))))] fmapEmpty),
         hFin bm am seed) := by
  have hsymc : (h1 bm am seed).core_run_state0.sym_supply
      = seed + 1 := e49_symc bm am [] 0 0 seed 0
  have hsymc2 : (h2 bm am seed).core_run_state0.sym_supply
      = seed + 2 := (b48_symc (envOf (h1 bm am seed))
      (h1 bm am seed).layout_state (h1 bm am seed).trace
      (h1 bm am seed).core_run_state0.aid_supply
      (h1 bm am seed).core_run_state0.excluded_supply
      (h1 bm am seed).core_run_state0.sym_supply
      (h1 bm am seed).dr_step_counter).trans (by rw [hsymc])
  have halign : h2 bm am seed
      = mkLH (envOf (h2 bm am seed))
          (h2 bm am seed).layout_state
          (h2 bm am seed).trace
          (h2 bm am seed).core_run_state0.aid_supply
          (h2 bm am seed).core_run_state0.excluded_supply
          (h2 bm am seed).core_run_state0.sym_supply
          (h2 bm am seed).dr_step_counter :=
    b48_align (envOf (h1 bm am seed))
      (h1 bm am seed).layout_state (h1 bm am seed).trace
      (h1 bm am seed).core_run_state0.aid_supply
      (h1 bm am seed).core_run_state0.excluded_supply
      (h1 bm am seed).core_run_state0.sym_supply
      (h1 bm am seed).dr_step_counter
  rw [halign]
  refine bx_chainrel _ _ _ _ _ _ _
    hdig ?xbuilt ?xlkN ?xdd0 ?xalN ?xfpm ?xlum ?xscB ?xexcB ?xrdN
  case xbuilt => rfl
  case xlkN => seg_env_lookup
  case xdd0 => rfl
  case xalN => exact halN
  case xfpm => rfl
  case xlum => rfl
  case xscB => show seed + 2 < 1152921504606846976; omega
  case xexcB => show (2 : Nat) < 1152921504606846976; omega
  case xrdN => exact Kit.readBytesFrom_writeBytesTo_hit rfl

end Sites

/-! ## Statement data + THE INVARIANT (the one human artifact) -/

/-- c3b's pure spec on driver results: lead_digit(273) = 2,
    Specified. -/
def c3bSpec (r : driver_result) : Prop :=
  r.dres_core_value = intValue 2

/-- The environment hypothesis (digest pin; T4EnvHypThr lineage). -/
def C3BEnvHypThr : Prop := CerberusFresh.digest () = ""

/-- Seed apartness: the run's < 16 fresh draws stay below every
    static symbol hash (T7SeedApart lineage). -/
def C3BSeedApart (seed : Nat) : Prop :=
  seed + 16 < 1152921504606846976

/-- The label's spelling table ([F3]): c3b's join points all sit at
    the STORED spelling (measured — the alignments above are rfl). -/
def spellC3B : Seg.JoinSpellings Seg.LoopComps where
  entry c := mkLH c.env c.mem c.tr c.aid c.exc c.symc c.ctr
  stored c := mkLH c.env c.mem c.tr c.aid c.exc c.symc c.ctr

/-- Component projection. -/
def compOf (σ : driver_state) : Seg.LoopComps :=
  { env := envOf σ, mem := σ.layout_state, tr := σ.trace,
    aid := σ.core_run_state0.aid_supply,
    exc := σ.core_run_state0.excluded_supply,
    symc := σ.core_run_state0.sym_supply,
    ctr := σ.dr_step_counter }

/-- The components at the k-th stored head (n = 27, 2). -/
noncomputable def atC3B (bm : Std.TreeMap Int CerbMem.AbsByte)
    (am : Std.TreeMap Int CerbMem.Allocation) (seed : Nat) :
    Nat → Seg.LoopComps
  | 0 => compOf (h1 bm am seed)
  | _ + 1 => compOf (h2 bm am seed)

/-- THE MAP ENTRY: `while_529 ↦` the declared invariant. -/
noncomputable def leadInv (bm : Std.TreeMap Int CerbMem.AbsByte)
    (am : Std.TreeMap Int CerbMem.Allocation) (seed : Nat) :
    Seg.SegInv :=
  { Comp := Seg.LoopComps, label := symWhile, spell := spellC3B,
    at_ := atC3B bm am seed }

/-- The fixture's invariant map (RefinedC `gmap label` shape). -/
noncomputable def invMapC3B (bm : Std.TreeMap Int CerbMem.AbsByte)
    (am : Std.TreeMap Int CerbMem.Allocation) (seed : Nat) :
    Seg.InvMap :=
  [leadInv bm am seed]

/-- The driver round computation (the segment calculus's `C`). -/
abbrev C := Seg.dnmsC c3bFile.tagDefs 0

/-- The done offer the exit segment reaches. -/
noncomputable abbrev c3bOffer (bm : Std.TreeMap Int CerbMem.AbsByte)
    (am : Std.TreeMap Int CerbMem.Allocation) (seed : Nat) :
    nd_action (Fmap thread_id (List core_step2)) step_kind
      driver_error (mem_constraint CerbMem.IntegerValue) driver_state
      × driver_state :=
  (NDactive (fmapAddBy defaultCompare 0 [Step_done2 v2] fmapEmpty),
   hFin bm am seed)

/-! The family's members ARE the walk endpoints. -/

section StAlign
variable (bm : Std.TreeMap Int CerbMem.AbsByte)
  (am : Std.TreeMap Int CerbMem.Allocation) (seed : Nat)

theorem St0_eq : (leadInv bm am seed).St 0 = h1 bm am seed :=
  (e49_align bm am [] 0 0 seed 0).symm

theorem St1_eq : (leadInv bm am seed).St 1 = h2 bm am seed :=
  (b48_align (envOf (h1 bm am seed))
    (h1 bm am seed).layout_state (h1 bm am seed).trace
    (h1 bm am seed).core_run_state0.aid_supply
    (h1 bm am seed).core_run_state0.excluded_supply
    (h1 bm am seed).core_run_state0.sym_supply
    (h1 bm am seed).dr_step_counter).symm

end StAlign

/-- ENTRY + LOOP + EXIT: the run reaches the done offer in ≤ 132
    rounds — entry 49, `Seg.iter` at per-iteration budget 48, exit
    35 (33 rounds + terminal). -/
theorem c3b_run_seg (bm : Std.TreeMap Int CerbMem.AbsByte)
    (am : Std.TreeMap Int CerbMem.Allocation) (seed : Nat)
    (hdig : CerberusFresh.digest () = "")
    (hsB : seed + 16 < 1152921504606846976)
    (halN : am.get? 0 = some allocN)
    (hb : ∀ i : Nat, (hi : i < argBytes.length) →
      bm.get? (nAddr + (i : Int)) = some argBytes[i]) :
    Seg.SegDone C (49 + (48 * 1 + 35))
      (mkRdy bm am [] 0 0 seed 0) (c3bOffer bm am seed) := by
  have hentry : Seg.Seg C 49 (mkRdy bm am [] 0 0 seed 0)
      ((leadInv bm am seed).St 0) := by
    rw [St0_eq]
    exact Seg.Seg.of_chain (seg_entry bm am seed hdig hsB halN hb)
  have hbody : (leadInv bm am seed).BodyOb C 48 1 := by
    intro k hk
    match k with
    | 0 =>
      show Seg.Seg C 48 ((leadInv bm am seed).St 0)
        ((leadInv bm am seed).St 1)
      rw [St0_eq, St1_eq]
      exact Seg.Seg.of_chain (C := C) (k := 48)
        (s := h1 bm am seed) (s' := h2 bm am seed)
        (seg_body0 bm am seed hdig hsB halN hb)
    | k + 1 => exact absurd hk (by omega)
  have hexit : (leadInv bm am seed).ExitOb C 35 1
      (c3bOffer bm am seed) := by
    show Seg.SegDone C 35 ((leadInv bm am seed).St 1) _
    rw [St1_eq]
    exact Seg.SegDone.of_chain (C := C) (k := 35)
      (s := h2 bm am seed) (r := c3bOffer bm am seed)
      (seg_exit bm am seed hdig hsB halN hb)
  exact hentry.trans_done
    (Seg.InvMap.while_inv (invMapC3B bm am seed) (l := symWhile) rfl
      hbody hexit)

/-! ## The driver atom (write1: the loop re-writes n's range once per
    iteration — 2 layers, last image i32 2) -/

/-- The run's write ladder over n's range (chronological). -/
def ws : List (List CerbMem.AbsByte) :=
  [i32 27, i32 2]

/-- The final state at ZEROED maps, post `prepare_exit`. -/
noncomputable abbrev hFin0 (seed : Nat) : driver_state :=
  { hFin Std.TreeMap.empty Std.TreeMap.empty seed with
    core_state0 := prepare_exit
      (hFin Std.TreeMap.empty Std.TreeMap.empty seed).core_state0 v2 }

/-- The final rest. -/
noncomputable abbrev rDone (seed : Nat) : driver_state :=
  restOf (hFin0 seed)

/-- THE DRIVER LOOP at open maps: rest + n's footprint in, the
    composed segment discharged by `driver2_of_seg`. -/
@[seg_eq write1]
theorem driver2_o (seed : Nat) (henv : C3BEnvHypThr)
    (hap : C3BSeedApart seed) : ∀ bm am,
    am.get? 0 = some allocN →
    (∀ i : Nat, (hi : i < argBytes.length) →
      bm.get? (nAddr + (i : Int)) = some argBytes[i]) →
    app (driver2 c3bFile.tagDefs false) (setMaps (rRdy seed) bm am)
      = (NDactive (), setMaps (rDone seed)
          (writeSeq bm nAddr ws) am) := by
  intro bm am halN hb
  rw [mkRdy_align seed bm am]
  exact Seg.driver2_of_seg rfl
    ((c3b_run_seg bm am seed henv hap halN hb).mono (by decide)) rfl

/-- c3b's FnSpec ([F9]): the guarded ∀-seed face. -/
abbrev leadSpec : Seg.FnSpec Unit :=
  { fname := "lead_digit", args := fun _ => [intValue 273],
    guard := fun seed => C3BEnvHypThr ∧ C3BSeedApart seed,
    post := fun _ => c3bSpec }

/-! ## THE THREADED STATEMENTS (fuel-opsem faces, guarded ∀-seed) -/

/-- THE c3b HEADLINE (fuel opsem only): under the digest pin + seed
    apartness, every outcome of `callND(lead_digit, [intValue 273])`
    from the threaded initial state is `Active r` with
    `r = intValue 2`. -/
def C3BThreadedStatement : Prop :=
  C3BEnvHypThr →
  ∀ (seed : Nat), C3BSeedApart seed →
    CallHarnessAdequateThr seed c3bFile.tagDefs c3bFile "lead_digit"
      [intValue 273] c3bFs c3bSpec

/-- **c3b THREADED** (trio cone): the census-tier loop THROUGH THE
    SEGMENT LAYER — one declared invariant, derived obligations, a
    two-line proof. -/
theorem C3BThreaded : C3BThreadedStatement := by
  verify_fn leadSpec
  seg_auto

/-- **c3b THREADED UB-freedom** (the safety twin — same route). -/
theorem C3BThreaded_ubFree :
    C3BEnvHypThr →
    ∀ (seed : Nat), C3BSeedApart seed →
      CallHarnessUBFreeThr seed c3bFile.tagDefs c3bFile "lead_digit"
        [intValue 273] c3bFs := by
  verify_fn leadSpec
  seg_auto

end RelSem.C3B
