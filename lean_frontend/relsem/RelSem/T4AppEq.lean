/-
  RelSem.T4AppEq — arc-7 S5a (2026-08-20): THE T4 HARNESS APP EQUATION
  (theorem half; the probe-transcribed state terms live in
  RelSem/T4Defs.lean — see its header for the discovery record and the
  TAG-GLOBAL BOUNDARY honesty note, which applies to every
  htags-hypothesized lemma below).

  House rules: no sorry, no axioms, no Iris imports. Under the
  in-build audit (imported by RelSem.T4).
-/

import RelSem.T4Defs

set_option autoImplicit false

namespace RelSem.T4

open RelSem RelSem.Cerb RelSem.Slate
open RelSem.T1 (aU intCty loadedV xIntV mkByte roundtrip_arith zeroByte
  uninitByte patUnit loadE RExpr
  sizeof_int_eq alignof_int_eq sizeof_intCty_eq z0 z1 z2 z3 z4
  convLoadedIntSym convIntSym isReprIntegerSym errStore_bytes_fact)
-- (arc-9 S2: the generic eval/round crossings moved to the Kit)
open RelSem.Kit (eubind_defined stub_defined eumapM_one
  liftCore_run_defined aux2_step aux2_done perform_unfold ars_load_unfold)
open RelSem.T2 (storeArg_bytes_fact)
open RelSem.Kit (ars_create_unfold ars_store_unfold ars_kill_unfold)


/-! ## Layout facts under the tag-global hypothesis -/

/-- The struct's alignment at the fuel the size computation passes. -/
theorem alignofS_fuel_fact (htags : CerbTags.tagDefs () = t4File.tagDefs) :
    CerbMem.alignofCtype_lemFuel 999999
      (Ctype [] (Struct structSSym)) = 4 := by
  rw [CerbMem.alignofCtype_lemFuel, htags]
  rfl

/-- The struct's size under the pinned tag table. -/
theorem sizeofS_fact (htags : CerbTags.tagDefs () = t4File.tagDefs) :
    CerbMem.sizeofCtype structSCty = 8 := by
  show CerbMem.sizeofCtype_lemFuel (999999+1)
    (Ctype [] (Struct structSSym)) = 8
  rw [CerbMem.sizeofCtype_lemFuel, htags, alignofS_fuel_fact htags]
  rfl

/-- The struct's alignment (as an ival — the Civalignof result). -/
theorem alignS_fact (htags : CerbTags.tagDefs () = t4File.tagDefs) :
    CerbMem.alignofIval structSCty
      = CerbMem.IntegerValue.IV .Prov_none 4 := by
  unfold CerbMem.alignofIval
  show CerbMem.integerIval (CerbMem.alignofCtype_lemFuel (999999+1)
    (Ctype [] (Struct structSSym))) = _
  rw [CerbMem.alignofCtype_lemFuel, htags]
  rfl

/-- member_shift .a = +0. -/
theorem shiftA_fact (htags : CerbTags.tagDefs () = t4File.tagDefs) :
    CerbMem.memberShiftPtrval sPtr structSSym
      (Identifier CerbLocation.Loc.unknown "a") = sPtr := by
  unfold CerbMem.memberShiftPtrval
  rw [htags]
  rfl

/-- member_shift .b = +4. -/
theorem shiftB_fact (htags : CerbTags.tagDefs () = t4File.tagDefs) :
    CerbMem.memberShiftPtrval sPtr structSSym
      (Identifier CerbLocation.Loc.unknown "b") = bPtr := by
  unfold CerbMem.memberShiftPtrval
  rw [htags]
  rfl

/-- The unspecified-struct byte image (8 padding bytes). -/
theorem unspecBytes_fact (htags : CerbTags.tagDefs () = t4File.tagDefs) :
    CerbMem.memValueToBytes [] (.MVunspecified structSCty)
      = ([], [CerbMem.paddingByte, CerbMem.paddingByte, CerbMem.paddingByte,
              CerbMem.paddingByte, CerbMem.paddingByte, CerbMem.paddingByte,
              CerbMem.paddingByte, CerbMem.paddingByte]) := by
  show CerbMem.memValueToBytes_lemFuel (999999+1) []
    (.MVunspecified (Ctype [] (Struct structSSym))) = _
  rw [CerbMem.memValueToBytes_lemFuel,
    show CerbMem.sizeofCtype (Ctype [] (Struct structSSym)) = 8
      from sizeofS_fact htags]
  rfl

/-! ## Stuck-form arena variants (the pure-eval rounds produce values
    the kernel cannot reduce past the tag-global read; the producing
    round rewrites the target state to this spelling via the layout
    fact, then walks by rfl) -/

def arena01stuck : RExpr :=
  (Expr aU (Esseq (Pattern aU (CaseBase (some symS, (BTy_object OTy_pointer)))) (Expr aU (Eaction (Paction Pos (Action CerbLocation.Loc.unknown empty_annotation (Create (Pexpr [] () (PEval (Vobject (OVinteger (CerbMem.alignofIval structSCty))))) (Pexpr [] () (PEval (Vctype structSCty))) (PrefOther "Core")))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Eaction (Paction Pos (Action CerbLocation.Loc.unknown empty_annotation (Store0 false (Pexpr aU () (PEval (Vctype structSCty))) (Pexpr aU () (PEsym symS)) (Pexpr aU () (PEctor Cunspecified [(Pexpr aU () (PEval (Vctype structSCty)))])) NA))))) (Expr aU (Esseq (Pattern aU (CaseBase (none, (BTy_loaded OTy_integer)))) (Expr aU (Ebound (Expr aU (Ewseq (Pattern aU (CaseCtor Ctuple [(Pattern aU (CaseBase (some symA499, (BTy_object OTy_pointer)))), (Pattern aU (CaseBase (some symA502, (BTy_loaded OTy_integer))))])) (Expr aU (Eunseq [(Expr aU (Esseq (Pattern aU (CaseBase (some symA500, (BTy_object OTy_pointer)))) (Expr aU (Epure (Pexpr aU () (PEsym symS)))) (Expr aU (Epure (Pexpr aU () (PEmember_shift (Pexpr aU () (PEsym symA500)) structSSym (Identifier CerbLocation.Loc.unknown "a"))))))), (Expr aU (Ewseq (Pattern aU (CaseBase (some symA501, (BTy_object OTy_pointer)))) (Expr aU (Epure (Pexpr aU () (PEsym symV)))) (Expr aU (Eaction (Paction Pos (Action CerbLocation.Loc.unknown empty_annotation (Load0 (Pexpr aU () (PEval (Vctype intCty))) (Pexpr aU () (PEsym symA501)) NA)))))))])) (Expr aU (Ewseq (Pattern aU (CaseBase (none, BTy_unit))) (Expr aU (Eaction (Paction Neg0 (Action CerbLocation.Loc.unknown empty_annotation (Store0 false (Pexpr aU () (PEval (Vctype intCty))) (Pexpr aU () (PEsym symA499)) (Pexpr aU () (PEcall (Sym convLoadedIntSym) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym symA502))])) NA))))) (Expr aU (Epure (Pexpr aU () (PEcall (Sym convLoadedIntSym) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym symA502))])))))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Epure (Pexpr aU () (PEval Vunit)))) (Expr aU (Esseq (Pattern aU (CaseBase (none, (BTy_loaded OTy_integer)))) (Expr aU (Ebound (Expr aU (Ewseq (Pattern aU (CaseCtor Ctuple [(Pattern aU (CaseBase (some symA503, (BTy_object OTy_pointer)))), (Pattern aU (CaseBase (some symA505, (BTy_loaded OTy_integer))))])) (Expr aU (Eunseq [(Expr aU (Esseq (Pattern aU (CaseBase (some symA504, (BTy_object OTy_pointer)))) (Expr aU (Epure (Pexpr aU () (PEsym symS)))) (Expr aU (Epure (Pexpr aU () (PEmember_shift (Pexpr aU () (PEsym symA504)) structSSym (Identifier CerbLocation.Loc.unknown "b"))))))), (Expr aU (Epure (Pexpr aU () (PEctor Cspecified [(Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none 7)))))]))))])) (Expr aU (Ewseq (Pattern aU (CaseBase (none, BTy_unit))) (Expr aU (Eaction (Paction Neg0 (Action CerbLocation.Loc.unknown empty_annotation (Store0 false (Pexpr aU () (PEval (Vctype intCty))) (Pexpr aU () (PEsym symA503)) (Pexpr aU () (PEcall (Sym convLoadedIntSym) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym symA505))])) NA))))) (Expr aU (Epure (Pexpr aU () (PEcall (Sym convLoadedIntSym) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym symA505))])))))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Epure (Pexpr aU () (PEval Vunit)))) (Expr aU (Esseq (Pattern aU (CaseBase (some symA508, (BTy_loaded OTy_integer)))) (Expr aU (Ebound (Expr aU (Ewseq (Pattern aU (CaseBase (some symA507, (BTy_object OTy_pointer)))) (Expr aU (Esseq (Pattern aU (CaseBase (some symA506, (BTy_object OTy_pointer)))) (Expr aU (Epure (Pexpr aU () (PEsym symS)))) (Expr aU (Epure (Pexpr aU () (PEmember_shift (Pexpr aU () (PEsym symA506)) structSSym (Identifier CerbLocation.Loc.unknown "a"))))))) (Expr aU (Eaction (Paction Pos (Action CerbLocation.Loc.unknown empty_annotation (Load0 (Pexpr aU () (PEval (Vctype intCty))) (Pexpr aU () (PEsym symA507)) NA))))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Eaction (Paction Pos (Action CerbLocation.Loc.unknown empty_annotation (Kill (Static0 structSCty) (Pexpr aU () (PEsym symS))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Erun empty_annotation symRet498 [(Pexpr aU () (PEcall (Sym convLoadedIntSym) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym symA508))]))])) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Eaction (Paction Pos (Action CerbLocation.Loc.unknown empty_annotation (Kill (Static0 structSCty) (Pexpr aU () (PEsym symS))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Epure (Pexpr aU () (PEval Vunit)))) (Expr aU (Esave (symRet498, (BTy_loaded OTy_integer)) [(symA509, (((BTy_loaded OTy_integer), none), (Pexpr aU () (PEundef CerbLocation.Loc.unknown (DUMMY "UB088_reached_end_of_function")))))] (Expr aU (Epure (Pexpr aU () (PEsym symA509))))))))))))))))))))))))))))

def arena13stuck (x : Int) : RExpr :=
  (Expr [] (Eannot [(DA_pos [] (CerbMem.Footprint.FP .W 281474976710636 8))] (Expr aU (Esseq (Pattern aU (CaseBase (none, (BTy_loaded OTy_integer)))) (Expr aU (Ebound (Expr aU (Ewseq (Pattern aU (CaseCtor Ctuple [(Pattern aU (CaseBase (some symA499, (BTy_object OTy_pointer)))), (Pattern aU (CaseBase (some symA502, (BTy_loaded OTy_integer))))])) (Expr aU (Eunseq [(Expr aU (Epure (Pexpr [] () (PEval (Vobject (OVpointer (CerbMem.memberShiftPtrval sPtr structSSym (Identifier CerbLocation.Loc.unknown "a")))))))), (Expr [] (Eannot [(DA_pos [] (CerbMem.Footprint.FP .R 281474976710648 4))] (Expr [] (Epure (Pexpr [] () (PEval (loadedV x)))))))])) (Expr aU (Ewseq (Pattern aU (CaseBase (none, BTy_unit))) (Expr aU (Eaction (Paction Neg0 (Action CerbLocation.Loc.unknown empty_annotation (Store0 false (Pexpr aU () (PEval (Vctype intCty))) (Pexpr aU () (PEsym symA499)) (Pexpr aU () (PEcall (Sym convLoadedIntSym) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym symA502))])) NA))))) (Expr aU (Epure (Pexpr aU () (PEcall (Sym convLoadedIntSym) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym symA502))])))))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Epure (Pexpr aU () (PEval Vunit)))) (Expr aU (Esseq (Pattern aU (CaseBase (none, (BTy_loaded OTy_integer)))) (Expr aU (Ebound (Expr aU (Ewseq (Pattern aU (CaseCtor Ctuple [(Pattern aU (CaseBase (some symA503, (BTy_object OTy_pointer)))), (Pattern aU (CaseBase (some symA505, (BTy_loaded OTy_integer))))])) (Expr aU (Eunseq [(Expr aU (Esseq (Pattern aU (CaseBase (some symA504, (BTy_object OTy_pointer)))) (Expr aU (Epure (Pexpr aU () (PEsym symS)))) (Expr aU (Epure (Pexpr aU () (PEmember_shift (Pexpr aU () (PEsym symA504)) structSSym (Identifier CerbLocation.Loc.unknown "b"))))))), (Expr aU (Epure (Pexpr aU () (PEctor Cspecified [(Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none 7)))))]))))])) (Expr aU (Ewseq (Pattern aU (CaseBase (none, BTy_unit))) (Expr aU (Eaction (Paction Neg0 (Action CerbLocation.Loc.unknown empty_annotation (Store0 false (Pexpr aU () (PEval (Vctype intCty))) (Pexpr aU () (PEsym symA503)) (Pexpr aU () (PEcall (Sym convLoadedIntSym) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym symA505))])) NA))))) (Expr aU (Epure (Pexpr aU () (PEcall (Sym convLoadedIntSym) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym symA505))])))))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Epure (Pexpr aU () (PEval Vunit)))) (Expr aU (Esseq (Pattern aU (CaseBase (some symA508, (BTy_loaded OTy_integer)))) (Expr aU (Ebound (Expr aU (Ewseq (Pattern aU (CaseBase (some symA507, (BTy_object OTy_pointer)))) (Expr aU (Esseq (Pattern aU (CaseBase (some symA506, (BTy_object OTy_pointer)))) (Expr aU (Epure (Pexpr aU () (PEsym symS)))) (Expr aU (Epure (Pexpr aU () (PEmember_shift (Pexpr aU () (PEsym symA506)) structSSym (Identifier CerbLocation.Loc.unknown "a"))))))) (Expr aU (Eaction (Paction Pos (Action CerbLocation.Loc.unknown empty_annotation (Load0 (Pexpr aU () (PEval (Vctype intCty))) (Pexpr aU () (PEsym symA507)) NA))))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Eaction (Paction Pos (Action CerbLocation.Loc.unknown empty_annotation (Kill (Static0 structSCty) (Pexpr aU () (PEsym symS))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Erun empty_annotation symRet498 [(Pexpr aU () (PEcall (Sym convLoadedIntSym) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym symA508))]))])) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Eaction (Paction Pos (Action CerbLocation.Loc.unknown empty_annotation (Kill (Static0 structSCty) (Pexpr aU () (PEsym symS))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Epure (Pexpr aU () (PEval Vunit)))) (Expr aU (Esave (symRet498, (BTy_loaded OTy_integer)) [(symA509, (((BTy_loaded OTy_integer), none), (Pexpr aU () (PEundef CerbLocation.Loc.unknown (DUMMY "UB088_reached_end_of_function")))))] (Expr aU (Epure (Pexpr aU () (PEsym symA509))))))))))))))))))))))))))

def arena30stuck : RExpr :=
  (Expr [] (Eannot [(DA_pos [] (CerbMem.Footprint.FP .W 281474976710636 8))] (Expr aU (Esseq (Pattern aU (CaseBase (none, (BTy_loaded OTy_integer)))) (Expr aU (Ebound (Expr aU (Ewseq (Pattern aU (CaseCtor Ctuple [(Pattern aU (CaseBase (some symA503, (BTy_object OTy_pointer)))), (Pattern aU (CaseBase (some symA505, (BTy_loaded OTy_integer))))])) (Expr aU (Eunseq [(Expr aU (Epure (Pexpr [] () (PEval (Vobject (OVpointer (CerbMem.memberShiftPtrval sPtr structSSym (Identifier CerbLocation.Loc.unknown "b")))))))), (Expr aU (Epure (Pexpr [] () (PEval (Vloaded (LVspecified (OVinteger (.IV .Prov_none 7))))))))])) (Expr aU (Ewseq (Pattern aU (CaseBase (none, BTy_unit))) (Expr aU (Eaction (Paction Neg0 (Action CerbLocation.Loc.unknown empty_annotation (Store0 false (Pexpr aU () (PEval (Vctype intCty))) (Pexpr aU () (PEsym symA503)) (Pexpr aU () (PEcall (Sym convLoadedIntSym) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym symA505))])) NA))))) (Expr aU (Epure (Pexpr aU () (PEcall (Sym convLoadedIntSym) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym symA505))])))))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Epure (Pexpr aU () (PEval Vunit)))) (Expr aU (Esseq (Pattern aU (CaseBase (some symA508, (BTy_loaded OTy_integer)))) (Expr aU (Ebound (Expr aU (Ewseq (Pattern aU (CaseBase (some symA507, (BTy_object OTy_pointer)))) (Expr aU (Esseq (Pattern aU (CaseBase (some symA506, (BTy_object OTy_pointer)))) (Expr aU (Epure (Pexpr aU () (PEsym symS)))) (Expr aU (Epure (Pexpr aU () (PEmember_shift (Pexpr aU () (PEsym symA506)) structSSym (Identifier CerbLocation.Loc.unknown "a"))))))) (Expr aU (Eaction (Paction Pos (Action CerbLocation.Loc.unknown empty_annotation (Load0 (Pexpr aU () (PEval (Vctype intCty))) (Pexpr aU () (PEsym symA507)) NA))))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Eaction (Paction Pos (Action CerbLocation.Loc.unknown empty_annotation (Kill (Static0 structSCty) (Pexpr aU () (PEsym symS))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Erun empty_annotation symRet498 [(Pexpr aU () (PEcall (Sym convLoadedIntSym) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym symA508))]))])) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Eaction (Paction Pos (Action CerbLocation.Loc.unknown empty_annotation (Kill (Static0 structSCty) (Pexpr aU () (PEsym symS))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Epure (Pexpr aU () (PEval Vunit)))) (Expr aU (Esave (symRet498, (BTy_loaded OTy_integer)) [(symA509, (((BTy_loaded OTy_integer), none), (Pexpr aU () (PEundef CerbLocation.Loc.unknown (DUMMY "UB088_reached_end_of_function")))))] (Expr aU (Epure (Pexpr aU () (PEsym symA509))))))))))))))))))))))

def arena46stuck : RExpr :=
  (Expr [] (Eannot [(DA_pos [] (CerbMem.Footprint.FP .W 281474976710636 8))] (Expr aU (Esseq (Pattern aU (CaseBase (some symA508, (BTy_loaded OTy_integer)))) (Expr aU (Ebound (Expr aU (Ewseq (Pattern aU (CaseBase (some symA507, (BTy_object OTy_pointer)))) (Expr aU (Epure (Pexpr [] () (PEval (Vobject (OVpointer (CerbMem.memberShiftPtrval sPtr structSSym (Identifier CerbLocation.Loc.unknown "a")))))))) (Expr aU (Eaction (Paction Pos (Action CerbLocation.Loc.unknown empty_annotation (Load0 (Pexpr aU () (PEval (Vctype intCty))) (Pexpr aU () (PEsym symA507)) NA))))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Eaction (Paction Pos (Action CerbLocation.Loc.unknown empty_annotation (Kill (Static0 structSCty) (Pexpr aU () (PEsym symS))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Erun empty_annotation symRet498 [(Pexpr aU () (PEcall (Sym convLoadedIntSym) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym symA508))]))])) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Eaction (Paction Pos (Action CerbLocation.Loc.unknown empty_annotation (Kill (Static0 structSCty) (Pexpr aU () (PEsym symS))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Epure (Pexpr aU () (PEval Vunit)))) (Expr aU (Esave (symRet498, (BTy_loaded OTy_integer)) [(symA509, (((BTy_loaded OTy_integer), none), (Pexpr aU () (PEundef CerbLocation.Loc.unknown (DUMMY "UB088_reached_end_of_function")))))] (Expr aU (Epure (Pexpr aU () (PEsym symA509))))))))))))))))))

theorem arena01_stuck (htags : CerbTags.tagDefs () = t4File.tagDefs) :
    arena01stuck = arena01 := by
  unfold arena01stuck arena01
  rw [alignS_fact htags]
theorem arena13_stuck (htags : CerbTags.tagDefs () = t4File.tagDefs)
    (x : Int) : arena13stuck x = arena13 x := by
  unfold arena13stuck arena13
  rw [shiftA_fact htags]; rfl
theorem arena30_stuck (htags : CerbTags.tagDefs () = t4File.tagDefs) :
    arena30stuck = arena30 := by
  unfold arena30stuck arena30
  rw [shiftB_fact htags]; rfl
theorem arena46_stuck (htags : CerbTags.tagDefs () = t4File.tagDefs) :
    arena46stuck = arena46 := by
  unfold arena46stuck arena46
  rw [shiftA_fact htags]; rfl

/-! ## Memory-op equations -/

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

/-- R1's allocation: struct s (size/layout under htags). -/
theorem createS_eq (htags : CerbTags.tagDefs () = t4File.tagDefs) (x : Int) :
    app (CerbMem.allocateObject 0 (PrefOther "Core")
      (CerbMem.IntegerValue.IV .Prov_none 4) structSCty none none) (memD3 x)
    = (NDactive sPtr, memC x) := by
  simp only [CerbMem.allocateObject, CerbMem.integerIval,
    app, memD3, memC, bmC, sizeofS_fact htags, sPtr, sAddr, errAddr, vAddr,
    allocS, uninitByte, CerbMem.initialMemState]
  simp [CerbMem.alignDown, CerbMem.writeBytesTo, List.replicate]

theorem storeS_get_fact :
    ((((Std.TreeMap.empty.insert 0 allocV).insert 1 allocErr).insert 2 allocS :
        Std.TreeMap Int CerbMem.Allocation)).get? 2 = some allocS := rfl

/-- R4's store: the unspecified struct image. -/
theorem storeU_eq (htags : CerbTags.tagDefs () = t4File.tagDefs) (x : Int) :
    app (CerbMem.storeM CerbLocation.Loc.unknown structSCty false
      sPtr (CerbMem.MemValue.MVunspecified structSCty)) (memC x)
    = (NDactive (CerbMem.Footprint.FP .W sAddr 8), memU x) := by
  simp only [CerbMem.storeM, app, sizeofS_fact htags, sPtr,
    show (memC x).allocations.get? 2 = some allocS from rfl,
    show (memC x).funptrmap = ([] : CerbMem.Funptrmap) from rfl,
    unspecBytes_fact htags,
    show CerbMem.ctypeMemCompatible structSCty
      (CerbMem.typeofMval (CerbMem.MemValue.MVunspecified structSCty)) = true
      from rfl,
    show CerbMem.isAtomicMemberAccess allocS structSCty sAddr = false from rfl,
    show allocS.isReadonly = CerbMem.ReadonlyStatus.IsWritable from rfl,
    Bool.not_true, Bool.false_eq_true, if_false]
  rfl

/-- R19's store: s.a := v (int store at the .a offset). -/
theorem storeA_eq (x : Int) :
    app (CerbMem.storeM CerbLocation.Loc.unknown intCty false
      sPtr (CerbMem.MemValue.MVinteger (Signed Int_)
        (CerbMem.IntegerValue.IV .Prov_none x))) (memU x)
    = (NDactive (CerbMem.Footprint.FP .W sAddr 4), memA x) := by
  simp +decide only [CerbMem.storeM, app, sizeof_intCty_eq, sPtr,
    storeArg_bytes_fact, storeS_get_fact]
  rfl

/-- R36's store: s.b := 7. -/
theorem storeB_eq (x : Int) :
    app (CerbMem.storeM CerbLocation.Loc.unknown intCty false
      bPtr (CerbMem.MemValue.MVinteger (Signed Int_)
        (CerbMem.IntegerValue.IV .Prov_none 7))) (memA x)
    = (NDactive (CerbMem.Footprint.FP .W bAddr 4), memB x) := by
  simp +decide only [CerbMem.storeM, app, sizeof_intCty_eq, bPtr,
    storeArg_bytes_fact, storeS_get_fact]
  rfl

/-! ### The two loads (R9: v on memU; R48: s.a on memB) -/

theorem bmU_get0 (x : Int) :
    (memU x).bytemap[(281474976710648 : Int)]? = some (mkByte x 0) := by
  simp +decide only [memU, bmU, bmC, bmD3, bmErrAlloc, bmV, bmAllocV,
    vAddr, errAddr, sAddr, bAddr, Std.TreeMap.getElem?_insert,
    Std.TreeMap.getElem?_insert_self, if_true, if_false]
theorem bmU_get1 (x : Int) :
    (memU x).bytemap[(281474976710649 : Int)]? = some (mkByte x 1) := by
  simp +decide only [memU, bmU, bmC, bmD3, bmErrAlloc, bmV, bmAllocV,
    vAddr, errAddr, sAddr, bAddr, Std.TreeMap.getElem?_insert,
    Std.TreeMap.getElem?_insert_self, if_true, if_false]
theorem bmU_get2 (x : Int) :
    (memU x).bytemap[(281474976710650 : Int)]? = some (mkByte x 2) := by
  simp +decide only [memU, bmU, bmC, bmD3, bmErrAlloc, bmV, bmAllocV,
    vAddr, errAddr, sAddr, bAddr, Std.TreeMap.getElem?_insert,
    Std.TreeMap.getElem?_insert_self, if_true, if_false]
theorem bmU_get3 (x : Int) :
    (memU x).bytemap[(281474976710651 : Int)]? = some (mkByte x 3) := by
  simp +decide only [memU, bmU, bmC, bmD3, bmErrAlloc, bmV, bmAllocV,
    vAddr, errAddr, sAddr, bAddr, Std.TreeMap.getElem?_insert,
    Std.TreeMap.getElem?_insert_self, if_true, if_false]

theorem loadV_bytes_fact (x : Int) :
    CerbMem.readBytesFrom (memU x) 281474976710648 4
    = [mkByte x 0, mkByte x 1, mkByte x 2, mkByte x 3] := by
  simp [CerbMem.readBytesFrom, List.range, List.range.loop,
    bmU_get0 x, bmU_get1 x, bmU_get2 x, bmU_get3 x]

theorem loadV_get_fact (x : Int) :
    (memU x).allocations[(0 : Int)]? = some allocV := rfl
theorem loadV_dead_fact (x : Int) :
    (memU x).deadAllocations.contains 0 = false := rfl

theorem reconV_eq (x : Int) (h1 : -2147483648 ≤ x) (h2 : x ≤ 2147483647) :
    CerbMem.reconstructValue (memU x).lastUsedUnionMembers
      (memU x).funptrmap 281474976710648 intCty
      [mkByte x 0, mkByte x 1, mkByte x 2, mkByte x 3]
    = .MVinteger (Signed Int_) (.IV .Prov_none x) := by
  show CerbMem.reconstructValue_lemFuel (999999+1) _ _ _
    (Ctype [] (Basic (Integer (Signed Int_)))) _ = _
  rw [CerbMem.reconstructValue_lemFuel]
  simp only [CerberusImpl.is_signed_ity]
  rw [roundtrip_arith x h1 h2]
  simp [CerbMem.provFromIntegerBytes, CerbMem.combineProv, mkByte]

theorem loadV_eq (x : Int) (h1 : -2147483648 ≤ x) (h2 : x ≤ 2147483647) :
    app (CerbMem.loadM CerbLocation.Loc.unknown intCty vPtr) (memU x)
    = (NDactive (CerbMem.Footprint.FP .R vAddr 4,
        CerbMem.MemValue.MVinteger (Signed Int_) (.IV .Prov_none x)),
       memU x) := by
  simp only [CerbMem.loadM, app, vPtr, vAddr, sizeof_intCty_eq,
    loadV_dead_fact x, loadV_bytes_fact x, reconV_eq x h1 h2]
  simp [loadV_get_fact x, intCty,
    show CerbMem.isInBounds allocV 281474976710648 4 = true from rfl,
    show CerbMem.isAtomicMemberAccess allocV
      (Ctype [] (Basic (Integer (Signed Int_)))) 281474976710648 = false
      from rfl]

theorem bmB_get0 (x : Int) :
    (memB x).bytemap[(281474976710636 : Int)]? = some (mkByte x 0) := by
  simp +decide only [memB, bmB, bmA, bmU, bmC, bmD3, bmErrAlloc, bmV,
    bmAllocV, vAddr, errAddr, sAddr, bAddr, Std.TreeMap.getElem?_insert,
    Std.TreeMap.getElem?_insert_self, if_true, if_false]
theorem bmB_get1 (x : Int) :
    (memB x).bytemap[(281474976710637 : Int)]? = some (mkByte x 1) := by
  simp +decide only [memB, bmB, bmA, bmU, bmC, bmD3, bmErrAlloc, bmV,
    bmAllocV, vAddr, errAddr, sAddr, bAddr, Std.TreeMap.getElem?_insert,
    Std.TreeMap.getElem?_insert_self, if_true, if_false]
theorem bmB_get2 (x : Int) :
    (memB x).bytemap[(281474976710638 : Int)]? = some (mkByte x 2) := by
  simp +decide only [memB, bmB, bmA, bmU, bmC, bmD3, bmErrAlloc, bmV,
    bmAllocV, vAddr, errAddr, sAddr, bAddr, Std.TreeMap.getElem?_insert,
    Std.TreeMap.getElem?_insert_self, if_true, if_false]
theorem bmB_get3 (x : Int) :
    (memB x).bytemap[(281474976710639 : Int)]? = some (mkByte x 3) := by
  simp +decide only [memB, bmB, bmA, bmU, bmC, bmD3, bmErrAlloc, bmV,
    bmAllocV, vAddr, errAddr, sAddr, bAddr, Std.TreeMap.getElem?_insert,
    Std.TreeMap.getElem?_insert_self, if_true, if_false]

theorem loadA_bytes_fact (x : Int) :
    CerbMem.readBytesFrom (memB x) 281474976710636 4
    = [mkByte x 0, mkByte x 1, mkByte x 2, mkByte x 3] := by
  simp [CerbMem.readBytesFrom, List.range, List.range.loop,
    bmB_get0 x, bmB_get1 x, bmB_get2 x, bmB_get3 x]

theorem loadA_get_fact (x : Int) :
    (memB x).allocations[(2 : Int)]? = some allocS := rfl
theorem loadA_dead_fact (x : Int) :
    (memB x).deadAllocations.contains 2 = false := rfl

theorem reconA_eq (x : Int) (h1 : -2147483648 ≤ x) (h2 : x ≤ 2147483647) :
    CerbMem.reconstructValue (memB x).lastUsedUnionMembers
      (memB x).funptrmap 281474976710636 intCty
      [mkByte x 0, mkByte x 1, mkByte x 2, mkByte x 3]
    = .MVinteger (Signed Int_) (.IV .Prov_none x) := by
  show CerbMem.reconstructValue_lemFuel (999999+1) _ _ _
    (Ctype [] (Basic (Integer (Signed Int_)))) _ = _
  rw [CerbMem.reconstructValue_lemFuel]
  simp only [CerberusImpl.is_signed_ity]
  rw [roundtrip_arith x h1 h2]
  simp [CerbMem.provFromIntegerBytes, CerbMem.combineProv, mkByte]

/-- R48: the s.a load — THE struct-layout points-to payoff (the value
    written through .a survives the .b write at the sibling offset). -/
theorem loadA_eq (x : Int) (h1 : -2147483648 ≤ x) (h2 : x ≤ 2147483647) :
    app (CerbMem.loadM CerbLocation.Loc.unknown intCty sPtr) (memB x)
    = (NDactive (CerbMem.Footprint.FP .R sAddr 4,
        CerbMem.MemValue.MVinteger (Signed Int_) (.IV .Prov_none x)),
       memB x) := by
  simp only [CerbMem.loadM, app, sPtr, sAddr, sizeof_intCty_eq,
    loadA_dead_fact x, loadA_bytes_fact x, reconA_eq x h1 h2]
  simp [loadA_get_fact x, intCty,
    show CerbMem.isInBounds allocS 281474976710636 4 = true from rfl,
    show CerbMem.isAtomicMemberAccess allocS
      (Ctype [] (Basic (Integer (Signed Int_)))) 281474976710636 = false
      from rfl]

/-- R52's kill. -/
theorem killS_eq (x : Int) :
    app (CerbMem.killM CerbLocation.Loc.unknown false sPtr) (memB x)
    = (NDactive (), memK x) := by
  simp +decide only [CerbMem.killM, app, sPtr, storeS_get_fact,
    show ((memB x).deadAllocations.contains 2) = false from rfl,
    show ((memB x).allocations.get? 2) = some allocS from rfl]
  rfl

/-! ## Round lemmas (plain frame-parametric rounds; specials follow) -/

theorem round2 (fuel : Nat) (mem : CerbMem.MemState)
    (rs : core_run_state) (tr : List trace_event) (n : Nat) :
    app (dnms (fuel+1) fmapEmpty [0]) (mkDr th02 mem rs tr n)
      = app (dnms fuel fmapEmpty [0]) (mkDr th03 mem rs tr (n+1)) := by
  refine (app_bind_active rfl).trans ?_
  refine (app_bind_active rfl).trans ?_
  rfl

theorem round3 (fuel : Nat) (mem : CerbMem.MemState)
    (rs : core_run_state) (tr : List trace_event) (n : Nat) :
    app (dnms (fuel+1) fmapEmpty [0]) (mkDr th03 mem rs tr n)
      = app (dnms fuel fmapEmpty [0]) (mkDr th04 mem rs tr (n+1)) := by
  refine (app_bind_active rfl).trans ?_
  refine (app_bind_active rfl).trans ?_
  rfl

theorem round5 (fuel : Nat) (mem : CerbMem.MemState)
    (rs : core_run_state) (tr : List trace_event) (n : Nat) :
    app (dnms (fuel+1) fmapEmpty [0]) (mkDr th05 mem rs tr n)
      = app (dnms fuel fmapEmpty [0]) (mkDr th06 mem rs tr (n+1)) := by
  refine (app_bind_active rfl).trans ?_
  refine (app_bind_active rfl).trans ?_
  rfl

theorem round6 (fuel : Nat) (mem : CerbMem.MemState)
    (rs : core_run_state) (tr : List trace_event) (n : Nat) :
    app (dnms (fuel+1) fmapEmpty [0]) (mkDr th06 mem rs tr n)
      = app (dnms fuel fmapEmpty [0]) (mkDr th07 mem rs tr (n+1)) := by
  refine (app_bind_active rfl).trans ?_
  refine (app_bind_active rfl).trans ?_
  rfl

theorem round7 (fuel : Nat) (mem : CerbMem.MemState)
    (rs : core_run_state) (tr : List trace_event) (n : Nat) :
    app (dnms (fuel+1) fmapEmpty [0]) (mkDr th07 mem rs tr n)
      = app (dnms fuel fmapEmpty [0]) (mkDr th08 mem rs tr (n+1)) := by
  refine (app_bind_active rfl).trans ?_
  refine (app_bind_active rfl).trans ?_
  rfl

theorem round8 (fuel : Nat) (mem : CerbMem.MemState)
    (rs : core_run_state) (tr : List trace_event) (n : Nat) :
    app (dnms (fuel+1) fmapEmpty [0]) (mkDr th08 mem rs tr n)
      = app (dnms fuel fmapEmpty [0]) (mkDr th09 mem rs tr (n+1)) := by
  refine (app_bind_active rfl).trans ?_
  refine (app_bind_active rfl).trans ?_
  rfl

theorem round10 (x : Int) (fuel : Nat) (mem : CerbMem.MemState)
    (rs : core_run_state) (tr : List trace_event) (n : Nat) :
    app (dnms (fuel+1) fmapEmpty [0]) (mkDr (th10 x) mem rs tr n)
      = app (dnms fuel fmapEmpty [0]) (mkDr (th11 x) mem rs tr (n+1)) := by
  refine (app_bind_active rfl).trans ?_
  refine (app_bind_active rfl).trans ?_
  rfl

theorem round11 (x : Int) (fuel : Nat) (mem : CerbMem.MemState)
    (rs : core_run_state) (tr : List trace_event) (n : Nat) :
    app (dnms (fuel+1) fmapEmpty [0]) (mkDr (th11 x) mem rs tr n)
      = app (dnms fuel fmapEmpty [0]) (mkDr (th12 x) mem rs tr (n+1)) := by
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

theorem round16 (x : Int) (fuel : Nat) (mem : CerbMem.MemState)
    (rs : core_run_state) (tr : List trace_event) (n : Nat) :
    app (dnms (fuel+1) fmapEmpty [0]) (mkDr (th16 x) mem rs tr n)
      = app (dnms fuel fmapEmpty [0]) (mkDr (th17 x) mem rs tr (n+1)) := by
  refine (app_bind_active rfl).trans ?_
  refine (app_bind_active rfl).trans ?_
  rfl


theorem round20 (x : Int) (fuel : Nat) (mem : CerbMem.MemState)
    (rs : core_run_state) (tr : List trace_event) (n : Nat) :
    app (dnms (fuel+1) fmapEmpty [0]) (mkDr (th20 x) mem rs tr n)
      = app (dnms fuel fmapEmpty [0]) (mkDr (th21 x) mem rs tr (n+1)) := by
  refine (app_bind_active rfl).trans ?_
  refine (app_bind_active rfl).trans ?_
  rfl

theorem round21 (x : Int) (fuel : Nat) (mem : CerbMem.MemState)
    (rs : core_run_state) (tr : List trace_event) (n : Nat) :
    app (dnms (fuel+1) fmapEmpty [0]) (mkDr (th21 x) mem rs tr n)
      = app (dnms fuel fmapEmpty [0]) (mkDr (th22 x) mem rs tr (n+1)) := by
  refine (app_bind_active rfl).trans ?_
  refine (app_bind_active rfl).trans ?_
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
    app (dnms (fuel+1) fmapEmpty [0]) (mkDr (th23 x) mem rs tr n)
      = app (dnms fuel fmapEmpty [0]) (mkDr (th24 x) mem rs tr (n+1)) := by
  refine (app_bind_active rfl).trans ?_
  refine (app_bind_active rfl).trans ?_
  rfl

theorem round24 (x : Int) (fuel : Nat) (mem : CerbMem.MemState)
    (rs : core_run_state) (tr : List trace_event) (n : Nat) :
    app (dnms (fuel+1) fmapEmpty [0]) (mkDr (th24 x) mem rs tr n)
      = app (dnms fuel fmapEmpty [0]) (mkDr (th25 x) mem rs tr (n+1)) := by
  refine (app_bind_active rfl).trans ?_
  refine (app_bind_active rfl).trans ?_
  rfl

theorem round25 (x : Int) (fuel : Nat) (mem : CerbMem.MemState)
    (rs : core_run_state) (tr : List trace_event) (n : Nat) :
    app (dnms (fuel+1) fmapEmpty [0]) (mkDr (th25 x) mem rs tr n)
      = app (dnms fuel fmapEmpty [0]) (mkDr (th26 x) mem rs tr (n+1)) := by
  refine (app_bind_active rfl).trans ?_
  refine (app_bind_active rfl).trans ?_
  rfl

theorem round26 (x : Int) (fuel : Nat) (mem : CerbMem.MemState)
    (rs : core_run_state) (tr : List trace_event) (n : Nat) :
    app (dnms (fuel+1) fmapEmpty [0]) (mkDr (th26 x) mem rs tr n)
      = app (dnms fuel fmapEmpty [0]) (mkDr (th27 x) mem rs tr (n+1)) := by
  refine (app_bind_active rfl).trans ?_
  refine (app_bind_active rfl).trans ?_
  rfl

theorem round27 (x : Int) (fuel : Nat) (mem : CerbMem.MemState)
    (rs : core_run_state) (tr : List trace_event) (n : Nat) :
    app (dnms (fuel+1) fmapEmpty [0]) (mkDr (th27 x) mem rs tr n)
      = app (dnms fuel fmapEmpty [0]) (mkDr (th28 x) mem rs tr (n+1)) := by
  refine (app_bind_active rfl).trans ?_
  refine (app_bind_active rfl).trans ?_
  rfl

theorem round28 (x : Int) (fuel : Nat) (mem : CerbMem.MemState)
    (rs : core_run_state) (tr : List trace_event) (n : Nat) :
    app (dnms (fuel+1) fmapEmpty [0]) (mkDr (th28 x) mem rs tr n)
      = app (dnms fuel fmapEmpty [0]) (mkDr (th29 x) mem rs tr (n+1)) := by
  refine (app_bind_active rfl).trans ?_
  refine (app_bind_active rfl).trans ?_
  rfl

theorem round30 (x : Int) (fuel : Nat) (mem : CerbMem.MemState)
    (rs : core_run_state) (tr : List trace_event) (n : Nat) :
    app (dnms (fuel+1) fmapEmpty [0]) (mkDr (th30 x) mem rs tr n)
      = app (dnms fuel fmapEmpty [0]) (mkDr (th31 x) mem rs tr (n+1)) := by
  refine (app_bind_active rfl).trans ?_
  refine (app_bind_active rfl).trans ?_
  rfl

theorem round31 (x : Int) (fuel : Nat) (mem : CerbMem.MemState)
    (rs : core_run_state) (tr : List trace_event) (n : Nat) :
    app (dnms (fuel+1) fmapEmpty [0]) (mkDr (th31 x) mem rs tr n)
      = app (dnms fuel fmapEmpty [0]) (mkDr (th32 x) mem rs tr (n+1)) := by
  refine (app_bind_active rfl).trans ?_
  refine (app_bind_active rfl).trans ?_
  rfl

theorem round33 (x : Int) (fuel : Nat) (mem : CerbMem.MemState)
    (rs : core_run_state) (tr : List trace_event) (n : Nat) :
    app (dnms (fuel+1) fmapEmpty [0]) (mkDr (th33 x) mem rs tr n)
      = app (dnms fuel fmapEmpty [0]) (mkDr (th34 x) mem rs tr (n+1)) := by
  refine (app_bind_active rfl).trans ?_
  refine (app_bind_active rfl).trans ?_
  rfl


theorem round37 (x : Int) (fuel : Nat) (mem : CerbMem.MemState)
    (rs : core_run_state) (tr : List trace_event) (n : Nat) :
    app (dnms (fuel+1) fmapEmpty [0]) (mkDr (th37 x) mem rs tr n)
      = app (dnms fuel fmapEmpty [0]) (mkDr (th38 x) mem rs tr (n+1)) := by
  refine (app_bind_active rfl).trans ?_
  refine (app_bind_active rfl).trans ?_
  rfl

theorem round38 (x : Int) (fuel : Nat) (mem : CerbMem.MemState)
    (rs : core_run_state) (tr : List trace_event) (n : Nat) :
    app (dnms (fuel+1) fmapEmpty [0]) (mkDr (th38 x) mem rs tr n)
      = app (dnms fuel fmapEmpty [0]) (mkDr (th39 x) mem rs tr (n+1)) := by
  refine (app_bind_active rfl).trans ?_
  refine (app_bind_active rfl).trans ?_
  rfl

theorem round39 (x : Int) (fuel : Nat) (mem : CerbMem.MemState)
    (rs : core_run_state) (tr : List trace_event) (n : Nat) :
    app (dnms (fuel+1) fmapEmpty [0]) (mkDr (th39 x) mem rs tr n)
      = app (dnms fuel fmapEmpty [0]) (mkDr (th40 x) mem rs tr (n+1)) := by
  refine (app_bind_active rfl).trans ?_
  refine (app_bind_active rfl).trans ?_
  rfl

theorem round40 (x : Int) (fuel : Nat) (mem : CerbMem.MemState)
    (rs : core_run_state) (tr : List trace_event) (n : Nat) :
    app (dnms (fuel+1) fmapEmpty [0]) (mkDr (th40 x) mem rs tr n)
      = app (dnms fuel fmapEmpty [0]) (mkDr (th41 x) mem rs tr (n+1)) := by
  refine (app_bind_active rfl).trans ?_
  refine (app_bind_active rfl).trans ?_
  rfl

theorem round41 (x : Int) (fuel : Nat) (mem : CerbMem.MemState)
    (rs : core_run_state) (tr : List trace_event) (n : Nat) :
    app (dnms (fuel+1) fmapEmpty [0]) (mkDr (th41 x) mem rs tr n)
      = app (dnms fuel fmapEmpty [0]) (mkDr (th42 x) mem rs tr (n+1)) := by
  refine (app_bind_active rfl).trans ?_
  refine (app_bind_active rfl).trans ?_
  rfl

theorem round42 (x : Int) (fuel : Nat) (mem : CerbMem.MemState)
    (rs : core_run_state) (tr : List trace_event) (n : Nat) :
    app (dnms (fuel+1) fmapEmpty [0]) (mkDr (th42 x) mem rs tr n)
      = app (dnms fuel fmapEmpty [0]) (mkDr (th43 x) mem rs tr (n+1)) := by
  refine (app_bind_active rfl).trans ?_
  refine (app_bind_active rfl).trans ?_
  rfl

theorem round43 (x : Int) (fuel : Nat) (mem : CerbMem.MemState)
    (rs : core_run_state) (tr : List trace_event) (n : Nat) :
    app (dnms (fuel+1) fmapEmpty [0]) (mkDr (th43 x) mem rs tr n)
      = app (dnms fuel fmapEmpty [0]) (mkDr (th44 x) mem rs tr (n+1)) := by
  refine (app_bind_active rfl).trans ?_
  refine (app_bind_active rfl).trans ?_
  rfl

theorem round44 (x : Int) (fuel : Nat) (mem : CerbMem.MemState)
    (rs : core_run_state) (tr : List trace_event) (n : Nat) :
    app (dnms (fuel+1) fmapEmpty [0]) (mkDr (th44 x) mem rs tr n)
      = app (dnms fuel fmapEmpty [0]) (mkDr (th45 x) mem rs tr (n+1)) := by
  refine (app_bind_active rfl).trans ?_
  refine (app_bind_active rfl).trans ?_
  rfl

theorem round46 (x : Int) (fuel : Nat) (mem : CerbMem.MemState)
    (rs : core_run_state) (tr : List trace_event) (n : Nat) :
    app (dnms (fuel+1) fmapEmpty [0]) (mkDr (th46 x) mem rs tr n)
      = app (dnms fuel fmapEmpty [0]) (mkDr (th47 x) mem rs tr (n+1)) := by
  refine (app_bind_active rfl).trans ?_
  refine (app_bind_active rfl).trans ?_
  rfl

theorem round47 (x : Int) (fuel : Nat) (mem : CerbMem.MemState)
    (rs : core_run_state) (tr : List trace_event) (n : Nat) :
    app (dnms (fuel+1) fmapEmpty [0]) (mkDr (th47 x) mem rs tr n)
      = app (dnms fuel fmapEmpty [0]) (mkDr (th48 x) mem rs tr (n+1)) := by
  refine (app_bind_active rfl).trans ?_
  refine (app_bind_active rfl).trans ?_
  rfl

theorem round49 (x : Int) (fuel : Nat) (mem : CerbMem.MemState)
    (rs : core_run_state) (tr : List trace_event) (n : Nat) :
    app (dnms (fuel+1) fmapEmpty [0]) (mkDr (th49 x) mem rs tr n)
      = app (dnms fuel fmapEmpty [0]) (mkDr (th50 x) mem rs tr (n+1)) := by
  refine (app_bind_active rfl).trans ?_
  refine (app_bind_active rfl).trans ?_
  rfl

theorem round50 (x : Int) (fuel : Nat) (mem : CerbMem.MemState)
    (rs : core_run_state) (tr : List trace_event) (n : Nat) :
    app (dnms (fuel+1) fmapEmpty [0]) (mkDr (th50 x) mem rs tr n)
      = app (dnms fuel fmapEmpty [0]) (mkDr (th51 x) mem rs tr (n+1)) := by
  refine (app_bind_active rfl).trans ?_
  refine (app_bind_active rfl).trans ?_
  rfl

theorem round51 (x : Int) (fuel : Nat) (mem : CerbMem.MemState)
    (rs : core_run_state) (tr : List trace_event) (n : Nat) :
    app (dnms (fuel+1) fmapEmpty [0]) (mkDr (th51 x) mem rs tr n)
      = app (dnms fuel fmapEmpty [0]) (mkDr (th52 x) mem rs tr (n+1)) := by
  refine (app_bind_active rfl).trans ?_
  refine (app_bind_active rfl).trans ?_
  rfl


theorem round55 (x : Int) (fuel : Nat) (mem : CerbMem.MemState)
    (rs : core_run_state) (tr : List trace_event) (n : Nat) :
    app (dnms (fuel+1) fmapEmpty [0]) (mkDr (th55 x) mem rs tr n)
      = app (dnms fuel fmapEmpty [0]) (mkDr (th56 x) mem rs tr (n+1)) := by
  refine (app_bind_active rfl).trans ?_
  refine (app_bind_active rfl).trans ?_
  rfl

/-! ## Special rounds -/

/-- R0: eval create operands — the Civalignof value is STUCK at the
    tag-global; the target state is rewritten to the stuck spelling
    (the layout fact), then the walk is a plain rfl. -/
theorem round0 (htags : CerbTags.tagDefs () = t4File.tagDefs)
    (fuel : Nat) (mem : CerbMem.MemState) (rs : core_run_state)
    (tr : List trace_event) (n : Nat) :
    app (dnms (fuel+1) fmapEmpty [0]) (mkDr th00 mem rs tr n)
      = app (dnms fuel fmapEmpty [0]) (mkDr th01 mem rs tr (n+1)) := by
  rw [show th01 = mkTh arena01stuck e0 by
    show mkTh arena01 e0 = _
    rw [arena01_stuck htags]]
  refine (app_bind_active rfl).trans ?_
  refine (app_bind_active rfl).trans ?_
  rfl

/-- R1: the struct create round. -/
theorem round1 (htags : CerbTags.tagDefs () = t4File.tagDefs)
    (x : Int) (fuel : Nat) (rs : core_run_state)
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
      case halloc => exact createS_eq htags x
      rfl
    rfl
  rfl

/-- R4: the unspecified-struct store round. -/
theorem round4 (htags : CerbTags.tagDefs () = t4File.tagDefs)
    (x : Int) (fuel : Nat) (rs : core_run_state)
    (tr : List trace_event) (n : Nat) :
    app (dnms (fuel+1) fmapEmpty [0]) (mkDr th04 (memC x) rs tr n)
      = app (dnms fuel fmapEmpty [0]) (mkDr th05 (memU x)
          { rs with aid_supply := rs.aid_supply + 1 } (meStoreU :: tr) n) := by
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
      case hstore => exact storeU_eq htags x
      apply (app_bind_active (app_liftND_active _ _ _ _ ?hpref)).trans
      case hpref => rfl
      rfl
    rfl
  rfl

/-- R9: the v-load round. -/
theorem round9 (x : Int) (h1 : -2147483648 ≤ x) (h2 : x ≤ 2147483647)
    (fuel : Nat) (rs : core_run_state) (tr : List trace_event) (n : Nat) :
    app (dnms (fuel+1) fmapEmpty [0]) (mkDr th09 (memU x) rs tr n)
      = app (dnms fuel fmapEmpty [0]) (mkDr (th10 x) (memU x)
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

/-- R12: the member_shift .a eval (stuck-form target). -/
theorem round12 (htags : CerbTags.tagDefs () = t4File.tagDefs)
    (x : Int) (fuel : Nat) (mem : CerbMem.MemState) (rs : core_run_state)
    (tr : List trace_event) (n : Nat) :
    app (dnms (fuel+1) fmapEmpty [0]) (mkDr (th12 x) mem rs tr n)
      = app (dnms fuel fmapEmpty [0]) (mkDr (th13 x) mem rs tr (n+1)) := by
  rw [show th13 x = mkTh (arena13stuck x) e12 by
    show mkTh (arena13 x) e12 = _
    rw [arena13_stuck htags x]]
  refine (app_bind_active rfl).trans ?_
  refine (app_bind_active rfl).trans ?_
  rfl


/-! ## The fresh-symbol boundary (the NEG-store transform draws from
    the process-global fresh-int supply and the TU-digest global —
    both opaque externs on the census boundary; the T4 statement
    hypothesizes their reference initial state, exactly as for the tag
    global). -/

/-- The transform's first drawn symbol, in produced (stuck) form. -/
def anon1stuck : sym :=
  Symbol (CerberusFresh.digest ()) rsD3.sym_supply SD_None
/-- The second (supply bumped once). -/
def anon2stuck : sym :=
  Symbol (CerberusFresh.digest ()) (rsD3.sym_supply + 1) SD_None

theorem anon1_stuck_eq (hdig : CerberusFresh.digest () = "")
    (hfresh : rsD3.sym_supply = 1048577) : anon1stuck = anon1 := by
  unfold anon1stuck anon1
  rw [hdig, hfresh]

theorem anon2_stuck_eq (hdig : CerberusFresh.digest () = "")
    (hfresh : rsD3.sym_supply = 1048577) : anon2stuck = anon2 := by
  unfold anon2stuck anon2
  rw [hdig, hfresh]

def arena16stuck : RExpr :=
  (Expr [] (Eannot [(DA_pos [] (CerbMem.Footprint.FP .W 281474976710636 8))] (Expr aU (Esseq (Pattern aU (CaseBase (none, (BTy_loaded OTy_integer)))) (Expr aU (Ebound (Expr [] (Ewseq (Pattern [] (CaseCtor Ctuple [(Pattern [] (CaseBase (none, BTy_unit))), (Pattern [] (CaseBase (some anon1stuck, BTy_unit)))])) (Expr [] (Eunseq [(Expr [] (Eexcluded 0 (Action CerbLocation.Loc.unknown empty_annotation (Store0 false (Pexpr aU () (PEval (Vctype intCty))) (Pexpr aU () (PEsym symA499)) (Pexpr aU () (PEcall (Sym convLoadedIntSym) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym symA502))])) NA)))), (Expr [] (Eannot [(DA_pos [0] (CerbMem.Footprint.FP .R 281474976710648 4))] (Expr aU (Ewseq (Pattern aU (CaseBase (none, BTy_unit))) (Expr [] (Epure (Pexpr [] () (PEval Vunit)))) (Expr aU (Epure (Pexpr aU () (PEcall (Sym convLoadedIntSym) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym symA502))]))))))))])) (Expr [] (Epure (Pexpr [] () (PEsym anon1stuck)))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Epure (Pexpr aU () (PEval Vunit)))) (Expr aU (Esseq (Pattern aU (CaseBase (none, (BTy_loaded OTy_integer)))) (Expr aU (Ebound (Expr aU (Ewseq (Pattern aU (CaseCtor Ctuple [(Pattern aU (CaseBase (some symA503, (BTy_object OTy_pointer)))), (Pattern aU (CaseBase (some symA505, (BTy_loaded OTy_integer))))])) (Expr aU (Eunseq [(Expr aU (Esseq (Pattern aU (CaseBase (some symA504, (BTy_object OTy_pointer)))) (Expr aU (Epure (Pexpr aU () (PEsym symS)))) (Expr aU (Epure (Pexpr aU () (PEmember_shift (Pexpr aU () (PEsym symA504)) structSSym (Identifier CerbLocation.Loc.unknown "b"))))))), (Expr aU (Epure (Pexpr aU () (PEctor Cspecified [(Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none 7)))))]))))])) (Expr aU (Ewseq (Pattern aU (CaseBase (none, BTy_unit))) (Expr aU (Eaction (Paction Neg0 (Action CerbLocation.Loc.unknown empty_annotation (Store0 false (Pexpr aU () (PEval (Vctype intCty))) (Pexpr aU () (PEsym symA503)) (Pexpr aU () (PEcall (Sym convLoadedIntSym) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym symA505))])) NA))))) (Expr aU (Epure (Pexpr aU () (PEcall (Sym convLoadedIntSym) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym symA505))])))))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Epure (Pexpr aU () (PEval Vunit)))) (Expr aU (Esseq (Pattern aU (CaseBase (some symA508, (BTy_loaded OTy_integer)))) (Expr aU (Ebound (Expr aU (Ewseq (Pattern aU (CaseBase (some symA507, (BTy_object OTy_pointer)))) (Expr aU (Esseq (Pattern aU (CaseBase (some symA506, (BTy_object OTy_pointer)))) (Expr aU (Epure (Pexpr aU () (PEsym symS)))) (Expr aU (Epure (Pexpr aU () (PEmember_shift (Pexpr aU () (PEsym symA506)) structSSym (Identifier CerbLocation.Loc.unknown "a"))))))) (Expr aU (Eaction (Paction Pos (Action CerbLocation.Loc.unknown empty_annotation (Load0 (Pexpr aU () (PEval (Vctype intCty))) (Pexpr aU () (PEsym symA507)) NA))))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Eaction (Paction Pos (Action CerbLocation.Loc.unknown empty_annotation (Kill (Static0 structSCty) (Pexpr aU () (PEsym symS))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Erun empty_annotation symRet498 [(Pexpr aU () (PEcall (Sym convLoadedIntSym) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym symA508))]))])) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Eaction (Paction Pos (Action CerbLocation.Loc.unknown empty_annotation (Kill (Static0 structSCty) (Pexpr aU () (PEsym symS))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Epure (Pexpr aU () (PEval Vunit)))) (Expr aU (Esave (symRet498, (BTy_loaded OTy_integer)) [(symA509, (((BTy_loaded OTy_integer), none), (Pexpr aU () (PEundef CerbLocation.Loc.unknown (DUMMY "UB088_reached_end_of_function")))))] (Expr aU (Epure (Pexpr aU () (PEsym symA509))))))))))))))))))))))))))

def arena33stuck : RExpr :=
  (Expr [] (Eannot [(DA_pos [] (CerbMem.Footprint.FP .W 281474976710636 8))] (Expr aU (Esseq (Pattern aU (CaseBase (none, (BTy_loaded OTy_integer)))) (Expr aU (Ebound (Expr [] (Ewseq (Pattern [] (CaseCtor Ctuple [(Pattern [] (CaseBase (none, BTy_unit))), (Pattern [] (CaseBase (some anon2stuck, BTy_unit)))])) (Expr [] (Eunseq [(Expr [] (Eexcluded 1 (Action CerbLocation.Loc.unknown empty_annotation (Store0 false (Pexpr aU () (PEval (Vctype intCty))) (Pexpr aU () (PEsym symA503)) (Pexpr aU () (PEcall (Sym convLoadedIntSym) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym symA505))])) NA)))), (Expr [] (Eannot [] (Expr aU (Ewseq (Pattern aU (CaseBase (none, BTy_unit))) (Expr [] (Epure (Pexpr [] () (PEval Vunit)))) (Expr aU (Epure (Pexpr aU () (PEcall (Sym convLoadedIntSym) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym symA505))]))))))))])) (Expr [] (Epure (Pexpr [] () (PEsym anon2stuck)))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Epure (Pexpr aU () (PEval Vunit)))) (Expr aU (Esseq (Pattern aU (CaseBase (some symA508, (BTy_loaded OTy_integer)))) (Expr aU (Ebound (Expr aU (Ewseq (Pattern aU (CaseBase (some symA507, (BTy_object OTy_pointer)))) (Expr aU (Esseq (Pattern aU (CaseBase (some symA506, (BTy_object OTy_pointer)))) (Expr aU (Epure (Pexpr aU () (PEsym symS)))) (Expr aU (Epure (Pexpr aU () (PEmember_shift (Pexpr aU () (PEsym symA506)) structSSym (Identifier CerbLocation.Loc.unknown "a"))))))) (Expr aU (Eaction (Paction Pos (Action CerbLocation.Loc.unknown empty_annotation (Load0 (Pexpr aU () (PEval (Vctype intCty))) (Pexpr aU () (PEsym symA507)) NA))))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Eaction (Paction Pos (Action CerbLocation.Loc.unknown empty_annotation (Kill (Static0 structSCty) (Pexpr aU () (PEsym symS))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Erun empty_annotation symRet498 [(Pexpr aU () (PEcall (Sym convLoadedIntSym) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEsym symA508))]))])) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Eaction (Paction Pos (Action CerbLocation.Loc.unknown empty_annotation (Kill (Static0 structSCty) (Pexpr aU () (PEsym symS))))))) (Expr aU (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (Expr aU (Epure (Pexpr aU () (PEval Vunit)))) (Expr aU (Esave (symRet498, (BTy_loaded OTy_integer)) [(symA509, (((BTy_loaded OTy_integer), none), (Pexpr aU () (PEundef CerbLocation.Loc.unknown (DUMMY "UB088_reached_end_of_function")))))] (Expr aU (Epure (Pexpr aU () (PEsym symA509))))))))))))))))))))))

theorem arena16_stuck (hdig : CerberusFresh.digest () = "")
    (hfresh : rsD3.sym_supply = 1048577) :
    arena16stuck = arena16 := by
  unfold arena16stuck arena16
  rw [anon1_stuck_eq hdig hfresh]

theorem arena33_stuck (hdig : CerberusFresh.digest () = "")
    (hfresh : rsD3.sym_supply = 1048577) :
    arena33stuck = arena33 := by
  unfold arena33stuck arena33
  rw [anon2_stuck_eq hdig hfresh]

/-- R15: the NEG-store transform (exclusion id + fresh symbol drawn
    from the CONCRETE run state; stuck-form target for the two
    global reads). -/
theorem round15 (hdig : CerberusFresh.digest () = "")
    (hfresh : rsD3.sym_supply = 1048577)
    (x : Int) (fuel : Nat) (mem : CerbMem.MemState)
    (tr : List trace_event) (n : Nat) :
    app (dnms (fuel+1) fmapEmpty [0]) (mkDr (th15 x) mem r3 tr n)
      = app (dnms fuel fmapEmpty [0]) (mkDr (th16 x) mem r4 tr (n+1)) := by
  rw [show th16 x = mkTh arena16stuck (e15 x) by
    show mkTh arena16 (e15 x) = _
    rw [arena16_stuck hdig hfresh]]
  refine (app_bind_active rfl).trans ?_
  refine (app_bind_active rfl).trans ?_
  rfl

/-- R32: the second NEG-store transform. -/
theorem round32 (hdig : CerberusFresh.digest () = "")
    (hfresh : rsD3.sym_supply = 1048577)
    (x : Int) (fuel : Nat) (mem : CerbMem.MemState)
    (tr : List trace_event) (n : Nat) :
    app (dnms (fuel+1) fmapEmpty [0]) (mkDr (th32 x) mem r5 tr n)
      = app (dnms fuel fmapEmpty [0]) (mkDr (th33 x) mem r6 tr (n+1)) := by
  rw [show th33 x = mkTh arena33stuck (e32 x) by
    show mkTh arena33 (e32 x) = _
    rw [arena33_stuck hdig hfresh]]
  refine (app_bind_active rfl).trans ?_
  refine (app_bind_active rfl).trans ?_
  rfl

/-- R19: the s.a store round (through the exclusion wrapper). -/
theorem round19 (x : Int) (fuel : Nat) (rs : core_run_state)
    (tr : List trace_event) (n : Nat) :
    app (dnms (fuel+1) fmapEmpty [0]) (mkDr (th19 x) (memU x) rs tr n)
      = app (dnms fuel fmapEmpty [0]) (mkDr (th20 x) (memA x)
          { rs with aid_supply := rs.aid_supply + 1 } (meStoreA x :: tr) n) := by
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
      case hstore => exact storeA_eq x
      apply (app_bind_active (app_liftND_active _ _ _ _ ?hpref)).trans
      case hpref => rfl
      rfl
    rfl
  rfl

/-- R29: the member_shift .b eval (stuck-form target). -/
theorem round29 (htags : CerbTags.tagDefs () = t4File.tagDefs)
    (x : Int) (fuel : Nat) (mem : CerbMem.MemState) (rs : core_run_state)
    (tr : List trace_event) (n : Nat) :
    app (dnms (fuel+1) fmapEmpty [0]) (mkDr (th29 x) mem rs tr n)
      = app (dnms fuel fmapEmpty [0]) (mkDr (th30 x) mem rs tr (n+1)) := by
  rw [show th30 x = mkTh arena30stuck (e29 x) by
    show mkTh arena30 (e29 x) = _
    rw [arena30_stuck htags]]
  refine (app_bind_active rfl).trans ?_
  refine (app_bind_active rfl).trans ?_
  rfl

/-- R36: the s.b store round. -/
theorem round36 (x : Int) (fuel : Nat) (rs : core_run_state)
    (tr : List trace_event) (n : Nat) :
    app (dnms (fuel+1) fmapEmpty [0]) (mkDr (th36 x) (memA x) rs tr n)
      = app (dnms fuel fmapEmpty [0]) (mkDr (th37 x) (memB x)
          { rs with aid_supply := rs.aid_supply + 1 } (meStoreB :: tr) n) := by
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
      case hstore => exact storeB_eq x
      apply (app_bind_active (app_liftND_active _ _ _ _ ?hpref)).trans
      case hpref => rfl
      rfl
    rfl
  rfl

/-- R45: the member_shift .a eval, second visit (stuck-form target). -/
theorem round45 (htags : CerbTags.tagDefs () = t4File.tagDefs)
    (x : Int) (fuel : Nat) (mem : CerbMem.MemState) (rs : core_run_state)
    (tr : List trace_event) (n : Nat) :
    app (dnms (fuel+1) fmapEmpty [0]) (mkDr (th45 x) mem rs tr n)
      = app (dnms fuel fmapEmpty [0]) (mkDr (th46 x) mem rs tr (n+1)) := by
  rw [show th46 x = mkTh arena46stuck (e45 x) by
    show mkTh arena46 (e45 x) = _
    rw [arena46_stuck htags]]
  refine (app_bind_active rfl).trans ?_
  refine (app_bind_active rfl).trans ?_
  rfl

/-- R48: the s.a load round (the exit-criterion payoff). -/
theorem round48 (x : Int) (h1 : -2147483648 ≤ x) (h2 : x ≤ 2147483647)
    (fuel : Nat) (rs : core_run_state) (tr : List trace_event) (n : Nat) :
    app (dnms (fuel+1) fmapEmpty [0]) (mkDr (th48 x) (memB x) rs tr n)
      = app (dnms fuel fmapEmpty [0]) (mkDr (th49 x) (memB x)
          { rs with aid_supply := rs.aid_supply + 1 } (meLoadA x :: tr) n) := by
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
      case hload => exact loadA_eq x h1 h2
      apply (app_bind_active (app_liftND_active _ _ _ _ ?hpref)).trans
      case hpref => rfl
      rfl
    rfl
  rfl

/-- R52: the kill round. -/
theorem round52 (x : Int) (fuel : Nat) (rs : core_run_state)
    (tr : List trace_event) (n : Nat) :
    app (dnms (fuel+1) fmapEmpty [0]) (mkDr (th52 x) (memB x) rs tr n)
      = app (dnms fuel fmapEmpty [0]) (mkDr (th53 x) (memK x)
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
      case hkill => exact killS_eq x
      rfl
    rfl
  rfl

/-! ## The conv_loaded_int chains (three sites: a_502 at x — Epure R17
    and the store operands R18; a_505 at 7 — R34/R35; a_508 at x —
    R53's Erun) -/

def convA_PE : generic_pexpr Unit sym :=
  Pexpr aU () (PEcall (Sym convLoadedIntSym)
    [Pexpr aU () (PEval (Vctype intCty)), Pexpr aU () (PEsym symA502)])
def convA_PE_p : generic_pexpr Unit sym :=
  Pexpr [] () (PEcall (Sym convLoadedIntSym)
    [Pexpr aU () (PEval (Vctype intCty)), Pexpr aU () (PEsym symA502)])
def convB_PE : generic_pexpr Unit sym :=
  Pexpr aU () (PEcall (Sym convLoadedIntSym)
    [Pexpr aU () (PEval (Vctype intCty)), Pexpr aU () (PEsym symA505)])
def convB_PE_p : generic_pexpr Unit sym :=
  Pexpr [] () (PEcall (Sym convLoadedIntSym)
    [Pexpr aU () (PEval (Vctype intCty)), Pexpr aU () (PEsym symA505)])
def convR_PE : generic_pexpr Unit sym :=
  Pexpr aU () (PEcall (Sym convLoadedIntSym)
    [Pexpr aU () (PEval (Vctype intCty)), Pexpr aU () (PEsym symA508)])
def convR_PE_p : generic_pexpr Unit sym :=
  Pexpr [] () (PEcall (Sym convLoadedIntSym)
    [Pexpr aU () (PEval (Vctype intCty)), Pexpr aU () (PEsym symA508)])

theorem pull_convA : pull_constrained 0 convA_PE = convA_PE_p := rfl
theorem pull_convB : pull_constrained 0 convB_PE = convB_PE_p := rfl
theorem pull_convR : pull_constrained 0 convR_PE = convR_PE_p := rfl
theorem pull_z0 (v : Int) : pull_constrained 0 (z0 v) = z0 v := rfl
theorem pull_z1 (v : Int) : pull_constrained 0 (z1 v) = z1 v := rfl
theorem pull_z2 (v : Int) : pull_constrained 0 (z2 v) = z2 v := rfl
theorem pull_z3 (v : Int) : pull_constrained 0 (z3 v) = z3 v := rfl

theorem s0A_eq (x : Int) (mem : CerbMem.MemState) :
    step_eval_pexpr t4File.tagDefs 0 CerbLocation.Loc.unknown
      (some (CerbLocation.other "RelSem.callND")) (create_extern_symmap t4File)
      (e15 x) (some mem) t4File false convA_PE_p
      = Result (Defined (z0 x)) := rfl

theorem s0B_eq (x : Int) (mem : CerbMem.MemState) :
    step_eval_pexpr t4File.tagDefs 0 CerbLocation.Loc.unknown
      (some (CerbLocation.other "RelSem.callND")) (create_extern_symmap t4File)
      (e32 x) (some mem) t4File false convB_PE_p
      = Result (Defined (z0 7)) := rfl

theorem s0R_eq (x : Int) (mem : CerbMem.MemState) :
    step_eval_pexpr t4File.tagDefs 0 CerbLocation.Loc.unknown
      (some (CerbLocation.other "RelSem.callND")) (create_extern_symmap t4File)
      (e51 x) (some mem) t4File false convR_PE_p
      = Result (Defined (z0 x)) := rfl

theorem s1_eq (v : Int) (env : List (Fmap sym value))
    (mem : CerbMem.MemState) :
    step_eval_pexpr t4File.tagDefs 0 CerbLocation.Loc.unknown
      (some (CerbLocation.other "RelSem.callND")) (create_extern_symmap t4File)
      env (some mem) t4File false (z0 v)
      = Result (Defined (z1 v)) := rfl

theorem s2_eq (v : Int) (env : List (Fmap sym value))
    (mem : CerbMem.MemState) :
    step_eval_pexpr t4File.tagDefs 0 CerbLocation.Loc.unknown
      (some (CerbLocation.other "RelSem.callND")) (create_extern_symmap t4File)
      env (some mem) t4File false (z1 v)
      = Result (Defined (z2 v)) := rfl

theorem s3_eq (v : Int) (env : List (Fmap sym value))
    (mem : CerbMem.MemState) :
    step_eval_pexpr t4File.tagDefs 0 CerbLocation.Loc.unknown
      (some (CerbLocation.other "RelSem.callND")) (create_extern_symmap t4File)
      env (some mem) t4File false (z2 v)
      = Result (Defined (z3 v)) := rfl

/-- s4: the conv range check (T1's harm recipe, generic value+env). -/
theorem s4_eq (v : Int)
    (h1 : -2147483648 ≤ v) (h2 : v ≤ 2147483647)
    (env : List (Fmap sym value)) (mem : CerbMem.MemState) :
    step_eval_pexpr t4File.tagDefs 0 CerbLocation.Loc.unknown
      (some (CerbLocation.other "RelSem.callND")) (create_extern_symmap t4File)
      env (some mem) t4File false (z3 v)
      = Result (Defined (z4 v)) := by
  have hd1 : decide ((-2147483648:Int) ≤ v) = true := decide_eq_true h1
  have hd2 : decide (v ≤ (2147483647:Int)) = true := decide_eq_true h2
  change exception_undef_bind _ _ = _
  refine (eubind_defined
    (z := (PEval (loadedV v) : generic_pexpr_ Unit sym)) ?hBody).trans ?_
  case hBody =>
    change exception_undef_bind _ _ = _
    refine (eubind_defined
      (z := [(Pexpr [] () (PEval (xIntV v)) : generic_pexpr Unit sym)])
      ?hMap).trans ?_
    case hMap =>
      apply eumapM_one ?hIf
      case hIf =>
        change exception_undef_bind _ _ = _
        refine (eubind_defined
          (z := (PEval (xIntV v) : generic_pexpr_ Unit sym)) ?hIfBody).trans ?_
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
                show step_eval_pexpr_lemFuel 999997 t4File.tagDefs (0+1+1+1)
                  CerbLocation.Loc.unknown (some (CerbLocation.other "RelSem.callND"))
                  (create_extern_symmap t4File) env (some mem) t4File false
                  (Pexpr [] () (PEop OpLe
                    (Pexpr [] () (PEctor Civmin [Pexpr aU () (PEval (Vctype intCty))]))
                    (Pexpr [] () (PEval (xIntV v)))))
                  = Result (Defined (Pexpr [] () (PEval Vtrue)))
                have harm : (if (decide ((-2147483648:Int) ≤ v)) = true
                    then Vtrue else Vfalse) = Vtrue := by rw [hd1]; simp
                conv => rhs; rw [← harm]
                rfl
              change exception_undef_bind _ _ = _
              refine (eubind_defined
                (z := (Pexpr [] () (PEval Vtrue) : generic_pexpr Unit sym))
                ?hLe2).trans ?_
              case hLe2 =>
                show step_eval_pexpr_lemFuel 999997 t4File.tagDefs (0+1+1+1)
                  CerbLocation.Loc.unknown (some (CerbLocation.other "RelSem.callND"))
                  (create_extern_symmap t4File) env (some mem) t4File false
                  (Pexpr [] () (PEop OpLe
                    (Pexpr [] () (PEval (xIntV v)))
                    (Pexpr [] () (PEctor Civmax [Pexpr aU () (PEval (Vctype intCty))]))))
                  = Result (Defined (Pexpr [] () (PEval Vtrue)))
                have harm : (if (decide (v ≤ (2147483647:Int))) = true
                    then Vtrue else Vfalse) = Vtrue := by rw [hd2]; simp
                conv => rhs; rw [← harm]
                rfl
              rfl
            rfl
          rfl
        rfl
    rfl
  rfl

theorem convACore_eq (x : Int)
    (h1 : -2147483648 ≤ x) (h2 : x ≤ 2147483647) (mem : CerbMem.MemState) :
    eval_pexpr_aux2 t4File.tagDefs CerbLocation.Loc.unknown
      (some (CerbLocation.other "RelSem.callND"))
      (create_extern_symmap t4File) (e15 x) (some mem) t4File convA_PE
    = Result (Defined (Sum.inr (loadedV x))) :=
  (aux2_step 999999 _ _ _ _ _ _ _ (pull_convA)
      (by intro a xs h; simp [convA_PE_p] at h) (s0A_eq x mem) (by rfl)).trans
  ((aux2_step 999998 _ _ _ _ _ _ _ (pull_z0 x)
      (by intro a xs h; simp [z0] at h) (s1_eq x _ mem) (by rfl)).trans
  ((aux2_step 999997 _ _ _ _ _ _ _ (pull_z1 x)
      (by intro a xs h; simp [z1] at h) (s2_eq x _ mem) (by rfl)).trans
  ((aux2_step 999996 _ _ _ _ _ _ _ (pull_z2 x)
      (by intro a xs h; simp [z2] at h) (s3_eq x _ mem) (by rfl)).trans
  (aux2_done 999995 _ _ _ _ _ _ _ (pull_z3 x)
      (by intro a xs h; simp [z3] at h) (s4_eq x h1 h2 _ mem) (by rfl)))))

theorem convBCore_eq (x : Int) (mem : CerbMem.MemState) :
    eval_pexpr_aux2 t4File.tagDefs CerbLocation.Loc.unknown
      (some (CerbLocation.other "RelSem.callND"))
      (create_extern_symmap t4File) (e32 x) (some mem) t4File convB_PE
    = Result (Defined (Sum.inr (loadedV 7))) :=
  (aux2_step 999999 _ _ _ _ _ _ _ (pull_convB)
      (by intro a xs h; simp [convB_PE_p] at h) (s0B_eq x mem) (by rfl)).trans
  ((aux2_step 999998 _ _ _ _ _ _ _ (pull_z0 7)
      (by intro a xs h; simp [z0] at h) (s1_eq 7 _ mem) (by rfl)).trans
  ((aux2_step 999997 _ _ _ _ _ _ _ (pull_z1 7)
      (by intro a xs h; simp [z1] at h) (s2_eq 7 _ mem) (by rfl)).trans
  ((aux2_step 999996 _ _ _ _ _ _ _ (pull_z2 7)
      (by intro a xs h; simp [z2] at h) (s3_eq 7 _ mem) (by rfl)).trans
  (aux2_done 999995 _ _ _ _ _ _ _ (pull_z3 7)
      (by intro a xs h; simp [z3] at h)
      (s4_eq 7 (by decide) (by decide) _ mem) (by rfl)))))

theorem convRCore_eq (x : Int)
    (h1 : -2147483648 ≤ x) (h2 : x ≤ 2147483647) (mem : CerbMem.MemState) :
    eval_pexpr_aux2 t4File.tagDefs CerbLocation.Loc.unknown
      (some (CerbLocation.other "RelSem.callND"))
      (create_extern_symmap t4File) (e51 x) (some mem) t4File convR_PE
    = Result (Defined (Sum.inr (loadedV x))) :=
  (aux2_step 999999 _ _ _ _ _ _ _ (pull_convR)
      (by intro a xs h; simp [convR_PE_p] at h) (s0R_eq x mem) (by rfl)).trans
  ((aux2_step 999998 _ _ _ _ _ _ _ (pull_z0 x)
      (by intro a xs h; simp [z0] at h) (s1_eq x _ mem) (by rfl)).trans
  ((aux2_step 999997 _ _ _ _ _ _ _ (pull_z1 x)
      (by intro a xs h; simp [z1] at h) (s2_eq x _ mem) (by rfl)).trans
  ((aux2_step 999996 _ _ _ _ _ _ _ (pull_z2 x)
      (by intro a xs h; simp [z2] at h) (s3_eq x _ mem) (by rfl)).trans
  (aux2_done 999995 _ _ _ _ _ _ _ (pull_z3 x)
      (by intro a xs h; simp [z3] at h) (s4_eq x h1 h2 _ mem) (by rfl)))))

/-! Step/fullEval wrappers at the consuming thread states. -/

theorem convAStep17_eq (x : Int)
    (h1 : -2147483648 ≤ x) (h2 : x ≤ 2147483647)
    (mem : CerbMem.MemState) (rs : core_run_state) :
    E.eval_pexpr20 t4File.tagDefs (th17 x) (create_extern_symmap t4File)
      mem t4File convA_PE rs
    = Result (Defined (Sum.inr (loadedV x)), rs) := by
  simp only [E.eval_pexpr20, th17, mkTh]
  rw [convACore_eq x h1 h2 mem]
  rfl

theorem fullEvalConvA17 (x : Int)
    (h1 : -2147483648 ≤ x) (h2 : x ≤ 2147483647)
    (mem : CerbMem.MemState) (rs : core_run_state) :
    full_eval_pexpr t4File.tagDefs (th17 x) (create_extern_symmap t4File)
      mem t4File convA_PE rs
    = Result (Defined (loadedV x), rs) := by
  change stExceptUndef_bind _ _ _ = _
  refine (stub_defined (convAStep17_eq x h1 h2 mem rs)).trans ?_
  rfl

theorem convAStep18_eq (x : Int)
    (h1 : -2147483648 ≤ x) (h2 : x ≤ 2147483647)
    (mem : CerbMem.MemState) (rs : core_run_state) :
    E.eval_pexpr20 t4File.tagDefs (th18 x) (create_extern_symmap t4File)
      mem t4File convA_PE rs
    = Result (Defined (Sum.inr (loadedV x)), rs) := by
  simp only [E.eval_pexpr20, th18, mkTh]
  rw [convACore_eq x h1 h2 mem]
  rfl

theorem fullEvalConvA18 (x : Int)
    (h1 : -2147483648 ≤ x) (h2 : x ≤ 2147483647)
    (mem : CerbMem.MemState) (rs : core_run_state) :
    full_eval_pexpr t4File.tagDefs (th18 x) (create_extern_symmap t4File)
      mem t4File convA_PE rs
    = Result (Defined (loadedV x), rs) := by
  change stExceptUndef_bind _ _ _ = _
  refine (stub_defined (convAStep18_eq x h1 h2 mem rs)).trans ?_
  rfl

theorem convBStep34_eq (x : Int) (mem : CerbMem.MemState)
    (rs : core_run_state) :
    E.eval_pexpr20 t4File.tagDefs (th34 x) (create_extern_symmap t4File)
      mem t4File convB_PE rs
    = Result (Defined (Sum.inr (loadedV 7)), rs) := by
  simp only [E.eval_pexpr20, th34, mkTh]
  rw [convBCore_eq x mem]
  rfl

theorem fullEvalConvB34 (x : Int) (mem : CerbMem.MemState)
    (rs : core_run_state) :
    full_eval_pexpr t4File.tagDefs (th34 x) (create_extern_symmap t4File)
      mem t4File convB_PE rs
    = Result (Defined (loadedV 7), rs) := by
  show full_eval_pexpr_lemFuel (999999+1) t4File.tagDefs (th34 x)
    (create_extern_symmap t4File) mem t4File convB_PE rs
    = Result (Defined (loadedV 7), rs)
  change stExceptUndef_bind _ _ _ = _
  refine (stub_defined (convBStep34_eq x mem rs)).trans ?_
  rfl

theorem convBStep35_eq (x : Int) (mem : CerbMem.MemState)
    (rs : core_run_state) :
    E.eval_pexpr20 t4File.tagDefs (th35 x) (create_extern_symmap t4File)
      mem t4File convB_PE rs
    = Result (Defined (Sum.inr (loadedV 7)), rs) := by
  simp only [E.eval_pexpr20, th35, mkTh]
  rw [convBCore_eq x mem]
  rfl

theorem fullEvalConvB35 (x : Int) (mem : CerbMem.MemState)
    (rs : core_run_state) :
    full_eval_pexpr t4File.tagDefs (th35 x) (create_extern_symmap t4File)
      mem t4File convB_PE rs
    = Result (Defined (loadedV 7), rs) := by
  show full_eval_pexpr_lemFuel (999999+1) t4File.tagDefs (th35 x)
    (create_extern_symmap t4File) mem t4File convB_PE rs
    = Result (Defined (loadedV 7), rs)
  change stExceptUndef_bind _ _ _ = _
  refine (stub_defined (convBStep35_eq x mem rs)).trans ?_
  rfl

theorem convRStep54_eq (x : Int)
    (h1 : -2147483648 ≤ x) (h2 : x ≤ 2147483647)
    (mem : CerbMem.MemState) (rs : core_run_state) :
    E.eval_pexpr20 t4File.tagDefs (th54 x) (create_extern_symmap t4File)
      mem t4File convR_PE rs
    = Result (Defined (Sum.inr (loadedV x)), rs) := by
  simp only [E.eval_pexpr20, th54, mkTh]
  rw [convRCore_eq x h1 h2 mem]
  rfl

theorem fullEvalConvR54 (x : Int)
    (h1 : -2147483648 ≤ x) (h2 : x ≤ 2147483647)
    (mem : CerbMem.MemState) (rs : core_run_state) :
    full_eval_pexpr t4File.tagDefs (th54 x) (create_extern_symmap t4File)
      mem t4File convR_PE rs
    = Result (Defined (loadedV x), rs) := by
  change stExceptUndef_bind _ _ _ = _
  refine (stub_defined (convRStep54_eq x h1 h2 mem rs)).trans ?_
  rfl

/-- R17: the Epure conv eval (range check on x). -/
theorem round17 (x : Int)
    (h1 : -2147483648 ≤ x) (h2 : x ≤ 2147483647)
    (fuel : Nat) (mem : CerbMem.MemState) (rs : core_run_state)
    (tr : List trace_event) (n : Nat) :
    app (dnms (fuel+1) fmapEmpty [0]) (mkDr (th17 x) mem rs tr n)
      = app (dnms fuel fmapEmpty [0]) (mkDr (th18 x) mem rs tr (n+1)) := by
  refine (app_bind_active rfl).trans ?_
  apply (app_bind_active ?hadv).trans
  case hadv =>
    refine (app_bind_active rfl).trans ?_
    apply (app_bind_active (liftCore_run_defined ?hM)).trans
    case hM =>
      change stExceptUndef_bind _ _ _ = _
      apply (stub_defined ?hEv).trans
      case hEv =>
        change stExceptUndef_bind _ _ _ = _
        refine (stub_defined (fullEvalConvA17 x h1 h2 _ _)).trans ?_
        rfl
      rfl
    rfl
  rfl

/-- R18: the s.a store-operand eval (ctype, pointer, THE CONV CHAIN). -/
theorem round18 (x : Int)
    (h1 : -2147483648 ≤ x) (h2 : x ≤ 2147483647)
    (fuel : Nat) (mem : CerbMem.MemState) (rs : core_run_state)
    (tr : List trace_event) (n : Nat) :
    app (dnms (fuel+1) fmapEmpty [0]) (mkDr (th18 x) mem rs tr n)
      = app (dnms fuel fmapEmpty [0]) (mkDr (th19 x) mem rs tr (n+1)) := by
  refine (app_bind_active rfl).trans ?_
  apply (app_bind_active ?hadv).trans
  case hadv =>
    refine (app_bind_active rfl).trans ?_
    apply (app_bind_active (liftCore_run_defined ?hM)).trans
    case hM =>
      change stExceptUndef_bind _ _ _ = _
      apply (stub_defined ?hOps).trans
      case hOps =>
        change stExceptUndef_bind _ _ _ = _
        apply (stub_defined ?hOp1).trans
        case hOp1 => rfl
        change stExceptUndef_bind _ _ _ = _
        apply (stub_defined ?hOp2).trans
        case hOp2 => rfl
        change stExceptUndef_bind _ _ _ = _
        apply (stub_defined (fullEvalConvA18 x h1 h2 _ _)).trans
        rfl
      rfl
    rfl
  rfl

/-- R34: the Epure conv eval at the literal 7. -/
theorem round34 (x : Int) (fuel : Nat) (mem : CerbMem.MemState)
    (rs : core_run_state) (tr : List trace_event) (n : Nat) :
    app (dnms (fuel+1) fmapEmpty [0]) (mkDr (th34 x) mem rs tr n)
      = app (dnms fuel fmapEmpty [0]) (mkDr (th35 x) mem rs tr (n+1)) := by
  refine (app_bind_active rfl).trans ?_
  apply (app_bind_active ?hadv).trans
  case hadv =>
    refine (app_bind_active rfl).trans ?_
    apply (app_bind_active (liftCore_run_defined ?hM)).trans
    case hM =>
      change stExceptUndef_bind _ _ _ = _
      apply (stub_defined ?hEv).trans
      case hEv =>
        change stExceptUndef_bind _ _ _ = _
        refine (stub_defined (fullEvalConvB34 x _ _)).trans ?_
        rfl
      rfl
    rfl
  rfl

/-- R35: the s.b store-operand eval. -/
theorem round35 (x : Int) (fuel : Nat) (mem : CerbMem.MemState)
    (rs : core_run_state) (tr : List trace_event) (n : Nat) :
    app (dnms (fuel+1) fmapEmpty [0]) (mkDr (th35 x) mem rs tr n)
      = app (dnms fuel fmapEmpty [0]) (mkDr (th36 x) mem rs tr (n+1)) := by
  refine (app_bind_active rfl).trans ?_
  apply (app_bind_active ?hadv).trans
  case hadv =>
    refine (app_bind_active rfl).trans ?_
    apply (app_bind_active (liftCore_run_defined ?hM)).trans
    case hM =>
      change stExceptUndef_bind _ _ _ = _
      apply (stub_defined ?hOps).trans
      case hOps =>
        change stExceptUndef_bind _ _ _ = _
        apply (stub_defined ?hOp1).trans
        case hOp1 => rfl
        change stExceptUndef_bind _ _ _ = _
        apply (stub_defined ?hOp2).trans
        case hOp2 => rfl
        change stExceptUndef_bind _ _ _ = _
        apply (stub_defined (fullEvalConvB35 x _ _)).trans
        rfl
      rfl
    rfl
  rfl

/-- R53: the post-kill collapse (plain). -/
theorem round53 (x : Int) (fuel : Nat) (mem : CerbMem.MemState)
    (rs : core_run_state) (tr : List trace_event) (n : Nat) :
    app (dnms (fuel+1) fmapEmpty [0]) (mkDr (th53 x) mem rs tr n)
      = app (dnms fuel fmapEmpty [0]) (mkDr (th54 x) mem rs tr (n+1)) := by
  refine (app_bind_active rfl).trans ?_
  refine (app_bind_active rfl).trans ?_
  rfl

/-- R54: the Erun conv eval + save jump (label resolution at the
    concrete run state). -/
theorem round54 (x : Int)
    (h1 : -2147483648 ≤ x) (h2 : x ≤ 2147483647)
    (fuel : Nat) (mem : CerbMem.MemState)
    (tr : List trace_event) (n : Nat) :
    app (dnms (fuel+1) fmapEmpty [0]) (mkDr (th54 x) mem r9 tr n)
      = app (dnms fuel fmapEmpty [0]) (mkDr (th55 x) mem r9 tr (n+1)) := by
  refine (app_bind_active rfl).trans ?_
  apply (app_bind_active ?hadv).trans
  case hadv =>
    refine (app_bind_active rfl).trans ?_
    apply (app_bind_active (liftCore_run_defined ?hM)).trans
    case hM =>
      change stExceptUndef_bind _ _ _ = _
      apply (stub_defined ?hLab).trans
      case hLab => rfl
      change stExceptUndef_bind _ _ _ = _
      apply (stub_defined ?hFold).trans
      case hFold =>
        change stExceptUndef_bind _ _ _ = _
        apply (stub_defined ?hElem).trans
        case hElem =>
          change stExceptUndef_bind _ _ _ = _
          apply (stub_defined (fullEvalConvR54 x h1 h2 _ _)).trans
          rfl
        rfl
      rfl
    rfl
  rfl

/-- R56 (terminal). -/
theorem round56 (x : Int) (fuel : Nat) (mem : CerbMem.MemState)
    (rs : core_run_state) (tr : List trace_event) (n : Nat) :
    app (dnms (fuel+2) fmapEmpty [0]) (mkDr (th56 x) mem rs tr n)
      = (NDactive (accDone x), mkDr (th56 x) mem rs tr n) := by
  refine (app_bind_active rfl).trans ?_
  rfl

/-! ## Composition -/

def trFin (x : Int) : List trace_event :=
  [meKill, meLoadA x, meStoreB, meStoreA x, meLoadV x, meStoreU, meCreate]

/-- The full dnms run: fifty-six rounds + terminal. -/
theorem dnms_chain (htags : CerbTags.tagDefs () = t4File.tagDefs)
    (hdig : CerberusFresh.digest () = "")
    (hfresh : rsD3.sym_supply = 1048577)
    (x : Int) (h1 : -2147483648 ≤ x) (h2 : x ≤ 2147483647) :
    app (dnms lemDefaultFuel fmapEmpty [0]) (mkDr th00 (memD3 x) rsD3 [] 0)
      = (NDactive (accDone x),
         mkDr (th56 x) (memK x) r9 (trFin x) 49) :=
  (round0 htags 999999 (memD3 x) rsD3 ([]) 0).trans
  ((round1 htags x 999998 rsD3 ([]) 1).trans
  ((round2 999997 (memC x) r1 [meCreate] 1).trans
  ((round3 999996 (memC x) r1 [meCreate] 2).trans
  ((round4 htags x 999995 r1 [meCreate] 3).trans
  ((round5 999994 (memU x) r2 [meStoreU, meCreate] 3).trans
  ((round6 999993 (memU x) r2 [meStoreU, meCreate] 4).trans
  ((round7 999992 (memU x) r2 [meStoreU, meCreate] 5).trans
  ((round8 999991 (memU x) r2 [meStoreU, meCreate] 6).trans
  ((round9 x h1 h2 999990 r2 [meStoreU, meCreate] 7).trans
  ((round10 x 999989 (memU x) r3 [meLoadV x, meStoreU, meCreate] 7).trans
  ((round11 x 999988 (memU x) r3 [meLoadV x, meStoreU, meCreate] 8).trans
  ((round12 htags x 999987 (memU x) r3 [meLoadV x, meStoreU, meCreate] 9).trans
  ((round13 x 999986 (memU x) r3 [meLoadV x, meStoreU, meCreate] 10).trans
  ((round14 x 999985 (memU x) r3 [meLoadV x, meStoreU, meCreate] 11).trans
  ((round15 hdig hfresh x 999984 (memU x) [meLoadV x, meStoreU, meCreate] 12).trans
  ((round16 x 999983 (memU x) r4 [meLoadV x, meStoreU, meCreate] 13).trans
  ((round17 x h1 h2 999982 (memU x) r4 [meLoadV x, meStoreU, meCreate] 14).trans
  ((round18 x h1 h2 999981 (memU x) r4 [meLoadV x, meStoreU, meCreate] 15).trans
  ((round19 x 999980 r4 [meLoadV x, meStoreU, meCreate] 16).trans
  ((round20 x 999979 (memA x) r5 [meStoreA x, meLoadV x, meStoreU, meCreate] 16).trans
  ((round21 x 999978 (memA x) r5 [meStoreA x, meLoadV x, meStoreU, meCreate] 17).trans
  ((round22 x 999977 (memA x) r5 [meStoreA x, meLoadV x, meStoreU, meCreate] 18).trans
  ((round23 x 999976 (memA x) r5 [meStoreA x, meLoadV x, meStoreU, meCreate] 19).trans
  ((round24 x 999975 (memA x) r5 [meStoreA x, meLoadV x, meStoreU, meCreate] 20).trans
  ((round25 x 999974 (memA x) r5 [meStoreA x, meLoadV x, meStoreU, meCreate] 21).trans
  ((round26 x 999973 (memA x) r5 [meStoreA x, meLoadV x, meStoreU, meCreate] 22).trans
  ((round27 x 999972 (memA x) r5 [meStoreA x, meLoadV x, meStoreU, meCreate] 23).trans
  ((round28 x 999971 (memA x) r5 [meStoreA x, meLoadV x, meStoreU, meCreate] 24).trans
  ((round29 htags x 999970 (memA x) r5 [meStoreA x, meLoadV x, meStoreU, meCreate] 25).trans
  ((round30 x 999969 (memA x) r5 [meStoreA x, meLoadV x, meStoreU, meCreate] 26).trans
  ((round31 x 999968 (memA x) r5 [meStoreA x, meLoadV x, meStoreU, meCreate] 27).trans
  ((round32 hdig hfresh x 999967 (memA x) [meStoreA x, meLoadV x, meStoreU, meCreate] 28).trans
  ((round33 x 999966 (memA x) r6 [meStoreA x, meLoadV x, meStoreU, meCreate] 29).trans
  ((round34 x 999965 (memA x) r6 [meStoreA x, meLoadV x, meStoreU, meCreate] 30).trans
  ((round35 x 999964 (memA x) r6 [meStoreA x, meLoadV x, meStoreU, meCreate] 31).trans
  ((round36 x 999963 r6 [meStoreA x, meLoadV x, meStoreU, meCreate] 32).trans
  ((round37 x 999962 (memB x) r7 [meStoreB, meStoreA x, meLoadV x, meStoreU, meCreate] 32).trans
  ((round38 x 999961 (memB x) r7 [meStoreB, meStoreA x, meLoadV x, meStoreU, meCreate] 33).trans
  ((round39 x 999960 (memB x) r7 [meStoreB, meStoreA x, meLoadV x, meStoreU, meCreate] 34).trans
  ((round40 x 999959 (memB x) r7 [meStoreB, meStoreA x, meLoadV x, meStoreU, meCreate] 35).trans
  ((round41 x 999958 (memB x) r7 [meStoreB, meStoreA x, meLoadV x, meStoreU, meCreate] 36).trans
  ((round42 x 999957 (memB x) r7 [meStoreB, meStoreA x, meLoadV x, meStoreU, meCreate] 37).trans
  ((round43 x 999956 (memB x) r7 [meStoreB, meStoreA x, meLoadV x, meStoreU, meCreate] 38).trans
  ((round44 x 999955 (memB x) r7 [meStoreB, meStoreA x, meLoadV x, meStoreU, meCreate] 39).trans
  ((round45 htags x 999954 (memB x) r7 [meStoreB, meStoreA x, meLoadV x, meStoreU, meCreate] 40).trans
  ((round46 x 999953 (memB x) r7 [meStoreB, meStoreA x, meLoadV x, meStoreU, meCreate] 41).trans
  ((round47 x 999952 (memB x) r7 [meStoreB, meStoreA x, meLoadV x, meStoreU, meCreate] 42).trans
  ((round48 x h1 h2 999951 r7 [meStoreB, meStoreA x, meLoadV x, meStoreU, meCreate] 43).trans
  ((round49 x 999950 (memB x) r8 [meLoadA x, meStoreB, meStoreA x, meLoadV x, meStoreU, meCreate] 43).trans
  ((round50 x 999949 (memB x) r8 [meLoadA x, meStoreB, meStoreA x, meLoadV x, meStoreU, meCreate] 44).trans
  ((round51 x 999948 (memB x) r8 [meLoadA x, meStoreB, meStoreA x, meLoadV x, meStoreU, meCreate] 45).trans
  ((round52 x 999947 r8 [meLoadA x, meStoreB, meStoreA x, meLoadV x, meStoreU, meCreate] 46).trans
  ((round53 x 999946 (memK x) r9 [meKill, meLoadA x, meStoreB, meStoreA x, meLoadV x, meStoreU, meCreate] 46).trans
  ((round54 x h1 h2 999945 (memK x) [meKill, meLoadA x, meStoreB, meStoreA x, meLoadV x, meStoreU, meCreate] 47).trans
  ((round55 x 999944 (memK x) r9 [meKill, meLoadA x, meStoreB, meStoreA x, meLoadV x, meStoreU, meCreate] 48).trans
  (round56 x 999942 (memK x) r9 [meKill, meLoadA x, meStoreB, meStoreA x, meLoadV x, meStoreU, meCreate] 49))))))))))))))))))))))))))))))))))))))))))))))))))))))))
/-- The scheduler sees exactly the done step. -/
theorem ndct_eq (htags : CerbTags.tagDefs () = t4File.tagDefs)
    (hdig : CerberusFresh.digest () = "")
    (hfresh : rsD3.sym_supply = 1048577)
    (x : Int) (h1 : -2147483648 ≤ x) (h2 : x ≤ 2147483647) :
    app (new_drive_core_threads t4File.tagDefs ())
        (mkDr th00 (memD3 x) rsD3 [] 0)
      = (NDactive [(0, some (Step_done2 (loadedV x)))],
         mkDr (th56 x) (memK x) r9 (trFin x) 49) := by
  refine (app_bind_active rfl).trans ?_
  refine (app_bind_active (dnms_chain htags hdig hfresh x h1 h2)).trans ?_
  rfl

/-! ## The prefix walk -/

def finTail : Unit → driverM driver_result :=
  fun _ => nd_bind nd_get (fun (dr_st' : driver_state) =>
    nd_return (finalize t4File.tagDefs "callND" dr_st'))

theorem mvvV_fact (v : Int) :
    memValueFromValue t4File.tagDefs signed_int (intValue v)
      = some (CerbMem.MemValue.MVinteger (Signed Int_)
          (CerbMem.IntegerValue.IV .Prov_none v)) := rfl

def injPhase (x : Int) : driverM driver_result :=
  nd_bind (injectArgs t4File.tagDefs 0
      [(symV, BTy_object OTy_pointer)] [signed_int] [intValue x])
    (fun (bound : List (sym × value)) =>
      callFinish t4File.tagDefs 0 membT4Sym arena00 bound)

theorem prefix_a0 (x : Int) :
    app (callND t4File.tagDefs t4File "memb" [intValue x])
        (initial_driver_state t4File CerbFS.fs_initial_state)
      = app (injPhase x)
          (mkDr thG CerbMem.initialMemState rsD3 [] 0) := by
  refine (app_bind_active rfl).trans ?_   -- driver_globals
  refine (app_bind_active rfl).trans ?_   -- nd_get
  refine (app_bind_active rfl).trans ?_   -- resolveFunSym
  refine (app_bind_active rfl).trans ?_   -- lookupFunBody
  refine (app_bind_active rfl).trans ?_   -- lookupParamTys
  rfl

theorem prefix_a1 (x : Int) :
    app (injPhase x) (mkDr thG CerbMem.initialMemState rsD3 [] 0)
      = app (callFinish t4File.tagDefs 0 membT4Sym arena00
          [(symV, vPtrV)])
          (mkDr thG (memV x) rsD3 [] 0) := by
  apply (app_bind_active ?hinj).trans
  case hinj =>
    simp only [injectArgs, injectArg, mvvV_fact]
    apply (app_bind_active (app_liftND_active _ _ _ _ ?hmv)).trans
    case hmv =>
      refine (app_bind_active allocV_eq).trans ?_
      refine (app_bind_active (storeV_eq x)).trans ?_
      exact app_nd_return (Vobject (OVpointer vPtr)) (memV x)
    refine (app_bind_active rfl).trans ?_   -- injectArgs []
    rfl
  rfl

theorem prefix_b (x : Int) :
    app (callFinish t4File.tagDefs 0 membT4Sym arena00
        [(symV, vPtrV)])
        (mkDr thG (memV x) rsD3 [] 0)
      = app (nd_bind (driver2 t4File.tagDefs false) finTail)
          (mkDr th00 (memD3 x) rsD3 [] 0) := by
  refine (app_bind_active
    (v := (mkDr thG (memV x) rsD3 [] 0).core_state0.thread_states)
    (st' := mkDr thG (memV x) rsD3 [] 0) rfl).trans ?_
  apply (app_bind_active (app_liftND_active _ _ _ _ ?hmem)).trans
  case hmem =>
    refine (app_bind_active (errAlloc_eq x)).trans ?_
    refine (app_bind_active (errStore_eq x)).trans ?_
    exact app_nd_return errPtr (memD3 x)
  refine (app_bind_active rfl).trans ?_  -- driver_update_thread_state
  rfl

theorem prefix_walk (x : Int) :
    app (callND t4File.tagDefs t4File "memb" [intValue x])
        (initial_driver_state t4File CerbFS.fs_initial_state)
      = app (nd_bind (driver2 t4File.tagDefs false) finTail)
          (mkDr th00 (memD3 x) rsD3 [] 0) :=
  ((prefix_a0 x).trans (prefix_a1 x)).trans (prefix_b x)

/-- The post-exit thread. -/
def thDone (x : Int) : thread_state :=
  { th56 x with stack0 := Stack_empty, arena := mk_value_e (loadedV x) }

/-- The final driver state of the harness run. -/
def drDone (x : Int) : driver_state :=
  mkDr (thDone x) (memK x) r9 (trFin x) 49

/-- ONE driver2 iteration does the whole run. -/
theorem driver2_iter (htags : CerbTags.tagDefs () = t4File.tagDefs)
    (hdig : CerberusFresh.digest () = "")
    (hfresh : rsD3.sym_supply = 1048577)
    (x : Int) (h1 : -2147483648 ≤ x) (h2 : x ≤ 2147483647) :
    app (driver2 t4File.tagDefs false) (mkDr th00 (memD3 x) rsD3 [] 0)
      = (NDactive (), drDone x) := by
  show app (driver2_lemFuel (999999+1) t4File.tagDefs false)
    (mkDr th00 (memD3 x) rsD3 [] 0) = (NDactive (), drDone x)
  change app (nd_bind _ _) _ = _
  refine (app_bind_active (ndct_eq htags hdig hfresh x h1 h2)).trans ?_
  refine (app_bind_active rfl).trans ?_          -- nd_get
  cases hmode : Lem_Maybe.maybeEqualBy (fun x y => x == y)
      (CerbGlobal.current_execution_mode ())
      (some CerbGlobal.ExecutionMode.random) with
  | true =>
    simp only [reduceIte, bindExhaustive]
    apply (app_bind_active ?hpickT).trans
    case hpickT => rfl
    apply (app_bind_active ?hdbgT).trans
    case hdbgT => rfl
    rfl
  | false =>
    simp only [reduceIte]
    apply (app_bind_active ?hgrd).trans
    case hgrd => rfl
    apply (app_bind_active ?hpickF).trans
    case hpickF => rfl
    apply (app_bind_active ?hdbgF).trans
    case hdbgF => rfl
    rfl

/-- THE T4 HARNESS APP EQUATION, composed (under the tag-global
    hypothesis — the boundary honesty note in the header). -/
theorem t4_app_eq (htags : CerbTags.tagDefs () = t4File.tagDefs)
    (hdig : CerberusFresh.digest () = "")
    (hfresh : rsD3.sym_supply = 1048577)
    (x : Int) (h1 : -2147483648 ≤ x) (h2 : x ≤ 2147483647) :
    app (callND t4File.tagDefs t4File "memb" [intValue x])
        (initial_driver_state t4File CerbFS.fs_initial_state)
      = (NDactive (finalize t4File.tagDefs "callND" (drDone x)),
         drDone x) := by
  refine (prefix_walk x).trans ?_
  refine (app_bind_active (driver2_iter htags hdig hfresh x h1 h2)).trans ?_
  refine (app_bind_active rfl).trans ?_          -- finTail's nd_get
  rfl

/-- The finalize result carries the injected integer, Specified. -/
theorem t4_result_eq (x : Int) :
    (finalize t4File.tagDefs "callND" (drDone x)).dres_core_value
      = intValue x := rfl




end RelSem.T4
