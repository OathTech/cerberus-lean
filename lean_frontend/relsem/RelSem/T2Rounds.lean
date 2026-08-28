/-
  RelSem.T2Rounds — V2 (2026-08-28): THE T2 (add) ROUND ENGINE.
  Ground truth: the V2Probe transcripts at (3,5)/(-4,7) (two-point
  diff; x/y/x+y positions abstracted). 15 linear rounds — two
  argument loads, the tuple pack, THE CHECKED ADD (the
  catch_exceptional chain at the no-overflow hypothesis), the ret
  conv jump. Families/idioms mirror P01Rounds; the memory ladder has
  TWO argument objects (a@…648, b@…644) + errno@…640.

  House rules: no sorry, no axioms. Under the in-build audit.
-/

import RelSem.P01Rounds
import RelSem.T2Threaded
import RelSem.RoundEval.Arith
import RelSem.T1Proof

set_option autoImplicit false
set_option maxHeartbeats 2000000

namespace RelSem.T2

open RelSem RelSem.Cerb RelSem.Kit RelSem.CerbSt
open Lem_Basic_classes (ordCompare)
open RelSem.T1 (T1P RExpr aU intCty xAddr xPtr xPtrV loadedV xBytes
  mkByte roundtrip_arith allocX allocXS mr0 mr1 meLoad
  memValueToBytes_int memValueFromValue_int
  birth_new birth_pres birth_rev birth_wfp)
open RelSem.P01 (L0 clsNone dbl_new₁ dbl_new₂ dbl_pres dbl_rev
  dbl_wfp)
open RelSem.Slate (t2File addT2Sym)

/-! ## Program symbols + the second-argument memory ladder -/

def t2symA : sym := Symbol "" 15917291556903334389 (SD_Id "a")
def t2symB : sym := Symbol "" 15817570140490810055 (SD_Id "b")
def t2symA530 : sym := Symbol "" 4915778119994869450 (SD_Id "a_530")
def t2symA531 : sym := Symbol "" 17653705816563834534 (SD_Id "a_531")
def t2symA532 : sym := Symbol "" 1342427191597093029 (SD_Id "a_532")
def t2symA533 : sym := Symbol "" 18213349194842787190 (SD_Id "a_533")
def t2symA535 : sym := Symbol "" 15754218577363027919 (SD_Id "a_535")
def t2symA536 : sym := Symbol "" 6464411467923874555 (SD_Id "a_536")
def t2symA537 : sym := Symbol "" 6477419756603697776 (SD_Id "a_537")
def t2symA538 : sym := Symbol "" 18319030617476695216 (SD_Id "a_538")
def t2symCLI : sym := Symbol "" 7499171796590179012 (SD_Id "conv_loaded_int")
def t2symRet529 : sym :=
  Symbol "" 18125140908934492201 (SD_Id "ret_529")

def bAddr : Int := 281474976710644
def t2errAddr : Int := 281474976710640
def bPtr : CerbMem.PointerValue :=
  .PV (.Prov_some 1) (.PVconcrete none bAddr)
def bPtrV : value := Vobject (OVpointer bPtr)
def t2errPtr : CerbMem.PointerValue :=
  .PV (.Prov_some 2) (.PVconcrete none t2errAddr)

@[reducible] def allocB : CerbMem.Allocation :=
  { base := bAddr, size := 4, ty := some intCty,
    prefix_ := PrefOther "callND arg" }
@[reducible] def allocBS : CerbMem.Allocation :=
  { base := bAddr, size := (4 : Nat), ty := some signed_int,
    prefix_ := PrefOther "callND arg" }
@[reducible] def t2allocErrS : CerbMem.Allocation :=
  { base := t2errAddr, size := (4 : Nat), ty := some signed_int,
    prefix_ := PrefOther "errno" }

/-- The T2 memory residuals: after a, after b, after errno. -/
@[reducible] def t2mr2 : CerbMem.MemState := mrAlloc mr1 bAddr
@[reducible] def t2mr3 : CerbMem.MemState := mrAlloc t2mr2 t2errAddr

/-- The b-load at footprint facts (the xAddr lemma's mirror). -/
theorem loadB_eq_facts (y : Int) (ls : CerbMem.MemState)
    (hget : ls.allocations.get? 1 = some allocB)
    (hbytes : ∀ i : Nat, (hi : i < (xBytes y).length) →
      ls.bytemap.get? (bAddr + (i : Int)) = some (xBytes y)[i])
    (hlum : ls.lastUsedUnionMembers = [])
    (hfpm : ls.funptrmap = [])
    (hinv : MemInv ls)
    (h1 : -2147483648 ≤ y) (h2 : y ≤ 2147483647) :
    app (CerbMem.loadM CerbLocation.Loc.unknown intCty bPtr) ls
      = (NDactive (CerbMem.Footprint.FP .R bAddr 4,
          CerbMem.MemValue.MVinteger (Signed Int_) (.IV .Prov_none y)),
         ls) := by
  have hrecon : CerbMem.reconstructValue ls.lastUsedUnionMembers
      ls.funptrmap bAddr intCty (xBytes y)
      = CerbMem.MemValue.MVinteger (Signed Int_) (.IV .Prov_none y) := by
    rw [hlum, hfpm]
    show CerbMem.reconstructValue_lemFuel (999999 + 1) [] [] bAddr
      (Ctype [] (Basic (Integer (Signed Int_)))) (xBytes y) = _
    rw [CerbMem.reconstructValue_lemFuel]
    simp only [CerberusImpl.is_signed_ity]
    rw [show xBytes y
        = [mkByte y 0, mkByte y 1, mkByte y 2, mkByte y 3] from rfl,
      roundtrip_arith y h1 h2]
    simp [CerbMem.provFromIntegerBytes, CerbMem.combineProv,
      RelSem.T1.mkByte]
  exact Kit.mem_load_block (loc := CerbLocation.Loc.unknown)
    (um := none) (hinv.contains_dead_false hget) hget rfl rfl
    (readBytesFrom_of_pointwise rfl hbytes) hrecon rfl

/-- The b-load trace event. -/
def meLoadB (y : Int) : trace_event :=
  ME_load CerbLocation.Loc.unknown none intCty bPtr
    (CerbMem.MemValue.MVinteger (Signed Int_)
      (CerbMem.IntegerValue.IV .Prov_none y))

/-! ## Arena terms (generated from the probe; x=3/y=5 vs x=-4/y=7 diff) -/

def t2ar0 : RExpr :=
  (Expr aU (Esseq (Pattern aU (CaseBase ((some t2symA537), (BTy_loaded OTy_integer)))) (Expr aU (Ebound (Expr aU (Ewseq (Pattern aU (CaseCtor Ctuple [(Pattern aU (CaseBase ((some t2symA530), (BTy_loaded OTy_integer)))), (Pattern aU (CaseBase ((some t2symA531), (BTy_loaded OTy_integer))))])) (Expr aU (Eunseq [(Expr aU (Ewseq (Pattern aU (CaseBase ((some t2symA535), (BTy_object OTy_pointer)))) (Expr aU (Epure (Pexpr aU () (PEsym t2symA)))) (Expr aU (Eaction (Paction Pos (Action L0 empty_annotation (Load0 (Pexpr aU () (PEval (Vctype intCty))) (Pexpr aU () (PEsym t2symA535)) NA))))))), (Expr aU (Ewseq (Pattern aU (CaseBase ((some t2symA536), (BTy_object OTy_pointer)))) (Expr aU (Epure (Pexpr aU () (PEsym t2symB)))) (Expr aU (Eaction (Paction Pos (Action L0 empty_annotation (Load0 (Pexpr aU () (PEval (Vctype intCty))) (Pexpr aU () (PEsym t2symA536)) NA)))))))])) (Expr aU (Epure (Pexpr aU () (PEcase (Pexpr aU () (PEctor Ctuple [(Pexpr aU () (PEsym t2symA530)), (Pexpr aU () (PEsym t2symA531))])) [((Pattern aU (CaseCtor Ctuple [(Pattern aU (CaseCtor Cspecified [(Pattern aU (CaseBase ((some t2symA532), (BTy_object OTy_integer))))])), (Pattern aU (CaseCtor Cspecified [(Pattern aU (CaseBase ((some t2symA533), (BTy_object OTy_integer))))]))])), (Pexpr aU () (PEctor Cspecified [(Pexpr aU () (PEcatch_exceptional_condition (Signed Int_) IOpAdd (Pexpr aU () (PEconv_int (Signed Int_) (Pexpr aU () (PEsym t2symA532)))) (Pexpr aU () (PEconv_int (Signed Int_) (Pexpr aU () (PEsym t2symA533))))))]))), ((Pattern aU (CaseBase (none, (BTy_tuple [(BTy_loaded OTy_integer), (BTy_loaded OTy_integer)])))), (Pexpr aU () (PEundef L0 UB036_exceptional_condition)))])))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Erun empty_annotation t2symRet529 [(Pexpr aU () (PEcall (Sym t2symCLI) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym t2symA537))]))])) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Epure (Pexpr aU () (PEval Vunit)))) (Expr aU (Esave (t2symRet529, (BTy_loaded OTy_integer)) [(t2symA538, (((BTy_loaded OTy_integer), none), (Pexpr aU () (PEundef L0 UB088_reached_end_of_function))))] (Expr aU (Epure (Pexpr aU () (PEsym t2symA538))))))))))))

def t2ar1 : RExpr :=
  (Expr aU (Esseq (Pattern aU (CaseBase ((some t2symA537), (BTy_loaded OTy_integer)))) (Expr aU (Ebound (Expr aU (Ewseq (Pattern aU (CaseCtor Ctuple [(Pattern aU (CaseBase ((some t2symA530), (BTy_loaded OTy_integer)))), (Pattern aU (CaseBase ((some t2symA531), (BTy_loaded OTy_integer))))])) (Expr aU (Eunseq [(Expr aU (Ewseq (Pattern aU (CaseBase ((some t2symA535), (BTy_object OTy_pointer)))) (Expr aU (Epure (Pexpr aU () (PEsym t2symA)))) (Expr aU (Eaction (Paction Pos (Action L0 empty_annotation (Load0 (Pexpr aU () (PEval (Vctype intCty))) (Pexpr aU () (PEsym t2symA535)) NA))))))), (Expr aU (Ewseq (Pattern aU (CaseBase ((some t2symA536), (BTy_object OTy_pointer)))) (Expr aU (Epure (Pexpr [] () (PEval bPtrV)))) (Expr aU (Eaction (Paction Pos (Action L0 empty_annotation (Load0 (Pexpr aU () (PEval (Vctype intCty))) (Pexpr aU () (PEsym t2symA536)) NA)))))))])) (Expr aU (Epure (Pexpr aU () (PEcase (Pexpr aU () (PEctor Ctuple [(Pexpr aU () (PEsym t2symA530)), (Pexpr aU () (PEsym t2symA531))])) [((Pattern aU (CaseCtor Ctuple [(Pattern aU (CaseCtor Cspecified [(Pattern aU (CaseBase ((some t2symA532), (BTy_object OTy_integer))))])), (Pattern aU (CaseCtor Cspecified [(Pattern aU (CaseBase ((some t2symA533), (BTy_object OTy_integer))))]))])), (Pexpr aU () (PEctor Cspecified [(Pexpr aU () (PEcatch_exceptional_condition (Signed Int_) IOpAdd (Pexpr aU () (PEconv_int (Signed Int_) (Pexpr aU () (PEsym t2symA532)))) (Pexpr aU () (PEconv_int (Signed Int_) (Pexpr aU () (PEsym t2symA533))))))]))), ((Pattern aU (CaseBase (none, (BTy_tuple [(BTy_loaded OTy_integer), (BTy_loaded OTy_integer)])))), (Pexpr aU () (PEundef L0 UB036_exceptional_condition)))])))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Erun empty_annotation t2symRet529 [(Pexpr aU () (PEcall (Sym t2symCLI) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym t2symA537))]))])) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Epure (Pexpr aU () (PEval Vunit)))) (Expr aU (Esave (t2symRet529, (BTy_loaded OTy_integer)) [(t2symA538, (((BTy_loaded OTy_integer), none), (Pexpr aU () (PEundef L0 UB088_reached_end_of_function))))] (Expr aU (Epure (Pexpr aU () (PEsym t2symA538))))))))))))

def t2ar2 : RExpr :=
  (Expr aU (Esseq (Pattern aU (CaseBase ((some t2symA537), (BTy_loaded OTy_integer)))) (Expr aU (Ebound (Expr aU (Ewseq (Pattern aU (CaseCtor Ctuple [(Pattern aU (CaseBase ((some t2symA530), (BTy_loaded OTy_integer)))), (Pattern aU (CaseBase ((some t2symA531), (BTy_loaded OTy_integer))))])) (Expr aU (Eunseq [(Expr aU (Ewseq (Pattern aU (CaseBase ((some t2symA535), (BTy_object OTy_pointer)))) (Expr aU (Epure (Pexpr aU () (PEsym t2symA)))) (Expr aU (Eaction (Paction Pos (Action L0 empty_annotation (Load0 (Pexpr aU () (PEval (Vctype intCty))) (Pexpr aU () (PEsym t2symA535)) NA))))))), (Expr aU (Eaction (Paction Pos (Action L0 empty_annotation (Load0 (Pexpr aU () (PEval (Vctype intCty))) (Pexpr aU () (PEsym t2symA536)) NA)))))])) (Expr aU (Epure (Pexpr aU () (PEcase (Pexpr aU () (PEctor Ctuple [(Pexpr aU () (PEsym t2symA530)), (Pexpr aU () (PEsym t2symA531))])) [((Pattern aU (CaseCtor Ctuple [(Pattern aU (CaseCtor Cspecified [(Pattern aU (CaseBase ((some t2symA532), (BTy_object OTy_integer))))])), (Pattern aU (CaseCtor Cspecified [(Pattern aU (CaseBase ((some t2symA533), (BTy_object OTy_integer))))]))])), (Pexpr aU () (PEctor Cspecified [(Pexpr aU () (PEcatch_exceptional_condition (Signed Int_) IOpAdd (Pexpr aU () (PEconv_int (Signed Int_) (Pexpr aU () (PEsym t2symA532)))) (Pexpr aU () (PEconv_int (Signed Int_) (Pexpr aU () (PEsym t2symA533))))))]))), ((Pattern aU (CaseBase (none, (BTy_tuple [(BTy_loaded OTy_integer), (BTy_loaded OTy_integer)])))), (Pexpr aU () (PEundef L0 UB036_exceptional_condition)))])))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Erun empty_annotation t2symRet529 [(Pexpr aU () (PEcall (Sym t2symCLI) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym t2symA537))]))])) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Epure (Pexpr aU () (PEval Vunit)))) (Expr aU (Esave (t2symRet529, (BTy_loaded OTy_integer)) [(t2symA538, (((BTy_loaded OTy_integer), none), (Pexpr aU () (PEundef L0 UB088_reached_end_of_function))))] (Expr aU (Epure (Pexpr aU () (PEsym t2symA538))))))))))))

def t2ar3 : RExpr :=
  (Expr aU (Esseq (Pattern aU (CaseBase ((some t2symA537), (BTy_loaded OTy_integer)))) (Expr aU (Ebound (Expr aU (Ewseq (Pattern aU (CaseCtor Ctuple [(Pattern aU (CaseBase ((some t2symA530), (BTy_loaded OTy_integer)))), (Pattern aU (CaseBase ((some t2symA531), (BTy_loaded OTy_integer))))])) (Expr aU (Eunseq [(Expr aU (Ewseq (Pattern aU (CaseBase ((some t2symA535), (BTy_object OTy_pointer)))) (Expr aU (Epure (Pexpr aU () (PEsym t2symA)))) (Expr aU (Eaction (Paction Pos (Action L0 empty_annotation (Load0 (Pexpr aU () (PEval (Vctype intCty))) (Pexpr aU () (PEsym t2symA535)) NA))))))), (Expr aU (Eaction (Paction Pos (Action L0 empty_annotation (Load0 (Pexpr [] () (PEval (Vctype intCty))) (Pexpr [] () (PEval bPtrV)) NA)))))])) (Expr aU (Epure (Pexpr aU () (PEcase (Pexpr aU () (PEctor Ctuple [(Pexpr aU () (PEsym t2symA530)), (Pexpr aU () (PEsym t2symA531))])) [((Pattern aU (CaseCtor Ctuple [(Pattern aU (CaseCtor Cspecified [(Pattern aU (CaseBase ((some t2symA532), (BTy_object OTy_integer))))])), (Pattern aU (CaseCtor Cspecified [(Pattern aU (CaseBase ((some t2symA533), (BTy_object OTy_integer))))]))])), (Pexpr aU () (PEctor Cspecified [(Pexpr aU () (PEcatch_exceptional_condition (Signed Int_) IOpAdd (Pexpr aU () (PEconv_int (Signed Int_) (Pexpr aU () (PEsym t2symA532)))) (Pexpr aU () (PEconv_int (Signed Int_) (Pexpr aU () (PEsym t2symA533))))))]))), ((Pattern aU (CaseBase (none, (BTy_tuple [(BTy_loaded OTy_integer), (BTy_loaded OTy_integer)])))), (Pexpr aU () (PEundef L0 UB036_exceptional_condition)))])))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Erun empty_annotation t2symRet529 [(Pexpr aU () (PEcall (Sym t2symCLI) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym t2symA537))]))])) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Epure (Pexpr aU () (PEval Vunit)))) (Expr aU (Esave (t2symRet529, (BTy_loaded OTy_integer)) [(t2symA538, (((BTy_loaded OTy_integer), none), (Pexpr aU () (PEundef L0 UB088_reached_end_of_function))))] (Expr aU (Epure (Pexpr aU () (PEsym t2symA538))))))))))))

def t2ar4 (y : Int) : RExpr :=
  (Expr aU (Esseq (Pattern aU (CaseBase ((some t2symA537), (BTy_loaded OTy_integer)))) (Expr aU (Ebound (Expr aU (Ewseq (Pattern aU (CaseCtor Ctuple [(Pattern aU (CaseBase ((some t2symA530), (BTy_loaded OTy_integer)))), (Pattern aU (CaseBase ((some t2symA531), (BTy_loaded OTy_integer))))])) (Expr aU (Eunseq [(Expr aU (Ewseq (Pattern aU (CaseBase ((some t2symA535), (BTy_object OTy_pointer)))) (Expr aU (Epure (Pexpr aU () (PEsym t2symA)))) (Expr aU (Eaction (Paction Pos (Action L0 empty_annotation (Load0 (Pexpr aU () (PEval (Vctype intCty))) (Pexpr aU () (PEsym t2symA535)) NA))))))), (Expr [] (Eannot [(DA_pos [] (CerbMem.Footprint.FP .R 281474976710644 4))] (Expr [] (Epure (Pexpr [] () (PEval (loadedV y)))))))])) (Expr aU (Epure (Pexpr aU () (PEcase (Pexpr aU () (PEctor Ctuple [(Pexpr aU () (PEsym t2symA530)), (Pexpr aU () (PEsym t2symA531))])) [((Pattern aU (CaseCtor Ctuple [(Pattern aU (CaseCtor Cspecified [(Pattern aU (CaseBase ((some t2symA532), (BTy_object OTy_integer))))])), (Pattern aU (CaseCtor Cspecified [(Pattern aU (CaseBase ((some t2symA533), (BTy_object OTy_integer))))]))])), (Pexpr aU () (PEctor Cspecified [(Pexpr aU () (PEcatch_exceptional_condition (Signed Int_) IOpAdd (Pexpr aU () (PEconv_int (Signed Int_) (Pexpr aU () (PEsym t2symA532)))) (Pexpr aU () (PEconv_int (Signed Int_) (Pexpr aU () (PEsym t2symA533))))))]))), ((Pattern aU (CaseBase (none, (BTy_tuple [(BTy_loaded OTy_integer), (BTy_loaded OTy_integer)])))), (Pexpr aU () (PEundef L0 UB036_exceptional_condition)))])))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Erun empty_annotation t2symRet529 [(Pexpr aU () (PEcall (Sym t2symCLI) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym t2symA537))]))])) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Epure (Pexpr aU () (PEval Vunit)))) (Expr aU (Esave (t2symRet529, (BTy_loaded OTy_integer)) [(t2symA538, (((BTy_loaded OTy_integer), none), (Pexpr aU () (PEundef L0 UB088_reached_end_of_function))))] (Expr aU (Epure (Pexpr aU () (PEsym t2symA538))))))))))))

def t2ar5 (y : Int) : RExpr :=
  (Expr aU (Esseq (Pattern aU (CaseBase ((some t2symA537), (BTy_loaded OTy_integer)))) (Expr aU (Ebound (Expr aU (Ewseq (Pattern aU (CaseCtor Ctuple [(Pattern aU (CaseBase ((some t2symA530), (BTy_loaded OTy_integer)))), (Pattern aU (CaseBase ((some t2symA531), (BTy_loaded OTy_integer))))])) (Expr aU (Eunseq [(Expr aU (Ewseq (Pattern aU (CaseBase ((some t2symA535), (BTy_object OTy_pointer)))) (Expr aU (Epure (Pexpr [] () (PEval xPtrV)))) (Expr aU (Eaction (Paction Pos (Action L0 empty_annotation (Load0 (Pexpr aU () (PEval (Vctype intCty))) (Pexpr aU () (PEsym t2symA535)) NA))))))), (Expr [] (Eannot [(DA_pos [] (CerbMem.Footprint.FP .R 281474976710644 4))] (Expr [] (Epure (Pexpr [] () (PEval (loadedV y)))))))])) (Expr aU (Epure (Pexpr aU () (PEcase (Pexpr aU () (PEctor Ctuple [(Pexpr aU () (PEsym t2symA530)), (Pexpr aU () (PEsym t2symA531))])) [((Pattern aU (CaseCtor Ctuple [(Pattern aU (CaseCtor Cspecified [(Pattern aU (CaseBase ((some t2symA532), (BTy_object OTy_integer))))])), (Pattern aU (CaseCtor Cspecified [(Pattern aU (CaseBase ((some t2symA533), (BTy_object OTy_integer))))]))])), (Pexpr aU () (PEctor Cspecified [(Pexpr aU () (PEcatch_exceptional_condition (Signed Int_) IOpAdd (Pexpr aU () (PEconv_int (Signed Int_) (Pexpr aU () (PEsym t2symA532)))) (Pexpr aU () (PEconv_int (Signed Int_) (Pexpr aU () (PEsym t2symA533))))))]))), ((Pattern aU (CaseBase (none, (BTy_tuple [(BTy_loaded OTy_integer), (BTy_loaded OTy_integer)])))), (Pexpr aU () (PEundef L0 UB036_exceptional_condition)))])))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Erun empty_annotation t2symRet529 [(Pexpr aU () (PEcall (Sym t2symCLI) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym t2symA537))]))])) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Epure (Pexpr aU () (PEval Vunit)))) (Expr aU (Esave (t2symRet529, (BTy_loaded OTy_integer)) [(t2symA538, (((BTy_loaded OTy_integer), none), (Pexpr aU () (PEundef L0 UB088_reached_end_of_function))))] (Expr aU (Epure (Pexpr aU () (PEsym t2symA538))))))))))))

def t2ar6 (y : Int) : RExpr :=
  (Expr aU (Esseq (Pattern aU (CaseBase ((some t2symA537), (BTy_loaded OTy_integer)))) (Expr aU (Ebound (Expr aU (Ewseq (Pattern aU (CaseCtor Ctuple [(Pattern aU (CaseBase ((some t2symA530), (BTy_loaded OTy_integer)))), (Pattern aU (CaseBase ((some t2symA531), (BTy_loaded OTy_integer))))])) (Expr aU (Eunseq [(Expr aU (Eaction (Paction Pos (Action L0 empty_annotation (Load0 (Pexpr aU () (PEval (Vctype intCty))) (Pexpr aU () (PEsym t2symA535)) NA))))), (Expr [] (Eannot [(DA_pos [] (CerbMem.Footprint.FP .R 281474976710644 4))] (Expr [] (Epure (Pexpr [] () (PEval (loadedV y)))))))])) (Expr aU (Epure (Pexpr aU () (PEcase (Pexpr aU () (PEctor Ctuple [(Pexpr aU () (PEsym t2symA530)), (Pexpr aU () (PEsym t2symA531))])) [((Pattern aU (CaseCtor Ctuple [(Pattern aU (CaseCtor Cspecified [(Pattern aU (CaseBase ((some t2symA532), (BTy_object OTy_integer))))])), (Pattern aU (CaseCtor Cspecified [(Pattern aU (CaseBase ((some t2symA533), (BTy_object OTy_integer))))]))])), (Pexpr aU () (PEctor Cspecified [(Pexpr aU () (PEcatch_exceptional_condition (Signed Int_) IOpAdd (Pexpr aU () (PEconv_int (Signed Int_) (Pexpr aU () (PEsym t2symA532)))) (Pexpr aU () (PEconv_int (Signed Int_) (Pexpr aU () (PEsym t2symA533))))))]))), ((Pattern aU (CaseBase (none, (BTy_tuple [(BTy_loaded OTy_integer), (BTy_loaded OTy_integer)])))), (Pexpr aU () (PEundef L0 UB036_exceptional_condition)))])))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Erun empty_annotation t2symRet529 [(Pexpr aU () (PEcall (Sym t2symCLI) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym t2symA537))]))])) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Epure (Pexpr aU () (PEval Vunit)))) (Expr aU (Esave (t2symRet529, (BTy_loaded OTy_integer)) [(t2symA538, (((BTy_loaded OTy_integer), none), (Pexpr aU () (PEundef L0 UB088_reached_end_of_function))))] (Expr aU (Epure (Pexpr aU () (PEsym t2symA538))))))))))))

def t2ar7 (y : Int) : RExpr :=
  (Expr aU (Esseq (Pattern aU (CaseBase ((some t2symA537), (BTy_loaded OTy_integer)))) (Expr aU (Ebound (Expr aU (Ewseq (Pattern aU (CaseCtor Ctuple [(Pattern aU (CaseBase ((some t2symA530), (BTy_loaded OTy_integer)))), (Pattern aU (CaseBase ((some t2symA531), (BTy_loaded OTy_integer))))])) (Expr aU (Eunseq [(Expr aU (Eaction (Paction Pos (Action L0 empty_annotation (Load0 (Pexpr [] () (PEval (Vctype intCty))) (Pexpr [] () (PEval xPtrV)) NA))))), (Expr [] (Eannot [(DA_pos [] (CerbMem.Footprint.FP .R 281474976710644 4))] (Expr [] (Epure (Pexpr [] () (PEval (loadedV y)))))))])) (Expr aU (Epure (Pexpr aU () (PEcase (Pexpr aU () (PEctor Ctuple [(Pexpr aU () (PEsym t2symA530)), (Pexpr aU () (PEsym t2symA531))])) [((Pattern aU (CaseCtor Ctuple [(Pattern aU (CaseCtor Cspecified [(Pattern aU (CaseBase ((some t2symA532), (BTy_object OTy_integer))))])), (Pattern aU (CaseCtor Cspecified [(Pattern aU (CaseBase ((some t2symA533), (BTy_object OTy_integer))))]))])), (Pexpr aU () (PEctor Cspecified [(Pexpr aU () (PEcatch_exceptional_condition (Signed Int_) IOpAdd (Pexpr aU () (PEconv_int (Signed Int_) (Pexpr aU () (PEsym t2symA532)))) (Pexpr aU () (PEconv_int (Signed Int_) (Pexpr aU () (PEsym t2symA533))))))]))), ((Pattern aU (CaseBase (none, (BTy_tuple [(BTy_loaded OTy_integer), (BTy_loaded OTy_integer)])))), (Pexpr aU () (PEundef L0 UB036_exceptional_condition)))])))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Erun empty_annotation t2symRet529 [(Pexpr aU () (PEcall (Sym t2symCLI) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym t2symA537))]))])) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Epure (Pexpr aU () (PEval Vunit)))) (Expr aU (Esave (t2symRet529, (BTy_loaded OTy_integer)) [(t2symA538, (((BTy_loaded OTy_integer), none), (Pexpr aU () (PEundef L0 UB088_reached_end_of_function))))] (Expr aU (Epure (Pexpr aU () (PEsym t2symA538))))))))))))

def t2ar8 (x : Int) (y : Int) : RExpr :=
  (Expr aU (Esseq (Pattern aU (CaseBase ((some t2symA537), (BTy_loaded OTy_integer)))) (Expr aU (Ebound (Expr aU (Ewseq (Pattern aU (CaseCtor Ctuple [(Pattern aU (CaseBase ((some t2symA530), (BTy_loaded OTy_integer)))), (Pattern aU (CaseBase ((some t2symA531), (BTy_loaded OTy_integer))))])) (Expr aU (Eunseq [(Expr [] (Eannot [(DA_pos [] (CerbMem.Footprint.FP .R 281474976710648 4))] (Expr [] (Epure (Pexpr [] () (PEval (loadedV x))))))), (Expr [] (Eannot [(DA_pos [] (CerbMem.Footprint.FP .R 281474976710644 4))] (Expr [] (Epure (Pexpr [] () (PEval (loadedV y)))))))])) (Expr aU (Epure (Pexpr aU () (PEcase (Pexpr aU () (PEctor Ctuple [(Pexpr aU () (PEsym t2symA530)), (Pexpr aU () (PEsym t2symA531))])) [((Pattern aU (CaseCtor Ctuple [(Pattern aU (CaseCtor Cspecified [(Pattern aU (CaseBase ((some t2symA532), (BTy_object OTy_integer))))])), (Pattern aU (CaseCtor Cspecified [(Pattern aU (CaseBase ((some t2symA533), (BTy_object OTy_integer))))]))])), (Pexpr aU () (PEctor Cspecified [(Pexpr aU () (PEcatch_exceptional_condition (Signed Int_) IOpAdd (Pexpr aU () (PEconv_int (Signed Int_) (Pexpr aU () (PEsym t2symA532)))) (Pexpr aU () (PEconv_int (Signed Int_) (Pexpr aU () (PEsym t2symA533))))))]))), ((Pattern aU (CaseBase (none, (BTy_tuple [(BTy_loaded OTy_integer), (BTy_loaded OTy_integer)])))), (Pexpr aU () (PEundef L0 UB036_exceptional_condition)))])))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Erun empty_annotation t2symRet529 [(Pexpr aU () (PEcall (Sym t2symCLI) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym t2symA537))]))])) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Epure (Pexpr aU () (PEval Vunit)))) (Expr aU (Esave (t2symRet529, (BTy_loaded OTy_integer)) [(t2symA538, (((BTy_loaded OTy_integer), none), (Pexpr aU () (PEundef L0 UB088_reached_end_of_function))))] (Expr aU (Epure (Pexpr aU () (PEsym t2symA538))))))))))))

def t2ar9 (x : Int) (y : Int) : RExpr :=
  (Expr aU (Esseq (Pattern aU (CaseBase ((some t2symA537), (BTy_loaded OTy_integer)))) (Expr aU (Ebound (Expr aU (Ewseq (Pattern aU (CaseCtor Ctuple [(Pattern aU (CaseBase ((some t2symA530), (BTy_loaded OTy_integer)))), (Pattern aU (CaseBase ((some t2symA531), (BTy_loaded OTy_integer))))])) (Expr aU (Eannot [(DA_pos [] (CerbMem.Footprint.FP .R 281474976710644 4)), (DA_pos [] (CerbMem.Footprint.FP .R 281474976710648 4))] (Expr [] (Epure (Pexpr [] () (PEval (Vtuple [(loadedV x), (loadedV y)]))))))) (Expr aU (Epure (Pexpr aU () (PEcase (Pexpr aU () (PEctor Ctuple [(Pexpr aU () (PEsym t2symA530)), (Pexpr aU () (PEsym t2symA531))])) [((Pattern aU (CaseCtor Ctuple [(Pattern aU (CaseCtor Cspecified [(Pattern aU (CaseBase ((some t2symA532), (BTy_object OTy_integer))))])), (Pattern aU (CaseCtor Cspecified [(Pattern aU (CaseBase ((some t2symA533), (BTy_object OTy_integer))))]))])), (Pexpr aU () (PEctor Cspecified [(Pexpr aU () (PEcatch_exceptional_condition (Signed Int_) IOpAdd (Pexpr aU () (PEconv_int (Signed Int_) (Pexpr aU () (PEsym t2symA532)))) (Pexpr aU () (PEconv_int (Signed Int_) (Pexpr aU () (PEsym t2symA533))))))]))), ((Pattern aU (CaseBase (none, (BTy_tuple [(BTy_loaded OTy_integer), (BTy_loaded OTy_integer)])))), (Pexpr aU () (PEundef L0 UB036_exceptional_condition)))])))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Erun empty_annotation t2symRet529 [(Pexpr aU () (PEcall (Sym t2symCLI) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym t2symA537))]))])) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Epure (Pexpr aU () (PEval Vunit)))) (Expr aU (Esave (t2symRet529, (BTy_loaded OTy_integer)) [(t2symA538, (((BTy_loaded OTy_integer), none), (Pexpr aU () (PEundef L0 UB088_reached_end_of_function))))] (Expr aU (Epure (Pexpr aU () (PEsym t2symA538))))))))))))

def t2ar10 : RExpr :=
  (Expr aU (Esseq (Pattern aU (CaseBase ((some t2symA537), (BTy_loaded OTy_integer)))) (Expr aU (Ebound (Expr [] (Eannot [(DA_pos [] (CerbMem.Footprint.FP .R 281474976710644 4)), (DA_pos [] (CerbMem.Footprint.FP .R 281474976710648 4))] (Expr aU (Epure (Pexpr aU () (PEcase (Pexpr aU () (PEctor Ctuple [(Pexpr aU () (PEsym t2symA530)), (Pexpr aU () (PEsym t2symA531))])) [((Pattern aU (CaseCtor Ctuple [(Pattern aU (CaseCtor Cspecified [(Pattern aU (CaseBase ((some t2symA532), (BTy_object OTy_integer))))])), (Pattern aU (CaseCtor Cspecified [(Pattern aU (CaseBase ((some t2symA533), (BTy_object OTy_integer))))]))])), (Pexpr aU () (PEctor Cspecified [(Pexpr aU () (PEcatch_exceptional_condition (Signed Int_) IOpAdd (Pexpr aU () (PEconv_int (Signed Int_) (Pexpr aU () (PEsym t2symA532)))) (Pexpr aU () (PEconv_int (Signed Int_) (Pexpr aU () (PEsym t2symA533))))))]))), ((Pattern aU (CaseBase (none, (BTy_tuple [(BTy_loaded OTy_integer), (BTy_loaded OTy_integer)])))), (Pexpr aU () (PEundef L0 UB036_exceptional_condition)))])))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Erun empty_annotation t2symRet529 [(Pexpr aU () (PEcall (Sym t2symCLI) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym t2symA537))]))])) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Epure (Pexpr aU () (PEval Vunit)))) (Expr aU (Esave (t2symRet529, (BTy_loaded OTy_integer)) [(t2symA538, (((BTy_loaded OTy_integer), none), (Pexpr aU () (PEundef L0 UB088_reached_end_of_function))))] (Expr aU (Epure (Pexpr aU () (PEsym t2symA538))))))))))))

def t2ar11 (s : Int) : RExpr :=
  (Expr aU (Esseq (Pattern aU (CaseBase ((some t2symA537), (BTy_loaded OTy_integer)))) (Expr aU (Ebound (Expr [] (Eannot [(DA_pos [] (CerbMem.Footprint.FP .R 281474976710644 4)), (DA_pos [] (CerbMem.Footprint.FP .R 281474976710648 4))] (Expr aU (Epure (Pexpr [] () (PEval (loadedV s))))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Erun empty_annotation t2symRet529 [(Pexpr aU () (PEcall (Sym t2symCLI) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym t2symA537))]))])) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Epure (Pexpr aU () (PEval Vunit)))) (Expr aU (Esave (t2symRet529, (BTy_loaded OTy_integer)) [(t2symA538, (((BTy_loaded OTy_integer), none), (Pexpr aU () (PEundef L0 UB088_reached_end_of_function))))] (Expr aU (Epure (Pexpr aU () (PEsym t2symA538))))))))))))

def t2ar12 (s : Int) : RExpr :=
  (Expr aU (Esseq (Pattern aU (CaseBase ((some t2symA537), (BTy_loaded OTy_integer)))) (Expr aU (Epure (Pexpr [] () (PEval (loadedV s))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Erun empty_annotation t2symRet529 [(Pexpr aU () (PEcall (Sym t2symCLI) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym t2symA537))]))])) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Epure (Pexpr aU () (PEval Vunit)))) (Expr aU (Esave (t2symRet529, (BTy_loaded OTy_integer)) [(t2symA538, (((BTy_loaded OTy_integer), none), (Pexpr aU () (PEundef L0 UB088_reached_end_of_function))))] (Expr aU (Epure (Pexpr aU () (PEsym t2symA538))))))))))))

def t2ar13 : RExpr :=
  (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Erun empty_annotation t2symRet529 [(Pexpr aU () (PEcall (Sym t2symCLI) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym t2symA537))]))])) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Epure (Pexpr aU () (PEval Vunit)))) (Expr aU (Esave (t2symRet529, (BTy_loaded OTy_integer)) [(t2symA538, (((BTy_loaded OTy_integer), none), (Pexpr aU () (PEundef L0 UB088_reached_end_of_function))))] (Expr aU (Epure (Pexpr aU () (PEsym t2symA538))))))))))

def t2ar14 : RExpr :=
  (Expr aU (Epure (Pexpr aU () (PEsym t2symA538))))

def t2arDone (s : Int) : RExpr :=
  (Expr aU (Epure (Pexpr [] () (PEval (loadedV s)))))

/-! ## The T2 families -/

@[reducible] def t2Th (arena : RExpr) (f₁ : Fmap sym value) :
    thread_state :=
  { arena := arena,
    stack0 := Stack_empty,
    errno := t2errPtr,
    current_loc := L0,
    exec_loc := ELoc_normal [(addT2Sym, CerbLocation.other "RelSem.callND")],
    env := [f₁],
    current_proc_opt := some addT2Sym }

@[reducible] def t2σ (arena : RExpr) (f₁ : Fmap sym value)
    (tS aS eS sS : Nat) (ls : CerbMem.MemState)
    (tr : List trace_event) (n : Nat) : driver_state :=
  { core_file := t2File,
    core_extern := create_extern_symmap t2File,
    core_state0 :=
      { thread_states := [(0, (none, t2Th arena f₁))],
        io := initial_io_state },
    core_run_state0 :=
      { tid_supply := tS, aid_supply := aS, excluded_supply := eS,
        sym_supply := sS,
        labeled := (initial_core_run_state_threaded 0
          (collect_labeled_continuations_NEW t2File)).labeled },
    layout_state := ls,
    concurrency_state := symInitialState symInitialPre,
    fs_state0 := CerbFS.fs_initial_state,
    trace := tr,
    symbolic_assoc := fmapEmpty,
    blocked := false,
    dr_step_counter := n }

def t2CtlAt (arena : RExpr) (tr : List trace_event) (n : Nat) :
    driver_state :=
  ctlOf (t2σ arena fmapEmpty 0 0 0 0 CerbMem.initialMemState tr n)

@[reducible] def t2fam (arena : RExpr) (tr : List trace_event)
    (n : Nat) (p : T1P) : driver_state :=
  t2σ arena p.f₁ p.tS p.aS p.eS p.sS p.ls tr n

theorem t2_inv {σ : driver_state} {arena : RExpr}
    {tr : List trace_event} {n : Nat}
    (h : ctlOf σ = t2CtlAt arena tr n) :
    ∃ p : T1P, σ = t2fam arena tr n p := by
  obtain ⟨cf, ce, cs, crs, ls, ccs, fs0, tr', sa, bl, ctr'⟩ := σ
  obtain ⟨ths, io⟩ := cs
  obtain ⟨tS, aS, eS, sS, lab⟩ := crs
  have h' := h
  simp only [t2CtlAt, ctlOf, t2σ, eraseEnvs, driver_state.mk.injEq,
    core_state.mk.injEq, core_run_state.mk.injEq] at h'
  obtain ⟨hcf, hce, ⟨hths, hio⟩, ⟨-, -, -, -, hlab⟩, -, hccs, hfs,
    htr, hsa, hbl, hctr⟩ := h'
  cases ths with
  | nil => simp at hths
  | cons t rest =>
    obtain ⟨tid, pp, th⟩ := t
    obtain ⟨arena', stack', errno', env', proc', exec', loc'⟩ := th
    simp only [List.map_cons, List.map_nil, List.cons.injEq,
      List.map_eq_nil_iff, Prod.mk.injEq, eraseThreadEnv, t2Th,
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

theorem t2fam_frame {arena : RExpr} {tr : List trace_event} {n : Nat}
    {p : T1P} (hwf : EnvWf (t2fam arena tr n p)) :
    EnvWfFrame p.f₁ :=
  hwf p.f₁ (by
    show p.f₁ ∈ thread0Env _
    simp [thread0Env])

/-! ## The stage-0 family -/

@[reducible] def t2Th0 (arena : RExpr) (f₁ : Fmap sym value) :
    thread_state :=
  { arena := arena,
    stack0 := Stack_empty,
    errno := t2errPtr,
    current_loc := CerbLocation.other "RelSem.callND",
    exec_loc := ELoc_normal [(addT2Sym, CerbLocation.other "RelSem.callND")],
    env := [f₁],
    current_proc_opt := some addT2Sym }

@[reducible] def t2σ0 (f₁ : Fmap sym value)
    (tS aS eS sS : Nat) (ls : CerbMem.MemState) : driver_state :=
  { core_file := t2File,
    core_extern := create_extern_symmap t2File,
    core_state0 :=
      { thread_states := [(0, (none, t2Th0 t2ar0 f₁))],
        io := initial_io_state },
    core_run_state0 :=
      { tid_supply := tS, aid_supply := aS, excluded_supply := eS,
        sym_supply := sS,
        labeled := (initial_core_run_state_threaded 0
          (collect_labeled_continuations_NEW t2File)).labeled },
    layout_state := ls,
    concurrency_state := symInitialState symInitialPre,
    fs_state0 := CerbFS.fs_initial_state,
    trace := [],
    symbolic_assoc := fmapEmpty,
    blocked := false,
    dr_step_counter := 0 }

def t2Ctl0 : driver_state :=
  ctlOf (t2σ0 fmapEmpty 0 0 0 0 CerbMem.initialMemState)

@[reducible] def t2fam0 (p : T1P) : driver_state :=
  t2σ0 p.f₁ p.tS p.aS p.eS p.sS p.ls

theorem t2_inv0 {σ : driver_state} (h : ctlOf σ = t2Ctl0) :
    ∃ p : T1P, σ = t2fam0 p := by
  obtain ⟨cf, ce, cs, crs, ls, ccs, fs0, tr', sa, bl, ctr'⟩ := σ
  obtain ⟨ths, io⟩ := cs
  obtain ⟨tS, aS, eS, sS, lab⟩ := crs
  have h' := h
  simp only [t2Ctl0, ctlOf, t2σ0, eraseEnvs, driver_state.mk.injEq,
    core_state.mk.injEq, core_run_state.mk.injEq] at h'
  obtain ⟨hcf, hce, ⟨hths, hio⟩, ⟨-, -, -, -, hlab⟩, -, hccs, hfs,
    htr, hsa, hbl, hctr⟩ := h'
  cases ths with
  | nil => simp at hths
  | cons t rest =>
    obtain ⟨tid, pp, th⟩ := t
    obtain ⟨arena', stack', errno', env', proc', exec', loc'⟩ := th
    simp only [List.map_cons, List.map_nil, List.cons.injEq,
      List.map_eq_nil_iff, Prod.mk.injEq, eraseThreadEnv, t2Th0,
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

theorem t2fam0_frame {p : T1P} (hwf : EnvWf (t2fam0 p)) :
    EnvWfFrame p.f₁ :=
  hwf p.f₁ (by
    show p.f₁ ∈ thread0Env _
    simp [thread0Env])

/-! ## The initial and post-globals families + stage laws -/

def t2Init (seed : Nat) (ls : CerbMem.MemState) : driver_state :=
  { initial_driver_state_threaded seed t2File t2Fs with
      layout_state := ls }

@[reducible] def t2thGf (f₀ : Fmap sym value) : thread_state :=
  { arena := Expr [] (Epure (Pexpr [] () (PEval Vunit))),
    stack0 := Stack_empty,
    errno := .PV .Prov_none (.PVnull intCty),
    current_loc := CerbLocation.Loc.unknown,
    exec_loc := ELoc_globals,
    env := [f₀],
    current_proc_opt := none }

@[reducible] def t2dGσ (f₀ : Fmap sym value) (tS aS eS sS : Nat)
    (ls : CerbMem.MemState) : driver_state :=
  { core_file := t2File,
    core_extern := create_extern_symmap t2File,
    core_state0 :=
      { thread_states := [(0, (none, t2thGf f₀))],
        io := initial_io_state },
    core_run_state0 :=
      { tid_supply := tS, aid_supply := aS, excluded_supply := eS,
        sym_supply := sS,
        labeled := (initial_core_run_state_threaded 0
          (collect_labeled_continuations_NEW t2File)).labeled },
    layout_state := ls,
    concurrency_state := symInitialState symInitialPre,
    fs_state0 := CerbFS.fs_initial_state,
    trace := [],
    symbolic_assoc := fmapEmpty,
    blocked := false,
    dr_step_counter := 0 }

def t2dGCtl : driver_state :=
  ctlOf (t2dGσ fmapEmpty 0 0 0 0 CerbMem.initialMemState)

@[reducible] def t2dGfam (p : RelSem.T1.DGP) : driver_state :=
  t2dGσ p.f₀ p.tS p.aS p.eS p.sS p.ls

theorem t2dG_inv {σ : driver_state} (h : ctlOf σ = t2dGCtl) :
    ∃ p : RelSem.T1.DGP, σ = t2dGfam p := by
  obtain ⟨cf, ce, cs, crs, ls, ccs, fs0, tr', sa, bl, ctr'⟩ := σ
  obtain ⟨ths, io⟩ := cs
  obtain ⟨tS, aS, eS, sS, lab⟩ := crs
  have h' := h
  simp only [t2dGCtl, ctlOf, t2dGσ, eraseEnvs, driver_state.mk.injEq,
    core_state.mk.injEq, core_run_state.mk.injEq] at h'
  obtain ⟨hcf, hce, ⟨hths, hio⟩, ⟨-, -, -, -, hlab⟩, -, hccs, hfs,
    htr, hsa, hbl, hctr⟩ := h'
  cases ths with
  | nil => simp at hths
  | cons t rest =>
    obtain ⟨tid, pp, th⟩ := t
    obtain ⟨arena', stack', errno', env', proc', exec', loc'⟩ := th
    simp only [List.map_cons, List.map_nil, List.cons.injEq,
      List.map_eq_nil_iff, Prod.mk.injEq, eraseThreadEnv, t2thGf,
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

theorem t2Init_inv {σ : driver_state} {seed : Nat}
    (h : ctlOf σ = ctlOf (t2Init 0 CerbMem.initialMemState))
    (hs : suppliesOf σ
      = suppliesOf (t2Init seed CerbMem.initialMemState)) :
    σ = t2Init seed σ.layout_state := by
  obtain ⟨cf, ce, cs, crs, ls, ccs, fs0, tr', sa, bl, ctr'⟩ := σ
  obtain ⟨ths, io⟩ := cs
  obtain ⟨tS, aS, eS, sS, lab⟩ := crs
  have h' := h
  simp only [t2Init, ctlOf, eraseEnvs, driver_state.mk.injEq,
    core_state.mk.injEq, core_run_state.mk.injEq] at h'
  obtain ⟨hcf, hce, ⟨hths, hio⟩, ⟨-, -, -, -, hlab⟩, -, hccs, hfs,
    htr, hsa, hbl, hctr⟩ := h'
  have hs' := hs
  simp only [suppliesOf, t2Init, Supplies.mk.injEq] at hs'
  obtain ⟨hts, has, hes, hss⟩ := hs'
  cases ths with
  | cons t rest =>
    rw [show (initial_driver_state_threaded 0 t2File
        t2Fs).core_state0.thread_states
      = ([] : List (Nat × (Option thread_id × thread_state)))
      from rfl] at hths
    simp at hths
  | nil =>
    subst hcf hce hccs hfs htr hsa hbl hctr hio hlab hts has hes hss
    rfl

theorem t2k1_fam (seed : Nat) (ls : CerbMem.MemState) :
    app (driver_globals t2File.tagDefs false t2File)
        (t2Init seed ls)
      = (NDactive 0, t2dGσ fmapEmpty 1 0 0 seed ls) := rfl

theorem t2k3_any (σ : driver_state) :
    app (resolveFunSym t2File "add") σ
      = (NDactive addT2Sym, σ) := rfl

theorem t2k4_any (σ : driver_state) :
    app (lookupFunBody t2File addT2Sym) σ
      = (NDactive ([(t2symA, BTy_object OTy_pointer),
                    (t2symB, BTy_object OTy_pointer)], t2ar0), σ) := rfl

theorem t2k5_any (σ : driver_state) :
    app (lookupParamTys t2File addT2Sym) σ
      = (NDactive [signed_int, signed_int], σ) := rfl

theorem t2_init_ctl_eq (seed : Nat) :
    ctlOf (initial_driver_state_threaded seed t2File t2Fs)
      = ctlOf (t2Init 0 CerbMem.initialMemState) := rfl

theorem t2_init_sup_eq (seed : Nat) :
    suppliesOf (initial_driver_state_threaded seed t2File t2Fs)
      = suppliesOf (t2Init seed CerbMem.initialMemState) := rfl

theorem t2_init_mrest_eq (seed : Nat) :
    memRestOf (initial_driver_state_threaded seed t2File t2Fs)
      = mr0 := rfl

/-! ## The inject/errno memory-stage laws (TWO arguments) -/

/-- The stage-A post-store memory (spelled for the stage-B facts). -/
@[reducible] def t2memA (x : Int) (ls : CerbMem.MemState) :
    CerbMem.MemState :=
  layoutAllocStore ls xAddr 4 allocXS (xBytes x)

/-- k6×2: the two-argument injection at residual facts. -/
theorem t2k6_fam (x y : Int) (σ : driver_state)
    (hmr : memRestOf σ = mr0) (hinv : MemInv σ.layout_state) :
    app (injectArgs t2File.tagDefs 0
          [(t2symA, BTy_object OTy_pointer),
           (t2symB, BTy_object OTy_pointer)]
          [signed_int, signed_int] [intValue x, intValue y]) σ
      = (NDactive [(t2symA, xPtrV), (t2symB, bPtrV)],
         { σ with layout_state :=
             (layoutAllocStore (t2memA x σ.layout_state) bAddr 4
               allocBS (xBytes y)) }) := by
  have hlast : σ.layout_state.lastAddress = mr0.lastAddress := by
    rw [show σ.layout_state.lastAddress = (memRestOf σ).lastAddress
      from rfl, hmr]
  have h0 : σ.layout_state.nextAllocId = 0 := by
    rw [show σ.layout_state.nextAllocId = (memRestOf σ).nextAllocId
      from rfl, hmr]
    rfl
  -- stage A (x's object at xAddr)
  have hallocA := Kit.mem_alloc_block (tid := 0)
    (pref := PrefOther "callND arg") (pv := .Prov_none)
    (alignN := 4) (ty := signed_int) (mem := σ.layout_state)
    (addrOpt := none) (sz := 4) (a := xAddr)
    rfl (by rw [hlast]; rfl) rfl
  have hgetA : (CerbMem.writeBytesTo
      ({ σ.layout_state with
          nextAllocId := σ.layout_state.nextAllocId + 1,
          lastAddress := xAddr,
          allocations := σ.layout_state.allocations.insert
            σ.layout_state.nextAllocId allocXS })
      xAddr (List.replicate 4 RelSem.CerbSt.uninitB)).allocations.get?
        σ.layout_state.nextAllocId
      = some allocXS := by
    rw [Kit.writeBytesTo_allocations]
    exact Kit.tm_get?_insert_eq _ _ _
  have hstoreA := Kit.mem_store_block
    (loc := CerbLocation.other "callND arg init") (ty := signed_int)
    (allocId := σ.layout_state.nextAllocId) (addr := xAddr)
    (alloc := allocXS)
    (mem := CerbMem.writeBytesTo
      ({ σ.layout_state with
          nextAllocId := σ.layout_state.nextAllocId + 1,
          lastAddress := xAddr,
          allocations := σ.layout_state.allocations.insert
            σ.layout_state.nextAllocId allocXS })
      xAddr (List.replicate 4 RelSem.CerbSt.uninitB))
    (mv := CerbMem.integerValueMval (Signed Int_)
      (CerbMem.integerIval x))
    rfl hgetA rfl rfl rfl
    (by rw [Kit.writeBytesTo_funptrmap])
  -- stage B (y's object at bAddr, in the stage-A memory)
  have hlastB : (t2memA x σ.layout_state).lastAddress = xAddr := by
    rfl
  have hallocB := Kit.mem_alloc_block (tid := 0)
    (pref := PrefOther "callND arg") (pv := .Prov_none)
    (alignN := 4) (ty := signed_int)
    (mem := t2memA x σ.layout_state)
    (addrOpt := none) (sz := 4) (a := bAddr)
    rfl (by rw [hlastB]; rfl) rfl
  have hgetB : (CerbMem.writeBytesTo
      ({ t2memA x σ.layout_state with
          nextAllocId := (t2memA x σ.layout_state).nextAllocId + 1,
          lastAddress := bAddr,
          allocations := (t2memA x σ.layout_state).allocations.insert
            (t2memA x σ.layout_state).nextAllocId allocBS })
      bAddr (List.replicate 4 RelSem.CerbSt.uninitB)).allocations.get?
        (t2memA x σ.layout_state).nextAllocId
      = some allocBS := by
    rw [Kit.writeBytesTo_allocations]
    exact Kit.tm_get?_insert_eq _ _ _
  have hstoreB := Kit.mem_store_block
    (loc := CerbLocation.other "callND arg init") (ty := signed_int)
    (allocId := (t2memA x σ.layout_state).nextAllocId) (addr := bAddr)
    (alloc := allocBS)
    (mem := CerbMem.writeBytesTo
      ({ t2memA x σ.layout_state with
          nextAllocId := (t2memA x σ.layout_state).nextAllocId + 1,
          lastAddress := bAddr,
          allocations := (t2memA x σ.layout_state).allocations.insert
            (t2memA x σ.layout_state).nextAllocId allocBS })
      bAddr (List.replicate 4 RelSem.CerbSt.uninitB))
    (mv := CerbMem.integerValueMval (Signed Int_)
      (CerbMem.integerIval y))
    rfl hgetB rfl rfl rfl
    (by rw [Kit.writeBytesTo_funptrmap])
  rw [show xPtrV = Vobject (OVpointer
      (.PV (.Prov_some σ.layout_state.nextAllocId)
        (.PVconcrete none xAddr))) from by rw [h0]; rfl,
    show bPtrV = Vobject (OVpointer
      (.PV (.Prov_some ((t2memA x σ.layout_state).nextAllocId))
        (.PVconcrete none bAddr))) from by
      show bPtrV = Vobject (OVpointer
        (.PV (.Prov_some (σ.layout_state.nextAllocId + 1))
          (.PVconcrete none bAddr)))
      rw [h0]; rfl]
  exact RelSem.Laws.inject_ptr_arg2 (memValueFromValue_int x)
    (memValueFromValue_int y) hallocA hstoreA hallocB hstoreB rfl

/-- k8 at T2: the errno block after the two argument objects. -/
theorem t2k8_fam (x : Int) (σ : driver_state)
    (hmr : memRestOf σ = t2mr2) (hinv : MemInv σ.layout_state) :
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
      = (NDactive t2errPtr,
         { σ with layout_state :=
             (layoutAllocStore σ.layout_state t2errAddr 4 t2allocErrS
               RelSem.T1.zeroBytes) }) := by
  have hlast : σ.layout_state.lastAddress = t2mr2.lastAddress := by
    rw [show σ.layout_state.lastAddress = (memRestOf σ).lastAddress
      from rfl, hmr]
  have h0 : σ.layout_state.nextAllocId = 2 := by
    rw [show σ.layout_state.nextAllocId = (memRestOf σ).nextAllocId
      from rfl, hmr]
    rfl
  have halloc := Kit.mem_alloc_block (tid := 0)
    (pref := PrefOther "errno") (pv := .Prov_none)
    (alignN := 4) (ty := signed_int) (mem := σ.layout_state)
    (addrOpt := none) (sz := 4) (a := t2errAddr)
    rfl (by rw [hlast]; rfl) rfl
  have hget1 : (CerbMem.writeBytesTo
      ({ σ.layout_state with
          nextAllocId := σ.layout_state.nextAllocId + 1,
          lastAddress := t2errAddr,
          allocations := σ.layout_state.allocations.insert
            σ.layout_state.nextAllocId t2allocErrS })
      t2errAddr (List.replicate 4 RelSem.CerbSt.uninitB)).allocations.get?
        σ.layout_state.nextAllocId
      = some t2allocErrS := by
    rw [Kit.writeBytesTo_allocations]
    exact Kit.tm_get?_insert_eq _ _ _
  have hstore := Kit.mem_store_block
    (loc := CerbLocation.other "errno init") (ty := signed_int)
    (allocId := σ.layout_state.nextAllocId) (addr := t2errAddr)
    (alloc := t2allocErrS)
    (mem := CerbMem.writeBytesTo
      ({ σ.layout_state with
          nextAllocId := σ.layout_state.nextAllocId + 1,
          lastAddress := t2errAddr,
          allocations := σ.layout_state.allocations.insert
            σ.layout_state.nextAllocId t2allocErrS })
      t2errAddr (List.replicate 4 RelSem.CerbSt.uninitB))
    (mv := CerbMem.integerValueMval (Signed Int_)
      (CerbMem.integerIval 0))
    rfl hget1 rfl rfl rfl
    (by rw [Kit.writeBytesTo_funptrmap])
  rw [show t2errPtr = (.PV (.Prov_some σ.layout_state.nextAllocId)
      (.PVconcrete none t2errAddr) : CerbMem.PointerValue)
    from by rw [h0]; rfl]
  exact RelSem.Laws.callND_errno halloc hstore rfl

/-! ## The R10 add chain (case-select + the CHECKED ADD) -/

def zT2b (x y : Int) : generic_pexpr Unit sym :=
  Pexpr [] () (PEctor Cspecified
    [Pexpr aU () (PEcatch_exceptional_condition (Signed Int_) IOpAdd
      (Pexpr aU () (PEconv_int (Signed Int_)
        (Pexpr aU () (PEval (RelSem.P01.xObjV x)))))
      (Pexpr aU () (PEconv_int (Signed Int_)
        (Pexpr aU () (PEval (RelSem.P01.xObjV y))))))])

def t2r10Arms : List (generic_pattern sym × generic_pexpr Unit sym) :=
  [(Pattern aU (CaseCtor Ctuple
      [Pattern aU (CaseCtor Cspecified
        [Pattern aU (CaseBase ((some t2symA532), BTy_object OTy_integer))]),
       Pattern aU (CaseCtor Cspecified
        [Pattern aU (CaseBase ((some t2symA533), BTy_object OTy_integer))])]),
    Pexpr aU () (PEctor Cspecified
      [Pexpr aU () (PEcatch_exceptional_condition (Signed Int_) IOpAdd
        (Pexpr aU () (PEconv_int (Signed Int_)
          (Pexpr aU () (PEsym t2symA532))))
        (Pexpr aU () (PEconv_int (Signed Int_)
          (Pexpr aU () (PEsym t2symA533)))))])),
   (Pattern aU (CaseBase (none,
      BTy_tuple [BTy_loaded OTy_integer, BTy_loaded OTy_integer])),
    Pexpr aU () (PEundef L0 UB036_exceptional_condition))]

def t2r10redex : generic_pexpr Unit sym :=
  Pexpr aU () (PEcase
    (Pexpr aU () (PEctor Ctuple
      [Pexpr aU () (PEsym t2symA530),
       Pexpr aU () (PEsym t2symA531)]))
    t2r10Arms)

/-- The conv_int-of-value step (in-range: identity). -/
theorem sT2conv (v : Int) (h1 : -2147483648 ≤ v)
    (h2 : v ≤ 2147483647)
    (env : List (Fmap sym value)) (memo : Option CerbMem.MemState) :
    step_eval_pexpr_lemFuel 999998 t2File.tagDefs 2
      CerbLocation.Loc.unknown
      (some (CerbLocation.other "RelSem.callND"))
      (create_extern_symmap t2File) env memo t2File false
      (Pexpr aU () (PEconv_int (Signed Int_)
        (Pexpr aU () (PEval (RelSem.P01.xObjV v)))))
      = Result (Defined (Pexpr [] () (PEval (RelSem.P01.xObjV v)))) := by
  have hd1 : intLteb (-2147483648) v = true :=
    RelSem.RoundEval.intLteb_true h1
  have hd2 : intLteb v 2147483647 = true :=
    RelSem.RoundEval.intLteb_true h2
  have harm : (if (intLteb (-2147483648) v && intLteb v 2147483647)
      = true then CerbMem.integerIval v
      else mk_wrapI (Signed Int_) (CerbMem.integerIval v))
      = (.IV .Prov_none v : CerbMem.IntegerValue) := by
    rw [hd1, hd2]; simp; rfl
  conv => rhs; rw [show (RelSem.P01.xObjV v)
    = Vobject (OVinteger (.IV .Prov_none v)) from rfl, ← harm]
  rfl

/-- The CHECKED-ADD step: both convs discharge from the operand
    ranges, the catch from the sum range. -/
theorem sT2catch (x y : Int)
    (hx1 : -2147483648 ≤ x) (hx2 : x ≤ 2147483647)
    (hy1 : -2147483648 ≤ y) (hy2 : y ≤ 2147483647)
    (hs1 : -2147483648 ≤ x + y) (hs2 : x + y ≤ 2147483647)
    (env : List (Fmap sym value)) (memo : Option CerbMem.MemState) :
    step_eval_pexpr t2File.tagDefs 0 CerbLocation.Loc.unknown
      (some (CerbLocation.other "RelSem.callND"))
      (create_extern_symmap t2File) env memo t2File false (zT2b x y)
      = Result (Defined (Pexpr [] () (PEval (loadedV (x + y))))) := by
  have hd1 : intLteb (-2147483648) (x + y) = true :=
    RelSem.RoundEval.intLteb_true hs1
  have hd2 : intLteb (x + y) 2147483647 = true :=
    RelSem.RoundEval.intLteb_true hs2
  show exception_undef_fmap (Pexpr [] ()) _ = _
  change exception_undef_bind _ _ = _
  refine (eubind_defined
    (z := (PEval (loadedV (x + y)) : generic_pexpr_ Unit sym))
    ?hctor).trans rfl
  case hctor =>
    change exception_undef_bind _ _ = _
    refine (eubind_defined
      (z := [(Pexpr [] () (PEval (Vobject (OVinteger
        (.IV .Prov_none (x + y))))) : generic_pexpr Unit sym)])
      ?hMap).trans ?_
    case hMap =>
      apply eumapM_one ?hCatch
      case hCatch =>
        change exception_undef_bind _ _ = _
        refine (eubind_defined
          (z := (PEval (Vobject (OVinteger
            (.IV .Prov_none (x + y)))) : generic_pexpr_ Unit sym))
          ?hin).trans rfl
        case hin =>
          change exception_undef_bind _ _ = _
          refine (eubind_defined
            (sT2conv x hx1 hx2 env memo)).trans ?_
          change exception_undef_bind _ _ = _
          refine (eubind_defined
            (sT2conv y hy1 hy2 env memo)).trans ?_
          have harm : (if (intLteb (-2147483648) (x + y)
                && intLteb (x + y) 2147483647) = true
              then some (CerbMem.opIval IntAdd
                (.IV .Prov_none x) (.IV .Prov_none y))
              else none)
              = some (.IV .Prov_none (x + y)
                : CerbMem.IntegerValue) := by
            rw [hd1, hd2]; simp; rfl
          conv => rhs; rw [show (Result (Defined (PEval (Vobject
            (OVinteger (.IV .Prov_none (x + y)))))) : exceptM
              (t0 (generic_pexpr_ Unit sym)) core_run_cause)
            = (match some (.IV .Prov_none (x + y)
                : CerbMem.IntegerValue) with
               | some ival => exception_undef_return
                   (PEval (Vobject (OVinteger ival)))
               | none => except_return (undef CerbLocation.Loc.unknown
                   [UB036_exceptional_condition])) from rfl, ← harm]
          rfl
    rfl


/-! ## Bind patterns + env-write spellings + the conv chain -/

def t2patA535 : generic_pattern sym :=
  Pattern aU (CaseBase ((some t2symA535), BTy_object OTy_pointer))
def t2patA536 : generic_pattern sym :=
  Pattern aU (CaseBase ((some t2symA536), BTy_object OTy_pointer))
def t2patT3031 : generic_pattern sym :=
  Pattern aU (CaseCtor Ctuple
    [Pattern aU (CaseBase ((some t2symA530), BTy_loaded OTy_integer)),
     Pattern aU (CaseBase ((some t2symA531), BTy_loaded OTy_integer))])
def t2patA537 : generic_pattern sym :=
  Pattern aU (CaseBase ((some t2symA537), BTy_loaded OTy_integer))

theorem t2upd_a536 (f : Fmap sym value) :
    update_env_aux t2patA536 bPtrV f
      = @fmapAddBy sym value Lem_Map.instBEqOfMapKeyType
          (@Lem_Map.mapKeyCompare sym _) t2symA536 bPtrV f := rfl

theorem t2upd_a535 (f : Fmap sym value) :
    update_env_aux t2patA535 xPtrV f
      = @fmapAddBy sym value Lem_Map.instBEqOfMapKeyType
          (@Lem_Map.mapKeyCompare sym _) t2symA535 xPtrV f := rfl

theorem t2upd_3031 (x y : Int) (f : Fmap sym value) :
    update_env_aux t2patT3031 (Vtuple [loadedV x, loadedV y]) f
      = @fmapAddBy sym value Lem_Map.instBEqOfMapKeyType
          (@Lem_Map.mapKeyCompare sym _) t2symA530 (loadedV x)
          (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType
            (@Lem_Map.mapKeyCompare sym _) t2symA531 (loadedV y) f) := rfl

theorem t2upd_a537 (s : Int) (f : Fmap sym value) :
    update_env_aux t2patA537 (loadedV s) f
      = @fmapAddBy sym value Lem_Map.instBEqOfMapKeyType
          (@Lem_Map.mapKeyCompare sym _) t2symA537 (loadedV s) f := rfl

theorem t2upd_a538 (v : value) (f : Fmap sym value) :
    update_env_aux (mk_sym_pat t2symA538 (BTy_loaded OTy_integer)) v f
      = @fmapAddBy sym value Lem_Map.instBEqOfMapKeyType
          (@Lem_Map.mapKeyCompare sym _) t2symA538 v f := rfl

/-! ## The Erun conv chain at t2File (the p01 mirror; T1 z-terms) -/

open RelSem.T1 (z0 z1 z2 z3 xIntV)

def t2convPE (b : sym) : generic_pexpr Unit sym :=
  Pexpr aU () (PEcall (Sym RelSem.T1.convLoadedIntSym)
    [Pexpr aU () (PEval (Vctype intCty)), Pexpr aU () (PEsym b)])

theorem t2s0_eq (b : sym) (x : Int) (env : List (Fmap sym value))
    (memo : Option CerbMem.MemState)
    (hb : fmapLookupBy
      (fun (s1 s2 : sym) => ordCompare s1 s2) b
      (create_extern_symmap t2File) = none)
    (ha : lookup_env b env = some (loadedV x)) :
    step_eval_pexpr t2File.tagDefs 0 CerbLocation.Loc.unknown
      (some (CerbLocation.other "RelSem.callND"))
      (create_extern_symmap t2File) env memo t2File false
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

theorem t2s1_eq (x : Int) (env : List (Fmap sym value))
    (memo : Option CerbMem.MemState) :
    step_eval_pexpr t2File.tagDefs 0 CerbLocation.Loc.unknown
      (some (CerbLocation.other "RelSem.callND"))
      (create_extern_symmap t2File) env memo t2File false (z0 x)
      = Result (Defined (z1 x)) := rfl

theorem t2s2_eq (x : Int) (env : List (Fmap sym value))
    (memo : Option CerbMem.MemState) :
    step_eval_pexpr t2File.tagDefs 0 CerbLocation.Loc.unknown
      (some (CerbLocation.other "RelSem.callND"))
      (create_extern_symmap t2File) env memo t2File false (z1 x)
      = Result (Defined (z2 x)) := rfl

theorem t2s3_eq (x : Int) (env : List (Fmap sym value))
    (memo : Option CerbMem.MemState) :
    step_eval_pexpr t2File.tagDefs 0 CerbLocation.Loc.unknown
      (some (CerbLocation.other "RelSem.callND"))
      (create_extern_symmap t2File) env memo t2File false (z2 x)
      = Result (Defined (z3 x)) := rfl

theorem t2s4_eq (x : Int) (h1 : -2147483648 ≤ x)
    (h2 : x ≤ 2147483647)
    (env : List (Fmap sym value)) (memo : Option CerbMem.MemState) :
    step_eval_pexpr t2File.tagDefs 0 CerbLocation.Loc.unknown
      (some (CerbLocation.other "RelSem.callND"))
      (create_extern_symmap t2File) env memo t2File false (z3 x)
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
                show step_eval_pexpr_lemFuel 999997 t2File.tagDefs (0+1+1+1)
                  CerbLocation.Loc.unknown (some (CerbLocation.other "RelSem.callND"))
                  (create_extern_symmap t2File) env memo t2File false
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
                show step_eval_pexpr_lemFuel 999997 t2File.tagDefs (0+1+1+1)
                  CerbLocation.Loc.unknown (some (CerbLocation.other "RelSem.callND"))
                  (create_extern_symmap t2File) env memo t2File false
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

theorem t2conv_eval (b : sym) (x : Int) (h1 : -2147483648 ≤ x)
    (h2 : x ≤ 2147483647)
    (env : List (Fmap sym value)) (memo : Option CerbMem.MemState)
    (hb : fmapLookupBy
      (fun (s1 s2 : sym) => ordCompare s1 s2) b
      (create_extern_symmap t2File) = none)
    (ha : lookup_env b env = some (loadedV x)) :
    eval_pexpr_aux2 t2File.tagDefs CerbLocation.Loc.unknown
        (some (CerbLocation.other "RelSem.callND"))
        (create_extern_symmap t2File) env memo t2File (t2convPE b)
      = Result (Defined (Sum.inr (loadedV x))) :=
  (aux2_step 999999 _ _ _ _ _ _ _ rfl
      (by intro a xs h; cases h) (t2s0_eq b x env memo hb ha)
      (by rfl)).trans
  ((aux2_step 999998 _ _ _ _ _ _ _
      (show pull_constrained 0 (z0 x) = z0 x from rfl)
      (by intro a xs h; simp [z0] at h) (t2s1_eq x env memo)
      (by rfl)).trans
  ((aux2_step 999997 _ _ _ _ _ _ _
      (show pull_constrained 0 (z1 x) = z1 x from rfl)
      (by intro a xs h; simp [z1] at h) (t2s2_eq x env memo)
      (by rfl)).trans
  ((aux2_step 999996 _ _ _ _ _ _ _
      (show pull_constrained 0 (z2 x) = z2 x from rfl)
      (by intro a xs h; simp [z2] at h) (t2s3_eq x env memo)
      (by rfl)).trans
  (aux2_done 999995 _ _ _ _ _ _ _
      (show pull_constrained 0 (z3 x) = z3 x from rfl)
      (by intro a xs h; simp [z3] at h)
      (t2s4_eq x h1 h2 env memo) (by rfl)))))

theorem t2fullEval_conv (arena : RExpr) (b : sym) (x : Int)
    (h1 : -2147483648 ≤ x) (h2 : x ≤ 2147483647)
    (f₁ : Fmap sym value) (ls : CerbMem.MemState)
    (st : core_run_state)
    (hb : fmapLookupBy
      (fun (s1 s2 : sym) => ordCompare s1 s2) b
      (create_extern_symmap t2File) = none)
    (ha : lookup_env b [f₁] = some (loadedV x)) :
    full_eval_pexpr t2File.tagDefs (t2Th arena f₁)
        (create_extern_symmap t2File) ls t2File (t2convPE b) st
      = Result (Defined (loadedV x), st) := by
  show stExceptUndef_bind _ _ _ = _
  refine (stub_defined (z := Sum.inr (loadedV x)) (st' := st) ?_).trans ?_
  · show runEU (eval_pexpr_aux2 t2File.tagDefs
        CerbLocation.Loc.unknown
        (some (CerbLocation.other "RelSem.callND"))
        (create_extern_symmap t2File) [f₁] (some ls) t2File
        (t2convPE b)) _ = _
    rw [t2conv_eval b x h1 h2 [f₁] (some ls) hb ha]
    rfl
  · rfl

/-- R10 step 1: case-select + substitution at the read cells. -/
theorem sT2a (x y : Int) (env : List (Fmap sym value))
    (memo : Option CerbMem.MemState)
    (h530 : lookup_env t2symA530 env = some (loadedV x))
    (h531 : lookup_env t2symA531 env = some (loadedV y)) :
    step_eval_pexpr t2File.tagDefs 0 CerbLocation.Loc.unknown
      (some (CerbLocation.other "RelSem.callND"))
      (create_extern_symmap t2File) env memo t2File false
      (Pexpr [] () (PEcase
        (Pexpr [] () (PEctor Ctuple
          [Pexpr aU () (PEsym t2symA530),
           Pexpr aU () (PEsym t2symA531)]))
        t2r10Arms))
      = Result (Defined (zT2b x y)) :=
  se_case_sel
    (se_ctor_tuple
      (pes' := [Pexpr [] () (PEval (loadedV x)),
                Pexpr [] () (PEval (loadedV y))])
      (cvals := [loadedV x, loadedV y])
      (eumapM_cons (se_sym_hit (fuel := 999997) rfl h530)
        (eumapM_cons (se_sym_hit (fuel := 999997) rfl h531)
          eumapM_nil)) rfl)
    rfl

/-- The R10 whole-loop evaluation (the checked add). -/
theorem t2add_eval (x y : Int)
    (hx1 : -2147483648 ≤ x) (hx2 : x ≤ 2147483647)
    (hy1 : -2147483648 ≤ y) (hy2 : y ≤ 2147483647)
    (hs1 : -2147483648 ≤ x + y) (hs2 : x + y ≤ 2147483647)
    (env : List (Fmap sym value)) (memo : Option CerbMem.MemState)
    (h530 : lookup_env t2symA530 env = some (loadedV x))
    (h531 : lookup_env t2symA531 env = some (loadedV y)) :
    eval_pexpr_aux2 t2File.tagDefs CerbLocation.Loc.unknown
        (some (CerbLocation.other "RelSem.callND"))
        (create_extern_symmap t2File) env memo t2File t2r10redex
      = Result (Defined (Sum.inr (loadedV (x + y)))) :=
  (aux2_step 999999 _ _ _ _ _ _ _ rfl
      (by intro a xs h; cases h)
      (sT2a x y env memo h530 h531)
      (by rfl)).trans
  (aux2_done 999998 _ _ _ _ _ _ _
      (show pull_constrained 0 (zT2b x y) = zT2b x y from rfl)
      (by intro a xs h; simp [zT2b] at h)
      (sT2catch x y hx1 hx2 hy1 hy2 hs1 hs2 env memo) (by rfl))

/-! ## The rounds -/

/-- R0 (stage-0): b's cell read (the first Ewseq's pure). -/
theorem t2r0 (p : T1P)
    (hwf : EnvWfFrame p.f₁)
    (hb : envLookup (t2fam0 p) t2symB = some bPtrV) :
    app (dnmsRoundM t2File.tagDefs 0) (t2fam0 p)
      = (NDactive (Sum.inl NOWAKEUP), t2fam t2ar1 [] 1 p) := by
  refine dnmsRoundM_adv rfl ?_
  refine (advance_runstate_eval (th' := t2Th t2ar1 p.f₁)
    (rs' := (t2fam0 p).core_run_state0) ?_).trans ?_
  · show stExceptUndef_bind _ _ _ = _
    refine (stub_defined (z := Expr aU (Epure (Pexpr [] () (PEval bPtrV))))
      (st' := (t2fam0 p).core_run_state0) ?_).trans rfl
    show stExceptUndef_bind _ _ _ = _
    refine (stub_defined (z := bPtrV)
      (st' := (t2fam0 p).core_run_state0) ?_).trans rfl
    show stExceptUndef_bind _ _ _ = _
    refine (stub_defined (z := Sum.inr bPtrV)
      (st' := (t2fam0 p).core_run_state0) ?_).trans ?_
    · show runEU (eval_pexpr_aux2 t2File.tagDefs _ _
          (create_extern_symmap t2File) [p.f₁] (some p.ls) t2File
          (Pexpr aU () (PEsym t2symB))) _ = _
      rw [aux2_sym_hit (a := aU) (a' := []) (z := t2symB) (v := bPtrV)
        (env := [p.f₁]) rfl rfl
        (show lookup_env t2symB [p.f₁] = some bPtrV from hb)]
      rfl
    · rfl
  · rfl

/-- R1: the Ewseq binds a_536 := b's pointer (BIRTH). -/
theorem t2r1 (p : T1P) :
    app (dnmsRoundM t2File.tagDefs 0) (t2fam t2ar1 [] 1 p)
      = (NDactive (Sum.inl NOWAKEUP),
         t2fam t2ar2 [] 2
           { p with f₁ := update_env_aux t2patA536 bPtrV p.f₁ }) := by
  refine dnmsRoundM_adv rfl ?_
  exact (advance_tau_misc).trans rfl

/-- R2: the first Load's operands (a_536 read). -/
theorem t2r2 (p : T1P)
    (ha : envLookup (t2fam t2ar2 [] 2 p) t2symA536 = some bPtrV) :
    app (dnmsRoundM t2File.tagDefs 0) (t2fam t2ar2 [] 2 p)
      = (NDactive (Sum.inl NOWAKEUP), t2fam t2ar3 [] 3 p) := by
  refine dnmsRoundM_adv rfl ?_
  refine (advance_runstate_eval (th' := t2Th t2ar3 p.f₁)
    (rs' := (t2fam t2ar2 [] 2 p).core_run_state0) ?_).trans ?_
  · show stExceptUndef_bind _ _ _ = _
    refine (stub_defined
      (z := Action CerbLocation.Loc.unknown empty_annotation
        (Load0 (mk_value_pe (Vctype intCty)) (mk_value_pe bPtrV) NA))
      (st' := (t2fam t2ar2 [] 2 p).core_run_state0) ?_).trans rfl
    show stExceptUndef_bind _ _ _ = _
    refine (stub_defined (z := Vctype intCty)
      (st' := (t2fam t2ar2 [] 2 p).core_run_state0) ?_).trans ?_
    · rfl
    show stExceptUndef_bind _ _ _ = _
    refine (stub_defined (z := bPtrV)
      (st' := (t2fam t2ar2 [] 2 p).core_run_state0) ?_).trans rfl
    show stExceptUndef_bind _ _ _ = _
    refine (stub_defined (z := Sum.inr bPtrV)
      (st' := (t2fam t2ar2 [] 2 p).core_run_state0) ?_).trans ?_
    · show runEU (eval_pexpr_aux2 t2File.tagDefs
          CerbLocation.Loc.unknown
          (some (CerbLocation.other "RelSem.callND"))
          (create_extern_symmap t2File) [p.f₁] (some p.ls) t2File
          (Pexpr aU () (PEsym t2symA536))) _ = _
      rw [aux2_sym_hit (a := aU) (a' := []) (z := t2symA536)
        (v := bPtrV) (env := [p.f₁]) rfl rfl
        (show lookup_env t2symA536 [p.f₁] = some bPtrV from ha)]
      rfl
    · rfl
  · rfl

/-- R3: THE b LOAD. -/
theorem t2r3 (y : Int) (p : T1P)
    (hget : p.ls.allocations.get? 1 = some allocB)
    (hbytes : ∀ i : Nat, (hi : i < (xBytes y).length) →
      p.ls.bytemap.get? (bAddr + (i : Int)) = some (xBytes y)[i])
    (hlum : p.ls.lastUsedUnionMembers = [])
    (hfpm : p.ls.funptrmap = [])
    (hinv : MemInv p.ls)
    (h1 : -2147483648 ≤ y) (h2 : y ≤ 2147483647) :
    app (dnmsRoundM t2File.tagDefs 0) (t2fam t2ar3 [] 3 p)
      = (NDactive (Sum.inl NOWAKEUP),
         t2σ (t2ar4 y) p.f₁ p.tS (p.aS + 1) p.eS p.sS p.ls
           [meLoadB y] 3) := by
  refine dnmsRoundM_adv rfl ?_
  apply (app_bind_active ?hreq).trans
  case hreq =>
    refine (app_bind_active rfl).trans ?_
    rw [perform_unfold]
    refine (app_bind_active aid_draw).trans ?_
    rw [ars_load_unfold]
    refine (app_bind_active (app_liftMem_active rfl
      (loadB_eq_facts y p.ls hget hbytes hlum hfpm hinv h1 h2))).trans ?_
    refine (app_bind_active (app_liftMem_active rfl
      mem_prefix_block)).trans ?_
    exact app_nd_update _ _
  rfl

/-- R4: a's cell read. -/
theorem t2r4 (y : Int) (p : T1P)
    (ha : envLookup (t2fam (t2ar4 y) [meLoadB y] 3 p) t2symA
      = some xPtrV) :
    app (dnmsRoundM t2File.tagDefs 0)
        (t2fam (t2ar4 y) [meLoadB y] 3 p)
      = (NDactive (Sum.inl NOWAKEUP),
         t2fam (t2ar5 y) [meLoadB y] 4 p) := by
  refine dnmsRoundM_adv rfl ?_
  refine (advance_runstate_eval (th' := t2Th (t2ar5 y) p.f₁)
    (rs' := (t2fam (t2ar4 y) [meLoadB y] 3 p).core_run_state0)
    ?_).trans ?_
  · show stExceptUndef_bind _ _ _ = _
    refine (stub_defined (z := Expr aU (Epure (Pexpr [] () (PEval xPtrV))))
      (st' := (t2fam (t2ar4 y) [meLoadB y] 3 p).core_run_state0)
      ?_).trans rfl
    show stExceptUndef_bind _ _ _ = _
    refine (stub_defined (z := xPtrV)
      (st' := (t2fam (t2ar4 y) [meLoadB y] 3 p).core_run_state0)
      ?_).trans rfl
    show stExceptUndef_bind _ _ _ = _
    refine (stub_defined (z := Sum.inr xPtrV)
      (st' := (t2fam (t2ar4 y) [meLoadB y] 3 p).core_run_state0)
      ?_).trans ?_
    · show runEU (eval_pexpr_aux2 t2File.tagDefs
          CerbLocation.Loc.unknown
          (some (CerbLocation.other "RelSem.callND"))
          (create_extern_symmap t2File) [p.f₁] (some p.ls) t2File
          (Pexpr aU () (PEsym t2symA))) _ = _
      rw [aux2_sym_hit (a := aU) (a' := []) (z := t2symA) (v := xPtrV)
        (env := [p.f₁]) rfl rfl
        (show lookup_env t2symA [p.f₁] = some xPtrV from ha)]
      rfl
    · rfl
  · rfl

/-- R5: a_535 := a's pointer BORN. -/
theorem t2r5 (y : Int) (p : T1P) :
    app (dnmsRoundM t2File.tagDefs 0)
        (t2fam (t2ar5 y) [meLoadB y] 4 p)
      = (NDactive (Sum.inl NOWAKEUP),
         t2fam (t2ar6 y) [meLoadB y] 5
           { p with f₁ := update_env_aux t2patA535 xPtrV p.f₁ }) := by
  refine dnmsRoundM_adv rfl ?_
  exact (advance_tau_misc).trans rfl

/-- R6: the second Load's operands (a_535 read). -/
theorem t2r6 (y : Int) (p : T1P)
    (ha : envLookup (t2fam (t2ar6 y) [meLoadB y] 5 p) t2symA535
      = some xPtrV) :
    app (dnmsRoundM t2File.tagDefs 0)
        (t2fam (t2ar6 y) [meLoadB y] 5 p)
      = (NDactive (Sum.inl NOWAKEUP),
         t2fam (t2ar7 y) [meLoadB y] 6 p) := by
  refine dnmsRoundM_adv rfl ?_
  refine (advance_runstate_eval (th' := t2Th (t2ar7 y) p.f₁)
    (rs' := (t2fam (t2ar6 y) [meLoadB y] 5 p).core_run_state0)
    ?_).trans ?_
  · show stExceptUndef_bind _ _ _ = _
    refine (stub_defined
      (z := Action CerbLocation.Loc.unknown empty_annotation
        (Load0 (mk_value_pe (Vctype intCty)) (mk_value_pe xPtrV) NA))
      (st' := (t2fam (t2ar6 y) [meLoadB y] 5 p).core_run_state0)
      ?_).trans rfl
    show stExceptUndef_bind _ _ _ = _
    refine (stub_defined (z := Vctype intCty)
      (st' := (t2fam (t2ar6 y) [meLoadB y] 5 p).core_run_state0)
      ?_).trans ?_
    · rfl
    show stExceptUndef_bind _ _ _ = _
    refine (stub_defined (z := xPtrV)
      (st' := (t2fam (t2ar6 y) [meLoadB y] 5 p).core_run_state0)
      ?_).trans rfl
    show stExceptUndef_bind _ _ _ = _
    refine (stub_defined (z := Sum.inr xPtrV)
      (st' := (t2fam (t2ar6 y) [meLoadB y] 5 p).core_run_state0)
      ?_).trans ?_
    · show runEU (eval_pexpr_aux2 t2File.tagDefs
          CerbLocation.Loc.unknown
          (some (CerbLocation.other "RelSem.callND"))
          (create_extern_symmap t2File) [p.f₁] (some p.ls) t2File
          (Pexpr aU () (PEsym t2symA535))) _ = _
      rw [aux2_sym_hit (a := aU) (a' := []) (z := t2symA535)
        (v := xPtrV) (env := [p.f₁]) rfl rfl
        (show lookup_env t2symA535 [p.f₁] = some xPtrV from ha)]
      rfl
    · rfl
  · rfl

/-- R7: THE a LOAD (second aid drawn; the trace grows). -/
theorem t2r7 (x y : Int) (p : T1P)
    (hget : p.ls.allocations.get? 0 = some allocX)
    (hbytes : ∀ i : Nat, (hi : i < (xBytes x).length) →
      p.ls.bytemap.get? (xAddr + (i : Int)) = some (xBytes x)[i])
    (hlum : p.ls.lastUsedUnionMembers = [])
    (hfpm : p.ls.funptrmap = [])
    (hinv : MemInv p.ls)
    (h1 : -2147483648 ≤ x) (h2 : x ≤ 2147483647) :
    app (dnmsRoundM t2File.tagDefs 0)
        (t2fam (t2ar7 y) [meLoadB y] 6 p)
      = (NDactive (Sum.inl NOWAKEUP),
         t2σ (t2ar8 x y) p.f₁ p.tS (p.aS + 1) p.eS p.sS p.ls
           [meLoad x, meLoadB y] 6) := by
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

/-- R8: the Eunseq packs the pair (tau). -/
theorem t2r8 (x y : Int) (p : T1P) :
    app (dnmsRoundM t2File.tagDefs 0)
        (t2fam (t2ar8 x y) [meLoad x, meLoadB y] 6 p)
      = (NDactive (Sum.inl NOWAKEUP),
         t2fam (t2ar9 x y) [meLoad x, meLoadB y] 7 p) := by
  refine dnmsRoundM_adv rfl ?_
  exact (advance_tau_misc).trans rfl

/-- R9: (a_530, a_531) BORN (the tuple bind). -/
theorem t2r9 (x y : Int) (p : T1P) :
    app (dnmsRoundM t2File.tagDefs 0)
        (t2fam (t2ar9 x y) [meLoad x, meLoadB y] 7 p)
      = (NDactive (Sum.inl NOWAKEUP),
         t2fam t2ar10 [meLoad x, meLoadB y] 8
           { p with f₁ := update_env_aux t2patT3031 (Vtuple [loadedV x, loadedV y]) p.f₁ }) := by
  refine dnmsRoundM_adv rfl ?_
  exact (advance_tau_misc).trans rfl

/-- R10: THE CHECKED ADD (reads a_530/a_531; the sum lands). -/
theorem t2r10 (x y : Int)
    (hx1 : -2147483648 ≤ x) (hx2 : x ≤ 2147483647)
    (hy1 : -2147483648 ≤ y) (hy2 : y ≤ 2147483647)
    (hs1 : -2147483648 ≤ x + y) (hs2 : x + y ≤ 2147483647)
    (p : T1P)
    (h530 : envLookup (t2fam t2ar10 [meLoad x, meLoadB y] 8 p)
      t2symA530 = some (loadedV x))
    (h531 : envLookup (t2fam t2ar10 [meLoad x, meLoadB y] 8 p)
      t2symA531 = some (loadedV y)) :
    app (dnmsRoundM t2File.tagDefs 0)
        (t2fam t2ar10 [meLoad x, meLoadB y] 8 p)
      = (NDactive (Sum.inl NOWAKEUP),
         t2fam (t2ar11 (x + y)) [meLoad x, meLoadB y] 9 p) := by
  refine dnmsRoundM_adv rfl ?_
  refine (advance_runstate_eval
    (th' := t2Th (t2ar11 (x + y)) p.f₁)
    (rs' := (t2fam t2ar10 [meLoad x, meLoadB y] 8
      p).core_run_state0) ?_).trans ?_
  · show stExceptUndef_bind _ _ _ = _
    refine (stub_defined
      (z := Expr aU (Epure (Pexpr [] () (PEval (loadedV (x + y))))))
      (st' := (t2fam t2ar10 [meLoad x, meLoadB y] 8
        p).core_run_state0) ?_).trans rfl
    show stExceptUndef_bind _ _ _ = _
    refine (stub_defined (z := loadedV (x + y))
      (st' := (t2fam t2ar10 [meLoad x, meLoadB y] 8
        p).core_run_state0) ?_).trans rfl
    show stExceptUndef_bind _ _ _ = _
    refine (stub_defined (z := Sum.inr (loadedV (x + y)))
      (st' := (t2fam t2ar10 [meLoad x, meLoadB y] 8
        p).core_run_state0) ?_).trans ?_
    · show runEU (eval_pexpr_aux2 t2File.tagDefs
          CerbLocation.Loc.unknown
          (some (CerbLocation.other "RelSem.callND"))
          (create_extern_symmap t2File) [p.f₁] (some p.ls) t2File
          t2r10redex) _ = _
      rw [t2add_eval x y hx1 hx2 hy1 hy2 hs1 hs2 [p.f₁] (some p.ls)
        (show lookup_env t2symA530 [p.f₁] = some (loadedV x) from h530)
        (show lookup_env t2symA531 [p.f₁] = some (loadedV y) from h531)]
      rfl
    · rfl
  · rfl

/-- R11: the Ebound/Eannot wrapper strips (tau). -/
theorem t2r11 (s : Int) (p : T1P) {tr : List trace_event} :
    app (dnmsRoundM t2File.tagDefs 0) (t2fam (t2ar11 s) tr 9 p)
      = (NDactive (Sum.inl NOWAKEUP), t2fam (t2ar12 s) tr 10 p) := by
  refine dnmsRoundM_adv rfl ?_
  exact (advance_tau_misc).trans rfl

/-- R12: a_537 := the sum BORN. -/
theorem t2r12 (s : Int) (p : T1P) {tr : List trace_event} :
    app (dnmsRoundM t2File.tagDefs 0) (t2fam (t2ar12 s) tr 10 p)
      = (NDactive (Sum.inl NOWAKEUP),
         t2fam t2ar13 tr 11
           { p with f₁ := update_env_aux t2patA537 (loadedV s) p.f₁ }) := by
  refine dnmsRoundM_adv rfl ?_
  exact (advance_tau_misc).trans rfl

/-- R13: the ret jump — the conv chain at a_537, a_538 BORN. -/
theorem t2r13 (s : Int) (h1 : -2147483648 ≤ s) (h2 : s ≤ 2147483647)
    (p : T1P) {tr : List trace_event}
    (ha : envLookup (t2fam t2ar13 tr 11 p) t2symA537
      = some (loadedV s)) :
    app (dnmsRoundM t2File.tagDefs 0) (t2fam t2ar13 tr 11 p)
      = (NDactive (Sum.inl NOWAKEUP),
         t2fam t2ar14 tr 12
           { p with f₁ :=
               (update_env_aux
                 (mk_sym_pat t2symA538 (BTy_loaded OTy_integer))
                 (loadedV s) p.f₁) }) := by
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
          apply (stub_defined (t2fullEval_conv t2ar13 t2symA537 s
            h1 h2 p.f₁ p.ls _ rfl
            (show lookup_env t2symA537 [p.f₁] = some (loadedV s)
              from ha))).trans
          rfl
        rfl
      rfl
  rfl

/-- R14: a_538 evaluates (the sum reaches the arena). -/
theorem t2r14 (s : Int) (p : T1P) {tr : List trace_event}
    (ha : envLookup (t2fam t2ar14 tr 12 p) t2symA538
      = some (loadedV s)) :
    app (dnmsRoundM t2File.tagDefs 0) (t2fam t2ar14 tr 12 p)
      = (NDactive (Sum.inl NOWAKEUP),
         t2fam (t2arDone s) tr 13 p) := by
  refine dnmsRoundM_adv rfl ?_
  refine (advance_runstate_eval (th' := t2Th (t2arDone s) p.f₁)
    (rs' := (t2fam t2ar14 tr 12 p).core_run_state0) ?_).trans ?_
  · show stExceptUndef_bind _ _ _ = _
    refine (stub_defined
      (z := Expr aU (Epure (Pexpr [] () (PEval (loadedV s)))))
      (st' := (t2fam t2ar14 tr 12 p).core_run_state0) ?_).trans rfl
    show stExceptUndef_bind _ _ _ = _
    refine (stub_defined (z := loadedV s)
      (st' := (t2fam t2ar14 tr 12 p).core_run_state0) ?_).trans rfl
    show stExceptUndef_bind _ _ _ = _
    refine (stub_defined (z := Sum.inr (loadedV s))
      (st' := (t2fam t2ar14 tr 12 p).core_run_state0) ?_).trans ?_
    · show runEU (eval_pexpr_aux2 t2File.tagDefs
          CerbLocation.Loc.unknown
          (some (CerbLocation.other "RelSem.callND"))
          (create_extern_symmap t2File) [p.f₁] (some p.ls) t2File
          (Pexpr aU () (PEsym t2symA538))) _ = _
      rw [aux2_sym_hit (a := aU) (a' := []) (z := t2symA538)
        (v := loadedV s) (env := [p.f₁]) rfl rfl
        (show lookup_env t2symA538 [p.f₁] = some (loadedV s) from ha)]
      rfl
    · rfl
  · rfl

/-- R-terminal: the done offer at the sum. -/
theorem t2r15 (s : Int) (p : T1P) {tr : List trace_event} :
    app (dnmsRoundM t2File.tagDefs 0) (t2fam (t2arDone s) tr 13 p)
      = (NDactive (Sum.inr [Step_done2 (loadedV s)]),
         t2fam (t2arDone s) tr 13 p) := by
  refine (dnmsRoundM_inr rfl).trans ?_
  rfl

/-! ## Instance-generic double-birth legs (the SETUP binds two cells
    at the harness's insert spelling) -/

section GenericDoubleBirth

open RelSem.T1 (birth_new' birth_pres' birth_rev' birth_wfp')

variable {inst : BEq sym} {pcmp : sym → sym → LemOrdering}
variable {b₁ b₂ : sym} {v₁ v₂ : value} {f : Fmap sym value}

theorem dbl_new₁' (hpc : lemCmpToOrd pcmp = RelSem.Kit.symCmpO)
    (hwf : EnvWfFrame f) :
    lookup_env b₁ [@fmapAddBy sym value inst pcmp b₁ v₁
      (@fmapAddBy sym value inst pcmp b₂ v₂ f)] = some v₁ :=
  birth_new' hpc (birth_wfp' hpc hwf)

theorem dbl_new₂' (hpc : lemCmpToOrd pcmp = RelSem.Kit.symCmpO)
    (hwf : EnvWfFrame f)
    (hn₁ : ∀ z : sym, RelSem.Kit.symCmpO b₁ z = .eq →
      lookup_env z [f] = none)
    (hnum_ne : symNum b₁ ≠ symNum b₂) :
    lookup_env b₂ [@fmapAddBy sym value inst pcmp b₁ v₁
      (@fmapAddBy sym value inst pcmp b₂ v₂ f)] = some v₂ := by
  refine birth_pres' hpc (birth_wfp' hpc hwf) ?_ b₂ v₂
    (birth_new' hpc hwf)
  intro z hz
  cases hlk : lookup_env z [@fmapAddBy sym value inst pcmp b₂ v₂ f]
    with
  | none => rfl
  | some vz =>
    exfalso
    rcases birth_rev' hpc hwf z vz hlk with ⟨v₀, hv₀⟩ | hnum
    · rw [hn₁ z hz] at hv₀; cases hv₀
    · obtain ⟨d1, n1, s1⟩ := b₁
      obtain ⟨d2, n2, s2⟩ := b₂
      obtain ⟨dz, nz, sz⟩ := z
      obtain ⟨-, hn⟩ := (RelSem.Kit.symCmpO_eq_iff d1 dz n1 nz
        s1 sz).1 hz
      simp [symNum] at hnum hnum_ne
      omega

theorem dbl_rev' (hpc : lemCmpToOrd pcmp = RelSem.Kit.symCmpO)
    (hwf : EnvWfFrame f) :
    ∀ z v', lookup_env z [@fmapAddBy sym value inst pcmp b₁ v₁
        (@fmapAddBy sym value inst pcmp b₂ v₂ f)] = some v' →
      (∃ v₀, lookup_env z [f] = some v₀) ∨ symNum z = symNum b₁ ∨
        symNum z = symNum b₂ := by
  intro z v' hz
  rcases birth_rev' hpc (birth_wfp' hpc hwf) z v' hz
    with ⟨v₀, hv₀⟩ | hnum
  · rcases birth_rev' hpc hwf z v₀ hv₀ with ⟨v₁', hv₁⟩ | hnum2
    · exact Or.inl ⟨v₁', hv₁⟩
    · exact Or.inr (Or.inr hnum2)
  · exact Or.inr (Or.inl hnum)

theorem dbl_wfp' (hpc : lemCmpToOrd pcmp = RelSem.Kit.symCmpO)
    (hwf : EnvWfFrame f) :
    EnvWfFrame (@fmapAddBy sym value inst pcmp b₁ v₁
      (@fmapAddBy sym value inst pcmp b₂ v₂ f)) :=
  birth_wfp' hpc (birth_wfp' hpc hwf)

end GenericDoubleBirth
