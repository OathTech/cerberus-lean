/-
  RelSem.RunNDT — spike/relsem continuation (2026-08-19). SPIKE-GRADE.

  TOTAL-RUNNER PROTOTYPE (the Q1 AMENDMENT's dress rehearsal): a
  fuel-totalized mirror of the exhaustive runner `CerbND.runND`
  (CerbND.lean:39), RelSem-LOCAL — CerbND is untouched; the arc-7 slice
  "totalize CerbND" will transfer this definition (see the spike doc's
  continuation section for what that transfer needs).

  Mirroring discipline: branch ORDER is `runND`'s exactly —
  * NDnd/NDstep: `foldl (fun acc (_, branch) => run branch st' ++ acc) []`
    (OCaml smt2.ml:75-82 prepend accumulation, R_n ++ … ++ R_1);
  * NDbranch: left ++ right (smt2.ml:117-132);
  * NDguard: continuation, no pruning (recorded divergence, finding 23).
  The ONE difference is fuel: `runNDT 0 _ _ = []` ("no behaviors found
  within this fuel"), which is honest under the ∃-fuel reading because
  `runNDT_mono` makes the fuel-indexed sets increase — `Behaviors` (the
  ∃-fuel union) is exactly the set the partial runner enumerates when it
  terminates. Fuel counts TREE DEPTH, like `nd_bind`'s own fuel
  (Nondeterminism.lean:167).

  Proved here (spike scale):
  * `runNDT_sound` — EVERY element of `runNDT fuel m st` (head included)
    is `Steps`-reachable under the exhaustive discipline: membership of
    `(out, tr, st')` implies
    `Steps (CsSem.exhaustive C S) ⟨.running m, st⟩ ⟨.done out†, st'⟩`
    (out† = `Outcome.ofStatus out`). This is the golean
    `stepFn_sound`/`execStmt_sound_normal` analogue, at ND-tree
    granularity, for the TOTAL runner — no `partial` opacity in the way.
  * `runNDT_mono` — fuel monotonicity of membership (Q2(a)'s recommended
    lemma): more fuel only ADDS behaviors, so `∃ fuel` and "the default
    fuel, when it suffices" are interconvertible on enumerated outcomes.
  * `behaviors_sound` — the ∃-fuel corollary on `Behaviors`.

  NOT claimed: completeness (relation ⇒ runner membership). Per-node it
  is trivial (every `Step` successor is literally in the tree); run-level
  it is the stream-stitching converse golean records as unbuilt and
  unneeded (MachineSound.lean:535-545).

  House rules: no sorry, no axioms (beyond the generated code's declared
  DAEMON boundary entering through the types), no Iris imports.
-/

import Nondeterminism
import RelSem.Machine

set_option autoImplicit false

namespace RelSem

section RunNDT

variable {A I E C S : Type}

/-- Outcome of a runner status (drops the state duplicated in `Killed`). -/
def Outcome.ofStatus : nd_status A E S → Outcome A E
  | Active r => .value r
  | Killed _ r => .killed r

/-- One enumerated execution: verdict, trace, final state — the exact
    result triple shape of `CerbND.runND`. -/
abbrev RunResult (A E S : Type) := nd_status A E S × List String × S

/-- Fuel-totalized exhaustive runner: the total mirror of `CerbND.runND`
    (same node dispatch, same result order; see header). Fuel bounds tree
    depth; exhaustion yields `[]`. -/
def runNDT : Nat → ndM A I E C S → S → List (RunResult A E S)
  | 0, _, _ => []
  | fuel + 1, m, st =>
    match app m st with
    | (NDactive r, st') => [(Active r, [], st')]
    | (NDkilled r, st') => [(Killed st' r, [], st')]
    | (NDnd _ br, st') =>
      br.foldl (fun acc p => runNDT fuel p.2 st' ++ acc) []
    | (NDguard _ _ k, st') => runNDT fuel k st'
    | (NDbranch _ _ l r, st') => runNDT fuel l st' ++ runNDT fuel r st'
    | (NDstep _ br, st') =>
      br.foldl (fun acc p => runNDT fuel p.2 st' ++ acc) []

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

/-- SOUNDNESS of the total runner against the relational machine (golean
    `stepFn_sound` analogue): every enumerated execution — the head and
    every other element alike — is a `Steps`-trace of the exhaustive
    discipline, ending in the `done` injection of its verdict at its
    final state. Traces (`tr`) are unconstrained because the runner never
    populates them (they are `[]` throughout; the relation does not
    observe them). -/
theorem runNDT_sound :
    ∀ (fuel : Nat) (m : ndM A I E C S) (st : S) (out : nd_status A E S)
      (tr : List String) (st' : S),
      (out, tr, st') ∈ runNDT fuel m st →
      Steps (CsSem.exhaustive C S)
        ⟨.running m, st⟩ ⟨.done (Outcome.ofStatus out), st'⟩ := by
  intro fuel
  induction fuel with
  | zero =>
    intro m st out tr st' h
    cases h
  | succ fuel ih =>
    intro m st out tr st' h
    simp only [runNDT] at h
    generalize happ : app m st = p at h
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
        cases (mem_foldl_prepend (fun p => runNDT fuel p.2 st1)
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
        cases (mem_foldl_prepend (fun p => runNDT fuel p.2 st1)
            (out, tr, st') br []).mp h with
        | inl h' =>
          cases h' with
          | intro b hb =>
            exact Steps.head (Step.step (j := b.1) happ hb.1)
              (ih b.2 st1 out tr st' hb.2)
        | inr h' => cases h'

/-- FUEL MONOTONICITY of membership (the Q2(a) lemma, total-runner form):
    increasing fuel only adds enumerated executions. Consequently the
    fuel-indexed enumeration is an increasing chain and `Behaviors` below
    is its honest union; `∃-fuel` statements and default-fuel statements
    agree on any execution the default fuel reaches. -/
theorem runNDT_mono :
    ∀ (fuel fuel' : Nat), fuel ≤ fuel' →
    ∀ (m : ndM A I E C S) (st : S) (x : RunResult A E S),
      x ∈ runNDT fuel m st → x ∈ runNDT fuel' m st := by
  intro fuel
  induction fuel with
  | zero =>
    intro fuel' _ m st x h
    cases h
  | succ fuel ih =>
    intro fuel' hle m st x h
    cases fuel' with
    | zero => exact absurd hle (by omega)
    | succ fuel' =>
      have hle' : fuel ≤ fuel' := Nat.le_of_succ_le_succ hle
      simp only [runNDT] at h ⊢
      generalize happ : app m st = p at h ⊢
      cases p with
      | mk act st1 =>
        cases act with
        | NDactive r => exact h
        | NDkilled r => exact h
        | NDnd i br =>
          apply (mem_foldl_prepend (fun p => runNDT fuel' p.2 st1) x br []).mpr
          cases (mem_foldl_prepend (fun p => runNDT fuel p.2 st1)
              x br []).mp h with
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
          apply (mem_foldl_prepend (fun p => runNDT fuel' p.2 st1) x br []).mpr
          cases (mem_foldl_prepend (fun p => runNDT fuel p.2 st1)
              x br []).mp h with
          | inl h' =>
            cases h' with
            | intro b hb =>
              exact Or.inl ⟨b, hb.1, ih fuel' hle' b.2 st1 x hb.2⟩
          | inr h' => cases h'

/-- The ∃-fuel behavior set of an ND computation: the union over fuel of
    the total runner's enumerations (increasing by `runNDT_mono`). This is
    the observable-behavior extraction the sequential `ExecModel` instance
    uses (RelSem.Cerberus `seqModel`). -/
def Behaviors (m : ndM A I E C S) (st : S) (x : RunResult A E S) : Prop :=
  ∃ fuel, x ∈ runNDT fuel m st

/-- ∃-fuel corollary of `runNDT_sound`: every behavior is a relational
    trace. -/
theorem behaviors_sound {m : ndM A I E C S} {st : S}
    {out : nd_status A E S} {tr : List String} {st' : S}
    (h : Behaviors m st (out, tr, st')) :
    Steps (CsSem.exhaustive C S)
      ⟨.running m, st⟩ ⟨.done (Outcome.ofStatus out), st'⟩ := by
  cases h with
  | intro fuel h => exact runNDT_sound fuel m st out tr st' h

end RunNDT

end RelSem
