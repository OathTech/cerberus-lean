/-
  Cmm_csem_lemMeasureProofs — the hand-written proofs of the `fuel_measure`
  obligations lem emits into Cmm_csem_auxiliary.lean (concurrency Phase 0 S7,
  2026-09-05; `declare {lean} fuel_measure val …` in
  frontend/concurrency/cmm_csem.lem, Lean-only):

    apply_tree         measure `lemSize pred_tree`  (named_predicate_tree.lemSize)
    apply_tree_fp_aux  measure `lemSize pred_tree`  (named_predicate_tree_fp.lemSize)

  THE OBLIGATION (generated): the worker is fuel-STABLE at the measure. Shape =
  the C1/C2 template: strong induction on the size bound; at `Nat.succ f` /
  `Nat.succ g` the body is unfolded and the recursive call under `List.all`
  (through the destructuring lambda on the branch pair) is rewritten by the
  induction hypothesis via membership-relative congruence (`lall_congr`), the
  side condition `size branch < size (Node l)` from the member bound proved
  here. Upstream's `.lem` bodies are untouched ([USER 2026-09-05]: lem edits
  for the Lean target are against the rules) — this file is what makes the
  nested recursion total on the Lean target. Kernel-only tactics; no option
  bumps.

  MIRROR-OCAML NOTE: proofs about the Lean total workers; no OCaml text
  corresponds.
-/

import Cmm_csem
import CerbMeasureLemmas

set_option autoImplicit false

open CerbMeasureLemmas

namespace Cmm_csem_lemMeasureProofs

theorem tree_lemSize_pos (t : named_predicate_tree) : 1 ≤ named_predicate_tree.lemSize t := by
  cases t <;> simp [named_predicate_tree.lemSize]

theorem tree_mem_lt (l : List (String × named_predicate_tree)) (name : String) (b : named_predicate_tree)
    (h : (name, b) ∈ l) : named_predicate_tree.lemSize b < named_predicate_tree.lemSize_aux1 l := by
  induction l with
  | nil => cases h
  | cons x xs ih =>
    obtain ⟨n, t⟩ := x
    simp only [named_predicate_tree.lemSize_aux1]
    rcases List.mem_cons.mp h with h | h
    · cases h; omega
    · have := ih h; omega

theorem apply_tree_stable_aux (k : Nat) : ∀ (t : named_predicate_tree)
    (X : pre_execution × execution_witness × relation_list) (f g : Nat),
    named_predicate_tree.lemSize t ≤ k → named_predicate_tree.lemSize t ≤ f →
    named_predicate_tree.lemSize t ≤ g →
    apply_tree_lemFuel f t X = apply_tree_lemFuel g t X := by
  induction k with
  | zero => intro t _ _ _ hk; have := tree_lemSize_pos t; omega
  | succ k ih =>
    intro t X f g hk hf hg
    cases f with
    | zero => have := tree_lemSize_pos t; omega
    | succ f =>
      cases g with
      | zero => have := tree_lemSize_pos t; omega
      | succ g =>
        cases t with
        | Leaf p => simp only [apply_tree_lemFuel]
        | Node l =>
          simp only [apply_tree_lemFuel]
          apply lall_congr
          intro p hp
          obtain ⟨name, branch⟩ := p
          have hlt := tree_mem_lt l name branch hp
          simp only [named_predicate_tree.lemSize] at hk hf hg
          exact ih branch X f g (by omega) (by omega) (by omega)

theorem apply_tree_measure_sufficient (pred_tree : named_predicate_tree)
    (X : pre_execution × execution_witness × relation_list) (lemFuel : Nat)
    (lemMeasureLe : named_predicate_tree.lemSize pred_tree ≤ lemFuel) :
    apply_tree_lemFuel lemFuel pred_tree X = apply_tree pred_tree X := by
  unfold apply_tree
  exact apply_tree_stable_aux (named_predicate_tree.lemSize pred_tree) pred_tree X lemFuel _
    (Nat.le_refl _) lemMeasureLe (Nat.le_refl _)

theorem tree_fp_lemSize_pos (t : named_predicate_tree_fp) : 1 ≤ named_predicate_tree_fp.lemSize t := by
  cases t <;> simp [named_predicate_tree_fp.lemSize]

theorem tree_fp_mem_lt (l : List (String × named_predicate_tree_fp)) (name : String) (b : named_predicate_tree_fp)
    (h : (name, b) ∈ l) : named_predicate_tree_fp.lemSize b < named_predicate_tree_fp.lemSize_aux1 l := by
  induction l with
  | nil => cases h
  | cons x xs ih =>
    obtain ⟨n, t⟩ := x
    simp only [named_predicate_tree_fp.lemSize_aux1]
    rcases List.mem_cons.mp h with h | h
    · cases h; omega
    · have := ih h; omega

theorem apply_tree_fp_aux_stable_aux (k : Nat) : ∀ (t : named_predicate_tree_fp)
    (ex_fp : pre_execution × execution_witness_fp × relation_list_fp)
    (ex : pre_execution × execution_witness × relation_list) (f g : Nat),
    named_predicate_tree_fp.lemSize t ≤ k → named_predicate_tree_fp.lemSize t ≤ f →
    named_predicate_tree_fp.lemSize t ≤ g →
    apply_tree_fp_aux_lemFuel f t ex_fp ex = apply_tree_fp_aux_lemFuel g t ex_fp ex := by
  induction k with
  | zero => intro t _ _ _ _ hk; have := tree_fp_lemSize_pos t; omega
  | succ k ih =>
    intro t ex_fp ex f g hk hf hg
    cases f with
    | zero => have := tree_fp_lemSize_pos t; omega
    | succ f =>
      cases g with
      | zero => have := tree_fp_lemSize_pos t; omega
      | succ g =>
        cases t with
        | Leaf_fp p => simp only [apply_tree_fp_aux_lemFuel]
        | Leaf_non_fp p => simp only [apply_tree_fp_aux_lemFuel]
        | Node_fp l =>
          simp only [apply_tree_fp_aux_lemFuel]
          apply lall_congr
          intro p hp
          obtain ⟨name, branch⟩ := p
          have hlt := tree_fp_mem_lt l name branch hp
          simp only [named_predicate_tree_fp.lemSize] at hk hf hg
          exact ih branch ex_fp ex f g (by omega) (by omega) (by omega)

theorem apply_tree_fp_aux_measure_sufficient (pred_tree : named_predicate_tree_fp)
    (ex_fp : pre_execution × execution_witness_fp × relation_list_fp)
    (ex : pre_execution × execution_witness × relation_list) (lemFuel : Nat)
    (lemMeasureLe : named_predicate_tree_fp.lemSize pred_tree ≤ lemFuel) :
    apply_tree_fp_aux_lemFuel lemFuel pred_tree ex_fp ex = apply_tree_fp_aux pred_tree ex_fp ex := by
  unfold apply_tree_fp_aux
  exact apply_tree_fp_aux_stable_aux (named_predicate_tree_fp.lemSize pred_tree) pred_tree ex_fp ex lemFuel _
    (Nat.le_refl _) lemMeasureLe (Nat.le_refl _)

end Cmm_csem_lemMeasureProofs
