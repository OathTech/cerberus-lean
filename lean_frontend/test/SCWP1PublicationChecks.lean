import Unit.SCWP1Decision
import Unit.SCWP1SummaryRuntime

namespace SCWP1PublicationChecks
open SCWP1Stepping SCWP1Decision SCWP1Summary CerbMem

def store (name : String) (p : PointerValue) (n : Int) (mo : memory_order) : expr core_run_annotation :=
  Expr [] (Eaction (Paction Pos (Action (CerbLocation.Loc.other name) default
    (Store0 false (mk_value_pe (Vctype unsigned_char)) (mk_value_pe (Vobject (OVpointer p)))
      (mk_value_pe (Vloaded (LVspecified (OVinteger (iv n))))) mo))))
def load (name : String) (p : PointerValue) (mo : memory_order) : expr core_run_annotation :=
  Expr [] (Eaction (Paction Pos (Action (CerbLocation.Loc.other name) default
    (Load0 (mk_value_pe (Vctype unsigned_char)) (mk_value_pe (Vobject (OVpointer p))) mo))))

def trace (c : Config) : List (String × Int) :=
  ((c.base.experiment_state.layout_state.observations.getD []).reverse.filterMap fun r =>
    match r with
    | .Access_receipt l _ _ _ _ _ _ (.MVinteger _ (.IV _ v)) _ =>
      ([("d","data"),("p","publish"),("a","acquire"),("c","consume")].find? (fun s => l == CerbLocation.Loc.other s.2)).map (fun s => (s.1,v))
    | _ => none)

def enumerate [LemFuel] : Nat → Config → List (List (String × Int))
  | 0,_ => [[("INCOMPLETE",0)]]
  | n+1,c =>
    if experiment_terminal c.base then
      match c.base.experiment_phase0 with
      | .Exp_done _ => [trace c]
      | _ => [[("FAILED",0)]]
    else ((List.range (max 1 (choices c).length)).flatMap fun i =>
      enumerate n (SCWP1Decision.step i c)).eraseDups

/-- Observe the two concrete threads' straight-line source frontiers. The
    only conditional is the actual Core read-dependent branch. Reference
    schedules below are specified independently of this monitor. -/
def firstRace (tr : List (String × Int)) (acquireEdge : Bool) (inventOrder : Bool) : IO (Option String) := do
  let mut s ← emit empty "init" []
  s ← copy s "producer" "init"
  s ← copy s "consumer" "init"
  s ← copy s "flag" "init"
  let mut last : Option String := none
  let mut wrote := false
  let mut read := false
  for (name,v) in tr do
    let who := if name == "d" || name == "p" then "producer" else "consumer"
    let extra := if inventOrder then last.toList else []
    let acquired := if name == "a" && v == 1 && acquireEdge then ["flag"] else []
    s ← emit s who (who :: acquired ++ extra)
    if name == "d" then
      if read then
        if !(← precedes s "read-data" who) then return some "d"
      wrote := true
      s ← copy s "write-data" who
    if name == "p" then s ← copy s "flag" who
    if name == "c" then
      if wrote then
        if !(← precedes s "write-data" who) then return some "c"
      read := true
      s ← copy s "read-data" who
    s ← copy s "scheduled-last" who
    last := some "scheduled-last"
  return none

def check (fuel : Nat) : IO Unit :=
  letI := LemFuel.mk fuel
  do
    let (.NDactive p, mem) := evalND (allocateRegion 0 (PrefOther "data") (iv 1) (iv 1)) (initialMemState 65536)
      | throw (IO.userError "data")
    let (.NDactive q, mem) := evalND (allocateRegion 0 (PrefOther "flag") (iv 1) (iv 1)) mem
      | throw (IO.userError "flag")
    let (.NDactive _, mem) := evalND (storeM fmapEmpty fmapEmpty loc unsigned_char false p (.MVinteger (.Unsigned .Ichar) (iv 0))) mem
      | throw (IO.userError "init data")
    let (.NDactive _, mem) := evalND (storeM fmapEmpty fmapEmpty loc unsigned_char false q (.MVinteger (.Unsigned .Ichar) (iv 0))) mem
      | throw (IO.userError "init flag")
    let producer := Expr [] (Esseq (mk_empty_pat BTy_unit) (store "data" p 42 NA) (store "publish" q 1 Seq_cst))
    let consumer := Expr [] (Ewseq (mk_specified_pat (mk_sym_pat globSym (BTy_object OTy_integer)))
      (load "acquire" q Seq_cst) (Expr [] (Eif (mk_op_pe OpEq (mk_sym_pe globSym) (mk_integer_pe 1))
        (load "consume" p NA) (mk_value_e (Vloaded (LVspecified (OVinteger (iv 0))))))))
    let arena := Expr [] (Ewseq (mk_tuple_pat [mk_empty_pat BTy_unit,mk_sym_pat spinSym (BTy_loaded OTy_integer)])
      (Expr [] (Epar [producer,consumer])) (mk_pure_e (mk_sym_pe spinSym)))
    let f := fileFor arena
    let st := { initial f with layout_state := { mem with observations := some [] } }
    let traces := enumerate 36 ⟨experiment_start fmapEmpty fmapEmpty f [] st, []⟩
    -- All linear extensions of d < p, with the actual read deciding whether
    -- c exists. Initially flag=0; only p writes 1. Thus exactly these traces.
    let expected := [[("d",42),("p",1),("a",1),("c",42)],
      [("d",42),("a",0),("p",1)],[("a",0),("d",42),("p",1)]]
    require (traces.length == expected.length && expected.all traces.contains) s!"publication coverage: {traces}"
    for tr in traces do require ((← firstRace tr true false).isNone) "publication falsely races"
    let published := expected.head!
    require ((← firstRace published false false) == some "c") "missing synchronization control did not expose first conflict"
    require ((← firstRace published false true).isNone) "invented scheduler edge control did not mask race"
    IO.println s!"fuel={fuel} all Core publication/control-flow traces: {traces}"
    IO.println s!"fuel={fuel} reference publication race-free; removing acquire edge races first at c; inventing scheduler edge incorrectly masks it"

#eval check 64
#eval check 128
end SCWP1PublicationChecks
