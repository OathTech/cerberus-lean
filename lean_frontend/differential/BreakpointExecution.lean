import ObservationNice

/-! Host pause selection over the model's explicit phases. The fixed callback
    constructs an action from phase data; no whole-driver continuation is hidden
    in the suspension. Neither selection nor observation changes C state. -/
namespace CoreNiceDiff.Breakpoints
open Lean

inductive Policy where
  | all | none | every (interval : Nat) | site (identity : Nat) | visits (selected : List Nat)

def Policy.parse (text : String) : Except String Policy :=
  match text.splitOn ":" with
  | ["all"] => .ok .all
  | ["none"] => .ok .none
  | ["every", number] => do
    let some n := number.toNat? | throw "invalid pause interval"
    if n == 0 then throw "pause interval must be positive"
    return .every n
  | ["site", number] => do
    let some n := number.toNat? | throw "invalid pause site"
    return .site n
  | ["visits", values] => do
    let selected ← if values.isEmpty then pure [] else (values.splitOn ",").mapM fun text => do
      let some n := text.toNat? | throw "invalid pause visit"
      if n == 0 then throw "pause visits are numbered from one"
      return n
    return .visits selected
  | _ => .error "pause policy must be all, none, every:N, site:N or visits:N,M,..."

def Policy.select : Policy → CoreNice.nice_breakpoint_site → Nat → Bool
  | .all, _, _ => true
  | .none, _, _ => false
  | .every n, _, visit => visit % n == 0
  | .site n, pointSite, _ => pointSite.breakpoint_id == n
  | .visits selected, _, visit => selected.contains visit

structure Point where
  machine : CoreNice.nice_suspension
  encounter : Nat
  remainingHostBudget : Nat

inductive Result where
  | completed (value : CoreNice.driver_result)
  | suspended (point : Point)
  | incomplete (reason : String)

def advance [LemFuel] [CerbGlobal.Switches] (policy : Policy) (budget : Nat)
    (seen : Nat) (action : CoreNice.driverM CoreNice.nice_run_result) :
    CoreNice.driverM Result :=
  match budget with
  | 0 => nd_return (.incomplete "breakpoint host budget exhausted")
  | budget + 1 => nd_bind action fun result =>
    match result with
    | .NiceCompleted value => nd_return (.completed value)
    | .NiceBudgetExhausted => nd_return (.incomplete "breakpoint driver budget exhausted")
    | .NiceSuspended machine =>
      let point : Point := { machine, encounter := seen + 1, remainingHostBudget := budget }
      if policy.select machine.suspension_site point.encounter then
        nd_return (.suspended point)
      else advance policy budget point.encounter (CoreNice.resume_breakpoint machine.suspension_config.resume_file.enumDefs
        machine.suspension_config.resume_file.tagDefs machine)

def roleName : CoreNice.nice_breakpoint_role → String
  | .BP_statement_join => "statement-join"
  | .BP_condition_ready => "condition-ready"
  | .BP_loop_body_done => "loop-body-done"
  | .BP_internal => "internal"

def describe (point : Point) : Json :=
  let machine := point.machine
  let site := machine.suspension_site
  Json.mkObj [
    ("schema", toJson "corenice-breakpoint-v1"),
    ("procedure", toJson site.breakpoint_procedure),
    ("site", toJson site.breakpoint_id), ("role", toJson (roleName site.breakpoint_role)),
    ("ailOrigin", toJson site.breakpoint_ail_path), ("location", toJson site.breakpoint_location),
    ("thread", toJson machine.suspension_thread), ("encounter", toJson point.encounter),
    ("phase", toJson (match machine.suspension_phase with
      | .NiceNonmemory .. => "nonmemory"
      | .NiceRound .. => "round"
      | .NiceNextGlobal .. => "globals")),
    ("remainingBudget", toJson machine.suspension_budget),
    ("driverSteps", toJson machine.suspension_state.dr_step_counter)]

def adapter [LemFuel] [CerbGlobal.Switches] (policy : Policy) :
    Choice.Adapter Result CoreNice.driver_result Point CoreNice.step_kind
      CoreNice.driver_error mem_iv_constraint CoreNice.driver_state := {
  classify := fun result => match result with
    | .completed value => .done value
    | .suspended point => .pause point
    | .incomplete reason => .incomplete reason
  describe
  continueFrom := fun point => advance policy point.remainingHostBudget point.encounter
    (CoreNice.resume_breakpoint point.machine.suspension_config.resume_file.enumDefs
      point.machine.suspension_config.resume_file.tagDefs point.machine) }

end CoreNiceDiff.Breakpoints
