/- Structural fuel sufficiency for the Ail-to-Core translation helpers.
   Lean-only proofs over the generated workers; no OCaml implementation changes. -/
import Translation
import LemLibTheorems

set_option autoImplicit false

namespace Translation_lemMeasureProofs

theorem constant_size_pos (c : constant) : 0 < constant.lemSize c := by
  cases c <;> simp only [constant.lemSize] <;> omega

theorem constant_mem_lt (c : constant) (cs : List constant) (h : c ∈ cs) :
    constant.lemSize c < constant.lemSize_aux1 cs := by
  induction cs with
  | nil => cases h
  | cons d ds ih =>
    cases h with
    | head => simp only [constant.lemSize_aux1]; omega
    | tail _ h => have := ih h; simp only [constant.lemSize_aux1]; omega

theorem constant_field_mem_lt (p : identifier × constant) (cs : List (identifier × constant))
    (h : p ∈ cs) : constant.lemSize p.2 < constant.lemSize_aux2 cs := by
  induction cs with
  | nil => cases h
  | cons d ds ih =>
    obtain ⟨i, c⟩ := d
    cases h with
    | head => simp only [constant.lemSize_aux2]; omega
    | tail _ h => have := ih h; simp only [constant.lemSize_aux2]; omega

theorem translate_constant_stable (enums : Fmap sym integerType)
    (tags : Fmap sym (CerbLocation.Loc × tag_definition)) (k : Nat) :
    ∀ (c : constant) (f g : Nat), constant.lemSize c ≤ k →
      constant.lemSize c ≤ f → constant.lemSize c ≤ g →
      translate_constant_lemFuel f enums tags c = translate_constant_lemFuel g enums tags c := by
  induction k with
  | zero => intro c f g hk; have := constant_size_pos c; omega
  | succ k ih =>
    intro c f g hk hf hg
    have hp := constant_size_pos c
    cases f with
    | zero => omega
    | succ f =>
      cases g with
      | zero => omega
      | succ g =>
        have key : ∀ d, constant.lemSize d < constant.lemSize c →
            translate_constant_lemFuel f enums tags d = translate_constant_lemFuel g enums tags d :=
          fun d hd => ih d f g (by omega) (by omega) (by omega)
        have keys : ∀ cs, constant.lemSize_aux1 cs < constant.lemSize c →
            List.map (translate_constant_lemFuel f enums tags) cs =
            List.map (translate_constant_lemFuel g enums tags) cs := by
          intro cs hc
          apply List.map_congr_left
          intro d hd
          exact key d (by have := constant_mem_lt d cs hd; omega)
        have fields : ∀ cs, constant.lemSize_aux2 cs < constant.lemSize c →
            List.map (fun (p : identifier × constant) => (p.1, translate_constant_lemFuel f enums tags p.2)) cs =
            List.map (fun (p : identifier × constant) => (p.1, translate_constant_lemFuel g enums tags p.2)) cs := by
          intro cs hc
          apply List.map_congr_left
          intro p hp
          rw [key p.2 (by have := constant_field_mem_lt p cs hp; omega)]
        cases c <;>
          simp (disch := (simp only [constant.lemSize] at *; omega)) only
            [translate_constant_lemFuel, key, keys, fields]
        all_goals rename_i i; cases i <;> rfl

theorem translate_constant_measure_sufficient (enums : Fmap sym integerType)
    (tags : Fmap sym (CerbLocation.Loc × tag_definition)) (cst : constant) (lemFuel : Nat)
    (lemMeasureLe : constant.lemSize cst ≤ lemFuel) :
    translate_constant_lemFuel lemFuel enums tags cst = translate_constant enums tags cst :=
  translate_constant_stable enums tags (constant.lemSize cst) cst lemFuel
    (constant.lemSize cst) (Nat.le_refl _) lemMeasureLe (Nat.le_refl _)

theorem statement_size_pos (s : statement genTypeCategory) : 0 < statement.lemSize s := by
  cases s
  simp only [statement.lemSize]
  omega

theorem statement_mem_lt (s : statement genTypeCategory) (ss : List (statement genTypeCategory))
    (h : s ∈ ss) : statement.lemSize s < expression_.lemSize_aux6 ss := by
  induction ss with
  | nil => cases h
  | cons t ts ih =>
    cases h with
    | head => simp only [expression_.lemSize_aux6]; omega
    | tail _ h => have := ih h; simp only [expression_.lemSize_aux6]; omega

theorem collect_cases__stable (k : Nat) :
    ∀ (s : statement genTypeCategory) (f g : Nat), statement.lemSize s ≤ k →
      statement.lemSize s ≤ f → statement.lemSize s ≤ g →
      collect_cases__lemFuel f s = collect_cases__lemFuel g s := by
  induction k with
  | zero => intro s f g hk; have := statement_size_pos s; omega
  | succ k ih =>
    intro s f g hk hf hg
    have hp := statement_size_pos s
    cases f with
    | zero => omega
    | succ f =>
      cases g with
      | zero => omega
      | succ g =>
        have key : ∀ t, statement.lemSize t < statement.lemSize s →
            collect_cases__lemFuel f t = collect_cases__lemFuel g t :=
          fun t ht => ih t f g (by omega) (by omega) (by omega)
        have keys : ∀ ts, expression_.lemSize_aux6 ts < statement.lemSize s →
            mapM_ (collect_cases__lemFuel f) ts = mapM_ (collect_cases__lemFuel g) ts := by
          intro ts ht
          have hm : List.map (collect_cases__lemFuel f) ts = List.map (collect_cases__lemFuel g) ts := by
            apply List.map_congr_left
            intro t hmem
            exact key t (by have := statement_mem_lt t ts hmem; omega)
          simp only [mapM_, hm]
        obtain ⟨loc, info, attrs, node⟩ := s
        cases node <;>
          simp (disch := (simp only [statement.lemSize, statement_.lemSize] at *; omega)) only
            [collect_cases__lemFuel, key, keys]

theorem collect_cases__measure_sufficient (stmt : statement genTypeCategory) (lemFuel : Nat)
    (lemMeasureLe : statement.lemSize stmt ≤ lemFuel) :
    collect_cases__lemFuel lemFuel stmt = collect_cases_ stmt :=
  collect_cases__stable (statement.lemSize stmt) stmt lemFuel (statement.lemSize stmt)
    (Nat.le_refl _) lemMeasureLe (Nat.le_refl _)

theorem erase_loop_control_aux_stable (k : Nat) :
    ∀ (s : statement genTypeCategory) (f g : Nat), statement.lemSize s ≤ k →
      statement.lemSize s ≤ f → statement.lemSize s ≤ g →
      erase_loop_control_aux_lemFuel f s = erase_loop_control_aux_lemFuel g s := by
  induction k with
  | zero => intro s f g hk; have := statement_size_pos s; omega
  | succ k ih =>
    intro s f g hk hf hg
    have hp := statement_size_pos s
    cases f with
    | zero => omega
    | succ f =>
      cases g with
      | zero => omega
      | succ g =>
        have key : ∀ t, statement.lemSize t < statement.lemSize s →
            erase_loop_control_aux_lemFuel f t = erase_loop_control_aux_lemFuel g t :=
          fun t ht => ih t f g (by omega) (by omega) (by omega)
        have keys : ∀ ts, expression_.lemSize_aux6 ts < statement.lemSize s →
            mapM0 (erase_loop_control_aux_lemFuel f) ts = mapM0 (erase_loop_control_aux_lemFuel g) ts := by
          intro ts ht
          have hm : List.map (erase_loop_control_aux_lemFuel f) ts = List.map (erase_loop_control_aux_lemFuel g) ts := by
            apply List.map_congr_left
            intro t hmem
            exact key t (by have := statement_mem_lt t ts hmem; omega)
          simp only [mapM0, listM, hm]
        obtain ⟨loc, info, attrs, node⟩ := s
        cases node <;>
          simp (disch := (simp only [statement.lemSize, statement_.lemSize] at *; omega)) only
            [erase_loop_control_aux_lemFuel, key, keys]

theorem erase_loop_control_aux_measure_sufficient (stmt : statement genTypeCategory) (lemFuel : Nat)
    (lemMeasureLe : statement.lemSize stmt ≤ lemFuel) :
    erase_loop_control_aux_lemFuel lemFuel stmt = erase_loop_control_aux stmt :=
  erase_loop_control_aux_stable (statement.lemSize stmt) stmt lemFuel (statement.lemSize stmt)
    (Nat.le_refl _) lemMeasureLe (Nat.le_refl _)

theorem collect_visibles__stable (k : Nat) :
    ∀ (s : statement genTypeCategory) (f g : Nat), statement.lemSize s ≤ k →
      statement.lemSize s ≤ f → statement.lemSize s ≤ g →
      collect_visibles__lemFuel f s = collect_visibles__lemFuel g s := by
  induction k with
  | zero => intro s f g hk; have := statement_size_pos s; omega
  | succ k ih =>
    intro s f g hk hf hg
    have hp := statement_size_pos s
    cases f with
    | zero => omega
    | succ f =>
      cases g with
      | zero => omega
      | succ g =>
        have key : ∀ t, statement.lemSize t < statement.lemSize s →
            collect_visibles__lemFuel f t = collect_visibles__lemFuel g t :=
          fun t ht => ih t f g (by omega) (by omega) (by omega)
        have keys : ∀ ts, expression_.lemSize_aux6 ts < statement.lemSize s →
            mapM_ (collect_visibles__lemFuel f) ts = mapM_ (collect_visibles__lemFuel g) ts := by
          intro ts ht
          have hm : List.map (collect_visibles__lemFuel f) ts = List.map (collect_visibles__lemFuel g) ts := by
            apply List.map_congr_left
            intro t hmem
            exact key t (by have := statement_mem_lt t ts hmem; omega)
          simp only [mapM_, hm]
        obtain ⟨loc, info, attrs, node⟩ := s
        cases node <;>
          simp (disch := (simp only [statement.lemSize, statement_.lemSize] at *; omega)) only
            [collect_visibles__lemFuel, key, keys]

theorem collect_visibles__measure_sufficient (stmt : statement genTypeCategory) (lemFuel : Nat)
    (lemMeasureLe : statement.lemSize stmt ≤ lemFuel) :
    collect_visibles__lemFuel lemFuel stmt = collect_visibles_ stmt :=
  collect_visibles__stable (statement.lemSize stmt) stmt lemFuel (statement.lemSize stmt)
    (Nat.le_refl _) lemMeasureLe (Nat.le_refl _)

end Translation_lemMeasureProofs
