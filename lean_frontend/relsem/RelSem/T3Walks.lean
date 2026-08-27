/-
  RelSem.T3AppEq — arc-7 S5a (2026-08-20): THE T3 HARNESS APP EQUATION
  (roundtrip: create / store / load points-to / kill), by the T1/T2
  compositional discipline (D7/D8: no whole-run kernel reductions, no
  budget bumps).

  Discovery record (SlateProbe walk of `callND t3File "roundtrip"
  [intValue 42]`): prefix (globals → resolve/lookup → inject v@…648 →
  errno@…644 → thread update) + ONE driver2 iteration with
  TWENTY-THREE dnms rounds:
    R0  eval create operands (Civalignof)   R1  CreateRequest x@…640
    R2  Esseq tau (x)                       R3  eval PEsym v
    R4  Ewseq tau (a_526)                   R5  eval load operands
    R6  LoadRequest v (the roundtrip)       R7  Ebound/Eannot strip
    R8  Esseq tau (a_525)                   R9  eval Store operands
        (conv_loaded_int — range check #1)
    R10 StoreRequest x (byte write)         R11 Esseq collapse
    R12 tau                                 R13 eval PEsym x
    R14 Ewseq tau (a_527)                   R15 eval load-x operands
    R16 LoadRequest x (roundtrip #2)        R17 strip
    R18 Esseq tau (a_528) + eval kill operand ordering per probe
    R19 KillRequest x                       R20 kill-result collapse
    R21 eval Erun conv_loaded_int (range check #2) + jump
    R22 eval PEsym a_529                    R23 terminal [Step_done2 x]
  then pick → process (Step_done2) → prepare_exit → finalize.

  House rules: no sorry, no axioms, no Iris imports. Under the
  in-build audit (imported by RelSem.T3).
-/

import RelSem.SlateFiles
import RelSem.T1Walks
import RelSem.T2Walks
import RelSem.ConstructLaws

set_option autoImplicit false

namespace RelSem.T3

open RelSem RelSem.Cerb RelSem.Slate
open RelSem.T1 (aU intCty loadedV xIntV mkByte roundtrip_arith zeroByte
  uninitByte patUnit loadE RExpr
  sizeof_int_eq alignof_int_eq sizeof_intCty_eq z0 z1 z2 z3 z4
  convLoadedIntSym convIntSym isReprIntegerSym errStore_bytes_fact)
-- (arc-9 S2: the generic eval/round crossings moved to the Kit)
open RelSem.Kit (eubind_defined stub_defined eumapM_one
  liftCore_run_defined aux2_step aux2_done perform_unfold ars_load_unfold
  ars_create_unfold ars_store_unfold ars_kill_unfold)
open RelSem.T2 (storeArg_bytes_fact)

/-! ## Pinned symbols (from the pinned t3 Core program) -/

def symV : sym := Symbol "" 1965435164061188486 (SD_Id "v")
def symX : sym := Symbol "" 16562859848569467201 (SD_Id "x")
def symA525 : sym := Symbol "" 3579765898737599443 (SD_Id "a_525")
def symA526 : sym := Symbol "" 13429216386455784360 (SD_Id "a_526")
def symA527 : sym := Symbol "" 4139409277016632516 (SD_Id "a_527")
def symA528 : sym := Symbol "" 8935235297226827052 (SD_Id "a_528")
def symA529 : sym := Symbol "" 1680278659536745755 (SD_Id "a_529")
def symRet524 : sym := Symbol "" 14990978498630749272 (SD_Id "ret_524")

/-! ## Addresses / pointers (v's parameter object, errno, x's local) -/

def vAddr : Int := 281474976710648
def errAddr : Int := 281474976710644
def xAddr : Int := 281474976710640

def vPtr : CerbMem.PointerValue := .PV (.Prov_some 0) (.PVconcrete none vAddr)
def errPtr : CerbMem.PointerValue := .PV (.Prov_some 1) (.PVconcrete none errAddr)
def xPtr : CerbMem.PointerValue := .PV (.Prov_some 2) (.PVconcrete none xAddr)

def vPtrV : value := Vobject (OVpointer vPtr)
def xPtrV : value := Vobject (OVpointer xPtr)

/-! ## Arenas (probe-transcribed verbatim; the round rfls validate
    every transcription) -/

/-- Arena at state 0 (probe-transcribed verbatim). -/
def arena00 : RExpr :=
  (Expr aU (Esseq (Pattern aU (CaseBase (some symX, (BTy_object OTy_pointer)))) (Expr aU (Eaction (Paction Pos (Action CerbLocation.Loc.unknown empty_annotation (Create (Pexpr aU () (PEctor Civalignof [(Pexpr aU () (PEval (Vctype intCty)))])) (Pexpr aU () (PEval (Vctype intCty))) (PrefOther "Core")))))) (Expr aU (Esseq (Pattern aU (CaseBase (some symA525, (BTy_loaded OTy_integer)))) (Expr aU (Ebound (Expr aU (Ewseq (Pattern aU (CaseBase (some symA526, (BTy_object OTy_pointer)))) (Expr aU (Epure (Pexpr aU () (PEsym symV)))) (Expr aU (Eaction (Paction Pos (Action CerbLocation.Loc.unknown empty_annotation (Load0 (Pexpr aU () (PEval (Vctype intCty))) (Pexpr aU () (PEsym symA526)) NA))))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Eaction (Paction Pos (Action CerbLocation.Loc.unknown empty_annotation (Store0 false (Pexpr aU () (PEval (Vctype intCty))) (Pexpr aU () (PEsym symX)) (Pexpr aU () (PEcall (Sym convLoadedIntSym) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym symA525))])) NA))))) (Expr aU (Esseq (Pattern aU (CaseBase (some symA528, (BTy_loaded OTy_integer)))) (Expr aU (Ebound (Expr aU (Ewseq (Pattern aU (CaseBase (some symA527, (BTy_object OTy_pointer)))) (Expr aU (Epure (Pexpr aU () (PEsym symX)))) (Expr aU (Eaction (Paction Pos (Action CerbLocation.Loc.unknown empty_annotation (Load0 (Pexpr aU () (PEval (Vctype intCty))) (Pexpr aU () (PEsym symA527)) NA))))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Eaction (Paction Pos (Action CerbLocation.Loc.unknown empty_annotation (Kill (Static0 intCty) (Pexpr aU () (PEsym symX))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Erun empty_annotation symRet524 [(Pexpr aU () (PEcall (Sym convLoadedIntSym) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym symA528))]))])) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Eaction (Paction Pos (Action CerbLocation.Loc.unknown empty_annotation (Kill (Static0 intCty) (Pexpr aU () (PEsym symX))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Epure (Pexpr aU () (PEval Vunit)))) (Expr aU (Esave (symRet524, (BTy_loaded OTy_integer)) [(symA529, (((BTy_loaded OTy_integer), none), (Pexpr aU () (PEundef CerbLocation.Loc.unknown UB088_reached_end_of_function))))] (Expr aU (Epure (Pexpr aU () (PEsym symA529))))))))))))))))))))))

/-- Arena at state 1 (probe-transcribed verbatim). -/
def arena01 : RExpr :=
  (Expr aU (Esseq (Pattern aU (CaseBase (some symX, (BTy_object OTy_pointer)))) (Expr aU (Eaction (Paction Pos (Action CerbLocation.Loc.unknown empty_annotation (Create (Pexpr [] () (PEval (Vobject (OVinteger (.IV .Prov_none 4))))) (Pexpr [] () (PEval (Vctype intCty))) (PrefOther "Core")))))) (Expr aU (Esseq (Pattern aU (CaseBase (some symA525, (BTy_loaded OTy_integer)))) (Expr aU (Ebound (Expr aU (Ewseq (Pattern aU (CaseBase (some symA526, (BTy_object OTy_pointer)))) (Expr aU (Epure (Pexpr aU () (PEsym symV)))) (Expr aU (Eaction (Paction Pos (Action CerbLocation.Loc.unknown empty_annotation (Load0 (Pexpr aU () (PEval (Vctype intCty))) (Pexpr aU () (PEsym symA526)) NA))))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Eaction (Paction Pos (Action CerbLocation.Loc.unknown empty_annotation (Store0 false (Pexpr aU () (PEval (Vctype intCty))) (Pexpr aU () (PEsym symX)) (Pexpr aU () (PEcall (Sym convLoadedIntSym) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym symA525))])) NA))))) (Expr aU (Esseq (Pattern aU (CaseBase (some symA528, (BTy_loaded OTy_integer)))) (Expr aU (Ebound (Expr aU (Ewseq (Pattern aU (CaseBase (some symA527, (BTy_object OTy_pointer)))) (Expr aU (Epure (Pexpr aU () (PEsym symX)))) (Expr aU (Eaction (Paction Pos (Action CerbLocation.Loc.unknown empty_annotation (Load0 (Pexpr aU () (PEval (Vctype intCty))) (Pexpr aU () (PEsym symA527)) NA))))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Eaction (Paction Pos (Action CerbLocation.Loc.unknown empty_annotation (Kill (Static0 intCty) (Pexpr aU () (PEsym symX))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Erun empty_annotation symRet524 [(Pexpr aU () (PEcall (Sym convLoadedIntSym) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym symA528))]))])) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Eaction (Paction Pos (Action CerbLocation.Loc.unknown empty_annotation (Kill (Static0 intCty) (Pexpr aU () (PEsym symX))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Epure (Pexpr aU () (PEval Vunit)))) (Expr aU (Esave (symRet524, (BTy_loaded OTy_integer)) [(symA529, (((BTy_loaded OTy_integer), none), (Pexpr aU () (PEundef CerbLocation.Loc.unknown UB088_reached_end_of_function))))] (Expr aU (Epure (Pexpr aU () (PEsym symA529))))))))))))))))))))))

/-- Arena at state 2 (probe-transcribed verbatim). -/
def arena02 : RExpr :=
  (Expr aU (Esseq (Pattern aU (CaseBase (some symX, (BTy_object OTy_pointer)))) (Expr [] (Epure (Pexpr [] () (PEval xPtrV)))) (Expr aU (Esseq (Pattern aU (CaseBase (some symA525, (BTy_loaded OTy_integer)))) (Expr aU (Ebound (Expr aU (Ewseq (Pattern aU (CaseBase (some symA526, (BTy_object OTy_pointer)))) (Expr aU (Epure (Pexpr aU () (PEsym symV)))) (Expr aU (Eaction (Paction Pos (Action CerbLocation.Loc.unknown empty_annotation (Load0 (Pexpr aU () (PEval (Vctype intCty))) (Pexpr aU () (PEsym symA526)) NA))))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Eaction (Paction Pos (Action CerbLocation.Loc.unknown empty_annotation (Store0 false (Pexpr aU () (PEval (Vctype intCty))) (Pexpr aU () (PEsym symX)) (Pexpr aU () (PEcall (Sym convLoadedIntSym) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym symA525))])) NA))))) (Expr aU (Esseq (Pattern aU (CaseBase (some symA528, (BTy_loaded OTy_integer)))) (Expr aU (Ebound (Expr aU (Ewseq (Pattern aU (CaseBase (some symA527, (BTy_object OTy_pointer)))) (Expr aU (Epure (Pexpr aU () (PEsym symX)))) (Expr aU (Eaction (Paction Pos (Action CerbLocation.Loc.unknown empty_annotation (Load0 (Pexpr aU () (PEval (Vctype intCty))) (Pexpr aU () (PEsym symA527)) NA))))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Eaction (Paction Pos (Action CerbLocation.Loc.unknown empty_annotation (Kill (Static0 intCty) (Pexpr aU () (PEsym symX))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Erun empty_annotation symRet524 [(Pexpr aU () (PEcall (Sym convLoadedIntSym) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym symA528))]))])) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Eaction (Paction Pos (Action CerbLocation.Loc.unknown empty_annotation (Kill (Static0 intCty) (Pexpr aU () (PEsym symX))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Epure (Pexpr aU () (PEval Vunit)))) (Expr aU (Esave (symRet524, (BTy_loaded OTy_integer)) [(symA529, (((BTy_loaded OTy_integer), none), (Pexpr aU () (PEundef CerbLocation.Loc.unknown UB088_reached_end_of_function))))] (Expr aU (Epure (Pexpr aU () (PEsym symA529))))))))))))))))))))))

/-- Arena at state 3 (probe-transcribed verbatim). -/
def arena03 : RExpr :=
  (Expr aU (Esseq (Pattern aU (CaseBase (some symA525, (BTy_loaded OTy_integer)))) (Expr aU (Ebound (Expr aU (Ewseq (Pattern aU (CaseBase (some symA526, (BTy_object OTy_pointer)))) (Expr aU (Epure (Pexpr aU () (PEsym symV)))) (Expr aU (Eaction (Paction Pos (Action CerbLocation.Loc.unknown empty_annotation (Load0 (Pexpr aU () (PEval (Vctype intCty))) (Pexpr aU () (PEsym symA526)) NA))))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Eaction (Paction Pos (Action CerbLocation.Loc.unknown empty_annotation (Store0 false (Pexpr aU () (PEval (Vctype intCty))) (Pexpr aU () (PEsym symX)) (Pexpr aU () (PEcall (Sym convLoadedIntSym) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym symA525))])) NA))))) (Expr aU (Esseq (Pattern aU (CaseBase (some symA528, (BTy_loaded OTy_integer)))) (Expr aU (Ebound (Expr aU (Ewseq (Pattern aU (CaseBase (some symA527, (BTy_object OTy_pointer)))) (Expr aU (Epure (Pexpr aU () (PEsym symX)))) (Expr aU (Eaction (Paction Pos (Action CerbLocation.Loc.unknown empty_annotation (Load0 (Pexpr aU () (PEval (Vctype intCty))) (Pexpr aU () (PEsym symA527)) NA))))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Eaction (Paction Pos (Action CerbLocation.Loc.unknown empty_annotation (Kill (Static0 intCty) (Pexpr aU () (PEsym symX))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Erun empty_annotation symRet524 [(Pexpr aU () (PEcall (Sym convLoadedIntSym) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym symA528))]))])) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Eaction (Paction Pos (Action CerbLocation.Loc.unknown empty_annotation (Kill (Static0 intCty) (Pexpr aU () (PEsym symX))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Epure (Pexpr aU () (PEval Vunit)))) (Expr aU (Esave (symRet524, (BTy_loaded OTy_integer)) [(symA529, (((BTy_loaded OTy_integer), none), (Pexpr aU () (PEundef CerbLocation.Loc.unknown UB088_reached_end_of_function))))] (Expr aU (Epure (Pexpr aU () (PEsym symA529))))))))))))))))))))

/-- Arena at state 4 (probe-transcribed verbatim). -/
def arena04 : RExpr :=
  (Expr aU (Esseq (Pattern aU (CaseBase (some symA525, (BTy_loaded OTy_integer)))) (Expr aU (Ebound (Expr aU (Ewseq (Pattern aU (CaseBase (some symA526, (BTy_object OTy_pointer)))) (Expr aU (Epure (Pexpr [] () (PEval vPtrV)))) (Expr aU (Eaction (Paction Pos (Action CerbLocation.Loc.unknown empty_annotation (Load0 (Pexpr aU () (PEval (Vctype intCty))) (Pexpr aU () (PEsym symA526)) NA))))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Eaction (Paction Pos (Action CerbLocation.Loc.unknown empty_annotation (Store0 false (Pexpr aU () (PEval (Vctype intCty))) (Pexpr aU () (PEsym symX)) (Pexpr aU () (PEcall (Sym convLoadedIntSym) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym symA525))])) NA))))) (Expr aU (Esseq (Pattern aU (CaseBase (some symA528, (BTy_loaded OTy_integer)))) (Expr aU (Ebound (Expr aU (Ewseq (Pattern aU (CaseBase (some symA527, (BTy_object OTy_pointer)))) (Expr aU (Epure (Pexpr aU () (PEsym symX)))) (Expr aU (Eaction (Paction Pos (Action CerbLocation.Loc.unknown empty_annotation (Load0 (Pexpr aU () (PEval (Vctype intCty))) (Pexpr aU () (PEsym symA527)) NA))))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Eaction (Paction Pos (Action CerbLocation.Loc.unknown empty_annotation (Kill (Static0 intCty) (Pexpr aU () (PEsym symX))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Erun empty_annotation symRet524 [(Pexpr aU () (PEcall (Sym convLoadedIntSym) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym symA528))]))])) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Eaction (Paction Pos (Action CerbLocation.Loc.unknown empty_annotation (Kill (Static0 intCty) (Pexpr aU () (PEsym symX))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Epure (Pexpr aU () (PEval Vunit)))) (Expr aU (Esave (symRet524, (BTy_loaded OTy_integer)) [(symA529, (((BTy_loaded OTy_integer), none), (Pexpr aU () (PEundef CerbLocation.Loc.unknown UB088_reached_end_of_function))))] (Expr aU (Epure (Pexpr aU () (PEsym symA529))))))))))))))))))))

/-- Arena at state 5 (probe-transcribed verbatim). -/
def arena05 : RExpr :=
  (Expr aU (Esseq (Pattern aU (CaseBase (some symA525, (BTy_loaded OTy_integer)))) (Expr aU (Ebound (Expr aU (Eaction (Paction Pos (Action CerbLocation.Loc.unknown empty_annotation (Load0 (Pexpr aU () (PEval (Vctype intCty))) (Pexpr aU () (PEsym symA526)) NA))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Eaction (Paction Pos (Action CerbLocation.Loc.unknown empty_annotation (Store0 false (Pexpr aU () (PEval (Vctype intCty))) (Pexpr aU () (PEsym symX)) (Pexpr aU () (PEcall (Sym convLoadedIntSym) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym symA525))])) NA))))) (Expr aU (Esseq (Pattern aU (CaseBase (some symA528, (BTy_loaded OTy_integer)))) (Expr aU (Ebound (Expr aU (Ewseq (Pattern aU (CaseBase (some symA527, (BTy_object OTy_pointer)))) (Expr aU (Epure (Pexpr aU () (PEsym symX)))) (Expr aU (Eaction (Paction Pos (Action CerbLocation.Loc.unknown empty_annotation (Load0 (Pexpr aU () (PEval (Vctype intCty))) (Pexpr aU () (PEsym symA527)) NA))))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Eaction (Paction Pos (Action CerbLocation.Loc.unknown empty_annotation (Kill (Static0 intCty) (Pexpr aU () (PEsym symX))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Erun empty_annotation symRet524 [(Pexpr aU () (PEcall (Sym convLoadedIntSym) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym symA528))]))])) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Eaction (Paction Pos (Action CerbLocation.Loc.unknown empty_annotation (Kill (Static0 intCty) (Pexpr aU () (PEsym symX))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Epure (Pexpr aU () (PEval Vunit)))) (Expr aU (Esave (symRet524, (BTy_loaded OTy_integer)) [(symA529, (((BTy_loaded OTy_integer), none), (Pexpr aU () (PEundef CerbLocation.Loc.unknown UB088_reached_end_of_function))))] (Expr aU (Epure (Pexpr aU () (PEsym symA529))))))))))))))))))))

/-- Arena at state 6 (probe-transcribed verbatim). -/
def arena06 : RExpr :=
  (Expr aU (Esseq (Pattern aU (CaseBase (some symA525, (BTy_loaded OTy_integer)))) (Expr aU (Ebound (Expr aU (Eaction (Paction Pos (Action CerbLocation.Loc.unknown empty_annotation (Load0 (Pexpr [] () (PEval (Vctype intCty))) (Pexpr [] () (PEval vPtrV)) NA))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Eaction (Paction Pos (Action CerbLocation.Loc.unknown empty_annotation (Store0 false (Pexpr aU () (PEval (Vctype intCty))) (Pexpr aU () (PEsym symX)) (Pexpr aU () (PEcall (Sym convLoadedIntSym) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym symA525))])) NA))))) (Expr aU (Esseq (Pattern aU (CaseBase (some symA528, (BTy_loaded OTy_integer)))) (Expr aU (Ebound (Expr aU (Ewseq (Pattern aU (CaseBase (some symA527, (BTy_object OTy_pointer)))) (Expr aU (Epure (Pexpr aU () (PEsym symX)))) (Expr aU (Eaction (Paction Pos (Action CerbLocation.Loc.unknown empty_annotation (Load0 (Pexpr aU () (PEval (Vctype intCty))) (Pexpr aU () (PEsym symA527)) NA))))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Eaction (Paction Pos (Action CerbLocation.Loc.unknown empty_annotation (Kill (Static0 intCty) (Pexpr aU () (PEsym symX))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Erun empty_annotation symRet524 [(Pexpr aU () (PEcall (Sym convLoadedIntSym) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym symA528))]))])) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Eaction (Paction Pos (Action CerbLocation.Loc.unknown empty_annotation (Kill (Static0 intCty) (Pexpr aU () (PEsym symX))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Epure (Pexpr aU () (PEval Vunit)))) (Expr aU (Esave (symRet524, (BTy_loaded OTy_integer)) [(symA529, (((BTy_loaded OTy_integer), none), (Pexpr aU () (PEundef CerbLocation.Loc.unknown UB088_reached_end_of_function))))] (Expr aU (Epure (Pexpr aU () (PEsym symA529))))))))))))))))))))

/-- Arena at state 7 (probe-transcribed verbatim). -/
def arena07 (x : Int): RExpr :=
  (Expr aU (Esseq (Pattern aU (CaseBase (some symA525, (BTy_loaded OTy_integer)))) (Expr aU (Ebound (Expr [] (Eannot [(DA_pos [] (CerbMem.Footprint.FP .R 281474976710648 4))] (Expr [] (Epure (Pexpr [] () (PEval (loadedV x))))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Eaction (Paction Pos (Action CerbLocation.Loc.unknown empty_annotation (Store0 false (Pexpr aU () (PEval (Vctype intCty))) (Pexpr aU () (PEsym symX)) (Pexpr aU () (PEcall (Sym convLoadedIntSym) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym symA525))])) NA))))) (Expr aU (Esseq (Pattern aU (CaseBase (some symA528, (BTy_loaded OTy_integer)))) (Expr aU (Ebound (Expr aU (Ewseq (Pattern aU (CaseBase (some symA527, (BTy_object OTy_pointer)))) (Expr aU (Epure (Pexpr aU () (PEsym symX)))) (Expr aU (Eaction (Paction Pos (Action CerbLocation.Loc.unknown empty_annotation (Load0 (Pexpr aU () (PEval (Vctype intCty))) (Pexpr aU () (PEsym symA527)) NA))))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Eaction (Paction Pos (Action CerbLocation.Loc.unknown empty_annotation (Kill (Static0 intCty) (Pexpr aU () (PEsym symX))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Erun empty_annotation symRet524 [(Pexpr aU () (PEcall (Sym convLoadedIntSym) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym symA528))]))])) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Eaction (Paction Pos (Action CerbLocation.Loc.unknown empty_annotation (Kill (Static0 intCty) (Pexpr aU () (PEsym symX))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Epure (Pexpr aU () (PEval Vunit)))) (Expr aU (Esave (symRet524, (BTy_loaded OTy_integer)) [(symA529, (((BTy_loaded OTy_integer), none), (Pexpr aU () (PEundef CerbLocation.Loc.unknown UB088_reached_end_of_function))))] (Expr aU (Epure (Pexpr aU () (PEsym symA529))))))))))))))))))))

/-- Arena at state 8 (probe-transcribed verbatim). -/
def arena08 (x : Int): RExpr :=
  (Expr aU (Esseq (Pattern aU (CaseBase (some symA525, (BTy_loaded OTy_integer)))) (Expr [] (Epure (Pexpr [] () (PEval (loadedV x))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Eaction (Paction Pos (Action CerbLocation.Loc.unknown empty_annotation (Store0 false (Pexpr aU () (PEval (Vctype intCty))) (Pexpr aU () (PEsym symX)) (Pexpr aU () (PEcall (Sym convLoadedIntSym) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym symA525))])) NA))))) (Expr aU (Esseq (Pattern aU (CaseBase (some symA528, (BTy_loaded OTy_integer)))) (Expr aU (Ebound (Expr aU (Ewseq (Pattern aU (CaseBase (some symA527, (BTy_object OTy_pointer)))) (Expr aU (Epure (Pexpr aU () (PEsym symX)))) (Expr aU (Eaction (Paction Pos (Action CerbLocation.Loc.unknown empty_annotation (Load0 (Pexpr aU () (PEval (Vctype intCty))) (Pexpr aU () (PEsym symA527)) NA))))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Eaction (Paction Pos (Action CerbLocation.Loc.unknown empty_annotation (Kill (Static0 intCty) (Pexpr aU () (PEsym symX))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Erun empty_annotation symRet524 [(Pexpr aU () (PEcall (Sym convLoadedIntSym) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym symA528))]))])) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Eaction (Paction Pos (Action CerbLocation.Loc.unknown empty_annotation (Kill (Static0 intCty) (Pexpr aU () (PEsym symX))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Epure (Pexpr aU () (PEval Vunit)))) (Expr aU (Esave (symRet524, (BTy_loaded OTy_integer)) [(symA529, (((BTy_loaded OTy_integer), none), (Pexpr aU () (PEundef CerbLocation.Loc.unknown UB088_reached_end_of_function))))] (Expr aU (Epure (Pexpr aU () (PEsym symA529))))))))))))))))))))

/-- Arena at state 9 (probe-transcribed verbatim). -/
def arena09 : RExpr :=
  (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Eaction (Paction Pos (Action CerbLocation.Loc.unknown empty_annotation (Store0 false (Pexpr aU () (PEval (Vctype intCty))) (Pexpr aU () (PEsym symX)) (Pexpr aU () (PEcall (Sym convLoadedIntSym) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym symA525))])) NA))))) (Expr aU (Esseq (Pattern aU (CaseBase (some symA528, (BTy_loaded OTy_integer)))) (Expr aU (Ebound (Expr aU (Ewseq (Pattern aU (CaseBase (some symA527, (BTy_object OTy_pointer)))) (Expr aU (Epure (Pexpr aU () (PEsym symX)))) (Expr aU (Eaction (Paction Pos (Action CerbLocation.Loc.unknown empty_annotation (Load0 (Pexpr aU () (PEval (Vctype intCty))) (Pexpr aU () (PEsym symA527)) NA))))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Eaction (Paction Pos (Action CerbLocation.Loc.unknown empty_annotation (Kill (Static0 intCty) (Pexpr aU () (PEsym symX))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Erun empty_annotation symRet524 [(Pexpr aU () (PEcall (Sym convLoadedIntSym) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym symA528))]))])) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Eaction (Paction Pos (Action CerbLocation.Loc.unknown empty_annotation (Kill (Static0 intCty) (Pexpr aU () (PEsym symX))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Epure (Pexpr aU () (PEval Vunit)))) (Expr aU (Esave (symRet524, (BTy_loaded OTy_integer)) [(symA529, (((BTy_loaded OTy_integer), none), (Pexpr aU () (PEundef CerbLocation.Loc.unknown UB088_reached_end_of_function))))] (Expr aU (Epure (Pexpr aU () (PEsym symA529))))))))))))))))))

/-- Arena at state 10 (probe-transcribed verbatim). -/
def arena10 (x : Int): RExpr :=
  (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Eaction (Paction Pos (Action CerbLocation.Loc.unknown empty_annotation (Store0 false (Pexpr [] () (PEval (Vctype intCty))) (Pexpr [] () (PEval xPtrV)) (Pexpr [] () (PEval (loadedV x))) NA))))) (Expr aU (Esseq (Pattern aU (CaseBase (some symA528, (BTy_loaded OTy_integer)))) (Expr aU (Ebound (Expr aU (Ewseq (Pattern aU (CaseBase (some symA527, (BTy_object OTy_pointer)))) (Expr aU (Epure (Pexpr aU () (PEsym symX)))) (Expr aU (Eaction (Paction Pos (Action CerbLocation.Loc.unknown empty_annotation (Load0 (Pexpr aU () (PEval (Vctype intCty))) (Pexpr aU () (PEsym symA527)) NA))))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Eaction (Paction Pos (Action CerbLocation.Loc.unknown empty_annotation (Kill (Static0 intCty) (Pexpr aU () (PEsym symX))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Erun empty_annotation symRet524 [(Pexpr aU () (PEcall (Sym convLoadedIntSym) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym symA528))]))])) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Eaction (Paction Pos (Action CerbLocation.Loc.unknown empty_annotation (Kill (Static0 intCty) (Pexpr aU () (PEsym symX))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Epure (Pexpr aU () (PEval Vunit)))) (Expr aU (Esave (symRet524, (BTy_loaded OTy_integer)) [(symA529, (((BTy_loaded OTy_integer), none), (Pexpr aU () (PEundef CerbLocation.Loc.unknown UB088_reached_end_of_function))))] (Expr aU (Epure (Pexpr aU () (PEsym symA529))))))))))))))))))

/-- Arena at state 11 (probe-transcribed verbatim). -/
def arena11 : RExpr :=
  (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr [] (Eannot [(DA_pos [] (CerbMem.Footprint.FP .W 281474976710640 4))] (Expr [] (Epure (Pexpr [] () (PEval Vunit)))))) (Expr aU (Esseq (Pattern aU (CaseBase (some symA528, (BTy_loaded OTy_integer)))) (Expr aU (Ebound (Expr aU (Ewseq (Pattern aU (CaseBase (some symA527, (BTy_object OTy_pointer)))) (Expr aU (Epure (Pexpr aU () (PEsym symX)))) (Expr aU (Eaction (Paction Pos (Action CerbLocation.Loc.unknown empty_annotation (Load0 (Pexpr aU () (PEval (Vctype intCty))) (Pexpr aU () (PEsym symA527)) NA))))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Eaction (Paction Pos (Action CerbLocation.Loc.unknown empty_annotation (Kill (Static0 intCty) (Pexpr aU () (PEsym symX))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Erun empty_annotation symRet524 [(Pexpr aU () (PEcall (Sym convLoadedIntSym) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym symA528))]))])) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Eaction (Paction Pos (Action CerbLocation.Loc.unknown empty_annotation (Kill (Static0 intCty) (Pexpr aU () (PEsym symX))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Epure (Pexpr aU () (PEval Vunit)))) (Expr aU (Esave (symRet524, (BTy_loaded OTy_integer)) [(symA529, (((BTy_loaded OTy_integer), none), (Pexpr aU () (PEundef CerbLocation.Loc.unknown UB088_reached_end_of_function))))] (Expr aU (Epure (Pexpr aU () (PEsym symA529))))))))))))))))))

/-- Arena at state 12 (probe-transcribed verbatim). -/
def arena12 : RExpr :=
  (Expr [] (Eannot [(DA_pos [] (CerbMem.Footprint.FP .W 281474976710640 4))] (Expr aU (Esseq (Pattern aU (CaseBase (some symA528, (BTy_loaded OTy_integer)))) (Expr aU (Ebound (Expr aU (Ewseq (Pattern aU (CaseBase (some symA527, (BTy_object OTy_pointer)))) (Expr aU (Epure (Pexpr aU () (PEsym symX)))) (Expr aU (Eaction (Paction Pos (Action CerbLocation.Loc.unknown empty_annotation (Load0 (Pexpr aU () (PEval (Vctype intCty))) (Pexpr aU () (PEsym symA527)) NA))))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Eaction (Paction Pos (Action CerbLocation.Loc.unknown empty_annotation (Kill (Static0 intCty) (Pexpr aU () (PEsym symX))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Erun empty_annotation symRet524 [(Pexpr aU () (PEcall (Sym convLoadedIntSym) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym symA528))]))])) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Eaction (Paction Pos (Action CerbLocation.Loc.unknown empty_annotation (Kill (Static0 intCty) (Pexpr aU () (PEsym symX))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Epure (Pexpr aU () (PEval Vunit)))) (Expr aU (Esave (symRet524, (BTy_loaded OTy_integer)) [(symA529, (((BTy_loaded OTy_integer), none), (Pexpr aU () (PEundef CerbLocation.Loc.unknown UB088_reached_end_of_function))))] (Expr aU (Epure (Pexpr aU () (PEsym symA529))))))))))))))))))

/-- Arena at state 13 (probe-transcribed verbatim). -/
def arena13 : RExpr :=
  (Expr [] (Eannot [(DA_pos [] (CerbMem.Footprint.FP .W 281474976710640 4))] (Expr aU (Esseq (Pattern aU (CaseBase (some symA528, (BTy_loaded OTy_integer)))) (Expr aU (Ebound (Expr aU (Ewseq (Pattern aU (CaseBase (some symA527, (BTy_object OTy_pointer)))) (Expr aU (Epure (Pexpr [] () (PEval xPtrV)))) (Expr aU (Eaction (Paction Pos (Action CerbLocation.Loc.unknown empty_annotation (Load0 (Pexpr aU () (PEval (Vctype intCty))) (Pexpr aU () (PEsym symA527)) NA))))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Eaction (Paction Pos (Action CerbLocation.Loc.unknown empty_annotation (Kill (Static0 intCty) (Pexpr aU () (PEsym symX))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Erun empty_annotation symRet524 [(Pexpr aU () (PEcall (Sym convLoadedIntSym) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym symA528))]))])) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Eaction (Paction Pos (Action CerbLocation.Loc.unknown empty_annotation (Kill (Static0 intCty) (Pexpr aU () (PEsym symX))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Epure (Pexpr aU () (PEval Vunit)))) (Expr aU (Esave (symRet524, (BTy_loaded OTy_integer)) [(symA529, (((BTy_loaded OTy_integer), none), (Pexpr aU () (PEundef CerbLocation.Loc.unknown UB088_reached_end_of_function))))] (Expr aU (Epure (Pexpr aU () (PEsym symA529))))))))))))))))))

/-- Arena at state 14 (probe-transcribed verbatim). -/
def arena14 : RExpr :=
  (Expr [] (Eannot [(DA_pos [] (CerbMem.Footprint.FP .W 281474976710640 4))] (Expr aU (Esseq (Pattern aU (CaseBase (some symA528, (BTy_loaded OTy_integer)))) (Expr aU (Ebound (Expr aU (Eaction (Paction Pos (Action CerbLocation.Loc.unknown empty_annotation (Load0 (Pexpr aU () (PEval (Vctype intCty))) (Pexpr aU () (PEsym symA527)) NA))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Eaction (Paction Pos (Action CerbLocation.Loc.unknown empty_annotation (Kill (Static0 intCty) (Pexpr aU () (PEsym symX))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Erun empty_annotation symRet524 [(Pexpr aU () (PEcall (Sym convLoadedIntSym) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym symA528))]))])) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Eaction (Paction Pos (Action CerbLocation.Loc.unknown empty_annotation (Kill (Static0 intCty) (Pexpr aU () (PEsym symX))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Epure (Pexpr aU () (PEval Vunit)))) (Expr aU (Esave (symRet524, (BTy_loaded OTy_integer)) [(symA529, (((BTy_loaded OTy_integer), none), (Pexpr aU () (PEundef CerbLocation.Loc.unknown UB088_reached_end_of_function))))] (Expr aU (Epure (Pexpr aU () (PEsym symA529))))))))))))))))))

/-- Arena at state 15 (probe-transcribed verbatim). -/
def arena15 : RExpr :=
  (Expr [] (Eannot [(DA_pos [] (CerbMem.Footprint.FP .W 281474976710640 4))] (Expr aU (Esseq (Pattern aU (CaseBase (some symA528, (BTy_loaded OTy_integer)))) (Expr aU (Ebound (Expr aU (Eaction (Paction Pos (Action CerbLocation.Loc.unknown empty_annotation (Load0 (Pexpr [] () (PEval (Vctype intCty))) (Pexpr [] () (PEval xPtrV)) NA))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Eaction (Paction Pos (Action CerbLocation.Loc.unknown empty_annotation (Kill (Static0 intCty) (Pexpr aU () (PEsym symX))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Erun empty_annotation symRet524 [(Pexpr aU () (PEcall (Sym convLoadedIntSym) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym symA528))]))])) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Eaction (Paction Pos (Action CerbLocation.Loc.unknown empty_annotation (Kill (Static0 intCty) (Pexpr aU () (PEsym symX))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Epure (Pexpr aU () (PEval Vunit)))) (Expr aU (Esave (symRet524, (BTy_loaded OTy_integer)) [(symA529, (((BTy_loaded OTy_integer), none), (Pexpr aU () (PEundef CerbLocation.Loc.unknown UB088_reached_end_of_function))))] (Expr aU (Epure (Pexpr aU () (PEsym symA529))))))))))))))))))

/-- Arena at state 16 (probe-transcribed verbatim). -/
def arena16 (x : Int): RExpr :=
  (Expr [] (Eannot [(DA_pos [] (CerbMem.Footprint.FP .W 281474976710640 4))] (Expr aU (Esseq (Pattern aU (CaseBase (some symA528, (BTy_loaded OTy_integer)))) (Expr aU (Ebound (Expr [] (Eannot [(DA_pos [] (CerbMem.Footprint.FP .R 281474976710640 4))] (Expr [] (Epure (Pexpr [] () (PEval (loadedV x))))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Eaction (Paction Pos (Action CerbLocation.Loc.unknown empty_annotation (Kill (Static0 intCty) (Pexpr aU () (PEsym symX))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Erun empty_annotation symRet524 [(Pexpr aU () (PEcall (Sym convLoadedIntSym) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym symA528))]))])) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Eaction (Paction Pos (Action CerbLocation.Loc.unknown empty_annotation (Kill (Static0 intCty) (Pexpr aU () (PEsym symX))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Epure (Pexpr aU () (PEval Vunit)))) (Expr aU (Esave (symRet524, (BTy_loaded OTy_integer)) [(symA529, (((BTy_loaded OTy_integer), none), (Pexpr aU () (PEundef CerbLocation.Loc.unknown UB088_reached_end_of_function))))] (Expr aU (Epure (Pexpr aU () (PEsym symA529))))))))))))))))))

/-- Arena at state 17 (probe-transcribed verbatim). -/
def arena17 (x : Int): RExpr :=
  (Expr [] (Eannot [(DA_pos [] (CerbMem.Footprint.FP .W 281474976710640 4))] (Expr aU (Esseq (Pattern aU (CaseBase (some symA528, (BTy_loaded OTy_integer)))) (Expr [] (Epure (Pexpr [] () (PEval (loadedV x))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Eaction (Paction Pos (Action CerbLocation.Loc.unknown empty_annotation (Kill (Static0 intCty) (Pexpr aU () (PEsym symX))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Erun empty_annotation symRet524 [(Pexpr aU () (PEcall (Sym convLoadedIntSym) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym symA528))]))])) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Eaction (Paction Pos (Action CerbLocation.Loc.unknown empty_annotation (Kill (Static0 intCty) (Pexpr aU () (PEsym symX))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Epure (Pexpr aU () (PEval Vunit)))) (Expr aU (Esave (symRet524, (BTy_loaded OTy_integer)) [(symA529, (((BTy_loaded OTy_integer), none), (Pexpr aU () (PEundef CerbLocation.Loc.unknown UB088_reached_end_of_function))))] (Expr aU (Epure (Pexpr aU () (PEsym symA529))))))))))))))))))

/-- Arena at state 18 (probe-transcribed verbatim). -/
def arena18 : RExpr :=
  (Expr [] (Eannot [(DA_pos [] (CerbMem.Footprint.FP .W 281474976710640 4))] (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Eaction (Paction Pos (Action CerbLocation.Loc.unknown empty_annotation (Kill (Static0 intCty) (Pexpr aU () (PEsym symX))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Erun empty_annotation symRet524 [(Pexpr aU () (PEcall (Sym convLoadedIntSym) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym symA528))]))])) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Eaction (Paction Pos (Action CerbLocation.Loc.unknown empty_annotation (Kill (Static0 intCty) (Pexpr aU () (PEsym symX))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Epure (Pexpr aU () (PEval Vunit)))) (Expr aU (Esave (symRet524, (BTy_loaded OTy_integer)) [(symA529, (((BTy_loaded OTy_integer), none), (Pexpr aU () (PEundef CerbLocation.Loc.unknown UB088_reached_end_of_function))))] (Expr aU (Epure (Pexpr aU () (PEsym symA529))))))))))))))))

/-- Arena at state 19 (probe-transcribed verbatim). -/
def arena19 : RExpr :=
  (Expr [] (Eannot [(DA_pos [] (CerbMem.Footprint.FP .W 281474976710640 4))] (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Eaction (Paction Pos (Action CerbLocation.Loc.unknown empty_annotation (Kill (Static0 intCty) (Pexpr [] () (PEval xPtrV))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Erun empty_annotation symRet524 [(Pexpr aU () (PEcall (Sym convLoadedIntSym) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym symA528))]))])) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Eaction (Paction Pos (Action CerbLocation.Loc.unknown empty_annotation (Kill (Static0 intCty) (Pexpr aU () (PEsym symX))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Epure (Pexpr aU () (PEval Vunit)))) (Expr aU (Esave (symRet524, (BTy_loaded OTy_integer)) [(symA529, (((BTy_loaded OTy_integer), none), (Pexpr aU () (PEundef CerbLocation.Loc.unknown UB088_reached_end_of_function))))] (Expr aU (Epure (Pexpr aU () (PEsym symA529))))))))))))))))

/-- Arena at state 20 (probe-transcribed verbatim). -/
def arena20 : RExpr :=
  (Expr [] (Eannot [(DA_pos [] (CerbMem.Footprint.FP .W 281474976710640 4))] (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr [] (Epure (Pexpr [] () (PEval Vunit)))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Erun empty_annotation symRet524 [(Pexpr aU () (PEcall (Sym convLoadedIntSym) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym symA528))]))])) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Eaction (Paction Pos (Action CerbLocation.Loc.unknown empty_annotation (Kill (Static0 intCty) (Pexpr aU () (PEsym symX))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Epure (Pexpr aU () (PEval Vunit)))) (Expr aU (Esave (symRet524, (BTy_loaded OTy_integer)) [(symA529, (((BTy_loaded OTy_integer), none), (Pexpr aU () (PEundef CerbLocation.Loc.unknown UB088_reached_end_of_function))))] (Expr aU (Epure (Pexpr aU () (PEsym symA529))))))))))))))))

/-- Arena at state 21 (probe-transcribed verbatim). -/
def arena21 : RExpr :=
  (Expr [] (Eannot [(DA_pos [] (CerbMem.Footprint.FP .W 281474976710640 4))] (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Erun empty_annotation symRet524 [(Pexpr aU () (PEcall (Sym convLoadedIntSym) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym symA528))]))])) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Eaction (Paction Pos (Action CerbLocation.Loc.unknown empty_annotation (Kill (Static0 intCty) (Pexpr aU () (PEsym symX))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Epure (Pexpr aU () (PEval Vunit)))) (Expr aU (Esave (symRet524, (BTy_loaded OTy_integer)) [(symA529, (((BTy_loaded OTy_integer), none), (Pexpr aU () (PEundef CerbLocation.Loc.unknown UB088_reached_end_of_function))))] (Expr aU (Epure (Pexpr aU () (PEsym symA529))))))))))))))

/-- Arena at state 22 (probe-transcribed verbatim). -/
def arena22 : RExpr :=
  (Expr aU (Epure (Pexpr aU () (PEsym symA529))))

/-- Arena at state 23 (probe-transcribed verbatim). -/
def arena23 (x : Int): RExpr :=
  (Expr aU (Epure (Pexpr [] () (PEval (loadedV x)))))

/-! ## Patterns (for the env update chain) -/

def patX : generic_pattern sym :=
  Pattern aU (CaseBase (some symX, BTy_object OTy_pointer))
def patA500 : generic_pattern sym :=
  Pattern aU (CaseBase (some symA526, BTy_object OTy_pointer))
def patA499 : generic_pattern sym :=
  Pattern aU (CaseBase (some symA525, BTy_loaded OTy_integer))
def patA501 : generic_pattern sym :=
  Pattern aU (CaseBase (some symA527, BTy_object OTy_pointer))
def patA502 : generic_pattern sym :=
  Pattern aU (CaseBase (some symA528, BTy_loaded OTy_integer))

/-! ## Environments (spelled as the runtime builds them) -/

def env0 : List (Fmap sym value) :=
  [(List.foldl (fun (m : Fmap sym value) (pv : sym × value) =>
      fmapAddBy (fun (s1 s2 : sym) => Lem_Basic_classes.ordCompare s1 s2)
        pv.1 pv.2 m)
    fmapEmpty [(symV, vPtrV)])]
def env3 : List (Fmap sym value) := update_env patX xPtrV env0
def env5 : List (Fmap sym value) := update_env patA500 vPtrV env3
def env9 (x : Int) : List (Fmap sym value) :=
  update_env patA499 (loadedV x) env5
def env14 (x : Int) : List (Fmap sym value) :=
  update_env patA501 xPtrV (env9 x)
def env18 (x : Int) : List (Fmap sym value) :=
  update_env patA502 (loadedV x) (env14 x)
def env22 (x : Int) : List (Fmap sym value) :=
  update_env (mk_sym_pat symA529 (BTy_loaded OTy_integer))
    (loadedV x) (env18 x)

/-! ## Thread / driver-state frames -/

def mkTh (arena : RExpr) (env : List (Fmap sym value)) : thread_state :=
  { arena := arena, stack0 := Stack_empty, errno := errPtr,
    current_loc := CerbLocation.Loc.unknown,
    exec_loc := ELoc_normal
      [(roundtripT3Sym, CerbLocation.other "RelSem.callND")],
    env := env, current_proc_opt := some roundtripT3Sym }

def th00 : thread_state :=
  { mkTh arena00 env0 with current_loc := CerbLocation.other "RelSem.callND" }
def th01 : thread_state := mkTh arena01 env0
def th02 : thread_state := mkTh arena02 env0
def th03 : thread_state := mkTh arena03 env3
def th04 : thread_state := mkTh arena04 env3
def th05 : thread_state := mkTh arena05 env5
def th06 : thread_state := mkTh arena06 env5
def th07 (x : Int) : thread_state := mkTh (arena07 x) env5
def th08 (x : Int) : thread_state := mkTh (arena08 x) env5
def th09 (x : Int) : thread_state := mkTh arena09 (env9 x)
def th10 (x : Int) : thread_state := mkTh (arena10 x) (env9 x)
def th11 (x : Int) : thread_state := mkTh arena11 (env9 x)
def th12 (x : Int) : thread_state := mkTh arena12 (env9 x)
def th13 (x : Int) : thread_state := mkTh arena13 (env9 x)
def th14 (x : Int) : thread_state := mkTh arena14 (env14 x)
def th15 (x : Int) : thread_state := mkTh arena15 (env14 x)
def th16 (x : Int) : thread_state := mkTh (arena16 x) (env14 x)
def th17 (x : Int) : thread_state := mkTh (arena17 x) (env14 x)
def th18 (x : Int) : thread_state := mkTh arena18 (env18 x)
def th19 (x : Int) : thread_state := mkTh arena19 (env18 x)
def th20 (x : Int) : thread_state := mkTh arena20 (env18 x)
def th21 (x : Int) : thread_state := mkTh arena21 (env18 x)
def th22 (x : Int) : thread_state := mkTh arena22 (env22 x)
def th23 (x : Int) : thread_state := mkTh (arena23 x) (env22 x)

def accDone (v : Int) : Fmap thread_id (List core_step2) :=
  fmapAddBy defaultCompare 0 [Step_done2 (loadedV v)] fmapEmpty

def mkDr (th : thread_state) (mem : CerbMem.MemState)
    (rs : core_run_state) (tr : List trace_event) (n : Nat) : driver_state :=
  { core_file := t3File,
    core_extern := create_extern_symmap t3File,
    core_state0 := { thread_states := [(0, (none, th))], io := initial_io_state },
    core_run_state0 := rs,
    layout_state := mem,
    concurrency_state := symInitialState symInitialPre,
    fs_state0 := CerbFS.fs_initial_state,
    trace := tr,
    symbolic_assoc := fmapEmpty,
    blocked := false,
    dr_step_counter := n }

abbrev dnms (fuel : Nat) (acc : Fmap thread_id (List core_step2))
    (tids : List Nat) :=
  drive_nonmemory_steps_aux2_lemFuel fuel t3File.tagDefs acc tids

/-! ## Prefix states + memories (layered computation-shape spellings) -/

def thG : thread_state :=
  { arena := Expr [] (Epure (Pexpr [] () (PEval Vunit))),
    stack0 := Stack_empty,
    errno := .PV .Prov_none (.PVnull intCty),
    current_loc := CerbLocation.Loc.unknown,
    exec_loc := ELoc_globals,
    env := [fmapEmpty],
    current_proc_opt := none }

def rsD3 : core_run_state :=
  { initial_core_run_state (collect_labeled_continuations_NEW t3File)
      with tid_supply := 1 }

def allocV : CerbMem.Allocation :=
  { base := vAddr, size := 4, ty := some signed_int, prefix_ := PrefOther "callND arg" }
def allocErr : CerbMem.Allocation :=
  { base := errAddr, size := 4, ty := some signed_int, prefix_ := PrefOther "errno" }
/-- x's local allocation (create's ty operand is the PARSED ctype
    literal, and the prefix is the Core-create default). -/
def allocX : CerbMem.Allocation :=
  { base := xAddr, size := 4, ty := some intCty, prefix_ := PrefOther "Core" }

def bmAllocV : Std.TreeMap Int CerbMem.AbsByte :=
  (((Std.TreeMap.empty.insert vAddr uninitByte).insert
    (vAddr+1) uninitByte).insert (vAddr+2) uninitByte).insert
    (vAddr+3) uninitByte
def bmV (x : Int) : Std.TreeMap Int CerbMem.AbsByte :=
  (((bmAllocV.insert vAddr (mkByte x 0)).insert
    (vAddr+1) (mkByte x 1)).insert (vAddr+2) (mkByte x 2)).insert
    (vAddr+3) (mkByte x 3)
def bmErrAlloc (x : Int) : Std.TreeMap Int CerbMem.AbsByte :=
  ((((bmV x).insert errAddr uninitByte).insert
    (errAddr+1) uninitByte).insert (errAddr+2) uninitByte).insert
    (errAddr+3) uninitByte
def bmD3 (x : Int) : Std.TreeMap Int CerbMem.AbsByte :=
  ((((bmErrAlloc x).insert errAddr zeroByte).insert
    (errAddr+1) zeroByte).insert (errAddr+2) zeroByte).insert
    (errAddr+3) zeroByte
def bmC (x : Int) : Std.TreeMap Int CerbMem.AbsByte :=
  ((((bmD3 x).insert xAddr uninitByte).insert
    (xAddr+1) uninitByte).insert (xAddr+2) uninitByte).insert
    (xAddr+3) uninitByte
def bmS (x : Int) : Std.TreeMap Int CerbMem.AbsByte :=
  ((((bmC x).insert xAddr (mkByte x 0)).insert
    (xAddr+1) (mkByte x 1)).insert (xAddr+2) (mkByte x 2)).insert
    (xAddr+3) (mkByte x 3)

def memAllocV : CerbMem.MemState :=
  { CerbMem.initialMemState with
    nextAllocId := 1, lastAddress := vAddr,
    allocations := Std.TreeMap.empty.insert 0 allocV,
    bytemap := bmAllocV }
def memV (x : Int) : CerbMem.MemState :=
  { CerbMem.initialMemState with
    nextAllocId := 1, lastAddress := vAddr,
    allocations := Std.TreeMap.empty.insert 0 allocV,
    bytemap := bmV x }
def memErrAlloc (x : Int) : CerbMem.MemState :=
  { CerbMem.initialMemState with
    nextAllocId := 2, lastAddress := errAddr,
    allocations := (Std.TreeMap.empty.insert 0 allocV).insert 1 allocErr,
    bytemap := bmErrAlloc x }
/-- Memory at D3 (post-prefix; the run's entry memory). -/
def memD3 (x : Int) : CerbMem.MemState :=
  { CerbMem.initialMemState with
    nextAllocId := 2, lastAddress := errAddr,
    allocations := (Std.TreeMap.empty.insert 0 allocV).insert 1 allocErr,
    bytemap := bmD3 x }
/-- Memory after x's create. -/
def memC (x : Int) : CerbMem.MemState :=
  { CerbMem.initialMemState with
    nextAllocId := 3, lastAddress := xAddr,
    allocations := ((Std.TreeMap.empty.insert 0 allocV).insert 1 allocErr).insert
      2 allocX,
    bytemap := bmC x }
/-- Memory after the store to x. -/
def memS (x : Int) : CerbMem.MemState :=
  { CerbMem.initialMemState with
    nextAllocId := 3, lastAddress := xAddr,
    allocations := ((Std.TreeMap.empty.insert 0 allocV).insert 1 allocErr).insert
      2 allocX,
    bytemap := bmS x }
/-- Memory after x's kill (allocation erased, id retired). -/
def memK (x : Int) : CerbMem.MemState :=
  { CerbMem.initialMemState with
    nextAllocId := 3, lastAddress := xAddr,
    allocations := (((Std.TreeMap.empty.insert 0 allocV).insert 1 allocErr).insert
      2 allocX).erase 2,
    bytemap := bmS x,
    deadAllocations := [2] }

/-! ## Memory-op equations (the T2 recipes) -/

theorem allocV_eq :
    app (CerbMem.allocateObject 0 (PrefOther "callND arg")
      (CerbMem.alignofIval signed_int) signed_int none none)
      CerbMem.initialMemState
    = (NDactive vPtr, memAllocV) := by
  simp only [CerbMem.allocateObject, CerbMem.alignofIval, CerbMem.integerIval,
    app, memAllocV, bmAllocV, sizeof_int_eq, alignof_int_eq, vPtr, vAddr,
    allocV, uninitByte, CerbMem.initialMemState]
  simp [CerbMem.alignDown, CerbMem.writeBytesTo, List.replicate]

theorem storeV_get_fact :
    ((Std.TreeMap.empty.insert 0 allocV :
        Std.TreeMap Int CerbMem.Allocation)).get? 0 = some allocV := rfl

theorem storeV_eq (x : Int) :
    app (CerbMem.storeM (CerbLocation.other "callND arg init") signed_int false
      vPtr (CerbMem.MemValue.MVinteger (Signed Int_)
        (CerbMem.IntegerValue.IV .Prov_none x))) memAllocV
    = (NDactive (CerbMem.Footprint.FP .W vAddr 4), memV x) := by
  simp +decide only [CerbMem.storeM, app, sizeof_int_eq, vPtr,
    storeArg_bytes_fact, storeV_get_fact, RelSem.T2.storeArg_compat_fact]
  rfl

theorem errAlloc_eq (x : Int) :
    app (CerbMem.allocateObject 0 (PrefOther "errno")
      (CerbMem.alignofIval signed_int) signed_int none none) (memV x)
    = (NDactive errPtr, memErrAlloc x) := by
  simp only [CerbMem.allocateObject, CerbMem.alignofIval, CerbMem.integerIval,
    app, memV, memErrAlloc, bmErrAlloc, bmV, bmAllocV, sizeof_int_eq,
    alignof_int_eq, errPtr, errAddr, vAddr,
    allocV, allocErr, uninitByte, CerbMem.initialMemState]
  simp [CerbMem.alignDown, CerbMem.writeBytesTo, List.replicate]

theorem errStore_get_fact :
    (((Std.TreeMap.empty.insert 0 allocV).insert 1 allocErr :
        Std.TreeMap Int CerbMem.Allocation)).get? 1 = some allocErr := rfl

theorem errStore_eq (x : Int) :
    app (CerbMem.storeM (CerbLocation.other "errno init") signed_int false
      errPtr (CerbMem.integerValueMval (Signed Int_) (CerbMem.integerIval 0)))
      (memErrAlloc x)
    = (NDactive (CerbMem.Footprint.FP .W errAddr 4), memD3 x) := by
  simp +decide only [CerbMem.storeM, app, sizeof_int_eq, errPtr,
    errStore_bytes_fact, errStore_get_fact]
  rfl

/-- R1's allocation: x's create (align 4 from the evaluated
    Civalignof). -/
theorem createX_eq (x : Int) :
    app (CerbMem.allocateObject 0 (PrefOther "Core")
      (CerbMem.IntegerValue.IV .Prov_none 4) intCty none none) (memD3 x)
    = (NDactive xPtr, memC x) := by
  simp only [CerbMem.allocateObject, CerbMem.integerIval,
    app, memD3, memC, bmC, sizeof_intCty_eq, xPtr, xAddr, errAddr, vAddr,
    allocX, uninitByte, CerbMem.initialMemState]
  simp [CerbMem.alignDown, CerbMem.writeBytesTo, List.replicate,
    CerbMem.sizeofCtype]

theorem storeX_get_fact :
    ((((Std.TreeMap.empty.insert 0 allocV).insert 1 allocErr).insert 2 allocX :
        Std.TreeMap Int CerbMem.Allocation)).get? 2 = some allocX := rfl

/-- R10's store: the converted value written to x's object. -/
theorem storeX_eq (x : Int) :
    app (CerbMem.storeM CerbLocation.Loc.unknown intCty false
      xPtr (CerbMem.MemValue.MVinteger (Signed Int_)
        (CerbMem.IntegerValue.IV .Prov_none x))) (memC x)
    = (NDactive (CerbMem.Footprint.FP .W xAddr 4), memS x) := by
  simp +decide only [CerbMem.storeM, app, sizeof_intCty_eq, xPtr,
    storeArg_bytes_fact, storeX_get_fact]
  rfl

/-! ### The two loads (R6: v@…648 on memC; R15: x@…640 on memS) -/

theorem bmC_get0 (x : Int) :
    (memC x).bytemap[(281474976710648 : Int)]? = some (mkByte x 0) := by
  simp +decide only [memC, bmC, bmD3, bmErrAlloc, bmV, bmAllocV,
    vAddr, errAddr, xAddr, Std.TreeMap.getElem?_insert,
    Std.TreeMap.getElem?_insert_self, if_true, if_false]
theorem bmC_get1 (x : Int) :
    (memC x).bytemap[(281474976710649 : Int)]? = some (mkByte x 1) := by
  simp +decide only [memC, bmC, bmD3, bmErrAlloc, bmV, bmAllocV,
    vAddr, errAddr, xAddr, Std.TreeMap.getElem?_insert,
    Std.TreeMap.getElem?_insert_self, if_true, if_false]
theorem bmC_get2 (x : Int) :
    (memC x).bytemap[(281474976710650 : Int)]? = some (mkByte x 2) := by
  simp +decide only [memC, bmC, bmD3, bmErrAlloc, bmV, bmAllocV,
    vAddr, errAddr, xAddr, Std.TreeMap.getElem?_insert,
    Std.TreeMap.getElem?_insert_self, if_true, if_false]
theorem bmC_get3 (x : Int) :
    (memC x).bytemap[(281474976710651 : Int)]? = some (mkByte x 3) := by
  simp +decide only [memC, bmC, bmD3, bmErrAlloc, bmV, bmAllocV,
    vAddr, errAddr, xAddr, Std.TreeMap.getElem?_insert,
    Std.TreeMap.getElem?_insert_self, if_true, if_false]

theorem loadV_bytes_fact (x : Int) :
    CerbMem.readBytesFrom (memC x) 281474976710648 4
    = [mkByte x 0, mkByte x 1, mkByte x 2, mkByte x 3] := by
  simp [CerbMem.readBytesFrom, List.range, List.range.loop,
    bmC_get0 x, bmC_get1 x, bmC_get2 x, bmC_get3 x]

theorem loadV_get_fact (x : Int) :
    (memC x).allocations[(0 : Int)]? = some allocV := rfl
theorem loadV_dead_fact (x : Int) :
    (memC x).deadAllocations.contains 0 = false := rfl

theorem reconV_eq (x : Int) (h1 : -2147483648 ≤ x) (h2 : x ≤ 2147483647) :
    CerbMem.reconstructValue (memC x).lastUsedUnionMembers
      (memC x).funptrmap 281474976710648 intCty
      [mkByte x 0, mkByte x 1, mkByte x 2, mkByte x 3]
    = .MVinteger (Signed Int_) (.IV .Prov_none x) := by
  show CerbMem.reconstructValue_lemFuel (999999+1) _ _ _
    (Ctype [] (Basic (Integer (Signed Int_)))) _ = _
  rw [CerbMem.reconstructValue_lemFuel]
  simp only [CerberusImpl.is_signed_ity]
  rw [roundtrip_arith x h1 h2]
  simp [CerbMem.provFromIntegerBytes, CerbMem.combineProv, mkByte]

theorem loadV_eq (x : Int) (h1 : -2147483648 ≤ x) (h2 : x ≤ 2147483647) :
    app (CerbMem.loadM CerbLocation.Loc.unknown intCty vPtr) (memC x)
    = (NDactive (CerbMem.Footprint.FP .R vAddr 4,
        CerbMem.MemValue.MVinteger (Signed Int_) (.IV .Prov_none x)),
       memC x) := by
  simp only [CerbMem.loadM, app, vPtr, vAddr, sizeof_intCty_eq,
    loadV_dead_fact x, loadV_bytes_fact x, reconV_eq x h1 h2]
  simp [loadV_get_fact x, intCty,
    show CerbMem.isInBounds allocV 281474976710648 4 = true from rfl,
    show CerbMem.isAtomicMemberAccess allocV
      (Ctype [] (Basic (Integer (Signed Int_)))) 281474976710648 = false
      from rfl]

theorem bmS_get0 (x : Int) :
    (memS x).bytemap[(281474976710640 : Int)]? = some (mkByte x 0) := by
  simp +decide only [memS, bmS, bmC, bmD3, bmErrAlloc, bmV, bmAllocV,
    vAddr, errAddr, xAddr, Std.TreeMap.getElem?_insert,
    Std.TreeMap.getElem?_insert_self, if_true, if_false]
theorem bmS_get1 (x : Int) :
    (memS x).bytemap[(281474976710641 : Int)]? = some (mkByte x 1) := by
  simp +decide only [memS, bmS, bmC, bmD3, bmErrAlloc, bmV, bmAllocV,
    vAddr, errAddr, xAddr, Std.TreeMap.getElem?_insert,
    Std.TreeMap.getElem?_insert_self, if_true, if_false]
theorem bmS_get2 (x : Int) :
    (memS x).bytemap[(281474976710642 : Int)]? = some (mkByte x 2) := by
  simp +decide only [memS, bmS, bmC, bmD3, bmErrAlloc, bmV, bmAllocV,
    vAddr, errAddr, xAddr, Std.TreeMap.getElem?_insert,
    Std.TreeMap.getElem?_insert_self, if_true, if_false]
theorem bmS_get3 (x : Int) :
    (memS x).bytemap[(281474976710643 : Int)]? = some (mkByte x 3) := by
  simp +decide only [memS, bmS, bmC, bmD3, bmErrAlloc, bmV, bmAllocV,
    vAddr, errAddr, xAddr, Std.TreeMap.getElem?_insert,
    Std.TreeMap.getElem?_insert_self, if_true, if_false]

theorem loadX_bytes_fact (x : Int) :
    CerbMem.readBytesFrom (memS x) 281474976710640 4
    = [mkByte x 0, mkByte x 1, mkByte x 2, mkByte x 3] := by
  simp [CerbMem.readBytesFrom, List.range, List.range.loop,
    bmS_get0 x, bmS_get1 x, bmS_get2 x, bmS_get3 x]

theorem loadX_get_fact (x : Int) :
    (memS x).allocations[(2 : Int)]? = some allocX := rfl
theorem loadX_dead_fact (x : Int) :
    (memS x).deadAllocations.contains 2 = false := rfl

theorem reconX_eq (x : Int) (h1 : -2147483648 ≤ x) (h2 : x ≤ 2147483647) :
    CerbMem.reconstructValue (memS x).lastUsedUnionMembers
      (memS x).funptrmap 281474976710640 intCty
      [mkByte x 0, mkByte x 1, mkByte x 2, mkByte x 3]
    = .MVinteger (Signed Int_) (.IV .Prov_none x) := by
  show CerbMem.reconstructValue_lemFuel (999999+1) _ _ _
    (Ctype [] (Basic (Integer (Signed Int_)))) _ = _
  rw [CerbMem.reconstructValue_lemFuel]
  simp only [CerberusImpl.is_signed_ity]
  rw [roundtrip_arith x h1 h2]
  simp [CerbMem.provFromIntegerBytes, CerbMem.combineProv, mkByte]

theorem loadX_eq (x : Int) (h1 : -2147483648 ≤ x) (h2 : x ≤ 2147483647) :
    app (CerbMem.loadM CerbLocation.Loc.unknown intCty xPtr) (memS x)
    = (NDactive (CerbMem.Footprint.FP .R xAddr 4,
        CerbMem.MemValue.MVinteger (Signed Int_) (.IV .Prov_none x)),
       memS x) := by
  simp only [CerbMem.loadM, app, xPtr, xAddr, sizeof_intCty_eq,
    loadX_dead_fact x, loadX_bytes_fact x, reconX_eq x h1 h2]
  simp [loadX_get_fact x, intCty,
    show CerbMem.isInBounds allocX 281474976710640 4 = true from rfl,
    show CerbMem.isAtomicMemberAccess allocX
      (Ctype [] (Basic (Integer (Signed Int_)))) 281474976710640 = false
      from rfl]

/-- R19's kill: x's allocation retired. -/
theorem killX_eq (x : Int) :
    app (CerbMem.killM CerbLocation.Loc.unknown false xPtr) (memS x)
    = (NDactive (), memK x) := by
  simp +decide only [CerbMem.killM, app, xPtr, storeX_get_fact,
    show ((memS x).deadAllocations.contains 2) = false from rfl,
    show ((memS x).allocations.get? 2) = some allocX from rfl]
  rfl

/-! ## Generic request-arm unfolds (the ars_load_unfold pattern) -/

/-! ## Trace events -/

def meCreate : trace_event :=
  ME_allocate_object 0 (PrefOther "Core")
    (CerbMem.IntegerValue.IV .Prov_none 4) intCty none xPtr
def meLoadV (x : Int) : trace_event :=
  ME_load CerbLocation.Loc.unknown none intCty vPtr
    (CerbMem.MemValue.MVinteger (Signed Int_)
      (CerbMem.IntegerValue.IV .Prov_none x))
def meStore (x : Int) : trace_event :=
  ME_store CerbLocation.Loc.unknown none intCty false xPtr
    (CerbMem.MemValue.MVinteger (Signed Int_)
      (CerbMem.IntegerValue.IV .Prov_none x))
def meLoadX (x : Int) : trace_event :=
  ME_load CerbLocation.Loc.unknown none intCty xPtr
    (CerbMem.MemValue.MVinteger (Signed Int_)
      (CerbMem.IntegerValue.IV .Prov_none x))
def meKill : trace_event :=
  ME_kill CerbLocation.Loc.unknown false xPtr

/-! ## Round lemmas -/

theorem round0 (fuel : Nat) (mem : CerbMem.MemState) (rs : core_run_state)
    (tr : List trace_event) (n : Nat) :
    app (dnms (fuel+1) fmapEmpty [0]) (mkDr th00 mem rs tr n)
      = app (dnms fuel fmapEmpty [0]) (mkDr th01 mem rs tr (n+1)) := by
  refine (app_bind_active rfl).trans ?_
  refine (app_bind_active rfl).trans ?_
  rfl

/-- R1: the create round (aid drawn; counter NOT bumped; memory grows). -/
theorem round1 (x : Int) (fuel : Nat) (rs : core_run_state)
    (tr : List trace_event) (n : Nat) :
    app (dnms (fuel+1) fmapEmpty [0]) (mkDr th01 (memD3 x) rs tr n)
      = app (dnms fuel fmapEmpty [0]) (mkDr th02 (memC x)
          { rs with aid_supply := rs.aid_supply + 1 } (meCreate :: tr) n) := by
  refine (app_bind_active rfl).trans ?_
  apply (app_bind_active ?hadv).trans
  case hadv =>
    apply (app_bind_active ?hreq).trans
    case hreq =>
      refine (app_bind_active rfl).trans ?_
      rw [perform_unfold]
      refine (app_bind_active rfl).trans ?_
      rw [ars_create_unfold]
      apply (app_bind_active (app_liftND_active _ _ _ _ ?halloc)).trans
      case halloc => exact createX_eq x
      rfl
    rfl
  rfl

theorem round2 (x : Int) (fuel : Nat) (mem : CerbMem.MemState)
    (rs : core_run_state) (tr : List trace_event) (n : Nat) :
    app (dnms (fuel+1) fmapEmpty [0]) (mkDr th02 mem rs tr n)
      = app (dnms fuel fmapEmpty [0]) (mkDr th03 mem rs tr (n+1)) := by
  refine (app_bind_active rfl).trans ?_
  refine (app_bind_active rfl).trans ?_
  rfl

theorem round3 (fuel : Nat) (mem : CerbMem.MemState) (rs : core_run_state)
    (tr : List trace_event) (n : Nat) :
    app (dnms (fuel+1) fmapEmpty [0]) (mkDr th03 mem rs tr n)
      = app (dnms fuel fmapEmpty [0]) (mkDr th04 mem rs tr (n+1)) := by
  refine (app_bind_active rfl).trans ?_
  refine (app_bind_active rfl).trans ?_
  rfl

theorem round4 (fuel : Nat) (mem : CerbMem.MemState) (rs : core_run_state)
    (tr : List trace_event) (n : Nat) :
    app (dnms (fuel+1) fmapEmpty [0]) (mkDr th04 mem rs tr n)
      = app (dnms fuel fmapEmpty [0]) (mkDr th05 mem rs tr (n+1)) := by
  refine (app_bind_active rfl).trans ?_
  refine (app_bind_active rfl).trans ?_
  rfl

theorem round5 (fuel : Nat) (mem : CerbMem.MemState) (rs : core_run_state)
    (tr : List trace_event) (n : Nat) :
    app (dnms (fuel+1) fmapEmpty [0]) (mkDr th05 mem rs tr n)
      = app (dnms fuel fmapEmpty [0]) (mkDr th06 mem rs tr (n+1)) := by
  refine (app_bind_active rfl).trans ?_
  refine (app_bind_active rfl).trans ?_
  rfl

/-- R6: the v-load round. -/
theorem round6 (x : Int) (h1 : -2147483648 ≤ x) (h2 : x ≤ 2147483647)
    (fuel : Nat) (rs : core_run_state) (tr : List trace_event) (n : Nat) :
    app (dnms (fuel+1) fmapEmpty [0]) (mkDr th06 (memC x) rs tr n)
      = app (dnms fuel fmapEmpty [0]) (mkDr (th07 x) (memC x)
          { rs with aid_supply := rs.aid_supply + 1 } (meLoadV x :: tr) n) := by
  refine (app_bind_active rfl).trans ?_
  apply (app_bind_active ?hadv).trans
  case hadv =>
    apply (app_bind_active ?hreq).trans
    case hreq =>
      refine (app_bind_active rfl).trans ?_
      rw [perform_unfold]
      refine (app_bind_active rfl).trans ?_
      rw [ars_load_unfold]
      apply (app_bind_active (app_liftND_active _ _ _ _ ?hload)).trans
      case hload => exact loadV_eq x h1 h2
      apply (app_bind_active (app_liftND_active _ _ _ _ ?hpref)).trans
      case hpref => rfl
      rfl
    rfl
  rfl

theorem round7 (x : Int) (fuel : Nat) (mem : CerbMem.MemState)
    (rs : core_run_state) (tr : List trace_event) (n : Nat) :
    app (dnms (fuel+1) fmapEmpty [0]) (mkDr (th07 x) mem rs tr n)
      = app (dnms fuel fmapEmpty [0]) (mkDr (th08 x) mem rs tr (n+1)) := by
  refine (app_bind_active rfl).trans ?_
  refine (app_bind_active rfl).trans ?_
  rfl

theorem round8 (x : Int) (fuel : Nat) (mem : CerbMem.MemState)
    (rs : core_run_state) (tr : List trace_event) (n : Nat) :
    app (dnms (fuel+1) fmapEmpty [0]) (mkDr (th08 x) mem rs tr n)
      = app (dnms fuel fmapEmpty [0]) (mkDr (th09 x) mem rs tr (n+1)) := by
  refine (app_bind_active rfl).trans ?_
  refine (app_bind_active rfl).trans ?_
  rfl

/-! ## The conv_loaded_int chains (store operand, R9; Erun, R21) -/

def convStorePE : generic_pexpr Unit sym :=
  Pexpr aU () (PEcall (Sym convLoadedIntSym)
    [Pexpr aU () (PEval (Vctype intCty)), Pexpr aU () (PEsym symA525)])
def convStorePE_p : generic_pexpr Unit sym :=
  Pexpr [] () (PEcall (Sym convLoadedIntSym)
    [Pexpr aU () (PEval (Vctype intCty)), Pexpr aU () (PEsym symA525)])
def convRunPE : generic_pexpr Unit sym :=
  Pexpr aU () (PEcall (Sym convLoadedIntSym)
    [Pexpr aU () (PEval (Vctype intCty)), Pexpr aU () (PEsym symA528)])
def convRunPE_p : generic_pexpr Unit sym :=
  Pexpr [] () (PEcall (Sym convLoadedIntSym)
    [Pexpr aU () (PEval (Vctype intCty)), Pexpr aU () (PEsym symA528)])

theorem pull_convStorePE :
    pull_constrained 0 convStorePE = convStorePE_p := rfl
theorem pull_convRunPE :
    pull_constrained 0 convRunPE = convRunPE_p := rfl
theorem pull_z0 (v : Int) : pull_constrained 0 (z0 v) = z0 v := rfl
theorem pull_z1 (v : Int) : pull_constrained 0 (z1 v) = z1 v := rfl
theorem pull_z2 (v : Int) : pull_constrained 0 (z2 v) = z2 v := rfl
theorem pull_z3 (v : Int) : pull_constrained 0 (z3 v) = z3 v := rfl

theorem s0S_eq (x : Int) (mem : CerbMem.MemState) :
    step_eval_pexpr t3File.tagDefs 0 CerbLocation.Loc.unknown
      (some (CerbLocation.other "RelSem.callND")) (create_extern_symmap t3File)
      (env9 x) (some mem) t3File false convStorePE_p
      = Result (Defined (z0 x)) := rfl

theorem s0R_eq (x : Int) (mem : CerbMem.MemState) :
    step_eval_pexpr t3File.tagDefs 0 CerbLocation.Loc.unknown
      (some (CerbLocation.other "RelSem.callND")) (create_extern_symmap t3File)
      (env18 x) (some mem) t3File false convRunPE_p
      = Result (Defined (z0 x)) := rfl

theorem s1_eq (x : Int) (env : List (Fmap sym value))
    (mem : CerbMem.MemState) :
    step_eval_pexpr t3File.tagDefs 0 CerbLocation.Loc.unknown
      (some (CerbLocation.other "RelSem.callND")) (create_extern_symmap t3File)
      env (some mem) t3File false (z0 x)
      = Result (Defined (z1 x)) := rfl

theorem s2_eq (x : Int) (env : List (Fmap sym value))
    (mem : CerbMem.MemState) :
    step_eval_pexpr t3File.tagDefs 0 CerbLocation.Loc.unknown
      (some (CerbLocation.other "RelSem.callND")) (create_extern_symmap t3File)
      env (some mem) t3File false (z1 x)
      = Result (Defined (z2 x)) := rfl

theorem s3_eq (x : Int) (env : List (Fmap sym value))
    (mem : CerbMem.MemState) :
    step_eval_pexpr t3File.tagDefs 0 CerbLocation.Loc.unknown
      (some (CerbLocation.other "RelSem.callND")) (create_extern_symmap t3File)
      env (some mem) t3File false (z2 x)
      = Result (Defined (z3 x)) := rfl

/-- s4: the conv range check (the T1 harm recipe). -/
theorem s4_eq (x : Int)
    (h1 : -2147483648 ≤ x) (h2 : x ≤ 2147483647)
    (env : List (Fmap sym value)) (mem : CerbMem.MemState) :
    step_eval_pexpr t3File.tagDefs 0 CerbLocation.Loc.unknown
      (some (CerbLocation.other "RelSem.callND")) (create_extern_symmap t3File)
      env (some mem) t3File false (z3 x)
      = Result (Defined (z4 x)) := by
  have hd1 : decide ((-2147483648:Int) ≤ x) = true := decide_eq_true h1
  have hd2 : decide (x ≤ (2147483647:Int)) = true := decide_eq_true h2
  change exception_undef_bind _ _ = _
  refine (eubind_defined
    (z := (PEval (loadedV x) : generic_pexpr_ Unit sym)) ?hBody).trans ?_
  case hBody =>
    change exception_undef_bind _ _ = _
    refine (eubind_defined
      (z := [(Pexpr [] () (PEval (xIntV x)) : generic_pexpr Unit sym)])
      ?hMap).trans ?_
    case hMap =>
      apply eumapM_one ?hIf
      case hIf =>
        change exception_undef_bind _ _ = _
        refine (eubind_defined
          (z := (PEval (xIntV x) : generic_pexpr_ Unit sym)) ?hIfBody).trans ?_
        case hIfBody =>
          change exception_undef_bind _ _ = _
          refine (eubind_defined
            (z := (Pexpr [] () (PEval Vtrue) : generic_pexpr Unit sym))
            ?hCond).trans ?_
          case hCond =>
            change exception_undef_bind _ _ = _
            refine (eubind_defined
              (z := (PEval Vtrue : generic_pexpr_ Unit sym)) ?hCondBody).trans ?_
            case hCondBody =>
              change exception_undef_bind _ _ = _
              refine (eubind_defined
                (z := (Pexpr [] () (PEval Vtrue) : generic_pexpr Unit sym))
                ?hLe1).trans ?_
              case hLe1 =>
                show step_eval_pexpr_lemFuel 999997 t3File.tagDefs (0+1+1+1)
                  CerbLocation.Loc.unknown (some (CerbLocation.other "RelSem.callND"))
                  (create_extern_symmap t3File) env (some mem) t3File false
                  (Pexpr [] () (PEop OpLe
                    (Pexpr [] () (PEctor Civmin [Pexpr aU () (PEval (Vctype intCty))]))
                    (Pexpr [] () (PEval (xIntV x)))))
                  = Result (Defined (Pexpr [] () (PEval Vtrue)))
                have harm : (if (decide ((-2147483648:Int) ≤ x)) = true
                    then Vtrue else Vfalse) = Vtrue := by rw [hd1]; simp
                conv => rhs; rw [← harm]
                rfl
              change exception_undef_bind _ _ = _
              refine (eubind_defined
                (z := (Pexpr [] () (PEval Vtrue) : generic_pexpr Unit sym))
                ?hLe2).trans ?_
              case hLe2 =>
                show step_eval_pexpr_lemFuel 999997 t3File.tagDefs (0+1+1+1)
                  CerbLocation.Loc.unknown (some (CerbLocation.other "RelSem.callND"))
                  (create_extern_symmap t3File) env (some mem) t3File false
                  (Pexpr [] () (PEop OpLe
                    (Pexpr [] () (PEval (xIntV x)))
                    (Pexpr [] () (PEctor Civmax [Pexpr aU () (PEval (Vctype intCty))]))))
                  = Result (Defined (Pexpr [] () (PEval Vtrue)))
                have harm : (if (decide (x ≤ (2147483647:Int))) = true
                    then Vtrue else Vfalse) = Vtrue := by rw [hd2]; simp
                conv => rhs; rw [← harm]
                rfl
              rfl
            rfl
          rfl
        rfl
    rfl
  rfl

theorem convStoreCore_eq (x : Int)
    (h1 : -2147483648 ≤ x) (h2 : x ≤ 2147483647) (mem : CerbMem.MemState) :
    eval_pexpr_aux2 t3File.tagDefs CerbLocation.Loc.unknown
      (some (CerbLocation.other "RelSem.callND"))
      (create_extern_symmap t3File) (env9 x) (some mem) t3File convStorePE
    = Result (Defined (Sum.inr (loadedV x))) :=
  (aux2_step 999999 _ _ _ _ _ _ _ (pull_convStorePE)
      (by intro a xs h; simp [convStorePE_p] at h) (s0S_eq x mem) (by rfl)).trans
  ((aux2_step 999998 _ _ _ _ _ _ _ (pull_z0 x)
      (by intro a xs h; simp [z0] at h) (s1_eq x _ mem) (by rfl)).trans
  ((aux2_step 999997 _ _ _ _ _ _ _ (pull_z1 x)
      (by intro a xs h; simp [z1] at h) (s2_eq x _ mem) (by rfl)).trans
  ((aux2_step 999996 _ _ _ _ _ _ _ (pull_z2 x)
      (by intro a xs h; simp [z2] at h) (s3_eq x _ mem) (by rfl)).trans
  (aux2_done 999995 _ _ _ _ _ _ _ (pull_z3 x)
      (by intro a xs h; simp [z3] at h) (s4_eq x h1 h2 _ mem) (by rfl)))))

theorem convRunCore_eq (x : Int)
    (h1 : -2147483648 ≤ x) (h2 : x ≤ 2147483647) (mem : CerbMem.MemState) :
    eval_pexpr_aux2 t3File.tagDefs CerbLocation.Loc.unknown
      (some (CerbLocation.other "RelSem.callND"))
      (create_extern_symmap t3File) (env18 x) (some mem) t3File convRunPE
    = Result (Defined (Sum.inr (loadedV x))) :=
  (aux2_step 999999 _ _ _ _ _ _ _ (pull_convRunPE)
      (by intro a xs h; simp [convRunPE_p] at h) (s0R_eq x mem) (by rfl)).trans
  ((aux2_step 999998 _ _ _ _ _ _ _ (pull_z0 x)
      (by intro a xs h; simp [z0] at h) (s1_eq x _ mem) (by rfl)).trans
  ((aux2_step 999997 _ _ _ _ _ _ _ (pull_z1 x)
      (by intro a xs h; simp [z1] at h) (s2_eq x _ mem) (by rfl)).trans
  ((aux2_step 999996 _ _ _ _ _ _ _ (pull_z2 x)
      (by intro a xs h; simp [z2] at h) (s3_eq x _ mem) (by rfl)).trans
  (aux2_done 999995 _ _ _ _ _ _ _ (pull_z3 x)
      (by intro a xs h; simp [z3] at h) (s4_eq x h1 h2 _ mem) (by rfl)))))

theorem convStoreStep_eq (x : Int)
    (h1 : -2147483648 ≤ x) (h2 : x ≤ 2147483647)
    (mem : CerbMem.MemState) (rs : core_run_state) :
    E.eval_pexpr20 t3File.tagDefs (th09 x) (create_extern_symmap t3File)
      mem t3File convStorePE rs
    = Result (Defined (Sum.inr (loadedV x)), rs) := by
  simp only [E.eval_pexpr20, th09, mkTh]
  rw [convStoreCore_eq x h1 h2 mem]
  rfl

theorem fullEvalConvStore (x : Int)
    (h1 : -2147483648 ≤ x) (h2 : x ≤ 2147483647)
    (mem : CerbMem.MemState) (rs : core_run_state) :
    full_eval_pexpr t3File.tagDefs (th09 x) (create_extern_symmap t3File)
      mem t3File convStorePE rs
    = Result (Defined (loadedV x), rs) := by
  change stExceptUndef_bind _ _ _ = _
  refine (stub_defined (convStoreStep_eq x h1 h2 mem rs)).trans ?_
  rfl

theorem convRunStep_eq (x : Int)
    (h1 : -2147483648 ≤ x) (h2 : x ≤ 2147483647)
    (mem : CerbMem.MemState) (rs : core_run_state) :
    E.eval_pexpr20 t3File.tagDefs (th21 x) (create_extern_symmap t3File)
      mem t3File convRunPE rs
    = Result (Defined (Sum.inr (loadedV x)), rs) := by
  simp only [E.eval_pexpr20, th21, mkTh]
  rw [convRunCore_eq x h1 h2 mem]
  rfl

theorem fullEvalConvRun (x : Int)
    (h1 : -2147483648 ≤ x) (h2 : x ≤ 2147483647)
    (mem : CerbMem.MemState) (rs : core_run_state) :
    full_eval_pexpr t3File.tagDefs (th21 x) (create_extern_symmap t3File)
      mem t3File convRunPE rs
    = Result (Defined (loadedV x), rs) := by
  change stExceptUndef_bind _ _ _ = _
  refine (stub_defined (convRunStep_eq x h1 h2 mem rs)).trans ?_
  rfl

/-- R9: the store-operand eval round (ctype, pointer, and THE CONV
    CHAIN — range check #1). -/
theorem round9 (x : Int) (h1 : -2147483648 ≤ x) (h2 : x ≤ 2147483647)
    (fuel : Nat) (mem : CerbMem.MemState) (rs : core_run_state)
    (tr : List trace_event) (n : Nat) :
    app (dnms (fuel+1) fmapEmpty [0]) (mkDr (th09 x) mem rs tr n)
      = app (dnms fuel fmapEmpty [0]) (mkDr (th10 x) mem rs tr (n+1)) := by
  refine (app_bind_active rfl).trans ?_    -- nd_read (step_ctx)
  apply (app_bind_active ?hadv).trans
  case hadv =>
    refine (app_bind_active rfl).trans ?_  -- rsk match (RSK_eval)
    apply (app_bind_active (liftCore_run_defined ?hM)).trans
    case hM =>
      change stExceptUndef_bind _ _ _ = _
      apply (stub_defined ?hOps).trans
      case hOps =>
        change stExceptUndef_bind _ _ _ = _
        apply (stub_defined ?hOp1).trans          -- full_eval (Vctype)
        case hOp1 => rfl
        change stExceptUndef_bind _ _ _ = _
        apply (stub_defined ?hOp2).trans          -- full_eval (PEsym x)
        case hOp2 => rfl
        change stExceptUndef_bind _ _ _ = _
        apply (stub_defined (fullEvalConvStore x h1 h2 _ _)).trans
        rfl
      rfl
    rfl
  rfl

/-- R10: the store round. -/
theorem round10 (x : Int) (fuel : Nat) (rs : core_run_state)
    (tr : List trace_event) (n : Nat) :
    app (dnms (fuel+1) fmapEmpty [0]) (mkDr (th10 x) (memC x) rs tr n)
      = app (dnms fuel fmapEmpty [0]) (mkDr (th11 x) (memS x)
          { rs with aid_supply := rs.aid_supply + 1 } (meStore x :: tr) n) := by
  refine (app_bind_active rfl).trans ?_
  apply (app_bind_active ?hadv).trans
  case hadv =>
    apply (app_bind_active ?hreq).trans
    case hreq =>
      refine (app_bind_active rfl).trans ?_
      rw [perform_unfold]
      refine (app_bind_active rfl).trans ?_
      rw [ars_store_unfold]
      apply (app_bind_active (app_liftND_active _ _ _ _ ?hstore)).trans
      case hstore => exact storeX_eq x
      apply (app_bind_active (app_liftND_active _ _ _ _ ?hpref)).trans
      case hpref => rfl
      rfl
    rfl
  rfl

theorem round11 (x : Int) (fuel : Nat) (mem : CerbMem.MemState)
    (rs : core_run_state) (tr : List trace_event) (n : Nat) :
    app (dnms (fuel+1) fmapEmpty [0]) (mkDr (th11 x) mem rs tr n)
      = app (dnms fuel fmapEmpty [0]) (mkDr (th12 x) mem rs tr (n+1)) := by
  refine (app_bind_active rfl).trans ?_
  refine (app_bind_active rfl).trans ?_
  rfl

theorem round12 (x : Int) (fuel : Nat) (mem : CerbMem.MemState)
    (rs : core_run_state) (tr : List trace_event) (n : Nat) :
    app (dnms (fuel+1) fmapEmpty [0]) (mkDr (th12 x) mem rs tr n)
      = app (dnms fuel fmapEmpty [0]) (mkDr (th13 x) mem rs tr (n+1)) := by
  refine (app_bind_active rfl).trans ?_
  refine (app_bind_active rfl).trans ?_
  rfl

theorem round13 (x : Int) (fuel : Nat) (mem : CerbMem.MemState)
    (rs : core_run_state) (tr : List trace_event) (n : Nat) :
    app (dnms (fuel+1) fmapEmpty [0]) (mkDr (th13 x) mem rs tr n)
      = app (dnms fuel fmapEmpty [0]) (mkDr (th14 x) mem rs tr (n+1)) := by
  refine (app_bind_active rfl).trans ?_
  refine (app_bind_active rfl).trans ?_
  rfl

theorem round14 (x : Int) (fuel : Nat) (mem : CerbMem.MemState)
    (rs : core_run_state) (tr : List trace_event) (n : Nat) :
    app (dnms (fuel+1) fmapEmpty [0]) (mkDr (th14 x) mem rs tr n)
      = app (dnms fuel fmapEmpty [0]) (mkDr (th15 x) mem rs tr (n+1)) := by
  refine (app_bind_active rfl).trans ?_
  refine (app_bind_active rfl).trans ?_
  rfl

/-- R15: the x-load round (the roundtrip payoff). -/
theorem round15 (x : Int) (h1 : -2147483648 ≤ x) (h2 : x ≤ 2147483647)
    (fuel : Nat) (rs : core_run_state) (tr : List trace_event) (n : Nat) :
    app (dnms (fuel+1) fmapEmpty [0]) (mkDr (th15 x) (memS x) rs tr n)
      = app (dnms fuel fmapEmpty [0]) (mkDr (th16 x) (memS x)
          { rs with aid_supply := rs.aid_supply + 1 } (meLoadX x :: tr) n) := by
  refine (app_bind_active rfl).trans ?_
  apply (app_bind_active ?hadv).trans
  case hadv =>
    apply (app_bind_active ?hreq).trans
    case hreq =>
      refine (app_bind_active rfl).trans ?_
      rw [perform_unfold]
      refine (app_bind_active rfl).trans ?_
      rw [ars_load_unfold]
      apply (app_bind_active (app_liftND_active _ _ _ _ ?hload)).trans
      case hload => exact loadX_eq x h1 h2
      apply (app_bind_active (app_liftND_active _ _ _ _ ?hpref)).trans
      case hpref => rfl
      rfl
    rfl
  rfl

theorem round16 (x : Int) (fuel : Nat) (mem : CerbMem.MemState)
    (rs : core_run_state) (tr : List trace_event) (n : Nat) :
    app (dnms (fuel+1) fmapEmpty [0]) (mkDr (th16 x) mem rs tr n)
      = app (dnms fuel fmapEmpty [0]) (mkDr (th17 x) mem rs tr (n+1)) := by
  refine (app_bind_active rfl).trans ?_
  refine (app_bind_active rfl).trans ?_
  rfl

theorem round17 (x : Int) (fuel : Nat) (mem : CerbMem.MemState)
    (rs : core_run_state) (tr : List trace_event) (n : Nat) :
    app (dnms (fuel+1) fmapEmpty [0]) (mkDr (th17 x) mem rs tr n)
      = app (dnms fuel fmapEmpty [0]) (mkDr (th18 x) mem rs tr (n+1)) := by
  refine (app_bind_active rfl).trans ?_
  refine (app_bind_active rfl).trans ?_
  rfl

theorem round18 (x : Int) (fuel : Nat) (mem : CerbMem.MemState)
    (rs : core_run_state) (tr : List trace_event) (n : Nat) :
    app (dnms (fuel+1) fmapEmpty [0]) (mkDr (th18 x) mem rs tr n)
      = app (dnms fuel fmapEmpty [0]) (mkDr (th19 x) mem rs tr (n+1)) := by
  refine (app_bind_active rfl).trans ?_
  refine (app_bind_active rfl).trans ?_
  rfl

/-- R19: the kill round. -/
theorem round19 (x : Int) (fuel : Nat) (rs : core_run_state)
    (tr : List trace_event) (n : Nat) :
    app (dnms (fuel+1) fmapEmpty [0]) (mkDr (th19 x) (memS x) rs tr n)
      = app (dnms fuel fmapEmpty [0]) (mkDr (th20 x) (memK x)
          { rs with aid_supply := rs.aid_supply + 1 } (meKill :: tr) n) := by
  refine (app_bind_active rfl).trans ?_
  apply (app_bind_active ?hadv).trans
  case hadv =>
    apply (app_bind_active ?hreq).trans
    case hreq =>
      refine (app_bind_active rfl).trans ?_
      rw [perform_unfold]
      refine (app_bind_active rfl).trans ?_
      rw [ars_kill_unfold]
      apply (app_bind_active (app_liftND_active _ _ _ _ ?hkill)).trans
      case hkill => exact killX_eq x
      rfl
    rfl
  rfl

theorem round20 (x : Int) (fuel : Nat) (mem : CerbMem.MemState)
    (rs : core_run_state) (tr : List trace_event) (n : Nat) :
    app (dnms (fuel+1) fmapEmpty [0]) (mkDr (th20 x) mem rs tr n)
      = app (dnms fuel fmapEmpty [0]) (mkDr (th21 x) mem rs tr (n+1)) := by
  refine (app_bind_active rfl).trans ?_
  refine (app_bind_active rfl).trans ?_
  rfl

/-! ## The run-state ladder (five action-id draws) -/

def rs1 : core_run_state := { rsD3 with aid_supply := rsD3.aid_supply + 1 }
def rs2 : core_run_state := { rs1 with aid_supply := rs1.aid_supply + 1 }
def rs3 : core_run_state := { rs2 with aid_supply := rs2.aid_supply + 1 }
def rs4 : core_run_state := { rs3 with aid_supply := rs3.aid_supply + 1 }
def rs5 : core_run_state := { rs4 with aid_supply := rs4.aid_supply + 1 }

/-- R21: the Erun eval round (conv chain #2 + the save jump),
    ∀-run-state through the `erun_jump_m` construct law (arc-17 S1;
    was pinned to the concrete `rs5` — the label resolution now enters
    as the `hlab` projection hypothesis, `rfl` at every state ladder). -/
theorem round21 (x : Int) (h1 : -2147483648 ≤ x) (h2 : x ≤ 2147483647)
    (fuel : Nat) (mem : CerbMem.MemState) (rs : core_run_state)
    (hlab : rs.labeled = collect_labeled_continuations_NEW t3File)
    (tr : List trace_event) (n : Nat) :
    app (dnms (fuel+1) fmapEmpty [0]) (mkDr (th21 x) mem rs tr n)
      = app (dnms fuel fmapEmpty [0]) (mkDr (th22 x) mem rs tr (n+1)) := by
  refine (app_bind_active rfl).trans ?_    -- nd_read (step_ctx)
  apply (app_bind_active ?hadv).trans
  case hadv =>
    refine (app_bind_active rfl).trans ?_  -- rsk match (RSK_eval)
    apply (app_bind_active (liftCore_run_defined ?hM)).trans
    case hM =>
      change stExceptUndef_bind _ _ _ = _
      apply RelSem.Laws.erun_jump_m ?hres ?hk  -- label-jump construct law
      case hres => simp only [mkDr, hlab]; rfl -- label resolution
      case hk =>
        change stExceptUndef_bind _ _ _ = _
        apply (stub_defined ?hFold).trans       -- the args foldM
        case hFold =>
          change stExceptUndef_bind _ _ _ = _
          apply (stub_defined ?hElem).trans
          case hElem =>
            change stExceptUndef_bind _ _ _ = _
            apply (stub_defined (fullEvalConvRun x h1 h2 _ _)).trans
            rfl
          rfl
        rfl
    rfl
  rfl

theorem round22 (x : Int) (fuel : Nat) (mem : CerbMem.MemState)
    (rs : core_run_state) (tr : List trace_event) (n : Nat) :
    app (dnms (fuel+1) fmapEmpty [0]) (mkDr (th22 x) mem rs tr n)
      = app (dnms fuel fmapEmpty [0]) (mkDr (th23 x) mem rs tr (n+1)) := by
  refine (app_bind_active rfl).trans ?_
  refine (app_bind_active rfl).trans ?_
  rfl


theorem round23 (x : Int) (fuel : Nat) (mem : CerbMem.MemState)
    (rs : core_run_state) (tr : List trace_event) (n : Nat) :
    app (dnms (fuel+2) fmapEmpty [0]) (mkDr (th23 x) mem rs tr n)
      = (NDactive (accDone x), mkDr (th23 x) mem rs tr n) := by
  refine (app_bind_active rfl).trans ?_
  rfl

/-! ## The prefix walk (T2's a0/a1/b structure, one argument) -/

def finTail : Unit → driverM driver_result :=
  fun _ => nd_bind nd_get (fun (dr_st' : driver_state) =>
    nd_return (finalize t3File.tagDefs "callND" dr_st'))

theorem mvvV_fact (v : Int) :
    memValueFromValue t3File.tagDefs signed_int (intValue v)
      = some (CerbMem.MemValue.MVinteger (Signed Int_)
          (CerbMem.IntegerValue.IV .Prov_none v)) := rfl

def injPhase (x : Int) : driverM driver_result :=
  nd_bind (injectArgs t3File.tagDefs 0
      [(symV, BTy_object OTy_pointer)] [signed_int] [intValue x])
    (fun (bound : List (sym × value)) =>
      callFinish t3File.tagDefs 0 roundtripT3Sym arena00 bound)


/-! ## Composition -/

/-- The post-exit thread. -/
def thDone (x : Int) : thread_state :=
  { th23 x with stack0 := Stack_empty, arena := mk_value_e (loadedV x) }

/-- The final driver state of the harness run. -/
def drDone (x : Int) : driver_state :=
  mkDr (thDone x) (memK x) rs5
    [meKill, meLoadX x, meStore x, meLoadV x, meCreate] 18

/-! ## Statement vocabulary (RE-HOMED from the deleted ambient
    statement file RelSem/T3.lean at the 2026-08-27 kill-list
    execution — texts unchanged; every consumer resolves the same
    `RelSem.T3.t3Fs`/`RelSem.T3.t3Spec`). -/

/-- The harness filesystem state (the driver default). -/
def t3Fs : CerbFS.FsState := CerbFS.fs_initial_state

/-- T3's pure spec: the result value is the injected integer,
    Specified. -/
def t3Spec (x : Int) (r : driver_result) : Prop :=
  r.dres_core_value = intValue x

end RelSem.T3
