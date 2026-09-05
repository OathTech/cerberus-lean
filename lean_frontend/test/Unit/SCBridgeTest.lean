/-
  SCBridgeTest — the PLANT for the SC instance's bridge check and race verdict
  (concurrency Phase 0, slice S3; charter docs/2026-09-04_concurrency-phase0-
  sc-charter.md section 4.4 "plant-tested in S3 by corrupting rf").

  The driver's `drive … CM_sc …` builds a candidate execution alongside the
  run and, at trace end, (1) reports the library's `data_races` as UB005 and
  (2) requires the library's SC consistency tree to hold (a failing leaf is
  `DErr_model_inconsistent (MI_sc_inconsistent leaf)`). Those two checks
  must be LOUD, not vacuous. This test builds candidate executions BY HAND
  through the same generated functions the driver calls:

    * a coherent single-thread execution (two SC stores then an SC load
      reading the LATER store) passes every leaf;
    * the same execution with `rf` CORRUPTED to the earlier store fails —
      and the failing leaf is named;
    * a two-thread non-atomic store/load pair with no asw edge IS a data
      race; with the asw edge it is not.

  Runtime test (the sets carry pointer values; kernel evaluation is not the
  point here — the driver's runtime path is).
-/
import Driver
import Core_run_aux_lemMeasureProofs
open Lem_Num Lem_Pervasives Lem_List Lem_Set Lem_Map Lem_Maybe Lem_Function
  Lem_Show Lem_Show_extra Lem_Bool Lem_Basic_classes Lem_Map_extra
  Lem_String_extra Lem_Num_extra Lem_Set_helpers Lem_Either Lem_Assert_extra
  Lem_Set_extra Lem_List_extra Lem_Relation Lem_Tuple Lem_String Lem_Word Mem

set_option autoImplicit false

namespace SCBridgeTest

def x : CerbMem.PointerValue := CerbMem.concretePtrval 1 4096
def y : CerbMem.PointerValue := CerbMem.concretePtrval 2 8192
def v : CerbMem.MemValue := .MVunspecified signed_int

def rel (l : List (action × action)) : Pset (action × action) := setFromListBy setElemCompare l
def acts (l : List action) : Pset action := setFromListBy setElemCompare l
def tids (l : List Nat) : Pset Nat := setFromListBy setElemCompare l

/-- thread 0: W1 ; W2 ; R (all seq_cst, same atomic location) -/
def w1 : action := .Store 1 0 .Seq_cst x v
def w2 : action := .Store 2 0 .Seq_cst x v
def r  : action := .Load 3 0 .Seq_cst x v

def pre1 : pre_execution :=
  { actions := acts [w1, w2, r], threads := tids [0], lk := fun _ => .Atomic0,
    sb := rel [(w1, w2), (w1, r), (w2, r)], asw := rel [], dd := rel [] }
/-- the coherent witness: R reads the mo-latest store -/
def witGood : execution_witness :=
  { empty_witness with rf := rel [(w2, r)], mo := rel [(w1, w2)], sc := rel [(w1, w2), (w1, r), (w2, r)] }
/-- THE PLANT: rf corrupted to the EARLIER store (coherence violation: W2 is sb-between) -/
def witBad : execution_witness := { witGood with rf := rel [(w1, r)] }

def candidate (pre : pre_execution) (wit : execution_witness) :
    pre_execution × execution_witness × relation_list :=
  (pre, wit, release_acquire_fenced_relations pre wit)
def leaves (pre : pre_execution) (wit : execution_witness) : List String :=
  sc_failing_leaves "sc_accesses_consistent_execution" sc_accesses_consistent_execution (candidate pre wit)

/-- two threads, a non-atomic store and a non-atomic load of the same location -/
def wn : action := .Store 4 0 .NA y v
def rn : action := .Load 5 1 .NA y v
def preRace : pre_execution :=
  { actions := acts [wn, rn], threads := tids [0, 1], lk := fun _ => .Non_Atomic,
    sb := rel [], asw := rel [], dd := rel [] }
def preSync : pre_execution := { preRace with asw := rel [(wn, rn)] }
def witRace : execution_witness := { empty_witness with rf := rel [(wn, rn)] }

/-! ## Sequential identity facts (concurrency Phase 0 S5; library home since S7)

  The statements live in `Core_run_aux_lemMeasureProofs` (library side, so the
  exemplar's `drive_after_setup` can use `add_to_sb_sequential`); they are
  re-stated here as examples so the consumer-facing list is in one place with
  the plant. Every concurrency hook is the identity under `CM_sequential`. -/
section SequentialIdentity
open Core_run_aux_lemMeasureProofs

example (p_aids) (ctx) : add_to_sb_ctx CM_sequential p_aids ctx = ctx := add_to_sb_ctx_sequential p_aids ctx
example (aids) (ctx) : add_to_asw_ctx CM_sequential aids ctx = ctx := add_to_asw_ctx_sequential aids ctx
example (p_aids) (st) : add_to_sb_stack CM_sequential p_aids st = st := add_to_sb_stack_sequential p_aids st
example (aids) (st) : add_to_asw_stack CM_sequential aids st = st := add_to_asw_stack_sequential aids st
example (p_aids) (g : generic_expr core_run_annotation Unit sym) : add_to_sb CM_sequential p_aids g = g := add_to_sb_sequential p_aids g
example (aids) (g : generic_expr core_run_annotation Unit sym) : add_to_asw CM_sequential aids g = g := add_to_asw_sequential aids g

end SequentialIdentity

def check (name : String) (ok : Bool) (detail : String) : IO Bool := do
  IO.println s!"test: {name}"
  if ok then IO.println "  ✓ PASS" else IO.println s!"  ✗ FAIL — {detail}"
  return ok

def main : IO UInt32 := do
  let mut passed := 0
  let mut failed := 0
  let lGood := leaves pre1 witGood
  let lBad  := leaves pre1 witBad
  let raceR := setToList (data_races (candidate preRace witRace))
  let raceS := setToList (data_races (candidate preSync witRace))
  for res in [
      ← check "coherent SC execution passes every consistency leaf" lGood.isEmpty s!"failing leaves: {lGood}",
      ← check "PLANT: rf corrupted to the earlier store FAILS the tree (named leaf)" (!lBad.isEmpty) "no leaf failed — the bridge check is VACUOUS",
      ← check "PLANT names a coherence leaf" (lBad.any (fun s => s == "sc_accesses_sc_reads_restricted" || s == "coherent_memory_use" || s == "consistent_atomic_rf")) s!"leaves: {lBad}",
      ← check "unsynchronised NA store/load across threads IS a data race" (!raceR.isEmpty) "data_races returned empty — the race verdict is VACUOUS",
      ← check "the same pair ordered by asw is race-free" raceS.isEmpty s!"races: {raceS.length}" ] do
    if res then passed := passed + 1 else failed := failed + 1
  IO.println s!"  (plant's failing leaves: {lBad})"
  IO.println s!"\n{passed} passed, {failed} failed"
  return if failed == 0 then 0 else 1

end SCBridgeTest

def main : IO UInt32 := SCBridgeTest.main
