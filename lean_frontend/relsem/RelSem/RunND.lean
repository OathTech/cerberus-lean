/-
  RelSem.RunND — arc-7 S2 (2026-08-19): runner soundness against the
  PRODUCTION runner.

  This file replaces the spike prototype RelSem/RunNDT.lean (spike/relsem
  branch, `runNDT` + `runNDT_sound` + `runNDT_mono`): the operator's Q1
  AMENDED ruling (docs/2026-08-19_relsem-spike.md) totalized
  `CerbND.runND` itself (fuel worker `CerbND.runNDFuel` + default-budget
  wrapper, CerbND.lean), so the theorems are now STATED OVER THE
  PRODUCTION FUNCTION — the executable and the proof object are the same
  artifact. [AGENT:S2] disposition of the prototype: DELETED in favor of
  proving against the real thing (the leaning the slice brief recorded);
  `runNDT` was a byte-level mirror of `runND`'s dispatch, so keeping it
  would be a duplicate definition whose only role was drift risk. The
  spike file remains in history (branch spike/relsem; commit 1567aba)
  as the design record; the proofs below are its transfer, unchanged
  except for (a) the worker's `match m` unfolding (CerbND matches the
  `ND` constructor directly instead of going through `app` — the two are
  definitionally equal, see `app` in RelSem/Machine.lean) and (b) the
  fuel-0 leaf, which is now the loud `panic!` exhaustion marker
  (logically `= default = []`, so membership at fuel 0 is still absurd:
  an exhausted leaf CLAIMS no behaviors — soundness is honest, only
  enumeration completeness is fuel-bounded, and completeness was never
  claimed, per spike §C2).

  Proved:
  * `runNDFuel_sound` — EVERY element of `CerbND.runNDFuel fuel m st`
    (head included) is `Steps`-reachable under the exhaustive
    discipline (the golean `stepFn_sound` analogue, at ND-tree
    granularity, against the production worker).
  * `runND_sound` — the same statement over the PRODUCTION WRAPPER
    `CerbND.runND` (the arc-4/5/6 harness runner at its default budget);
    defeq-transfers from the worker (arc-3 wrapper discipline,
    `runND_wrapper_defeq`).
  * `runNDFuel_mono` — fuel monotonicity of membership (Q2(a)): more
    fuel only ADDS behaviors; the fuel-indexed enumerations form an
    increasing chain, `Behaviors` is their honest union.
  * `behaviors_sound` — the ∃-fuel corollary on `Behaviors`.

  NOT claimed: completeness (relation ⇒ runner membership). Per-node it
  is trivial (every `Step` successor is literally in the tree); run-level
  it is the stream-stitching converse golean records as unbuilt and
  unneeded (MachineSound.lean:535-545).

  House rules: no sorry, no axioms (beyond the generated code's declared
  DAEMON boundary entering through the types), no Iris imports.
-/

import Nondeterminism
import CerbND
import RelSem.Machine

set_option autoImplicit false

namespace RelSem

section RunND

variable {A I E C S : Type}

/-- Outcome of a runner status (drops the state duplicated in `Killed`). -/
def Outcome.ofStatus : nd_status A E S → Outcome A E
  | Active r => .value r
  | Killed _ r => .killed r

/-- One enumerated execution: verdict, trace, final state — the exact
    result triple shape of `CerbND.runND`. -/
abbrev RunResult (A E S : Type) := nd_status A E S × List String × S

/-- The production wrapper is the worker at the default budget, BY RFL
    (arc-3 wrapper-defeq discipline): every `runNDFuel` theorem is a
    `runND` theorem at `ndDefaultFuel`. -/
theorem runND_wrapper_defeq (m : ndM A I E C S) (st : S) :
    CerbND.runND m st = CerbND.runNDFuel CerbND.ndDefaultFuel m st := rfl

/-- The fuel-0 leaf — the loud `panic!` exhaustion marker — is `[]` in
    the logic (`panic! = default`, and `default` for lists is `[]`): an
    exhausted leaf enumerates NOTHING, so soundness never has to speak
    for it. Loudness is a runtime property (@[extern] panic), invisible
    here by design. -/
theorem runNDFuel_zero (m : ndM A I E C S) (st : S) :
    CerbND.runNDFuel 0 m st = [] := rfl

/-- Membership in the prepend-accumulation fold (the NDnd/NDstep result
    order): an element is in the fold iff it comes from some branch or
    from the accumulator. Isolates all order-bookkeeping of the OCaml
    `R_n ++ … ++ R_1` convention in one lemma. -/
theorem mem_foldl_prepend {α β : Type} (f : β → List α) (x : α) :
    ∀ (l : List β) (acc : List α),
      x ∈ l.foldl (fun acc b => f b ++ acc) acc ↔
        (∃ b, b ∈ l ∧ x ∈ f b) ∨ x ∈ acc := by
  intro l
  induction l with
  | nil =>
    intro acc
    simp
  | cons hd tl ih =>
    intro acc
    rw [List.foldl_cons, ih]
    constructor
    · intro h
      cases h with
      | inl h =>
        cases h with
        | intro b hb => exact Or.inl ⟨b, List.mem_cons_of_mem hd hb.1, hb.2⟩
      | inr h =>
        cases List.mem_append.mp h with
        | inl h => exact Or.inl ⟨hd, List.mem_cons_self .., h⟩
        | inr h => exact Or.inr h
    · intro h
      cases h with
      | inl h =>
        cases h with
        | intro b hb =>
          cases List.mem_cons.mp hb.1 with
          | inl heq =>
            exact Or.inr (List.mem_append.mpr (Or.inl (heq ▸ hb.2)))
          | inr hmem => exact Or.inl ⟨b, hmem, hb.2⟩
      | inr h => exact Or.inr (List.mem_append.mpr (Or.inr h))

/-- SOUNDNESS of the production worker against the relational machine
    (golean `stepFn_sound` analogue): every enumerated execution — the
    head and every other element alike — is a `Steps`-trace of the
    exhaustive discipline, ending in the `done` injection of its verdict
    at its final state. Traces (`tr`) are unconstrained because the
    runner never populates them (they are `[]` throughout; the relation
    does not observe them). -/
theorem runNDFuel_sound :
    ∀ (fuel : Nat) (m : ndM A I E C S) (st : S) (out : nd_status A E S)
      (tr : List String) (st' : S),
      (out, tr, st') ∈ CerbND.runNDFuel fuel m st →
      Steps (CsSem.exhaustive C S)
        ⟨.running m, st⟩ ⟨.done (Outcome.ofStatus out), st'⟩ := by
  intro fuel
  induction fuel with
  | zero =>
    intro m st out tr st' h
    rw [runNDFuel_zero] at h
    cases h
  | succ fuel ih =>
    intro m st out tr st' h
    cases m with
    | ND f =>
      simp only [CerbND.runNDFuel] at h
      generalize happ : f st = p at h
      cases p with
      | mk act st1 =>
        cases act with
        | NDactive r =>
          cases h with
          | head => exact Steps.single (Step.active happ)
          | tail _ h => cases h
        | NDkilled r =>
          cases h with
          | head => exact Steps.single (Step.killed happ)
          | tail _ h => cases h
        | NDnd i br =>
          cases (mem_foldl_prepend (fun p => CerbND.runNDFuel fuel p.2 st1)
              (out, tr, st') br []).mp h with
          | inl h' =>
            cases h' with
            | intro b hb =>
              exact Steps.head (Step.nd (j := b.1) happ hb.1)
                (ih b.2 st1 out tr st' hb.2)
          | inr h' => cases h'
        | NDguard i c k =>
          exact Steps.head (Step.guard happ trivial) (ih k st1 out tr st' h)
        | NDbranch i c l r =>
          cases List.mem_append.mp h with
          | inl h' =>
            exact Steps.head (Step.branchL happ trivial)
              (ih l st1 out tr st' h')
          | inr h' =>
            exact Steps.head (Step.branchR happ trivial)
              (ih r st1 out tr st' h')
        | NDstep i br =>
          cases (mem_foldl_prepend (fun p => CerbND.runNDFuel fuel p.2 st1)
              (out, tr, st') br []).mp h with
          | inl h' =>
            cases h' with
            | intro b hb =>
              exact Steps.head (Step.step (j := b.1) happ hb.1)
                (ih b.2 st1 out tr st' hb.2)
          | inr h' => cases h'

/-- SOUNDNESS OF THE PRODUCTION RUNNER `CerbND.runND` — the function
    Main.lean executes on every exhaustive run. This is the statement
    the Q1 AMENDED ruling exists for: no mirror, no bridge, no
    differential — the theorem is about the artifact that runs. -/
theorem runND_sound (m : ndM A I E C S) (st : S) (out : nd_status A E S)
    (tr : List String) (st' : S)
    (h : (out, tr, st') ∈ CerbND.runND m st) :
    Steps (CsSem.exhaustive C S)
      ⟨.running m, st⟩ ⟨.done (Outcome.ofStatus out), st'⟩ :=
  runNDFuel_sound CerbND.ndDefaultFuel m st out tr st' h

/-- FUEL MONOTONICITY of membership (the Q2(a) lemma, production form):
    increasing fuel only adds enumerated executions. Consequently the
    fuel-indexed enumeration is an increasing chain and `Behaviors` below
    is its honest union; `∃-fuel` statements and default-budget
    statements agree on any execution the default budget reaches. -/
theorem runNDFuel_mono :
    ∀ (fuel fuel' : Nat), fuel ≤ fuel' →
    ∀ (m : ndM A I E C S) (st : S) (x : RunResult A E S),
      x ∈ CerbND.runNDFuel fuel m st → x ∈ CerbND.runNDFuel fuel' m st := by
  intro fuel
  induction fuel with
  | zero =>
    intro fuel' _ m st x h
    rw [runNDFuel_zero] at h
    cases h
  | succ fuel ih =>
    intro fuel' hle m st x h
    cases fuel' with
    | zero => exact absurd hle (by omega)
    | succ fuel' =>
      have hle' : fuel ≤ fuel' := Nat.le_of_succ_le_succ hle
      cases m with
      | ND f =>
        simp only [CerbND.runNDFuel] at h ⊢
        generalize happ : f st = p at h ⊢
        cases p with
        | mk act st1 =>
          cases act with
          | NDactive r => exact h
          | NDkilled r => exact h
          | NDnd i br =>
            apply (mem_foldl_prepend
                (fun p => CerbND.runNDFuel fuel' p.2 st1) x br []).mpr
            cases (mem_foldl_prepend
                (fun p => CerbND.runNDFuel fuel p.2 st1) x br []).mp h with
            | inl h' =>
              cases h' with
              | intro b hb =>
                exact Or.inl ⟨b, hb.1, ih fuel' hle' b.2 st1 x hb.2⟩
            | inr h' => cases h'
          | NDguard i c k => exact ih fuel' hle' k st1 x h
          | NDbranch i c l r =>
            cases List.mem_append.mp h with
            | inl h' =>
              exact List.mem_append.mpr (Or.inl (ih fuel' hle' l st1 x h'))
            | inr h' =>
              exact List.mem_append.mpr (Or.inr (ih fuel' hle' r st1 x h'))
          | NDstep i br =>
            apply (mem_foldl_prepend
                (fun p => CerbND.runNDFuel fuel' p.2 st1) x br []).mpr
            cases (mem_foldl_prepend
                (fun p => CerbND.runNDFuel fuel p.2 st1) x br []).mp h with
            | inl h' =>
              cases h' with
              | intro b hb =>
                exact Or.inl ⟨b, hb.1, ih fuel' hle' b.2 st1 x hb.2⟩
            | inr h' => cases h'

/-! ## Terminal-head outcome-set characterization (arc-7 S3): the
    slate-path fuel-erasure instances. The tests/verify trace evidence
    (RelSem/Machine.lean § Coverage-by-need) shows every T1-T5 run is
    ONE bind-collapsed `app` computation with a terminal head; on such
    a head the production worker's ENTIRE enumeration is the same
    singleton at EVERY positive fuel — fuel fully erased: the `∃ fuel`
    extraction, the default budget, and the exhaustive verdict set all
    coincide. These are the lemmas that turn one proved `app` equation
    into "outcomes = {…}" (the slate theorems' conclusion shape). -/

/-- Active head ⇒ the enumeration is the singleton `Active` triple, at
    every positive fuel (fuel-erasure instance). -/
theorem runNDFuel_active (fuel : Nat) {m : ndM A I E C S} {st st' : S}
    {v : A} (h : app m st = (NDactive v, st')) :
    CerbND.runNDFuel (fuel + 1) m st = [(Active v, [], st')] := by
  cases m with
  | ND g =>
    have hg : g st = (NDactive v, st') := h
    simp only [CerbND.runNDFuel, hg]

/-- Killed head ⇒ the singleton `Killed` triple, at every positive
    fuel. -/
theorem runNDFuel_killed (fuel : Nat) {m : ndM A I E C S} {st st' : S}
    {r : kill_reason E} (h : app m st = (NDkilled r, st')) :
    CerbND.runNDFuel (fuel + 1) m st = [(Killed st' r, [], st')] := by
  cases m with
  | ND g =>
    have hg : g st = (NDkilled r, st') := h
    simp only [CerbND.runNDFuel, hg]

/-- The production runner's outcome set on an active head (default
    budget = any positive fuel, by the erasure above). -/
theorem runND_active {m : ndM A I E C S} {st st' : S} {v : A}
    (h : app m st = (NDactive v, st')) :
    CerbND.runND m st = [(Active v, [], st')] :=
  runNDFuel_active 999999 h

/-- The production runner's outcome set on a killed head. -/
theorem runND_killed {m : ndM A I E C S} {st st' : S}
    {r : kill_reason E} (h : app m st = (NDkilled r, st')) :
    CerbND.runND m st = [(Killed st' r, [], st')] :=
  runNDFuel_killed 999999 h

/-- The ∃-fuel behavior set of an ND computation: the union over fuel of
    the production worker's enumerations (increasing by `runNDFuel_mono`).
    This is the observable-behavior extraction the sequential `ExecModel`
    instance uses (RelSem.Cerberus `seqModel`). -/
def Behaviors (m : ndM A I E C S) (st : S) (x : RunResult A E S) : Prop :=
  ∃ fuel, x ∈ CerbND.runNDFuel fuel m st

/-- ∃-FUEL ERASURE on an active head: the behavior set IS the singleton
    — the quantified extraction and the executable's default budget
    agree exactly (no behavior appears at any other fuel). -/
theorem behaviors_active_iff {m : ndM A I E C S} {st st' : S} {v : A}
    (h : app m st = (NDactive v, st')) (x : RunResult A E S) :
    Behaviors m st x ↔ x = (Active v, [], st') := by
  constructor
  · intro hx
    obtain ⟨fuel, hmem⟩ := hx
    cases fuel with
    | zero => rw [runNDFuel_zero] at hmem; cases hmem
    | succ fuel =>
      rw [runNDFuel_active fuel h] at hmem
      cases hmem with
      | head => rfl
      | tail _ h' => cases h'
  · intro hx
    subst hx
    exact ⟨1, by rw [runNDFuel_active 0 h]; exact List.Mem.head _⟩

/-- ∃-fuel erasure on a killed head. -/
theorem behaviors_killed_iff {m : ndM A I E C S} {st st' : S}
    {r : kill_reason E} (h : app m st = (NDkilled r, st'))
    (x : RunResult A E S) :
    Behaviors m st x ↔ x = (Killed st' r, [], st') := by
  constructor
  · intro hx
    obtain ⟨fuel, hmem⟩ := hx
    cases fuel with
    | zero => rw [runNDFuel_zero] at hmem; cases hmem
    | succ fuel =>
      rw [runNDFuel_killed fuel h] at hmem
      cases hmem with
      | head => rfl
      | tail _ h' => cases h'
  · intro hx
    subst hx
    exact ⟨1, by rw [runNDFuel_killed 0 h]; exact List.Mem.head _⟩

/-- ∃-fuel corollary of `runNDFuel_sound`: every behavior is a relational
    trace. -/
theorem behaviors_sound {m : ndM A I E C S} {st : S}
    {out : nd_status A E S} {tr : List String} {st' : S}
    (h : Behaviors m st (out, tr, st')) :
    Steps (CsSem.exhaustive C S)
      ⟨.running m, st⟩ ⟨.done (Outcome.ofStatus out), st'⟩ := by
  cases h with
  | intro fuel h => exact runNDFuel_sound fuel m st out tr st' h

end RunND

end RelSem
