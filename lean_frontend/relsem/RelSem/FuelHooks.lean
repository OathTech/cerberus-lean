/-
  RelSem.FuelHooks — arc-7 S3 (2026-08-20): the wrapper-defeq hooks for
  every fuel'd function on the T1-T4 (and T5) execution path.

  THE MECHANISM (arc-3 wrapper-defeq discipline, cf.
  test/Unit/TotalityProofTest.lean and the two hooks already named in
  RelSem/Cerberus.lean): each generated fuel'd function ships as a
  worker `f_lemFuel (lemFuel : Nat) …` plus an executable wrapper
  `f := f_lemFuel lemDefaultFuel`, definitionally equal BY RFL. A proof
  about the executable moves to the fuel-generic worker (where induction
  and fuel-erasure statements live) by citing the hook, never by
  unfolding a definition it doesn't own. The ∃-fuel erasure instances
  themselves are with the objects they erase: the runner's are in
  RelSem/RunND.lean (`Behaviors`, `runNDFuel_mono`, and the arc-7 S3
  singleton characterization `runND_active`/`behaviors_active_iff`);
  the pure-eval value-case instance is in RelSem/Cerberus.lean
  (`step_eval_pexpr_val_erase`).

  ENUMERATION EVIDENCE ([AGENT:S3]): the tests/verify trace runs show
  every T1-T5 execution is ONE bind-collapsed `app` computation (record
  in RelSem/Machine.lean § Coverage-by-need), so "the fuel'd functions
  on the execution path" = the fuel'd functions in the CALL GRAPH of
  that computation. Enumerated statically from the traversed code:

  * harness + runner spine (Nondeterminism/CerbND): `nd_bind`,
    `liftND`, `liftAction` (the `liftMem` lens), `CerbND.runND`
    (hook `runND_wrapper_defeq`, RelSem/RunND.lean);
  * driver loop (Driver): `driver2` (hook in RelSem/Cerberus.lean),
    `drive_nonmemory_steps_aux2`;
  * pure evaluation (Core_eval): `step_eval_pexpr` (hook in
    RelSem/Cerberus.lean), `eval_pexpr_aux2`, `pull_constrained`;
  * redex discovery / stepping (Core_reduction): `full_eval_pexpr`,
    `get_ctx`, `get_ctx_unseq_aux`, `has_ccall`, `one_step_unseq_aux`;
  * reduction bookkeeping (Core_aux): pattern matching + substitution
    (`match_pattern`, `in_pattern`, `subst_pattern`,
    `subst_pattern_val`, `subst_sym_expr`, `subst_sym_pexpr`,
    `unsafe_subst_pattern`, `unsafe_subst_sym_expr`,
    `unsafe_subst_sym_pexpr`, `update_env_aux`), save/run continuations
    (`find_labeled_continuation`, `find_labeled_continuation2_aux`,
    `collect_saves_aux`, `m_collect_saves_aux`), value/memory
    conversion (`to_pure`, `to_pures`, `loadedValueFromMemValue`,
    `memValueFromValue`, `zeros_aux`).

  Not hooked (off-path, deliberate): `eval_pexpr_aux_broken` (dead by
  name), `hack`/`print_eval_conv_aux` (debug printing), Core_run_aux's
  `convert_expr`/`convert_pexpr` (compile-time, upstream of the run),
  `add_to_sb`/`add_to_asw` (concurrency bookkeeping — declared
  boundary).

  House rules: no sorry, no axioms declared; every theorem is `rfl`.
  Under the in-build audit.
-/

import Driver
import Core_eval
import Core_reduction
import Core_aux
import Nondeterminism

set_option autoImplicit false

namespace RelSem
namespace FuelHooks

/-! ## Nondeterminism (the monadic spine) -/

theorem nd_bind_wrapper_defeq {a b c d e f : Type} :
    nd_bind (a := a) (b := b) (c := c) (d := d) (e := e) (f := f)
      = nd_bind_lemFuel lemDefaultFuel := rfl

theorem liftND_wrapper_defeq
    {a cs err1 err2 info1 info2 st1 st2 : Type} :
    liftND (a := a) (cs := cs) (err1 := err1) (err2 := err2)
        (info1 := info1) (info2 := info2) (st1 := st1) (st2 := st2)
      = liftND_lemFuel lemDefaultFuel := rfl

theorem liftAction_wrapper_defeq
    {a cs err1 err2 info1 info2 st1 st2 : Type} :
    liftAction (a := a) (cs := cs) (err1 := err1) (err2 := err2)
        (info1 := info1) (info2 := info2) (st1 := st1) (st2 := st2)
      = liftAction_lemFuel lemDefaultFuel := rfl

/-! ## Driver (the loop; `driver2`'s hook is in RelSem/Cerberus.lean) -/

theorem drive_nonmemory_steps_aux2_wrapper_defeq :
    drive_nonmemory_steps_aux2
      = drive_nonmemory_steps_aux2_lemFuel lemDefaultFuel := rfl

/-! ## Core_eval (pure evaluation; `step_eval_pexpr`'s hook is in
    RelSem/Cerberus.lean) -/

theorem eval_pexpr_aux2_wrapper_defeq :
    eval_pexpr_aux2 = eval_pexpr_aux2_lemFuel lemDefaultFuel := rfl

theorem pull_constrained_wrapper_defeq :
    pull_constrained = pull_constrained_lemFuel lemDefaultFuel := rfl

/-! ## Core_reduction (redex discovery / stepping) -/

theorem full_eval_pexpr_wrapper_defeq {b : Type} :
    full_eval_pexpr (b := b) = full_eval_pexpr_lemFuel lemDefaultFuel := rfl

theorem get_ctx_wrapper_defeq :
    get_ctx = get_ctx_lemFuel lemDefaultFuel := rfl

theorem get_ctx_unseq_aux_wrapper_defeq :
    get_ctx_unseq_aux = get_ctx_unseq_aux_lemFuel lemDefaultFuel := rfl

theorem has_ccall_wrapper_defeq {a b c : Type} :
    has_ccall (a := a) (b := b) (c := c)
      = has_ccall_lemFuel lemDefaultFuel := rfl

theorem one_step_unseq_aux_wrapper_defeq {a b : Type} :
    one_step_unseq_aux (a := a) (b := b)
      = one_step_unseq_aux_lemFuel lemDefaultFuel := rfl

/-! ## Core_aux: pattern matching + substitution -/

theorem match_pattern_wrapper_defeq :
    match_pattern = match_pattern_lemFuel lemDefaultFuel := rfl

theorem in_pattern_wrapper_defeq :
    in_pattern = in_pattern_lemFuel lemDefaultFuel := rfl

theorem subst_pattern_wrapper_defeq {a : Type} :
    subst_pattern (a := a) = subst_pattern_lemFuel lemDefaultFuel := rfl

theorem subst_pattern_val_wrapper_defeq {a : Type} :
    subst_pattern_val (a := a)
      = subst_pattern_val_lemFuel lemDefaultFuel := rfl

theorem subst_sym_expr_wrapper_defeq {a : Type} :
    subst_sym_expr (a := a) = subst_sym_expr_lemFuel lemDefaultFuel := rfl

theorem subst_sym_pexpr_wrapper_defeq :
    subst_sym_pexpr = subst_sym_pexpr_lemFuel lemDefaultFuel := rfl

theorem unsafe_subst_pattern_wrapper_defeq {a : Type} :
    unsafe_subst_pattern (a := a)
      = unsafe_subst_pattern_lemFuel lemDefaultFuel := rfl

theorem unsafe_subst_sym_expr_wrapper_defeq {a : Type} :
    unsafe_subst_sym_expr (a := a)
      = unsafe_subst_sym_expr_lemFuel lemDefaultFuel := rfl

theorem unsafe_subst_sym_pexpr_wrapper_defeq :
    unsafe_subst_sym_pexpr
      = unsafe_subst_sym_pexpr_lemFuel lemDefaultFuel := rfl

theorem update_env_aux_wrapper_defeq {a : Type} [Lem_Map.MapKeyType a] :
    update_env_aux (a := a) = update_env_aux_lemFuel lemDefaultFuel := rfl

/-! ## Core_aux: save/run labeled continuations -/

theorem find_labeled_continuation_wrapper_defeq
    {a b c : Type} [Lem_Basic_classes.Eq0 a] :
    find_labeled_continuation (a := a) (b := b) (c := c)
      = find_labeled_continuation_lemFuel lemDefaultFuel := rfl

theorem find_labeled_continuation2_aux_wrapper_defeq {a : Type} :
    find_labeled_continuation2_aux (a := a)
      = find_labeled_continuation2_aux_lemFuel lemDefaultFuel := rfl

theorem collect_saves_aux_wrapper_defeq {a : Type} :
    collect_saves_aux (a := a)
      = collect_saves_aux_lemFuel lemDefaultFuel := rfl

theorem m_collect_saves_aux_wrapper_defeq {a : Type} :
    m_collect_saves_aux (a := a)
      = m_collect_saves_aux_lemFuel lemDefaultFuel := rfl

/-! ## Core_aux: value/memory conversion -/

theorem to_pure_wrapper_defeq {a : Type} :
    to_pure (a := a) = to_pure_lemFuel lemDefaultFuel := rfl

theorem to_pures_wrapper_defeq {a : Type} :
    to_pures (a := a) = to_pures_lemFuel lemDefaultFuel := rfl

theorem loadedValueFromMemValue_wrapper_defeq :
    loadedValueFromMemValue
      = loadedValueFromMemValue_lemFuel lemDefaultFuel := rfl

theorem memValueFromValue_wrapper_defeq :
    memValueFromValue = memValueFromValue_lemFuel lemDefaultFuel := rfl

theorem zeros_aux_wrapper_defeq {a : Type} :
    zeros_aux (a := a) = zeros_aux_lemFuel lemDefaultFuel := rfl

end FuelHooks
end RelSem
