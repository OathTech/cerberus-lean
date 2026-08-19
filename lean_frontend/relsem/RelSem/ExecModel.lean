/-
  RelSem.ExecModel — spike/relsem continuation (2026-08-19). SPIKE-GRADE.

  THE MODEL-PARAMETRICITY INTERFACE (operator principle, spike doc
  "Model-parametricity principle" [USER] entry): all adequacy-shaped
  plumbing is stated over an ABSTRACT execution model — a configuration
  type, a step relation (for the Layer-3 coupling), an observable-behavior
  extraction, and a UB classification — never over CerbND-shaped outcome
  lists directly. The sequential driver-level machine (RelSem.Cerberus:
  `seqModel`) is THE current instance; a concurrency instance (candidate-
  execution behaviors per the cmm direction) and a future RC11-style
  instance are parameter fills, not rebuilds. See the spike doc's
  continuation section for the fields-only sketch of the concurrency
  instance.

  Deliberately dependency-free (no import of the generated code): the
  interface must not know what a behavior IS, only that behaviors can be
  extracted from configurations and classified as UB or not.

  House rules: no sorry, no axioms, no Iris imports.
-/

set_option autoImplicit false

namespace RelSem

/-- An execution model: the data the model-generic adequacy plumbing (and
    the Layer-3 coupling) consumes.

    * `Config`/`Step` — the relational machine the program logic couples
      to (iris-lean `PrimStep` wraps `Step`; see RelSem/IrisCoupling.lean).
    * `Behavior`/`behavior` — the observable-behavior extraction: which
      observable behaviors a configuration admits. For the sequential
      instance this is (outcome, final state) via the fuel-erased total
      runner (`∃ fuel, · ∈ CerbND.runNDFuel fuel …`); for a concurrency
      instance it
      would be consistent candidate executions. Adequacy statements
      quantify over `behavior`, so "more nondeterminism" (weak memory,
      schedulers) arrives as MORE behaviors in the SAME statement form
      (forward-design constraint 3).
    * `isUB` — UB classification on behaviors. UB is a VALUE of the model
      (classifiable, excludable by specs), never encoded as stuckness. -/
structure ExecModel : Type 1 where
  /-- Machine configurations (Layer-2 carrier). -/
  Config : Type
  /-- The Layer-2 step relation on configurations. -/
  Step : Config → Config → Prop
  /-- Observable behaviors. -/
  Behavior : Type
  /-- Observable-behavior extraction: `behavior c b` = configuration `c`
      admits behavior `b`. -/
  behavior : Config → Behavior → Prop
  /-- UB classification of behaviors. -/
  isUB : Behavior → Prop

namespace ExecModel

variable (M : ExecModel)

/-- Model-generic adequacy shape: EVERY behavior of `c` satisfies `spec`.
    This is the statement form every instance-level headline refines; the
    Layer-3 discharge chain ends here (WP ⇒ iris adequacy ⇒ relational
    traces ⇒ `behavior`-membership ⇒ this). -/
def Adequate (c : M.Config) (spec : M.Behavior → Prop) : Prop :=
  ∀ b, M.behavior c b → spec b

/-- Model-generic UB-freedom: no admitted behavior is classified UB. -/
def UBFree (c : M.Config) : Prop :=
  M.Adequate c fun b => ¬ M.isUB b

/-- Adequacy is monotone in the spec (proved; the interface's smoke-test
    lemma — consequence-rule shape at the adequacy boundary). -/
theorem Adequate.mono {M : ExecModel} {c : M.Config}
    {spec spec' : M.Behavior → Prop}
    (h : M.Adequate c spec) (himp : ∀ b, spec b → spec' b) :
    M.Adequate c spec' :=
  fun b hb => himp b (h b hb)

/-- Adequacy for a conjunction splits (proved). -/
theorem Adequate.and {M : ExecModel} {c : M.Config}
    {spec spec' : M.Behavior → Prop}
    (h : M.Adequate c spec) (h' : M.Adequate c spec') :
    M.Adequate c fun b => spec b ∧ spec' b :=
  fun b hb => ⟨h b hb, h' b hb⟩

/-- UB-freedom is exactly adequacy at the ¬UB spec (proved; definitional,
    named so instance code can cite the interface, not the unfolding). -/
theorem ubFree_iff {M : ExecModel} {c : M.Config} :
    M.UBFree c ↔ M.Adequate c (fun b => ¬ M.isUB b) :=
  Iff.rfl

end ExecModel

end RelSem
