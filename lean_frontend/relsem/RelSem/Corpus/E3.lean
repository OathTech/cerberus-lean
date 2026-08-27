/-
  RelSem.Corpus.E3 — arc-18 R6 batch 1 (2026-08-27): EASY-tier e3.

  tests/verify/e3_scale.c — `int scale(int x)`: straight-line
  arithmetic through one scalar local (census tie: the straight-line
  cost floor; corpus plan row e3; the INT_MAX UB row is excluded by
  the concrete instance). One local: the SCRATCH1 driver-atom shape
  (y's whole create/store/load/kill lifetime internal to the atom).

  Recipe: the T6Probe open-memory route verbatim at the e1 data —
  harness spine k-stage equations (registered segment supply), the
  open-memory `derive_rounds` mint, the read1 driver atom, statements
  through `verify_fn` + `seg_auto`. Statement shape: plain ∀-seed
  (no loop ⇒ no fresh draws ⇒ no digest/apartness guard).

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

namespace RelSem.E3

open RelSem RelSem.Cerb RelSem.Slate RelSem.Kit
open Lem_Basic_classes (ordCompare)

/-! ## Statement data -/

/-- e1's filesystem state (initial, as every slate fixture). -/
def e3Fs : CerbFS.FsState := CerbFS.fs_initial_state

/-- e3's pure spec on driver results: scale(7) = 17, Specified. -/
def e3Spec (r : driver_result) : Prop :=
  r.dres_core_value = intValue 17

/-! ## Fixture data (addresses, bytes, memory states — DATA, not
    equations; the T6 scalar-fixture layout family). -/

/-- `clamp0`'s single parameter symbol (the emitted decl's binder). -/
def symX : sym := Symbol "" 16562859848569467201 (SD_Id "x")

def xAddr : Int := 281474976710648
def errAddr : Int := 281474976710644

def xPtr : CerbMem.PointerValue := .PV (.Prov_some 0) (.PVconcrete none xAddr)
def errPtr : CerbMem.PointerValue := .PV (.Prov_some 1) (.PVconcrete none errAddr)

def allocX : CerbMem.Allocation :=
  { base := xAddr, size := 4, ty := some signed_int,
    prefix_ := PrefOther "callND arg" }
def allocErr : CerbMem.Allocation :=
  { base := errAddr, size := 4, ty := some signed_int,
    prefix_ := PrefOther "errno" }

/-- Little-endian byte `i` of an int-range integer (the house
    spelling — defeq to what the store computes). -/
def mkByte (x : Int) (i : Nat) : CerbMem.AbsByte :=
  { prov := .Prov_none, copyOffset := none,
    value := some ((((if x < 0 then (1 <<< 32) + x else x) >>> (i * 8)).toNat % 256).toUInt8) }

/-- The int byte image as a list. -/
def i32 (v : Int) : List CerbMem.AbsByte :=
  [mkByte v 0, mkByte v 1, mkByte v 2, mkByte v 3]

def uninitByte : CerbMem.AbsByte :=
  { prov := .Prov_none, copyOffset := none, value := none }

/-- The argument object's byte image (x = 7). -/
def argBytes : List CerbMem.AbsByte := i32 7

/-- Memory after the argument allocation (mem_alloc_block RHS form). -/
def memArgAlloc : CerbMem.MemState :=
  CerbMem.writeBytesTo
    { CerbMem.initialMemState with
      nextAllocId := 1, lastAddress := xAddr,
      allocations := Std.TreeMap.empty.insert 0 allocX }
    xAddr (List.replicate 4 uninitByte)

/-- Memory after the argument injection (mem_store_block RHS form). -/
def memInj : CerbMem.MemState :=
  CerbMem.writeBytesTo { memArgAlloc with funptrmap := [] } xAddr argBytes

/-- Memory after the errno allocation. -/
def memErrAlloc : CerbMem.MemState :=
  CerbMem.writeBytesTo
    { memInj with
      nextAllocId := 2, lastAddress := errAddr,
      allocations := (Std.TreeMap.empty.insert 0 allocX).insert 1 allocErr }
    errAddr (List.replicate 4 uninitByte)

/-- Memory after the errno block (the pre-run memory). -/
def memD3 : CerbMem.MemState :=
  CerbMem.writeBytesTo { memErrAlloc with funptrmap := [] } errAddr (i32 0)

/-- `scale`'s Core body, projected from the emitted (drift-gated)
    declaration. The fallback arm is unreachable (scaleE3Decl IS a
    `Proc`); a wrong projection would fail every downstream `rfl`
    loudly. -/
def scaleBody : generic_expr core_run_annotation Unit sym :=
  match fmapLookupBy (fun (s1 s2 : sym) => ordCompare s1 s2) scaleE3Sym
      e3File.funs with
  | some (Proc _ _ _ _ e) => e
  | _ => Expr [] (Epure (Pexpr [] () (PEval Vunit)))

/-- The ready thread (callFinish's thread-setup record). -/
def thRdy : thread_state :=
  { arena := scaleBody,
    stack0 := Stack_empty,
    errno := errPtr,
    current_loc := CerbLocation.other "RelSem.callND",
    exec_loc := ELoc_normal [(scaleE3Sym, CerbLocation.other "RelSem.callND")],
    env := [fmapAddBy (fun (s1 s2 : sym) => ordCompare s1 s2) symX
      (Vobject (OVpointer xPtr)) fmapEmpty],
    current_proc_opt := some scaleE3Sym }

/-! ## The named-state ladder (minted) -/

/-- Stage 1: driver_globals (e1 has none). -/
derive_state_step dG (seed : Nat)
  from (driver_globals e3File.tagDefs false e3File)
  at (initial_driver_state_threaded seed e3File e3Fs)

/-- Post-injection driver state. -/
derive_state dInj (seed : Nat) : driver_state :=
  { dG seed with layout_state := memInj }

/-- Post-errno driver state. -/
derive_state dErr (seed : Nat) : driver_state :=
  { dG seed with layout_state := memD3 }

/-- The ready state (thread set to `scale`'s body). -/
derive_state dRdy (seed : Nat) : driver_state :=
  { dErr seed with
    core_state0 := update_thread_state 0 thRdy (dErr seed).core_state0 }

/-! ### The rest ladder -/

abbrev rInit (seed : Nat) : driver_state :=
  restOf (initial_driver_state_threaded seed e3File e3Fs)
abbrev rGlob (seed : Nat) : driver_state := restOf (dG seed)
abbrev rArg (seed : Nat) : driver_state :=
  restAllocR (rGlob seed) xAddr
abbrev rErr (seed : Nat) : driver_state :=
  restAllocR (rArg seed) errAddr
abbrev rRdy (seed : Nat) : driver_state := restOf (dRdy seed)

/-! ## The open-memory harness spine (the T6 k-stage recipe at the
    e1 data; registered segment supply — seg_auto's feed) -/

@[seg_eq rest]
theorem k1_o (seed : Nat) : ∀ bm am,
    app (driver_globals e3File.tagDefs false e3File)
        (setMaps (rInit seed) bm am)
      = (NDactive 0, setMaps (rGlob seed) bm am) := fun _ _ => rfl

/-- The post-globals canonical representative (`nd_get` joint). -/
@[seg_canon]
theorem e3_canon (seed : Nat) : Seg.CanonAt (rGlob seed) (dG seed) :=
  rfl

@[seg_eq rest]
theorem k3_o (seed : Nat) : ∀ bm am,
    app (resolveFunSym (dG seed).core_file "scale")
        (setMaps (rGlob seed) bm am)
      = (NDactive scaleE3Sym, setMaps (rGlob seed) bm am) :=
  fun _ _ => rfl

@[seg_eq rest]
theorem k4_o (seed : Nat) : ∀ bm am,
    app (lookupFunBody (dG seed).core_file scaleE3Sym)
        (setMaps (rGlob seed) bm am)
      = (NDactive ([(symX, BTy_object OTy_pointer)], scaleBody),
         setMaps (rGlob seed) bm am) := fun _ _ => rfl

@[seg_eq rest]
theorem k5_o (seed : Nat) : ∀ bm am,
    app (lookupParamTys (dG seed).core_file scaleE3Sym)
        (setMaps (rGlob seed) bm am)
      = (NDactive [signed_int], setMaps (rGlob seed) bm am) :=
  fun _ _ => rfl

/-- The argument-object address arithmetic. -/
@[seg_fact]
theorem argAddr_fact (seed : Nat) :
    ((CerbMem.alignDown
        ((rGlob seed).layout_state.lastAddress - 4).toNat
        ((4 : Int).toNat.max 1) : Nat) : Int) = xAddr := by
  rw [show (rGlob seed).layout_state.lastAddress
    = (281474976710655 : Int) from rfl]
  decide

/-- The memValue the caller protocol computes for the e1 argument. -/
theorem memValueFromValue_e3_eq :
    memValueFromValue e3File.tagDefs signed_int (intValue 7)
      = some (CerbMem.integerValueMval (Signed Int_)
          (CerbMem.integerIval 7)) := rfl

/-- Stage 6, THE ARGUMENT INJECTION at open maps. -/
@[seg_eq argobj]
theorem k6_o (seed : Nat) : ∀ bm am,
    app (injectArgs e3File.tagDefs 0
          [(symX, BTy_object OTy_pointer)] [signed_int] [intValue 7])
        (setMaps (rGlob seed) bm am)
      = (NDactive [(symX, Vobject (OVpointer xPtr))],
         allocStoreState (restAllocR (rGlob seed) xAddr) bm am xAddr 4
           argBytes 0 allocX) := by
  intro bm am
  refine Laws.inject_ptr_arg1 (σ := setMaps (rGlob seed) bm am)
    (hmv := memValueFromValue_e3_eq)
    (halloc := Kit.mem_alloc_block (sz := 4) (a := xAddr)
      (by exact rfl) (argAddr_fact seed) (by exact rfl))
    (hstore := Kit.mem_store_block (ty := signed_int)
      (mv := CerbMem.integerValueMval (Signed Int_)
        (CerbMem.integerIval 7))
      (allocId := 0) (addr := xAddr) (alloc := allocX)
      (fpm := []) (bytes := argBytes)
      (hcompat := by exact rfl)
      (hget := by
        rw [Kit.writeBytesTo_allocations]
        show (am.insert 0 allocX).get? 0 = some allocX
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
  rw [show (rArg seed).layout_state.lastAddress = xAddr from rfl]
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

/-! ## THE DRIVER RUN at open maps (the T6 open-drive recipe: heap
    maps FREE binders, map reads through the registered memRW lane
    laws + the footprint pack) -/

/-- The ready memory at open maps (literal scalar fields). -/
def memRdy (bm : Std.TreeMap Int CerbMem.AbsByte)
    (am : Std.TreeMap Int CerbMem.Allocation) : CerbMem.MemState :=
  { CerbMem.initialMemState with
    nextAllocId := 2, lastAddress := errAddr,
    bytemap := bm, allocations := am }

/-- THE READY BUILDER (T6 mkRdy6 shape at the e1 fixture). -/
def mkRdy (bm : Std.TreeMap Int CerbMem.AbsByte)
    (am : Std.TreeMap Int CerbMem.Allocation)
    (tr : List trace_event) (aid exc symc ctr : Nat) : driver_state :=
  { core_file := e3File,
    core_extern := create_extern_symmap e3File,
    core_state0 :=
      { thread_states := [(0, (none, thRdy))],
        io := initial_io_state },
    core_run_state0 :=
      { tid_supply := 1, aid_supply := aid, excluded_supply := exc,
        sym_supply := symc,
        labeled := (initial_core_run_state_threaded 0
          (collect_labeled_continuations_NEW e3File)).labeled },
    layout_state := memRdy bm am,
    concurrency_state := symInitialState symInitialPre,
    fs_state0 := CerbFS.fs_initial_state,
    trace := tr,
    symbolic_assoc := fmapEmpty,
    blocked := false,
    dr_step_counter := ctr }

/-! THE OPEN DRIVE: the whole run minted with the maps free; the
    terminal ∀-fuel relative chain `ro_chainrel` is the theorem
    layer's feed. -/
set_option Elab.async false in
derive_rounds ro
  (bm : Std.TreeMap Int CerbMem.AbsByte)
  (am : Std.TreeMap Int CerbMem.Allocation)
  (tr : List trace_event) (aid exc symc ctr : Nat)
  (halX : am.get? 0 = some allocX)
  (hrdX : CerbMem.readBytesFrom (memRdy bm am) xAddr 4 = argBytes)
  assuming halX hrdX
  fencing CerbMem.writeBytesTo Std.TreeMap.insert Std.TreeMap.get? Std.TreeMap.erase
  using (e3File.tagDefs) 0 from (mkRdy bm am tr aid exc symc ctr) upto 90 chain builder

/-! ## The scratch object (y, scale's local) and the final state
    (SCRATCH1: y's whole create/store/load/kill lifetime internal to
    the atom; the errno object rides the frame) -/

/-- y's address (the bump allocator's next slot below errno). -/
def tAddr : Int := 281474976710640

/-- y's allocation record (rule-shaped). -/
def allocY : CerbMem.Allocation :=
  { base := tAddr, size := 4, ty := some signed_int,
    prefix_ := PrefOther "Core" }

/-- y's stored byte image (y = 17). -/
def bytesY : List CerbMem.AbsByte := i32 17

/-- The run's terminal value (Specified 17). -/
def v17 : value :=
  Vloaded (LVspecified (OVinteger
    (CerbMem.IntegerValue.IV .Prov_none 17)))

/-- The scratch address arithmetic (y's create inside the driver
    atom). -/
@[seg_fact]
theorem tAddr_fact (seed : Nat) :
    ((CerbMem.alignDown
        ((rRdy seed).layout_state.lastAddress - 4).toNat
        ((4 : Int).toNat.max 1) : Nat) : Int) = tAddr := by
  rw [show (rRdy seed).layout_state.lastAddress = errAddr from rfl]
  decide

/-- The final driver state at the canonical instantiation with the
    maps ZEROED (map-independent by construction), post
    `prepare_exit`. -/
noncomputable abbrev roFin0 (seed : Nat) : driver_state :=
  { ro31 Std.TreeMap.empty Std.TreeMap.empty [] 0 0 seed 0 with
    core_state0 := prepare_exit
      (ro31 Std.TreeMap.empty Std.TreeMap.empty [] 0 0 seed 0).core_state0
      v17 }

/-- The final rest. -/
noncomputable abbrev rDone (seed : Nat) : driver_state := restOf (roFin0 seed)

/-- THE DRIVER LOOP at open maps: characterized by the rest + the
    argument object's footprint; the scratch object's whole lifetime
    (create/store/load/kill of y) is internal to the equation; the
    errno object is never mentioned (it rides the frame). -/
@[seg_eq scratch1]
theorem driver2_o (seed : Nat) : ∀ bm am,
    am.get? 0 = some allocX →
    (∀ i : Nat, (hi : i < argBytes.length) →
      bm.get? (xAddr + (i : Int)) = some (argBytes[i])) →
    app (driver2 e3File.tagDefs false) (setMaps (rRdy seed) bm am)
      = (NDactive (), setMaps (rDone seed)
          (allocStoreBytes bm tAddr 4 bytesY)
          ((am.insert 2 allocY).erase 2)) := by
  intro bm am hget hb
  have hrdX : CerbMem.readBytesFrom (memRdy bm am) xAddr 4
      = argBytes :=
    readBytesFrom_of_pointwise rfl (fun i hi => hb i hi)
  have hchain := ro_chainrel bm am [] 0 0 seed 0 hget hrdX 999967
  have hndct : app (new_drive_core_threads e3File.tagDefs ())
      (mkRdy bm am [] 0 0 seed 0)
      = (NDactive [(0, some (Step_done2 v17))],
         ro31 bm am [] 0 0 seed 0) :=
    RelSem.Laws.ndct_offer1 rfl hchain
  have h6 : app (driver2 e3File.tagDefs false)
      (mkRdy bm am [] 0 0 seed 0)
      = (NDactive (), setMaps (rDone seed)
          (allocStoreBytes bm tAddr 4 bytesY)
          ((am.insert 2 allocY).erase 2)) := by
    show app (driver2_lemFuel (999999+1) e3File.tagDefs false)
      (mkRdy bm am [] 0 0 seed 0) = _
    exact RelSem.Laws.driver2_done hndct (by rfl)
  have halign : setMaps (rRdy seed) bm am
      = mkRdy bm am [] 0 0 seed 0 := rfl
  rw [halign]
  exact h6

/-- e3's FnSpec ([F9], role 1): `scale(7)` returns `Specified 17`.
    REDUCIBLE — the faces unify its projections against the statement
    text. -/
abbrev scaleSpec : Seg.FnSpec Unit :=
  { fname := "scale", args := fun _ => [intValue 7],
    post := fun _ => e3Spec }

/-! ## THE THREADED STATEMENTS (fuel-opsem faces, ∀-seed) -/

/-- THE e3 HEADLINE (fuel opsem only): for EVERY fresh-symbol supply
    seed, every outcome of `callND(scale, [intValue 7])` from the
    threaded initial state is `Active r` with
    `r.dres_core_value = intValue 17`. -/
def E3ThreadedStatement : Prop :=
  ∀ (seed : Nat),
    CallHarnessAdequateThr seed e3File.tagDefs e3File "scale"
      [intValue 7] e3Fs e3Spec

/-- **e3 THREADED, UNCONDITIONAL** (cone exactly the classical trio;
    through the segment layer). -/
theorem E3Threaded : E3ThreadedStatement := by
  verify_fn scaleSpec
  seg_auto

/-- **e3 THREADED UB-freedom** (the safety twin — same route). -/
theorem E3Threaded_ubFree :
    ∀ (seed : Nat),
      CallHarnessUBFreeThr seed e3File.tagDefs e3File "scale"
        [intValue 7] e3Fs := by
  verify_fn scaleSpec
  seg_auto

end RelSem.E3
