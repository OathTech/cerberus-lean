import Unit.SCProtocolSupport
import CerbSCAtomicUpdate
import Core_typing

open SCProtocolControls Lem_Basic_classes Lem_Map

private def updateSym : sym := Symbol "sc-atomic-update-control" 50 SD_None
private def atomicByte : ctype := Ctype [] (Atomic unsigned_char)
private def atomicExpr (forward : Bool) (update : pexpr := pe (intval 9))
    (order : memory_order := Seq_cst) : expr core_run_annotation :=
  Expr [] (Eaction (Paction Pos (Action (CerbLocation.other "SC atomic update") empty_annotation
    (AtomicUpdate forward (pe (Vctype unsigned_char))
      (pe (Vobject (OVpointer (pointer 20 200)))) updateSym update order))))
private def setup (s : driver_state) : driver_state :=
  let s := memorySetup s
  let allocations := s.layout_state.allocations.insert 20
    {base := 200, size := 1, ty := some atomicByte}
  { s with layout_state := { s.layout_state with allocations := allocations } }
private def runBody (fuel : Nat) (body : expr core_run_annotation)
    (prepare : driver_state → driver_state := setup) :=
  letI := LemFuel.mk fuel
  runProgram (program body) prepare
private def byteAt (s : driver_state) : Option UInt8 :=
  (s.layout_state.bytemap.get? 200).bind (·.value)
private def labels (s : driver_state) := (memoryEffects s).map fun e =>
  match e.sc_effect_request.sc_request_kind0, e.sc_effect_observation with
  | SC_atomic_update Seq_cst, Observe_access _ LoadAccess _ _ _ _ _ _ _ => "R"
  | SC_atomic_update Seq_cst, Observe_access _ StoreAccess _ _ _ _ _ _ _ => "W"
  | _, _ => "X"
private def grouped (s : driver_state) :=
  match (memoryEffects s).filter (fun e => match e.sc_effect_request.sc_request_kind0 with
    | SC_atomic_update _ => true | _ => false) with
  | [r,w] => r.sc_effect_request.sc_request_id == w.sc_effect_request.sc_request_id &&
      r.sc_effect_id != w.sc_effect_id && !effectBefore r w && !effectBefore w r
  | _ => false
private def successful := fun (row : nd_status driver_result driver_error driver_state × List String × driver_state) =>
  match row.1 with
  | Active r => !r.dres_blocked && row.2.2.sc_pending.isEmpty
  | _ => false

private def typingControls : List (String × Bool) :=
  let tags : Fmap sym (CerbLocation.Loc × tag_definition) := fmapEmpty
  let action : generic_action Unit Unit sym := Action CerbLocation.unknown ()
    (AtomicUpdate false (pe (Vctype unsigned_char))
      (pe (Vobject (OVpointer (pointer 20 200)))) updateSym
      (Pexpr [] () (PEsym updateSym)) Seq_cst)
  let loaded := BTy_loaded OTy_integer
  let accepted := fun {α β : Type} (result : exceptM α β) =>
    match result with | Result _ => true | Exception _ => false
  let malformed : generic_action Unit Unit sym := Action CerbLocation.unknown ()
    (AtomicUpdate false (pe (Vctype unsigned_char))
      (pe (Vobject (OVpointer (pointer 20 200)))) updateSym (pe Vunit) Seq_cst)
  [ ("Core inference returns the loaded value type", match infer_action tags empty_env action with
      | Result (ty, _) => ty == loaded | _ => false),
    ("Core checking accepts the update binder and loaded result", accepted
      (typecheck_action tags empty_env loaded action)),
    ("Core checking rejects a unit result expectation", !(accepted
      (typecheck_action tags empty_env BTy_unit action))),
    ("Core checking rejects an illtyped update", !(accepted
      (typecheck_action tags empty_env loaded malformed))),
    ("Core checking rejects negative atomic update polarity", !(accepted
      (typecheck_expr Normal_callconv tags empty_env loaded
        (Expr [] (Eaction (Paction Neg0 action)))))) ]

private def floatExchange (fuel : Nat) (oldBits : UInt64) : Bool :=
  letI := LemFuel.mk fuel
  let ty := Ctype [] (Basic (Floating (RealFloating Double)))
  let body := Expr [] (Eaction (Paction Pos (Action (CerbLocation.other "SC floating exchange")
    empty_annotation (AtomicUpdate false (pe (Vctype ty))
      (pe (Vobject (OVpointer (pointer 20 200)))) updateSym
      (pe (Vloaded (LVspecified (OVfloating (CerbFloat.Value.ofBits 0x3ff0000000000000))))) Seq_cst))))
  let prepare := fun (s : driver_state) =>
    let bytes := (List.range 8).foldl (fun acc offset => acc.insert (200 + Int.ofNat offset)
      ({value := some ((oldBits >>> (8 * offset).toUInt64).toUInt8)} : CerbMem.AbsByte)) s.layout_state.bytemap
    let allocations := s.layout_state.allocations.insert 20
      {base := 200, size := 8, ty := some (Ctype [] (Atomic ty))}
    { s with layout_state := { s.layout_state with bytemap := bytes, allocations := allocations } }
  let results := runProgram (program body) prepare
  !results.isEmpty && results.all (fun (outcome, _, s) =>
    grouped s && (List.range 8).map (fun offset => (s.layout_state.bytemap.get? (200 + Int.ofNat offset)).bind (·.value)) ==
      [0,0,0,0,0,0,0xf0,0x3f].map some &&
    match outcome with
    | Active r => match r.dres_core_value with
      | Vloaded (LVspecified (OVfloating old)) => old.toBits == oldBits
      | _ => false
    | _ => false)

def main (args : List String) : IO UInt32 := do
  let [arg] := args | return 2
  let some fuel := arg.toNat? | return 2
  let mut good := true
  let check := fun label pass => do
    IO.println s!"{label}: {pass}"
    return pass
  for (label, pass) in typingControls do
    good := (← check label pass) && good
  for forward in [false, true] do
    let rows := runBody fuel (atomicExpr forward)
    for (status, _, state) in rows.take 2 do
      IO.println s!"atomic result: {outcomeText status}; effects={labels state}; byte={byteAt state}"
    good := (← check s!"atomic update returns forward={forward} with one completed group"
      (!rows.isEmpty && rows.all (fun row => successful row && grouped row.2.2 && byteAt row.2.2 == some 9 &&
        match row.1 with
        | Active r => r.dres_core_value == intval (if forward then 9 else 7)
        | _ => false))) && good
  let rows := runBody fuel (parExpr [atomicExpr false, storeExpr 30 300])
  good := (← check "atomic read and write cannot be separated by another thread"
    (!rows.isEmpty && rows.all (fun row => successful row && grouped row.2.2 &&
        (labels row.2.2 == ["R","W","X"] || labels row.2.2 == ["X","R","W"])) &&
      rows.any (fun (_,_,s) => labels s == ["R","W","X"]) &&
      rows.any (fun (_,_,s) => labels s == ["X","R","W"]))) && good
  let same := atomicExpr false (Pexpr [] () (PEsym updateSym))
  let shadow := Expr [] (Elet (Pattern [] (CaseBase (some updateSym, BTy_loaded OTy_integer)))
    (pe (intval 99)) same)
  let rows := runBody fuel shadow
  good := (← check "update binder shadows outer value and retains an equal-value write"
    (!rows.isEmpty && rows.all (fun row => successful row && grouped row.2.2 && byteAt row.2.2 == some 7 &&
      match row.1 with | Active r => r.dres_core_value == intval 7 | _ => false))) && good
  let unspecifiedSetup := fun s =>
    let s := setup s
    {s with layout_state := {s.layout_state with bytemap := s.layout_state.bytemap.insert 200 {value := none}}}
  let rows := runBody fuel (atomicExpr false) unspecifiedSetup
  good := (← check "exchange of unspecified bytes does not introduce a CAS comparison"
    (!rows.isEmpty && rows.all (fun row => successful row && grouped row.2.2 && byteAt row.2.2 == some 9 &&
      match row.1 with
      | Active r => match r.dres_core_value with | Vloaded (LVunspecified _) => true | _ => false
      | _ => false))) && good
  let malformed := atomicExpr false (pe Vunit)
  let rows := runBody fuel malformed
  good := (← check "illformed update result retains the completed read and original bytes"
    (!rows.isEmpty && rows.all (fun (outcome,_,s) => labels s == ["R"] && byteAt s == some 7 &&
      match outcome with
      | Killed _ (Other (DErr_core_run (Illformed_program message))) =>
          message == "AtomicUpdate result does not match its object type"
      | _ => false))) && good
  let prepareReadonly := fun s =>
    let s := setup s
    let allocations := s.layout_state.allocations.insert 20
      {base := 200, size := 1, ty := some atomicByte, isReadonly := .IsReadOnly ReadonlyConstQualified}
    {s with layout_state := {s.layout_state with allocations := allocations}}
  let rows := runBody fuel (atomicExpr false) prepareReadonly
  good := (← check "atomic store failure retains its read and original bytes"
    (!rows.isEmpty && rows.all (fun (outcome,_,s) => labels s == ["R"] && byteAt s == some 7 &&
      match outcome with | Killed _ (Undef0 _ [UB064_modifying_const]) => true | _ => false))) && good
  let orders := [NA, Relaxed, Consume, Acquire, Release, Acq_rel]
  good := (← check "every excluded atomic update order refuses before the object read"
    (orders.all fun order =>
      let rows := runBody fuel (atomicExpr false (pe (intval 9)) order)
      !rows.isEmpty && rows.all (fun (outcome,_,s) => (memoryEffects s).isEmpty && byteAt s == some 7 &&
        match outcome with
        | Killed _ (Other (DErr_concurrency reason)) => reason == SC_fault_order (SC_atomic_update order)
        | _ => false))) && good
  for strong in [false, true] do
    let body := Expr [] ((if strong then Esseq else Ewseq)
      (Pattern [] (CaseBase (none, BTy_loaded OTy_integer))) (atomicExpr false) (storeExpr 30 300))
    let rows := runBody fuel body
    good := (← check s!"atomic completion transmits both effects across strong={strong} continuation"
      (!rows.isEmpty && rows.all (fun row => successful row && match memoryEffects row.2.2 with
        | [r,w,next] => effectBefore r next && effectBefore w next
        | _ => false))) && good
  good := (← check "unconditional floating exchange retains identical NaN bits"
    (floatExchange fuel 0x7ff8000000000001)) && good
  good := (← check "unconditional floating exchange retains negative zero bits"
    (floatExchange fuel 0x8000000000000000)) && good
  return if good then 0 else 1
