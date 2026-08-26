/-
  RelSem.Kit.Eval — arc-9 S2 (2026-08-20): L1 kit, the pure-eval
  crossing layer (design docs/2026-08-20_arc9-s1-design.md §1.2,
  [IN-HOUSE promote + KIT-EXTRACT]).

  MOVED here from RelSem/T1AppEq.lean (golean lift-wave rule: extract,
  pin, delete duplicates — T1AppEq now imports this file): the
  exception/state-exception monad crossings (`eubind_defined`,
  `stub_defined`, `eumapM_one`), the `liftCore_run` crossing, and the
  eval_pexpr_aux2 loop laws (`aux2_step`, `aux2_done`). All fully
  generic; the fixture-specific residual ladders stay with their
  fixtures.

  Import discipline (design §6): no Iris, no fixtures.

  House rules: no sorry, no axioms declared here. Pins in Kit/Audit.
-/

import RelSem.Machine
import RelSem.Cerberus
import RelSem.Tactics.AppEqAttr
import RelSem.LawRegistry

set_option autoImplicit false

namespace RelSem.Kit

open RelSem RelSem.Cerb

/-! ### Eval-monad crossing lemmas (the `app_bind_active` pattern at
    the exception/state-exception monads — generic, proved once) -/

theorem eubind_defined {A B C : Type} {m : exceptM (t0 C) B}
    {f : C → exceptM (t0 A) B} {z : C}
    (h : m = Result (Defined z)) : exception_undef_bind m f = f z := by
  simp only [exception_undef_bind, h]

theorem stub_defined {A B C D E : Type} {m : E → exceptM (t0 D × A) C}
    {f : D → A → exceptM (t0 B × A) C} {st : E} {z : D} {st' : A}
    (h : m st = Result (Defined z, st')) :
    stExceptUndef_bind m f st = f z st' := by
  simp only [stExceptUndef_bind, h]

/-- mapM on a singleton (generic). -/
theorem eumapM_one {A C M : Type} {f : C → exceptM (t0 A) M} {a : C} {b : A}
    (h : f a = Result (Defined b)) :
    exception_undef_mapM f [a] = Result (Defined [b]) := by
  simp [exception_undef_mapM, except_mapM, except_bind, except_return, h,
    mapM1, except_sequence, sequence0, bind2, return1]

/-- Crossing lemma for `liftCore_run` at a Defined verdict (generic). -/
@[app_eq]
theorem liftCore_run_defined {A : Type}
    {m : core_run_state → exceptM (t0 A × core_run_state) core_run_cause}
    {dr : driver_state} {z : A} {rs' : core_run_state}
    (h : m dr.core_run_state0 = Result (Defined z, rs')) :
    app (liftCore_run m) dr
      = (NDactive z, { dr with core_run_state0 := rs' }) := by
  refine (app_bind_active (app_nd_get dr)).trans ?_
  simp only [stExceptUndef_run, h]
  rfl

/-! ### The eval_pexpr_aux2 loop laws (one iteration / exit) -/

/-- One iteration of the eval_pexpr_aux2 loop (generic; the debug print
    is a Unit match). -/
theorem aux2_step (fuel : Nat)
    (tag : Fmap sym (CerbLocation.Loc × tag_definition))
    (loc : CerbLocation.Loc) (cloc : Option CerbLocation.Loc)
    (ext : Fmap sym sym) (env : List (Fmap sym value))
    (memo : Option CerbMem.MemState) (file1 : file core_run_annotation)
    {pe peP pe' : generic_pexpr Unit sym}
    (hpull : pull_constrained 0 pe = peP)
    (hnc : ∀ (a : List annot) (xs : List (mem_iv_constraint × generic_pexpr Unit sym)), peP ≠ Pexpr a () (PEconstrained xs))
    (hstep : step_eval_pexpr tag 0 loc cloc ext env memo file1 false peP
      = Result (Defined pe'))
    (hnv : valueFromPexpr pe' = none) :
    eval_pexpr_aux2_lemFuel (fuel+1) tag loc cloc ext env memo file1 pe
      = eval_pexpr_aux2_lemFuel fuel tag loc cloc ext env memo file1 pe' := by
  rw [eval_pexpr_aux2_lemFuel]
  simp only [hpull, hstep, hnv, eubind_defined hstep,
    eubind_defined (rfl : (Result (Defined pe') :
      exceptM (t0 (generic_pexpr Unit sym)) core_run_cause)
        = Result (Defined pe'))]

/-- Loop exit: the step produced a value. -/
theorem aux2_done (fuel : Nat)
    (tag : Fmap sym (CerbLocation.Loc × tag_definition))
    (loc : CerbLocation.Loc) (cloc : Option CerbLocation.Loc)
    (ext : Fmap sym sym) (env : List (Fmap sym value))
    (memo : Option CerbMem.MemState) (file1 : file core_run_annotation)
    {pe peP pe' : generic_pexpr Unit sym} {v : value}
    (hpull : pull_constrained 0 pe = peP)
    (hnc : ∀ (a : List annot) (xs : List (mem_iv_constraint × generic_pexpr Unit sym)), peP ≠ Pexpr a () (PEconstrained xs))
    (hstep : step_eval_pexpr tag 0 loc cloc ext env memo file1 false peP
      = Result (Defined pe'))
    (hv : valueFromPexpr pe' = some v) :
    eval_pexpr_aux2_lemFuel (fuel+1) tag loc cloc ext env memo file1 pe
      = Result (Defined (Sum.inr v)) := by
  rw [eval_pexpr_aux2_lemFuel]
  simp only [hpull, hstep, hv, eubind_defined hstep,
    eubind_defined (rfl : (Result (Defined pe') :
      exceptM (t0 (generic_pexpr Unit sym)) core_run_cause)
        = Result (Defined pe'))]
  rfl

/-! ### THE PULL_CONSTRAINED IDENTITY LAW (arc-18 C3; the arc-17 S3
    record §3.4's priced construct law). Mirror citations:
    `pull_helper` / `pull_constrained_lemFuel` /
    `pull_constrained` — generated/Core_eval.lean (from
    frontend/model/core_eval.lem). The mirror `pullSpine` tracks the
    generated traversal ARM BY ARM; a generated-surface change that
    alters the traversal breaks `pull_constrained_spine`'s per-arm
    proofs loudly (the lockstep discipline, law-local). -/

/-- `true` iff the top node is not a `PEconstrained`. -/
def notConstrained : generic_pexpr Unit sym → Bool
  | Pexpr _ _ (PEconstrained _) => false
  | _ => true

/-- THE PULL SPINE (mirror of `pull_constrained_lemFuel`,
    generated/Core_eval.lean — the traversal at CONSTRAINT-FREE
    pexprs): `some peP` iff the traversal completes within `fuel`
    and meets no `PEconstrained` node; `peP` is then exactly
    `pull_constrained_lemFuel fuel n pe`'s result (the law below).
    Mirrors the generated code's rebuild discipline: visited wrap
    nodes are re-annotated `[]`; list children (wrap_list/pull_helper
    positions) are kept VERBATIM. -/
def pullSpine : Nat → generic_pexpr Unit sym →
    Option (generic_pexpr Unit sym)
  | 0, _ => none
  | fuel+1, Pexpr _ _ pe_ =>
    (match pe_ with
     | PEsym s => some (PEsym s)
     | PEimpl i => some (PEimpl i)
     | PEval v => some (PEval v)
     | PEconstrained _ => none
     | PEundef l ub => some (PEundef l ub)
     | PEerror s pe => (pullSpine fuel pe).map (PEerror s)
     | PEctor c pes =>
        if pes.all (fun pe => (pullSpine fuel pe).isSome) then
          some (PEctor c pes) else none
     | PEcase pe pat_pes =>
        (pullSpine fuel pe).bind fun p =>
          if pat_pes.all (fun pp => (pullSpine fuel pp.2).isSome) then
            some (PEcase p pat_pes) else none
     | PEarray_shift pe1 ty pe2 =>
        (pullSpine fuel pe1).bind fun p1 =>
          (pullSpine fuel pe2).map fun p2 => PEarray_shift p1 ty p2
     | PEmember_shift pe s i =>
        (pullSpine fuel pe).map fun p => PEmember_shift p s i
     | PEmemop m pes =>
        if pes.all (fun pe => (pullSpine fuel pe).isSome) then
          some (PEmemop m pes) else none
     | PEnot pe => (pullSpine fuel pe).map PEnot
     | PEop b pe1 pe2 =>
        (pullSpine fuel pe1).bind fun p1 =>
          (pullSpine fuel pe2).map fun p2 => PEop b p1 p2
     | PEconv_int ity pe => (pullSpine fuel pe).map (PEconv_int ity)
     | PEwrapI ity iop pe1 pe2 =>
        (pullSpine fuel pe1).bind fun p1 =>
          (pullSpine fuel pe2).map fun p2 => PEwrapI ity iop p1 p2
     | PEcatch_exceptional_condition ity iop pe1 pe2 =>
        (pullSpine fuel pe1).bind fun p1 =>
          (pullSpine fuel pe2).map fun p2 =>
            PEcatch_exceptional_condition ity iop p1 p2
     | PEstruct s xs =>
        if xs.all (fun pp => (pullSpine fuel pp.2).isSome) then
          some (PEstruct s xs) else none
     | PEunion s i pe => (pullSpine fuel pe).map (PEunion s i)
     | PEcfunction pe => (pullSpine fuel pe).map PEcfunction
     | PEmemberof s i pe => (pullSpine fuel pe).map (PEmemberof s i)
     | PEcall nm pes =>
        if pes.all (fun pe => (pullSpine fuel pe).isSome) then
          some (PEcall nm pes) else none
     | PElet pat pe1 pe2 =>
        (pullSpine fuel pe1).bind fun p1 =>
          (pullSpine fuel pe2).map fun p2 => PElet pat p1 p2
     | PEif pe1 pe2 pe3 =>
        if ([pe1, pe2, pe3]).all (fun pe => (pullSpine fuel pe).isSome) then
          some (PEif pe1 pe2 pe3) else none
     | PEis_scalar pe => (pullSpine fuel pe).map PEis_scalar
     | PEis_integer pe => (pullSpine fuel pe).map PEis_integer
     | PEis_signed pe => (pullSpine fuel pe).map PEis_signed
     | PEis_unsigned pe => (pullSpine fuel pe).map PEis_unsigned
     | PEbmc_assume pe => (pullSpine fuel pe).map PEbmc_assume
     | PEare_compatible pe1 pe2 =>
        (pullSpine fuel pe1).bind fun p1 =>
          (pullSpine fuel pe2).map fun p2 => PEare_compatible p1 p2
    ).map (Pexpr [] ())

/-- The spine result never has a `PEconstrained` head. -/
theorem pullSpine_notConstrained :
    ∀ {fuel : Nat} {pe p : generic_pexpr Unit sym},
    pullSpine fuel pe = some p → notConstrained p = true := by
  intro fuel pe p h
  match fuel, pe with
  | 0, _ => simp [pullSpine] at h
  | fuel+1, Pexpr a u pe_ =>
    cases pe_ <;>
      simp only [pullSpine, Option.map_eq_some_iff,
        Option.bind_eq_some_iff, Option.map_some, Option.some.injEq] at h <;>
      (try obtain ⟨q1, hq1, h⟩ := h) <;>
      (try obtain ⟨q2, hq2, hq1⟩ := hq1) <;>
      (try obtain ⟨q3, hq3, hq1⟩ := hq1) <;>
      (try split at h) <;>
      (try split at hq1) <;>
      (try simp only [Option.some.injEq] at hq1) <;>
      subst_vars <;>
      first
        | rfl
        | simp_all [notConstrained]

/-- foldl over a Sum accumulator that stays in `inr`, one cons per
    element (the `pull_helper` fold's constraint-free invariant). -/
theorem foldl_inr_of_step {R S : Type}
    {F : Sum R (List S) → S → Sum R (List S)} {P : S → Prop}
    (hstep : ∀ acc x, P x → F (Sum.inr acc) x = Sum.inr (x :: acc)) :
    ∀ (xs : List S) (acc : List S), (∀ x ∈ xs, P x) →
      List.foldl F (Sum.inr acc) xs = Sum.inr (xs.reverse ++ acc) := by
  intro xs
  induction xs with
  | nil => intro acc _; simp
  | cons x xs ihx =>
    intro acc hall
    rw [List.foldl_cons, hstep acc x (hall x (by simp)),
      ihx (x :: acc) (fun y hy => hall y (by simp [hy]))]
    simp

/-- `pull_helper` at constraint-free children is the identity on the
    pair list (mirror-cited: generated/Core_eval.lean `pull_helper` —
    the `Sum.inr` arm keeps the ORIGINAL `pe`, so no annotation
    stripping happens in list positions). -/
theorem pull_helper_id {A B : Type}
    (pull : generic_pexpr Unit sym → generic_pexpr Unit sym)
    (pe_cons : List (A × generic_pexpr Unit sym) → generic_pexpr_ Unit B)
    (ps : List (A × generic_pexpr Unit sym))
    (hnc : ∀ p ∈ ps, notConstrained (pull p.2) = true) :
    pull_helper pull pe_cons ps = pe_cons ps := by
  rw [pull_helper]
  rw [foldl_inr_of_step (P := fun p => notConstrained (pull p.2) = true)
      ?hstep ps [] hnc]
  case hstep =>
    intro acc x hx
    obtain ⟨a1, pe⟩ := x
    simp only []
    split
    · next heq => rw [heq] at hx; simp [notConstrained] at hx
    · rfl
  · simp

/-- THE PULL_CONSTRAINED IDENTITY LAW (fuel face): on
    constraint-free pexprs (`pullSpine fuel pe = some peP` — the
    fail-closed structural check, fuel mirroring the traversal
    depth), `pull_constrained_lemFuel` is exactly the `pullSpine`
    rebuild: annotations strip at wrap nodes, list children stay
    verbatim, and NO constraint-set plumbing is entered. The arc-17
    S3 record §3.4's priced mechanism ("a LAW, not a lane"): the
    concrete memory model never emits `PEconstrained`, so every
    walk's crossing of `pull_constrained` is this identity — the
    constraint-set dedup wall is deleted by construction. -/
@[step_law (kind := evalPull) (variant := fuel) (side := rfl)
  (frontier := "eval/pull-constrained")
  (trace := "{law := pull_constrained_spine, joint := eval-pull, hyps := [h : rfl]}")
  (lineage := "identity of the constraint-pull traversal on constraint-free pexprs, proved once by fuel induction against generated Core_eval.lean pull_constrained_lemFuel (mirror: pullSpine; arc-17 S3 \u00a73.4 priced law, landed arc-18 C3)")]
theorem pull_constrained_spine :
    ∀ (fuel : Nat) (pe peP : generic_pexpr Unit sym) (n : Nat),
    pullSpine fuel pe = some peP →
    pull_constrained_lemFuel fuel n pe = peP := by
  intro fuel
  induction fuel with
  | zero => intro pe peP n h; simp [pullSpine] at h
  | succ fuel ih =>
    intro pe peP n h
    -- shared discharge helpers at this fuel/n
    have hself : ∀ (pe1 q : generic_pexpr Unit sym),
        pullSpine fuel pe1 = some q →
        pull_constrained_lemFuel fuel (n+1) pe1 = q := fun pe1 q hq =>
      ih pe1 q (n+1) hq
    have hncSelf : ∀ (pe1 q : generic_pexpr Unit sym),
        pullSpine fuel pe1 = some q →
        notConstrained (pull_constrained_lemFuel fuel (n+1) pe1) = true :=
      fun pe1 q hq => (hself pe1 q hq) ▸ pullSpine_notConstrained hq
    have hlistNC : ∀ {A : Type}
        (ps : List (A × generic_pexpr Unit sym)),
        ps.all (fun pp => (pullSpine fuel pp.2).isSome) = true →
        ∀ p ∈ ps, notConstrained
          (pull_constrained_lemFuel fuel (n+1) p.2) = true := by
      intro A ps hall p hp
      obtain ⟨q, hq⟩ := Option.isSome_iff_exists.mp
        (List.all_eq_true.mp hall p hp)
      exact hncSelf p.2 q hq
    have hmapNC : ∀ (pes : List (generic_pexpr Unit sym)),
        pes.all (fun pe => (pullSpine fuel pe).isSome) = true →
        ∀ (p : Unit × generic_pexpr Unit sym),
          p ∈ pes.map (fun pe => ((), pe)) →
          notConstrained
            (pull_constrained_lemFuel fuel (n+1) p.2) = true := by
      intro pes hall p hp
      obtain ⟨pe0, hpe0, rfl⟩ := List.mem_map.mp hp
      obtain ⟨q, hq⟩ := Option.isSome_iff_exists.mp
        (List.all_eq_true.mp hall pe0 hpe0)
      exact hncSelf pe0 q hq
    obtain ⟨a, u, pe_⟩ := pe
    cases u
    cases pe_ with
    | PEsym s =>
      rw [pull_constrained_lemFuel]
      simp only [pullSpine, Option.map_some, Option.some.injEq] at h
      subst h; rfl
    | PEimpl i =>
      rw [pull_constrained_lemFuel]
      simp only [pullSpine, Option.map_some, Option.some.injEq] at h
      subst h; rfl
    | PEval v =>
      rw [pull_constrained_lemFuel]
      simp only [pullSpine, Option.map_some, Option.some.injEq] at h
      subst h; rfl
    | PEconstrained xs =>
      simp [pullSpine] at h
    | PEundef l ub =>
      rw [pull_constrained_lemFuel]
      simp only [pullSpine, Option.map_some, Option.some.injEq] at h
      subst h; rfl
    | PEerror s pe1 =>
      rw [pull_constrained_lemFuel]
      simp only [pullSpine, Option.map_eq_some_iff] at h
      obtain ⟨_, ⟨q, hq, rfl⟩, rfl⟩ := h
      have hnc := hncSelf pe1 q hq
      simp only [hself pe1 q hq] at hnc ⊢
      split
      all_goals
        first
          | rfl
          | (rename_i heq; rw [heq] at hnc; simp [notConstrained] at hnc)
          | (rename_i heq _; rw [heq] at hnc; simp [notConstrained] at hnc)
          | simp_all [notConstrained]
    | PEctor c pes =>
      rw [pull_constrained_lemFuel]
      simp only [pullSpine] at h
      split at h
      · next hall =>
        simp only [Option.map_some, Option.some.injEq] at h
        subst h
        refine congrArg (Pexpr [] ()) ?_
        refine (pull_helper_id _ _ _ (hmapNC pes hall)).trans ?_
        simp [List.map_map, Function.comp_def]
      · simp at h
    | PEcase pe1 pat_pes =>
      rw [pull_constrained_lemFuel]
      simp only [pullSpine, Option.map_eq_some_iff,
        Option.bind_eq_some_iff] at h
      obtain ⟨_, ⟨q, hq, h2⟩, rfl⟩ := h
      split at h2
      · next hall =>
        simp only [Option.some.injEq] at h2
        subst h2
        have hnc := hncSelf pe1 q hq
        simp only [hself pe1 q hq] at hnc ⊢
        split
        all_goals
          first
            | exact congrArg (Pexpr [] ())
                (pull_helper_id _ _ _ (hlistNC pat_pes hall))
            | (rename_i heq; rw [heq] at hnc; simp [notConstrained] at hnc)
            | (rename_i heq _; rw [heq] at hnc; simp [notConstrained] at hnc)
            | simp_all [notConstrained]
      · simp at h2
    | PEarray_shift pe1 ty pe2 =>
      rw [pull_constrained_lemFuel]
      simp only [pullSpine, Option.map_eq_some_iff,
        Option.bind_eq_some_iff] at h
      obtain ⟨_, ⟨q1, hq1, q2, hq2, rfl⟩, rfl⟩ := h
      have hnc1 := hncSelf pe1 q1 hq1
      have hnc2 := hncSelf pe2 q2 hq2
      simp only [hself pe1 q1 hq1, hself pe2 q2 hq2] at hnc1 hnc2 ⊢
      split
      all_goals
        first
          | rfl
          | (rename_i heq; rw [heq] at hnc1; simp [notConstrained] at hnc1)
          | (rename_i heq; rw [heq] at hnc2; simp [notConstrained] at hnc2)
          | (rename_i heq _; rw [heq] at hnc1; simp [notConstrained] at hnc1)
          | (rename_i heq _; rw [heq] at hnc2; simp [notConstrained] at hnc2)
          | simp_all [notConstrained]
    | PEmember_shift pe1 s i =>
      rw [pull_constrained_lemFuel]
      simp only [pullSpine, Option.map_eq_some_iff] at h
      obtain ⟨_, ⟨q, hq, rfl⟩, rfl⟩ := h
      have hnc := hncSelf pe1 q hq
      simp only [hself pe1 q hq] at hnc ⊢
      split
      all_goals
        first
          | rfl
          | (rename_i heq; rw [heq] at hnc; simp [notConstrained] at hnc)
          | (rename_i heq _; rw [heq] at hnc; simp [notConstrained] at hnc)
          | simp_all [notConstrained]
    | PEmemop m pes =>
      rw [pull_constrained_lemFuel]
      simp only [pullSpine] at h
      split at h
      · next hall =>
        simp only [Option.map_some, Option.some.injEq] at h
        subst h
        refine congrArg (Pexpr [] ()) ?_
        refine (pull_helper_id _ _ _ (hmapNC pes hall)).trans ?_
        simp [List.map_map, Function.comp_def]
      · simp at h
    | PEnot pe1 =>
      rw [pull_constrained_lemFuel]
      simp only [pullSpine, Option.map_eq_some_iff] at h
      obtain ⟨_, ⟨q, hq, rfl⟩, rfl⟩ := h
      have hnc := hncSelf pe1 q hq
      simp only [hself pe1 q hq] at hnc ⊢
      split
      all_goals
        first
          | rfl
          | (rename_i heq; rw [heq] at hnc; simp [notConstrained] at hnc)
          | (rename_i heq _; rw [heq] at hnc; simp [notConstrained] at hnc)
          | simp_all [notConstrained]
    | PEop b pe1 pe2 =>
      rw [pull_constrained_lemFuel]
      simp only [pullSpine, Option.map_eq_some_iff,
        Option.bind_eq_some_iff] at h
      obtain ⟨_, ⟨q1, hq1, q2, hq2, rfl⟩, rfl⟩ := h
      have hnc1 := hncSelf pe1 q1 hq1
      have hnc2 := hncSelf pe2 q2 hq2
      simp only [hself pe1 q1 hq1, hself pe2 q2 hq2] at hnc1 hnc2 ⊢
      split
      all_goals
        first
          | rfl
          | (rename_i heq; rw [heq] at hnc1; simp [notConstrained] at hnc1)
          | (rename_i heq; rw [heq] at hnc2; simp [notConstrained] at hnc2)
          | (rename_i heq _; rw [heq] at hnc1; simp [notConstrained] at hnc1)
          | (rename_i heq _; rw [heq] at hnc2; simp [notConstrained] at hnc2)
          | simp_all [notConstrained]
    | PEconv_int ity pe1 =>
      rw [pull_constrained_lemFuel]
      simp only [pullSpine, Option.map_eq_some_iff] at h
      obtain ⟨_, ⟨q, hq, rfl⟩, rfl⟩ := h
      have hnc := hncSelf pe1 q hq
      simp only [hself pe1 q hq] at hnc ⊢
      split
      all_goals
        first
          | rfl
          | (rename_i heq; rw [heq] at hnc; simp [notConstrained] at hnc)
          | (rename_i heq _; rw [heq] at hnc; simp [notConstrained] at hnc)
          | simp_all [notConstrained]
    | PEwrapI ity iop pe1 pe2 =>
      rw [pull_constrained_lemFuel]
      simp only [pullSpine, Option.map_eq_some_iff,
        Option.bind_eq_some_iff] at h
      obtain ⟨_, ⟨q1, hq1, q2, hq2, rfl⟩, rfl⟩ := h
      have hnc1 := hncSelf pe1 q1 hq1
      have hnc2 := hncSelf pe2 q2 hq2
      simp only [hself pe1 q1 hq1, hself pe2 q2 hq2] at hnc1 hnc2 ⊢
      split
      all_goals
        first
          | rfl
          | (rename_i heq; rw [heq] at hnc1; simp [notConstrained] at hnc1)
          | (rename_i heq; rw [heq] at hnc2; simp [notConstrained] at hnc2)
          | (rename_i heq _; rw [heq] at hnc1; simp [notConstrained] at hnc1)
          | (rename_i heq _; rw [heq] at hnc2; simp [notConstrained] at hnc2)
          | simp_all [notConstrained]
    | PEcatch_exceptional_condition ity iop pe1 pe2 =>
      rw [pull_constrained_lemFuel]
      simp only [pullSpine, Option.map_eq_some_iff,
        Option.bind_eq_some_iff] at h
      obtain ⟨_, ⟨q1, hq1, q2, hq2, rfl⟩, rfl⟩ := h
      have hnc1 := hncSelf pe1 q1 hq1
      have hnc2 := hncSelf pe2 q2 hq2
      simp only [hself pe1 q1 hq1, hself pe2 q2 hq2] at hnc1 hnc2 ⊢
      split
      all_goals
        first
          | rfl
          | (rename_i heq; rw [heq] at hnc1; simp [notConstrained] at hnc1)
          | (rename_i heq; rw [heq] at hnc2; simp [notConstrained] at hnc2)
          | (rename_i heq _; rw [heq] at hnc1; simp [notConstrained] at hnc1)
          | (rename_i heq _; rw [heq] at hnc2; simp [notConstrained] at hnc2)
          | simp_all [notConstrained]
    | PEstruct s xs =>
      rw [pull_constrained_lemFuel]
      simp only [pullSpine] at h
      split at h
      · next hall =>
        simp only [Option.map_some, Option.some.injEq] at h
        subst h
        exact congrArg (Pexpr [] ()) (pull_helper_id _ _ _ (hlistNC xs hall))
      · simp at h
    | PEunion s i pe1 =>
      rw [pull_constrained_lemFuel]
      simp only [pullSpine, Option.map_eq_some_iff] at h
      obtain ⟨_, ⟨q, hq, rfl⟩, rfl⟩ := h
      have hnc := hncSelf pe1 q hq
      simp only [hself pe1 q hq] at hnc ⊢
      split
      all_goals
        first
          | rfl
          | (rename_i heq; rw [heq] at hnc; simp [notConstrained] at hnc)
          | (rename_i heq _; rw [heq] at hnc; simp [notConstrained] at hnc)
          | simp_all [notConstrained]
    | PEcfunction pe1 =>
      rw [pull_constrained_lemFuel]
      simp only [pullSpine, Option.map_eq_some_iff] at h
      obtain ⟨_, ⟨q, hq, rfl⟩, rfl⟩ := h
      have hnc := hncSelf pe1 q hq
      simp only [hself pe1 q hq] at hnc ⊢
      split
      all_goals
        first
          | rfl
          | (rename_i heq; rw [heq] at hnc; simp [notConstrained] at hnc)
          | (rename_i heq _; rw [heq] at hnc; simp [notConstrained] at hnc)
          | simp_all [notConstrained]
    | PEmemberof s i pe1 =>
      rw [pull_constrained_lemFuel]
      simp only [pullSpine, Option.map_eq_some_iff] at h
      obtain ⟨_, ⟨q, hq, rfl⟩, rfl⟩ := h
      have hnc := hncSelf pe1 q hq
      simp only [hself pe1 q hq] at hnc ⊢
      split
      all_goals
        first
          | rfl
          | (rename_i heq; rw [heq] at hnc; simp [notConstrained] at hnc)
          | (rename_i heq _; rw [heq] at hnc; simp [notConstrained] at hnc)
          | simp_all [notConstrained]
    | PEcall nm pes =>
      rw [pull_constrained_lemFuel]
      simp only [pullSpine] at h
      split at h
      · next hall =>
        simp only [Option.map_some, Option.some.injEq] at h
        subst h
        refine congrArg (Pexpr [] ()) ?_
        refine (pull_helper_id _ _ _ (hmapNC pes hall)).trans ?_
        simp [List.map_map, Function.comp_def]
      · simp at h
    | PElet pat pe1 pe2 =>
      rw [pull_constrained_lemFuel]
      simp only [pullSpine, Option.map_eq_some_iff,
        Option.bind_eq_some_iff] at h
      obtain ⟨_, ⟨q1, hq1, q2, hq2, rfl⟩, rfl⟩ := h
      have hnc1 := hncSelf pe1 q1 hq1
      have hnc2 := hncSelf pe2 q2 hq2
      simp only [hself pe1 q1 hq1, hself pe2 q2 hq2] at hnc1 hnc2 ⊢
      split
      all_goals
        first
          | rfl
          | (rename_i heq; rw [heq] at hnc1; simp [notConstrained] at hnc1)
          | (rename_i heq; rw [heq] at hnc2; simp [notConstrained] at hnc2)
          | (rename_i heq _; rw [heq] at hnc1; simp [notConstrained] at hnc1)
          | (rename_i heq _; rw [heq] at hnc2; simp [notConstrained] at hnc2)
          | simp_all [notConstrained]
    | PEif pe1 pe2 pe3 =>
      rw [pull_constrained_lemFuel]
      simp only [pullSpine] at h
      split at h
      · next hall =>
        simp only [Option.map_some, Option.some.injEq] at h
        subst h
        exact congrArg (Pexpr [] ())
          (pull_helper_id _ _ _ (hmapNC [pe1, pe2, pe3] hall))
      · simp at h
    | PEis_scalar pe1 =>
      rw [pull_constrained_lemFuel]
      simp only [pullSpine, Option.map_eq_some_iff] at h
      obtain ⟨_, ⟨q, hq, rfl⟩, rfl⟩ := h
      have hnc := hncSelf pe1 q hq
      simp only [hself pe1 q hq] at hnc ⊢
      split
      all_goals
        first
          | rfl
          | (rename_i heq; rw [heq] at hnc; simp [notConstrained] at hnc)
          | (rename_i heq _; rw [heq] at hnc; simp [notConstrained] at hnc)
          | simp_all [notConstrained]
    | PEis_integer pe1 =>
      rw [pull_constrained_lemFuel]
      simp only [pullSpine, Option.map_eq_some_iff] at h
      obtain ⟨_, ⟨q, hq, rfl⟩, rfl⟩ := h
      have hnc := hncSelf pe1 q hq
      simp only [hself pe1 q hq] at hnc ⊢
      split
      all_goals
        first
          | rfl
          | (rename_i heq; rw [heq] at hnc; simp [notConstrained] at hnc)
          | (rename_i heq _; rw [heq] at hnc; simp [notConstrained] at hnc)
          | simp_all [notConstrained]
    | PEis_signed pe1 =>
      rw [pull_constrained_lemFuel]
      simp only [pullSpine, Option.map_eq_some_iff] at h
      obtain ⟨_, ⟨q, hq, rfl⟩, rfl⟩ := h
      have hnc := hncSelf pe1 q hq
      simp only [hself pe1 q hq] at hnc ⊢
      split
      all_goals
        first
          | rfl
          | (rename_i heq; rw [heq] at hnc; simp [notConstrained] at hnc)
          | (rename_i heq _; rw [heq] at hnc; simp [notConstrained] at hnc)
          | simp_all [notConstrained]
    | PEis_unsigned pe1 =>
      rw [pull_constrained_lemFuel]
      simp only [pullSpine, Option.map_eq_some_iff] at h
      obtain ⟨_, ⟨q, hq, rfl⟩, rfl⟩ := h
      have hnc := hncSelf pe1 q hq
      simp only [hself pe1 q hq] at hnc ⊢
      split
      all_goals
        first
          | rfl
          | (rename_i heq; rw [heq] at hnc; simp [notConstrained] at hnc)
          | (rename_i heq _; rw [heq] at hnc; simp [notConstrained] at hnc)
          | simp_all [notConstrained]
    | PEbmc_assume pe1 =>
      rw [pull_constrained_lemFuel]
      simp only [pullSpine, Option.map_eq_some_iff] at h
      obtain ⟨_, ⟨q, hq, rfl⟩, rfl⟩ := h
      have hnc := hncSelf pe1 q hq
      simp only [hself pe1 q hq] at hnc ⊢
      split
      all_goals
        first
          | rfl
          | (rename_i heq; rw [heq] at hnc; simp [notConstrained] at hnc)
          | (rename_i heq _; rw [heq] at hnc; simp [notConstrained] at hnc)
          | simp_all [notConstrained]
    | PEare_compatible pe1 pe2 =>
      rw [pull_constrained_lemFuel]
      simp only [pullSpine, Option.map_eq_some_iff,
        Option.bind_eq_some_iff] at h
      obtain ⟨_, ⟨q1, hq1, q2, hq2, rfl⟩, rfl⟩ := h
      have hnc1 := hncSelf pe1 q1 hq1
      have hnc2 := hncSelf pe2 q2 hq2
      simp only [hself pe1 q1 hq1, hself pe2 q2 hq2] at hnc1 hnc2 ⊢
      split
      all_goals
        first
          | rfl
          | (rename_i heq; rw [heq] at hnc1; simp [notConstrained] at hnc1)
          | (rename_i heq; rw [heq] at hnc2; simp [notConstrained] at hnc2)
          | (rename_i heq _; rw [heq] at hnc1; simp [notConstrained] at hnc1)
          | (rename_i heq _; rw [heq] at hnc2; simp [notConstrained] at hnc2)
          | simp_all [notConstrained]

/-- THE PULL_CONSTRAINED IDENTITY LAW (wrapper face, at the
    generated call sites' `pull_constrained n pe` spelling —
    `lemDefaultFuel` covers every constructible pexpr depth). -/
@[step_law (kind := evalPull) (variant := wrapper) (side := rfl)
  (frontier := "eval/pull-constrained")
  (trace := "{law := pull_constrained_id, joint := eval-pull, hyps := [h : rfl]}")
  (lineage := "the fuel-face identity law at the generated wrapper spelling (pull_constrained = pull_constrained_lemFuel lemDefaultFuel; arc-18 C3)")]
theorem pull_constrained_id (n : Nat)
    {pe peP : generic_pexpr Unit sym}
    (h : pullSpine lemDefaultFuel pe = some peP) :
    pull_constrained n pe = peP :=
  pull_constrained_spine lemDefaultFuel pe peP n h

end RelSem.Kit
