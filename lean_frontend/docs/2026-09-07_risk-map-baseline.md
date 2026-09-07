# Risk-map BASELINE — 2026-09-07

[AGENT auditor] Independent read-only audit under [the charter](2026-09-07_codex-charter-risk-map-baseline.md). Verdicts distinguish a reviewed change from proof of preservation; “MOVED-WITH-RULING” does not mean all residual obligations are discharged. Numeric censuses and diff tallies below are derived unless explicitly presented as verbatim program output.

Independently confirmed gaps are R3's missing code marker, the older acyclicity guarantee's overstatement, CerbGlobal's overbroad identical-values claim for `backend_name`, and the sweep record's “12 TIMEOUT” count versus nine in the actual baseline. These findings and the unmeasured consumer-build/correspondence claims are kept explicit below.

| Identity | Independently read value |
|---|---|
| Baseline A | `7c66b39a4`; Lem `861ed814f178a40a28616326378ae2f38bf79b4a`. |
| Baseline B | `ae1a5448c`; Lem `045dcb0d57a171eb4fb3a6eb5abe288c227270ce`. |
| Fixed target | `df1fdaf02`. |
| Audit branch/start HEAD | `audit/risk-map-baseline`, `a0f7b9842dd419df9332a2bbc04ef339ae3fc50d`; its only addition beyond the target is the charter. |
| Upstream | `b9aeedcb4dd438763b0eef7f95ac19e93875d7de`. |
| Installed/current Lem | `f6542f8e6860d12d4655e6648bc4c45dabd1d798`; `lem -v` printed `Lem f6542f8`; all three Lake LemLib revs agree. |
| Worktree | `/home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-audit/risk-map-baseline`. |

Every shell invocation sourced the required environment first. Build/proof/test commands additionally used the shown cache/cap settings:

```sh
source /home/dev/projects/cerberus-lean-proj/scripts/env.sh
export DUNE_CACHE=disabled CERB_MEM_MAX=48G
```

Commands below are relative to the worktree unless they explicitly enter `lean_frontend`. Shells were nonlogin: an initial login-shell read of `/etc/profile` hit a nono OS sandbox boundary; nonlogin execution with the mandated environment succeeded. The separate cap preflight observed `memory.max=51539607552`, rc 0. No cgroup-cap denial occurred. All Lean/Lake proof/build invocations used `scripts/capped` under 48 GiB; corpus test children used the harness's declared 4 GiB cap. Jobs were serialized.

Existing sources, scripts, tests, pins and baselines were left unchanged. Required build/test recipes necessarily created ignored local outputs; the deliverable contains only this record and small plain-text evidence. No baseline refresh/re-record was run. The reading-list documents, change manifests and external consumer sources were inspected as claims and ruling provenance, not substituted for independent measurements.

## 1. Oracle

[AGENT auditor] The fork OCaml oracle has moved since A in reviewed supply threading and auxiliary interfaces. Relative to B its generated OCaml delta pins are unchanged; CLI/bridge changes still make the oracle surface broader than the ordinary execution result alone. No MOVED-UNRULED oracle verdict was established, so the charter's early stop was not triggered.

I ran `git diff 7c66b39a4 df1fdaf02 -- '*.lem'` and the same command for `ae1a5448c`. Exact diffs are retained as [lem-diff-A.txt](2026-09-07_risk-map-baseline-evidence/lem-diff-A.txt) and [lem-diff-B.txt](2026-09-07_risk-map-baseline-evidence/lem-diff-B.txt). Hunk IDs below are sequential unified-diff hunks, including the new standalone test file; counts **74 / 32 are derived**. Class a means Lean-target declaration only; b means an OCaml-visible body/type change; c means other. A mixed comment/declaration hunk is explicitly marked a/c.

All b model hunks belong to `cabs_to_ail`, `cabs_to_ail_effect`, `core_run_aux`, `ctype_aux`, `driver`, `mini_pipeline`, `symbol`, `translation` or `translation_effect`: each corresponding .ml is in the manifest's expected-semantic set. These are findings of shared-source movement, covered by the C1 adoption/effect-retirement review, not Lean-only annotations. For c findings, stale-comment deletions have no executable content; removal of `initial_core_run_state_seeded` is explicitly OCaml-excluded; the b-class standalone failure probe is outside the oracle's generation/build inputs. None requires an extra generated-oracle delta. The independent current hash comparison and B→HEAD pin equality below check that disposition.


A→target, every hunk:

| ID / file and target hunk | Class | Inspected change |
|---|---|---|
| A001 `frontend/concurrency/cmm_op.lem` `@@ -14,7 +14,18 @@ open import {hol} `pp_memTheory` `utilTheory`` | a | cmm_op: replace Lean sorry target representation; printer-only declaration. |
| A002 `frontend/model/ail/ailTypesAux.lem` `@@ -1336,3 +1336,15 @@ let rec agnostic_alignment_requirement_ord ((Ctype.Ctype _ ty1_) as ty1) ((Ctype` | a | ailTypesAux: add the three compatibility fuel measures. |
| A003 `frontend/model/annot.lem` `@@ -325,10 +325,10 @@ let set_loc loc annots =` | c | annot: remove stale noncomputable/axiom commentary; no executable change. |
| A004 `frontend/model/cabs_to_ail.lem` `@@ -1128,8 +1128,15 @@ val evaluate_integer_constant_expression: Loc.t -> maybe Ctype.ctype -> expressi` | b | cabs_to_ail: constant-expression evaluator threads fresh supply. |
| A005 `frontend/model/cabs_to_ail.lem` `@@ -4958,9 +4965,14 @@ let register_additional_cn_var id = E.register_cn_ident CN_vars id` | b | cabs_to_ail: desugar accepts supply and returns final supply. |
| A006 `frontend/model/cabs_to_ail.lem` `@@ -5035,7 +5047,7 @@ let desugar core_eval_stuff cn_eval_stuff startup_str (TUnit edecls) =` | b | cabs_to_ail: evaluator result destructuring gains final supply. |
| A007 `frontend/model/cabs_to_ail_effect.lem` `@@ -568,12 +568,18 @@ let empty_switch_info =` | b | cabs_to_ail_effect: seeded state initialization. |
| A008 `frontend/model/cabs_to_ail_effect.lem` `@@ -682,13 +688,25 @@ let fin_markers_env () =` | b | cabs_to_ail_effect: evaluator interface threads supply triples. |
| A009 `frontend/model/core.lem` `@@ -461,8 +461,7 @@ instance (SetType polarity)` | c | core: retire obsolete noncomputable commentary. |
| A010 `frontend/model/core.lem` `@@ -471,3 +470,8 @@ end` | a | core: core-base-type equality measure. |
| A011 `frontend/model/core_aux.lem` `@@ -2535,21 +2535,44 @@ declare {lean} termination_argument select_case = automatic` | a | core_aux: structural measures and fuel declarations. |
| A012 `frontend/model/core_eval.lem` `@@ -1215,8 +1215,18 @@ let eval_pexpr loc current_call_loc_opt core_extern env mem_st_opt file pe =` | a | core_eval: measures and typed zero-fuel Error. |
| A013 `frontend/model/core_reduction.lem` `@@ -1508,13 +1508,34 @@ let step_ctx mem_st file core_extern current_tid (parent_tid_opt, th_st) =` | a | core_reduction: measures and typed zero-fuel Error. |
| A014 `frontend/model/core_run_aux.lem` `@@ -268,6 +268,7 @@ end` | b | core_run_aux: add initial_core_run_state_given signature. |
| A015 `frontend/model/core_run_aux.lem` `@@ -279,16 +280,24 @@ let initial_core_state = <\|` | b | core_run_aux: factor explicit-supply pure initial-state builder. |
| A016 `frontend/model/core_run_aux.lem` `@@ -297,30 +306,6 @@ let initial_core_run_state xs = <\|` | c | core_run_aux: delete obsolete initial_core_run_state_seeded, explicitly excluded from OCaml by ~{ocaml}. |
| A017 `frontend/model/core_run_aux.lem` `@@ -758,14 +743,21 @@ declare {lean} termination_argument subst_wait_stack = automatic` | a | core_run_aux: measured stack-walking declarations. |
| A018 `frontend/model/ctype.lem` `@@ -418,11 +418,19 @@ let is_ptr_t (Ctype _ ty_) =` | a/c | ctype: equality measure plus deletion of obsolete comment. |
| A019 `frontend/model/ctype_aux.lem` `@@ -13,22 +13,28 @@ val with_tagDefs: forall 'a. map Symbol.sym (Loc.t * tag_definition) -> (unit ->` | b | ctype_aux: with_tagDefs body becomes f (); OCaml target_rep still redirects to Cerb_tags.with_tagDefs; Lean reader declarations. |
| A020 `frontend/model/ctype_aux.lem` `@@ -74,8 +80,6 @@ let get_unionDef tag_sym =` | a | ctype_aux: delete Lean setter/reset representations. |
| A021 `frontend/model/defacto_memory.lem` `@@ -2669,10 +2669,25 @@ declare {lean} termination_argument impl_sizeof_ival_aux = automatic` | a | defacto_memory: measures and typed exhaustion declarations. |
| A022 `frontend/model/defacto_memory_aux.lem` `@@ -462,8 +462,20 @@ let lifted_simplify_integer_value_base ival_ =` | a | defacto_memory_aux: MemValue equality measure. |
| A023 `frontend/model/driver.lem` `@@ -1506,12 +1506,19 @@ let finalize debug_str dr_st =` | b | driver: pure initial-state factoring. |
| A024 `frontend/model/driver.lem` `@@ -1521,6 +1528,15 @@ let initial_driver_state file fs_state =` | b | driver: initial_driver_state_given/with builders. |
| A025 `frontend/model/driver.lem` `@@ -1877,13 +1893,17 @@ end` | a | driver: typed driver zero-fuel declarations. |
| A026 `frontend/model/formatted.lem` `@@ -320,6 +320,23 @@ let rec showNonNegativeWithBasis_aux acc useUpper b n =` | a | formatted: structural/measure declaration for numeric formatting. |
| A027 `frontend/model/formatted.lem` `@@ -384,6 +401,15 @@ let rec load_character_array_aux elem_ty ptrval prec_n_opt acc =` | a | formatted: character-load fuel declaration and typed zero. |
| A028 `frontend/model/formatted.lem` `@@ -758,6 +784,11 @@ let rec printf_aux loc eval_conv acc fs ty_ptrvals =` | a | formatted: printf_aux totality declaration. |
| A029 `frontend/model/formatted.lem` `@@ -782,6 +813,10 @@ let rec store_chars_in_array zero_terminated ptrval = function` | a | formatted: store_chars_in_array totality declaration. |
| A030 `frontend/model/mem.lem` `@@ -76,16 +76,34 @@ val kill: Loc.t -> bool -> pointer_value -> memM unit` | a | mem: Lean reader/fuel consumers for memory operations. |
| A031 `frontend/model/mem.lem` `@@ -123,6 +141,7 @@ declare ocaml target_rep function eq_ptrval = `Impl_mem.eq_ptrval`` | a | mem: pointer-inequality fuel consumer. |
| A032 `frontend/model/mem.lem` `@@ -133,6 +152,8 @@ declare ocaml target_rep function ge_ptrval = `Impl_mem.ge_ptrval`` | a | mem: pointer-difference/well-alignment reader/fuel declarations. |
| A033 `frontend/model/mem.lem` `@@ -144,10 +165,14 @@ declare lean target_rep function prefix_of_pointer = `CerbMem.prefixOfPointer`` | a | mem: dereference/sizeof/alignof reader/fuel declarations. |
| A034 `frontend/model/mem.lem` `@@ -177,16 +202,24 @@ val array_shift_ptrval:  pointer_value -> Ctype.ctype -> integer_value -> pointe` | a | mem: pointer-shift reader/fuel declarations. |
| A035 `frontend/model/mem.lem` `@@ -195,10 +228,16 @@ val realloc: Loc.t -> Mem_common.thread_id -> integer_value -> pointer_value ->` | a | mem: realloc/memcpy/memcmp reader/fuel declarations. |
| A036 `frontend/model/mem.lem` `@@ -221,6 +260,7 @@ declare lean target_rep function va_list = `CerbMem.vaList`` | a | mem: copy_alloc_id fuel consumer. |
| A037 `frontend/model/mem.lem` `@@ -255,10 +295,29 @@ declare ocaml target_rep function op_ival = `Impl_mem.op_ival`` | a | mem: atomic-member reader/fuel declarations and explanatory comment. |
| A038 `frontend/model/mini_pipeline.lem` `@@ -77,13 +77,22 @@ let run_const_expr_driver tds dr_st =` | b | mini_pipeline: constant-expression setup accepts/returns supply. |
| A039 `frontend/model/mini_pipeline.lem` `@@ -129,10 +138,13 @@ let evalConstantExpressionAux loc (*TODO*)(ailnames, stdlib_fun_map, impl) sigm` | b | mini_pipeline: evaluator initializes supplied state. |
| A040 `frontend/model/mini_pipeline.lem` `@@ -148,7 +160,7 @@ let evalConstantExpressionAux loc (*TODO*)(ailnames, stdlib_fun_map, impl) sigm` | b | mini_pipeline: constant-expression result includes supply. |
| A041 `frontend/model/mini_pipeline.lem` `@@ -162,10 +174,11 @@ let evalConstantExpressionAux loc (*TODO*)(ailnames, stdlib_fun_map, impl) sigm` | b | mini_pipeline: null-pointer test threads supply. |
| A042 `frontend/model/mini_pipeline.lem` `@@ -174,7 +187,7 @@ let evalConstantExpressionAux loc (*TODO*)(ailnames, stdlib_fun_map, impl) sigm` | b | mini_pipeline: null-pointer result destructuring. |
| A043 `frontend/model/mini_pipeline.lem` `@@ -186,10 +199,11 @@ let evalConstantExpressionAux loc (*TODO*)(ailnames, stdlib_fun_map, impl) sigm` | b | mini_pipeline: null-pointer failure preserves returned supply. |
| A044 `frontend/model/mini_pipeline.lem` `@@ -204,15 +218,15 @@ let evalIntegerConstantExpression loc core_env sigm ty_opt expr =` | b | mini_pipeline: integer constant-expression evaluator threads supply. |
| A045 `frontend/model/monadic_parsing.lem` `@@ -90,6 +90,13 @@ let rec string cs =` | a | monadic_parsing: string structural declaration. |
| A046 `frontend/model/monadic_parsing.lem` `@@ -97,3 +104,12 @@ and     many1 p =` | a | monadic_parsing: many/many1 fuel declarations. |
| A047 `frontend/model/nondeterminism.lem` `@@ -13,6 +13,11 @@ open import Pervasives` | a | nondeterminism: Lean fuel import and exhaustion declarations. |
| A048 `frontend/model/nondeterminism.lem` `@@ -546,13 +551,21 @@ type nd_status 'a 'err 'st =` | a | nondeterminism: typed zero-fuel ND leaves. |
| A049 `frontend/model/state_exception_undefined.lem` `@@ -146,8 +146,7 @@ let inline undef loc ubs =` | c | state_exception_undefined: retire obsolete noncomputable commentary. |
| A050 `frontend/model/symbol.lem` `@@ -225,10 +225,21 @@ type prefix =` | a | symbol: Lean effectful declarations replaced by supply rendering. |
| A051 `frontend/model/symbol.lem` `@@ -251,10 +262,13 @@ let fresh_pretty_with_id mkStr =` | b | symbol: eta-expand fresh_fancy to expose the stateful mint. |
| A052 `frontend/model/translation.lem` `@@ -872,8 +872,11 @@ let translate_function_call loc annots is_used translate_expr stdlib e es =` | b | translation: function-call temporary mint sequenced in elabM. |
| A053 `frontend/model/translation.lem` `@@ -1868,7 +1871,7 @@ end                       end))) ) ]` | b | translation: pass loop-control fresh supply. |
| A054 `frontend/model/translation.lem` `@@ -3295,17 +3298,37 @@ let collect_cases s =` | b | translation: loop-control state gains explicit supply/mint. |
| A055 `frontend/model/translation.lem` `@@ -3381,11 +3404,19 @@ let rec erase_loop_control_aux stmt =` | b | translation: switch/case loop-control mint sequencing. |
| A056 `frontend/model/translation.lem` `@@ -3797,7 +3828,7 @@ let rec translate_stmt stdlib tagDefs f env stmt : E.elabM (C.expr unit) =` | b | translation: monadic symbol creation in statement lowering. |
| A057 `frontend/model/translation.lem` `@@ -3833,9 +3864,9 @@ let rec translate_stmt stdlib tagDefs f env stmt : E.elabM (C.expr unit) =` | b | translation: with_block_objects callback adjustment. |
| A058 `frontend/model/translation.lem` `@@ -3951,8 +3982,11 @@ let rec translate_stmt stdlib tagDefs f env stmt : E.elabM (C.expr unit) =` | b | translation: statement temporary mint sequencing. |
| A059 `frontend/model/translation.lem` `@@ -4232,7 +4266,9 @@ let translate_program stdlib (startup_sym_opt, sigm) =` | b | translation: translate_program accepts initial supply. |
| A060 `frontend/model/translation.lem` `@@ -4262,7 +4298,7 @@ let translate_program stdlib (startup_sym_opt, sigm) =` | b | translation: elab state initialization uses supplied counter. |
| A061 `frontend/model/translation.lem` `@@ -4351,18 +4387,23 @@ let translate_program stdlib (startup_sym_opt, sigm) =` | b | translation: accumulate lowered functions and returned supply. |
| A062 `frontend/model/translation.lem` `@@ -4411,7 +4452,7 @@ let translate_program stdlib (startup_sym_opt, sigm) =` | b | translation: return final supply with translated file. |
| A063 `frontend/model/translation.lem` `@@ -4511,19 +4552,28 @@ let translate_extern_map (_, sigm) =` | b | translation: translate entry accepts and returns supply. |
| A064 `frontend/model/translation.lem` `@@ -4532,6 +4582,6 @@ let translate (ailnames, stdlib_fun_map) callconv impl prog =` | b | translation: final result tuple carries supply. |
| A065 `frontend/model/translation_effect.lem` `@@ -32,16 +32,24 @@ type elab_state = <\|` | b | translation_effect: elab_state gains fresh_supply and seeded initialization. |
| A066 `frontend/model/translation_effect.lem` `@@ -49,6 +57,7 @@ let elab_init callconv = <\|` | b | translation_effect: initialize fresh_supply field. |
| A067 `frontend/model/translation_effect.lem` `@@ -57,18 +66,54 @@ val get_calling_convention: elabM C.calling_convention` | b | translation_effect: explicit monadic fresh helpers and supply access. |
| A068 `frontend/model/translation_effect.lem` `@@ -101,15 +146,21 @@ let cheri_const_alias_map = fun st ->` | b | translation_effect: with_block_objects sequences fresh draws. |
| A069 `frontend/model/translation_effect.lem` `@@ -174,8 +225,8 @@ let resolve_object_type sym = fun st ->` | b | translation_effect: object-type marker uses monadic mint. |
| A070 `frontend/model/translation_effect.lem` `@@ -191,7 +242,7 @@ let record_object_types_marker () =` | b | translation_effect: marker result now sequenced. |
| A071 `frontend/model/utils.lem` `@@ -329,9 +329,8 @@ declare ocaml target_rep function is_power_of_two = `Cerb_util.is_power_of_two`` | c | utils: retire obsolete noncomputable commentary. |
| A072 `frontend/model/utils.lem` `@@ -342,7 +341,11 @@ declare lean target_rep function is_power_of_two = `CerbUtils.is_power_of_two`` | a | utils: bit-operation structural measures. |
| A073 `frontend/model/utils.lem` `@@ -351,6 +354,8 @@ declare {lean} termination_argument set_from_options = automatic` | a | utils: list-replication structural measure. |
| A074 `tests/failure-probes/discarded_failures.lem` `@@ -0,0 +1,14 @@` | b (probe) | Standalone discarded-failure test body, OCaml-visible only when the probe instrument compiles it; outside oracle build inputs. |

B→target, every hunk:

| ID / file and target hunk | Class | Inspected change |
|---|---|---|
| B001 `frontend/concurrency/cmm_op.lem` `@@ -14,7 +14,18 @@ open import {hol} `pp_memTheory` `utilTheory`` | a | cmm_op: replace Lean sorry target representation; printer-only declaration. |
| B002 `frontend/model/ail/ailTypesAux.lem` `@@ -1336,3 +1336,15 @@ let rec agnostic_alignment_requirement_ord ((Ctype.Ctype _ ty1_) as ty1) ((Ctype` | a | ailTypesAux: add the three compatibility fuel measures. |
| B003 `frontend/model/annot.lem` `@@ -325,10 +325,10 @@ let set_loc loc annots =` | c | annot: remove stale noncomputable/axiom commentary; no executable change. |
| B004 `frontend/model/core.lem` `@@ -461,8 +461,7 @@ instance (SetType polarity)` | c | core: retire obsolete noncomputable commentary. |
| B005 `frontend/model/core.lem` `@@ -471,3 +470,8 @@ end` | a | core: core-base-type equality measure. |
| B006 `frontend/model/core_aux.lem` `@@ -2535,21 +2535,44 @@ declare {lean} termination_argument select_case = automatic` | a | core_aux: structural measures and fuel declarations. |
| B007 `frontend/model/core_eval.lem` `@@ -1215,8 +1215,18 @@ let eval_pexpr loc current_call_loc_opt core_extern env mem_st_opt file pe =` | a | core_eval: measures and typed zero-fuel Error. |
| B008 `frontend/model/core_reduction.lem` `@@ -1508,13 +1508,34 @@ let step_ctx mem_st file core_extern current_tid (parent_tid_opt, th_st) =` | a | core_reduction: measures and typed zero-fuel Error. |
| B009 `frontend/model/core_run_aux.lem` `@@ -306,30 +306,6 @@ let initial_core_run_state xs =` | c | core_run_aux: delete obsolete initial_core_run_state_seeded, explicitly excluded from OCaml by ~{ocaml}. |
| B010 `frontend/model/core_run_aux.lem` `@@ -767,14 +743,21 @@ declare {lean} termination_argument subst_wait_stack = automatic` | a | core_run_aux: measured stack-walking declarations. |
| B011 `frontend/model/ctype.lem` `@@ -418,11 +418,19 @@ let is_ptr_t (Ctype _ ty_) =` | a/c | ctype: equality measure plus deletion of obsolete comment. |
| B012 `frontend/model/defacto_memory.lem` `@@ -2669,10 +2669,25 @@ declare {lean} termination_argument impl_sizeof_ival_aux = automatic` | a | defacto_memory: measures and typed exhaustion declarations. |
| B013 `frontend/model/defacto_memory_aux.lem` `@@ -462,8 +462,20 @@ let lifted_simplify_integer_value_base ival_ =` | a | defacto_memory_aux: MemValue equality measure. |
| B014 `frontend/model/driver.lem` `@@ -1893,13 +1893,17 @@ end` | a | driver: typed driver zero-fuel declarations. |
| B015 `frontend/model/formatted.lem` `@@ -326,6 +326,16 @@ let rec showNonNegativeWithBasis_aux acc useUpper b n =` | a | formatted: numeric-formatting fuel measure; the structural declaration was already at B. |
| B016 `frontend/model/formatted.lem` `@@ -396,7 +406,10 @@ let rec load_character_array_aux elem_ty ptrval prec_n_opt acc =` | a | formatted: typed zero-fuel exhaustion declaration. |
| B017 `frontend/model/mem.lem` `@@ -92,14 +92,18 @@ declare {lean} reader_consumer val store` | a | mem: Lean fuel consumers for memory operations. |
| B018 `frontend/model/mem.lem` `@@ -137,6 +141,7 @@ declare ocaml target_rep function eq_ptrval = `Impl_mem.eq_ptrval`` | a | mem: pointer-inequality fuel consumer. |
| B019 `frontend/model/mem.lem` `@@ -147,6 +152,7 @@ declare ocaml target_rep function ge_ptrval = `Impl_mem.ge_ptrval`` | a | mem: pointer-difference/well-alignment fuel declarations. |
| B020 `frontend/model/mem.lem` `@@ -159,11 +165,13 @@ declare lean target_rep function prefix_of_pointer = `CerbMem.prefixOfPointer`` | a | mem: dereference/sizeof/alignof fuel declarations. |
| B021 `frontend/model/mem.lem` `@@ -194,9 +202,11 @@ val array_shift_ptrval:  pointer_value -> Ctype.ctype -> integer_value -> pointe` | a | mem: pointer-shift fuel declarations. |
| B022 `frontend/model/mem.lem` `@@ -204,9 +214,11 @@ val eff_array_shift_ptrval: Loc.t -> pointer_value -> Ctype.ctype -> integer_val` | a | mem: pointer-shift fuel declarations. |
| B023 `frontend/model/mem.lem` `@@ -216,12 +228,15 @@ val realloc: Loc.t -> Mem_common.thread_id -> integer_value -> pointer_value ->` | a | mem: realloc/memcpy/memcmp fuel declarations. |
| B024 `frontend/model/mem.lem` `@@ -245,6 +260,7 @@ declare lean target_rep function va_list = `CerbMem.vaList`` | a | mem: copy_alloc_id fuel consumer. |
| B025 `frontend/model/mem.lem` `@@ -279,12 +295,28 @@ declare ocaml target_rep function op_ival = `Impl_mem.op_ival`` | a | mem: atomic-member fuel declarations and explanatory comment. |
| B026 `frontend/model/nondeterminism.lem` `@@ -13,6 +13,11 @@ open import Pervasives` | a | nondeterminism: Lean fuel import and exhaustion declarations. |
| B027 `frontend/model/nondeterminism.lem` `@@ -546,13 +551,21 @@ type nd_status 'a 'err 'st =` | a | nondeterminism: typed zero-fuel ND leaves. |
| B028 `frontend/model/state_exception_undefined.lem` `@@ -146,8 +146,7 @@ let inline undef loc ubs =` | c | state_exception_undefined: retire obsolete noncomputable commentary. |
| B029 `frontend/model/utils.lem` `@@ -329,9 +329,8 @@ declare ocaml target_rep function is_power_of_two = `Cerb_util.is_power_of_two`` | c | utils: retire obsolete noncomputable commentary. |
| B030 `frontend/model/utils.lem` `@@ -342,7 +341,11 @@ declare lean target_rep function is_power_of_two = `CerbUtils.is_power_of_two`` | a | utils: bit-operation structural measures. |
| B031 `frontend/model/utils.lem` `@@ -351,6 +354,8 @@ declare {lean} termination_argument set_from_options = automatic` | a | utils: list-replication structural measure. |
| B032 `tests/failure-probes/discarded_failures.lem` `@@ -0,0 +1,14 @@` | b (probe) | Standalone discarded-failure test body, OCaml-visible only when the probe instrument compiles it; outside oracle build inputs. |


The relevant ruling is effect-retirement design §9/Q1a–Q4, especially [USER 2026-08-31]: “this seems like... the more principled way of doing it. We don't bake in some weird back-compat machinery, and we stay in sync with the oracle up to renaming (it seems like the oracle *should not* depend on naming, that seems like a defect in itself)”. C1 adoption record §10 records the expanded permutation-only adjudication with [USER 2026-09-01]: “yes, agree on the resume per your recommendation”. The later fuel ruling “we don't change the lem structure for ocaml” did not introduce further OCaml model-body changes relative to B.

I ran the fork-drift check with no refresh or skip, before and after fresh OCaml generation. Verbatim:

```
check_fork_content: OK — 76 source files content/mode-pinned
check_fork_drift: OK — layer 1: 76 oracle-surface files = manifest (set, C-locale canonical, no duplicates); layer 2: 22 differing generated files, all hash-pinned (merge-base b9aeedcb4dd438763b0eef7f95ac19e93875d7de; lem-pin f6542f8 = lem -v)
FORK_DRIFT rc=0
POST_REGEN_FORK_DRIFT rc=0
```

Independent SHA-256 computation over both generated directories found **86 files each and 22 differing names (derived)**, no name-set differences, and exactly the manifest's differing-file set:

`ailSyntax.ml, cabs_to_ail.ml, cabs_to_ail_effect.ml, cn.ml, core.ml, core_aux.ml, core_reduction.ml, core_run.ml, core_run_aux.ml, ctype.ml, ctype_aux.ml, defacto_memory_types.ml, driver.ml, lem_debug.ml, mini_pipeline.ml, nondeterminism.ml, pp.ml, std.ml, symbol.ml, translation.ml, translation_effect.ml, utils.ml`.

[generated-hashes.txt](2026-09-07_risk-map-baseline-evidence/generated-hashes.txt) gives the hashes. Derived reviewed categories: eleven semantic and eleven cosmetic. The expected-delta pin rows are **20 at A, 22 at B, 22 at HEAD**; their B/HEAD symmetric difference is empty. This directory comparison uses the existing upstream generated tree, so it does not establish compiler independence by itself.

I therefore separately built pristine Cerberus `b9aeedcb4dd438763b0eef7f95ac19e93875d7de` with pristine upstream Lem `3802cb04b53d5f1096a464e51ecbfb2a750a7ccd`, from git objects, in the worktree-owned `.validation-foundations/independent-oracle-v2` prefix. The installed fork Lem was not its compiler. Commands:

```sh
/home/dev/projects/cerberus-lean-proj/scripts/ce python3 scripts/build_independent_oracle.py --lem-repo /home/dev/projects/cerberus-lean-proj/deps/lem-pinned --cerberus-repo . --out .validation-foundations/independent-oracle-v2
/home/dev/projects/cerberus-lean-proj/scripts/ce python3 scripts/test_upstream_oracle.py --out .tmp/risk-map-upstream
```

Verbatim direct-run results (full command output in independent-build.txt/upstream-oracle.txt):

```
INDEPENDENT_BUILD rc=0
Independent oracle: passed; {'semantic_agreement': 709, 'reviewed_difference': 1, 'matching_failure': 11, 'interface_agreement': 2}; /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-audit/risk-map-baseline/.tmp/risk-map-upstream/report.json
UPSTREAM_ORACLE rc=0 elapsed_seconds=68.402
```

The manifest/source checks passed and the source snapshot was unchanged. Both separately linked public Utils.fromJust clients returned 42. I read `scripts/upstream_oracle_differences.json` and both raw captures for `minimal/097-null-ptr-arith.undef.c`. Both exit 125, produce empty stdout, and raise exactly `Failure("TODO(pure shift a null pointer should be undefined behaviour), offset:4")`; the reviewed delta is backtrace line positions (Lem_list, core reduction, nondeterminism, pipeline and main). [reviewed-diagnostic-diff.txt](2026-09-07_risk-map-baseline-evidence/reviewed-diagnostic-diff.txt) retains the actual unified diff. This is a reviewed matching failure, not an additional successful semantic agreement.

I independently diffed the current handwritten OCaml files against the pristine upstream checkout; [oracle-hand-diff.txt](2026-09-07_risk-map-baseline-evidence/oracle-hand-diff.txt) contains **21 hunks (derived)**:

| Hunk | File | Behavior changed | Review provenance read |
|---|---|---|---|
| H01 | backend/common/ail_sym_hwm.ml (new) | Walk Ail symbols to find per-TU high-water bounds and validate the fresh window. | 2026-08-22_arc13-s0-scheme-decision.md; source content pin and Ail/supply diffs. |
| H02 | backend/common/driver_ocaml.ml | Return final-state optional allocation census alongside execution results. | 2026-09-01_s-basket.md §2.8 (8e23d1fa7). |
| H03 | backend/common/driver_ocaml.mli | Public batch_drive signature becomes a triple. | Same S-basket §2.8; explicit API finding. |
| H04 | backend/common/pipeline.ml | Use desugar supply shim; validate/check Ail fresh-symbol window. | arc13 S0 scheme decision; 2026-09-01_C1-adoption-record.md. |
| H05 | backend/common/pipeline.ml | Call supply-threaded translate, discard returned counter at OCaml boundary. | C1 adoption record and effect-retirement design §9. |
| H06 | backend/common/pipeline.mli | Expose batch result triple through pipeline interface. | S-basket §2.8. |
| H07 | backend/driver/main.ml | Thread cabs_json and batch_alloc_census flag arguments. | 2026-08-21_fork-drift-review.md §5; S-basket §2.8. |
| H08 | backend/driver/main.ml | Adjust exit-status result matching for triple. | S-basket §2.8; output-class preservation checked by pristine lane. |
| H09 | backend/driver/main.ml | Unpack triple; optional AllocCensus output while preserving exit calculation. | S-basket §2.8. |
| H10 | backend/driver/main.ml | Add parse-only JSON path, source digest field, and failure on non-object serialization. | Original fork-drift review §5; trust-basket parse-only fix 80e674ee2/C2 closing note; 2026-09-05_zero-discrepancy-Z3-record.md. |
| H11 | backend/driver/main.ml | Register --cabs-json flag. | Original fork-drift review §5. |
| H12 | backend/driver/main.ml | Register --batch-alloc-census flag. | S-basket §2.8. |
| H13 | backend/driver/main.ml | Wire both flag values through Cmdliner. | Original fork-drift review; S-basket §2.8. |
| H14 | backend/lean_export/cabs_json.ml (new) | 639-line JSON AST serializer behind bridge flag. | Original fork-drift review §5 (explicitly lists file and line count). |
| H15 | memory/cheri-coq/impl_mem.ml | Implement optional census as None for this model. | S-basket §2.8. |
| H16 | memory/concrete/impl_mem.ml | Return live/dead allocation-map cardinalities. | S-basket §2.8. |
| H17 | memory/symbolic/impl_mem.ml | Implement optional census as None. | S-basket §2.8. |
| H18 | memory/vip/impl_mem.ml | Implement optional census as None. | S-basket §2.8. |
| H19 | ocaml_frontend/fork_renumber.ml (new) | Bridge explicit-supply desugar/run/elab/loop-control operations to the single OCaml counter. | arc13 S0 scheme decision; C1 adoption record. |
| H20 | ocaml_frontend/memory_model.ml | Extend memory-model signature with alloc_census_opt. | S-basket §2.8. |
| H21 | util/cerb_fresh.ml | Expose/seed/advance counter, validate TU bounds, floor forward and fail-stop on invalid window; reset check with digest. | arc13 S0 scheme decision and single-supply/libc-floor records; C1 adoption review. |

The allocation census is printed only when requested, but `batch_drive` computes it for final states regardless of that print flag; its work is a residual cost, and its triple return type is an API change. The fresh-supply window check can refuse with exit 70; no universal proof says arbitrary extensions preserve that invariant.

A/B archaeology adds a change invisible in a current-vs-upstream diff because upstream never had it: `b4a7cc4d6` deletes the 792-line `cn_spec_json.ml`, its CLI branch/flag/Term wiring and the now-unused c_parser dependency in lean_export/dune. `2026-09-02_release-hygiene-record.md` §2/G5 records the [USER 2026-09-02] PARK ruling. The B→HEAD source diff verifies these deletions; they are not silently classified as unchanged public API. No generated .ml delta accompanies them.

I also diffed the non-OCaml handwritten build/runtime entries of the same manifest against upstream: **18 further hunks (derived)**. They are separate from the 21 OCaml hunks above; the generation and linking machinery is part of the oracle's provenance.

| Hunk / file and location | Behavior changed | Review provenance read |
|---|---|---|
| H22 `Makefile` `@@ -1,6 +1,15 @@` | Skip dune prerequisite only for the named Lean-only make goals. | Original fork-drift review §5; independent-oracle/fork-pins record:121. |
| H23 `Makefile` `@@ -182,14 +191,32 @@` | Keep core_unstruct in OCaml inputs but drop it from Lean inputs; add the OCaml generation stamp prerequisite. | Effect-retirement C1 generation-list ruling; arc13-hotfix-libc-floor; independent-oracle/fork-pins:121. |
| H24 `Makefile` `@@ -202,6 +229,8 @@` | Record the OCaml source/output stamp after generation. | arc13-hotfix-libc-floor; independent-oracle/fork-pins:121. |
| H25 `Makefile` `@@ -267,12 +296,98 @@` | Add Lean generation/copy/native/build/clean recipes; delete stale Core_unstruct copies and preserve explicit maintenance rebuild-lem. | Original fork-drift review §5; effect-retirement C1; freshness-copy-gap; independent-oracle/fork-pins:121. |
| H26 `Makefile` `@@ -290,7 +405,7 @@` | Include clean-lean in distclean. | Original fork-drift review §5; independent-oracle/fork-pins:121. |
| H27 `backend/driver/dune` `@@ -3,7 +3,7 @@` | Link lean_export into concrete driver. | Original fork-drift review:241. |
| H28 `backend/driver/dune` `@@ -22,7 +22,7 @@` | Link lean_export into VIP driver. | Original fork-drift review:241. |
| H29 `backend/driver/dune` `@@ -34,7 +34,7 @@` | Link lean_export into CHERI driver. | Original fork-drift review:241. |
| H30 `backend/lean_export/dune` `@@ -0,0 +1,3 @@` | Declare the serializer library with yojson/frontend dependencies. | Original fork-drift review:242; CN deletion separately accounted above. |
| H31 `cerberus-lib.opam` `@@ -26,7 +26,7 @@` | Raise yojson library dependency floor from 2 to 3. | Original fork-drift review:244. |
| H32 `cerberus.opam` `@@ -26,7 +26,7 @@` | Raise yojson driver dependency floor from 2 to 3. | Original fork-drift review:244. |
| H33 `ocaml_frontend/dune` `@@ -16,3 +16,28 @@` | Require an uncached generated-source stamp check in dune. | 2026-08-22_arc13-hotfix-libc-floor.md. |
| H34 `runtime/libc/dune` `@@ -1,15 +1,26 @@` | Make libc/libm generation depend on that witness. | 2026-08-22_arc13-hotfix-libc-floor.md. |
| H35 `runtime/libcore/impls/i686-apple-darwin10-gcc-4.2.1.impl` `@@ -1,93 +1,93 @@` | Change comment delimiters in a nondefault i686 implementation file; this makes previously unparseable input loadable, while definitions are unchanged. | Original fork-drift review:243; current core_lexer comment delimiter read. |
| H36 `scripts/common.sh` `@@ -0,0 +1,480 @@` | New whole-file harness helper: build roots/local install, driver selection, caps and observations; environment reads audited in §5. | 2026-09-06_independent-oracle-and-fork-pins.md:125; observation contract. |
| H37 `tools/check_driver_fresh.sh` `@@ -0,0 +1,202 @@` | New whole-file source/binary freshness checker, including copy-set prerequisite and explicit override. | 2026-09-06_independent-oracle-and-fork-pins.md:124; freshness-copy-gap. |
| H38 `tools/check_handwritten_sync.sh` `@@ -0,0 +1,138 @@` | New whole-file bidirectional handwritten copy checker. | 2026-09-06_independent-oracle-and-fork-pins.md:123; freshness-copy-gap. |
| H39 `tools/check_lem_sync.sh` `@@ -0,0 +1,207 @@` | New whole-file source/generated derivation-stamp checker. | 2026-09-06_independent-oracle-and-fork-pins.md:122; arc13-hotfix-libc-floor. |

[oracle-build-diff.txt](2026-09-07_risk-map-baseline-evidence/oracle-build-diff.txt) retains the short diffs and identities of the four whole-file helper additions. The i686 change is a nondefault parser-acceptance change already present at both audit anchors, not a new A/B movement; this audit's default-profile execution does not independently certify that nondefault implementation.

VERDICT: MOVED-WITH-RULING · evidence: `git diff 7c66b39a4 df1fdaf02 -- '*.lem'` and B equivalent; `scripts/check_fork_drift.sh`; direct `scripts/test_upstream_oracle.py`; independent hash/hunk ledgers · residual risk: Finite matched-mode execution and content pins do not prove all fork behavior equivalent to upstream, and supply/bridge/API invariants remain review obligations. · mover: master plan step 2 Pure-failure CORRESPONDENCE design note and step 5 F7 instances.

## 2. Execution behavior

The OCaml and Lean builds were cold in this worktree, with `DUNE_CACHE=disabled` and `CERB_MEM_MAX=48G`. The OCaml recipe was `dune clean; make prelude-src; source scripts/common.sh; build_cerberus` through ce. I removed only this worktree's ignored Lean build output directories, regenerated with `make lean-prelude-src`, rebuilt native/md5.o through capped leanc, then ran `../scripts/capped lake build` from lean_frontend. Source/pin/baseline files were not edited. Freshness stamps were emitted by the required build recipes, not re-recorded test baselines.

Verbatim selected build output (full retained capture excerpts identify the omitted large Lean log):

```
check_lem_sync: recorded ocaml_frontend/lem_sync.sha256 (src 977326511c1096013d9b1fa183500ad6487a23ac9c6edc3d3f2ff8bd11e266e0, gen 295e4f8291c9ffd57a4061dd38e8ec273f18d6c1cfe3a0465291f1a4bcff8100)
FORK_COLD_BUILD rc=0 elapsed_seconds=33.079
Original complete capture sha256=8a28fe29050a82555d1843906d2af9168995f813af4e0e7a476df452131ddb93
check_lem_sync: recorded lean_frontend/lem_sync.sha256 (src 977326511c1096013d9b1fa183500ad6487a23ac9c6edc3d3f2ff8bd11e266e0, gen 11c6b37a5dc95ed9f2ec3d1f6f3e157e1f0309c7236e247b9d279deaf1ab2938)
LEAN_GENERATE rc=0 elapsed_seconds=42.742
LEAN_NATIVE rc=0 elapsed_seconds=0.860
Build completed successfully (377 jobs).
LEAN_COLD_BUILD rc=0 elapsed_seconds=278.666
```

The exact Tier A+B command membership came from LADDER. The runner command was:

```sh
/home/dev/projects/cerberus-lean-proj/scripts/ce python3 scripts/release.py --mode full --lane-timeout 3300 --out .tmp/risk-map-full
```

The 3300-second per-lane limit implements the charter's “approaching one hour” stop. The whole battery is intentionally longer. Required direct witnesses were separate invocations of both exported-environment unit runs (§5) and these four commands, all through the sourced environment:

```sh
./scripts/test_exec.sh --check-baseline
./scripts/test_exec.sh --check-baseline=scripts/exec_coverage_baseline.txt tests/coverage
./scripts/test_exec.sh --check-baseline=scripts/exec_debug_baseline.txt tests/debug
./scripts/test_exec.sh --check-baseline=scripts/exec_float_baseline.txt tests/float
```

The full run completed with no artifact issues; source and external inputs were unchanged, and the selection was complete. Verbatim runner conclusion:

```
full: passed; 32/32 selected commands completed successfully.
Source unchanged: True. Complete tier selection: True.
Release certification: incomplete: reporting/adoption/audit exits require separate evidence.
FULL_RELEASE rc=0 elapsed_seconds=4506.862
```

| Command ID | rc | Seconds (derived from report) |
|---|---:|---:|
| A1 | 0 | 138.278 |
| A2 | 0 | 28.932 |
| A3 | 0 | 55.321 |
| A4 | 0 | 24.412 |
| A4b | 0 | 19.356 |
| A4c | 0 | 3.384 |
| A5 | 0 | 25.069 |
| A6 | 0 | 2.282 |
| A7 | 0 | 9.749 |
| A8 | 0 | 8.793 |
| A9 | 0 | 16.454 |
| A10 | 0 | 18.560 |
| A11 | 0 | 59.979 |
| B1 | 0 | 690.991 |
| B2 | 0 | 22.958 |
| B3 | 0 | 15.197 |
| B4 | 0 | 46.486 |
| B5 | 0 | 72.323 |
| B6.1 | 0 | 174.628 |
| B6.2 | 0 | 2.331 |
| B6.3 | 0 | 10.145 |
| B6.4 | 0 | 9.545 |
| B6.5 | 0 | 10.400 |
| B6.6 | 0 | 10.846 |
| B6.7 | 0 | 9.241 |
| B7 | 0 | 1524.197 |
| B8.1 | 0 | 13.516 |
| B8.2 | 0 | 220.106 |
| B8.3 | 0 | 6.687 |
| B9 | 0 | 1188.683 |
| B10.1 | 0 | 65.085 |
| B10.2 | 0 | 1.381 |

B9's actual output is `observation lane plants: 91/91 passed`; the LADDER's 90-case timing citation names an earlier run. B10.1 again reported 709 semantic agreements, one reviewed difference, eleven matching failures and two interface agreements; B10.2 rejected its real verdict mutation. No reporting-tier write-baseline command was dispatched. Direct-run results follow in the evidence and §5.


Verbatim direct execution-baseline conclusions (minimal, coverage, debug, float, in that order):

```
COMMAND exec-minimal
SUMMARY: total=106 match=85 ub_match=18 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=3 cerb_floor=0 cerb_inconsistent=0
Baseline check: 0 regression(s), 0 improvement(s)
BASELINE OK
DERIVED direct result exec-minimal rc=0 elapsed_seconds=27.668
COMMAND exec-coverage
SUMMARY: total=212 match=183 ub_match=16 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=13 cerb_floor=0 cerb_inconsistent=0
Baseline check: 0 regression(s), 0 improvement(s)
BASELINE OK
DERIVED direct result exec-coverage rc=0 elapsed_seconds=52.707
COMMAND exec-debug
SUMMARY: total=90 match=66 ub_match=20 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=4 cerb_floor=0 cerb_inconsistent=0
Baseline check: 0 regression(s), 0 improvement(s)
BASELINE OK
DERIVED direct result exec-debug rc=0 elapsed_seconds=23.561
COMMAND exec-float
SUMMARY: total=69 match=69 ub_match=0 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=0 cerb_floor=0 cerb_inconsistent=0
Baseline check: 0 regression(s), 0 improvement(s)
BASELINE OK
DERIVED direct result exec-float rc=0 elapsed_seconds=19.102
```

Every emitted SUMMARY/BASELINE/return-code line is quoted verbatim in [full-lane-lines.txt](2026-09-07_risk-map-baseline-evidence/full-lane-lines.txt), [full-release.txt](2026-09-07_risk-map-baseline-evidence/full-release.txt) and the direct-run evidence. SHA-256 identities of omitted bulky logs are included; the commands regenerate them. Green baseline checks do not convert retained crashes/skips/ISO differences into agreements. GCC's native integer-exit projection is weaker than the engine observation comparison.

Baseline movement was independently derived from both git diffs, without regeneration. Files inventoried: all scripts/*baseline*.txt, tests/libc_exec/baseline.txt, tests/immaculate/baseline.txt and tests/litmus if present (absent). No duplicate row keys occurred at A, B or target. [baseline-rows.txt](2026-09-07_risk-map-baseline-evidence/baseline-rows.txt) gives **every changed/added key, its exact old/current row, one attribution class and its row-edit SHA**. Compact A/G rows mean old absent because the GCC ledger did not exist at A. The raw baseline diffs are also retained.

| File | A→HEAD moved row payloads (derived) | B→HEAD (derived) | Attribution |
|---|---:|---:|---|
| exec_baseline | 0 | 0 | None. |
| exec_ci_baseline | 18 | 18 | Ruled re-record ddcfc9199 after parse-only cabs-json fix 80e674ee2. |
| exec_coverage_baseline | 13 | 13 | Instrument additions: three dynaddr rows 4ac1cc63f, ten Z2 rows bef08dcf4. |
| exec_csmith_corpus_baseline | 2 | 2 | Instrument 7ffe05156 first classified exhaustion; 00a3d2b49 recorded the changed budget: sia_477 TIMEOUT, sia_769 MATCH. |
| exec_debug_baseline | 1 | 1 | Same ruled re-record ddcfc9199: ub-inconsistent becomes UB_MATCH. |
| exec_float_baseline | 0 | 0 | Header citation/path only. |
| gcc_oracle_baseline | 1963 | 12 | Ledger introduced by db93d12f3; dedicated audit/triage re-records 07a7fca29, df63018e3; B→HEAD two fuel rows 00a3d2b49 and ten new Z1/Z2 pins a3d58c6c5/589e3d726. |
| immaculate/baseline | 57 | 55 | Per-row ledger: instrument observation widening; ISO R1 added string example; ruled Z1/Z2/Z3 mirror pins. A additionally predates the illtyped-store/offsetof-union instrument rows. |
| libc_exec/baseline | 5 | 5 | Four probe rows bef08dcf4 and global-order row 22dcb6284. |

R-C2 cites `2026-09-01_C2-ratchet-record.md:865`, [USER 2026-09-01]: “great, let's run the regen”. R-Z1/Z2/Z3 cite their corresponding change records and the zero-discrepancy design §1.1 ruling, quoted in current VALIDATION §0, [USER 2026-09-03]:

> “All *execution* discrepancies are definitionally bugs (other
> machinery intended to support proof is allowed but should have no
> semantic / execution effect whatsoever and all legacy permission
> revoked”

The row ledger distinguishes this ruled mirror re-record from an instrument-only change. Some observation/pin edits are colocated with the mirrored source fix (e.g. 62cbc8116); they are not falsely described as source-free commits. The R1/R2/R3 statuses on the original g5/s4b rows already existed at the anchors: their later token-format expansion is an instrument movement, not a newly authorized ISO result. The new zd-e2 row is attributed to R1. The original S-basket additions at A are traceable to a19b55bde/83158fd50/3ca8c6783/57e6a1eb4; subsequent formatting edits have their own row-edit SHA.

Ordering-only GCC diff rows retain identical key/payloads: a3d58c6c5 reorders 62 existing lines while adding seven pins (derived from that commit's 69 added/62 deleted noncomment rows). They are instrument ordering changes, not 62 result changes. Header-only edits name records/parked paths (4cef6bba3/b4a7cc4d6 and each instrument's dated header); none changes row outcomes. No row is left UNEXPLAINED by this attribution.

The current exception classes are **not the same four as B**, because B does not define these four classes at all. B's headings were “## 1. What is compared, against what” through “## 5. What this does and does not establish”; its weaker text says:

```text
1. On every corpus above, the Lean port and the OCaml implementation
   produce **identical verdicts** (to the recorded baseline
   exceptions, each classified and pinned).
```

HEAD §1's four classes, quoted verbatim (including their operational tests and ruling provenance):

```text
**(a) Failure-path MESSAGE TEXT** may differ; the failure-vs-success
classification must be identical. *Test:* both engines fail on the input
(both `Error`, or both tool crashes — exit 125 uncaught exception on the
oracle, exit 134 `PANIC` under `LEAN_ABORT_ON_PANIC=1` on Lean), and only
the text differs. A crash on one side and a verdict on the other is NOT
(a). *Standing members:* the `Illformed_program` text (`Main.lean`
`driverErrorBatchMsg` vs `pp_errors.ml:501`; the libxml2-uri lane pins
it modulo the embedded symbol id, tray 17); the both-crash immaculate
pairs (`MATCH | L=CRASH`: `g2-memcmp-uninit`, `g4-bswap64-overflow`,
`g5-decode-multichar`, `offsetof-union-member`, the `zd-z2*` pairs);
front-end rejections reported on stderr by the oracle and as an `Error
{msg: …}` line on stdout by Lean (exit class identical — measured on 112
reject rows, Z1 record §2). Quoted PANIC texts carry build-relative line
numbers (`CerbMem:2075:6` today) — never compare them byte-wise.

**(b) RESOURCE LIMITS** — Lean must not fail where the oracle succeeds;
the converse is acceptable. *Test:* the oracle completes the input
(within the lane bound) and Lean does not → a **(b)-VIOLATION**, i.e. a
BUG carrying a named mover, not a tolerated limit; loudness (`HANG`,
`KILL`, `TIMEOUT` classes) is necessary, not sufficient. A wall-clock
row is tolerated ONLY per row with measured completion at a larger bound
(charter Q5). *Standing members:* §3 lists them with their movers.
**(b)/fuel** — fuel exhaustion is accepted under (b), [USER 2026-09-03]
verbatim: "fuel is a reasonable exception because we could always just
run the semantics with more fuel"; the bound is a PARAMETER (`--fuel N`,
§7), and a FUEL row is never counted as agreement.

**(c) MISSING FEATURES** — [USER 2026-09-03], verbatim: "*missing
features* are allowed deviations if they are cleanly identified. CerbFS
is kind of an obscure feature as is concurrency, it's unclear if we'll
support it". *Test:* the Lean side REFUSES — non-zero exit AND a message
that names the missing feature and the boundary (not a symptom: a
file-not-found error for a flag is loud but not attributed) — where the
oracle answers. A different answer, or a silent absorption (an errno, a
default, a zero) is never (c). *Standing members:* §3.

**(d) ISO-CORRECTNESS FIXES — the register (§2).** [USER 2026-09-03],
verbatim: "I think that a short listed set of fixes is in keeping for
the purpose of cerberus-lean but the bar for such a fix must be
extremely high." *Test:* the deviation is an enumerated register entry
meeting criteria (i)–(vii) (or admitted BY CLASS as a kind-2 artifact,
§0), individually [USER]-ruled, pinned as a Lean-right/oracle-wrong
immaculate pair, with the `-- ISO-fix register R<n>` code marker. Nothing
else may deviate toward ISO.
```

[AGENT auditor] This is a ruled policy change, not continuity inferred from B.

The required legacy shard was **RED, rc 1**, with exactly the two already registered pending regressions and no other movement. An independent parse of all 279 sequential output rows found 279 unique keys equal to the selected input list, baseline counts 159 MATCH / 117 CERB_SKIP / three TIMEOUT, and current counts 157 / 117 / five (all **derived**). [csmith-derived.txt](2026-09-07_risk-map-baseline-evidence/csmith-derived.txt) records the independent join; [direct-csmith-shard-2.txt](2026-09-07_risk-map-baseline-evidence/direct-csmith-shard-2.txt) preserves the failure. Verbatim:

```
[24/279] TIMEOUT sa_csmith_369 (Lean TIMEOUT(cpu 15.00s of 15.00s wall; timeout 15s))
[27/279] TIMEOUT sa_csmith_371 (Lean TIMEOUT(cpu 15.00s of 15.00s wall; timeout 15s))
SUMMARY: total=279 match=157 ub_match=0 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=5 hang=0 cerb_skip=117 cerb_floor=0 cerb_inconsistent=0
REGRESSION: sa_csmith_369.c baseline=MATCH current=TIMEOUT
REGRESSION: sa_csmith_371.c baseline=MATCH current=TIMEOUT
Baseline check: 2 regression(s), 0 improvement(s)
FAILED: regressions vs baseline
DIRECT csmith-shard-2 rc=1 elapsed_seconds=1999.201 status=FINDING cleaned=true residual_processes=False
```

I then reran only these two inputs through the same exhaustive OCaml/Lean harness, reusing the stage created by the required shard:

```sh
TIMEOUT_SECS=90 ./scripts/test_exec.sh .tmp/scripts/csmith-corpus.qIpKLJ78JB/sa_csmith_369.c
TIMEOUT_SECS=90 ./scripts/test_exec.sh .tmp/scripts/csmith-corpus.qIpKLJ78JB/sa_csmith_371.c
```

The stage uses the existing script's CSMITH_MINIMAL/csmith_cerberus.h substitution. Input/header hashes and the exact absolute commands are in [completion-369.txt](2026-09-07_risk-map-baseline-evidence/completion-369.txt) and [completion-371.txt](2026-09-07_risk-map-baseline-evidence/completion-371.txt). Verbatim conclusions, in that order:

```
SUMMARY: total=1 match=1 ub_match=0 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=0 cerb_floor=0 cerb_inconsistent=0
DIRECT_CSMITH_90 sa_csmith_369.c rc=0 elapsed_seconds=27.317
SUMMARY: total=1 match=1 ub_match=0 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=0 cerb_floor=0 cerb_inconsistent=0
DIRECT_CSMITH_90 sa_csmith_371.c rc=0 elapsed_seconds=21.357
```

These are fresh complete-observation MATCH results at the larger bound. The full GCC lane also completed them with values 57 and 165 at 30 seconds, but its csmith tier uses `--first` (test_gcc_oracle.sh:439), so that earlier result alone was insufficient evidence for exhaustive completion. The 15-second regressions remain findings with mover C-P1; no baseline was changed, no historical binary was timed, and the eager-measure explanation remains UNKNOWN as a causal attribution. All individual passes stayed below the 3300-second tripwire.


I read the complete 2026-09-06 csmith sweep record and ran only the required legacy shard 2/6, not its full 1,669-file sweep. The mandatory full GCC lane separately includes the staged csmith tier by LADDER membership. The corpus baseline itself has **1161 MATCH, 499 CERB_SKIP, nine TIMEOUT (derived)**. The sweep record's sentence “the baseline has 12 TIMEOUT rows in total” conflicts with the independently counted nine; its own shard-2 summary was missing. Current LADDER's nine is correct. The 90-second comparisons quoted above are this audit's fresh measurements; the older record was not used as their evidence.

VERDICT: MOVED-WITH-RULING · evidence: cold local builds; `python3 scripts/release.py --mode full`; direct `scripts/test_unit.sh`/four exec lanes; baseline row ledger; `scripts/test_csmith_corpus.sh --check-baseline --shard 2/6` · residual risk: Known failures remain pinned, timeout causation/performance against historical binaries is unresolved, and the battery does not establish universal termination or ISO correctness. · mover: C-P1 historical timing/cheaper measures, C-Z4 pending semantic cases, master plan steps 2–3 and step 5.

## 3. Definitions that consumers reason about

[AGENT auditor] The reasoning interface moved against both anchors. At A the supply/effect projection was still present; B already had explicit supply and tag-reader arguments. Since B the changed fuel interfaces, measured wrappers, runtime defaults and LemLib representation are real definition changes, even where the intended result is unchanged. Rulings: effect-retirement design §9; fuel-parameter C1 record §1 ([USER 2026-09-03/04], “Any and all magic values that are hardcoded and can't be quantified over are definitionally bugs (unless they mirror lem or ISO-C design choices)”); C4 record §1 ([USER 2026-09-05], “agree, go ahead with option 1”).

| Surface | Independently inspected contract and evidence kind | Limit |
|---|---|---|
| Caller fuel | `LemFuel` has a `fuel : Nat` field; the library has no global instance. `CerbND.driver2_wrapper_defeq (n)` is `@driver2 ⟨n⟩ = @driver2_lemFuel ⟨n⟩ n`; runner equations likewise quantify fuel. THEOREM, checked by the cone gate. CLI `--fuel`/default and refusal behavior are battery evidence. | The equation identifies a wrapper with a worker at the chosen fuel; it does not prove successful completion or OCaml equivalence. Each callee starts at full ambient fuel. |
| Measured wrappers | `subst_sym_pexpr`, `get_ctx`, `update_env_aux`, layout and the other table rows call their workers at a data-derived measure. THEOREM: `Core_aux_lemMeasureProofs.subst_sym_pexpr_measure_sufficient`, `Core_reduction_lemMeasureProofs.get_ctx_measure_sufficient`, and the per-row obligations/proofs in the fuel table. The gate verifies argument/measure correspondence and cones. | Equality is to the current worker at sufficiently large fuel. The measure executes and can cost time; neither a universal OCaml simulation nor the promised performance bound follows. |
| Absorbing payloads | THEOREM: generated `driver2_lemFuel_zero`, `nd_bind_lemFuel_zero`, `full_eval_pexpr_lemFuel_zero`, and `CerbND.runNDFuel_zero` (all thirteen rows checked). Exhaustion at literal zero is the typed Error/ND kill. | General propagation through successors and monotonic completion remain open (Lem TODO 13). Constructor-disjointness lemmas against `Undef0`/`Other` do not prove distinction from every genuine `Error0`. |
| Retired/renamed interfaces | Since B: `lemDefaultFuel`, `CerbFuel.driverFuel`, `CerbND.ndDefaultFuel`, the intermediate `CerbND.drive_lemFuel` mirror/`drive_wrapper_defeq`, and duplicate namespaced zero lemmas are absent or superseded by generated root lemmas. `initial_core_run_state_seeded` was removed (B009); `*_given` builders remain. PIN/source deletion plus replacement wrapper THEOREMS. | Absence is a source fact, not an equivalence theorem between deleted binaries. Several names were introduced and then retired within B→HEAD. |
| Memory optimizations | THEOREM: `CerbMem.reconstructValue_lemFuel_eq_indexed`, `reconstructValue_eq_indexed`, `memValueToBytes_lemFuel_eq_append`, `memValueToBytes_eq_append`, supported by `chunksOf_eq_range_map` and `foldl_append_eq_flatten_reverse`; all six cones checked. | These connect optimized Lean bodies to retained Lean reference forms, not the entire OCaml implementation. Current wrappers use current measures, not the historical fixed budget. |
| `CerbGlobal` | Eleven plain definitions and eleven `*_eq` rfl theorems now replace ref-backed opaques. The probe checks every theorem. Types are unchanged. | `backend_name ()` actually changed from runtime “cerberus-lean” to “Driver”. I re-grepped all nine model reads: comparisons with “Cn”/“Bmc” only. Whole-program preservation is argued from those reads and tested; the new rfl theorems alone do not establish equivalence to the deleted refs. |
| `Acyclic` | `CerbTagsWf.Ranked` descends through by-value references, including `_Alignas(type)`; `Acyclic` existentially supplies a rank. Six layout/reconstruction sufficiency statements require `Acyclic`/`AcyclicPair`; formatting requires `2 ≤ b`. THEOREMS checked via the fuel gate and probe. | The wrappers themselves take no proof. Frontend acceptance does not establish the hypothesis. The C4 manifest at lines 109–110 says “it is what the frontend guarantees”, despite its own lines 98–102 counterexample; current VALIDATION §7 correctly calls it “not an established frontend invariant”. This is an overstatement in the older manifest, not a proved invariant. |
| Pmap/Fmap | B's TreeMap-backed Fmap became the comparator-capturing Pmap representation. THEOREMS `Pmap.find?_add_same`, `find?_add_other`, `WF_add`, `Fmap.fmapLookupBy_fmapAddBy_same/other` exist and are cone-probed. They require `Pmap.CmpLaws cmp` and map `WF`; the other-key law requires comparator inequality. | Delivered lookup laws do not prove arbitrary ill-formed trees correct or prove the entire representation equivalent to OCaml. Captured comparator/order affects enumeration; the mirror and battery remain part of the trust argument. |

[AGENT auditor] CerbGlobal's source introduction says “every read already returned these values” and “Behaviour is identical by construction”; those statements are too broad for direct `backend_name` consumers, given the inspected old/new string values. The narrower modeled-execution argument above is what was checked.

I invoked the compiled `fuel-forms-tool` directly under `../scripts/capped lake env`, importing Driver, CerbCall, CerbND, Main and every generated auxiliary/measure-proof carrier, with no classifier override. [direct-fuel-table.txt](2026-09-07_risk-map-baseline-evidence/direct-fuel-table.txt) contains the full command and raw TSV. I split only `FUEL_FORM` rows and counted their class/reachability/hypothesis columns; [fuel-derived.txt](2026-09-07_risk-map-baseline-evidence/fuel-derived.txt) lists every resulting group and the bidirectional register checks:

```
DERIVED rows=81 unique_workers=81 measured=54 absorbing=13 ambient_reachable=8 ambient_unreachable=6 measured_under_hyp=7
DERIVED reachable_minus_pending=[] pending_minus_reachable=[]
DERIVED hypotheses_minus_register=[] register_minus_hypotheses=[]
```

Verbatim direct gate output:

```
check_fuel_forms: forms partition OK (54 MEASURED + 13 ABSORBING + 8 ambient-reachable + 6 ambient-unreachable = 81 fuel'd workers)
check_fuel_forms: OK (81 fuel'd workers: 54 MEASURED (obligation of the contract's shape incl. argument correspondence against the wrapper's body; every obligation + proof cone ⊆ the standard three; 7 of them under a hypothesis, each = a reviewed row of fuel_hypotheses.txt, both directions), 13 ABSORBING = kill at zero (the _zero lemma is the worker at literal 0 on its own binders = the monad's absorbing element, cone ⊆ the standard three; propagation NOT proved — lem TODO 13), 8 reachable-AMBIENT = the 8 rows of fuel_forms_pending.txt exactly, 6 ambient unreachable from the drive cone)
check_no_fuel_numerals: OK (293 files scanned comment-stripped; no lemDefaultFuel/driverFuel/ndDefaultFuel, no LemFuel instance, no literal fuel (F1-F6); allowed Main.lean sites seen: 4 of 4 (hand-written + generated copy))
```

The [theorem probe](2026-09-07_risk-map-baseline-evidence/direct-theorem-probe.txt) checked all eleven CerbGlobal equations (each `does not depend on any axioms`), `CerbTagsWf.Acyclic.pair` (cone `[propext, Classical.choice, Quot.sound]`) and the six conditional layout/reconstruction sufficiency statements (each cone exactly `[propext, Classical.choice, Quot.sound]`). It printed the actual hypothesis-bearing statements; the input is [theorem-probe-input.txt](2026-09-07_risk-map-baseline-evidence/theorem-probe-input.txt). This was rc 0.

I also kernel-checked the current LemLibPmapLaws source directly via `../scripts/capped lake env lean .lake/packages/LemLib/lean-lib/LemLibPmapLaws.lean` (rc 0). Verbatim:

```
'Pmap.find?_add_same' depends on axioms: [propext, Quot.sound]
'Pmap.find?_add_other' depends on axioms: [propext, Quot.sound]
'Pmap.WF_add' depends on axioms: [propext, Quot.sound]
'Fmap.fmapLookupBy_fmapAddBy_same' depends on axioms: [propext, Quot.sound]
'Fmap.fmapLookupBy_fmapAddBy_other' depends on axioms: [propext, Quot.sound]
'Pmap.cmpLaws_defaultCompare_nat' depends on axioms: [propext, Quot.sound]
'Pmap.cmpLaws_of_transOrd' depends on axioms: [propext]
'Pmap.cmpLaws_defaultCompare_int' depends on axioms: [propext, Classical.choice, Quot.sound]
'Pmap.cmpLaws_defaultCompare_string' depends on axioms: [propext, Classical.choice, Quot.sound]
```


The table partitions the compiled environment, not all possible C executions. The eight pending workers are `are_compatible_aux_lemFuel`, `are_compatible_params_aux0_lemFuel`, `are_compatible_params0_lemFuel`, `hack_lemFuel`, `to_pure_lemFuel`, `to_pures_lemFuel`, `many_lemFuel`, `many1_lemFuel`. The six outside the checked execution dependency closure are `zeros_aux_lemFuel`, `list_unfoldr_aux_lemFuel`, `mkUnspec_lemFuel`, `simplify_integer_value_base_lemFuel` and the two CerbMem reference workers. Their absence from that closure is not general API unreachability.

The consumer census in [consumer-uses.txt](2026-09-07_risk-map-baseline-evidence/consumer-uses.txt) independently reads its tracked main sources, masks nested comments/strings and lists imports, references and locations. Relevant signature changes since B among actual uses:

- `drive`, `driver2` (including qualified/generated uses), `initial_driver_state`, `step_ctx`, `step_eval_pexpr`, `nd_bind`, `liftND`, `CerbND.runND` now carry the ambient fuel instance where they reach ambient callees. The explicit-counter runner workers retain their explicit counter interfaces.
- `CerbMem.alignofIval`, `sizeofIval`, `arrayShiftPtrval`, `allocateObject`, `allocateRegion`, `isAtomicMemberAccess`, `loadM`, `storeM` gained `[LemFuel]`. These still include the disclosed vacuous layout-only binders pending cleanup.
- `CerbMem.intToBytes` gained a leading `signed : Bool`. `allocator`, `CerbTagsWf.envBound`, the sufficiency lemmas and Pmap laws are new to B.
- `get_ctx` and the substitution/update wrappers are now measured; their intermediate C1/C2 fuel binders disappeared again. Against B, do not misreport an intermediate binder removal as a net added binder. Hoisted trailing arguments are now named. `sizeofCtype`, `reconstructValue`, `memValueToBytes`, `typeofMval` and `ctypeMemCompatible` likewise have current fuel-free signatures with changed definitional bodies.
- `CerbGlobal.current_execution_mode` keeps its type and becomes reducible; `has_switch_eq` is new. `killM` keeps its type but changed behavior; signature stability is not semantic stability. Fmap consumers also see the representation/ordering change, even where operation types stay the same.

VERDICT: MOVED-WITH-RULING · evidence: A/B source diffs; direct fuel table and `scripts/check_fuel_forms.sh`; theorem-probe-input.txt/output; consumer-uses.txt · residual risk: Sufficiency is conditional, failure propagation and logical/native correspondence are incomplete, and eager-measure performance remains unmeasured against the historical binaries. · mover: master plan steps 2–3 (Pure-failure CORRESPONDENCE / C-TF1), step 5 fuel residue, TODO F-A2 and C-P1; Lem TODO 13.

## 4. Trust base

Direct commands: `./scripts/check_theorem_axioms.sh`, `./scripts/check_sorry_token.sh`, `./scripts/check_exec_purity.sh`, and `ENFORCE=1 ./scripts/check_exec_totality.sh`. All returned 0. Verbatim gate conclusions:

```
check_theorem_axioms: hand-written axiom census OK (0 axioms — the arc-17 S2b end state)
check_theorem_axioms: generated-tree census OK (207 files: 0 axioms, boundary-opaque population = the 15 registered rows exactly-once (incl. CerbFuel.fuelExhaustedLoc), 0 unsafeCast)
check_theorem_axioms: C2 ratchet OK (326 files scanned recursively: 0 axioms, 0 runEffectful, seam population = the 38 pinned path-qualified counted rows exactly incl. the extern class; lem tests/ scaffolds asserted outside the surface)
check_theorem_axioms: D14 grep-ban OK (no native_decide/bv_decide in 1 tree(s) + 37 hand-written seam files + LemLibTest.lean)
check_theorem_axioms: driver2 cone sorryAx-free + ofReduce*-free + DAEMON-free (arc-8 S3 bar)
check_theorem_axioms: C2 entry census OK (9 entries, every cone ⊆ [propext, Classical.choice, Quot.sound])
check_theorem_axioms: mem-scale S1 leg OK (6 C1/C3 equality theorems, every cone ⊆ [propext, Classical.choice, Quot.sound])
check_theorem_axioms: FUEL arc leg OK (34 contract lemmas — 9 generated _zero + the CerbND runner leaves/parametricity pins + the ∀-fuel exemplar and its instances + the 3 fuel_measure sufficiency obligations (generated statement + hand-written proof), every cone ⊆ [propext, Classical.choice, Quot.sound])
check_theorem_axioms: OK (effect-retirement C2 bar: zero axiom declarations anywhere; entry cones ⊆ the standard three)
check_sorry_token: OK (286 files scanned comment-stripped — generated 207, hand-written+test 44, LemLib 35; 0 sorry tokens)
check_exec_purity: CLEAN (11 modules)
check_exec_totality: CLEAN (22 generated modules + hand-written CerbND, 0 allowlisted)
```

The separate command/return-code evidence is `direct-check_theorem_axioms.txt`, `direct-check_sorry_token.txt`, `direct-check_exec_purity.txt` and `direct-check_exec_totality.txt`.

The independent scan is deliberately broader than the gates: hand-written/generated Lean under `lean_frontend` (excluding `.lake`, including historical documentation probes) and the actual `deps/lem-pinned/lean-lib`. [trust-raw-grep.txt](2026-09-07_risk-map-baseline-evidence/trust-raw-grep.txt) retains the raw requested-token grep; [trust-independent-census.txt](2026-09-07_risk-map-baseline-evidence/trust-independent-census.txt) applies an independently written nested-comment/string mask, then lists active sites and normalized populations. Strings and comments in gate tests are not axiom declarations.

Derived active counts: `axiom=0`, `sorry=0`, `native_decide=0`, `bv_decide=0`, `ofReduce*=0`, `maxHeartbeats=0`, `maxRecDepth=0`; `implemented_by=20`, `extern=34`, `unsafe=29`, and `partial def=473`. These count source occurrences including duplicated generated copies, not distinct logical constants; `extern` also occurs as an ordinary field identifier. The raw grep's nonzero sorry/axiom/proof-option hits are comments, string fixtures and historical examples after masking. No newly hidden active axiom/sorry site emerged.

I independently normalized native boundary sites by kind/path/name and compared counted multisets both ways. Generated copies fold onto their hand-written path with multiplicity two; the external LemLib source is counted once. Derived: **38 rows, 71 occurrences**, exactly the allowlist's **38/71**; found-minus-pinned and pinned-minus-found are both empty. The six live `unsafeBaseIO` KEEP identities (four CerbUtils, two enum-registry identities) also match both ways; old DELETE/converted comments are not live allowlist rows.

The totality allowlist is empty. Independently restricting the partial scan to its 22 named generated modules plus hand-written CerbND gives zero sites and zero stale permissions. The broader 473-site scan is not empty: examples include CabsImport (37 plus its copy), CoreParser (108 plus its copy), CerberusImpl.alignof_ty (one plus its copy), generated frontend/typechecking/translation modules, tooling and historical probes, and four LemLib helpers (`natSqrtAux`, `lemListUnfoldrAux`, `lemListUnfoldr`, `leastFixedPointUnbounded`). These are outside that gate, not permitted exceptions inside it. The gate header's assertion that CerbMem has “ONE partial def (stringFromMemValue, pp-only)” is stale: independent current scan finds zero there. Axiom-cone output can underreport across partial boundaries; zero execution-slice partials is not whole-frontend totality.

Three-set reconciliation, with explicit granularity:

| Sets | Derived symmetric difference |
|---|---|
| P = normalized runtime PIN population; G = independently found declaration/attribute population | P △ G = ∅, including occurrence multiplicities. |
| D = VALIDATION §9 runtime families expanded to their native/IO helper declarations; P and G restricted to semantics/runtime | D △ P = D △ G = ∅. Digest includes its IO accessors/force thunk, not only the three prose example names. |
| D versus all P/G, including audit tooling | Exactly `UNSAFEDECL lean_frontend/test/Unit/FuelFormsTool.lean main 1`; an explicitly documented instrument-side row, not an imported semantics definition. |
| Pure boundary opaques versus runtime PIN rows | Different universes: the 15 opaque constants include the pure `CerbFuel.fuelExhaustedLoc`, which has no native binding. It must not be invented as an unsafe/extern site. |

Changes against the anchors, independently checked with source/pin diffs:

| Movement | Evidence and ruling provenance |
|---|---|
| A→B: effect projection removed | A's Lake rev is `861ed814f178a40a28616326378ae2f38bf79b4a`; `git -C deps/lem-pinned grep … 861ed814 -- lean-lib` finds `LemLib.lean:54:axiom runEffectful {α : Type} : (Unit → BaseIO α) → α`. B's `045dcb0` and HEAD have no such declaration. CerbTags global/reader opaques and native tag/fresh projection plumbing disappear; digest converts to the remaining pinned opaque chain. C1/C2 source diffs and the effect-retirement design §9/Q4, [USER 2026-08-31]: “yeah, this all seems reasonable”; the record expressly says “axiom gone” plus classified survivors. |
| B→HEAD: CerbGlobal leaves | 29 runtime pin identities leave (11 IMPLBY, 14 UNSAFEDECL, four UNSAFEBASEIO); eleven opaque entries leave. Source deletion and new definitions were read, not inferred from the allowlist. `2026-09-05_cerbglobal-defs-record.md` §9 records the [USER 2026-09-05] conditional overnight pre-sign and its two conditions; it does not reproduce a separate verbatim operator utterance, so none is invented here. Q4's temporal classification and the named follow-up are the earlier ruling context. |
| B→HEAD: five EXTERN pins enter | `digestIO`, `digestPure`, `forceThunkIO`, `md5Hex`, `setDigestIO` were already present at B; their addition is expanded gate coverage/path-and-count pinning, not five new native bindings. They remain Q4's digest family. |
| B→HEAD: FuelFormsTool.main enters | One unsafe instrument declaration enables imported pretty-printer extensions. C4 record lines 372–383 and its §1 hypothesis-carrying ruling: [USER 2026-09-05] “agree, go ahead with option 1”. No semantics module imports this tool. |
| B→HEAD: fuel location opaque enters | Pure `CerbFuel.fuelExhaustedLoc` has a value witness and no unsafe/extern implementation; fuel-arc change manifest §1 and fuel design Option C ruling. Axiom-free does not mean runtime failure correspondence is proved. |

Derived pin arithmetic is B **61 − 29 + 5 + 1 = 38**. The intermediate “66→37” comment describes a later checkpoint, not baseline B; the header's 37 is also not the current tooling-inclusive count.

The current ISO register contains exactly R1, R2 and R3; R4 is explicitly deferred. I matched the table to source markers and immaculate rows:

| Entry | Marker read | Pin read and rerun |
|---|---|---|
| R1 | CerbDecode line 102 | `g5-decode-question`, `zd-e2-ptr-string-literals`: ORACLE_CRASH, Lean values 63/0 and the recorded output bytes. |
| R2 | CerbDecode lines 175/184 (explanatory mention plus actual site) | `g5-escape-roundtrip`: DIFF, Lean value 127. |
| R3 | **Absent from CerbMem** | `s4b-memcmp-hugesize`: ORACLE_CRASH, Lean UB_CERB002a. |

[AGENT auditor] The missing R3 marker and missing register/marker bijection gate are real unfinished obligations, expressly acknowledged in VALIDATION §2. Admission is ruled by class and confirmed there with [USER 2026-09-05] “(2) agree”; R3 is ruled, but its current marker requirement remains unsatisfied. The aligned_alloc-zero pending kind-2 rows are separately disclosed in Z2/VALIDATION; a baseline pin is not an additional numbered ISO admission.

VERDICT: MOVED-WITH-RULING · evidence: direct `scripts/check_theorem_axioms.sh`, `scripts/check_sorry_token.sh`, purity/totality gates; independent scans/pin diffs; CerbDecode:102,184 and CerbMem marker grep · residual risk: Native/pure correspondence, partial frontend code and R3's missing marker remain outside what the green censuses establish. · mover: master plan steps 2–3 (Pure-failure CORRESPONDENCE design note / C-TF1 monadic seam slice) and step 5 F7 instances, C-Z4 (R3 marker/register gate).

## 5. Gates

[AGENT auditor] I diffed `scripts/test_unit.sh` and `scripts/LADDER.md` from B and read the resulting callers. The literal diff is retained in [gate-boundary-diff.txt](2026-09-07_risk-map-baseline-evidence/gate-boundary-diff.txt). All B Tier A and B1–B6 memberships remain. Changes are:

| Change since B | Assessment |
|---|---|
| Unit executable list: add fuel-exemplar-test (five→six) | Strengthened: an actual theorem about the shipped pipeline is built. |
| Inline Makefile copy-set parser replaced by handwritten_copy.manifest/check_handwritten_sync | Strengthened: one copy authority, missing/empty/unlisted source and byte drift refuse. |
| Axiom gate: path-qualified counted unsafe/native population, extern coverage, exact opaque population, fuel and memory equality cones, broader proof-method ban | Strengthened. Intentional population reductions track deletions; an empty axiom census alone is not the new acceptance test. |
| Add sorry-token, fuel classifier, native GCC capture, observations codec, capture prerequisites, release runner, failure census and independent-oracle instrument tests | New source/protocol/instrument checks and executable plants. |
| Add exec extractor selftest; no-fuel-numerals gate+selftest; ambient parametricity pin-set check; Lake roots gate+selftest; fuel-forms gate+selftest | Strengthened. Current generated ambient pin count is 22, not the historical 64 still mentioned in a caller comment. Fuel-forms accepts only positional worker/measure correspondence and proper zero lemmas; P0 closes the documented decoys. |
| Exec-totality module set: 20→22 plus CerbND | Strengthened by Formatted/Monadic_parsing. Empty allowlist unchanged. |
| Fork drift: mandatory prerequisites, locale-independent set comparison, duplicates/metadata checks, content/mode pins and selftests; test_unit unsets development skip | Strengthened: missing upstream/tree no longer passes as an rc-0 skip. |
| Existing lem-sync/fixture freeze; added renumber plants | Existing gates retained and renumber admission tests added; fresh generated/source/binary checks are used by build/skip paths. The fixture population is fixed rather than silently expanded. |
| Parse A7/B2 now uses --pp-core with per-file timeout and explicit rejection/crash classes | Changed scope: it no longer incidentally executes while testing frontend parity. This removes incidental execution coverage from the parse row, while the execution lanes remain; classify honestly as a narrower parse task, not an additional execution proof. |
| Tier B adds GCC oracle B7 | Promotion from reporting, [USER 2026-09-02] as recorded in LADDER. Asymmetric ledger remains: regressions/DISAGREE fatal, improvements explicit at rc 0. |
| Tier B adds hang/kill/fuel B8, actual-entry observation B9 and pristine-oracle real+plant B10 | New gates; real status and bytes are retained, resource failures are not agreement. |
| Executable release/CI membership, ownership/timeouts/source identity | New orchestration; incomplete/subset results cannot certify full membership. |
| Resource convention: VM ulimit→4 GiB per-test RSS cgroups | Ruled [USER 2026-09-02] “Q2 agree” (mem-scale design §0/Q2, LADDER). Meaning changes from address-space to RSS, tested with positive OOM witnesses. This audit uses 48 GiB for every Lean/Lake build or proof invocation. |
| Reporting tables add CI sweep and named instruments, revise csmith accounting | Visibility, not new Tier A/B coverage. No whole legacy csmith sweep was dispatched. |
| CN spec exporter/lane removed outside these two membership files | Ruled PARK in release-hygiene G5; the removed lane was not B's ladder membership. |

For every current gate with a selftest/plant mechanism I ran that mechanism (bundled A1/B8/B9/B10 where applicable, plus the five real spec-lab family plant modes directly). Exact pass lines are in [full-lane-lines.txt](2026-09-07_risk-map-baseline-evidence/full-lane-lines.txt) and the direct evidence. Python unittest gates print `Ran … tests`/`OK`; I do not rename those outputs “SELFTEST OK”.

Verbatim shell selftest/plant conclusions from those runs:

```
test_exec: SELFTEST OK (E0 pre-repair collapse reproduced; E1-E7: same-value/different-stdout and different-stderr yield distinct whole-line tokens, escaped payload byte-exact, multi-outcome order kept, embedded text is payload, Undefined unchanged, truncated line is no token)
check_no_fuel_numerals: SELFTEST OK (20 plants red with the declared label; E5 indirection a recorded known gap; unplanted set green)
check_lakefile_roots: SELFTEST OK (3 plants red, baseline green)
check_fuel_forms: SELFTEST OK (24 plants with the declared label — 6 on the table (incl. the ABSORBING-cone plant), 3 on the hypothesis register, 15 compiled decoys: the C4 four (type True / wrong worker / contradictory hypothesis caught by the register / extra binder), the whole-project audit's two decoys verbatim (review_bad _zero about runNDFuel; review_shift at literal 0), wrong fuel position, swapped worker-side and wrapper-side arguments, changed measure, wrapper calling another worker, hidden premise, and three _zero decoys (a POSITIVE control ABSORBING, a term for a binder, fuel 1) — each rejected with its own message; unplanted table green)
check_fork_drift: SELFTEST OK (14 plants with declared verdict/message: S1-S10 prerequisite/locale/name controls; S11 copied-content control; S12 inside-listed-file drift; S13/S14 duplicate/missing content pins; unplanted gate green)
test_speclab [selftest] /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-audit/risk-map-baseline/.tmp/scripts/speclab.Rj9hAEjKMX/identity.c
test_speclab: PASS (both pipelines agree on Specified(0))
test_speclab [plant] /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-audit/risk-map-baseline/.tmp/scripts/speclab.l6UZ4erdeY/plant.c
test_speclab: PASS (both pipelines agree on Specified(2))
test_hang_plant: all plants read as expected (sleep→HANG, busy→TIMEOUT, both lanes; missing record→harness error)
test_kill_plant: all plants read as expected (cap breach -> OOM-KILLED witness; ci_sweep LEAN_KILL, libc_exec KILL, immaculate KILL, uri/libxml2 FAIL-killed; SIGKILL stub NOT the cap class; native exit(137) still compared; no MATCH anywhere)
test_fuel_plant: ALL PLANTS OK (FUEL classification live in exec/gcc/ci_sweep/cn_coverage/measure; negatives not FUEL; the real driver at --fuel 1 reads FUEL and at the default MATCH; --fuel 0/non-numeral/out-of-position/missing refused)
observation lane plants: 91/91 passed
2/2 plant_rejected: plant/unexpected-verdict
Independent oracle: plants_passed; {'semantic_agreement': 1, 'plant_rejected': 1}; /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-audit/risk-map-baseline/.tmp/risk-map-full/B10.2/independent-oracle/report.json
PLANT SUMMARY: all wrong-operator plants RED with predicted indexes; healthy twins green
test_speclab_divmod: PASS (--plant)
PLANT SUMMARY: plants RED at predicted indexes; healthy + blind-spot twins green as predicted; malformed twins at 254
test_speclab_bytearr: PASS (--plant)
PLANT SUMMARY: wrong-link plant RED in the 255 length arm (structural-break signature); wrong-element plant RED at predicted index 3; healthy + blind-spot twins green as predicted; malformed twins at 254
test_speclab_list: PASS (--plant)
PLANT SUMMARY: wrong-child-swap plant RED at the locus-val byte (content signature, leak-free); dropped-subtree plant RED in the 255 length arm (structural signature, the leak arm's witness); healthy + blind-spot twins green as predicted; malformed twins at 254
test_speclab_tree: PASS (--plant)
PLANT SUMMARY: lost-update plant RED at byte 8 (verdict 9); wrong-constant plant RED at result byte 0; diagonal/non-medium blind twins green as predicted (swap blind set kernel-characterized: swapPlant_blind_iff); malformed twins at 254
test_speclab_seed: PASS (--plant)
```

| Gate/mechanism | One plant read and why it forces the claimed fault |
|---|---|
| exec --selftest | Its same-value/different-stdout pair reproduces the old extractor's collapse (E0), then demands distinct full-payload tokens. |
| no-fuel-numerals --selftest | Lines 146–152 append a literal `mkListN_aux_lemFuel 5 …` to a copied scanned file and require F3, then restore it. The separate E5 indirection case is an explicitly green known gap, not a successful negative plant. |
| Lake roots --selftest | Lines 58–63 delete Core_aux_auxiliary, assert the deletion happened, then require the missing-root failure. |
| fuel forms --selftest | Lines 233–238 compile a same-named `to_pure_measure_sufficient : True` decoy; classification must reject its statement shape, not merely find a matching name. |
| fork drift --selftest | Lines 418–420 first admit copied source contents, append a definition inside listed cerb_fresh.ml, then require content drift. Locale plants also assert the two sort orders really differ. |
| renumber plants | `s5_string_content.old/new` changes the digits inside an error string as well as binding names; the checker must refuse this payload change. Manifest positive controls prevent “refuse everything” from passing. |
| fuel classifier | Explicit exit/message fixtures require typed fuel kill classification; an assertion failure and fuel words inside successful payloads are negatives. |
| native GCC capture | Lines 25–34 compile stderr bytes 0,128,255 and byte-compare both captures against a literal expected file, preserving exit 3. |
| observations codec | `test_each_semantic_field_changes_comparison` changes each field independently; malformed-suffix tests require refusal of a valid-looking prefix followed by garbage. |
| capture prerequisites | A synthetic build prints both witnesses and exits nonzero; the test asserts the stale generator marker was never created, with a successful-build control. |
| release runner | Lines 78–85 run a fixture that prints ALL PASSED then exits 1 and demand a failed lane/nonzero result. |
| failure census | Malformed/unclosed comments raise; a mixed named/anonymous fixture must retain the anonymous declaration, and unresolved dependency mapping must not acquire a guessed exec_dependency flag. |
| upstream instrument unit tests | Lines 25–30 keep the value and change raw semantic stdout to NUL/high bytes; comparison must become difference. Provenance mutations must refuse too. |
| base spec-lab --selftest/--plant | Emitter receives a concrete expected-array corruption at index 1; both actual engines must report Specified(2), while identity reports 0. |
| divmod --plant | `form1-plant 7 2` substitutes the wrong operator; the shell explicitly rejects a zero plant verdict and checks the pure prediction on both engines. |
| bytearr --plant | `memcpy-plant 1,2,3` writes the wrong byte; shell requires the nonzero predicted index. Empty/canary collisions are separately identified blind spots. |
| list --plant | Lines 263–266 use `append-link-plant "1,2\|3"` (wrong-link fault, expected length-arm verdict 255) and the wrong-element twin (expected 3); zero is rejected for the plant class, with empty/degenerate controls separately classified. |
| tree --plant | The asymmetric M0 tree with distinct children exercises child-swap; zero verdict is rejected. Self-similar/off-shape examples are disclosed controls, not negative evidence. |
| seed --plant | Unequal seeded swap values force the lost-update fault; equal inputs are separately named the diagonal blind spot. |
| hang plant | A sleeping stub and an endless busy loop are timed by the actual exec/CI harnesses; rc and CPU/wall-based HANG/TIMEOUT labels must differ. |
| kill plant | A real 5 GiB bytearray under a 4 GiB cap must exit 137 with an OOM counter; self-SIGKILL is the no-OOM control. |
| fuel plant | A wrapper runs the real fresh driver at --fuel 1 and requires FUEL, alongside default MATCH and invalid-budget refusals. |
| observation entry plants | The byte mutation prefixes NUL/high bytes inside the successful stdout field without changing the value; every real lane must reject it. Other cases test status/UB-location/OOM and refusal handling. |
| pristine oracle --plant | Lines 252–270 run a real positive pair, then wrap the real fork binary and change `Specified(` to `Specified(999`; only a detected difference counts as plant_rejected. |

I found no vacuous negative plant among those selected. This is a per-gate structural spot audit, not a proof that all tests cover all faulty implementations.

Direct shell-exported locale/terminal witnesses, both rc 0. Commands:

```sh
export LC_ALL=C TERM=dumb
./scripts/test_unit.sh
# In a separate invoking shell:
export LC_ALL=en_US.UTF-8 TERM=xterm-256color
./scripts/test_unit.sh
```

C/dumb stdout tail and supervisor rc, verbatim:

```
  OK (refused as declared): l1_string_ws
  OK (refused as declared): l3_comment_absorb
  OK (refused as declared): l4_comment_release
  OK (refused as declared): count_mismatch
  OK (refused as declared): appended_line
  OK (refused as declared): token_change
  OK (refused as declared): section_reorder
  OK (admitted as declared): strict_renumber [RENUMBER-ONLY ADMIT plant/strict_renumber class=STRICT ids=1 moved=1 canon=d7b6d3c7463e]
  OK (admitted as declared): layout_rewrap [RENUMBER-ONLY ADMIT plant/layout_rewrap class=LAYOUT ids=2 moved=2 canon=9b2ed22f1988]
  OK (refused as declared): crlf_string
  OK (admitted as declared): crlf_code [RENUMBER-ONLY ADMIT plant/crlf_code class=LAYOUT ids=1 moved=1 canon=8c8910c71fce]
test_renumber_plants: OK (12 plants: refusals refuse, admits admit with declared class)
DIRECT unit-C rc=0 elapsed_seconds=89.343 status=passed cleaned=true residual_processes=False
```

UTF-8/xterm stdout tail and supervisor rc, verbatim:

```
  OK (refused as declared): l1_string_ws
  OK (refused as declared): l3_comment_absorb
  OK (refused as declared): l4_comment_release
  OK (refused as declared): count_mismatch
  OK (refused as declared): appended_line
  OK (refused as declared): token_change
  OK (refused as declared): section_reorder
  OK (admitted as declared): strict_renumber [RENUMBER-ONLY ADMIT plant/strict_renumber class=STRICT ids=1 moved=1 canon=d7b6d3c7463e]
  OK (admitted as declared): layout_rewrap [RENUMBER-ONLY ADMIT plant/layout_rewrap class=LAYOUT ids=2 moved=2 canon=9b2ed22f1988]
  OK (refused as declared): crlf_string
  OK (admitted as declared): crlf_code [RENUMBER-ONLY ADMIT plant/crlf_code class=LAYOUT ids=1 moved=1 canon=8c8910c71fce]
test_renumber_plants: OK (12 plants: refusals refuse, admits admit with declared class)
DIRECT unit-UTF8 rc=0 elapsed_seconds=120.788 status=passed cleaned=true residual_processes=False
```

Each complete set of selected gate/selftest lines is in `direct-unit-C.txt` / `direct-unit-UTF8.txt`; the latter's elapsed time was 120.788 seconds, the former's 89.343 seconds.

Both configurations are exported by the invoking shell. `common.sh` then pins `NO_COLOR=1` and `TERM=dumb`, so the second run checks robustness to the caller environment; it does not test styled engine output as an accepted protocol. Independent batteries ran serially; no concurrent dune battery was started.

Every ambient input/pin read in common.sh: `GIT_CONFIG_GLOBAL` and command availability via `PATH` (lem/lake/opam/dune); `CERB_ORACLE_BIN_OVERRIDE`, `CERB_LEAN_BIN_OVERRIDE`; `CERB_OBSERVATION_DIR`; `SKIP_BUILD`; `CERB_TEST_MEM_MAX` (default 4G); `CERB_TEST_FUEL` (default 100000000). It exports `NO_COLOR=1`, `TERM=dumb`, sets `LEAN_ABORT_ON_PANIC=1` for run_cerberus_lean, and passes `CERB_MEM_MAX=$TEST_MEM_MAX` to per-test capped commands. Build/proof capped invocations inherit this audit's `CERB_MEM_MAX=48G`; dune inherits `DUNE_CACHE=disabled`. Locale is inherited here (the relevant sorting gates pin C internally). `CERB_DRIVER_FRESH_OVERRIDE` is documented here but read in the delegated freshness checker; `TIMEOUT_SECS` is set/read by callers, not selected by common.sh. `BASH_SOURCE`, `$0`, PID and TTY status determine local paths/capture names/color escapes. Internal PROJECT_ROOT/TMP_DIR/TIME_BIN/CAPPED_BIN variables are assigned by the harness, not optional environment overrides.

VERDICT: MOVED-WITH-RULING · evidence: `git diff ae1a5448c df1fdaf02 -- scripts/test_unit.sh scripts/LADDER.md`; direct plant/unit runs; `scripts/common.sh` · residual risk: Regex scanners, asymmetric baselines and finite adversarial cases do not prove completeness, and serialized runs do not establish safe concurrent dune batteries. · mover: lean_frontend/TODO.md raw-string census/dependency-set pin items; master plan step 7 repeat audit and fresh-noodler exit.

## 6. Consumer surface

I read the actual consumer main checkout in place, including `scripts/semantics-pin.env`, DECISIONS, KNOWN-OPEN-ITEMS, FUEL.md and tracked theorem sources. At the read, main was `1e1f584afcacef628b8e198f8f22bc4dd4183322`; a follow-up `git status --porcelain --untracked-files=no` returned no tracked changes, on the same main HEAD. Its pin is literally:

```
CERBERUS_LEAN_COMMIT="89f7e688530c6910884518811d645e4e892e4507"
```

The pin's latest entry records the [USER 2026-09-07] R1 landing and LemLib `f6542f8`. This supersedes the older `f95ef8d9c` consumer starting point used by provider planning records; it does not retroactively make those dated measurements false. The corrected independent census covers **64 tracked main Lean files (derived)**, excluding the consumer's other worktrees and dependency stores. Comment-only references to retired `CerbFuel.driverFuel`/`CerbND.drive_lemFuel` in Audit.lean are not live uses.

All ten change manifests newly added since B lie at or before the consumer's current provider pin:

| Manifest | Adoption evidence I read in current consumer source |
|---|---|
| 2026-09-02_mem-scale | Current reconstruction/serialization workers and reference-view proof uses; the f95ef8 pin entry explicitly carried this change. |
| 2026-09-03_fuel-arc | Fuel kill constructors/contracts in Heap, Adequacy and DriverCollapse; its intermediate fixed-budget interface is superseded by C1–C4. |
| 2026-09-03_pin-bump | EnvLaws operates on Pmap/Fmap, proves comparator and map invariants; old TreeMap-only Fmap proofs are replaced. |
| 2026-09-03_zero-discrepancy-Z1 | Heap/Round use the changed killM arms and transparent switch facts; current pin includes the mirrors. |
| 2026-09-04_zero-discrepancy-Z2 | Allocation and byte rules use signed size/alignment, requested-address restrictions, PrefMalloc/lastUsed and signed intToBytes. KNOWN-OPEN-ITEMS B21 spells out narrowed theorem coverage. |
| 2026-09-04_fuel-parameter-C1 | Actual `[LemFuel]` hypotheses and generated drive calls; no live old mirror/default references in the inspected uses. |
| 2026-09-04_fuel-parameter-C2 | Fragment/Substitution explicitly use subst_sym_pexpr_measure_sufficient; Soundness/EvalClass use evaluation sufficiency. |
| 2026-09-05_fuel-parameter-C3 | Round uses get_ctx_measure_sufficient; EnvLaws imports LemLibPmapLaws and consumes its laws. |
| 2026-09-05_fuel-parameter-C4 | Heap/TreeRot use CerbTagsWf.envBound and current layout/reconstruction equations. |
| 2026-09-05_cerbglobal-defs | Heap/Round use CerbGlobal.has_switch_eq; default-mode reasoning can unfold current_execution_mode. |

This is source/pin adoption evidence, **not a consumer build rerun**. The read-only charter does not authorize modifying that checkout to re-prime/build it. Consumer proof-check success at this provider target is therefore UNKNOWN in this audit.

`git diff --stat 89f7e6885 df1fdaf02`, inspected by paths, shows the newer validation-foundations instrumentation, observation/status capture, release runner, independent build/oracle, content pins, failure/provider probes and documentation are outside the consumer pin. The delivered model/seam definitions and LemLib revision did not change in that interval; the only added .lem file is the standalone failure probe. No post-B change manifest is missing from the pinned ancestry. The consumer has not thereby adopted the newer provider instruments or discharged their newly exposed correspondence/release obligations.

Provisionality and actual promised statements:

- General inputs reaching the new kind-1 `panic!` arms remain PROVISIONAL in the Z1/Z2 manifest sense: native fail-stop and in-process default denotation are not yet connected by a faithful outcome theorem. Consumer KNOWN-OPEN-ITEMS A5 records that reachability burden; its report of 117 panic arms is its own dated census, not a count certified by this audit.
- Do **not** mark all current consumer exports PROVISIONAL merely because the provider has pending fuel rows. Current KNOWN-OPEN-ITEMS A1/A2 marks its fuel restatement closed for its fragment, and B10 says there are zero PROVISIONAL labels after F1. I read actual fuel/depth hypotheses in the sources; I did not recheck their proofs. The eight provider-pending workers remain provider debt.
- Arbitrary tag environments require `Acyclic` or `AcyclicPair` when using the six conditional sufficiency theorems. The consumer's current fragment uses empty/concrete tag environments and explains this in FUEL.md; it does not silently gain a blanket frontend-acyclicity theorem. A broader C-file frontend/linking theorem would need that obligation discharged at its real entry.
- The promised zero-fuel and sufficiency lemmas exist at HEAD with the restrictions in §3 and passed the cone checks. General absorbing propagation/monotonicity is not among the delivered conclusions.
- Pmap/Fmap lookup laws exist at HEAD with comparator/WF hypotheses, and EnvLaws actually supplies/maintains those predicates. This closes the missing-law API item; it does not validate arbitrary maps.
- Allocation exports were narrowed: `region_loop_certified_production` gained positive alignment and nonnegative size; `malloc_list_certified_production` gained positive alignment. Requested-address create has no rule. These are visible premise changes, disclosed by B21 and source definitions, not merely compilation repairs.
- Provider-native correspondence, strict failures, byte-string parity and broad accepted-domain/completion claims remain open (master plan steps 2–3 and step 5). Consumer whole-file/library adequacy is separately open (KNOWN-OPEN-ITEMS A7). Neither this audit nor a small provider smoke theorem closes those obligations.

VERDICT: MOVED-WITH-RULING · evidence: consumer `scripts/semantics-pin.env`, DECISIONS/KNOWN-OPEN-ITEMS and tracked use census; `git diff 89f7e6885 df1fdaf02` · residual risk: Source adoption is visible, but this audit has not rebuilt the consumer or proved provider failure/native correspondence or whole-C-file adequacy. · mover: master plan step 6 consumer adoption exit, following steps 2–5 provider semantics obligations.

## 7. Summary and operator answer

The final branch/source/file-fence checks are retained in [final-fence.txt](2026-09-07_risk-map-baseline-evidence/final-fence.txt). Only this record and the permitted evidence directory were added; existing tracked files have no diff. No merge or push was performed.

| Surface | Verdict | Evidence | Residual risk | Mover |
|---|---|---|---|---|
| Oracle | MOVED-WITH-RULING | §1 A/B hunk census; independent hashes and pristine execution. | Finite matched-mode checks do not establish complete upstream equivalence. | Master steps 2 and 5. |
| Execution | MOVED-WITH-RULING | §2 cold builds, 32/32 full ladder, direct witnesses and shard 2/6. | Historical timing causes and general completion remain unresolved. | C-P1, C-Z4; master steps 2–5. |
| Definitions | MOVED-WITH-RULING | §3 raw fuel table, proof cones, source signatures and consumer uses. | Conditional sufficiency is not native/OCaml correspondence or successor propagation. | Master steps 2–3 and 5; F-A2, C-P1; Lem TODO 13. |
| Trust base | MOVED-WITH-RULING | §4 independent census/population differences, direct gates, ISO marker grep. | Native boundaries, broad partial code and R3's missing marker remain. | C-TF1/F7; C-Z4 marker/register gate. |
| Gates | MOVED-WITH-RULING | §5 B→target diff, all mechanisms run, structural plant reads, both locale runs. | Regex and finite-plant coverage are incomplete; dependency-set/raw-string gaps remain. | Named TODO census/dependency-set items; master step 7. |
| Consumer | MOVED-WITH-RULING | §6 actual main pin, clean tracked source uses and manifests. | Fresh consumer proof-check and whole-file/native-failure adequacy are unmeasured/open. | Master step 6 following provider steps 2–5. |

[AGENT auditor] The trust surface has moved since the split on all six audited surfaces, including removal of the effect axiom/global runtime references and addition of explicit fuel and conditional sufficiency contracts.
Every movement identified in this pass has ruling or instrument provenance, with no MOVED-UNRULED oracle finding; correspondence, historical timing, marker compliance and fresh consumer proof-check obligations remain open rather than established by the green gates.

VERDICT: MOVED-WITH-RULING · evidence: `git status --porcelain` / final-fence.txt:1 and the measured commands in §§1–6 · residual risk: This baseline audit records known limits and cannot substitute for the master's remaining correspondence, adoption and repeat-audit exits. · mover: master plan steps 2–7.


## 8. Orchestrator review of this record (2026-09-07)

[AGENT orchestrator] — a separate author; §§0–7 above are the auditor's.
Fence: `git status --porcelain` at the auditor's final commit listed only
the record and the evidence directory (`final-fence.txt`); no tracked file
changed; evidence 992 KB, no archives. The four documentary gaps the
auditor named were re-verified on this tree:

| Gap | Re-verification |
|---|---|
| R3 marker absent | `grep -rn "ISO-fix register R" lean_frontend/*.lean` → R1 (`CerbDecode.lean:102`), R2 (`:175`, `:184`) only. Known C-Z4 item. |
| Acyclic "guarantee" overstated | `scripts/fuel_hypotheses.txt:43-46`, `CerbTagsWf.lean:19-40` say "holds for every program the frontend ACCEPTS CORRECTLY" with the F-A2 gap noted — a conjecture presented as a guarantee. TODO row added. |
| CerbGlobal "identical by construction" overbroad | `git show ae1a5448c:lean_frontend/CerbGlobal.lean:37` `backendName := "cerberus-lean"`; HEAD `CerbGlobal.lean:101/140/186` `"Driver"`. Erratum appended to the cerbglobal record; TODO row for the comment. |
| Sweep record "12 TIMEOUT" | `grep -c "^[^#].* TIMEOUT$" scripts/exec_csmith_corpus_baseline.txt` → 9; the 12 counted 3 comment hits. Erratum appended to that record. |

Verdicts accepted as stated: six surfaces MOVED-WITH-RULING, none
MOVED-UNRULED; the auditor's independent re-derivations (86/22 generated
files, 38-row native pin population, 81/54/13/8/6 fuel census, 709/1/11/2
pristine lane, 32/32 cold ladder, both locale/terminal unit runs) agree
with the repo's gates. The operator's question is answered in §7: the
trust surface moved on every audited surface since the split, every
movement carries a ruling or an instrument commit, and the open items are
obligations the plan already names, not undisclosed movement.
