/-
  Core_eval_lemMeasureProofs — the hand-written proofs of the `fuel_measure`
  obligations lem emits into Core_eval_auxiliary.lean (fuel-parameter arc C2,
  2026-09-04; frontend/model/core_eval.lem, Lean-only):

    pull_constrained  measure `lemSize g`       (the counter n only grows; every
                      `self` argument is a component of the matched pexpr)
    step_eval_pexpr   measure `lemSize pexpr1`  (every `self` argument is a
                      component of the matched pexpr; the Core function-call
                      result goes through `exception_undef_return`, never
                      through `self`); the statement keeps `[LemFuel]` for the
                      ambient callees the body reaches

  Shape = the C2 template; the higher-order uses of `self` (`pull_helper`,
  `exception_undef_mapM`, `step_eval_peop`) are rewritten by the congruence
  lemmas below, membership-relative where a list is traversed. Kernel-only
  tactics; no option bumps.

  MIRROR-OCAML NOTE: proofs about the Lean total workers; no OCaml text
  corresponds (fuel is a Lean-target artifact).
-/

import Core_eval
import CerbMeasureLemmas

set_option autoImplicit false

open CerbMeasureLemmas

namespace Core_eval_lemMeasureProofs

/-- `pull_helper` is congruent in `pull` on the members of its list. -/
theorem pull_helper_congr {a b : Type} (F G : generic_pexpr Unit sym → generic_pexpr Unit sym)
    (c : List (a × generic_pexpr Unit sym) → generic_pexpr_ Unit b) (ps : List (a × pexpr))
    (h : ∀ x pe, (x, pe) ∈ ps → F pe = G pe) : pull_helper F c ps = pull_helper G c ps := by
  unfold pull_helper
  congr 1
  apply lfoldl_congr; intro acc p hp
  obtain ⟨x1, pe⟩ := p; dsimp only; rw [h x1 pe hp]

/-- `exception_undef_mapM` is congruent on the members of its list. -/
theorem exception_undef_mapM_congr {a b c : Type} (F G : c → exceptM (t0 a) b) (xs : List c)
    (h : ∀ x ∈ xs, F x = G x) : exception_undef_mapM F xs = exception_undef_mapM G xs := by
  unfold exception_undef_mapM except_mapM
  rw [lmap_congr xs F G h]

/-- `step_eval_peop` uses `self` at exactly its two operands. -/
theorem step_eval_peop_congr (loc1 : CerbLocation.Loc)
    (F G : generic_pexpr Unit sym → exceptM (t0 (generic_pexpr Unit sym)) core_run_cause)
    (binop1 : binop) (pe1 pe2 : generic_pexpr Unit sym) (h1 : F pe1 = G pe1) (h2 : F pe2 = G pe2) :
    step_eval_peop loc1 F binop1 pe1 pe2 = step_eval_peop loc1 G binop1 pe1 pe2 := by
  unfold step_eval_peop
  rw [h1, h2]

theorem mem_unzip_snd {α β : Type} (pe : β) (l : List (α × β)) (h : pe ∈ (lemListUnzip l).2) :
    ∃ x, (x, pe) ∈ l := by
  rw [LemLibTheorems.lemListUnzip_eq, List.unzip_snd] at h
  obtain ⟨⟨x, q⟩, hp, hq⟩ := List.mem_map.mp h
  cases hq
  exact ⟨x, hp⟩

theorem pull_constrained_stable_aux (k : Nat) : ∀ (n : Nat) (e : generic_pexpr Unit sym) (f g : Nat),
    generic_pexpr.lemSize e ≤ k → generic_pexpr.lemSize e ≤ f → generic_pexpr.lemSize e ≤ g →
    pull_constrained_lemFuel f n e = pull_constrained_lemFuel g n e := by
  induction k with
  | zero => intro n e f g hk _ _; have := pexpr_lemSize_pos e; omega
  | succ k ih =>
    intro n e f g hk hf hg
    cases f with
    | zero => have := pexpr_lemSize_pos e; omega
    | succ f =>
      cases g with
      | zero => have := pexpr_lemSize_pos e; omega
      | succ g =>
        have key : ∀ (m : Nat) (y : generic_pexpr Unit sym), generic_pexpr.lemSize y < generic_pexpr.lemSize e →
            pull_constrained_lemFuel f m y = pull_constrained_lemFuel g m y :=
          fun m y hy => ih m y f g (by omega) (by omega) (by omega)
        obtain ⟨an, u, pexpr_⟩ := e
        cases u
        have hph : ∀ (b : Type) (c : List (Unit × generic_pexpr Unit sym) → generic_pexpr_ Unit b)
            (pes : List (generic_pexpr Unit sym)),
            (∀ q ∈ pes, generic_pexpr.lemSize q < generic_pexpr.lemSize (Pexpr an () pexpr_)) →
            pull_helper (fun pe => pull_constrained_lemFuel f (n + 1) pe) c (List.map (fun pe => ((), pe)) pes) =
              pull_helper (fun pe => pull_constrained_lemFuel g (n + 1) pe) c (List.map (fun pe => ((), pe)) pes) := by
          intro b c pes hpes
          apply pull_helper_congr; intro x pe hp
          exact key (n + 1) pe (hpes pe (mem_map_unit hp))
        cases pexpr_ <;> simp (disch := size_lt) only [pull_constrained_lemFuel, key]
        case PEconstrained xs =>
          to_congr
          intro acc p hp
          obtain ⟨cs, pe⟩ := p; dsimp only
          rw [key (n + 1) pe (by have := pexpr_mem_lt_aux1 cs pe _ hp; size_lt)]
        case PEctor ctor1 pes =>
          congr 1
          exact hph _ _ pes (fun q hq => by have := pexpr_mem_lt_aux2 q _ hq; size_lt)
        case PEcase pe pat_pes =>
          have hc : ∀ (c : List (generic_pattern sym × generic_pexpr Unit sym) → generic_pexpr_ Unit sym),
              pull_helper (fun pe => pull_constrained_lemFuel f (n + 1) pe) c pat_pes =
                pull_helper (fun pe => pull_constrained_lemFuel g (n + 1) pe) c pat_pes :=
            fun c => pull_helper_congr _ _ c pat_pes (fun x q hq => key (n + 1) q (by have := pexpr_mem_lt_aux3 x q _ hq; size_lt))
          simp only [hc]
        case PEmemop mop pes =>
          congr 1
          exact hph _ _ pes (fun q hq => by have := pexpr_mem_lt_aux2 q _ hq; size_lt)
        case PEstruct tag xs =>
          congr 1
          exact pull_helper_congr _ _ _ xs (fun x q hq => key (n + 1) q (by have := pexpr_mem_lt_aux4 x q _ hq; size_lt))
        case PEcall nm pes =>
          congr 1
          exact hph _ _ pes (fun q hq => by have := pexpr_mem_lt_aux2 q _ hq; size_lt)
        case PEif pe1 pe2 pe3 =>
          congr 1
          exact hph _ _ [pe1, pe2, pe3] (fun q hq => by
            simp only [List.mem_cons, List.mem_singleton, List.not_mem_nil, or_false] at hq
            rcases hq with rfl | rfl | rfl <;> size_lt)

/-- THE OBLIGATION, exactly as Core_eval_auxiliary.lean states and delegates it. -/
theorem pull_constrained_measure_sufficient (n : Nat) (g : generic_pexpr Unit sym) (lemFuel : Nat)
    (lemMeasureLe : generic_pexpr.lemSize g ≤ lemFuel) :
    pull_constrained_lemFuel lemFuel n g = pull_constrained n g :=
  pull_constrained_stable_aux (generic_pexpr.lemSize g) n g lemFuel (generic_pexpr.lemSize g)
    (Nat.le_refl _) lemMeasureLe (Nat.le_refl _)

theorem step_eval_pexpr_stable_aux [LemFuel] (k : Nat) :
    ∀ (td : Fmap sym (CerbLocation.Loc × tag_definition)) (n : Nat) (loc1 : CerbLocation.Loc)
      (pcl : Option CerbLocation.Loc) (ce : Fmap sym sym) (env1 : List (Fmap sym value))
      (mso : Option CerbMem.MemState) (file1 : generic_file Unit core_run_annotation) (hc : Bool)
      (e : generic_pexpr Unit sym) (f g : Nat),
    generic_pexpr.lemSize e ≤ k → generic_pexpr.lemSize e ≤ f → generic_pexpr.lemSize e ≤ g →
    step_eval_pexpr_lemFuel f td n loc1 pcl ce env1 mso file1 hc e =
      step_eval_pexpr_lemFuel g td n loc1 pcl ce env1 mso file1 hc e := by
  induction k with
  | zero => intro td n loc1 pcl ce env1 mso file1 hc e f g hk _ _; have := pexpr_lemSize_pos e; omega
  | succ k ih =>
    intro td n loc1 pcl ce env1 mso file1 hc e f g hk hf hg
    cases f with
    | zero => have := pexpr_lemSize_pos e; omega
    | succ f =>
      cases g with
      | zero => have := pexpr_lemSize_pos e; omega
      | succ g =>
        have key : ∀ (m : Nat) (hc' : Bool) (y : generic_pexpr Unit sym),
            generic_pexpr.lemSize y < generic_pexpr.lemSize e →
            step_eval_pexpr_lemFuel f td m loc1 pcl ce env1 mso file1 hc' y =
              step_eval_pexpr_lemFuel g td m loc1 pcl ce env1 mso file1 hc' y :=
          fun m hc' y hy => ih td m loc1 pcl ce env1 mso file1 hc' y f g (by omega) (by omega) (by omega)
        obtain ⟨an, u, pexpr_⟩ := e
        cases u
        cases pexpr_ <;> simp (disch := size_lt) only [step_eval_pexpr_lemFuel, key]
        case PEctor ctor1 pes =>
          congr 2
          apply exception_undef_mapM_congr; intro q hq
          exact key (n + 1) false q (by have := pexpr_mem_lt_aux2 q _ hq; size_lt)
        case PEmemop mop pes =>
          congr 2
          apply exception_undef_mapM_congr; intro q hq
          exact key (n + 1) false q (by have := pexpr_mem_lt_aux2 q _ hq; size_lt)
        case PEcall nm pes =>
          congr 2
          apply exception_undef_mapM_congr; intro q hq
          exact key (n + 1) false q (by have := pexpr_mem_lt_aux2 q _ hq; size_lt)
        case PEnot q =>
          obtain ⟨an', b', q_⟩ := q
          simp (disch := size_lt) only [key]
        case PEop binop1 pe1 pe2 =>
          congr 1
          exact step_eval_peop_congr loc1 _ _ binop1 pe1 pe2
            (key (n + 1) false pe1 (by size_lt)) (key (n + 1) false pe2 (by size_lt))
        case PEstruct tag ident_pes =>
          rcases hz : lemListUnzip ident_pes with ⟨idents1, pes⟩
          simp only []
          congr 2
          apply exception_undef_mapM_congr; intro q hq
          have hq' : q ∈ (lemListUnzip ident_pes).2 := by rw [hz]; exact hq
          obtain ⟨x, hx⟩ := mem_unzip_snd q ident_pes hq'
          exact key (n + 1) false q (by have := pexpr_mem_lt_aux4 x q _ hx; size_lt)

/-- THE OBLIGATION, exactly as Core_eval_auxiliary.lean states and delegates it. -/
theorem step_eval_pexpr_measure_sufficient [LemFuel] (_lemReader_tagDefs : Fmap sym (CerbLocation.Loc × tag_definition))
    (n : Nat) (loc1 : CerbLocation.Loc) (parent_call_loc_opt : Option CerbLocation.Loc)
    (core_extern1 : Fmap sym sym) (env1 : List (Fmap sym value)) (mem_st_opt : Option CerbMem.MemState)
    (file1 : generic_file Unit core_run_annotation) (hasConstrained : Bool) (pexpr1 : generic_pexpr Unit sym)
    (lemFuel : Nat) (lemMeasureLe : generic_pexpr.lemSize pexpr1 ≤ lemFuel) :
    step_eval_pexpr_lemFuel lemFuel _lemReader_tagDefs n loc1 parent_call_loc_opt core_extern1 env1 mem_st_opt file1 hasConstrained pexpr1 =
      step_eval_pexpr _lemReader_tagDefs n loc1 parent_call_loc_opt core_extern1 env1 mem_st_opt file1 hasConstrained pexpr1 :=
  step_eval_pexpr_stable_aux (generic_pexpr.lemSize pexpr1) _lemReader_tagDefs n loc1 parent_call_loc_opt core_extern1
    env1 mem_st_opt file1 hasConstrained pexpr1 lemFuel (generic_pexpr.lemSize pexpr1) (Nat.le_refl _) lemMeasureLe (Nat.le_refl _)

end Core_eval_lemMeasureProofs
