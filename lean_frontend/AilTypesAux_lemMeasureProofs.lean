/-
  AilTypesAux_lemMeasureProofs — the hand-written proofs of the three
  `fuel_measure` obligations lem emits into AilTypesAux_auxiliary.lean for the
  `are_compatible` mutual block (fuel-parameter arc C3, 2026-09-05; Lean-only
  declares in frontend/model/ail/ailTypesAux.lem):

    are_compatible            = `ctype.lemSize p.2 + ctype.lemSize p0.2 + 1`
    are_compatible_params_aux = `ctype_.lemSize_aux1 lemTail.1 + ctype_.lemSize_aux1 lemTail.2 + 1`
    are_compatible_params     = `ctype_.lemSize_aux1 params1 + ctype_.lemSize_aux1 params2 + 2`

  The block shares ONE fuel counter (lem demutualizes a mutual block over a
  single `lemFuel`, decremented at every hop), so each member's measure must
  bound the WHOLE block's call depth from that entry: every cross-call strictly
  decreases the CALLEE's measure. `are_compatible_params_aux`'s recursion
  argument is the `function` scrutinee, hoisted into the head as `lemTail` by
  lem d4ba548 (the tails slice), a pair of parameter lists: its measure is
  the derived size of BOTH lists (the elements' ctypes are recursed into by
  `are_compatible`, so `List.length` alone is NOT sufficient — the lem dry
  run's acceptance witness, record §7 decision 3, corrected here).
  `are_compatible_params` calls the aux at fuel − 1 on the same lists, hence
  its `+ 2`.

  Shape: the C2 template — one joint stability statement for the three
  members by strong induction on the bound k (the C1 lemma: any two fuels at
  or above the measure agree), the arms opened by `rcases` on both ctypes
  (the Ctype_lemMeasureProofs shape: tuple patterns destructured before the
  matcher is reduced); every recursive call rewritten by a `key` whose side
  condition `omega` proves from the unfolded derived sizes. Kernel-only
  tactics; no option bumps.

  MIRROR-OCAML NOTE: proofs about the Lean total workers; no OCaml text
  corresponds (fuel is a Lean-target artifact).
-/

import AilTypesAux

set_option autoImplicit false

namespace AilTypesAux_lemMeasureProofs

/-- The discharger: unfold the derived ctype sizes (goal and hypotheses), then `omega`. -/
macro "csize" : tactic => `(tactic| (
  (try simp only [ctype.lemSize, ctype_.lemSize, ctype_.lemSize_aux1] at *); omega))

/-- The joint stability lemma for the mutual block: above each member's measure,
    any two fuels agree. -/
theorem are_compatible_stable_aux (k : Nat) :
    (∀ (qs1 : qualifiers) (t1 : ctype) (qs2 : qualifiers) (t2 : ctype) (f g : Nat),
      ctype.lemSize t1 + ctype.lemSize t2 + 1 ≤ k →
      ctype.lemSize t1 + ctype.lemSize t2 + 1 ≤ f →
      ctype.lemSize t1 + ctype.lemSize t2 + 1 ≤ g →
      are_compatible_lemFuel f (qs1, t1) (qs2, t2) = are_compatible_lemFuel g (qs1, t1) (qs2, t2)) ∧
    (∀ (acc : Bool) (l1 l2 : List (qualifiers × ctype × Bool)) (f g : Nat),
      ctype_.lemSize_aux1 l1 + ctype_.lemSize_aux1 l2 + 1 ≤ k →
      ctype_.lemSize_aux1 l1 + ctype_.lemSize_aux1 l2 + 1 ≤ f →
      ctype_.lemSize_aux1 l1 + ctype_.lemSize_aux1 l2 + 1 ≤ g →
      are_compatible_params_aux_lemFuel f acc (l1, l2) = are_compatible_params_aux_lemFuel g acc (l1, l2)) ∧
    (∀ (ps1 ps2 : List (qualifiers × ctype × Bool)) (f g : Nat),
      ctype_.lemSize_aux1 ps1 + ctype_.lemSize_aux1 ps2 + 2 ≤ k →
      ctype_.lemSize_aux1 ps1 + ctype_.lemSize_aux1 ps2 + 2 ≤ f →
      ctype_.lemSize_aux1 ps1 + ctype_.lemSize_aux1 ps2 + 2 ≤ g →
      are_compatible_params_lemFuel f ps1 ps2 = are_compatible_params_lemFuel g ps1 ps2) := by
  induction k with
  | zero =>
    exact ⟨fun _ _ _ _ _ _ hk _ _ => by omega, fun _ _ _ _ _ hk _ _ => by omega,
      fun _ _ _ _ hk _ _ => by omega⟩
  | succ k ih =>
    obtain ⟨ih1, ih2, ih3⟩ := ih
    refine ⟨?_, ?_, ?_⟩
    -- are_compatible
    · intro qs1 t1 qs2 t2 f g hk hf hg
      cases f with
      | zero => omega
      | succ f =>
        cases g with
        | zero => omega
        | succ g =>
          -- every cross-call strictly decreases the callee's measure below THIS entry's
          have key1 : ∀ (q1 : qualifiers) (u1 : ctype) (q2 : qualifiers) (u2 : ctype),
              ctype.lemSize u1 + ctype.lemSize u2 + 1 < ctype.lemSize t1 + ctype.lemSize t2 + 1 →
              are_compatible_lemFuel f (q1, u1) (q2, u2) = are_compatible_lemFuel g (q1, u1) (q2, u2) :=
            fun q1 u1 q2 u2 h => ih1 q1 u1 q2 u2 f g (by omega) (by omega) (by omega)
          have key3 : ∀ (ps1 ps2 : List (qualifiers × ctype × Bool)),
              ctype_.lemSize_aux1 ps1 + ctype_.lemSize_aux1 ps2 + 2 < ctype.lemSize t1 + ctype.lemSize t2 + 1 →
              are_compatible_params_lemFuel f ps1 ps2 = are_compatible_params_lemFuel g ps1 ps2 :=
            fun ps1 ps2 h => ih3 ps1 ps2 f g (by omega) (by omega) (by omega)
          obtain ⟨an1, ty1⟩ := t1
          obtain ⟨an2, ty2⟩ := t2
          -- every constructor of both sides, tuple patterns destructured
          (rcases ty1 with _ | b1 | ⟨u1, n1⟩ | ⟨⟨q1, u1⟩, ps1, v1⟩ | ⟨⟨q1, u1⟩⟩ | ⟨q1, u1⟩ | u1 | s1 | s1 | _ <;>
           rcases ty2 with _ | b2 | ⟨u2, n2⟩ | ⟨⟨q2, u2⟩, ps2, v2⟩ | ⟨⟨q2, u2⟩⟩ | ⟨q2, u2⟩ | u2 | s2 | s2 | _ <;>
           simp only [are_compatible_lemFuel] <;> try rfl)
          -- the arms with a recursive call: Array0, Function (×3 shapes), FunctionNoParams, Pointer, Atomic
          all_goals simp (disch := csize) only [key1, key3]
    -- are_compatible_params_aux (the hoisted `lemTail` is the pair of lists)
    · intro acc l1 l2 f g hk hf hg
      cases f with
      | zero => omega
      | succ f =>
        cases g with
        | zero => omega
        | succ g =>
          have key1 : ∀ (q1 : qualifiers) (u1 : ctype) (q2 : qualifiers) (u2 : ctype),
              ctype.lemSize u1 + ctype.lemSize u2 + 1 < ctype_.lemSize_aux1 l1 + ctype_.lemSize_aux1 l2 + 1 →
              are_compatible_lemFuel f (q1, u1) (q2, u2) = are_compatible_lemFuel g (q1, u1) (q2, u2) :=
            fun q1 u1 q2 u2 h => ih1 q1 u1 q2 u2 f g (by omega) (by omega) (by omega)
          have key2 : ∀ (acc' : Bool) (m1 m2 : List (qualifiers × ctype × Bool)),
              ctype_.lemSize_aux1 m1 + ctype_.lemSize_aux1 m2 + 1 < ctype_.lemSize_aux1 l1 + ctype_.lemSize_aux1 l2 + 1 →
              are_compatible_params_aux_lemFuel f acc' (m1, m2) = are_compatible_params_aux_lemFuel g acc' (m1, m2) :=
            fun acc' m1 m2 h => ih2 acc' m1 m2 f g (by omega) (by omega) (by omega)
          rcases l1 with _ | ⟨⟨q1, u1, b1⟩, ps1⟩ <;> rcases l2 with _ | ⟨⟨q2, u2, b2⟩, ps2⟩ <;>
            simp only [are_compatible_params_aux_lemFuel]
          simp (disch := csize) only [key1, key2]
    -- are_compatible_params
    · intro ps1 ps2 f g hk hf hg
      cases f with
      | zero => omega
      | succ f =>
        cases g with
        | zero => omega
        | succ g =>
          have key2 : ∀ (acc' : Bool) (m1 m2 : List (qualifiers × ctype × Bool)),
              ctype_.lemSize_aux1 m1 + ctype_.lemSize_aux1 m2 + 1 < ctype_.lemSize_aux1 ps1 + ctype_.lemSize_aux1 ps2 + 2 →
              are_compatible_params_aux_lemFuel f acc' (m1, m2) = are_compatible_params_aux_lemFuel g acc' (m1, m2) :=
            fun acc' m1 m2 h => ih2 acc' m1 m2 f g (by omega) (by omega) (by omega)
          simp (disch := csize) only [are_compatible_params_lemFuel, key2]

/-- THE OBLIGATION, exactly as AilTypesAux_auxiliary.lean states and delegates it. -/
theorem are_compatible_measure_sufficient (p : qualifiers × ctype) (p0 : qualifiers × ctype) (lemFuel : Nat)
    (lemMeasureLe : ctype.lemSize p.2 + ctype.lemSize p0.2 + 1 ≤ lemFuel) :
    are_compatible_lemFuel lemFuel p p0 = are_compatible p p0 := by
  obtain ⟨qs1, t1⟩ := p
  obtain ⟨qs2, t2⟩ := p0
  exact (are_compatible_stable_aux (ctype.lemSize t1 + ctype.lemSize t2 + 1)).1 qs1 t1 qs2 t2 lemFuel
    (ctype.lemSize t1 + ctype.lemSize t2 + 1) (Nat.le_refl _) lemMeasureLe (Nat.le_refl _)

/-- THE OBLIGATION for the hoisted-tail member (`lemTail` = the pair of parameter lists). -/
theorem are_compatible_params_aux_measure_sufficient (acc : Bool)
    (lemTail : List (qualifiers × ctype × Bool) × List (qualifiers × ctype × Bool)) (lemFuel : Nat)
    (lemMeasureLe : ctype_.lemSize_aux1 lemTail.1 + ctype_.lemSize_aux1 lemTail.2 + 1 ≤ lemFuel) :
    are_compatible_params_aux_lemFuel lemFuel acc lemTail = are_compatible_params_aux acc lemTail := by
  obtain ⟨l1, l2⟩ := lemTail
  exact (are_compatible_stable_aux (ctype_.lemSize_aux1 l1 + ctype_.lemSize_aux1 l2 + 1)).2.1 acc l1 l2 lemFuel
    (ctype_.lemSize_aux1 l1 + ctype_.lemSize_aux1 l2 + 1) (Nat.le_refl _) lemMeasureLe (Nat.le_refl _)

/-- THE OBLIGATION, exactly as AilTypesAux_auxiliary.lean states and delegates it. -/
theorem are_compatible_params_measure_sufficient (params1 params2 : List (qualifiers × ctype × Bool)) (lemFuel : Nat)
    (lemMeasureLe : ctype_.lemSize_aux1 params1 + ctype_.lemSize_aux1 params2 + 2 ≤ lemFuel) :
    are_compatible_params_lemFuel lemFuel params1 params2 = are_compatible_params params1 params2 :=
  (are_compatible_stable_aux (ctype_.lemSize_aux1 params1 + ctype_.lemSize_aux1 params2 + 2)).2.2 params1 params2 lemFuel
    (ctype_.lemSize_aux1 params1 + ctype_.lemSize_aux1 params2 + 2) (Nat.le_refl _) lemMeasureLe (Nat.le_refl _)

end AilTypesAux_lemMeasureProofs
