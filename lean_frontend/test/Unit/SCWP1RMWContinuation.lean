import Unit.SCWP1Stepping

/-! Counterexamples to suspending the existing production SeqRMW callbacks.
    These manually compose actual callbacks with intervening Core/memory work;
    they are not an implementation of concurrent SeqRMW. The ordinary
    unsuspended handler has a positive control and is not indicted here.
    The memory-map example is synthetic Core, not a demonstrated C lowering. -/

namespace SCWP1RMWContinuation
open SCWP1Stepping CerbMem

def countStores (st : driver_state) : Nat :=
  (experiment_contexts st.core_state0).filter (fun (_, _, (_, e)) =>
    match e with | Expr _ (Eaction (Paction _ (Action _ _ (.Store0 ..)))) => true | _ => false) |>.length

def rmwCounterexample (fuel : Nat) : IO Unit :=
  letI := LemFuel.mk fuel
  do
    let (.NDactive p, mem) := evalND (allocateRegion 0 (PrefOther "rmw") (iv 1) (iv 1))
        (initialMemState 65536) | throw (IO.userError "allocate p")
    let (.NDactive q, mem) := evalND (allocateRegion 0 (PrefOther "sibling") (iv 1) (iv 1)) mem
      | throw (IO.userError "allocate q")
    let zero := MemValue.MVinteger (.Unsigned .Ichar) (iv 0)
    let one := MemValue.MVinteger (.Unsigned .Ichar) (iv 1)
    let (.NDactive _, mem) := evalND (storeM fmapEmpty fmapEmpty loc unsigned_char false p zero) mem
      | throw (IO.userError "initialize p")
    let act := SeqRMW false (mk_value_pe (Vctype unsigned_char))
      (mk_value_pe (Vobject (OVpointer p))) globSym (mk_value_pe (Vobject (OVinteger (iv 1))))
    let arena := Expr [] (Ebound (Expr [] (Eunseq [
      Expr [] (Eaction (Paction Pos (Action loc default act))), storeArena q])))
    let st := initial (fileFor done)
    let st := { st with layout_state := { mem with observations := some [] } }
    let st := { st with core_state0 := { st.core_state0 with thread_states := [(0, (none, th arena))] } }
    let some (_, _, ctx) := (experiment_contexts st.core_state0).find? (fun (_, _, (_, e)) =>
      match e with | Expr _ (Eaction (Paction _ (Action _ _ (.SeqRMW ..)))) => true | _ => false)
      | throw (IO.userError "no RMW context")
    let .Step_action_request2 _ _ _ _ request := step_ctx_at fmapEmpty fmapEmpty
        st.layout_state st.core_file st.core_extern 0 (none, th arena) ctx
      | throw (IO.userError "not an RMW request")
    let (.NDactive req, st) := evalND (liftCore_run request) st
      | throw (IO.userError "no request")
    let .SeqRMWRequest2 _ _ update finish := req | throw (IO.userError "no callback")
    -- Positive control: the existing unsuspended handler runs the sibling once.
    let (.NDactive _, sequential) := evalND (perform_action_request2 fmapEmpty fmapEmpty false loc 0 req) st
      | throw (IO.userError "sequential request failed")
    require (receiptCount sequential == 2 && countStores sequential == 1) "sequential RMW control"
    let some seqIdx := (experiment_runnable sequential.core_state0).findIdx? (fun (_, _, (_, e)) =>
      match e with | Expr _ (Eaction (Paction _ (Action _ _ (.Store0 ..)))) => true | _ => false)
      | throw (IO.userError "sequential sibling missing")
    let sequential := (step seqIdx (coreConfig sequential)).experiment_state
    require (receiptCount sequential == 3 && countStores sequential == 0) "sequential sibling did not run once"
    let (.NDactive (_, old), mem) := evalND (loadM fmapEmpty fmapEmpty loc unsigned_char p) st.layout_state
      | throw (IO.userError "load")
    let st := { st with layout_state := mem }
    let contexts := experiment_runnable st.core_state0
    let some i := contexts.findIdx? (fun (_, _, (_, e)) =>
      match e with | Expr _ (Eaction (Paction _ (Action _ _ (.Store0 ..)))) => true | _ => false)
      | throw (IO.userError "no sibling")
    let progressed := (step i (coreConfig st)).experiment_state
    require (countStores progressed == 0 && receiptCount progressed == 2) "sibling did not finish"
    let (.NDactive actualNew, progressed) := evalND (liftCore_run (update old)) progressed
      | throw (IO.userError "update")
    require (actualNew == one) "unexpected updater result"
    let (.NDactive fp, mem) := evalND (storeM fmapEmpty fmapEmpty loc unsigned_char false p actualNew)
        progressed.layout_state | throw (IO.userError "RMW write")
    let progressed := { progressed with layout_state := mem }
    let resumed := { progressed with core_state0 := update_thread_state 0 (finish default fp old actualNew) progressed.core_state0 }
    require (countStores resumed == 1 && receiptCount resumed == 3) "expected stale context resurrection absent"
    let some j := (experiment_runnable resumed.core_state0).findIdx? (fun (_, _, (_, e)) =>
      match e with | Expr _ (Eaction (Paction _ (Action _ _ (.Store0 ..)))) => true | _ => false)
      | throw (IO.userError "reintroduced store missing")
    let duplicated := (step j (coreConfig resumed)).experiment_state
    require (receiptCount duplicated == 4) "reintroduced sibling did not execute again"
    IO.println "production SeqRMW callback: sibling store completed; saved callback resurrected it; executing it produced a second receipt"

#eval rmwCounterexample 64
#eval rmwCounterexample 128

end SCWP1RMWContinuation


namespace SCWP1RMWMemory
open SCWP1Stepping CerbMem

def check (fuel : Nat) : IO Unit :=
  letI := LemFuel.mk fuel
  do
    let (.NDactive p, mem) := evalND (allocateRegion 0 (PrefOther "rmw") (iv 1) (iv 1))
        (initialMemState 65536) | throw (IO.userError "allocate p")
    let (.NDactive q, mem) := evalND (allocateRegion 0 (PrefOther "function pointer") (iv 8) (iv 8)) mem
      | throw (IO.userError "allocate q")
    let fn := Symbol "wp1-memory" 77 (SD_Id "metadata")
    let fnTy := Ctype [] (.Function (no_qualifiers, signed_int) [] false)
    let ptrTy := Ctype [] (.Pointer no_qualifiers fnTy)
    let fnPtr := PointerValue.PV .Prov_none (.PVfunction fn)
    let concretePtr := PointerValue.PV .Prov_none (.PVconcrete none 77)
    let f := { fileFor done with funinfo := symMap [(fn, (loc, default, signed_int, [], false, true))] }
    let metadata := Pexpr [] () (PEcfunction (mk_value_pe (Vloaded (LVspecified (OVpointer concretePtr)))))
    let pat := mk_tuple_pat (List.map mk_empty_pat [BTy_ctype, BTy_list BTy_ctype, BTy_boolean, BTy_boolean])
    let updateExpr := Pexpr [] () (PElet pat metadata (mk_value_pe (Vloaded (LVspecified (OVinteger (iv 1))))))
    let arena := Expr [] (Ebound (Expr [] (Eaction (Paction Pos (Action loc default
      (SeqRMW false (mk_value_pe (Vctype unsigned_char))
        (mk_value_pe (Vobject (OVpointer p))) globSym updateExpr))))))
    let st := { initial f with layout_state := mem }
    let st := { st with core_state0 := { st.core_state0 with thread_states := [(0, (none, th arena))] } }
    let some (_, _, ctx) := (experiment_contexts st.core_state0).head? | throw (IO.userError "context")
    let .Step_action_request2 _ _ _ _ request := step_ctx_at fmapEmpty fmapEmpty mem f st.core_extern 0 (none, th arena) ctx
      | throw (IO.userError "request")
    let (.NDactive req, st) := evalND (liftCore_run request) st | throw (IO.userError "request effect")
    let .SeqRMWRequest2 _ _ savedUpdate _ := req | throw (IO.userError "RMW callback")
    let (.NDactive _, currentMem) := evalND (storeM fmapEmpty fmapEmpty loc ptrTy false q (.MVpointer fnTy fnPtr)) mem
      | throw (IO.userError "publish function pointer")
    require (caseFunsymOpt mem concretePtr == none && caseFunsymOpt currentMem concretePtr == some fn)
      "function-pointer map did not change through the store"
    let current := { st with layout_state := currentMem }
    let (staleResult, _) := evalND (liftCore_run (savedUpdate (.MVinteger (.Unsigned .Ichar) (iv 0)))) current
    require (match staleResult with | .NDkilled (.Other (.DErr_core_run (.Illformed_program msg))) => msg.endsWith ": does not point to a function" | _ => false)
      "saved update unexpectedly saw current memory"
    let .Step_action_request2 _ _ _ _ freshRequest := step_ctx_at fmapEmpty fmapEmpty
        currentMem f st.core_extern 0 (none, th arena) ctx
      | throw (IO.userError "fresh request")
    let (.NDactive freshReq, current) := evalND (liftCore_run freshRequest) current
      | throw (IO.userError "fresh request effect")
    let .SeqRMWRequest2 _ _ freshUpdate _ := freshReq | throw (IO.userError "fresh RMW callback")
    let (freshResult, _) := evalND (liftCore_run (freshUpdate (.MVinteger (.Unsigned .Ichar) (iv 0)))) current
    require (match freshResult with | .NDactive (.MVinteger _ (.IV _ 1)) => true | _ => false)
      "fresh evaluation did not resolve current function-pointer map"
    IO.println "production SeqRMW update: saved memory rejects a function pointer published by a real store; current-memory evaluation returns 1"

#eval check 64
#eval check 128
end SCWP1RMWMemory
