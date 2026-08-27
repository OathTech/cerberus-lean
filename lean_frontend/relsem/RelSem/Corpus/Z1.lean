/-
  RelSem.Corpus.Z1 — arc-18 R6 batch 4 (2026-08-27): SIZE-LADDER z1.

  ***PARKED (measured cliff — the size ladder DID ITS JOB; NOT in
  the build).*** THE DEPTH CLIFF, measured: the 20-layer write1
  ladder's open-memory mint DID NOT COMPLETE in 25 minutes (killed
  at the bound; ~500 estimated rounds), vs ~90 s for c3b's 130
  rounds at depth 2 — per-round normalization cost grows with the
  accumulated fenced write tower (each round's hypNorm walks the
  whole layered memory term). Measurements taken under shared-box
  contention (another agent building concurrently) — the ORDER of
  magnitude is the datum, not the exact seconds. BETTER-ABSTRACTIONS
  work item (charter ruling: never a budget bump): index the
  accumulating memory term instead of inlining it per round — the
  [USER 2026-08-24] giant-terms-are-a-representation-smell rule
  applied to the minting engine's anchor states (derive_state-style
  named memory anchors per store layer, or a writeSeq-symbolic
  memory spelling the rounds carry by name). Also a fresh-draw
  finding: EVERY C assignment statement's elaboration draws a fresh
  symbol (the anon binder), so even straight-line programs need the
  guarded ∀-seed face once they re-assign — recorded for the
  statement-shape table.

  The fixture (.c/.core, z1File assembly, 3 harness rows,
  chain20(5) = 215) stays oracle-green as the reproducer.

  tests/verify/z1_chain.c — `int chain20(int x)`: LONG STRAIGHT-LINE
  (size-ladder row z1) — 20 sequential updates through the argument
  object: the write1 ladder at depth 20. The fixture's PURPOSE is
  measurement (rounds, mint wall-clock, equation size); the numbers
  live in the R6 campaign record.

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

namespace RelSem.Z1

open RelSem RelSem.Cerb RelSem.Slate RelSem.Kit
open Lem_Basic_classes (ordCompare)

/-! ## Statement data -/

/-- e1's filesystem state (initial, as every slate fixture). -/
def z1Fs : CerbFS.FsState := CerbFS.fs_initial_state

/-- z1's pure spec on driver results: chain20(5) = 215, Specified. -/
def z1Spec (r : driver_result) : Prop :=
  r.dres_core_value = intValue 215

/-! ## Fixture data (addresses, bytes, memory states — DATA, not
    equations; the T6 scalar-fixture layout family). -/

/-- `chain20`'s single parameter symbol (the emitted decl's binder). -/
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

/-- The argument object's byte image (x = -3). -/
def argBytes : List CerbMem.AbsByte := i32 5

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

/-- `chain20`'s Core body, projected from the emitted (drift-gated)
    declaration. The fallback arm is unreachable (chain20Z1Decl IS a
    `Proc`); a wrong projection would fail every downstream `rfl`
    loudly. -/
def chainBody : generic_expr core_run_annotation Unit sym :=
  match fmapLookupBy (fun (s1 s2 : sym) => ordCompare s1 s2) chain20Z1Sym
      z1File.funs with
  | some (Proc _ _ _ _ e) => e
  | _ => Expr [] (Epure (Pexpr [] () (PEval Vunit)))

/-- The ready thread (callFinish's thread-setup record). -/
def thRdy : thread_state :=
  { arena := chainBody,
    stack0 := Stack_empty,
    errno := errPtr,
    current_loc := CerbLocation.other "RelSem.callND",
    exec_loc := ELoc_normal [(chain20Z1Sym, CerbLocation.other "RelSem.callND")],
    env := [fmapAddBy (fun (s1 s2 : sym) => ordCompare s1 s2) symX
      (Vobject (OVpointer xPtr)) fmapEmpty],
    current_proc_opt := some chain20Z1Sym }

/-! ## The named-state ladder (minted) -/

/-- Stage 1: driver_globals (e1 has none). -/
derive_state_step dG (seed : Nat)
  from (driver_globals z1File.tagDefs false z1File)
  at (initial_driver_state_threaded seed z1File z1Fs)

/-- Post-injection driver state. -/
derive_state dInj (seed : Nat) : driver_state :=
  { dG seed with layout_state := memInj }

/-- Post-errno driver state. -/
derive_state dErr (seed : Nat) : driver_state :=
  { dG seed with layout_state := memD3 }

/-- The ready state (thread set to `chain20`'s body). -/
derive_state dRdy (seed : Nat) : driver_state :=
  { dErr seed with
    core_state0 := update_thread_state 0 thRdy (dErr seed).core_state0 }

/-! ### The rest ladder -/

abbrev rInit (seed : Nat) : driver_state :=
  restOf (initial_driver_state_threaded seed z1File z1Fs)
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
    app (driver_globals z1File.tagDefs false z1File)
        (setMaps (rInit seed) bm am)
      = (NDactive 0, setMaps (rGlob seed) bm am) := fun _ _ => rfl

/-- The post-globals canonical representative (`nd_get` joint). -/
@[seg_canon]
theorem z1_canon (seed : Nat) : Seg.CanonAt (rGlob seed) (dG seed) :=
  rfl

@[seg_eq rest]
theorem k3_o (seed : Nat) : ∀ bm am,
    app (resolveFunSym (dG seed).core_file "chain20")
        (setMaps (rGlob seed) bm am)
      = (NDactive chain20Z1Sym, setMaps (rGlob seed) bm am) :=
  fun _ _ => rfl

@[seg_eq rest]
theorem k4_o (seed : Nat) : ∀ bm am,
    app (lookupFunBody (dG seed).core_file chain20Z1Sym)
        (setMaps (rGlob seed) bm am)
      = (NDactive ([(symX, BTy_object OTy_pointer)], chainBody),
         setMaps (rGlob seed) bm am) := fun _ _ => rfl

@[seg_eq rest]
theorem k5_o (seed : Nat) : ∀ bm am,
    app (lookupParamTys (dG seed).core_file chain20Z1Sym)
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
theorem memValueFromValue_z1_eq :
    memValueFromValue z1File.tagDefs signed_int (intValue 5)
      = some (CerbMem.integerValueMval (Signed Int_)
          (CerbMem.integerIval 5)) := rfl

/-- Stage 6, THE ARGUMENT INJECTION at open maps. -/
@[seg_eq argobj]
theorem k6_o (seed : Nat) : ∀ bm am,
    app (injectArgs z1File.tagDefs 0
          [(symX, BTy_object OTy_pointer)] [signed_int] [intValue 5])
        (setMaps (rGlob seed) bm am)
      = (NDactive [(symX, Vobject (OVpointer xPtr))],
         allocStoreState (restAllocR (rGlob seed) xAddr) bm am xAddr 4
           argBytes 0 allocX) := by
  intro bm am
  refine Laws.inject_ptr_arg1 (σ := setMaps (rGlob seed) bm am)
    (hmv := memValueFromValue_z1_eq)
    (halloc := Kit.mem_alloc_block (sz := 4) (a := xAddr)
      (by exact rfl) (argAddr_fact seed) (by exact rfl))
    (hstore := Kit.mem_store_block (ty := signed_int)
      (mv := CerbMem.integerValueMval (Signed Int_)
        (CerbMem.integerIval 5))
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
  { core_file := z1File,
    core_extern := create_extern_symmap z1File,
    core_state0 :=
      { thread_states := [(0, (none, thRdy))],
        io := initial_io_state },
    core_run_state0 :=
      { tid_supply := 1, aid_supply := aid, excluded_supply := exc,
        sym_supply := symc,
        labeled := (initial_core_run_state_threaded 0
          (collect_labeled_continuations_NEW z1File)).labeled },
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
  (hdig : CerberusFresh.digest () = "")
  (hscB : symc < 1152921504606846976)
  (hexcB : exc < 1152921504606846976)
  (halX : am.get? 0 = some allocX)
  (hrdX : CerbMem.readBytesFrom (memRdy bm am) xAddr 4 = argBytes)
  (hbuilt : RelSem.Kit.FmapBuilt RelSem.Kit.symCmpO
    (fmapAddBy (fun (s1 s2 : sym) => ordCompare s1 s2) symX
      (Vobject (OVpointer xPtr)) fmapEmpty))
  assuming hdig hscB hexcB halX hrdX hbuilt
  fencing fmapAddBy fmapLookupBy CerbMem.writeBytesTo Std.TreeMap.insert Std.TreeMap.get? mkByte mk_conv_int mk_call_catch_exceptional_condition mk_wrapI
  using (z1File.tagDefs) 0 from (mkRdy bm am tr aid exc symc ctr) upto 700 chain builder
