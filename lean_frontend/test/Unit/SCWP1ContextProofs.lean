import Core_reduction_lemMeasureProofs

/-! General reconstruction law for production Core contexts. This supports
    fresh context selection; it is not an SC/source-order correspondence proof. -/
namespace SCWP1Context
open CerbCoreMeasure
abbrev E := expr core_run_annotation
abbrev C := context × E

def Rebuilds (e : E) (xs : List C) : Prop :=
  ∀ p ∈ xs, apply_ctx p.1 p.2 = e

@[simp] theorem rebuilds_single (e : E) : Rebuilds e [(CTX, e)] := by
  simp [Rebuilds, apply_ctx]

@[simp] theorem rebuilds_nil (e : E) : Rebuilds e [] := by simp [Rebuilds]

theorem lift_rebuild (f : context → context) (g : E → E) (e : E) (xs : List C)
    (h : Rebuilds e xs)
    (hf : ∀ c x, apply_ctx (f c) x = g (apply_ctx c x)) :
    Rebuilds (g e) (xs.map (fun (c,x) => (f c,x))) := by
  intro p hp
  obtain ⟨⟨c,x⟩, hm, rfl⟩ := List.mem_map.mp hp
  simp only [hf, h (c,x) hm]

@[simp] theorem rebuilds_append (e : E) (xs ys : List C) :
    Rebuilds e (xs ++ ys) ↔ Rebuilds e xs ∧ Rebuilds e ys := by
  constructor
  · intro h
    exact ⟨fun p hp => h p (List.mem_append.mpr (Or.inl hp)),
      fun p hp => h p (List.mem_append.mpr (Or.inr hp))⟩
  · rintro ⟨hx, hy⟩ p hp
    rcases List.mem_append.mp hp with h | h
    · exact hx p h
    · exact hy p h

theorem contexts_rebuild_aux (k : Nat) :
    (∀ (e : E) (f : Nat), getCtxBound (.inl e) ≤ k → getCtxBound (.inl e) ≤ f →
      Rebuilds e (get_ctx_lemFuel f e)) ∧
    (∀ (a : List annot) (acc : List C) (es1 es2 : List E) (f : Nat),
      getCtxBound (.inr es2) ≤ k → getCtxBound (.inr es2) ≤ f →
      Rebuilds (Expr a (Eunseq (es1 ++ es2))) acc →
      Rebuilds (Expr a (Eunseq (es1 ++ es2))) (get_ctx_unseq_aux_lemFuel f a acc es1 es2)) := by
  induction k with
  | zero =>
      constructor
      · intro e f hk hf; have := getCtxBound_pos (.inl e); omega
      · intro a acc es1 es2 f hk hf ha; have := getCtxBound_pos (.inr es2); omega
  | succ k ih =>
      obtain ⟨ih1, ih2⟩ := ih
      constructor
      · intro e f hk hf
        have hp := getCtxBound_pos (.inl e)
        cases f with
        | zero => omega
        | succ f =>
          have key1 (y : E) (hy : getCtxBound (.inl y) < getCtxBound (.inl e)) :
              Rebuilds y (get_ctx_lemFuel f y) := ih1 y f (by omega) (by omega)
          have key2 (a : List annot) (acc : List C) (es1 es2 : List E)
              (hy : getCtxBound (.inr es2) < getCtxBound (.inl e))
              (ha : Rebuilds (Expr a (Eunseq (es1 ++ es2))) acc) :
              Rebuilds (Expr a (Eunseq (es1 ++ es2))) (get_ctx_unseq_aux_lemFuel f a acc es1 es2) :=
            ih2 a acc es1 es2 f (by omega) (by omega) ha
          obtain ⟨a, body⟩ := e
          simp only [get_ctx_lemFuel]
          split
          · exact rebuilds_single _
          · cases body <;> try exact rebuilds_single _
            case Eunseq es hred =>
              dsimp only
              split
              · exact rebuilds_single _
              · exact key2 a [] [] es
                  (getCtxBound_child_lt _ _ (by simp [getCtxNext])) (rebuilds_nil _)
            case Ewseq pat e1 e2 hred =>
              dsimp only
              split
              · exact rebuilds_single _
              · exact lift_rebuild (fun c => Cwseq a pat c e2)
                  (fun x => Expr a (Ewseq pat x e2)) e1 _
                  (key1 e1 (getCtxBound_child_lt _ _ (by simp [getCtxNext]))) (by intros; rfl)
            case Esseq pat e1 e2 hred =>
              dsimp only
              split
              · exact rebuilds_single _
              · exact lift_rebuild (fun c => Csseq a pat c e2)
                  (fun x => Expr a (Esseq pat x e2)) e1 _
                  (key1 e1 (getCtxBound_child_lt _ _ (by simp [getCtxNext]))) (by intros; rfl)
            case Ebound e hred =>
              dsimp only
              split
              · exact rebuilds_single _
              · exact lift_rebuild (fun c => Cbound a c)
                  (fun x => Expr a (Ebound x)) e _
                  (key1 e (getCtxBound_child_lt _ _ (by simp [getCtxNext]))) (by intros; rfl)
            case Eannot xs e hred =>
              obtain ⟨a2, body2⟩ := e
              cases body2 <;> dsimp only
              all_goals first
                | exact rebuilds_single _
                | exact lift_rebuild (fun c => Cannot a xs c)
                    (fun x => Expr a (Eannot xs x)) _ _
                    (key1 _ (getCtxBound_child_lt _ _ (by simp [getCtxNext]))) (by intros; rfl)
      · intro a acc es1 es2 f hk hf ha
        have hp := getCtxBound_pos (.inr es2)
        cases f with
        | zero => omega
        | succ f =>
          cases es2 with
          | nil => exact ha
          | cons e es2 =>
            have he := getCtxBound_child_lt (.inr (e :: es2)) (.inl e) (by simp [getCtxNext])
            have ht := getCtxBound_child_lt (.inr (e :: es2)) (.inr es2) (by simp [getCtxNext])
            have hh := ih1 e f (by omega) (by omega)
            have next (acc' : List C)
                (hacc : Rebuilds (Expr a (Eunseq ((es1 ++ [e]) ++ es2))) acc') :
                Rebuilds (Expr a (Eunseq ((es1 ++ [e]) ++ es2)))
                  (get_ctx_unseq_aux_lemFuel f a acc' (es1 ++ [e]) es2) :=
              ih2 a acc' (es1 ++ [e]) es2 f (by omega) (by omega) hacc
            simp only [List.append_assoc, List.singleton_append] at next
            simp only [get_ctx_unseq_aux_lemFuel]
            split
            · exact next acc ha
            · apply next
              rw [rebuilds_append]
              constructor
              · exact lift_rebuild (fun c => Cunseq a es1 c es2)
                  (fun x => Expr a (Eunseq (es1 ++ x :: es2))) e _ hh (by intros; rfl)
              · exact ha

/-- Every selected production context reconstructs the expression it came from. -/
theorem contexts_rebuild (e : E) : Rebuilds e (get_ctx e) :=
  (contexts_rebuild_aux (getCtxBound (.inl e))).1 e (getCtxBound (.inl e))
    (Nat.le_refl _) (Nat.le_refl _)

theorem selected_context_rebuilds (e : E) (ctx : context) (focus : E)
    (h : (ctx, focus) ∈ get_ctx e) : apply_ctx ctx focus = e :=
  contexts_rebuild e (ctx, focus) h

end SCWP1Context
