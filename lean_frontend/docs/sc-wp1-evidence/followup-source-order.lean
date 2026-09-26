import Unit.SCWP1Stepping

namespace SCWP1SourceOrder
open SCWP1Stepping CerbMem

def unit : expr core_run_annotation := mk_value_e Vunit
def voidPat := mk_empty_pat BTy_unit
def action (name : String) (p : PointerValue) (pol : polarity) : expr core_run_annotation :=
  Expr [] (Eaction (Paction pol (Action (CerbLocation.Loc.other name) default
    (Store0 false (mk_value_pe (Vctype unsigned_char))
      (mk_value_pe (Vobject (OVpointer p)))
      (mk_value_pe (Vloaded (LVspecified (OVinteger (iv 1))))) NA))))
def weak (a b : expr core_run_annotation) := Expr [] (Ewseq voidPat a b)
def strong (a b : expr core_run_annotation) := Expr [] (Esseq voidPat a b)
def parallel (a b : expr core_run_annotation) :=
  Expr [] (Ewseq (mk_tuple_pat [voidPat, voidPat]) (Expr [] (Eunseq [a,b])) unit)

def trace (c : experiment_config) : String :=
  String.join ((c.experiment_state.layout_state.observations.getD []).reverse.filterMap
    (fun r => match r with
      | .Access_receipt l .. =>
        if l == CerbLocation.Loc.other "a" then some "a"
        else if l == CerbLocation.Loc.other "b" then some "b"
        else if l == CerbLocation.Loc.other "c" then some "c"
        else none))

def tally (key : String) (n : Nat) : List (String × Nat) → List (String × Nat)
  | [] => [(key,n)]
  | (k,m) :: xs => if key == k then (k,m+n) :: xs else (k,m) :: tally key n xs
def merge (a b : List (String × Nat)) := b.foldl (fun xs (k,n) => tally k n xs) a
def enumerate [LemFuel] : Nat → experiment_config → List (String × Nat)
  | 0, c => [("INCOMPLETE:" ++ trace c,1)]
  | n+1, c =>
    if experiment_terminal c then
      [(match c.experiment_phase0 with
        | .Exp_done _ => trace c
        | .Exp_killed (.Undef0 _ [.UB035_unsequenced_race]) => "UNSEQUENCED:" ++ trace c
        | .Exp_killed _ => "OTHER_KILL:" ++ trace c
        | _ => "OTHER:" ++ trace c,1)]
    else
      let count := max 1 (experiment_choice_count c)
      (List.range count).foldl (fun xs i => merge xs (enumerate n (step i c))) []

def checkAt (fuel : Nat) : IO Unit :=
  letI := LemFuel.mk fuel
  do
    let (.NDactive p, mem) := evalND (allocateRegion 0 (PrefOther "a") (iv 1) (iv 1))
      (initialMemState 65536) | throw (IO.userError "p")
    let (.NDactive q, mem) := evalND (allocateRegion 0 (PrefOther "b") (iv 1) (iv 1)) mem
      | throw (IO.userError "q")
    let (.NDactive r, mem) := evalND (allocateRegion 0 (PrefOther "c") (iv 1) (iv 1)) mem
      | throw (IO.userError "r")
    let a := action "a" p Pos
    let an := action "a" p polarity.Neg0
    let b := action "b" q Pos
    let c := action "c" r Pos
    -- Expectations are enumerations of declarative partial orders, not sampled
    -- runs: unseq adds no edge; weak sequences positive but not negative a;
    -- strong orders either polarity; final c follows both unseq operands.
    let fixtures := [
      ("unseq-positive", parallel a b, ["ab","ba"]),
      ("weak-positive", weak a b, ["ab"]),
      ("strong-positive", strong a b, ["ab"]),
      ("weak-negative", weak an b, ["ab","ba"]),
      ("strong-negative", strong an b, ["ab"]),
      ("strong-closed-negative-through-weak", weak (strong an unit) b, ["ab"]),
      ("unseq-then-positive", weak (parallel a b) c, ["abc","bac"]),
      ("weak-negative-chain", weak (weak an b) c, ["abc","bac","bca"]),
      ("strong-negative-chain", strong (weak an b) c, ["abc","bac"])]
    for (name, body, expected) in fixtures do
      let f := fileFor (strong (Expr [] (Ebound body)) done)
      let st := { initial f with layout_state := { mem with observations := some [] } }
      let cfg := experiment_start fmapEmpty fmapEmpty f [] st
      let results := enumerate 40 cfg
      let actual := results.map Prod.fst
      require (actual.length == expected.length && expected.all actual.contains)
        s!"{name} expected {expected}, got {results}"
      IO.println s!"fuel={fuel} {name}: complete Core schedules={results}"

    let bSame := action "b" p Pos
    let f := fileFor (strong (Expr [] (Ebound (parallel a bSame))) done)
    let st := { initial f with layout_state := { mem with observations := some [] } }
    let rs := enumerate 40 (experiment_start fmapEmpty fmapEmpty f [] st)
    require (rs.length == 2 && rs.all (fun (key,_) => key == "UNSEQUENCED:ab" || key == "UNSEQUENCED:ba"))
      s!"finite unsequenced conflict control: {rs}"
    IO.println s!"fuel={fuel} finite-conflict: {rs}"

    let arena := Expr [] (Esseq
      (mk_empty_pat (BTy_tuple [BTy_unit, BTy_unit, BTy_loaded OTy_integer]))
      (Expr [] (Ebound (Expr [] (Eunseq [a,bSame,Expr [] (Eproc empty_annotation (Sym spinSym) [])])))) done)
    let f := { fileFor arena with funs := symMap [
      (mainSym, Proc loc none (BTy_loaded OTy_integer) [] arena),
      (spinSym, Proc loc none (BTy_loaded OTy_integer) [] loop)] }
    let st := { initial f with layout_state := { mem with observations := some [] } }
    let mut cfg := step 0 (experiment_start fmapEmpty fmapEmpty f [] st)
    for name in ["a","b"] do
      let some i := (experiment_runnable cfg.experiment_state.core_state0).findIdx? (fun (_,_,(_,e)) =>
        match e with
        | Expr _ (Eaction (Paction _ (Action l ..))) => l == CerbLocation.Loc.other name
        | _ => false) | throw (IO.userError "selected race access unavailable")
      cfg := step i cfg
    require (trace cfg == "ab") "conflicting prefix was not executed"
    let .Exp_incomplete afterLoop := bounded (List.replicate 1000 0) cfg
      | throw (IO.userError "expected inherited delayed-race diagnostic to remain incomplete")
    require (trace afterLoop == "ab" && receiptCount afterLoop.experiment_state == 3)
      "race-before-loop unexpectedly changed effects"
    IO.println s!"fuel={fuel} race-before-loop: two conflicting writes completed; inherited Core checker still incomplete after 1000 further steps"

#eval checkAt 64
#eval checkAt 128
end SCWP1SourceOrder
