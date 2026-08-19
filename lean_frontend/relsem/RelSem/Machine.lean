/-
  RelSem.Machine — spike/relsem (2026-08-19). SPIKE-GRADE SKELETON, not merge-bar.

  Layer-2 relational semantics over the generated fuel opsem (Layer 1):
  a small-step relation on ND-machine configurations, where the "machine"
  is the REIFIED nondeterminism tree `ndM` produced by the generated code
  (Nondeterminism.lean:101-119: `ndM a info err cs st =
  ND (st → nd_action a info err cs st × st)`).

  Design intent (see docs/2026-08-19_relsem-spike.md):
  * A configuration is a suspended ND computation (or a finished outcome)
    plus the monad's state. Nondeterminism appears as genuine relational
    branching: `Step` relates a configuration to EVERY successor the tree
    offers (NDnd/NDstep list membership, both NDbranch arms), so no
    oracle/schedule parameter is needed — quantification over Step-paths
    IS quantification over schedules. This mirrors how the OCaml/Lean
    exhaustive runners walk the same tree (CerbND.lean:39).
  * Constraint nodes (NDguard/NDbranch) are parameterized by a constraint
    discipline `CsSem`, so the relation can either mirror the current
    executable no-pruning divergence (CerbND.lean:7-14, survey finding 23)
    or a real constraint evaluator, without changing the step relation.
  * The `MExpr`/`Outcome` split is shaped for iris-lean's language
    interface (Iris/ProgramLogic/Language.lean:34-115: ToVal + PrimStep +
    val_stuck): `toVal (running _) = none`, `toVal (done o) = some o`,
    and `Step` only fires from `running`, giving `val_stuck` for free
    (proved below). NO Iris import here — coupling is paper-only in
    RelSem/IrisCoupling.lean.

  House rules: no sorry, no axioms. Statements that are arc-scale (not
  spike-scale) are given as Prop-valued defs; spike-scale facts are proved.
-/

import Nondeterminism

set_option autoImplicit false

namespace RelSem

/-! ## Outcomes and machine expressions -/

/-- Terminal outcome of an ND computation: the payload of `NDactive` or
    `NDkilled` (Nondeterminism.lean:105-107), without state/trace. This is
    the `Val` type of the intended Iris language instance. -/
inductive Outcome (A E : Type) : Type where
  | value  : A → Outcome A E
  | killed : kill_reason E → Outcome A E
  deriving BEq

/-- Machine expression: a suspended ND computation, or a finished outcome.
    The `done` injection exists so that value-ness of an expression is
    state-INdependent, as iris-lean's `ToVal` requires (an `ndM` alone
    cannot reveal `NDactive` without being applied to a state). -/
inductive MExpr (A I E C S : Type) : Type where
  | running : ndM A I E C S → MExpr A I E C S
  | done    : Outcome A E → MExpr A I E C S

/-- Configuration of the relational machine: expression + monad state. -/
structure Config (A I E C S : Type) : Type where
  expr : MExpr A I E C S
  st   : S

/-! ## ToVal structure (the iris-lean `ToVal` fields, stated locally) -/

section ToVal
variable {A I E C S : Type}

def toVal : MExpr A I E C S → Option (Outcome A E)
  | .running _ => none
  | .done o    => some o

def ofVal (o : Outcome A E) : MExpr A I E C S := .done o

/-- iris-lean `ToVal.toVal_coe` (Language.lean:34-48), locally. -/
theorem toVal_ofVal (o : Outcome A E) :
    toVal (ofVal o : MExpr A I E C S) = some o := rfl

/-- iris-lean `ToVal.coe_of_toVal_eq_some`, locally. -/
theorem ofVal_toVal {e : MExpr A I E C S} {o : Outcome A E} :
    toVal e = some o → (ofVal o : MExpr A I E C S) = e := by
  cases e with
  | running m => intro h; cases h
  | done o' => intro h; cases h; rfl

end ToVal

/-! ## The step relation -/

section Step
variable {A I E C S : Type}

/-- One unfolding of the reified ND tree at a state. This is the ONLY way
    the relational layer consumes the generated code: `Step` premises are
    equations about `app`, so the generated definitions are never
    restructured, only observed. -/
def app (m : ndM A I E C S) (st : S) : nd_action A I E C S × S :=
  match m with | .ND f => f st

/-- Constraint discipline: when may an `NDguard` be crossed, and which arms
    of an `NDbranch` are enabled. `sat c` guards the positive arm, `nsat c`
    the negative arm (OCaml explores the branch under the negated
    constraint, smt2.ml). Kept abstract so the relation covers both the
    executable divergence (no pruning) and a real evaluator (the concrete
    model's cs_module, impl_mem.ml:321-361). -/
structure CsSem (C S : Type) where
  sat  : C → S → Prop
  nsat : C → S → Prop

/-- Exhaustive/no-pruning discipline: exactly what `CerbND.runND`
    implements today (CerbND.lean:58-67 — guards always pass, both branch
    arms explored). -/
def CsSem.exhaustive (C S : Type) : CsSem C S :=
  { sat := fun _ _ => True, nsat := fun _ _ => True }

/-- Small-step relation of the ND machine. Each rule unfolds the tree once
    at the current state and commits to one offered successor; ND is the
    relational branching across rules `nd`/`step`/`branchL`/`branchR`.
    The `I`-labels (`step_kind` at driver instantiation) are carried in
    the premises and can become Iris observations later. -/
inductive Step (γ : CsSem C S) : Config A I E C S → Config A I E C S → Prop where
  | active {m : ndM A I E C S} {st st' : S} {v : A} :
      app m st = (NDactive v, st') →
      Step γ ⟨.running m, st⟩ ⟨.done (.value v), st'⟩
  | killed {m : ndM A I E C S} {st st' : S} {r : kill_reason E} :
      app m st = (NDkilled r, st') →
      Step γ ⟨.running m, st⟩ ⟨.done (.killed r), st'⟩
  | nd {m : ndM A I E C S} {st st' : S} {i j : I}
      {br : List (I × ndM A I E C S)} {m' : ndM A I E C S} :
      app m st = (NDnd i br, st') → (j, m') ∈ br →
      Step γ ⟨.running m, st⟩ ⟨.running m', st'⟩
  | step {m : ndM A I E C S} {st st' : S} {i j : I}
      {br : List (I × ndM A I E C S)} {m' : ndM A I E C S} :
      app m st = (NDstep i br, st') → (j, m') ∈ br →
      Step γ ⟨.running m, st⟩ ⟨.running m', st'⟩
  | guard {m : ndM A I E C S} {st st' : S} {i : I} {c : C}
      {k : ndM A I E C S} :
      app m st = (NDguard i c k, st') → γ.sat c st' →
      Step γ ⟨.running m, st⟩ ⟨.running k, st'⟩
  | branchL {m : ndM A I E C S} {st st' : S} {i : I} {c : C}
      {l r : ndM A I E C S} :
      app m st = (NDbranch i c l r, st') → γ.sat c st' →
      Step γ ⟨.running m, st⟩ ⟨.running l, st'⟩
  | branchR {m : ndM A I E C S} {st st' : S} {i : I} {c : C}
      {l r : ndM A I E C S} :
      app m st = (NDbranch i c l r, st') → γ.nsat c st' →
      Step γ ⟨.running m, st⟩ ⟨.running r, st'⟩

/-- Reflexive-transitive closure of `Step` (self-contained; no external
    closure library needed at spike scale). -/
inductive Steps (γ : CsSem C S) : Config A I E C S → Config A I E C S → Prop where
  | refl {c : Config A I E C S} : Steps γ c c
  | tail {a b c : Config A I E C S} : Steps γ a b → Step γ b c → Steps γ a c

theorem Steps.single {γ : CsSem C S} {a b : Config A I E C S}
    (h : Step γ a b) : Steps γ a b := .tail .refl h

theorem Steps.trans {γ : CsSem C S} {a b c : Config A I E C S}
    (h₁ : Steps γ a b) (h₂ : Steps γ b c) : Steps γ a c := by
  induction h₂ with
  | refl => exact h₁
  | tail _ hs ih => exact .tail ih hs

/-! ## Proved micro-lemmas (spike-scale existence proofs) -/

/-- `nd_return v` (Nondeterminism.lean:163) is one `active` step from any
    state, leaving the state unchanged — the relation really does compute
    on the generated monad's constructors. -/
theorem step_nd_return (γ : CsSem C S) (v : A) (st : S) :
    Step γ (⟨.running (nd_return v), st⟩ : Config A I E C S)
           ⟨.done (.value v), st⟩ :=
  .active rfl

/-- `kill r` (Nondeterminism.lean:210) is one `killed` step. -/
theorem step_kill (γ : CsSem C S) (r : kill_reason E) (st : S) :
    Step γ (⟨.running (kill r), st⟩ : Config A I E C S)
           ⟨.done (.killed r), st⟩ :=
  .killed rfl

/-- iris-lean `Language.val_stuck` (Language.lean:109-115), locally: only
    `running` configurations step, so anything that steps is not a value. -/
theorem val_stuck {γ : CsSem C S} {c c' : Config A I E C S}
    (h : Step γ c c') : toVal c.expr = none := by
  cases h <;> rfl

/-- `done` configurations are terminal (the other half of value-soundness:
    values are irreducible). -/
theorem done_irreducible {γ : CsSem C S} {o : Outcome A E} {st : S}
    {c' : Config A I E C S} :
    ¬ Step γ ⟨.done o, st⟩ c' := by
  intro h; cases h

end Step

end RelSem
