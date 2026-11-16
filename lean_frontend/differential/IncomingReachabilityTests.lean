import IncomingReachability

namespace CoreNice.Incoming.ReachabilityTests

private def symbol (number : Nat) : sym := .Symbol "reachability-tests" number .SD_None
private def firstLabel := symbol 10
private def finalLabel := symbol 20
private def done : expr Unit := .Expr [] (.Epure (.Pexpr [] () (.PEval .Vunit)))
private def literal (value : Bool) : pexpr :=
  .Pexpr [] () (.PEval (if value then .Vtrue else .Vfalse))
private def jump (label : sym) : expr Unit :=
  .Expr [] (.Erun () label [] empty_nice_jump_info)
private def save (label : sym) (body : expr Unit) : expr Unit :=
  .Expr [] (.Esave (label, .BTy_unit) [] body empty_nice_label_info)
private def sequence (first second : expr Unit) : expr Unit :=
  .Expr [] (.Esseq default first second)
private def weakSequence (first second : expr Unit) : expr Unit :=
  .Expr [] (.Ewseq default first second)
private def conditional (test : pexpr) (yes no : expr Unit) : expr Unit :=
  .Expr [] (.Eif test yes no)
private def program (body : expr Unit) : file Unit :=
  { (default : file Unit) with
    funs := fmapAddBy symbol_compare (symbol 1) (.Proc .unknown none .BTy_unit [] body) .empty }

private def ensure (condition : Bool) (message : String) : IO Unit :=
  unless condition do throw (IO.userError message)
private def success {α : Type} (result : Except String α) : IO α :=
  match result with
  | .ok value => pure value
  | .error reason => throw (IO.userError reason)

private def check (name : String) (body : expr Unit) (before after visited : Nat) : IO Unit := do
  let baseline ← success (finalize (program body))
  let tightened ← success (tighten baseline)
  ensure (baseline.stats.allowedOrigins == before) s!"{name}: wrong conservative count"
  ensure (tightened.result.stats.allowedOrigins == after) s!"{name}: wrong retained count"
  ensure (tightened.tightening.removedOrigins == before - after) s!"{name}: wrong removal count"
  ensure (tightened.tightening.visitedLabels == visited) s!"{name}: wrong closure label count"
  let erase : file Unit → file Unit := mapMetadataFile (fun _ _ _ => empty_nice_jump_info)
    (fun _ _ _ => empty_nice_label_info)
  ensure (erase tightened.result.file == program body) s!"{name}: ordinary AST changed"
  ensure (tightened.result.procedures.map (fun p => p.jumps.map (·.info.nice_jump_origin)) ==
    baseline.procedures.map (fun p => p.jumps.map (·.info.nice_jump_origin)))
    s!"{name}: tightening changed jump identities"

def run : IO Unit := do
  for seq in [sequence, weakSequence] do
    -- The second jump cannot run: the first jumps directly to the label body.
    check "dead jump after goto"
      (seq (jump firstLabel) (seq (jump firstLabel) (save firstLabel done))) 2 1 1
    -- The label is in the unchosen arm, but the chosen arm jumps into it.
    check "jump into statically unchosen branch"
      (seq (conditional (literal true) (jump firstLabel)
        (save firstLabel (jump finalLabel))) (save finalLabel done)) 2 2 2
    -- collect_saves reattaches the outer suffix to the label's continuation.
    check "saved continuation restores sequence suffix"
      (seq (seq (seq (jump firstLabel) (save firstLabel done))
        (jump finalLabel)) (save finalLabel done)) 2 2 2
  check "literal false removes unreachable origin"
    (save firstLabel (conditional (literal false) (jump firstLabel) done)) 1 0 0
  check "literal true removes unreachable origin"
    (save firstLabel (conditional (literal true) done (jump firstLabel))) 1 0 0
  check "unknown condition retains both origins"
    (save firstLabel (conditional (.Pexpr [] () (.PEsym (symbol 99)))
      (jump firstLabel) (jump firstLabel))) 2 2 1
  check "normal label entry remains root"
    (save firstLabel (save finalLabel (jump finalLabel))) 1 1 1
  check "self-loop closure terminates" (save firstLabel (jump firstLabel)) 1 1 1
  check "mutual loop closure terminates"
    (sequence (save firstLabel (jump finalLabel))
      (save finalLabel (jump firstLabel))) 2 2 2
  -- Either child can run first, so neither origin is removed just because the
  -- other child jumps. A left-to-right analysis would lose the second origin.
  check "unsequenced alternatives retain both jumps"
    (sequence (.Expr [] (.Eunseq [jump firstLabel, jump finalLabel]))
      (.Expr [] (.Eunseq [save firstLabel done, save finalLabel done]))) 2 2 2
  check "nondeterministic alternatives retain both jumps"
    (sequence (.Expr [] (.End [jump firstLabel, jump finalLabel]))
      (.Expr [] (.Eunseq [save firstLabel done, save finalLabel done]))) 2 2 2
  check "jump under bound contributes to closure"
    (sequence (.Expr [] (.Ebound (jump firstLabel))) (save firstLabel done)) 1 1 1
  IO.println "PASS: comesfrom structural reachability and saved-continuation closure tests"

end CoreNice.Incoming.ReachabilityTests

#eval CoreNice.Incoming.ReachabilityTests.run
