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

