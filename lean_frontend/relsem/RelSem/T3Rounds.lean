/-
  RelSem.T3Rounds — V2 (2026-08-28): THE T3 (roundtrip) ROUND ENGINE
  — the MEMORY-WRITING program (create a local, store the loaded
  argument, load it back, kill the local, return). Ground truth: the
  V2Probe transcripts at 7 and -4. 23 linear rounds exercising the three
  new round classes (ctl_sup_alloc / _store / _kill).

  House rules: no sorry, no axioms. Under the in-build audit.
-/

import RelSem.T2Rounds
import RelSem.T3Threaded

set_option autoImplicit false
set_option maxHeartbeats 2000000

namespace RelSem.T3

open RelSem RelSem.Cerb RelSem.Kit RelSem.CerbSt
open Lem_Basic_classes (ordCompare)
open RelSem.T1 (T1P RExpr aU intCty xAddr xPtr errAddr errPtr xPtrV
  loadedV xBytes mkByte roundtrip_arith allocX allocXS allocErrS
  zeroBytes mr0 mr1 mr2 meLoad
  memValueToBytes_int memValueFromValue_int
  birth_new birth_pres birth_rev birth_wfp)
open RelSem.P01 (L0 clsNone xObjV)
open RelSem.Slate (t3File roundtripT3Sym)

/-! ## Program symbols + the local-object ladder -/

def t3symV : sym := Symbol "" 1965435164061188486 (SD_Id "v")
def t3symx : sym := Symbol "" 16562859848569467201 (SD_Id "x")
def t3symA525 : sym := Symbol "" 3579765898737599443 (SD_Id "a_525")
def t3symA526 : sym := Symbol "" 13429216386455784360 (SD_Id "a_526")
def t3symA527 : sym := Symbol "" 4139409277016632516 (SD_Id "a_527")
def t3symA528 : sym := Symbol "" 8935235297226827052 (SD_Id "a_528")
def t3symA529 : sym := Symbol "" 1680278659536745755 (SD_Id "a_529")
def t3symCLI : sym :=
  Symbol "" 7499171796590179012 (SD_Id "conv_loaded_int")
def t3symRet524 : sym :=
  Symbol "" 14990978498630749272 (SD_Id "ret_524")

def locAddr : Int := 281474976710640
def locPtr : CerbMem.PointerValue :=
  .PV (.Prov_some 2) (.PVconcrete none locAddr)
def locPtrV : value := Vobject (OVpointer locPtr)

@[reducible] def allocLoc : CerbMem.Allocation :=
  { base := locAddr, size := (4 : Nat), ty := some intCty,
    prefix_ := PrefOther "Core" }

/-- Residuals: T1's mr2 (arg+errno), then the local's create/kill. -/
@[reducible] def t3mr3 : CerbMem.MemState := mrAlloc mr2 locAddr
@[reducible] def t3mr4 : CerbMem.MemState := mrKill t3mr3 2

/-- The uninitialized fill the create mints. -/
@[reducible] def uninit4 : List CerbMem.AbsByte :=
  List.replicate 4
    { prov := .Prov_none, copyOffset := none, value := none }

/-! ## Trace events -/

def t3meAlloc : trace_event :=
  ME_allocate_object 0 (PrefOther "Core")
    (CerbMem.IntegerValue.IV .Prov_none 4) intCty none locPtr

def t3meStore (x : Int) : trace_event :=
  ME_store CerbLocation.Loc.unknown none intCty false locPtr
    (CerbMem.MemValue.MVinteger (Signed Int_)
      (CerbMem.IntegerValue.IV .Prov_none x))

def t3meLoad2 (x : Int) : trace_event :=
  ME_load CerbLocation.Loc.unknown none intCty locPtr
    (CerbMem.MemValue.MVinteger (Signed Int_)
      (CerbMem.IntegerValue.IV .Prov_none x))

def t3meKill : trace_event :=
  ME_kill CerbLocation.Loc.unknown false locPtr

/-! ## Arena terms (generated) -/

def t3ar0 : RExpr :=
  (Expr aU (Esseq (Pattern aU (CaseBase ((some t3symx), (BTy_object OTy_pointer)))) (Expr aU (Eaction (Paction Pos (Action L0 empty_annotation (Create (Pexpr aU () (PEctor Civalignof [(Pexpr aU () (PEval (Vctype intCty)))])) (Pexpr aU () (PEval (Vctype intCty))) (PrefOther "Core")))))) (Expr aU (Esseq (Pattern aU (CaseBase ((some t3symA525), (BTy_loaded OTy_integer)))) (Expr aU (Ebound (Expr aU (Ewseq (Pattern aU (CaseBase ((some t3symA526), (BTy_object OTy_pointer)))) (Expr aU (Epure (Pexpr aU () (PEsym t3symV)))) (Expr aU (Eaction (Paction Pos (Action L0 empty_annotation (Load0 (Pexpr aU () (PEval (Vctype intCty))) (Pexpr aU () (PEsym t3symA526)) NA))))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Eaction (Paction Pos (Action L0 empty_annotation (Store0 false (Pexpr aU () (PEval (Vctype intCty))) (Pexpr aU () (PEsym t3symx)) (Pexpr aU () (PEcall (Sym t3symCLI) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym t3symA525))])) NA))))) (Expr aU (Esseq (Pattern aU (CaseBase ((some t3symA528), (BTy_loaded OTy_integer)))) (Expr aU (Ebound (Expr aU (Ewseq (Pattern aU (CaseBase ((some t3symA527), (BTy_object OTy_pointer)))) (Expr aU (Epure (Pexpr aU () (PEsym t3symx)))) (Expr aU (Eaction (Paction Pos (Action L0 empty_annotation (Load0 (Pexpr aU () (PEval (Vctype intCty))) (Pexpr aU () (PEsym t3symA527)) NA))))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Eaction (Paction Pos (Action L0 empty_annotation (Kill (Static0 intCty) (Pexpr aU () (PEsym t3symx))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Erun empty_annotation t3symRet524 [(Pexpr aU () (PEcall (Sym t3symCLI) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym t3symA528))]))])) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Eaction (Paction Pos (Action L0 empty_annotation (Kill (Static0 intCty) (Pexpr aU () (PEsym t3symx))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Epure (Pexpr aU () (PEval Vunit)))) (Expr aU (Esave (t3symRet524, (BTy_loaded OTy_integer)) [(t3symA529, (((BTy_loaded OTy_integer), none), (Pexpr aU () (PEundef L0 UB088_reached_end_of_function))))] (Expr aU (Epure (Pexpr aU () (PEsym t3symA529))))))))))))))))))))))

def t3ar1 : RExpr :=
  (Expr aU (Esseq (Pattern aU (CaseBase ((some t3symx), (BTy_object OTy_pointer)))) (Expr aU (Eaction (Paction Pos (Action L0 empty_annotation (Create (Pexpr [] () (PEval (Vobject (OVinteger (.IV .Prov_none (4)))))) (Pexpr [] () (PEval (Vctype intCty))) (PrefOther "Core")))))) (Expr aU (Esseq (Pattern aU (CaseBase ((some t3symA525), (BTy_loaded OTy_integer)))) (Expr aU (Ebound (Expr aU (Ewseq (Pattern aU (CaseBase ((some t3symA526), (BTy_object OTy_pointer)))) (Expr aU (Epure (Pexpr aU () (PEsym t3symV)))) (Expr aU (Eaction (Paction Pos (Action L0 empty_annotation (Load0 (Pexpr aU () (PEval (Vctype intCty))) (Pexpr aU () (PEsym t3symA526)) NA))))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Eaction (Paction Pos (Action L0 empty_annotation (Store0 false (Pexpr aU () (PEval (Vctype intCty))) (Pexpr aU () (PEsym t3symx)) (Pexpr aU () (PEcall (Sym t3symCLI) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym t3symA525))])) NA))))) (Expr aU (Esseq (Pattern aU (CaseBase ((some t3symA528), (BTy_loaded OTy_integer)))) (Expr aU (Ebound (Expr aU (Ewseq (Pattern aU (CaseBase ((some t3symA527), (BTy_object OTy_pointer)))) (Expr aU (Epure (Pexpr aU () (PEsym t3symx)))) (Expr aU (Eaction (Paction Pos (Action L0 empty_annotation (Load0 (Pexpr aU () (PEval (Vctype intCty))) (Pexpr aU () (PEsym t3symA527)) NA))))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Eaction (Paction Pos (Action L0 empty_annotation (Kill (Static0 intCty) (Pexpr aU () (PEsym t3symx))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Erun empty_annotation t3symRet524 [(Pexpr aU () (PEcall (Sym t3symCLI) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym t3symA528))]))])) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Eaction (Paction Pos (Action L0 empty_annotation (Kill (Static0 intCty) (Pexpr aU () (PEsym t3symx))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Epure (Pexpr aU () (PEval Vunit)))) (Expr aU (Esave (t3symRet524, (BTy_loaded OTy_integer)) [(t3symA529, (((BTy_loaded OTy_integer), none), (Pexpr aU () (PEundef L0 UB088_reached_end_of_function))))] (Expr aU (Epure (Pexpr aU () (PEsym t3symA529))))))))))))))))))))))

def t3ar2 : RExpr :=
  (Expr aU (Esseq (Pattern aU (CaseBase ((some t3symx), (BTy_object OTy_pointer)))) (Expr [] (Epure (Pexpr [] () (PEval locPtrV)))) (Expr aU (Esseq (Pattern aU (CaseBase ((some t3symA525), (BTy_loaded OTy_integer)))) (Expr aU (Ebound (Expr aU (Ewseq (Pattern aU (CaseBase ((some t3symA526), (BTy_object OTy_pointer)))) (Expr aU (Epure (Pexpr aU () (PEsym t3symV)))) (Expr aU (Eaction (Paction Pos (Action L0 empty_annotation (Load0 (Pexpr aU () (PEval (Vctype intCty))) (Pexpr aU () (PEsym t3symA526)) NA))))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Eaction (Paction Pos (Action L0 empty_annotation (Store0 false (Pexpr aU () (PEval (Vctype intCty))) (Pexpr aU () (PEsym t3symx)) (Pexpr aU () (PEcall (Sym t3symCLI) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym t3symA525))])) NA))))) (Expr aU (Esseq (Pattern aU (CaseBase ((some t3symA528), (BTy_loaded OTy_integer)))) (Expr aU (Ebound (Expr aU (Ewseq (Pattern aU (CaseBase ((some t3symA527), (BTy_object OTy_pointer)))) (Expr aU (Epure (Pexpr aU () (PEsym t3symx)))) (Expr aU (Eaction (Paction Pos (Action L0 empty_annotation (Load0 (Pexpr aU () (PEval (Vctype intCty))) (Pexpr aU () (PEsym t3symA527)) NA))))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Eaction (Paction Pos (Action L0 empty_annotation (Kill (Static0 intCty) (Pexpr aU () (PEsym t3symx))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Erun empty_annotation t3symRet524 [(Pexpr aU () (PEcall (Sym t3symCLI) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym t3symA528))]))])) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Eaction (Paction Pos (Action L0 empty_annotation (Kill (Static0 intCty) (Pexpr aU () (PEsym t3symx))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Epure (Pexpr aU () (PEval Vunit)))) (Expr aU (Esave (t3symRet524, (BTy_loaded OTy_integer)) [(t3symA529, (((BTy_loaded OTy_integer), none), (Pexpr aU () (PEundef L0 UB088_reached_end_of_function))))] (Expr aU (Epure (Pexpr aU () (PEsym t3symA529))))))))))))))))))))))

def t3ar3 : RExpr :=
  (Expr aU (Esseq (Pattern aU (CaseBase ((some t3symA525), (BTy_loaded OTy_integer)))) (Expr aU (Ebound (Expr aU (Ewseq (Pattern aU (CaseBase ((some t3symA526), (BTy_object OTy_pointer)))) (Expr aU (Epure (Pexpr aU () (PEsym t3symV)))) (Expr aU (Eaction (Paction Pos (Action L0 empty_annotation (Load0 (Pexpr aU () (PEval (Vctype intCty))) (Pexpr aU () (PEsym t3symA526)) NA))))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Eaction (Paction Pos (Action L0 empty_annotation (Store0 false (Pexpr aU () (PEval (Vctype intCty))) (Pexpr aU () (PEsym t3symx)) (Pexpr aU () (PEcall (Sym t3symCLI) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym t3symA525))])) NA))))) (Expr aU (Esseq (Pattern aU (CaseBase ((some t3symA528), (BTy_loaded OTy_integer)))) (Expr aU (Ebound (Expr aU (Ewseq (Pattern aU (CaseBase ((some t3symA527), (BTy_object OTy_pointer)))) (Expr aU (Epure (Pexpr aU () (PEsym t3symx)))) (Expr aU (Eaction (Paction Pos (Action L0 empty_annotation (Load0 (Pexpr aU () (PEval (Vctype intCty))) (Pexpr aU () (PEsym t3symA527)) NA))))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Eaction (Paction Pos (Action L0 empty_annotation (Kill (Static0 intCty) (Pexpr aU () (PEsym t3symx))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Erun empty_annotation t3symRet524 [(Pexpr aU () (PEcall (Sym t3symCLI) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym t3symA528))]))])) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Eaction (Paction Pos (Action L0 empty_annotation (Kill (Static0 intCty) (Pexpr aU () (PEsym t3symx))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Epure (Pexpr aU () (PEval Vunit)))) (Expr aU (Esave (t3symRet524, (BTy_loaded OTy_integer)) [(t3symA529, (((BTy_loaded OTy_integer), none), (Pexpr aU () (PEundef L0 UB088_reached_end_of_function))))] (Expr aU (Epure (Pexpr aU () (PEsym t3symA529))))))))))))))))))))

def t3ar4 : RExpr :=
  (Expr aU (Esseq (Pattern aU (CaseBase ((some t3symA525), (BTy_loaded OTy_integer)))) (Expr aU (Ebound (Expr aU (Ewseq (Pattern aU (CaseBase ((some t3symA526), (BTy_object OTy_pointer)))) (Expr aU (Epure (Pexpr [] () (PEval xPtrV)))) (Expr aU (Eaction (Paction Pos (Action L0 empty_annotation (Load0 (Pexpr aU () (PEval (Vctype intCty))) (Pexpr aU () (PEsym t3symA526)) NA))))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Eaction (Paction Pos (Action L0 empty_annotation (Store0 false (Pexpr aU () (PEval (Vctype intCty))) (Pexpr aU () (PEsym t3symx)) (Pexpr aU () (PEcall (Sym t3symCLI) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym t3symA525))])) NA))))) (Expr aU (Esseq (Pattern aU (CaseBase ((some t3symA528), (BTy_loaded OTy_integer)))) (Expr aU (Ebound (Expr aU (Ewseq (Pattern aU (CaseBase ((some t3symA527), (BTy_object OTy_pointer)))) (Expr aU (Epure (Pexpr aU () (PEsym t3symx)))) (Expr aU (Eaction (Paction Pos (Action L0 empty_annotation (Load0 (Pexpr aU () (PEval (Vctype intCty))) (Pexpr aU () (PEsym t3symA527)) NA))))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Eaction (Paction Pos (Action L0 empty_annotation (Kill (Static0 intCty) (Pexpr aU () (PEsym t3symx))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Erun empty_annotation t3symRet524 [(Pexpr aU () (PEcall (Sym t3symCLI) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym t3symA528))]))])) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Eaction (Paction Pos (Action L0 empty_annotation (Kill (Static0 intCty) (Pexpr aU () (PEsym t3symx))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Epure (Pexpr aU () (PEval Vunit)))) (Expr aU (Esave (t3symRet524, (BTy_loaded OTy_integer)) [(t3symA529, (((BTy_loaded OTy_integer), none), (Pexpr aU () (PEundef L0 UB088_reached_end_of_function))))] (Expr aU (Epure (Pexpr aU () (PEsym t3symA529))))))))))))))))))))

def t3ar5 : RExpr :=
  (Expr aU (Esseq (Pattern aU (CaseBase ((some t3symA525), (BTy_loaded OTy_integer)))) (Expr aU (Ebound (Expr aU (Eaction (Paction Pos (Action L0 empty_annotation (Load0 (Pexpr aU () (PEval (Vctype intCty))) (Pexpr aU () (PEsym t3symA526)) NA))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Eaction (Paction Pos (Action L0 empty_annotation (Store0 false (Pexpr aU () (PEval (Vctype intCty))) (Pexpr aU () (PEsym t3symx)) (Pexpr aU () (PEcall (Sym t3symCLI) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym t3symA525))])) NA))))) (Expr aU (Esseq (Pattern aU (CaseBase ((some t3symA528), (BTy_loaded OTy_integer)))) (Expr aU (Ebound (Expr aU (Ewseq (Pattern aU (CaseBase ((some t3symA527), (BTy_object OTy_pointer)))) (Expr aU (Epure (Pexpr aU () (PEsym t3symx)))) (Expr aU (Eaction (Paction Pos (Action L0 empty_annotation (Load0 (Pexpr aU () (PEval (Vctype intCty))) (Pexpr aU () (PEsym t3symA527)) NA))))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Eaction (Paction Pos (Action L0 empty_annotation (Kill (Static0 intCty) (Pexpr aU () (PEsym t3symx))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Erun empty_annotation t3symRet524 [(Pexpr aU () (PEcall (Sym t3symCLI) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym t3symA528))]))])) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Eaction (Paction Pos (Action L0 empty_annotation (Kill (Static0 intCty) (Pexpr aU () (PEsym t3symx))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Epure (Pexpr aU () (PEval Vunit)))) (Expr aU (Esave (t3symRet524, (BTy_loaded OTy_integer)) [(t3symA529, (((BTy_loaded OTy_integer), none), (Pexpr aU () (PEundef L0 UB088_reached_end_of_function))))] (Expr aU (Epure (Pexpr aU () (PEsym t3symA529))))))))))))))))))))

def t3ar6 : RExpr :=
  (Expr aU (Esseq (Pattern aU (CaseBase ((some t3symA525), (BTy_loaded OTy_integer)))) (Expr aU (Ebound (Expr aU (Eaction (Paction Pos (Action L0 empty_annotation (Load0 (Pexpr [] () (PEval (Vctype intCty))) (Pexpr [] () (PEval xPtrV)) NA))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Eaction (Paction Pos (Action L0 empty_annotation (Store0 false (Pexpr aU () (PEval (Vctype intCty))) (Pexpr aU () (PEsym t3symx)) (Pexpr aU () (PEcall (Sym t3symCLI) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym t3symA525))])) NA))))) (Expr aU (Esseq (Pattern aU (CaseBase ((some t3symA528), (BTy_loaded OTy_integer)))) (Expr aU (Ebound (Expr aU (Ewseq (Pattern aU (CaseBase ((some t3symA527), (BTy_object OTy_pointer)))) (Expr aU (Epure (Pexpr aU () (PEsym t3symx)))) (Expr aU (Eaction (Paction Pos (Action L0 empty_annotation (Load0 (Pexpr aU () (PEval (Vctype intCty))) (Pexpr aU () (PEsym t3symA527)) NA))))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Eaction (Paction Pos (Action L0 empty_annotation (Kill (Static0 intCty) (Pexpr aU () (PEsym t3symx))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Erun empty_annotation t3symRet524 [(Pexpr aU () (PEcall (Sym t3symCLI) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym t3symA528))]))])) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Eaction (Paction Pos (Action L0 empty_annotation (Kill (Static0 intCty) (Pexpr aU () (PEsym t3symx))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Epure (Pexpr aU () (PEval Vunit)))) (Expr aU (Esave (t3symRet524, (BTy_loaded OTy_integer)) [(t3symA529, (((BTy_loaded OTy_integer), none), (Pexpr aU () (PEundef L0 UB088_reached_end_of_function))))] (Expr aU (Epure (Pexpr aU () (PEsym t3symA529))))))))))))))))))))

def t3ar7 (x : Int) : RExpr :=
  (Expr aU (Esseq (Pattern aU (CaseBase ((some t3symA525), (BTy_loaded OTy_integer)))) (Expr aU (Ebound (Expr [] (Eannot [(DA_pos [] (CerbMem.Footprint.FP .R 281474976710648 4))] (Expr [] (Epure (Pexpr [] () (PEval (loadedV x))))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Eaction (Paction Pos (Action L0 empty_annotation (Store0 false (Pexpr aU () (PEval (Vctype intCty))) (Pexpr aU () (PEsym t3symx)) (Pexpr aU () (PEcall (Sym t3symCLI) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym t3symA525))])) NA))))) (Expr aU (Esseq (Pattern aU (CaseBase ((some t3symA528), (BTy_loaded OTy_integer)))) (Expr aU (Ebound (Expr aU (Ewseq (Pattern aU (CaseBase ((some t3symA527), (BTy_object OTy_pointer)))) (Expr aU (Epure (Pexpr aU () (PEsym t3symx)))) (Expr aU (Eaction (Paction Pos (Action L0 empty_annotation (Load0 (Pexpr aU () (PEval (Vctype intCty))) (Pexpr aU () (PEsym t3symA527)) NA))))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Eaction (Paction Pos (Action L0 empty_annotation (Kill (Static0 intCty) (Pexpr aU () (PEsym t3symx))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Erun empty_annotation t3symRet524 [(Pexpr aU () (PEcall (Sym t3symCLI) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym t3symA528))]))])) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Eaction (Paction Pos (Action L0 empty_annotation (Kill (Static0 intCty) (Pexpr aU () (PEsym t3symx))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Epure (Pexpr aU () (PEval Vunit)))) (Expr aU (Esave (t3symRet524, (BTy_loaded OTy_integer)) [(t3symA529, (((BTy_loaded OTy_integer), none), (Pexpr aU () (PEundef L0 UB088_reached_end_of_function))))] (Expr aU (Epure (Pexpr aU () (PEsym t3symA529))))))))))))))))))))

def t3ar8 (x : Int) : RExpr :=
  (Expr aU (Esseq (Pattern aU (CaseBase ((some t3symA525), (BTy_loaded OTy_integer)))) (Expr [] (Epure (Pexpr [] () (PEval (loadedV x))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Eaction (Paction Pos (Action L0 empty_annotation (Store0 false (Pexpr aU () (PEval (Vctype intCty))) (Pexpr aU () (PEsym t3symx)) (Pexpr aU () (PEcall (Sym t3symCLI) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym t3symA525))])) NA))))) (Expr aU (Esseq (Pattern aU (CaseBase ((some t3symA528), (BTy_loaded OTy_integer)))) (Expr aU (Ebound (Expr aU (Ewseq (Pattern aU (CaseBase ((some t3symA527), (BTy_object OTy_pointer)))) (Expr aU (Epure (Pexpr aU () (PEsym t3symx)))) (Expr aU (Eaction (Paction Pos (Action L0 empty_annotation (Load0 (Pexpr aU () (PEval (Vctype intCty))) (Pexpr aU () (PEsym t3symA527)) NA))))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Eaction (Paction Pos (Action L0 empty_annotation (Kill (Static0 intCty) (Pexpr aU () (PEsym t3symx))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Erun empty_annotation t3symRet524 [(Pexpr aU () (PEcall (Sym t3symCLI) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym t3symA528))]))])) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Eaction (Paction Pos (Action L0 empty_annotation (Kill (Static0 intCty) (Pexpr aU () (PEsym t3symx))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Epure (Pexpr aU () (PEval Vunit)))) (Expr aU (Esave (t3symRet524, (BTy_loaded OTy_integer)) [(t3symA529, (((BTy_loaded OTy_integer), none), (Pexpr aU () (PEundef L0 UB088_reached_end_of_function))))] (Expr aU (Epure (Pexpr aU () (PEsym t3symA529))))))))))))))))))))

def t3ar9 : RExpr :=
  (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Eaction (Paction Pos (Action L0 empty_annotation (Store0 false (Pexpr aU () (PEval (Vctype intCty))) (Pexpr aU () (PEsym t3symx)) (Pexpr aU () (PEcall (Sym t3symCLI) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym t3symA525))])) NA))))) (Expr aU (Esseq (Pattern aU (CaseBase ((some t3symA528), (BTy_loaded OTy_integer)))) (Expr aU (Ebound (Expr aU (Ewseq (Pattern aU (CaseBase ((some t3symA527), (BTy_object OTy_pointer)))) (Expr aU (Epure (Pexpr aU () (PEsym t3symx)))) (Expr aU (Eaction (Paction Pos (Action L0 empty_annotation (Load0 (Pexpr aU () (PEval (Vctype intCty))) (Pexpr aU () (PEsym t3symA527)) NA))))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Eaction (Paction Pos (Action L0 empty_annotation (Kill (Static0 intCty) (Pexpr aU () (PEsym t3symx))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Erun empty_annotation t3symRet524 [(Pexpr aU () (PEcall (Sym t3symCLI) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym t3symA528))]))])) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Eaction (Paction Pos (Action L0 empty_annotation (Kill (Static0 intCty) (Pexpr aU () (PEsym t3symx))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Epure (Pexpr aU () (PEval Vunit)))) (Expr aU (Esave (t3symRet524, (BTy_loaded OTy_integer)) [(t3symA529, (((BTy_loaded OTy_integer), none), (Pexpr aU () (PEundef L0 UB088_reached_end_of_function))))] (Expr aU (Epure (Pexpr aU () (PEsym t3symA529))))))))))))))))))

def t3ar10 (x : Int) : RExpr :=
  (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Eaction (Paction Pos (Action L0 empty_annotation (Store0 false (Pexpr [] () (PEval (Vctype intCty))) (Pexpr [] () (PEval locPtrV)) (Pexpr [] () (PEval (loadedV x))) NA))))) (Expr aU (Esseq (Pattern aU (CaseBase ((some t3symA528), (BTy_loaded OTy_integer)))) (Expr aU (Ebound (Expr aU (Ewseq (Pattern aU (CaseBase ((some t3symA527), (BTy_object OTy_pointer)))) (Expr aU (Epure (Pexpr aU () (PEsym t3symx)))) (Expr aU (Eaction (Paction Pos (Action L0 empty_annotation (Load0 (Pexpr aU () (PEval (Vctype intCty))) (Pexpr aU () (PEsym t3symA527)) NA))))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Eaction (Paction Pos (Action L0 empty_annotation (Kill (Static0 intCty) (Pexpr aU () (PEsym t3symx))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Erun empty_annotation t3symRet524 [(Pexpr aU () (PEcall (Sym t3symCLI) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym t3symA528))]))])) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Eaction (Paction Pos (Action L0 empty_annotation (Kill (Static0 intCty) (Pexpr aU () (PEsym t3symx))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Epure (Pexpr aU () (PEval Vunit)))) (Expr aU (Esave (t3symRet524, (BTy_loaded OTy_integer)) [(t3symA529, (((BTy_loaded OTy_integer), none), (Pexpr aU () (PEundef L0 UB088_reached_end_of_function))))] (Expr aU (Epure (Pexpr aU () (PEsym t3symA529))))))))))))))))))

def t3ar11 : RExpr :=
  (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr [] (Eannot [(DA_pos [] (CerbMem.Footprint.FP .W 281474976710640 4))] (Expr [] (Epure (Pexpr [] () (PEval Vunit)))))) (Expr aU (Esseq (Pattern aU (CaseBase ((some t3symA528), (BTy_loaded OTy_integer)))) (Expr aU (Ebound (Expr aU (Ewseq (Pattern aU (CaseBase ((some t3symA527), (BTy_object OTy_pointer)))) (Expr aU (Epure (Pexpr aU () (PEsym t3symx)))) (Expr aU (Eaction (Paction Pos (Action L0 empty_annotation (Load0 (Pexpr aU () (PEval (Vctype intCty))) (Pexpr aU () (PEsym t3symA527)) NA))))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Eaction (Paction Pos (Action L0 empty_annotation (Kill (Static0 intCty) (Pexpr aU () (PEsym t3symx))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Erun empty_annotation t3symRet524 [(Pexpr aU () (PEcall (Sym t3symCLI) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym t3symA528))]))])) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Eaction (Paction Pos (Action L0 empty_annotation (Kill (Static0 intCty) (Pexpr aU () (PEsym t3symx))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Epure (Pexpr aU () (PEval Vunit)))) (Expr aU (Esave (t3symRet524, (BTy_loaded OTy_integer)) [(t3symA529, (((BTy_loaded OTy_integer), none), (Pexpr aU () (PEundef L0 UB088_reached_end_of_function))))] (Expr aU (Epure (Pexpr aU () (PEsym t3symA529))))))))))))))))))

def t3ar12 : RExpr :=
  (Expr [] (Eannot [(DA_pos [] (CerbMem.Footprint.FP .W 281474976710640 4))] (Expr aU (Esseq (Pattern aU (CaseBase ((some t3symA528), (BTy_loaded OTy_integer)))) (Expr aU (Ebound (Expr aU (Ewseq (Pattern aU (CaseBase ((some t3symA527), (BTy_object OTy_pointer)))) (Expr aU (Epure (Pexpr aU () (PEsym t3symx)))) (Expr aU (Eaction (Paction Pos (Action L0 empty_annotation (Load0 (Pexpr aU () (PEval (Vctype intCty))) (Pexpr aU () (PEsym t3symA527)) NA))))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Eaction (Paction Pos (Action L0 empty_annotation (Kill (Static0 intCty) (Pexpr aU () (PEsym t3symx))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Erun empty_annotation t3symRet524 [(Pexpr aU () (PEcall (Sym t3symCLI) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym t3symA528))]))])) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Eaction (Paction Pos (Action L0 empty_annotation (Kill (Static0 intCty) (Pexpr aU () (PEsym t3symx))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Epure (Pexpr aU () (PEval Vunit)))) (Expr aU (Esave (t3symRet524, (BTy_loaded OTy_integer)) [(t3symA529, (((BTy_loaded OTy_integer), none), (Pexpr aU () (PEundef L0 UB088_reached_end_of_function))))] (Expr aU (Epure (Pexpr aU () (PEsym t3symA529))))))))))))))))))

def t3ar13 : RExpr :=
  (Expr [] (Eannot [(DA_pos [] (CerbMem.Footprint.FP .W 281474976710640 4))] (Expr aU (Esseq (Pattern aU (CaseBase ((some t3symA528), (BTy_loaded OTy_integer)))) (Expr aU (Ebound (Expr aU (Ewseq (Pattern aU (CaseBase ((some t3symA527), (BTy_object OTy_pointer)))) (Expr aU (Epure (Pexpr [] () (PEval locPtrV)))) (Expr aU (Eaction (Paction Pos (Action L0 empty_annotation (Load0 (Pexpr aU () (PEval (Vctype intCty))) (Pexpr aU () (PEsym t3symA527)) NA))))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Eaction (Paction Pos (Action L0 empty_annotation (Kill (Static0 intCty) (Pexpr aU () (PEsym t3symx))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Erun empty_annotation t3symRet524 [(Pexpr aU () (PEcall (Sym t3symCLI) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym t3symA528))]))])) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Eaction (Paction Pos (Action L0 empty_annotation (Kill (Static0 intCty) (Pexpr aU () (PEsym t3symx))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Epure (Pexpr aU () (PEval Vunit)))) (Expr aU (Esave (t3symRet524, (BTy_loaded OTy_integer)) [(t3symA529, (((BTy_loaded OTy_integer), none), (Pexpr aU () (PEundef L0 UB088_reached_end_of_function))))] (Expr aU (Epure (Pexpr aU () (PEsym t3symA529))))))))))))))))))

def t3ar14 : RExpr :=
  (Expr [] (Eannot [(DA_pos [] (CerbMem.Footprint.FP .W 281474976710640 4))] (Expr aU (Esseq (Pattern aU (CaseBase ((some t3symA528), (BTy_loaded OTy_integer)))) (Expr aU (Ebound (Expr aU (Eaction (Paction Pos (Action L0 empty_annotation (Load0 (Pexpr aU () (PEval (Vctype intCty))) (Pexpr aU () (PEsym t3symA527)) NA))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Eaction (Paction Pos (Action L0 empty_annotation (Kill (Static0 intCty) (Pexpr aU () (PEsym t3symx))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Erun empty_annotation t3symRet524 [(Pexpr aU () (PEcall (Sym t3symCLI) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym t3symA528))]))])) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Eaction (Paction Pos (Action L0 empty_annotation (Kill (Static0 intCty) (Pexpr aU () (PEsym t3symx))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Epure (Pexpr aU () (PEval Vunit)))) (Expr aU (Esave (t3symRet524, (BTy_loaded OTy_integer)) [(t3symA529, (((BTy_loaded OTy_integer), none), (Pexpr aU () (PEundef L0 UB088_reached_end_of_function))))] (Expr aU (Epure (Pexpr aU () (PEsym t3symA529))))))))))))))))))

def t3ar15 : RExpr :=
  (Expr [] (Eannot [(DA_pos [] (CerbMem.Footprint.FP .W 281474976710640 4))] (Expr aU (Esseq (Pattern aU (CaseBase ((some t3symA528), (BTy_loaded OTy_integer)))) (Expr aU (Ebound (Expr aU (Eaction (Paction Pos (Action L0 empty_annotation (Load0 (Pexpr [] () (PEval (Vctype intCty))) (Pexpr [] () (PEval locPtrV)) NA))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Eaction (Paction Pos (Action L0 empty_annotation (Kill (Static0 intCty) (Pexpr aU () (PEsym t3symx))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Erun empty_annotation t3symRet524 [(Pexpr aU () (PEcall (Sym t3symCLI) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym t3symA528))]))])) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Eaction (Paction Pos (Action L0 empty_annotation (Kill (Static0 intCty) (Pexpr aU () (PEsym t3symx))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Epure (Pexpr aU () (PEval Vunit)))) (Expr aU (Esave (t3symRet524, (BTy_loaded OTy_integer)) [(t3symA529, (((BTy_loaded OTy_integer), none), (Pexpr aU () (PEundef L0 UB088_reached_end_of_function))))] (Expr aU (Epure (Pexpr aU () (PEsym t3symA529))))))))))))))))))

def t3ar16 (x : Int) : RExpr :=
  (Expr [] (Eannot [(DA_pos [] (CerbMem.Footprint.FP .W 281474976710640 4))] (Expr aU (Esseq (Pattern aU (CaseBase ((some t3symA528), (BTy_loaded OTy_integer)))) (Expr aU (Ebound (Expr [] (Eannot [(DA_pos [] (CerbMem.Footprint.FP .R 281474976710640 4))] (Expr [] (Epure (Pexpr [] () (PEval (loadedV x))))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Eaction (Paction Pos (Action L0 empty_annotation (Kill (Static0 intCty) (Pexpr aU () (PEsym t3symx))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Erun empty_annotation t3symRet524 [(Pexpr aU () (PEcall (Sym t3symCLI) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym t3symA528))]))])) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Eaction (Paction Pos (Action L0 empty_annotation (Kill (Static0 intCty) (Pexpr aU () (PEsym t3symx))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Epure (Pexpr aU () (PEval Vunit)))) (Expr aU (Esave (t3symRet524, (BTy_loaded OTy_integer)) [(t3symA529, (((BTy_loaded OTy_integer), none), (Pexpr aU () (PEundef L0 UB088_reached_end_of_function))))] (Expr aU (Epure (Pexpr aU () (PEsym t3symA529))))))))))))))))))

def t3ar17 (x : Int) : RExpr :=
  (Expr [] (Eannot [(DA_pos [] (CerbMem.Footprint.FP .W 281474976710640 4))] (Expr aU (Esseq (Pattern aU (CaseBase ((some t3symA528), (BTy_loaded OTy_integer)))) (Expr [] (Epure (Pexpr [] () (PEval (loadedV x))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Eaction (Paction Pos (Action L0 empty_annotation (Kill (Static0 intCty) (Pexpr aU () (PEsym t3symx))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Erun empty_annotation t3symRet524 [(Pexpr aU () (PEcall (Sym t3symCLI) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym t3symA528))]))])) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Eaction (Paction Pos (Action L0 empty_annotation (Kill (Static0 intCty) (Pexpr aU () (PEsym t3symx))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Epure (Pexpr aU () (PEval Vunit)))) (Expr aU (Esave (t3symRet524, (BTy_loaded OTy_integer)) [(t3symA529, (((BTy_loaded OTy_integer), none), (Pexpr aU () (PEundef L0 UB088_reached_end_of_function))))] (Expr aU (Epure (Pexpr aU () (PEsym t3symA529))))))))))))))))))

def t3ar18 : RExpr :=
  (Expr [] (Eannot [(DA_pos [] (CerbMem.Footprint.FP .W 281474976710640 4))] (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Eaction (Paction Pos (Action L0 empty_annotation (Kill (Static0 intCty) (Pexpr aU () (PEsym t3symx))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Erun empty_annotation t3symRet524 [(Pexpr aU () (PEcall (Sym t3symCLI) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym t3symA528))]))])) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Eaction (Paction Pos (Action L0 empty_annotation (Kill (Static0 intCty) (Pexpr aU () (PEsym t3symx))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Epure (Pexpr aU () (PEval Vunit)))) (Expr aU (Esave (t3symRet524, (BTy_loaded OTy_integer)) [(t3symA529, (((BTy_loaded OTy_integer), none), (Pexpr aU () (PEundef L0 UB088_reached_end_of_function))))] (Expr aU (Epure (Pexpr aU () (PEsym t3symA529))))))))))))))))

def t3ar19 : RExpr :=
  (Expr [] (Eannot [(DA_pos [] (CerbMem.Footprint.FP .W 281474976710640 4))] (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Eaction (Paction Pos (Action L0 empty_annotation (Kill (Static0 intCty) (Pexpr [] () (PEval locPtrV))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Erun empty_annotation t3symRet524 [(Pexpr aU () (PEcall (Sym t3symCLI) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym t3symA528))]))])) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Eaction (Paction Pos (Action L0 empty_annotation (Kill (Static0 intCty) (Pexpr aU () (PEsym t3symx))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Epure (Pexpr aU () (PEval Vunit)))) (Expr aU (Esave (t3symRet524, (BTy_loaded OTy_integer)) [(t3symA529, (((BTy_loaded OTy_integer), none), (Pexpr aU () (PEundef L0 UB088_reached_end_of_function))))] (Expr aU (Epure (Pexpr aU () (PEsym t3symA529))))))))))))))))

def t3ar20 : RExpr :=
  (Expr [] (Eannot [(DA_pos [] (CerbMem.Footprint.FP .W 281474976710640 4))] (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr [] (Epure (Pexpr [] () (PEval Vunit)))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Erun empty_annotation t3symRet524 [(Pexpr aU () (PEcall (Sym t3symCLI) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym t3symA528))]))])) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Eaction (Paction Pos (Action L0 empty_annotation (Kill (Static0 intCty) (Pexpr aU () (PEsym t3symx))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Epure (Pexpr aU () (PEval Vunit)))) (Expr aU (Esave (t3symRet524, (BTy_loaded OTy_integer)) [(t3symA529, (((BTy_loaded OTy_integer), none), (Pexpr aU () (PEundef L0 UB088_reached_end_of_function))))] (Expr aU (Epure (Pexpr aU () (PEsym t3symA529))))))))))))))))

def t3ar21 : RExpr :=
  (Expr [] (Eannot [(DA_pos [] (CerbMem.Footprint.FP .W 281474976710640 4))] (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Erun empty_annotation t3symRet524 [(Pexpr aU () (PEcall (Sym t3symCLI) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym t3symA528))]))])) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Eaction (Paction Pos (Action L0 empty_annotation (Kill (Static0 intCty) (Pexpr aU () (PEsym t3symx))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Epure (Pexpr aU () (PEval Vunit)))) (Expr aU (Esave (t3symRet524, (BTy_loaded OTy_integer)) [(t3symA529, (((BTy_loaded OTy_integer), none), (Pexpr aU () (PEundef L0 UB088_reached_end_of_function))))] (Expr aU (Epure (Pexpr aU () (PEsym t3symA529))))))))))))))

def t3ar22 : RExpr :=
  (Expr aU (Epure (Pexpr aU () (PEsym t3symA529))))

def t3arDone (x : Int) : RExpr :=
  (Expr aU (Epure (Pexpr [] () (PEval (loadedV x)))))


-- pre-0 NEW {'v': 'xPtrV'}
-- pre-3 NEW {'x': 'locPtrV'}
-- pre-5 NEW {'a_526': 'xPtrV'}
-- pre-9 NEW {'a_525': '(loadedV 7)'}
-- pre-14 NEW {'a_527': 'locPtrV'}
-- pre-18 NEW {'a_528': '(loadedV 7)'}
-- pre-22 NEW {'a_529': '(loadedV 7)'}
-- post-1 TRACE [(ME_allocate_object 0 (PrefOther "Core") (.IV .Prov_none (4)) intCty none locPtr)]
-- post-6 TRACE [(ME_load L0 none intCty xPtr MV=MVinteger (Signed Int_) (.IV .Prov_none (7))), (ME_allocate_object 0 (PrefOther "Core") (.IV .Prov_none (4)) intCty none locPtr)]
-- post-10 TRACE [(ME_store L0 none intCty false locPtr MV=MVinteger (Signed Int_) (.IV .Prov_none (7))), (ME_load L0 none intCty xPtr MV=MVinteger (Signed Int_) (.IV .Prov_none (7))), (ME_allocate_object 0 (PrefOther "Core") (.IV .Prov_none (4)) intCty none locPtr)]
-- post-15 TRACE [(ME_load L0 none intCty locPtr MV=MVinteger (Signed Int_) (.IV .Prov_none (7))), (ME_store L0 none intCty false locPtr MV=MVinteger (Signed Int_) (.IV .Prov_none (7))), (ME_load L0 none intCty xPtr MV=MVinteger (Signed Int_) (.IV .Prov_none (7))), (ME_allocate_object 0 (PrefOther "Core") (.IV .Prov_none (4)) intCty none locPtr)]
-- post-19 TRACE [(ME_kill L0 false locPtr), (ME_load L0 none intCty locPtr MV=MVinteger (Signed Int_) (.IV .Prov_none (7))), (ME_store L0 none intCty false locPtr MV=MVinteger (Signed Int_) (.IV .Prov_none (7))), (ME_load L0 none intCty xPtr MV=MVinteger (Signed Int_) (.IV .Prov_none (7))), (ME_allocate_object 0 (PrefOther "Core") (.IV .Prov_none (4)) intCty none locPtr)]

/-! ## The T3 families -/

@[reducible] def t3Th (arena : RExpr) (f₁ : Fmap sym value) :
    thread_state :=
  { arena := arena,
    stack0 := Stack_empty,
    errno := errPtr,
    current_loc := L0,
    exec_loc := ELoc_normal [(roundtripT3Sym, CerbLocation.other "RelSem.callND")],
    env := [f₁],
    current_proc_opt := some roundtripT3Sym }

@[reducible] def t3σ (arena : RExpr) (f₁ : Fmap sym value)
    (tS aS eS sS : Nat) (ls : CerbMem.MemState)
    (tr : List trace_event) (n : Nat) : driver_state :=
  { core_file := t3File,
    core_extern := create_extern_symmap t3File,
    core_state0 :=
      { thread_states := [(0, (none, t3Th arena f₁))],
        io := initial_io_state },
    core_run_state0 :=
      { tid_supply := tS, aid_supply := aS, excluded_supply := eS,
        sym_supply := sS,
        labeled := (initial_core_run_state_threaded 0
          (collect_labeled_continuations_NEW t3File)).labeled },
    layout_state := ls,
    concurrency_state := symInitialState symInitialPre,
    fs_state0 := CerbFS.fs_initial_state,
    trace := tr,
    symbolic_assoc := fmapEmpty,
    blocked := false,
    dr_step_counter := n }

def t3CtlAt (arena : RExpr) (tr : List trace_event) (n : Nat) :
    driver_state :=
  ctlOf (t3σ arena fmapEmpty 0 0 0 0 CerbMem.initialMemState tr n)

@[reducible] def t3fam (arena : RExpr) (tr : List trace_event)
    (n : Nat) (p : T1P) : driver_state :=
  t3σ arena p.f₁ p.tS p.aS p.eS p.sS p.ls tr n

theorem t3_inv {σ : driver_state} {arena : RExpr}
    {tr : List trace_event} {n : Nat}
    (h : ctlOf σ = t3CtlAt arena tr n) :
    ∃ p : T1P, σ = t3fam arena tr n p := by
  obtain ⟨cf, ce, cs, crs, ls, ccs, fs0, tr', sa, bl, ctr'⟩ := σ
  obtain ⟨ths, io⟩ := cs
  obtain ⟨tS, aS, eS, sS, lab⟩ := crs
  have h' := h
  simp only [t3CtlAt, ctlOf, t3σ, eraseEnvs, driver_state.mk.injEq,
    core_state.mk.injEq, core_run_state.mk.injEq] at h'
  obtain ⟨hcf, hce, ⟨hths, hio⟩, ⟨-, -, -, -, hlab⟩, -, hccs, hfs,
    htr, hsa, hbl, hctr⟩ := h'
  cases ths with
  | nil => simp at hths
  | cons t rest =>
    obtain ⟨tid, pp, th⟩ := t
    obtain ⟨arena', stack', errno', env', proc', exec', loc'⟩ := th
    simp only [List.map_cons, List.map_nil, List.cons.injEq,
      List.map_eq_nil_iff, Prod.mk.injEq, eraseThreadEnv, t3Th,
      thread_state.mk.injEq] at hths
    obtain ⟨⟨htid0, hp, harena, hstack, herrno, henv, hproc, hexec,
      hloc⟩, hrest⟩ := hths
    cases env' with
    | nil => simp at henv
    | cons f₁ fr =>
      simp only [List.map_cons, List.map_nil, List.cons.injEq,
        List.map_eq_nil_iff] at henv
      obtain ⟨-, hfr⟩ := henv
      refine ⟨⟨f₁, tS, aS, eS, sS, ls⟩, ?_⟩
      subst hcf hce htid0 hp harena hstack herrno hproc hexec hloc
        hccs hfs htr hsa hbl hctr hio hrest hfr hlab
      rfl

theorem t3fam_frame {arena : RExpr} {tr : List trace_event} {n : Nat}
    {p : T1P} (hwf : EnvWf (t3fam arena tr n p)) :
    EnvWfFrame p.f₁ :=
  hwf p.f₁ (by
    show p.f₁ ∈ thread0Env _
    simp [thread0Env])

/-! ## The stage-0 family -/

@[reducible] def t3Th0 (arena : RExpr) (f₁ : Fmap sym value) :
    thread_state :=
  { arena := arena,
    stack0 := Stack_empty,
    errno := errPtr,
    current_loc := CerbLocation.other "RelSem.callND",
    exec_loc := ELoc_normal [(roundtripT3Sym, CerbLocation.other "RelSem.callND")],
    env := [f₁],
    current_proc_opt := some roundtripT3Sym }

@[reducible] def t3σ0 (f₁ : Fmap sym value)
    (tS aS eS sS : Nat) (ls : CerbMem.MemState) : driver_state :=
  { core_file := t3File,
    core_extern := create_extern_symmap t3File,
    core_state0 :=
      { thread_states := [(0, (none, t3Th0 t3ar0 f₁))],
        io := initial_io_state },
    core_run_state0 :=
      { tid_supply := tS, aid_supply := aS, excluded_supply := eS,
        sym_supply := sS,
        labeled := (initial_core_run_state_threaded 0
          (collect_labeled_continuations_NEW t3File)).labeled },
    layout_state := ls,
    concurrency_state := symInitialState symInitialPre,
    fs_state0 := CerbFS.fs_initial_state,
    trace := [],
    symbolic_assoc := fmapEmpty,
    blocked := false,
    dr_step_counter := 0 }

def t3Ctl0 : driver_state :=
  ctlOf (t3σ0 fmapEmpty 0 0 0 0 CerbMem.initialMemState)

@[reducible] def t3fam0 (p : T1P) : driver_state :=
  t3σ0 p.f₁ p.tS p.aS p.eS p.sS p.ls

theorem t3_inv0 {σ : driver_state} (h : ctlOf σ = t3Ctl0) :
    ∃ p : T1P, σ = t3fam0 p := by
  obtain ⟨cf, ce, cs, crs, ls, ccs, fs0, tr', sa, bl, ctr'⟩ := σ
  obtain ⟨ths, io⟩ := cs
  obtain ⟨tS, aS, eS, sS, lab⟩ := crs
  have h' := h
  simp only [t3Ctl0, ctlOf, t3σ0, eraseEnvs, driver_state.mk.injEq,
    core_state.mk.injEq, core_run_state.mk.injEq] at h'
  obtain ⟨hcf, hce, ⟨hths, hio⟩, ⟨-, -, -, -, hlab⟩, -, hccs, hfs,
    htr, hsa, hbl, hctr⟩ := h'
  cases ths with
  | nil => simp at hths
  | cons t rest =>
    obtain ⟨tid, pp, th⟩ := t
    obtain ⟨arena', stack', errno', env', proc', exec', loc'⟩ := th
    simp only [List.map_cons, List.map_nil, List.cons.injEq,
      List.map_eq_nil_iff, Prod.mk.injEq, eraseThreadEnv, t3Th0,
      thread_state.mk.injEq] at hths
    obtain ⟨⟨htid0, hp, harena, hstack, herrno, henv, hproc, hexec,
      hloc⟩, hrest⟩ := hths
    cases env' with
    | nil => simp at henv
    | cons f₁ fr =>
      simp only [List.map_cons, List.map_nil, List.cons.injEq,
        List.map_eq_nil_iff] at henv
      obtain ⟨-, hfr⟩ := henv
      refine ⟨⟨f₁, tS, aS, eS, sS, ls⟩, ?_⟩
      subst hcf hce htid0 hp harena hstack herrno hproc hexec hloc
        hccs hfs htr hsa hbl hctr hio hrest hfr hlab
      rfl

theorem t3fam0_frame {p : T1P} (hwf : EnvWf (t3fam0 p)) :
    EnvWfFrame p.f₁ :=
  hwf p.f₁ (by
    show p.f₁ ∈ thread0Env _
    simp [thread0Env])

/-! ## The initial and post-globals families + stage laws -/

def t3Init (seed : Nat) (ls : CerbMem.MemState) : driver_state :=
  { initial_driver_state_threaded seed t3File t3Fs with
      layout_state := ls }

@[reducible] def t3thGf (f₀ : Fmap sym value) : thread_state :=
  { arena := Expr [] (Epure (Pexpr [] () (PEval Vunit))),
    stack0 := Stack_empty,
    errno := .PV .Prov_none (.PVnull intCty),
    current_loc := CerbLocation.Loc.unknown,
    exec_loc := ELoc_globals,
    env := [f₀],
    current_proc_opt := none }

@[reducible] def t3dGσ (f₀ : Fmap sym value) (tS aS eS sS : Nat)
    (ls : CerbMem.MemState) : driver_state :=
  { core_file := t3File,
    core_extern := create_extern_symmap t3File,
    core_state0 :=
      { thread_states := [(0, (none, t3thGf f₀))],
        io := initial_io_state },
    core_run_state0 :=
      { tid_supply := tS, aid_supply := aS, excluded_supply := eS,
        sym_supply := sS,
        labeled := (initial_core_run_state_threaded 0
          (collect_labeled_continuations_NEW t3File)).labeled },
    layout_state := ls,
    concurrency_state := symInitialState symInitialPre,
    fs_state0 := CerbFS.fs_initial_state,
    trace := [],
    symbolic_assoc := fmapEmpty,
    blocked := false,
    dr_step_counter := 0 }

def t3dGCtl : driver_state :=
  ctlOf (t3dGσ fmapEmpty 0 0 0 0 CerbMem.initialMemState)

@[reducible] def t3dGfam (p : RelSem.T1.DGP) : driver_state :=
  t3dGσ p.f₀ p.tS p.aS p.eS p.sS p.ls

theorem t3dG_inv {σ : driver_state} (h : ctlOf σ = t3dGCtl) :
    ∃ p : RelSem.T1.DGP, σ = t3dGfam p := by
  obtain ⟨cf, ce, cs, crs, ls, ccs, fs0, tr', sa, bl, ctr'⟩ := σ
  obtain ⟨ths, io⟩ := cs
  obtain ⟨tS, aS, eS, sS, lab⟩ := crs
  have h' := h
  simp only [t3dGCtl, ctlOf, t3dGσ, eraseEnvs, driver_state.mk.injEq,
    core_state.mk.injEq, core_run_state.mk.injEq] at h'
  obtain ⟨hcf, hce, ⟨hths, hio⟩, ⟨-, -, -, -, hlab⟩, -, hccs, hfs,
    htr, hsa, hbl, hctr⟩ := h'
  cases ths with
  | nil => simp at hths
  | cons t rest =>
    obtain ⟨tid, pp, th⟩ := t
    obtain ⟨arena', stack', errno', env', proc', exec', loc'⟩ := th
    simp only [List.map_cons, List.map_nil, List.cons.injEq,
      List.map_eq_nil_iff, Prod.mk.injEq, eraseThreadEnv, t3thGf,
      thread_state.mk.injEq] at hths
    obtain ⟨⟨htid0, hp, harena, hstack, herrno, henv, hproc, hexec,
      hloc⟩, hrest⟩ := hths
    cases env' with
    | nil => simp at henv
    | cons f₀ fr =>
      simp only [List.map_cons, List.map_nil, List.cons.injEq,
        List.map_eq_nil_iff] at henv
      obtain ⟨-, hfr⟩ := henv
      refine ⟨⟨f₀, tS, aS, eS, sS, ls⟩, ?_⟩
      subst hcf hce htid0 hp harena hstack herrno hproc hexec hloc
        hccs hfs htr hsa hbl hctr hio hrest hfr hlab
      rfl

theorem t3Init_inv {σ : driver_state} {seed : Nat}
    (h : ctlOf σ = ctlOf (t3Init 0 CerbMem.initialMemState))
    (hs : suppliesOf σ
      = suppliesOf (t3Init seed CerbMem.initialMemState)) :
    σ = t3Init seed σ.layout_state := by
  obtain ⟨cf, ce, cs, crs, ls, ccs, fs0, tr', sa, bl, ctr'⟩ := σ
  obtain ⟨ths, io⟩ := cs
  obtain ⟨tS, aS, eS, sS, lab⟩ := crs
  have h' := h
  simp only [t3Init, ctlOf, eraseEnvs, driver_state.mk.injEq,
    core_state.mk.injEq, core_run_state.mk.injEq] at h'
  obtain ⟨hcf, hce, ⟨hths, hio⟩, ⟨-, -, -, -, hlab⟩, -, hccs, hfs,
    htr, hsa, hbl, hctr⟩ := h'
  have hs' := hs
  simp only [suppliesOf, t3Init, Supplies.mk.injEq] at hs'
  obtain ⟨hts, has, hes, hss⟩ := hs'
  cases ths with
  | cons t rest =>
    rw [show (initial_driver_state_threaded 0 t3File
        t3Fs).core_state0.thread_states
      = ([] : List (Nat × (Option thread_id × thread_state)))
      from rfl] at hths
    simp at hths
  | nil =>
    subst hcf hce hccs hfs htr hsa hbl hctr hio hlab hts has hes hss
    rfl

theorem t3k1_fam (seed : Nat) (ls : CerbMem.MemState) :
    app (driver_globals t3File.tagDefs false t3File)
        (t3Init seed ls)
      = (NDactive 0, t3dGσ fmapEmpty 1 0 0 seed ls) := rfl

theorem t3k3_any (σ : driver_state) :
    app (resolveFunSym t3File "roundtrip") σ
      = (NDactive roundtripT3Sym, σ) := rfl

theorem t3k4_any (σ : driver_state) :
    app (lookupFunBody t3File roundtripT3Sym) σ
      = (NDactive ([(t3symV, BTy_object OTy_pointer)], t3ar0),
         σ) := rfl

theorem t3k5_any (σ : driver_state) :
    app (lookupParamTys t3File roundtripT3Sym) σ
      = (NDactive [signed_int], σ) := rfl

theorem t3_init_ctl_eq (seed : Nat) :
    ctlOf (initial_driver_state_threaded seed t3File t3Fs)
      = ctlOf (t3Init 0 CerbMem.initialMemState) := rfl

theorem t3_init_sup_eq (seed : Nat) :
    suppliesOf (initial_driver_state_threaded seed t3File t3Fs)
      = suppliesOf (t3Init seed CerbMem.initialMemState) := rfl

theorem t3_init_mrest_eq (seed : Nat) :
    memRestOf (initial_driver_state_threaded seed t3File t3Fs)
      = mr0 := rfl


/-! ## The inject/errno memory-stage laws -/

theorem t3k6_fam (x : Int) (σ : driver_state)
    (hmr : memRestOf σ = mr0) (hinv : MemInv σ.layout_state) :
    app (injectArgs t3File.tagDefs 0
          [(t3symV, BTy_object OTy_pointer)] [signed_int] [intValue x]) σ
      = (NDactive [(t3symV, xPtrV)],
         { σ with layout_state :=
             (layoutAllocStore σ.layout_state xAddr 4 allocXS
               (xBytes x)) }) := by
  have hlast : σ.layout_state.lastAddress = mr0.lastAddress := by
    rw [show σ.layout_state.lastAddress = (memRestOf σ).lastAddress
      from rfl, hmr]
  have h0 : σ.layout_state.nextAllocId = 0 := by
    rw [show σ.layout_state.nextAllocId = (memRestOf σ).nextAllocId
      from rfl, hmr]
    rfl
  have halloc := Kit.mem_alloc_block (tid := 0)
    (pref := PrefOther "callND arg") (pv := .Prov_none)
    (alignN := 4) (ty := signed_int) (mem := σ.layout_state)
    (addrOpt := none) (sz := 4) (a := xAddr)
    rfl (by rw [hlast]; rfl) rfl
  have hget1 : (CerbMem.writeBytesTo
      ({ σ.layout_state with
          nextAllocId := σ.layout_state.nextAllocId + 1,
          lastAddress := xAddr,
          allocations := σ.layout_state.allocations.insert
            σ.layout_state.nextAllocId allocXS })
      xAddr (List.replicate 4 uninitB)).allocations.get?
        σ.layout_state.nextAllocId
      = some allocXS := by
    rw [Kit.writeBytesTo_allocations]
    exact Kit.tm_get?_insert_eq _ _ _
  have hstore := Kit.mem_store_block
    (loc := CerbLocation.other "callND arg init") (ty := signed_int)
    (allocId := σ.layout_state.nextAllocId) (addr := xAddr)
    (alloc := allocXS)
    (mem := CerbMem.writeBytesTo
      ({ σ.layout_state with
          nextAllocId := σ.layout_state.nextAllocId + 1,
          lastAddress := xAddr,
          allocations := σ.layout_state.allocations.insert
            σ.layout_state.nextAllocId allocXS })
      xAddr (List.replicate 4 uninitB))
    (mv := CerbMem.integerValueMval (Signed Int_)
      (CerbMem.integerIval x))
    rfl hget1 rfl rfl rfl
    (by rw [Kit.writeBytesTo_funptrmap])
  rw [show xPtrV = Vobject (OVpointer
      (.PV (.Prov_some σ.layout_state.nextAllocId)
        (.PVconcrete none xAddr))) from by rw [h0]; rfl]
  exact RelSem.Laws.inject_ptr_arg1 (memValueFromValue_int x)
    halloc hstore rfl

/-- k8: the errno block at residual facts. -/
theorem t3k8_fam (x : Int) (σ : driver_state)
    (hmr : memRestOf σ = mr1) (hinv : MemInv σ.layout_state) :
    app (liftMem (nd_bind
        (CerbMem.allocateObject 0 (PrefOther "errno")
          (CerbMem.alignofIval signed_int) signed_int none none)
        (fun (ptr_val : CerbMem.PointerValue) =>
          let zero := CerbMem.integerValueMval (Signed Int_)
            (CerbMem.integerIval (0 : Int))
          nd_bind
            (CerbMem.storeM (CerbLocation.other "errno init")
              signed_int false ptr_val zero)
            (fun (_ : CerbMem.Footprint) => nd_return ptr_val)))) σ
      = (NDactive errPtr,
         { σ with layout_state :=
             (layoutAllocStore σ.layout_state errAddr 4 allocErrS
               zeroBytes) }) := by
  have hlast : σ.layout_state.lastAddress = mr1.lastAddress := by
    rw [show σ.layout_state.lastAddress = (memRestOf σ).lastAddress
      from rfl, hmr]
  have h0 : σ.layout_state.nextAllocId = 1 := by
    rw [show σ.layout_state.nextAllocId = (memRestOf σ).nextAllocId
      from rfl, hmr]
    rfl
  have halloc := Kit.mem_alloc_block (tid := 0)
    (pref := PrefOther "errno") (pv := .Prov_none)
    (alignN := 4) (ty := signed_int) (mem := σ.layout_state)
    (addrOpt := none) (sz := 4) (a := errAddr)
    rfl (by rw [hlast]; rfl) rfl
  have hget1 : (CerbMem.writeBytesTo
      ({ σ.layout_state with
          nextAllocId := σ.layout_state.nextAllocId + 1,
          lastAddress := errAddr,
          allocations := σ.layout_state.allocations.insert
            σ.layout_state.nextAllocId allocErrS })
      errAddr (List.replicate 4 uninitB)).allocations.get?
        σ.layout_state.nextAllocId
      = some allocErrS := by
    rw [Kit.writeBytesTo_allocations]
    exact Kit.tm_get?_insert_eq _ _ _
  have hstore := Kit.mem_store_block
    (loc := CerbLocation.other "errno init") (ty := signed_int)
    (allocId := σ.layout_state.nextAllocId) (addr := errAddr)
    (alloc := allocErrS)
    (mem := CerbMem.writeBytesTo
      ({ σ.layout_state with
          nextAllocId := σ.layout_state.nextAllocId + 1,
          lastAddress := errAddr,
          allocations := σ.layout_state.allocations.insert
            σ.layout_state.nextAllocId allocErrS })
      errAddr (List.replicate 4 uninitB))
    (mv := CerbMem.integerValueMval (Signed Int_)
      (CerbMem.integerIval 0))
    rfl hget1 rfl rfl rfl
    (by rw [Kit.writeBytesTo_funptrmap])
  rw [show errPtr = (.PV (.Prov_some σ.layout_state.nextAllocId)
      (.PVconcrete none errAddr) : CerbMem.PointerValue)
    from by rw [h0]; rfl]
  exact RelSem.Laws.callND_errno halloc hstore rfl


/-! ## The Erun conv chain at t3File (the mirror; T1 z-terms) -/

open RelSem.T1 (z0 z1 z2 z3 xIntV)

def t3convPE (b : sym) : generic_pexpr Unit sym :=
  Pexpr aU () (PEcall (Sym RelSem.T1.convLoadedIntSym)
    [Pexpr aU () (PEval (Vctype intCty)), Pexpr aU () (PEsym b)])

theorem t3s0_eq (b : sym) (x : Int) (env : List (Fmap sym value))
    (memo : Option CerbMem.MemState)
    (hb : fmapLookupBy
      (fun (s1 s2 : sym) => ordCompare s1 s2) b
      (create_extern_symmap t3File) = none)
    (ha : lookup_env b env = some (loadedV x)) :
    step_eval_pexpr t3File.tagDefs 0 CerbLocation.Loc.unknown
      (some (CerbLocation.other "RelSem.callND"))
      (create_extern_symmap t3File) env memo t3File false
      (Pexpr [] () (PEcall (Sym RelSem.T1.convLoadedIntSym)
        [Pexpr aU () (PEval (Vctype intCty)),
         Pexpr aU () (PEsym b)]))
      = Result (Defined (z0 x)) := by
  show step_eval_pexpr_lemFuel (999999 + 1) _ _ _ _ _ _ _ _ _ _ = _
  refine se_call (pes' := [Pexpr [] () (PEval (Vctype intCty)),
      Pexpr [] () (PEval (loadedV x))])
    (cvals := [Vctype intCty, loadedV x]) ?_ rfl rfl rfl
  exact eumapM_cons rfl
    (eumapM_cons (se_sym_hit (fuel := 999998) hb ha) eumapM_nil)

theorem t3s1_eq (x : Int) (env : List (Fmap sym value))
    (memo : Option CerbMem.MemState) :
    step_eval_pexpr t3File.tagDefs 0 CerbLocation.Loc.unknown
      (some (CerbLocation.other "RelSem.callND"))
      (create_extern_symmap t3File) env memo t3File false (z0 x)
      = Result (Defined (z1 x)) := rfl

theorem t3s2_eq (x : Int) (env : List (Fmap sym value))
    (memo : Option CerbMem.MemState) :
    step_eval_pexpr t3File.tagDefs 0 CerbLocation.Loc.unknown
      (some (CerbLocation.other "RelSem.callND"))
      (create_extern_symmap t3File) env memo t3File false (z1 x)
      = Result (Defined (z2 x)) := rfl

theorem t3s3_eq (x : Int) (env : List (Fmap sym value))
    (memo : Option CerbMem.MemState) :
    step_eval_pexpr t3File.tagDefs 0 CerbLocation.Loc.unknown
      (some (CerbLocation.other "RelSem.callND"))
      (create_extern_symmap t3File) env memo t3File false (z2 x)
      = Result (Defined (z3 x)) := rfl

theorem t3s4_eq (x : Int) (h1 : -2147483648 ≤ x)
    (h2 : x ≤ 2147483647)
    (env : List (Fmap sym value)) (memo : Option CerbMem.MemState) :
    step_eval_pexpr t3File.tagDefs 0 CerbLocation.Loc.unknown
      (some (CerbLocation.other "RelSem.callND"))
      (create_extern_symmap t3File) env memo t3File false (z3 x)
      = Result (Defined (Pexpr [] () (PEval (loadedV x)))) := by
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
                  (create_extern_symmap t3File) env memo t3File false
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
                  (create_extern_symmap t3File) env memo t3File false
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

theorem t3conv_eval (b : sym) (x : Int) (h1 : -2147483648 ≤ x)
    (h2 : x ≤ 2147483647)
    (env : List (Fmap sym value)) (memo : Option CerbMem.MemState)
    (hb : fmapLookupBy
      (fun (s1 s2 : sym) => ordCompare s1 s2) b
      (create_extern_symmap t3File) = none)
    (ha : lookup_env b env = some (loadedV x)) :
    eval_pexpr_aux2 t3File.tagDefs CerbLocation.Loc.unknown
        (some (CerbLocation.other "RelSem.callND"))
        (create_extern_symmap t3File) env memo t3File (t3convPE b)
      = Result (Defined (Sum.inr (loadedV x))) :=
  (aux2_step 999999 _ _ _ _ _ _ _ rfl
      (by intro a xs h; cases h) (t3s0_eq b x env memo hb ha)
      (by rfl)).trans
  ((aux2_step 999998 _ _ _ _ _ _ _
      (show pull_constrained 0 (z0 x) = z0 x from rfl)
      (by intro a xs h; simp [z0] at h) (t3s1_eq x env memo)
      (by rfl)).trans
  ((aux2_step 999997 _ _ _ _ _ _ _
      (show pull_constrained 0 (z1 x) = z1 x from rfl)
      (by intro a xs h; simp [z1] at h) (t3s2_eq x env memo)
      (by rfl)).trans
  ((aux2_step 999996 _ _ _ _ _ _ _
      (show pull_constrained 0 (z2 x) = z2 x from rfl)
      (by intro a xs h; simp [z2] at h) (t3s3_eq x env memo)
      (by rfl)).trans
  (aux2_done 999995 _ _ _ _ _ _ _
      (show pull_constrained 0 (z3 x) = z3 x from rfl)
      (by intro a xs h; simp [z3] at h)
      (t3s4_eq x h1 h2 env memo) (by rfl)))))

theorem t3fullEval_conv (arena : RExpr) (b : sym) (x : Int)
    (h1 : -2147483648 ≤ x) (h2 : x ≤ 2147483647)
    (f₁ : Fmap sym value) (ls : CerbMem.MemState)
    (st : core_run_state)
    (hb : fmapLookupBy
      (fun (s1 s2 : sym) => ordCompare s1 s2) b
      (create_extern_symmap t3File) = none)
    (ha : lookup_env b [f₁] = some (loadedV x)) :
    full_eval_pexpr t3File.tagDefs (t3Th arena f₁)
        (create_extern_symmap t3File) ls t3File (t3convPE b) st
      = Result (Defined (loadedV x), st) := by
  show stExceptUndef_bind _ _ _ = _
  refine (stub_defined (z := Sum.inr (loadedV x)) (st' := st) ?_).trans ?_
  · show runEU (eval_pexpr_aux2 t3File.tagDefs
        CerbLocation.Loc.unknown
        (some (CerbLocation.other "RelSem.callND"))
        (create_extern_symmap t3File) [f₁] (some ls) t3File
        (t3convPE b)) _ = _
    rw [t3conv_eval b x h1 h2 [f₁] (some ls) hb ha]
    rfl
  · rfl


/-! ## Bind patterns + env-write spellings -/

def t3patX : generic_pattern sym :=
  Pattern aU (CaseBase ((some t3symx), BTy_object OTy_pointer))
def t3patA526 : generic_pattern sym :=
  Pattern aU (CaseBase ((some t3symA526), BTy_object OTy_pointer))
def t3patA525 : generic_pattern sym :=
  Pattern aU (CaseBase ((some t3symA525), BTy_loaded OTy_integer))
def t3patA527 : generic_pattern sym :=
  Pattern aU (CaseBase ((some t3symA527), BTy_object OTy_pointer))
def t3patA528 : generic_pattern sym :=
  Pattern aU (CaseBase ((some t3symA528), BTy_loaded OTy_integer))

theorem t3upd_x (f : Fmap sym value) :
    update_env_aux t3patX locPtrV f
      = @fmapAddBy sym value Lem_Map.instBEqOfMapKeyType
          (@Lem_Map.mapKeyCompare sym _) t3symx locPtrV f := rfl

theorem t3upd_a526 (f : Fmap sym value) :
    update_env_aux t3patA526 xPtrV f
      = @fmapAddBy sym value Lem_Map.instBEqOfMapKeyType
          (@Lem_Map.mapKeyCompare sym _) t3symA526 xPtrV f := rfl

theorem t3upd_a525 (x : Int) (f : Fmap sym value) :
    update_env_aux t3patA525 (loadedV x) f
      = @fmapAddBy sym value Lem_Map.instBEqOfMapKeyType
          (@Lem_Map.mapKeyCompare sym _) t3symA525 (loadedV x) f := rfl

theorem t3upd_a527 (f : Fmap sym value) :
    update_env_aux t3patA527 locPtrV f
      = @fmapAddBy sym value Lem_Map.instBEqOfMapKeyType
          (@Lem_Map.mapKeyCompare sym _) t3symA527 locPtrV f := rfl

theorem t3upd_a528 (x : Int) (f : Fmap sym value) :
    update_env_aux t3patA528 (loadedV x) f
      = @fmapAddBy sym value Lem_Map.instBEqOfMapKeyType
          (@Lem_Map.mapKeyCompare sym _) t3symA528 (loadedV x) f := rfl

theorem t3upd_a529 (v : value) (f : Fmap sym value) :
    update_env_aux (mk_sym_pat t3symA529 (BTy_loaded OTy_integer)) v f
      = @fmapAddBy sym value Lem_Map.instBEqOfMapKeyType
          (@Lem_Map.mapKeyCompare sym _) t3symA529 v f := rfl

/-! ## The rounds -/

/-- The create's layout image. -/
@[reducible] def t3layoutAlloc (ls : CerbMem.MemState) :
    CerbMem.MemState :=
  CerbMem.writeBytesTo
    ({ ls with
        nextAllocId := ls.nextAllocId + 1,
        lastAddress := locAddr,
        allocations := ls.allocations.insert ls.nextAllocId allocLoc })
    locAddr uninit4

/-- R0 (stage-0): the Create's operands evaluate (closed). -/
theorem t3r0 (p : T1P) :
    app (dnmsRoundM t3File.tagDefs 0) (t3fam0 p)
      = (NDactive (Sum.inl NOWAKEUP), t3fam t3ar1 [] 1 p) := by
  refine dnmsRoundM_adv rfl ?_
  exact (advance_runstate_eval (th' := t3Th t3ar1 p.f₁)
    (rs' := (t3fam0 p).core_run_state0) rfl).trans rfl

/-- R1: THE CREATE — the local object born (aid drawn, layout
    allocates, ME_allocate_object traced). -/
theorem t3r1 (p : T1P)
    (hlast : p.ls.lastAddress = mr2.lastAddress)
    (hnext : p.ls.nextAllocId = 2) :
    app (dnmsRoundM t3File.tagDefs 0) (t3fam t3ar1 [] 1 p)
      = (NDactive (Sum.inl NOWAKEUP),
         t3σ t3ar2 p.f₁ p.tS (p.aS + 1) p.eS p.sS
           (t3layoutAlloc p.ls) [t3meAlloc] 1) := by
  have hmem := Kit.mem_alloc_block (tid := 0)
    (pref := PrefOther "Core") (pv := .Prov_none)
    (alignN := 4) (ty := intCty) (mem := p.ls)
    (addrOpt := none) (sz := 4) (a := locAddr)
    rfl (by rw [hlast]; rfl) rfl
  rw [hnext] at hmem
  refine dnmsRoundM_adv rfl ?_
  apply (app_bind_active ?hreq).trans
  case hreq =>
    refine (app_bind_active rfl).trans ?_
    refine (RelSem.Kit.perform_create (hmem := hmem)).trans ?_
    rfl
  rw [show t3layoutAlloc p.ls
        = CerbMem.writeBytesTo
            ({ p.ls with nextAllocId := 2 + 1, lastAddress := locAddr, allocations := p.ls.allocations.insert 2 allocLoc })
            locAddr uninit4 from by
      show CerbMem.writeBytesTo
            ({ p.ls with nextAllocId := p.ls.nextAllocId + 1, lastAddress := locAddr, allocations := p.ls.allocations.insert p.ls.nextAllocId allocLoc })
            locAddr uninit4 = _
      rw [hnext]]
  rfl

/-- R2: the Esseq binds the local pointer x (BIRTH). -/
theorem t3r2 (p : T1P) :
    app (dnmsRoundM t3File.tagDefs 0) (t3fam t3ar2 [t3meAlloc] 1 p)
      = (NDactive (Sum.inl NOWAKEUP),
         t3fam t3ar3 [t3meAlloc] 2
           { p with f₁ := update_env_aux t3patX locPtrV p.f₁ }) := by
  refine dnmsRoundM_adv rfl ?_
  exact (advance_tau_misc).trans rfl

/-- R3: v's cell read. -/
theorem t3r3 (p : T1P)
    (hv : envLookup (t3fam t3ar3 [t3meAlloc] 2 p) t3symV
      = some xPtrV) :
    app (dnmsRoundM t3File.tagDefs 0) (t3fam t3ar3 [t3meAlloc] 2 p)
      = (NDactive (Sum.inl NOWAKEUP), t3fam t3ar4 [t3meAlloc] 3 p) := by
  refine dnmsRoundM_adv rfl ?_
  refine (advance_runstate_eval (th' := t3Th t3ar4 p.f₁)
    (rs' := (t3fam t3ar3 [t3meAlloc] 2 p).core_run_state0) ?_).trans ?_
  · show stExceptUndef_bind _ _ _ = _
    refine (stub_defined (z := Expr aU (Epure (Pexpr [] () (PEval xPtrV))))
      (st' := (t3fam t3ar3 [t3meAlloc] 2 p).core_run_state0) ?_).trans rfl
    show stExceptUndef_bind _ _ _ = _
    refine (stub_defined (z := xPtrV)
      (st' := (t3fam t3ar3 [t3meAlloc] 2 p).core_run_state0) ?_).trans rfl
    show stExceptUndef_bind _ _ _ = _
    refine (stub_defined (z := Sum.inr xPtrV)
      (st' := (t3fam t3ar3 [t3meAlloc] 2 p).core_run_state0) ?_).trans ?_
    · show runEU (eval_pexpr_aux2 t3File.tagDefs
          CerbLocation.Loc.unknown
          (some (CerbLocation.other "RelSem.callND"))
          (create_extern_symmap t3File) [p.f₁] (some p.ls) t3File
          (Pexpr aU () (PEsym t3symV))) _ = _
      rw [aux2_sym_hit (a := aU) (a' := []) (z := t3symV) (v := xPtrV)
        (env := [p.f₁]) rfl rfl
        (show lookup_env t3symV [p.f₁] = some xPtrV from hv)]
      rfl
    · rfl
  · rfl

/-- R4: a_526 := the argument pointer BORN. -/
theorem t3r4 (p : T1P) :
    app (dnmsRoundM t3File.tagDefs 0) (t3fam t3ar4 [t3meAlloc] 3 p)
      = (NDactive (Sum.inl NOWAKEUP),
         t3fam t3ar5 [t3meAlloc] 4
           { p with f₁ := update_env_aux t3patA526 xPtrV p.f₁ }) := by
  refine dnmsRoundM_adv rfl ?_
  exact (advance_tau_misc).trans rfl

/-- R5: the first Load's operands (a_526 read). -/
theorem t3r5 (p : T1P)
    (ha : envLookup (t3fam t3ar5 [t3meAlloc] 4 p) t3symA526
      = some xPtrV) :
    app (dnmsRoundM t3File.tagDefs 0) (t3fam t3ar5 [t3meAlloc] 4 p)
      = (NDactive (Sum.inl NOWAKEUP), t3fam t3ar6 [t3meAlloc] 5 p) := by
  refine dnmsRoundM_adv rfl ?_
  refine (advance_runstate_eval (th' := t3Th t3ar6 p.f₁)
    (rs' := (t3fam t3ar5 [t3meAlloc] 4 p).core_run_state0) ?_).trans ?_
  · show stExceptUndef_bind _ _ _ = _
    refine (stub_defined
      (z := Action CerbLocation.Loc.unknown empty_annotation
        (Load0 (mk_value_pe (Vctype intCty)) (mk_value_pe xPtrV) NA))
      (st' := (t3fam t3ar5 [t3meAlloc] 4 p).core_run_state0) ?_).trans rfl
    show stExceptUndef_bind _ _ _ = _
    refine (stub_defined (z := Vctype intCty)
      (st' := (t3fam t3ar5 [t3meAlloc] 4 p).core_run_state0) ?_).trans ?_
    · rfl
    show stExceptUndef_bind _ _ _ = _
    refine (stub_defined (z := xPtrV)
      (st' := (t3fam t3ar5 [t3meAlloc] 4 p).core_run_state0) ?_).trans rfl
    show stExceptUndef_bind _ _ _ = _
    refine (stub_defined (z := Sum.inr xPtrV)
      (st' := (t3fam t3ar5 [t3meAlloc] 4 p).core_run_state0) ?_).trans ?_
    · show runEU (eval_pexpr_aux2 t3File.tagDefs
          CerbLocation.Loc.unknown
          (some (CerbLocation.other "RelSem.callND"))
          (create_extern_symmap t3File) [p.f₁] (some p.ls) t3File
          (Pexpr aU () (PEsym t3symA526))) _ = _
      rw [aux2_sym_hit (a := aU) (a' := []) (z := t3symA526)
        (v := xPtrV) (env := [p.f₁]) rfl rfl
        (show lookup_env t3symA526 [p.f₁] = some xPtrV from ha)]
      rfl
    · rfl
  · rfl

/-- R6: THE ARGUMENT LOAD. -/
theorem t3r6 (x : Int) (p : T1P)
    (hget : p.ls.allocations.get? 0 = some allocX)
    (hbytes : ∀ i : Nat, (hi : i < (xBytes x).length) →
      p.ls.bytemap.get? (xAddr + (i : Int)) = some (xBytes x)[i])
    (hlum : p.ls.lastUsedUnionMembers = [])
    (hfpm : p.ls.funptrmap = [])
    (hinv : MemInv p.ls)
    (h1 : -2147483648 ≤ x) (h2 : x ≤ 2147483647) :
    app (dnmsRoundM t3File.tagDefs 0) (t3fam t3ar6 [t3meAlloc] 5 p)
      = (NDactive (Sum.inl NOWAKEUP),
         t3σ (t3ar7 x) p.f₁ p.tS (p.aS + 1) p.eS p.sS p.ls
           [meLoad x, t3meAlloc] 5) := by
  refine dnmsRoundM_adv rfl ?_
  apply (app_bind_active ?hreq).trans
  case hreq =>
    refine (app_bind_active rfl).trans ?_
    rw [perform_unfold]
    refine (app_bind_active aid_draw).trans ?_
    rw [ars_load_unfold]
    refine (app_bind_active (app_liftMem_active rfl
      (RelSem.T1.loadX_eq_facts x p.ls hget hbytes hlum hfpm hinv
        h1 h2))).trans ?_
    refine (app_bind_active (app_liftMem_active rfl
      mem_prefix_block)).trans ?_
    exact app_nd_update _ _
  rfl

/-- R7: the Ebound/Eannot strips (tau). -/
theorem t3r7 (x : Int) (p : T1P) :
    app (dnmsRoundM t3File.tagDefs 0)
        (t3fam (t3ar7 x) [meLoad x, t3meAlloc] 5 p)
      = (NDactive (Sum.inl NOWAKEUP),
         t3fam (t3ar8 x) [meLoad x, t3meAlloc] 6 p) := by
  refine dnmsRoundM_adv rfl ?_
  exact (advance_tau_misc).trans rfl

/-- R8: a_525 := the loaded argument BORN. -/
theorem t3r8 (x : Int) (p : T1P) :
    app (dnmsRoundM t3File.tagDefs 0)
        (t3fam (t3ar8 x) [meLoad x, t3meAlloc] 6 p)
      = (NDactive (Sum.inl NOWAKEUP),
         t3fam t3ar9 [meLoad x, t3meAlloc] 7
           { p with f₁ := update_env_aux t3patA525 (loadedV x) p.f₁ }) := by
  refine dnmsRoundM_adv rfl ?_
  exact (advance_tau_misc).trans rfl

/-- R9: the Store's operands — reads x's (local pointer) and a_525's
    cells; the conv chain discharges from the range. -/
theorem t3r9 (x : Int) (h1 : -2147483648 ≤ x) (h2 : x ≤ 2147483647)
    (p : T1P)
    (hx : envLookup (t3fam t3ar9 [meLoad x, t3meAlloc] 7 p) t3symx
      = some locPtrV)
    (ha : envLookup (t3fam t3ar9 [meLoad x, t3meAlloc] 7 p) t3symA525
      = some (loadedV x)) :
    app (dnmsRoundM t3File.tagDefs 0)
        (t3fam t3ar9 [meLoad x, t3meAlloc] 7 p)
      = (NDactive (Sum.inl NOWAKEUP),
         t3fam (t3ar10 x) [meLoad x, t3meAlloc] 8 p) := by
  refine dnmsRoundM_adv rfl ?_
  refine (advance_runstate_eval (th' := t3Th (t3ar10 x) p.f₁)
    (rs' := (t3fam t3ar9 [meLoad x, t3meAlloc] 7 p).core_run_state0)
    ?_).trans ?_
  · show stExceptUndef_bind _ _ _ = _
    refine (stub_defined
      (z := Action CerbLocation.Loc.unknown empty_annotation
        (Store0 false (mk_value_pe (Vctype intCty))
          (mk_value_pe locPtrV) (mk_value_pe (loadedV x)) NA))
      (st' := (t3fam t3ar9 [meLoad x, t3meAlloc] 7 p).core_run_state0)
      ?_).trans rfl
    show stExceptUndef_bind _ _ _ = _
    refine (stub_defined (z := Vctype intCty)
      (st' := (t3fam t3ar9 [meLoad x, t3meAlloc] 7 p).core_run_state0)
      ?_).trans ?_
    · rfl
    show stExceptUndef_bind _ _ _ = _
    refine (stub_defined (z := locPtrV)
      (st' := (t3fam t3ar9 [meLoad x, t3meAlloc] 7 p).core_run_state0)
      ?_).trans ?_
    · show stExceptUndef_bind _ _ _ = _
      refine (stub_defined (z := Sum.inr locPtrV)
        (st' := (t3fam t3ar9 [meLoad x, t3meAlloc] 7 p).core_run_state0)
        ?_).trans ?_
      · show runEU (eval_pexpr_aux2 t3File.tagDefs
            CerbLocation.Loc.unknown
            (some (CerbLocation.other "RelSem.callND"))
            (create_extern_symmap t3File) [p.f₁] (some p.ls) t3File
            (Pexpr aU () (PEsym t3symx))) _ = _
        rw [aux2_sym_hit (a := aU) (a' := []) (z := t3symx)
          (v := locPtrV) (env := [p.f₁]) rfl rfl
          (show lookup_env t3symx [p.f₁] = some locPtrV from hx)]
        rfl
      · rfl
    show stExceptUndef_bind _ _ _ = _
    refine (stub_defined (z := loadedV x)
      (st' := (t3fam t3ar9 [meLoad x, t3meAlloc] 7 p).core_run_state0)
      ?_).trans rfl
    show stExceptUndef_bind _ _ _ = _
    refine (stub_defined (z := Sum.inr (loadedV x))
      (st' := (t3fam t3ar9 [meLoad x, t3meAlloc] 7 p).core_run_state0)
      ?_).trans ?_
    · show runEU (eval_pexpr_aux2 t3File.tagDefs
          CerbLocation.Loc.unknown
          (some (CerbLocation.other "RelSem.callND"))
          (create_extern_symmap t3File) [p.f₁] (some p.ls) t3File
          (t3convPE t3symA525)) _ = _
      rw [t3conv_eval t3symA525 x h1 h2 [p.f₁] (some p.ls) rfl
        (show lookup_env t3symA525 [p.f₁] = some (loadedV x) from ha)]
      rfl
    · rfl
  · rfl

/-- R10: THE STORE — the argument value written into the local
    (aid drawn, ME_store traced). -/
theorem t3r10 (x : Int) (p : T1P)
    (hget : p.ls.allocations.get? 2 = some allocLoc)
    (hfpm : p.ls.funptrmap = []) :
    app (dnmsRoundM t3File.tagDefs 0)
        (t3fam (t3ar10 x) [meLoad x, t3meAlloc] 8 p)
      = (NDactive (Sum.inl NOWAKEUP),
         t3σ (t3ar11) p.f₁ p.tS (p.aS + 1) p.eS p.sS
           (CerbMem.writeBytesTo { p.ls with funptrmap := [] }
             locAddr (xBytes x))
           [t3meStore x, meLoad x, t3meAlloc] 8) := by
  refine dnmsRoundM_adv rfl ?_
  apply (app_bind_active ?hreq).trans
  case hreq =>
    refine (app_bind_active rfl).trans ?_
    refine (RelSem.Kit.perform_store
      (hmem := Kit.mem_store_block (alloc := allocLoc)
        rfl hget rfl rfl rfl
        (by rw [hfpm]))
      (hpref := mem_prefix_block)).trans ?_
    rfl
  rfl

/-- R11: the Esseq/Eannot consumes the store's unit (tau). -/
theorem t3r11 (x : Int) (p : T1P) :
    app (dnmsRoundM t3File.tagDefs 0)
        (t3fam (t3ar11) [t3meStore x, meLoad x, t3meAlloc] 8 p)
      = (NDactive (Sum.inl NOWAKEUP),
         t3fam t3ar12 [t3meStore x, meLoad x, t3meAlloc] 9 p) := by
  refine dnmsRoundM_adv rfl ?_
  exact (advance_tau_misc).trans rfl

/-- R12: x's (local pointer) cell read. -/
theorem t3r12 (x : Int) (p : T1P)
    (hx : envLookup (t3fam t3ar12 [t3meStore x, meLoad x, t3meAlloc]
      9 p) t3symx = some locPtrV) :
    app (dnmsRoundM t3File.tagDefs 0)
        (t3fam t3ar12 [t3meStore x, meLoad x, t3meAlloc] 9 p)
      = (NDactive (Sum.inl NOWAKEUP),
         t3fam t3ar13 [t3meStore x, meLoad x, t3meAlloc] 10 p) := by
  refine dnmsRoundM_adv rfl ?_
  refine (advance_runstate_eval (th' := t3Th t3ar13 p.f₁)
    (rs' := (t3fam t3ar12 [t3meStore x, meLoad x, t3meAlloc]
      9 p).core_run_state0) ?_).trans ?_
  · show stExceptUndef_bind _ _ _ = _
    refine (stub_defined (z := Expr aU (Epure (Pexpr [] () (PEval locPtrV))))
      (st' := (t3fam t3ar12 [t3meStore x, meLoad x, t3meAlloc]
        9 p).core_run_state0) ?_).trans rfl
    show stExceptUndef_bind _ _ _ = _
    refine (stub_defined (z := locPtrV)
      (st' := (t3fam t3ar12 [t3meStore x, meLoad x, t3meAlloc]
        9 p).core_run_state0) ?_).trans rfl
    show stExceptUndef_bind _ _ _ = _
    refine (stub_defined (z := Sum.inr locPtrV)
      (st' := (t3fam t3ar12 [t3meStore x, meLoad x, t3meAlloc]
        9 p).core_run_state0) ?_).trans ?_
    · show runEU (eval_pexpr_aux2 t3File.tagDefs
          CerbLocation.Loc.unknown
          (some (CerbLocation.other "RelSem.callND"))
          (create_extern_symmap t3File) [p.f₁] (some p.ls) t3File
          (Pexpr aU () (PEsym t3symx))) _ = _
      rw [aux2_sym_hit (a := aU) (a' := []) (z := t3symx)
        (v := locPtrV) (env := [p.f₁]) rfl rfl
        (show lookup_env t3symx [p.f₁] = some locPtrV from hx)]
      rfl
    · rfl
  · rfl

/-- R13: a_527 := the local pointer BORN. -/
theorem t3r13 (x : Int) (p : T1P) :
    app (dnmsRoundM t3File.tagDefs 0)
        (t3fam t3ar13 [t3meStore x, meLoad x, t3meAlloc] 10 p)
      = (NDactive (Sum.inl NOWAKEUP),
         t3fam t3ar14 [t3meStore x, meLoad x, t3meAlloc] 11
           { p with f₁ := update_env_aux t3patA527 locPtrV p.f₁ }) := by
  refine dnmsRoundM_adv rfl ?_
  exact (advance_tau_misc).trans rfl

/-- R14: the second Load's operands (a_527 read). -/
theorem t3r14 (x : Int) (p : T1P)
    (ha : envLookup (t3fam t3ar14 [t3meStore x, meLoad x, t3meAlloc]
      11 p) t3symA527 = some locPtrV) :
    app (dnmsRoundM t3File.tagDefs 0)
        (t3fam t3ar14 [t3meStore x, meLoad x, t3meAlloc] 11 p)
      = (NDactive (Sum.inl NOWAKEUP),
         t3fam t3ar15 [t3meStore x, meLoad x, t3meAlloc] 12 p) := by
  refine dnmsRoundM_adv rfl ?_
  refine (advance_runstate_eval (th' := t3Th t3ar15 p.f₁)
    (rs' := (t3fam t3ar14 [t3meStore x, meLoad x, t3meAlloc]
      11 p).core_run_state0) ?_).trans ?_
  · show stExceptUndef_bind _ _ _ = _
    refine (stub_defined
      (z := Action CerbLocation.Loc.unknown empty_annotation
        (Load0 (mk_value_pe (Vctype intCty)) (mk_value_pe locPtrV) NA))
      (st' := (t3fam t3ar14 [t3meStore x, meLoad x, t3meAlloc]
        11 p).core_run_state0) ?_).trans rfl
    show stExceptUndef_bind _ _ _ = _
    refine (stub_defined (z := Vctype intCty)
      (st' := (t3fam t3ar14 [t3meStore x, meLoad x, t3meAlloc]
        11 p).core_run_state0) ?_).trans ?_
    · rfl
    show stExceptUndef_bind _ _ _ = _
    refine (stub_defined (z := locPtrV)
      (st' := (t3fam t3ar14 [t3meStore x, meLoad x, t3meAlloc]
        11 p).core_run_state0) ?_).trans rfl
    show stExceptUndef_bind _ _ _ = _
    refine (stub_defined (z := Sum.inr locPtrV)
      (st' := (t3fam t3ar14 [t3meStore x, meLoad x, t3meAlloc]
        11 p).core_run_state0) ?_).trans ?_
    · show runEU (eval_pexpr_aux2 t3File.tagDefs
          CerbLocation.Loc.unknown
          (some (CerbLocation.other "RelSem.callND"))
          (create_extern_symmap t3File) [p.f₁] (some p.ls) t3File
          (Pexpr aU () (PEsym t3symA527))) _ = _
      rw [aux2_sym_hit (a := aU) (a' := []) (z := t3symA527)
        (v := locPtrV) (env := [p.f₁]) rfl rfl
        (show lookup_env t3symA527 [p.f₁] = some locPtrV from ha)]
      rfl
    · rfl
  · rfl

/-- The local-load memory equation (the roundtrip readback). -/
theorem loadLoc_eq_facts (x : Int) (ls : CerbMem.MemState)
    (hget : ls.allocations.get? 2 = some allocLoc)
    (hbytes : ∀ i : Nat, (hi : i < (xBytes x).length) →
      ls.bytemap.get? (locAddr + (i : Int)) = some (xBytes x)[i])
    (hlum : ls.lastUsedUnionMembers = [])
    (hfpm : ls.funptrmap = [])
    (hinv : MemInv ls)
    (h1 : -2147483648 ≤ x) (h2 : x ≤ 2147483647) :
    app (CerbMem.loadM CerbLocation.Loc.unknown intCty locPtr) ls
      = (NDactive (CerbMem.Footprint.FP .R locAddr 4,
          CerbMem.MemValue.MVinteger (Signed Int_) (.IV .Prov_none x)),
         ls) := by
  have hrecon : CerbMem.reconstructValue ls.lastUsedUnionMembers
      ls.funptrmap locAddr intCty (xBytes x)
      = CerbMem.MemValue.MVinteger (Signed Int_) (.IV .Prov_none x) := by
    rw [hlum, hfpm]
    show CerbMem.reconstructValue_lemFuel (999999 + 1) [] [] locAddr
      (Ctype [] (Basic (Integer (Signed Int_)))) (xBytes x) = _
    rw [CerbMem.reconstructValue_lemFuel]
    simp only [CerberusImpl.is_signed_ity]
    rw [show xBytes x
        = [mkByte x 0, mkByte x 1, mkByte x 2, mkByte x 3] from rfl,
      roundtrip_arith x h1 h2]
    simp [CerbMem.provFromIntegerBytes, CerbMem.combineProv,
      RelSem.T1.mkByte]
  exact Kit.mem_load_block (loc := CerbLocation.Loc.unknown)
    (um := none) (hinv.contains_dead_false hget) hget rfl rfl
    (readBytesFrom_of_pointwise rfl hbytes) hrecon rfl

/-- R15: THE LOCAL LOAD (the stored bytes come back as exactly x). -/
theorem t3r15 (x : Int) (p : T1P)
    (hget : p.ls.allocations.get? 2 = some allocLoc)
    (hbytes : ∀ i : Nat, (hi : i < (xBytes x).length) →
      p.ls.bytemap.get? (locAddr + (i : Int)) = some (xBytes x)[i])
    (hlum : p.ls.lastUsedUnionMembers = [])
    (hfpm : p.ls.funptrmap = [])
    (hinv : MemInv p.ls)
    (h1 : -2147483648 ≤ x) (h2 : x ≤ 2147483647) :
    app (dnmsRoundM t3File.tagDefs 0)
        (t3fam t3ar15 [t3meStore x, meLoad x, t3meAlloc] 12 p)
      = (NDactive (Sum.inl NOWAKEUP),
         t3σ (t3ar16 x) p.f₁ p.tS (p.aS + 1) p.eS p.sS p.ls
           [t3meLoad2 x, t3meStore x, meLoad x, t3meAlloc] 12) := by
  refine dnmsRoundM_adv rfl ?_
  apply (app_bind_active ?hreq).trans
  case hreq =>
    refine (app_bind_active rfl).trans ?_
    rw [perform_unfold]
    refine (app_bind_active aid_draw).trans ?_
    rw [ars_load_unfold]
    refine (app_bind_active (app_liftMem_active rfl
      (loadLoc_eq_facts x p.ls hget hbytes hlum hfpm hinv
        h1 h2))).trans ?_
    refine (app_bind_active (app_liftMem_active rfl
      mem_prefix_block)).trans ?_
    exact app_nd_update _ _
  rfl

/-- R16: the Ebound/Eannot strips (tau). -/
theorem t3r16 (x : Int) (p : T1P) :
    app (dnmsRoundM t3File.tagDefs 0)
        (t3fam (t3ar16 x) [t3meLoad2 x, t3meStore x, meLoad x,
          t3meAlloc] 12 p)
      = (NDactive (Sum.inl NOWAKEUP),
         t3fam (t3ar17 x) [t3meLoad2 x, t3meStore x, meLoad x,
           t3meAlloc] 13 p) := by
  refine dnmsRoundM_adv rfl ?_
  exact (advance_tau_misc).trans rfl

/-- R17: a_528 := the read-back value BORN. -/
theorem t3r17 (x : Int) (p : T1P) :
    app (dnmsRoundM t3File.tagDefs 0)
        (t3fam (t3ar17 x) [t3meLoad2 x, t3meStore x, meLoad x,
          t3meAlloc] 13 p)
      = (NDactive (Sum.inl NOWAKEUP),
         t3fam t3ar18 [t3meLoad2 x, t3meStore x, meLoad x,
           t3meAlloc] 14
           { p with f₁ := update_env_aux t3patA528 (loadedV x) p.f₁ }) := by
  refine dnmsRoundM_adv rfl ?_
  exact (advance_tau_misc).trans rfl

/-- R18: the Kill's operand — reads x's (local pointer) cell. -/
theorem t3r18 (x : Int) (p : T1P)
    (hx : envLookup (t3fam t3ar18 [t3meLoad2 x, t3meStore x,
      meLoad x, t3meAlloc] 14 p) t3symx = some locPtrV) :
    app (dnmsRoundM t3File.tagDefs 0)
        (t3fam t3ar18 [t3meLoad2 x, t3meStore x, meLoad x,
          t3meAlloc] 14 p)
      = (NDactive (Sum.inl NOWAKEUP),
         t3fam t3ar19 [t3meLoad2 x, t3meStore x, meLoad x,
           t3meAlloc] 15 p) := by
  refine dnmsRoundM_adv rfl ?_
  refine (advance_runstate_eval (th' := t3Th t3ar19 p.f₁)
    (rs' := (t3fam t3ar18 [t3meLoad2 x, t3meStore x, meLoad x,
      t3meAlloc] 14 p).core_run_state0) ?_).trans ?_
  · show stExceptUndef_bind _ _ _ = _
    refine (stub_defined
      (z := Action CerbLocation.Loc.unknown empty_annotation
        (Kill (Static0 intCty) (mk_value_pe locPtrV)))
      (st' := (t3fam t3ar18 [t3meLoad2 x, t3meStore x, meLoad x,
        t3meAlloc] 14 p).core_run_state0) ?_).trans rfl
    show stExceptUndef_bind _ _ _ = _
    refine (stub_defined (z := locPtrV)
      (st' := (t3fam t3ar18 [t3meLoad2 x, t3meStore x, meLoad x,
        t3meAlloc] 14 p).core_run_state0) ?_).trans rfl
    show stExceptUndef_bind _ _ _ = _
    refine (stub_defined (z := Sum.inr locPtrV)
      (st' := (t3fam t3ar18 [t3meLoad2 x, t3meStore x, meLoad x,
        t3meAlloc] 14 p).core_run_state0) ?_).trans ?_
    · show runEU (eval_pexpr_aux2 t3File.tagDefs
          CerbLocation.Loc.unknown
          (some (CerbLocation.other "RelSem.callND"))
          (create_extern_symmap t3File) [p.f₁] (some p.ls) t3File
          (Pexpr aU () (PEsym t3symx))) _ = _
      rw [aux2_sym_hit (a := aU) (a' := []) (z := t3symx)
        (v := locPtrV) (env := [p.f₁]) rfl rfl
        (show lookup_env t3symx [p.f₁] = some locPtrV from hx)]
      rfl
    · rfl
  · rfl

/-- R19: THE KILL — the local freed (aid drawn, ME_kill traced). -/
theorem t3r19 (x : Int) (p : T1P)
    (hdead : p.ls.deadAllocations.contains 2 = false)
    (hget : p.ls.allocations.get? 2 = some allocLoc) :
    app (dnmsRoundM t3File.tagDefs 0)
        (t3fam t3ar19 [t3meLoad2 x, t3meStore x, meLoad x,
          t3meAlloc] 15 p)
      = (NDactive (Sum.inl NOWAKEUP),
         t3σ t3ar20 p.f₁ p.tS (p.aS + 1) p.eS p.sS
           { p.ls with
             deadAllocations := 2 :: p.ls.deadAllocations,
             allocations := p.ls.allocations.erase 2 }
           [t3meKill, t3meLoad2 x, t3meStore x, meLoad x,
             t3meAlloc] 15) := by
  refine dnmsRoundM_adv rfl ?_
  apply (app_bind_active ?hreq).trans
  case hreq =>
    refine (app_bind_active rfl).trans ?_
    refine (RelSem.Kit.perform_kill
      (hmem := Kit.mem_kill_block (alloc := allocLoc)
        hdead hget rfl)).trans ?_
    rfl
  rfl

/-- R20: the Esseq consumes the kill's unit (tau). -/
theorem t3r20 (x : Int) (p : T1P) :
    app (dnmsRoundM t3File.tagDefs 0)
        (t3fam t3ar20 [t3meKill, t3meLoad2 x, t3meStore x, meLoad x,
          t3meAlloc] 15 p)
      = (NDactive (Sum.inl NOWAKEUP),
         t3fam t3ar21 [t3meKill, t3meLoad2 x, t3meStore x, meLoad x,
           t3meAlloc] 16 p) := by
  refine dnmsRoundM_adv rfl ?_
  exact (advance_tau_misc).trans rfl

/-- R21: the ret jump — the conv chain at a_528, a_529 BORN. -/
theorem t3r21 (x : Int) (h1 : -2147483648 ≤ x) (h2 : x ≤ 2147483647)
    (p : T1P)
    (ha : envLookup (t3fam t3ar21 [t3meKill, t3meLoad2 x,
      t3meStore x, meLoad x, t3meAlloc] 16 p) t3symA528
      = some (loadedV x)) :
    app (dnmsRoundM t3File.tagDefs 0)
        (t3fam t3ar21 [t3meKill, t3meLoad2 x, t3meStore x, meLoad x,
          t3meAlloc] 16 p)
      = (NDactive (Sum.inl NOWAKEUP),
         t3fam t3ar22 [t3meKill, t3meLoad2 x, t3meStore x, meLoad x,
           t3meAlloc] 17
           { p with f₁ :=
               (update_env_aux
                 (mk_sym_pat t3symA529 (BTy_loaded OTy_integer))
                 (loadedV x) p.f₁) }) := by
  refine dnmsRoundM_adv rfl ?_
  refine (app_bind_active rfl).trans ?_
  apply (app_bind_active (liftCore_run_defined ?hM)).trans
  case hM =>
    change stExceptUndef_bind _ _ _ = _
    apply RelSem.Laws.erun_jump_m ?hres ?hk
    case hres => rfl
    case hk =>
      change stExceptUndef_bind _ _ _ = _
      apply (stub_defined ?hFold).trans
      case hFold =>
        change stExceptUndef_bind _ _ _ = _
        apply (stub_defined ?hElem).trans
        case hElem =>
          change stExceptUndef_bind _ _ _ = _
          apply (stub_defined (t3fullEval_conv t3ar21 t3symA528 x
            h1 h2 p.f₁ p.ls _ rfl
            (show lookup_env t3symA528 [p.f₁] = some (loadedV x)
              from ha))).trans
          rfl
        rfl
      rfl
  rfl

/-- R22: a_529 evaluates (the round-tripped value reaches the
    arena). -/
theorem t3r22 (x : Int) (p : T1P)
    (ha : envLookup (t3fam t3ar22 [t3meKill, t3meLoad2 x,
      t3meStore x, meLoad x, t3meAlloc] 17 p) t3symA529
      = some (loadedV x)) :
    app (dnmsRoundM t3File.tagDefs 0)
        (t3fam t3ar22 [t3meKill, t3meLoad2 x, t3meStore x, meLoad x,
          t3meAlloc] 17 p)
      = (NDactive (Sum.inl NOWAKEUP),
         t3fam (t3arDone x) [t3meKill, t3meLoad2 x, t3meStore x,
           meLoad x, t3meAlloc] 18 p) := by
  refine dnmsRoundM_adv rfl ?_
  refine (advance_runstate_eval (th' := t3Th (t3arDone x) p.f₁)
    (rs' := (t3fam t3ar22 [t3meKill, t3meLoad2 x, t3meStore x,
      meLoad x, t3meAlloc] 17 p).core_run_state0) ?_).trans ?_
  · show stExceptUndef_bind _ _ _ = _
    refine (stub_defined
      (z := Expr aU (Epure (Pexpr [] () (PEval (loadedV x)))))
      (st' := (t3fam t3ar22 [t3meKill, t3meLoad2 x, t3meStore x,
        meLoad x, t3meAlloc] 17 p).core_run_state0) ?_).trans rfl
    show stExceptUndef_bind _ _ _ = _
    refine (stub_defined (z := loadedV x)
      (st' := (t3fam t3ar22 [t3meKill, t3meLoad2 x, t3meStore x,
        meLoad x, t3meAlloc] 17 p).core_run_state0) ?_).trans rfl
    show stExceptUndef_bind _ _ _ = _
    refine (stub_defined (z := Sum.inr (loadedV x))
      (st' := (t3fam t3ar22 [t3meKill, t3meLoad2 x, t3meStore x,
        meLoad x, t3meAlloc] 17 p).core_run_state0) ?_).trans ?_
    · show runEU (eval_pexpr_aux2 t3File.tagDefs
          CerbLocation.Loc.unknown
          (some (CerbLocation.other "RelSem.callND"))
          (create_extern_symmap t3File) [p.f₁] (some p.ls) t3File
          (Pexpr aU () (PEsym t3symA529))) _ = _
      rw [aux2_sym_hit (a := aU) (a' := []) (z := t3symA529)
        (v := loadedV x) (env := [p.f₁]) rfl rfl
        (show lookup_env t3symA529 [p.f₁] = some (loadedV x) from ha)]
      rfl
    · rfl
  · rfl

/-- R-terminal: the done offer at x. -/
theorem t3r23 (x : Int) (p : T1P) :
    app (dnmsRoundM t3File.tagDefs 0)
        (t3fam (t3arDone x) [t3meKill, t3meLoad2 x, t3meStore x,
          meLoad x, t3meAlloc] 18 p)
      = (NDactive (Sum.inr [Step_done2 (loadedV x)]),
         t3fam (t3arDone x) [t3meKill, t3meLoad2 x, t3meStore x,
           meLoad x, t3meAlloc] 18 p) := by
  refine (dnmsRoundM_inr rfl).trans ?_
  rfl
