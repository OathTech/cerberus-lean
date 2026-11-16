import CoreNice.Driver

/- Direct operational tests of the resumable driver. These synthetic CoreNice
   programs test driver phases; they are not claims about AIL lowering. -/
namespace CoreNice.BreakpointDriverTests

private instance : LemFuel := ⟨10000⟩
private instance : CerbGlobal.Switches := ⟨[]⟩

private def check (label : String) (condition : Bool) : IO Unit :=
  unless condition do throw (IO.userError s!"breakpoint driver: {label}")

private def symbol (n : Nat) : sym := .Symbol "breakpoint-driver" n (.SD_Id s!"s{n}")
private def mainSym : sym := symbol 1
private def g1 : sym := symbol 2
private def g2 : sym := symbol 3
private def prefix1 : sym := symbol 4
private def suffix1 : sym := symbol 5
private def prefix2 : sym := symbol 6
private def mainSeen : sym := symbol 7
private def unitExpr : expr core_run_annotation := mk_value_e .Vunit

private def site (n : Nat) : nice_breakpoint_site := {
  breakpoint_procedure := mainSym, breakpoint_id := n,
  breakpoint_role := .BP_internal, breakpoint_origin := .NiceInternal,
  breakpoint_location := .other s!"driver-test:{n}" }

private def cut (n : Nat) (left right : expr core_run_annotation)
    (pat : pattern := mk_empty_pat .BTy_unit) : expr core_run_annotation :=
  mk_breakpoint_sseq_e (site n) pat left right

private def fileFor (body : expr core_run_annotation) : file core_run_annotation := {
  (default : file core_run_annotation) with
  main := some mainSym
  funs := Lem_Map.fromList [(mainSym, .Proc .unknown none .BTy_unit [] body)] }

private def initial (program : file core_run_annotation) : driver_state :=
  (initial_driver_state_given 100 65535 "breakpoint-driver" program CerbFS.fs_initial_state).1

private def threadFor (arena : expr core_run_annotation) : thread_state := {
  arena, stack0 := .Stack_empty, errno := CerbMem.nullPtrval signed_int,
  env := [fmapEmpty], current_proc_opt := some mainSym,
  exec_loc := .ELoc_normal [], current_loc := .unknown }

private def binding (frames : List (Fmap sym value)) (name : sym) : Option value :=
  match frames with
  | [] => none
  | frame :: rest =>
    match fmapLookupBy symbol_compare name frame with
    | some value => some value
    | none => binding rest name

private def onlyThread (state : driver_state) : IO thread_state :=
  match state.core_state0.thread_states with
  | [(_, (_, thread))] => pure thread
  | _ => throw (IO.userError "expected one live startup thread")

/-- A small direct test executor: only explicit finite choices are allowed.
    It refuses guards, failures, missing choices and surplus choices. Production
    replay/session validation is tested by the differential runner suite. -/
private def selected {α : Type} : Nat → List Nat → driverM α → driver_state → IO (α × driver_state)
  | 0, _, _, _ => throw (IO.userError "direct test traversal bound exhausted")
  | fuel + 1, choices, .ND action, state => do
    let (next, state') := action state
    match next with
    | .NDactive value =>
      check "unused direct test choices" choices.isEmpty
      pure (value, state')
    | .NDnd _ alternatives | .NDstep _ alternatives =>
      let (index, remaining) ← if alternatives.length == 1 then pure (0, choices) else
        match choices with
        | [] => throw (IO.userError "direct test needs an explicit choice")
        | index :: rest => pure (index, rest)
      match alternatives[index]? with
      | some (_, continuation) => selected fuel remaining continuation state'
      | none => throw (IO.userError "direct test choice out of range or empty frontier")
    | _ => throw (IO.userError "direct test encountered an unexpected failure or constraint")

private def active {α : Type} (action : driverM α) (state : driver_state) : IO (α × driver_state) :=
  selected 100 [] action state

private def suspended (expected : Nat) (result : nice_run_result) : IO nice_suspension := do
  match result with
  | .NiceSuspended saved =>
    check "wrong static breakpoint" (saved.suspension_site == site expected)
    pure saved
  | _ => throw (IO.userError "expected suspension, not completion or exhaustion")

private def equivalentObservations (label : String) (left right : driver_state) : IO Unit := do
  -- Maps and Dlists contain functional fields: compare their exposed contents,
  -- not generated equality on an entire state. These fixtures have empty stacks.
  let emptyStacks := fun (state : driver_state) => state.core_state0.thread_states.all
    fun (_, _, thread) => match thread.stack0 with | .Stack_empty => true | _ => false
  check s!"{label}: left fixture has empty stacks" (emptyStacks left)
  check s!"{label}: right fixture has empty stacks" (emptyStacks right)
  let control := fun (state : driver_state) => state.core_state0.thread_states.map
    fun (tid, parent, thread) =>
      (tid, parent, thread.current_proc_opt, thread.arena, thread.env.map fmapElements)
  check s!"{label}: thread control and environment" (control left == control right)
  check s!"{label}: output contents"
    (toList left.core_state0.io.stdout == toList right.core_state0.io.stdout &&
      toList left.core_state0.io.stderr == toList right.core_state0.io.stderr)
  check s!"{label}: execution counters and supplies"
    (left.dr_step_counter == right.dr_step_counter &&
      left.core_run_state0.tid_supply == right.core_run_state0.tid_supply &&
      left.core_run_state0.aid_supply == right.core_run_state0.aid_supply &&
      left.core_run_state0.sym_supply == right.core_run_state0.sym_supply)
  check s!"{label}: allocation count and cursor"
    (left.layout_state.nextAllocId == right.layout_state.nextAllocId &&
      left.layout_state.lastAddress == right.layout_state.lastAddress)
  check s!"{label}: driver trace" (left.trace == right.trace)

private def globalTests : IO Unit := do
  let global1 := cut 11 unitExpr
    (mk_sseq_e (mk_sym_pat suffix1 .BTy_boolean) (mk_value_e .Vtrue) (mk_value_e .Vfalse))
    (mk_sym_pat prefix1 .BTy_unit)
  let global2 := cut 12 (mk_value_e .Vfalse) (mk_value_e .Vtrue)
    (mk_sym_pat prefix2 .BTy_boolean)
  let mainBody := cut 13 (.Expr [] (.Epure (.Pexpr [] () (.PEsym g2)))) unitExpr
    (mk_sym_pat mainSeen .BTy_boolean)
  let program := { fileFor mainBody with
    globs := [(g1, .GlobalDef (.BTy_boolean, signed_int) global1),
      (g2, .GlobalDef (.BTy_boolean, signed_int) global2)] }
  let start := initial program
  let (r1, st1) ← active (drive_until_breakpoint fmapEmpty fmapEmpty false program [] 200) start
  let s1 ← suspended 11 r1
  let t1 ← onlyThread st1
  check "global prefix bound, suffix/global/next initializer not executed"
    (binding t1.env prefix1 == some .Vunit && binding t1.env suffix1 == none &&
      binding t1.env g1 == none && binding t1.env g2 == none && binding t1.env prefix2 == none)
  check "global pause precedes startup preparation"
    (t1.current_proc_opt == none && st1.layout_state.nextAllocId == start.layout_state.nextAllocId)
  match s1.suspension_phase with
  | .NiceNonmemory (.NiceAfterGlobal tid name _ rest) acc pending =>
    check "global continuation and exact worklist"
      (tid == s1.suspension_thread && name == g1 && rest.length == 1 &&
        (fmapElements acc).isEmpty && pending == [tid])
  | _ => throw (IO.userError "global suspension lost its enclosing initializer")
  equivalentObservations "first suspension snapshot" st1 s1.suspension_state
  let (r2, st2) ← active (resume_breakpoint fmapEmpty fmapEmpty s1) st1
  let s2 ← suspended 12 r2
  let t2 ← onlyThread st2
  check "finished global bound once before next initializer"
    (binding t2.env g1 == some .Vfalse && binding t2.env suffix1 == some .Vtrue &&
      binding t2.env prefix2 == some .Vfalse && binding t2.env g2 == none)
  let (r3, st3) ← active (resume_breakpoint fmapEmpty fmapEmpty s2) st2
  let s3 ← suspended 13 r3
  let t3 ← onlyThread st3
  check "main sees both completed global initializers"
    (binding t3.env g1 == some .Vfalse && binding t3.env g2 == some .Vtrue &&
      binding t3.env mainSeen == some .Vtrue && t3.current_proc_opt == some mainSym)
  check "startup allocation and thread creation occur once"
    (st3.layout_state.nextAllocId == start.layout_state.nextAllocId + 1 &&
      st3.core_run_state0.tid_supply == start.core_run_state0.tid_supply + 1)
  check "budget decreases across initializer and main cuts"
    (s3.suspension_budget < s2.suspension_budget && s2.suspension_budget < s1.suspension_budget)
  let (finished, finalState) ← active (resume_breakpoint fmapEmpty fmapEmpty s3) st3
  let (automatic, automaticState) ← active (drive fmapEmpty fmapEmpty false program []) start
  match finished with
  | .NiceCompleted result =>
    check "completion value agrees" (result.dres_core_value == .Vunit &&
      result.dres_core_value == automatic.dres_core_value)
  | _ => throw (IO.userError "main suffix did not complete")
  equivalentObservations "global/main automatic comparison" finalState automaticState

private def call (callee : sym) : expr core_run_annotation :=
  .Expr [] (.Eccall default (.Pexpr [] () (.PEval (.Vctype signed_int)))
    (.Pexpr [] () (.PEval (.Vloaded (.LVspecified (.OVpointer (CerbMem.funPtrval callee)))))) [])

private def frontierTests : IO Unit := do
  let f1 := symbol 21
  let f2 := symbol 22
  let f3 := symbol 23
  let program := { fileFor unitExpr with funs := Lem_Map.fromList [
    (f1, .Proc .unknown none .BTy_unit [] (cut 21 unitExpr unitExpr)),
    (f2, .Proc .unknown none .BTy_unit [] (cut 22 unitExpr unitExpr)),
    (f3, .Proc .unknown none .BTy_unit [] unitExpr)] }
  let base := initial program
  let first := threadFor (.Expr [] (.Eunseq [call f1, call f2]))
  let second := threadFor (cut 20 unitExpr (call f3))
  let start := { base with core_state0 := { base.core_state0 with
    thread_states := [(0, (none, first)), (1, (some 0, second))] } }
  let config : nice_resume_config := ⟨false, program, []⟩
  let (result, pausedState) ← active
    (nice_drive_loop fmapEmpty fmapEmpty config 100 (.NiceNonmemory .NiceAfterMain fmapEmpty [0, 1])) start
  let saved ← suspended 20 result
  match saved.suspension_phase with
  | .NiceNonmemory .NiceAfterMain acc pending =>
    check "exact pending thread order" (pending == [1])
    match fmapLookupBy Lem_Basic_classes.ordCompare 0 acc with
    | some [.Step_ccall2 0 _, .Step_ccall2 0 _] => pure ()
    | _ => throw (IO.userError "earlier thread's two deferred calls were not retained")
    check "only earlier frontier is accumulated" ((fmapElements acc).length == 1)
  | _ => throw (IO.userError "pause restarted or discarded the nonmemory phase")
  let .ND originalAction := new_drive_core_threads fmapEmpty fmapEmpty ()
  let (originalNext, originalState) := originalAction start
  let .ND resumedAction := resume_breakpoint fmapEmpty fmapEmpty saved
  let (resumedNext, resumedState) := resumedAction pausedState
  match originalNext, resumedNext with
  | .NDnd originalInfo originalBranches, .NDnd resumedInfo resumedBranches =>
    check "genuine competing choice and exact ordered descriptors"
      (originalBranches.length == 2 && originalInfo == resumedInfo &&
        originalBranches.map Prod.fst == resumedBranches.map Prod.fst)
  | _, _ => throw (IO.userError "expected the actual competing-call choice after resumption")
  equivalentObservations "choice boundary after resume" originalState resumedState
  for choice in [0, 1] do
    let (steps, _) ← selected 100 [choice] (new_drive_core_threads fmapEmpty fmapEmpty ()) start
    let target ← match steps.find? (fun entry => entry.1 == 0) with
      | some (_, some (.Step_ccall2 _ action)) =>
        match action originalState.core_run_state0 with
        | .Result (.Defined next, _) => pure next.current_proc_opt
        | _ => throw (IO.userError "reference deferred call failed")
      | _ => throw (IO.userError "reference driver lost the selected deferred call")
    let (branchResult, _) ← selected 100 [choice, 0]
      (resume_breakpoint fmapEmpty fmapEmpty saved) pausedState
    let expectedSite ← match target with
      | some proc =>
        if proc == f1 then pure 21 else if proc == f2 then pure 22
        else throw (IO.userError "reference selected an unknown procedure")
      | none => throw (IO.userError "reference call has no resolved procedure")
    let _ ← suspended expectedSite branchResult
  IO.println "PASS: retained nonmemory frontier and both genuine competing call choices"

private def immediate : Nat → driverM nice_run_result → driverM nice_run_result
  | 0, _ => .ND fun state => (.NDkilled (.Other (.DErr_other "test auto-resume guard exhausted")), state)
  | fuel + 1, action => nd_bind action fun result =>
    match result with
    | .NiceSuspended saved => immediate fuel (resume_breakpoint fmapEmpty fmapEmpty saved)
    | _ => nd_return result

private def host : Nat → driverM nice_run_result → driver_state → IO (nice_run_result × driver_state × Nat)
  | 0, _, _ => throw (IO.userError "test host-resume guard exhausted")
  | fuel + 1, action, state => do
    let (result, state') ← active action state
    match result with
    | .NiceSuspended saved =>
      let (endResult, endState, visits) ← host fuel (resume_breakpoint fmapEmpty fmapEmpty saved) state'
      pure (endResult, endState, visits + 1)
    | _ => pure (result, state', 0)

private def budgetTests : IO Unit := do
  let loopLabel := symbol 30
  let jump : expr core_run_annotation := .Expr [] (.Erun default loopLabel []
    { nice_jump_origin := 1, nice_jump_location := .other "loop-backedge" })
  let body := .Expr [] (.Esave (loopLabel, .BTy_unit) [] (cut 30 unitExpr jump)
    { nice_label_origins := [1], nice_label_location := .other "loop-label" })
  let program := fileFor body
  let start := initial program
  for budget in [12, 19, 31] do
    let action := drive_until_breakpoint fmapEmpty fmapEmpty false program [] budget
    let (automatic, autoState) ← active (immediate 100 action) start
    let (explicit, explicitState, visits) ← host 100 action start
    match automatic, explicit with
    | .NiceBudgetExhausted, .NiceBudgetExhausted => pure ()
    | _, _ => throw (IO.userError "pauses refilled the cumulative budget or produced a semantic result")
    check "loop reached multiple cuts before exhaustion" (visits >= 2)
    equivalentObservations s!"budget {budget}: immediate/host resumption" autoState explicitState
  IO.println "PASS: cumulative budget survives repeated loop resumption"

def run : IO Unit := do
  globalTests
  IO.println "PASS: initializer/main handoffs, suffixes and one-time startup preparation"
  frontierTests
  budgetTests

end CoreNice.BreakpointDriverTests

def main : IO Unit := CoreNice.BreakpointDriverTests.run
