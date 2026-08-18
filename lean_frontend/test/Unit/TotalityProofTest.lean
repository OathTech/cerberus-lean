/-
  Arc-3 totality proofs (S3).

  Part 1 — wrapper defeq: for EVERY fuel'd def in the sweep, the point-free
  wrapper is definitionally the worker at lemDefaultFuel. Provable by rfl
  only because both exist as total defs with equations; each `example` is
  universally quantified over the def's actual arguments (reader parameters
  included — they are honest leading arguments of the wrapper type).

  Part 2 (below) — symbolic execution theorems over the newly-total spine.

  Compile-time proofs; main reports success at runtime.
-/

import LemLib
import Core_aux
import Core_eval
import Core_reduction
import Core_run_aux
import Ctype_aux
import Defacto_memory
import Defacto_memory_aux
import Driver
import Nondeterminism

open Lem_Basic_classes Lem_Map
set_option autoImplicit true

/-! ### Part 1: wrapper-defeq, one per fuel'd def -/

example : ∀ x1, loadedValueFromMemValue x1 = loadedValueFromMemValue_lemFuel lemDefaultFuel x1 := fun _ => rfl
example : ∀ x1 x2 x3, memValueFromValue x1 x2 x3 = memValueFromValue_lemFuel lemDefaultFuel x1 x2 x3 := fun _ _ _ => rfl
example : ∀ x1 x2, in_pattern x1 x2 = in_pattern_lemFuel lemDefaultFuel x1 x2 := fun _ _ => rfl
example : ∀ x1 x2 x3, subst_sym_pexpr x1 x2 x3 = subst_sym_pexpr_lemFuel lemDefaultFuel x1 x2 x3 := fun _ _ _ => rfl
example {a : Type} : ∀ x1 x2 x3, subst_sym_expr (a := a) x1 x2 x3 = subst_sym_expr_lemFuel (a := a) lemDefaultFuel x1 x2 x3 := fun _ _ _ => rfl
example {a : Type} : ∀ x1 x2 x3, subst_pattern_val (a := a) x1 x2 x3 = subst_pattern_val_lemFuel (a := a) lemDefaultFuel x1 x2 x3 := fun _ _ _ => rfl
example : ∀ x1 x2 x3, unsafe_subst_sym_pexpr x1 x2 x3 = unsafe_subst_sym_pexpr_lemFuel lemDefaultFuel x1 x2 x3 := fun _ _ _ => rfl
example {a : Type} : ∀ x1 x2 x3, unsafe_subst_sym_expr (a := a) x1 x2 x3 = unsafe_subst_sym_expr_lemFuel (a := a) lemDefaultFuel x1 x2 x3 := fun _ _ _ => rfl
example {a : Type} : ∀ x1 x2 x3, unsafe_subst_pattern (a := a) x1 x2 x3 = unsafe_subst_pattern_lemFuel (a := a) lemDefaultFuel x1 x2 x3 := fun _ _ _ => rfl
example {a : Type} : ∀ x1 x2 x3, subst_pattern (a := a) x1 x2 x3 = subst_pattern_lemFuel (a := a) lemDefaultFuel x1 x2 x3 := fun _ _ _ => rfl
example {a : Type} : ∀ x1, to_pure (a := a) x1 = to_pure_lemFuel (a := a) lemDefaultFuel x1 := fun _ => rfl
example {a : Type} : ∀ x1, to_pures (a := a) x1 = to_pures_lemFuel (a := a) lemDefaultFuel x1 := fun _ => rfl
example {a : Type} : ∀ x1 x2 x3, subst_wait (a := a) x1 x2 x3 = subst_wait_lemFuel (a := a) lemDefaultFuel x1 x2 x3 := fun _ _ _ => rfl
example {a : Type} {b : Type} {c : Type} [Eq0 a] : ∀ x1 x2, find_labeled_continuation (a := a) (b := b) (c := c) x1 x2 = find_labeled_continuation_lemFuel (a := a) (b := b) (c := c) lemDefaultFuel x1 x2 := fun _ _ => rfl
example {a : Type} : ∀ x1 x2 x3, find_labeled_continuation2_aux (a := a) x1 x2 x3 = find_labeled_continuation2_aux_lemFuel (a := a) lemDefaultFuel x1 x2 x3 := fun _ _ _ => rfl
example : ∀ x1 x2, match_pattern x1 x2 = match_pattern_lemFuel lemDefaultFuel x1 x2 := fun _ _ => rfl
example {a : Type} : ∀ x1 x2, collect_saves_aux (a := a) x1 x2 = collect_saves_aux_lemFuel (a := a) lemDefaultFuel x1 x2 := fun _ _ => rfl
example {a : Type} : ∀ x1 x2, m_collect_saves_aux (a := a) x1 x2 = m_collect_saves_aux_lemFuel (a := a) lemDefaultFuel x1 x2 := fun _ _ => rfl
example {a : Type} [MapKeyType a] : ∀ x1 x2 x3, update_env_aux (a := a) x1 x2 x3 = update_env_aux_lemFuel (a := a) lemDefaultFuel x1 x2 x3 := fun _ _ _ => rfl
example : ∀ x1 x2, pull_constrained x1 x2 = pull_constrained_lemFuel lemDefaultFuel x1 x2 := fun _ _ => rfl
example : ∀ x1 x2 x3 x4 x5 x6 x7 x8 x9 x10, step_eval_pexpr x1 x2 x3 x4 x5 x6 x7 x8 x9 x10 = step_eval_pexpr_lemFuel lemDefaultFuel x1 x2 x3 x4 x5 x6 x7 x8 x9 x10 := fun _ _ _ _ _ _ _ _ _ _ => rfl
example : ∀ x1 x2 x3 x4 x5 x6 x7 x8, eval_pexpr_aux2 x1 x2 x3 x4 x5 x6 x7 x8 = eval_pexpr_aux2_lemFuel lemDefaultFuel x1 x2 x3 x4 x5 x6 x7 x8 := fun _ _ _ _ _ _ _ _ => rfl
example : ∀ x1 x2 x3 x4 x5 x6 x7 x8, eval_pexpr_aux_broken x1 x2 x3 x4 x5 x6 x7 x8 = eval_pexpr_aux_broken_lemFuel lemDefaultFuel x1 x2 x3 x4 x5 x6 x7 x8 := fun _ _ _ _ _ _ _ _ => rfl
example {b : Type} : ∀ x1 x2 x3 x4 x5 x6 x7, full_eval_pexpr (b := b) x1 x2 x3 x4 x5 x6 x7 = full_eval_pexpr_lemFuel (b := b) lemDefaultFuel x1 x2 x3 x4 x5 x6 x7 := fun _ _ _ _ _ _ _ => rfl
example {a : Type} {b : Type} : ∀ x1 x2, one_step_unseq_aux (a := a) (b := b) x1 x2 = one_step_unseq_aux_lemFuel (a := a) (b := b) lemDefaultFuel x1 x2 := fun _ _ => rfl
example {a : Type} {b : Type} {c : Type} : ∀ x1, has_ccall (a := a) (b := b) (c := c) x1 = has_ccall_lemFuel (a := a) (b := b) (c := c) lemDefaultFuel x1 := fun _ => rfl
example : ∀ x1, get_ctx x1 = get_ctx_lemFuel lemDefaultFuel x1 := fun _ => rfl
example : ∀ x1 x2 x3 x4, get_ctx_unseq_aux x1 x2 x3 x4 = get_ctx_unseq_aux_lemFuel lemDefaultFuel x1 x2 x3 x4 := fun _ _ _ _ => rfl
example : ∀ x1 x2, add_to_sb x1 x2 = add_to_sb_lemFuel lemDefaultFuel x1 x2 := fun _ _ => rfl
example : ∀ x1 x2, add_to_asw x1 x2 = add_to_asw_lemFuel lemDefaultFuel x1 x2 := fun _ _ => rfl
example {bty : Type} : ∀ x1, convert_pexpr (bty := bty) x1 = convert_pexpr_lemFuel (bty := bty) lemDefaultFuel x1 := fun _ => rfl
example {a : Type} {bty : Type} : ∀ x1, convert_expr (a := a) (bty := bty) x1 = convert_expr_lemFuel (a := a) (bty := bty) lemDefaultFuel x1 := fun _ => rfl
example : ∀ x1 x2 x3, are_compatible_params_aux0 x1 x2 x3 = are_compatible_params_aux0_lemFuel lemDefaultFuel x1 x2 x3 := fun _ _ _ => rfl
example : ∀ x1 x2 x3, are_compatible_params0 x1 x2 x3 = are_compatible_params0_lemFuel lemDefaultFuel x1 x2 x3 := fun _ _ _ => rfl
example : ∀ x1 x2 x3, are_compatible_aux x1 x2 x3 = are_compatible_aux_lemFuel lemDefaultFuel x1 x2 x3 := fun _ _ _ => rfl
example : ∀ x1 x2, mkUnspec x1 x2 = mkUnspec_lemFuel lemDefaultFuel x1 x2 := fun _ _ => rfl
example : ∀ x1, has_concurRead x1 = has_concurRead_lemFuel lemDefaultFuel x1 := fun _ => rfl
example : ∀ x1 x2 x3, find_array_index x1 x2 x3 = find_array_index_lemFuel lemDefaultFuel x1 x2 x3 := fun _ _ _ => rfl
example : ∀ x1 x2 x3 x4 x5, memcmp_load_aux x1 x2 x3 x4 x5 = memcmp_load_aux_lemFuel lemDefaultFuel x1 x2 x3 x4 x5 := fun _ _ _ _ _ => rfl
example : ∀ x1 x2, fake_mem_value_eq x1 x2 = fake_mem_value_eq_lemFuel lemDefaultFuel x1 x2 := fun _ _ => rfl
example : ∀ x1 x2, tmp_compl_aux x1 x2 = tmp_compl_aux_lemFuel lemDefaultFuel x1 x2 := fun _ _ => rfl
example : ∀ x1 x2 x3, tmp_AND_aux x1 x2 x3 = tmp_AND_aux_lemFuel lemDefaultFuel x1 x2 x3 := fun _ _ _ => rfl
example : ∀ x1 x2 x3, tmp_OR_aux x1 x2 x3 = tmp_OR_aux_lemFuel lemDefaultFuel x1 x2 x3 := fun _ _ _ => rfl
example : ∀ x1 x2 x3, tmp_XOR_aux x1 x2 x3 = tmp_XOR_aux_lemFuel lemDefaultFuel x1 x2 x3 := fun _ _ _ => rfl
example : ∀ x1 x2, simplify_integer_value_base x1 x2 = simplify_integer_value_base_lemFuel lemDefaultFuel x1 x2 := fun _ _ => rfl
example : ∀ x1 x2 x3 x4, print_eval_conv_aux x1 x2 x3 x4 = print_eval_conv_aux_lemFuel lemDefaultFuel x1 x2 x3 x4 := fun _ _ _ _ => rfl
example : ∀ x1 x2 x3, drive_nonmemory_steps_aux2 x1 x2 x3 = drive_nonmemory_steps_aux2_lemFuel lemDefaultFuel x1 x2 x3 := fun _ _ _ => rfl
example : ∀ x1 x2, driver2 x1 x2 = driver2_lemFuel lemDefaultFuel x1 x2 := fun _ _ => rfl
example : ∀ x1 x2 x3 x4 x5 x6 x7, hack x1 x2 x3 x4 x5 x6 x7 = hack_lemFuel lemDefaultFuel x1 x2 x3 x4 x5 x6 x7 := fun _ _ _ _ _ _ _ => rfl
example {a : Type} {b : Type} {c : Type} {d : Type} {e : Type} {f : Type} : ∀ x1 x2, nd_bind (a := a) (b := b) (c := c) (d := d) (e := e) (f := f) x1 x2 = nd_bind_lemFuel (a := a) (b := b) (c := c) (d := d) (e := e) (f := f) lemDefaultFuel x1 x2 := fun _ _ => rfl
example {a : Type} {cs : Type} {err1 : Type} {err2 : Type} {info1 : Type} {info2 : Type} {st1 : Type} {st2 : Type} : ∀ x1 x2 x3 x4 x5, liftND (a := a) (cs := cs) (err1 := err1) (err2 := err2) (info1 := info1) (info2 := info2) (st1 := st1) (st2 := st2) x1 x2 x3 x4 x5 = liftND_lemFuel (a := a) (cs := cs) (err1 := err1) (err2 := err2) (info1 := info1) (info2 := info2) (st1 := st1) (st2 := st2) lemDefaultFuel x1 x2 x3 x4 x5 := fun _ _ _ _ _ => rfl
example {a : Type} {cs : Type} {err1 : Type} {err2 : Type} {info1 : Type} {info2 : Type} {st1 : Type} {st2 : Type} : ∀ x1 x2 x3 x4 x5, liftAction (a := a) (cs := cs) (err1 := err1) (err2 := err2) (info1 := info1) (info2 := info2) (st1 := st1) (st2 := st2) x1 x2 x3 x4 x5 = liftAction_lemFuel (a := a) (cs := cs) (err1 := err1) (err2 := err2) (info1 := info1) (info2 := info2) (st1 := st1) (st2 := st2) lemDefaultFuel x1 x2 x3 x4 x5 := fun _ _ _ _ _ => rfl

/-! ### Part 2: symbolic execution over the newly-total exec slice.
    Every statement is SYMBOLIC in the fuel (any `Nat.succ f`), the
    annotations, and the payloads — kernel-checked by `rfl`, which no
    `partial def` admits (no equations). -/

/-- Pattern matching: the wildcard base pattern matches anything, binding
    nothing. -/
example (f : Nat) (an : List annot) (bty : core_base_type) (cval : value) :
    match_pattern_lemFuel (Nat.succ f) (Pattern an (CaseBase (none, bty))) cval
      = some [] := rfl

/-- Pattern matching: a variable base pattern binds the scrutinee. -/
example (f : Nat) (an : List annot) (bty : core_base_type) (s : sym) (cval : value) :
    match_pattern_lemFuel (Nat.succ f) (Pattern an (CaseBase (some s, bty))) cval
      = some [(s, cval)] := rfl

/-- Type-annotation erasure: converting a symbol pexpr erases the bty and
    keeps the symbol (symbolic in the erased annotation's VALUE too). -/
example (f : Nat) (an : List annot) (b : Type) (btyv : b) (s : sym) :
    convert_pexpr_lemFuel (Nat.succ f) (Pexpr an btyv (PEsym s))
      = Pexpr an () (PEsym s) := rfl

/-- Concurrency-call analysis: a pure expression contains no ccall — via the
    WORKER at symbolic fuel. -/
example (f : Nat) (an : List annot) (pe : generic_pexpr b a) :
    has_ccall_lemFuel (c := c) (Nat.succ f) (Expr an (Epure pe)) = false := rfl

/-- The same fact through the default-fuel WRAPPER: the wrapper is not a
    black box — it unfolds definitionally through the worker. -/
example (an : List annot) (pe : generic_pexpr b a) :
    has_ccall (c := c) (Expr an (Epure pe)) = false := rfl

/-- Substitution: a value pexpr is untouched (values contain no symbols). -/
example (f : Nat) (s : sym) (cval : value) (an : List annot) (bty : Unit)
    (v : value) :
    subst_sym_pexpr_lemFuel (Nat.succ f) s cval (Pexpr an bty (PEval v))
      = Pexpr an bty (PEval v) := rfl

/-- Pattern occurrence: no symbol occurs in a wildcard base pattern. -/
example (f : Nat) (s : sym) (an : List annot) (bty : core_base_type) :
    in_pattern_lemFuel (Nat.succ f) s (Pattern an (CaseBase (none, bty)))
      = false := rfl

/-- Environment lookup on the empty environment stack (structural-total,
    no fuel needed). -/
example (s : sym) : lookup_env (a := value) s [] = none := rfl

def main : IO Unit :=
  IO.println "TotalityProofTest: all proofs kernel-checked at compile time"
