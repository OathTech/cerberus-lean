/-
  RelSem.T7Walks — arc-18 R2 (2026-08-26): THE T7 EQUATION SUPPLY.

  NAMING (arc-18 R2, the walk→segment map in
  docs/2026-08-26_arc18-r2-donor-correspondence.md): "walk" is
  ENGINE-ROOM vocabulary — the drive/mint layer's term for a chain of
  evaluator rounds. The user-facing surface calls these SEGMENTS
  (RelSem/Segment.lean consumes each chain as one `Seg`).

  tests/verify/t7_flip.c — THE BRANCH-IN-LOOP FIXTURE ([F1], the
  fixed-round breaker): `int flip(int n)` decrements `n` through a
  while loop whose body BRANCHES (even arm: one store; odd arm: two
  stores), so per-iteration round counts are DATA-DEPENDENT — the
  uniform-k `iter_compose` cannot state this loop; the ∃-round
  segment judgment (`Seg.iter`, RelSem/Segment.lean) composes it.

  The walks (each an evaluator mint at OPEN memory — heap maps /
  supplies free, per-iteration values CONCRETE at the theorem's
  instance flip(7): 7 →odd→ 4 →even→ 2 →even→ 0 →exit):

  * `e`  — entry: mkRdy through the prologue AND iteration 1 (odd
    arm, 7 → 6 → 4) to the first STORED loop head — 95 rounds,
    `e_chainrel`. This fixture's join points all sit at the stored
    spelling (measured: e95/bEven72/bOdd94 each align to the `mkLH`
    builder at their own components BY RFL), so the C3b fall-in twin
    never surfaces here — the [F3] twin normalization is demonstrated
    on the T5 twins, where the decomposition genuinely needs it.
  * `bEven` — an EVEN-arm iteration at n = 4 (4 → 3): 72 rounds.
  * `bOdd`  — an ODD-arm iteration at n = 3 (3 → 2 → 0): 94 rounds.
    NOTE 72 ≠ 94 INSIDE the composed loop family — the data-dependent
    round counts the uniform-k rule cannot state ([F1]).
  * `bx` — exit (guard false at n = 0): break, the return load, the
    run to the thread's terminal — 33 rounds + terminal chain.

  Fixture data below is DATA (symbols, addresses, byte images, the
  builder records); the program text is fixture-derived (the
  labeled-continuation lookup), never transcribed.

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
-- the segment layer: registration attributes + the env-peel
-- discharger the obligation feeds consume
import RelSem.SegmentFaces

set_option autoImplicit false

namespace RelSem.T7W

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

/-- The 4-byte little-endian image of a 32-bit int value. -/
def mkByte (x : Int) (i : Nat) : CerbMem.AbsByte :=
  { prov := .Prov_none, copyOffset := none,
    value := some ((((if x < 0 then (1 <<< 32) + x else x) >>> (i * 8)).toNat % 256).toUInt8) }

/-- The int byte image as a list. -/
def i32 (v : Int) : List CerbMem.AbsByte :=
  [mkByte v 0, mkByte v 1, mkByte v 2, mkByte v 3]

def uninitByte : CerbMem.AbsByte :=
  { prov := .Prov_none, copyOffset := none, value := none }

/-! ## The builders -/

/-- `flip`'s Core body (fixture-derived — never transcribed). -/
def flipBody : generic_expr core_run_annotation Unit sym :=
  match fmapLookupBy (fun (s1 s2 : sym) => ordCompare s1 s2) flipT7Sym
      t7File.funs with
  | some (Proc _ _ _ _ e) => e
  | _ => Expr [] (Epure (Pexpr [] () (PEval Vunit)))

/-- The while_529 labeled-continuation body (fixture-derived). -/
def whileBody : generic_expr core_run_annotation Unit sym :=
  match Lem_Maybe.bind0
      (fmapLookupBy (fun (s1 s2 : sym) => ordCompare s1 s2) flipT7Sym
        (initial_core_run_state_threaded 0
          (collect_labeled_continuations_NEW t7File)).labeled)
      (fmapLookupBy (fun (s1 s2 : sym) => ordCompare s1 s2) symWhile) with
  | some pb => pb.2
  | none => Expr [] (Epure (Pexpr [] () (PEval Vunit)))

/-- The ready thread (arena = flip's body; n bound). -/
def thRdy : thread_state :=
  { arena := flipBody,
    stack0 := Stack_empty,
    errno := errPtr,
    current_loc := CerbLocation.other "RelSem.callND",
    exec_loc := ELoc_normal [(flipT7Sym, CerbLocation.other "RelSem.callND")],
    env := [fmapAddBy (fun (s1 s2 : sym) => ordCompare s1 s2) symN
      (Vobject (OVpointer nPtr)) fmapEmpty],
    current_proc_opt := some flipT7Sym }

/-- The ready memory at open maps (post-injection, post-errno; literal
    scalar fields — the T5W `mkRdy` builder discipline). -/
def memRdy (bm : Std.TreeMap Int CerbMem.AbsByte)
    (am : Std.TreeMap Int CerbMem.Allocation) : CerbMem.MemState :=
  { CerbMem.initialMemState with
    nextAllocId := 2, lastAddress := errAddr,
    bytemap := bm, allocations := am }

/-- THE READY BUILDER (the entry walk's from-state). -/
def mkRdy (bm : Std.TreeMap Int CerbMem.AbsByte)
    (am : Std.TreeMap Int CerbMem.Allocation)
    (tr : List trace_event) (aid exc symc ctr : Nat) : driver_state :=
  { core_file := t7File,
    core_extern := create_extern_symmap t7File,
    core_state0 :=
      { thread_states := [(0, (none, thRdy))],
        io := initial_io_state },
    core_run_state0 :=
      { tid_supply := 1, aid_supply := aid, excluded_supply := exc,
        sym_supply := symc,
        labeled := (initial_core_run_state_threaded 0
          (collect_labeled_continuations_NEW t7File)).labeled },
    layout_state := memRdy bm am,
    concurrency_state := symInitialState symInitialPre,
    fs_state0 := CerbFS.fs_initial_state,
    trace := tr,
    symbolic_assoc := fmapEmpty,
    blocked := false,
    dr_step_counter := ctr }

/-- THE LOOP-HEAD BUILDER, stored spelling (iterations ≥ 2 and the
    exit start here). -/
def mkLH (env : Fmap sym value) (mem : CerbMem.MemState)
    (tr : List trace_event) (aid exc symc ctr : Nat) : driver_state :=
  { core_file := t7File,
    core_extern := create_extern_symmap t7File,
    core_state0 :=
      { thread_states := [(0, (none,
          { arena := whileBody,
            stack0 := Stack_empty,
            errno := errPtr,
            current_loc := CerbLocation.Loc.unknown,
            exec_loc := ELoc_normal
              [(flipT7Sym, CerbLocation.other "RelSem.callND")],
            env := [env],
            current_proc_opt := some flipT7Sym }))],
        io := initial_io_state },
    core_run_state0 :=
      { tid_supply := 1, aid_supply := aid, excluded_supply := exc,
        sym_supply := symc,
        labeled := (initial_core_run_state_threaded 0
          (collect_labeled_continuations_NEW t7File)).labeled },
    layout_state := mem,
    concurrency_state := symInitialState symInitialPre,
    fs_state0 := CerbFS.fs_initial_state,
    trace := tr,
    symbolic_assoc := fmapEmpty,
    blocked := false,
    dr_step_counter := ctr }

/-! ## THE ENTRY WALK `e` — mkRdy through the prologue AND iteration 1
    (the ODD arm at n = 7: stores 6 then 4) to the FIRST STORED loop
    head. Join points for this fixture sit at the STORED spelling
    only: the loop-closing `run while_529` jump lands there, so the
    entry SEGMENT is entry→head₁ and the C3b fall-in spelling never
    surfaces (the [F3] twin normalization is demonstrated on the T5
    twins, where the theorem's decomposition genuinely needs it). -/

set_option Elab.async false in
derive_rounds e (bm : Std.TreeMap Int CerbMem.AbsByte)
  (am : Std.TreeMap Int CerbMem.Allocation)
  (tr : List trace_event) (aid exc symc ctr : Nat)
  (hdig : CerberusFresh.digest () = "")
  (hscB : symc < 1152921504606846976)
  (hexcB : exc < 1152921504606846976)
  (halN : am.get? 0 = some allocN)
  (hrdN : CerbMem.readBytesFrom (memRdy bm am) nAddr 4 = i32 7)
  (hbuilt : RelSem.Kit.FmapBuilt RelSem.Kit.symCmpO
    (fmapAddBy (fun (s1 s2 : sym) => ordCompare s1 s2) symN
      (Vobject (OVpointer nPtr)) fmapEmpty))
  assuming hdig hscB hexcB halN hrdN hbuilt
  fencing fmapAddBy fmapLookupBy CerbMem.writeBytesTo Std.TreeMap.insert Std.TreeMap.get? mkByte mk_conv_int mk_call_catch_exceptional_condition mk_wrapI
  using (t7File.tagDefs) 0 from (mkRdy bm am tr aid exc symc ctr) upto 95 chain builder


/-- Head thread of a driver state (total; probe helper). -/
def thOf (σ : driver_state) : thread_state :=
  match σ.core_state0.thread_states with
  | (_, (_, th)) :: _ => th
  | [] => thRdy



/-! ## THE BODY WALKS (stored spelling; per-iteration values CONCRETE
    at the flip(7) instance — the branch conditions are ground, the
    heap maps and supplies stay free). The EVEN and ODD arms have
    DIFFERENT round counts: the ∃-round composition's raison d'être. -/

set_option Elab.async false in
derive_rounds bEven (env : Fmap sym value) (mem : CerbMem.MemState)
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
  (hrdN : CerbMem.readBytesFrom mem nAddr 4 = i32 4)
  assuming hdig hbuilt hlkN hdd0 halN hfpm hlum hscB hexcB hrdN
  fencing fmapAddBy fmapLookupBy CerbMem.writeBytesTo mkByte mk_conv_int mk_call_catch_exceptional_condition mk_wrapI
  using (t7File.tagDefs) 0 from (mkLH env mem tr aid exc symc ctr) upto 72 chain builder

set_option Elab.async false in
derive_rounds bOdd (env : Fmap sym value) (mem : CerbMem.MemState)
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
  (hrdN : CerbMem.readBytesFrom mem nAddr 4 = i32 3)
  assuming hdig hbuilt hlkN hdd0 halN hfpm hlum hscB hexcB hrdN
  fencing fmapAddBy fmapLookupBy CerbMem.writeBytesTo mkByte mk_conv_int mk_call_catch_exceptional_condition mk_wrapI
  using (t7File.tagDefs) 0 from (mkLH env mem tr aid exc symc ctr) upto 94 chain builder

/-! ## THE EXIT WALK (guard false at n = 0: break, the return load,
    the run to the thread's terminal — terminal chain). -/

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
  (hrdN : CerbMem.readBytesFrom mem nAddr 4 = i32 0)
  assuming hdig hbuilt hlkN hdd0 halN hfpm hlum hscB hexcB hrdN
  fencing fmapAddBy fmapLookupBy CerbMem.writeBytesTo mkByte mk_conv_int mk_call_catch_exceptional_condition mk_wrapI
  using (t7File.tagDefs) 0 from (mkLH env mem tr aid exc symc ctr) upto 70 chain builder


/-! ## The harness spine (the T6Probe recipe at the t7 data; every
    stage equation registered as segment supply — seg_auto's feed) -/

/-- T7's filesystem state (initial, as every slate fixture). -/
def t7Fs : CerbFS.FsState := CerbFS.fs_initial_state

/-- Memory after the argument allocation (mem_alloc_block RHS form). -/
def memArgAlloc : CerbMem.MemState :=
  CerbMem.writeBytesTo
    { CerbMem.initialMemState with
      nextAllocId := 1, lastAddress := nAddr,
      allocations := Std.TreeMap.empty.insert 0 allocN }
    nAddr (List.replicate 4 uninitByte)

/-- Memory after the argument injection (n = 7). -/
def memInj : CerbMem.MemState :=
  CerbMem.writeBytesTo { memArgAlloc with funptrmap := [] } nAddr (i32 7)

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

/-- Stage 1: driver_globals (t7 has none). -/
derive_state_step dG (seed : Nat)
  from (driver_globals t7File.tagDefs false t7File)
  at (initial_driver_state_threaded seed t7File t7Fs)

/-- Post-injection driver state (n = 7). -/
derive_state dInj (seed : Nat) : driver_state :=
  { dG seed with layout_state := memInj }

/-- Post-errno driver state. -/
derive_state dErr (seed : Nat) : driver_state :=
  { dG seed with layout_state := memD3 }

/-- The ready state (thread set to `flip`'s body, all memory in
    place). -/
derive_state dRdy (seed : Nat) : driver_state :=
  { dErr seed with
    core_state0 := update_thread_state 0 thRdy (dErr seed).core_state0 }

/-! ### The rest ladder -/

abbrev rInit (seed : Nat) : driver_state :=
  restOf (initial_driver_state_threaded seed t7File t7Fs)
abbrev rGlob (seed : Nat) : driver_state := restOf (dG seed)
abbrev rArg (seed : Nat) : driver_state :=
  restAllocR (rGlob seed) nAddr
abbrev rErr (seed : Nat) : driver_state :=
  restAllocR (rArg seed) errAddr
abbrev rRdy (seed : Nat) : driver_state := restOf (dRdy seed)

/-- The argument object's byte image (n = 7). -/
def argBytes : List CerbMem.AbsByte := i32 7

/-! ### The open-memory stage equations (the T6Probe k-stage shapes) -/

@[seg_eq rest]
theorem k1_o (seed : Nat) : ∀ bm am,
    app (driver_globals t7File.tagDefs false t7File)
        (setMaps (rInit seed) bm am)
      = (NDactive 0, setMaps (rGlob seed) bm am) := fun _ _ => rfl

/-- The post-globals canonical representative (`nd_get` joint). -/
@[seg_canon]
theorem t7_canon (seed : Nat) : Seg.CanonAt (rGlob seed) (dG seed) :=
  rfl

@[seg_eq rest]
theorem k3_o (seed : Nat) : ∀ bm am,
    app (resolveFunSym (dG seed).core_file "flip")
        (setMaps (rGlob seed) bm am)
      = (NDactive flipT7Sym, setMaps (rGlob seed) bm am) :=
  fun _ _ => rfl

@[seg_eq rest]
theorem k4_o (seed : Nat) : ∀ bm am,
    app (lookupFunBody (dG seed).core_file flipT7Sym)
        (setMaps (rGlob seed) bm am)
      = (NDactive ([(symN, BTy_object OTy_pointer)], flipBody),
         setMaps (rGlob seed) bm am) := fun _ _ => rfl

@[seg_eq rest]
theorem k5_o (seed : Nat) : ∀ bm am,
    app (lookupParamTys (dG seed).core_file flipT7Sym)
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

/-- The memValue the caller protocol computes for the T7 argument. -/
theorem memValueFromValue_t7_eq :
    memValueFromValue t7File.tagDefs signed_int (intValue 7)
      = some (CerbMem.integerValueMval (Signed Int_)
          (CerbMem.integerIval 7)) := rfl

/-- Stage 6, THE ARGUMENT INJECTION at open maps. -/
@[seg_eq argobj]
theorem k6_o (seed : Nat) : ∀ bm am,
    app (injectArgs t7File.tagDefs 0
          [(symN, BTy_object OTy_pointer)] [signed_int] [intValue 7])
        (setMaps (rGlob seed) bm am)
      = (NDactive [(symN, Vobject (OVpointer nPtr))],
         allocStoreState (restAllocR (rGlob seed) nAddr) bm am nAddr 4
           argBytes 0 allocN) := by
  intro bm am
  refine Laws.inject_ptr_arg1 (σ := setMaps (rGlob seed) bm am)
    (hmv := memValueFromValue_t7_eq)
    (halloc := Kit.mem_alloc_block (sz := 4) (a := nAddr)
      (by exact rfl) (argAddr_fact seed) (by exact rfl))
    (hstore := Kit.mem_store_block (ty := signed_int)
      (mv := CerbMem.integerValueMval (Signed Int_)
        (CerbMem.integerIval 7))
      (allocId := 0) (addr := nAddr) (alloc := allocN)
      (fpm := []) (bytes := argBytes)
      (hcompat := by exact rfl)
      (hget := by
        rw [Kit.writeBytesTo_allocations]
        show (am.insert 0 allocN).get? 0 = some allocN
        simp [Std.TreeMap.get?_eq_getElem?, Std.TreeMap.getElem?_insert])
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
        simp [Std.TreeMap.get?_eq_getElem?, Std.TreeMap.getElem?_insert])
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

/-! ## Obligation feeds (the mechanical layer the composition in
    RelSem/T7.lean consumes — mem pins by rfl, reads by the
    registered read-over-write laws, env lookups by the layer's
    `seg_env_lookup` discharger, supply projections by rfl) -/

/-- The ready builder aligns with the harness rest at the canonical
    supplies (the T6 mkRdy6 alignment). -/
theorem mkRdy_align (seed : Nat)
    (bm : Std.TreeMap Int CerbMem.AbsByte)
    (am : Std.TreeMap Int CerbMem.Allocation) :
    setMaps (rRdy seed) bm am = mkRdy bm am [] 0 0 seed 0 := rfl

section Feeds
variable (bm : Std.TreeMap Int CerbMem.AbsByte)
  (am : Std.TreeMap Int CerbMem.Allocation)
  (env : Fmap sym value) (mem : CerbMem.MemState)
  (tr : List trace_event) (aid exc symc ctr : Nat)

/-- E's endpoint memory, pinned tidy (rfl — structure eta over the
    minted field-by-field ladder). -/
theorem e95_mem :
    (e95 bm am tr aid exc symc ctr).layout_state
      = CerbMem.writeBytesTo
          (CerbMem.writeBytesTo (memRdy bm am) nAddr (i32 6))
          nAddr (i32 4) := rfl

theorem bEven72_mem :
    (bEven72 env mem tr aid exc symc ctr).layout_state
      = CerbMem.writeBytesTo
          { mem with funptrmap := [], lastUsedUnionMembers := [] }
          nAddr (i32 3) := rfl

theorem bOdd94_mem :
    (bOdd94 env mem tr aid exc symc ctr).layout_state
      = CerbMem.writeBytesTo
          (CerbMem.writeBytesTo
            { mem with funptrmap := [], lastUsedUnionMembers := [] }
            nAddr (i32 2))
          nAddr (i32 0) := rfl

theorem bx33_mem :
    (bx33 env mem tr aid exc symc ctr).layout_state = mem := rfl

/-- Supply projections (rfl pins; the seed-bound transport). -/
theorem e95_symc :
    (e95 bm am tr aid exc symc ctr).core_run_state0.sym_supply
      = symc + 2 := rfl
theorem bEven72_symc :
    (bEven72 env mem tr aid exc symc ctr).core_run_state0.sym_supply
      = symc + 1 := rfl
theorem bOdd94_symc :
    (bOdd94 env mem tr aid exc symc ctr).core_run_state0.sym_supply
      = symc + 2 := rfl
theorem e95_exc :
    (e95 bm am tr aid exc symc ctr).core_run_state0.excluded_supply
      = exc + 2 := rfl
theorem bEven72_exc :
    (bEven72 env mem tr aid exc symc ctr).core_run_state0.excluded_supply
      = exc + 1 := rfl
theorem bOdd94_exc :
    (bOdd94 env mem tr aid exc symc ctr).core_run_state0.excluded_supply
      = exc + 2 := rfl

end Feeds

/-! ### The composed family's feed sites (the chain instantiations at
    the walks' own endpoints — the mechanical layer RelSem/T7.lean's
    composition consumes; env lookups via the layer's
    `seg_env_lookup`, reads via the registered read-over-write laws,
    supplies by the rfl pins + `omega`) -/

theorem i32_len (v : Int) : (i32 v).length = 4 := rfl

/-- envOf (total; the family's env projection). -/
def envOf (σ : driver_state) : Fmap sym value :=
  match (thOf σ).env with
  | e :: _ => e
  | [] => fmapEmpty

/-- A body/exit walk applied at a state's own components (the family
    step — projections, never transcriptions). -/
noncomputable def atComps
    (f : Fmap sym value → CerbMem.MemState → List trace_event →
      Nat → Nat → Nat → Nat → driver_state)
    (σ : driver_state) : driver_state :=
  f (envOf σ) σ.layout_state σ.trace
    σ.core_run_state0.aid_supply σ.core_run_state0.excluded_supply
    σ.core_run_state0.sym_supply σ.dr_step_counter

/-! ### The stored-spelling alignments (the b79_align' discipline:
    every walk endpoint is DEFINITIONALLY a loop-head builder state
    at its own components — the composition's instantiation feed;
    probe-verified rfl-grade at free binders) -/

section Aligns
variable (bm : Std.TreeMap Int CerbMem.AbsByte)
  (am : Std.TreeMap Int CerbMem.Allocation)
  (env : Fmap sym value) (mem : CerbMem.MemState)
  (tr : List trace_event) (aid exc symc ctr : Nat)

theorem e95_align :
    e95 bm am tr aid exc symc ctr
      = mkLH (envOf (e95 bm am tr aid exc symc ctr))
          (e95 bm am tr aid exc symc ctr).layout_state
          (e95 bm am tr aid exc symc ctr).trace
          (e95 bm am tr aid exc symc ctr).core_run_state0.aid_supply
          (e95 bm am tr aid exc symc ctr).core_run_state0.excluded_supply
          (e95 bm am tr aid exc symc ctr).core_run_state0.sym_supply
          (e95 bm am tr aid exc symc ctr).dr_step_counter := rfl

theorem bEven72_align :
    bEven72 env mem tr aid exc symc ctr
      = mkLH (envOf (bEven72 env mem tr aid exc symc ctr))
          (bEven72 env mem tr aid exc symc ctr).layout_state
          (bEven72 env mem tr aid exc symc ctr).trace
          (bEven72 env mem tr aid exc symc ctr).core_run_state0.aid_supply
          (bEven72 env mem tr aid exc symc ctr).core_run_state0.excluded_supply
          (bEven72 env mem tr aid exc symc ctr).core_run_state0.sym_supply
          (bEven72 env mem tr aid exc symc ctr).dr_step_counter := rfl

theorem bOdd94_align :
    bOdd94 env mem tr aid exc symc ctr
      = mkLH (envOf (bOdd94 env mem tr aid exc symc ctr))
          (bOdd94 env mem tr aid exc symc ctr).layout_state
          (bOdd94 env mem tr aid exc symc ctr).trace
          (bOdd94 env mem tr aid exc symc ctr).core_run_state0.aid_supply
          (bOdd94 env mem tr aid exc symc ctr).core_run_state0.excluded_supply
          (bOdd94 env mem tr aid exc symc ctr).core_run_state0.sym_supply
          (bOdd94 env mem tr aid exc symc ctr).dr_step_counter := rfl

end Aligns

section Sites
variable (bm : Std.TreeMap Int CerbMem.AbsByte)
  (am : Std.TreeMap Int CerbMem.Allocation) (seed : Nat)

/-- The loop heads at the canonical harness supplies: h1 = the entry
    walk's endpoint; h2/h3 by the family's own step. -/
noncomputable abbrev h1 : driver_state := e95 bm am [] 0 0 seed 0
noncomputable abbrev h2 : driver_state := atComps bEven72 (h1 bm am seed)
noncomputable abbrev h3 : driver_state := atComps bOdd94 (h2 bm am seed)
noncomputable abbrev hFin : driver_state := atComps bx33 (h3 bm am seed)

/-- SITE 0 — the entry segment's chain (mkRdy → h1). -/
theorem seg_entry (hdig : CerberusFresh.digest () = "")
    (hsB : seed + 16 < 1152921504606846976)
    (halN : am.get? 0 = some allocN)
    (hb : ∀ i : Nat, (hi : i < argBytes.length) →
      bm.get? (nAddr + (i : Int)) = some argBytes[i]) :
    ∀ fuel, app (drive_nonmemory_steps_aux2_lemFuel (fuel + 95)
        t7File.tagDefs fmapEmpty [0]) (mkRdy bm am [] 0 0 seed 0)
      = app (drive_nonmemory_steps_aux2_lemFuel fuel
          t7File.tagDefs fmapEmpty [0]) (h1 bm am seed) :=
  e_chainrel bm am [] 0 0 seed 0 hdig (by omega) (by omega) halN
    (readBytesFrom_of_pointwise rfl (fun i hi => hb i hi))
    Kit.fmapAddBy_built_empty


/-- SITE 1 — the even-arm segment's chain (h1 → h2). -/
theorem seg_body0 (hdig : CerberusFresh.digest () = "")
    (hsB : seed + 16 < 1152921504606846976)
    (halN : am.get? 0 = some allocN)
    (hb : ∀ i : Nat, (hi : i < argBytes.length) →
      bm.get? (nAddr + (i : Int)) = some argBytes[i]) :
    ∀ fuel, app (drive_nonmemory_steps_aux2_lemFuel (fuel + 72)
        t7File.tagDefs fmapEmpty [0]) (h1 bm am seed)
      = app (drive_nonmemory_steps_aux2_lemFuel fuel
          t7File.tagDefs fmapEmpty [0]) (h2 bm am seed) := by
  have hsymc : (h1 bm am seed).core_run_state0.sym_supply
      = seed + 2 := e95_symc bm am [] 0 0 seed 0
  refine bEven_chainrel (envOf (h1 bm am seed))
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
  case hscB => show seed + 2 < 1152921504606846976; omega
  case hexcB => show (2 : Nat) < 1152921504606846976; omega
  case hrdN => exact Kit.readBytesFrom_writeBytesTo_hit rfl

/-- SITE 2 — the odd-arm segment's chain (h2 → h3). -/
theorem seg_body1 (hdig : CerberusFresh.digest () = "")
    (hsB : seed + 16 < 1152921504606846976)
    (halN : am.get? 0 = some allocN)
    (hb : ∀ i : Nat, (hi : i < argBytes.length) →
      bm.get? (nAddr + (i : Int)) = some argBytes[i]) :
    ∀ fuel, app (drive_nonmemory_steps_aux2_lemFuel (fuel + 94)
        t7File.tagDefs fmapEmpty [0]) (h2 bm am seed)
      = app (drive_nonmemory_steps_aux2_lemFuel fuel
          t7File.tagDefs fmapEmpty [0]) (h3 bm am seed) := by
  have hsymc : (h1 bm am seed).core_run_state0.sym_supply
      = seed + 2 := e95_symc bm am [] 0 0 seed 0
  have hsymc2 : (h2 bm am seed).core_run_state0.sym_supply
      = seed + 3 := (bEven72_symc (envOf (h1 bm am seed))
      (h1 bm am seed).layout_state (h1 bm am seed).trace
      (h1 bm am seed).core_run_state0.aid_supply
      (h1 bm am seed).core_run_state0.excluded_supply
      (h1 bm am seed).core_run_state0.sym_supply
      (h1 bm am seed).dr_step_counter).trans (by rw [hsymc])
  exact bOdd_chainrel (envOf (h2 bm am seed))
    (h2 bm am seed).layout_state (h2 bm am seed).trace
    (h2 bm am seed).core_run_state0.aid_supply
    (h2 bm am seed).core_run_state0.excluded_supply
    (h2 bm am seed).core_run_state0.sym_supply
    (h2 bm am seed).dr_step_counter
    hdig
    (by rfl)
    (by seg_env_lookup)
    (by rfl)
    (by exact halN)
    (by rfl) (by rfl)
    (by show seed + 3 < 1152921504606846976; omega)
    (by show (3 : Nat) < 1152921504606846976; omega)
    (by exact Kit.readBytesFrom_writeBytesTo_hit rfl)

/-- SITE 3 — the exit segment's terminal chain (h3 → the done
    offer). -/
theorem seg_exit (hdig : CerberusFresh.digest () = "")
    (hsB : seed + 16 < 1152921504606846976)
    (halN : am.get? 0 = some allocN)
    (hb : ∀ i : Nat, (hi : i < argBytes.length) →
      bm.get? (nAddr + (i : Int)) = some argBytes[i]) :
    ∀ fuel, app (drive_nonmemory_steps_aux2_lemFuel (fuel + 35)
        t7File.tagDefs fmapEmpty [0]) (h3 bm am seed)
      = (NDactive (fmapAddBy defaultCompare 0
          [Step_done2 (Vloaded (LVspecified (OVinteger
            (CerbMem.IntegerValue.IV CerbMem.Provenance.Prov_none
              (Int.ofNat 0)))))] fmapEmpty),
         hFin bm am seed) := by
  have hsymc : (h1 bm am seed).core_run_state0.sym_supply
      = seed + 2 := e95_symc bm am [] 0 0 seed 0
  have hsymc2 : (h2 bm am seed).core_run_state0.sym_supply
      = seed + 3 := (bEven72_symc (envOf (h1 bm am seed))
      (h1 bm am seed).layout_state (h1 bm am seed).trace
      (h1 bm am seed).core_run_state0.aid_supply
      (h1 bm am seed).core_run_state0.excluded_supply
      (h1 bm am seed).core_run_state0.sym_supply
      (h1 bm am seed).dr_step_counter).trans (by rw [hsymc])
  have hsymc3 : (h3 bm am seed).core_run_state0.sym_supply
      = seed + 5 := (bOdd94_symc (envOf (h2 bm am seed))
      (h2 bm am seed).layout_state (h2 bm am seed).trace
      (h2 bm am seed).core_run_state0.aid_supply
      (h2 bm am seed).core_run_state0.excluded_supply
      (h2 bm am seed).core_run_state0.sym_supply
      (h2 bm am seed).dr_step_counter).trans (by rw [hsymc2])
  exact bx_chainrel (envOf (h3 bm am seed))
    (h3 bm am seed).layout_state (h3 bm am seed).trace
    (h3 bm am seed).core_run_state0.aid_supply
    (h3 bm am seed).core_run_state0.excluded_supply
    (h3 bm am seed).core_run_state0.sym_supply
    (h3 bm am seed).dr_step_counter
    hdig
    (by rfl)
    (by seg_env_lookup)
    (by rfl)
    (by exact halN)
    (by rfl) (by rfl)
    (by show seed + 5 < 1152921504606846976; omega)
    (by show (5 : Nat) < 1152921504606846976; omega)
    (by exact Kit.readBytesFrom_writeBytesTo_hit rfl)

end Sites

end RelSem.T7W
