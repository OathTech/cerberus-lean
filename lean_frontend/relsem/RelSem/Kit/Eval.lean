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

end RelSem.Kit
