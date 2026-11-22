# Consumer note for cerberus-sl: definitions that read the implementation profile bind `[CerberusImpl.ImplProfile]` (2026-11-22)

From: the `arc/impl-profile` worker [AGENT]. Contract D20; record `2026-11-22_impl-profile-record.md`. The shape is
the switch set's (your PNVI-arc note of 2026-10-07): a new instance-implicit binder, no semantic change under the
default.

## What changed

`class CerberusImpl.ImplProfile where char_is_signed : Bool` (`CerberusImpl.lean`). Every definition that reads plain
`char`'s signedness, directly or through a callee, binds `[CerberusImpl.ImplProfile]`. Binder order, as lem emits it:
`[LemFuel] [CerberusImpl.ImplProfile] [CerbGlobal.Switches]`. No instance is declared in the repository.

## What you need to do at the re-pin

- A statement or proof that mentions one of the definitions below needs an instance in scope: bind
  `[CerberusImpl.ImplProfile]` to quantify over profiles, or state the default with `@f … CerberusImpl.defaultImpl …`
  (positional, between the fuel and the switch set), or declare your own instance. The default is
  `CerberusImpl.defaultImpl : ImplProfile := { char_is_signed := true }`, an `abbrev`.
- A proof that unfolds to the `Char` arm rewrites with the default lemmas, all `rfl`:
  `CerberusImpl.defaultImpl_char_is_signed : defaultImpl.char_is_signed = true`,
  `is_signed_ity_char_default : @is_signed_ity defaultImpl .Char0 = true`,
  `precision_ity_char_default : @precision_ity defaultImpl .Char0 = some 7`
  (and `…_hafnium`: `false`, `false`, `some 8`). Off the `Char` arm the instance is irrelevant:
  `is_signed_ity_of_ne_char (p q : ImplProfile) (ity) (h : ity ≠ .Char0) : @is_signed_ity p ity = @is_signed_ity q ity`.
- `CerbMem.reconstructValue` and `reconstructValue_lemFuel` (the default-SWITCH wrappers you import) now bind the
  profile too; they still pin the switch set and do not pin the profile [AGENT 2026-11-22].
  `CerbMemDefaultFacts` and `CerbMemAccessFacts` state their theorems for every profile (the same proofs).
- `CerbND.driver2_wrapper_defeq`, `print_eval_conv_aux_wrapper_defeq` and `drive_nonmemory_steps_aux2_wrapper_defeq`
  take the profile as an explicit argument before the switch set.
- `CabsImport.parseJson*` bind the class and check the document's recorded profile (the refinedc-lean note).

Not changed: `storeM`'s and `loadM`'s text beyond the binder, `initial_driver_state`, `initialMemState`, the layout
functions (`sizeof_ity`, `alignof_ity`, `sizeof_ty`, `alignof_ty`, `offsetsof`), `CerbND.runNDFuel`.

## Hand-written definitions and theorems that gained the binder (61 declarations in 14 modules; derived)

- `CabsImport`: `labelsOfParsed`, `parseJsonWithAllLabels`, `parseJsonWithFiles`, `parseJson`
- `CerbCall`: `allocErrno`, `callFinish`, `driveCall`
- `CerbDecode`: `wrapChar`, `decode_character_constant`
- `CerbMem`: `memValueToBytes_lemFuel`, `memValueToBytes`, `memValueToBytes_append_lemFuel`, `memValueToBytes_lemFuel_eq_append`, `memValueToBytes_eq_append`, `reconstructValueAbst_lemFuel`, `reconstructValueAbst`, `reconstructValue_lemFuel`, `reconstructValue`, `maxIval`, `minIval`, `allocateObject`, `loadM`, `storeM`, `intfromptr`, `memcpyM`, `memcmpM`, `reallocM`, `copyAllocId`
- `CerbMemAccessFacts`: `loadM_erasure`, `storeM_erasure`
- `CerbMemDefaultFacts`: `reconstructValue_lemFuel_unfold`, `reconstructValueAbst_lemFuel_default_closure`, `reconstructValueAbst_lemFuel_default_snd`, `reconstructValueAbst_default_snd`, `reconstructValueAbst_snd_of_default`, `loadM_reconstruct_eq_reconstructValue`
- `CerbMem_lemMeasureProofs`: `memValueToBytes_stable_aux`, `memValueToBytes_measure_sufficient`, `reconstructValueAbst_stable_aux`, `reconstructValueAbst_measure_sufficient`, `reconstructValue_measure_sufficient`
- `CerbND`: `driver2_wrapper_defeq`, `print_eval_conv_aux_wrapper_defeq`, `drive_nonmemory_steps_aux2_wrapper_defeq`
- `CerberusImpl`: `is_signed_ity`, `precision_ity`
- `Core_eval_lemMeasureProofs`: `step_eval_pexpr_stable_aux`, `step_eval_pexpr_measure_sufficient`
- `Defacto_memory_lemMeasureProofs`: `easy_update_mem_value_aux_stable_aux`, `easy_update_mem_value_aux_measure_sufficient`, `memcmp_load_aux_stable_aux`, `memcmp_load_aux_measure_sufficient`
- `Driver_lemMeasureProofs`: `step_eval_pexpr_value`, `hack_value`, `hack_measure_sufficient`
- `Main`: `selfTest`, `frontendTU`, `loadLibc`, `runPipeline`
- `Translation_lemMeasureProofs`: `translate_constant_stable`, `translate_constant_measure_sufficient`

## Generated definitions that gained the binder (261 declarations in 21 modules; derived)

A `_lemFuel` worker, its wrapper and its `_zero` lemma are listed separately, as they are declared.

- `AilTypesAux`: `is_signed_ity0`, `is_unsigned_ity`, `le_integer_range`, `integer_promotion`, `promotion`, `usual_arithmetic_integer_CHERI`, `usual_arithmetic_integer_default`, `usual_arithmetic_integer`, `is_signed_integer_type`, `is_unsigned_integer_type`
- `Cabs_to_ail`: `is_integer_constant_expression0`, `is_arithmetic_constant_expression_`, `is_arithmetic_constant_expression`, `is_lvalue_to_static_object`, `is_address_constant_`, `is_address_constant`, `static_lvalue_type`, `is_decayed_static_lvalue`, `is_static_array_lvalue`, `is_initializer_constant_expression_or_string_literal0`, `evaluate_integer_constant_expression_aux`, `evaluate_integer_constant_expression0`, `evaluate_case_constant_expression`, `desugar_expression0`, `desugar_struct_declaration`, `desugar_struct_declarator`, `desugar_init_declarator_BROKEN`, `desugar_init_declarator`, `check_storage_class_specifiers`, `desugar_enumerator`, `desugar_alignment_specifier`, `desugar_parameter_type_list`, `desugar_type_name`, `desugar_and_register_static_assert_declaration`, `wip_desugar_initializer_`, `_UNUSED_static_thread_implicit_initializer`, `desugar_array_declarator`, `desugar_pointer_declarator`, `desugar_abstract_declarator`, `desugar_direct_abstract_declarator`, `desugar_type_specifiers`, `register_enumerators`, `desugar_direct_declarator`, `desugar_parameter_declaration`, `desugar_declarator`, `desugar_alignment_specifiers`, `pathFromDesigs_aux`, `pathFromDesigs`, `foo_aux`, `foo`, `desugar_declaration_base`, `desugar_block_statement`, `desugar_statement_aux`, `desugar_statement`, `desugar_cn_expr`, `desugar_cn_pred`, `desugar_cn_resource`, `desugar_o_cn_func_body`, `desugar_cn_assertion`, `desugar_cn_clause_aux`, `desugar_cn_clause`, `desugar_cn_clauses`, `desugar_maybe_cn_clauses`, `desugar_and_register_cn_predicate`, `desugar_and_register_cn_function`, `desugar_cn_condition`, `desugar_cn_conditions`, `desugar_and_register_cn_lemma`, `desugar_cn_statement`, `desugar_and_register_function_definition`, `desugar_and_register_external_declaration`, `desugar`
- `Core_eval`: `mk_wrapI`, `mk_conv_int`, `mk_wrapI_op`, `mk_call_catch_exceptional_condition`, `step_eval_pexpr_lemFuel`, `step_eval_pexpr`, `step_eval_pexpr_lemFuel_zero`, `eval_pexpr_aux2_lemFuel`, `eval_pexpr_aux2`, `eval_pexpr_aux2_lemFuel_zero`, `eval_pexpr_aux_broken_lemFuel`, `eval_pexpr_aux_broken`, `eval_pexpr_aux_broken_lemFuel_zero`, `eval_pexpr`
- `Core_eval_auxiliary`: `step_eval_pexpr_measure_sufficient`
- `Core_reduction`: `eval_pexpr20`, `full_eval_pexpr_lemFuel`, `full_eval_pexpr`, `full_eval_pexpr_lemFuel_zero`, `step_ctx`
- `Core_run`: `step_eval_pexprs`, `core_run_step_eval_pexpr`, `core_run_eval_pexpr`, `eval_pexpr2`, `wrapped_eval_pexpr2`, `core_action_step`, `core_thread_step2`
- `Ctype_aux`: `match_integer_ctype`
- `Defacto_memory`: `mk_op_ival_`, `mk_offsetof_ival_`, `integer_value_baseFromShift_path`, `impl_eval_integer_value`, `impl_offsetof_ival`, `real_address_expression_of_pointer`, `address_expression_of_pointer`, `impl_kill`, `apply_shift_path_element`, `apply_shift_path`, `insert_element_to_path`, `internal_shift_ptrval`, `impl_array_shift_ptrval`, `impl_member_shift_ptrval`, `impl_op_ival`, `is_one_past_pointer`, `impl_eq_ptrval`, `silly_sh_eq`, `impl_ne_ptrval`, `impl_lt_ptrval`, `impl_gt_ptrval`, `impl_le_ptrval`, `impl_ge_ptrval`, `impl_diff_ptrval`, `impl_intcast_ptrval`, `impl_lt_ival`, `impl_le_ival`, `can_store`, `easy_update_mem_value_aux_lemFuel`, `easy_update_mem_value_aux`, `easy_update_mem_value_aux_lemFuel_zero`, `easy_update_mem_value`, `register_write_event`, `perform_access`, `ival_footprintFromWrite_event`, `isOccludedBy`, `discardOccluded_write_events`, `impl_load`, `impl_store`, `memcmp_load_aux_lemFuel`, `memcmp_load_aux`, `memcmp_load_aux_lemFuel_zero`, `memcmp_compare`, `fold_memcmp_compare`, `impl_memcmp`
- `Defacto_memory_aux`: `simplify_integer_value_base_lemFuel`, `simplify_integer_value_base`, `simplify_integer_value_base_lemFuel_zero`, `eval_integer_value_base`, `lifted_simplify_integer_value_base`
- `Defacto_memory_auxiliary`: `easy_update_mem_value_aux_measure_sufficient`, `memcmp_load_aux_measure_sufficient`
- `Driver`: `print_eval_conv_aux_lemFuel`, `print_eval_conv_aux`, `print_eval_conv_aux_lemFuel_zero`, `printf_eval_conv`, `drive_fs_step`, `action_request_sequential2`, `perform_action_request2`, `perform_memop_request2`, `advance_step`, `drive_nonmemory_steps_aux2_lemFuel`, `drive_nonmemory_steps_aux2`, `drive_nonmemory_steps_aux2_lemFuel_zero`, `new_drive_core_threads`, `process_core_step2`, `driver2_lemFuel`, `driver2`, `driver2_lemFuel_zero`, `hack_lemFuel`, `hack`, `hack_lemFuel_zero`, `finalize`, `driver_globals`, `prepare_main_args`, `drive`
- `Driver_auxiliary`: `hack_measure_sufficient`
- `Formatted`: `load_character_array_aux_lemFuel`, `load_character_array_aux`, `load_character_array_aux_lemFuel_zero`, `load_character_array`, `is_illtyped_conversion`, `convert`, `load_star_argument`, `printf_aux`, `store_chars_in_array`, `vsnprintf`, `printf`, `vprintf`
- `GenTypesAux`: `interpret_genIntegerType`, `interpret_genBasicType`, `interpret_genType`, `interpret_genTypeCategory`
- `GenTyping`: `in_range`, `try_ranges`, `gen_typing_type_of_constant`, `typecheck_constant`, `annotate_rvalue`, `annotate_assignee`, `annotate_expression`, `perform_decays`, `annotate_arguments_aux`, `annotate_definition_aux`, `annotate_definition`, `annotate_definitions`, `annotate_statement_`, `annotate_statement`, `annotate_block`, `annotate_sigma`, `annotate_program`
- `Implementation`: `is_signed_ity`, `precision_ity`, `integerImpl`, `is_compatible_with_size_t`, `is_compatible_with_ptrdiff_t`, `is_signed_or_unsigned_aux`, `is_signed_or_unsigned`
- `Mem_common`: `try_usual_arithmetic`, `resolve_arg`, `derive_intrinsic_signature`
- `Mini_pipeline`: `run_const_expr_driver`, `evalIntegerConstantExpressionAux`, `evalIntegerConstantExpression`, `typecheckAil`, `evalIntegerConstantExpression_seeded`, `typecheckAil_seeded`, `annotate_expression_seeded`, `qualified_ctype_of_seeded`, `typecheckAil_promoted`, `typecheckAil_promoted_seeded`, `in_range_of_signed_int`
- `Translation`: `with_wrapI_or_catch_exceptional_condition`, `mkTestExpression`, `translate_integerConstant`, `translate_constant_lemFuel`, `translate_constant`, `translate_constant_lemFuel_zero`, `translate_function_designator`, `translate_mul_operator`, `translate_div_mod_operator`, `translate_relational_operator`, `translate_equality_operator`, `translate_bitwise_operator`, `translate_postfix`, `translate_assignment_conversion`, `translate_function_call`, `translate_atomic_explicit`, `translate_expression_lemFuel`, `translate_expression`, `translate_expression_lemFuel_zero`, `wrapped_translate_expression`, `translate_block`, `translate_stmt_lemFuel`, `translate_stmt`, `translate_stmt_lemFuel_zero`, `translate_program`, `translate`
- `Translation_aux`: `ctype_of`, `qualified_ctype_of`, `combine_params_args`
- `Translation_auxiliary`: `translate_constant_measure_sufficient`
