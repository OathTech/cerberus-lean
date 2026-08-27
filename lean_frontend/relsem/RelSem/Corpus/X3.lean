/-
  RelSem.Corpus.X3 — arc-18 R6 batch 4 (2026-08-27): EDGE-tier x3 (the call rule).

  ***PARKED (design finding, [F5] park-not-grind; NOT in the build —
  no lakefile root, no RelSemAll/Audit import).*** THE CALL-RULE
  FRONTIER, measured to its root cause:
    1. FIXED (landed): EmitLeanCore lacked OVpointer/PVfunction and
       PEerror arms (function designators + params_nth's error arm).
    2. FIXED (landed): the pruned slate stdlib lacks the ccall
       protocol's functions — `x3Stdlib` (SlateFiles) extends the t1
       closure with params_length/_aux/params_nth (emitted from
       std.core; existing fixtures' file VALUES untouched).
    3. OPEN (the parked wall — THE ROOT CAUSE): round 12, the
       function-pointer compatibility check. Core_eval's
       PEare_compatible arm calls `AilTypesAux.are_compatible`,
       which is a generated **`partial def`** — KERNEL-OPAQUE: no
       whnf, no rfl, no law can be proved about it in-logic. Every
       internal function call crosses this check, so NO two-function
       program can be minted until it is totalized (the
       no-internal-trust-gaps doctrine's standard move: lem-side
       fuel-totalization or a `declare lean target_rep` to a
       hand-written total mirror — the CerbCtypeInstances pattern —
       + lean-prelude-src regen + sync/drift gates). Priced M as a
       dedicated slice. The FnSpec/Summary.consume worked instance
       (charter R6 item) and the lock-shaped ownership-transfer
       example (x5) BOTH wait on this slice — recorded as the
       campaign's second vocabulary frontier (first: the array lane,
       Corpus/C9.lean).
  The fixture (.c/.core, x3File assembly, harness points at
  twice(5)=12 / inc3(7)=10) is oracle-green and stays as the
  reproducer; this module compiles through round 11.

  tests/verify/x3_call.c — TWO FUNCTIONS: `int twice(int y)` calls
  `int inc3(int x)` (the charter's R6 call-rule row). The harness
  designates `twice`; the run crosses the ccall/return protocol
  (function-designator metadata, caller-allocated argument object,
  Step_ccall2 frame push, callee body, TSK_Return pop).

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

namespace RelSem.X3

open RelSem RelSem.Cerb RelSem.Slate RelSem.Kit
open Lem_Basic_classes (ordCompare)

/-! ## Fixture data (symbols, addresses, byte images) -/

def symN : sym := Symbol "" 16978132545290669629 (SD_Id "y")

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
def twiceBody : generic_expr core_run_annotation Unit sym :=
  match fmapLookupBy (fun (s1 s2 : sym) => ordCompare s1 s2) twiceX3Sym
      x3File.funs with
  | some (Proc _ _ _ _ e) => e
  | _ => Expr [] (Epure (Pexpr [] () (PEval Vunit)))

/-- The ready thread (arena = lead_digit's body; n bound). -/
def thRdy : thread_state :=
  { arena := twiceBody,
    stack0 := Stack_empty,
    errno := errPtr,
    current_loc := CerbLocation.other "RelSem.callND",
    exec_loc := ELoc_normal [(twiceX3Sym, CerbLocation.other "RelSem.callND")],
    env := [fmapAddBy (fun (s1 s2 : sym) => ordCompare s1 s2) symN
      (Vobject (OVpointer nPtr)) fmapEmpty],
    current_proc_opt := some twiceX3Sym }

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
  { core_file := x3File,
    core_extern := create_extern_symmap x3File,
    core_state0 :=
      { thread_states := [(0, (none, thRdy))],
        io := initial_io_state },
    core_run_state0 :=
      { tid_supply := 1, aid_supply := aid, excluded_supply := exc,
        sym_supply := symc,
        labeled := (initial_core_run_state_threaded 0
          (collect_labeled_continuations_NEW x3File)).labeled },
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
  (hdig : CerberusFresh.digest () = "")
  (hscB : symc < 1152921504606846976)
  (hexcB : exc < 1152921504606846976)
  (halN : am.get? 0 = some allocN)
  (hrdN : CerbMem.readBytesFrom (memRdy bm am) nAddr 4 = i32 5)
  (hbuilt : RelSem.Kit.FmapBuilt RelSem.Kit.symCmpO
    (fmapAddBy (fun (s1 s2 : sym) => ordCompare s1 s2) symN
      (Vobject (OVpointer nPtr)) fmapEmpty))
  assuming hdig hscB hexcB halN hrdN hbuilt
  fencing fmapAddBy fmapLookupBy CerbMem.writeBytesTo Std.TreeMap.insert Std.TreeMap.get? mkByte mk_conv_int mk_call_catch_exceptional_condition mk_wrapI
  using (x3File.tagDefs) 0 from (mkRdy bm am tr aid exc symc ctr) upto 300 chain builder

end RelSem.X3
