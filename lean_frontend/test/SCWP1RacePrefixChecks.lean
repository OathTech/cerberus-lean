import Unit.SCWP1Decision
import Unit.SCWP1SummaryRuntime

namespace SCWP1RacePrefixChecks
open SCWP1Stepping SCWP1Decision SCWP1Summary CerbMem

def action (name : String) (p : PointerValue) : expr core_run_annotation :=
  Expr [] (Eaction (Paction Pos (Action (CerbLocation.Loc.other name) default
    (Store0 false (mk_value_pe (Vctype unsigned_char)) (mk_value_pe (Vobject (OVpointer p)))
      (mk_value_pe (Vloaded (LVspecified (OVinteger (iv 1))))) NA))))

def check (fuel : Nat) : IO Unit :=
  letI := LemFuel.mk fuel
  do
    let (.NDactive p, mem) := evalND (allocateRegion 0 (PrefOther "shared") (iv 1) (iv 1)) (initialMemState 65536)
      | throw (IO.userError "shared")
    let arena := Expr [] (Esseq (mk_empty_pat (BTy_tuple [BTy_unit,BTy_unit,BTy_loaded OTy_integer]))
      (Expr [] (Ebound (Expr [] (Eunseq [action "a" p, action "b" p,
        Expr [] (Eproc empty_annotation (Sym spinSym) [])])))) done)
    let f := { fileFor arena with funs := symMap [(mainSym,Proc loc none (BTy_loaded OTy_integer) [] arena),
      (spinSym,Proc loc none (BTy_loaded OTy_integer) [] loop)] }
    let st := { initial f with layout_state := { mem with observations := some [] } }
    for order in [["a","b"],["b","a"]] do
      let mut c : Config := ⟨experiment_start fmapEmpty fmapEmpty f [] st, []⟩
      c := SCWP1Decision.step 0 c
      -- Domain-specific source observer: these are two different operands of
      -- this actual Eunseq, hence share only the pre-split parent frontier.
      let mut s ← emit empty "parent" []
      s ← copy s "a" "parent"
      s ← copy s "b" "parent"
      let mut prior : Option (String × Footprint) := none
      let mut first : Option String := none
      for name in order do
        let some i := (choices c).findIdx? (fun ch => match ch with
          | .core _ _ (_,Expr _ (Eaction (Paction _ (Action l ..)))) => l == CerbLocation.Loc.other name
          | _ => false) | throw (IO.userError "chosen source operand unavailable")
        c := SCWP1Decision.step i c
        let some (.Access_receipt _ .StoreAccess _ _ _ address bytes _ _) :=
          (c.base.experiment_state.layout_state.observations.getD []).head?
          | throw (IO.userError "selected write did not complete")
        let fp := Footprint.FP .W address (Int.ofNat bytes.length)
        s ← emit s name [name]
        match prior with
        | none => prior := some (name,fp)
        | some (previous,oldFP) =>
          if overlapping oldFP fp && !(← precedes s previous name) then first := some name
      require (first == order[1]? && c.base.experiment_steps == 3 &&
        receiptCount c.base.experiment_state == 3 && !experiment_terminal c.base)
        "first conflict/prefix was lost or delayed until looping operand"
      IO.println s!"fuel={fuel} source-order={order}: first conflict at second completed write; 3 paid steps; errno+2 receipts; loop never selected"

#eval check 64
#eval check 128
end SCWP1RacePrefixChecks
