/-
  Core_reduction_lemMeasureProofs — the hand-written proof of the `fuel_measure`
  obligation lem emits into Core_reduction_auxiliary.lean (fuel-parameter arc
  C2, 2026-09-04; `declare {lean} fuel_measure val has_ccall = `lemSize g`` in
  frontend/model/core_reduction.lem, Lean-only), extended at C3 (2026-09-05) with
  the three point-free `function` tails `one_step_unseq_aux`, `get_ctx`,
  `get_ctx_unseq_aux` (lem d4ba548's hoisted `lemTail`). Shape: the C2 template
  (Core_run_aux_lemMeasureProofs.lean) — strong induction on the derived
  expression size, `key` rewrites the direct children, `List.any` congruence
  for `Ecase`/`Eunseq`/`End`. Kernel-only tactics; no option bumps.

  MIRROR-OCAML NOTE: proofs about the Lean total workers; no OCaml text
  corresponds (fuel is a Lean-target artifact).
-/

import Core_reduction
import CerbMeasureLemmas

set_option autoImplicit false

open CerbMeasureLemmas

namespace Core_reduction_lemMeasureProofs

theorem has_ccall_stable_aux {a : Type} {b : Type} {c : Type} (k : Nat) : ∀ (e : generic_expr c b a) (f g : Nat),
    generic_expr.lemSize e ≤ k → generic_expr.lemSize e ≤ f → generic_expr.lemSize e ≤ g →
    has_ccall_lemFuel f e = has_ccall_lemFuel g e := by
  induction k with
  | zero => intro e f g hk _ _; have := expr_lemSize_pos e; omega
  | succ k ih =>
    intro e f g hk hf hg
    cases f with
    | zero => have := expr_lemSize_pos e; omega
    | succ f =>
      cases g with
      | zero => have := expr_lemSize_pos e; omega
      | succ g =>
        have key : ∀ (y : generic_expr c b a), generic_expr.lemSize y < generic_expr.lemSize e →
            has_ccall_lemFuel f y = has_ccall_lemFuel g y :=
          fun y hy => ih y f g (by omega) (by omega) (by omega)
        obtain ⟨annot1, e_⟩ := e
        cases e_ <;> simp (disch := size_lt) only [has_ccall_lemFuel, key]
        case Ecase pe xs =>
          apply lany_congr; intro p hp; obtain ⟨x1, e⟩ := p
          dsimp only
          rw [key e (by have := expr_mem_lt_aux1 x1 e _ hp; size_lt)]
        case Eunseq es =>
          apply lany_congr; intro e he
          exact key e (by have := expr_mem_lt_aux2 e _ he; size_lt)
        case End es =>
          apply lany_congr; intro e he
          exact key e (by have := expr_mem_lt_aux2 e _ he; size_lt)

/-- THE OBLIGATION, exactly as the generated auxiliary module states and delegates it. -/
theorem has_ccall_measure_sufficient {a : Type} {b : Type} {c : Type} (g : generic_expr c b a) (lemFuel : Nat)
    (lemMeasureLe : generic_expr.lemSize g ≤ lemFuel) :
    has_ccall_lemFuel lemFuel g = has_ccall g :=
  has_ccall_stable_aux (generic_expr.lemSize g) g lemFuel (generic_expr.lemSize g) (Nat.le_refl _) lemMeasureLe (Nat.le_refl _)

/-! ## The point-free `function` tails (fuel-parameter arc C3, 2026-09-05)

    lem d4ba548 hoists the `function` scrutinee of a measured definition into the
    head as `lemTail`, so the three rows below carry a `fuel_measure`:
    `one_step_unseq_aux` = `List.length lemTail + 1` (self-recursion on the tail only);
    `get_ctx` = `lemSize g + 1` and `get_ctx_unseq_aux` =
    `generic_expr_.lemSize_aux2 lemTail + 1` — a mutual block over ONE fuel counter,
    proved by one joint statement: `get_ctx` descends into a strict subexpression or
    hands the `Eunseq` operand list to the aux at fuel − 1; the aux recurses into
    `get_ctx` on the head element and into itself on the rest, both at fuel − 1 — the
    list's derived size (`1 + lemSize e + …` per element) pays for both hops. -/

/-- `one_step_unseq_aux (fps_acc, cvals_acc) = function …`: stable above the length of
    the hoisted list. The nested list-head patterns are opened by `split`, whose
    generalized discriminant equation is closed by `cases`. -/
theorem one_step_unseq_aux_stable {a b : Type} (l : List (generic_expr b a sym)) :
    ∀ (p : List dyn_annotation × List value) (f g : Nat),
    List.length l + 1 ≤ f → List.length l + 1 ≤ g →
    one_step_unseq_aux_lemFuel f p l = one_step_unseq_aux_lemFuel g p l := by
  induction l with
  | nil =>
    intro p f g hf hg
    cases f with
    | zero => omega
    | succ f =>
      cases g with
      | zero => omega
      | succ g => obtain ⟨fps, cvals⟩ := p; simp only [one_step_unseq_aux_lemFuel]
  | cons x xs ih =>
    intro p f g hf hg
    cases f with
    | zero => omega
    | succ f =>
      cases g with
      | zero => omega
      | succ g =>
        obtain ⟨fps, cvals⟩ := p
        simp only [List.length_cons] at hf hg
        have key : ∀ q, one_step_unseq_aux_lemFuel f q xs = one_step_unseq_aux_lemFuel g q xs :=
          fun q => ih q f g (by omega) (by omega)
        simp only [one_step_unseq_aux_lemFuel]
        split <;> rename_i heq <;> cases heq <;> first | rfl | simp only [key]

/-- THE OBLIGATION, exactly as the generated auxiliary module states and delegates it. -/
theorem one_step_unseq_aux_measure_sufficient {a b : Type} (p : List dyn_annotation × List value)
    (lemTail : List (generic_expr b a sym)) (lemFuel : Nat)
    (lemMeasureLe : List.length lemTail + 1 ≤ lemFuel) :
    one_step_unseq_aux_lemFuel lemFuel p lemTail = one_step_unseq_aux p lemTail :=
  one_step_unseq_aux_stable lemTail p lemFuel (List.length lemTail + 1) lemMeasureLe (Nat.le_refl _)

/-- The joint stability lemma for the `get_ctx`/`get_ctx_unseq_aux` block: above each
    member's measure, any two fuels agree. -/
theorem get_ctx_stable_aux (k : Nat) :
    (∀ (e : generic_expr core_run_annotation Unit sym) (f g : Nat),
      generic_expr.lemSize e + 1 ≤ k → generic_expr.lemSize e + 1 ≤ f → generic_expr.lemSize e + 1 ≤ g →
      get_ctx_lemFuel f e = get_ctx_lemFuel g e) ∧
    (∀ (annot1 : List annot) (acc : List (context × generic_expr core_run_annotation Unit sym))
      (es1 l : List (generic_expr core_run_annotation Unit sym)) (f g : Nat),
      generic_expr_.lemSize_aux2 l + 1 ≤ k → generic_expr_.lemSize_aux2 l + 1 ≤ f →
      generic_expr_.lemSize_aux2 l + 1 ≤ g →
      get_ctx_unseq_aux_lemFuel f annot1 acc es1 l = get_ctx_unseq_aux_lemFuel g annot1 acc es1 l) := by
  induction k with
  | zero => exact ⟨fun _ _ _ hk _ _ => by omega, fun _ _ _ _ _ _ hk _ _ => by omega⟩
  | succ k ih =>
    obtain ⟨ih1, ih2⟩ := ih
    refine ⟨?_, ?_⟩
    -- get_ctx
    · intro e f g hk hf hg
      cases f with
      | zero => omega
      | succ f =>
        cases g with
        | zero => omega
        | succ g =>
          -- every cross-call strictly decreases the callee's measure below THIS entry's
          have key1 : ∀ (y : generic_expr core_run_annotation Unit sym),
              generic_expr.lemSize y + 1 < generic_expr.lemSize e + 1 →
              get_ctx_lemFuel f y = get_ctx_lemFuel g y :=
            fun y hy => ih1 y f g (by omega) (by omega) (by omega)
          have key2 : ∀ (annot1 : List annot) (acc : List (context × generic_expr core_run_annotation Unit sym))
              (es1 l : List (generic_expr core_run_annotation Unit sym)),
              generic_expr_.lemSize_aux2 l + 1 < generic_expr.lemSize e + 1 →
              get_ctx_unseq_aux_lemFuel f annot1 acc es1 l = get_ctx_unseq_aux_lemFuel g annot1 acc es1 l :=
            fun annot1 acc es1 l hl => ih2 annot1 acc es1 l f g (by omega) (by omega) (by omega)
          obtain ⟨annot1, e_⟩ := e
          cases e_ <;> simp (disch := size_lt) only [get_ctx_lemFuel, key1, key2]
          -- Eannot: the nested pattern `Eannot _ (Expr _ (Eannot _ e))` needs the inner expression opened
          case Eannot xs e =>
            obtain ⟨annot2, e2⟩ := e
            cases e2 <;> simp (disch := size_lt) only [key1]
    -- get_ctx_unseq_aux (the hoisted `lemTail` is the operand list)
    · intro annot1 acc es1 l f g hk hf hg
      cases f with
      | zero => omega
      | succ f =>
        cases g with
        | zero => omega
        | succ g =>
          -- every cross-call strictly decreases the callee's measure below THIS entry's
          have key1 : ∀ (y : generic_expr core_run_annotation Unit sym),
              generic_expr.lemSize y + 1 < generic_expr_.lemSize_aux2 l + 1 →
              get_ctx_lemFuel f y = get_ctx_lemFuel g y :=
            fun y hy => ih1 y f g (by omega) (by omega) (by omega)
          have key2 : ∀ (annot1' : List annot) (acc' : List (context × generic_expr core_run_annotation Unit sym))
              (es1' l' : List (generic_expr core_run_annotation Unit sym)),
              generic_expr_.lemSize_aux2 l' + 1 < generic_expr_.lemSize_aux2 l + 1 →
              get_ctx_unseq_aux_lemFuel f annot1' acc' es1' l' = get_ctx_unseq_aux_lemFuel g annot1' acc' es1' l' :=
            fun annot1' acc' es1' l' hl => ih2 annot1' acc' es1' l' f g (by omega) (by omega) (by omega)
          cases l with
          | nil => simp only [get_ctx_unseq_aux_lemFuel]
          | cons e es2 => simp (disch := size_lt) only [get_ctx_unseq_aux_lemFuel, key1, key2]

/-- THE OBLIGATION, exactly as the generated auxiliary module states and delegates it. -/
theorem get_ctx_measure_sufficient (g : generic_expr core_run_annotation Unit sym) (lemFuel : Nat)
    (lemMeasureLe : generic_expr.lemSize g + 1 ≤ lemFuel) :
    get_ctx_lemFuel lemFuel g = get_ctx g :=
  (get_ctx_stable_aux (generic_expr.lemSize g + 1)).1 g lemFuel (generic_expr.lemSize g + 1)
    (Nat.le_refl _) lemMeasureLe (Nat.le_refl _)

/-- THE OBLIGATION for the hoisted-tail member (`lemTail` = the `Eunseq` operand list). -/
theorem get_ctx_unseq_aux_measure_sufficient (annot1 : List annot)
    (acc : List (context × generic_expr core_run_annotation Unit sym))
    (es1 lemTail : List (generic_expr core_run_annotation Unit sym)) (lemFuel : Nat)
    (lemMeasureLe : generic_expr_.lemSize_aux2 lemTail + 1 ≤ lemFuel) :
    get_ctx_unseq_aux_lemFuel lemFuel annot1 acc es1 lemTail = get_ctx_unseq_aux annot1 acc es1 lemTail :=
  (get_ctx_stable_aux (generic_expr_.lemSize_aux2 lemTail + 1)).2 annot1 acc es1 lemTail lemFuel
    (generic_expr_.lemSize_aux2 lemTail + 1) (Nat.le_refl _) lemMeasureLe (Nat.le_refl _)

end Core_reduction_lemMeasureProofs
