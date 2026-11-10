# Consumer note for cerberus-sl: generated binder names changed where unreferenced (2026-11-10)

From: the `arc/todo54-repin` worker [AGENT]. Record `docs/2026-11-10_todo54-repin-record.md`; the lem-lean side:
its `doc/lean-backend/2026-11-07_unreferenced-binders-record.md` (lem TODO 54). You pin this repository by commit in `scripts/semantics-pin.env`; the note applies to a pin at or after the landing of `arc/todo54-repin`.

What moved, in one paragraph: the lem pin is `2220010bc25f0c5682d8200f016e786ee66d65c6`. The Lean backend now
spells a binder the definition's body never references with a leading underscore (`x` becomes `_x`; a derived
`Inhabited` constant function's binder becomes `_`), and emits `termination_by structural` on a derived comparison
or size definition only when that definition recurses. The generated Lean tree changes in those three shapes and
nothing else (52 modules: 147 clauses removed, 601 binders renamed, 75 `Inhabited` binders blanked; every hunk
classified token by token, record §3). The generated OCaml is byte-identical. No definition's type, body, name,
module or universe changed; no hand-written seam, proof module, gate register or baseline moved.

What this means for you:

- **A named argument on a renamed parameter stops elaborating.** `f (x := e)` against a generated definition whose
  parameter `x` is now `_x` fails with an unknown-named-argument error; write it positionally or as `(_x := e)`.
  The same holds for anything that matches the printed form of a generated signature or body textually: it
  now reads `_x`. This repository's own hand-written Lean (seams, measure proofs, tests, speclab) needed no change.
- **Only signature parameters are reachable that way.** Of the 676 renamed or blanked binders, 80 are parameters in
  the signature of 61 generated definitions (the table below, derived from the token comparison); the other 596 are
  pattern variables and lambda or let binders inside bodies, visible only when a body is unfolded and printed.
- **Kernel terms are unchanged up to binder names.** Binder names are not part of definitional equality: a proof by
  `rfl`, `simp`, `unfold`, `decide` or a rewrite with a generated equation lemma is unaffected. Equation-lemma and
  `.eq_def` statements keep their names; the bound-variable names inside them follow the source.
- **The removed `termination_by structural` clauses** sat on derived `cmpx_`/`sizex_` definitions that do not
  recurse; Lean had been ignoring them with a warning. Those definitions were and are plain non-recursive `def`s.
- **Warnings:** the root package now builds with `-DwarningAsError=true` and its stored build logs carry no warning.
  A consumer building this package as a Lake dependency compiles it with that flag; nothing is required of you.

The 80 renamed signature parameters (module-qualified definition, parameters; derived):

| Definition | Parameters |
|---|---|
| `AilTypesAux.le_integer_range` | `impl2` → `_impl2` |
| `AilTypesAux.usual_arithmetic_floating` | `impl2` → `_impl2`, `ty2` → `_ty2` |
| `AilTyping.well_formed_bindings` | `loc1` → `_loc1` |
| `Cabs_to_ail.desugar_cabs_constant` | `loc1` → `_loc1` |
| `Cmm_csem.finite_prefixes` | `r` → `_r`, `s` → `_s` |
| `Cmm_csem.minimal_elements` | `r` → `_r` |
| `Cmm_csem.threadwise` | `s` → `_s` |
| `Cmm_csem.interthread` | `s` → `_s` |
| `Cmm_csem.locationwise` | `s` → `_s` |
| `Cmm_csem.action_respects_location_kinds` | `action2` → `_action2` |
| `Cmm_csem.downclosed` | `A` → `_A`, `R` → `_R` |
| `Cmm_csem.relation_plug` | `R` → `_R`, `a` → `_a`, `a'` → `_a'` |
| `Cmm_csem.receptiveness` | `opsem` → `_opsem` |
| `Cmm_csem.extends_prefix` | `Xo` → `_Xo`, `A` → `_A`, `A'` → `_A'` |
| `Cmm_csem.produce_well_formed_threads` | `opsem` → `_opsem` |
| `Cmm_csem.single_thread_relations` | `Xw` → `_Xw` |
| `Cmm_csem.locks_only_sw` | `actions1` → `_actions1` |
| `Cmm_csem.locks_only_good_mutex_use` | `lk1` → `_lk1` |
| `Cmm_csem.release_acquire_synchronizes_with` | `actions1` → `_actions1`, `sb1` → `_sb1` |
| `Cmm_csem.release_acquire_relaxed_synchronizes_with` | `sb1` → `_sb1` |
| `Cmm_csem.release_sequence_set` | `lk1` → `_lk1` |
| `Cmm_csem.hypothetical_release_sequence_set` | `lk1` → `_lk1` |
| `Cmm_csem.with_consume_cad_set` | `actions1` → `_actions1` |
| `Cmm_csem.inter_thread_happens_before` | `actions1` → `_actions1` |
| `Cmm_csem.happens_before` | `actions1` → `_actions1` |
| `Cmm_csem.bounded_executions` | `Xs` → `_Xs` |
| `Cmm_csem.release_acquire_no_locks_synchronizes_with` | `actions1` → `_actions1`, `sb1` → `_sb1` |
| `Cmm_op.sb_r_f` | `wit` → `_wit` |
| `Cmm_op.sb_f_w` | `wit` → `_wit` |
| `Cmm_op.monAddToMo` | `pre` → `_pre` |
| `Cmm_op.auxAddToRfLoad` | `pre` → `_pre` |
| `Cmm_op.auxAddToRfRmw` | `pre` → `_pre` |
| `Cmm_op.monAddToLo` | `pre` → `_pre` |
| `Cmm_op.monAddToSc` | `pre` → `_pre` |
| `Core_eval.step_eval_pexpr_lemFuel` | `hasConstrained` → `_hasConstrained` |
| `Core_reduction_aux.step_fs_proc` | `th_st` → `_th_st` |
| `Core_typing_aux.export_ctor` | `loc1` → `_loc1` |
| `Ctype_aux.with_tagDefs` | `tds` → `_tds` |
| `Defacto_memory.impl_offsetof_ival` | `tagDefs1` → `_tagDefs1` |
| `Defacto_memory.fetch_first_write_event` | `pred1` → `_pred1` |
| `Defacto_memory.is_concrete_ival` | `ival` → `_ival` |
| `Defacto_memory.impl_eq_ptrval` | `loc1` → `_loc1` |
| `Defacto_memory.impl_lt_ptrval` | `loc1` → `_loc1` |
| `Defacto_memory.impl_gt_ptrval` | `loc1` → `_loc1` |
| `Defacto_memory.impl_le_ptrval` | `loc1` → `_loc1` |
| `Defacto_memory.impl_ge_ptrval` | `loc1` → `_loc1` |
| `Defacto_memory.impl_diff_ptrval` | `ty1` → `_ty1` |
| `Defacto_memory.impl_validForDeref_ptrval` | `ref_ty` → `_ref_ty`, `ptr_val` → `_ptr_val` |
| `Defacto_memory.impl_isWellAligned_ptrval` | `ref_ty` → `_ref_ty`, `ptr_val` → `_ptr_val` |
| `Defacto_memory.impl_ptrcast_ival` | `int_ty` → `_int_ty` |
| `Defacto_memory.impl_store` | `is_locking` → `_is_locking` |
| `Defacto_memory.impl_memcpy` | `ptr_val1` → `_ptr_val1`, `ptr_val2` → `_ptr_val2`, `size_ival` → `_size_ival` |
| `Driver.driver_globals` | `file1` → `_file1` |
| `Formatted.applyFlagsAndPadding` | `isSignedConversion1` → `_isSignedConversion1`, `fs` → `_fs`, `fw_opt` → `_fw_opt`, `str` → `_str` |
| `Nondeterminism.log` | `msg` → `_msg` |
| `Nondeterminism.mplus` | `m1` → `_m1`, `m2` → `_m2` |
| `Nondeterminism.nd_mem` | `x` → `_x`, `m` → `_m` |
| `Nondeterminism.warns_if_no_active_ex` | `m` → `_m` |
| `Translation.translate_bitwise_operator` | `loc1` → `_loc1`, `stdlib1` → `_stdlib1` |
| `Translation.translate_function_call` | `is_used` → `_is_used` |
| `Translation_aux.illTypedAil` | `loc1` → `_loc1` |

A parameter that a later change to the Lem source starts to reference loses its underscore again, so a consumer
that must name one of these should prefer the positional form.
