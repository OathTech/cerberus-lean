/-
  CerbMeasureLemmas — the shared toolbox of the hand-written `fuel_measure`
  sufficiency proofs (`*_lemMeasureProofs.lean`; fuel-parameter arc C2,
  2026-09-04). Nothing here is a model definition: only congruence lemmas for
  the list traversals the generated workers use AS WRITTEN (`List.map`,
  `List.any`, `List.all`, `List.foldl`, `lemListFoldr`), the "a member is
  strictly below its list's derived size helper" facts for the backend-derived
  `t.lemSize_auxN` helpers (Core's expr/pexpr/pattern blocks, the
  Defacto_memory_types integer-value block, the hand-written
  `CerbMem.memValueSize`), positivity of every size, and the `size_lt` tactic
  the stability proofs use as `simp`'s discharger: unfold the derived sizes,
  then `omega`. Kernel-only (no option bumps, no non-kernel decision
  procedures); imported by the proofs modules only.

  MIRROR-OCAML NOTE: proofs about the Lean total workers; no OCaml text
  corresponds.
-/

import Core
import CerbMem
import Defacto_memory_types
import LemLibTheorems

set_option autoImplicit false

namespace CerbMeasureLemmas

/-! ## Traversal congruences (membership-relative) -/

theorem lmap_congr {α β : Type} (l : List α) (F G : α → β)
    (h : ∀ x ∈ l, F x = G x) : l.map F = l.map G := List.map_congr_left h

theorem lany_congr {α : Type} (l : List α) (F G : α → Bool)
    (h : ∀ x ∈ l, F x = G x) : l.any F = l.any G := by
  induction l with
  | nil => rfl
  | cons x xs ih =>
    simp only [List.any_cons]
    rw [h x (List.mem_cons_self ..), ih (fun p hp => h p (List.mem_cons_of_mem _ hp))]

theorem lall_congr {α : Type} (l : List α) (F G : α → Bool)
    (h : ∀ x ∈ l, F x = G x) : l.all F = l.all G := by
  induction l with
  | nil => rfl
  | cons x xs ih =>
    simp only [List.all_cons]
    rw [h x (List.mem_cons_self ..), ih (fun p hp => h p (List.mem_cons_of_mem _ hp))]

theorem lfoldl_congr {α β : Type} (l : List α) (F G : β → α → β)
    (h : ∀ acc x, x ∈ l → F acc x = G acc x) : ∀ init, l.foldl F init = l.foldl G init := by
  induction l with
  | nil => intro _; rfl
  | cons x xs ih =>
    intro init
    simp only [List.foldl_cons]
    rw [h init x (List.mem_cons_self ..)]
    exact ih (fun acc y hy => h acc y (List.mem_cons_of_mem _ hy)) _

theorem lfoldr_congr {α β : Type} (l : List α) (F G : α → β → β) (init : β)
    (h : ∀ x acc, x ∈ l → F x acc = G x acc) : l.foldr F init = l.foldr G init := by
  induction l with
  | nil => rfl
  | cons x xs ih =>
    simp only [List.foldr_cons]
    rw [ih (fun y acc hy => h y acc (List.mem_cons_of_mem _ hy)), h x _ (List.mem_cons_self ..)]

/-- `lemListFoldr` (LemLib, array-backed) is `List.foldr` (LemLibTheorems). -/
theorem lemListFoldr_congr {α β : Type} (l : List α) (F G : α → β → β) (init : β)
    (h : ∀ x acc, x ∈ l → F x acc = G x acc) : lemListFoldr F init l = lemListFoldr G init l := by
  rw [LemLibTheorems.lemListFoldr_eq, LemLibTheorems.lemListFoldr_eq]
  exact lfoldr_congr l F G init h

/-- A member of `List.zip l1 l2` is a member of `l1` (first component). -/
theorem mem_zip_left {α β : Type} {x : α} {y : β} {l1 : List α} {l2 : List β}
    (h : (x, y) ∈ List.zip l1 l2) : x ∈ l1 := (List.of_mem_zip h).1

/-! ## Members are strictly below their list helper's size (Core block) -/

theorem expr_mem_lt_aux2 {a bty sym : Type} (e : generic_expr a bty sym)
    (l : List (generic_expr a bty sym)) (h : e ∈ l) :
    generic_expr.lemSize e < generic_expr_.lemSize_aux2 l := by
  induction l with
  | nil => cases h
  | cons y ys ih =>
    cases h with
    | head => simp only [generic_expr_.lemSize_aux2]; omega
    | tail _ h' => have := ih h'; simp only [generic_expr_.lemSize_aux2]; omega

theorem expr_mem_lt_aux1 {a bty sym : Type} (pat : generic_pattern sym) (e : generic_expr a bty sym)
    (l : List (generic_pattern sym × generic_expr a bty sym)) (h : (pat, e) ∈ l) :
    generic_expr.lemSize e < generic_expr_.lemSize_aux1 l := by
  induction l with
  | nil => cases h
  | cons y ys ih =>
    obtain ⟨p', e'⟩ := y
    cases h with
    | head => simp only [generic_expr_.lemSize_aux1]; omega
    | tail _ h' => have := ih h'; simp only [generic_expr_.lemSize_aux1]; omega

theorem pexpr_mem_lt_aux1 {bty sym : Type} (c : mem_iv_constraint) (pe : generic_pexpr bty sym)
    (l : List (mem_iv_constraint × generic_pexpr bty sym)) (h : (c, pe) ∈ l) :
    generic_pexpr.lemSize pe < generic_pexpr_.lemSize_aux1 l := by
  induction l with
  | nil => cases h
  | cons y ys ih =>
    obtain ⟨c', pe'⟩ := y
    cases h with
    | head => simp only [generic_pexpr_.lemSize_aux1]; omega
    | tail _ h' => have := ih h'; simp only [generic_pexpr_.lemSize_aux1]; omega

theorem pexpr_mem_lt_aux2 {bty sym : Type} (pe : generic_pexpr bty sym)
    (l : List (generic_pexpr bty sym)) (h : pe ∈ l) :
    generic_pexpr.lemSize pe < generic_pexpr_.lemSize_aux2 l := by
  induction l with
  | nil => cases h
  | cons y ys ih =>
    cases h with
    | head => simp only [generic_pexpr_.lemSize_aux2]; omega
    | tail _ h' => have := ih h'; simp only [generic_pexpr_.lemSize_aux2]; omega

theorem pexpr_mem_lt_aux3 {bty sym : Type} (pat : generic_pattern sym) (pe : generic_pexpr bty sym)
    (l : List (generic_pattern sym × generic_pexpr bty sym)) (h : (pat, pe) ∈ l) :
    generic_pexpr.lemSize pe < generic_pexpr_.lemSize_aux3 l := by
  induction l with
  | nil => cases h
  | cons y ys ih =>
    obtain ⟨p', pe'⟩ := y
    cases h with
    | head => simp only [generic_pexpr_.lemSize_aux3]; omega
    | tail _ h' => have := ih h'; simp only [generic_pexpr_.lemSize_aux3]; omega

theorem pexpr_mem_lt_aux4 {bty sym : Type} (id : identifier) (pe : generic_pexpr bty sym)
    (l : List (identifier × generic_pexpr bty sym)) (h : (id, pe) ∈ l) :
    generic_pexpr.lemSize pe < generic_pexpr_.lemSize_aux4 l := by
  induction l with
  | nil => cases h
  | cons y ys ih =>
    obtain ⟨i', pe'⟩ := y
    cases h with
    | head => simp only [generic_pexpr_.lemSize_aux4]; omega
    | tail _ h' => have := ih h'; simp only [generic_pexpr_.lemSize_aux4]; omega

theorem pattern_mem_lt_aux1 {sym : Type} (p : generic_pattern sym)
    (l : List (generic_pattern sym)) (h : p ∈ l) :
    generic_pattern.lemSize p < generic_pattern_.lemSize_aux1 l := by
  induction l with
  | nil => cases h
  | cons y ys ih =>
    cases h with
    | head => simp only [generic_pattern_.lemSize_aux1]; omega
    | tail _ h' => have := ih h'; simp only [generic_pattern_.lemSize_aux1]; omega

/-! ## Defacto_memory_types: a list of integer values -/

theorem ival_mem_lt_aux2 (iv : integer_value_base) (l : List integer_value_base) (h : iv ∈ l) :
    integer_value_base.lemSize iv < impl_pointer_value.lemSize_aux2 l := by
  induction l with
  | nil => cases h
  | cons y ys ih =>
    cases h with
    | head => simp only [impl_pointer_value.lemSize_aux2]; omega
    | tail _ h' => have := ih h'; simp only [impl_pointer_value.lemSize_aux2]; omega

/-! ## CerbMem.memValueSize -/

theorem memValue_mem_lt_list (v : CerbMem.MemValue) (l : List CerbMem.MemValue) (h : v ∈ l) :
    CerbMem.memValueSize v < CerbMem.memValueListSize l := by
  induction l with
  | nil => cases h
  | cons y ys ih =>
    cases h with
    | head => simp only [CerbMem.memValueListSize]; omega
    | tail _ h' => have := ih h'; simp only [CerbMem.memValueListSize]; omega

/-! ## Positivity: every constructor counts at least 1 -/

theorem expr_lemSize_pos {a bty sym : Type} (e : generic_expr a bty sym) : 1 ≤ generic_expr.lemSize e := by
  cases e; simp only [generic_expr.lemSize]; omega

theorem pexpr_lemSize_pos {bty sym : Type} (pe : generic_pexpr bty sym) : 1 ≤ generic_pexpr.lemSize pe := by
  cases pe; simp only [generic_pexpr.lemSize]; omega

theorem pattern_lemSize_pos {sym : Type} (p : generic_pattern sym) : 1 ≤ generic_pattern.lemSize p := by
  cases p; simp only [generic_pattern.lemSize]; omega

theorem ival_lemSize_pos (iv : integer_value_base) : 1 ≤ integer_value_base.lemSize iv := by
  cases iv <;> simp only [integer_value_base.lemSize] <;> omega

theorem ctype_lemSize_pos (c : ctype) : 1 ≤ ctype.lemSize c := by
  cases c; simp only [ctype.lemSize]; omega

theorem memValueSize_pos (v : CerbMem.MemValue) : 1 ≤ CerbMem.memValueSize v := by
  cases v <;> simp only [CerbMem.memValueSize] <;> omega

/-- `unatomic` (Ctype) strips one `Atomic` wrapper or is the identity: never larger. -/
theorem unatomic_size_le (c : ctype) : ctype.lemSize (unatomic c) ≤ ctype.lemSize c := by
  obtain ⟨an, t⟩ := c
  cases t <;> simp only [unatomic, ctype.lemSize, ctype_.lemSize] <;> omega

/-- A member of `List.map (fun pe => ((), pe)) pes` (the `wrap_list` shape of Core_eval) is a member of `pes`. -/
theorem mem_map_unit {α : Type} {x : Unit} {pe : α} {pes : List α}
    (h : (x, pe) ∈ List.map (fun pe => ((), pe)) pes) : pe ∈ pes := by
  induction pes with
  | nil => cases h
  | cons y ys ih =>
    simp only [List.map_cons, List.mem_cons] at h
    rcases h with h | h
    · cases h; exact List.mem_cons_self ..
    · exact List.mem_cons_of_mem _ (ih h)

/-! ## `to_congr`: descend to the list traversal whose per-member congruence is the goal

    After the `key` sweep the only differences left between the two sides of an
    arm are the recursive calls inside a `List.map`/`List.any`/`List.all`/
    `List.foldl`/`lemListFoldr`; `to_congr` applies the matching membership-
    relative congruence lemma as soon as the goal is such a traversal, and
    otherwise peels ONE congruence level (`congr 1`, `funext` on lambdas) and
    recurses — depth-agnostic, so it does not depend on which debug/unit
    matches `simp` has already reduced. -/
syntax "to_congr" : tactic
macro_rules
  | `(tactic| to_congr) => `(tactic| first
      | apply lmap_congr
      | apply lany_congr
      | apply lall_congr
      | apply lfoldl_congr
      | apply lemListFoldr_congr
      | (congr 1 <;> to_congr))

/-! ## The discharger: unfold the derived sizes (goal and hypotheses), then `omega` -/

macro "size_lt" : tactic => `(tactic| (
  (try simp only [generic_expr.lemSize, generic_expr_.lemSize, generic_expr_.lemSize_aux1,
    generic_expr_.lemSize_aux2, generic_pexpr.lemSize, generic_pexpr_.lemSize,
    generic_pexpr_.lemSize_aux1, generic_pexpr_.lemSize_aux2, generic_pexpr_.lemSize_aux3,
    generic_pexpr_.lemSize_aux4, generic_pattern.lemSize, generic_pattern_.lemSize,
    generic_pattern_.lemSize_aux1, integer_value_base.lemSize, bitwise_operation.lemSize,
    impl_pointer_value.lemSize_aux2, CerbMem.memValueSize, CerbMem.memValueListSize,
    CerbMem.memValueMembersSize, ctype.lemSize, ctype_.lemSize, List.length_cons, List.length_nil] at *);
  omega))

end CerbMeasureLemmas
