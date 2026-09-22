import CerbSCOperational
import CerbND

open Lem_Map Lem_Basic_classes
namespace SCProtocolControls

def mainSym : sym := Symbol "sc-protocol-control" 1 SD_None

def intval (n : Int) : value := Vloaded (LVspecified (OVinteger (CerbMem.integerIval n)))
def pureExpr (v : value) : expr core_run_annotation := Expr [] (Epure (Pexpr [] () (PEval v)))
def parExpr (es : List (expr core_run_annotation)) : expr core_run_annotation := Expr [] (Epar es)

def program (body : expr core_run_annotation) : file core_run_annotation :=
  { main := some mainSym, calling_convention0 := default, tagDefs := default,
    stdlib := fmapEmpty, impl0 := fmapEmpty, globs := [],
    funs := fmapAddBy (fun (s1 s2 : sym) => ordCompare s1 s2) mainSym
      (Proc CerbLocation.unknown none BTy_unit [] body) fmapEmpty,
    extern := fmapEmpty, funinfo := fmapEmpty, loop_attributes1 := default,
    visible_objects_env0 := default }

def runProgram [LemFuel] (f : file core_run_annotation)
    (setup : driver_state → driver_state := id) :=
  let s := setup (initial_driver_state 2 0x10000 f CerbFS.fs_initial_state).1
  CerbND.runND (nd_bind sc_enable (fun () => drive_recorded f.tagDefs true f ["SC test"])) s

def run [LemFuel] (body : expr core_run_annotation) := runProgram (program body)

def outcomeText : nd_status driver_result driver_error driver_state → String
  | Active result => if result.dres_blocked then "blocked" else "active"
  | Killed _ (Error0 _ msg) => "Error: " ++ msg
  | Killed _ (Other (DErr_concurrency msg)) => "SC gap: " ++ msg
  | Killed _ (Other (DErr_core_run (Illformed_program msg))) => "Core: " ++ msg
  | Killed _ _ => "killed (other cause)"

def expect (fuel : Nat) (name : String) (body : expr core_run_annotation)
    (expected : value) (blocked : Bool := false) : IO Bool :=
  letI := LemFuel.mk fuel
  let results := run body
  let good := !results.isEmpty && results.all (fun (status, _, _) =>
    match status with
    | Active result => result.dres_blocked == blocked && result.dres_core_value == expected
    | _ => false)
  IO.println (name ++ ": " ++ toString results.length ++ " alternatives; pass=" ++ toString good) >>= fun _ => pure good

def pe (v : value) : pexpr := Pexpr [] () (PEval v)
def pointer (id address : Int) : CerbMem.PointerValue :=
  .PV (.Prov_some id) (.PVconcrete none address)
def storeExpr (id address : Int) : expr core_run_annotation :=
  Expr [] (Eaction (Paction Pos (Action (CerbLocation.other "SC ordering control") empty_annotation
    (Store0 false (pe (Vctype unsigned_char)) (pe (Vobject (OVpointer (pointer id address))))
      (pe (intval 7)) NA))))
def memorySetup (s : driver_state) : driver_state :=
  { s with layout_state := { s.layout_state with
    allocations := (s.layout_state.allocations.insert 20 {base := 200, size := 1}).insert 30 {base := 300, size := 1}
    bytemap := (s.layout_state.bytemap.insert 200 {value := some 7}).insert 300 {value := some 7} } }

def calleeSym : sym := Symbol "sc-protocol-control" 40 SD_None
def callExpr (cCall : Bool) : expr core_run_annotation :=
  Expr [] (if cCall then
    Eccall empty_annotation (pe (Vctype unsigned_char))
      (pe (Vloaded (LVspecified (OVpointer (.PV .Prov_none (.PVfunction calleeSym)))))) []
    else Eproc empty_annotation (Sym calleeSym) [])

def memoryEffects (s : driver_state) : List sc_effect :=
  match s.sc_state0 with
  | none => []
  | some sc => sc.sc_effects.reverse.filter fun e =>
      match e.sc_effect_observation with
      | Observe_access _ _ _ _ (some id) _ _ _ _ => id == 20 || id == 30
      | _ => false

def effectBefore (before after : sc_effect) : Bool :=
  setMemberBy setElemCompare
    (before.sc_effect_request.sc_request_thread, before.sc_effect_id)
    after.sc_effect_request.sc_request_annotation.sb_before

def expectOrdering (fuel : Nat) (name : String) (body : expr core_run_annotation)
    (ordered : Bool) : IO Bool :=
  letI := LemFuel.mk fuel
  let f := program body
  let f := { f with funs := (fmapAddBy (fun (x y : sym) => ordCompare x y) calleeSym
    (Proc CerbLocation.unknown none BTy_unit [] (storeExpr 20 200)) f.funs) }
  let results := runProgram f memorySetup
  let good := !results.isEmpty && results.all (fun (status, _, s) =>
    match status with
    | Active r => !r.dres_blocked && match memoryEffects s with
      | [first, second] => effectBefore first second == ordered && !effectBefore second first
      | _ => false
    | _ => false)
  IO.println (name ++ ": " ++ toString results.length ++ " alternatives; pass=" ++ toString good) >>= fun _ =>
  (if good then pure () else results.take 2 |>.forM (fun (status, _, s) =>
    IO.println (outcomeText status ++ "; memory effects=" ++ toString (memoryEffects s).length))) >>= fun _ =>
  pure good

def expectThreadEdges (fuel : Nat) (name : String) (body : expr core_run_annotation) : IO Bool :=
  letI := LemFuel.mk fuel
  let results := runProgram (program body) memorySetup
  let good := !results.isEmpty && results.all (fun (status, _, s) =>
    match status with
    | Active r => !r.dres_blocked && match memoryEffects s with
      | [first, second] =>
        first.sc_effect_request.sc_request_thread != second.sc_effect_request.sc_request_thread &&
        !effectBefore first second &&
        setMemberBy setElemCompare first.sc_effect_id
          second.sc_effect_request.sc_request_annotation.asw_before
      | _ => false
    | _ => false)
  IO.println (name ++ ": " ++ toString results.length ++ " alternatives; pass=" ++ toString good) >>= fun _ => pure good

def observerControls (fuel : Nat) : List (String × Bool) := Id.run do
  letI := LemFuel.mk fuel
  let f := program (pureExpr Vunit)
  let base := memorySetup (initial_driver_state 2 0x10000 f CerbFS.fs_initial_state).1
  let enabled := (CerbSCOperational.node
    (sc_enable : ndM Unit step_kind driver_error (mem_constraint CerbMem.IntegerValue) driver_state) base).2
  let ready := sc_request_state 0 (SC_runtime "copy control") empty_annotation enabled
  let copyAction := CerbMem.memcpyM f.tagDefs (CerbLocation.other "SC copy control")
      (pointer 30 300) (pointer 20 200) (CerbMem.integerIval 2)
  let copy := CerbSCOperational.node (driver_liftMem copyAction) ready
  let original := CerbSCOperational.node (liftMem copyAction) ready
  let unowned := CerbSCOperational.node
    (driver_liftMem (CerbMem.loadM f.tagDefs (CerbLocation.other "SC ownership control")
      unsigned_char (pointer 20 200))) enabled
  let kinds := (memoryEffects copy.2).filterMap fun e => match e.sc_effect_observation with
    | Observe_access _ kind _ _ _ _ _ _ _ => some kind
    | _ => none
  return [
    ("driver preserves original copy failure", match copy.1, original.1 with
      | NDkilled reason, NDkilled originalReason => reason == originalReason
      | _, _ => false),
    ("driver records read and equal-value write before copy failure", kinds == [LoadAccess, StoreAccess]),
    ("driver drains successful owned observation journal", match copy.2.layout_state.observations with
      | some [] => true | _ => false),
    ("unowned memory has explicit SC failure", match unowned.1 with
      | NDkilled (Other (DErr_concurrency _)) => true | _ => false),
    ("unowned failure retains raw journal", match unowned.2.layout_state.observations with
      | some [_] => true | _ => false)]

end SCProtocolControls

def main (args : List String) : IO UInt32 := do
  let [arg] := args | IO.eprintln "requires caller-selected fuel"; return 2
  let some fuel := arg.toNat? | return 2
  letI := LemFuel.mk fuel
  open SCProtocolControls in
  do
    let mut good := true
    good := (← expect fuel "startup and return" (pureExpr (intval 42)) (intval 42)) && good
    good := (← expect fuel "one structured child" (parExpr [pureExpr (intval 7)]) (Vtuple [intval 7])) && good
    good := (← expect fuel "two children preserve result order" (parExpr [pureExpr (intval 7), pureExpr (intval 9)]) (Vtuple [intval 7, intval 9])) && good
    good := (← expect fuel "nested join" (parExpr [parExpr [pureExpr (intval 7)]]) (Vtuple [Vtuple [intval 7]])) && good
    good := (← expect fuel "blocked has no fabricated value" (Expr [] (Ewait 99)) Vunit true) && good
    good := (← expectOrdering fuel "unsequenced stores remain unordered"
      (Expr [] (Eunseq [storeExpr 20 200, storeExpr 30 300])) false) && good
    good := (← expectOrdering fuel "strong sequence orders stores"
      (Expr [] (Esseq (Pattern [] (CaseBase (none, BTy_unit))) (storeExpr 20 200) (storeExpr 30 300))) true) && good
    good := (← expectOrdering fuel "weak sequence orders positive stores"
      (Expr [] (Ewseq (Pattern [] (CaseBase (none, BTy_unit))) (storeExpr 20 200) (storeExpr 30 300))) true) && good
    good := (← expectOrdering fuel "C call is indeterminately sequenced with caller"
      (Expr [] (Eunseq [callExpr true, storeExpr 30 300])) true) && good
    good := (← expectOrdering fuel "Core procedure keeps ordinary source ordering"
      (Expr [] (Eunseq [callExpr false, storeExpr 30 300])) false) && good
    good := (← expectThreadEdges fuel "creation uses additional-sw, not cross-thread sb"
      (Expr [] (Esseq (Pattern [] (CaseBase (none, BTy_unit)))
        (storeExpr 20 200) (parExpr [storeExpr 30 300])))) && good
    good := (← expectThreadEdges fuel "join uses additional-sw, not cross-thread sb"
      (Expr [] (Esseq (Pattern [] (CaseBase (none, BTy_unit)))
        (parExpr [storeExpr 20 200]) (storeExpr 30 300)))) && good
    good := (← expectThreadEdges fuel "nested join retains descendant synchronization"
      (Expr [] (Esseq (Pattern [] (CaseBase (none, BTy_unit)))
        (parExpr [parExpr [storeExpr 20 200]]) (storeExpr 30 300)))) && good
    for (name, passed) in observerControls fuel do
      IO.println (name ++ ": pass=" ++ toString passed)
      good := passed && good
    return if good then 0 else 1
