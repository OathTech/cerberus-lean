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

/-- Discipline induced by a boolean constraint evaluator (the shape of the
    OCaml concrete model's `eval_cs`, impl_mem.ml:321-361): the positive
    arm is enabled exactly when the evaluator says `true`, the negative
    arm exactly when it says `false`. Under this discipline the two arms
    of an `NDbranch` are mutually exclusive (see `step_ifM_inv` below +
    `Bool` disjointness) — the relational content of constraint PRUNING,
    which the executable runner does not implement yet (recorded
    divergence, survey finding 23). -/
def CsSem.ofEval {C S : Type} (ev : C → S → Bool) : CsSem C S :=
  { sat := fun c s => ev c s = true, nsat := fun c s => ev c s = false }

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

/-- Head-cons for the closure (the shape the runner-soundness induction
    produces: one node-step, then the recursive trace). -/
theorem Steps.head {γ : CsSem C S} {a b c : Config A I E C S}
    (h : Step γ a b) (hs : Steps γ b c) : Steps γ a c :=
  (Steps.single h).trans hs

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

/-! ## Constraint-arm micro-lemmas: the CsSem discipline exercised
    (continuation, 2026-08-19). `ifM`/`addConstraints` are the generated
    combinators that BUILD the `NDbranch`/`NDguard` nodes
    (Nondeterminism.lean:265/281); these lemmas show the relation's
    constraint arms compute on them under an arbitrary discipline. -/

/-- `app`-computation on `ifM`: one `NDbranch` node, state untouched. -/
theorem app_ifM (i : I) (c : C) (mT mE : ndM A I E C S) (st : S) :
    app (ifM i c mT mE) st = (NDbranch i c mT mE, st) := rfl

/-- `app`-computation on `addConstraints`: one `NDguard` node whose
    continuation is `nd_return ()`. -/
theorem app_addConstraints (i : I) (c : C) (st : S) :
    app (addConstraints i c : ndM Unit I E C S) st
      = (NDguard i c (nd_return ()), st) := rfl

/-- Positive arm of `ifM` under any discipline: a step when sat. -/
theorem step_ifM_then (γ : CsSem C S) {i : I} {c : C}
    (mT mE : ndM A I E C S) {st : S} (h : γ.sat c st) :
    Step γ (⟨.running (ifM i c mT mE), st⟩ : Config A I E C S)
           ⟨.running mT, st⟩ :=
  .branchL (app_ifM i c mT mE st) h

/-- Negative arm of `ifM` under any discipline: a step when nsat. -/
theorem step_ifM_else (γ : CsSem C S) {i : I} {c : C}
    (mT mE : ndM A I E C S) {st : S} (h : γ.nsat c st) :
    Step γ (⟨.running (ifM i c mT mE), st⟩ : Config A I E C S)
           ⟨.running mE, st⟩ :=
  .branchR (app_ifM i c mT mE st) h

/-- Crossing a constraint node (`addConstraints`) under any discipline:
    a step to the unit continuation when sat. Under `CsSem.exhaustive`
    the premise is trivial (the executable's no-pruning behavior); under
    `CsSem.ofEval` it is a real evaluator verdict — the same rule, two
    disciplines, no change to the relation. -/
theorem step_addConstraints (γ : CsSem C S) {i : I} {c : C} {st : S}
    (h : γ.sat c st) :
    Step γ (⟨.running (addConstraints i c), st⟩ : Config Unit I E C S)
           ⟨.running (nd_return ()), st⟩ :=
  .guard (app_addConstraints i c st) h

/-- INVERSION at an `ifM` node: any step out of it is one of the two
    arms, with the discipline's verdict attached and the state unchanged.
    With `γ := CsSem.ofEval ev` the two disjuncts are mutually exclusive
    (`ev c st` cannot be both `true` and `false`) — branch pruning as a
    relational fact. -/
theorem step_ifM_inv {γ : CsSem C S} {i : I} {c : C}
    {mT mE : ndM A I E C S} {st : S} {c' : Config A I E C S}
    (h : Step γ ⟨.running (ifM i c mT mE), st⟩ c') :
    (γ.sat c st ∧ c' = ⟨.running mT, st⟩) ∨
    (γ.nsat c st ∧ c' = ⟨.running mE, st⟩) := by
  cases h with
  | active happ =>
    rw [app_ifM] at happ
    injection happ with h1 _; injection h1
  | killed happ =>
    rw [app_ifM] at happ
    injection happ with h1 _; injection h1
  | nd happ _ =>
    rw [app_ifM] at happ
    injection happ with h1 _; injection h1
  | step happ _ =>
    rw [app_ifM] at happ
    injection happ with h1 _; injection h1
  | guard happ _ =>
    rw [app_ifM] at happ
    injection happ with h1 _; injection h1
  | branchL happ hsat =>
    rw [app_ifM] at happ
    injection happ with h1 h2
    injection h1 with hi hc hl hr
    subst hi; subst hc; subst hl; subst hr; subst h2
    exact Or.inl ⟨hsat, rfl⟩
  | branchR happ hnsat =>
    rw [app_ifM] at happ
    injection happ with h1 h2
    injection h1 with hi hc hl hr
    subst hi; subst hc; subst hl; subst hr; subst h2
    exact Or.inr ⟨hnsat, rfl⟩

end Step

/-! ## Bind congruence (continuation, 2026-08-19): sequential composition
    meets the relation. `nd_bind` is fuel'd (Nondeterminism.lean:167);
    the lemmas are proved at generic positive fuel and instantiated at
    the default via the arc-3 wrapper-defeq move
    (`lemDefaultFuel ≡ 999999 + 1`, kernel literal arithmetic). Only the
    ACTIVE case is needed at spike scale: an `NDactive` head of `m` makes
    `nd_bind m f` behave exactly like `f v` at the post-state — the
    workhorse for walking the generated driver code, which is all binds. -/

section Bind
variable {A B I E C S : Type}

theorem app_bindFuel_active (fuel : Nat) {m : ndM A I E C S}
    {f : A → ndM B I E C S} {st st' : S} {v : A}
    (h : app m st = (NDactive v, st')) :
    app (nd_bind_lemFuel (fuel + 1) m f) st = app (f v) st' := by
  cases m with
  | ND g =>
    cases hfv : f v with
    | ND g' =>
      have hg : g st = (NDactive v, st') := h
      simp only [nd_bind_lemFuel, app, hg, hfv]

/-- The default-fuel wrapper form (the executable's own `nd_bind`). -/
theorem app_bind_active {m : ndM A I E C S} {f : A → ndM B I E C S}
    {st st' : S} {v : A} (h : app m st = (NDactive v, st')) :
    app (nd_bind m f) st = app (f v) st' :=
  app_bindFuel_active 999999 h

/-- Step transfer across a bind with an active head: whatever step the
    continuation takes at the post-state, the bound computation takes
    from the pre-state. -/
theorem step_bind_active {γ : CsSem C S} {m : ndM A I E C S}
    {f : A → ndM B I E C S} {st st' : S} {v : A}
    {c' : Config B I E C S}
    (h : app m st = (NDactive v, st'))
    (hs : Step γ ⟨.running (f v), st'⟩ c') :
    Step γ ⟨.running (nd_bind m f), st⟩ c' := by
  have happ := app_bind_active (f := f) h
  cases hs with
  | active h2 => exact .active (happ.trans h2)
  | killed h2 => exact .killed (happ.trans h2)
  | nd h2 hm => exact .nd (happ.trans h2) hm
  | step h2 hm => exact .step (happ.trans h2) hm
  | guard h2 hg => exact .guard (happ.trans h2) hg
  | branchL h2 hg => exact .branchL (happ.trans h2) hg
  | branchR h2 hg => exact .branchR (happ.trans h2) hg

end Bind

/-! ## State-lens lifting (continuation, 2026-08-19): `liftND`
    (Nondeterminism.lean:289) re-bases a computation through a get/put
    lens on the state — the combinator behind the driver's memory-op
    seam `liftMem` (Driver.lean:218). Active case only, same fuel
    discipline as the bind lemmas (`lemDefaultFuel ≡ 999998 + 2`). -/

section Lift
variable {A C E₁ E₂ I₁ I₂ S₁ S₂ : Type}

theorem app_liftFuel_active (fuel : Nat)
    (get2 : S₂ → S₁) (put1 : S₂ → S₁ → S₂)
    (li : I₁ → I₂) (le : E₁ → E₂)
    {m : ndM A I₁ E₁ C S₁} {st2 : S₂} {st1' : S₁} {v : A}
    (h : app m (get2 st2) = (NDactive v, st1')) :
    app (liftND_lemFuel (fuel + 2) get2 put1 li le m) st2
      = (NDactive v, put1 st2 st1') := by
  cases m with
  | ND g =>
    have hg : g (get2 st2) = (NDactive v, st1') := h
    simp only [liftND_lemFuel, liftAction_lemFuel, app, hg]

/-- The default-fuel wrapper form (the generated `liftND` itself). -/
theorem app_liftND_active
    (get2 : S₂ → S₁) (put1 : S₂ → S₁ → S₂)
    (li : I₁ → I₂) (le : E₁ → E₂)
    {m : ndM A I₁ E₁ C S₁} {st2 : S₂} {st1' : S₁} {v : A}
    (h : app m (get2 st2) = (NDactive v, st1')) :
    app (liftND get2 put1 li le m) st2 = (NDactive v, put1 st2 st1') :=
  app_liftFuel_active 999998 get2 put1 li le h

/-- `liftAction`'s kill-reason mapping, named (the error component is
    re-based through the lens; locations/UB payloads are untouched). -/
def liftKill (le : E₁ → E₂) : kill_reason E₁ → kill_reason E₂
  | Undef0 loc ubs => Undef0 loc ubs
  | Error0 loc msg => Error0 loc msg
  | Other e => Other (le e)

/-- Kill propagation through the lens (fuel-generic): a killed head
    surfaces as a killed head of the lifted computation, with the
    reason mapped by `liftKill` and the state written back. -/
theorem app_liftFuel_killed (fuel : Nat)
    (get2 : S₂ → S₁) (put1 : S₂ → S₁ → S₂)
    (li : I₁ → I₂) (le : E₁ → E₂)
    {m : ndM A I₁ E₁ C S₁} {st2 : S₂} {st1' : S₁} {r : kill_reason E₁}
    (h : app m (get2 st2) = (NDkilled r, st1')) :
    app (liftND_lemFuel (fuel + 2) get2 put1 li le m) st2
      = (NDkilled (liftKill le r), put1 st2 st1') := by
  cases m with
  | ND g =>
    have hg : g (get2 st2) = (NDkilled r, st1') := h
    cases r <;>
      simp only [liftND_lemFuel, liftAction_lemFuel, app, hg, liftKill]

/-- The default-fuel wrapper form. -/
theorem app_liftND_killed
    (get2 : S₂ → S₁) (put1 : S₂ → S₁ → S₂)
    (li : I₁ → I₂) (le : E₁ → E₂)
    {m : ndM A I₁ E₁ C S₁} {st2 : S₂} {st1' : S₁} {r : kill_reason E₁}
    (h : app m (get2 st2) = (NDkilled r, st1')) :
    app (liftND get2 put1 li le m) st2
      = (NDkilled (liftKill le r), put1 st2 st1') :=
  app_liftFuel_killed 999998 get2 put1 li le h

end Lift

/-! ## Coverage-by-need micro-lemmas (arc-7 S3, 2026-08-20).

    EVIDENCE (tests/verify fixtures under
    `cerberus-lean --trace-nodes [--call f --call-args …]`, branch-0
    trace = the exhaustive set on this corpus): every T1-T5 execution —
    main-startup mode and call-harness mode alike — crosses exactly ONE
    ND-tree node: `NDactive` (`NDkilled` on T2's signed-overflow
    instance). Two generated-code facts make this so: `nd_bind`
    collapses ACTIVE heads inside one `app` unfolding
    (Nondeterminism.lean:169, the NDactive case applies the
    continuation's action to the post-state directly), and the
    scheduler's `pick` on a SINGLETON candidate list builds an
    `NDactive` node, not an `NDnd` (Nondeterminism.lean:257) — so a
    deterministic single-threaded run is ONE `Step.active` (or
    `Step.killed`) from `callConfig` to `done`.

    CONSEQUENCE (Step coverage BY NEED, the charter's bespoke stance):
    no new Step ARMS are needed for T1-T5 — the 7-rule relation already
    covers every node kind, and these executions traverse exactly the
    `active`/`killed` arms. What the slate proofs need instead is THE
    APP-EQUATION LAYER: lemmas that compute the one big `app` unfolding
    combinator by combinator (state-combinator equations, kill
    propagation through bind and the lens, singleton scheduling, and
    inversion at `done`). Those are below; each is characteristic
    (one equation per combinator), per the escalation rule. -/

section AppEquations
variable {A B I E C S : Type}

/-- `app`-computation on `nd_return`: an active head, state untouched. -/
theorem app_nd_return (v : A) (st : S) :
    app (nd_return v : ndM A I E C S) st = (NDactive v, st) := rfl

/-- `app`-computation on `kill`: a killed head, state untouched. -/
theorem app_kill (r : kill_reason E) (st : S) :
    app (kill r : ndM A I E C S) st = (NDkilled r, st) := rfl

/-- `app`-computation on `nd_get`: yields the state, state untouched. -/
theorem app_nd_get (st : S) :
    app (nd_get : ndM S I E C S) st = (NDactive st, st) := rfl

/-- `app`-computation on `nd_put`: yields unit, replaces the state. -/
theorem app_nd_put (st st0 : S) :
    app (nd_put st : ndM Unit I E C S) st0 = (NDactive (), st) := rfl

/-- `app`-computation on `nd_update`: yields unit, transforms the state. -/
theorem app_nd_update (f : S → S) (st : S) :
    app (nd_update f : ndM Unit I E C S) st = (NDactive (), f st) := rfl

/-- `app`-computation on `nd_read`: yields a projection, state untouched. -/
theorem app_nd_read (f : S → A) (st : S) :
    app (nd_read f : ndM A I E C S) st = (NDactive (f st), st) := rfl

/-- `app`-computation on `print_debug`: logically `nd_return ()` (the
    debug printing is pure-invisible; unit eta). -/
theorem app_print_debug (level : Nat) (doms : List domain)
    (msg : Unit → String) (st : S) :
    app (print_debug level doms msg : ndM Unit I E C S) st
      = (NDactive (), st) := rfl

/-- `nd_guard` at a satisfied guard: `nd_return ()`. -/
theorem app_nd_guard_true (r : kill_reason E) (st : S) :
    app (nd_guard true r : ndM Unit I E C S) st = (NDactive (), st) := rfl

/-- `nd_guard` at a violated guard: `kill`. -/
theorem app_nd_guard_false (r : kill_reason E) (st : S) :
    app (nd_guard false r : ndM Unit I E C S) st = (NDkilled r, st) := rfl

/-- SINGLETON SCHEDULING (the trace-evidence keystone): `pick` on a
    one-candidate list is an ACTIVE node — no `NDnd`, no relational
    branching. This is why single-threaded deterministic runs are
    one-step: the driver loop's `pick (SK_misc ["driver 2"]) tid_steps`
    always sees a singleton. -/
theorem app_pick_singleton [Constraints C] [Lem_Show.Show I]
    (i : I) (x : A) (st : S) :
    app (pick i [x] : ndM A I E C S) st = (NDactive x, st) := rfl

end AppEquations

/-! ## Kill propagation through bind (the T2 UB-trace shape) -/

section BindKilled
variable {A B I E C S : Type}

/-- A killed head propagates through a bind INSIDE one `app` unfolding
    (nd_bind's NDkilled case) — the whole T2 signed-overflow run is one
    `NDkilled` node because every bind on the path forwards the kill. -/
theorem app_bindFuel_killed (fuel : Nat) {m : ndM A I E C S}
    {f : A → ndM B I E C S} {st st' : S} {r : kill_reason E}
    (h : app m st = (NDkilled r, st')) :
    app (nd_bind_lemFuel (fuel + 1) m f) st = (NDkilled r, st') := by
  cases m with
  | ND g =>
    have hg : g st = (NDkilled r, st') := h
    simp only [nd_bind_lemFuel, app, hg]

/-- The default-fuel wrapper form (the executable's own `nd_bind`). -/
theorem app_bind_killed {m : ndM A I E C S} {f : A → ndM B I E C S}
    {st st' : S} {r : kill_reason E}
    (h : app m st = (NDkilled r, st')) :
    app (nd_bind m f) st = (NDkilled r, st') :=
  app_bindFuel_killed 999999 h

/-- One killed step out of a bind with a killed head. -/
theorem step_bind_killed {γ : CsSem C S} {m : ndM A I E C S}
    {f : A → ndM B I E C S} {st st' : S} {r : kill_reason E}
    (h : app m st = (NDkilled r, st')) :
    Step γ (⟨.running (nd_bind m f), st⟩ : Config B I E C S)
           ⟨.done (.killed r), st'⟩ :=
  .killed (app_bind_killed h)

end BindKilled

/-! ## Inversion at `done` (the adequacy-direction reading: a terminal
    step happened, therefore the `app` equation held) -/

section DoneInversion
variable {A I E C S : Type}

/-- Any step into a `done` configuration is an `active`/`killed` arm
    with the matching `app` equation. -/
theorem step_done_inv {γ : CsSem C S} {m : ndM A I E C S}
    {st st' : S} {o : Outcome A E}
    (h : Step γ ⟨.running m, st⟩ ⟨.done o, st'⟩) :
    (∃ v, o = .value v ∧ app m st = (NDactive v, st')) ∨
    (∃ r, o = .killed r ∧ app m st = (NDkilled r, st')) := by
  cases h with
  | active happ => exact Or.inl ⟨_, rfl, happ⟩
  | killed happ => exact Or.inr ⟨_, rfl, happ⟩

/-- Value-terminal inversion: a step to `done (.value v)` IS the
    `NDactive v` equation. -/
theorem step_done_value_inv {γ : CsSem C S} {m : ndM A I E C S}
    {st st' : S} {v : A}
    (h : Step γ ⟨.running m, st⟩ ⟨.done (.value v), st'⟩) :
    app m st = (NDactive v, st') := by
  cases h with
  | active happ => exact happ

/-- Kill-terminal inversion. -/
theorem step_done_killed_inv {γ : CsSem C S} {m : ndM A I E C S}
    {st st' : S} {r : kill_reason E}
    (h : Step γ ⟨.running m, st⟩ ⟨.done (.killed r), st'⟩) :
    app m st = (NDkilled r, st') := by
  cases h with
  | killed happ => exact happ

end DoneInversion

end RelSem
