import Unit.SCWP1Stepping

/-! WP1 candidate experiment, deliberately not a public executor. The ordinary
    driver and earlier experiment are unchanged. Actual Core reductions,
    memory operations, fork/join and lifecycle run underneath this adapter.
    A SeqRMW owns its thread until its store; other threads remain runnable.
    Child completion cannot rewrite an owned parent's saved continuation.
    This is a bounded feasibility instrument, not accepted SC semantics. -/
namespace SCWP1Decision
open SCWP1Stepping CerbMem Lem_Basic_classes

inductive Stage where
  | read
  | update (old : MemValue)
  | write (old new : MemValue)

structure Pending where
  tid : Nat
  loc : CerbLocation.Loc
  ty : ctype
  ptr : PointerValue
  owner : thread_state
  binder : sym
  updateExpr : pexpr
  finish : aid → Footprint → MemValue → MemValue → thread_state
  stage : Stage

structure Config where
  base : experiment_config
  pending : List Pending := []

inductive Choice where
  | core (tid : Nat) (info : Option Nat × thread_state) (selected : context × expr core_run_annotation)
  | resume (p : Pending)
  | lifecycle (index : Nat)

def owned (ps : List Pending) (tid : Nat) : Bool := ps.any (fun p => p.tid == tid)

def choices (c : Config) : List Choice :=
  match c.base.experiment_phase0 with
  | .Exp_core _ =>
    (c.pending.map Choice.resume) ++
      ((experiment_runnable c.base.experiment_state.core_state0).filterMap fun (tid, info, selected) =>
        if owned c.pending tid then none
        -- A child may run, but finishing it substitutes into the parent arena.
        -- Delay only the completion transition while the parent is owned.
        else if info.1.any (owned c.pending) && is_irreducible info.2.arena &&
            (match info.2.stack0 with | .Stack_empty => true | _ => false) then none
        else some (.core tid info selected))
  | _ => (List.range (experiment_choice_count c.base)).map Choice.lifecycle

/-- Mirrored from core_reduction.lem SeqRMWRequest2's updater. The deliberate
    difference is the memory argument: the state at this update transition,
    not the memory captured when the load was prepared. -/
def update [LemFuel] (p : Pending) (old : MemValue) (st : driver_state) : driverM MemValue :=
  match p.owner.env with
  | [] => .ND (fun st => (.NDkilled (.Other (.DErr_core_run (.Illformed_program "WP1 SeqRMW empty environment"))), st))
  | env :: rest =>
    let owner := { p.owner with env := fmapAddBy ordCompare p.binder (valueFromMemValue old).2 env :: rest }
    nd_bind (liftCore_run (full_eval_pexpr fmapEmpty fmapEmpty owner st.core_extern st.layout_state
      st.core_file p.updateExpr)) fun v =>
      match memValueFromValue fmapEmpty fmapEmpty (Ctype [] (unatomic_ p.ty)) v with
      | some v => nd_return v
      | none => .ND (fun st => (.NDkilled (.Other (.DErr_core_run (.Illformed_program "WP1 SeqRMW update type mismatch"))), st))

def replacePending (p : Pending) (ps : List Pending) :=
  ps.map (fun q => if q.tid == p.tid then p else q)

/-- Observe one primitive. Nondeterministic primitive results are explicitly
    refused by this candidate; state at that node is retained. S1 must carry
    the alternatives as per-owner continuations rather than run them eagerly. -/
def observe {α : Type} (c : Config) (m : driverM α) (next : α → Config → Config) : Config :=
  let (result, st) := evalND m c.base.experiment_state
  let c := { c with base := { c.base with experiment_state := st } }
  match result with
  | .NDactive x => next x c
  | .NDkilled why => { c with base := { c.base with experiment_phase0 := .Exp_killed why } }
  | _ => { c with base := { c.base with experiment_phase0 := .Exp_unsupported "WP1 pending primitive alternatives" } }

def resume [LemFuel] (c : Config) (p : Pending) : Config :=
  match p.stage with
  | .read => observe c (liftMem (loadM fmapEmpty fmapEmpty p.loc p.ty p.ptr)) fun (_,old) c =>
    { c with pending := replacePending { p with stage := .update old } c.pending }
  | .update old => observe c (update p old c.base.experiment_state) fun new c =>
    { c with pending := replacePending { p with stage := .write old new } c.pending }
  | .write old new =>
    observe c (perform_action_request2 fmapEmpty fmapEmpty false p.loc p.tid
      (.StoreRequest2 NA p.ty false p.ptr new (fun a fp => p.finish a fp old new))) fun _ c =>
        { c with pending := c.pending.filter (fun q => q.tid != p.tid) }

/-- Candidate repair of the missing modern stack case. The expression and
    legacy continuation substitutions are the actual Core functions. -/
def substContext (tid : Nat) (v : value) : context → context
  | .CTX => .CTX
  | .Cunseq a before ctx after => .Cunseq a (before.map (subst_wait tid v))
      (substContext tid v ctx) (after.map (subst_wait tid v))
  | .Cwseq a pat ctx e => .Cwseq a pat (substContext tid v ctx) (subst_wait tid v e)
  | .Csseq a pat ctx e => .Csseq a pat (substContext tid v ctx) (subst_wait tid v e)
  | .Cannot a xs ctx => .Cannot a xs (substContext tid v ctx)
  | .Cbound a ctx => .Cbound a (substContext tid v ctx)

def substStack (tid : Nat) (v : value) : stack core_run_annotation → stack core_run_annotation
  | .Stack_empty => .Stack_empty
  | .Stack_cons proc cont rest => .Stack_cons proc (subst_wait_continuation tid v cont) (substStack tid v rest)
  | .Stack_cons2 proc ctx rest => .Stack_cons2 proc (substContext tid v ctx) (substStack tid v rest)

def join (tid parent : Nat) (v : value) (st : core_state) : core_state :=
  { st with thread_states := (st.thread_states.filter (fun t => t.1 != tid)).map fun (t,(p,s)) =>
      (t, (p, if t == parent then { s with arena := subst_wait tid v s.arena, stack0 := substStack tid v s.stack0 } else s)) }

/-- Finite scalar publication probe only: SC loads/stores use the same concrete
    memory operations; synchronization is observed by a separate summary
    instrument. This does not supply the race monitor or the SC public mode. -/
def request [LemFuel] (loc : CerbLocation.Loc) (tid : Nat)
    (r : action_request2 thread_state) : driverM experiment_reply :=
  match r with
  | .LoadRequest2 .Seq_cst .. | .StoreRequest2 .Seq_cst .. =>
    nd_bind (perform_action_request2 fmapEmpty fmapEmpty false loc tid r) (fun _ => nd_return Exp_continue)
  | _ => experiment_request fmapEmpty fmapEmpty loc tid r

def core [LemFuel] (c : Config) (tid : Nat) (info : Option Nat × thread_state)
    (selected : context × expr core_run_annotation) : Config :=
  let st := c.base.experiment_state
  let k := match c.base.experiment_phase0 with | .Exp_core k => k | _ => nd_return default
  let s := step_ctx_at fmapEmpty fmapEmpty st.layout_state st.core_file st.core_extern tid info selected
  match selected.2, s with
  | Expr _ (Eaction (Paction Pos (Action _ _ (.SeqRMW _ _ _ binder pe)))),
      .Step_action_request2 _ loc _ _ req =>
    if info.2.env.isEmpty then
      { c with base := { c.base with experiment_phase0 := .Exp_unsupported "WP1 SeqRMW empty environment" } }
    else observe c (liftCore_run req) fun req c =>
      match req with
      | .SeqRMWRequest2 ty ptr _ finish =>
        { c with pending := { tid := tid, loc := loc, ty := ty, ptr := ptr, owner := info.2, binder := binder, updateExpr := pe, finish := finish, stage := .read } :: c.pending }
      | _ => { c with base := { c.base with experiment_phase0 := .Exp_unsupported "WP1 unexpected SeqRMW request" } }
  | _, _ =>
    let m := match s with
      | .Step_spawn_threads2 parent children =>
        -- advance_step accumulates IDs backwards; Epar's result is positional.
        nd_bind (advance_step fmapEmpty fmapEmpty tid
          (.Step_spawn_threads2 (fun tids => parent tids.reverse) children)) (fun _ => nd_return Exp_continue)
      | .Step_thread_done2 parent v =>
        nd_bind (nd_update (fun st => { st with core_state0 := join tid parent v st.core_state0 }))
          (fun _ => nd_return Exp_continue)
      | .Step_action_request2 _ loc tid _ req =>
        -- Selecting an action before a C call is permitted. Once the call is
        -- entered its production stack hides the entire caller continuation.
        nd_bind (liftCore_run req) (request loc tid)
      | _ => experiment_core_step fmapEmpty fmapEmpty tid s
    let (phase, st) := experiment_effect k m st
    { c with base := { c.base with experiment_phase0 := phase, experiment_state := st } }

def step [LemFuel] (i : Nat) (c : Config) : Config :=
  if experiment_terminal c.base then c else
  let next := match (choices c)[i]? with
    | some (.resume p) => resume c p
    | some (.core tid info selected) => core c tid info selected
    | some (.lifecycle i) => { c with base := SCWP1Stepping.step i c.base }
    | none => { c with base := { c.base with experiment_phase0 :=
        if (choices c).isEmpty then .Exp_blocked else .Exp_bad_choice } }
  { next with base := { next.base with experiment_steps := c.base.experiment_steps + 1 } }

def run [LemFuel] : List Nat → Config → Config
  | [], c => c
  | i :: rest, c => if experiment_terminal c.base then c else run rest (step i c)

end SCWP1Decision
