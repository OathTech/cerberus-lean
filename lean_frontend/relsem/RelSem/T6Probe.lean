/-
  RelSem.T6Probe — arc-17 S1/S2 (2026-08-24/25): THE ACCEPTANCE PROBE,
  COMPLETED (un-parked; charter S2 deliverable 1's acceptance).

  History: S1 drove this fixture's zero-fixture-equation proof to the
  first MEMORY round and PARKED at a measured wall — minting the store
  round's successor by raw meta whnf allocated past the 64 G cap (S1
  record §4.2). S2's law-driven round evaluator
  (RelSem/RoundEval.lean — memory rounds through the Kit law chain,
  successors ANCHORED as constant-depth records) closes the gap: the
  ENTIRE run (51 advancing dnms rounds + terminal, mixed
  tau/runstate/create/store/load classes) is minted by ONE
  `derive_rounds` command, and the whole-run driver equation
  (`r_driver`) comes out of the same command via the S1 construct laws
  (`ndct_offer1`, `driver2_done`).

  Fixture: tests/verify/t6_branch.c — `int pick(int x)` with a local,
  a computed branch, subtraction/addition arms; oracle-pinned,
  drift-gated, 4 harness expectation points, slate concrete points in
  EmitLeanCoreTest. Headline: ∀-seed, callND(pick,[10]) = Specified 7,
  no UB — statements at the threaded faces, cones exactly the
  classical trio.

  ACCOUNTING (the charter bar): ZERO fixture-specific derived-equation
  lemmas. The per-fixture text is DATA (addresses, byte literals, the
  named-state ladder) plus one-line INSTANTIATIONS of registered
  construct laws (`inject_ptr_arg1`, `callND_errno`,
  `driver_update_ts`) whose side conditions discharge by rfl/decide.
  All driver rounds are evaluator mints.

  ARC-18 R1 (2026-08-26): THE OPEN-MEMORY ROUTE. The C2 exemption is
  CLEARED — this walk now lives on the ONE route (`CerbMemInterp`):
  the driver run is minted by `derive_rounds … builder` at the
  setMaps decomposition (heap maps FREE binders; map reads discharged
  through the registered memRW lane laws + the footprint hypothesis
  pack instead of ground eval — the RoundEval OPEN-MEMORY MINTING
  MODE, the C2 §6 named mover, landed), and the statement-facing
  discharge is the T1Threaded heap-route pattern verbatim: rest
  ladder + open k-stage equations + the CerbHeapWalk macros +
  `kCallHarnessAdequateThrHeap_of_wp`. The GROUND drive (below) is
  retained as the evaluator's ground-lane acceptance instance; the
  OPEN drive is the segment layer's equation supply.

  House rules: no sorry, no axioms. Under the in-build audit.
-/

import RelSem.Threaded
import RelSem.PerStepTactics
import RelSem.DeriveState
import RelSem.RoundEval
import RelSem.ConstructLaws
import RelSem.SlateFiles
import RelSem.CerbHeapWalk

set_option autoImplicit false

namespace RelSem.T6

open RelSem RelSem.Cerb RelSem.Slate RelSem.Kit
open Lem_Basic_classes (ordCompare)
open Iris Iris.ProgramLogic Iris.BI

/-! ## Statement data -/

/-- T6's filesystem state (initial, as every slate fixture). -/
def t6Fs : CerbFS.FsState := CerbFS.fs_initial_state

/-- T6's pure spec on driver results: pick(10) = 10 - 3 = 7,
    Specified. -/
def t6Spec (r : driver_result) : Prop :=
  r.dres_core_value = intValue 7

/-! ## Fixture data (addresses, bytes, memory states — DATA, not
    equations; the LP64 allocator is deterministic from the initial
    state, same layout family as every scalar fixture).

    S2 change from the parked frontier: the memory-state ladder is
    spelled in the Kit laws' COMPUTED-RHS form (`writeBytesTo` layers)
    rather than insert-chain literals — the recorded heartbeat
    crossers on the `hout` recast direction (S1 record §4.2, input 5)
    dissolve because the law output and the named state now match by
    spelling. -/

/-- `pick`'s single parameter symbol (the emitted decl's binder). -/
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

/-- Little-endian byte `i` of an int-range integer (the T1AppEq
    spelling — defeq to what the store computes). -/
def mkByte (x : Int) (i : Nat) : CerbMem.AbsByte :=
  { prov := .Prov_none, copyOffset := none,
    value := some ((((if x < 0 then (1 <<< 32) + x else x) >>> (i * 8)).toNat % 256).toUInt8) }

def uninitByte : CerbMem.AbsByte :=
  { prov := .Prov_none, copyOffset := none, value := none }

/-- Memory after the argument allocation (mem_alloc_block RHS form). -/
def memArgAlloc : CerbMem.MemState :=
  CerbMem.writeBytesTo
    { CerbMem.initialMemState with
      nextAllocId := 1, lastAddress := xAddr,
      allocations := Std.TreeMap.empty.insert 0 allocX }
    xAddr (List.replicate 4 uninitByte)

/-- Memory after the argument injection (mem_store_block RHS form). -/
def memInj : CerbMem.MemState :=
  CerbMem.writeBytesTo { memArgAlloc with funptrmap := [] } xAddr
    [mkByte 10 0, mkByte 10 1, mkByte 10 2, mkByte 10 3]

/-- Memory after the errno allocation. -/
def memErrAlloc : CerbMem.MemState :=
  CerbMem.writeBytesTo
    { memInj with
      nextAllocId := 2, lastAddress := errAddr,
      allocations := (Std.TreeMap.empty.insert 0 allocX).insert 1 allocErr }
    errAddr (List.replicate 4 uninitByte)

/-- Memory after the errno block (the pre-run memory). -/
def memD3 : CerbMem.MemState :=
  CerbMem.writeBytesTo { memErrAlloc with funptrmap := [] } errAddr
    [mkByte 0 0, mkByte 0 1, mkByte 0 2, mkByte 0 3]

/-- `pick`'s Core body, projected from the emitted (drift-gated)
    declaration. The fallback arm is unreachable (pickT6Decl IS a
    `Proc`); a wrong projection would fail every downstream `rfl`
    loudly. -/
def pickBody : generic_expr core_run_annotation Unit sym :=
  match fmapLookupBy (fun (s1 s2 : sym) => ordCompare s1 s2) pickT6Sym
      t6File.funs with
  | some (Proc _ _ _ _ e) => e
  | _ => Expr [] (Epure (Pexpr [] () (PEval Vunit)))

/-- The ready thread (callFinish's thread-setup record, at the probe's
    concrete data). -/
def thRdy : thread_state :=
  { arena := pickBody,
    stack0 := Stack_empty,
    errno := errPtr,
    current_loc := CerbLocation.other "RelSem.callND",
    exec_loc := ELoc_normal [(pickT6Sym, CerbLocation.other "RelSem.callND")],
    env := [fmapAddBy (fun (s1 s2 : sym) => ordCompare s1 s2) symX
      (Vobject (OVpointer xPtr)) fmapEmpty],
    current_proc_opt := some pickT6Sym }

/-! ## The named-state ladder (minted; the S0 giant-terms discipline) -/

/-- Stage 1: driver_globals (t6 has none). -/
derive_state_step dG (seed : Nat)
  from (driver_globals t6File.tagDefs false t6File)
  at (initial_driver_state_threaded seed t6File t6Fs)

/-- Stage 3: resolve the designated function name (state-preserving;
    value auto-derived). -/
derive_state_step kRes (seed : Nat)
  from (resolveFunSym (dG seed).core_file "pick")
  at (dG seed) expecting (dG seed)

/-- Stage 4: the designated function's params + body. -/
derive_state_step kBody (seed : Nat)
  from (lookupFunBody (dG seed).core_file pickT6Sym)
  at (dG seed) expecting (dG seed)

/-- Stage 5: the funinfo parameter C types. -/
derive_state_step kTys (seed : Nat)
  from (lookupParamTys (dG seed).core_file pickT6Sym)
  at (dG seed) expecting (dG seed)

/-- Post-injection driver state. -/
derive_state dInj (seed : Nat) : driver_state :=
  { dG seed with layout_state := memInj }

/-- Post-errno driver state. -/
derive_state dErr (seed : Nat) : driver_state :=
  { dG seed with layout_state := memD3 }

/-- The ready state (thread set to `pick`'s body, all memory in
    place) — the driver loop's starting point. -/
derive_state dRdy (seed : Nat) : driver_state :=
  { dErr seed with
    core_state0 := update_thread_state 0 thRdy (dErr seed).core_state0 }

/-! ## The harness caller-protocol stages (registered construct laws
    at this fixture's data; side conditions rfl/decide — the S2
    projection-rewrite + kernel-decide recipe for the allocator
    arithmetic) -/

/-- The argument injection through `Laws.inject_ptr_arg1` (the
    one-scalar-argument caller protocol). -/
theorem t6_inject (seed : Nat) :
    app (injectArgs t6File.tagDefs 0 [(symX, BTy_object OTy_pointer)]
        [signed_int] [intValue 10]) (dG seed)
      = (NDactive [(symX, Vobject (OVpointer xPtr))], dInj seed) :=
  RelSem.Laws.inject_ptr_arg1
    (hmv := by exact rfl)
    (halloc := Kit.mem_alloc_block (ty := signed_int) (sz := 4)
      (a := xAddr) (by exact rfl)
      (by rw [show (dG seed).layout_state.lastAddress
            = 281474976710655 from rfl]; decide) (by exact rfl))
    (hstore := Kit.mem_store_block (ty := signed_int)
      (mv := CerbMem.integerValueMval (Signed Int_)
        (CerbMem.integerIval 10))
      (allocId := 0) (addr := xAddr)
      (alloc := allocX) (fpm := [])
      (bytes := [mkByte 10 0, mkByte 10 1, mkByte 10 2, mkByte 10 3])
      (by exact rfl) (by exact rfl) (by decide) (by exact rfl)
      (by exact rfl) (by exact rfl))
    (hout := rfl)

/-- The errno block through `Laws.callND_errno`. -/
theorem t6_errno (seed : Nat) :
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
      (dInj seed)
      = (NDactive errPtr, dErr seed) :=
  RelSem.Laws.callND_errno
    (halloc := Kit.mem_alloc_block (ty := signed_int) (sz := 4)
      (a := errAddr) (by exact rfl)
      (by rw [show (dInj seed).layout_state.lastAddress
            = xAddr from rfl]; decide) (by exact rfl))
    (hstore := Kit.mem_store_block (ty := signed_int)
      (mv := CerbMem.integerValueMval (Signed Int_)
        (CerbMem.integerIval 0))
      (allocId := 1) (addr := errAddr)
      (alloc := allocErr) (fpm := [])
      (bytes := [mkByte 0 0, mkByte 0 1, mkByte 0 2, mkByte 0 3])
      (by exact rfl) (by exact rfl) (by decide) (by exact rfl)
      (by exact rfl) (by exact rfl))
    (hout := rfl)

/-! ## THE DRIVER RUN — every round evaluator-minted (RoundEval:
    memory rounds through the Kit law chain, successors anchored;
    emits the dnms chain `r_chain`, the scheduler offer `r_ndct`, the
    final state `r_fin` and the whole-run driver equation
    `r_driver`) -/

derive_rounds r (seed : Nat) using (t6File.tagDefs) 0 from (dRdy seed)

/-- The finalize result: Specified 7 (kernel-checked at the anchored
    final state). -/
theorem t6_result_eq (seed : Nat) :
    (finalize t6File.tagDefs "callND" (r_fin seed)).dres_core_value
      = intValue 7 := rfl

/-! ## THE OPEN-MEMORY EQUATION SUPPLY (arc-18 R1): the driver run
    minted at the setMaps decomposition — heap maps FREE binders,
    map reads through the registered memRW lane laws + the footprint
    pack. The builder is the T5W `mkRdy` discipline (LITERAL scalar
    fields — no hidden fenced ladders under the anchor); the pack is
    exactly the two footprint facts the walk rule feeds
    (`wpk_seq_scratch1`'s hget + pointwise-bytes premises, in the
    one-fact `readBytesFrom` form `readBytesFrom_of_pointwise`
    derives). -/

/-- The ready rest (the driver loop's start, maps zeroed). -/
abbrev rRdy (seed : Nat) : driver_state := restOf (dRdy seed)

/-- The argument object's byte image (x = 10). -/
def argBytes6 : List CerbMem.AbsByte :=
  [mkByte 10 0, mkByte 10 1, mkByte 10 2, mkByte 10 3]

/-- The ready memory at open maps (the `mkRdy6` layout; literal
    scalar fields). -/
def memRdy (bm : Std.TreeMap Int CerbMem.AbsByte)
    (am : Std.TreeMap Int CerbMem.Allocation) : CerbMem.MemState :=
  { CerbMem.initialMemState with
    nextAllocId := 2, lastAddress := errAddr,
    bytemap := bm, allocations := am }

/-- THE READY BUILDER (T5W mkRdy shape at the T6 fixture): heap maps
    and supplies free, every other field concrete. Aligns with
    `setMaps (rRdy seed) bm am` by rfl at the canonical
    instantiation. -/
def mkRdy6 (bm : Std.TreeMap Int CerbMem.AbsByte)
    (am : Std.TreeMap Int CerbMem.Allocation)
    (tr : List trace_event) (aid exc symc ctr : Nat) : driver_state :=
  { core_file := t6File,
    core_extern := create_extern_symmap t6File,
    core_state0 :=
      { thread_states := [(0, (none, thRdy))],
        io := initial_io_state },
    core_run_state0 :=
      { tid_supply := 1, aid_supply := aid, excluded_supply := exc,
        sym_supply := symc,
        labeled := (initial_core_run_state_threaded 0
          (collect_labeled_continuations_NEW t6File)).labeled },
    layout_state := memRdy bm am,
    concurrency_state := symInitialState symInitialPre,
    fs_state0 := CerbFS.fs_initial_state,
    trace := tr,
    symbolic_assoc := fmapEmpty,
    blocked := false,
    dr_step_counter := ctr }

/-! THE OPEN DRIVE: the whole run (51 rounds + terminal) minted with
    the maps free; the terminal ∀-fuel relative chain `ro_chainrel`
    is the theorem layer's feed. -/
set_option Elab.async false in
derive_rounds ro
  (bm : Std.TreeMap Int CerbMem.AbsByte)
  (am : Std.TreeMap Int CerbMem.Allocation)
  (tr : List trace_event) (aid exc symc ctr : Nat)
  (halX : am.get? 0 = some allocX)
  (hrdX : CerbMem.readBytesFrom (memRdy bm am) xAddr 4 = argBytes6)
  assuming halX hrdX
  fencing CerbMem.writeBytesTo Std.TreeMap.insert Std.TreeMap.get? Std.TreeMap.erase
  using (t6File.tagDefs) 0 from (mkRdy6 bm am tr aid exc symc ctr) upto 60 chain builder

/-! ## The scratch object (t, pick's local) and the final state -/

/-- t's address (the bump allocator's next slot below errno). -/
def tAddr : Int := 281474976710640

/-- t's allocation record (rule-shaped). -/
def allocT : CerbMem.Allocation :=
  { base := tAddr, size := 4, ty := some signed_int,
    prefix_ := PrefOther "Core" }

/-- t's stored byte image (t = 3). -/
def bytesT : List CerbMem.AbsByte :=
  [mkByte 3 0, mkByte 3 1, mkByte 3 2, mkByte 3 3]

/-- The run's terminal value (Specified 7). -/
def v7 : value :=
  Vloaded (LVspecified (OVinteger
    (CerbMem.IntegerValue.IV .Prov_none 7)))

/-- The final driver state at the canonical instantiation with the
    maps ZEROED (map-independent by construction — the walk's own
    endpoint, projected, never transcribed; the `lh1Arena`
    precedent), post `prepare_exit`. -/
noncomputable abbrev roFin0 (seed : Nat) : driver_state :=
  { ro51 Std.TreeMap.empty Std.TreeMap.empty [] 0 0 seed 0 with
    core_state0 := prepare_exit
      (ro51 Std.TreeMap.empty Std.TreeMap.empty [] 0 0 seed 0).core_state0
      v7 }

/-- The final rest. -/
noncomputable abbrev rDone6 (seed : Nat) : driver_state := restOf (roFin0 seed)

/-! ## The driver loop at open maps: the whole `driver2` atom from
    the minted terminal chain + the construct laws (`ndct_offer1` /
    `driver2_done` — the T1Threaded recipe with the hand round-chain
    replaced by the evaluator's `ro_chainrel`). -/

/-- THE DRIVER LOOP at open maps: characterized by the rest + the
    argument object's footprint; the scratch object's whole lifetime
    (create/store/load/kill of t) is internal to the equation; the
    errno object is never mentioned (it rides the frame). -/
theorem driver2_o (seed : Nat) : ∀ bm am,
    am.get? 0 = some allocX →
    (∀ i : Nat, (hi : i < argBytes6.length) →
      bm.get? (xAddr + (i : Int)) = some (argBytes6[i])) →
    app (driver2 t6File.tagDefs false) (setMaps (rRdy seed) bm am)
      = (NDactive (), setMaps (rDone6 seed)
          (allocStoreBytes bm tAddr 4 bytesT)
          ((am.insert 2 allocT).erase 2)) := by
  intro bm am hget hb
  have hrdX : CerbMem.readBytesFrom (memRdy bm am) xAddr 4
      = argBytes6 :=
    readBytesFrom_of_pointwise rfl (fun i hi => hb i hi)
  have hchain := ro_chainrel bm am [] 0 0 seed 0 hget hrdX 999947
  have hndct : app (new_drive_core_threads t6File.tagDefs ())
      (mkRdy6 bm am [] 0 0 seed 0)
      = (NDactive [(0, some (Step_done2 v7))],
         ro51 bm am [] 0 0 seed 0) :=
    RelSem.Laws.ndct_offer1 rfl hchain
  have h6 : app (driver2 t6File.tagDefs false)
      (mkRdy6 bm am [] 0 0 seed 0)
      = (NDactive (), setMaps (rDone6 seed)
          (allocStoreBytes bm tAddr 4 bytesT)
          ((am.insert 2 allocT).erase 2)) := by
    show app (driver2_lemFuel (999999+1) t6File.tagDefs false)
      (mkRdy6 bm am [] 0 0 seed 0) = _
    exact RelSem.Laws.driver2_done hndct (by rfl)
  have halign : setMaps (rRdy seed) bm am
      = mkRdy6 bm am [] 0 0 seed 0 := rfl
  rw [halign]
  exact h6

/-- The terminal readout, uniform over the rest fiber. -/
theorem t6_post_o (seed : Nat) : ∀ bm am,
    ∃ r : driver_result,
      (Outcome.value (finalize t6File.tagDefs "callND"
          (setMaps (rDone6 seed) bm am)) : DriveVal)
        = Outcome.value r ∧ t6Spec r :=
  fun _ _ => ⟨_, rfl, rfl⟩

/-! ## The harness spine at open maps (the T1Threaded k-stage recipe
    verbatim at the T6 data; pure stages `rfl` at free maps, memory
    stages through the construct laws + Kit blocks) -/

abbrev rInit6 (seed : Nat) : driver_state :=
  restOf (initial_driver_state_threaded seed t6File t6Fs)
abbrev rGlob6 (seed : Nat) : driver_state := restOf (dG seed)
abbrev rArg6 (seed : Nat) : driver_state :=
  restAllocR (rGlob6 seed) xAddr
abbrev rErr6 (seed : Nat) : driver_state :=
  restAllocR (rArg6 seed) errAddr

theorem k1_o (seed : Nat) : ∀ bm am,
    app (driver_globals t6File.tagDefs false t6File)
        (setMaps (rInit6 seed) bm am)
      = (NDactive 0, setMaps (rGlob6 seed) bm am) := fun _ _ => rfl

theorem k3_o (seed : Nat) : ∀ bm am,
    app (resolveFunSym (dG seed).core_file "pick")
        (setMaps (rGlob6 seed) bm am)
      = (NDactive pickT6Sym, setMaps (rGlob6 seed) bm am) :=
  fun _ _ => rfl

theorem k4_o (seed : Nat) : ∀ bm am,
    app (lookupFunBody (dG seed).core_file pickT6Sym)
        (setMaps (rGlob6 seed) bm am)
      = (NDactive ([(symX, BTy_object OTy_pointer)], pickBody),
         setMaps (rGlob6 seed) bm am) := fun _ _ => rfl

theorem k5_o (seed : Nat) : ∀ bm am,
    app (lookupParamTys (dG seed).core_file pickT6Sym)
        (setMaps (rGlob6 seed) bm am)
      = (NDactive [signed_int], setMaps (rGlob6 seed) bm am) :=
  fun _ _ => rfl

/-- The argument-object address arithmetic. -/
theorem argAddr6_fact (seed : Nat) :
    ((CerbMem.alignDown
        ((rGlob6 seed).layout_state.lastAddress - 4).toNat
        ((4 : Int).toNat.max 1) : Nat) : Int) = xAddr := by
  rw [show (rGlob6 seed).layout_state.lastAddress
    = (281474976710655 : Int) from rfl]
  decide

/-- The memValue the caller protocol computes for the T6 argument
    (fixes the injection law's ctype/align slots for the eager named
    facts below — the T1 `memValueFromValue_t1_eq` recipe). -/
theorem memValueFromValue_t6_eq :
    memValueFromValue t6File.tagDefs signed_int (intValue 10)
      = some (CerbMem.integerValueMval (Signed Int_)
          (CerbMem.integerIval 10)) := rfl

/-- Stage 6, THE ARGUMENT INJECTION at open maps. -/
theorem k6_o (seed : Nat) : ∀ bm am,
    app (injectArgs t6File.tagDefs 0
          [(symX, BTy_object OTy_pointer)] [signed_int] [intValue 10])
        (setMaps (rGlob6 seed) bm am)
      = (NDactive [(symX, Vobject (OVpointer xPtr))],
         allocStoreState (restAllocR (rGlob6 seed) xAddr) bm am xAddr 4
           argBytes6 0 allocX) := by
  intro bm am
  refine Laws.inject_ptr_arg1 (σ := setMaps (rGlob6 seed) bm am)
    (hmv := memValueFromValue_t6_eq)
    (halloc := Kit.mem_alloc_block (sz := 4) (a := xAddr)
      (by exact rfl) (argAddr6_fact seed) (by exact rfl))
    (hstore := Kit.mem_store_block (ty := signed_int)
      (mv := CerbMem.integerValueMval (Signed Int_)
        (CerbMem.integerIval 10))
      (allocId := 0) (addr := xAddr) (alloc := allocX)
      (fpm := []) (bytes := argBytes6)
      (hcompat := by exact rfl)
      (hget := by
        rw [Kit.writeBytesTo_allocations]
        show (am.insert 0 allocX).get? 0 = some allocX
        simp [Std.TreeMap.get?_eq_getElem?, Std.TreeMap.getElem?_insert])
      (hbounds := by exact rfl) (hro := rfl)
      (hatomic := by exact rfl)
      (hbytes := by
        rw [Kit.writeBytesTo_funptrmap]
        exact rfl))
    (hout := by
      simp only [writeBytesTo_eq]
      rfl)

theorem k7_o (seed : Nat) : ∀ bm am,
    app get_thread_states (setMaps (rArg6 seed) bm am)
      = (NDactive ((dG seed).core_state0.thread_states),
         setMaps (rArg6 seed) bm am) :=
  fun _ _ => rfl

/-- The errno address arithmetic. -/
theorem errAddr6_fact (seed : Nat) :
    ((CerbMem.alignDown
        ((rArg6 seed).layout_state.lastAddress - 4).toNat
        ((4 : Int).toNat.max 1) : Nat) : Int) = errAddr := by
  rw [show (rArg6 seed).layout_state.lastAddress = xAddr from rfl]
  decide

/-- Stage 8, THE ERRNO BLOCK at open maps. -/
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
      (setMaps (rArg6 seed) bm am)
      = (NDactive errPtr,
         allocStoreState (restAllocR (rArg6 seed) errAddr) bm am errAddr
           4 [mkByte 0 0, mkByte 0 1, mkByte 0 2, mkByte 0 3]
           1 allocErr) := by
  intro bm am
  refine Laws.callND_errno (σ := setMaps (rArg6 seed) bm am)
    (halloc := Kit.mem_alloc_block (sz := 4) (a := errAddr)
      (by exact rfl) (errAddr6_fact seed) (by exact rfl))
    (hstore := Kit.mem_store_block (ty := signed_int)
      (mv := CerbMem.integerValueMval (Signed Int_)
        (CerbMem.integerIval 0))
      (allocId := 1) (addr := errAddr) (alloc := allocErr)
      (fpm := [])
      (bytes := [mkByte 0 0, mkByte 0 1, mkByte 0 2, mkByte 0 3])
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
theorem k9_o (seed : Nat) (th : thread_state) (hth : th = thRdy) :
    ∀ bm am,
    app (driver_update_thread_state 0 th : driverM Unit)
        (setMaps (rErr6 seed) bm am)
      = (NDactive (), setMaps (rRdy seed) bm am) := by
  subst hth; exact fun _ _ => rfl

/-- The scratch address arithmetic (t's create inside the driver
    atom). -/
theorem tAddr_fact (seed : Nat) :
    ((CerbMem.alignDown
        ((rRdy seed).layout_state.lastAddress - 4).toNat
        ((4 : Int).toNat.max 1) : Nat) : Int) = tAddr := by
  rw [show (rRdy seed).layout_state.lastAddress = errAddr from rfl]
  decide

/-! ## The statement-facing route: the per-step WP walk ON THE HEAP
    ROUTE (CerbMemInterp; the T1/T3 walk pattern — the driver atom is
    `wp_scratch1`: it reads the argument object's footprint, runs t's
    whole lifetime internally, and the errno fragments ride the frame
    across it). -/

theorem t6_wpK_thr {GF : BundledGFunctors} [CerbHeapGS GF]
    (seed : Nat) :
    (restIs (GF := GF) restHalf (rInit6 seed)) ⊢
      WP (callK t6File.tagDefs t6File "pick" [intValue 10])
        @ Stuckness.NotStuck ; ⊤
        {{ o, ⌜∃ r : driver_result, o = Outcome.value r ∧ t6Spec r⌝ }} := by
  iintro Hst
  wp_rest (k1_o seed) Hst
  wp_get (dG seed) Hst
  wp_rest (k3_o seed) Hst
  wp_rest (k4_o seed) Hst
  wp_rest (k5_o seed) Hst
  wp_argobj (k6_o seed) (argAddr6_fact seed) Hst HalX HptX
  wp_rest (k7_o seed) Hst
  wp_argobj (k8_o seed) (errAddr6_fact seed) Hst HalE HptE
  wp_rest (k9_o seed _ (by rfl)) Hst
  wp_scratch1 (driver2_o seed) (tAddr_fact seed) Hst HalX HptX HptT
  wp_fin (t6_post_o seed) Hst

/-! ## THE THREADED STATEMENTS (fuel-opsem faces, ∀-seed) -/

/-- THE T6 HEADLINE (fuel opsem only): for EVERY fresh-symbol supply
    seed, every outcome the production runner enumerates for
    `callND(pick, [intValue 10])` from the threaded initial state is
    `Active r` with `r.dres_core_value = intValue 7`. -/
def T6ThreadedStatement : Prop :=
  ∀ (seed : Nat),
    CallHarnessAdequateThr seed t6File.tagDefs t6File "pick"
      [intValue 10] t6Fs t6Spec

/-- **T6 THREADED, UNCONDITIONAL** (cone exactly the classical trio;
    arc-18 R1: through the heap-route walk — the open-memory minted
    equation supply discharged via `kCallHarnessAdequateThrHeap_of_wp`;
    statement text byte-stable across the migration). -/
theorem T6Threaded : T6ThreadedStatement := by
  intro seed
  refine kCallHarnessAdequateThrHeap_of_wp (GF := CerbHeapS) seed
    t6File.tagDefs t6File "pick" [intValue 10] t6Fs t6Spec ?_
  intro η
  exact t6_wpK_thr seed

/-- **T6 THREADED UB-freedom** (same route). -/
theorem T6Threaded_ubFree :
    ∀ (seed : Nat),
      CallHarnessUBFreeThr seed t6File.tagDefs t6File "pick"
        [intValue 10] t6Fs := by
  intro seed
  refine kCallHarnessUBFreeThrHeap_of_wp (GF := CerbHeapS) seed
    t6File.tagDefs t6File "pick" [intValue 10] t6Fs t6Spec ?_
  intro η
  exact t6_wpK_thr seed

/-! ## The piecewise relative-chain SMOKE (arc-18 C1)

    A 3-round partial drive with the `chain` token: exercises the
    re-derived PIECEWISE chain assembler (endpoints tracked
    syntactically; premises kernel-deferred through
    `dnms_round_computed` — registry variant `computed`) on the t6
    fixture. `rchain_chainrel` is the iter_compose feed shape:
    ∀ fuel, app (dnms (fuel+3) …) (dRdy seed)
      = app (dnms fuel …) (rchain3 seed) — the ∀-fuel relative block
    equation T5-by-invariant's loop composition consumes (C3). The
    sweep is the cone witness (trio-clean like every minted
    artifact); the emission itself is the smoke. -/

derive_rounds rchain (seed : Nat) using (t6File.tagDefs) 0
  from (dRdy seed) upto 3 chain

end RelSem.T6
