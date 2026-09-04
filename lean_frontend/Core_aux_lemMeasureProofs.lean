/-
  Core_aux_lemMeasureProofs — the hand-written proofs of the `fuel_measure`
  obligations lem emits into Core_aux_auxiliary.lean (fuel-parameter arc C2,
  2026-09-04; frontend/model/core_aux.lem, Lean-only). Every measure is the
  derived structural size of the argument the recursion descends:

    pattern-recursive  (generic_pattern.lemSize g):  in_pattern, subst_pattern_val,
                       unsafe_subst_pattern, subst_pattern, match_pattern, update_env_aux
    pexpr-recursive    (generic_pexpr.lemSize g / g0): subst_sym_pexpr, unsafe_subst_sym_pexpr
    expr-recursive     (generic_expr.lemSize g):  subst_wait, find_labeled_continuation2_aux,
                       subst_sym_expr, unsafe_subst_sym_expr, collect_saves_aux,
                       m_collect_saves_aux, find_labeled_continuation
    loadedValueFromMemValue  (CerbMem.memValueSize mem_val — the hand-written MemValue's size)
    memValueFromValue        (ctype.lemSize ty1 — the recursion descends `unatomic ty1`,
                              never larger: CerbMeasureLemmas.unatomic_size_le)

  NOT here (ambient, pending — C2 record): to_pure/to_pures, whose recursion
  descends into `subst_pattern`'s RESULT; its ill-typed arms are an opaque
  `failwithI` value, so no size bound on that result is provable.

  Shape = the C2 template: strong induction on the size bound; at
  `Nat.succ f`/`Nat.succ g` the body is unfolded and every recursive call on a
  strict sub-term is rewritten by `key` (a `simp` rewrite whose side condition
  the `size_lt` discharger proves); the multi-discriminant matches of the
  pattern family are opened by `split`; the list traversals by
  membership-relative congruence with the derived helpers' member bounds
  (CerbMeasureLemmas). Kernel-only tactics; no option bumps.

  MIRROR-OCAML NOTE: proofs about the Lean total workers; no OCaml text
  corresponds (fuel is a Lean-target artifact).
-/

import Core_aux
import CerbMeasureLemmas

set_option autoImplicit false

open CerbMeasureLemmas

namespace Core_aux_lemMeasureProofs

theorem in_pattern_stable_aux (k : Nat) : ∀ (sym1 : sym) (e : generic_pattern sym) (f g : Nat),
    generic_pattern.lemSize e ≤ k → generic_pattern.lemSize e ≤ f → generic_pattern.lemSize e ≤ g →
    in_pattern_lemFuel f sym1 e = in_pattern_lemFuel g sym1 e := by
  induction k with
  | zero => intro sym1 e f g hk _ _; have := pattern_lemSize_pos e; omega
  | succ k ih =>
    intro sym1 e f g hk hf hg
    cases f with
    | zero => have := pattern_lemSize_pos e; omega
    | succ f =>
      cases g with
      | zero => have := pattern_lemSize_pos e; omega
      | succ g =>
        have key : ∀ (sym1' : sym) (y : generic_pattern sym), generic_pattern.lemSize y < generic_pattern.lemSize e →
            in_pattern_lemFuel f sym1' y = in_pattern_lemFuel g sym1' y :=
          fun sym1' y hy => ih sym1' y f g (by omega) (by omega) (by omega)
        obtain ⟨an, pat⟩ := e
        cases pat with
        | CaseBase sb => obtain ⟨so, bt⟩ := sb; simp only [in_pattern_lemFuel]
        | CaseCtor c pats =>
          simp only [in_pattern_lemFuel]
          apply lany_congr; intro p hp
          exact key sym1 p (by have := pattern_mem_lt_aux1 p _ hp; size_lt)

/-- THE OBLIGATION, exactly as the generated auxiliary module states and delegates it. -/
theorem in_pattern_measure_sufficient (sym1 : sym) (g : generic_pattern sym) (lemFuel : Nat)
    (lemMeasureLe : generic_pattern.lemSize g ≤ lemFuel) :
    in_pattern_lemFuel lemFuel sym1 g = in_pattern sym1 g :=
  in_pattern_stable_aux (generic_pattern.lemSize g) sym1 g lemFuel (generic_pattern.lemSize g) (Nat.le_refl _) lemMeasureLe (Nat.le_refl _)

theorem subst_wait_stable_aux {a : Type} (k : Nat) : ∀ (tid1 : Nat) (v : value) (e : generic_expr a Unit sym) (f g : Nat),
    generic_expr.lemSize e ≤ k → generic_expr.lemSize e ≤ f → generic_expr.lemSize e ≤ g →
    subst_wait_lemFuel f tid1 v e = subst_wait_lemFuel g tid1 v e := by
  induction k with
  | zero => intro tid1 v e f g hk _ _; have := expr_lemSize_pos e; omega
  | succ k ih =>
    intro tid1 v e f g hk hf hg
    cases f with
    | zero => have := expr_lemSize_pos e; omega
    | succ f =>
      cases g with
      | zero => have := expr_lemSize_pos e; omega
      | succ g =>
        have key : ∀ (tid1' : Nat) (v' : value) (y : generic_expr a Unit sym), generic_expr.lemSize y < generic_expr.lemSize e →
            subst_wait_lemFuel f tid1' v' y = subst_wait_lemFuel g tid1' v' y :=
          fun tid1' v' y hy => ih tid1' v' y f g (by omega) (by omega) (by omega)
        obtain ⟨annot1, e_⟩ := e
        cases e_ <;> simp (disch := size_lt) only [subst_wait_lemFuel, key]
        case Ecase pe pat_es =>
          to_congr; intro p hp; obtain ⟨x1, e⟩ := p
          dsimp only
          rw [key tid1 v e (by have := expr_mem_lt_aux1 x1 e _ hp; size_lt)]
        case Eunseq es =>
          to_congr; intro e he
          exact key tid1 v e (by have := expr_mem_lt_aux2 e _ he; size_lt)
        case End es =>
          to_congr; intro e he
          exact key tid1 v e (by have := expr_mem_lt_aux2 e _ he; size_lt)
        case Epar es =>
          to_congr; intro e he
          exact key tid1 v e (by have := expr_mem_lt_aux2 e _ he; size_lt)

/-- THE OBLIGATION, exactly as the generated auxiliary module states and delegates it. -/
theorem subst_wait_measure_sufficient {a : Type} (tid1 : Nat) (v : value) (g : generic_expr a Unit sym) (lemFuel : Nat)
    (lemMeasureLe : generic_expr.lemSize g ≤ lemFuel) :
    subst_wait_lemFuel lemFuel tid1 v g = subst_wait tid1 v g :=
  subst_wait_stable_aux (generic_expr.lemSize g) tid1 v g lemFuel (generic_expr.lemSize g) (Nat.le_refl _) lemMeasureLe (Nat.le_refl _)

theorem find_labeled_continuation2_aux_stable_aux {a : Type} (k : Nat) : ∀ (acc : Fmap sym (List sym × generic_expr a Unit sym)) (sym1 : sym) (e : generic_expr a Unit sym) (f g : Nat),
    generic_expr.lemSize e ≤ k → generic_expr.lemSize e ≤ f → generic_expr.lemSize e ≤ g →
    find_labeled_continuation2_aux_lemFuel f acc sym1 e = find_labeled_continuation2_aux_lemFuel g acc sym1 e := by
  induction k with
  | zero => intro acc sym1 e f g hk _ _; have := expr_lemSize_pos e; omega
  | succ k ih =>
    intro acc sym1 e f g hk hf hg
    cases f with
    | zero => have := expr_lemSize_pos e; omega
    | succ f =>
      cases g with
      | zero => have := expr_lemSize_pos e; omega
      | succ g =>
        have key : ∀ (acc' : Fmap sym (List sym × generic_expr a Unit sym)) (sym1' : sym) (y : generic_expr a Unit sym), generic_expr.lemSize y < generic_expr.lemSize e →
            find_labeled_continuation2_aux_lemFuel f acc' sym1' y = find_labeled_continuation2_aux_lemFuel g acc' sym1' y :=
          fun acc' sym1' y hy => ih acc' sym1' y f g (by omega) (by omega) (by omega)
        obtain ⟨annot1, e_⟩ := e
        cases e_ <;> simp (disch := size_lt) only [find_labeled_continuation2_aux_lemFuel, key]
        case Ecase pe pat_es =>
          to_congr
          intro acc' p hp
          obtain ⟨x1, e⟩ := p; dsimp only
          rw [key acc' sym1 e (by have := expr_mem_lt_aux1 x1 e _ hp; size_lt)]

/-- THE OBLIGATION, exactly as the generated auxiliary module states and delegates it. -/
theorem find_labeled_continuation2_aux_measure_sufficient {a : Type} (acc : Fmap sym (List sym × generic_expr a Unit sym)) (sym1 : sym) (g : generic_expr a Unit sym) (lemFuel : Nat)
    (lemMeasureLe : generic_expr.lemSize g ≤ lemFuel) :
    find_labeled_continuation2_aux_lemFuel lemFuel acc sym1 g = find_labeled_continuation2_aux acc sym1 g :=
  find_labeled_continuation2_aux_stable_aux (generic_expr.lemSize g) acc sym1 g lemFuel (generic_expr.lemSize g) (Nat.le_refl _) lemMeasureLe (Nat.le_refl _)

theorem loadedValueFromMemValue_stable_aux (k : Nat) : ∀ (e : CerbMem.MemValue) (f g : Nat),
    CerbMem.memValueSize e ≤ k → CerbMem.memValueSize e ≤ f → CerbMem.memValueSize e ≤ g →
    loadedValueFromMemValue_lemFuel f e = loadedValueFromMemValue_lemFuel g e := by
  induction k with
  | zero => intro e f g hk _ _; have := memValueSize_pos e; omega
  | succ k ih =>
    intro e f g hk hf hg
    cases f with
    | zero => have := memValueSize_pos e; omega
    | succ f =>
      cases g with
      | zero => have := memValueSize_pos e; omega
      | succ g =>
        have key : ∀ (y : CerbMem.MemValue), CerbMem.memValueSize y < CerbMem.memValueSize e →
            loadedValueFromMemValue_lemFuel f y = loadedValueFromMemValue_lemFuel g y :=
          fun y hy => ih y f g (by omega) (by omega) (by omega)
        cases e <;> simp (disch := size_lt) only [loadedValueFromMemValue_lemFuel, CerbMem.caseMemValue, key]
        case MVarray vals =>
          rw [lmap_congr vals _ _ (fun v hv => key v (by have := memValue_mem_lt_list v _ hv; size_lt))]

/-- THE OBLIGATION, exactly as the generated auxiliary module states and delegates it. -/
theorem loadedValueFromMemValue_measure_sufficient (mem_val : CerbMem.MemValue) (lemFuel : Nat)
    (lemMeasureLe : CerbMem.memValueSize mem_val ≤ lemFuel) :
    loadedValueFromMemValue_lemFuel lemFuel mem_val = loadedValueFromMemValue mem_val :=
  loadedValueFromMemValue_stable_aux (CerbMem.memValueSize mem_val) mem_val lemFuel (CerbMem.memValueSize mem_val) (Nat.le_refl _) lemMeasureLe (Nat.le_refl _)

theorem memValueFromValue_stable_aux [LemFuel] (k : Nat) :
    ∀ (td : Fmap sym (CerbLocation.Loc × tag_definition)) (ty1 : ctype) (cval : value) (f g : Nat),
    ctype.lemSize ty1 ≤ k → ctype.lemSize ty1 ≤ f → ctype.lemSize ty1 ≤ g →
    memValueFromValue_lemFuel f td ty1 cval = memValueFromValue_lemFuel g td ty1 cval := by
  induction k with
  | zero => intro td ty1 cval f g hk _ _; have := ctype_lemSize_pos ty1; omega
  | succ k ih =>
    intro td ty1 cval f g hk hf hg
    cases f with
    | zero => have := ctype_lemSize_pos ty1; omega
    | succ f =>
      cases g with
      | zero => have := ctype_lemSize_pos ty1; omega
      | succ g =>
        have key : ∀ (cv : value) (y : ctype), ctype.lemSize y < ctype.lemSize ty1 →
            memValueFromValue_lemFuel f td y cv = memValueFromValue_lemFuel g td y cv :=
          fun cv y hy => ih td y cv f g (by omega) (by omega) (by omega)
        have hsz := unatomic_size_le ty1
        rcases hu : unatomic ty1 with ⟨annots1, ty_⟩
        rw [hu] at hsz
        simp only [memValueFromValue_lemFuel, hu]
        split <;> (try simp (disch := size_lt) only [key])

/-- THE OBLIGATION, exactly as Core_aux_auxiliary.lean states and delegates it. -/
theorem memValueFromValue_measure_sufficient [LemFuel] (_lemReader_tagDefs : Fmap sym (CerbLocation.Loc × tag_definition))
    (ty1 : ctype) (cval : value) (lemFuel : Nat) (lemMeasureLe : ctype.lemSize ty1 ≤ lemFuel) :
    memValueFromValue_lemFuel lemFuel _lemReader_tagDefs ty1 cval = memValueFromValue _lemReader_tagDefs ty1 cval :=
  memValueFromValue_stable_aux (ctype.lemSize ty1) _lemReader_tagDefs ty1 cval lemFuel (ctype.lemSize ty1)
    (Nat.le_refl _) lemMeasureLe (Nat.le_refl _)

theorem subst_sym_pexpr_stable_aux (k : Nat) : ∀ (sym1 : sym) (cval : value) (e : generic_pexpr Unit sym) (f g : Nat),
    generic_pexpr.lemSize e ≤ k → generic_pexpr.lemSize e ≤ f → generic_pexpr.lemSize e ≤ g →
    subst_sym_pexpr_lemFuel f sym1 cval e = subst_sym_pexpr_lemFuel g sym1 cval e := by
  induction k with
  | zero => intro sym1 cval e f g hk _ _; have := pexpr_lemSize_pos e; omega
  | succ k ih =>
    intro sym1 cval e f g hk hf hg
    cases f with
    | zero => have := pexpr_lemSize_pos e; omega
    | succ f =>
      cases g with
      | zero => have := pexpr_lemSize_pos e; omega
      | succ g =>
        have key : ∀ (sym1' : sym) (cval' : value) (y : generic_pexpr Unit sym), generic_pexpr.lemSize y < generic_pexpr.lemSize e →
            subst_sym_pexpr_lemFuel f sym1' cval' y = subst_sym_pexpr_lemFuel g sym1' cval' y :=
          fun sym1' cval' y hy => ih sym1' cval' y f g (by omega) (by omega) (by omega)
        obtain ⟨annot1, bty, pexpr_⟩ := e
        cases pexpr_ <;> simp (disch := size_lt) only [subst_sym_pexpr_lemFuel, key]
        case PEconstrained xs =>
          to_congr; intro p hp; obtain ⟨x1, e⟩ := p
          dsimp only
          rw [key sym1 cval e (by have := pexpr_mem_lt_aux1 x1 e _ hp; size_lt)]
        case PEctor ctor1 pes =>
          to_congr; intro e he
          exact key sym1 cval e (by have := pexpr_mem_lt_aux2 e _ he; size_lt)
        case PEcase pe xs =>
          to_congr; intro p hp; obtain ⟨x1, e⟩ := p
          dsimp only
          rw [key sym1 cval e (by have := pexpr_mem_lt_aux3 x1 e _ hp; size_lt)]
        case PEmemop mop pes =>
          to_congr; intro e he
          exact key sym1 cval e (by have := pexpr_mem_lt_aux2 e _ he; size_lt)
        case PEstruct tag xs =>
          to_congr; intro p hp; obtain ⟨x1, e⟩ := p
          dsimp only
          rw [key sym1 cval e (by have := pexpr_mem_lt_aux4 x1 e _ hp; size_lt)]
        case PEcall nm pes =>
          to_congr; intro e he
          exact key sym1 cval e (by have := pexpr_mem_lt_aux2 e _ he; size_lt)

/-- THE OBLIGATION, exactly as the generated auxiliary module states and delegates it. -/
theorem subst_sym_pexpr_measure_sufficient (sym1 : sym) (cval : value) (g : generic_pexpr Unit sym) (lemFuel : Nat)
    (lemMeasureLe : generic_pexpr.lemSize g ≤ lemFuel) :
    subst_sym_pexpr_lemFuel lemFuel sym1 cval g = subst_sym_pexpr sym1 cval g :=
  subst_sym_pexpr_stable_aux (generic_pexpr.lemSize g) sym1 cval g lemFuel (generic_pexpr.lemSize g) (Nat.le_refl _) lemMeasureLe (Nat.le_refl _)

theorem subst_sym_expr_stable_aux {a : Type} (k : Nat) : ∀ (sym1 : sym) (cval : value) (e : generic_expr a Unit sym) (f g : Nat),
    generic_expr.lemSize e ≤ k → generic_expr.lemSize e ≤ f → generic_expr.lemSize e ≤ g →
    subst_sym_expr_lemFuel f sym1 cval e = subst_sym_expr_lemFuel g sym1 cval e := by
  induction k with
  | zero => intro sym1 cval e f g hk _ _; have := expr_lemSize_pos e; omega
  | succ k ih =>
    intro sym1 cval e f g hk hf hg
    cases f with
    | zero => have := expr_lemSize_pos e; omega
    | succ f =>
      cases g with
      | zero => have := expr_lemSize_pos e; omega
      | succ g =>
        have key : ∀ (sym1' : sym) (cval' : value) (y : generic_expr a Unit sym), generic_expr.lemSize y < generic_expr.lemSize e →
            subst_sym_expr_lemFuel f sym1' cval' y = subst_sym_expr_lemFuel g sym1' cval' y :=
          fun sym1' cval' y hy => ih sym1' cval' y f g (by omega) (by omega) (by omega)
        obtain ⟨annot1, e_⟩ := e
        cases e_ <;> simp (disch := size_lt) only [subst_sym_expr_lemFuel, key]
        case Ecase pe pat_es =>
          to_congr; intro p hp; obtain ⟨x1, e⟩ := p
          dsimp only
          rw [key sym1 cval e (by have := expr_mem_lt_aux1 x1 e _ hp; size_lt)]
        case Eunseq es =>
          to_congr; intro e he
          exact key sym1 cval e (by have := expr_mem_lt_aux2 e _ he; size_lt)
        case End es =>
          to_congr; intro e he
          exact key sym1 cval e (by have := expr_mem_lt_aux2 e _ he; size_lt)
        case Epar es =>
          to_congr; intro e he
          exact key sym1 cval e (by have := expr_mem_lt_aux2 e _ he; size_lt)

/-- THE OBLIGATION, exactly as the generated auxiliary module states and delegates it. -/
theorem subst_sym_expr_measure_sufficient {a : Type} (sym1 : sym) (cval : value) (g : generic_expr a Unit sym) (lemFuel : Nat)
    (lemMeasureLe : generic_expr.lemSize g ≤ lemFuel) :
    subst_sym_expr_lemFuel lemFuel sym1 cval g = subst_sym_expr sym1 cval g :=
  subst_sym_expr_stable_aux (generic_expr.lemSize g) sym1 cval g lemFuel (generic_expr.lemSize g) (Nat.le_refl _) lemMeasureLe (Nat.le_refl _)

theorem subst_pattern_val_stable_aux {a : Type} (k : Nat) : ∀ (e : generic_pattern sym) (cval : value) (expr1 : generic_expr a Unit sym) (f g : Nat),
    generic_pattern.lemSize e ≤ k → generic_pattern.lemSize e ≤ f → generic_pattern.lemSize e ≤ g →
    subst_pattern_val_lemFuel f e cval expr1 = subst_pattern_val_lemFuel g e cval expr1 := by
  induction k with
  | zero => intro e cval expr1 f g hk _ _; have := pattern_lemSize_pos e; omega
  | succ k ih =>
    intro e cval expr1 f g hk hf hg
    cases f with
    | zero => have := pattern_lemSize_pos e; omega
    | succ f =>
      cases g with
      | zero => have := pattern_lemSize_pos e; omega
      | succ g =>
        have key : ∀ (cval' : value) (expr1' : generic_expr a Unit sym) (y : generic_pattern sym), generic_pattern.lemSize y < generic_pattern.lemSize e →
            subst_pattern_val_lemFuel f y cval' expr1' = subst_pattern_val_lemFuel g y cval' expr1' :=
          fun cval' expr1' y hy => ih y cval' expr1' f g (by omega) (by omega) (by omega)
        obtain ⟨an, pat⟩ := e
        simp only [subst_pattern_val_lemFuel]
        split <;> (try simp (disch := size_lt) only [key])
        all_goals
          apply lemListFoldr_congr; intro p acc hp
          obtain ⟨pat', q⟩ := p
          rw [LemLibTheorems.lemListZip_eq] at hp
          have := pattern_mem_lt_aux1 pat' _ (mem_zip_left hp)
          dsimp only
          have k' : ∀ ex, subst_pattern_val_lemFuel f pat' q ex = subst_pattern_val_lemFuel g pat' q ex := fun ex => key q ex pat' (by size_lt)
          simp only [k']

/-- THE OBLIGATION, exactly as the generated auxiliary module states and delegates it. -/
theorem subst_pattern_val_measure_sufficient {a : Type} (g : generic_pattern sym) (cval : value) (expr1 : generic_expr a Unit sym) (lemFuel : Nat)
    (lemMeasureLe : generic_pattern.lemSize g ≤ lemFuel) :
    subst_pattern_val_lemFuel lemFuel g cval expr1 = subst_pattern_val g cval expr1 :=
  subst_pattern_val_stable_aux (generic_pattern.lemSize g) g cval expr1 lemFuel (generic_pattern.lemSize g) (Nat.le_refl _) lemMeasureLe (Nat.le_refl _)

theorem unsafe_subst_sym_pexpr_stable_aux (k : Nat) : ∀ (sym1 : sym) (q : generic_pexpr Unit sym) (e : generic_pexpr Unit sym) (f g : Nat),
    generic_pexpr.lemSize e ≤ k → generic_pexpr.lemSize e ≤ f → generic_pexpr.lemSize e ≤ g →
    unsafe_subst_sym_pexpr_lemFuel f sym1 q e = unsafe_subst_sym_pexpr_lemFuel g sym1 q e := by
  induction k with
  | zero => intro sym1 q e f g hk _ _; have := pexpr_lemSize_pos e; omega
  | succ k ih =>
    intro sym1 q e f g hk hf hg
    cases f with
    | zero => have := pexpr_lemSize_pos e; omega
    | succ f =>
      cases g with
      | zero => have := pexpr_lemSize_pos e; omega
      | succ g =>
        have key : ∀ (sym1' : sym) (q' : generic_pexpr Unit sym) (y : generic_pexpr Unit sym), generic_pexpr.lemSize y < generic_pexpr.lemSize e →
            unsafe_subst_sym_pexpr_lemFuel f sym1' q' y = unsafe_subst_sym_pexpr_lemFuel g sym1' q' y :=
          fun sym1' q' y hy => ih sym1' q' y f g (by omega) (by omega) (by omega)
        obtain ⟨annot1, bty, pe_'⟩ := q
        obtain ⟨an0, bty0, pexpr_⟩ := e
        cases pexpr_ <;> simp (disch := size_lt) only [unsafe_subst_sym_pexpr_lemFuel, key]
        case PEconstrained xs =>
          to_congr; intro p hp; obtain ⟨x1, e⟩ := p
          dsimp only
          rw [key sym1 (Pexpr annot1 bty pe_') e (by have := pexpr_mem_lt_aux1 x1 e _ hp; size_lt)]
        case PEctor ctor1 pes =>
          to_congr; intro e he
          exact key sym1 (Pexpr annot1 bty pe_') e (by have := pexpr_mem_lt_aux2 e _ he; size_lt)
        case PEcase pe xs =>
          to_congr; intro p hp; obtain ⟨x1, e⟩ := p
          dsimp only
          rw [key sym1 (Pexpr annot1 bty pe_') e (by have := pexpr_mem_lt_aux3 x1 e _ hp; size_lt)]
        case PEmemop mop pes =>
          to_congr; intro e he
          exact key sym1 (Pexpr annot1 bty pe_') e (by have := pexpr_mem_lt_aux2 e _ he; size_lt)
        case PEstruct tag xs =>
          to_congr; intro p hp; obtain ⟨x1, e⟩ := p
          dsimp only
          rw [key sym1 (Pexpr annot1 bty pe_') e (by have := pexpr_mem_lt_aux4 x1 e _ hp; size_lt)]
        case PEcall nm pes =>
          to_congr; intro e he
          exact key sym1 (Pexpr annot1 bty pe_') e (by have := pexpr_mem_lt_aux2 e _ he; size_lt)

/-- THE OBLIGATION, exactly as the generated auxiliary module states and delegates it. -/
theorem unsafe_subst_sym_pexpr_measure_sufficient (sym1 : sym) (g : generic_pexpr Unit sym) (g0 : generic_pexpr Unit sym) (lemFuel : Nat)
    (lemMeasureLe : generic_pexpr.lemSize g0 ≤ lemFuel) :
    unsafe_subst_sym_pexpr_lemFuel lemFuel sym1 g g0 = unsafe_subst_sym_pexpr sym1 g g0 :=
  unsafe_subst_sym_pexpr_stable_aux (generic_pexpr.lemSize g0) sym1 g g0 lemFuel (generic_pexpr.lemSize g0) (Nat.le_refl _) lemMeasureLe (Nat.le_refl _)

theorem unsafe_subst_sym_expr_stable_aux {a : Type} (k : Nat) : ∀ (sym1 : sym) (q : generic_pexpr Unit sym) (e : generic_expr a Unit sym) (f g : Nat),
    generic_expr.lemSize e ≤ k → generic_expr.lemSize e ≤ f → generic_expr.lemSize e ≤ g →
    unsafe_subst_sym_expr_lemFuel f sym1 q e = unsafe_subst_sym_expr_lemFuel g sym1 q e := by
  induction k with
  | zero => intro sym1 q e f g hk _ _; have := expr_lemSize_pos e; omega
  | succ k ih =>
    intro sym1 q e f g hk hf hg
    cases f with
    | zero => have := expr_lemSize_pos e; omega
    | succ f =>
      cases g with
      | zero => have := expr_lemSize_pos e; omega
      | succ g =>
        have key : ∀ (sym1' : sym) (q' : generic_pexpr Unit sym) (y : generic_expr a Unit sym), generic_expr.lemSize y < generic_expr.lemSize e →
            unsafe_subst_sym_expr_lemFuel f sym1' q' y = unsafe_subst_sym_expr_lemFuel g sym1' q' y :=
          fun sym1' q' y hy => ih sym1' q' y f g (by omega) (by omega) (by omega)
        obtain ⟨annot1, e_⟩ := e
        cases e_ <;> simp (disch := size_lt) only [unsafe_subst_sym_expr_lemFuel, key]
        case Ecase pe pat_es =>
          to_congr; intro p hp; obtain ⟨x1, e⟩ := p
          dsimp only
          rw [key sym1 q e (by have := expr_mem_lt_aux1 x1 e _ hp; size_lt)]
        case Eunseq es =>
          to_congr; intro e he
          exact key sym1 q e (by have := expr_mem_lt_aux2 e _ he; size_lt)
        case End es =>
          to_congr; intro e he
          exact key sym1 q e (by have := expr_mem_lt_aux2 e _ he; size_lt)
        case Epar es =>
          to_congr; intro e he
          exact key sym1 q e (by have := expr_mem_lt_aux2 e _ he; size_lt)

/-- THE OBLIGATION, exactly as the generated auxiliary module states and delegates it. -/
theorem unsafe_subst_sym_expr_measure_sufficient {a : Type} (sym1 : sym) (pe' : generic_pexpr Unit sym) (g : generic_expr a Unit sym) (lemFuel : Nat)
    (lemMeasureLe : generic_expr.lemSize g ≤ lemFuel) :
    unsafe_subst_sym_expr_lemFuel lemFuel sym1 pe' g = unsafe_subst_sym_expr sym1 pe' g :=
  unsafe_subst_sym_expr_stable_aux (generic_expr.lemSize g) sym1 pe' g lemFuel (generic_expr.lemSize g) (Nat.le_refl _) lemMeasureLe (Nat.le_refl _)

theorem unsafe_subst_pattern_stable_aux {a : Type} (k : Nat) : ∀ (e : generic_pattern sym) (q : generic_pexpr Unit sym) (expr1 : generic_expr a Unit sym) (f g : Nat),
    generic_pattern.lemSize e ≤ k → generic_pattern.lemSize e ≤ f → generic_pattern.lemSize e ≤ g →
    unsafe_subst_pattern_lemFuel f e q expr1 = unsafe_subst_pattern_lemFuel g e q expr1 := by
  induction k with
  | zero => intro e q expr1 f g hk _ _; have := pattern_lemSize_pos e; omega
  | succ k ih =>
    intro e q expr1 f g hk hf hg
    cases f with
    | zero => have := pattern_lemSize_pos e; omega
    | succ f =>
      cases g with
      | zero => have := pattern_lemSize_pos e; omega
      | succ g =>
        have key : ∀ (q' : generic_pexpr Unit sym) (expr1' : generic_expr a Unit sym) (y : generic_pattern sym), generic_pattern.lemSize y < generic_pattern.lemSize e →
            unsafe_subst_pattern_lemFuel f y q' expr1' = unsafe_subst_pattern_lemFuel g y q' expr1' :=
          fun q' expr1' y hy => ih y q' expr1' f g (by omega) (by omega) (by omega)
        obtain ⟨an, pat⟩ := e
        simp only [unsafe_subst_pattern_lemFuel]
        split <;> (try simp (disch := size_lt) only [key])
        all_goals
          apply lemListFoldr_congr; intro p acc hp
          obtain ⟨pat', q⟩ := p
          rw [LemLibTheorems.lemListZip_eq] at hp
          have := pattern_mem_lt_aux1 pat' _ (mem_zip_left hp)
          dsimp only
          have k' : ∀ ex, unsafe_subst_pattern_lemFuel f pat' q ex = unsafe_subst_pattern_lemFuel g pat' q ex := fun ex => key q ex pat' (by size_lt)
          simp only [k']

/-- THE OBLIGATION, exactly as the generated auxiliary module states and delegates it. -/
theorem unsafe_subst_pattern_measure_sufficient {a : Type} (g : generic_pattern sym) (pe' : generic_pexpr Unit sym) (expr1 : generic_expr a Unit sym) (lemFuel : Nat)
    (lemMeasureLe : generic_pattern.lemSize g ≤ lemFuel) :
    unsafe_subst_pattern_lemFuel lemFuel g pe' expr1 = unsafe_subst_pattern g pe' expr1 :=
  unsafe_subst_pattern_stable_aux (generic_pattern.lemSize g) g pe' expr1 lemFuel (generic_pattern.lemSize g) (Nat.le_refl _) lemMeasureLe (Nat.le_refl _)

theorem subst_pattern_stable_aux {a : Type} (k : Nat) : ∀ (e : generic_pattern sym) (q : generic_pexpr Unit sym) (expr1 : generic_expr a Unit sym) (f g : Nat),
    generic_pattern.lemSize e ≤ k → generic_pattern.lemSize e ≤ f → generic_pattern.lemSize e ≤ g →
    subst_pattern_lemFuel f e q expr1 = subst_pattern_lemFuel g e q expr1 := by
  induction k with
  | zero => intro e q expr1 f g hk _ _; have := pattern_lemSize_pos e; omega
  | succ k ih =>
    intro e q expr1 f g hk hf hg
    cases f with
    | zero => have := pattern_lemSize_pos e; omega
    | succ f =>
      cases g with
      | zero => have := pattern_lemSize_pos e; omega
      | succ g =>
        have key : ∀ (q' : generic_pexpr Unit sym) (expr1' : generic_expr a Unit sym) (y : generic_pattern sym), generic_pattern.lemSize y < generic_pattern.lemSize e →
            subst_pattern_lemFuel f y q' expr1' = subst_pattern_lemFuel g y q' expr1' :=
          fun q' expr1' y hy => ih y q' expr1' f g (by omega) (by omega) (by omega)
        obtain ⟨an, pat⟩ := e
        simp only [subst_pattern_lemFuel]
        split <;> (try simp (disch := size_lt) only [key])
        all_goals
          apply lemListFoldr_congr; intro p acc hp
          obtain ⟨pat', q⟩ := p
          rw [LemLibTheorems.lemListZip_eq] at hp
          have := pattern_mem_lt_aux1 pat' _ (mem_zip_left hp)
          dsimp only
          have k' : ∀ ex, subst_pattern_lemFuel f pat' q ex = subst_pattern_lemFuel g pat' q ex := fun ex => key q ex pat' (by size_lt)
          simp only [k']

/-- THE OBLIGATION, exactly as the generated auxiliary module states and delegates it. -/
theorem subst_pattern_measure_sufficient {a : Type} (g : generic_pattern sym) (pe' : generic_pexpr Unit sym) (expr1 : generic_expr a Unit sym) (lemFuel : Nat)
    (lemMeasureLe : generic_pattern.lemSize g ≤ lemFuel) :
    subst_pattern_lemFuel lemFuel g pe' expr1 = subst_pattern g pe' expr1 :=
  subst_pattern_stable_aux (generic_pattern.lemSize g) g pe' expr1 lemFuel (generic_pattern.lemSize g) (Nat.le_refl _) lemMeasureLe (Nat.le_refl _)

theorem match_pattern_stable_aux (k : Nat) : ∀ (e : generic_pattern sym) (cval : value) (f g : Nat),
    generic_pattern.lemSize e ≤ k → generic_pattern.lemSize e ≤ f → generic_pattern.lemSize e ≤ g →
    match_pattern_lemFuel f e cval = match_pattern_lemFuel g e cval := by
  induction k with
  | zero => intro e cval f g hk _ _; have := pattern_lemSize_pos e; omega
  | succ k ih =>
    intro e cval f g hk hf hg
    cases f with
    | zero => have := pattern_lemSize_pos e; omega
    | succ f =>
      cases g with
      | zero => have := pattern_lemSize_pos e; omega
      | succ g =>
        have key : ∀ (cval' : value) (y : generic_pattern sym), generic_pattern.lemSize y < generic_pattern.lemSize e →
            match_pattern_lemFuel f y cval' = match_pattern_lemFuel g y cval' :=
          fun cval' y hy => ih y cval' f g (by omega) (by omega) (by omega)
        obtain ⟨an, pat⟩ := e
        simp only [match_pattern_lemFuel]
        split <;> (try simp (disch := size_lt) only [key])
        all_goals
          apply lemListFoldr_congr; intro p acc hp
          obtain ⟨pat', q⟩ := p
          rw [LemLibTheorems.lemListZip_eq] at hp
          have := pattern_mem_lt_aux1 pat' _ (mem_zip_left hp)
          dsimp only
          rw [key q pat' (by size_lt)]

/-- THE OBLIGATION, exactly as the generated auxiliary module states and delegates it. -/
theorem match_pattern_measure_sufficient (g : generic_pattern sym) (cval : value) (lemFuel : Nat)
    (lemMeasureLe : generic_pattern.lemSize g ≤ lemFuel) :
    match_pattern_lemFuel lemFuel g cval = match_pattern g cval :=
  match_pattern_stable_aux (generic_pattern.lemSize g) g cval lemFuel (generic_pattern.lemSize g) (Nat.le_refl _) lemMeasureLe (Nat.le_refl _)

theorem collect_saves_aux_stable_aux {a : Type} (k : Nat) : ∀ (st : collect_saves_state a) (e : generic_expr a Unit sym) (f g : Nat),
    generic_expr.lemSize e ≤ k → generic_expr.lemSize e ≤ f → generic_expr.lemSize e ≤ g →
    collect_saves_aux_lemFuel f st e = collect_saves_aux_lemFuel g st e := by
  induction k with
  | zero => intro st e f g hk _ _; have := expr_lemSize_pos e; omega
  | succ k ih =>
    intro st e f g hk hf hg
    cases f with
    | zero => have := expr_lemSize_pos e; omega
    | succ f =>
      cases g with
      | zero => have := expr_lemSize_pos e; omega
      | succ g =>
        have key : ∀ (st' : collect_saves_state a) (y : generic_expr a Unit sym), generic_expr.lemSize y < generic_expr.lemSize e →
            collect_saves_aux_lemFuel f st' y = collect_saves_aux_lemFuel g st' y :=
          fun st' y hy => ih st' y f g (by omega) (by omega) (by omega)
        obtain ⟨annot1, e_⟩ := e
        cases e_ <;> simp (disch := size_lt) only [collect_saves_aux_lemFuel, key]
        case Ecase pe pat_es =>
          to_congr
          intro acc p hp
          obtain ⟨x1, e⟩ := p; dsimp only
          rw [key acc e (by have := expr_mem_lt_aux1 x1 e _ hp; size_lt)]
        case Eunseq es =>
          to_congr
          intro acc e he

          exact key acc e (by have := expr_mem_lt_aux2 e _ he; size_lt)
        case Epar es =>
          rw [lfoldl_congr es _ _ (fun acc e he => key acc e (by have := expr_mem_lt_aux2 e _ he; size_lt)) empty_saves]

/-- THE OBLIGATION, exactly as the generated auxiliary module states and delegates it. -/
theorem collect_saves_aux_measure_sufficient {a : Type} (st : collect_saves_state a) (g : generic_expr a Unit sym) (lemFuel : Nat)
    (lemMeasureLe : generic_expr.lemSize g ≤ lemFuel) :
    collect_saves_aux_lemFuel lemFuel st g = collect_saves_aux st g :=
  collect_saves_aux_stable_aux (generic_expr.lemSize g) st g lemFuel (generic_expr.lemSize g) (Nat.le_refl _) lemMeasureLe (Nat.le_refl _)

theorem m_collect_saves_aux_stable_aux {a : Type} (k : Nat) : ∀ (st : m_collect_saves_state a) (e : generic_expr a Unit sym) (f g : Nat),
    generic_expr.lemSize e ≤ k → generic_expr.lemSize e ≤ f → generic_expr.lemSize e ≤ g →
    m_collect_saves_aux_lemFuel f st e = m_collect_saves_aux_lemFuel g st e := by
  induction k with
  | zero => intro st e f g hk _ _; have := expr_lemSize_pos e; omega
  | succ k ih =>
    intro st e f g hk hf hg
    cases f with
    | zero => have := expr_lemSize_pos e; omega
    | succ f =>
      cases g with
      | zero => have := expr_lemSize_pos e; omega
      | succ g =>
        have key : ∀ (st' : m_collect_saves_state a) (y : generic_expr a Unit sym), generic_expr.lemSize y < generic_expr.lemSize e →
            m_collect_saves_aux_lemFuel f st' y = m_collect_saves_aux_lemFuel g st' y :=
          fun st' y hy => ih st' y f g (by omega) (by omega) (by omega)
        obtain ⟨annot1, e_⟩ := e
        cases e_ <;> simp (disch := size_lt) only [m_collect_saves_aux_lemFuel, key]
        case Ecase pe pat_es =>
          to_congr
          intro acc p hp
          obtain ⟨x1, e⟩ := p; dsimp only
          rw [key acc e (by have := expr_mem_lt_aux1 x1 e _ hp; size_lt)]
        case Eunseq es =>
          to_congr
          intro acc e he

          exact key acc e (by have := expr_mem_lt_aux2 e _ he; size_lt)
        case Epar es =>
          rw [lfoldl_congr es _ _ (fun acc e he => key acc e (by have := expr_mem_lt_aux2 e _ he; size_lt)) m_empty_saves]

/-- THE OBLIGATION, exactly as the generated auxiliary module states and delegates it. -/
theorem m_collect_saves_aux_measure_sufficient {a : Type} (st : m_collect_saves_state a) (g : generic_expr a Unit sym) (lemFuel : Nat)
    (lemMeasureLe : generic_expr.lemSize g ≤ lemFuel) :
    m_collect_saves_aux_lemFuel lemFuel st g = m_collect_saves_aux st g :=
  m_collect_saves_aux_stable_aux (generic_expr.lemSize g) st g lemFuel (generic_expr.lemSize g) (Nat.le_refl _) lemMeasureLe (Nat.le_refl _)

theorem find_labeled_continuation_stable_aux {a : Type} {b : Type} {c : Type} [Lem_Basic_classes.Eq0 a] (k : Nat) : ∀ (sym1 : a) (e : generic_expr c b a) (f g : Nat),
    generic_expr.lemSize e ≤ k → generic_expr.lemSize e ≤ f → generic_expr.lemSize e ≤ g →
    find_labeled_continuation_lemFuel f sym1 e = find_labeled_continuation_lemFuel g sym1 e := by
  induction k with
  | zero => intro sym1 e f g hk _ _; have := expr_lemSize_pos e; omega
  | succ k ih =>
    intro sym1 e f g hk hf hg
    cases f with
    | zero => have := expr_lemSize_pos e; omega
    | succ f =>
      cases g with
      | zero => have := expr_lemSize_pos e; omega
      | succ g =>
        have key : ∀ (sym1' : a) (y : generic_expr c b a), generic_expr.lemSize y < generic_expr.lemSize e →
            find_labeled_continuation_lemFuel f sym1' y = find_labeled_continuation_lemFuel g sym1' y :=
          fun sym1' y hy => ih sym1' y f g (by omega) (by omega) (by omega)
        obtain ⟨annot1, e_⟩ := e
        cases e_ <;> simp (disch := size_lt) only [find_labeled_continuation_lemFuel, key]
        case Ecase pe pat_es =>
          to_congr
          intro acc p hp
          obtain ⟨x1, e⟩ := p; dsimp only
          rw [key sym1 e (by have := expr_mem_lt_aux1 x1 e _ hp; size_lt)]

/-- THE OBLIGATION, exactly as the generated auxiliary module states and delegates it. -/
theorem find_labeled_continuation_measure_sufficient {a : Type} {b : Type} {c : Type} [Lem_Basic_classes.Eq0 a] (sym1 : a) (g : generic_expr c b a) (lemFuel : Nat)
    (lemMeasureLe : generic_expr.lemSize g ≤ lemFuel) :
    find_labeled_continuation_lemFuel lemFuel sym1 g = find_labeled_continuation sym1 g :=
  find_labeled_continuation_stable_aux (generic_expr.lemSize g) sym1 g lemFuel (generic_expr.lemSize g) (Nat.le_refl _) lemMeasureLe (Nat.le_refl _)

theorem update_env_aux_stable_aux {a : Type} [Lem_Map.MapKeyType a] (k : Nat) : ∀ (e : generic_pattern a) (cval : value) (env1 : Fmap a value) (f g : Nat),
    generic_pattern.lemSize e ≤ k → generic_pattern.lemSize e ≤ f → generic_pattern.lemSize e ≤ g →
    update_env_aux_lemFuel f e cval env1 = update_env_aux_lemFuel g e cval env1 := by
  induction k with
  | zero => intro e cval env1 f g hk _ _; have := pattern_lemSize_pos e; omega
  | succ k ih =>
    intro e cval env1 f g hk hf hg
    cases f with
    | zero => have := pattern_lemSize_pos e; omega
    | succ f =>
      cases g with
      | zero => have := pattern_lemSize_pos e; omega
      | succ g =>
        have key : ∀ (cval' : value) (env1' : Fmap a value) (y : generic_pattern a), generic_pattern.lemSize y < generic_pattern.lemSize e →
            update_env_aux_lemFuel f y cval' env1' = update_env_aux_lemFuel g y cval' env1' :=
          fun cval' env1' y hy => ih y cval' env1' f g (by omega) (by omega) (by omega)
        obtain ⟨an, pat⟩ := e
        simp only [update_env_aux_lemFuel]
        split <;> (try simp (disch := size_lt) only [key])
        all_goals
          apply lemListFoldr_congr; intro p acc hp
          obtain ⟨pat', q⟩ := p
          rw [LemLibTheorems.lemListZip_eq] at hp
          have := pattern_mem_lt_aux1 pat' _ (mem_zip_left hp)
          dsimp only
          have k' : ∀ env, update_env_aux_lemFuel f pat' q env = update_env_aux_lemFuel g pat' q env := fun env => key q env pat' (by size_lt)
          simp only [k']

/-- THE OBLIGATION, exactly as the generated auxiliary module states and delegates it. -/
theorem update_env_aux_measure_sufficient {a : Type} [Lem_Map.MapKeyType a] (g : generic_pattern a) (cval : value) (env1 : Fmap a value) (lemFuel : Nat)
    (lemMeasureLe : generic_pattern.lemSize g ≤ lemFuel) :
    update_env_aux_lemFuel lemFuel g cval env1 = update_env_aux g cval env1 :=
  update_env_aux_stable_aux (generic_pattern.lemSize g) g cval env1 lemFuel (generic_pattern.lemSize g) (Nat.le_refl _) lemMeasureLe (Nat.le_refl _)

end Core_aux_lemMeasureProofs
