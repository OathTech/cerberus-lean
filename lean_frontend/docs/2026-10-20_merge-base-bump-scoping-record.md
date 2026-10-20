# Merge-base bump scoping record — b9aeedcb4 → upstream/master 68bdc84bf

[AGENT 2026-10-20] Read-only scoping, no build, no commit. Every judgement
below is the scoping agent's; the operator has decided only that the bump
is a staged arc after the current consumer deliveries. Machine outputs are
quoted verbatim where they carry a claim; tallies computed from them are
labelled *derived*.

Inputs: fork mainline `mdd/cerberus-lean` = `3ac3ff336`; merge-base
`b9aeedcb4dd438763b0eef7f95ac19e93875d7de` (2026-08-13); `upstream/master`
= `68bdc84bf` (2026-10-20). Upstream history over the range is linear
(`git log --merges b9aeedcb4..upstream/master` prints nothing). The fork
has `git rev-list --count b9aeedcb4..mdd/cerberus-lean` = `1144` commits
over the same base. Scratch: `.tmp/bump-scoping/` (conflict hunks, per-commit
diffs, declare census, scripts' outputs); the throwaway worktree
`worktrees/scoping-bump-scratch` was used for `git merge --no-commit --no-ff
upstream/master` and removed at the end.

---

## 1. Upstream commit inventory (46 commits, topological order)

Classes: **FIX** semantic fix (CI witness file where upstream added one);
**ADD** semantic addition (GNU extension / new diagnostic / elaboration
shape); **REF** refactor or API change; **RM** removal; **PARSE**
parser/CN-only; **OCAML** OCaml-tooling-only; **DOCS** docs/CI/Coq.

| # | hash | date | class | subject | witness / note |
|---|------|------|-------|---------|----------------|
| 1 | 08e941f0e | 2026-09-06 | ADD | (desugaring) add constraint violation for file scope GNU statement expression | new `Constraint` violation; genTyping/cabs_to_ail/mini_pipeline |
| 2 | 2fdc7afaf | 2026-09-06 | PARSE | (cparser) add missing semicolon after inline assembly | `c_parser.mly` + `.messages` |
| 3 | 7f5885fc7 | 2026-09-06 | PARSE | (cparser) allow extra semicolon after edecl | +1 `errors.lem` constructor |
| 4 | 766073467 | 2026-09-06 | FIX | (util) fix float multiplication | `util/cerb_floating.ml` `let mul = (+.)` → `( *. )` — closes tray **01** (filed as issues/1009) |
| 5 | 5a3a06036 | 2026-09-06 | FIX | (core_typing) add check for result type of binary expression in typecheck_pexpr | 1 line; no CI file |
| 6 | 83f9cc641 | 2026-09-06 | ADD | (frontend) allow GNU extension: `return E;` in a `void` function when `E` has type `void` (with --permissive) | permissive-gated |
| 7 | c8c085d47 | 2026-09-06 | ADD | (frontend) adding GNU extension: labels as value (statics only) | NEW constructors `CabsElabel_addressGNU` (cabs.lem), `AilElabel_addressGNU` (ailSyntax.lem), `EXT_GNUlabelAsValue` |
| 8 | 2ab256040 | 2026-09-22 | DOCS | [ci] run apt-get update before apt-get install | |
| 9 | b3e11ea33 | 2026-09-19 | REF | (frontend) moving sizeof/alignof out of the memory interface | NEW opam dep `"monomorphic" {= "2.1.0"}` (cerberus-lib.opam); `Implementation.sizeof_ty/alignof_ty`; `Mem.sizeof_ival/alignof_ival` deleted |
| 10 | 334a1563b | 2026-09-26 | REF | (frontend) adding an environment to the Elaboration monad | `elabM 'a = elab_config -> elab_state -> ('a * elab_state)`; `translate … conf …`, `desugar desug_conf …` |
| 11 | 83b1a7424 | 2026-09-27 | ADD | (elaboration) use mkTestExpression in the elaboration of AilSdo | Core shape of do-while changes (text lanes move) |
| 12 | 588672e95 | 2026-09-27 | FIX | (desugaring) fix missing implicit conversions in switch and case statements | `tests/ci/expected/0213-…expected` changed; `Mini_pipeline.eval_mode` |
| 13 | ad233f84f | 2026-09-27 | FIX | (desugaring) keeping the body of empty GNU case range statements | `tests/ci/0342-empty-range-case.c` |
| 14 | 06759464d | 2026-09-27 | OCAML | (ocaml_frontend/pp_errors) fixing typo in message for Desugar_agnosticFailure | |
| 15 | 3230aa494 | 2026-09-27 | FIX | (frontend) fixing the conversion of floating values with magnitude less than 1 to _Bool | `tests/ci/0343-subzero-floating-to-_Bool.c`; **`runtime/libcore/std.core` + `std_inner_arg_temps.core` change** — closes tray **15** |
| 16 | cee382443 | 2026-09-27 | FIX | (elaboration) giving a consistent treatment of branching on an unspecified value | new switch `SW_branching_on_unspec_is_nd` (switches.ml), `Config/elab_config.branching_on_unspec`; answers tray **33** |
| 17 | 3771dce03 | 2026-09-28 | REF | (frontend) making it so Symbol is never opened | 7 lem files; qualification only |
| 18 | 325128b52 | 2026-09-28 | DOCS | (ci) add support for testing the two calling conventions | `tests/run-ci.sh` |
| 19 | f10329b44 | 2026-09-28 | FIX | (elaboration) with 'inner_arg_temps' fixing ptr->_Bool conversions in function calls | `tests/ci/0344-ptr-to-_Bool-param.c` |
| 20 | e573fd6bf | 2026-09-28 | OCAML | (backend) making --json-batch actually always produce valid JSON | driver_ocaml/main.ml |
| 21 | 97371d8ed | 2026-09-29 | FIX | (desugaring) checking that the expression of a case is an integer constant | new constraint violation |
| 22 | 0fc82e266 | 2026-09-29 | FIX | (desugaring) adding support for casts in integer constant expressions | |
| 23 | cabe81c3b | 2026-09-29 | FIX | (elaboration) fix the elaboration of switch statements | `collect_cases_` → `collect_switch_content_aux` (measured function replaced); +1 `errors.lem` |
| 24 | f4a3a3d54 | 2026-09-18 (cd 09-30) | FIX | (frontend) making pure array_shift_ptrval properly return UB on NULL pointers | `Mem.array_shift_ptrval: Loc.t -> … -> Undefined.t pointer_value`, `memcmp loc`, `load_character_array loc`, `ND.lift_undef` — closes tray **04** (CI witness lands later in #28) |
| 25 | c3ff8c53f | 2026-09-30 | PARSE | (cparser) proper locations in array_abstract_declarator | |
| 26 | 4d3b03322 | 2026-01-15 (cd 09-30) | RM | Removing the bit rotted Symbolic memory model | deletes `defacto_memory{,_aux,_types}.lem`, `memory/symbolic/`, `pp_cmm/pp_defacto_memory/…`; `mem_aux.lem` −34, `pp.lem` −15 |
| 27 | 736690a65 | 2026-09-30 | REF | Removing the global Tags reference | `Ctype.tag_definitions`; `tagDefs` explicit parameter everywhere; `Mem.initial_mem_state tagDefs`; impl_mem stores `tagDefs` in `mem_state`; `Tags` module deleted |
| 28 | 0676e9fca | 2026-09-30 | FIX | (desugaring) checking for arrays of functions and invalid types in compound literals | `tests/ci/0120,0121 *.error.c → *.undef.c` (the tray-04 witness), expecteds for 0258/0270 |
| 29 | 2a121fb6d | 2026-10-01 | REF | (web) repairing the stepping | driver.lem +52 (`step_kind_of_core_step2`, `as_step`, `do_stepping`) |
| 30 | a09e6717b | 2026-10-03 | RM | (frontend) remove stale core_run_effect, pp_run, pp_sb | not in the fork's LEM_SRC — no Lean effect |
| 31 | cfcb31834 | 2026-10-03 | FIX | (desugaring) properly dealing with GNU statement expressions in sizeof() | 2 lines |
| 32 | 8c47748ed | 2026-10-04 | REF | (driver) only recording trace events when --trace is enabled | `record_trace_event`, `do_trace` |
| 33 | 20881fae1 | 2026-10-03 | REF | (cerb_diagnostic) adding a new module to round up all warn/error functions | `utils.lem` `error` rep → `Cerb_diagnostic.internal_error` (OCaml only) |
| 34 | 7b1003ea2 | 2026-10-03 (cd 10-17) | REF | Removing Cerb_global and replacing the config reference by params | NEW `frontend/model/config.lem` (`Config.config`, `calling_convention`, `execution_mode`); `global.lem` −52 (keeps `cerb_switch`/`has_switch`/`is_PNVI`/`is_CHERI`/`has_strict_pointer_arith`); `errorM` gains conf; `driver_state.conf`; `concurrency` threaded into core_run/core_run_aux |
| 35 | c3a438b1c | 2026-10-03 | OCAML | (backend/pipeline) cosmetic polish | pipeline.ml rewrite (−296/+252) |
| 36 | fcd99cca1 | 2026-10-04 | OCAML | (util/cerb_location) optimising is_library_location | |
| 37 | b57be1fbe | 2026-10-04 | REF | (cabs_to_ail_effect) using a set for used_identifiers | |
| 38 | fc6b20526 | 2026-10-04 | REF | (frontend) using Result.t in OCaml for the Exception monad | `declare ocaml target_rep type exceptM = \`Stdlib.result\``; many Exception helpers deleted |
| 39 | 9f23c62b3 | 2026-10-04 | REF | (frontend) rewriting the list functions of a few monads | new `let rec *_mapM_aux` in nondeterminism/state/state_exception/state_exception_undefined/exception_undefined/errorMonad; `foldrM`/`filterM`/second ND monad deleted |
| 40 | 0c374d8b4 | 2026-10-17 | FIX | (desugaring) properly ordering declarations in for loops | `tests/ci/0351-for-decl-init-order.c`; deletes `State_exception.foldrM` |
| 41 | 30a04ac47 | 2026-10-14 | PARSE | (parser) moving CN to its own lexer and parser | `c_parser.mly` −841, `cn_parser.mly` +1133, `.messages` ±17k; `errors.lem` −34 lines |
| 42 | b519931bb | 2026-10-18 | RM | Removing unused modules | `core_indet.lem`, `core_rewrite2.lem`, smt/cerbcore/interactive_driver |
| 43 | 8d1926c7f | 2026-10-18 | FIX | (core_typing) fixing PEmember_shift checks for flexible array members | `Ctype_aux.is_memberof`; answers tray **41** |
| 44 | 6dc8d2a47 | 2026-10-19 | REF | (frontend) renaming ctype Pp functions | `stringFromAil_ctype`→`stringFromCtype_human`, `stringFromAil_qualifiers`→`stringFromQualifiers`, `stringFromCore_ctype`→`stringFromCtype` |
| 45 | ee415b6a1 | 2026-10-19 | DOCS | (cheri) fixing revocation proof broken by coq-ext-lib 0.13.2 | Coq only |
| 46 | 68bdc84bf | 2026-10-20 | FIX | (desugaring) narrowing location for non-integer switch expression | diagnostic location only |

Derived tally: FIX 16 (the orchestrator's 13 + 766073467, 5a3a06036,
68bdc84bf), ADD 4, REF 12, RM 3, PARSE 4, OCAML 4 (06759464d, e573fd6bf,
c3a438b1c, fcd99cca1), DOCS 3. Sum 46. Of these, 36 touch
`frontend/model` per the orchestrator's count (not re-derived here).

Tray closures visible in this range: 01 ↔ 766073467; 04 ↔ f4a3a3d54 (+ the
0120/0121 rename in 0676e9fca); 15 ↔ 3230aa494; 33 ↔ cee382443 (upstream's
answer is a switch, default stays UB); 41 ↔ 8d1926c7f. Not fixed upstream in
this range: 10/11/13/40 (ISO register), 34, 37, 38, 44, 45, 47, 51, 52, 53,
55, 56, 57 — so every fork-ahead mirror behind those stays a fork delta.

---

## 2. Conflict map (34 files; the `git merge --no-commit --no-ff upstream/master` in the scratch worktree)

Verbatim summary line of that merge: `Automatic merge failed; fix conflicts
and then commit the result.` The 34 names equal
`.tmp/bump-conflicts.txt`. Hunk counts are *derived* (count of `<<<<<<< `
markers; "lines" = lines inside the conflict regions).

Nature: **T** textual (same region, independent edits), **S** semantic
(both sides change the same mechanism), **X** structural (signature / type /
module shape), **D** modify-vs-delete.

### Hot files

| file | hunks/lines | upstream (commits) | fork (slices) | nature | resolution sketch |
|------|-------------|--------------------|---------------|--------|-------------------|
| `frontend/model/translation.lem` | 7 / 97 | 334a1563b (elabM env), 83b1a7424, cee382443, f10329b44, cabe81c3b, 736690a65, 7b1003ea2, 6dc8d2a47, 83f9cc641, c8c085d47 | C1 supply threading (`E.fresh_elab_*`, `translate sup …`), E-A enumDefs in the Core file, D-S digest, translation fuel 2026-10-18 (`translate_expression/translate_stmt` fuel declares + kernel equations, `aa734bdce` state runners), `extra_import CerbCtypeInstances` | **S/X** | Take upstream's `collect_switch_content`/`mkTestExpression conf`/`translate_branch_on_unspec` bodies; re-express every ambient `Symbol.fresh_pretty_with_id` mint (while_/do_/case_/default_) through the fork's `E.fresh_elab_*` supply (the C1 rule: contiguous mints, list order kept); `translate` = `sup`+`conf` (fork keeps the returned supply); keep `core_enumDefs` beside `core_tagDefs`; re-add the `extra_import`; the fuel declares follow the new `elabM` type |
| `frontend/model/mini_pipeline.lem` | 7 / 163 | 334a1563b, 588672e95 (`eval_mode`, `evalIntegerConstantExpressionAux conf …`), 3771dce03, 736690a65, 2a121fb6d, 8c47748ed, 7b1003ea2 (`typecheckAil` moved OUT to cabs_to_ail.lem) | address-space top + supply threading (`evalConstantExpressionAux sup top loc …`), arc-2 S6 `run_const_expr_driver` reader_seed, E-A `_seeded` reader seeds (`evalIntegerConstantExpression_seeded`, `typecheckAil_seeded`, `annotate_expression_seeded`, `qualified_ctype_of_seeded`), D-S `initial_driver_state_given` | **S/X** (hottest) | Rebuild on upstream's `eval_mode` shape: keep `sup`/`top` as explicit parameters next to `conf` (or fold them into `Config.config` as fork-ahead fields — §3.1), keep the reader seeds but re-point `typecheckAil_seeded` at the moved `Cabs_to_ail.typecheckAil_with_ctx`; the mini-run's `conf_for_mini_driver` replaces the fork's `run_const_expr_driver` extent IF the tagDefs reader is retired (§3.2), else keep the seed |
| `frontend/model/cabs_to_ail.lem` | 6 / 94 | 08e941f0e, 83f9cc641, c8c085d47, b3e11ea33, 334a1563b, 588672e95, ad233f84f, 97371d8ed, 0fc82e266, 0676e9fca, cfcb31834, 7b1003ea2 (`typecheckAil_with_ctx`, `fail_if_agnostic`), fc6b20526, 0c374d8b4, 6dc8d2a47, 68bdc84bf | supply/top threading at the const-expr mini-run (`:1209`), E-A `annotate_expression_seeded`/`qualified_ctype_of_seeded` at sizeof/typeof/init sites, asm refusal (c8969b6ce), `_Alignas` tray-47 check (3bd1623d9), `desugar sup top …` entry | **S** | Upstream's `typecheckAil_with_ctx` arms replace the fork's four inline `Mini_pipeline.*_seeded` call sites — keep the seeds INSIDE `typecheckAil_with_ctx` (one seeded helper instead of four); `desugar sup top conf …`; re-apply asm/alignas refusals on upstream's text; adopt `E.read_config` where the fork read `Global.*` |
| `frontend/model/cabs_to_ail_effect.lem` | 5 / 105 | 08e941f0e, c8c085d47, b3e11ea33 (`alignof_ty` via `Implementation.alignof_ty tagDefs`), 334a1563b, 588672e95, 7b1003ea2 (`desug_config` → `Config.config`, `with_record_marker` replaces `Global.backend_name () = "Cn"`), b57be1fbe, 9f23c62b3, 0c374d8b4, 6dc8d2a47 | C1 supply field + `get/set_fresh_sym_supply`, address-space top in the desugar state, E-A `alignof_ty_seeded`/`are_compatible_seeded`/`make_composite*_seeded`, `fresh_sym_int` supply draw at `:692` | **S/X** | State record = upstream's + `fresh_sym_supply` + `address_space_top`; `eval sup top conf …`; `:692` keeps the supply draw and reads `conf.with_record_marker`; `get_alignof` → upstream's `Implementation.alignof_ty tagDefs` with the fork's enum reader seed (`alignof_ty_seeded` re-targeted) |
| `frontend/model/translation_effect.lem` | 5 / 48 | 334a1563b (`elabM` = `conf -> st -> …`, `elab_initial_state`, `runElabM`), cee382443, 7b1003ea2 | C1 `elab_init sup callconv` with `fresh_supply`/`calling_convention` in `elab_state`, supply-threaded `with_block_objects`/`fresh_elab_int` marker | **X** | Adopt upstream's reader+state `elabM`; `elab_state` keeps `fresh_supply` (drop `calling_convention` — now `conf.calling_convention`); `elab_initial_state sup`; the C1 mints become `elab_update`-style state draws; lem-lean must accept the function-typed monad with `fun conf st ->` lambdas (it already does for `stateM`) |
| `frontend/model/mem.lem` | 2 / 39 | b3e11ea33 (`sizeof_ival/alignof_ival` deleted), f4a3a3d54 (`array_shift_ptrval` + `memcmp` loc/UB), 736690a65 (`initial_mem_state tagDefs`, `prefix_of_pointer tagDefs`, `offsetof_ival: Ctype.tag_definitions`) | `initial_mem_state top` (address-space bound), the 19 `fuel_consumer`/`reader_consumer` declares, Lean reps to CerbMem | **X** | `initial_mem_state tagDefs top` (both parameters); keep the fuel/reader declares on the surviving vals; delete the `sizeof_ival/alignof_ival` declares and move their CerbMem reps behind `Implementation.sizeof_ty/alignof_ty` (§3.3); `array_shift_ptrval loc …: Undefined.t` (§3.4) |
| `frontend/model/global.lem` | 2 / 70 | 7b1003ea2 (execution_mode / backend_name / using_concurrency / isDefacto / isPermissive / isAgnostic / isIgnoreBitfields DELETED; `cerb_switch` + the four switch reads KEPT) | the Lean reps for exactly those deleted vals (`CerbGlobal.*`), `has_switch` Lean rep | **X** | Delete the fork's Lean reps with the vals (they become `Config.config` fields — CerbGlobal keeps `defaultConfig` with its `rfl` pins, §3.1); keep `declare lean target_rep function has_switch = \`CerbGlobal.has_switch\`` and `lean_switches.lem` untouched (upstream still reads switches ambiently) |
| `frontend/model/implementation.lem` | 1 / 135 | b3e11ea33 + 736690a65 (`sizeof_ty/alignof_ty: Ctype.tag_definitions -> ctype -> integer`, OCaml reps `Ocaml_implementation.sizeof/alignof`; the fork-era `alignof_ty … -> maybe nat` with `alignof_proxy` deleted) | E-A enum reader block (`enum_definitions` reader, `register_enum`, `typeof_enum`, `normalise_integerType` reader_consumer, the `*_norm` wrappers, `alignof_ty` reader_consumer) | **S/X** | Keep the whole E-A block (upstream has no enum-as-data equivalent); add upstream's two vals with Lean reps `CerberusImpl.sizeof_ty/alignof_ty` implemented over `CerbMem.sizeofCtype/alignofCtype` (§3.3); the OCaml side follows upstream (the fork's `alignof_proxy` disappears from `ocaml_implementation.mli`) |
| `frontend/model/ctype_aux.lem` | 2 / 62 | 736690a65 (`tagDefs`/`set_tagDefs`/`with_tagDefs` deleted; `get_membersDefs tagDefs`, `get_structDef tagDefs`), 8d1926c7f (`is_memberof`) | the `tagDefs` reader declare + `tagDefsUnreachable` rep, `with_tagDefs` Lean body, tray-37 `are_compatible_aux` accumulator `(tagDefs, tagDefs, [])` + its measure, `extra_import CerbTags/CerbCtypeMeasure` | **X** | §3.2 decides: retire the reader (adopt upstream's explicit parameter) → the declare block goes, `are_compatible_aux` keeps the fork's triple with upstream's pair form inside; `extra_import CerbCtypeMeasure` stays |
| `frontend/model/driver.lem` | 2 / 19 | b3e11ea33 (`prepare_main_args … alignof_ival …`), f4a3a3d54, 736690a65 (`initial_mem_state file.tagDefs`), 2a121fb6d, 8c47748ed, 7b1003ea2 (`initial_driver_state file fs_state conf`, `driver_state.conf`, `read_config`) | `initial_driver_state_with top run_st …`, `initial_driver_state top digest …`, `_given sup top digest …` (D-S), fuel declares on `driver2/hack/…`, `fuel_hypotheses` cites by line | **X** | `initial_driver_state[_given] [sup] top digest conf file fs` — or `conf` absorbs `top` (§3.1); `conf` lives in `driver_state` as upstream (beside the fork's digest); re-cite `fuel_hypotheses.txt` lines (prepare_exit etc. move) |
| `frontend/model/formatted.lem` | 1 / 16 | f4a3a3d54 (`load_character_array loc …`), 736690a65, 6dc8d2a47 | fuel declare + absorbing payload on `load_character_array_aux` (C2) | **T/X** | keep the declare, add `loc` to the wrapper (payload unchanged) |
| `frontend/model/core_typing.lem` | 1 / 8 | cabe81c3b, 736690a65, 7b1003ea2, 8d1926c7f (`ArityMismatchRun`), 5a3a06036, 6dc8d2a47 | audit-R3 `Erun` arity guard (`MismatchExpected "run" …`), match-pattern arity guards, E-A | **S** | adopt upstream's `ArityMismatchRun` (the fork's R3 guard for `run` is superseded; Main.lean's error printer gains the arm); keep the tuple-arity guards (tray 45 unfixed) |
| `frontend/model/core.lem` | 1 / 12 | 736690a65 (`tagDefs: Ctype.tag_definitions`), 7b1003ea2 (`callconv: Config.calling_convention`, `calling_convention` type moved to config.lem) | E-A `enumDefs` field, fuel declares | **X** | Core file = `main; callconv; tagDefs; enumDefs; …` — the field rename is consumer-visible (§8) |
| `frontend/model/core_aux.lem` | 1 / 14 | 736690a65 (`zeros: Ctype.tag_definitions`, `memValueFromValue tagDefs`), 7b1003ea2, 6dc8d2a47 | `zeros_aux` fuel declare comment block, C2 measures | **T** | keep the declares; `memValueFromValue` gains a parameter (§5) |
| `frontend/model/pp.lem` | 3 / 47 | 4d3b03322 (`stringFromCmm_op_symState`, `stringFromMem_iv_mem_constraint` deleted), 6dc8d2a47 (renames) | Lean reps for every pp val (`CerbPP.*`) | **T/X** | rename the CerbPP defs with upstream, delete the two orphaned reps |
| `frontend/model/state.lem`, `state_exception.lem` | 1 / 14, 1 / 16 | 9f23c62b3 (`foldlM`→`state_foldlM` with `let inline`, `foldrM` deleted; `stExpect_*`→`stExcept_*`), 0c374d8b4 | `termination_argument` declares on `foldlM/foldrM`, `stExcept_foldlM/foldrM` | **T** | rename the declares to the new workers, drop the deleted ones, ADD declares for the new `*_mapM_aux`/`*_mapM_` recursions (§4) |
| `memory/concrete/impl_mem.ml` | 3 / 50 | 9f23c62b3, 736690a65 (`initial_mem_state tagDefs`, `get_tagDefs`, `sizeof ~tagDefs`), f4a3a3d54, b3e11ea33 (−194 lines: layout moved to ocaml_implementation.ml) | address-space top (`initial_mem_state address_space_top`), SC WP0 receipts (`begin_observing`/`record_access`), allocator remedy 1 (tray 44), item G refusals (memcpy overlap, alignment), `--batch-alloc-census` | **S** | `initial_mem_state tagDefs address_space_top`; keep receipts/remedy/refusals on upstream's text; the layout functions the fork mirrored into CerbMem now live in `ocaml_implementation.ml` (CerbMem cites move) |
| `backend/driver/main.ml` | 3 / 66 | e573fd6bf, 334a1563b, 736690a65, 2a121fb6d, 20881fae1, 7b1003ea2 (`Cerb_diagnostic.init`, `cli_conf`, `interp_backend ~conf`), fc6b20526 (`Result.ok`) | `--cabs-json` (parse+serialize exporter + digest field), `--address-space-top`, `--batch-alloc-census`, `Tags.reset/set` lines, `driver_conf` record | **S** | rebuild the fork-only flags on upstream's `Config`-building driver: `address_space_top` into the fork's config extension; the cabs-json arm returns `Result.ok`; drop the `Tags.*` lines with the module |
| `backend/common/pipeline.ml` | 3 / 97 | 334a1563b, cee382443, 736690a65, 20881fae1, 7b1003ea2, c3a438b1c (rewrite), fc6b20526, b519931bb | arc-13 `Ail_sym_hwm` window check hook, `desugar 0 conf.address_space_top …`, `translate 0 …` dead-supply shims, `Tags.reset_tagDefs`, `enumDefs= Pmap.empty` in `read_core_object` | **S** | re-insert the window check after upstream's `let* markers_env, ail_prog = …`; `Cabs_to_ail.desugar 0 top conf …`; keep `enumDefs=` in the `.co` assembly |
| `backend/common/driver_ocaml.ml/.mli` | 3 / 42, 2 / 22 | fc6b20526, 7b1003ea2 (`driver_conf` deleted → `Config.config`), 8c47748ed, 2a121fb6d, e573fd6bf | `driver_conf.address_space_top`, `address_space_top_default` (THE ONE OCaml numeral), `Cerb_fresh.digest ()` into `initial_driver_state`, alloc-census output | **X** | keep `address_space_top_default` here; `initial_driver_state top (digest ()) file fs conf`; batch output keeps the fork's census triple |

### The rest

| file | hunks/lines | upstream | fork | nature | sketch |
|------|-------------|----------|------|--------|--------|
| `backend/bmc/bmc_utils.ml` | 1 / 6 | 7b1003ea2, 736690a65 | address-space top (not ladder-built) | T | `initial_mem_state tagDefs address_space_top_default` |
| `backend/web/instance.ml` | 1 / 6 | 334a1563b, 736690a65, 2a121fb6d, 8c47748ed, 7b1003ea2, fc6b20526 | top + digest (not ladder-built) | T | mechanical |
| `backend/common/pipeline.mli` | 1 / 7 | 334a1563b, 7b1003ea2, fc6b20526 | `driver_conf` + census triple in `interp_backend` | X | follow §3.1 |
| `frontend/model/core_rewrite2.lem` | D | b519931bb deletes | E-A touched it once (3ad477462) | D | delete (fork's edit was mechanical) |
| `frontend/model/defacto_memory{,_aux,_types}.lem` | D ×3 | 4d3b03322 deletes | arc-3 totalization, C1/C2 fuel declares + measures (9 obligations), the fuel-kill mechanism | D | delete with upstream (§3.9): drop `LEM_DEFACTO` entries, lakefile roots (6), `Defacto_memory{,_aux}_lemMeasureProofs.lean` (369 lines), `CerbND`/`CerbMeasureLemmas`/`TotalityProofTest` imports, the exec-totality/purity/axiom-census lists |
| `memory/symbolic/impl_mem.ml` | D | 4d3b03322 deletes | receipts + top + census (mechanical mirrors) | D | delete; the fork's `[source-content]` pin row goes |
| `memory/cheri-coq/impl_mem.ml`, `memory/vip/impl_mem.ml` | 1 / 7, 2 / 15 | f4a3a3d54, cee382443, 736690a65, 9f23c62b3, b3e11ea33 | top, receipts, remedy 1 (vip) | S | `initial_mem_state tagDefs top`; vip stores `tagDefs` AND the parametric `last_address` |
| `ocaml_frontend/memory_model.ml` | 1 / 7 | b3e11ea33, f4a3a3d54, 4d3b03322, 736690a65 | `val initial_mem_state: Z.t -> mem_state` | X | `Ctype.tag_definitions -> Z.t -> mem_state` |
| `ocaml_frontend/ocaml_implementation.mli` | 1 / 13 | b3e11ea33 (`offsetsof/sizeof/alignof` exported; `alignof_proxy` gone) | E-A `enum_definitions` + `alignof_proxy` | X | keep `enum_definitions`, drop `alignof_proxy` |

Auto-merged but load-bearing (no conflict markers, must still be reviewed):
`nondeterminism.lem` (upstream deleted the second ND monad and `import Global`;
the fork's `nd_bind/liftND/liftAction` fuel declares survive textually),
`translation_aux.lem` (`combine_params_args conf`, `ctype_of conf`),
`utils.lem` (`error` rep: OCaml only), `ocaml_frontend/dune`,
`parsers/c/c_parser.mly` (the fork's asm-refusal edit c8969b6ce on a grammar
30a04ac47 rewrote — the `.messages` file must be regenerated),
`runtime/libcore/std.core` + `std_inner_arg_temps.core` (3230aa494),
`ocaml_frontend/switches.ml` (new switch; `prerr_endline` → `warn`),
`ocaml_frontend/rewriters/core_peval.ml`, `remove_unspecs.ml`.

---

## 3. Seam interactions — each with a proposal

### 3.1 `Cerb_global` removal (7b1003ea2) vs `lean_switches.lem` / `CerbGlobal`

What upstream did: `Config.config` (config.lem, 25 fields: agnostic,
permissive, ignore_bitfields, three GNU-allow flags, `calling_convention`,
`is_PNVI`, `is_CHERI`, `is_CN`, `with_record_marker`, `strict_pointer_arith`,
`branching_on_unspec`, `no_seq_rmw`, `execution_mode: maybe …`, concurrency,
do_stepping, do_tracing, fs_dump) is passed as data: a parameter of
`desugar`/`translate`/`initial_driver_state`, a reader component of `elabM`
and `errorM`, a field of `driver_state` (`read_config = ND.get >>= st.conf`).
`global.lem` KEEPS the ambient switch reads (`has_switch`, `is_PNVI`,
`is_CHERI`, `has_strict_pointer_arith` → `Switches.*`), so upstream now has
two overlapping sources for `is_PNVI`/`strict_pointer_arith` (the config
field and the ambient switch).

Fork today: the deleted vals are `CerbGlobal` plain `def`s with `rfl` pins
(2026-09-05) — not process state — and the switch set is the instance reader
`[CerbGlobal.Switches]` (PNVI S1), consumed by `Global.has_switch/is_PNVI/
has_strict_pointer_arith` and 17 `Mem.*` vals.

Proposal [AGENT]: **take upstream's parameter; keep the instance reader.**
- `Config.config` becomes the one run-configuration carrier (lem data, as
  the address-space top and the digest already are). The fork adds two
  fork-ahead fields — `address_space_top: integer` and (optionally) the run
  digest — so `desugar`, `initial_driver_state*`, `translate` take `conf`
  instead of `top` (the supply parameter stays separate: it is state, not
  configuration). The alternative (keep `top` as its own parameter next to
  `conf`) costs nothing technically; it is a question of one signature or
  two (open question Q4).
- `CerbGlobal` keeps `defaultConfig : Config.config` (the matched-mode values
  the deleted `def`s pinned, each with a `rfl` lemma), the `CerbSwitch`
  type, and `class Switches`. `Main.lean` builds the `Config.config` from
  `--switches`/`--address-space-top`/`--fuel` as it builds the instances
  today.
- The instance reader is NOT folded into `Config.config`: upstream's own
  model still reads switches ambiently, so `lean_switches.lem` stays
  byte-for-byte (its record §3 invariant — generated OCaml unchanged — holds
  because upstream's `global.lem` keeps the four vals). The duplicated
  `conf.is_PNVI`/`conf.strict_pointer_arith` fields are pinned equal to the
  instance's reads by a `rfl`/`simp` lemma in `CerbGlobal` for the default
  instance and checked at `Main` construction (one place builds both) —
  the `check_no_fuel_numerals.sh` W1 speedbump extends to "no second
  `Config.config` literal outside Main".
- Cost centre: every `fun st ->` in `translation_effect.lem` gains `conf`;
  `errorM`'s `run` gains `conf` (consumer-visible, §8); core_run/core_run_aux
  take `concurrency: bool` explicitly (measure signatures, §5).

### 3.2 Tags global removal (736690a65) vs the `CerbTags` reader

Upstream: `Ctype.tag_definitions` (new type abbrev), `tagDefs` an explicit
parameter of `Ctype_aux.get_membersDefs/get_structDef/get_unionDef`,
`Core_aux.zeros/memValueFromValue`, `Core_reduction.step_action`,
`Core_unstruct.*`, `Mem.initial_mem_state/prefix_of_pointer/offsetof_ival`,
`Implementation.sizeof_ty/alignof_ty`; `impl_mem.ml` stores `tagDefs` in
`mem_state` (`get_tagDefs = read (fun st -> st.tagDefs)`); the `Tags` module
and `with_tagDefs` are deleted.

Fork: Lean-side `tagDefs` is an ambient READER (`declare {lean} reader val
tagDefs`, every transitive reader takes `_lemReader_tagDefs` first; the
hand-written CerbMem receives it via `reader_consumer`; `with_tagDefs` is
the plain application on Lean; `run_const_expr_driver` is a `reader_seed`).
The OCaml oracle kept its mutable `Tags`.

Proposal [AGENT]: **retire the `tagDefs` reader; adopt upstream's explicit
parameter** (mirror-OCaml doctrine: the divergence was a fork-side stand-in
for exactly this upstream change). Concretely: delete the reader/consumer
declares for `tagDefs` (ctype_aux.lem, the 17 `reader_consumer val Mem.*`
rows that exist only for tagDefs — the `enum_definitions` reader STAYS, so
the `reader_consumer` declares whose only purpose is the enum map remain),
CerbMem's `(tagDefs : TagDefs)` becomes the lem-threaded parameter at the
same position (textually the same Lean signature: the reader lifting already
put it first — the generated call sites change from injected to explicit),
`CerbTags.tagDefsUnreachable` goes, `run_const_expr_driver` becomes
upstream's inline `conf_for_mini_driver` block (the seed's only remaining
job, the enum map, moves to the `_seeded` helper that survives).
`CerbMem.MemState` gains `tagDefs` as upstream's `mem_state` does?
**No** — proposal: keep the Lean memory model's `tagDefs` as a function
parameter (it already is), do not duplicate it into `MemState`; the
divergence is documented in-code (one line) since upstream's state field is
a convenience for the OCaml functor, not semantics. Open question Q3.
The seven CerbMem obligations under `CerbTagsWf.AcyclicPair ambient tagDefs`
collapse to the one-map form (the "ambient" map was the OCaml global the
fork mirrored — it disappears with `Tags`): `offsetsof_lemFuel`'s two-map
signature becomes one map; `fuel_hypotheses.txt` rows re-stated (§5).

### 3.3 sizeof/alignof out of the memory interface (b3e11ea33) vs `CerberusImpl`/`CerbMem`

Upstream: `Implementation.sizeof_ty/alignof_ty : tag_definitions -> ctype ->
integer` with OCaml reps `Ocaml_implementation.sizeof/alignof` (+ `offsetsof`
exported); `Mem.sizeof_ival/alignof_ival` deleted; callers (`core_eval`,
`cabs_to_ail_effect.get_alignof`, `driver.prepare_main_args`) take the
layout function or call `Implementation.*`; new opam dep `monomorphic 2.1.0`.

Fork: layout lives in `CerbMem.sizeofCtype/alignofCtype/offsetsof` (fuel'd,
measured under `Acyclic`), reached through the mem.lem reps `sizeofIval/
alignofIval`; `CerberusImpl.alignof_ty` is the desugarer's `_Alignas` check
over a pseudo-tagDefs map (reader_consumer); the E-A enum reader normalises
integer types first.

Proposal [AGENT]: Lean reps `declare lean target_rep function sizeof_ty =
\`CerberusImpl.sizeof_ty\`` / `alignof_ty` implemented as `fun enumDefs tagDefs
ty => (CerbMem.sizeofCtype enumDefs tagDefs ty : Int)` (keep `fuel_consumer`
+ the enum `reader_consumer` on them); delete `CerbMem.sizeofIval/alignofIval`
with the vals; `CerberusImpl.alignof_ty`'s pseudo-map form goes (upstream
now passes the real `tagDefs`, which is what the fork's `_Alignas`
completeness check (3bd1623d9, tray 47) wants anyway — re-check that the
refusal still fires: `alignof_ty` on an incomplete type must stay a loud
refusal, not `0`). `CerbMem`'s header cites of `impl_mem.ml:173/:255`
(offsetsof/alignof) move to `ocaml_implementation.ml`. **Prerequisite**:
`monomorphic` is NOT in the fork's switch (`ls _opam/lib/monomorphic*`
→ `no matches found`) — an operator-run `opam install monomorphic.2.1.0`
(network) before any stage builds.

### 3.4 `array_shift_ptrval` in the UB monad with a loc (f4a3a3d54) vs CerbMem

Upstream: `val array_shift_ptrval: Loc.t -> pointer_value -> ctype ->
integer_value -> Undefined.t pointer_value`; `memcmp loc …`;
`load_character_array[_aux] loc …`; `ND.lift_undef`; the concrete model's
null arm returns `Undef loc [UB…]` instead of `failwith`.

Fork: `CerbMem.arrayShiftPtrval [LemFuel] enumDefs tagDefs pv elemTy iv :
PointerValue` mirrors the pre-fix `failwith` on null (tray 04 is a fork
report, not a fork fix) and carries the PNVI S3 refusal arm R-PNVI-06
(`Prov_symbolic` → `failwithI (pnviRefusal …)`); `effArrayShiftPtrval`
(memM, loc) is separate and unchanged upstream apart from `tagDefs`.

Proposal [AGENT]: change the rep's type to `… (loc : Loc) … : Undefined.t
PointerValue`; the null arm becomes `.Undef loc [UB…]` exactly as upstream;
R-PNVI-06 stays a `failwithI` INSIDE the `Undefined.t`-returning body (a
refusal is not a UB verdict; the register row's text keeps its cite with the
new impl_mem.ml line); `memcmpM` gains `loc` (the fork's item-G overlap
refusal in `memcpyM` is unaffected); `Formatted.load_character_array_aux`'s
absorbing fuel declare keeps its payload (signature-only change, §5). The
pnvi lane (row 14) baseline rows that pin an oracle crash on
`array_shift_ptrval` (tray 53, `R-PNVI-06 ORACLE_CRASH`) are re-classified
only if upstream's symbolic arm changed — it did not (53 stays open).
`tests/ci/0120,0121` move from `.error.c`/`CERB_SKIP` to `.undef.c` rows.

### 3.5 Elaboration-monad environment (334a1563b) vs the translation-fuel wrappers and `Mini_pipeline`

Upstream: `elabM 'a = elab_config -> elab_state -> ('a * elab_state)` (later
`Config.config -> …`), `elab_return/bind/mapM/foldlM/update/read_config`,
`runElabM conf m st`; `Mini_pipeline` runs `TranslateEff.runElabM conf
(toCore a_expr) elab_initial_state`.

Fork: `elabM 'a = stateM 'a elab_state` with `fresh_supply`/`calling_convention`
in the state (C1), `E.runStateM_errors`, and the 2026-10-18 translation
fuel: `translate_expression`/`translate_stmt` are `declare {lean} fuel`
(absorbing) with kernel fuel equations and the state runners refusing
exhaustion (`aa734bdce`).

Proposal [AGENT]: adopt upstream's function-typed monad; the fuel wrappers'
generated types follow mechanically (`… → Config.config → elab_state →
(expr × elab_state)`); the absorbing payload `_zero` statements are
regenerated by lem (the C2 mechanism) — `TranslationFuelTest`'s kernel
equations are restated over the new binder list (no new proof idea). The
supply stays in `elab_state` (upstream mints ambiently — `Symbol.fresh_*` —
where the fork threads; every upstream `let sym = Symbol.fresh_pretty_with_id
…` in translation.lem is re-expressed as `E.fresh_elab_pretty_with_id … >>=`,
the C1 rule). `Mini_pipeline`'s run point: `runElabM conf (toCore a_expr)
(elab_initial_state sup)`; the final supply is read back as today.
The new recursions `elab_mapM_aux`/`elab_foldlM_aux` need
`termination_argument = automatic` (§4).

### 3.6 `Symbol` never opened (3771dce03) vs generated-Lean naming / consumer imports

Seven lem files switch `open import Symbol` to `import Symbol` and qualify
`Symbol.sym`, `Symbol.identifier`, `Symbol.Symbol`, `Symbol.SD_Id`.
Generated Lean declaration names do not change (lem's Lean backend names by
module + definition, not by open); only the generated references change.
Consumer: no API effect (cerberus-caesium uses `Symbol.show_symbol`, `Loc.*`,
field names — unchanged). Residual risk: lem-lean's renamer may pick a
different disambiguation suffix where a now-qualified name clashed before —
visible only at generation; the `tests/comprehensive` cross-module tests
(`test_cross_module*.lem`, `test_name_capture.lem`) cover the construct.
Proposal: no seam change; diff the generated tree's declaration-name set
before/after as a one-off check.

### 3.7 `Result.t` for the Exception monad (fc6b20526) and the monad list rewrite (9f23c62b3) vs lem target reps and lem-lean

fc6b20526 adds `declare ocaml target_rep type exceptM = \`Stdlib.result\`` +
reps for `Result`/`Exception`/`return`/`bind`/`fail` and DELETES many
Exception helpers (`except_sequence`, `listM`, `guard`, `onException`,
`trysM`, `sequence_map`, `map_map`, `inj_right`, `compare`, `rbind*`, `app`
… — kept: `except_fmap`, `app`, `except_mapM` (now `_aux`), `except_foldlM`).
The fork's `exception.lem` has NO Lean declares (`grep 'declare (lean|{lean})'`
→ nothing) and Lean keeps `inductive exceptM`; the OCaml rep is OCaml-only.
Nothing for lem-lean here; the fork's hand-written Lean uses of deleted
helpers must be checked at build (`grep` for `Exception.except_sequence`
etc. in `lean_frontend/*.lean` is the first step of the slice).

9f23c62b3: deletes the second ND monad block in `nondeterminism.lem`
(`nd_action`, the `ndM 'a 'err 'cs 'st` family — dead code), rewrites
`mapM/mapM_/foldlM` of ND/State/State_exception/State_exception_undefined/
Exception_undefined/ErrorMonad as accumulator recursions
(`*_mapM_aux f acc = function …`, `let rec *_mapM_`), deletes `foldrM`
(state, state_exception), `filterM`, `replicateM`, `sequence` variants.
Fork impact: (a) the `termination_argument = automatic` declares on
`State.foldlM/foldrM`, `State_exception.stExcept_foldlM/foldrM`,
`State_exception_undefined.stExceptUndef_foldM/filterM`, `ND.nd_foldlM`
must be renamed/dropped (`foldlM` → `state_foldlM`, `stExceptUndef_foldM` →
`stExceptUndef_foldlM`); (b) **every new `let rec` defaults to `partial def`
in lem-lean** (DESIGN.md:50 "Recursive functions default to `partial def`"),
and `State`, `State_exception`, `State_exception_undefined`, `Nondeterminism`
are in the exec-totality gate's 22-module list with an EMPTY allowlist →
the gate goes RED unless ~15 `termination_argument = automatic` declares are
added (list-structural; Lean accepts them): `nd_mapM_aux`, `nd_mapM_`,
`state_mapM_aux`, `state_mapM_`, `state_foldlM`, `stExcept_mapM_aux`,
`stExcept_mapM_`, `stExceptUndef_mapM_aux`, `stExceptUndef_foldlM`,
`exception_undef_mapM_aux`, `ailErr_mapM_aux`, `ailErr_mapM_`,
`except_mapM_aux`, `elab_mapM_aux`, `elab_foldlM_aux` (the last three are
outside the 22 but `check_exec_purity`/consumer hygiene want them total too).
(c) The fork's `CerbND` wrappers over `nd_bind/liftND/liftAction` are
untouched (`liftND` body hunk is a `Global` import removal, not a change).

### 3.8 Removals (4d3b03322, b519931bb, a09e6717b) vs LEM_SRC, the exec-totality list, the failure-reach register

- 4d3b03322: `LEM_DEFACTO = mem_common.lem mem.lem mem_aux.lem` (upstream's
  Makefile). Fork artefacts to delete: `Defacto_memory{,_aux,_types}.lean`
  + 3 `_auxiliary` shells (9 obligations: `has_concurRead`, `find_array_index`,
  `easy_update_mem_value_aux`, `memcmp_load_aux`, `tmp_{compl,AND,OR,XOR}_aux`,
  `fake_mem_value_eq`), `Defacto_memory_lemMeasureProofs.lean` (162 lines) +
  `Defacto_memory_aux_lemMeasureProofs.lean` (207), lakefile roots ×6,
  `handwritten_copy.manifest` ×2, `check_exec_totality.sh` list (22 → 20),
  `check_exec_purity.sh` list, `check_theorem_axioms.sh` (the
  `fake_mem_value_eq_measure_sufficient` cone + the
  `import Defacto_memory_aux_auxiliary` probe), `CerbND.lean` `import
  Defacto_memory` (comment-only use — the three `_zero` names it cites are
  Defacto's), `CerbMeasureLemmas.lean` `import Defacto_memory_types` + its
  "list of integer values" section, `test/Unit/TotalityProofTest.lean`
  (imports + `mkUnspec`/`simplify_integer_value_base`/`fake_mem_value_eq`
  witnesses), `CerbFloat.lean` comment cites. Failure-reach register: ZERO
  rows name `Defacto_memory` (derived: `awk` over the 240 rows) — nothing to
  retire there. Fork-drift: `defacto_memory_types.ml` leaves
  `[expected-cosmetic]`; `memory/symbolic/impl_mem.ml` leaves `[files]`.
- b519931bb: `core_indet.lem` leaves `LEM_CORE_TO_CORE`; `Core_indet(_auxiliary)`
  lakefile roots go; `check_theorem_axioms.sh:78` comment; `core_rewrite2.ml`
  leaves `[files]`/`[source-content]`.
- a09e6717b: `core_run_effect.lem` is not in the fork's LEM lists → no
  Lean effect; `pp_run.ml`/`pp_sb.ml` are OCaml-only.
- Also `pp.lem` −15 (two reps orphaned, §2) and `mem_aux.lem` −34 (stays in
  LEM_DEFACTO; `Mem_aux` stays in the totality list).

### 3.9 Trace events (8c47748ed) vs the driver/trace lanes

Upstream records `trace_event`s only when `conf.do_tracing`
(`record_trace_event mk_event`). The fork's lanes do not consume the driver
trace (`test_memory_access.py` uses the SC WP0 receipts, not `trace`); the
Lean driver has no `--trace`. Proposal: mirror (the fork's `Config.config`
sets `do_tracing = false` by default; the `trace` field stays). Expected
baseline movement: none (verdicts unchanged); the exhaustive-mode step
counts are unaffected. 2a121fb6d (`as_step do_stepping`, `step_kind`) is
likewise neutral at `do_stepping = false`; `driver2`'s body changes shape →
the `fuel_hypotheses.txt` cites for `hack`/`to_pure` (driver.lem:1309-1316,
:1331-1338, :1352-1356, :1473-1477, :1611-1616) must be re-pointed.

### 3.10 `cerb_diagnostic` (20881fae1) vs Main.lean's error-printing mirrors

OCaml-only: `Cerb_debug.error`/`warn` move to `Cerb_diagnostic.internal_error/
fatal/warn`; `utils.lem`'s `error` OCaml rep changes, its Lean rep
(`failwith`) does not; `switches.ml` warnings go through `warn ~always:true`
(same text). Main.lean mirrors `Pp_errors` text (pp_errors.ml:499-509 etc.),
not `Cerb_debug`, so the only movement is where pp_errors itself changed:
new arms for `ArityMismatchRun` (8d1926c7f), the two new constraint
violations (08e941f0e, 97371d8ed), the new `errors.lem` constructors
(7f5885fc7, cabe81c3b, c8c085d47), the CN parser errors REMOVED from
`errors.lem` (30a04ac47, −34 lines → Main's/`AilToCaesium`'s
`stringOfDesugarCause`-style printers lose arms), and 06759464d's typo fix
(byte-exact diagnostic lanes: `test_batch_diagnostics.py`). Proposal: re-mirror
pp_errors.ml per arm with fresh file:line cites; no structural change.

---

## 4. lem-lean backend needs

Scan of the ADDED lines of `git diff b9aeedcb4 upstream/master -- frontend/model
frontend/concurrency` (12617-line diff; `.tmp/bump-scoping/diffs/model-all.diff`):

Library functions newly used (counts of added-line occurrences, derived):
`List.reverse` 11, `Map.insert` 10, `List.length` 5, `Map.empty` 4,
`Set.member` 3, `Set.map` 3, `Map.lookup` 3, `List.map` 3, `List.foldl` 2,
`Set.insert` 1, `Set.empty` 1, `Map_extra.toList` 1, `Map_extra.fold` 1,
`List.splitAt` 1, `List.lookup` 1, `List.filter` 1, `Result.ok/error/bind`
(OCaml reps only). Every one of these is ALREADY used by the fork's lem at
`mdd/cerberus-lean` and builds (files using them, derived: `Set.map` 3,
`List.lookup` 14, `Map_extra.fold` 8, `List.splitAt` 4, `Map_extra.toList`
5, `Set.member` 1, `List.reverse` 16) — no new library surface.

Declaration forms newly used: `instance (Eq calling_convention)` (config.lem
— `unsafe_structural_equality`, the fork's `skip_instances`/derived-BEq path
handles it as for `core.lem`'s former instance); `module Operators = struct`
(mini_pipeline.lem/state.lem inline operators — pre-existing form);
record update `<| conf with … |>` on the new `Config.config` (covered:
`tests/comprehensive/test_records.lem`, `test_cerberus_patterns.lem`,
`test_cmp_threading.lem`); function-typed monads with `fun conf st ->`
(`elabM`, `errorM (fun conf ts -> …)`) — the `stateM` form already compiles;
`let rec … = function` accumulator recursions (termination declares, §3.7).
No `indreln`, no new `declare lean`, no measure/termination annotations
upstream (upstream has none).

Possible backend touch points (cannot be confirmed read-only; first-build
findings):
1. **Default `partial def` for undeclared recursion** — not a backend change,
   a declare obligation (§3.7 list of ~15).
2. The renamer on `Symbol`-qualified references after 3771dce03 (§3.6) —
   `tests/comprehensive/test_cross_module*.lem`, `test_name_capture.lem`,
   `test_scope_shadowing.lem` cover qualified-vs-open references.
3. `Config.config` is a 25-field record with a `maybe execution_mode` field
   and an `Eq` instance on a sub-type — `test_records.lem`/`test_instances.lem`
   cover; the instance-priority lattice applies (`test_instance_priority.lem`).
4. The fuel-measure validator on `elabM`-typed workers whose type is now a
   function type (the `translate_*` absorbing declares): `test_fuel_param.lem`
   / `test_fuel_measure_types.lem` cover fuel'd workers over function types
   only indirectly — if the validator rejects the shape, it is a lem-lean
   slice (re-pin dance), not a cerberus one.
5. `exception.lem` now declares an OCaml rep for a lem TYPE (`exceptM =
   Stdlib.result`) while Lean keeps the inductive: lem's target-coverage
   check is per target; the fork's `-cerberus_pp -ocaml` run and the `-lean`
   run are separate invocations, so no cross-target conflict is expected.
Verdict: no lem-lean change is known to be required; budget 0.5 day of
contingency in stage 1 and 1 day in stage 2 for first-build findings.

---

## 5. Measure-proof churn

Fork declares (derived from `grep` over `frontend/model/**/*.lem`): 57
`fuel_measure`, 74 `fuel`, 73 `termination_argument`, 19 `fuel_consumer`,
42 `reader_consumer`, 10 `reader_seed`, 3 `reader`, 1 `supply`; 57 generated
`*_measure_sufficient` obligations across 15 `_auxiliary.lean` shells (the
record's "38" is the C2-era count; today's tree has 57 — derived from
`grep -oE '… _measure_sufficient' lean_frontend/generated/*_auxiliary.lean`).

Signature comparison of every fuel/measure/termination-declared function
that exists at the merge-base, `b9aeedcb4` vs `upstream/master` (script over
`git show`; output in the scoping transcript):

| function (file) | declares | upstream change | effort (C2 template: strong induction on the size bound, `key`/`size_lt`, `split`, `to_congr`) |
|---|---|---|---|
| `collect_cases_` (translation.lem) | fuel_measure `lemSize stmt` | **deleted; replaced by `collect_switch_content_aux`** (cabe81c3b) — same recursion over `A.statement`, richer state | new obligation, same shape as the old proof (Translation_lemMeasureProofs.lean:91-122, ~30 lines): **0.5 day** |
| `memValueFromValue` (core_aux.lem) | fuel+measure `lemSize ty1` | signature: `Ctype.tag_definitions -> ctype -> value -> …` (736690a65) | binder added, recursion unchanged: re-statement of the obligation + `split`-based proof re-run (Core_aux_lemMeasureProofs.lean:171-195): **0.25 day** |
| `add_to_sb`, `add_to_asw` (core_run_aux.lem) | fuel+measure `lemSize g` | signature: leading `bool` (`concurrency`) (7b1003ea2) | binder added; proofs :34-73 / :80-117 re-run: **0.25 day each** |
| `add_to_sb_stack/_continuation`, `add_to_asw_stack/_continuation` | termination_argument | signature (`concurrency`) | declares unchanged (name-keyed): **0** |
| `load_character_array_aux` (formatted.lem) | fuel (absorbing) | signature: leading `Loc.t` (f4a3a3d54) | payload unchanged; `_zero` statement regenerated: **0** (build check) |
| `translate_expression`, `translate_stmt` (translation.lem) | fuel (absorbing, 2026-10-18) | type: `elabM` becomes `conf -> st -> …` (334a1563b); `C.core_tag_definitions` → `Ctype.tag_definitions` (736690a65) | the kernel fuel equations + state-runner refusals (`TranslationFuelTest`, `aa734bdce`) restated over the new binders: **0.5–1 day** |
| `combine_params_args` (translation_aux.lem) | termination_argument | signature (`Config.config`) | **0** |
| `nd_foldlM` (nondeterminism.lem) | termination_argument | comment-only signature change | **0** |
| `State.foldlM`, `State_exception.stExcept_foldlM` | termination_argument | renamed/`let inline` (9f23c62b3) | rename declares: **0.1 day** |
| `State.foldrM`, `State_exception.foldrM`, `State_exception_undefined.filterM`, `stExceptUndef_foldM` | termination_argument | **deleted** (9f23c62b3, 0c374d8b4) | drop declares: **0** |
| `has_concurRead`, `find_array_index`, `easy_update_mem_value_aux`, `memcmp_load_aux`, `tmp_{compl,AND,OR,XOR}_aux`, `fake_mem_value_eq` (defacto_memory{,_aux}.lem) | fuel+measure (9 obligations) + `mkUnspec`, `simplify_integer_value_base` (fuel) + 11 termination declares | **files deleted** (4d3b03322) | delete 2 carriers (369 lines) + shells: **0.25 day** (plus the gate-list edits, §3.8) |
| `CerbMem.offsetsof_lemFuel` and the six sibling rows of `fuel_hypotheses.txt` under `CerbTagsWf.Acyclic/AcyclicPair ambient` | hand-written measured seams | the `ambient` (OCaml-global) map disappears with `Tags` (§3.2) | re-state the seven hypotheses one-map; `CerbMem_lemMeasureProofs.lean` (1069 lines) proofs re-run with one binder fewer: **1 day** |
| `hack`, `to_pure`, `to_pures` hypotheses | fuel_measure under `CerbCoreShape.*` | `driver2`/`process_core_step2` bodies change (2a121fb6d, 8c47748ed) — invariant (`prepare_exit`) unchanged | re-cite lines in `fuel_hypotheses.txt`: **0.1 day**; re-verify the invariant against the new `as_step` wrapping |
| all other 40-odd measured functions | — | unchanged signature and body (derived: the script printed no row) | **0** beyond regeneration + rebuild |

Derived total: ~3.5–4.5 worker-days of proof work, of which stage 1 carries
~1.5 (collect_switch_content_aux, translate_* equations, load_character_array)
and stage 2 the rest.

---

## 6. Fork-drift re-pin plan

Gate facts (`scripts/check_fork_drift.sh`): `[meta] merge-base=` is checked
against the LIVE `git merge-base upstream/master HEAD` (a moved base FAILS
until the manifest is refreshed); layer 1 = the SET of files under
`SURFACES` that differ between the pinned base and HEAD (+ untracked) must
equal `[files]`; layer 2 = the generated `.ml` files that differ from
`$CERB_UPSTREAM_TREE` (the pristine tree at the base, derived with the SAME
fork lem pin) must each carry a pinned sha256 of their unified diff under
`[expected-semantic]`/`[expected-cosmetic]`; `[source-content]` pins every
layer-1 file's bytes (89 rows today); `lem-pin=2d3a492…` cross-checked
against `lem -v`.

Plan per stage (the refresh is `--refresh` + review, never a blind refresh):
1. **Move the pristine tree**: `deps/cerberus-upstream` → checkout the
   stage's upstream target; `scripts/ce make -C deps/cerberus-upstream
   prelude-src` with the fork lem (2d3a492) → new `CERB_UPSTREAM_TREE`
   (86 → 83 `.ml` files after 4d3b03322/b519931bb: `defacto_memory*.ml` ×3,
   `core_indet.ml`, `core_rewrite2.ml` gone; `config.ml` new → 82 at tip;
   derived from the Makefile diff).
2. **Layer 1 (`[files]`)**: files the fork touched that upstream ALSO
   touched stay (the diff vs the new base is the re-merged delta);
   files that drop out: `memory/symbolic/impl_mem.ml`,
   `frontend/model/defacto_memory{,_aux,_types}.lem`,
   `frontend/model/core_rewrite2.lem` (deleted upstream);
   `frontend/model/global.lem` stays (the Lean reps for `has_switch`);
   NEW rows: `frontend/model/config.lem` (fork-ahead fields),
   `parsers/c/c_parser.mly` stays (asm refusal re-applied on the new
   grammar — plus `parsers/c/c_lexer.mll`/`cn_*` only if the refusal touches
   them), `util/cerb_diagnostic.ml` only if Main-mirrored text is edited.
   Every `[source-content]` row is re-pinned (all 89 move or go).
3. **Layer 2 — re-derive, re-justify** (31 today: 21 semantic + 10
   cosmetic). Derived from the per-module history (`git rev-list --count`
   on each source `.lem`, base..HEAD vs base..upstream):
   - **Disappear**: `defacto_memory_types.ml` (cosmetic; file gone);
     `core_typing.ml`'s R3 `Erun` guard part (upstream `ArityMismatchRun`)
     — the module stays a delta for the tuple-arity guards (tray 45);
     `ctype_aux.ml`'s `with_tagDefs`/reader stub part — stays a delta for
     the tray-37 accumulator; `implementation.ml`'s `alignof_proxy` part —
     stays for the enum reader.
   - **Remain, re-derived over the new base** (each a fork-ahead mechanism
     upstream does not have): supply threading (`symbol.ml`, `translation.ml`,
     `translation_effect.ml`, `cabs_to_ail*.ml`, `mini_pipeline.ml`,
     `driver.ml`, `core_run*.ml`), enum-as-data (`core.ml`, `core_linking.ml`,
     `ailSyntax.ml`, `genTyping.ml`, `implementation.ml`, `cabs_to_ail*.ml`),
     address-space top (`mem.ml`, `driver.ml`, `cabs_to_ail_effect.ml`,
     `mini_pipeline.ml`), run digest (`driver.ml`, `mini_pipeline.ml`,
     `translation_effect.ml`), match/arity guards (`core_aux.ml`,
     `core_typing.ml`), `are_compatible` accumulator (`ctype_aux.ml`),
     many/many1 restatement (`monadic_parsing.ml`), asm/alignas refusals
     (`cabs_to_ail.ml`), `mem_common.ml` (1 fork commit; reason to be
     re-read at refresh), the cosmetic comment/`(*val …*)` deltas
     (`cmm_csem`, `cn`, `ctype`, `lem_debug`, `nondeterminism`, `pp`, `std`,
     `utils`, `mem`).
   - **New**: `config.ml` (fork-ahead fields) — semantic; possibly
     `state.ml`/`state_exception*.ml`/`exception*.ml`/`errorMonad.ml` if the
     termination declares emit anything into OCaml (they do not: `declare`
     emits nothing — expected NOT new, verify at refresh).
   Each remaining row gets its justification re-read against the new
   upstream text (the `--refresh` output lists NEW differing files under
   `[expected-semantic]` pending review — the review is the work).
4. **The pristine EXECUTABLE instrument** (Tier B row 10/12, Tier C): 
   `scripts/build_independent_oracle.py` pins `CERBERUS_REV = b9aeedcb4…`
   and `LEM_REV = 3802cb0…` (upstream Lem); both move with the stage;
   `scripts/upstream_oracle_differences.json` (8 registered
   `shared-model-fix` cases: `multi_tu_tray/node`, minimal/112, 113,
   immaculate tray44 ×2, coverage/alignas ×3) are re-derived: none of their
   upstream defects (trays 37, 44, 47) is fixed in this range, so all 8
   are expected to REMAIN with refreshed rationale text; new rows appear
   wherever the new base fixed something the fork had mirrored as a crash
   (tray 04: the pristine engine now says UB where the fork says UB too →
   agreement, no row). Whether upstream Lem `3802cb0` still builds the new
   base cannot be determined read-only (upstream CI installs lem through
   opam `--deps-only`, no pin visible in `ci.yml`) — first-build finding.
5. `[meta] merge-base=` → the stage target; `renumber=arc13` unchanged;
   the dated header NOTE names the stage and the per-row dispositions.
6. Everything that quotes `b9aeedcb4` outside docs stays historical
   (tests' comments, `CONTRACT.md:36` "Matched mode … at the fork
   merge-base b9aeedcb4" → update to the new base; 238 docs mention it and
   are records — untouched).

---

## 7. Baseline movement (per `release.py --list` lane)

Oracle-DEPENDENT lanes (both engines move together; every row movement is
a dedicated instrument commit with the upstream commit cited):

| lane | expected movement | why |
|---|---|---|
| A1 `test_unit.sh` | gate lists change (totality 22→20 modules, purity, axiom cones, lakefile roots, handwritten manifest, pin sites, fork-drift manifest, `check_cli_refusals` (new upstream switch `branching_on_unspec_is_nd` must be REFUSED by Lean until mirrored — or accepted via the instance reader), `check_item_g_refusals`/`check_asm_refusal` re-run on the new text) | §3, §6 |
| A2 `tests/minimal` | rows touching null-pointer arithmetic (tray 04), `_Bool` from floats (tray 15), switch/case implicit conversions, for-loop decl order, FAM member-shift typing (tray 41), float `*` (tray 01 — fork oracle fixed with upstream; Lean's `CerbFloat` already multiplies, so DIFF rows may become MATCH) | FIX commits |
| A3 `tests/coverage` | same classes; `alignas/*` stay (unfixed upstream); union-init rows per the in-flight branch | |
| A4/A4b `tests/debug`, `tests/float` | `tests/float`: `_Bool` conversion rows (3230aa494) and the tray-01 multiplication rows | 3230aa494, 766073467 |
| A4c `test_bytes.sh` | **must NOT move** (oracle-independent `.exec` references) — any movement is a finding | |
| A5 `test_libc_exec.sh` | `std.core` changed (3230aa494: `loaded_fvfromint`/`ivfromfloat`) → `tests/libc/libc.core.sha256` RE-PIN (`libc_prep.sh`), libc-mode rows re-run | 3230aa494 |
| A6/A6b multi-TU + tray | 6b: tray 37 unfixed → rows stay; `node` stays `shared-model-fix` | |
| A7/A8 `test_parse.sh`/`test_core.sh` (tests/minimal; B2/B3 on tests/ci) | tests/ci 128 → 132 files (0342/0343/0344/0351 adopted; 0120/0121 renamed; 0341 upstream-skipped); Core TEXT changes for do-while (83b1a7424), switch (cabe81c3b, 588672e95), labels-as-values → `--pp core` round-trip rows move | ADD/FIX |
| A9 `test_elab.sh` | same/diff state moves on switch/do-while Core shapes | cabe81c3b, 83b1a7424 |
| A10 libxml2 URI, B1 chvalid | expected unchanged (no null arithmetic, no `_Bool` from float in the corpus — to be measured, not assumed) | |
| A11 CN coverage | upstream's CN parser split (30a04ac47) changes CN parse errors → REJECT-lane rows may move; exec rows should not | 30a04ac47 |
| A12 address-space lane | **must NOT move** (fork-only parameter; identity at default) — plant battery re-run | |
| A13 memory-access | **must NOT move** (receipts are fork-only) | |
| A14 pnvi | `tests/pnvi_lane/baseline.txt` (164 rows): `R-PNVI-06`/`-10` rows keyed on oracle crashes stay (51/52/53 unfixed); rows on `array_shift_ptrval` null arithmetic may move crash→UB (f4a3a3d54) | f4a3a3d54 |
| B4 verify fixtures | pinned Core dumps (`corpus/`, `check_fixture_freeze.sh`) re-derive on Core-text changes — dedicated re-pin | |
| B5 immaculate | tray44 rows stay | |
| B6 speclab | imports `Core`, `Driver`, `Core_run_aux`, `CerbND` — rebuild; gates should not move | |
| B7 gcc second oracle | triage ledger rows for the fixed classes (null arithmetic, `_Bool`) flip from SKIP/DISAGREE to agreement — improvements print loudly, re-recorded | |
| B10/B12 pristine oracle | instrument rebuilt at the new base (§6.4); 8 cases re-derived | |
| C1 `exec_ci_baseline.txt` (242 rows) | +4 rows, 2 renames (`0120/0121 … .error.c CERB_SKIP` → `.undef.c`), 0258/0270 expecteds, the skipped 0341 | 0676e9fca, ad233f84f, 3230aa494, f10329b44, 0c374d8b4 |
| C3 csmith corpus (1669; 1161 MATCH / 499 CERB_SKIP / 9 TIMEOUT) | re-run (reporting); movement expected in the `CERB_SKIP` class if upstream's desugaring fixes unlock files | |

---

## 8. Consumer impact (cerberus-caesium, pin `aa734bdce`; cerberus-sl two re-pins behind)

What cerberus-caesium imports/uses (derived from `grep` over its `.lean`):
modules `Translation`, `Cabs_to_ail`, `GenTyping`, `Core`, `Core_run_aux`,
`Core_reduction`, `Core_eval`, `Core_linking`, `Core_aux`, `Implementation`,
`Symbol`, `Ctype`, `AilSyntax`, `CerbGlobal`, `CerberusImpl`, `CerbMem`,
`CerbND`, `CerbLocation`, `Cn_desugaring`, `Errors`, `Annot`, `Builtins`,
`AilTypesAux`, `IntegerImpl`, `GenTypesAux`, `ErrorMonad`, `IntegerType`,
`CoreParser`, `CabsImport`, `CerberusFresh`, `CerbCoreMeasure`,
`CerbMeasureLemmas`, `Core_eval/Core_reduction_lemMeasureProofs`,
`CerbMemAllocatorProofs`; names `Loc.region` (6054 occurrences — quoted
Core ASTs), `Cabs_to_ail.constructValue`, `Core_reduction.step_ctx`,
`Driver.drive_nonmemory_steps_aux2`, `Core.getMessageLog`,
`Implementation.sizeof_ity`, `Symbol.show_symbol`; field names in quoted
`Core.file` records: `main`, `calling_convention0`, `tagDefs`, `enumDefs`,
`stdlib`, `impl0`, `globs`, …; `calling_convention.Normal_callconv`;
entry calls `desugar fmapEmpty fmapEmpty supply top coreEvalStuff empty_init
"main" tunit`, `runErrorMonad (annotate_program enums fmapEmpty (main, ail))`,
`translate enums fmapEmpty supply (names, stdlib) Normal_callconv impl typed`,
`initial_driver_state_given sup top digest file default`,
`step_ctx enumDefs tagDefs`, `advance_step enumDefs tagDefs …`.

Changes by stage:
- **Stage 1**: `desugar` gains a `desug_config` (334a1563b; the fork's
  `sup`/`top` stay), `translate`'s `callconv` argument becomes an
  `elab_config` record (`elab_config callconv is_PNVI is_CHERI is_CN
  strict_pointer_arith branching_on_unspec`); `elabM` is a function type
  (only visible if the consumer runs elaboration pieces — it does not);
  NEW constructors `CabsElabel_addressGNU`/`AilElabel_addressGNU` in the
  Cabs/Ail ASTs (exhaustive matches in `AilToCaesium` must add an arm);
  `Core` text of do-while/switch changes (re-quote `CoreCaesium/Generated/*`);
  `Mem.array_shift_ptrval` returns `Undefined.t` with a loc;
  `Constraint`/`Errors` gain constructors (`stringOfDesugarCause` arms).
- **Stage 2**: `Core.file.calling_convention0` → `callconv` of type
  `Config.calling_convention` (every quoted file regenerates);
  `Ctype.tag_definitions` abbrev replaces `core_tag_definitions`;
  `tagDefs` becomes an explicit parameter where the reader injected it
  (`step_ctx`, `advance_step`, `memValueFromValue`, `zeros`, …): the SAME
  Lean argument positions if §3.2 is adopted as proposed (the reader's
  leading parameter becomes the lem parameter) — re-check per call;
  `Config.config` parameter on `desugar`/`translate`/`initial_driver_state*`
  (+ `driver_state.conf` field, `driver_state` literals need it),
  `runErrorMonad` gains `conf` (the Ail typing monad), `Core_run_aux.add_to_sb
  concurrency …`, `CerbGlobal.{isPermissive,…}` defs disappear (→
  `CerbGlobal.defaultConfig.permissive`), `CerbPP` renames,
  `Implementation.sizeof_ity` unchanged, `Mem.sizeof_ival/alignof_ival` gone
  (→ `Implementation.sizeof_ty/alignof_ty`), the Defacto_memory modules
  gone (consumer does not import them).

Re-pin note sketch (one per stage, the 2026-10-07 consumer-note shape:
VERIFIED/PREDICTED labels, cites at the consumer's pin): §1 what changed in
consumer terms (the lists above, with the lem/upstream commit per item);
§2 mechanical edits (re-quote generated Core files with the quotation tool;
`calling_convention0` → `callconv`; add the two GNU-label arms; thread
`Config.config`/`defaultConfig` into `initial_driver_state_given` and the
driver-state literals; `runErrorMonad conf`); §3 semantic consequences
(verdict changes on null arithmetic/`_Bool`/switch — list the corpus rows
of the consumer's `CoreCaesium/Corpus*` that move, VERIFIED by a scratch
build); §4 what did NOT change (`Loc`, `Symbol`, `CerbMem` memory-model
behaviour at the default switch set, the fuel/measure contracts' names);
§5 the new base hash and `LemLib` pin (unchanged `2d3a492` unless §4 finds
a backend need).

---

## 9. Staged plan

Dry-run conflict counts, `git merge-tree --write-tree mdd/cerberus-lean <c>
| grep -c '^CONFLICT'` (machine counts; one line per conflicted file):

```
cee382443 … 9     3771dce03 … 9     f10329b44 … 9     cabe81c3b … 10
f4a3a3d54 … 11    c3ff8c53f … 11    4d3b03322 … 16    736690a65 … 26
0676e9fca … 26    2a121fb6d … 28    a09e6717b … 28    cfcb31834 … 28
8c47748ed … 28    20881fae1 … 28    7b1003ea2 … 31    c3a438b1c … 31
fc6b20526 … 31    9f23c62b3 … 33    0c374d8b4 … 33    30a04ac47 … 33
b519931bb … 34    8d1926c7f … 34    6dc8d2a47 … 34    68bdc84bf … 34
```

The conflict set grows in three steps: the Sept-6..30 fixes and the two
early refactors (elab env, sizeof/alignof) cost 9–11 files; the two
removals/Tags (4d3b03322, 736690a65) add 15; Cerb_global→Config and the
monad rewrites add 8.

### Stage 1 — target `c3ff8c53f` (2026-09-30; "everything before the Symbolic-memory-model removal"), 11 conflicted files

Commits 1–25 of §1. Fixes captured: 766073467 (tray 01), 5a3a06036,
588672e95, ad233f84f, 3230aa494 (tray 15), cee382443 (tray 33), f10329b44,
97371d8ed, 0fc82e266, cabe81c3b, f4a3a3d54 (tray 04) — 11 of the 16 FIX
rows; additions 83f9cc641, c8c085d47, 08e941f0e, 83b1a7424; refactors
b3e11ea33, 334a1563b, 3771dce03. Candidates compared: `cee382443`/`3771dce03`/
`f10329b44` (9 files) leave 97371d8ed/0fc82e266/cabe81c3b/f4a3a3d54 for
stage 2, where they would re-conflict inside the big refactors; `cabe81c3b`
(10) adds the switch-elaboration fix; `c3ff8c53f` (11) adds the tray-04 fix
and the parser location fix at +1 file (`formatted.lem`, 1 hunk). The
orchestrator's `736690a65` (26) and `20881fae1` (28) candidates pull the
Tags removal and the Symbolic removal into stage 1 without the Config
change that completes them — a worse cut [AGENT].

Work: merge + the 11 resolutions (§2; ~2.5 days: mini_pipeline/cabs_to_ail
over `eval_mode` + the seeds, implementation.lem's two blocks, the elabM
shape); seams (§3.3 sizeof/alignof reps, §3.4 array_shift/memcmp/
load_character_array, §3.5 fuel wrappers, Cabs/Ail GNU-label constructor in
`cabs_json.ml` (exhaustive OCaml match → build error until added) +
`CabsImport.lean` (fails closed: `unknown tag`) + `CerbPP`, Main.lean error
arms; ~2.5 days); measure proofs (§5 stage-1 share, ~1.5 days);
`termination_argument` for `elab_mapM_aux`/`elab_foldlM_aux` (0.1);
generation + builds + Tier A/B + baseline movement (§7: libc dump re-pin,
tests/ci adoption, exec/ci/float/pnvi rows, verify fixtures; ~2 days);
fork-drift re-pin + pristine instrument at `c3ff8c53f` (§6; ~1.5 days);
records, tray INDEX closures (01/04/15/33), consumer note (~1 day).
**Estimate: 10–12 worker-days** + the fork's audit cycle (pre-merge audit,
re-gate; ~2 days).
Gates: full Tier A + Tier B (rows 1–12), `leanchecker` over the changed
proof carriers (Translation, Core_aux, Formatted, CerbMem carriers), the
axiom censuses, `check_fork_drift.sh` on the moved base, the pristine
instrument rebuilt, the consumer scratch build (cerberus-caesium at its pin
against the stage-1 tree — PREDICTED → VERIFIED as in the 2026-10-07 note).
Risks: the `monomorphic` dependency (operator, network) blocks the first
build; the supply re-expression of upstream's new ambient mints in
`translation.lem` (cabe81c3b's `case_` symbols) changes symbol NUMBERING of
the Lean side only if the mint order differs from the fork's C1 rule — the
multi-TU `failure-class` projection row (A6b) is the tell; `std.core`
changes every lane's runtime.
Consumer sees: §8 stage 1 (small: `desug_config`/`elab_config` arguments,
two AST constructors, Core-text re-quotes, `Undefined.t` array shift).

### Stage 2 — target `upstream/master` (`68bdc84bf`), 23 further conflicted files (34 at tip from the current base; the count from a stage-1-merged tree cannot be measured read-only)

Commits 26–46: removals (4d3b03322, a09e6717b, b519931bb), Tags
(736690a65), Cerb_global→Config (7b1003ea2 + c3a438b1c), cerb_diagnostic
(20881fae1), Result.t (fc6b20526), monad rewrite (9f23c62b3), Pp renames
(6dc8d2a47), CN parser split (30a04ac47), trace/stepping (8c47748ed,
2a121fb6d), fixes 0676e9fca, cfcb31834, 0c374d8b4, 8d1926c7f (tray 41),
68bdc84bf. Optional split at `20881fae1` (28): 2a = removals + Tags +
0676e9fca/cfcb31834 + trace/stepping/diagnostic; 2b = Config + monads +
parser + the rest — the split isolates the Tags-reader decision (§3.2) from
the Config decision (§3.1), at the price of a second full re-gate.
Work: §3.1 Config (3–4 days incl. Main/CerbCall/mini_pipeline/driver_state/
errorM/core_run concurrency), §3.2 Tags reader retirement (2–3 days +
1 day CerbMem hypotheses), §3.8 removals (1–1.5 days incl. gate lists),
§3.7 declares/renames + CerbPP + Main error arms + `errors.lem` CN arms
(1.5–2 days), parser: re-apply the asm refusal on the split grammar and
regenerate `c_parser_error.messages` (0.5–1 day), measure proofs (§5 stage-2
share, ~2.5 days incl. CerbMem), baselines/gates/pristine instrument
(2–3 days), consumer note + scratch build (1–1.5 days).
**Estimate: 15–19 worker-days** + audits (~3 days; two if split).
Gates: as stage 1 plus `check_failure_reach.sh` (positions move in
Core_reduction/Driver/Implementation), `check_fuel_forms.sh` over the
re-stated CerbMem hypotheses (P0 argument correspondence), `check_pin_sites`
(unchanged lem pin), the CN coverage lane (parser split), the `--switches`
refusal witnesses (new upstream switch).
Risks: the two design decisions (Q3/Q4) are consumer-API decisions; the
`partial def` default on the new recursions (totality RED until declared);
the `.messages` regeneration needs menhir in the switch (present — the fork
builds the parser today); `driver_state.conf` + the fork's digest/top make
the driver-state literal shape the consumer builds change twice if stage 2
is split.
Consumer sees: §8 stage 2 (large: `callconv` rename, `Config.config`
everywhere, `tagDefs` explicit, `runErrorMonad conf`, driver-state field).

### Alternative — cherry-pick the semantic fixes only, no refactors

Per-fix simulation (`git merge-tree --write-tree --merge-base=<c>^
mdd/cerberus-lean <c>`, verbatim CONFLICT lines in the transcript):
3230aa494 1 (`tests/tests.sh` only), f10329b44 1 (`tests/tests.sh`),
f4a3a3d54 1 (`formatted.lem`), cabe81c3b 2 (`core_typing.lem`,
`translation.lem`), cee382443 3 (`pipeline.ml`, `translation.lem`,
`translation_effect.lem`), cfcb31834 1 (`cabs_to_ail.lem`), 588672e95 2
(`cabs_to_ail.lem`, `mini_pipeline.lem`), 0c374d8b4 2 (`state_exception.lem`,
`tests/tests.sh`), 8d1926c7f 0, 0fc82e266 1 (`cabs_to_ail.lem`), 97371d8ed 2
(`cabs_to_ail.lem`, `pp_errors.ml`), 0676e9fca 0, ad233f84f 1
(`cabs_to_ail.lem`); also 5a3a06036 0, 766073467 0, 83b1a7424 1.
Derived sum 17 conflict lines, but the simulations are INDEPENDENT: the
switch/ICE cluster (588672e95 → 97371d8ed → 0fc82e266 → cabe81c3b →
cfcb31834 → 0676e9fca → 68bdc84bf) is one rewrite of `cabs_to_ail.lem`'s
constant-expression path on `eval_mode` and (from 7b1003ea2) `typecheckAil_
with_ctx`; cabe81c3b's `translation.lem` uses ambient `Symbol.fresh_*` and
`collect_switch_content` (a new measured function); cee382443 needs either
the elab env or a fork-side switch read (`has_switch SW_branching_on_unspec_
is_nd` through the instance reader — simpler than upstream's env); the
`tests/tests.sh` "conflicts" are context drift only. Cost [AGENT]: ~4–5 days
for the cluster re-expressed in the fork's threaded style, ~0.5 day each for
the other 7, ~2 days of baselines/records → **8–11 worker-days**, i.e. the
price of stage 1 with none of its benefits: the base stays at `b9aeedcb4`,
layer 2 grows by one justified delta per fix, every later bump re-conflicts
on the re-expressed code, and the pristine instrument keeps diverging.
Where it IS cheap: `8d1926c7f`, `0676e9fca`, `5a3a06036`, `766073467` apply
with 0 conflicts and `3230aa494`, `f10329b44` with a trivial one — **six
fixes for ~2 days**, if a consumer delivery needs any of them before the
arc (they then come out again at the bump as "already applied").

---

## 10. Recommendation and open questions

Recommendation [AGENT 2026-10-20]: run the bump as **two stages — stage 1 to
`c3ff8c53f` (11 conflicted files, 11 of 16 fixes, ~10–12 worker-days), stage
2 to the tip (~15–19 worker-days)**, each a true merge commit on its arc
branch (as the fork's existing upstream merge `24c3314c0` was), landed
ff-only after the audit. Reasons: the conflict surface is concentrated in
four lem files whose fork mechanisms (supply, top, digest, enum reader,
seeds) must be re-threaded once per stage regardless of where the cut is;
cutting before the Tags/Config refactors keeps stage 1 almost invisible to
the consumer and makes the two design decisions (reader retirement, Config
as the run-parameter carrier) their own reviewed slice; cherry-picking is
not cheaper and leaves the base where it is. Do the six zero-conflict fixes
early ONLY if a delivery needs them.

Open questions only the operator can answer:
1. **Merge commits on the arc branch** — the bump is a merge (not a rebase of
   1144 commits); the ff-only rule governs the landing. Confirm this reading
   of the working practices, as for `24c3314c0`.
2. **`monomorphic 2.1.0`** — a new upstream opam dependency not in the switch;
   needs an operator-run install with network before stage 1's first build.
3. **Retire the `tagDefs` reader in favour of upstream's explicit parameter
   (§3.2)?** Mirror-OCaml doctrine says yes; it changes generated call shapes
   the consumer uses (`step_ctx`, `advance_step`, …). The enum reader stays
   either way.
4. **`Config.config` as the one run-parameter carrier (§3.1)** — fold the
   fork's `address_space_top` (and the digest?) into it as fork-ahead fields,
   or keep them as separate parameters beside `conf`.
5. **Stage-1 cut**: `c3ff8c53f` (recommended) vs `f10329b44` (9 files, defers
   the switch-elaboration and tray-04 fixes) vs the orchestrator's
   `736690a65`/`20881fae1`.
6. **Stage 2 split at `20881fae1`** (two re-gates, two consumer notes) or one
   stage.
7. **Sequencing with in-flight work**: `fix/union-init-refusal` (1 commit,
   14 files incl. `fork_drift_manifest.txt`) lands before stage 1 or is
   rebased after; the other `arc/*` branches are parked records.
8. **Consumer timing**: cerberus-caesium pins `aa734bdce`; stage 2's API
   churn (§8) is the largest since the fuel-parameter arc — when the
   consumer wants to absorb it decides whether stage 2 waits.
9. **Upstream switch `branching_on_unspec_is_nd`**: mirror it as a fork
   `CerbSwitch` accepted by `--switches` (and `judgeSwitches`), or refuse it
   as every other non-PNVI switch is refused today (R-PNVI-12 class).
10. **Tray filings**: close 01/04/15/33/41 in the INDEX at stage 1/2 (the
    reports stay for the record); the operator files nothing new from this
    scoping.

Not determinable read-only (first-build findings, budgeted above): whether
lem-lean's fuel-measure validator accepts the function-typed `elabM`
workers; whether upstream Lem `3802cb0` still builds the new base for the
pristine instrument; the stage-2 conflict count from a stage-1-merged tree;
exact baseline row movements.
