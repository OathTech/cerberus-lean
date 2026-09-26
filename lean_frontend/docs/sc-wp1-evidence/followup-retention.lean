import Unit.SCWP1Stepping

namespace SCWP1ScaleCore
open SCWP1Stepping CerbMem

def mkStore (p : PointerValue) (negative : Bool) : expr core_run_annotation :=
  Expr [] (Eaction (Paction (if negative then polarity.Neg0 else Pos) (Action loc default
    (Store0 false (mk_value_pe (Vctype unsigned_char))
      (mk_value_pe (Vobject (OVpointer p)))
      (mk_value_pe (Vloaded (LVspecified (OVinteger (iv 1))))) NA))))

def checkAt (budget : Nat) (negative : Bool) : IO Unit :=
  letI := LemFuel.mk 64
  do
    let (.NDactive p, mem) := evalND (allocateRegion 0 (PrefOther "p") (iv 1) (iv 1))
      (initialMemState 65536) | throw (IO.userError "p")
    let (.NDactive q, mem) := evalND (allocateRegion 0 (PrefOther "q") (iv 1) (iv 1)) mem
      | throw (IO.userError "q")
    let voidPat := mk_empty_pat BTy_unit
    let body := Expr [] (Esseq (mk_tuple_pat [voidPat, voidPat])
      (Expr [] (Ebound (Expr [] (Eunseq [mkStore p negative, mkStore q false]))))
      (Expr [] (Erun empty_annotation loopSym [])))
    let arena := Expr [] (Esave (loopSym, BTy_loaded OTy_integer) [] body)
    let f := fileFor arena
    let st := { initial f with layout_state := mem }
    let now ← IO.monoMsNow
    let .Exp_incomplete cfg := bounded (List.replicate budget 0)
      (experiment_start fmapEmpty fmapEmpty f [] st)
      | throw (IO.userError "fixed-width loop terminated")
    let elapsed := (← IO.monoMsNow) - now
    let st := cfg.experiment_state
    let some (_,(_,th)) := st.core_state0.thread_states.head?
      | throw (IO.userError "no thread")
    let envBindings := (th.env.map (fun m => (fmapElements m).length)).foldl Nat.add 0
    require (st.layout_state.allocations.size == 3 && st.core_state0.thread_states.length == 1 &&
      st.layout_state.observations.isNone) "fixture live-state dimensions moved"
    IO.println s!"negative={negative} budget={budget} ms={elapsed} live-allocations=3 live-threads=1 inherited-trace={st.trace.length} env-bindings={envBindings} next-symbol={st.core_run_state0.sym_supply}"

#eval checkAt 128 false
#eval checkAt 1024 false
#eval checkAt 8192 false
#eval checkAt 128 true
#eval checkAt 1024 true
#eval checkAt 8192 true
end SCWP1ScaleCore
