/-
  RelSem.T6Probe — arc-17 S1 (2026-08-24/25): THE ACCEPTANCE PROBE,
  PARKED AT ITS MEASURED FRONTIER (the charter's stop clause).

  NOT IN THE BUILD (deliberately absent from lakefile roots /
  RelSemAll / Audit): the file is a reproducible record of how far
  the zero-fixture-equation probe reached and of the precise
  machinery gap that stops it — run `scripts/capped lake lean` on it
  (green, ~18 s) to reproduce the frontier. Full account: the S1
  record (docs/2026-08-25_arc17-s1-equation-frontier.md, acceptance-
  probe section).

  Fixture: tests/verify/t6_branch.c (branch + arithmetic + scalar
  locals; oracle-pinned, drift-gated, 4 harness expectation points,
  slate concrete points in EmitLeanCoreTest). What stands VERIFIED
  here: the statement data, the S0-emitter stage mints (globals /
  resolve / body / param-tys), the named-state ladder, and the
  mechanical per-round successor mints for the run's first seven
  (pure) rounds — ZERO fixture-specific equation lemmas anywhere.
  The park frontier (round 8, the first memory round) is documented
  at the bottom with its measurements.

  House rules: no sorry, no axioms.
-/

import RelSem.Threaded
import RelSem.PerStepTactics
import RelSem.DeriveState
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

/-- A loaded specified integer value (the shared T1AppEq spelling,
    restated to keep this file fixture-import-free). -/
def loadedV (v : Int) : value :=
  Vloaded (LVspecified (OVinteger (CerbMem.IntegerValue.IV .Prov_none v)))

/-- T6's pure spec on driver results: pick(10) = 10 - 3 = 7,
    Specified. -/
def t6Spec (r : driver_result) : Prop :=
  r.dres_core_value = intValue 7

/-! ## Fixture data (addresses, bytes, memory states — DATA, not
    equations; the LP64 allocator is deterministic from the initial
    state, same layout family as every scalar fixture) -/

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

/-- Bytemap after the argument's alloc+store (overwrite-chain
    spelling — the defeq-faithful shape). -/
def bmX : Std.TreeMap Int CerbMem.AbsByte :=
  ((((((( Std.TreeMap.empty.insert xAddr uninitByte).insert
    (xAddr+1) uninitByte).insert (xAddr+2) uninitByte).insert
    (xAddr+3) uninitByte).insert xAddr (mkByte 10 0)).insert
    (xAddr+1) (mkByte 10 1)).insert (xAddr+2) (mkByte 10 2)).insert
    (xAddr+3) (mkByte 10 3)

/-- Bytemap after the errno alloc+zero-store. -/
def bmD3 : Std.TreeMap Int CerbMem.AbsByte :=
  ((((((( bmX.insert errAddr uninitByte).insert
    (errAddr+1) uninitByte).insert (errAddr+2) uninitByte).insert
    (errAddr+3) uninitByte).insert errAddr (mkByte 0 0)).insert
    (errAddr+1) (mkByte 0 1)).insert (errAddr+2) (mkByte 0 2)).insert
    (errAddr+3) (mkByte 0 3)

/-- Memory after the argument injection. -/
def memInj : CerbMem.MemState :=
  { CerbMem.initialMemState with
    nextAllocId := 1, lastAddress := xAddr,
    allocations := Std.TreeMap.empty.insert 0 allocX,
    bytemap := bmX }

/-- Memory after the errno block (the pre-run memory). -/
def memD3 : CerbMem.MemState :=
  { CerbMem.initialMemState with
    nextAllocId := 2, lastAddress := errAddr,
    allocations := (Std.TreeMap.empty.insert 0 allocX).insert 1 allocErr,
    bytemap := bmD3 }

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

/-- Round 1 successor (minted; the create of `t`). -/
derive_state_step r1 (seed : Nat)
  from (advance_step t6File.tagDefs 0
    (RelSem.Laws.stepAt t6File.tagDefs 0 (dRdy seed)))
  at (dRdy seed)

/-- Round 2 successor (minted). -/
derive_state_step r2 (seed : Nat)
  from (advance_step t6File.tagDefs 0
    (RelSem.Laws.stepAt t6File.tagDefs 0 (r1 seed)))
  at (r1 seed)

/-- Round 3 successor (minted). -/
derive_state_step r3 (seed : Nat)
  from (advance_step t6File.tagDefs 0
    (RelSem.Laws.stepAt t6File.tagDefs 0 (r2 seed)))
  at (r2 seed)

/-- Round 4 successor (minted). -/
derive_state_step r4 (seed : Nat)
  from (advance_step t6File.tagDefs 0
    (RelSem.Laws.stepAt t6File.tagDefs 0 (r3 seed)))
  at (r3 seed)

/-- Round 5 successor (minted). -/
derive_state_step r5 (seed : Nat)
  from (advance_step t6File.tagDefs 0
    (RelSem.Laws.stepAt t6File.tagDefs 0 (r4 seed)))
  at (r4 seed)

/-- Round 6 successor (minted). -/
derive_state_step r6 (seed : Nat)
  from (advance_step t6File.tagDefs 0
    (RelSem.Laws.stepAt t6File.tagDefs 0 (r5 seed)))
  at (r5 seed)

/-- Round 7 successor (minted). -/
derive_state_step r7 (seed : Nat)
  from (advance_step t6File.tagDefs 0
    (RelSem.Laws.stepAt t6File.tagDefs 0 (r6 seed)))
  at (r6 seed)

/-! ## The harness prefix (parked evidence note)

    The full harness-prefix WP walk — 9 `wp_step`s: the minted stage
    equations above + `Laws.inject_ptr_arg1` / `Laws.get_ths_eq` /
    `Laws.callND_errno` / `Laws.driver_update_ts` with Kit mem-block
    facts at this file's literals — elaborated to `stateIs (dRdy
    seed)` with the loop atom exposed (goal-display transcript in the
    S1 record). It is not committed here because its tail (the loop
    equation) is exactly the parked frontier below; standalone
    `example` forms of the memory-stage instantiations cross the
    default heartbeat budget on the `hout` recast direction
    (literal-vs-computed memory defeq — same cost family as the
    frontier). No heartbeat bump taken, per doctrine. -/

/-! ## THE PARK FRONTIER (arc-17 S1; the acceptance probe's stop point)

    Round 8 is the first MEMORY round (`Step_action_request2`, the
    store of `t`'s initializer). Its mechanical mint is the measured
    wall — reproducer (uncomment to reproduce; run via
    `scripts/capped lake lean` and expect the blast-radius kill):

    derive_state_step r8 (seed : Nat)
      from (advance_step t6File.tagDefs 0
        (RelSem.Laws.stepAt t6File.tagDefs 0 (r7 seed)))
      at (r7 seed)

    Measured (2026-08-25, this worktree):
    * meta-whnf of the store round's successor allocates past the
      64 G blast-radius cap at BOTH `.default` and `.all`
      transparency (single command; capped cgroup kill at ~75 s);
    * an all-projection body design instead crosses the default
      heartbeat budget by round 5 (exponential recompute, no
      memoization);
    * the run's ground truth (compiled runner, seed 0):
      44 advancing rounds + terminal, final value Specified(7).

    The pure-round frontier (rounds 1–7 + the full harness-prefix
    walk below) elaborates in ~17 s with ZERO fixture-specific
    equations. The gap is S0-emitter-class machinery — a law-driven
    successor evaluator for memory rounds (compute the post-state
    through the Kit mem-block laws instead of raw whnf; the
    HeapLang-ProofMode architecture) — registered in the S1 record
    as an S2 input. -/

end RelSem.T6
