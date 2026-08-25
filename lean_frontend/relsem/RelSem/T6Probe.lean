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

  House rules: no sorry, no axioms. Under the in-build audit.
-/

import RelSem.Threaded
import RelSem.PerStepTactics
import RelSem.PerStepOwnP
import RelSem.DeriveState
import RelSem.RoundEval
import RelSem.ConstructLaws
import RelSem.SlateFiles

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

/-! ## The statement-facing route: the per-step WP walk, discharged
    through the threaded adequacy bridges (the T1Threaded template) -/

/-- T6's WP over the per-step instance at the THREADED initial state
    (all feeds are mints, construct-law instantiations, or the
    evaluator's whole-run equation). -/
theorem t6_wpK_thr {GF : BundledGFunctors} [CerbGpreS GF]
    [CerbGS .hasLC GF] (seed : Nat) :
    (stateIs (GF := GF) (initial_driver_state_threaded seed t6File t6Fs)) ⊢
      WP (callK t6File.tagDefs t6File "pick" [intValue 10])
        @ Stuckness.NotStuck ; ⊤
        {{ o, ⌜∃ r : driver_result, o = Outcome.value r ∧ t6Spec r⌝ }} := by
  iintro Hst
  wp_step (dG_app seed) Hst
  wp_step (app_nd_get (dG seed)) Hst
  wp_step (kRes seed) Hst
  wp_step (kBody seed) Hst
  wp_step (kTys seed) Hst
  wp_step (t6_inject seed) Hst
  wp_step (RelSem.Laws.get_ths_eq (dInj seed)) Hst
  wp_step (t6_errno seed) Hst
  wp_step (RelSem.Laws.driver_update_ts 0 _ (dErr seed) (by rfl)) Hst
  wp_step (r_driver seed) Hst
  wp_step (app_nd_get (r_fin seed)) Hst
  wp_done
  ipureintro
  exact ⟨_, rfl, t6_result_eq seed⟩

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
    the S1 acceptance probe's theorem, landed). -/
theorem T6Threaded : T6ThreadedStatement := by
  intro seed
  refine kCallHarnessAdequateThr_of_wp (GF := CerbS) seed
    t6File.tagDefs t6File "pick" [intValue 10] t6Fs t6Spec ?_
  intro η
  exact t6_wpK_thr seed

/-- **T6 THREADED UB-freedom** (same route). -/
theorem T6Threaded_ubFree :
    ∀ (seed : Nat),
      CallHarnessUBFreeThr seed t6File.tagDefs t6File "pick"
        [intValue 10] t6Fs := by
  intro seed
  refine kCallHarnessUBFreeThr_of_wp (GF := CerbS) seed
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
