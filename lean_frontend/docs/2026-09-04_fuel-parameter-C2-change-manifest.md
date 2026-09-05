# Fuel-parameter arc, cerberus half, slice C2 — change manifest for refined-cerberus (2026-09-04)

Branch `arc/fuel-parameter-C2` (base mainline `mdd/cerberus-lean` @
`753644005`, the merged C1). Record: `2026-09-04_fuel-parameter-C2-record.md`
(same directory; the 67-row table is its §2). Lem side unchanged at
`ecf75b4` (no LemLib re-pin needed on your side). Author [AGENT] (the C2
worker); rulings [USER 2026-09-04] as quoted in the record §1.

## 1. What is now TRUE (your §2 requirement), and how it is checked

Every fuel'd worker in the compiled environment (81: 67 generated, 14
hand-written) is exactly one of — checked by `scripts/check_fuel_forms.sh`
from the KERNEL environment (constants, `_zero` lemma statements, the
constant closure of the drive cone), plant-tested, in `test_unit.sh`:

- **(A) MEASURED, 41** — the wrapper is `def f (xs…) := f_lemFuel (<measure>)
  xs…` (no `[LemFuel]` unless the body reaches an ambient callee), with the
  theorem `f_measure_sufficient : <measure> ≤ lemFuel → f_lemFuel lemFuel xs…
  = f xs…` (generated statement in `<Module>_auxiliary`, hand-written proof
  in `<Module>_lemMeasureProofs`; for the three `CerbMem` seams the theorem
  is `CerbMem.f_measure_sufficient` directly), every cone ⊆ [propext,
  Classical.choice, Quot.sound] (the gate probes all 41). `f xs… =
  f_lemFuel (<measure>) xs…` by `rfl`; the kernel computes through them.
- **(B) ABSORBING, 13** — `f_lemFuel_zero … : f_lemFuel 0 … = <absorbing
  element>` where the element is `NDkilled (Error0 CerbFuel.fuelExhaustedLoc
  CerbFuel.fuelExhaustedMsg)` inside `ND`/bare (ND monad: `nd_bind`,
  `liftND`, `liftAction`, `driver2`, `drive_nonmemory_steps_aux2`,
  `print_eval_conv_aux`, `load_character_array_aux`), `Result (Error
  CerbFuel.fuelExhaustedLoc CerbFuel.fuelExhaustedMsg)` (the undefined monad
  `t0`: `eval_pexpr_aux2`, `eval_pexpr_aux_broken`; `full_eval_pexpr` returns
  `fun st => Result (Error …, st)`), or `[(Killed st0 fuelExhaustedKill, [],
  st0)]` (the `CerbND` runners). `stExceptUndef_bind`/`exception_undef_bind`
  propagate `Result (Error …)`; `Driver` turns it into `kill (Error0 loc
  str)` — so on the drive path exhaustion is the kill, never a value.
- **(C) UNREACHABLE from `drive`, 6 ambient** — not in the kernel constant
  closure of `drive`/`initial_driver_state`/`CerbND.runND*`/
  `CerbCall.driveCall` (closed under mutual blocks): `zeros_aux`,
  `list_unfoldr_aux`, `mkUnspec`, `simplify_integer_value_base` (your
  flagged payload — the DEFACTO memory model is not the model wired into
  `drive`; `CerbMem` is), `CerbMem.memValueToBytes_append_lemFuel`,
  `CerbMem.reconstructValue_indexed_lemFuel` (reference forms).
- **PENDING, 21** — reachable AND ambient: `scripts/fuel_forms_pending.txt`
  (a reviewed register the gate enforces both ways). For these your `∀ fuel`
  statements are NOT yet true without a depth hypothesis: the `CerbMem`
  layout oracle (`sizeofCtype_lemFuel`, `alignofCtype_lemFuel`,
  `offsetsof_lemFuel`, `offsetsofMembers_lemFuel`, `memberAlign_lemFuel`),
  `reconstructValue_lemFuel`, the `ctype_aux` `are_compatible_aux` trio (tag
  lookups — a measure needs tag-environment acyclicity: record D-C2-1); the
  `ail` `are_compatible` trio, `one_step_unseq_aux`, `get_ctx`,
  `get_ctx_unseq_aux` (point-free tails: lem-lean TODO 17 — they flip to (A)
  when it lands, no name changes); `hack`; `to_pure`/`to_pures`;
  `many`/`many1`; `showNonNegativeWithBasis_aux` (record §2 rows 1, 3, 4,
  24, 25, 45 and §9). Their exhaustion is the opaque `fuelExhausted x`
  (loud panic at runtime; the sentinel in the kernel).

## 2. Names that changed for you

| You had (C1) | You write now | Note |
|---|---|---|
| `@f ⟨fuel⟩ …` for the 35 functions of record §2 marked M this slice (`in_pattern`, `subst_sym_pexpr`, `subst_sym_expr`, `subst_pattern_val`, `unsafe_subst_sym_pexpr`, `unsafe_subst_sym_expr`, `unsafe_subst_pattern`, `subst_pattern`, `match_pattern`, `update_env_aux`, `subst_wait`, `find_labeled_continuation`, `find_labeled_continuation2_aux`, `collect_saves_aux`, `m_collect_saves_aux`, `loadedValueFromMemValue`, `add_to_sb`, `add_to_asw`, `convert_pexpr`, `convert_expr`, `has_ccall`, `pull_constrained`, `has_concurRead`, `find_array_index`, `mkListN_aux`, `mkListFromTo_aux`, `replicate_list_`, `tmp_compl_aux`, `tmp_AND_aux`, `tmp_OR_aux`, `tmp_XOR_aux`) | `f …` — NO instance: fuel-free, kernel-computable | their `_lemFuel_zero` lemmas still exist; the parametricity pins (`@f ⟨n⟩ = f_lemFuel n`) are GONE for them (the wrapper is no longer ambient) — use `f_measure_sufficient` instead |
| `@memValueFromValue ⟨fuel⟩ tds ty cval`, `@step_eval_pexpr ⟨fuel⟩ …`, `@easy_update_mem_value_aux ⟨fuel⟩ …`, `@memcmp_load_aux ⟨fuel⟩ …` | the same — these four measured wrappers KEEP `[LemFuel]` (their bodies reach an ambient callee: `are_compatible0`; `CerbMem.sizeofIval`/`arrayShiftPtrval`/…; `mkUnspec`/`simplify_integer_value_base`; `impl_load`) but their OWN counter is the measure: `@f ⟨n⟩ xs = @f_lemFuel ⟨n⟩ (<measure>) xs` by `rfl` | the obligation carries `[LemFuel]` too |
| `CerbMem.typeofMval [LemFuel]`, `CerbMem.ctypeMemCompatible [LemFuel]` | `CerbMem.typeofMval mval`, `CerbMem.ctypeMemCompatible ty1 ty2` — fuel-FREE (measured by hand: `typeofMval_lemFuel (memValueSize mval) mval`) | `CerbMem.typeofMval_measure_sufficient`, `CerbMem.unqualifyAndUnatomic_measure_sufficient`; `unqualifyAndUnatomic` is no longer `private` |
| `CerbMem.memValueToBytes [LemFuel] ambient fpm v = memValueToBytes_lemFuel LemFuel.fuel …` | `= memValueToBytes_lemFuel (memValueSize v) ambient fpm v` (still `[LemFuel]` for the layout oracle) | `CerbMem.memValueToBytes_measure_sufficient [LemFuel]`; `memValueToBytes_eq_append` now `= memValueToBytes_append_lemFuel (memValueSize val_) …` |
| `full_eval_pexpr_lemFuel_zero`, `eval_pexpr_aux2_lemFuel_zero`, `eval_pexpr_aux_broken_lemFuel_zero`, `load_character_array_aux_lemFuel_zero` (RHS a `fuelExhausted …` VALUE) | RHS `fun st => Result (Error CerbFuel.fuelExhaustedLoc CerbFuel.fuelExhaustedMsg, st)` / `Result (Error …)` / the ND kill | record §3 verbatim |
| — | NEW `CerbMem.memValueSize`/`memValueListSize`/`memValueMembersSize` (structural size of the seam `MemValue`), `CerbMeasureLemmas.*` (member bounds, congruences, `unatomic_size_le`) | usable in your proofs |

Nothing else moved: `drive [LemFuel]`, the runners, `CerbCall.driveCall`,
`Main --fuel`, `CERB_TEST_FUEL`, the C1 exemplar are as at C1.

## 3. Consequences for your statements

- For every (A) function `f` on your path: no `[LemFuel]` hypothesis, no
  fuel in the statement; `f x = f_lemFuel (μ x) x` by `rfl`, and `∀ n ≥ μ x,
  f_lemFuel n x = f x` is `f_measure_sufficient`.
- For every (B) function: `∀ fuel`, the run is EXHAUSTED (`Killed _
  fuelExhaustedKill` / `Result (Error fuelExhaustedLoc _)`) or the specified
  outcome — TRUE on the drive path modulo the PENDING rows; monotonicity
  ("done at the bound ⇒ done at every larger fuel") is provable per function
  by induction on the counter for these 13 (not generated — lem TODO 13).
- For the 21 PENDING rows your hypothesis must bound their depth (a
  tag-environment/layout depth for the nine tag-lookup rows; the pattern/
  list shape for the six point-free rows; the evaluation depth for `hack`,
  `to_pure`; the format length for `many`; `b ≥ 2` for
  `showNonNegativeWithBasis`). The record's §9 lists the routes.
