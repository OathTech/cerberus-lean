import Unit.SCWP1Decision

namespace SCWP1DecisionChecks
open SCWP1Stepping SCWP1Decision CerbMem Lem_Basic_classes

def valueE (n : Int) : expr core_run_annotation := mk_value_e (Vloaded (LVspecified (OVinteger (iv n))))
def action (name : String) (p : PointerValue) (n : Int) : expr core_run_annotation :=
  Expr [] (Eaction (Paction Pos (Action (CerbLocation.Loc.other name) default
    (Store0 false (mk_value_pe (Vctype unsigned_char)) (mk_value_pe (Vobject (OVpointer p)))
      (mk_value_pe (Vloaded (LVspecified (OVinteger (iv n))))) NA))))
def seq (a b : expr core_run_annotation) := Expr [] (Esseq (mk_empty_pat BTy_unit) a b)
def rmw (p : PointerValue) (forward : Bool) (up : pexpr) : expr core_run_annotation :=
  Expr [] (Eaction (Paction Pos (Action (CerbLocation.Loc.other "rmw") default
    (SeqRMW forward (mk_value_pe (Vctype unsigned_char))
      (mk_value_pe (Vobject (OVpointer p))) globSym up))))
def rows (c : Config) : List String :=
  (c.base.experiment_state.layout_state.observations.getD []).reverse.map fun r =>
    match r with | .Access_receipt l .. => CerbLocation.stringFromLocation l

def pick [LemFuel] (c : Config) (f : Choice → Bool) : IO Config := do
  let some i := (choices c).findIdx? f | throw (IO.userError "requested choice absent")
  return SCWP1Decision.step i c
def pickTid [LemFuel] (c : Config) (tid : Nat) := pick c (fun ch => match ch with
  | .core n .. => n == tid | .resume p => p.tid == tid | _ => false)

def checkRMW (fuel : Nat) (forward : Bool) : IO Unit :=
  letI := LemFuel.mk fuel
  do
    let (.NDactive p, mem) := evalND (allocateRegion 0 (PrefOther "p") (iv 1) (iv 1)) (initialMemState 65536)
      | throw (IO.userError "allocate p")
    let (.NDactive q, mem) := evalND (allocateRegion 0 (PrefOther "q") (iv 1) (iv 1)) mem
      | throw (IO.userError "allocate q")
    let (.NDactive _, mem) := evalND (storeM fmapEmpty fmapEmpty loc unsigned_char false p
      (.MVinteger (.Unsigned .Ichar) (iv 0))) mem | throw (IO.userError "init p")
    let one := mk_value_pe (Vloaded (LVspecified (OVinteger (iv 1))))
    let arena := Expr [] (Ebound (Expr [] (Eunseq [rmw p forward one, action "sibling" q 7])))
    let st := { initial (fileFor done) with layout_state := { mem with observations := some [] } }
    let st := { st with core_state0 := { st.core_state0 with thread_states :=
      [(0,(none,th arena)),(1,(some 9,th (action "interference" p 9)))] } }
    let c : Config := ⟨coreConfig st, []⟩
    let c ← pick c (fun ch => match ch with
      | .core _ _ (_, Expr _ (Eaction (Paction _ (Action _ _ (.SeqRMW ..))))) => true | _ => false)
    require (c.pending.length == 1 && receiptCount c.base.experiment_state == 0) "prepare had effects"
    require (!(choices c).any (fun ch => match ch with | .core 0 .. => true | _ => false)) "owner still runnable"
    let c ← pickTid c 0 -- load
    require (receiptCount c.base.experiment_state == 1) "missing RMW load boundary"
    let c ← pickTid c 1 -- other C thread's store between read and write
    require (receiptCount c.base.experiment_state == 2) "other thread did not run"
    let c ← pickTid c 0 -- pure update
    let c ← pickTid c 0 -- store and release owner
    require (c.pending.isEmpty && receiptCount c.base.experiment_state == 3) "RMW write boundary"
    let c ← pick c (fun ch => match ch with
      | .core 0 _ (_, Expr _ (Eaction (Paction _ (Action _ _ (.Store0 ..))))) => true | _ => false)
    require (receiptCount c.base.experiment_state == 4) "sibling lost"
    -- Remove the deliberately synthetic second thread; finish the actual first
    -- thread using its original lifecycle-free Core continuation.
    let st := c.base.experiment_state
    let c := { c with base := { c.base with experiment_state := { st with core_state0 :=
      { st.core_state0 with thread_states := st.core_state0.thread_states.filter (fun x => x.1 == 0) } } } }
    let c := SCWP1Decision.run (List.replicate 35 0) c
    require (receiptCount c.base.experiment_state == 4) "sibling was duplicated"
    let some (_,(_,t)) := c.base.experiment_state.core_state0.thread_states.head? | throw (IO.userError "lost main")
    require (match t.arena with
      | Expr _ (Epure (Pexpr _ _ (PEval (Vtuple [Vloaded (LVspecified (OVinteger (.IV _ n))), Vunit])))) =>
        n == (if forward then 1 else 0)
      | _ => false) "RMW forwarding/result"
    IO.println s!"fuel={fuel} forward={forward}: separate read/update/write; other thread intervenes; sibling exactly once; correct return"

def inheritedForkStep [LemFuel] (c : experiment_config) : experiment_config :=
  match c.experiment_phase0, (experiment_runnable c.experiment_state.core_state0).head? with
  | .Exp_core k, some (tid,info,selected) =>
    let st := c.experiment_state
    let s := step_ctx_at fmapEmpty fmapEmpty st.layout_state st.core_file st.core_extern tid info selected
    match s with
    | .Step_spawn_threads2 .. | .Step_thread_done2 .. =>
      let (phase,st) := experiment_effect k (nd_bind (advance_step fmapEmpty fmapEmpty tid s)
        (fun _ => nd_return Exp_continue)) st
      { c with experiment_state := st, experiment_phase0 := phase, experiment_steps := c.experiment_steps+1 }
    | _ => SCWP1Stepping.step 0 c
  | _, _ => SCWP1Stepping.step 0 c

def checkFork (fuel : Nat) : IO Unit :=
  letI := LemFuel.mk fuel
  do
    let arena := Expr [] (Epar [valueE 11,valueE 22])
    let st := initial (fileFor done)
    let st := { st with core_state0 := { st.core_state0 with thread_states := [(0,(none,th arena))] } }
    let st := { st with core_run_state0 := { st.core_run_state0 with tid_supply := 1 } }
    let inherited := (List.range 12).foldl (fun c _ => inheritedForkStep c) (coreConfig st)
    let some (_,(_,old)) := inherited.experiment_state.core_state0.thread_states.head?
      | throw (IO.userError "inherited fork lost parent")
    require (old.arena == mk_value_e (Vtuple [Vloaded (LVspecified (OVinteger (iv 22))),Vloaded (LVspecified (OVinteger (iv 11)))]))
      "inherited reversal control changed"
    IO.println s!"fuel={fuel} actual inherited advance_step fork control: (22,11)"
    let c : Config := ⟨coreConfig st, []⟩
    let c := SCWP1Decision.run (List.replicate 12 0) c
    let some (_,(_,t)) := c.base.experiment_state.core_state0.thread_states.head? | throw (IO.userError "lost parent")
    let Expr _ (Epure (Pexpr _ _ (PEval (Vtuple [Vloaded (LVspecified (OVinteger (.IV _ a))), Vloaded (LVspecified (OVinteger (.IV _ b)))])))) := t.arena
      | throw (IO.userError "fork failed to yield tuple")
    require (a == 11 && b == 22) "candidate changed positional fork results"
    IO.println s!"fuel={fuel} corrected Core fork result: ({a},{b}); children reclaimed"


def trace (c : Config) : String :=
  String.join ((c.base.experiment_state.layout_state.observations.getD []).reverse.filterMap fun r =>
    match r with
    | .Access_receipt l .. =>
      ["a", "b", "c", "rmw", "data", "publish", "acquire", "consume"].find? (fun s => l == CerbLocation.Loc.other s))

def enumerate [LemFuel] : Nat → Config → List String
  | 0,c => ["INCOMPLETE:" ++ trace c]
  | n+1,c =>
    if experiment_terminal c.base then
      [match c.base.experiment_phase0 with
        | .Exp_done _ => trace c
        | .Exp_killed _ => "KILLED:" ++ trace c
        | _ => "OTHER:" ++ trace c]
    else ((List.range (max 1 (choices c).length)).flatMap fun i =>
      enumerate n (SCWP1Decision.step i c)).eraseDups

def checkCalls (fuel : Nat) : IO Unit :=
  letI := LemFuel.mk fuel
  do
    let (.NDactive p, mem) := evalND (allocateRegion 0 (PrefOther "a") (iv 1) (iv 1)) (initialMemState 65536)
      | throw (IO.userError "a")
    let (.NDactive q, mem) := evalND (allocateRegion 0 (PrefOther "b") (iv 1) (iv 1)) mem
      | throw (IO.userError "b")
    let (.NDactive r, mem) := evalND (allocateRegion 0 (PrefOther "c") (iv 1) (iv 1)) mem
      | throw (IO.userError "c")
    let fn := Symbol "wp1-call" 1 (SD_Id "callee")
    let fnPtr := PointerValue.PV .Prov_none (.PVfunction fn)
    let call : expr core_run_annotation := Expr [] (Eccall empty_annotation (mk_value_pe (Vctype signed_int))
      (mk_value_pe (Vloaded (LVspecified (OVpointer fnPtr)))) [])
    let body := seq (action "a" p 1) (action "b" q 1)
    let outside := action "c" r 1
    for par in [false,true] do
      let group := if par then Expr [] (Epar [call,outside]) else Expr [] (Ebound (Expr [] (Eunseq [call,outside])))
      let arena := Expr [] (Esseq (mk_empty_pat (BTy_tuple [BTy_unit,BTy_unit])) group done)
      let f := { fileFor arena with funs := symMap [(mainSym, Proc loc none (BTy_loaded OTy_integer) [] arena), (fn, Proc loc none BTy_unit [] body)] }
      let st := { initial f with layout_state := { mem with observations := some [] } }
      let c : Config := ⟨experiment_start fmapEmpty fmapEmpty f [] st, []⟩
      let rs := enumerate 32 c
      let expected := if par then ["abc","acb","cab"] else ["abc","cab"]
      require (rs.length == expected.length && expected.all rs.contains) s!"call atomicity par={par}: {rs}"
      IO.println s!"fuel={fuel} actual Eccall (separate-threads={par}): {rs}"

    -- RMW/call source indivisibility: the other C call cannot split the pair.
    let arena := Expr [] (Esseq (mk_empty_pat (BTy_tuple [BTy_loaded OTy_integer,BTy_unit]))
      (Expr [] (Ebound (Expr [] (Eunseq [rmw r false (mk_value_pe (Vloaded (LVspecified (OVinteger (iv 1))))),call])))) done)
    let f := { fileFor arena with funs := symMap [(mainSym, Proc loc none (BTy_loaded OTy_integer) [] arena), (fn, Proc loc none BTy_unit [] body)] }
    let (.NDactive _, mem) := evalND (storeM fmapEmpty fmapEmpty loc unsigned_char false r (.MVinteger (.Unsigned .Ichar) (iv 0))) mem
      | throw (IO.userError "init RMW")
    let st := { initial f with layout_state := { mem with observations := some [] } }
    let rs := enumerate 40 ⟨experiment_start fmapEmpty fmapEmpty f [] st, []⟩
    require (rs.length == 2 && ["rmwrmwab", "abrmwrmw"].all rs.contains) s!"SeqRMW/call split: {rs}"
    IO.println s!"fuel={fuel} SeqRMW and C call: {rs}"


def checkCurrentMemory (fuel : Nat) : IO Unit :=
  letI := LemFuel.mk fuel
  do
    let (.NDactive p, mem) := evalND (allocateRegion 0 (PrefOther "p") (iv 1) (iv 1)) (initialMemState 65536)
      | throw (IO.userError "p")
    let (.NDactive q, mem) := evalND (allocateRegion 0 (PrefOther "q") (iv 8) (iv 8)) mem
      | throw (IO.userError "q")
    let (.NDactive _, mem) := evalND (storeM fmapEmpty fmapEmpty loc unsigned_char false p (.MVinteger (.Unsigned .Ichar) (iv 0))) mem
      | throw (IO.userError "init")
    let fn := Symbol "wp1-memory" 77 (SD_Id "metadata")
    let fnTy := Ctype [] (.Function (no_qualifiers, signed_int) [] false)
    let ptrTy := Ctype [] (.Pointer no_qualifiers fnTy)
    let fnPtr := PointerValue.PV .Prov_none (.PVfunction fn)
    let concretePtr := PointerValue.PV .Prov_none (.PVconcrete none 77)
    let metadata := Pexpr [] () (PEcfunction (mk_value_pe (Vloaded (LVspecified (OVpointer concretePtr)))))
    let pat := mk_tuple_pat (List.map mk_empty_pat [BTy_ctype, BTy_list BTy_ctype, BTy_boolean, BTy_boolean])
    let up := Pexpr [] () (PElet pat metadata (mk_value_pe (Vloaded (LVspecified (OVinteger (iv 1))))))
    let owner := Expr [] (Ebound (rmw p true up))
    let other := Expr [] (Eaction (Paction Pos (Action loc default (Store0 false
      (mk_value_pe (Vctype ptrTy)) (mk_value_pe (Vobject (OVpointer q)))
      (mk_value_pe (Vloaded (LVspecified (OVpointer fnPtr)))) NA))))
    let f := { fileFor done with funinfo := symMap [(fn, (loc, default, signed_int, [], false, true))] }
    let st := { initial f with layout_state := { mem with observations := some [] } }
    let st := { st with core_state0 := { st.core_state0 with thread_states := [(0,(none,th owner)),(1,(some 9,th other))] } }
    let c : Config := ⟨coreConfig st, []⟩
    let c ← pickTid c 0
    let c ← pickTid c 0
    let c ← pickTid c 1
    let c ← pickTid c 0
    let c ← pickTid c 0
    require (c.pending.isEmpty && receiptCount c.base.experiment_state == 3 && !experiment_terminal c.base)
      "RMW failed to evaluate against published current memory"
    IO.println s!"fuel={fuel} pending update sees other thread's function-pointer metadata publication"

    let bad := Expr [] (Ebound (rmw p false (mk_value_pe Vunit)))
    let st := { st with core_state0 := { st.core_state0 with thread_states := [(0,(none,th bad))] } }
    let c : Config := ⟨coreConfig st, []⟩
    let c := SCWP1Decision.run [0,0,0] c
    require (match c.base.experiment_phase0 with | .Exp_killed _ => true | _ => false) "bad updater not rejected"
    require (receiptCount c.base.experiment_state == 1) "update failure lost load prefix or performed store"
    IO.println s!"fuel={fuel} update failure retains completed read, without store"

#eval checkCurrentMemory 64
#eval checkCurrentMemory 128
#eval checkRMW 64 false
#eval checkRMW 128 true
#eval checkFork 64
#eval checkFork 128
#eval checkCalls 64
#eval checkCalls 128
end SCWP1DecisionChecks
