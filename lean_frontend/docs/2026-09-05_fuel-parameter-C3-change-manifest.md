# Fuel-parameter arc, cerberus half, slice C3 — change manifest for refined-cerberus (2026-09-05)

Branch `arc/fuel-parameter-C3` (base mainline `mdd/cerberus-lean` @
`a910f097c`, the merged C2). Record: `2026-09-05_fuel-parameter-C3-record.md`
(same directory). Author [AGENT] (the C3 worker).

**Lake pin you should take: LemLib `d4ba548d084ff393126f04d90f18a72c3000aa88`**
(lem-lean mainline `mdd/lean-backend` after the tails-and-pmap-laws merge;
`lean_frontend/lakefile.toml`, all three `lake-manifest.json`). What that lem
brings you directly: `LemLibPmapLaws.lean` (your `Pmap`/`Fmap`
lookup-after-insert laws, `Pmap.CmpLaws`, the `Std.TransOrd` bridge — lem-lean
`doc/lean-backend/2026-09-05_tails-and-pmap-laws-record.md` §3), and the
emission rule below.

## 1. What changed in the generated tree (one rule, six functions)

lem `d4ba548` HOISTS the trailing lambda binders of a `fuel_measure`d or
`structural` definition into its head on the Lean target: the binder the
pattern compiler makes for a `function` scrutinee becomes the parameter
`lemTail`; a user-written `fun k ->` keeps its name (the general rule —
any trailing lambda; lem record §2.2). The rule fires ONLY where a
`fuel_measure`/`structural` declare exists — at the pin bump alone the whole
Lean tree was byte-identical (204/204 files) to the C2 head's.

This slice adds the six `fuel_measure` declares the rule enables (the last
six "point-free" rows of the C2 pending register), so these six are now
fuel-FREE, form (A) MEASURED:

| Function (module) | Was (C2) | Is now (C3) | Measure (the `_measure_sufficient` hypothesis) |
|---|---|---|---|
| `one_step_unseq_aux` (`Core_reduction`) | `def one_step_unseq_aux {a b} [LemFuel] : (List dyn_annotation × List value) → List (generic_expr b a sym) → Option …` | `def one_step_unseq_aux {a b} (p : List dyn_annotation × List value) (lemTail : List (generic_expr b a sym)) : Option …` | `List.length lemTail + 1 ≤ lemFuel` |
| `get_ctx` (`Core_reduction`) | `def get_ctx [LemFuel] : expr core_run_annotation → List (context × expr core_run_annotation)` | `def get_ctx (g : generic_expr core_run_annotation Unit sym) : List (context × expr core_run_annotation)` | `generic_expr.lemSize g + 1 ≤ lemFuel` |
| `get_ctx_unseq_aux` (`Core_reduction`) | `def get_ctx_unseq_aux [LemFuel] : List annot → List (context × …) → List (generic_expr …) → List (generic_expr …) → List (context × …)` | `def get_ctx_unseq_aux (annot1 : List annot) (acc : List (context × …)) (es1 : List (generic_expr …)) (lemTail : List (generic_expr …)) : List (context × …)` | `generic_expr_.lemSize_aux2 lemTail + 1 ≤ lemFuel` |
| `are_compatible` (`AilTypesAux`) | `def are_compatible [LemFuel] : (qualifiers × ctype) → (qualifiers × ctype) → Bool` | `def are_compatible (p : qualifiers × ctype) (p0 : qualifiers × ctype) : Bool` | `ctype.lemSize p.2 + ctype.lemSize p0.2 + 1 ≤ lemFuel` |
| `are_compatible_params_aux` (`AilTypesAux`) | `def are_compatible_params_aux [LemFuel] : Bool → (List (qualifiers × ctype × Bool) × List (qualifiers × ctype × Bool)) → Bool` | `def are_compatible_params_aux (acc : Bool) (lemTail : List (qualifiers × ctype × Bool) × List (qualifiers × ctype × Bool)) : Bool` | `ctype_.lemSize_aux1 lemTail.1 + ctype_.lemSize_aux1 lemTail.2 + 1 ≤ lemFuel` |
| `are_compatible_params` (`AilTypesAux`) | `def are_compatible_params [LemFuel] : List (qualifiers × ctype × Bool) → List (qualifiers × ctype × Bool) → Bool` | `def are_compatible_params (params1 params2 : List (qualifiers × ctype × Bool)) : Bool` | `ctype_.lemSize_aux1 params1 + ctype_.lemSize_aux1 params2 + 2 ≤ lemFuel` |

For each: `f … = f_lemFuel (<measure>) …` by `rfl`; the obligation
`f_measure_sufficient` lives in `Core_reduction_auxiliary` /
`AilTypesAux_auxiliary` (proofs: `Core_reduction_lemMeasureProofs`,
`AilTypesAux_lemMeasureProofs`), every cone `[propext, Classical.choice,
Quot.sound]`. The two mutual blocks share ONE fuel counter, so each member's
measure bounds the WHOLE block's depth from that entry (the lem record's
dry-run measures for `get_ctx_unseq_aux` and the ail trio were acceptance
witnesses only — `List.length` is NOT sufficient there; the derived sizes
above are what is proved).

## 2. Names/arity that changed for you

**Arity shape (point-free → named binders).** The six wrappers above AND
their workers now take the former trailing argument as an explicit named
parameter. Extensionally the same functions (`funext` recovers the point-free
form); an `@f` application changes as follows:

| You had (C2) | You write now |
|---|---|
| `@one_step_unseq_aux a b ⟨fuel⟩ p l`, `one_step_unseq_aux_lemFuel n p` (: `List … → Option …`) | `one_step_unseq_aux p l`, `one_step_unseq_aux_lemFuel n p l` |
| `@get_ctx ⟨fuel⟩ e`, `get_ctx_lemFuel n` | `get_ctx e`, `get_ctx_lemFuel n e` (arity unchanged for the worker; the binder is now named `g`) |
| `@get_ctx_unseq_aux ⟨fuel⟩ annot acc es1 l`, `get_ctx_unseq_aux_lemFuel n annot acc es1` (: `List … → List …`) | `get_ctx_unseq_aux annot acc es1 l`, `get_ctx_unseq_aux_lemFuel n annot acc es1 l` |
| `@are_compatible ⟨fuel⟩ p p0` | `are_compatible p p0` |
| `@are_compatible_params_aux ⟨fuel⟩ acc pr`, `are_compatible_params_aux_lemFuel n acc` (: `_ × _ → Bool`) | `are_compatible_params_aux acc pr`, `are_compatible_params_aux_lemFuel n acc pr` |
| `@are_compatible_params ⟨fuel⟩ ps1 ps2` | `are_compatible_params ps1 ps2` |

**`_zero` lemmas of the three hoisted-tail members** are now applied to the
hoisted binder (β-equal to the old point-free statement):
`one_step_unseq_aux_lemFuel_zero p lemTail : one_step_unseq_aux_lemFuel 0 p lemTail = ((fuelExhausted (fun _ => none)) lemTail)`,
`get_ctx_unseq_aux_lemFuel_zero annot1 acc es1 lemTail : … = ((fuelExhausted (fun _ => acc)) lemTail)`,
`are_compatible_params_aux_lemFuel_zero acc lemTail : … = ((fuelExhausted (fun _ => false)) lemTail)`.

**Callers that lost `[LemFuel]`** (derived from the tree diff, C2 head vs
this head; `.tmp`-free reproduction: regenerate both trees and `diff`): every
generated definition whose head changed is one of the 59 below — all of them
only DROP the `[LemFuel]` binder (they called one of the six ambiently), none
changes its explicit parameters:

- `AilTypesAux`: `make_composite_params`, `make_composite` (partial), `are_pointers_to_compatible_complete_objects`, `are_pointers_to_compatible_objects`, `pointers_to_compatible_types`, `compatibleWithQualifiedUnqualifiedVersionOf`, `agnostic_alignment_requirement_ord` (partial) (+ the six above and their workers/`_zero` lemmas).
- `Core_reduction`: `one_step0` (+ the three above).
- `Ctype_aux`: the WORKERS `are_compatible_aux_lemFuel`, `are_compatible_params_aux0_lemFuel`, `are_compatible_params0_lemFuel` and their `_zero` lemmas lose `[LemFuel]` (the wrappers `are_compatible_aux`/`are_compatible_params_aux0`/`are_compatible_params0` stay AMBIENT — tag-lookup rows, still PENDING; their parametricity pins are now `@f ⟨n⟩ = f_lemFuel n`, no longer `… ⟨n⟩ n`).
- `Cabs_to_ail_aux`: `make_composite_fdecl`. `Cabs_to_ail_effect`: `register_global_object_definition2`, `register_function_declaration`, `register_external_object_declaration`. `Cabs_to_ail`: `find_compatible_generic_association` (partial).
- `GenTypesAux`: `are_pointers_to_qualifiedOrUnqualified_compatible_complete_objects`, `are_pointers_to_qualifiedOrUnqualified_compatible_types`, `are_pointers_to_compatible_types`, `composite_pointer`.
- `GenTyping`: `well_typed_assignment`, `well_typed_equality`, `well_typed_conditional`, `find_generic_association`, `annotate_definition`, `annotate_sigma`, `annotate_program`, and the partials `annotate_rvalue`, `annotate_assignee`, `annotate_expression`, `perform_decays`, `annotate_arguments_aux`, `annotate_definition_aux`, `annotate_definitions`, `annotate_statement_`, `annotate_statement`, `annotate_block`.
- `Mini_pipeline`: `typecheckAil`.

Nothing else moved: `drive [LemFuel]`, the runners, `CerbCall.driveCall`,
`Main --fuel`, the C1 exemplar, every C2 measured/absorbing form.

## 3. The (A)/(B)/(C) state after this slice

`check_fuel_forms.sh` on this head (verbatim in the record §6): 81 fuel'd
workers = 47 MEASURED + 13 ABSORBING + 15 reachable-AMBIENT (the register,
`scripts/fuel_forms_pending.txt`) + 6 ambient-unreachable. The 15 PENDING
rows are the nine tag-lookup recursions (`CerbMem` layout oracle ×5,
`reconstructValue`, the `ctype_aux` `are_compatible_aux` trio — C2 decision
D-C2-1), `hack`, `to_pure`/`to_pures`, `many`/`many1`,
`showNonNegativeWithBasis_aux` (C2 D-C2-2..4). `[LemFuel]` binders in the
generated model: 298 → 251 (derived, comment-stripped `grep`); ambient
generated wrappers 29 → 23 (the parametricity pins regenerated with the
committed generator, 23 = 23).

One thing to know when you REDUCE through these (kernel or `#eval`): a
measured wrapper evaluates its measure eagerly — `get_ctx g` is
`get_ctx_lemFuel (generic_expr.lemSize g + 1) g`, a full traversal of `g`
before the walk; on the driver that measured +7 % CPU on one arena-heavy
csmith row (record §7 F-C3-4, decision §8.4) — no correctness effect, but a
`decide`/`rfl` over a large arena pays it too.
