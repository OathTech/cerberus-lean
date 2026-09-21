# Program-data parameters — E-A + D-A record (2026-09-20)

**Status (final, 2026-09-21):** E-A is DONE and audited — Phase 1 = E-A ALONE (readers `enum_definitions`, `tagDefs`; the `digest` reader is BLOCKED structurally at this pin, §3.1 — the D-A route is the operator's open decision). The branch `arc/program-data-parameters` = mainline `5407597d9` + `3ad477462` (E-A Phase 1) + `70408e483` (seven D3 witnesses) + `0e1968ffb` (rebase, first full re-gate, record) + the pre-merge-audit repair commit (§10: E1 the seed-closure regression, E2 two Core-file literals, E3 the run-integrity claim, E4 the signedness domain, six more witnesses, the boundary docs). The FINAL source-stable full battery (§10.6, evidence dir `2026-09-20_program-data-parameters-EA-DA-evidence/`) is the certification; the earlier runs (§5, §9.4) are dated history, as are the two stops (§2 S4/S6 on 2026-09-20; §3.6 F-1). Waiting for the E-A delta audit; Phase 2 does not start.

## 0. Decisions restated (provenance as in the charter §0) and errata found in Phase 1

- **D1 [AGENT orchestrator]** — the enum map lives in `A.sigma.enum_definitions : list (Symbol.sym
  * Ctype.integerType)` and the Core `file.enumDefs : map Symbol.sym Ctype.integerType`; the
  Core-text printer is NOT changed; every non-generated OCaml full `Core.file` literal gains the dead
  field (compiler-forced; the D1 site list).
- **D2 [AGENT orchestrator]** — normalise FIRST, one consumer: `Implementation.normalise_integerType`
  is the `reader_consumer`; the four layout vals become shared one-line lem wrappers over renamed
  `*_norm` reps (OCaml reps unchanged; the Lean reps keep their names and their type-only
  signatures); `max_ival`/`min_ival` are consumers too; `typeof_enum` keeps a SHARED lem body;
  `register_enum`'s Lean rep is the pure `true`.
- **D3 [AGENT orchestrator]** — desugar-time reads see the registry-so-far: every desugar-time path
  into the consumers is seeded from the DESUGAR STATE (`Enum_definition ns ↦ enum_compatible_type ns`
  over `st.tag_definitions`) through N-ary `reader_seed` defs; typing/translation get the complete
  per-TU map from the sigma; the run gets the linked `runFile.enumDefs`.
- **D4 [AGENT orchestrator]** — the digest is `declare {lean} reader val digest` (Phase 2 plumbing:
  per-TU value, the run's value = the LAST program TU's digest, S0 record §3).
- **D5 [AGENT orchestrator]** — reader order everywhere: `digest`, `enum_definitions`, `tagDefs`
  (sorted by name; S0 record §1.6 rule 1). The lem val is named `enum_definitions` exactly.
- Rulings honoured: [USER 2026-09-19] delegation of implementation-focused calls + "roll it
  together" (Q2); [USER 2026-09-04] "we don't change the lem structure for ocaml" (dead
  parameters and shared bodies excepted); [USER 2026-09-08] nothing new out of policy.

**Errata found by this worker (E-A1(a)) [AGENT worker 2026-09-20]:**

| # | Charter/record text | At `e110d7db2` |
|---|---|---|
| W1 | D2 names five consumer-side reps (`normalise_integerType`, the four `*_ity`, `max_ival`/`min_ival`) | **`Implementation.alignof_ty` is a SIXTH**: its OCaml rep `Ocaml_implementation.alignof` (`ocaml_implementation.ml:444-511`) resolves integer member types with `(get ()).alignof_ity` — i.e. through the enum registry — and it is a DESUGAR-TIME read: `cabs_to_ail_effect.lem:2200-2217` `get_alignof` builds a closure over it, consumed by `cabs_to_ail.lem:2793-2866` (`_Alignas` / redeclaration alignment checks). The Lean rep `CerberusImpl.alignof_ty` (`CerberusImpl.lean:224-258`) calls `alignof_ity` on the raw member type, which under D2 is the un-normalised-Enum leaf. Fix (within fence): `declare {lean} reader_consumer val alignof_ty`; the Lean rep takes the three readers and normalises through `normalise_integerType d e t`. Applied in the Stage A lem (§1.3). |
| W2 | D1: "`CoreParser` defaults `enumDefs := fmapEmpty` (`CoreParser.lean:2329,2660,2986` and the `pCoreFile` result)" | Those sites build CoreParser's OWN `structure CoreFile` (`CoreParser.lean:2292`), not the generated `Core.file`; no field is needed there. The only generated-`file` literal assembled from a parsed dump is `Main.lean:833-840` (`loadLibc`, the `read_core_object` mirror) — the `enumDefs := fmapEmpty` default belongs THERE (mirrors `pipeline.ml:666` `read_core_object`, whose registry is empty). `CoreParser.lean` needs NO change. |
| W3 | E-A2: "`cabs_to_ail_effect.lem:2538-2539` the arm … (also `:594`/`mini_pipeline.lem:42` literals)" | `:594` is the desugar-STATE literal (`tag_definitions= Map.empty`, the `inner` record), not a sigma. The sigma builders that must gain `A.enum_definitions` are THREE: `:2522-2548` `mk_current_ail_sigma` (used by `is_complete_object`/`is_incomplete`, `:2553-2563`), `:2711-2735` the final sigma at `desugar`'s tail, `:2772-2820` `get_sigma_sofar` (the const-expr mini-run's and `Init_expr` typing's sigma); plus the two `empty_sigma` literals `ailSyntax.lem:324-341`, `mini_pipeline.lem:36-52`. |
| W4 | E-A2 lem list; fence §3 (lem: `implementation, symbol, mini_pipeline, cabs_to_ail_effect, cabs_to_ail, core, core_linking, translation`, `ail/ailSyntax`, `ail/ailTypesAux`) | A `C.file` field forces every FULL `file` record literal in lem: in fence `translation.lem:4576-4584`, `core_linking.lem:291-300`, `mini_pipeline.lem:149-161` (`dummy_core_file` — not named by the charter); **OUTSIDE the fence** `core_typing.lem:1968-1977` (`typecheck_program`), `core_rewrite2.lem:809-816` (`rw_file`), `core_run_aux.lem:723-734` (`convert_file`) — one dead line `enumDefs= file.enumDefs;` each (the lem analogue of D1's OCaml rule). Fence ruling needed (§2). |
| W5 | Fence §3 (Lean hand-written: `CerberusImpl, CerbMem, CerberusFresh, Main, CerbCall, CoreParser, native/md5.c, test/Unit/*, speclab …`) | Threading `enumDefs` "to every internal normalisation" of `CerbMem.lean` (E-A4) reaches the MEASURED mutual layout workers `memberAlign/offsetsofMembers/offsetsof/sizeofCtype/alignofCtype_lemFuel` (`CerbMem.lean:379-537`, leaves `CerberusImpl.sizeof_ity/alignof_ity` at `:463,:515` on member types that can be `.Enum0`), `memValueToBytes_lemFuel` (`:713,:718`), `reconstructValue_lemFuel` (`:1021`, `:1178`). Their signatures gain the parameter, so the sufficiency theorems in **`CerbMem_lemMeasureProofs.lean`** (`layout_stable_aux :448-680`, `memValueToBytes_stable_aux/measure_sufficient :93-132`, and the `reconstructValue` block — dozens of `f ambient tagDefs …` applications) must be restated — a file the fence does not list. `scripts/fuel_hypotheses.txt` keys on worker name + hypothesis text (`CerbTagsWf.Acyclic ambient`) and would NOT move. Fence ruling needed (§2). No fence-internal alternative is honest: pre-normalising the argument ctype misses struct MEMBER types (they come from the tag map); pre-normalising the map changes the member `ty` that `offsetsof` returns and `loadM` stamps on `MVinteger` (an observable value — a movement hazard); the consumer-stable `CerberusImpl.*_ity` signatures are D2. |
| W7 | S0 record §4 E11 / charter §1: "`initial_driver_state` … draws a symbol via `fresh_given_int` and so LIFTS under D-A — one more consumer-visible signature" | In the `e110d7db2` tree `fresh_given_int` has exactly ONE generated caller, `Core_run.lean:126` (`fresh_symbol'`: `(fresh_given_int n, { run_st with sym_supply := n + 1 })`); `Driver.lean:495` `initial_driver_state (_lemSupply_fresh_int : Nat) …` and `Core_run_aux.lean:429` `initial_core_run_state (_lemSupply_fresh_int : Nat) …` are SUPPLY-lifted (a `supplySplit` draw seeds `sym_supply`) and mint NO symbol — no digest read. Prediction: `initial_driver_state` does NOT lift under D-A; the consumer note loses that row. To be confirmed by the regenerated tree's binders (Phase 2). |
| W6 | S0 record §1.6 verdict "everything else is SUPPORTED AS-IS"; charter §1 "whatever else the regenerated tree's binders demand" | **The pinned backend (`Lem 4307dc5`) refuses a fuel'd TRULY-MUTUAL block that becomes reader-lifted** (`lean_backend.ml:4604-4606`, a deliberate `Some _ when is_truly_mutual && lifted` guard: "unsupported; extend when needed"). Two such blocks sit in the enum reach: `ailTypesAux.lem:784-862` `are_compatible`/`are_compatible_params_aux`/`are_compatible_params` (fuel `:1336-1338` + `fuel_measure` `:1348-1350`; it calls `Implementation.normalise_integerType` at `:792-796`) — refused verbatim in §1.2 — and `ctype_aux.lem:89-220` `are_compatible_aux`/`are_compatible_params_aux`/`are_compatible_params` (fuel `:287-289` + `fuel_measure` `:295-297`; in the derived reach, §1.1, to be confirmed by the lem run once the first is fixed). Both genuinely depend on the enum map on BOTH targets (C's enum/compatible-integer-type compatibility, §6.7.2.2#4), so no lem-source shape avoids the lifting under the [USER 2026-09-04] rule. **Stop rule S4.** |

## 1. E-A1 — the reach inventory

### 1.1 (a) Static reach — DERIVED from the `e110d7db2` generated Lean tree (token closure)

Method [derived, approximate]: over `lean_frontend/generated/*.lean` as at `e110d7db2` (219 modules;
snapshot `.tmp/eada/gen-base/`), every `def` whose BODY mentions a seed name joins the reach, and its
own name (and the wrapper of a `*_lemFuel` worker) becomes a seed; propagation only through GENERATED
modules (the hand-written seams are the consumers themselves). Enum seeds = the consumer reps
`CerberusImpl.{normalise_integerType, sizeof_ity, is_signed_ity, alignof_ity, precision_ity, alignof_ty,
typeof_enum}`, `CerbMem.{maxIval, minIval}`; digest seed = `CerberusFresh.digest`. Generated Lean has no
per-module namespaces (bare global names), so bare-token matching is the right model; the residual
imprecision is name collision (over-) and the rare qualified reference (under-). Flags: `M` = inside a
column-0 `mutual … end` block (truly mutual), `F` = fuel'd (`*_lemFuel` worker or wrapper), `L` = already
reader-lifted by `tagDefs` (has `_lemReader_tagDefs`). Instances/theorems in either reach: NONE (rule 6
fail-closed positions are clear). Script: `.tmp/eada/reach2.py` (ephemeral; the tables below are the record).

**ENUM reach: 267 generated decls, 129 NEWLY lifted defs (the rest already carry `tagDefs`).**

| Module | defs in reach | already `tagDefs`-lifted | NEWLY lifted | fuel'd truly-mutual |
|---|---|---|---|---|
| AilTypesAux | 24 | 0 | 24 | **3** (`are_compatible_lemFuel`, `are_compatible_params_aux_lemFuel`, `are_compatible_params_lemFuel`) |
| Cabs_to_ail | 47 | 46 | 1 (`find_compatible_generic_association`) | 0 |
| Cabs_to_ail_aux | 1 | 0 | 1 (`make_composite_fdecl`) | 0 |
| Cabs_to_ail_effect | 5 | 0 | 5 (`get_alignof`, `get_compatible_alignment_requirements`, `register_external_object_declaration`, `register_function_declaration`, `register_global_object_definition2`) | 0 |
| Core_aux | 2 | 2 | 0 | 0 |
| Core_eval | 11 | 5 | 6 (`eval_pexpr_aux2[F]`, `eval_pexpr_aux_broken[F]`, `mk_call_catch_exceptional_condition`, `mk_conv_int`, `mk_wrapI`, `mk_wrapI_op`) | 0 |
| Core_reduction | 5 | 4 | 1 (`full_eval_pexpr[F]`) | 0 |
| Core_reduction_aux | 2 | 0 | 2 (`is_fs_function`, `step_fs_proc`) | 0 |
| Core_run | 7 | 7 | 0 | 0 |
| Core_typing | 7 | 0 | 7 (`infer_action`, `infer_pexpr[M]`, `typecheck_action`, `typecheck_export_pexpr`, `typecheck_expr`, `typecheck_pexpr[M]`, `typecheck_program`) | 0 (mutual, NOT fuel'd — supported) |
| Ctype_aux | 8 | 1 | 7 | **3** (`are_compatible_aux_lemFuel`, `are_compatible_params0_lemFuel`, `are_compatible_params_aux0_lemFuel`) |
| Defacto_memory | 49 | 42 | 7 (`impl_allocate_object`, `impl_allocate_region`, `impl_max_ival`, `impl_min_ival`, `impl_sizeof_ival`, `impl_sizeof_ival_aux`, `register_address_constraints`) | 0 |
| Defacto_memory_aux | 4 | 3 | 1 (`simplify_integer_value_base[F]`) | 0 |
| Driver | 17 | 14 | 3 (`drive_nonmemory_steps_aux2[F]`, `driver2[F]`, `print_eval_conv_aux[F]`) | 0 |
| Formatted | 9 | 7 | 2 (`is_illtyped_conversion`, `load_character_array_aux[F]`) | 0 |
| GenTypesAux | 8 | 0 | 8 | 0 |
| GenTyping | 20 | 0 | 20 (incl. `annotate_program`, `annotate_sigma`, `annotate_expression[M]`, `in_range`, `typecheck_constant`) | 0 (mutual, NOT fuel'd) |
| Implementation | 6 | 0 | 6 (`integerImpl`, `is_compatible_with_ptrdiff_t`, `is_compatible_with_size_t`, `is_signed_or_unsigned`, `is_signed_or_unsigned_aux`, `normalise_ctype` (partial def)) | 0 |
| IntegerImpl | 4 | 0 | 4 (`min_integer_range`, `min_precision`, `min_range_signed`, `min_range_unsigned`) | 0 |
| Mem_common | 3 | 0 | 3 (`derive_intrinsic_signature`, `resolve_arg`, `try_usual_arithmetic`) | 0 |
| Mini_pipeline | 5 | 2 | 3 (`in_range_of_signed_int`, `run_const_expr_driver` (the seed def — must stay a seed), `typecheckAil`) | 0 |
| Translation | 19 | 5 | 14 (incl. `translate_constant`, `translate_integerConstant`, `mkTestExpression`) | 0 |
| Translation_aux | 3 | 0 | 3 (`combine_params_args`, `ctype_of`, `qualified_ctype_of`) | 0 |
| Undefined | 1 | 0 | 1 (`pretty_string_of_undefined_behaviour`) | 0 |

Full member list (flags as above): AilTypesAux: agnostic_alignment_requirement_ord, are_compatible[F], are_compatible_lemFuel[MF], are_compatible_params[F], are_compatible_params_aux[F], are_compatible_params_aux_lemFuel[MF], are_compatible_params_lemFuel[MF], are_pointers_to_compatible_complete_objects, are_pointers_to_compatible_objects, compatibleWithQualifiedUnqualifiedVersionOf, in_min_integer_range, integer_promotion, is_signed_integer_type, is_signed_ity, is_unsigned_integer_type, is_unsigned_ity, le_integer_range, make_composite, make_composite_params, pointers_to_compatible_types, promotion, usual_arithmetic_integer, usual_arithmetic_integer_CHERI, usual_arithmetic_integer_default · Ctype_aux: are_compatible0[L], are_compatible_aux[F], are_compatible_aux_lemFuel[MF], are_compatible_params0[F], are_compatible_params0_lemFuel[MF], are_compatible_params_aux0[F], are_compatible_params_aux0_lemFuel[MF], match_integer_ctype · (the other modules' members are the counts above; `.tmp/eada/reach-base.json` holds the list until slice end).

**DIGEST reach: 117 generated decls, 56 NEWLY lifted defs; no fuel'd truly-mutual block.**

| Module | defs | already lifted | NEWLY lifted |
|---|---|---|---|
| Cabs_to_ail | 54 | 46 | 8 (`desugar_and_register_cn_datatype`, `desugar_cn_arg`, `register_additional_cn_var`, `register_and_desugar_cn_pattern`, `register_cn_datatype_names`, `register_cn_function_names`, `register_cn_predicate_names`, `register_labels`) |
| Cabs_to_ail_effect | 14 | 0 | 14 (`fresh_sym`, `fresh_sym_cn`, `fresh_sym_description`, `fresh_sym_object_address`, `fresh_sym_pretty`, `get_gamma_sofar`, `internal_register_identifier`, `register_cn_ident`, `register_cn_lemma`, `register_enum_constant`, `register_label`, `register_ordinary_identifier`, `register_tag`, `register_typedef`) |
| Core_reduction | 2 | 1 | 1 (`fresh_symbol0`) |
| Core_run | 4 | 2 | 2 (`fresh_symbol`, `fresh_symbol'`) |
| Driver | 7 | 5 | 2 (`drive_nonmemory_steps_aux2[F]`, `driver2[F]`) — `initial_driver_state` is NOT in the reach (W7) |
| GenTyping | 2 | 0 | 2 (`annotate_program`, `annotate_sigma`) |
| Mini_pipeline | 3 | 2 | 1 (`run_const_expr_driver` — stays a seed) |
| Symbol | 9 | 0 | 9 (`fresh`, `fresh_cn`, `fresh_description`, `fresh_fancy`, `fresh_funarg`, `fresh_given_int`, `fresh_object_address`, `fresh_pretty`, `fresh_pretty_with_id`) |
| Translation | 17 | 5 | 12 (incl. `erase_loop_control`, `erase_loop_control_aux`) |
| Translation_effect | 5 | 0 | 5 (`fresh_elab_pretty_with_id`, `fresh_elab_sym`, `with_block_objects`, `wrapped_fresh_symbol`, `wrapped_fresh_symbol_`) |

Overlap: 76 decls in both reaches, 191 enum-only, 41 digest-only.

**Desugar-time reads the D3 seeds must cover (the enum reach entering from a `desugM` site) [derived]:**

| # | desugM site (lem) | reaches the consumer through | seed source at the site |
|---|---|---|---|
| S-1 | `cabs_to_ail.lem:1127-1140` `evaluate_integer_constant_expression` → `Mini_pipeline.evalIntegerConstantExpression` | `GenTyping.annotate_expression` (typing: `in_range` → `precision_ity`/`is_signed_ity`; `AilTypesAux.integer_promotion`/`le_integer_range` → `normalise_integerType`), `Translation.translate_expression` (`translate_integerConstant` etc.), then the mini-run (`run_const_expr_driver`, already a seed) | `get_sigma_sofar`'s `sigm` is in hand: `Map.fromList sigm.A.enum_definitions` (= the registry-so-far, Q-A) |
| S-2 | `cabs_to_ail.lem:3187-3190` `Init_expr` → `Mini_pipeline.typecheckAil sigm gamm d_e` | `GenTyping.annotate_expression` | same `sigm` |
| S-3 | `cabs_to_ail_effect.lem:2200-2217` `get_alignof` → `Implementation.alignof_ty` (consumer, W1) | direct | `get_tag_definitions`' map (the same `tagDefs` the pseudo map is built from) |
| S-4 | `cabs_to_ail_effect.lem` `register_function_declaration`, `register_external_object_declaration`, `register_global_object_definition2` (redeclaration compatibility) | `AilTypesAux.are_compatible` / `make_composite` (`Cabs_to_ail_aux.make_composite_fdecl`) → `normalise_integerType` | `read_inner`'s `st.tag_definitions` |
| S-5 | `cabs_to_ail.lem` `find_compatible_generic_association` (`_Generic`) | `AilTypesAux.are_compatible` | the enclosing desugM's state |
| S-6 | `mini_pipeline.lem:247-259` `in_range_of_signed_int` | `Mem.min_ival/max_ival (Signed Int_)` — enum-FREE by construction (a literal non-enum type) | none needed; on the binder (a miss is impossible; a future change makes it loud) |

Every other newly-lifted Cabs_to_ail def is lifted transitively THROUGH these sites (or through `tagDefs` already). The typing entry (`GenTyping.annotate_program`) and `Translation.translate` receive the COMPLETE per-TU map from the sigma; the run receives the linked map (D3).

### 1.2 The Stage A lem run — the S4 refusal, verbatim

Command: `scripts/ce make lean-prelude-src` (the Stage A lem of §1.3 in place: the `enum_definitions`
reader + the D2/W1 consumers + the shared bodies and wrappers; the `digest` declare NOT yet added, so
the run isolates the ENUM reach). Wall: `16.90s user 0.27s system 99% cpu 17.171 total`; exit
`make: *** [Makefile:352: lean-prelude-src] Error 1`. `lean_frontend/lem.log:384-386`:

```
File "frontend/model/ail/ailTypesAux.lem", line 784, character 1 to line 862, character 51 processed by: compile_faux_seplist, mk_case_exp
  Error: Lean backend: 'declare {lean} fuel val' in a mutual block combined with reader lifting (unsupported; extend when needed)
  original input:
let rec ~{coq} are_compatible (qs1, Ctype _ ty1) (qs2, Ctype _ ty2) =
```

Backend site (`deps/lem-pinned/src/lean_backend.ml:4603-4606`, `Lem 4307dc5`):
```
                     | Some _ when is_truly_mutual && lifted ->
                       raise (Reporting_basic.err_general true (locn_of_clause_group g)
                         "Lean backend: 'declare {lean} fuel val' in a mutual block combined with reader lifting (unsupported; extend when needed)")
```
(the neighbouring comment: "fuel x reader composes (arc 3, B1): the worker's fuel counter is emitted
BEFORE the reader binders … lifted callers inject into the wrapper as for any lifted def" — the
single-def case IS supported; the guard is the truly-mutual case only).

lem stopped after emitting `Implementation.lean`; that module's diff against the snapshot is the
rendering evidence (verbatim excerpts, long lines cut at 260 columns):
```
> def  enum_compatible_type  (ns : List (Int))  : integerType :=
>   if  List.any  ns  (fun (n : Int) =>  intLtb  n (( 0 :  Int))) then  Signed  Int_  else  Unsigned  Int_
> def  typeof_enum (_lemReader_enum_definitions : Fmap (sym) (integerType)) (_lemReader_tagDefs : Fmap (sym) ((CerbLocation.Loc ×tag_definition)))  (tag_sym : sym)  : integerType :=
>   match  (fmapLookupBy  (fun (sym1 : sym) (sym2 : sym)=> ordCompare  sym1  sym2)  tag_sym  (_lemReader_enum_definitions)) with  |  some  ity =>  ity |  none => (failwithI  ( String.append "Ocaml_implementation.typeof_enum: '"   (String.append (show_symbol  t
> def  sizeof_ity (_lemReader_enum_definitions : Fmap (sym) (integerType)) (_lemReader_tagDefs : Fmap (sym) ((CerbLocation.Loc ×tag_definition)))  (ity : integerType)  : Option (Nat) :=  CerberusImpl.sizeof_ity  ((CerberusImpl.normalise_integerType _lemReader
> def  integerImpl (_lemReader_enum_definitions : Fmap (sym) (integerType)) (_lemReader_tagDefs : Fmap (sym) ((CerbLocation.Loc ×tag_definition)))  (_ : Unit)  : implementation :=
>  partial def  normalise_ctype (_lemReader_enum_definitions : Fmap (sym) (integerType)) (_lemReader_tagDefs : Fmap (sym) ((CerbLocation.Loc ×tag_definition)))  (c : ctype)  : ctype := match c with | ( Ctype  annots1  ty_) =>  Ctype  annots1 ( match  ty_ with
```
— the binders in sorted order (`enum_definitions` before `tagDefs`), the lookup by `ordCompare`
(symbol_compare parity), the miss `failwithI` with the OCaml text through `show_symbol`. The module was
then RESTORED from the snapshot (219/219 byte-equal; both lem-sync stamps unchanged) so the untracked
generated tree matches its stamp.

### 1.3 The Stage A lem edits (UNCOMMITTED in the working tree; `git status`: `M frontend/model/implementation.lem`, `M frontend/model/mem.lem`)

- `frontend/model/implementation.lem`: `enum_compatible_type` (shared GCC body, cite
  `ocaml_implementation.ml:130-136`); `enum_definitions` (OCaml rep `Ocaml_implementation.enum_definitions`
  — NOT yet written on the OCaml side, E-A3 pending; Lean coverage stub `CerberusImpl.enumDefinitionsUnreachable`
  — NOT yet written, E-A4 pending) + `declare {lean} reader val enum_definitions`; `typeof_enum` shared
  body (`Assert_extra.failwith`, renders `failwith` on OCaml / `failwithI` on Lean, OCaml text preserved);
  `normalise_integerType` + `alignof_ty` (W1) `reader_consumer`; the four `*_norm` reps and the four
  shared wrappers (D2); header prose describing what IS.
- `frontend/model/mem.lem`: `declare {lean} reader_consumer val max_ival` / `min_ival` (+ a 4-line comment).
- NOT yet done (pending the rulings of §2): the `digest` declare (`symbol.lem`), the sigma/file fields
  and arms, the translation/linking carry, the mini-run N-ary seed, the D3 seeds, all OCaml and Lean.

(b) Dynamic run: NOT RUN — it needs a buildable tree, which needs (i) the backend fix (W6) and (ii) the
fence rulings (W4, W5).

## 2. STOP — stop rules S4 (backend) and the fence rulings the charter's S3 analogue requires

**S4.** The pinned lem (`4307dc5`) refuses fuel'd truly-mutual blocks under reader lifting (§1.2). The
enum reader lifts two such blocks (W6): `AilTypesAux.are_compatible*` (refused, verbatim) and
`Ctype_aux.are_compatible_aux*` (derived reach). Both need the enum map on both targets; a lem-source
restructuring (de-mutualising, or threading a normaliser parameter) would change the lem structure for
OCaml against [USER 2026-09-04]. The fix is a paired lem-lean slice (the S0.5 shape): extend
`lean_backend.ml`'s fuel×reader composition to truly-mutual groups (the guard at `:4604-4606`; the
worker's fuel counter already precedes the reader binders in the single-def case), with a
`tests/comprehensive` reproducer (a fuel'd + `fuel_measure`d mutual pair reading a reader), the
`neg_*` probe for what stays unsupported, the DESIGN.md row, then the pin dance and a zero-movement
regeneration at the new pin BEFORE E-A resumes. Sizing [AGENT worker]: the S0.5 class (one guard →
one composition path + tests/docs); the `fuel_measure` obligations for a lifted mutual block need the
reader binders in the `_measure_sufficient` shells too — the lem-lean worker must check that path.

**Fence rulings requested (W4, W5; the charter's S3 rule for OCaml applied by analogy):**
1. lem outside the fence, compiler-forced, one dead line each: `frontend/model/core_typing.lem:1968-1977`,
   `frontend/model/core_rewrite2.lem:809-816`, `frontend/model/core_run_aux.lem:723-734`
   (`enumDefs= file.enumDefs;` in full `file` literals).
2. Lean outside the fence, signature ripple of the honest `enumDefs` thread through CerbMem's measured
   workers: `lean_frontend/CerbMem_lemMeasureProofs.lean` (restating the sufficiency/stability theorems
   over the new parameter — mechanical; the fuel-forms gate's argument correspondence and
   `scripts/fuel_hypotheses.txt` follow without edits since hypothesis texts do not move).
3. (Information, within fence) W1 `alignof_ty` as a sixth consumer; W2 no `CoreParser.lean` change, the
   default goes in `Main.lean:833-840`; W3 three sigma builders + two `empty_sigma` literals; the
   `dummy_core_file` literal `mini_pipeline.lem:149-161`.

Nothing else was touched: no OCaml, no Lean, no scripts, registers, baselines, or pins; no build ran;
no lane ran; nothing committed; nothing pushed.

### 2.1 Rulings received (2026-09-20, [AGENT orchestrator], relayed to this worker verbatim in substance)

- **S4 confirmed and acted on**: the refusal at `lean_backend.ml:4604-4606` (guard from lem-lean
  `a618b9c` "fuel composes with mutual blocks (arc 3, B2)") fires because `ailTypesAux.lem:784-862` and
  `ctype_aux.lem:283-297` are fuel'd truly-mutual blocks that now reach `normalise_integerType`; no
  lem-source reshaping under [USER 2026-09-04]. A paired lem-lean slice **S1.5** is chartered:
  `2026-09-20_charter-program-data-parameters-S1.5.md` (committed `0f5509872` on this branch; Part A
  in lem-lean, Part B — the pin bump, byte-identical regeneration, Tier A, record, one commit — and the
  E-A resume are this worker's after the re-launch).
- **Fence rulings GRANTED** (the charter's S3 rule applied by analogy):
  1. the three lem full-`file` literals `core_typing.lem:1968-1977`, `core_rewrite2.lem:809-816`,
     `core_run_aux.lem:723-734` gain the dead `enumDefs= file.enumDefs;` line (compiler-forced by D1);
  2. `CerbMem_lemMeasureProofs.lean` may be restated for the honest `enumDefs` thread (and, once S1.5
     lands, `AilTypesAux_lemMeasureProofs.lean` and `Ctype_aux_lemMeasureProofs.lean` for the reader
     binders their obligations gain) — mechanical restatements only, `scripts/fuel_hypotheses.txt`
     unmoved;
  3. W1 `alignof_ty` as the sixth consumer — accepted;
  4. W2 — accepted: no `CoreParser.lean` change; the `enumDefs := fmapEmpty` default at
     `Main.lean:833-840`;
  5. W7 — accepted: `initial_driver_state` does not lift under D-A; the consumer note loses that row
     (confirm on the regenerated tree in Phase 2).
- **Housekeeping ordered and done (§2.2)**: the Stage A lem edits saved as a patch and reverted, so the
  working tree at `0f5509872` carries only this untracked record draft; both generated trees re-checked
  against their lem-sync stamps. HOLD until the re-launch.

### 2.2 Housekeeping evidence

Steps run at `0f5509872` (`arc/program-data-parameters`), outputs verbatim:

- `git diff -- frontend/model/implementation.lem frontend/model/mem.lem > .tmp/eada/stageA.patch` →
  156 lines; `git apply --stat`:
  ```
   frontend/model/implementation.lem |  109 +++++++++++++++++++++++++++++++------
   frontend/model/mem.lem            |    6 ++
   2 files changed, 97 insertions(+), 18 deletions(-)
  ```
- `git checkout -- frontend/model/implementation.lem frontend/model/mem.lem`; then
  `git apply --check .tmp/eada/stageA.patch` → exit 0 (applies cleanly on `0f5509872`).
- `scripts/ce bash tools/check_lem_sync.sh --check` →
  `check_lem_sync: OK (src 037dee26c6472b1bf7f8d628bec1b7e64d2f9d12d67c81bd37b55e634fd34b2d, gen 08b84774381fd86eeb1a658efa47a9b372ebb438085530b5ab6ba045da3eec8d)` rc=0
- `scripts/ce bash tools/check_lem_sync.sh --check-lean` →
  `check_lem_sync: lean OK (src 037dee26c6472b1bf7f8d628bec1b7e64d2f9d12d67c81bd37b55e634fd34b2d, gen cd499eab48146463197f60b35a9fb26c31337bab7d06b2f1d9af43047c2619b5)` rc=0
- `git status --short` → `?? lean_frontend/docs/2026-09-20_program-data-parameters-EA-DA-record.md` (only this draft).

The patch lives in the ephemeral `.tmp/eada/` (with the `gen-base/` snapshot and the reach scripts);
it is re-applied when E-A Phase 1 resumes after S1.5 Part B.



## 3. Phase 1 — build log (E-A at `Lem 38f87d5`, on `52af8ccf1`)

### 3.1 D-A's lem line is BLOCKED (structural; stop-rule-S4 class for the digest; decision: E-A alone)

With `declare {lean} reader val digest` (symbol.lem) added beside the enum reader, `scripts/ce make
prelude-src lean-prelude-src` regenerates the OCaml tree and then FAILS the Lean tree with a lem
INTERNAL error (`lean_frontend/lem.log:385-386`, verbatim):
```
no location information available
  LEM internal error: lookup_mod_descr failed to find module 'IntegerType'
```
Cause, verified on the sources: `integerType` is defined in `frontend/model/integerType.lem`
(module `IntegerType`), imported by `ctype.lem` (`open import Pervasives Utils Loc Show Symbol` /
`import Annot IntegerType`), which imports `Symbol`; `symbol.lem` imports only
`Pervasives Utils Show Show_extra Enum Loc` + `Debug`. Under rule 2 (S0 record §1.6: every lifted
def takes ALL declared readers) the `digest` reader lifts `Symbol.fresh*` (`symbol.lem:247-281`),
which would then have to bind `_lemReader_enum_definitions : Fmap sym integerType` and
`_lemReader_tagDefs : Fmap sym (CerbLocation.Loc × tag_definition)` — types from modules
DOWNSTREAM of `Symbol`: lem cannot resolve the module (the internal error) and the generated
`Symbol.lean` would need an import cycle. The same regeneration with the digest declare removed
succeeds (§3.3) — the declare is the sole cause. The S0 probes had all three readers' types in one
module (or in modules downstream of every lifted def), so the case never arose there.

Consequence [AGENT worker], flagged for the orchestrator: D-A as chartered (D4/D5) cannot be
generated at this pin. Routes for the orchestrator to weigh (not this worker's call): (i) a
lem-lean rule change — a lifted def takes only the readers it transitively reads (per-def subsets,
in sorted order; consumer stubs keep all readers; the N-ary seed rule re-partitioned per def) — a
backend slice larger than S0.5/S1.5; (ii) a digest design that does not lift `Symbol.fresh*`
(e.g. the digest carried as data on the supply or the desugar state — a `.lem` structure change
against [USER 2026-09-04]); (iii) leave the digest as is (the design note §3.2 called D-A "the
contested item"; cerberus-sl's P-call-F note said "do NOT request it now"). Phase 1 proceeds with
E-A alone: readers `enum_definitions`, `tagDefs`; every "two leading arguments" below is ONE
(`enum_definitions`) before `tagDefs`; the consumer note will say so.

### 3.2 Further errata found while building (numbering continues §0's table)

| # | Text | Fact |
|---|---|---|
| W8 | fence: lem `ail/ailTypesAux.lem` only for D3 seeds; rulings (1) named three `file` literals | `frontend/model/ail/genTyping.lem:2377-2394` (`annotate_sigma`) is a FULL `A.sigma` literal — lem refuses without the new field (`ocaml_frontend/lem.log`: `File "frontend/model/ail/genTyping.lem", line 2378 … Type error: missing field: enum_definitions`). One dead line `enum_definitions= sigm.enum_definitions;` — compiler-forced by D1, the class of ruling (1); **applied and flagged** (an assumed fence extension). No other full sigma literal exists (grep `tag_definitions *=` over `frontend/model/**/*.lem`). |
| W9 | D1's driver-build-graph list: `backend/ocaml/runtime/rt_ocaml.ml:348`, `backend/ocaml/driver/core_opt.ml:58,77`, `backend/ocaml/driver/main.ml:75` | those literals ALREADY lack `calling_convention` (`rt_ocaml.ml:345-352`, `main.ml:72-80`, `core_opt.ml:55-63`) — they are NOT compiled by `dune build backend/driver/main.exe cerberus-lib.install cerberus.install` (the OCaml backend's own tree). Compiler-forced sites: `backend/common/pipeline.ml:288` (`Core.enumDefs= Pmap.empty Symbol.symbol_compare`), `:517` (`enumDefs= file.enumDefs`), `:677` (`read_core_object`: `enumDefs= Pmap.empty sym_compare` — a `.co` carries no enum map), `ocaml_frontend/rewriters/core_peval.ml:865`, `ocaml_frontend/rewriters/remove_unspecs.ml:106` (`enumDefs = file.enumDefs`). `build_cerberus` → `rc=0`; NO site outside the D1 list was forced (S3 not triggered). `bmc_utils.ml`/`instance.ml`/`cfg.ml` untouched (not built). |
| W10 | D2: "the four layout vals become SHARED one-line lem wrappers … OCaml `(Ocaml_implementation.get()).sizeof_ity` UNCHANGED" | a shared lem BODY makes `Implementation.is_signed_ity` a generated OCaml DEFINITION, and lem's OCaml renamer then renames `ailTypesAux.lem:28`'s alias `let is_signed_ity = Implementation.is_signed_ity` to `is_signed_ity0` (`ailTypesAux.ml:33`), breaking the non-generated callers `memory/concrete/impl_mem.ml:960` and `memory/vip/impl_mem.ml:326` (`Error: Unbound value AilTypesAux.is_signed_ity`) — sites outside the D1 list. Resolution within the fence (the `with_tagDefs` precedent, `ctype_aux.lem:32-33`): the four wrappers keep an OCaml `target_rep` at their previous reps — the lem body is Lean-only; the generated OCaml layout path is BYTE-IDENTICAL to before (`ailTypesAux.ml` back to baseline; `implementation.ml`'s delta shrinks to the shared `enum_compatible_type`/`typeof_enum` bodies + the `_norm` rep echoes). `typeof_enum` keeps its shared body as chartered (no clash: no other definition of that name). |
| W11 | S0 record §2.6 / audit N1: "the backend never checks a seed's type against its reader" | in the flesh: with `let run_const_expr_driver en tds dr_st` and no `val`, lem GENERALISED the unused-in-lem-body seed: `def run_const_expr_driver {a : Type} [LemFuel] (en : a) (tds : …)` — Lean would reject `driver2 en tds`. Fixed by a `val` type annotation on the seed def; every D3 seed def carries one. Rule for the charter/DESIGN.md: a seed def's `val` is MANDATORY when a seed is used only by injection. |
| W12 | rulings (2): `CerbMem_lemMeasureProofs.lean` + (post-S1.5) `AilTypesAux_`/`Ctype_aux_lemMeasureProofs.lean` | FOUR MORE hand-written proof files state generated obligations whose shells now carry `_lemReader_enum_definitions`: `Core_aux_lemMeasureProofs.lean` (`memValueFromValue_measure_sufficient`), `Core_eval_lemMeasureProofs.lean` (`step_eval_pexpr_measure_sufficient`), `Defacto_memory_lemMeasureProofs.lean` (`easy_update_mem_value_aux_`, `memcmp_load_aux_measure_sufficient`), `Driver_lemMeasureProofs.lean` (`hack_measure_sufficient`) — the same class as ruling (2); **restated mechanically and flagged** (an assumed fence extension). |
| W13 | E-A1(a) derived table (§1.1) | the REAL census on the regenerated tree (`.tmp/eada/gen-EA/`) is §3.4: 119 newly lifted decls incl. the `_zero` lemmas and obligation shells; the token closure had over-counted `Undefined`, `IntegerImpl`, `Core_typing` (no binder in the real tree) and under-counted `GenTyping`'s `perform_decays`, `Translation.translate_equality_operator`, `Defacto_memory.impl_sizeof_ival*`. |

### 3.3 Regeneration at `Lem 38f87d5` with the E-A lem (E-A2 complete except the D3 seeds — deliberately, for the dynamic run)

`scripts/ce make prelude-src lean-prelude-src` → `make rc=0 wall=34s` (then `35s` after W10, `34s`
after W11); stamps `check_lem_sync: recorded ocaml_frontend/lem_sync.sha256 (src 9384b687…, gen
5afdf71c…)`, `… lean_frontend/lem_sync.sha256 (src 9384b687…, gen a19f63d5…)` (the values after
the final lem edit). Generated OCaml files moved vs the `e110d7db2`/`52af8ccf1` tree (layer-2
candidates, §5): `ailSyntax.ml cabs_to_ail_effect.ml core_linking.ml core.ml core_run_aux.ml
core_typing.ml genTyping.ml implementation.ml mini_pipeline.ml translation.ml` (10; `ailTypesAux.ml`,
`ctype_aux.ml`, `defacto_memory*.ml` moved before W10 and are back to baseline after it).

Generated heads, verbatim (long lines cut):
```
def  run_const_expr_driver [LemFuel]  (en : Fmap (sym) (integerType)) (tds : Fmap (sym) ((CerbLocation.Loc ×tag_definition))) (dr_st : driver_state)  : List (…) :=
  let  driver_action  :=     nd_bind  ((driver2 en tds)  false)  (fun (u : Unit) =>  match u with |  () =>        nd_bind  nd_get  (fun (dr_st' : driver_state) =>          nd_return  ((finalize en tds)  "Mini_pipeline"  dr_st')       )      );
def  typeof_enum (_lemReader_enum_definitions : Fmap (sym) (integerType)) (_lemReader_tagDefs : Fmap (sym) ((CerbLocation.Loc ×tag_definition)))  (tag_sym : sym)  : integerType :=
def  sizeof_ity (_lemReader_enum_definitions : Fmap (sym) (integerType)) (_lemReader_tagDefs : Fmap (sym) ((CerbLocation.Loc ×tag_definition)))  (ity : integerType)  : Option (Nat) :=  CerberusImpl.sizeof_ity  ((CerberusImpl.normalise_integerType _lemReader_…
 def  are_compatible_lemFuel (lemFuel : Nat) (_lemReader_enum_definitions : Fmap (sym) (integerType)) (_lemReader_tagDefs : Fmap (sym) ((CerbLocation.Loc ×tag_definition)))  (p : (qualifiers ×ctype)) (p0 : (qualifiers ×ctype))  : Bool := match lemFuel with
theorem are_compatible_lemFuel_zero (_lemReader_enum_definitions : Fmap (sym) (integerType)) (_lemReader_tagDefs : Fmap (sym) ((CerbLocation.Loc ×tag_definition))) (p : (qualifiers ×ctype)) (p0 : (qualifiers ×ctype)) :
    are_compatible_lemFuel 0 _lemReader_enum_definitions _lemReader_tagDefs p p0 = (fuelExhausted false) := rfl
theorem are_compatible_measure_sufficient (_lemReader_enum_definitions : Fmap (sym) (integerType)) (_lemReader_tagDefs : Fmap (sym) ((CerbLocation.Loc ×tag_definition))) (p : (qualifiers ×ctype)) (p0 : (qualifiers ×ctype)) (lemFuel : Nat) (lemMeasureLe : (ctype.lemSize p.2 + ctype.lemSize p0.2 + 1) ≤ lemFuel) :
  AilTypesAux_lemMeasureProofs.are_compatible_measure_sufficient _lemReader_enum_definitions _lemReader_tagDefs p p0 lemFuel lemMeasureLe
def  desugar [LemFuel] (_lemReader_enum_definitions : Fmap (sym) (integerType)) (_lemReader_tagDefs : Fmap (sym) ((CerbLocation.Loc ×tag_definition)))  (sup : Nat) (address_space_top1 : Int) …
def  annotate_program (_lemReader_enum_definitions : Fmap (sym) (integerType)) (_lemReader_tagDefs : Fmap (sym) ((CerbLocation.Loc ×tag_definition)))  (p : (Option (sym) ×sigma (Unit)))  : errorM (…)
def  translate [LemFuel] (_lemReader_enum_definitions : Fmap (sym) (integerType)) (_lemReader_tagDefs : Fmap (sym) ((CerbLocation.Loc ×tag_definition)))  (sup : Nat) …
def  drive [LemFuel] (_lemReader_enum_definitions : Fmap (sym) (integerType)) (_lemReader_tagDefs : Fmap (sym) ((CerbLocation.Loc ×tag_definition)))   (with_concurrency : Bool) (file1 : generic_file (Unit) (core_run_annotation))  (arg_strs : List  String) …
def  initial_driver_state (_lemSupply_fresh_int : Nat)  (address_space_top1 : Int) (file1 : generic_file (Unit) (core_run_annotation)) (fs_state2 : CerbFS.FsState)  : ((driver_state) × Nat) :=
```
(the last: W7 confirmed — `initial_driver_state` carries no reader). Consumer call shapes:
`CerbMem.maxIval _lemReader_enum_definitions _lemReader_tagDefs …`,
`CerberusImpl.normalise_integerType _lemReader_enum_definitions _lemReader_tagDefs …`,
`CerberusImpl.alignof_ty _lemReader_enum_definitions _lemReader_tagDefs …`.

### 3.4 E-A1(a) — the REAL static census (regenerated tree vs the `e110d7db2` snapshot)

Defs/theorems carrying `_lemReader_enum_definitions`: 292 (every one also carries `_lemReader_tagDefs`;
the 5 mismatches are the hand-written proof files' obligation theorems, W12); tagDefs-lifted at the
baseline: 178; **NEWLY lifted: 119** — per module (names = the new ones):

- AilTypesAux 26: `agnostic_alignment_requirement_ord, are_compatible(+_lemFuel, _lemFuel_zero), are_compatible_params(+…), are_compatible_params_aux(+…), are_pointers_to_compatible_complete_objects, are_pointers_to_compatible_objects, compatibleWithQualifiedUnqualifiedVersionOf, integer_promotion, is_signed_integer_type, is_signed_ity0, is_unsigned_integer_type, is_unsigned_ity, le_integer_range, make_composite, make_composite_params, pointers_to_compatible_types, promotion, usual_arithmetic_integer(+_CHERI, _default)`; AilTypesAux_auxiliary 3 (the shells).
- Cabs_to_ail 1 (of 51): `find_compatible_generic_association`; Cabs_to_ail_aux 1: `make_composite_fdecl`; Cabs_to_ail_effect 5: `get_alignof, get_compatible_alignment_requirements, register_external_object_declaration, register_function_declaration, register_global_object_definition2`.
- Core_eval 4: `mk_call_catch_exceptional_condition, mk_conv_int, mk_wrapI, mk_wrapI_op`.
- Ctype_aux 10: `are_compatible_aux(+…), are_compatible_params0(+…), are_compatible_params_aux0(+…), match_integer_ctype`; Ctype_aux_auxiliary 3.
- Defacto_memory 2: `impl_sizeof_ival, impl_sizeof_ival_aux`. Formatted 1: `is_illtyped_conversion`.
- GenTypesAux 8: `are_pointers_to_compatible_types, are_pointers_to_qualifiedOrUnqualified_compatible_complete_objects, are_pointers_to_qualifiedOrUnqualified_compatible_types, composite_pointer, interpret_genBasicType, interpret_genIntegerType, interpret_genType, interpret_genTypeCategory`.
- GenTyping 21: `annotate_arguments_aux, annotate_assignee, annotate_block, annotate_definition(+_aux), annotate_definitions, annotate_expression, annotate_program, annotate_rvalue, annotate_sigma, annotate_statement(+_), find_generic_association, gen_typing_type_of_constant, in_range, perform_decays, try_ranges, typecheck_constant, well_typed_assignment, well_typed_conditional, well_typed_equality`.
- Implementation 11: `alignof_ity, integerImpl, is_compatible_with_ptrdiff_t, is_compatible_with_size_t, is_signed_ity, is_signed_or_unsigned(+_aux), normalise_ctype, precision_ity, sizeof_ity, typeof_enum`.
- Mem_common 3: `derive_intrinsic_signature, resolve_arg, try_usual_arithmetic`. Mini_pipeline 2: `in_range_of_signed_int, typecheckAil`.
- Translation 15: `mkTestExpression, translate_assignment_conversion, translate_atomic_explicit, translate_bitwise_operator, translate_block, translate_constant, translate_div_mod_operator, translate_equality_operator, translate_function_call, translate_function_designator, translate_integerConstant, translate_mul_operator, translate_postfix, translate_relational_operator, with_wrapI_or_catch_exceptional_condition`; Translation_aux 3: `combine_params_args, ctype_of, qualified_ctype_of`.
- Already tagDefs-lifted and now also enum-lifted (no new signature change for the consumer): Cabs_to_ail 50, Core_aux 3, Core_eval 8, Core_reduction 5, Core_run 7, Ctype_aux 4, Defacto_memory 50, Defacto_memory_aux 4, Driver 21, Formatted 9, Mini_pipeline 2, Translation 5 (+ their auxiliary shells).
Newly reader-taking ENTRIES: `desugar` (was tagDefs-only), `annotate_program` (NEW: first reader),
`translate`; NOT `initial_driver_state` (W7).

### 3.5 Files touched so far in Phase 1 (grouped; reasons)

- lem: `frontend/model/implementation.lem` (E-A2: reader, consumers incl. W1, shared bodies, wrappers with OCaml reps W10), `mem.lem` (max/min_ival consumers), `ail/ailSyntax.lem` (sigma field + `empty_sigma`), `core.lem` (`enumDefs`), `cabs_to_ail_effect.lem` (three sigma builders — W3), `translation.lem` (carry via the `translate_program` tuple), `core_linking.lem` (merge), `mini_pipeline.lem` (`empty_sigma`, `dummy_core_file`, the N=2 seed with its `val` — W11, the caller's seeds), `core_typing.lem`/`core_rewrite2.lem`/`core_run_aux.lem` (dead `enumDefs` — ruling (1)), `ail/genTyping.lem` (dead `enum_definitions` — W8). `symbol.lem`: UNCHANGED (the digest declare withdrawn, §3.1).
- OCaml: `ocaml_frontend/ocaml_implementation.ml` (`enum_definitions`), `.mli` (export), `backend/common/pipeline.ml` ×3, `ocaml_frontend/rewriters/core_peval.ml`, `ocaml_frontend/rewriters/remove_unspecs.ml` (dead fields — W9).
- Lean seams: `CerberusImpl.lean` (the registry machinery deleted; `EnumDefs`, `enumDefinitionsUnreachable`, `lookupEnum`, `resolveEnum`, `register_enum := true`, `normalise_aliases`, `normalise_integerType_in`, the two-reader consumer stubs `normalise_integerType` and `alignof_ty`, the layout reps on resolved types), `CerbMem.lean` (the `enumDefs` thread: 11 worker signatures, the wrappers, 18 consumer stubs with the reader first, `maxIval`/`minIval` via `resolveEnum`, 8 leaves), `Main.lean` (entry values: desugar `fmapEmpty`, typing/translation the per-TU `Lem_Map.fromList ailProg.enum_definitions`, the run `runFile.enumDefs`, the libc-dump literal `fmapEmpty` — W2), `CerbCall.lean` (the three heads + eight calls).
- Lean proofs (mechanical restatements): `CerbMem_lemMeasureProofs.lean`, `AilTypesAux_lemMeasureProofs.lean`, `Ctype_aux_lemMeasureProofs.lean` (ruling (2)); `Core_aux_`, `Core_eval_`, `Defacto_memory_`, `Driver_lemMeasureProofs.lean` (W12).
- Tests: `test/Unit/FuelExemplar.lean` (`eds` beside `tds`, `fmapEmpty fmapEmpty` at 18 entry applications, the literal), `test/Unit/MonadicFailstop.lean` (2), `test/Unit/EnumDataTest.lean` (NEW, E-A5), `speclab/test/SLUnit/*GateTest.lean` (5), `speclab/SpecLab/{ByteArr,CnSeed,DivMod,ListAppend,TreeRot}Files.lean` (6 literals), `tests/immaculate/illtyped-store.lean`.
- Build/registration: `lean_frontend/lakefile.toml` (`[[lean_exe]] enum-data-test`), `scripts/test_unit.sh` (the list).

### 3.6 STOP (S6 + a pre-existing trust finding F-1): `CerbMem_lemMeasureProofs.lean` has not compiled since seam-hygiene H1, and cannot under the registered hypothesis

**What happened.** After threading `enumDefs` (§3.5), `scripts/ce ../scripts/capped lake build
CerberusImpl CerbMem CerbMem_lemMeasureProofs` (the first EXPLICIT build of the proofs module)
compiles `CerberusImpl` and `CerbMem` and fails the proofs module at two spots, verbatim
(`.tmp/eada/build_lean_seams.log`):
```
error: generated/CerbMem_lemMeasureProofs.lean:921:8: Tactic `rewrite` failed: Did not find an occurrence of the pattern
  panicWithPosWithDecl ?m ?d ?l ?c ?msg
in the target expression
  x ∈ (failwithI "CerbMem.offsetsof: unknown tag (OCaml: Pmap.find Not_found)").fst
…
hx : x ∈ (failwithI "CerbMem.offsetsof: unknown tag (OCaml: Pmap.find Not_found)").fst
⊢ ∃ v, lookup tagDefs t = some v ∧ x.snd.fst ∈ memberTypes v.snd
error: generated/CerbMem_lemMeasureProofs.lean:1016:18: Tactic `rewrite` failed: Did not find an occurrence of the pattern
  panicWithPosWithDecl ?m ?d ?l ?c ?msg
in the target expression
  MemValue.MVunion t (failwithI "CerbMem.reconstructValue: recorded union member not in UnionDef (OCaml: assert false)").fst (reconstructValue_lemFuel f enumDefs ambient … ) = MemValue.MVunion t (…).fst (reconstructValue_lemFuel g enumDefs ambient …)
```
(`offsetsof_types`' unknown-tag arm; `reconstructValue_stable_aux`'s "recorded member not in
UnionDef" arm — both `rw [panic_eq_default]` where `panic_eq_default : (panicWithPosWithDecl m d l c msg : α) = default := rfl`.)

**It is not this slice's doing — the baseline fails identically.** At `52af8ccf1` the leaf and the
proof text are the same: `git show HEAD:lean_frontend/CerbMem.lean` line 430 `| none => failwithI
"CerbMem.offsetsof: unknown tag (OCaml: Pmap.find Not_found)"`; `git show
HEAD:lean_frontend/CerbMem_lemMeasureProofs.lean` lines 915-921 = `theorem offsetsof_types … split at
hx / · rw [panic_eq_default] at hx; cases hx`. LemLib's `failwithI` is `opaque` (lean-lib
`LemLib.lean:152-178`: "opaque: NO equations"), so the rewrite cannot succeed on any tree whose leaf is
`failwithI`. The leaf became `failwithI` in seam-hygiene H1 — `fce1de9f8` (2026-09-19 01:34) "the
register's 98 hand-written `panic!` sites → LemLib's opaque `failwithI`" — and the proofs module was
NOT rebuilt then or since: `lean_frontend/.lake/build/lib/lean/CerbMem_lemMeasureProofs.olean.hash`
and `.trace` carry mtime **2026-09-15 18:25:48** (the trace's `LEAN_PATH` names the PRIMARY checkout —
the artifact came with the worktree priming), against `CerbTagsWf.olean` 2026-09-19 23:41 and
`CerbMem.olean` today; Lake's failed rebuild has now removed the stale `.olean` (only `.hash`/`.trace`
remain). No importer builds it: nothing under `lean_frontend/` imports `CerbMem_lemMeasureProofs`
(`check_fuel_forms.sh:93-95`: "imported by nothing else"); `build_lean` runs `lake build cerberus-lean`
(Main's import closure only); `check_lakefile_roots.sh` compares root NAMES against generated file
names and builds nothing; `check_fuel_forms.sh` builds only `fuel-forms-tool` (`:100`) and then
`importModules` the carrier modules at runtime (`:104`) — a stale `.olean` loads by name. **So since
H1 the fuel-forms gate's MEASURED verdicts for the six `CerbMem` rows of `scripts/fuel_hypotheses.txt`
(`sizeofCtype/alignofCtype/memberAlign/offsetsof/offsetsofMembers/reconstructValue_lemFuel`) rested
on a 2026-09-15 olean compiled against the `panic!`-era CerbMem — a gate vacuity (the same class as
the P0 2026-09-05 audit's F2/F3 findings).**

**Why it cannot be repaired within the granted fence.** The unknown-tag potentials encode "the
failure value has no members": `pot_struct_none : pot … (Ctype an (.Struct t)) = 2` and `oPot_of_none :
oPot … t flag = 1` when `lookup tagDefs t = none` (`CerbMem_lemMeasureProofs.lean:268-270, :436-437`).
`reconstructValue_stable_aux`'s Struct arm (`:975-990`) recurses over the members of
`offsetsof … tagSym` — for an unknown tag now an OPAQUE `failwithI` value — and needs `pot membTy <
pot ty` for each: unavailable for an opaque list. The five layout obligations are unaffected (their
unknown-tag arms are `failwithI … = failwithI …`, closed by `rfl`), as are `memValueToBytes`'s (its
recursion is on the MemValue's own components); **`reconstructValue_measure_sufficient` under the
registered hypothesis `CerbTagsWf.Acyclic ambient` (row 6) is no longer provable** — it needs a
hypothesis that the reconstructed type's struct/union tags (and, transitively, its members') are IN
the table (a `Closed`-style predicate — plausibly a real invariant at the one exec-path call site,
`loadM`'s `reconstructValue … ty` with `ty` a loaded Core type whose tags are in the linked table),
i.e. a change of row 6's hypothesis TEXT — which ruling (2) fixed as "unmoved" — and a frontend-
invariant citation for the register. Alternatively an ABSORBING classification for
`reconstructValue_lemFuel`, or (against H1's doctrine) a transparent leaf at those two arms. Each is
an operator/orchestrator decision, not this worker's.

**Rule conflict (S6):** "restate mechanically, `fuel_hypotheses.txt` unmoved" cannot be satisfied
together with "the module compiles" — and Phase 1's Tier A row 1 needs `check_fuel_forms.sh` green,
which (correctly, now that the stale olean is gone) will FAIL until the module compiles. **STOPPED.**

**Gate hardening to consider (for the orchestrator):** `check_fuel_forms.sh` should `lake build` every
carrier module it imports (`generated/*_auxiliary.lean`, `generated/*_lemMeasureProofs.lean`) before
`importModules`, so a non-compiling proofs module is RED (plant: a proofs module with a failing
theorem); `check_lakefile_roots.sh`'s OK text "all built" should not say built when it checks names.

**State at the stop (for the resume):** all Phase 1 edits of §3.5 are UNCOMMITTED in the working tree
(`git status`: the lem/OCaml/Lean/test/script files listed there + this record + the new
`test/Unit/EnumDataTest.lean`); both generated trees are regenerated at the E-A lem (stamps §3.3, final
values `src 9384b687…`, `gen 5afdf71c…` / `a19f63d5…` — the `intfromptr`/`copy_alloc_id` consumer
declares (W14/W15) regenerated after those lines were captured; the current stamps are the ones
`check_lem_sync.sh --check`/`--check-lean` print); `build_cerberus` green (`rc=0 wall=8s`);
`CerberusImpl`/`CerbMem` compile; `CerbMem_lemMeasureProofs` fails as above; the rest of the Lean tree,
the E-A1(b) dynamic run, the D3 seeds (S-1..S-6), E-A5's exe run, E-A6 and Tier A are NOT yet done.
Consumers added this session beyond the charter's list, within the fence: `intfromptr` (W14) and
`copy_alloc_id` (W15) — both call `max_ival`/`min_ival` (impl_mem.ml:2439-2461, :2766-2770), so
their CerbMem reps take the readers (the census: 22 `reader_consumer` declares — 20 in `mem.lem`, 2 in `implementation.lem` — the earlier "18" counted only the CerbMem stubs and miscounted; corrected §10).

### 3.7 Interim rulings on the two blockers (2026-09-20, [AGENT orchestrator], relayed verbatim in substance)

- **F-1 CONFIRMED on the MAINLINE checkout by the orchestrator** (cerberus-lean @ `e283bed77`,
  `scripts/ce ../scripts/capped lake build CerbMem_lemMeasureProofs`), quoted: "`error:
  generated/CerbMem_lemMeasureProofs.lean:921:8: Tactic `rewrite` failed: Did not find an occurrence of
  the pattern panicWithPosWithDecl ?m ?d ?l ?c ?msg in the target expression x ∈ (failwithI
  "CerbMem.offsetsof: unknown tag (OCaml: Pmap.find Not_found)").fst` and the same at `:1016:18`; the
  primary's `CerbMem_lemMeasureProofs.olean` was dated 2026-09-15 18:25 (pre-H1) and is now gone;
  nothing imports the module; `check_fuel_forms.sh:100` builds only `fuel-forms-tool` and
  `FuelFormsTool.lean:376` `importModules` the compiled environment at runtime." Classification
  upheld: a gate vacuity of the P0-F2/F3 class since seam-hygiene H1 (`fce1de9f8`). **Not E-A's to
  repair**: a separate hotfix-class slice on its own branch, landed BEFORE E-A; the row-6 hypothesis
  question is the operator's (a register move). Instructions followed: row-6 logic and
  `scripts/fuel_hypotheses.txt` untouched; the mechanical enum-threading restatement of the five
  layout obligations + `memValueToBytes` stays in the file; the two failing proofs are left as they
  are (they fail on the baseline too).
- **Granted:** W8 (`genTyping.lem:2378` dead field), W12 (the four additional proof files' mechanical
  restatements), W14/W15 (`intfromptr`, `copy_alloc_id` as consumers — honest threading), W9/W10/W11 as
  recorded. **E-A-alone for Phase 1 CONFIRMED** as the working assumption; the D-A route is the
  operator's decision. §3.1 is a DESIGN-NOTE ERRATUM (to §3.2 "ONE declare lifts every transitive
  user … the OCaml is UNCHANGED"): S0 record §1.6 rule 2 makes `Symbol.fresh*` bind the other
  readers' types (`integerType`, `tag_definition`), which live DOWNSTREAM of `Symbol` — the digest
  reader cannot coexist with the enum/tag readers under rule 2 without a lem-lean rule change or a
  different digest design.
- **Order of the remaining Phase 1 work** (stop before anything that needs the F-1 repair; NO commit
  until the hotfix lands and this branch rebases onto it — the orchestrator's rebase plan): (1) full
  Lean build (`build_lean`) + the unit exes (`test_unit.sh` RED on the fuel-forms gate is EXPECTED,
  not worked around); (2) E-A1(b) the dynamic run with the desugar entry at `fmapEmpty` — Tier A rows
  2–4b + `test_immaculate.sh` — the lookup-miss list; (3) the D3 seeds at the sites the list names;
  regenerate, rebuild; (4) `enum-data-test`; (5) E-A6 registers/gates EXCEPT `fuel_hypotheses.txt` /
  the fuel-forms gate; (6) Tier A rows 2–12 (row 1's red line quoted with every other sub-gate's
  green line). Zero lane movement stays stop rule S2.

## 4. Phase 1 (continued) — E-A1(b) the dynamic run, and the D3 seeds

### 4.1 The corpora at the unseeded desugar entry (`desugar fmapEmpty fmapEmpty …`, NO D3 seeds)

Build: `lake build cerberus-lean` → `Build completed successfully (285 jobs).` (after the self-test's two
bare `CerbMem.maxIval/minIval (Signed Int_)` calls gained `fmapEmpty fmapEmpty`); `build_lean` →
`check_driver_fresh: recorded lean stamp (bin 7af627579c…, src 90bb42b971…)`; speclab `Build completed
successfully (148 jobs).` (93 s). `release.py --lane A2 --lane A3 --lane A4 --lane A4b` (126 s;
`.tmp/eada/dyn-run/`), verbatim:
- A2 `SUMMARY: total=113 match=90 ub_match=18 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=5 cerb_floor=0 cerb_inconsistent=0` / `Baseline check: 0 regression(s), 0 improvement(s)` / `BASELINE OK` (27.8 s)
- A3 `SUMMARY: total=212 match=183 ub_match=16 ub_diff=0 mismatch=0 fail=0 crash=0 … cerb_skip=13 …` / `BASELINE OK` (51.0 s)
- A4 `SUMMARY: total=90 match=66 ub_match=20 ub_diff=0 mismatch=0 fail=0 crash=0 … cerb_skip=4 …` / `BASELINE OK` (22.5 s)
- A4b `SUMMARY: total=93 match=93 ub_match=0 ub_diff=0 mismatch=0 fail=0 crash=0 …` / `BASELINE OK` (24.0 s)
- `test_immaculate.sh` (67 s): `OK: lane matches the committed baseline (MATCH except the ISO-fix register pins R1 …, R2 …, R3 …, R5 …)`; in-lean probes `TRIPWIRE g6-hash-collision`, `KILL illtyped-store`.

**The corpora's lookup-miss list is EMPTY**: no standing corpus (tests/minimal, coverage, debug, float,
immaculate incl. its `s9-enum-*` cases) exercises a desugar-time enum normalisation. That is not the
same as "D3 reduces to Q-A": the static inventory (§1.1, §3.4) names eight reaching site classes, so the
instrument was made to bite with EPHEMERAL witness programs (`.tmp/eada/probes/`, deleted at slice end —
no new committed test surface, [USER 2026-09-08]), each the smallest oracle-accepted C reaching one
class, run through `scripts/test_exec.sh <dir>` (the lane's exact flags) and directly
(`cerberus --cabs-json` → `LEAN_ABORT_ON_PANIC=1 cerberus-lean --batch`).

### 4.2 The witnesses BEFORE the seeds (verbatim; `.tmp/eada/probes-before.stdout`)

```
[1/8] LEAN_CRASH d3-s3-alignas-enum (exit 134): PANIC at _private.LemLib.0.failwithIImpl LemLib:168:2: Ocaml_implementation.typeof_enum: 'Symbol(19, SD_Id("E"))' was no
[2/8] LEAN_CRASH d3-s4a-tentative-enum (exit 134): PANIC at … typeof_enum: 'Symbol(19, SD_Id("E"))' was no
[3/8] LEAN_CRASH d3-s4b-fdecl-enum-param (exit 134): PANIC at … typeof_enum: 'Symbol(19, SD_Id("E"))' was no
[4/8] LEAN_CRASH d3-s4c-extern-redecl-enum (exit 134): PANIC at … typeof_enum: 'Symbol(19, SD_Id("E"))' was no
[5/8] LEAN_CRASH d3-s5a-generic-enum (exit 134): PANIC at … typeof_enum: 'Symbol(19, SD_Id("E"))' was no
[6/8] LEAN_CRASH d3-s5b-builtin-compat-enum (exit 134): PANIC at … typeof_enum: 'Symbol(19, SD_Id("E"))' was no
[7/8] CERB_SKIP d3-s7-typeof-enum-expr (exit 1)
[8/8] LEAN_CRASH d3-s8-sizeof-enum-expr (exit 134): PANIC at … typeof_enum: 'Symbol(19, SD_Id("E"))' was no
SUMMARY: total=8 match=0 ub_match=0 ub_diff=0 mismatch=0 fail=0 crash=7 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=1 cerb_floor=0 cerb_inconsistent=0
```
Each crashing probe's Lean stderr, first line (identical for all seven): `PANIC at
_private.LemLib.0.failwithIImpl LemLib:168:2: Ocaml_implementation.typeof_enum: 'Symbol(19, SD_Id("E"))'
was not registered` — the `lookupEnum` leaf on the entry's empty map; the oracle runs every one of them
(their `--exec` results are the MATCH values of §4.4). The programs:

| class | probe | C | desugar-time path (lem) |
|---|---|---|---|
| S-3 | `d3-s3-alignas-enum` | `struct S { _Alignas(enum E) int i; char c; };` | `get_alignof` → `Implementation.alignof_ty` (the non-character-member path; the earlier `_Alignas(enum E) char c` spelling MATCHED — the agnostic path of `fuel_hypotheses.txt` F-A2) |
| S-4a | `d3-s4a-tentative-enum` | `enum E g; enum E g;` | `register_global_object_definition2` → `AilTypesAux.make_composite` |
| S-4b | `d3-s4b-fdecl-enum-param` | `int f(enum E x); int f(enum E x);` | `register_function_declaration` → `make_composite_fdecl` → `make_composite_params` → `are_compatible` |
| S-4c | `d3-s4c-extern-redecl-enum` | `extern enum E g; extern enum E g;` | `register_external_object_declaration` → `are_compatible`, `make_composite` |
| S-5a | `d3-s5a-generic-enum` | `_Generic(e, enum E: 7, long: 9, default: 3)` | `find_compatible_generic_association` (the overlap check between two TYPE associations; a single association MATCHED — nothing to compare) |
| S-5b | `d3-s5b-builtin-compat-enum` | `__builtin_types_compatible_p(enum E, unsigned int)` | `desugar_expression`'s builtin arm → `are_compatible` |
| S-8 | `d3-s8-sizeof-enum-expr` | `sizeof((enum E)1 + 1)` | `desugar_expression`'s sizeof arm → `GenTyping.annotate_expression` (usual arithmetic conversions → `integer_promotion` → `normalise_integerType`) |
| S-7 | six witnesses (§10 E1: `d3-s7-callback-*`) — CORRECTED | `typeof(({ enum E e = A; unsigned int *p = &e; p; })) x` | my `__typeof__` spellings were parse errors, so I wrongly recorded "no oracle-accepted witness"; the parser recognises `typeof` (the pre-merge audit's reproducers), and even `typeof(e + 1) y` runs on both engines. The site reads the map through the BLOCK-typing callback — which E1 found was built outside the seed (§10) |
| S-1 | (no witness) | a constant expression with an enum-TYPED operand outside `sizeof` | the oracle rejects casts there (`error: feature not yet supported: cast operator in `integer constant expressions'`), enumeration constants are `int`-typed (§6.7.2.2#3), and `sizeof(enum-expr)` is folded by S-8 before S-1's typing sees it — no oracle-accepted witness; seeded anyway (D3): the mini-pipeline's typing/translation of a constant expression take the sigma-so-far's map |
| S-6 | — | — | `in_range_of_signed_int`: `Mem.min/max_ival (Signed Int_)`, enum-free by construction; left on the binder (a future enum there would be LOUD) |

### 4.3 The D3 seeds (lem; `.tmp/eada/d3_seeds.py` applied once)

- `mini_pipeline.lem`: `evalIntegerConstantExpression_seeded en tds …` (S-1), `typecheckAil_seeded en tds …` (S-2), `annotate_expression_seeded en tds annotate_block sigm gamm ctx expr` (S-7/S-8) — each `declare {lean} reader_seed`, each with a `val` (W11), each wrapping the unseeded function; the seeds' types differ (`map sym integerType` vs `map sym (Loc.t * tag_definition)`), so an N1 positional slip is a type error.
- `cabs_to_ail_effect.lem`: `enum_definitions_of_tag_definitions` (the list the three sigma builders now share) and `enum_map_of_tag_definitions` (its `Map.fromList`); seed defs `are_compatible_seeded`, `make_composite_seeded`, `make_composite_fdecl_seeded`, `alignof_ty_seeded`; the sites: `register_global_object_definition2` (`st.tag_definitions` in hand), `register_function_declaration` and `register_external_object_declaration` (a `get_tag_definitions` bind prepended — a dead state read on OCaml), `get_alignof` (its own `tagDefs`).
- `cabs_to_ail.lem`: S-1/S-2/S-7/S-8 pass `(Map.fromList sigm.enum_definitions) (Ctype_aux.tagDefs ())` (the sigma-so-far is in hand at each site); S-5a `find_compatible_generic_association_seeded` + an `E.get_tag_definitions` bind at the `_Generic` overlap check; S-5b `E.are_compatible_seeded` + the same bind.
- The `tds` seed: **W16 (charter erratum, found fail-closed)** — the charter's `Ctype_aux.tagDefs ()` is
  NOT dead on OCaml: a seed argument is evaluated strictly, and the oracle's Tags global is UNSET until
  elaboration, so the first `build_cerberus` with the seeds died in the `cerberus.install` step (which
  RUNS the driver over the libc sources to build `libc.co`), verbatim: `cerberus: internal error, uncaught
  exception: Failure("Tags definitions must be set by Tags.set_tagDefs before any use")` (backtrace through
  `Cerb_backend__Pipeline.c_frontend` `pipeline.ml:260`). The value the enclosing `_lemReader_tagDefs`
  binder holds at every seeded site IS the empty table (Main.lean passes `fmapEmpty` to `desugar`,
  "mirroring the oracle's empty Tags global there"), so the seed is the named constant
  `Cabs_to_ail_effect.desugar_time_tagDefs = Map.empty` (cited to `ocaml_frontend/tags.ml`), used at
  all twelve seed calls; the two `import Ctype_aux` additions were withdrawn.

### 4.4 The registers and gates (E-A6, the Phase 1 part; `fuel_hypotheses.txt` and the fuel-forms gate excluded per §3.7)

| register | before | after | edit |
|---|---|---|---|
| `scripts/unsafebaseio_allowlist.txt` KEEP rows | 3 (`boundedIntegerImpl`, `typeof_enum_impl`, `register_enum_impl`) | 1 (`boundedIntegerImpl`) | the two CerberusImpl KEEP rows → a dated "retired 2026-09-20" note in the file's style; the Q4-classes comment's CerberusImpl bullet → "NO rows since 2026-09-20" |
| `unsafebaseio_allowlist.txt` PIN rows | 25 | 19 | the six `CerberusImpl.lean register_enum_impl/typeof_enum_impl` rows (IMPLBY ×2, UNSAFEBASEIO ×2, UNSAFEDECL ×2) deleted |
| `check_theorem_axioms.sh` `OPAQUE_WANT` | 12 | 10 | `'CerberusImpl.lean:typeof_enum' 'CerberusImpl.lean:register_enum'` deleted; the trail comment gains "… 12 -> 10 — the reviewed population is 10"; the CerberusImpl block comment says why (verdict at this population: `check_theorem_axioms: OK (…)` in row 1, §5) |
| `scripts/check_exec_purity.sh` header | "CerberusImpl enum registry: temporal with a named mover, Q4" | a `CerberusImpl.lean — ZERO seams since program-data parameters E-A` bullet (verdict `check_exec_purity: CLEAN (11 modules)`, §5) |
| `scripts/observations.py` `IMMACULATE_PANICS` | `{b'_private.CerberusImpl.0.CerberusImpl.typeof_enum_impl'}` | `set()` — the branch intact (fail-closed: anything but the LemLib origin is `ProtocolError('unreviewed panic origin')`) |
| `scripts/test_observations.py` | the kept origin ACCEPTED under immaculate | the kept origin REJECTED under BOTH policies; the enum lookup miss (a `failwithI`, LemLib origin) accepted like every seam failure; `test_immaculate_validates_before_coarse_crash_projection` re-based on the LemLib origin; `LEMLIB_FAILWITHI_ORIGIN` imported. `python3 scripts/test_observations.py` → `Ran 25 tests … OK` |
| `scripts/failure_reach_register.txt` | 233 rows (0 `panic!`) | §5 (resealed via `--emit`, reviewed) |
| `scripts/fork_drift_manifest.txt` | `[files]` 76, layer-2 25 (13 semantic + 12 cosmetic) | §5 (single rows + one NOTE) |

### 4.5 The witnesses AFTER the seeds — and the ninth site the witnesses found (W17)

After the seeds of §4.3 (S-1..S-8), the lane on the probe directory (`.tmp/eada/probes-after.stdout`, first pass):
```
[1/7] MATCH d3-s3-alignas-enum: VAL:{value: "Specified(7)", stdout: "", stderr: "", blocked: "false"}
[2/7] MATCH d3-s4a-tentative-enum: VAL:{value: "Specified(1)", …}
[3/7] MATCH d3-s4b-fdecl-enum-param: VAL:{value: "Specified(2)", …}
[4/7] MATCH d3-s4c-extern-redecl-enum: VAL:{value: "Specified(1)", …}
[5/7] MATCH d3-s5a-generic-enum: VAL:{value: "Specified(7)", …}
[6/7] MATCH d3-s5b-builtin-compat-enum: VAL:{value: "Specified(1)", …}
[7/7] LEAN_CRASH d3-s8-sizeof-enum-expr (exit 134): PANIC at _private.LemLib.0.failwithIImpl LemLib:168:2: Ocaml_implementation.typeof_enum: 'Symbol(19, SD_Id("E"))' was no
SUMMARY: total=7 match=6 ub_match=0 ub_diff=0 mismatch=0 fail=0 crash=1 …
```
**W17 (E-A1 table erratum, found by the witness).** S-8 still missed although both typing calls were
seeded and no unseeded `annotate_expression` call remained in the generated tree (`grep -c
'annotate_expression _lemReader_enum_definitions' Cabs_to_ail.lean` → 0). Bisect (verbose driver: the
PANIC follows `desugaring Cabs → AIL...`; `return (enum E)1 + 1;` → `Specified(2)`; `sizeof((enum E)1)` →
`Specified(4)`; `enum E e = B; sizeof(e + 1)` → the miss): the NINTH desugar-time path is
**`Translation_aux.qualified_ctype_of a_expr`** right after each seeded typing call (`cabs_to_ail.lem:1766`
typeof, `:2419` sizeof) — the genType → ctype interpretation (`GenTypesAux.interpret_gen*`, newly lifted
in §3.4) normalises the arithmetic result's integer type. My static grep (§1.1/§3.4's "desugar-time
reads") had matched `AilTypesAux./Implementation./Mem./Mini_pipeline./GenTyping.` but not
`Translation_aux.` — the census listed `Translation_aux.{ctype_of, qualified_ctype_of,
combine_params_args}` as lifted, and the cross-check against the desugarer's call sites was mine to make.
Seed S-9: `Mini_pipeline.qualified_ctype_of_seeded en tds a_expr` (a `val`, `reader_seed`) at both sites,
with the same `(Map.fromList sigm.enum_definitions) E.desugar_time_tagDefs` seeds. Second pass, after S-9
(regeneration `wall=39s`; `build_cerberus+build_lean rc=0 wall=33s`; unit exes and speclab green):
```
[4/10] MATCH d3-s3-alignas-enum … [10/10] MATCH d3-s8-sizeof-enum-expr: VAL:{value: "Specified(4)", stdout: "", stderr: "", blocked: "false"}
SUMMARY: total=10 match=10 ub_match=0 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=0 cerb_floor=0 cerb_inconsistent=0
[1/3] MATCH v1-runtime-arith: VAL:{value: "Specified(2)", …}  [2/3] MATCH v2-sizeof-cast: … "Specified(4)" …  [3/3] MATCH v3-sizeof-var-arith: … "Specified(4)" …
```
Every witnessed class MATCHES the oracle (7/7 + the 3 bisect variants). Rows 2/3/4/4b and the immaculate
lane after S-9: `BASELINE OK` ×4 (`crash=0` everywhere, the same SUMMARY lines as §4.1), `test_immaculate
rc=0` `OK: lane matches the committed baseline …` — zero movement (S2 clear). The complete D3 seed set
is therefore S-1..S-5, S-7, S-8, S-9 (eight seeded site classes, twelve seeded call sites; S-6 on the
binder by construction).

**Charter erratum on the seed VALUES (W16, §4.3)** stands; **the E-A1(a) table's method** (a grep over a
fixed list of module prefixes) is the lesson: the authoritative list is the census of lifted defs
CROSSED with the desugarer's call sites — which is what the witnesses enforced.

### 4.6 Register/manifest "after" (completes §4.4)

- `scripts/failure_reach_register.txt`: `check_failure_reach.sh --emit` → 5 UNREVIEWED rows (`CerberusImpl.lookupEnum` TAIL, `CerberusImpl.is_signed_ity` TAIL, `CerberusImpl.normalise_aliases` TAIL, `CerbMem.maxIval` ARGUMENT, `CerbMem.minIval` ARGUMENT) and 2 STALE (rows 103/105, the "Enum after typeof_enum" texts — replaced by "Enum after resolveEnum"); reviewed (`.tmp/eada/register_review.py`: `lookupEnum` REACHABLE — a Core-text input naming an enum tag, a both-crash pair with `ocaml_implementation.ml:146-149`, unwitnessed by construction; the four un-normalised-Enum leaves UNREACHABLE-BY-INVARIANT — the map's values are `enum_compatible_type ns` ∈ {Signed Int_, Unsigned Int_} and every type-only rep is called on a resolved type; the two `sizeof_ity` rows' cites refreshed to `normalise_aliases`), then `check_failure_reach.py --reseal` → `check_failure_reach: resealed 236 rows`. Tally `sites=236 exec=234 unresolved-owner=2 reviewed-TAIL=182 reviewed-NON-TAIL=54 UNREACHABLE-BY-INVARIANT=168 REACHABLE=49 UNKNOWN=19 discardable=0` (was 233/231/2/179/54/166/48/19/0). Gate: `check_failure_reach: OK (236 pure failure sites = the 236 register rows exactly (234 in the exec dependency closure + 2 unresolved-owner; key = file/owner/token/message, both directions); position classes unchanged; 0 DISCARDABLE; reach UNREACHABLE-BY-INVARIANT=168 REACHABLE=49 UNKNOWN=19; every row sealed; tally line consistent)`.
- `scripts/fork_drift_manifest.txt` (targeted rows via `.tmp/eada/manifest_edit.py` — recomputed with the gate's own `identity()`/`diff_hash` recipes; one dated NOTE; never `--refresh`): `[files]` 76 → 82 (+`frontend/model/core_rewrite2.lem`, `frontend/model/core_typing.lem`, `ocaml_frontend/ocaml_implementation.ml`, `.mli`, `ocaml_frontend/rewriters/core_peval.ml`, `ocaml_frontend/rewriters/remove_unspecs.ml`); `[source-content]` 12 pins moved + 6 new; layer 2: 25 → 29 differing generated files — `[expected-semantic]` moved `cabs_to_ail_effect.ml`, `cabs_to_ail.ml`, `core_run_aux.ml`, `mini_pipeline.ml`, `translation.ml`; `ailSyntax.ml`, `core.ml` MOVED cosmetic → semantic (a record field); NEW `core_linking.ml`, `core_typing.ml`, `genTyping.ml`, `implementation.ml` (byte-identical to upstream before this slice) → 19 semantic + 10 cosmetic; `lem-pin=38f87d5` unchanged. Gate: `check_fork_content: OK — 82 source files content/mode-pinned` / `check_fork_drift: OK — layer 1: 82 oracle-surface files = manifest (set, C-locale canonical, no duplicates); layer 2: 29 differing generated files, all hash-pinned (merge-base b9aeedcb4dd438763b0eef7f95ac19e93875d7de; lem-pin 38f87d5 = lem -v)`.

## 5. Phase 1 gates (E-A alone; UNCOMMITTED — the commit waits for the F-1 hotfix and the rebase, §3.7)

Binaries: `build_cerberus` → `check_driver_fresh: recorded oracle stamp (bin 8e76d3b33f03a392339f1ded6ddef4265c887e115c914e95dc381d5b6e005be2, src 592ad09d487abc94f5ccc26748a4490bbe7a64d2193a0b6a75fe5893dacd3804)`; `build_lean` → `Build completed successfully (285 jobs).` / `check_driver_fresh: recorded lean stamp (bin 55b07adf2797b91c4218d7bf2292931b74c340ffc1efbd8fde31f976ad0c639e, src fb78a07d3f3714a74625240e5b60f11d9b213cf6206b932ae2a1ec043919dc8a)`; the final regeneration's stamps `check_lem_sync: recorded ocaml_frontend/lem_sync.sha256 (src bc2f8bbbcb90a6ca30b3cbdbf4df3944edd9d0554ab7c038f7be9c559aa5e12d, gen b2f073232e32ac707650a45766014dede7b8de6b9181e6243ce6bfefac73456c)` / `… lean_frontend/lem_sync.sha256 (src bc2f8bbb…, gen eb2b61a1268f8425ec9b73c1d3fa2d1175c51a596db3ea602de02a315bd232e3)`. Wall times: regeneration 34–39 s each; `build_cerberus+build_lean` 29–46 s incremental after each regeneration (Lake replayed; the first full Lean rebuild after the seam rewrite was 46 s); speclab 93 s once, then replay.

**Row 1** (`scripts/ce ./scripts/test_unit.sh`, `test_unit rc=1 wall=179s`, `.tmp/eada/test_unit3.stdout`) — RED on exactly the fuel-forms gate (F-1, §3.6/§3.7), every other sub-gate green, verbatim:
`✓ effects-proof-test PASSED` · `✓ totality-proof-test PASSED` · `✓ core-parser-test PASSED` · `✓ fresh-int-test PASSED` · `✓ pp-test PASSED` · `✓ fuel-exemplar-test PASSED` · `✓ monadic-failstop-test PASSED` · `✓ allocator-soundness-test PASSED` · `✓ float-literal-test PASSED` · `✓ are-compatible-test PASSED` · `✓ many-restatement-test PASSED` · `✓ opaque-failure-test PASSED` · `✓ enum-data-test PASSED` · **`Total: 13 passed, 0 failed`** · `check_exec_purity: CLEAN (11 modules)` · `check_theorem_axioms: OK (effect-retirement C2 bar: zero axiom declarations anywhere; entry cones ⊆ the standard three)` (at `OPAQUE_WANT` population 10 and the 19-row PIN set) · `check_sorry_token: OK (319 files scanned comment-stripped — generated 219, hand-written+test 65, LemLib 35; 0 sorry tokens)` · `test_exec: SELFTEST OK (E0 pre-repair collapse reproduced; E1-E7: …)` · `check_no_fuel_numerals: OK (326 files scanned comment-stripped; …)` + `SELFTEST OK (26 plants …)` · `gen_fuel_parametricity: OK (14 ambient fuel wrappers in the generated tree = the 14 pins of TotalityProofTest.lean Part 1, both directions)` · `check_lakefile_roots: OK (218 roots = 218 generated modules + the exe root Main; 85 auxiliary modules all built)` + `SELFTEST OK` · **`check_fuel_forms: FAIL — the classifier tool failed (fail-closed); diagnostics tail:` … `fuel-forms-tool: importing 104 modules` / `uncaught exception: unknown module prefix 'CerbMem_lemMeasureProofs'` / `No directory 'CerbMem_lemMeasureProofs' or file 'CerbMem_lemMeasureProofs.olean' in the search path entries: …` / `test_unit: fuel-forms gate SELFTEST FAILED`** (the runner stops there). The sub-gates row 1 runs AFTER that stop, run standalone: `check_failure_reach: OK (236 pure failure sites = the 236 register rows exactly …)` (§4.6) · `check_exec_totality: CLEAN (22 generated modules + hand-written CerbND, 0 allowlisted)` · `check_lem_sync: OK (src bc2f8bbb…, gen b2f07323…)` · `check_lem_sync: lean OK (src bc2f8bbb…, gen eb2b61a1…)` · `check_fork_drift: OK — layer 1: 82 oracle-surface files = manifest …; layer 2: 29 differing generated files, all hash-pinned (…; lem-pin 38f87d5 = lem -v)` (§4.6) · `check_fixture_freeze: OK (16 fixture files match the pinned manifest; name set exact)` · `test_renumber_plants: OK (12 plants: refusals refuse, admits admit with declared class)`; `python3 scripts/test_observations.py` → `Ran 25 tests … OK`. `enum-data-test` (E-A5) standalone: `EnumDataTest: the enum's compatible type is program data — normalise/sizeof/alignof/is_signed/precision at a registered enum by rfl/decide given the map; GCC's rule in lem; register_enum = true; the retired registry names no longer elaborate — kernel-checked at compile time` rc 0; its pin's cone `'EnumDataTest.sizeof_enum_pin' depends on axioms: [propext, Classical.choice, Quot.sound]`.

**Rows 2, 3, 4, 4b** (final tree, `release.py --lane`, `.tmp/eada/dyn-run3/`): `PASSED A2 (27.9s)`, `A3 (50.9s)`, `A4 (22.5s)`, `A4b (24.0s)`; SUMMARY lines identical to §4.1's (`crash=0`, `mismatch=0` throughout); each `Baseline check: 0 regression(s), 0 improvement(s)` / `BASELINE OK`.

**Rows 5–12** (`.tmp/eada/tierA-rest/`, `release rows 5-12 rc=0 wall=148s`): `PASSED A5 (21.8s)` `SUMMARY: match=12 diff=0` / `ALL MATCH RECORDED BASELINE` · `PASSED A6 (2.1s)` `SUMMARY: total=2 match=2 fail=0` / `ALL PASSED` · `PASSED A6b (3.5s)` `SUMMARY: total=7 match=7 fail=0` / `ALL PASSED` · `PASSED A7 (10.4s)` `batch diagnostic producers: 8/8 passed` / `cabs bytes probe: 128 raw bytes 0x80..0xFF crossed the bridge as one code point each (valid UTF-8 JSON; Lean sizeof = 129)` / `ALL PASSED` · `PASSED A8 (8.9s)` `Lean parse:     113 ok, 0 failed` / `Success rate:   100% (of cerberus successes)` / `ALL PASSED` · `PASSED A9 (16.7s)` `SUMMARY: total=113 same=108 diff=5 ocaml_fail=0 lean_fail=0` (the recorded state) · `PASSED A10 (16.6s)` `[lean+libc] EXACT MATCH with ORACLE_LIBC (16/16 URI corpus)` / `GATE PASS: all lane expectations pinned-green + baseline unchanged (16/16)` · `PASSED A11 (57.4s)` `SUMMARY: total=213 match=207 ub_match=6 ub_diff=0 reject_match=0 diff=0 mismatch=0 reject_diff=0 lean_fail=0 lean_crash=0 fuel=0 lean_error=0 lean_timeout=0 oracle_fail=0 oracle_timeout=0 oracle_inconsistent=0` / `BASELINE OK (213 entries, exact match)` · `PASSED A12.1 (4.8s)` `EXPECT OK    18 pinned rows = 18 observed cases, every token identical` / `test_address_space: SELFTEST OK (14 plants — …)` · `PASSED A12.2 (4.4s)` `test_address_space: OK (18 cases: LEAN = FORK through the shared codec at tops 64 32 8; every fork observation = its pinned row in expectations.txt)`. **Tier B row 5** `test_immaculate.sh` (run as the dynamic instrument): `OK: lane matches the committed baseline …`.

ZERO movement on every lane, before and after the D3 seeds (S2 never triggered).

## 6. Phase 1 file list (the working tree at the stop; `git status --short`: 53 modified + 2 untracked)

- lem (13): `frontend/model/implementation.lem`, `mem.lem`, `ail/ailSyntax.lem`, `ail/genTyping.lem` (W8), `core.lem`, `cabs_to_ail_effect.lem` (sigma builders, `enum_definitions_of_tag_definitions`/`enum_map_of_tag_definitions`, `desugar_time_tagDefs`, four seed defs, five seeded sites), `cabs_to_ail.lem` (S-1/S-2/S-5a/S-5b/S-7/S-8/S-9 seeded sites, `find_compatible_generic_association_seeded`), `translation.lem`, `core_linking.lem`, `mini_pipeline.lem` (`empty_sigma`, `dummy_core_file`, the N=2 seed + `val`, four seed defs), `core_typing.lem`/`core_rewrite2.lem`/`core_run_aux.lem` (dead `enumDefs`).
- OCaml (5): `ocaml_frontend/ocaml_implementation.ml` + `.mli` (`enum_definitions`), `backend/common/pipeline.ml` (3 dead fields), `ocaml_frontend/rewriters/core_peval.ml`, `ocaml_frontend/rewriters/remove_unspecs.ml`.
- Lean seams (4): `lean_frontend/CerberusImpl.lean`, `CerbMem.lean` (incl. W14/W15 `intfromptr`/`copyAllocId`), `Main.lean` (entry values + the self-test's two calls), `CerbCall.lean`.
- Lean proofs, mechanical restatements (7): `CerbMem_lemMeasureProofs.lean` (its two pre-existing F-1 failures untouched), `AilTypesAux_lemMeasureProofs.lean`, `Ctype_aux_lemMeasureProofs.lean`, `Core_aux_`, `Core_eval_`, `Defacto_memory_`, `Driver_lemMeasureProofs.lean`.
- Tests (12 + 1 new): `test/Unit/EnumDataTest.lean` (NEW), `FuelExemplar.lean`, `MonadicFailstop.lean`, `EffectsProofTest.lean` (`get_membersDefs fmapEmpty …`), `AreCompatibleTest.lean` (`are_compatible0 fmapEmpty tags …`), `speclab/test/SLUnit/{ByteArr,Core,List,Seed,Tree}GateTest.lean`, `speclab/SpecLab/{ByteArr,CnSeed,DivMod,ListAppend,TreeRot}Files.lean`, `tests/immaculate/illtyped-store.lean`.
- Registration (2): `lean_frontend/lakefile.toml` (`[[lean_exe]] enum-data-test`), `scripts/test_unit.sh`.
- Registers/gates (6): `scripts/unsafebaseio_allowlist.txt`, `scripts/check_theorem_axioms.sh`, `scripts/check_exec_purity.sh`, `scripts/observations.py`, `scripts/test_observations.py`, `scripts/failure_reach_register.txt`, `scripts/fork_drift_manifest.txt`.
- Docs (1): this record. NOT touched: `scripts/fuel_hypotheses.txt`, any baseline/expectation/fixture, `CoreParser.lean`, `CerberusFresh.lean`, `native/`, `symbol.lem`, lem-lean, pins.
Ephemeral (deleted at slice end): `.tmp/eada/` (the Stage A patch, the two generated-tree snapshots, the reach/manifest/register scripts, the witness programs, every lane log quoted above).

## 7. Commit and the mandatory re-gate

[AGENT orchestrator] rulings at the Phase 1 stop: (1) commit the Phase 1 tree as ONE commit on
`52af8ccf1` despite row 1's single red line — F-1 is a pre-existing MAINLINE gate vacuity this slice
neither causes nor touches (`scripts/fuel_hypotheses.txt` unmoved), and every other Tier A row and
sub-gate is green with zero movement; the F-1 hotfix (`fix/fuel-forms-carriers`) restates the two
`reconstructValue_lemFuel` arms in `CerbMem.lean` (struct arm guards `lookupEntry` before the fold; the
union arm's `find?` moves outward so the whole `MVunion` is the leaf) and the `Reconstruct` section of
`CerbMem_lemMeasureProofs.lean`, and hardens the gate; (2) the seven oracle-accepted witnesses become
PERMANENT immaculate cases in a second commit (their own section below); (3) STOP for the boundary —
Phase 2 does not start (the D-A route, §3.1, is the operator's open decision).

**MANDATORY before any merge ask:** after this branch is rebased onto the landed hotfix, the FULL Tier A
battery re-runs and row 1 must be GREEN — `check_fuel_forms` included, with the hardened gate that
builds its carrier modules — and every row must again show zero movement. Until then the Phase 1 commit
is a kill-loss-containment checkpoint, not a certified state.

## 8. The seven permanent witnesses (second Phase 1 commit; [AGENT orchestrator] ruling (2))

`tests/immaculate/nolibc/d3-{s3-alignas-enum, s4a-tentative-enum, s4b-fdecl-enum-param, s4c-extern-redecl-enum,
s5a-generic-enum, s5b-types-compatible-enum, s8-sizeof-enum-expr}.c` — the §4.2 witnesses made permanent (each
header names the desugar-time read it exercises and quotes the pre-seed crash verbatim). S-1 and S-7 have no
oracle-accepted witness (§4.2) and stay documented here; their seeds are load-bearing by the static reach.

Baseline re-record (`scripts/test_immaculate.sh --record-baseline`, 71 s → `BASELINE RECORDED`), the file diff
against the pre-record copy, verbatim: `90a91,98` = the 8-line header note naming this slice; `93a102,108` = the
seven new `MATCH` rows (`d3-s3-alignas-enum MATCH | L=VAL:{value: "Specified(7)", …}`, `d3-s4a … Specified(1)`,
`d3-s4b … Specified(2)`, `d3-s4c … Specified(1)`, `d3-s5a … Specified(7)`, `d3-s5b … Specified(1)`, `d3-s8 …
Specified(4)`); `pre-existing rows removed/changed: 0; header lines removed: 0; new rows: 7`. Then
`test_immaculate.sh` → rc 0, `OK: lane matches the committed baseline (…)` with all seven `MATCH`; the pristine
lane `python3 scripts/test_upstream_oracle.py --only "immaculate/nolibc/d3-"` → `7/7 semantic_agreement` …
`Independent oracle: subset_passed; {'semantic_agreement': 7}` (a subset run, never a full-lane certification).

**F-2 (process finding, repaired here):** the FIRST `--record-baseline` of this slice silently DROPPED 14 header
lines of the committed baseline (the ISO-fix R5 pin note and the Finding-3 pins note, `baseline.txt:77-90`):
they had been hand-edited into the file after their re-records and never added to the recipe's header block in
`test_immaculate.sh`, so the recipe — the documented authority — did not reproduce the committed header. Repaired
by putting the 14 lines into the script's header block byte for byte (a comment in the script says why), then
re-recording; the diff above is against the pre-record copy, so it shows the repair worked (0 header lines
removed). Lesson for the lane's doctrine: a baseline header edit must go through the recipe, or the next honest
re-record erases it.

## 9. Rebase onto the landed mainline (`5407597d9` = F-1 hotfix + S1.5 landing), and the mandatory full re-gate

### 9.1 The rebase (`git rebase 5407597d9` from `b61db241d`; both commits replayed with their messages)

Mainline range `52af8ccf1..5407597d9`: `8c712657f` (S1.5 record erratum), `b89a010ab`/`5d462da86`/`e5065fc5a`
(hotfix `fix/fuel-forms-carriers`: the fuel-forms gate builds every carrier module; `reconstructValue_lemFuel`'s
struct/union arms take the whole-result leaf shape — option (d); `build_lean` builds EVERY Lake root),
`027b6fc66`/`1ee426e2b` (the combined pre-merge audit), `5407597d9` (landing note). Replayed heads:
**`3ad477462`** (E-A Phase 1) and **`70408e483`** (the seven witnesses). Conflicts at the first replay, one line each:
- `lean_frontend/CerbMem.lean` (4 hunks = the struct/union arms of `reconstructValue_lemFuel` and its `_indexed` twin):
  KEPT the hotfix's shape (the struct arm guards `CerbTagsWf.lookupEntry ambient tagSym` before the fold; the union arm
  selects the member before recursing; every leaf is the WHOLE result) and re-applied the `enumDefs` thread inside it
  (`offsetsof enumDefs ambient ambient`, `sizeofCtype enumDefs ambient`, `reconstructValue_lemFuel lemFuel enumDefs
  ambient …`) — both intents; 0 bare-`ambient` applications remain.
- `lean_frontend/CerbMem_lemMeasureProofs.lean` (4 hunks in the `Reconstruct` section): KEPT the hotfix's proof shape
  (`offsetsof_types … (v : Entry) (hl : lookup tagDefs t = some v)`, the `split`/`rfl` leaves, `panic_eq_default` and
  `pot_default` gone) and added my reader binder (`(enumDefs : CerberusImpl.EnumDefs)` on `offsetsof_types` and
  `reconstructValue_stable_aux`; `enumDefs` before `ambient` in every worker/wrapper application) — every obligation's
  statement is the hotfix's shape plus the reader binder; `fuel_hypotheses.txt` untouched.
- `scripts/failure_reach_register.txt` (1 hunk, the tally line): took the mainline line as a placeholder; the register
  is RE-DERIVED below via `check_failure_reach.sh --emit` → review → `--reseal` (never a hand-merge of sealed rows).
- No conflict in `scripts/test_unit.sh` (the hotfix's "25 plants" comment and my `enum-data-test` entry both present),
  `scripts/fork_drift_manifest.txt` (the hotfix's `scripts/common.sh` re-pin + NOTE beside my rows + NOTE),
  `lean_frontend/CLAUDE.md`/`VALIDATION.md` (Phase 1 did not touch them). The second replay was clean.
`git status --short` after the rebase: clean. `git log --oneline 5407597d9..HEAD`: `70408e483 tests(immaculate): seven
desugar-time enum-read witnesses …` / `3ad477462 program-data-parameters E-A Phase 1: …` (same messages).

### 9.2 The consumer re-pin note (cerberus-sl; the operator relays)

Pin target: this branch's head after the E-A audit and ff-only merge (readers `enum_definitions`, `tagDefs` — D-A is
NOT in this range). Signature changes since your `035f12c`-era pin of `mdd/cerberus-lean`:
1. **One new leading argument, `enumDefs : Fmap sym integerType`, BEFORE `tagDefs` on every reader-taking generated
   signature** (the global sorted reader order is `enum_definitions`, `tagDefs`): `drive enumDefs tagDefs …`,
   `driver2`, `driver_globals`, `finalize`, `desugar`, `translate`, and every def that carried `_lemReader_tagDefs`;
   NEWLY reader-taking (had no reader before): `GenTyping.annotate_program enumDefs tagDefs p`, `Implementation.
   {sizeof_ity, alignof_ity, is_signed_ity, precision_ity, integerImpl, normalise_ctype, is_compatible_with_size_t,
   is_compatible_with_ptrdiff_t, is_signed_or_unsigned}`, `AilTypesAux.are_compatible`/`make_composite`/…,
   `Ctype_aux.are_compatible_aux`/`match_integer_ctype`, `GenTyping.*`, `GenTypesAux.*`, `Translation_aux.
   {ctype_of, qualified_ctype_of, combine_params_args}`, `Mem_common.{derive_intrinsic_signature, resolve_arg,
   try_usual_arithmetic}` — the authoritative list is the GENERATED tree's binders (§3.4's census of 119 newly lifted
   decls; `Core_typing.*` is NOT among them — the field addition does not make those defs read the map).
   `initial_driver_state` is UNCHANGED (W7 — it is supply-lifted only).
2. **`Core.file` has a new field `enumDefs : Fmap sym integerType`** (beside `tagDefs`; linking unions it): your
   three full-file literals `CertP.lean:67,77,89` gain `enumDefs := F.enumDefs` (or `fmapEmpty` for a file with no
   enums); `Program := ⟨file, supply⟩` is unchanged. The run's reader value is `runFile.enumDefs`; the elaborator's
   is the per-TU `Lem_Map.fromList sigma.enum_definitions` (`A.sigma` has the new field `enum_definitions : List
   (sym × integerType)`).
3. **`CerberusImpl.{sizeof_ity, is_signed_ity, alignof_ity, precision_ity}` keep their type-only signatures** — but
   they are now functions of a RESOLVED type: an `Enum0` reaching them is the `failwithI` leaf. Resolve first with
   `CerberusImpl.normalise_integerType enumDefs tagDefs ity` (the one consumer; `.Enum0 s` ↦ the map's entry,
   `failwithI "Ocaml_implementation.typeof_enum: '…' was not registered"` on a miss) or `CerberusImpl.resolveEnum
   enumDefs ity` (Enum-only); `CerberusImpl.typeof_enum`, `register_enum`'s effect, `enumRegistryRef` are GONE.
   Payoff: `sizeof_ity e t (.Enum0 s) = some 4` (the generated `Implementation` wrapper; generated modules carry no
   namespace) is `rfl` given `e = Lem_Map.fromList [(s, .Unsigned .Int_)]` (test/Unit/EnumDataTest.lean);
   `CerbMem.sizeofCtype enumDefs tds (Ctype [] (Basic (Integer (.Enum0 s))))` is a function of program data — the enum
   argument is the map, first. `is_signed_ity e t ity` resolves ONLY an enum (audit E4): on `Signed (IntN_t 128)` it
   answers `true` as the OCaml does; `sizeof_ity`/`alignof_ity`/`precision_ity` normalise fully.
4. **CerbMem** (if you call the hand-written stubs directly): every `reader_consumer` stub takes `enumDefs` FIRST —
   `allocateObject enumDefs tagDefs …`, `loadM`, `storeM`, `sizeofIval`, `alignofIval`, `offsetofIval`, `maxIval
   enumDefs tagDefs ity`, `minIval`, `intfromptr`, `copyAllocId`, … (the 20 `mem.lem` consumers; `implementation.lem`'s
   two are `normalise_integerType` and `alignof_ty`); the measured layout workers/wrappers
   (`sizeofCtype enumDefs ambient cty`, `alignofCtype`, `offsetsof`, `memberAlign`, `offsetsofMembers`,
   `memValueToBytes`, `reconstructValue`) likewise. The sufficiency theorems in `CerbMem_lemMeasureProofs.lean`
   carry the same extra binder; `fuel_hypotheses.txt` is unmoved.
5. **`reconstructValue_lemFuel`'s struct/union arms are reshaped by the F-1 hotfix** (in this range's base, `5d462da86`):
   the struct arm guards `lookupEntry` before its fold; the union arm selects the member before recursing; each failure
   leaf is the WHOLE result — if you unfold these arms (`TreeRotExhibit.lean:148`, `ListRevExhibit.lean:260` did), the
   match structure changed; the `_indexed` twin and `reconstructValue_lemFuel_eq_indexed` are restated identically.
6. **Seeds (S0.5 audit N1 + this audit's E1):** if you write a `reader_seed` def, its first N parameters (N = 2 here)
   are the seeds in the sorted order, and a def with ≥ N parameters silently takes its own leading parameter as a seed —
   give every seed def a `val` and a VALUE pin (the two seeds have different types here, so a slip is a type error).
   AND: a `reader_seed` does not re-seed closures constructed OUTSIDE its extent — a reader-lifted function value passed
   INTO a seed is already applied to the caller's binders; pass the data it is built from and construct it inside (§10 E1).
7. `CerberusFresh.digest` is UNCHANGED in this range (D-A is deferred; §3.1): `SymFresh.lean:70-75`'s property stays
   as it is; the `HeapNeg.lean`/`SymFresh.lean` prose about `set_digest` is not yet stale.

### 9.3 Post-rebase fixes (uncommitted at the re-gate; folded into the record commit, as ruled), regeneration and builds

The replayed commits compiled against the hotfix base needed four mechanical residues, found by the first
`build_lean` over every root (`Some required targets logged failures: Ctype_aux_lemMeasureProofs,
Defacto_memory_lemMeasureProofs, CerbMem_lemMeasureProofs, Core_aux_lemMeasureProofs, Core_eval_lemMeasureProofs`):
- `Core_aux_/Core_eval_/Defacto_memory_lemMeasureProofs.lean`: my rebase-time binder substitution had doubled the
  `(ed : Fmap sym integerType)` binder on the `∀`-headed `stable_aux` lemmas (`(ed …) (ed …) (td …)`) — de-duplicated
  (`Invalid alternative name `zero`` was the symptom: the extra binder shifted the `intro` names).
- `Ctype_aux_lemMeasureProofs.lean`: the two obligation RIGHT-hand sides (`are_compatible_params_aux0 env1 acc
  lemTail`, `are_compatible_params0 env1 params1 params2`) lacked the reader arguments the wrappers now take.
- `CerbMem_lemMeasureProofs.lean` (the merged `Reconstruct` section): one `offsetsof_lemFuel (…) ambient ambient t
  true` inside the hotfix's `hm` step lacked `enumDefs`.
- `scripts/check_fuel_forms.sh` — **W18 (fence extension, GRANTED [AGENT orchestrator] at the resume):** the
  self-test's two COMPILED decoys P10/P11 restate REAL obligations (`CerbMem.alignofCtype_measure_sufficient` under
  `cty ≠ cty`; `CerbMem.sizeofCtype_measure_sufficient` with an extra binder) whose signatures E-A changed, so they
  failed to compile against `sizeofCtype_lemFuel lemFuel enumDefs ambient …` (`PLANT FAIL [tool with the extra-binder
  + contradictory-hypothesis decoys]` → `check_fuel_forms: SELFTEST FAILED (3)`); restated with `(enumDefs :
  CerberusImpl.EnumDefs)` before `ambient` and a comment saying why. Nothing else in the gate moved.
- `scripts/failure_reach_register.txt`: re-derived (`--emit` → 237 rows; the class columns of every row equal to the
  git text-merge's — `diff` of columns 1–8: 0 lines, so no new review was needed; `--reseal` → `resealed 237 rows`);
  tally `sites=237 exec=235 unresolved-owner=2 reviewed-TAIL=184 reviewed-NON-TAIL=53 UNREACHABLE-BY-INVARIANT=169
  REACHABLE=49 UNKNOWN=19 discardable=0` (= the hotfix's 234 + my +5 −2). Gate: `check_failure_reach: OK (237 pure
  failure sites = the 237 register rows exactly (235 in the exec dependency closure + 2 unresolved-owner; …); position
  classes unchanged; 0 DISCARDABLE; reach UNREACHABLE-BY-INVARIANT=169 REACHABLE=49 UNKNOWN=19; every row sealed;
  tally line consistent)`.

Regeneration at `Lem 38f87d5`: `make rc=0 wall=40s`, stamps `check_lem_sync: recorded ocaml_frontend/lem_sync.sha256
(src bc2f8bbbcb90a6ca30b3cbdbf4df3944edd9d0554ab7c038f7be9c559aa5e12d, gen b2f073232e32ac707650a45766014dede7b8de6b9181e6243ce6bfefac73456c)`
/ `… lean_frontend/lem_sync.sha256 (src bc2f8bbb…, gen eb2b61a1268f8425ec9b73c1d3fa2d1175c51a596db3ea602de02a315bd232e3)`
(the same values as before the rebase — the mainline range touched no `.lem`). `build_cerberus rc=0 wall=6s`
(`oracle stamp bin 55e8055f…`); `build_lean` (EVERY root) → `Build completed successfully (395 jobs).` /
`check_driver_fresh: recorded lean stamp (bin 80f2e318ce1cf114b03d4a2745aadad33f2533c69e154db42d5dacba4450b724, src
7e778bf7b36f729b05c9431b80d35d135e43b2028994c4c04ac596ab62439d54)` (40 s on the first pass with the residues, 1 s
replay after); the eight proof modules `lake build … rc=0 wall=4s`; speclab `Build completed successfully (148 jobs).`
(91 s); the 14 unit exes `rc=0`.

### 9.4 The mandatory full re-gate

Standalone row 1 after the fixes (`scripts/ce ./scripts/test_unit.sh`, `test_unit rc=0 wall=216s`), verbatim:
`Total: 13 passed, 0 failed` · `check_exec_purity: CLEAN (11 modules)` · `check_theorem_axioms: OK (effect-retirement
C2 bar: zero axiom declarations anywhere; entry cones ⊆ the standard three)` · `check_sorry_token: OK (319 files
scanned comment-stripped — generated 219, hand-written+test 65, LemLib 35; 0 sorry tokens)` · `test_exec: SELFTEST
OK (…)` · `check_no_fuel_numerals: OK (326 files …)` · `gen_fuel_parametricity: OK (14 …)` · `check_lakefile_roots: OK
(218 roots = 218 generated modules + the exe root Main; 85 auxiliary modules listed as roots — names only; every
carrier is built by check_fuel_forms.sh)` · **`check_fuel_forms: SELFTEST OK (25 plants with the declared label — 6 on
the table (incl. the ABSORBING-cone plant), 3 on the hypothesis register, 15 compiled decoys: …)`** ·
**`check_fuel_forms: OK (81 fuel'd workers: 62 MEASURED (obligation of the contract's shape incl. argument
correspondence against the wrapper's body; every obligation + proof cone ⊆ the standard three; 12 of them under a
hypothesis, each = a reviewed row of fuel_hypotheses.txt, both directions), 13 ABSORBING = kill at zero (…)`** (real:
the carriers are built by the gate — F-1 closed) · `check_failure_reach: OK (237 …)` (above) · `check_exec_totality:
CLEAN (22 generated modules + hand-written CerbND, 0 allowlisted)` · `check_lem_sync: OK (src bc2f8bbb…, gen
b2f07323…)` / `check_lem_sync: lean OK (src bc2f8bbb…, gen eb2b61a1…)` · **`check_fork_drift: OK — layer 1: 82
oracle-surface files = manifest (set, C-locale canonical, no duplicates); layer 2: 29 differing generated files, all
hash-pinned (merge-base b9aeedcb4dd438763b0eef7f95ac19e93875d7de; lem-pin 38f87d5 = lem -v)`** ·
`check_fixture_freeze: OK (16 fixture files match the pinned manifest; name set exact)` · `test_renumber_plants: OK (12
plants: refusals refuse, admits admit with declared class)`.

**The battery** (`scripts/ce python3 scripts/release.py --mode full --out .tmp/eada/regate-full`, ONE run, Tier A + B):
`full: incomplete; 39/39 selected commands completed successfully.` / `Source unchanged: False. Complete tier
selection: True.` — **wall 5464 s (91 min)**. **This run is INCOMPLETE as the runner says (E3 of the pre-merge audit, §10):**
`Source unchanged: False` means the source identity CHANGED DURING THE RUN — I edited this record while the battery ran
(the runner compares the complete before/after source and external-input identities; a stable dirty tree compares
EQUAL, so my earlier explanation "the eight files were uncommitted" was WRONG, and "incomplete" here is the tier-run
status, not the separate `Release certification` sentence). Its 39 row verdicts stand as history; it is NOT the
certification — §10.6's source-stable run is. Every row `PASSED`: `A1 (309.3s) A2 (54.0s) A3
(55.8s) A4 (23.1s) A4b (24.5s) A4c (3.1s) A5 (22.3s) A6 (2.2s) A6b (3.6s) A7 (10.6s) A8 (9.2s) A9 (18.8s) A10 (17.3s)
A11 (58.7s) A12.1 (4.9s) A12.2 (4.5s) B1 (739.6s) B2 (23.6s) B3 (15.5s) B4 (48.8s) B5 (71.9s) B6.1 (78.2s) B6.2 (2.3s)
B6.3 (9.7s) B6.4 (9.1s) B6.5 (9.4s) B6.6 (10.9s) B6.7 (9.0s) B7 (1350.7s) B8.1 (13.4s) B8.2 (241.9s) B8.3 (6.3s) B8.4
(16.5s) B9 (1489.3s) B10.1 (208.0s) B10.2 (2.3s) B11.1 (18.1s) B11.2 (7.9s) B12 (457.9s)`.

Tier A in the battery: row 1's key lines = §9.4's standalone lines verbatim (`Total: 13 passed, 0 failed`,
`check_fuel_forms: OK (81 …)`, `SELFTEST OK (25 plants …)`, `check_failure_reach: OK (237 …)`, `check_fork_drift: OK —
layer 1: 82 … layer 2: 29 … lem-pin 38f87d5 = lem -v`, `check_lem_sync: OK`/`lean OK`, `check_theorem_axioms: OK`,
`check_exec_purity: CLEAN (11 modules)`); rows 2–12 = the §5 tails (SUMMARY lines identical, `BASELINE OK` ×4, A4c
`exec_match=9 neg_pinned=5`, A5 `match=12 diff=0`, A6 `2/2`, A6b `7/7`, A7/A8 `ALL PASSED`, A9 `same=108 diff=5`,
A10 `GATE PASS … (16/16)`, A11 `BASELINE OK (213 entries, exact match)`, A12 `18/18`).

Tier B, verbatim tails:
- B1 `test_libxml2.sh`: `SUMMARY: total=4 match=4 fail=0 (points: 1354, 22 observations each)` / `ALL PASSED`.
- B2 `test_parse.sh tests/ci`: `Total: 250` / `Cerberus parse: 247 ok, 3 failed` / `Lean parse: 128 ok, 0 failed, 0 timeout
  (>60s; fatal), 0 lean failure(s) …` / `Lean front end: 117 rejected (exit 1 + a printed Error/Undefined verdict; not a
  parse failure), 2 internal-error-expected (…)` / `Success rate: 51% (of cerberus successes)` / `batch diagnostic
  producers: 8/8 passed` / `ALL PASSED` (the lane's standing shape: the seam-hygiene record §5.6 quotes the same trailing
  lines).
- B3 `test_core.sh tests/ci`: `Success rate: 100% (of cerberus successes)` / `ALL PASSED`.
- B4 `test_verify.sh`: `test_verify: 127 passed, 0 failed (25 fixtures, 28 call points, 14 corpus fixtures, 21 corpus points)`.
- B5 `test_immaculate.sh`: `OK: lane matches the committed baseline (MATCH except the ISO-fix register pins R1 …, R2 …,
  R3 …, R5 …)` — the seven d3 rows MATCH inside it.
- B6.1/B6.2 `test_speclab.sh --selftest`/`--plant`: `test_speclab: PASS (both pipelines agree on Specified(0))` /
  `… Specified(2))`; B6.3–B6.7 the five gates: `CoreGateTest: ALL PASSED`, `ByteArrGateTest: ALL PASSED`,
  `ListGateTest: ALL PASSED`, `TreeGateTest: ALL PASSED`, `SeedGateTest: ALL PASSED`.
- B7 `test_gcc_oracle.sh --check-baseline`: `SUMMARY: total=2008 compared=1923 agree=1911 agree_nd=0 triaged=12 disagree=0
  o2_agree=197 skip_gcc_compile=1 skip_gcc_stdout=1 skip_lean_crash=12 skip_lean_fail=13 skip_lean_timeout=11 skip_ub=47
  triaged_addr=11 triaged_ub=1` / `Baseline check: 0 regression(s), 0 improvement(s)` (1350.7 s).
- B8.1–B8.4 plant batteries: `test_hang_plant: all plants read as expected (sleep→HANG, busy→TIMEOUT, both lanes; missing
  record→harness error)`; `test_kill_plant: all plants read as expected (…)`; `test_fuel_plant: ALL PLANTS OK (…)`;
  `test_failstop_plant: PASS (11 class and rejection checks)`.
- B9 `test_observation_lanes.py`: `observation lane plants: 93/93 passed` (1489 s — the immaculate plants re-run the
  lane, now seven cases longer).
- **B10.1 pristine**: `Independent oracle: passed; {'semantic_agreement': 829, 'matching_failure': 28,
  'reviewed_difference': 7, 'interface_agreement': 2}` — 829 = 822 + the seven d3 cases (an ADDITION of corpus, each
  `semantic_agreement`); **W19 (charter erratum):** the charter's/re-launch's expectation `'reviewed_difference': 3` is
  STALE — the register `scripts/upstream_oracle_differences.json` has held SEVEN cases since before this arc (identical
  at `52af8ccf1` and at this head; no history entry in the range: the three multi-TU tray rows + `minimal/112`,
  `minimal/113`, `immaculate/nolibc/tray44-allocator-exhausted-single-request{,-overlap}` — the allocator-soundness
  slice's rows), and the last three mainline full batteries (2026-09-17 address-space part two, 2026-09-18 seam hygiene,
  its audit) all quote `'reviewed_difference': 7`. NOT movement. B10.2 `--plant`: `Independent oracle: plants_passed;
  {'semantic_agreement': 1, 'plant_rejected': 1, 'plant_ok': 51}`.
- B11.1/B11.2 `check_failure_reach.sh --selftest` / gate: `check_failure_reach: SELFTEST OK (5 plants …)`; `check_failure_reach:
  OK (237 pure failure sites = the 237 register rows exactly (…); every row sealed; tally line consistent)`.
- B12 pristine chvalid: `4/4 semantic_agreement …` / `Independent oracle: passed; {'semantic_agreement': 4}`.

**ZERO lane movement** across Tier A and Tier B (stop rule S2 never triggered); row 1 FULLY green with the hardened
fuel-forms gate — §7's mandatory condition is met.

### 9.5 Final register/manifest counts (this head)

`unsafebaseio_allowlist.txt` KEEP 1 / PIN 19 (was 3 / 25); `OPAQUE_WANT` 10 (was 12); `failure_reach_register.txt` 237
rows (mainline's 234 after the hotfix + this slice's +5 −2), tally `sites=237 exec=235 unresolved-owner=2
reviewed-TAIL=184 reviewed-NON-TAIL=53 UNREACHABLE-BY-INVARIANT=169 REACHABLE=49 UNKNOWN=19 discardable=0`;
`fork_drift_manifest.txt` `[files]` 82 (was 76), `[source-content]` 82 pins (12 moved + 6 new by this slice; the
hotfix's `scripts/common.sh` re-pin beside them), layer 2: 29 (19 semantic + 10 cosmetic; was 25 = 13 + 12), `lem-pin
38f87d5`; `fuel_hypotheses.txt` UNMOVED (12 hypothesis rows); `tests/immaculate/baseline.txt` +7 rows (§8);
`IMMACULATE_PANICS = set()`. Consumers: 22 `reader_consumer` declares (20 `mem.lem` + 2 `implementation.lem`). Readers: `enum_definitions`, `tagDefs`.

### 9.6 Commit

ONE commit for this section: the eight post-rebase files (five `*_lemMeasureProofs.lean` binder residues, the
`check_fuel_forms.sh` decoy restatement W18, the re-derived register, this record). Then `.tmp/eada/` (the Stage A
patch, the generated-tree snapshots, the reach/manifest/register scripts, the witness probes, every lane log quoted
above) is DELETED — the record carries what matters. STOP for the E-A audit ask; Phase 2/D-A does not start (the
operator's decision, §3.1).

## 10. Pre-merge audit repairs (Codex audit `2026-09-20_enum-premerge-audit.md`, REQUEST CHANGES on `5407597d9..0e1968ffb`; every premise verified by the orchestrator [AGENT] and reproduced by me)

### 10.1 E1 (P1, a REGRESSION) — the block-typing callback captured the empty enum map outside the seed

Reproduced on my head binary `0e1968ffb` through the exec lane on the audit's six reproducers (`.tmp/eada2/prefix/`),
verbatim: `[1/6] LEAN_CRASH d3-s7-callback-assign (exit 134): PANIC at _private.LemLib.0.failwithIImpl LemLib:168:2:
Ocaml_implementation.typeof_enum: 'Symbol(19, SD_Id("E"))' was no` — the same line for `conditional`, `equality`,
`init`, `param`, `return`; `SUMMARY: total=6 match=0 … crash=6` (the fork oracle: `Specified(1)`, `1`, `3`, `1`, `2`,
`1`). Cause (the audit's, confirmed in the generated tree): `Mini_pipeline.annotate_expression_seeded en tds
annotate_block …` received the callback `GenTyping.annotate_block (Just ret_ty)` built at the CALL SITE
(`cabs_to_ail.lem:1761`, `:2414`) — `annotate_block` is itself reader-lifted, so the generated call passed
`(annotate_block _lemReader_enum_definitions _lemReader_tagDefs) (some ret_ty)`, a closure already applied to the OUTER
binders (the desugar entry's EMPTY enum map); the seed forwarded it unchanged. **Fix:** the seed takes the DATA the
callback is built from — `annotate_expression_seeded en tds (ret_ty : maybe Ctype.ctype) sigm gamm ctx expr =
GenTyping.annotate_expression (GenTyping.annotate_block ret_ty) sigm gamm ctx expr` — and both call sites pass `(Just
ret_ty)` / `Nothing`. **Per-seed review of function-typed arguments crossing the seed boundary (the same hazard):**
`run_const_expr_driver en tds dr_st` — none (a `driver_state`: Core data, no Lean closure); `evalIntegerConstantExpression_seeded
… core_env sigm ty_opt expr` — none (`core_env` is three maps of Core declarations; the `typing_guard` closure is built
INSIDE `evalIntegerConstantExpression`, within the seed); `typecheckAil_seeded sigm gamm expr` — none (`typecheckAil`
builds `annotate_block Nothing` inside); `annotate_expression_seeded` — FIXED (the only one); `qualified_ctype_of_seeded
a_expr` — none; `are_compatible_seeded p1 p2`, `make_composite_seeded ty1 ty2`, `make_composite_fdecl_seeded d1 d2`
(`fun_declaration` = data), `alignof_ty_seeded pseudo_tagDefs ty`, `find_compatible_generic_association_seeded p gs` — none.
**lem-lean DESIGN follow-up (a doc sentence at the next lem-lean touch, not this slice):** "a `reader_seed` does not
re-seed closures constructed outside its extent." Six PERMANENT witnesses `tests/immaculate/nolibc/d3-s7-callback-
{init,assign,conditional,equality,param,return}.c` (the audit's sources, headers naming the read and the pre-fix crash),
baseline rows ADDED via the recipe (§10.5). **Erratum W21** to §4.2 and the baseline header: S-7 HAS oracle-accepted
witnesses — the parser recognises `typeof`, not `__typeof__` (my spellings were parse errors); only S-1 (a cast inside an
integer constant expression) has none.

### 10.2 E2 (P2) — two remaining full `Core.file` literals lacked `enumDefs`

`backend/web/instance.ml:334-346` and `backend/bmc/bmc_utils.ml:413-426` are full literals (all base fields incl.
`calling_convention`) that omitted the new field — the auditor type-checked the extracted records: `Some record fields
are undefined: enumDefs`. Fixed: `enumDefs= file.enumDefs;` / `enumDefs= (file1.enumDefs);` — PRESERVED, never an empty
map. Complete scan of non-generated OCaml for full `Core.file` literals (`tagDefs` + `calling_convention` + `funinfo` in
one literal; `.tmp/eada2` scan): `pipeline.ml:288,518,679`, `core_peval.ml:865`, `remove_unspecs.ml:106` (done in Phase
1), `instance.ml:334`, `bmc_utils.ml:413` (done now) — no other. `backend/absint/src/cfg.ml:1025` is NOT a `Core.file`
(absint's own record: no `calling_convention`/`extern`/`loop_attributes0`, `impl = ()`); `backend/ocaml/{driver/main.ml:75,
driver/core_opt.ml:58,77, runtime/rt_ocaml.ml:348}` already lack `calling_convention` — pre-existing stale literals that
cannot compile with or without this slice (left as they are). **Erratum W22 to W9:** "not in the selected build graph" is
not evidence that a constructor remains valid after a required field is added — the check is the type-check the auditor
performed, and it is now part of the E2 scan above. Neither file is on the fork-drift oracle surface (`check_fork_drift.sh`
`SURFACES` = frontend, backend/common, backend/driver, backend/lean_export, ocaml_frontend, memory, util, …), so no
manifest row moves.

### 10.3 E4 (P2, a zero-discrepancy violation) — `is_signed_ity` must resolve ONLY an enum

OCaml's `Common.is_signed_ity` (`ocaml_implementation.ml:79-94`) resolves an `Enum` through `typeof_enum` and then reads the
CONSTRUCTOR — `Signed _ → true`, `Unsigned _ → false` — never the width-alias table; my D2 wrapper `is_signed_ity ity =
is_signed_ity_norm (normalise_integerType ity)` normalised the alias table too, so `Signed (IntN_t 128)` aborted on Lean
(`DefaultImpl.type_alias_map has no alias for an N-family width of 128`) where the OCaml answers `true` (the audit's
table: base Lean `true`, base/head OCaml `true`, head Lean abort). **Fix:** a SHARED lem def `resolve_enum ity = match ity
with Enum s -> typeof_enum s | _ -> ity` (implementation.lem, beside `typeof_enum`) and `is_signed_ity ity =
is_signed_ity_norm (resolve_enum ity)`; `sizeof_ity`/`alignof_ity`/`precision_ity` KEEP full normalisation because OCaml's
own do — `DefaultImpl.sizeof_ity` (`:172-174`) and `alignof_ity` (`:214-216`) match on `Common.normalise_integerType_`'s
result, and `Common.precision_ity` (`:68-70`) calls `sizeof_ity` FIRST (so an unsupported width fails closed there on both
engines). **Erratum W20 to charter D2** ("same for `is_signed_ity`" was wrong: the four layout vals do not share one
normalisation shape). Controls in `EnumDataTest`: `is_signed_ity eU t (.Signed (.IntN_t 128)) = true` and `(.Unsigned
(.IntN_t 128)) = false` by `rfl`, the supported-width pair, `sizeof_ity eU t (.Signed (.IntN_t 32)) = some 4`, and a
`#guard_msgs` negative that `sizeof_ity eU t (.Signed (.IntN_t 128)) = some 16` is NOT provable by `rfl` (the leaf is
opaque — fail-closed as before). The failure-reach register gains `typeof_enum`'s generated leaf (now in the exec closure
through `resolve_enum` → `is_signed_ity`): reviewed REACHABLE, the same class as `lookupEnum` (a Core-text input naming an
enum tag; a both-crash pair with `ocaml_implementation.ml:146-149`).

### 10.4 E3 (P2, record integrity) — the first full run was INCOMPLETE

§9.4 is corrected in place: `Source unchanged: False` = the source identity changed DURING the run (I edited this record
while the battery ran), so that run is labelled incomplete and kept as history; the FINAL re-gate (§10.6) is a
source-stable run on a tree I did not touch, whose `report.json` and `summary.txt` are RETAINED in
`lean_frontend/docs/2026-09-20_program-data-parameters-EA-DA-evidence/` (JSON/txt — `.gitignore:59` swallows `*.log`, so no
logs are kept; the record quotes the tails). **Erratum W23** to my earlier reading of the runner.

### 10.5 Docs and boundary (with the fix)

`lean_frontend/README.md`, `DESIGN.md`, `VALIDATION.md`'s boundary bullet: the enum registry LEFT the boundary (the digest
seam stays, explicitly); `docs/2026-08-22_arc14-effect-erasure-invariant.md` gains the dated header "ENUM HALF RETIRED
2026-09-20 … the DIGEST seam REMAINS"; `Main.lean`'s desugar comment says FIRST reader; the consumer census is 22
`reader_consumer` declares (20 `mem.lem` + 2 `implementation.lem`; "18" counted the CerbMem stubs and miscounted) at its
three mentions; the consumer note (§9.2) is tightened to the generated signatures (no `Core_typing.*`; the enum argument
shown in the `sizeofCtype` example; the E4 domain rule; the E1 closure rule). Baseline: the six `d3-s7-callback-*` rows
ADDED via `test_immaculate.sh --record-baseline` with the header note corrected (S-7 has witnesses; S-1 does not).

### 10.6 The final, source-stable re-gate (the certification of this branch)

**What is in the repair commit** (one commit on `0e1968ffb`): lem `frontend/model/mini_pipeline.lem` (E1 seed),
`cabs_to_ail.lem` (E1 call sites), `implementation.lem` (E4 `resolve_enum` + `is_signed_ity`); OCaml
`backend/web/instance.ml`, `backend/bmc/bmc_utils.ml` (E2); Lean `CerberusImpl.lean` (comment), `Main.lean` (comment),
`test/Unit/EnumDataTest.lean` (E4 controls); tests `tests/immaculate/nolibc/d3-s7-callback-{init,assign,conditional,
equality,param,return}.c` + `tests/immaculate/baseline.txt` (+6 rows via the recipe; the S-1/S-7 header note CORRECTED —
the one replaced header line is that correction, rows removed/changed 0) + `scripts/test_immaculate.sh` (the header
note); registers `scripts/failure_reach_register.txt` (238 rows: +1 `Implementation.lean typeof_enum` REACHABLE, resealed;
tally `sites=238 exec=236 unresolved-owner=2 reviewed-TAIL=185 reviewed-NON-TAIL=53 UNREACHABLE-BY-INVARIANT=169
REACHABLE=50 UNKNOWN=19 discardable=0`), `scripts/fork_drift_manifest.txt` (three `[source-content]` pins + three
`[expected-semantic]` hashes moved, one NOTE; set 29 unchanged); docs `README.md`, `DESIGN.md`, `VALIDATION.md`, the
effect-erasure page header, this record, and the evidence dir `2026-09-20_program-data-parameters-EA-DA-evidence/`
(`report.json` + `summary.txt` of the run below — JSON/txt, not `.log`).

**Focused verdicts on the repaired tree (before the battery):** regeneration `Lem 38f87d5` `make rc=0 wall=39s`
(`check_lem_sync: recorded ocaml_frontend/lem_sync.sha256 (src ef81624da3fe5a53d3e99d696d86fec8af241a9d32921552adfed1f419a7867a,
gen 5192589f474b9834b036a34b4c9f5be279a03aa057fd895d2c6e067d68b42082)` / `… lean_frontend/lem_sync.sha256 (src ef81624d…, gen
c6c8a49dc76f34edef76c087a1b33b33b19f3b9a677bffa819acb730dd764d36)`); `build_cerberus rc=0 wall=8s` (`oracle stamp bin
e13a6474…`); E2 type-check the auditor's way (the extracted `instance.ml`/`bmc_utils.ml` records compiled against the
freshly built `cerb_frontend` interfaces): `web_record head 0 (no diagnostics)`, `bmc_record head 0 (no diagnostics)`
(the optional `dune` targets themselves need `z3`/`fpath`, absent here, as for the auditor); `build_lean` (every root)
`Build completed successfully (395 jobs).` (57 s; `lean stamp bin e76f7087…`); speclab `148 jobs`; the 14 unit exes;
`enum-data-test` with the E4 controls → `EnumDataTest: … kernel-checked at compile time` rc 0 (pin cone `[propext,
Classical.choice, Quot.sound]`; the `#guard_msgs` negative fires on the opaque leaf: `Tactic `rfl` failed: … sizeof_ity eU t
(Signed (IntN_t 128)) … some 16`). **The six E1 witnesses through the exec lane — BEFORE the fix on `0e1968ffb`'s binary:**
`[1/6] LEAN_CRASH d3-s7-callback-assign (exit 134): PANIC at _private.LemLib.0.failwithIImpl LemLib:168:2:
Ocaml_implementation.typeof_enum: 'Symbol(19, SD_Id("E"))' was no` (and the same for `conditional`, `equality`, `init`, `param`,
`return`; `SUMMARY: total=6 match=0 … crash=6`); **AFTER:** `[1/6] MATCH d3-s7-callback-assign: VAL:{value: "Specified(1)", …}`,
`conditional Specified(1)`, `equality Specified(3)`, `init Specified(1)`, `param Specified(2)`, `return Specified(1)`;
`SUMMARY: total=6 match=6 ub_match=0 ub_diff=0 mismatch=0 fail=0 crash=0 …`. `test_immaculate.sh` (72 s) → `OK: lane matches
the committed baseline …` with the six new rows `MATCH`; pristine `test_upstream_oracle.py --only "immaculate/nolibc/d3-s7-"` →
`Independent oracle: subset_passed; {'semantic_agreement': 6}`; `check_failure_reach: OK (238 pure failure sites = the 238
register rows exactly (236 in the exec dependency closure + 2 unresolved-owner; …); every row sealed; tally line consistent)`;
`check_fork_content: OK — 82 source files content/mode-pinned` / `check_fork_drift: OK — layer 1: 82 … layer 2: 29 … lem-pin
38f87d5 = lem -v`.

**The battery** (`scripts/ce python3 scripts/release.py --mode full --out .tmp/eada2/final`), started only after every edit
above (this record included) and on a tree NOT touched until it ended; its `report.json`/`summary.txt` are copied to the
evidence dir afterwards and the tails appended below:

**Runner verdict (verbatim, `summary.txt`):** `full: passed; 39/39 selected commands completed successfully.` /
`Source unchanged: True. Complete tier selection: True.` / `Release certification: incomplete: reporting/adoption/audit
exits require separate evidence.` (the third sentence is the runner's standing release-exit sentence — the reporting/
adoption/audit exits are separate evidence by design; it is not a tier verdict). Wall: `release.py rc=0 wall=5495s`
(started `20260921T015126.988243Z`, finished `2026-09-21T03:23:02.570402+00:00`). `report.json`: `status passed`,
`source_unchanged True`, `selection_complete True`; `source_before` = `source_after` = head `0e1968ffb6d4736e60a7b53bee2fb3eb2c336304`
with the SAME dirty-tree `diff_sha256 161aa5801989884babf08814b2b9f61b1a1265f64b6f5b5903d23ce158018af5` (the repair
diff, uncommitted during the run and committed as the fix commit with this record) — and my own before/after snapshot of
the tree (`git status --short | sha256sum` = `4671fadf…`, `git diff | sha256sum` = `161aa580…`, the six witnesses + this
record = `d06af24a…`) is identical on both sides. All 39 lanes `passed`: `A1 (226.6s) A2 (29.4s) A3 (52.7s) A4 (23.6s)
A4b (25.1s) A4c (3.2s) A5 (26.8s) A6 (2.4s) A6b (3.8s) A7 (10.8s) A8 (9.2s) A9 (18.2s) A10 (18.0s) A11 (59.7s) A12.1 (5.0s)
A12.2 (4.6s) B1 (756.1s) B2 (23.9s) B3 (15.6s) B4 (46.7s) B5 (75.4s) B6.1 (3.8s) B6.2 (2.3s) B6.3 (9.6s) B6.4 (9.0s) B6.5 (9.6s)
B6.6 (10.1s) B6.7 (8.8s) B7 (1533.9s) B8.1 (13.4s) B8.2 (261.8s) B8.3 (6.3s) B8.4 (16.6s) B9 (1600.6s) B10.1 (119.8s) B10.2 (1.8s)
B11.1 (15.4s) B11.2 (6.7s) B12 (427.7s)`. Evidence dir: `report.json` sha256 `0ecc6f902341254e75f04f6456c11aacbd346da55bbce9705f2b2f64c0074b3c`,
`summary.txt` sha256 `8a982b1a5855d318a90fc19da8e4d0a9850345dbf4422e741b0b604d8c2fdf20`.

**Tier A, verbatim tails (from `A*/stdout` of the run):**
- A1 `test_unit.sh`: `Total: 13 passed, 0 failed`; `✓ enum-data-test PASSED` (its line: `EnumDataTest: the enum's compatible
  type is program data — normalise/sizeof/alignof/is_signed/precision at a registered enum by rfl/decide given the map;
  GCC's rule in lem; register_enum = true; the retired registry names no longer elaborate …`; pin cone
  `'EnumDataTest.sizeof_enum_pin' depends on axioms: [propext, Classical.choice, Quot.sound]`); `check_exec_purity: CLEAN
  (11 modules)`; `check_theorem_axioms: OK (effect-retirement C2 bar: zero axiom declarations anywhere; entry cones ⊆ the
  standard three)`; `check_sorry_token: OK (319 files scanned comment-stripped — generated 219, hand-written+test 65,
  LemLib 35; 0 sorry tokens)`; `check_no_fuel_numerals: OK (326 files scanned …)`; `gen_fuel_parametricity: OK (14 ambient
  fuel wrappers …)`; `check_lakefile_roots: OK (218 roots = 218 generated modules + the exe root Main; 85 auxiliary
  modules …)`; `check_fuel_forms: SELFTEST OK (25 plants with the declared label — …)`; `check_fuel_forms: OK (81 fuel'd
  workers: 62 MEASURED (… 12 of them under a hypothesis, each = a reviewed row of fuel_hypotheses.txt, both directions),
  13 ABSORBING = kill at zero (…), 0 reachable-AMBIENT = the 0 rows of fuel_forms_pending.txt exactly, 6 ambient
  unreachable from the drive cone)`; `check_failure_reach: OK (238 pure failure sites = the 238 register rows exactly
  (236 in the exec dependency closure + 2 unresolved-owner; key = file/owner/token/message, both directions); position
  classes unchanged; 0 DISCARDABLE; reach UNREACHABLE-BY-INVARIANT=169 REACHABLE=50 UNKNOWN=19; every row sealed; tally
  line consistent …)`; `check_exec_totality: CLEAN (22 generated modules + hand-written CerbND, 0 allowlisted)`;
  `check_lem_sync: OK (src ef81624d…, gen 5192589f…)` / `check_lem_sync: lean OK (src ef81624d…, gen c6c8a49d…)`;
  `check_fork_content: OK — 82 source files content/mode-pinned`; `check_fork_drift: OK — layer 1: 82 oracle-surface files
  = manifest (set, C-locale canonical, no duplicates); layer 2: 29 differing generated files, all hash-pinned (merge-base
  b9aeedcb4dd438763b0eef7f95ac19e93875d7de; lem-pin 38f87d5 = lem -v)`; `check_fixture_freeze: OK (16 fixture files match
  the pinned manifest; name set exact)`; `test_renumber_plants: OK (12 plants: refusals refuse, admits admit with declared
  class)`. (Standalone on the same tree just before the battery: `test_unit rc=0 wall=227s`, the same lines.)
- A2 `SUMMARY: total=113 match=90 ub_match=18 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0
  cerb_skip=5 cerb_floor=0 cerb_inconsistent=0` / `Baseline check: 0 regression(s), 0 improvement(s)` / `BASELINE OK`.
- A3 `SUMMARY: total=212 match=183 ub_match=16 ub_diff=0 mismatch=0 fail=0 crash=0 … cerb_skip=13 …` / `BASELINE OK`.
- A4 `SUMMARY: total=90 match=66 ub_match=20 ub_diff=0 mismatch=0 fail=0 crash=0 … cerb_skip=4 …` / `BASELINE OK`.
- A4b `SUMMARY: total=93 match=93 ub_match=0 ub_diff=0 mismatch=0 fail=0 crash=0 … cerb_skip=0 …` / `BASELINE OK`.
- A4c `SUMMARY: exec_match=9 neg_pinned=5 fail=0` / `ALL AT COMMITTED EXPECTEDS`.
- A5 `SUMMARY: match=12 diff=0` / `ALL MATCH RECORDED BASELINE`.
- A6 `SUMMARY: total=2 match=2 fail=0` / `ALL PASSED`; A6b `SUMMARY: total=7 match=7 fail=0` / `ALL PASSED`.
- A7 `Lean parse: 113 ok, 0 failed, 0 timeout (>60s; fatal), 0 lean failure(s) …` / `Success rate: 100% (of cerberus
  successes)` / `batch diagnostic producers: 8/8 passed` / `ALL PASSED`; A8 `Cerberus --pp: 113 ok, 0 failed` / `Lean
  parse: 113 ok, 0 failed` / `ALL PASSED`.
- A9 `SUMMARY: total=113 same=108 diff=5 ocaml_fail=0 lean_fail=0` (reporting mode; unchanged).
- A10 `[lean+libc] EXACT MATCH with ORACLE_LIBC (16/16 URI corpus)` / `GATE PASS: all lane expectations pinned-green +
  baseline unchanged (16/16)`.
- A11 `SUMMARY: total=213 match=207 ub_match=6 ub_diff=0 reject_match=0 diff=0 mismatch=0 …` / `BASELINE OK (213 entries,
  exact match)`.
- A12.1 `test_address_space: SELFTEST OK (14 plants — …)`; A12.2 `test_address_space: OK (18 cases: LEAN = FORK through the
  shared codec at tops 64 32 8; every fork observation = its pinned row in expectations.txt)`.

**Tier B, verbatim tails:**
- B1 `test_libxml2.sh`: `SUMMARY: total=4 match=4 fail=0 (points: 1354, 22 observations each)` / `ALL PASSED`.
- B2 `test_parse.sh tests/ci`: `batch diagnostic producers: 8/8 passed` / `ALL PASSED` (the standing shape, §9).
- B3 `test_core.sh tests/ci`: `Total: 250` / `Cerberus --pp: 128 ok, 122 failed` / `Lean parse: 128 ok, 0 failed` /
  `Success rate: 100% (of cerberus successes)` / `ALL PASSED`.
- B4 `test_verify.sh`: `Build completed successfully (395 jobs).` / `check_driver_fresh: recorded lean stamp (bin
  e76f70878fa51f8665a28856256ad3bde635590978124a393b27b162e45ccdae, src d53c64965d4132773e11771962c697bb181815c96cc7e41ae3699ea8de92ce3c)`
  / `test_verify: 127 passed, 0 failed (25 fixtures, 28 call points, 14 corpus fixtures, 21 corpus points)`.
- B5 `test_immaculate.sh`: the six E1 witnesses inside it — `MATCH d3-s7-callback-assign O[VAL:{value: "Specified(1)", …}]
  L[VAL:{value: "Specified(1)", …}]`, `… d3-s7-callback-conditional … Specified(1)`, `… d3-s7-callback-equality … Specified(3)`,
  `… d3-s7-callback-init … Specified(1)`, `… d3-s7-callback-param … Specified(2)`, `… d3-s7-callback-return … Specified(1)`
  (oracle = Lean on each) — and the verdict `OK: lane matches the committed baseline (MATCH except the ISO-fix register
  pins R1 g5-decode-question/zd-e2-ptr-string-literals ORACLE_CRASH, R2 g5-escape-roundtrip DIFF, R3 s4b-memcmp-hugesize
  ORACLE_CRASH, R5 r5-hex-subnormal-double-rounding DIFF — VALIDATION.md 'ISO-fix register' — and the in-Lean probes g6
  TRIPWIRE / illtyped-store KILL).`
- B6.1/B6.2 `test_speclab: PASS (both pipelines agree on Specified(0))` / `… Specified(2))`; B6.3–B6.7 `CoreGateTest: ALL
  PASSED`, `ByteArrGateTest: ALL PASSED`, `ListGateTest: ALL PASSED`, `TreeGateTest: ALL PASSED`, `SeedGateTest: ALL PASSED`.
- B7 `test_gcc_oracle.sh --check-baseline`: `SUMMARY: total=2014 compared=1929 agree=1917 agree_nd=0 triaged=12 disagree=0
  o2_agree=197 skip_gcc_compile=1 skip_gcc_stdout=1 skip_lean_crash=12 skip_lean_fail=13 skip_lean_timeout=11 skip_ub=47
  triaged_addr=11 triaged_ub=1` / `Baseline check: 0 regression(s), 0 improvement(s)` / `gcc second-oracle lane OK`
  (1533.9 s). [DERIVED] vs §9's `total=2008 compared=1923 agree=1911`: +6 = the six new witness files, each reported by
  the lane as `new file (not in baseline, not fatal): tests/immaculate/nolibc/d3-s7-callback-{assign,conditional,equality,
  init,param,return}.c AGREE/-` (as the seven earlier d3 files are, e.g. `… d3-s4b-fdecl-enum-param.c AGREE/O2_AGREE`);
  every other count identical. The lane's gcc baseline was NOT edited (S2: no re-baselining in this slice; the 13 d3
  rows' admission to that baseline is a housekeeping item for the orchestrator, not a movement).
- B8.1 `test_hang_plant: all plants read as expected (sleep→HANG, busy→TIMEOUT, both lanes; missing record→harness error)`;
  B8.2 `test_kill_plant: all plants read as expected (cap breach -> OOM-KILLED witness; …; no MATCH anywhere)`; B8.3
  `test_fuel_plant: ALL PLANTS OK (…)`; B8.4 `test_failstop_plant: PASS (11 class and rejection checks)`.
- B9 `test_observation_lanes.py`: `observation lane plants: 93/93 passed` (1600.6 s; the immaculate plants re-run the lane,
  now thirteen d3 cases longer).
- **B10.1 pristine** `test_upstream_oracle.py`: `Independent oracle scope: tier-b; 872 rows in 119.5s; source unchanged:
  True` / `Independent oracle: passed; {'semantic_agreement': 835, 'matching_failure': 28, 'reviewed_difference': 7,
  'interface_agreement': 2}` — **835 = 829 + the six new witnesses** ([DERIVED]; each of the thirteen d3 rows is
  `semantic_agreement`: `768/872 semantic_agreement: immaculate/nolibc/d3-s7-callback-assign` … `773/872 … d3-s7-callback-return`
  alongside the seven of §9); `reviewed_difference: 7` = the register's seven (W19), `matching_failure: 28`,
  `interface_agreement: 2` unchanged.
- B10.2 `--plant`: `Independent oracle: plants_passed; {'semantic_agreement': 1, 'plant_rejected': 1, 'plant_ok': 51}`.
- B11.1 `check_failure_reach.sh --selftest`: `check_failure_reach: SELFTEST OK (5 plants with the declared message — …; and
  the unplanted register green)`; B11.2 `check_failure_reach: OK (238 pure failure sites = the 238 register rows exactly …)`.
- B12 `--corpus libxml2_chvalid`: `Independent oracle scope: libxml2_chvalid; 4 rows in 427.5s; source unchanged: True` /
  `Independent oracle: passed; {'semantic_agreement': 4}`.

**Movement (S2): none.** Every baseline lane reports `0 regression(s), 0 improvement(s)` / `BASELINE OK` / `exact match`;
immaculate and cn_coverage at their committed baselines; the only count changes anywhere are the +6 corpus ADDITIONS
(B5 rows, B7 `total`/`compared`/`agree`, B10.1 `semantic_agreement`), each labelled derived above. No baseline was
re-recorded except `tests/immaculate/baseline.txt` by the recipe (+6 rows, additions-only evidence in §10.3).

**State after this section:** the fix commit (this record's §10 + the files listed at the top of §10.6 + the evidence dir)
is the ONLY commit added on `0e1968ffb`; `.tmp/eada2/` deleted; `git status` clean. STOPPED for the delta audit. Phase 2
(D-A) NOT started — the operator's open decision (§3.1).
