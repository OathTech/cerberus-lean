import Unit.SCProtocolSupport

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
