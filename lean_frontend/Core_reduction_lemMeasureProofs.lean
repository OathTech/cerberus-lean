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

/-- The two kinds of calls in the context-search mutual block. -/
abbrev GetCtxState := Sum (generic_expr core_run_annotation Unit sym)
  (List (generic_expr core_run_annotation Unit sym))

/-- Possible recursive calls, conservatively ignoring irreducibility tests.
    Sequences search only their left operand; continuations and pure-expression
    payloads never cause a recursive call to either context-search worker. -/
def getCtxNext (y : GetCtxState) : List GetCtxState :=
  Sum.casesOn y
    (fun e => generic_expr.casesOn e (fun _ node =>
      generic_expr_.casesOn node
        (fun _ => [])                         -- Epure
        (fun _ _ => [])                       -- Ememop
        (fun _ => [])                         -- Eaction
        (fun _ _ => [])                       -- Ecase
        (fun _ _ _ => [])                     -- Elet
        (fun _ _ _ => [])                     -- Eif
        (fun _ _ _ _ => [])                   -- Eccall
        (fun _ _ _ => [])                     -- Eproc
        (fun es => [Sum.inr es])               -- Eunseq
        (fun _ e _ => [Sum.inl e])             -- Ewseq
        (fun _ e _ => [Sum.inl e])             -- Esseq
        (fun e => [Sum.inl e])                 -- Ebound
        (fun _ => [])                         -- End
        (fun _ _ _ => [])                     -- Esave
        (fun _ _ _ => [])                     -- Erun
        (fun _ => [])                         -- Epar
        (fun _ => [])                         -- Ewait
        (fun _ e => [Sum.inl e])               -- Eannot
        (fun _ _ => [])))                     -- Eexcluded
    (fun es => List.casesOn es [] (fun e es => [Sum.inl e, Sum.inr es]))

/-- Compute the call-depth bound directly. The unit increment pays for the
    current worker frame; every possible child receives a strictly lower bound.
    Unlike `getCtxNext`, this executable step allocates no child lists. -/
def getCtxStep (x : GetCtxState) : ((y : GetCtxState) → sizeOf y < sizeOf x → Nat) → Nat :=
  Sum.casesOn
    (motive := fun x => ((y : GetCtxState) → sizeOf y < sizeOf x → Nat) → Nat) x
    (fun e => generic_expr.casesOn
      (motive_2 := fun e => ((y : GetCtxState) → sizeOf y < sizeOf (Sum.inl e : GetCtxState) → Nat) → Nat) e
      (fun annot node => generic_expr_.casesOn
        (motive_1 := fun node => ((y : GetCtxState) →
          sizeOf y < sizeOf (Sum.inl (.Expr annot node) : GetCtxState) → Nat) → Nat) node
        (fun _ _ => 1)                     -- Epure
        (fun _ _ _ => 1)                   -- Ememop
        (fun _ _ => 1)                     -- Eaction
        (fun _ _ _ => 1)                   -- Ecase
        (fun _ _ _ _ => 1)                 -- Elet
        (fun _ _ _ _ => 1)                 -- Eif
        (fun _ _ _ _ _ => 1)               -- Eccall
        (fun _ _ _ _ => 1)                 -- Eproc
        (fun es rec => rec (.inr es) (by simp_wf; omega) + 1)       -- Eunseq
        (fun _ e _ rec => rec (.inl e) (by simp_wf; omega) + 1)      -- Ewseq
        (fun _ e _ rec => rec (.inl e) (by simp_wf; omega) + 1)      -- Esseq
        (fun e rec => rec (.inl e) (by simp_wf; omega) + 1)          -- Ebound
        (fun _ _ => 1)                     -- End
        (fun _ _ _ _ => 1)                 -- Esave
        (fun _ _ _ _ => 1)                 -- Erun
        (fun _ _ => 1)                     -- Epar
        (fun _ _ => 1)                     -- Ewait
        (fun _ e rec => rec (.inl e) (by simp_wf; omega) + 1)        -- Eannot
        (fun _ _ _ => 1)))                 -- Eexcluded
    (fun es => List.casesOn
      (motive := fun es => ((y : GetCtxState) → sizeOf y < sizeOf (Sum.inr es : GetCtxState) → Nat) → Nat) es
      (fun _ => 1)
      (fun e es rec => max (rec (.inl e) (by simp_wf; omega))
        (rec (.inr es) (by simp_wf; omega)) + 1))

def getCtxBound (x : GetCtxState) : Nat := CerbTagsWf.callBoundEntry sizeOf getCtxStep x

theorem getCtxBound_eq_step (x : GetCtxState) :
    getCtxBound x = getCtxStep x (fun y _ => getCtxBound y) := by
  change getCtxStep x (fun y _ => CerbTagsWf.callBound sizeOf getCtxStep y) = _
  apply congrArg (getCtxStep x)
  funext y hy
  exact (CerbTagsWf.callBoundEntry_eq sizeOf getCtxStep y).symm

theorem getCtxBound_pos (x : GetCtxState) : 0 < getCtxBound x := by
  rw [getCtxBound_eq_step]
  cases x with
  | inl e =>
    obtain ⟨annot, node⟩ := e
    cases node <;> simp only [getCtxStep] <;> omega
  | inr es =>
    cases es <;> simp only [getCtxStep] <;> omega

theorem getCtxBound_child_lt (x y : GetCtxState) (h : y ∈ getCtxNext x) :
    getCtxBound y < getCtxBound x := by
  rw [getCtxBound_eq_step x]
  cases x with
  | inl e =>
    obtain ⟨annot, node⟩ := e
    cases node <;> simp only [getCtxNext, List.mem_singleton, List.not_mem_nil] at h
    all_goals first | contradiction | (subst y; simp only [getCtxStep]; omega)
  | inr es =>
    cases es with
    | nil => simp [getCtxNext] at h
    | cons e es =>
      simp only [getCtxNext, List.mem_cons, List.not_mem_nil, or_false] at h
      rcases h with h | h <;> subst y <;> simp only [getCtxStep] <;> omega

/-- Joint fuel stability for the narrower call-depth measure. -/
theorem get_ctx_search_stable_aux (k : Nat) :
    (∀ (e : generic_expr core_run_annotation Unit sym) (f g : Nat),
      getCtxBound (.inl e) ≤ k → getCtxBound (.inl e) ≤ f → getCtxBound (.inl e) ≤ g →
      get_ctx_lemFuel f e = get_ctx_lemFuel g e) ∧
    (∀ (annot1 : List annot) (acc : List (context × generic_expr core_run_annotation Unit sym))
      (es1 l : List (generic_expr core_run_annotation Unit sym)) (f g : Nat),
      getCtxBound (.inr l) ≤ k → getCtxBound (.inr l) ≤ f →
      getCtxBound (.inr l) ≤ g →
      get_ctx_unseq_aux_lemFuel f annot1 acc es1 l = get_ctx_unseq_aux_lemFuel g annot1 acc es1 l) := by
  have pos : ∀ x : GetCtxState, 0 < getCtxBound x := getCtxBound_pos
  induction k with
  | zero => exact ⟨fun e _ _ hk _ _ => by have := pos (.inl e); omega, fun _ _ _ l _ _ hk _ _ => by have := pos (.inr l); omega⟩
  | succ k ih =>
    obtain ⟨ih1, ih2⟩ := ih
    refine ⟨?_, ?_⟩
    -- get_ctx
    · intro e f g hk hf hg
      have hp := pos (.inl e)
      cases f with
      | zero => omega
      | succ f =>
        cases g with
        | zero => omega
        | succ g =>
          -- every cross-call strictly decreases the callee's measure below THIS entry's
          have key1 : ∀ (y : generic_expr core_run_annotation Unit sym),
              getCtxBound (.inl y) < getCtxBound (.inl e) →
              get_ctx_lemFuel f y = get_ctx_lemFuel g y :=
            fun y hy => ih1 y f g (by omega) (by omega) (by omega)
          have key2 : ∀ (annot1 : List annot) (acc : List (context × generic_expr core_run_annotation Unit sym))
              (es1 l : List (generic_expr core_run_annotation Unit sym)),
              getCtxBound (.inr l) < getCtxBound (.inl e) →
              get_ctx_unseq_aux_lemFuel f annot1 acc es1 l = get_ctx_unseq_aux_lemFuel g annot1 acc es1 l :=
            fun annot1 acc es1 l hl => ih2 annot1 acc es1 l f g (by omega) (by omega) (by omega)
          obtain ⟨annot1, e_⟩ := e
          cases e_ <;> simp (disch := (apply getCtxBound_child_lt; simp [getCtxNext])) only [get_ctx_lemFuel, key1, key2]
          -- Eannot: the nested pattern `Eannot _ (Expr _ (Eannot _ e))` needs the inner expression opened
          case Eannot xs e =>
            obtain ⟨annot2, e2⟩ := e
            cases e2 <;> simp (disch := (apply getCtxBound_child_lt; simp [getCtxNext])) only [key1]
    -- get_ctx_unseq_aux (the hoisted `lemTail` is the operand list)
    · intro annot1 acc es1 l f g hk hf hg
      have hp := pos (.inr l)
      cases f with
      | zero => omega
      | succ f =>
        cases g with
        | zero => omega
        | succ g =>
          -- every cross-call strictly decreases the callee's measure below THIS entry's
          have key1 : ∀ (y : generic_expr core_run_annotation Unit sym),
              getCtxBound (.inl y) < getCtxBound (.inr l) →
              get_ctx_lemFuel f y = get_ctx_lemFuel g y :=
            fun y hy => ih1 y f g (by omega) (by omega) (by omega)
          have key2 : ∀ (annot1' : List annot) (acc' : List (context × generic_expr core_run_annotation Unit sym))
              (es1' l' : List (generic_expr core_run_annotation Unit sym)),
              getCtxBound (.inr l') < getCtxBound (.inr l) →
              get_ctx_unseq_aux_lemFuel f annot1' acc' es1' l' = get_ctx_unseq_aux_lemFuel g annot1' acc' es1' l' :=
            fun annot1' acc' es1' l' hl => ih2 annot1' acc' es1' l' f g (by omega) (by omega) (by omega)
          cases l with
          | nil => simp only [get_ctx_unseq_aux_lemFuel]
          | cons e es2 => simp (disch := (apply getCtxBound_child_lt; simp [getCtxNext])) only [get_ctx_unseq_aux_lemFuel, key1, key2]


/-- THE OBLIGATION, exactly as the generated auxiliary module states and delegates it. -/
theorem get_ctx_measure_sufficient (g : generic_expr core_run_annotation Unit sym) (lemFuel : Nat)
    (lemMeasureLe : getCtxBound (.inl g) ≤ lemFuel) :
    get_ctx_lemFuel lemFuel g = get_ctx g :=
  (get_ctx_search_stable_aux (getCtxBound (.inl g))).1 g lemFuel (getCtxBound (.inl g))
    (Nat.le_refl _) lemMeasureLe (Nat.le_refl _)

/-- THE OBLIGATION for the hoisted-tail member (`lemTail` = the `Eunseq` operand list). -/
theorem get_ctx_unseq_aux_measure_sufficient (annot1 : List annot)
    (acc : List (context × generic_expr core_run_annotation Unit sym))
    (es1 lemTail : List (generic_expr core_run_annotation Unit sym)) (lemFuel : Nat)
    (lemMeasureLe : getCtxBound (.inr lemTail) ≤ lemFuel) :
    get_ctx_unseq_aux_lemFuel lemFuel annot1 acc es1 lemTail = get_ctx_unseq_aux annot1 acc es1 lemTail :=
  (get_ctx_search_stable_aux (getCtxBound (.inr lemTail))).2 annot1 acc es1 lemTail lemFuel
    (getCtxBound (.inr lemTail)) (Nat.le_refl _) lemMeasureLe (Nat.le_refl _)

/-- The previous expression-size measure and the new wrapper return the
    same result on every input, via a common sufficient fuel. -/
theorem get_ctx_previous_measure_eq (e : generic_expr core_run_annotation Unit sym) :
    get_ctx_lemFuel (generic_expr.lemSize e + 1) e = get_ctx e := by
  let f := max (generic_expr.lemSize e + 1) (getCtxBound (.inl e))
  calc
    _ = get_ctx_lemFuel f e :=
      (get_ctx_stable_aux (generic_expr.lemSize e + 1)).1 e _ f
        (Nat.le_refl _) (Nat.le_refl _) (Nat.le_max_left ..)
    _ = _ := get_ctx_measure_sufficient e f (Nat.le_max_right ..)

/-- The same equivalence for the operand-list entry point. -/
theorem get_ctx_unseq_aux_previous_measure_eq (annot1 : List annot)
    (acc : List (context × generic_expr core_run_annotation Unit sym))
    (es1 l : List (generic_expr core_run_annotation Unit sym)) :
    get_ctx_unseq_aux_lemFuel (generic_expr_.lemSize_aux2 l + 1) annot1 acc es1 l =
      get_ctx_unseq_aux annot1 acc es1 l := by
  let f := max (generic_expr_.lemSize_aux2 l + 1) (getCtxBound (.inr l))
  calc
    _ = get_ctx_unseq_aux_lemFuel f annot1 acc es1 l :=
      (get_ctx_stable_aux (generic_expr_.lemSize_aux2 l + 1)).2 annot1 acc es1 l _ f
        (Nat.le_refl _) (Nat.le_refl _) (Nat.le_max_left ..)
    _ = _ := get_ctx_unseq_aux_measure_sufficient annot1 acc es1 l f (Nat.le_max_right ..)

end Core_reduction_lemMeasureProofs
