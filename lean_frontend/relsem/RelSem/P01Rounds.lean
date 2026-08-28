/-
  RelSem.P01Rounds — V2 (2026-08-28): THE P01 (clamp0) ROUND ENGINE.
  Ground truth: the V2Probe Lean-source printer transcripts at
  x = -3 / x = 7 (two-point diff; x-dependent positions abstracted,
  the branch parameters c/vb per side). 26 rounds on the x<0 path,
  30 on the else path; rounds 0-9 shared; the compare materializes
  at round 10; the Eif picks the arm at round 20; the else path
  RELOADS x (its second load round). Families/idioms mirror
  RelSem/T1Rounds.lean (T1P reused; the memory ladder mr0-mr2,
  xAddr/errAddr, byte roundtrip are the T1 objects — the caller
  protocol is identical).

  House rules: no sorry, no axioms. Under the in-build audit.
-/

import RelSem.T1Rounds
import RelSem.CorpusFiles

set_option autoImplicit false
set_option maxHeartbeats 2000000

namespace RelSem.P01

open RelSem RelSem.Cerb RelSem.Kit RelSem.CerbSt RelSem.Corpus
open Lem_Basic_classes (ordCompare)
open RelSem.T1 (T1P RExpr aU intCty xAddr errAddr xPtr errPtr xPtrV loadedV
  xBytes mkByte roundtrip_arith allocX allocXS allocErr allocErrS
  zeroByte zeroBytes mr0 mr1 mr2 symX
  memValueToBytes_int memValueFromValue_int symCmpO_refl
  mapKeyCompare_is_symCmpO birth_new birth_pres birth_rev birth_wfp)

abbrev L0 : CerbLocation.Loc := CerbLocation.Loc.unknown

/-! ## Program symbols (name-hash interned; from the parsed decl) -/

def symA526 : sym := Symbol "" 13429216386455784360 (SD_Id "a_526")
def symA527 : sym := Symbol "" 4139409277016632516 (SD_Id "a_527")
def symA528 : sym := Symbol "" 8935235297226827052 (SD_Id "a_528")
def symA529 : sym := Symbol "" 1680278659536745755 (SD_Id "a_529")
def symA530 : sym := Symbol "" 4915778119994869450 (SD_Id "a_530")
def symA531 : sym := Symbol "" 17653705816563834534 (SD_Id "a_531")
def symA532 : sym := Symbol "" 1342427191597093029 (SD_Id "a_532")
def symA534 : sym := Symbol "" 5254944664791163557 (SD_Id "a_534")
def symA535 : sym := Symbol "" 15754218577363027919 (SD_Id "a_535")
def symA536 : sym := Symbol "" 6464411467923874555 (SD_Id "a_536")
def symA537 : sym := Symbol "" 6477419756603697776 (SD_Id "a_537")
def symA538 : sym := Symbol "" 18319030617476695216 (SD_Id "a_538")
def symA540 : sym := Symbol "" 229457971439601039 (SD_Id "a_540")
def symA541 : sym := Symbol "" 17100379974685333628 (SD_Id "a_541")
def symA542 : sym := Symbol "" 16217071427669230452 (SD_Id "a_542")
def symA543 : sym := Symbol "" 14641249357205542421 (SD_Id "a_543")
def symConvInt : sym := Symbol "" 15837442492999787586 (SD_Id "conv_int")
def symConvLoadedInt : sym :=
  Symbol "" 7499171796590179012 (SD_Id "conv_loaded_int")
def symRet525 : sym := Symbol "" 8255284729932948114 (SD_Id "ret_525")

/-! ## Arena terms (transcribed; shared blocks factored) -/

-- shared body blocks (factored; innermost first)
def p01SaveBlk : RExpr :=
  (Expr aU (Esave (symRet525, (BTy_loaded OTy_integer)) [(symA543, (((BTy_loaded OTy_integer), none), (Pexpr aU () (PEundef L0 UB088_reached_end_of_function))))] (Expr aU (Epure (Pexpr aU () (PEsym symA543))))))

def p01ArmT : RExpr :=
  (Expr aU (Esseq (Pattern aU (CaseBase ((some symA540), (BTy_loaded OTy_integer)))) (Expr aU (Ebound (Expr aU (Epure (Pexpr aU () (PEctor Cspecified [(Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (0))))))])))))) (Expr aU (Erun empty_annotation symRet525 [(Pexpr aU () (PEcall (Sym symConvLoadedInt) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym symA540))]))]))))

def p01ArmF : RExpr :=
  (Expr aU (Epure (Pexpr aU () (PEval Vunit))))

def p01IfBlk : RExpr :=
  (Expr aU (Eif (Pexpr aU () (PEsym symA526)) p01ArmT p01ArmF))

def p01Rest : RExpr :=
  (Expr aU (Esseq (Pattern aU (CaseBase ((some symA526), BTy_boolean))) (Expr aU (Ecase (Pexpr aU () (PEsym symA527)) [((Pattern aU (CaseCtor Cspecified [(Pattern aU (CaseBase ((some symA528), (BTy_object OTy_integer))))])), (Expr aU (Epure (Pexpr aU () (PEif (Pexpr aU () (PEnot (Pexpr aU () (PEop OpEq (Pexpr aU () (PEsym symA528)) (Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (1)))))))))) (Pexpr aU () (PEval Vtrue)) (Pexpr aU () (PEval Vfalse))))))), ((Pattern aU (CaseCtor Cunspecified [(Pattern aU (CaseBase (none, BTy_ctype)))])), (Expr aU (End [(Expr aU (Epure (Pexpr aU () (PEval Vtrue)))), (Expr aU (Epure (Pexpr aU () (PEval Vfalse))))])))])) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) p01IfBlk (Expr aU (Esseq (Pattern aU (CaseBase ((some symA542), (BTy_loaded OTy_integer)))) (Expr aU (Ebound (Expr aU (Ewseq (Pattern aU (CaseBase ((some symA541), (BTy_object OTy_pointer)))) (Expr aU (Epure (Pexpr aU () (PEsym symX)))) (Expr aU (Eaction (Paction Pos (Action L0 empty_annotation (Load0 (Pexpr aU () (PEval (Vctype intCty))) (Pexpr aU () (PEsym symA541)) NA))))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Erun empty_annotation symRet525 [(Pexpr aU () (PEcall (Sym symConvLoadedInt) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym symA542))]))])) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) p01ArmF p01SaveBlk))))))))))

def p01ar0 : RExpr :=
  (Expr aU (Esseq (Pattern aU (CaseBase ((some symA527), (BTy_loaded OTy_integer)))) (Expr aU (Ebound (Expr aU (Ewseq (Pattern aU (CaseCtor Ctuple [(Pattern aU (CaseBase ((some symA529), (BTy_loaded OTy_integer)))), (Pattern aU (CaseBase ((some symA530), (BTy_loaded OTy_integer))))])) (Expr aU (Eunseq [(Expr aU (Ewseq (Pattern aU (CaseCtor Ctuple [(Pattern aU (CaseBase ((some symA535), (BTy_loaded OTy_integer)))), (Pattern aU (CaseBase ((some symA536), (BTy_loaded OTy_integer))))])) (Expr aU (Eunseq [(Expr aU (Ewseq (Pattern aU (CaseBase ((some symA534), (BTy_object OTy_pointer)))) (Expr aU (Epure (Pexpr aU () (PEsym symX)))) (Expr aU (Eaction (Paction Pos (Action L0 empty_annotation (Load0 (Pexpr aU () (PEval (Vctype intCty))) (Pexpr aU () (PEsym symA534)) NA))))))), (Expr aU (Epure (Pexpr aU () (PEctor Cspecified [(Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (0))))))]))))])) (Expr aU (Ecase (Pexpr aU () (PEctor Ctuple [(Pexpr aU () (PEsym symA535)), (Pexpr aU () (PEsym symA536))])) [((Pattern aU (CaseCtor Ctuple [(Pattern aU (CaseCtor Cspecified [(Pattern aU (CaseBase ((some symA537), (BTy_object OTy_integer))))])), (Pattern aU (CaseCtor Cspecified [(Pattern aU (CaseBase ((some symA538), (BTy_object OTy_integer))))]))])), (Expr aU (Epure (Pexpr aU () (PEif (Pexpr aU () (PEop OpLt (Pexpr aU () (PEcall (Sym symConvInt) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym symA537))])) (Pexpr aU () (PEcall (Sym symConvInt) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym symA538))])))) (Pexpr aU () (PEctor Cspecified [(Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (1))))))])) (Pexpr aU () (PEctor Cspecified [(Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (0))))))]))))))), ((Pattern aU (CaseBase (none, (BTy_tuple [(BTy_loaded OTy_integer), (BTy_loaded OTy_integer)])))), (Expr aU (Epure (Pexpr aU () (PEctor Cunspecified [(Pexpr aU () (PEval (Vctype intCty)))])))))])))), (Expr aU (Epure (Pexpr aU () (PEctor Cspecified [(Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (0))))))]))))])) (Expr aU (Epure (Pexpr aU () (PEcase (Pexpr aU () (PEctor Ctuple [(Pexpr aU () (PEsym symA529)), (Pexpr aU () (PEsym symA530))])) [((Pattern aU (CaseCtor Ctuple [(Pattern aU (CaseCtor Cspecified [(Pattern aU (CaseBase ((some symA531), (BTy_object OTy_integer))))])), (Pattern aU (CaseCtor Cspecified [(Pattern aU (CaseBase ((some symA532), (BTy_object OTy_integer))))]))])), (Pexpr aU () (PEif (Pexpr aU () (PEop OpEq (Pexpr aU () (PEcall (Sym symConvInt) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym symA531))])) (Pexpr aU () (PEcall (Sym symConvInt) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym symA532))])))) (Pexpr aU () (PEctor Cspecified [(Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (1))))))])) (Pexpr aU () (PEctor Cspecified [(Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (0))))))]))))), ((Pattern aU (CaseBase (none, (BTy_tuple [(BTy_loaded OTy_integer), (BTy_loaded OTy_integer)])))), (Pexpr aU () (PEctor Cunspecified [(Pexpr aU () (PEval (Vctype intCty)))])))])))))))) p01Rest))

def p01ar1 : RExpr :=
  (Expr aU (Esseq (Pattern aU (CaseBase ((some symA527), (BTy_loaded OTy_integer)))) (Expr aU (Ebound (Expr aU (Ewseq (Pattern aU (CaseCtor Ctuple [(Pattern aU (CaseBase ((some symA529), (BTy_loaded OTy_integer)))), (Pattern aU (CaseBase ((some symA530), (BTy_loaded OTy_integer))))])) (Expr aU (Eunseq [(Expr aU (Ewseq (Pattern aU (CaseCtor Ctuple [(Pattern aU (CaseBase ((some symA535), (BTy_loaded OTy_integer)))), (Pattern aU (CaseBase ((some symA536), (BTy_loaded OTy_integer))))])) (Expr aU (Eunseq [(Expr aU (Ewseq (Pattern aU (CaseBase ((some symA534), (BTy_object OTy_pointer)))) (Expr aU (Epure (Pexpr aU () (PEsym symX)))) (Expr aU (Eaction (Paction Pos (Action L0 empty_annotation (Load0 (Pexpr aU () (PEval (Vctype intCty))) (Pexpr aU () (PEsym symA534)) NA))))))), (Expr aU (Epure (Pexpr aU () (PEctor Cspecified [(Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (0))))))]))))])) (Expr aU (Ecase (Pexpr aU () (PEctor Ctuple [(Pexpr aU () (PEsym symA535)), (Pexpr aU () (PEsym symA536))])) [((Pattern aU (CaseCtor Ctuple [(Pattern aU (CaseCtor Cspecified [(Pattern aU (CaseBase ((some symA537), (BTy_object OTy_integer))))])), (Pattern aU (CaseCtor Cspecified [(Pattern aU (CaseBase ((some symA538), (BTy_object OTy_integer))))]))])), (Expr aU (Epure (Pexpr aU () (PEif (Pexpr aU () (PEop OpLt (Pexpr aU () (PEcall (Sym symConvInt) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym symA537))])) (Pexpr aU () (PEcall (Sym symConvInt) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym symA538))])))) (Pexpr aU () (PEctor Cspecified [(Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (1))))))])) (Pexpr aU () (PEctor Cspecified [(Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (0))))))]))))))), ((Pattern aU (CaseBase (none, (BTy_tuple [(BTy_loaded OTy_integer), (BTy_loaded OTy_integer)])))), (Expr aU (Epure (Pexpr aU () (PEctor Cunspecified [(Pexpr aU () (PEval (Vctype intCty)))])))))])))), (Expr aU (Epure (Pexpr [] () (PEval (loadedV 0)))))])) (Expr aU (Epure (Pexpr aU () (PEcase (Pexpr aU () (PEctor Ctuple [(Pexpr aU () (PEsym symA529)), (Pexpr aU () (PEsym symA530))])) [((Pattern aU (CaseCtor Ctuple [(Pattern aU (CaseCtor Cspecified [(Pattern aU (CaseBase ((some symA531), (BTy_object OTy_integer))))])), (Pattern aU (CaseCtor Cspecified [(Pattern aU (CaseBase ((some symA532), (BTy_object OTy_integer))))]))])), (Pexpr aU () (PEif (Pexpr aU () (PEop OpEq (Pexpr aU () (PEcall (Sym symConvInt) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym symA531))])) (Pexpr aU () (PEcall (Sym symConvInt) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym symA532))])))) (Pexpr aU () (PEctor Cspecified [(Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (1))))))])) (Pexpr aU () (PEctor Cspecified [(Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (0))))))]))))), ((Pattern aU (CaseBase (none, (BTy_tuple [(BTy_loaded OTy_integer), (BTy_loaded OTy_integer)])))), (Pexpr aU () (PEctor Cunspecified [(Pexpr aU () (PEval (Vctype intCty)))])))])))))))) p01Rest))

def p01ar2 : RExpr :=
  (Expr aU (Esseq (Pattern aU (CaseBase ((some symA527), (BTy_loaded OTy_integer)))) (Expr aU (Ebound (Expr aU (Ewseq (Pattern aU (CaseCtor Ctuple [(Pattern aU (CaseBase ((some symA529), (BTy_loaded OTy_integer)))), (Pattern aU (CaseBase ((some symA530), (BTy_loaded OTy_integer))))])) (Expr aU (Eunseq [(Expr aU (Ewseq (Pattern aU (CaseCtor Ctuple [(Pattern aU (CaseBase ((some symA535), (BTy_loaded OTy_integer)))), (Pattern aU (CaseBase ((some symA536), (BTy_loaded OTy_integer))))])) (Expr aU (Eunseq [(Expr aU (Ewseq (Pattern aU (CaseBase ((some symA534), (BTy_object OTy_pointer)))) (Expr aU (Epure (Pexpr aU () (PEsym symX)))) (Expr aU (Eaction (Paction Pos (Action L0 empty_annotation (Load0 (Pexpr aU () (PEval (Vctype intCty))) (Pexpr aU () (PEsym symA534)) NA))))))), (Expr aU (Epure (Pexpr [] () (PEval (loadedV 0)))))])) (Expr aU (Ecase (Pexpr aU () (PEctor Ctuple [(Pexpr aU () (PEsym symA535)), (Pexpr aU () (PEsym symA536))])) [((Pattern aU (CaseCtor Ctuple [(Pattern aU (CaseCtor Cspecified [(Pattern aU (CaseBase ((some symA537), (BTy_object OTy_integer))))])), (Pattern aU (CaseCtor Cspecified [(Pattern aU (CaseBase ((some symA538), (BTy_object OTy_integer))))]))])), (Expr aU (Epure (Pexpr aU () (PEif (Pexpr aU () (PEop OpLt (Pexpr aU () (PEcall (Sym symConvInt) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym symA537))])) (Pexpr aU () (PEcall (Sym symConvInt) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym symA538))])))) (Pexpr aU () (PEctor Cspecified [(Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (1))))))])) (Pexpr aU () (PEctor Cspecified [(Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (0))))))]))))))), ((Pattern aU (CaseBase (none, (BTy_tuple [(BTy_loaded OTy_integer), (BTy_loaded OTy_integer)])))), (Expr aU (Epure (Pexpr aU () (PEctor Cunspecified [(Pexpr aU () (PEval (Vctype intCty)))])))))])))), (Expr aU (Epure (Pexpr [] () (PEval (loadedV 0)))))])) (Expr aU (Epure (Pexpr aU () (PEcase (Pexpr aU () (PEctor Ctuple [(Pexpr aU () (PEsym symA529)), (Pexpr aU () (PEsym symA530))])) [((Pattern aU (CaseCtor Ctuple [(Pattern aU (CaseCtor Cspecified [(Pattern aU (CaseBase ((some symA531), (BTy_object OTy_integer))))])), (Pattern aU (CaseCtor Cspecified [(Pattern aU (CaseBase ((some symA532), (BTy_object OTy_integer))))]))])), (Pexpr aU () (PEif (Pexpr aU () (PEop OpEq (Pexpr aU () (PEcall (Sym symConvInt) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym symA531))])) (Pexpr aU () (PEcall (Sym symConvInt) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym symA532))])))) (Pexpr aU () (PEctor Cspecified [(Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (1))))))])) (Pexpr aU () (PEctor Cspecified [(Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (0))))))]))))), ((Pattern aU (CaseBase (none, (BTy_tuple [(BTy_loaded OTy_integer), (BTy_loaded OTy_integer)])))), (Pexpr aU () (PEctor Cunspecified [(Pexpr aU () (PEval (Vctype intCty)))])))])))))))) p01Rest))

def p01ar3 : RExpr :=
  (Expr aU (Esseq (Pattern aU (CaseBase ((some symA527), (BTy_loaded OTy_integer)))) (Expr aU (Ebound (Expr aU (Ewseq (Pattern aU (CaseCtor Ctuple [(Pattern aU (CaseBase ((some symA529), (BTy_loaded OTy_integer)))), (Pattern aU (CaseBase ((some symA530), (BTy_loaded OTy_integer))))])) (Expr aU (Eunseq [(Expr aU (Ewseq (Pattern aU (CaseCtor Ctuple [(Pattern aU (CaseBase ((some symA535), (BTy_loaded OTy_integer)))), (Pattern aU (CaseBase ((some symA536), (BTy_loaded OTy_integer))))])) (Expr aU (Eunseq [(Expr aU (Ewseq (Pattern aU (CaseBase ((some symA534), (BTy_object OTy_pointer)))) (Expr aU (Epure (Pexpr [] () (PEval xPtrV)))) (Expr aU (Eaction (Paction Pos (Action L0 empty_annotation (Load0 (Pexpr aU () (PEval (Vctype intCty))) (Pexpr aU () (PEsym symA534)) NA))))))), (Expr aU (Epure (Pexpr [] () (PEval (loadedV 0)))))])) (Expr aU (Ecase (Pexpr aU () (PEctor Ctuple [(Pexpr aU () (PEsym symA535)), (Pexpr aU () (PEsym symA536))])) [((Pattern aU (CaseCtor Ctuple [(Pattern aU (CaseCtor Cspecified [(Pattern aU (CaseBase ((some symA537), (BTy_object OTy_integer))))])), (Pattern aU (CaseCtor Cspecified [(Pattern aU (CaseBase ((some symA538), (BTy_object OTy_integer))))]))])), (Expr aU (Epure (Pexpr aU () (PEif (Pexpr aU () (PEop OpLt (Pexpr aU () (PEcall (Sym symConvInt) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym symA537))])) (Pexpr aU () (PEcall (Sym symConvInt) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym symA538))])))) (Pexpr aU () (PEctor Cspecified [(Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (1))))))])) (Pexpr aU () (PEctor Cspecified [(Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (0))))))]))))))), ((Pattern aU (CaseBase (none, (BTy_tuple [(BTy_loaded OTy_integer), (BTy_loaded OTy_integer)])))), (Expr aU (Epure (Pexpr aU () (PEctor Cunspecified [(Pexpr aU () (PEval (Vctype intCty)))])))))])))), (Expr aU (Epure (Pexpr [] () (PEval (loadedV 0)))))])) (Expr aU (Epure (Pexpr aU () (PEcase (Pexpr aU () (PEctor Ctuple [(Pexpr aU () (PEsym symA529)), (Pexpr aU () (PEsym symA530))])) [((Pattern aU (CaseCtor Ctuple [(Pattern aU (CaseCtor Cspecified [(Pattern aU (CaseBase ((some symA531), (BTy_object OTy_integer))))])), (Pattern aU (CaseCtor Cspecified [(Pattern aU (CaseBase ((some symA532), (BTy_object OTy_integer))))]))])), (Pexpr aU () (PEif (Pexpr aU () (PEop OpEq (Pexpr aU () (PEcall (Sym symConvInt) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym symA531))])) (Pexpr aU () (PEcall (Sym symConvInt) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym symA532))])))) (Pexpr aU () (PEctor Cspecified [(Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (1))))))])) (Pexpr aU () (PEctor Cspecified [(Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (0))))))]))))), ((Pattern aU (CaseBase (none, (BTy_tuple [(BTy_loaded OTy_integer), (BTy_loaded OTy_integer)])))), (Pexpr aU () (PEctor Cunspecified [(Pexpr aU () (PEval (Vctype intCty)))])))])))))))) p01Rest))

def p01ar4 : RExpr :=
  (Expr aU (Esseq (Pattern aU (CaseBase ((some symA527), (BTy_loaded OTy_integer)))) (Expr aU (Ebound (Expr aU (Ewseq (Pattern aU (CaseCtor Ctuple [(Pattern aU (CaseBase ((some symA529), (BTy_loaded OTy_integer)))), (Pattern aU (CaseBase ((some symA530), (BTy_loaded OTy_integer))))])) (Expr aU (Eunseq [(Expr aU (Ewseq (Pattern aU (CaseCtor Ctuple [(Pattern aU (CaseBase ((some symA535), (BTy_loaded OTy_integer)))), (Pattern aU (CaseBase ((some symA536), (BTy_loaded OTy_integer))))])) (Expr aU (Eunseq [(Expr aU (Eaction (Paction Pos (Action L0 empty_annotation (Load0 (Pexpr aU () (PEval (Vctype intCty))) (Pexpr aU () (PEsym symA534)) NA))))), (Expr aU (Epure (Pexpr [] () (PEval (loadedV 0)))))])) (Expr aU (Ecase (Pexpr aU () (PEctor Ctuple [(Pexpr aU () (PEsym symA535)), (Pexpr aU () (PEsym symA536))])) [((Pattern aU (CaseCtor Ctuple [(Pattern aU (CaseCtor Cspecified [(Pattern aU (CaseBase ((some symA537), (BTy_object OTy_integer))))])), (Pattern aU (CaseCtor Cspecified [(Pattern aU (CaseBase ((some symA538), (BTy_object OTy_integer))))]))])), (Expr aU (Epure (Pexpr aU () (PEif (Pexpr aU () (PEop OpLt (Pexpr aU () (PEcall (Sym symConvInt) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym symA537))])) (Pexpr aU () (PEcall (Sym symConvInt) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym symA538))])))) (Pexpr aU () (PEctor Cspecified [(Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (1))))))])) (Pexpr aU () (PEctor Cspecified [(Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (0))))))]))))))), ((Pattern aU (CaseBase (none, (BTy_tuple [(BTy_loaded OTy_integer), (BTy_loaded OTy_integer)])))), (Expr aU (Epure (Pexpr aU () (PEctor Cunspecified [(Pexpr aU () (PEval (Vctype intCty)))])))))])))), (Expr aU (Epure (Pexpr [] () (PEval (loadedV 0)))))])) (Expr aU (Epure (Pexpr aU () (PEcase (Pexpr aU () (PEctor Ctuple [(Pexpr aU () (PEsym symA529)), (Pexpr aU () (PEsym symA530))])) [((Pattern aU (CaseCtor Ctuple [(Pattern aU (CaseCtor Cspecified [(Pattern aU (CaseBase ((some symA531), (BTy_object OTy_integer))))])), (Pattern aU (CaseCtor Cspecified [(Pattern aU (CaseBase ((some symA532), (BTy_object OTy_integer))))]))])), (Pexpr aU () (PEif (Pexpr aU () (PEop OpEq (Pexpr aU () (PEcall (Sym symConvInt) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym symA531))])) (Pexpr aU () (PEcall (Sym symConvInt) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym symA532))])))) (Pexpr aU () (PEctor Cspecified [(Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (1))))))])) (Pexpr aU () (PEctor Cspecified [(Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (0))))))]))))), ((Pattern aU (CaseBase (none, (BTy_tuple [(BTy_loaded OTy_integer), (BTy_loaded OTy_integer)])))), (Pexpr aU () (PEctor Cunspecified [(Pexpr aU () (PEval (Vctype intCty)))])))])))))))) p01Rest))

def p01ar5 : RExpr :=
  (Expr aU (Esseq (Pattern aU (CaseBase ((some symA527), (BTy_loaded OTy_integer)))) (Expr aU (Ebound (Expr aU (Ewseq (Pattern aU (CaseCtor Ctuple [(Pattern aU (CaseBase ((some symA529), (BTy_loaded OTy_integer)))), (Pattern aU (CaseBase ((some symA530), (BTy_loaded OTy_integer))))])) (Expr aU (Eunseq [(Expr aU (Ewseq (Pattern aU (CaseCtor Ctuple [(Pattern aU (CaseBase ((some symA535), (BTy_loaded OTy_integer)))), (Pattern aU (CaseBase ((some symA536), (BTy_loaded OTy_integer))))])) (Expr aU (Eunseq [(Expr aU (Eaction (Paction Pos (Action L0 empty_annotation (Load0 (Pexpr [] () (PEval (Vctype intCty))) (Pexpr [] () (PEval xPtrV)) NA))))), (Expr aU (Epure (Pexpr [] () (PEval (loadedV 0)))))])) (Expr aU (Ecase (Pexpr aU () (PEctor Ctuple [(Pexpr aU () (PEsym symA535)), (Pexpr aU () (PEsym symA536))])) [((Pattern aU (CaseCtor Ctuple [(Pattern aU (CaseCtor Cspecified [(Pattern aU (CaseBase ((some symA537), (BTy_object OTy_integer))))])), (Pattern aU (CaseCtor Cspecified [(Pattern aU (CaseBase ((some symA538), (BTy_object OTy_integer))))]))])), (Expr aU (Epure (Pexpr aU () (PEif (Pexpr aU () (PEop OpLt (Pexpr aU () (PEcall (Sym symConvInt) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym symA537))])) (Pexpr aU () (PEcall (Sym symConvInt) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym symA538))])))) (Pexpr aU () (PEctor Cspecified [(Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (1))))))])) (Pexpr aU () (PEctor Cspecified [(Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (0))))))]))))))), ((Pattern aU (CaseBase (none, (BTy_tuple [(BTy_loaded OTy_integer), (BTy_loaded OTy_integer)])))), (Expr aU (Epure (Pexpr aU () (PEctor Cunspecified [(Pexpr aU () (PEval (Vctype intCty)))])))))])))), (Expr aU (Epure (Pexpr [] () (PEval (loadedV 0)))))])) (Expr aU (Epure (Pexpr aU () (PEcase (Pexpr aU () (PEctor Ctuple [(Pexpr aU () (PEsym symA529)), (Pexpr aU () (PEsym symA530))])) [((Pattern aU (CaseCtor Ctuple [(Pattern aU (CaseCtor Cspecified [(Pattern aU (CaseBase ((some symA531), (BTy_object OTy_integer))))])), (Pattern aU (CaseCtor Cspecified [(Pattern aU (CaseBase ((some symA532), (BTy_object OTy_integer))))]))])), (Pexpr aU () (PEif (Pexpr aU () (PEop OpEq (Pexpr aU () (PEcall (Sym symConvInt) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym symA531))])) (Pexpr aU () (PEcall (Sym symConvInt) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym symA532))])))) (Pexpr aU () (PEctor Cspecified [(Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (1))))))])) (Pexpr aU () (PEctor Cspecified [(Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (0))))))]))))), ((Pattern aU (CaseBase (none, (BTy_tuple [(BTy_loaded OTy_integer), (BTy_loaded OTy_integer)])))), (Pexpr aU () (PEctor Cunspecified [(Pexpr aU () (PEval (Vctype intCty)))])))])))))))) p01Rest))

def p01ar6 (x : Int) : RExpr :=
  (Expr aU (Esseq (Pattern aU (CaseBase ((some symA527), (BTy_loaded OTy_integer)))) (Expr aU (Ebound (Expr aU (Ewseq (Pattern aU (CaseCtor Ctuple [(Pattern aU (CaseBase ((some symA529), (BTy_loaded OTy_integer)))), (Pattern aU (CaseBase ((some symA530), (BTy_loaded OTy_integer))))])) (Expr aU (Eunseq [(Expr aU (Ewseq (Pattern aU (CaseCtor Ctuple [(Pattern aU (CaseBase ((some symA535), (BTy_loaded OTy_integer)))), (Pattern aU (CaseBase ((some symA536), (BTy_loaded OTy_integer))))])) (Expr aU (Eunseq [(Expr [] (Eannot [(DA_pos [] (CerbMem.Footprint.FP .R 281474976710648 4))] (Expr [] (Epure (Pexpr [] () (PEval (loadedV x))))))), (Expr aU (Epure (Pexpr [] () (PEval (loadedV 0)))))])) (Expr aU (Ecase (Pexpr aU () (PEctor Ctuple [(Pexpr aU () (PEsym symA535)), (Pexpr aU () (PEsym symA536))])) [((Pattern aU (CaseCtor Ctuple [(Pattern aU (CaseCtor Cspecified [(Pattern aU (CaseBase ((some symA537), (BTy_object OTy_integer))))])), (Pattern aU (CaseCtor Cspecified [(Pattern aU (CaseBase ((some symA538), (BTy_object OTy_integer))))]))])), (Expr aU (Epure (Pexpr aU () (PEif (Pexpr aU () (PEop OpLt (Pexpr aU () (PEcall (Sym symConvInt) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym symA537))])) (Pexpr aU () (PEcall (Sym symConvInt) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym symA538))])))) (Pexpr aU () (PEctor Cspecified [(Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (1))))))])) (Pexpr aU () (PEctor Cspecified [(Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (0))))))]))))))), ((Pattern aU (CaseBase (none, (BTy_tuple [(BTy_loaded OTy_integer), (BTy_loaded OTy_integer)])))), (Expr aU (Epure (Pexpr aU () (PEctor Cunspecified [(Pexpr aU () (PEval (Vctype intCty)))])))))])))), (Expr aU (Epure (Pexpr [] () (PEval (loadedV 0)))))])) (Expr aU (Epure (Pexpr aU () (PEcase (Pexpr aU () (PEctor Ctuple [(Pexpr aU () (PEsym symA529)), (Pexpr aU () (PEsym symA530))])) [((Pattern aU (CaseCtor Ctuple [(Pattern aU (CaseCtor Cspecified [(Pattern aU (CaseBase ((some symA531), (BTy_object OTy_integer))))])), (Pattern aU (CaseCtor Cspecified [(Pattern aU (CaseBase ((some symA532), (BTy_object OTy_integer))))]))])), (Pexpr aU () (PEif (Pexpr aU () (PEop OpEq (Pexpr aU () (PEcall (Sym symConvInt) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym symA531))])) (Pexpr aU () (PEcall (Sym symConvInt) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym symA532))])))) (Pexpr aU () (PEctor Cspecified [(Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (1))))))])) (Pexpr aU () (PEctor Cspecified [(Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (0))))))]))))), ((Pattern aU (CaseBase (none, (BTy_tuple [(BTy_loaded OTy_integer), (BTy_loaded OTy_integer)])))), (Pexpr aU () (PEctor Cunspecified [(Pexpr aU () (PEval (Vctype intCty)))])))])))))))) p01Rest))

def p01ar7 (x : Int) : RExpr :=
  (Expr aU (Esseq (Pattern aU (CaseBase ((some symA527), (BTy_loaded OTy_integer)))) (Expr aU (Ebound (Expr aU (Ewseq (Pattern aU (CaseCtor Ctuple [(Pattern aU (CaseBase ((some symA529), (BTy_loaded OTy_integer)))), (Pattern aU (CaseBase ((some symA530), (BTy_loaded OTy_integer))))])) (Expr aU (Eunseq [(Expr aU (Ewseq (Pattern aU (CaseCtor Ctuple [(Pattern aU (CaseBase ((some symA535), (BTy_loaded OTy_integer)))), (Pattern aU (CaseBase ((some symA536), (BTy_loaded OTy_integer))))])) (Expr aU (Eannot [(DA_pos [] (CerbMem.Footprint.FP .R 281474976710648 4))] (Expr [] (Epure (Pexpr [] () (PEval (Vtuple [(loadedV x), (loadedV 0)]))))))) (Expr aU (Ecase (Pexpr aU () (PEctor Ctuple [(Pexpr aU () (PEsym symA535)), (Pexpr aU () (PEsym symA536))])) [((Pattern aU (CaseCtor Ctuple [(Pattern aU (CaseCtor Cspecified [(Pattern aU (CaseBase ((some symA537), (BTy_object OTy_integer))))])), (Pattern aU (CaseCtor Cspecified [(Pattern aU (CaseBase ((some symA538), (BTy_object OTy_integer))))]))])), (Expr aU (Epure (Pexpr aU () (PEif (Pexpr aU () (PEop OpLt (Pexpr aU () (PEcall (Sym symConvInt) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym symA537))])) (Pexpr aU () (PEcall (Sym symConvInt) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym symA538))])))) (Pexpr aU () (PEctor Cspecified [(Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (1))))))])) (Pexpr aU () (PEctor Cspecified [(Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (0))))))]))))))), ((Pattern aU (CaseBase (none, (BTy_tuple [(BTy_loaded OTy_integer), (BTy_loaded OTy_integer)])))), (Expr aU (Epure (Pexpr aU () (PEctor Cunspecified [(Pexpr aU () (PEval (Vctype intCty)))])))))])))), (Expr aU (Epure (Pexpr [] () (PEval (loadedV 0)))))])) (Expr aU (Epure (Pexpr aU () (PEcase (Pexpr aU () (PEctor Ctuple [(Pexpr aU () (PEsym symA529)), (Pexpr aU () (PEsym symA530))])) [((Pattern aU (CaseCtor Ctuple [(Pattern aU (CaseCtor Cspecified [(Pattern aU (CaseBase ((some symA531), (BTy_object OTy_integer))))])), (Pattern aU (CaseCtor Cspecified [(Pattern aU (CaseBase ((some symA532), (BTy_object OTy_integer))))]))])), (Pexpr aU () (PEif (Pexpr aU () (PEop OpEq (Pexpr aU () (PEcall (Sym symConvInt) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym symA531))])) (Pexpr aU () (PEcall (Sym symConvInt) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym symA532))])))) (Pexpr aU () (PEctor Cspecified [(Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (1))))))])) (Pexpr aU () (PEctor Cspecified [(Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (0))))))]))))), ((Pattern aU (CaseBase (none, (BTy_tuple [(BTy_loaded OTy_integer), (BTy_loaded OTy_integer)])))), (Pexpr aU () (PEctor Cunspecified [(Pexpr aU () (PEval (Vctype intCty)))])))])))))))) p01Rest))

def p01ar8 : RExpr :=
  (Expr aU (Esseq (Pattern aU (CaseBase ((some symA527), (BTy_loaded OTy_integer)))) (Expr aU (Ebound (Expr aU (Ewseq (Pattern aU (CaseCtor Ctuple [(Pattern aU (CaseBase ((some symA529), (BTy_loaded OTy_integer)))), (Pattern aU (CaseBase ((some symA530), (BTy_loaded OTy_integer))))])) (Expr aU (Eunseq [(Expr [] (Eannot [(DA_pos [] (CerbMem.Footprint.FP .R 281474976710648 4))] (Expr aU (Ecase (Pexpr aU () (PEctor Ctuple [(Pexpr aU () (PEsym symA535)), (Pexpr aU () (PEsym symA536))])) [((Pattern aU (CaseCtor Ctuple [(Pattern aU (CaseCtor Cspecified [(Pattern aU (CaseBase ((some symA537), (BTy_object OTy_integer))))])), (Pattern aU (CaseCtor Cspecified [(Pattern aU (CaseBase ((some symA538), (BTy_object OTy_integer))))]))])), (Expr aU (Epure (Pexpr aU () (PEif (Pexpr aU () (PEop OpLt (Pexpr aU () (PEcall (Sym symConvInt) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym symA537))])) (Pexpr aU () (PEcall (Sym symConvInt) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym symA538))])))) (Pexpr aU () (PEctor Cspecified [(Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (1))))))])) (Pexpr aU () (PEctor Cspecified [(Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (0))))))]))))))), ((Pattern aU (CaseBase (none, (BTy_tuple [(BTy_loaded OTy_integer), (BTy_loaded OTy_integer)])))), (Expr aU (Epure (Pexpr aU () (PEctor Cunspecified [(Pexpr aU () (PEval (Vctype intCty)))])))))])))), (Expr aU (Epure (Pexpr [] () (PEval (loadedV 0)))))])) (Expr aU (Epure (Pexpr aU () (PEcase (Pexpr aU () (PEctor Ctuple [(Pexpr aU () (PEsym symA529)), (Pexpr aU () (PEsym symA530))])) [((Pattern aU (CaseCtor Ctuple [(Pattern aU (CaseCtor Cspecified [(Pattern aU (CaseBase ((some symA531), (BTy_object OTy_integer))))])), (Pattern aU (CaseCtor Cspecified [(Pattern aU (CaseBase ((some symA532), (BTy_object OTy_integer))))]))])), (Pexpr aU () (PEif (Pexpr aU () (PEop OpEq (Pexpr aU () (PEcall (Sym symConvInt) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym symA531))])) (Pexpr aU () (PEcall (Sym symConvInt) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym symA532))])))) (Pexpr aU () (PEctor Cspecified [(Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (1))))))])) (Pexpr aU () (PEctor Cspecified [(Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (0))))))]))))), ((Pattern aU (CaseBase (none, (BTy_tuple [(BTy_loaded OTy_integer), (BTy_loaded OTy_integer)])))), (Pexpr aU () (PEctor Cunspecified [(Pexpr aU () (PEval (Vctype intCty)))])))])))))))) p01Rest))

def p01ar9 (x : Int) : RExpr :=
  (Expr aU (Esseq (Pattern aU (CaseBase ((some symA527), (BTy_loaded OTy_integer)))) (Expr aU (Ebound (Expr aU (Ewseq (Pattern aU (CaseCtor Ctuple [(Pattern aU (CaseBase ((some symA529), (BTy_loaded OTy_integer)))), (Pattern aU (CaseBase ((some symA530), (BTy_loaded OTy_integer))))])) (Expr aU (Eunseq [(Expr [] (Eannot [(DA_pos [] (CerbMem.Footprint.FP .R 281474976710648 4))] (Expr aU (Ecase (Pexpr [] () (PEval (Vtuple [(loadedV x), (loadedV 0)]))) [((Pattern aU (CaseCtor Ctuple [(Pattern aU (CaseCtor Cspecified [(Pattern aU (CaseBase ((some symA537), (BTy_object OTy_integer))))])), (Pattern aU (CaseCtor Cspecified [(Pattern aU (CaseBase ((some symA538), (BTy_object OTy_integer))))]))])), (Expr aU (Epure (Pexpr aU () (PEif (Pexpr aU () (PEop OpLt (Pexpr aU () (PEcall (Sym symConvInt) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym symA537))])) (Pexpr aU () (PEcall (Sym symConvInt) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym symA538))])))) (Pexpr aU () (PEctor Cspecified [(Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (1))))))])) (Pexpr aU () (PEctor Cspecified [(Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (0))))))]))))))), ((Pattern aU (CaseBase (none, (BTy_tuple [(BTy_loaded OTy_integer), (BTy_loaded OTy_integer)])))), (Expr aU (Epure (Pexpr aU () (PEctor Cunspecified [(Pexpr aU () (PEval (Vctype intCty)))])))))])))), (Expr aU (Epure (Pexpr [] () (PEval (loadedV 0)))))])) (Expr aU (Epure (Pexpr aU () (PEcase (Pexpr aU () (PEctor Ctuple [(Pexpr aU () (PEsym symA529)), (Pexpr aU () (PEsym symA530))])) [((Pattern aU (CaseCtor Ctuple [(Pattern aU (CaseCtor Cspecified [(Pattern aU (CaseBase ((some symA531), (BTy_object OTy_integer))))])), (Pattern aU (CaseCtor Cspecified [(Pattern aU (CaseBase ((some symA532), (BTy_object OTy_integer))))]))])), (Pexpr aU () (PEif (Pexpr aU () (PEop OpEq (Pexpr aU () (PEcall (Sym symConvInt) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym symA531))])) (Pexpr aU () (PEcall (Sym symConvInt) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym symA532))])))) (Pexpr aU () (PEctor Cspecified [(Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (1))))))])) (Pexpr aU () (PEctor Cspecified [(Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (0))))))]))))), ((Pattern aU (CaseBase (none, (BTy_tuple [(BTy_loaded OTy_integer), (BTy_loaded OTy_integer)])))), (Pexpr aU () (PEctor Cunspecified [(Pexpr aU () (PEval (Vctype intCty)))])))])))))))) p01Rest))

def p01ar10 (x : Int) : RExpr :=
  (Expr aU (Esseq (Pattern aU (CaseBase ((some symA527), (BTy_loaded OTy_integer)))) (Expr aU (Ebound (Expr aU (Ewseq (Pattern aU (CaseCtor Ctuple [(Pattern aU (CaseBase ((some symA529), (BTy_loaded OTy_integer)))), (Pattern aU (CaseBase ((some symA530), (BTy_loaded OTy_integer))))])) (Expr aU (Eunseq [(Expr [] (Eannot [(DA_pos [] (CerbMem.Footprint.FP .R 281474976710648 4))] (Expr aU (Epure (Pexpr aU () (PEif (Pexpr aU () (PEop OpLt (Pexpr aU () (PEcall (Sym symConvInt) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (x))))))])) (Pexpr aU () (PEcall (Sym symConvInt) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (0))))))])))) (Pexpr aU () (PEctor Cspecified [(Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (1))))))])) (Pexpr aU () (PEctor Cspecified [(Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (0))))))])))))))), (Expr aU (Epure (Pexpr [] () (PEval (loadedV 0)))))])) (Expr aU (Epure (Pexpr aU () (PEcase (Pexpr aU () (PEctor Ctuple [(Pexpr aU () (PEsym symA529)), (Pexpr aU () (PEsym symA530))])) [((Pattern aU (CaseCtor Ctuple [(Pattern aU (CaseCtor Cspecified [(Pattern aU (CaseBase ((some symA531), (BTy_object OTy_integer))))])), (Pattern aU (CaseCtor Cspecified [(Pattern aU (CaseBase ((some symA532), (BTy_object OTy_integer))))]))])), (Pexpr aU () (PEif (Pexpr aU () (PEop OpEq (Pexpr aU () (PEcall (Sym symConvInt) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym symA531))])) (Pexpr aU () (PEcall (Sym symConvInt) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym symA532))])))) (Pexpr aU () (PEctor Cspecified [(Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (1))))))])) (Pexpr aU () (PEctor Cspecified [(Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (0))))))]))))), ((Pattern aU (CaseBase (none, (BTy_tuple [(BTy_loaded OTy_integer), (BTy_loaded OTy_integer)])))), (Pexpr aU () (PEctor Cunspecified [(Pexpr aU () (PEval (Vctype intCty)))])))])))))))) p01Rest))

-- round 11: c = 1 (x<0) / 0 (else)
def p01ar11 (c : Int) : RExpr :=
  (Expr aU (Esseq (Pattern aU (CaseBase ((some symA527), (BTy_loaded OTy_integer)))) (Expr aU (Ebound (Expr aU (Ewseq (Pattern aU (CaseCtor Ctuple [(Pattern aU (CaseBase ((some symA529), (BTy_loaded OTy_integer)))), (Pattern aU (CaseBase ((some symA530), (BTy_loaded OTy_integer))))])) (Expr aU (Eunseq [(Expr [] (Eannot [(DA_pos [] (CerbMem.Footprint.FP .R 281474976710648 4))] (Expr aU (Epure (Pexpr [] () (PEval (Vloaded (LVspecified (OVinteger (.IV .Prov_none (c))))))))))), (Expr aU (Epure (Pexpr [] () (PEval (loadedV 0)))))])) (Expr aU (Epure (Pexpr aU () (PEcase (Pexpr aU () (PEctor Ctuple [(Pexpr aU () (PEsym symA529)), (Pexpr aU () (PEsym symA530))])) [((Pattern aU (CaseCtor Ctuple [(Pattern aU (CaseCtor Cspecified [(Pattern aU (CaseBase ((some symA531), (BTy_object OTy_integer))))])), (Pattern aU (CaseCtor Cspecified [(Pattern aU (CaseBase ((some symA532), (BTy_object OTy_integer))))]))])), (Pexpr aU () (PEif (Pexpr aU () (PEop OpEq (Pexpr aU () (PEcall (Sym symConvInt) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym symA531))])) (Pexpr aU () (PEcall (Sym symConvInt) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym symA532))])))) (Pexpr aU () (PEctor Cspecified [(Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (1))))))])) (Pexpr aU () (PEctor Cspecified [(Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (0))))))]))))), ((Pattern aU (CaseBase (none, (BTy_tuple [(BTy_loaded OTy_integer), (BTy_loaded OTy_integer)])))), (Pexpr aU () (PEctor Cunspecified [(Pexpr aU () (PEval (Vctype intCty)))])))])))))))) p01Rest))

-- round 12: c = 1 (x<0) / 0 (else)
def p01ar12 (c : Int) : RExpr :=
  (Expr aU (Esseq (Pattern aU (CaseBase ((some symA527), (BTy_loaded OTy_integer)))) (Expr aU (Ebound (Expr aU (Ewseq (Pattern aU (CaseCtor Ctuple [(Pattern aU (CaseBase ((some symA529), (BTy_loaded OTy_integer)))), (Pattern aU (CaseBase ((some symA530), (BTy_loaded OTy_integer))))])) (Expr aU (Eannot [(DA_pos [] (CerbMem.Footprint.FP .R 281474976710648 4))] (Expr [] (Epure (Pexpr [] () (PEval (Vtuple [(Vloaded (LVspecified (OVinteger (.IV .Prov_none (c))))), (loadedV 0)]))))))) (Expr aU (Epure (Pexpr aU () (PEcase (Pexpr aU () (PEctor Ctuple [(Pexpr aU () (PEsym symA529)), (Pexpr aU () (PEsym symA530))])) [((Pattern aU (CaseCtor Ctuple [(Pattern aU (CaseCtor Cspecified [(Pattern aU (CaseBase ((some symA531), (BTy_object OTy_integer))))])), (Pattern aU (CaseCtor Cspecified [(Pattern aU (CaseBase ((some symA532), (BTy_object OTy_integer))))]))])), (Pexpr aU () (PEif (Pexpr aU () (PEop OpEq (Pexpr aU () (PEcall (Sym symConvInt) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym symA531))])) (Pexpr aU () (PEcall (Sym symConvInt) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym symA532))])))) (Pexpr aU () (PEctor Cspecified [(Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (1))))))])) (Pexpr aU () (PEctor Cspecified [(Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (0))))))]))))), ((Pattern aU (CaseBase (none, (BTy_tuple [(BTy_loaded OTy_integer), (BTy_loaded OTy_integer)])))), (Pexpr aU () (PEctor Cunspecified [(Pexpr aU () (PEval (Vctype intCty)))])))])))))))) p01Rest))

def p01ar13 : RExpr :=
  (Expr aU (Esseq (Pattern aU (CaseBase ((some symA527), (BTy_loaded OTy_integer)))) (Expr aU (Ebound (Expr [] (Eannot [(DA_pos [] (CerbMem.Footprint.FP .R 281474976710648 4))] (Expr aU (Epure (Pexpr aU () (PEcase (Pexpr aU () (PEctor Ctuple [(Pexpr aU () (PEsym symA529)), (Pexpr aU () (PEsym symA530))])) [((Pattern aU (CaseCtor Ctuple [(Pattern aU (CaseCtor Cspecified [(Pattern aU (CaseBase ((some symA531), (BTy_object OTy_integer))))])), (Pattern aU (CaseCtor Cspecified [(Pattern aU (CaseBase ((some symA532), (BTy_object OTy_integer))))]))])), (Pexpr aU () (PEif (Pexpr aU () (PEop OpEq (Pexpr aU () (PEcall (Sym symConvInt) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym symA531))])) (Pexpr aU () (PEcall (Sym symConvInt) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym symA532))])))) (Pexpr aU () (PEctor Cspecified [(Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (1))))))])) (Pexpr aU () (PEctor Cspecified [(Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (0))))))]))))), ((Pattern aU (CaseBase (none, (BTy_tuple [(BTy_loaded OTy_integer), (BTy_loaded OTy_integer)])))), (Pexpr aU () (PEctor Cunspecified [(Pexpr aU () (PEval (Vctype intCty)))])))])))))))) p01Rest))

-- round 14: c = 0 (x<0) / 1 (else)
def p01ar14 (c : Int) : RExpr :=
  (Expr aU (Esseq (Pattern aU (CaseBase ((some symA527), (BTy_loaded OTy_integer)))) (Expr aU (Ebound (Expr [] (Eannot [(DA_pos [] (CerbMem.Footprint.FP .R 281474976710648 4))] (Expr aU (Epure (Pexpr [] () (PEval (Vloaded (LVspecified (OVinteger (.IV .Prov_none (c))))))))))))) p01Rest))

-- round 15: c = 0 (x<0) / 1 (else)
def p01ar15 (c : Int) : RExpr :=
  (Expr aU (Esseq (Pattern aU (CaseBase ((some symA527), (BTy_loaded OTy_integer)))) (Expr aU (Epure (Pexpr [] () (PEval (Vloaded (LVspecified (OVinteger (.IV .Prov_none (c))))))))) p01Rest))

def p01ar16 : RExpr :=
  p01Rest

-- round 17: c = 0 / 1
def p01ar17 (c : Int) : RExpr :=
  (Expr aU (Esseq (Pattern aU (CaseBase ((some symA526), BTy_boolean))) (Expr aU (Ecase (Pexpr [] () (PEval (Vloaded (LVspecified (OVinteger (.IV .Prov_none (c))))))) [((Pattern aU (CaseCtor Cspecified [(Pattern aU (CaseBase ((some symA528), (BTy_object OTy_integer))))])), (Expr aU (Epure (Pexpr aU () (PEif (Pexpr aU () (PEnot (Pexpr aU () (PEop OpEq (Pexpr aU () (PEsym symA528)) (Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (1)))))))))) (Pexpr aU () (PEval Vtrue)) (Pexpr aU () (PEval Vfalse))))))), ((Pattern aU (CaseCtor Cunspecified [(Pattern aU (CaseBase (none, BTy_ctype)))])), (Expr aU (End [(Expr aU (Epure (Pexpr aU () (PEval Vtrue)))), (Expr aU (Epure (Pexpr aU () (PEval Vfalse))))])))])) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) p01IfBlk (Expr aU (Esseq (Pattern aU (CaseBase ((some symA542), (BTy_loaded OTy_integer)))) (Expr aU (Ebound (Expr aU (Ewseq (Pattern aU (CaseBase ((some symA541), (BTy_object OTy_pointer)))) (Expr aU (Epure (Pexpr aU () (PEsym symX)))) (Expr aU (Eaction (Paction Pos (Action L0 empty_annotation (Load0 (Pexpr aU () (PEval (Vctype intCty))) (Pexpr aU () (PEsym symA541)) NA))))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Erun empty_annotation symRet525 [(Pexpr aU () (PEcall (Sym symConvLoadedInt) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym symA542))]))])) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) p01ArmF p01SaveBlk))))))))))

-- round 18: c = 0 / 1
def p01ar18 (c : Int) : RExpr :=
  (Expr aU (Esseq (Pattern aU (CaseBase ((some symA526), BTy_boolean))) (Expr aU (Epure (Pexpr aU () (PEif (Pexpr aU () (PEnot (Pexpr aU () (PEop OpEq (Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (c)))))) (Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (1)))))))))) (Pexpr aU () (PEval Vtrue)) (Pexpr aU () (PEval Vfalse)))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) p01IfBlk (Expr aU (Esseq (Pattern aU (CaseBase ((some symA542), (BTy_loaded OTy_integer)))) (Expr aU (Ebound (Expr aU (Ewseq (Pattern aU (CaseBase ((some symA541), (BTy_object OTy_pointer)))) (Expr aU (Epure (Pexpr aU () (PEsym symX)))) (Expr aU (Eaction (Paction Pos (Action L0 empty_annotation (Load0 (Pexpr aU () (PEval (Vctype intCty))) (Pexpr aU () (PEsym symA541)) NA))))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Erun empty_annotation symRet525 [(Pexpr aU () (PEcall (Sym symConvLoadedInt) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym symA542))]))])) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) p01ArmF p01SaveBlk))))))))))

-- round 19: vb = Vtrue (x<0) / Vfalse (else)
def p01ar19 (vb : value) : RExpr :=
  (Expr aU (Esseq (Pattern aU (CaseBase ((some symA526), BTy_boolean))) (Expr aU (Epure (Pexpr [] () (PEval vb)))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) p01IfBlk (Expr aU (Esseq (Pattern aU (CaseBase ((some symA542), (BTy_loaded OTy_integer)))) (Expr aU (Ebound (Expr aU (Ewseq (Pattern aU (CaseBase ((some symA541), (BTy_object OTy_pointer)))) (Expr aU (Epure (Pexpr aU () (PEsym symX)))) (Expr aU (Eaction (Paction Pos (Action L0 empty_annotation (Load0 (Pexpr aU () (PEval (Vctype intCty))) (Pexpr aU () (PEsym symA541)) NA))))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Erun empty_annotation symRet525 [(Pexpr aU () (PEcall (Sym symConvLoadedInt) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym symA542))]))])) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) p01ArmF p01SaveBlk))))))))))

def p01ar20 : RExpr :=
  (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) p01IfBlk (Expr aU (Esseq (Pattern aU (CaseBase ((some symA542), (BTy_loaded OTy_integer)))) (Expr aU (Ebound (Expr aU (Ewseq (Pattern aU (CaseBase ((some symA541), (BTy_object OTy_pointer)))) (Expr aU (Epure (Pexpr aU () (PEsym symX)))) (Expr aU (Eaction (Paction Pos (Action L0 empty_annotation (Load0 (Pexpr aU () (PEval (Vctype intCty))) (Pexpr aU () (PEsym symA541)) NA))))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Erun empty_annotation symRet525 [(Pexpr aU () (PEcall (Sym symConvLoadedInt) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym symA542))]))])) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) p01ArmF p01SaveBlk))))))))

def p01arT21 : RExpr :=
  (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) p01ArmT (Expr aU (Esseq (Pattern aU (CaseBase ((some symA542), (BTy_loaded OTy_integer)))) (Expr aU (Ebound (Expr aU (Ewseq (Pattern aU (CaseBase ((some symA541), (BTy_object OTy_pointer)))) (Expr aU (Epure (Pexpr aU () (PEsym symX)))) (Expr aU (Eaction (Paction Pos (Action L0 empty_annotation (Load0 (Pexpr aU () (PEval (Vctype intCty))) (Pexpr aU () (PEsym symA541)) NA))))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Erun empty_annotation symRet525 [(Pexpr aU () (PEcall (Sym symConvLoadedInt) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym symA542))]))])) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) p01ArmF p01SaveBlk))))))))

def p01arT22 : RExpr :=
  (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Esseq (Pattern aU (CaseBase ((some symA540), (BTy_loaded OTy_integer)))) (Expr aU (Ebound (Expr aU (Epure (Pexpr [] () (PEval (loadedV 0))))))) (Expr aU (Erun empty_annotation symRet525 [(Pexpr aU () (PEcall (Sym symConvLoadedInt) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym symA540))]))])))) (Expr aU (Esseq (Pattern aU (CaseBase ((some symA542), (BTy_loaded OTy_integer)))) (Expr aU (Ebound (Expr aU (Ewseq (Pattern aU (CaseBase ((some symA541), (BTy_object OTy_pointer)))) (Expr aU (Epure (Pexpr aU () (PEsym symX)))) (Expr aU (Eaction (Paction Pos (Action L0 empty_annotation (Load0 (Pexpr aU () (PEval (Vctype intCty))) (Pexpr aU () (PEsym symA541)) NA))))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Erun empty_annotation symRet525 [(Pexpr aU () (PEcall (Sym symConvLoadedInt) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym symA542))]))])) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) p01ArmF p01SaveBlk))))))))

def p01arT23 : RExpr :=
  (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Esseq (Pattern aU (CaseBase ((some symA540), (BTy_loaded OTy_integer)))) (Expr aU (Epure (Pexpr [] () (PEval (loadedV 0))))) (Expr aU (Erun empty_annotation symRet525 [(Pexpr aU () (PEcall (Sym symConvLoadedInt) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym symA540))]))])))) (Expr aU (Esseq (Pattern aU (CaseBase ((some symA542), (BTy_loaded OTy_integer)))) (Expr aU (Ebound (Expr aU (Ewseq (Pattern aU (CaseBase ((some symA541), (BTy_object OTy_pointer)))) (Expr aU (Epure (Pexpr aU () (PEsym symX)))) (Expr aU (Eaction (Paction Pos (Action L0 empty_annotation (Load0 (Pexpr aU () (PEval (Vctype intCty))) (Pexpr aU () (PEsym symA541)) NA))))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Erun empty_annotation symRet525 [(Pexpr aU () (PEcall (Sym symConvLoadedInt) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym symA542))]))])) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) p01ArmF p01SaveBlk))))))))

def p01arT24 : RExpr :=
  (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Erun empty_annotation symRet525 [(Pexpr aU () (PEcall (Sym symConvLoadedInt) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym symA540))]))])) (Expr aU (Esseq (Pattern aU (CaseBase ((some symA542), (BTy_loaded OTy_integer)))) (Expr aU (Ebound (Expr aU (Ewseq (Pattern aU (CaseBase ((some symA541), (BTy_object OTy_pointer)))) (Expr aU (Epure (Pexpr aU () (PEsym symX)))) (Expr aU (Eaction (Paction Pos (Action L0 empty_annotation (Load0 (Pexpr aU () (PEval (Vctype intCty))) (Pexpr aU () (PEsym symA541)) NA))))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Erun empty_annotation symRet525 [(Pexpr aU () (PEcall (Sym symConvLoadedInt) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym symA542))]))])) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) p01ArmF p01SaveBlk))))))))

def p01arT25 : RExpr :=
  (Expr aU (Epure (Pexpr aU () (PEsym symA543))))

def p01arF21 : RExpr :=
  (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) p01ArmF (Expr aU (Esseq (Pattern aU (CaseBase ((some symA542), (BTy_loaded OTy_integer)))) (Expr aU (Ebound (Expr aU (Ewseq (Pattern aU (CaseBase ((some symA541), (BTy_object OTy_pointer)))) (Expr aU (Epure (Pexpr aU () (PEsym symX)))) (Expr aU (Eaction (Paction Pos (Action L0 empty_annotation (Load0 (Pexpr aU () (PEval (Vctype intCty))) (Pexpr aU () (PEsym symA541)) NA))))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Erun empty_annotation symRet525 [(Pexpr aU () (PEcall (Sym symConvLoadedInt) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym symA542))]))])) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) p01ArmF p01SaveBlk))))))))

def p01arF22 : RExpr :=
  (Expr aU (Esseq (Pattern aU (CaseBase ((some symA542), (BTy_loaded OTy_integer)))) (Expr aU (Ebound (Expr aU (Ewseq (Pattern aU (CaseBase ((some symA541), (BTy_object OTy_pointer)))) (Expr aU (Epure (Pexpr aU () (PEsym symX)))) (Expr aU (Eaction (Paction Pos (Action L0 empty_annotation (Load0 (Pexpr aU () (PEval (Vctype intCty))) (Pexpr aU () (PEsym symA541)) NA))))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Erun empty_annotation symRet525 [(Pexpr aU () (PEcall (Sym symConvLoadedInt) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym symA542))]))])) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) p01ArmF p01SaveBlk))))))

def p01arF23 : RExpr :=
  (Expr aU (Esseq (Pattern aU (CaseBase ((some symA542), (BTy_loaded OTy_integer)))) (Expr aU (Ebound (Expr aU (Ewseq (Pattern aU (CaseBase ((some symA541), (BTy_object OTy_pointer)))) (Expr aU (Epure (Pexpr [] () (PEval xPtrV)))) (Expr aU (Eaction (Paction Pos (Action L0 empty_annotation (Load0 (Pexpr aU () (PEval (Vctype intCty))) (Pexpr aU () (PEsym symA541)) NA))))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Erun empty_annotation symRet525 [(Pexpr aU () (PEcall (Sym symConvLoadedInt) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym symA542))]))])) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) p01ArmF p01SaveBlk))))))

def p01arF24 : RExpr :=
  (Expr aU (Esseq (Pattern aU (CaseBase ((some symA542), (BTy_loaded OTy_integer)))) (Expr aU (Ebound (Expr aU (Eaction (Paction Pos (Action L0 empty_annotation (Load0 (Pexpr aU () (PEval (Vctype intCty))) (Pexpr aU () (PEsym symA541)) NA))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Erun empty_annotation symRet525 [(Pexpr aU () (PEcall (Sym symConvLoadedInt) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym symA542))]))])) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) p01ArmF p01SaveBlk))))))

def p01arF25 : RExpr :=
  (Expr aU (Esseq (Pattern aU (CaseBase ((some symA542), (BTy_loaded OTy_integer)))) (Expr aU (Ebound (Expr aU (Eaction (Paction Pos (Action L0 empty_annotation (Load0 (Pexpr [] () (PEval (Vctype intCty))) (Pexpr [] () (PEval xPtrV)) NA))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Erun empty_annotation symRet525 [(Pexpr aU () (PEcall (Sym symConvLoadedInt) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym symA542))]))])) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) p01ArmF p01SaveBlk))))))

def p01arF26 (x : Int) : RExpr :=
  (Expr aU (Esseq (Pattern aU (CaseBase ((some symA542), (BTy_loaded OTy_integer)))) (Expr aU (Ebound (Expr [] (Eannot [(DA_pos [] (CerbMem.Footprint.FP .R 281474976710648 4))] (Expr [] (Epure (Pexpr [] () (PEval (loadedV x))))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Erun empty_annotation symRet525 [(Pexpr aU () (PEcall (Sym symConvLoadedInt) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym symA542))]))])) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) p01ArmF p01SaveBlk))))))

def p01arF27 (x : Int) : RExpr :=
  (Expr aU (Esseq (Pattern aU (CaseBase ((some symA542), (BTy_loaded OTy_integer)))) (Expr [] (Epure (Pexpr [] () (PEval (loadedV x))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Erun empty_annotation symRet525 [(Pexpr aU () (PEcall (Sym symConvLoadedInt) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym symA542))]))])) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) p01ArmF p01SaveBlk))))))

def p01arF28 : RExpr :=
  (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Erun empty_annotation symRet525 [(Pexpr aU () (PEcall (Sym symConvLoadedInt) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym symA542))]))])) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) p01ArmF p01SaveBlk))))

def p01arF29 : RExpr :=
  (Expr aU (Epure (Pexpr aU () (PEsym symA543))))

def p01arF30 (x : Int) : RExpr :=
  (Expr aU (Epure (Pexpr [] () (PEval (loadedV x)))))



/-! ## ENV BIRTH SCHEDULE (post-round n: new bindings) -/
-- NEG pre-round 0: NEW {'x': 'xPtrV'} CHG {}
-- NEG pre-round 4: NEW {'a_534': 'xPtrV'} CHG {}
-- NEG pre-round 8: NEW {'a_535': '(loadedV -3)', 'a_536': '(loadedV 0)'} CHG {}
-- NEG pre-round 13: NEW {'a_529': '(loadedV 1)', 'a_530': '(loadedV 0)'} CHG {}
-- NEG pre-round 16: NEW {'a_527': '(loadedV 0)'} CHG {}
-- NEG pre-round 20: NEW {'a_526': 'Vtrue'} CHG {}
-- NEG pre-round 24: NEW {'a_540': '(loadedV 0)'} CHG {}
-- NEG pre-round 25: NEW {'a_543': '(loadedV 0)'} CHG {}
-- NEG traces: (ME_load L0 none intCty xPtr MV=MVinteger (Signed Int_) (.IV .Prov_none (-3)))
-- POS pre-round 0: NEW {'x': 'xPtrV'} CHG {}
-- POS pre-round 4: NEW {'a_534': 'xPtrV'} CHG {}
-- POS pre-round 8: NEW {'a_535': '(loadedV 7)', 'a_536': '(loadedV 0)'} CHG {}
-- POS pre-round 13: NEW {'a_529': '(loadedV 0)', 'a_530': '(loadedV 0)'} CHG {}
-- POS pre-round 16: NEW {'a_527': '(loadedV 1)'} CHG {}
-- POS pre-round 20: NEW {'a_526': 'Vfalse'} CHG {}
-- POS pre-round 24: NEW {'a_541': 'xPtrV'} CHG {}
-- POS pre-round 28: NEW {'a_542': '(loadedV 7)'} CHG {}
-- POS pre-round 29: NEW {'a_543': '(loadedV 7)'} CHG {}
-- POS traces: (ME_load L0 none intCty xPtr MV=MVinteger (Signed Int_) (.IV .Prov_none (7))) | (ME_load L0 none intCty xPtr MV=MVinteger (Signed Int_) (.IV .Prov_none (7))), (ME_load L0 none intCty xPtr MV=MVinteger (Signed Int_) (.IV .Prov_none (7)))

/-! ## The P01 state families (T1Rounds mirrors at p01File/clamp0) -/

@[reducible] def p01Th (arena : RExpr) (f₁ : Fmap sym value) :
    thread_state :=
  { arena := arena,
    stack0 := Stack_empty,
    errno := errPtr,
    current_loc := L0,
    exec_loc := ELoc_normal [(clampP01Sym, CerbLocation.other "RelSem.callND")],
    env := [f₁],
    current_proc_opt := some clampP01Sym }

@[reducible] def p01σ (arena : RExpr) (f₁ : Fmap sym value)
    (tS aS eS sS : Nat) (ls : CerbMem.MemState)
    (tr : List trace_event) (n : Nat) : driver_state :=
  { core_file := p01File,
    core_extern := create_extern_symmap p01File,
    core_state0 :=
      { thread_states := [(0, (none, p01Th arena f₁))],
        io := initial_io_state },
    core_run_state0 :=
      { tid_supply := tS, aid_supply := aS, excluded_supply := eS,
        sym_supply := sS,
        labeled := (initial_core_run_state_threaded 0
          (collect_labeled_continuations_NEW p01File)).labeled },
    layout_state := ls,
    concurrency_state := symInitialState symInitialPre,
    fs_state0 := CerbFS.fs_initial_state,
    trace := tr,
    symbolic_assoc := fmapEmpty,
    blocked := false,
    dr_step_counter := n }

def p01CtlAt (arena : RExpr) (tr : List trace_event) (n : Nat) :
    driver_state :=
  ctlOf (p01σ arena fmapEmpty 0 0 0 0 CerbMem.initialMemState tr n)

@[reducible] def p01fam (arena : RExpr) (tr : List trace_event)
    (n : Nat) (p : T1P) : driver_state :=
  p01σ arena p.f₁ p.tS p.aS p.eS p.sS p.ls tr n

/-- Control inversion at the P01 family. -/
@[seg_inv]
theorem p01_inv {σ : driver_state} {arena : RExpr}
    {tr : List trace_event} {n : Nat}
    (h : ctlOf σ = p01CtlAt arena tr n) :
    ∃ p : T1P, σ = p01fam arena tr n p := by
  obtain ⟨cf, ce, cs, crs, ls, ccs, fs0, tr', sa, bl, ctr'⟩ := σ
  obtain ⟨ths, io⟩ := cs
  obtain ⟨tS, aS, eS, sS, lab⟩ := crs
  have h' := h
  simp only [p01CtlAt, ctlOf, p01σ, eraseEnvs, driver_state.mk.injEq,
    core_state.mk.injEq, core_run_state.mk.injEq] at h'
  obtain ⟨hcf, hce, ⟨hths, hio⟩, ⟨-, -, -, -, hlab⟩, -, hccs, hfs,
    htr, hsa, hbl, hctr⟩ := h'
  cases ths with
  | nil => simp at hths
  | cons t rest =>
    obtain ⟨tid, pp, th⟩ := t
    obtain ⟨arena', stack', errno', env', proc', exec', loc'⟩ := th
    simp only [List.map_cons, List.map_nil, List.cons.injEq,
      List.map_eq_nil_iff, Prod.mk.injEq, eraseThreadEnv, p01Th,
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

theorem p01fam_frame {arena : RExpr} {tr : List trace_event} {n : Nat}
    {p : T1P} (hwf : EnvWf (p01fam arena tr n p)) :
    EnvWfFrame p.f₁ :=
  hwf p.f₁ (by
    show p.f₁ ∈ thread0Env _
    simp [thread0Env])

/-! ## The stage-0 family (harness setup writes
    `current_loc := other "RelSem.callND"`; the first eval resets) -/

@[reducible] def p01Th0 (arena : RExpr) (f₁ : Fmap sym value) :
    thread_state :=
  { arena := arena,
    stack0 := Stack_empty,
    errno := errPtr,
    current_loc := CerbLocation.other "RelSem.callND",
    exec_loc := ELoc_normal [(clampP01Sym, CerbLocation.other "RelSem.callND")],
    env := [f₁],
    current_proc_opt := some clampP01Sym }

@[reducible] def p01σ0 (f₁ : Fmap sym value)
    (tS aS eS sS : Nat) (ls : CerbMem.MemState) : driver_state :=
  { core_file := p01File,
    core_extern := create_extern_symmap p01File,
    core_state0 :=
      { thread_states := [(0, (none, p01Th0 p01ar0 f₁))],
        io := initial_io_state },
    core_run_state0 :=
      { tid_supply := tS, aid_supply := aS, excluded_supply := eS,
        sym_supply := sS,
        labeled := (initial_core_run_state_threaded 0
          (collect_labeled_continuations_NEW p01File)).labeled },
    layout_state := ls,
    concurrency_state := symInitialState symInitialPre,
    fs_state0 := CerbFS.fs_initial_state,
    trace := [],
    symbolic_assoc := fmapEmpty,
    blocked := false,
    dr_step_counter := 0 }

def p01Ctl0 : driver_state :=
  ctlOf (p01σ0 fmapEmpty 0 0 0 0 CerbMem.initialMemState)

@[reducible] def p01fam0 (p : T1P) : driver_state :=
  p01σ0 p.f₁ p.tS p.aS p.eS p.sS p.ls

@[seg_inv]
theorem p01_inv0 {σ : driver_state} (h : ctlOf σ = p01Ctl0) :
    ∃ p : T1P, σ = p01fam0 p := by
  obtain ⟨cf, ce, cs, crs, ls, ccs, fs0, tr', sa, bl, ctr'⟩ := σ
  obtain ⟨ths, io⟩ := cs
  obtain ⟨tS, aS, eS, sS, lab⟩ := crs
  have h' := h
  simp only [p01Ctl0, ctlOf, p01σ0, eraseEnvs, driver_state.mk.injEq,
    core_state.mk.injEq, core_run_state.mk.injEq] at h'
  obtain ⟨hcf, hce, ⟨hths, hio⟩, ⟨-, -, -, -, hlab⟩, -, hccs, hfs,
    htr, hsa, hbl, hctr⟩ := h'
  cases ths with
  | nil => simp at hths
  | cons t rest =>
    obtain ⟨tid, pp, th⟩ := t
    obtain ⟨arena', stack', errno', env', proc', exec', loc'⟩ := th
    simp only [List.map_cons, List.map_nil, List.cons.injEq,
      List.map_eq_nil_iff, Prod.mk.injEq, eraseThreadEnv, p01Th0,
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

theorem p01fam0_frame {p : T1P} (hwf : EnvWf (p01fam0 p)) :
    EnvWfFrame p.f₁ :=
  hwf p.f₁ (by
    show p.f₁ ∈ thread0Env _
    simp [thread0Env])

/-! ## The initial and post-globals families -/

def p01Init (seed : Nat) (ls : CerbMem.MemState) : driver_state :=
  { initial_driver_state_threaded seed p01File corpusFs with
      layout_state := ls }

@[reducible] def p01thGf (f₀ : Fmap sym value) : thread_state :=
  { arena := Expr [] (Epure (Pexpr [] () (PEval Vunit))),
    stack0 := Stack_empty,
    errno := .PV .Prov_none (.PVnull intCty),
    current_loc := CerbLocation.Loc.unknown,
    exec_loc := ELoc_globals,
    env := [f₀],
    current_proc_opt := none }

@[reducible] def p01dGσ (f₀ : Fmap sym value) (tS aS eS sS : Nat)
    (ls : CerbMem.MemState) : driver_state :=
  { core_file := p01File,
    core_extern := create_extern_symmap p01File,
    core_state0 :=
      { thread_states := [(0, (none, p01thGf f₀))],
        io := initial_io_state },
    core_run_state0 :=
      { tid_supply := tS, aid_supply := aS, excluded_supply := eS,
        sym_supply := sS,
        labeled := (initial_core_run_state_threaded 0
          (collect_labeled_continuations_NEW p01File)).labeled },
    layout_state := ls,
    concurrency_state := symInitialState symInitialPre,
    fs_state0 := CerbFS.fs_initial_state,
    trace := [],
    symbolic_assoc := fmapEmpty,
    blocked := false,
    dr_step_counter := 0 }

def p01dGCtl : driver_state :=
  ctlOf (p01dGσ fmapEmpty 0 0 0 0 CerbMem.initialMemState)

@[reducible] def p01dGfam (p : RelSem.T1.DGP) : driver_state :=
  p01dGσ p.f₀ p.tS p.aS p.eS p.sS p.ls

theorem p01dG_inv {σ : driver_state} (h : ctlOf σ = p01dGCtl) :
    ∃ p : RelSem.T1.DGP, σ = p01dGfam p := by
  obtain ⟨cf, ce, cs, crs, ls, ccs, fs0, tr', sa, bl, ctr'⟩ := σ
  obtain ⟨ths, io⟩ := cs
  obtain ⟨tS, aS, eS, sS, lab⟩ := crs
  have h' := h
  simp only [p01dGCtl, ctlOf, p01dGσ, eraseEnvs, driver_state.mk.injEq,
    core_state.mk.injEq, core_run_state.mk.injEq] at h'
  obtain ⟨hcf, hce, ⟨hths, hio⟩, ⟨-, -, -, -, hlab⟩, -, hccs, hfs,
    htr, hsa, hbl, hctr⟩ := h'
  cases ths with
  | nil => simp at hths
  | cons t rest =>
    obtain ⟨tid, pp, th⟩ := t
    obtain ⟨arena', stack', errno', env', proc', exec', loc'⟩ := th
    simp only [List.map_cons, List.map_nil, List.cons.injEq,
      List.map_eq_nil_iff, Prod.mk.injEq, eraseThreadEnv, p01thGf,
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

theorem p01Init_inv {σ : driver_state} {seed : Nat}
    (h : ctlOf σ = ctlOf (p01Init 0 CerbMem.initialMemState))
    (hs : suppliesOf σ
      = suppliesOf (p01Init seed CerbMem.initialMemState)) :
    σ = p01Init seed σ.layout_state := by
  obtain ⟨cf, ce, cs, crs, ls, ccs, fs0, tr', sa, bl, ctr'⟩ := σ
  obtain ⟨ths, io⟩ := cs
  obtain ⟨tS, aS, eS, sS, lab⟩ := crs
  have h' := h
  simp only [p01Init, ctlOf, eraseEnvs, driver_state.mk.injEq,
    core_state.mk.injEq, core_run_state.mk.injEq] at h'
  obtain ⟨hcf, hce, ⟨hths, hio⟩, ⟨-, -, -, -, hlab⟩, -, hccs, hfs,
    htr, hsa, hbl, hctr⟩ := h'
  have hs' := hs
  simp only [suppliesOf, p01Init, Supplies.mk.injEq] at hs'
  obtain ⟨hts, has, hes, hss⟩ := hs'
  cases ths with
  | cons t rest =>
    rw [show (initial_driver_state_threaded 0 p01File
        corpusFs).core_state0.thread_states
      = ([] : List (Nat × (Option thread_id × thread_state)))
      from rfl] at hths
    simp at hths
  | nil =>
    subst hcf hce hccs hfs htr hsa hbl hctr hio hlab hts has hes hss
    rfl

/-! ## The caller-protocol stage laws (T1 k-law mirrors) -/

theorem p01k1_fam (seed : Nat) (ls : CerbMem.MemState) :
    app (driver_globals p01File.tagDefs false p01File)
        (p01Init seed ls)
      = (NDactive 0, p01dGσ fmapEmpty 1 0 0 seed ls) := rfl

theorem p01k3_any (σ : driver_state) :
    app (resolveFunSym p01File "clamp0") σ
      = (NDactive clampP01Sym, σ) := rfl

theorem p01k4_any (σ : driver_state) :
    app (lookupFunBody p01File clampP01Sym) σ
      = (NDactive ([(symX, BTy_object OTy_pointer)], p01ar0), σ) := rfl

theorem p01k5_any (σ : driver_state) :
    app (lookupParamTys p01File clampP01Sym) σ
      = (NDactive [signed_int], σ) := rfl

/-! ## Bridge-spelling anchors -/

theorem p01_init_ctl_eq (seed : Nat) :
    ctlOf (initial_driver_state_threaded seed p01File corpusFs)
      = ctlOf (p01Init 0 CerbMem.initialMemState) := rfl

theorem p01_init_sup_eq (seed : Nat) :
    suppliesOf (initial_driver_state_threaded seed p01File corpusFs)
      = suppliesOf (p01Init seed CerbMem.initialMemState) := rfl

theorem p01_init_mrest_eq (seed : Nat) :
    memRestOf (initial_driver_state_threaded seed p01File corpusFs)
      = mr0 := rfl


/-! ## The inject/errno memory-stage laws (k6/k8 at p01File) -/

theorem p01k6_fam (x : Int) (σ : driver_state)
    (hmr : memRestOf σ = mr0) (hinv : MemInv σ.layout_state) :
    app (injectArgs p01File.tagDefs 0
          [(symX, BTy_object OTy_pointer)] [signed_int] [intValue x]) σ
      = (NDactive [(symX, xPtrV)],
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
theorem p01k8_fam (x : Int) (σ : driver_state)
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


/-! ## Terminal arenas (the value states the done rounds read) -/

def p01arT26 : RExpr :=
  (Expr aU (Epure (Pexpr [] () (PEval (loadedV 0)))))

/-! ## Bind patterns + the env-write spellings -/

def patA534 : generic_pattern sym :=
  Pattern aU (CaseBase ((some symA534), BTy_object OTy_pointer))
def patT3536 : generic_pattern sym :=
  Pattern aU (CaseCtor Ctuple
    [Pattern aU (CaseBase ((some symA535), BTy_loaded OTy_integer)),
     Pattern aU (CaseBase ((some symA536), BTy_loaded OTy_integer))])
def patT2930 : generic_pattern sym :=
  Pattern aU (CaseCtor Ctuple
    [Pattern aU (CaseBase ((some symA529), BTy_loaded OTy_integer)),
     Pattern aU (CaseBase ((some symA530), BTy_loaded OTy_integer))])
def patA527 : generic_pattern sym :=
  Pattern aU (CaseBase ((some symA527), BTy_loaded OTy_integer))
def patA526 : generic_pattern sym :=
  Pattern aU (CaseBase ((some symA526), BTy_boolean))
def patA540 : generic_pattern sym :=
  Pattern aU (CaseBase ((some symA540), BTy_loaded OTy_integer))
def patA542 : generic_pattern sym :=
  Pattern aU (CaseBase ((some symA542), BTy_loaded OTy_integer))
def patA541 : generic_pattern sym :=
  Pattern aU (CaseBase ((some symA541), BTy_object OTy_pointer))

theorem update_env_aux_a534 (f : Fmap sym value) :
    update_env_aux patA534 xPtrV f
      = @fmapAddBy sym value Lem_Map.instBEqOfMapKeyType
          (@Lem_Map.mapKeyCompare sym _) symA534 xPtrV f := rfl

/-- The tuple bind (a_535, a_536): the foldr inserts RIGHT-then-LEFT. -/
theorem update_env_aux_3536 (x : Int) (f : Fmap sym value) :
    update_env_aux patT3536 (Vtuple [loadedV x, loadedV 0]) f
      = @fmapAddBy sym value Lem_Map.instBEqOfMapKeyType
          (@Lem_Map.mapKeyCompare sym _) symA535 (loadedV x)
          (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType
            (@Lem_Map.mapKeyCompare sym _) symA536 (loadedV 0) f) := rfl

theorem update_env_aux_2930 (c : Int) (f : Fmap sym value) :
    update_env_aux patT2930 (Vtuple [loadedV c, loadedV 0]) f
      = @fmapAddBy sym value Lem_Map.instBEqOfMapKeyType
          (@Lem_Map.mapKeyCompare sym _) symA529 (loadedV c)
          (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType
            (@Lem_Map.mapKeyCompare sym _) symA530 (loadedV 0) f) := rfl

theorem update_env_aux_a527 (c : Int) (f : Fmap sym value) :
    update_env_aux patA527 (loadedV c) f
      = @fmapAddBy sym value Lem_Map.instBEqOfMapKeyType
          (@Lem_Map.mapKeyCompare sym _) symA527 (loadedV c) f := rfl

theorem update_env_aux_a526 (vb : value) (f : Fmap sym value) :
    update_env_aux patA526 vb f
      = @fmapAddBy sym value Lem_Map.instBEqOfMapKeyType
          (@Lem_Map.mapKeyCompare sym _) symA526 vb f := rfl

theorem update_env_aux_a540 (f : Fmap sym value) :
    update_env_aux patA540 (loadedV 0) f
      = @fmapAddBy sym value Lem_Map.instBEqOfMapKeyType
          (@Lem_Map.mapKeyCompare sym _) symA540 (loadedV 0) f := rfl

/-! ## The rounds — shared prefix (0-9) -/

open RelSem.T1 (meLoad)

/-- R0: the inner unseq's specified-zero operand evaluates (closed;
    STAGE-0 input — the eval resets current_loc). -/
@[seg_round]
theorem p01r0 (p : T1P) :
    app (dnmsRoundM p01File.tagDefs 0) (p01fam0 p)
      = (NDactive (Sum.inl NOWAKEUP), p01fam p01ar1 [] 1 p) := by
  refine dnmsRoundM_adv rfl ?_
  exact (advance_runstate_eval (th' := p01Th p01ar1 p.f₁)
    (rs' := (p01fam0 p).core_run_state0) rfl).trans rfl

/-- R1: the outer unseq's specified-zero operand evaluates (closed). -/
@[seg_round]
theorem p01r1 (p : T1P) :
    app (dnmsRoundM p01File.tagDefs 0) (p01fam p01ar1 [] 1 p)
      = (NDactive (Sum.inl NOWAKEUP), p01fam p01ar2 [] 2 p) := by
  refine dnmsRoundM_adv rfl ?_
  exact (advance_runstate_eval (th' := p01Th p01ar2 p.f₁)
    (rs' := (p01fam p01ar1 [] 1 p).core_run_state0) rfl).trans rfl

/-- R2: the Ewseq's pure operand evaluates — reads x's cell. -/
@[seg_round]
theorem p01r2 (p : T1P)
    (hwf : EnvWfFrame p.f₁)
    (hx : envLookup (p01fam p01ar2 [] 2 p) symX = some xPtrV) :
    app (dnmsRoundM p01File.tagDefs 0) (p01fam p01ar2 [] 2 p)
      = (NDactive (Sum.inl NOWAKEUP), p01fam p01ar3 [] 3 p) := by
  refine dnmsRoundM_adv rfl ?_
  refine (advance_runstate_eval (th' := p01Th p01ar3 p.f₁)
    (rs' := (p01fam p01ar2 [] 2 p).core_run_state0) ?_).trans ?_
  · show stExceptUndef_bind _ _ _ = _
    refine (stub_defined (z := Expr aU (Epure (Pexpr [] () (PEval xPtrV))))
      (st' := (p01fam p01ar2 [] 2 p).core_run_state0) ?_).trans rfl
    show stExceptUndef_bind _ _ _ = _
    refine (stub_defined (z := xPtrV)
      (st' := (p01fam p01ar2 [] 2 p).core_run_state0) ?_).trans rfl
    show stExceptUndef_bind _ _ _ = _
    refine (stub_defined (z := Sum.inr xPtrV)
      (st' := (p01fam p01ar2 [] 2 p).core_run_state0) ?_).trans ?_
    · show runEU (eval_pexpr_aux2 p01File.tagDefs
          CerbLocation.Loc.unknown
          (some (CerbLocation.other "RelSem.callND"))
          (create_extern_symmap p01File) [p.f₁] (some p.ls) p01File
          (Pexpr aU () (PEsym symX))) _ = _
      rw [aux2_sym_hit (a := aU) (a' := []) (z := symX) (v := xPtrV)
        (env := [p.f₁]) rfl rfl
        (show lookup_env symX [p.f₁] = some xPtrV from hx)]
      rfl
    · rfl
  · rfl

/-- R3: the Ewseq binds a_534 (BIRTH). -/
@[seg_round]
theorem p01r3 (p : T1P) :
    app (dnmsRoundM p01File.tagDefs 0) (p01fam p01ar3 [] 3 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p01fam p01ar4 [] 4
           { p with f₁ := update_env_aux patA534 xPtrV p.f₁ }) := by
  refine dnmsRoundM_adv rfl ?_
  exact (advance_tau_misc).trans rfl

/-- R4: the Load's operands evaluate — reads a_534's cell. -/
@[seg_round]
theorem p01r4 (p : T1P)
    (ha : envLookup (p01fam p01ar4 [] 4 p) symA534 = some xPtrV) :
    app (dnmsRoundM p01File.tagDefs 0) (p01fam p01ar4 [] 4 p)
      = (NDactive (Sum.inl NOWAKEUP), p01fam p01ar5 [] 5 p) := by
  refine dnmsRoundM_adv rfl ?_
  refine (advance_runstate_eval (th' := p01Th p01ar5 p.f₁)
    (rs' := (p01fam p01ar4 [] 4 p).core_run_state0) ?_).trans ?_
  · show stExceptUndef_bind _ _ _ = _
    refine (stub_defined
      (z := Action CerbLocation.Loc.unknown empty_annotation
        (Load0 (mk_value_pe (Vctype intCty)) (mk_value_pe xPtrV) NA))
      (st' := (p01fam p01ar4 [] 4 p).core_run_state0) ?_).trans rfl
    show stExceptUndef_bind _ _ _ = _
    refine (stub_defined (z := Vctype intCty)
      (st' := (p01fam p01ar4 [] 4 p).core_run_state0) ?_).trans ?_
    · rfl
    show stExceptUndef_bind _ _ _ = _
    refine (stub_defined (z := xPtrV)
      (st' := (p01fam p01ar4 [] 4 p).core_run_state0) ?_).trans rfl
    show stExceptUndef_bind _ _ _ = _
    refine (stub_defined (z := Sum.inr xPtrV)
      (st' := (p01fam p01ar4 [] 4 p).core_run_state0) ?_).trans ?_
    · show runEU (eval_pexpr_aux2 p01File.tagDefs
          CerbLocation.Loc.unknown
          (some (CerbLocation.other "RelSem.callND"))
          (create_extern_symmap p01File) [p.f₁] (some p.ls) p01File
          (Pexpr aU () (PEsym symA534))) _ = _
      rw [aux2_sym_hit (a := aU) (a' := []) (z := symA534) (v := xPtrV)
        (env := [p.f₁]) rfl rfl
        (show lookup_env symA534 [p.f₁] = some xPtrV from ha)]
      rfl
    · rfl
  · rfl

/-- R5: THE LOAD — aid drawn, x's bytes recombine to exactly x,
    ME_load traced (step counter does not move). -/
@[seg_round]
theorem p01r5 (x : Int) (p : T1P)
    (hget : p.ls.allocations.get? 0 = some allocX)
    (hbytes : ∀ i : Nat, (hi : i < (xBytes x).length) →
      p.ls.bytemap.get? (xAddr + (i : Int)) = some (xBytes x)[i])
    (hlum : p.ls.lastUsedUnionMembers = [])
    (hfpm : p.ls.funptrmap = [])
    (hinv : MemInv p.ls)
    (h1 : -2147483648 ≤ x) (h2 : x ≤ 2147483647) :
    app (dnmsRoundM p01File.tagDefs 0) (p01fam p01ar5 [] 5 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p01fam (p01ar6 x) [meLoad x] 5 { p with aS := p.aS + 1 })
      := by
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

/-- R6: the inner Eunseq packs the tuple (tau). -/
@[seg_round]
theorem p01r6 (x : Int) (p : T1P) :
    app (dnmsRoundM p01File.tagDefs 0)
        (p01fam (p01ar6 x) [meLoad x] 5 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p01fam (p01ar7 x) [meLoad x] 6 p) := by
  refine dnmsRoundM_adv rfl ?_
  exact (advance_tau_misc).trans rfl

/-- R7: the Ewseq tuple-binds (a_535, a_536) (BIRTH2). -/
@[seg_round]
theorem p01r7 (x : Int) (p : T1P) :
    app (dnmsRoundM p01File.tagDefs 0)
        (p01fam (p01ar7 x) [meLoad x] 6 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p01fam p01ar8 [meLoad x] 7
           { p with f₁ := update_env_aux patT3536 (Vtuple [loadedV x, loadedV 0]) p.f₁ }) := by
  refine dnmsRoundM_adv rfl ?_
  exact (advance_tau_misc).trans rfl

/-- The first expr-level Ecase's arms (the a_537/a_538 compare). -/
def p01case1Arms :
    List (generic_pattern sym × RExpr) :=
  [(Pattern aU (CaseCtor Ctuple
      [Pattern aU (CaseCtor Cspecified
        [Pattern aU (CaseBase (some symA537, BTy_object OTy_integer))]),
       Pattern aU (CaseCtor Cspecified
        [Pattern aU (CaseBase (some symA538, BTy_object OTy_integer))])]),
    Expr aU (Epure (Pexpr aU () (PEif
      (Pexpr aU () (PEop OpLt
        (Pexpr aU () (PEcall (Sym symConvInt)
          [Pexpr aU () (PEval (Vctype intCty)),
           Pexpr aU () (PEsym symA537)]))
        (Pexpr aU () (PEcall (Sym symConvInt)
          [Pexpr aU () (PEval (Vctype intCty)),
           Pexpr aU () (PEsym symA538)]))))
      (Pexpr aU () (PEctor Cspecified
        [Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none 1))))]))
      (Pexpr aU () (PEctor Cspecified
        [Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none 0))))]))))
    )),
   (Pattern aU (CaseBase (none,
      BTy_tuple [BTy_loaded OTy_integer, BTy_loaded OTy_integer])),
    Expr aU (Epure (Pexpr aU () (PEctor Cunspecified
      [Pexpr aU () (PEval (Vctype intCty))]))))]

/-- The R8 scrutinee's whole-loop evaluation (tuple of two cell
    reads; ∀-env with the two facts fed). -/
theorem p01ctor2_eval (x : Int) (env : List (Fmap sym value))
    (memo : Option CerbMem.MemState)
    (ha5 : lookup_env symA535 env = some (loadedV x))
    (ha6 : lookup_env symA536 env = some (loadedV 0)) :
    eval_pexpr_aux2 p01File.tagDefs CerbLocation.Loc.unknown
        (some (CerbLocation.other "RelSem.callND"))
        (create_extern_symmap p01File) env memo p01File
        (Pexpr aU () (PEctor Ctuple
          [Pexpr aU () (PEsym symA535),
           Pexpr aU () (PEsym symA536)]))
      = Result (Defined (Sum.inr (Vtuple [loadedV x, loadedV 0]))) :=
  aux2_done 999999 _ _ _ _ _ _ _
    (show pull_constrained 0 (Pexpr aU () (PEctor Ctuple
        [Pexpr aU () (PEsym symA535),
         Pexpr aU () (PEsym symA536)]))
      = Pexpr [] () (PEctor Ctuple
        [Pexpr aU () (PEsym symA535),
         Pexpr aU () (PEsym symA536)]) from rfl)
    (by intro a xs h; simp at h)
    (se_ctor_tuple
      (pes' := [Pexpr [] () (PEval (loadedV x)),
                Pexpr [] () (PEval (loadedV 0))])
      (cvals := [loadedV x, loadedV 0])
      (eumapM_cons (se_sym_hit (fuel := 999998) rfl ha5)
        (eumapM_cons (se_sym_hit (fuel := 999998) rfl ha6)
          eumapM_nil)) rfl)
    (by rfl)

/-- R8: the Ecase scrutinee evaluates — reads a_535's and a_536's
    cells (the tuple packs). -/
@[seg_round]
theorem p01r8 (x : Int) (p : T1P)
    (ha5 : envLookup (p01fam p01ar8 [meLoad x] 7 p) symA535
      = some (loadedV x))
    (ha6 : envLookup (p01fam p01ar8 [meLoad x] 7 p) symA536
      = some (loadedV 0)) :
    app (dnmsRoundM p01File.tagDefs 0) (p01fam p01ar8 [meLoad x] 7 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p01fam (p01ar9 x) [meLoad x] 8 p) := by
  refine dnmsRoundM_adv rfl ?_
  refine (advance_runstate_eval (th' := p01Th (p01ar9 x) p.f₁)
    (rs' := (p01fam p01ar8 [meLoad x] 7 p).core_run_state0) ?_).trans ?_
  · show stExceptUndef_bind _ _ _ = _
    refine (stub_defined
      (z := Expr aU (Ecase
        (Pexpr [] () (PEval (Vtuple [loadedV x, loadedV 0])))
        p01case1Arms))
      (st' := (p01fam p01ar8 [meLoad x] 7 p).core_run_state0) ?_).trans rfl
    show stExceptUndef_bind _ _ _ = _
    refine (stub_defined
      (z := (Pexpr [] () (PEval (Vtuple [loadedV x, loadedV 0]))
        : generic_pexpr Unit sym))
      (st' := (p01fam p01ar8 [meLoad x] 7 p).core_run_state0) ?_).trans rfl
    show stExceptUndef_bind _ _ _ = _
    refine (stub_defined
      (z := Sum.inr (Vtuple [loadedV x, loadedV 0]))
      (st' := (p01fam p01ar8 [meLoad x] 7 p).core_run_state0) ?_).trans ?_
    · show runEU (eval_pexpr_aux2 p01File.tagDefs
          CerbLocation.Loc.unknown
          (some (CerbLocation.other "RelSem.callND"))
          (create_extern_symmap p01File) [p.f₁] (some p.ls) p01File
          (Pexpr aU () (PEctor Ctuple
            [Pexpr aU () (PEsym symA535),
             Pexpr aU () (PEsym symA536)]))) _ = _
      rw [p01ctor2_eval x [p.f₁] (some p.ls)
        (show lookup_env symA535 [p.f₁] = some (loadedV x) from ha5)
        (show lookup_env symA536 [p.f₁] = some (loadedV 0) from ha6)]
      rfl
    · rfl
  · rfl

/-- R9: the Ecase picks the tuple arm and substitutes (tau). -/
@[seg_round]
theorem p01r9 (x : Int) (p : T1P) :
    app (dnmsRoundM p01File.tagDefs 0)
        (p01fam (p01ar9 x) [meLoad x] 8 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p01fam (p01ar10 x) [meLoad x] 9 p) := by
  refine dnmsRoundM_adv rfl ?_
  exact (advance_tau_misc).trans rfl

/-- R11: the inner Eunseq packs (tau; branch-value abstract). -/
@[seg_round]
theorem p01r11 (c : Int) (p : T1P) {tr : List trace_event} :
    app (dnmsRoundM p01File.tagDefs 0)
        (p01fam (p01ar11 c) tr 10 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p01fam (p01ar12 c) tr 11 p) := by
  refine dnmsRoundM_adv rfl ?_
  exact (advance_tau_misc).trans rfl

/-- R12: the Ewseq tuple-binds (a_529, a_530) (BIRTH2). -/
@[seg_round]
theorem p01r12 (c : Int) (p : T1P) {tr : List trace_event} :
    app (dnmsRoundM p01File.tagDefs 0)
        (p01fam (p01ar12 c) tr 11 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p01fam p01ar13 tr 12
           { p with f₁ := update_env_aux patT2930 (Vtuple [loadedV c, loadedV 0]) p.f₁ }) := by
  refine dnmsRoundM_adv rfl ?_
  exact (advance_tau_misc).trans rfl

/-- R14: the Ebound wrapper strips (tau). -/
@[seg_round]
theorem p01r14 (c : Int) (p : T1P) {tr : List trace_event} :
    app (dnmsRoundM p01File.tagDefs 0)
        (p01fam (p01ar14 c) tr 13 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p01fam (p01ar15 c) tr 14 p) := by
  refine dnmsRoundM_adv rfl ?_
  exact (advance_tau_misc).trans rfl

/-- R15: the Esseq binds a_527 (BIRTH). -/
@[seg_round]
theorem p01r15 (c : Int) (p : T1P) {tr : List trace_event} :
    app (dnmsRoundM p01File.tagDefs 0)
        (p01fam (p01ar15 c) tr 14 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p01fam p01ar16 tr 15
           { p with f₁ := update_env_aux patA527 (loadedV c) p.f₁ }) := by
  refine dnmsRoundM_adv rfl ?_
  exact (advance_tau_misc).trans rfl

/-- The second expr-level Ecase's arms (the a_528 guard build). -/
def p01case2Arms :
    List (generic_pattern sym × RExpr) :=
  [(Pattern aU (CaseCtor Cspecified
      [Pattern aU (CaseBase ((some symA528), BTy_object OTy_integer))]),
    Expr aU (Epure (Pexpr aU () (PEif
      (Pexpr aU () (PEnot (Pexpr aU () (PEop OpEq
        (Pexpr aU () (PEsym symA528))
        (Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none 1)))))))))
      (Pexpr aU () (PEval Vtrue)) (Pexpr aU () (PEval Vfalse)))))),
   (Pattern aU (CaseCtor Cunspecified
      [Pattern aU (CaseBase (none, BTy_ctype))]),
    Expr aU (End [Expr aU (Epure (Pexpr aU () (PEval Vtrue))),
                  Expr aU (Epure (Pexpr aU () (PEval Vfalse)))]))]

/-- R16: the second Ecase's scrutinee evaluates — reads a_527's cell
    (value abstract; both branch sides share this equation). -/
@[seg_round]
theorem p01r16 (c : Int) (p : T1P) {tr : List trace_event}
    (ha : envLookup (p01fam p01ar16 tr 15 p) symA527
      = some (loadedV c)) :
    app (dnmsRoundM p01File.tagDefs 0) (p01fam p01ar16 tr 15 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p01fam (p01ar17 c) tr 16 p) := by
  refine dnmsRoundM_adv rfl ?_
  refine (advance_runstate_eval (th' := p01Th (p01ar17 c) p.f₁)
    (rs' := (p01fam p01ar16 tr 15 p).core_run_state0) ?_).trans ?_
  · show stExceptUndef_bind _ _ _ = _
    refine (stub_defined
      (z := Expr aU (Ecase
        (Pexpr [] () (PEval (loadedV c))) p01case2Arms))
      (st' := (p01fam p01ar16 tr 15 p).core_run_state0) ?_).trans rfl
    show stExceptUndef_bind _ _ _ = _
    refine (stub_defined
      (z := (Pexpr [] () (PEval (loadedV c)) : generic_pexpr Unit sym))
      (st' := (p01fam p01ar16 tr 15 p).core_run_state0) ?_).trans rfl
    show stExceptUndef_bind _ _ _ = _
    refine (stub_defined (z := Sum.inr (loadedV c))
      (st' := (p01fam p01ar16 tr 15 p).core_run_state0) ?_).trans ?_
    · show runEU (eval_pexpr_aux2 p01File.tagDefs
          CerbLocation.Loc.unknown
          (some (CerbLocation.other "RelSem.callND"))
          (create_extern_symmap p01File) [p.f₁] (some p.ls) p01File
          (Pexpr aU () (PEsym symA527))) _ = _
      rw [aux2_sym_hit (a := aU) (a' := []) (z := symA527)
        (v := loadedV c) (env := [p.f₁]) rfl rfl
        (show lookup_env symA527 [p.f₁] = some (loadedV c) from ha)]
      rfl
    · rfl
  · rfl

/-- R17: the second Ecase picks the specified arm, substituting the
    payload for a_528 (tau; value abstract — the loaded shape is
    constructor-headed at any `c`). -/
@[seg_round]
theorem p01r17 (c : Int) (p : T1P) {tr : List trace_event} :
    app (dnmsRoundM p01File.tagDefs 0)
        (p01fam (p01ar17 c) tr 16 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p01fam (p01ar18 c) tr 17 p) := by
  refine dnmsRoundM_adv rfl ?_
  exact (advance_tau_misc).trans rfl

/-- R19: the Esseq binds the guard cell a_526 (BIRTH; vb abstract). -/
@[seg_round]
theorem p01r19 (vb : value) (p : T1P) {tr : List trace_event} :
    app (dnmsRoundM p01File.tagDefs 0)
        (p01fam (p01ar19 vb) tr 18 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p01fam p01ar20 tr 19
           { p with f₁ := update_env_aux patA526 vb p.f₁ }) := by
  refine dnmsRoundM_adv rfl ?_
  exact (advance_tau_misc).trans rfl

/-! ## The R10 compare chain (conv_int ×2 + OpLt + the branch pick;
    the z-chain from the aux2 probe — steps A/B are x-INDEPENDENT
    structure (rfl), step C carries the arithmetic verdicts) -/

def symIsRepr : sym :=
  Symbol "" 7764867060197914680 (SD_Id "is_representable_integer")
def symWrapI : sym := Symbol "" 14671517598387306907 (SD_Id "wrapI")

def z10a (x : Int) : generic_pexpr Unit sym :=
  (Pexpr [] () (PEif (Pexpr aU () (PEop OpLt (Pexpr aU () (PEcall (Sym symConvInt) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (x))))))])) (Pexpr aU () (PEcall (Sym symConvInt) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (0))))))])))) (Pexpr aU () (PEctor Cspecified [(Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (1))))))])) (Pexpr aU () (PEctor Cspecified [(Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (0))))))]))))

def z10b (x : Int) : generic_pexpr Unit sym :=
  (Pexpr [] () (PEif (Pexpr [] () (PEop OpLt (Pexpr [] () (PEif (Pexpr aU () (PEop OpEq (Pexpr aU () (PEval (Vctype intCty))) (Pexpr aU () (PEval (Vctype (Ctype [] (Basic (Integer Bool0)))))))) (Pexpr aU () (PEif (Pexpr aU () (PEop OpEq (Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (x)))))) (Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (0)))))))) (Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (0)))))) (Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (1)))))))) (Pexpr aU () (PEif (Pexpr aU () (PEcall (Sym symIsRepr) [(Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (x)))))), (Pexpr aU () (PEval (Vctype intCty)))])) (Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (x)))))) (Pexpr aU () (PEif (Pexpr aU () (PEis_unsigned (Pexpr aU () (PEval (Vctype intCty))))) (Pexpr aU () (PEcall (Sym symWrapI) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (x))))))])) (Pexpr aU () (PEcall (Impl Integer__conv_nonrepresentable_signed_integer) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (x))))))])))))))) (Pexpr [] () (PEif (Pexpr aU () (PEop OpEq (Pexpr aU () (PEval (Vctype intCty))) (Pexpr aU () (PEval (Vctype (Ctype [] (Basic (Integer Bool0)))))))) (Pexpr aU () (PEif (Pexpr aU () (PEop OpEq (Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (0)))))) (Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (0)))))))) (Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (0)))))) (Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (1)))))))) (Pexpr aU () (PEif (Pexpr aU () (PEcall (Sym symIsRepr) [(Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (0)))))), (Pexpr aU () (PEval (Vctype intCty)))])) (Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (0)))))) (Pexpr aU () (PEif (Pexpr aU () (PEis_unsigned (Pexpr aU () (PEval (Vctype intCty))))) (Pexpr aU () (PEcall (Sym symWrapI) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (0))))))])) (Pexpr aU () (PEcall (Impl Integer__conv_nonrepresentable_signed_integer) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (0))))))])))))))))) (Pexpr aU () (PEctor Cspecified [(Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (1))))))])) (Pexpr aU () (PEctor Cspecified [(Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (0))))))]))))

def z10c (x : Int) : generic_pexpr Unit sym :=
  (Pexpr [] () (PEif (Pexpr [] () (PEop OpLt (Pexpr [] () (PEif (Pexpr [] () (PEop OpAnd (Pexpr [] () (PEop OpLe (Pexpr [] () (PEctor Civmin [(Pexpr aU () (PEval (Vctype intCty)))])) (Pexpr [] () (PEval (Vobject (OVinteger (.IV .Prov_none (x)))))))) (Pexpr [] () (PEop OpLe (Pexpr [] () (PEval (Vobject (OVinteger (.IV .Prov_none (x)))))) (Pexpr [] () (PEctor Civmax [(Pexpr aU () (PEval (Vctype intCty)))])))))) (Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (x)))))) (Pexpr aU () (PEif (Pexpr aU () (PEis_unsigned (Pexpr aU () (PEval (Vctype intCty))))) (Pexpr aU () (PEcall (Sym symWrapI) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (x))))))])) (Pexpr aU () (PEcall (Impl Integer__conv_nonrepresentable_signed_integer) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (x))))))])))))) (Pexpr [] () (PEif (Pexpr [] () (PEop OpAnd (Pexpr [] () (PEop OpLe (Pexpr [] () (PEctor Civmin [(Pexpr aU () (PEval (Vctype intCty)))])) (Pexpr [] () (PEval (Vobject (OVinteger (.IV .Prov_none (0)))))))) (Pexpr [] () (PEop OpLe (Pexpr [] () (PEval (Vobject (OVinteger (.IV .Prov_none (0)))))) (Pexpr [] () (PEctor Civmax [(Pexpr aU () (PEval (Vctype intCty)))])))))) (Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (0)))))) (Pexpr aU () (PEif (Pexpr aU () (PEis_unsigned (Pexpr aU () (PEval (Vctype intCty))))) (Pexpr aU () (PEcall (Sym symWrapI) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (0))))))])) (Pexpr aU () (PEcall (Impl Integer__conv_nonrepresentable_signed_integer) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (0))))))])))))))) (Pexpr aU () (PEctor Cspecified [(Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (1))))))])) (Pexpr aU () (PEctor Cspecified [(Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (0))))))]))))

/-- Step A: the two conv_int calls inline (x-independent; rfl). -/
theorem s10a (x : Int) (env : List (Fmap sym value))
    (memo : Option CerbMem.MemState) :
    step_eval_pexpr p01File.tagDefs 0 CerbLocation.Loc.unknown
      (some (CerbLocation.other "RelSem.callND"))
      (create_extern_symmap p01File) env memo p01File false (z10a x)
      = Result (Defined (z10b x)) := rfl

/-- Step B: the bool-ctype test + is_representable inline (rfl). -/
theorem s10b (x : Int) (env : List (Fmap sym value))
    (memo : Option CerbMem.MemState) :
    step_eval_pexpr p01File.tagDefs 0 CerbLocation.Loc.unknown
      (some (CerbLocation.other "RelSem.callND"))
      (create_extern_symmap p01File) env memo p01File false (z10b x)
      = Result (Defined (z10c x)) := rfl

/-! ### The R10 verdict sub-evals (concrete fuels along the descent;
    the range/compare decides enter via the s4-style harm rewrites) -/

def xObjV (x : Int) : value := Vobject (OVinteger (.IV .Prov_none x))

def le1pe (x : Int) : generic_pexpr Unit sym :=
  Pexpr [] () (PEop OpLe
    (Pexpr [] () (PEctor Civmin [Pexpr aU () (PEval (Vctype intCty))]))
    (Pexpr [] () (PEval (xObjV x))))

def le2pe (x : Int) : generic_pexpr Unit sym :=
  Pexpr [] () (PEop OpLe
    (Pexpr [] () (PEval (xObjV x)))
    (Pexpr [] () (PEctor Civmax [Pexpr aU () (PEval (Vctype intCty))])))

theorem sLe1 (x : Int) (h1 : -2147483648 ≤ x)
    (env : List (Fmap sym value)) (memo : Option CerbMem.MemState) :
    step_eval_pexpr_lemFuel 999996 p01File.tagDefs 4
      CerbLocation.Loc.unknown
      (some (CerbLocation.other "RelSem.callND"))
      (create_extern_symmap p01File) env memo p01File false (le1pe x)
      = Result (Defined (Pexpr [] () (PEval Vtrue))) := by
  have hd1 : decide ((-2147483648:Int) ≤ x) = true := decide_eq_true h1
  have harm : (if (decide ((-2147483648:Int) ≤ x)) = true
      then Vtrue else Vfalse) = Vtrue := by rw [hd1]; simp
  conv => rhs; rw [← harm]
  rfl

theorem sLe2 (x : Int) (h2 : x ≤ 2147483647)
    (env : List (Fmap sym value)) (memo : Option CerbMem.MemState) :
    step_eval_pexpr_lemFuel 999996 p01File.tagDefs 4
      CerbLocation.Loc.unknown
      (some (CerbLocation.other "RelSem.callND"))
      (create_extern_symmap p01File) env memo p01File false (le2pe x)
      = Result (Defined (Pexpr [] () (PEval Vtrue))) := by
  have hd2 : decide (x ≤ (2147483647:Int)) = true := decide_eq_true h2
  have harm : (if (decide (x ≤ (2147483647:Int))) = true
      then Vtrue else Vfalse) = Vtrue := by rw [hd2]; simp
  conv => rhs; rw [← harm]
  rfl

def and12pe (x : Int) : generic_pexpr Unit sym :=
  Pexpr [] () (PEop OpAnd (le1pe x) (le2pe x))

theorem sAnd1 (x : Int) (h1 : -2147483648 ≤ x) (h2 : x ≤ 2147483647)
    (env : List (Fmap sym value)) (memo : Option CerbMem.MemState) :
    step_eval_pexpr_lemFuel 999997 p01File.tagDefs 3
      CerbLocation.Loc.unknown
      (some (CerbLocation.other "RelSem.callND"))
      (create_extern_symmap p01File) env memo p01File false (and12pe x)
      = Result (Defined (Pexpr [] () (PEval Vtrue))) := by
  change exception_undef_bind _ _ = _
  refine (eubind_defined
    (z := (PEval Vtrue : generic_pexpr_ Unit sym)) ?hop).trans rfl
  case hop =>
    change exception_undef_bind _ _ = _
    refine (eubind_defined (sLe1 x h1 env memo)).trans ?_
    change exception_undef_bind _ _ = _
    refine (eubind_defined (sLe2 x h2 env memo)).trans ?_
    rfl

/-- The then-side conv operand: `if in-range then x` (the range check
    discharges; PEval x-object out). -/
def if1pe (x : Int) : generic_pexpr Unit sym :=
  Pexpr [] () (PEif (and12pe x)
    (Pexpr aU () (PEval (xObjV x)))
    (Pexpr aU () (PEif
      (Pexpr aU () (PEis_unsigned (Pexpr aU () (PEval (Vctype intCty)))))
      (Pexpr aU () (PEcall (Sym symWrapI)
        [Pexpr aU () (PEval (Vctype intCty)),
         Pexpr aU () (PEval (xObjV x))]))
      (Pexpr aU () (PEcall (Impl Integer__conv_nonrepresentable_signed_integer)
        [Pexpr aU () (PEval (Vctype intCty)),
         Pexpr aU () (PEval (xObjV x))])))))

theorem sIf1 (x : Int) (h1 : -2147483648 ≤ x) (h2 : x ≤ 2147483647)
    (env : List (Fmap sym value)) (memo : Option CerbMem.MemState) :
    step_eval_pexpr_lemFuel 999998 p01File.tagDefs 2
      CerbLocation.Loc.unknown
      (some (CerbLocation.other "RelSem.callND"))
      (create_extern_symmap p01File) env memo p01File false (if1pe x)
      = Result (Defined (Pexpr [] () (PEval (xObjV x)))) := by
  change exception_undef_bind _ _ = _
  refine (eubind_defined
    (z := (PEval (xObjV x) : generic_pexpr_ Unit sym)) ?hif).trans rfl
  case hif =>
    change exception_undef_bind _ _ = _
    refine (eubind_defined (sAnd1 x h1 h2 env memo)).trans ?_
    rfl

/-- The else-side conv operand at zero (closed; rfl). -/
def if2pe : generic_pexpr Unit sym :=
  Pexpr [] () (PEif (and12pe 0)
    (Pexpr aU () (PEval (xObjV 0)))
    (Pexpr aU () (PEif
      (Pexpr aU () (PEis_unsigned (Pexpr aU () (PEval (Vctype intCty)))))
      (Pexpr aU () (PEcall (Sym symWrapI)
        [Pexpr aU () (PEval (Vctype intCty)),
         Pexpr aU () (PEval (xObjV 0))]))
      (Pexpr aU () (PEcall (Impl Integer__conv_nonrepresentable_signed_integer)
        [Pexpr aU () (PEval (Vctype intCty)),
         Pexpr aU () (PEval (xObjV 0))])))))

theorem sIf2 (env : List (Fmap sym value))
    (memo : Option CerbMem.MemState) :
    step_eval_pexpr_lemFuel 999998 p01File.tagDefs 2
      CerbLocation.Loc.unknown
      (some (CerbLocation.other "RelSem.callND"))
      (create_extern_symmap p01File) env memo p01File false if2pe
      = Result (Defined (Pexpr [] () (PEval (xObjV 0)))) := rfl

/-- The guard: `conv_int x < conv_int 0` — TRUE side. -/
theorem sGuardT (x : Int) (h1 : -2147483648 ≤ x) (h2 : x ≤ 2147483647)
    (hlt : x < 0)
    (env : List (Fmap sym value)) (memo : Option CerbMem.MemState) :
    step_eval_pexpr_lemFuel 999999 p01File.tagDefs 1
      CerbLocation.Loc.unknown
      (some (CerbLocation.other "RelSem.callND"))
      (create_extern_symmap p01File) env memo p01File false
      (Pexpr [] () (PEop OpLt (if1pe x) if2pe))
      = Result (Defined (Pexpr [] () (PEval Vtrue))) := by
  have hdlt : decide (x < (0:Int)) = true := decide_eq_true hlt
  have harm : (if (decide (x < (0:Int))) = true
      then Vtrue else Vfalse) = Vtrue := by rw [hdlt]; simp
  change exception_undef_bind _ _ = _
  refine (eubind_defined
    (z := (PEval Vtrue : generic_pexpr_ Unit sym)) ?hop).trans rfl
  case hop =>
    change exception_undef_bind _ _ = _
    refine (eubind_defined (sIf1 x h1 h2 env memo)).trans ?_
    change exception_undef_bind _ _ = _
    refine (eubind_defined (sIf2 env memo)).trans ?_
    conv => rhs; rw [show (Result (Defined (PEval Vtrue
      : generic_pexpr_ Unit sym)) : exceptM
        (t0 (generic_pexpr_ Unit sym)) core_run_cause)
      = Result (Defined (PEval (if (decide (x < (0:Int))) = true
          then Vtrue else Vfalse))) from by rw [harm]]
    rfl

/-- The guard — FALSE side. -/
theorem sGuardF (x : Int) (h1 : -2147483648 ≤ x) (h2 : x ≤ 2147483647)
    (hge : ¬ x < 0)
    (env : List (Fmap sym value)) (memo : Option CerbMem.MemState) :
    step_eval_pexpr_lemFuel 999999 p01File.tagDefs 1
      CerbLocation.Loc.unknown
      (some (CerbLocation.other "RelSem.callND"))
      (create_extern_symmap p01File) env memo p01File false
      (Pexpr [] () (PEop OpLt (if1pe x) if2pe))
      = Result (Defined (Pexpr [] () (PEval Vfalse))) := by
  have hdlt : decide (x < (0:Int)) = false := decide_eq_false hge
  have harm : (if (decide (x < (0:Int))) = true
      then Vtrue else Vfalse) = Vfalse := by rw [hdlt]; simp
  change exception_undef_bind _ _ = _
  refine (eubind_defined
    (z := (PEval Vfalse : generic_pexpr_ Unit sym)) ?hop).trans rfl
  case hop =>
    change exception_undef_bind _ _ = _
    refine (eubind_defined (sIf1 x h1 h2 env memo)).trans ?_
    change exception_undef_bind _ _ = _
    refine (eubind_defined (sIf2 env memo)).trans ?_
    conv => rhs; rw [show (Result (Defined (PEval Vfalse
      : generic_pexpr_ Unit sym)) : exceptM
        (t0 (generic_pexpr_ Unit sym)) core_run_cause)
      = Result (Defined (PEval (if (decide (x < (0:Int))) = true
          then Vtrue else Vfalse))) from by rw [harm]]
    rfl

/-- Step C, TRUE side: the whole verdict pexpr steps to `loaded 1`. -/
theorem s10cT (x : Int) (h1 : -2147483648 ≤ x) (h2 : x ≤ 2147483647)
    (hlt : x < 0)
    (env : List (Fmap sym value)) (memo : Option CerbMem.MemState) :
    step_eval_pexpr p01File.tagDefs 0 CerbLocation.Loc.unknown
      (some (CerbLocation.other "RelSem.callND"))
      (create_extern_symmap p01File) env memo p01File false (z10c x)
      = Result (Defined (Pexpr [] () (PEval (loadedV 1)))) := by
  change exception_undef_bind _ _ = _
  refine (eubind_defined
    (z := (PEval (loadedV 1) : generic_pexpr_ Unit sym)) ?hif).trans rfl
  case hif =>
    change exception_undef_bind _ _ = _
    refine (eubind_defined (sGuardT x h1 h2 hlt env memo)).trans ?_
    rfl

/-- Step C, FALSE side: the whole verdict pexpr steps to `loaded 0`. -/
theorem s10cF (x : Int) (h1 : -2147483648 ≤ x) (h2 : x ≤ 2147483647)
    (hge : ¬ x < 0)
    (env : List (Fmap sym value)) (memo : Option CerbMem.MemState) :
    step_eval_pexpr p01File.tagDefs 0 CerbLocation.Loc.unknown
      (some (CerbLocation.other "RelSem.callND"))
      (create_extern_symmap p01File) env memo p01File false (z10c x)
      = Result (Defined (Pexpr [] () (PEval (loadedV 0)))) := by
  change exception_undef_bind _ _ = _
  refine (eubind_defined
    (z := (PEval (loadedV 0) : generic_pexpr_ Unit sym)) ?hif).trans rfl
  case hif =>
    change exception_undef_bind _ _ = _
    refine (eubind_defined (sGuardF x h1 h2 hge env memo)).trans ?_
    rfl

/-- The R10 redex (in-arena spelling; the substituted compare). -/
def r10redex (x : Int) : generic_pexpr Unit sym :=
  Pexpr aU () (PEif (Pexpr aU () (PEop OpLt
      (Pexpr aU () (PEcall (Sym symConvInt)
        [Pexpr aU () (PEval (Vctype intCty)),
         Pexpr aU () (PEval (xObjV x))]))
      (Pexpr aU () (PEcall (Sym symConvInt)
        [Pexpr aU () (PEval (Vctype intCty)),
         Pexpr aU () (PEval (xObjV 0))]))))
    (Pexpr aU () (PEctor Cspecified
      [Pexpr aU () (PEval (xObjV 1))]))
    (Pexpr aU () (PEctor Cspecified
      [Pexpr aU () (PEval (xObjV 0))])))

/-- The R10 whole-loop evaluation, TRUE side. -/
theorem p01cmp_eval_T (x : Int) (h1 : -2147483648 ≤ x)
    (h2 : x ≤ 2147483647) (hlt : x < 0)
    (env : List (Fmap sym value)) (memo : Option CerbMem.MemState) :
    eval_pexpr_aux2 p01File.tagDefs CerbLocation.Loc.unknown
        (some (CerbLocation.other "RelSem.callND"))
        (create_extern_symmap p01File) env memo p01File (r10redex x)
      = Result (Defined (Sum.inr (loadedV 1))) :=
  (aux2_step 999999 _ _ _ _ _ _ _
      (show pull_constrained 0 (r10redex x) = z10a x from rfl)
      (by intro a xs h; simp [z10a] at h) (s10a x env memo)
      (by rfl)).trans
  ((aux2_step 999998 _ _ _ _ _ _ _
      (show pull_constrained 0 (z10b x) = z10b x from rfl)
      (by intro a xs h; simp [z10b] at h) (s10b x env memo)
      (by rfl)).trans
  (aux2_done 999997 _ _ _ _ _ _ _
      (show pull_constrained 0 (z10c x) = z10c x from rfl)
      (by intro a xs h; simp [z10c] at h)
      (s10cT x h1 h2 hlt env memo) (by rfl)))

/-- The R10 whole-loop evaluation, FALSE side. -/
theorem p01cmp_eval_F (x : Int) (h1 : -2147483648 ≤ x)
    (h2 : x ≤ 2147483647) (hge : ¬ x < 0)
    (env : List (Fmap sym value)) (memo : Option CerbMem.MemState) :
    eval_pexpr_aux2 p01File.tagDefs CerbLocation.Loc.unknown
        (some (CerbLocation.other "RelSem.callND"))
        (create_extern_symmap p01File) env memo p01File (r10redex x)
      = Result (Defined (Sum.inr (loadedV 0))) :=
  (aux2_step 999999 _ _ _ _ _ _ _
      (show pull_constrained 0 (r10redex x) = z10a x from rfl)
      (by intro a xs h; simp [z10a] at h) (s10a x env memo)
      (by rfl)).trans
  ((aux2_step 999998 _ _ _ _ _ _ _
      (show pull_constrained 0 (z10b x) = z10b x from rfl)
      (by intro a xs h; simp [z10b] at h) (s10b x env memo)
      (by rfl)).trans
  (aux2_done 999997 _ _ _ _ _ _ _
      (show pull_constrained 0 (z10c x) = z10c x from rfl)
      (by intro a xs h; simp [z10c] at h)
      (s10cF x h1 h2 hge env memo) (by rfl)))

/-- R10, TRUE side: the compare round lands `loaded 1`. -/
@[seg_round]
theorem p01r10T (x : Int) (h1 : -2147483648 ≤ x)
    (h2 : x ≤ 2147483647) (hlt : x < 0) (p : T1P) :
    app (dnmsRoundM p01File.tagDefs 0)
        (p01fam (p01ar10 x) [meLoad x] 9 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p01fam (p01ar11 1) [meLoad x] 10 p) := by
  refine dnmsRoundM_adv rfl ?_
  refine (advance_runstate_eval (th' := p01Th (p01ar11 1) p.f₁)
    (rs' := (p01fam (p01ar10 x) [meLoad x] 9 p).core_run_state0)
    ?_).trans ?_
  · show stExceptUndef_bind _ _ _ = _
    refine (stub_defined
      (z := Expr aU (Epure (Pexpr [] () (PEval (loadedV 1)))))
      (st' := (p01fam (p01ar10 x) [meLoad x] 9 p).core_run_state0)
      ?_).trans rfl
    show stExceptUndef_bind _ _ _ = _
    refine (stub_defined (z := loadedV 1)
      (st' := (p01fam (p01ar10 x) [meLoad x] 9 p).core_run_state0)
      ?_).trans rfl
    show stExceptUndef_bind _ _ _ = _
    refine (stub_defined (z := Sum.inr (loadedV 1))
      (st' := (p01fam (p01ar10 x) [meLoad x] 9 p).core_run_state0)
      ?_).trans ?_
    · show runEU (eval_pexpr_aux2 p01File.tagDefs
          CerbLocation.Loc.unknown
          (some (CerbLocation.other "RelSem.callND"))
          (create_extern_symmap p01File) [p.f₁] (some p.ls) p01File
          (r10redex x)) _ = _
      rw [p01cmp_eval_T x h1 h2 hlt [p.f₁] (some p.ls)]
      rfl
    · rfl
  · rfl

/-- R10, FALSE side: the compare round lands `loaded 0`. -/
@[seg_round]
theorem p01r10F (x : Int) (h1 : -2147483648 ≤ x)
    (h2 : x ≤ 2147483647) (hge : ¬ x < 0) (p : T1P) :
    app (dnmsRoundM p01File.tagDefs 0)
        (p01fam (p01ar10 x) [meLoad x] 9 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p01fam (p01ar11 0) [meLoad x] 10 p) := by
  refine dnmsRoundM_adv rfl ?_
  refine (advance_runstate_eval (th' := p01Th (p01ar11 0) p.f₁)
    (rs' := (p01fam (p01ar10 x) [meLoad x] 9 p).core_run_state0)
    ?_).trans ?_
  · show stExceptUndef_bind _ _ _ = _
    refine (stub_defined
      (z := Expr aU (Epure (Pexpr [] () (PEval (loadedV 0)))))
      (st' := (p01fam (p01ar10 x) [meLoad x] 9 p).core_run_state0)
      ?_).trans rfl
    show stExceptUndef_bind _ _ _ = _
    refine (stub_defined (z := loadedV 0)
      (st' := (p01fam (p01ar10 x) [meLoad x] 9 p).core_run_state0)
      ?_).trans rfl
    show stExceptUndef_bind _ _ _ = _
    refine (stub_defined (z := Sum.inr (loadedV 0))
      (st' := (p01fam (p01ar10 x) [meLoad x] 9 p).core_run_state0)
      ?_).trans ?_
    · show runEU (eval_pexpr_aux2 p01File.tagDefs
          CerbLocation.Loc.unknown
          (some (CerbLocation.other "RelSem.callND"))
          (create_extern_symmap p01File) [p.f₁] (some p.ls) p01File
          (r10redex x)) _ = _
      rw [p01cmp_eval_F x h1 h2 hge [p.f₁] (some p.ls)]
      rfl
    · rfl
  · rfl
-- r13 T-side chain: 5 pulled / 4 steps; final (Vloaded (LVspecified (OVinteger (.IV .Prov_none (0)))))
def z13Tb : generic_pexpr Unit sym :=
  (Pexpr [] () (PEif (Pexpr aU () (PEop OpEq (Pexpr aU () (PEcall (Sym symConvInt) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (1))))))])) (Pexpr aU () (PEcall (Sym symConvInt) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (0))))))])))) (Pexpr aU () (PEctor Cspecified [(Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (1))))))])) (Pexpr aU () (PEctor Cspecified [(Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (0))))))]))))

def z13Tc : generic_pexpr Unit sym :=
  (Pexpr [] () (PEif (Pexpr [] () (PEop OpEq (Pexpr [] () (PEif (Pexpr aU () (PEop OpEq (Pexpr aU () (PEval (Vctype intCty))) (Pexpr aU () (PEval (Vctype (Ctype [] (Basic (Integer Bool0)))))))) (Pexpr aU () (PEif (Pexpr aU () (PEop OpEq (Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (1)))))) (Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (0)))))))) (Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (0)))))) (Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (1)))))))) (Pexpr aU () (PEif (Pexpr aU () (PEcall (Sym symIsRepr) [(Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (1)))))), (Pexpr aU () (PEval (Vctype intCty)))])) (Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (1)))))) (Pexpr aU () (PEif (Pexpr aU () (PEis_unsigned (Pexpr aU () (PEval (Vctype intCty))))) (Pexpr aU () (PEcall (Sym symWrapI) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (1))))))])) (Pexpr aU () (PEcall (Impl Integer__conv_nonrepresentable_signed_integer) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (1))))))])))))))) (Pexpr [] () (PEif (Pexpr aU () (PEop OpEq (Pexpr aU () (PEval (Vctype intCty))) (Pexpr aU () (PEval (Vctype (Ctype [] (Basic (Integer Bool0)))))))) (Pexpr aU () (PEif (Pexpr aU () (PEop OpEq (Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (0)))))) (Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (0)))))))) (Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (0)))))) (Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (1)))))))) (Pexpr aU () (PEif (Pexpr aU () (PEcall (Sym symIsRepr) [(Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (0)))))), (Pexpr aU () (PEval (Vctype intCty)))])) (Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (0)))))) (Pexpr aU () (PEif (Pexpr aU () (PEis_unsigned (Pexpr aU () (PEval (Vctype intCty))))) (Pexpr aU () (PEcall (Sym symWrapI) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (0))))))])) (Pexpr aU () (PEcall (Impl Integer__conv_nonrepresentable_signed_integer) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (0))))))])))))))))) (Pexpr aU () (PEctor Cspecified [(Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (1))))))])) (Pexpr aU () (PEctor Cspecified [(Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (0))))))]))))

def z13Td : generic_pexpr Unit sym :=
  (Pexpr [] () (PEif (Pexpr [] () (PEop OpEq (Pexpr [] () (PEif (Pexpr [] () (PEop OpAnd (Pexpr [] () (PEop OpLe (Pexpr [] () (PEctor Civmin [(Pexpr aU () (PEval (Vctype intCty)))])) (Pexpr [] () (PEval (Vobject (OVinteger (.IV .Prov_none (1)))))))) (Pexpr [] () (PEop OpLe (Pexpr [] () (PEval (Vobject (OVinteger (.IV .Prov_none (1)))))) (Pexpr [] () (PEctor Civmax [(Pexpr aU () (PEval (Vctype intCty)))])))))) (Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (1)))))) (Pexpr aU () (PEif (Pexpr aU () (PEis_unsigned (Pexpr aU () (PEval (Vctype intCty))))) (Pexpr aU () (PEcall (Sym symWrapI) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (1))))))])) (Pexpr aU () (PEcall (Impl Integer__conv_nonrepresentable_signed_integer) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (1))))))])))))) (Pexpr [] () (PEif (Pexpr [] () (PEop OpAnd (Pexpr [] () (PEop OpLe (Pexpr [] () (PEctor Civmin [(Pexpr aU () (PEval (Vctype intCty)))])) (Pexpr [] () (PEval (Vobject (OVinteger (.IV .Prov_none (0)))))))) (Pexpr [] () (PEop OpLe (Pexpr [] () (PEval (Vobject (OVinteger (.IV .Prov_none (0)))))) (Pexpr [] () (PEctor Civmax [(Pexpr aU () (PEval (Vctype intCty)))])))))) (Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (0)))))) (Pexpr aU () (PEif (Pexpr aU () (PEis_unsigned (Pexpr aU () (PEval (Vctype intCty))))) (Pexpr aU () (PEcall (Sym symWrapI) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (0))))))])) (Pexpr aU () (PEcall (Impl Integer__conv_nonrepresentable_signed_integer) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (0))))))])))))))) (Pexpr aU () (PEctor Cspecified [(Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (1))))))])) (Pexpr aU () (PEctor Cspecified [(Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (0))))))]))))

-- r13 F-side chain: 5 pulled / 4 steps; final (Vloaded (LVspecified (OVinteger (.IV .Prov_none (1)))))
def z13Fb : generic_pexpr Unit sym :=
  (Pexpr [] () (PEif (Pexpr aU () (PEop OpEq (Pexpr aU () (PEcall (Sym symConvInt) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (0))))))])) (Pexpr aU () (PEcall (Sym symConvInt) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (0))))))])))) (Pexpr aU () (PEctor Cspecified [(Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (1))))))])) (Pexpr aU () (PEctor Cspecified [(Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (0))))))]))))

def z13Fc : generic_pexpr Unit sym :=
  (Pexpr [] () (PEif (Pexpr [] () (PEop OpEq (Pexpr [] () (PEif (Pexpr aU () (PEop OpEq (Pexpr aU () (PEval (Vctype intCty))) (Pexpr aU () (PEval (Vctype (Ctype [] (Basic (Integer Bool0)))))))) (Pexpr aU () (PEif (Pexpr aU () (PEop OpEq (Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (0)))))) (Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (0)))))))) (Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (0)))))) (Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (1)))))))) (Pexpr aU () (PEif (Pexpr aU () (PEcall (Sym symIsRepr) [(Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (0)))))), (Pexpr aU () (PEval (Vctype intCty)))])) (Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (0)))))) (Pexpr aU () (PEif (Pexpr aU () (PEis_unsigned (Pexpr aU () (PEval (Vctype intCty))))) (Pexpr aU () (PEcall (Sym symWrapI) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (0))))))])) (Pexpr aU () (PEcall (Impl Integer__conv_nonrepresentable_signed_integer) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (0))))))])))))))) (Pexpr [] () (PEif (Pexpr aU () (PEop OpEq (Pexpr aU () (PEval (Vctype intCty))) (Pexpr aU () (PEval (Vctype (Ctype [] (Basic (Integer Bool0)))))))) (Pexpr aU () (PEif (Pexpr aU () (PEop OpEq (Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (0)))))) (Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (0)))))))) (Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (0)))))) (Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (1)))))))) (Pexpr aU () (PEif (Pexpr aU () (PEcall (Sym symIsRepr) [(Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (0)))))), (Pexpr aU () (PEval (Vctype intCty)))])) (Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (0)))))) (Pexpr aU () (PEif (Pexpr aU () (PEis_unsigned (Pexpr aU () (PEval (Vctype intCty))))) (Pexpr aU () (PEcall (Sym symWrapI) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (0))))))])) (Pexpr aU () (PEcall (Impl Integer__conv_nonrepresentable_signed_integer) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (0))))))])))))))))) (Pexpr aU () (PEctor Cspecified [(Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (1))))))])) (Pexpr aU () (PEctor Cspecified [(Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (0))))))]))))

def z13Fd : generic_pexpr Unit sym :=
  (Pexpr [] () (PEif (Pexpr [] () (PEop OpEq (Pexpr [] () (PEif (Pexpr [] () (PEop OpAnd (Pexpr [] () (PEop OpLe (Pexpr [] () (PEctor Civmin [(Pexpr aU () (PEval (Vctype intCty)))])) (Pexpr [] () (PEval (Vobject (OVinteger (.IV .Prov_none (0)))))))) (Pexpr [] () (PEop OpLe (Pexpr [] () (PEval (Vobject (OVinteger (.IV .Prov_none (0)))))) (Pexpr [] () (PEctor Civmax [(Pexpr aU () (PEval (Vctype intCty)))])))))) (Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (0)))))) (Pexpr aU () (PEif (Pexpr aU () (PEis_unsigned (Pexpr aU () (PEval (Vctype intCty))))) (Pexpr aU () (PEcall (Sym symWrapI) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (0))))))])) (Pexpr aU () (PEcall (Impl Integer__conv_nonrepresentable_signed_integer) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (0))))))])))))) (Pexpr [] () (PEif (Pexpr [] () (PEop OpAnd (Pexpr [] () (PEop OpLe (Pexpr [] () (PEctor Civmin [(Pexpr aU () (PEval (Vctype intCty)))])) (Pexpr [] () (PEval (Vobject (OVinteger (.IV .Prov_none (0)))))))) (Pexpr [] () (PEop OpLe (Pexpr [] () (PEval (Vobject (OVinteger (.IV .Prov_none (0)))))) (Pexpr [] () (PEctor Civmax [(Pexpr aU () (PEval (Vctype intCty)))])))))) (Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (0)))))) (Pexpr aU () (PEif (Pexpr aU () (PEis_unsigned (Pexpr aU () (PEval (Vctype intCty))))) (Pexpr aU () (PEcall (Sym symWrapI) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (0))))))])) (Pexpr aU () (PEcall (Impl Integer__conv_nonrepresentable_signed_integer) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (0))))))])))))))) (Pexpr aU () (PEctor Cspecified [(Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (1))))))])) (Pexpr aU () (PEctor Cspecified [(Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (0))))))]))))

/-- The R13 redex (in-arena; the a_529/a_530 case + EQ compare). -/
def r13redex : generic_pexpr Unit sym :=
  Pexpr aU () (PEcase
    (Pexpr aU () (PEctor Ctuple
      [Pexpr aU () (PEsym symA529), Pexpr aU () (PEsym symA530)]))
    [(Pattern aU (CaseCtor Ctuple
        [Pattern aU (CaseCtor Cspecified
          [Pattern aU (CaseBase ((some symA531), BTy_object OTy_integer))]),
         Pattern aU (CaseCtor Cspecified
          [Pattern aU (CaseBase ((some symA532), BTy_object OTy_integer))])]),
      Pexpr aU () (PEif (Pexpr aU () (PEop OpEq
          (Pexpr aU () (PEcall (Sym symConvInt)
            [Pexpr aU () (PEval (Vctype intCty)),
             Pexpr aU () (PEsym symA531)]))
          (Pexpr aU () (PEcall (Sym symConvInt)
            [Pexpr aU () (PEval (Vctype intCty)),
             Pexpr aU () (PEsym symA532)]))))
        (Pexpr aU () (PEctor Cspecified
          [Pexpr aU () (PEval (xObjV 1))]))
        (Pexpr aU () (PEctor Cspecified
          [Pexpr aU () (PEval (xObjV 0))])))),
     (Pattern aU (CaseBase (none,
        BTy_tuple [BTy_loaded OTy_integer, BTy_loaded OTy_integer])),
      Pexpr aU () (PEctor Cunspecified
        [Pexpr aU () (PEval (Vctype intCty))]))]
    )

/-- The R13 arm list. -/
def r13redexArms : List (generic_pattern sym × generic_pexpr Unit sym) :=
  [(Pattern aU (CaseCtor Ctuple
      [Pattern aU (CaseCtor Cspecified
        [Pattern aU (CaseBase ((some symA531), BTy_object OTy_integer))]),
       Pattern aU (CaseCtor Cspecified
        [Pattern aU (CaseBase ((some symA532), BTy_object OTy_integer))])]),
    Pexpr aU () (PEif (Pexpr aU () (PEop OpEq
        (Pexpr aU () (PEcall (Sym symConvInt)
          [Pexpr aU () (PEval (Vctype intCty)),
           Pexpr aU () (PEsym symA531)]))
        (Pexpr aU () (PEcall (Sym symConvInt)
          [Pexpr aU () (PEval (Vctype intCty)),
           Pexpr aU () (PEsym symA532)]))))
      (Pexpr aU () (PEctor Cspecified
        [Pexpr aU () (PEval (xObjV 1))]))
      (Pexpr aU () (PEctor Cspecified
        [Pexpr aU () (PEval (xObjV 0))])))),
   (Pattern aU (CaseBase (none,
      BTy_tuple [BTy_loaded OTy_integer, BTy_loaded OTy_integer])),
    Pexpr aU () (PEctor Cunspecified
      [Pexpr aU () (PEval (Vctype intCty))]))]

/-- R13 step 1, TRUE side: case-select + substitution at the read
    cells. -/
theorem s13Ta (env : List (Fmap sym value))
    (memo : Option CerbMem.MemState)
    (h529 : lookup_env symA529 env = some (loadedV 1))
    (h530 : lookup_env symA530 env = some (loadedV 0)) :
    step_eval_pexpr p01File.tagDefs 0 CerbLocation.Loc.unknown
      (some (CerbLocation.other "RelSem.callND"))
      (create_extern_symmap p01File) env memo p01File false
      (Pexpr [] () (PEcase
        (Pexpr [] () (PEctor Ctuple
          [Pexpr aU () (PEsym symA529),
           Pexpr aU () (PEsym symA530)]))
        r13redexArms))
      = Result (Defined z13Tb) :=
  se_case_sel
    (se_ctor_tuple
      (pes' := [Pexpr [] () (PEval (loadedV 1)),
                Pexpr [] () (PEval (loadedV 0))])
      (cvals := [loadedV 1, loadedV 0])
      (eumapM_cons (se_sym_hit (fuel := 999997) rfl h529)
        (eumapM_cons (se_sym_hit (fuel := 999997) rfl h530)
          eumapM_nil)) rfl)
    rfl

/-- R13 step 1, FALSE side. -/
theorem s13Fa (env : List (Fmap sym value))
    (memo : Option CerbMem.MemState)
    (h529 : lookup_env symA529 env = some (loadedV 0))
    (h530 : lookup_env symA530 env = some (loadedV 0)) :
    step_eval_pexpr p01File.tagDefs 0 CerbLocation.Loc.unknown
      (some (CerbLocation.other "RelSem.callND"))
      (create_extern_symmap p01File) env memo p01File false
      (Pexpr [] () (PEcase
        (Pexpr [] () (PEctor Ctuple
          [Pexpr aU () (PEsym symA529),
           Pexpr aU () (PEsym symA530)]))
        r13redexArms))
      = Result (Defined z13Fb) :=
  se_case_sel
    (se_ctor_tuple
      (pes' := [Pexpr [] () (PEval (loadedV 0)),
                Pexpr [] () (PEval (loadedV 0))])
      (cvals := [loadedV 0, loadedV 0])
      (eumapM_cons (se_sym_hit (fuel := 999997) rfl h529)
        (eumapM_cons (se_sym_hit (fuel := 999997) rfl h530)
          eumapM_nil)) rfl)
    rfl

/-- The R13 whole-loop evaluation, TRUE side (a_529 = 1 ⇒ EQ false
    ⇒ loaded 0). -/
theorem p01eq_eval_T (env : List (Fmap sym value))
    (memo : Option CerbMem.MemState)
    (h529 : lookup_env symA529 env = some (loadedV 1))
    (h530 : lookup_env symA530 env = some (loadedV 0)) :
    eval_pexpr_aux2 p01File.tagDefs CerbLocation.Loc.unknown
        (some (CerbLocation.other "RelSem.callND"))
        (create_extern_symmap p01File) env memo p01File r13redex
      = Result (Defined (Sum.inr (loadedV 0))) :=
  (aux2_step 999999 _ _ _ _ _ _ _
      rfl
      (by intro a xs h; cases h)
      (s13Ta env memo h529 h530)
      (by rfl)).trans
  ((aux2_step 999998 _ _ _ _ _ _ _
      (show pull_constrained 0 z13Tb = z13Tb from rfl)
      (by intro a xs h; simp [z13Tb] at h) rfl (by rfl)).trans
  ((aux2_step 999997 _ _ _ _ _ _ _
      (show pull_constrained 0 z13Tc = z13Tc from rfl)
      (by intro a xs h; simp [z13Tc] at h)
      (show step_eval_pexpr p01File.tagDefs 0 CerbLocation.Loc.unknown
          (some (CerbLocation.other "RelSem.callND"))
          (create_extern_symmap p01File) env memo p01File false z13Tc
        = Result (Defined z13Td) from rfl) (by rfl)).trans
  (aux2_done 999996 _ _ _ _ _ _ _
      (show pull_constrained 0 z13Td = z13Td from rfl)
      (by intro a xs h; simp [z13Td] at h)
      (show step_eval_pexpr p01File.tagDefs 0 CerbLocation.Loc.unknown
          (some (CerbLocation.other "RelSem.callND"))
          (create_extern_symmap p01File) env memo p01File false z13Td
        = Result (Defined (Pexpr [] () (PEval (loadedV 0)))) from rfl)
      (by rfl))))

/-- The R13 whole-loop evaluation, FALSE side (a_529 = 0 ⇒ EQ true
    ⇒ loaded 1). -/
theorem p01eq_eval_F (env : List (Fmap sym value))
    (memo : Option CerbMem.MemState)
    (h529 : lookup_env symA529 env = some (loadedV 0))
    (h530 : lookup_env symA530 env = some (loadedV 0)) :
    eval_pexpr_aux2 p01File.tagDefs CerbLocation.Loc.unknown
        (some (CerbLocation.other "RelSem.callND"))
        (create_extern_symmap p01File) env memo p01File r13redex
      = Result (Defined (Sum.inr (loadedV 1))) :=
  (aux2_step 999999 _ _ _ _ _ _ _
      rfl
      (by intro a xs h; cases h)
      (s13Fa env memo h529 h530)
      (by rfl)).trans
  ((aux2_step 999998 _ _ _ _ _ _ _
      (show pull_constrained 0 z13Fb = z13Fb from rfl)
      (by intro a xs h; simp [z13Fb] at h) rfl (by rfl)).trans
  ((aux2_step 999997 _ _ _ _ _ _ _
      (show pull_constrained 0 z13Fc = z13Fc from rfl)
      (by intro a xs h; simp [z13Fc] at h)
      (show step_eval_pexpr p01File.tagDefs 0 CerbLocation.Loc.unknown
          (some (CerbLocation.other "RelSem.callND"))
          (create_extern_symmap p01File) env memo p01File false z13Fc
        = Result (Defined z13Fd) from rfl) (by rfl)).trans
  (aux2_done 999996 _ _ _ _ _ _ _
      (show pull_constrained 0 z13Fd = z13Fd from rfl)
      (by intro a xs h; simp [z13Fd] at h)
      (show step_eval_pexpr p01File.tagDefs 0 CerbLocation.Loc.unknown
          (some (CerbLocation.other "RelSem.callND"))
          (create_extern_symmap p01File) env memo p01File false z13Fd
        = Result (Defined (Pexpr [] () (PEval (loadedV 1)))) from rfl)
      (by rfl))))

/-- R13, TRUE side: the EQ-compare case evaluates (reads a_529/a_530;
    lands loaded 0). -/
@[seg_round]
theorem p01r13T (x : Int) (p : T1P)
    (h529 : envLookup (p01fam p01ar13 [meLoad x] 12 p) symA529
      = some (loadedV 1))
    (h530 : envLookup (p01fam p01ar13 [meLoad x] 12 p) symA530
      = some (loadedV 0)) :
    app (dnmsRoundM p01File.tagDefs 0)
        (p01fam p01ar13 [meLoad x] 12 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p01fam (p01ar14 0) [meLoad x] 13 p) := by
  refine dnmsRoundM_adv rfl ?_
  refine (advance_runstate_eval (th' := p01Th (p01ar14 0) p.f₁)
    (rs' := (p01fam p01ar13 [meLoad x] 12 p).core_run_state0)
    ?_).trans ?_
  · show stExceptUndef_bind _ _ _ = _
    refine (stub_defined
      (z := Expr aU (Epure (Pexpr [] () (PEval (loadedV 0)))))
      (st' := (p01fam p01ar13 [meLoad x] 12 p).core_run_state0)
      ?_).trans rfl
    show stExceptUndef_bind _ _ _ = _
    refine (stub_defined (z := loadedV 0)
      (st' := (p01fam p01ar13 [meLoad x] 12 p).core_run_state0)
      ?_).trans rfl
    show stExceptUndef_bind _ _ _ = _
    refine (stub_defined (z := Sum.inr (loadedV 0))
      (st' := (p01fam p01ar13 [meLoad x] 12 p).core_run_state0)
      ?_).trans ?_
    · show runEU (eval_pexpr_aux2 p01File.tagDefs
          CerbLocation.Loc.unknown
          (some (CerbLocation.other "RelSem.callND"))
          (create_extern_symmap p01File) [p.f₁] (some p.ls) p01File
          r13redex) _ = _
      rw [p01eq_eval_T [p.f₁] (some p.ls)
        (show lookup_env symA529 [p.f₁] = some (loadedV 1) from h529)
        (show lookup_env symA530 [p.f₁] = some (loadedV 0) from h530)]
      rfl
    · rfl
  · rfl

/-- R13, FALSE side (a_529 = 0 ⇒ loaded 1). -/
@[seg_round]
theorem p01r13F (x : Int) (p : T1P)
    (h529 : envLookup (p01fam p01ar13 [meLoad x] 12 p) symA529
      = some (loadedV 0))
    (h530 : envLookup (p01fam p01ar13 [meLoad x] 12 p) symA530
      = some (loadedV 0)) :
    app (dnmsRoundM p01File.tagDefs 0)
        (p01fam p01ar13 [meLoad x] 12 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p01fam (p01ar14 1) [meLoad x] 13 p) := by
  refine dnmsRoundM_adv rfl ?_
  refine (advance_runstate_eval (th' := p01Th (p01ar14 1) p.f₁)
    (rs' := (p01fam p01ar13 [meLoad x] 12 p).core_run_state0)
    ?_).trans ?_
  · show stExceptUndef_bind _ _ _ = _
    refine (stub_defined
      (z := Expr aU (Epure (Pexpr [] () (PEval (loadedV 1)))))
      (st' := (p01fam p01ar13 [meLoad x] 12 p).core_run_state0)
      ?_).trans rfl
    show stExceptUndef_bind _ _ _ = _
    refine (stub_defined (z := loadedV 1)
      (st' := (p01fam p01ar13 [meLoad x] 12 p).core_run_state0)
      ?_).trans rfl
    show stExceptUndef_bind _ _ _ = _
    refine (stub_defined (z := Sum.inr (loadedV 1))
      (st' := (p01fam p01ar13 [meLoad x] 12 p).core_run_state0)
      ?_).trans ?_
    · show runEU (eval_pexpr_aux2 p01File.tagDefs
          CerbLocation.Loc.unknown
          (some (CerbLocation.other "RelSem.callND"))
          (create_extern_symmap p01File) [p.f₁] (some p.ls) p01File
          r13redex) _ = _
      rw [p01eq_eval_F [p.f₁] (some p.ls)
        (show lookup_env symA529 [p.f₁] = some (loadedV 0) from h529)
        (show lookup_env symA530 [p.f₁] = some (loadedV 0) from h530)]
      rfl
    · rfl
  · rfl

/-- R18, TRUE side (a_528 substituted at 0: NOT(0=1) ⇒ Vtrue; closed
    eval). -/
@[seg_round]
theorem p01r18T (x : Int) (p : T1P) :
    app (dnmsRoundM p01File.tagDefs 0)
        (p01fam (p01ar18 0) [meLoad x] 17 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p01fam (p01ar19 Vtrue) [meLoad x] 18 p) := by
  refine dnmsRoundM_adv rfl ?_
  exact (advance_runstate_eval (th' := p01Th (p01ar19 Vtrue) p.f₁)
    (rs' := (p01fam (p01ar18 0) [meLoad x] 17 p).core_run_state0)
    rfl).trans rfl

/-- R18, FALSE side (a_528 at 1: NOT(1=1) ⇒ Vfalse; closed eval). -/
@[seg_round]
theorem p01r18F (x : Int) (p : T1P) :
    app (dnmsRoundM p01File.tagDefs 0)
        (p01fam (p01ar18 1) [meLoad x] 17 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p01fam (p01ar19 Vfalse) [meLoad x] 18 p) := by
  refine dnmsRoundM_adv rfl ?_
  exact (advance_runstate_eval (th' := p01Th (p01ar19 Vfalse) p.f₁)
    (rs' := (p01fam (p01ar18 1) [meLoad x] 17 p).core_run_state0)
    rfl).trans rfl

/-- R20, TRUE side: the Eif reads the guard cell a_526 = Vtrue and
    picks the then-arm. -/
@[seg_round]
theorem p01r20T (x : Int) (p : T1P)
    (ha : envLookup (p01fam p01ar20 [meLoad x] 19 p) symA526
      = some Vtrue) :
    app (dnmsRoundM p01File.tagDefs 0)
        (p01fam p01ar20 [meLoad x] 19 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p01fam p01arT21 [meLoad x] 20 p) := by
  refine dnmsRoundM_adv rfl ?_
  refine (advance_runstate_tau_misc (th' := p01Th p01arT21 p.f₁)
    (rs' := (p01fam p01ar20 [meLoad x] 19 p).core_run_state0)
    ?_).trans ?_
  · show stExceptUndef_bind _ _ _ = _
    refine (stub_defined (z := ([p.f₁], p01ArmT))
      (st' := (p01fam p01ar20 [meLoad x] 19 p).core_run_state0)
      ?_).trans rfl
    show stExceptUndef_bind _ _ _ = _
    refine (stub_defined (z := Vtrue)
      (st' := (p01fam p01ar20 [meLoad x] 19 p).core_run_state0)
      ?_).trans ?_
    · show stExceptUndef_bind _ _ _ = _
      refine (stub_defined (z := Sum.inr Vtrue)
        (st' := (p01fam p01ar20 [meLoad x] 19 p).core_run_state0)
        ?_).trans rfl
      show runEU (eval_pexpr_aux2 p01File.tagDefs
          CerbLocation.Loc.unknown
          (some (CerbLocation.other "RelSem.callND"))
          (create_extern_symmap p01File) [p.f₁] (some p.ls) p01File
          (Pexpr aU () (PEsym symA526))) _ = _
      rw [aux2_sym_hit (a := aU) (a' := []) (z := symA526)
        (v := Vtrue) (env := [p.f₁]) rfl rfl
        (show lookup_env symA526 [p.f₁] = some Vtrue from ha)]
      rfl
    · rfl
  · rfl

/-! ## The Erun conv chains (conv_loaded_int at the jump argument;
    the T1 z-chain reused — its terms are file-independent) -/

open RelSem.T1 (z0 z1 z2 z3 xIntV)

/-- The jump argument at cell `b`. -/
def p01convPE (b : sym) : generic_pexpr Unit sym :=
  Pexpr aU () (PEcall (Sym RelSem.T1.convLoadedIntSym)
    [Pexpr aU () (PEval (Vctype intCty)), Pexpr aU () (PEsym b)])

/-- s0 at p01File/cell `b`: the conv call inlines (the cell read). -/
theorem p01s0_eq (b : sym) (x : Int) (env : List (Fmap sym value))
    (memo : Option CerbMem.MemState)
    (hb : fmapLookupBy
      (fun (s1 s2 : sym) => ordCompare s1 s2) b
      (create_extern_symmap p01File) = none)
    (ha : lookup_env b env = some (loadedV x)) :
    step_eval_pexpr p01File.tagDefs 0 CerbLocation.Loc.unknown
      (some (CerbLocation.other "RelSem.callND"))
      (create_extern_symmap p01File) env memo p01File false
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

theorem p01s1_eq (x : Int) (env : List (Fmap sym value))
    (memo : Option CerbMem.MemState) :
    step_eval_pexpr p01File.tagDefs 0 CerbLocation.Loc.unknown
      (some (CerbLocation.other "RelSem.callND"))
      (create_extern_symmap p01File) env memo p01File false (z0 x)
      = Result (Defined (z1 x)) := rfl

theorem p01s2_eq (x : Int) (env : List (Fmap sym value))
    (memo : Option CerbMem.MemState) :
    step_eval_pexpr p01File.tagDefs 0 CerbLocation.Loc.unknown
      (some (CerbLocation.other "RelSem.callND"))
      (create_extern_symmap p01File) env memo p01File false (z1 x)
      = Result (Defined (z2 x)) := rfl

theorem p01s3_eq (x : Int) (env : List (Fmap sym value))
    (memo : Option CerbMem.MemState) :
    step_eval_pexpr p01File.tagDefs 0 CerbLocation.Loc.unknown
      (some (CerbLocation.other "RelSem.callND"))
      (create_extern_symmap p01File) env memo p01File false (z2 x)
      = Result (Defined (z3 x)) := rfl

/-- s4 at p01File: the range check (path hypotheses enter). -/
theorem p01s4_eq (x : Int) (h1 : -2147483648 ≤ x)
    (h2 : x ≤ 2147483647)
    (env : List (Fmap sym value)) (memo : Option CerbMem.MemState) :
    step_eval_pexpr p01File.tagDefs 0 CerbLocation.Loc.unknown
      (some (CerbLocation.other "RelSem.callND"))
      (create_extern_symmap p01File) env memo p01File false (z3 x)
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
                show step_eval_pexpr_lemFuel 999997 p01File.tagDefs (0+1+1+1)
                  CerbLocation.Loc.unknown (some (CerbLocation.other "RelSem.callND"))
                  (create_extern_symmap p01File) env memo p01File false
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
                show step_eval_pexpr_lemFuel 999997 p01File.tagDefs (0+1+1+1)
                  CerbLocation.Loc.unknown (some (CerbLocation.other "RelSem.callND"))
                  (create_extern_symmap p01File) env memo p01File false
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

/-- The whole conv loop at p01File (cell `b`, range-checked value). -/
theorem p01conv_eval (b : sym) (x : Int) (h1 : -2147483648 ≤ x)
    (h2 : x ≤ 2147483647)
    (env : List (Fmap sym value)) (memo : Option CerbMem.MemState)
    (hb : fmapLookupBy
      (fun (s1 s2 : sym) => ordCompare s1 s2) b
      (create_extern_symmap p01File) = none)
    (ha : lookup_env b env = some (loadedV x)) :
    eval_pexpr_aux2 p01File.tagDefs CerbLocation.Loc.unknown
        (some (CerbLocation.other "RelSem.callND"))
        (create_extern_symmap p01File) env memo p01File (p01convPE b)
      = Result (Defined (Sum.inr (loadedV x))) :=
  (aux2_step 999999 _ _ _ _ _ _ _ rfl
      (by intro a xs h; cases h) (p01s0_eq b x env memo hb ha)
      (by rfl)).trans
  ((aux2_step 999998 _ _ _ _ _ _ _
      (show pull_constrained 0 (z0 x) = z0 x from rfl)
      (by intro a xs h; simp [z0] at h) (p01s1_eq x env memo)
      (by rfl)).trans
  ((aux2_step 999997 _ _ _ _ _ _ _
      (show pull_constrained 0 (z1 x) = z1 x from rfl)
      (by intro a xs h; simp [z1] at h) (p01s2_eq x env memo)
      (by rfl)).trans
  ((aux2_step 999996 _ _ _ _ _ _ _
      (show pull_constrained 0 (z2 x) = z2 x from rfl)
      (by intro a xs h; simp [z2] at h) (p01s3_eq x env memo)
      (by rfl)).trans
  (aux2_done 999995 _ _ _ _ _ _ _
      (show pull_constrained 0 (z3 x) = z3 x from rfl)
      (by intro a xs h; simp [z3] at h)
      (p01s4_eq x h1 h2 env memo) (by rfl)))))

/-- The full-eval face of the conv chain (∀-run-state, arena-generic
    thread). -/
theorem p01fullEval_conv (arena : RExpr) (b : sym) (x : Int)
    (h1 : -2147483648 ≤ x) (h2 : x ≤ 2147483647)
    (f₁ : Fmap sym value) (ls : CerbMem.MemState)
    (st : core_run_state)
    (hb : fmapLookupBy
      (fun (s1 s2 : sym) => ordCompare s1 s2) b
      (create_extern_symmap p01File) = none)
    (ha : lookup_env b [f₁] = some (loadedV x)) :
    full_eval_pexpr p01File.tagDefs (p01Th arena f₁)
        (create_extern_symmap p01File) ls p01File (p01convPE b) st
      = Result (Defined (loadedV x), st) := by
  show stExceptUndef_bind _ _ _ = _
  refine (stub_defined (z := Sum.inr (loadedV x)) (st' := st) ?_).trans ?_
  · show runEU (eval_pexpr_aux2 p01File.tagDefs
        CerbLocation.Loc.unknown
        (some (CerbLocation.other "RelSem.callND"))
        (create_extern_symmap p01File) [f₁] (some ls) p01File
        (p01convPE b)) _ = _
    rw [p01conv_eval b x h1 h2 [f₁] (some ls) hb ha]
    rfl
  · rfl

/-- The a_543 jump bind (compiled-matcher spelling). -/
theorem update_env_aux_a543 (v : value) (f : Fmap sym value) :
    update_env_aux (mk_sym_pat symA543 (BTy_loaded OTy_integer)) v f
      = @fmapAddBy sym value Lem_Map.instBEqOfMapKeyType
          (@Lem_Map.mapKeyCompare sym _) symA543 v f := rfl

theorem update_env_aux_a541 (f : Fmap sym value) :
    update_env_aux patA541 xPtrV f
      = @fmapAddBy sym value Lem_Map.instBEqOfMapKeyType
          (@Lem_Map.mapKeyCompare sym _) symA541 xPtrV f := rfl

theorem update_env_aux_a542 (x : Int) (f : Fmap sym value) :
    update_env_aux patA542 (loadedV x) f
      = @fmapAddBy sym value Lem_Map.instBEqOfMapKeyType
          (@Lem_Map.mapKeyCompare sym _) symA542 (loadedV x) f := rfl

/-! ## THE TRUE-SIDE TAIL (x < 0: return 0 via the ret label) -/

/-- R21T: the then-arm's specified-zero evaluates (closed). -/
@[seg_round]
theorem p01r21T (x : Int) (p : T1P) :
    app (dnmsRoundM p01File.tagDefs 0)
        (p01fam p01arT21 [meLoad x] 20 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p01fam p01arT22 [meLoad x] 21 p) := by
  refine dnmsRoundM_adv rfl ?_
  exact (advance_runstate_eval (th' := p01Th p01arT22 p.f₁)
    (rs' := (p01fam p01arT21 [meLoad x] 20 p).core_run_state0)
    rfl).trans rfl

/-- R22T: the Ebound strips (tau). -/
@[seg_round]
theorem p01r22T (x : Int) (p : T1P) :
    app (dnmsRoundM p01File.tagDefs 0)
        (p01fam p01arT22 [meLoad x] 21 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p01fam p01arT23 [meLoad x] 22 p) := by
  refine dnmsRoundM_adv rfl ?_
  exact (advance_tau_misc).trans rfl

/-- R23T: the Esseq binds a_540 := loaded 0 (BIRTH). -/
@[seg_round]
theorem p01r23T (x : Int) (p : T1P) :
    app (dnmsRoundM p01File.tagDefs 0)
        (p01fam p01arT23 [meLoad x] 22 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p01fam p01arT24 [meLoad x] 23
           { p with f₁ := update_env_aux patA540 (loadedV 0) p.f₁ }) := by
  refine dnmsRoundM_adv rfl ?_
  exact (advance_tau_misc).trans rfl

/-- R24T: the Erun jump — conv chain at a_540 (= 0), a_543 BORN. -/
@[seg_round]
theorem p01r24T (x : Int) (p : T1P)
    (ha : envLookup (p01fam p01arT24 [meLoad x] 23 p) symA540
      = some (loadedV 0)) :
    app (dnmsRoundM p01File.tagDefs 0)
        (p01fam p01arT24 [meLoad x] 23 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p01fam p01arT25 [meLoad x] 24
           { p with f₁ :=
               (update_env_aux
                 (mk_sym_pat symA543 (BTy_loaded OTy_integer))
                 (loadedV 0) p.f₁) }) := by
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
          apply (stub_defined (p01fullEval_conv p01arT24 symA540 0
            (by decide) (by decide) p.f₁ p.ls _ rfl
            (show lookup_env symA540 [p.f₁] = some (loadedV 0)
              from ha))).trans
          rfl
        rfl
      rfl
  rfl

/-- R25T: a_543 evaluates (the return value reaches the arena). -/
@[seg_round]
theorem p01r25T (x : Int) (p : T1P)
    (ha : envLookup (p01fam p01arT25 [meLoad x] 24 p) symA543
      = some (loadedV 0)) :
    app (dnmsRoundM p01File.tagDefs 0)
        (p01fam p01arT25 [meLoad x] 24 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p01fam p01arT26 [meLoad x] 25 p) := by
  refine dnmsRoundM_adv rfl ?_
  refine (advance_runstate_eval (th' := p01Th p01arT26 p.f₁)
    (rs' := (p01fam p01arT25 [meLoad x] 24 p).core_run_state0)
    ?_).trans ?_
  · show stExceptUndef_bind _ _ _ = _
    refine (stub_defined
      (z := Expr aU (Epure (Pexpr [] () (PEval (loadedV 0)))))
      (st' := (p01fam p01arT25 [meLoad x] 24 p).core_run_state0)
      ?_).trans rfl
    show stExceptUndef_bind _ _ _ = _
    refine (stub_defined (z := loadedV 0)
      (st' := (p01fam p01arT25 [meLoad x] 24 p).core_run_state0)
      ?_).trans rfl
    show stExceptUndef_bind _ _ _ = _
    refine (stub_defined (z := Sum.inr (loadedV 0))
      (st' := (p01fam p01arT25 [meLoad x] 24 p).core_run_state0)
      ?_).trans ?_
    · show runEU (eval_pexpr_aux2 p01File.tagDefs
          CerbLocation.Loc.unknown
          (some (CerbLocation.other "RelSem.callND"))
          (create_extern_symmap p01File) [p.f₁] (some p.ls) p01File
          (Pexpr aU () (PEsym symA543))) _ = _
      rw [aux2_sym_hit (a := aU) (a' := []) (z := symA543)
        (v := loadedV 0) (env := [p.f₁]) rfl rfl
        (show lookup_env symA543 [p.f₁] = some (loadedV 0) from ha)]
      rfl
    · rfl
  · rfl

/-- R-terminal, TRUE side: the value state offers exactly the done
    step at 0. -/
@[seg_round]
theorem p01r26T (x : Int) (p : T1P) :
    app (dnmsRoundM p01File.tagDefs 0)
        (p01fam p01arT26 [meLoad x] 25 p)
      = (NDactive (Sum.inr [Step_done2 (loadedV 0)]),
         p01fam p01arT26 [meLoad x] 25 p) := by
  refine (dnmsRoundM_inr rfl).trans ?_
  rfl

/-! ## THE FALSE-SIDE TAIL (x ≥ 0: fall through, reload x,
    return x) -/

/-- R20F: the Eif reads a_526 = Vfalse and falls through to Vunit. -/
@[seg_round]
theorem p01r20F (x : Int) (p : T1P)
    (ha : envLookup (p01fam p01ar20 [meLoad x] 19 p) symA526
      = some Vfalse) :
    app (dnmsRoundM p01File.tagDefs 0)
        (p01fam p01ar20 [meLoad x] 19 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p01fam p01arF21 [meLoad x] 20 p) := by
  refine dnmsRoundM_adv rfl ?_
  refine (advance_runstate_tau_misc (th' := p01Th p01arF21 p.f₁)
    (rs' := (p01fam p01ar20 [meLoad x] 19 p).core_run_state0)
    ?_).trans ?_
  · show stExceptUndef_bind _ _ _ = _
    refine (stub_defined (z := ([p.f₁], p01ArmF))
      (st' := (p01fam p01ar20 [meLoad x] 19 p).core_run_state0)
      ?_).trans rfl
    show stExceptUndef_bind _ _ _ = _
    refine (stub_defined (z := Vfalse)
      (st' := (p01fam p01ar20 [meLoad x] 19 p).core_run_state0)
      ?_).trans ?_
    · show stExceptUndef_bind _ _ _ = _
      refine (stub_defined (z := Sum.inr Vfalse)
        (st' := (p01fam p01ar20 [meLoad x] 19 p).core_run_state0)
        ?_).trans rfl
      show runEU (eval_pexpr_aux2 p01File.tagDefs
          CerbLocation.Loc.unknown
          (some (CerbLocation.other "RelSem.callND"))
          (create_extern_symmap p01File) [p.f₁] (some p.ls) p01File
          (Pexpr aU () (PEsym symA526))) _ = _
      rw [aux2_sym_hit (a := aU) (a' := []) (z := symA526)
        (v := Vfalse) (env := [p.f₁]) rfl rfl
        (show lookup_env symA526 [p.f₁] = some Vfalse from ha)]
      rfl
    · rfl
  · rfl

/-- R21F: the unit Esseq consumes Vunit (tau). -/
@[seg_round]
theorem p01r21F (x : Int) (p : T1P) :
    app (dnmsRoundM p01File.tagDefs 0)
        (p01fam p01arF21 [meLoad x] 20 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p01fam p01arF22 [meLoad x] 21 p) := by
  refine dnmsRoundM_adv rfl ?_
  exact (advance_tau_misc).trans rfl

/-- R22F: the reload's pure operand evaluates — reads x's cell. -/
@[seg_round]
theorem p01r22F (x : Int) (p : T1P)
    (hx : envLookup (p01fam p01arF22 [meLoad x] 21 p) symX
      = some xPtrV) :
    app (dnmsRoundM p01File.tagDefs 0)
        (p01fam p01arF22 [meLoad x] 21 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p01fam p01arF23 [meLoad x] 22 p) := by
  refine dnmsRoundM_adv rfl ?_
  refine (advance_runstate_eval (th' := p01Th p01arF23 p.f₁)
    (rs' := (p01fam p01arF22 [meLoad x] 21 p).core_run_state0)
    ?_).trans ?_
  · show stExceptUndef_bind _ _ _ = _
    refine (stub_defined (z := Expr aU (Epure (Pexpr [] () (PEval xPtrV))))
      (st' := (p01fam p01arF22 [meLoad x] 21 p).core_run_state0)
      ?_).trans rfl
    show stExceptUndef_bind _ _ _ = _
    refine (stub_defined (z := xPtrV)
      (st' := (p01fam p01arF22 [meLoad x] 21 p).core_run_state0)
      ?_).trans rfl
    show stExceptUndef_bind _ _ _ = _
    refine (stub_defined (z := Sum.inr xPtrV)
      (st' := (p01fam p01arF22 [meLoad x] 21 p).core_run_state0)
      ?_).trans ?_
    · show runEU (eval_pexpr_aux2 p01File.tagDefs
          CerbLocation.Loc.unknown
          (some (CerbLocation.other "RelSem.callND"))
          (create_extern_symmap p01File) [p.f₁] (some p.ls) p01File
          (Pexpr aU () (PEsym symX))) _ = _
      rw [aux2_sym_hit (a := aU) (a' := []) (z := symX) (v := xPtrV)
        (env := [p.f₁]) rfl rfl
        (show lookup_env symX [p.f₁] = some xPtrV from hx)]
      rfl
    · rfl
  · rfl

/-- R23F: the Ewseq binds a_541 (BIRTH). -/
@[seg_round]
theorem p01r23F (x : Int) (p : T1P) :
    app (dnmsRoundM p01File.tagDefs 0)
        (p01fam p01arF23 [meLoad x] 22 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p01fam p01arF24 [meLoad x] 23
           { p with f₁ := update_env_aux patA541 xPtrV p.f₁ }) := by
  refine dnmsRoundM_adv rfl ?_
  exact (advance_tau_misc).trans rfl

/-- R24F: the second Load's operands evaluate — reads a_541's cell. -/
@[seg_round]
theorem p01r24F (x : Int) (p : T1P)
    (ha : envLookup (p01fam p01arF24 [meLoad x] 23 p) symA541
      = some xPtrV) :
    app (dnmsRoundM p01File.tagDefs 0)
        (p01fam p01arF24 [meLoad x] 23 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p01fam p01arF25 [meLoad x] 24 p) := by
  refine dnmsRoundM_adv rfl ?_
  refine (advance_runstate_eval (th' := p01Th p01arF25 p.f₁)
    (rs' := (p01fam p01arF24 [meLoad x] 23 p).core_run_state0)
    ?_).trans ?_
  · show stExceptUndef_bind _ _ _ = _
    refine (stub_defined
      (z := Action CerbLocation.Loc.unknown empty_annotation
        (Load0 (mk_value_pe (Vctype intCty)) (mk_value_pe xPtrV) NA))
      (st' := (p01fam p01arF24 [meLoad x] 23 p).core_run_state0)
      ?_).trans rfl
    show stExceptUndef_bind _ _ _ = _
    refine (stub_defined (z := Vctype intCty)
      (st' := (p01fam p01arF24 [meLoad x] 23 p).core_run_state0)
      ?_).trans ?_
    · rfl
    show stExceptUndef_bind _ _ _ = _
    refine (stub_defined (z := xPtrV)
      (st' := (p01fam p01arF24 [meLoad x] 23 p).core_run_state0)
      ?_).trans rfl
    show stExceptUndef_bind _ _ _ = _
    refine (stub_defined (z := Sum.inr xPtrV)
      (st' := (p01fam p01arF24 [meLoad x] 23 p).core_run_state0)
      ?_).trans ?_
    · show runEU (eval_pexpr_aux2 p01File.tagDefs
          CerbLocation.Loc.unknown
          (some (CerbLocation.other "RelSem.callND"))
          (create_extern_symmap p01File) [p.f₁] (some p.ls) p01File
          (Pexpr aU () (PEsym symA541))) _ = _
      rw [aux2_sym_hit (a := aU) (a' := []) (z := symA541)
        (v := xPtrV) (env := [p.f₁]) rfl rfl
        (show lookup_env symA541 [p.f₁] = some xPtrV from ha)]
      rfl
    · rfl
  · rfl

/-- R25F: THE SECOND LOAD (same owned bytes; second aid drawn). -/
@[seg_round]
theorem p01r25F (x : Int) (p : T1P)
    (hget : p.ls.allocations.get? 0 = some allocX)
    (hbytes : ∀ i : Nat, (hi : i < (xBytes x).length) →
      p.ls.bytemap.get? (xAddr + (i : Int)) = some (xBytes x)[i])
    (hlum : p.ls.lastUsedUnionMembers = [])
    (hfpm : p.ls.funptrmap = [])
    (hinv : MemInv p.ls)
    (h1 : -2147483648 ≤ x) (h2 : x ≤ 2147483647) :
    app (dnmsRoundM p01File.tagDefs 0)
        (p01fam p01arF25 [meLoad x] 24 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p01fam (p01arF26 x) [meLoad x, meLoad x] 24
           { p with aS := p.aS + 1 }) := by
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

/-- R26F: the Ebound/Eannot wrapper strips (tau). -/
@[seg_round]
theorem p01r26F (x : Int) (p : T1P) :
    app (dnmsRoundM p01File.tagDefs 0)
        (p01fam (p01arF26 x) [meLoad x, meLoad x] 24 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p01fam (p01arF27 x) [meLoad x, meLoad x] 25 p) := by
  refine dnmsRoundM_adv rfl ?_
  exact (advance_tau_misc).trans rfl

/-- R27F: the Esseq binds a_542 := loaded x (BIRTH). -/
@[seg_round]
theorem p01r27F (x : Int) (p : T1P) :
    app (dnmsRoundM p01File.tagDefs 0)
        (p01fam (p01arF27 x) [meLoad x, meLoad x] 25 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p01fam p01arF28 [meLoad x, meLoad x] 26
           { p with f₁ := update_env_aux patA542 (loadedV x) p.f₁ }) := by
  refine dnmsRoundM_adv rfl ?_
  exact (advance_tau_misc).trans rfl

/-- R28F: the Erun jump — conv chain at a_542 (= x, range-checked),
    a_543 BORN. -/
@[seg_round]
theorem p01r28F (x : Int) (h1 : -2147483648 ≤ x)
    (h2 : x ≤ 2147483647) (p : T1P)
    (ha : envLookup (p01fam p01arF28 [meLoad x, meLoad x] 26 p)
      symA542 = some (loadedV x)) :
    app (dnmsRoundM p01File.tagDefs 0)
        (p01fam p01arF28 [meLoad x, meLoad x] 26 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p01fam p01arF29 [meLoad x, meLoad x] 27
           { p with f₁ :=
               (update_env_aux
                 (mk_sym_pat symA543 (BTy_loaded OTy_integer))
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
          apply (stub_defined (p01fullEval_conv p01arF28 symA542 x
            h1 h2 p.f₁ p.ls _ rfl
            (show lookup_env symA542 [p.f₁] = some (loadedV x)
              from ha))).trans
          rfl
        rfl
      rfl
  rfl

/-- R29F: a_543 evaluates (the return value = x reaches the arena). -/
@[seg_round]
theorem p01r29F (x : Int) (p : T1P)
    (ha : envLookup (p01fam p01arF29 [meLoad x, meLoad x] 27 p)
      symA543 = some (loadedV x)) :
    app (dnmsRoundM p01File.tagDefs 0)
        (p01fam p01arF29 [meLoad x, meLoad x] 27 p)
      = (NDactive (Sum.inl NOWAKEUP),
         p01fam (p01arF30 x) [meLoad x, meLoad x] 28 p) := by
  refine dnmsRoundM_adv rfl ?_
  refine (advance_runstate_eval (th' := p01Th (p01arF30 x) p.f₁)
    (rs' := (p01fam p01arF29 [meLoad x, meLoad x] 27 p).core_run_state0)
    ?_).trans ?_
  · show stExceptUndef_bind _ _ _ = _
    refine (stub_defined
      (z := Expr aU (Epure (Pexpr [] () (PEval (loadedV x)))))
      (st' := (p01fam p01arF29 [meLoad x, meLoad x] 27 p).core_run_state0)
      ?_).trans rfl
    show stExceptUndef_bind _ _ _ = _
    refine (stub_defined (z := loadedV x)
      (st' := (p01fam p01arF29 [meLoad x, meLoad x] 27 p).core_run_state0)
      ?_).trans rfl
    show stExceptUndef_bind _ _ _ = _
    refine (stub_defined (z := Sum.inr (loadedV x))
      (st' := (p01fam p01arF29 [meLoad x, meLoad x] 27 p).core_run_state0)
      ?_).trans ?_
    · show runEU (eval_pexpr_aux2 p01File.tagDefs
          CerbLocation.Loc.unknown
          (some (CerbLocation.other "RelSem.callND"))
          (create_extern_symmap p01File) [p.f₁] (some p.ls) p01File
          (Pexpr aU () (PEsym symA543))) _ = _
      rw [aux2_sym_hit (a := aU) (a' := []) (z := symA543)
        (v := loadedV x) (env := [p.f₁]) rfl rfl
        (show lookup_env symA543 [p.f₁] = some (loadedV x) from ha)]
      rfl
    · rfl
  · rfl

/-- R-terminal, FALSE side: the done offer at x. -/
@[seg_round]
theorem p01r30F (x : Int) (p : T1P) :
    app (dnmsRoundM p01File.tagDefs 0)
        (p01fam (p01arF30 x) [meLoad x, meLoad x] 28 p)
      = (NDactive (Sum.inr [Step_done2 (loadedV x)]),
         p01fam (p01arF30 x) [meLoad x, meLoad x] 28 p) := by
  refine (dnmsRoundM_inr rfl).trans ?_
  rfl

/-! ## DOUBLE-BIRTH LEGS (the tuple-bind rounds insert two cells:
    `ins b₁ v₁ (ins b₂ v₂ f)`; the ledger certifies both classes) -/

section DoubleBirth

/-- Insert shorthand at the machine spelling. -/
local notation "ins" => @fmapAddBy sym value Lem_Map.instBEqOfMapKeyType
  (@Lem_Map.mapKeyCompare sym _)

variable {b₁ b₂ : sym} {v₁ v₂ : value} {f : Fmap sym value}

theorem dbl_new₁ (hwf : EnvWfFrame f) :
    lookup_env b₁ [ins b₁ v₁ (ins b₂ v₂ f)] = some v₁ :=
  birth_new (birth_wfp hwf)

theorem dbl_new₂ (hwf : EnvWfFrame f)
    (hn₁ : ∀ z : sym, RelSem.Kit.symCmpO b₁ z = .eq →
      lookup_env z [f] = none)
    (hnum_ne : symNum b₁ ≠ symNum b₂) :
    lookup_env b₂ [ins b₁ v₁ (ins b₂ v₂ f)] = some v₂ := by
  refine birth_pres (birth_wfp hwf) ?_ b₂ v₂ (birth_new hwf)
  intro z hz
  cases hlk : lookup_env z [ins b₂ v₂ f] with
  | none => rfl
  | some vz =>
    exfalso
    rcases birth_rev hwf z vz hlk with ⟨v₀, hv₀⟩ | hnum
    · rw [hn₁ z hz] at hv₀; cases hv₀
    · obtain ⟨d1, n1, s1⟩ := b₁
      obtain ⟨d2, n2, s2⟩ := b₂
      obtain ⟨dz, nz, sz⟩ := z
      obtain ⟨-, hn⟩ := (RelSem.Kit.symCmpO_eq_iff d1 dz n1 nz
        s1 sz).1 hz
      simp [symNum] at hnum hnum_ne
      omega

theorem dbl_pres (hwf : EnvWfFrame f)
    (hn₁ : ∀ z : sym, RelSem.Kit.symCmpO b₁ z = .eq →
      lookup_env z [f] = none)
    (hn₂ : ∀ z : sym, RelSem.Kit.symCmpO b₂ z = .eq →
      lookup_env z [f] = none)
    (hnum_ne : symNum b₁ ≠ symNum b₂) :
    ∀ z v', lookup_env z [f] = some v' →
      lookup_env z [ins b₁ v₁ (ins b₂ v₂ f)] = some v' := by
  intro z v' hz
  refine birth_pres (birth_wfp hwf) ?_ z v'
    (birth_pres hwf hn₂ z v' hz)
  intro w hw
  cases hlk : lookup_env w [ins b₂ v₂ f] with
  | none => rfl
  | some vw =>
    exfalso
    rcases birth_rev hwf w vw hlk with ⟨v₀, hv₀⟩ | hnum
    · rw [hn₁ w hw] at hv₀; cases hv₀
    · -- w in b₁'s cmp-class and b₂'s num-class: then a b₂-num sym
      -- would be f-bound at z... derive via hn₁ again
      obtain ⟨d1, n1, s1⟩ := b₁
      obtain ⟨d2, n2, s2⟩ := b₂
      obtain ⟨dw, nw, sw⟩ := w
      obtain ⟨-, hnw⟩ := (RelSem.Kit.symCmpO_eq_iff d1 dw n1 nw
        s1 sw).1 hw
      simp [symNum] at hnum hnum_ne
      omega

theorem dbl_rev (hwf : EnvWfFrame f) :
    ∀ z v', lookup_env z [ins b₁ v₁ (ins b₂ v₂ f)] = some v' →
      (∃ v₀, lookup_env z [f] = some v₀) ∨ symNum z = symNum b₁ ∨
        symNum z = symNum b₂ := by
  intro z v' hz
  rcases birth_rev (birth_wfp hwf) z v' hz with ⟨v₀, hv₀⟩ | hnum
  · rcases birth_rev hwf z v₀ hv₀ with ⟨v₁', hv₁⟩ | hnum2
    · exact Or.inl ⟨v₁', hv₁⟩
    · exact Or.inr (Or.inr hnum2)
  · exact Or.inr (Or.inl hnum)

theorem dbl_wfp (hwf : EnvWfFrame f) :
    EnvWfFrame (ins b₁ v₁ (ins b₂ v₂ f)) :=
  birth_wfp (birth_wfp hwf)

end DoubleBirth

/-- Ledger-to-class emptiness: a fresh number's whole comparator
    class is unbound (the hsh feeder for every birth leg). -/
theorem clsNone {f : Fmap sym value} {d : List Int} {b : sym}
    (hdm : ∀ z v, lookup_env z [f] = some v → symNum z ∈ d)
    (hfresh : symNum b ∉ d) :
    ∀ z : sym, RelSem.Kit.symCmpO b z = .eq →
      lookup_env z [f] = none := by
  intro z hz
  cases hlk : lookup_env z [f] with
  | none => rfl
  | some vz =>
    exfalso
    have hin := hdm z vz hlk
    obtain ⟨d1, n1, s1⟩ := b
    obtain ⟨dz, nz, sz⟩ := z
    obtain ⟨-, hn⟩ := (RelSem.Kit.symCmpO_eq_iff d1 dz n1 nz
      s1 sz).1 hz
    apply hfresh
    rw [show symNum (Symbol d1 n1 s1) = ((n1 : Int)) from rfl, hn]
    exact hin
