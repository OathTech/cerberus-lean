import Unit.SCWP1Decision
import Unit.SCWP1SummaryRuntime

namespace SCWP1RetentionChecks
open SCWP1Stepping SCWP1Decision SCWP1Summary CerbMem

def action (name : String) (p : PointerValue) : expr core_run_annotation :=
  Expr [] (Eaction (Paction Pos (Action (CerbLocation.Loc.other name) default
    (Store0 false (mk_value_pe (Vctype unsigned_char)) (mk_value_pe (Vobject (OVpointer p)))
      (mk_value_pe (Vloaded (LVspecified (OVinteger (iv 1))))) NA))))

def check (fuel rounds : Nat) (fork : Bool) : IO Unit :=
  letI := LemFuel.mk fuel
  do
    let (.NDactive p, mem) := evalND (allocateRegion 0 (PrefOther "a") (iv 1) (iv 1)) (initialMemState 65536)
      | throw (IO.userError "a")
    let (.NDactive q, mem) := evalND (allocateRegion 0 (PrefOther "b") (iv 1) (iv 1)) mem
      | throw (IO.userError "b")
    let group := Expr [] (Ebound (Expr [] (if fork then Epar [action "a" p,action "b" q]
      else Eunseq [action "a" p,action "b" q])))
    let body := Expr [] (Esseq (mk_tuple_pat [mk_empty_pat BTy_unit,mk_empty_pat BTy_unit]) group
      (Expr [] (Erun empty_annotation loopSym [])))
    let loopBody := Expr [] (Esave (loopSym, BTy_loaded OTy_integer) [] body)
    -- Eproc forces a real Stack_cons2 on the waiting parent. The candidate's
    -- stack repair is exercised by each child completion, not just at top level.
    let arena := Expr [] (Eproc empty_annotation (Sym spinSym) [])
    let f := { fileFor arena with funs := symMap [(mainSym, Proc loc none (BTy_loaded OTy_integer) [] arena),
      (spinSym, Proc loc none (BTy_loaded OTy_integer) [] loopBody)] }
    let st := { initial f with layout_state := { mem with observations := some [] } }
    let mut c : Config := ⟨experiment_start fmapEmpty fmapEmpty f [] st, []⟩
    let mut clock ← emit empty "parent" []
    clock ← copy clock "a" "parent"
    clock ← copy clock "b" "parent"
    let mut complete := 0
    let mut accesses := 0
    let mut peakRoots := 0
    let mut peakThreads := 0
    let started ← IO.monoMsNow
    -- This bound is an instrument failure threshold; every loop iteration
    -- is paid for by the actual candidate step API, independently of call fuel.
    for _ in [:rounds * 28 + 10] do
      if complete == rounds then break
      require (!experiment_terminal c.base) "Core churn terminated"
      let selected := (choices c).head?
      let isBackedge := match selected with
        | some (.core _ _ (_, Expr _ (.Erun ..))) => true | _ => false
      c := SCWP1Decision.step 0 c
      peakThreads := max peakThreads c.base.experiment_state.core_state0.thread_states.length
      let st := c.base.experiment_state
      let rs := (st.layout_state.observations.getD []).reverse
      for receipt in rs do
        let .Access_receipt l _ _ _ _ _ _ _ _ := receipt
        if l == CerbLocation.Loc.other "a" || l == CerbLocation.Loc.other "b" then
          let name := if l == CerbLocation.Loc.other "a" then "a" else "b"
          clock ← emit clock name [name]
          clock ← copy clock ("last-" ++ name) name
          if accesses == 0 then clock ← copy clock "old-publication" name
          accesses := accesses + 1
          if accesses % 2 == 0 then
            require (!(← precedes clock "a" "b") && !(← precedes clock "b" "a"))
              "scheduler order became source/hb order"
          if accesses > 2 then
            require (!(← precedes clock name "old-publication")) "retirement advanced an old published snapshot"
      if isBackedge then
        require (accesses == 2 * (complete+1)) "not exactly two actual accesses per split/join"
        clock ← emit clock "parent" ["a","b"]
        clock := discard clock ["a","b"]
        clock ← copy clock "a" "parent"
        clock ← copy clock "b" "parent"
        complete := complete + 1
      let (n,bits,refs) := counts clock
      require (n ≤ 6 && bits == n*n && refs == n) "retained summary exceeds live-root bound"
      peakRoots := max peakRoots n
      -- Explicit diagnostic streaming policy. Removing ordinary driver trace
      -- output is not a claimed production optimization. No semantic field is
      -- pruned: the inherited environment/allocations/stack remain measured.
      c := { c with base := { c.base with experiment_state :=
        { st with trace := [], layout_state := { st.layout_state with observations := some [] } } } }
    require (complete == rounds && accesses == 2*rounds) "churn bound exhausted"
    let envs := c.base.experiment_state.core_state0.thread_states.foldl (fun n t =>
      n + (t.2.2.env.map (fun env => (fmapElements env).length)).foldl Nat.add 0) 0
    require (envs == 0 && c.base.experiment_state.layout_state.allocations.size == 3 && c.pending.isEmpty)
      "semantic live state grew"
    require (c.base.experiment_state.core_state0.thread_states.length == 1) "retired children retained"
    let nextTid := c.base.experiment_state.core_run_state0.tid_supply
    IO.println s!"fuel={fuel} fork={fork} rounds={rounds} effects={accesses} steps={c.base.experiment_steps} peak-threads={peakThreads} next-tid={nextTid} retained-roots={clock.n} peak-roots={peakRoots} matrix-bools={clock.n*clock.n} root-refs={clock.n} env-bindings={envs} allocations=3 elapsed-ms={(← IO.monoMsNow)-started}"

#eval check 64 16 false
#eval check 64 1024 false
#eval check 64 8192 false
#eval check 64 16 true
#eval check 64 1024 true
#eval check 64 8192 true
#eval check 128 16 true
end SCWP1RetentionChecks
