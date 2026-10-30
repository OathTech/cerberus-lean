# Merge-base bump, stage 1 — record (b9aeedcb4 → upstream c3ff8c53f)

Branch `arc/merge-base-bump`, worktree `worktrees/cerberus-lean-arc/merge-base-bump`,
base = mainline `mdd/cerberus-lean` `676f9f21c` (Lean 4.35.0, lem `e6d8db5`). Charter:
`docs/2026-10-29_worker-charter-merge-base-bump-stage1.md`; scoping:
`docs/2026-10-20_merge-base-bump-scoping-record.md` (§ numbers below refer to it). Worker
[AGENT 2026-10-29]. Machine outputs are quoted verbatim; tallies computed from them are
labelled *derived*. The charter file stays as committed; where this record and the charter
differ, this record is the truth (§0.2).

Milestone sections are appended as they close: §0 M0 (this plan), then M1–M6.

---

## 0. M0 — the plan on today's base (2026-10-29)

### 0.1 Inputs and the reproduced simulation

```
$ git rev-parse upstream/master
ae70925fc38c65e363f182894770bb488c31eaee
$ git rev-parse c3ff8c53f
c3ff8c53f05982745f9b3a10b3d05442e214bcb5
$ git merge-base upstream/master HEAD
b9aeedcb4dd438763b0eef7f95ac19e93875d7de
$ git rev-list --count b9aeedcb4..c3ff8c53f
25
$ git log --merges --oneline b9aeedcb4..c3ff8c53f | wc -l
0
$ git remote -v
origin	git@github.com:OathTech/cerberus-lean.git (fetch)
origin	git@github.com:OathTech/cerberus-lean.git (push)
upstream	/home/dev/projects/cerberus-lean-proj/deps/mirrors/cerberus.git (fetch)
upstream	no-push-fetch-only (push)
$ lem -v
Lem lean-backend-v0.1.0-alpha.1-78-ge6d8db5
$ opam list --switch=. | grep monomorphic
monomorphic             2.1.0       A small library used to shadow polymorphic operators (and functions) contained in the stdlib
```

The merge simulation on the charter's base (`HEAD` = `38b0c8c96`, the charter commit; the three commits since
`676f9f21c` touch only `lean_frontend/docs/` and `lean_frontend/TODO.md`):

```
$ git merge-tree --write-tree HEAD c3ff8c53f | head -1
d66848b66ee4ea3cbe4409bc891b30312be01118
$ git merge-tree --write-tree HEAD c3ff8c53f | grep '^CONFLICT'
CONFLICT (content): Merge conflict in backend/common/pipeline.ml
CONFLICT (content): Merge conflict in frontend/model/cabs_to_ail.lem
CONFLICT (content): Merge conflict in frontend/model/cabs_to_ail_effect.lem
CONFLICT (content): Merge conflict in frontend/model/core_typing.lem
CONFLICT (content): Merge conflict in frontend/model/formatted.lem
CONFLICT (content): Merge conflict in frontend/model/implementation.lem
CONFLICT (content): Merge conflict in frontend/model/mem.lem
CONFLICT (content): Merge conflict in frontend/model/mini_pipeline.lem
CONFLICT (content): Merge conflict in frontend/model/translation.lem
CONFLICT (content): Merge conflict in frontend/model/translation_aux.lem
CONFLICT (content): Merge conflict in frontend/model/translation_effect.lem
CONFLICT (content): Merge conflict in ocaml_frontend/ocaml_implementation.mli
CONFLICT (content): Merge conflict in tests/tests.sh
```

13 conflicted files, the charter's list exactly. Hunk and line counts per file (*derived*:
`<<<<<<<` markers; lines inside the marker regions, both sides) are in the table of §0.5: 33 hunks,
657 lines in total. The conflicted files with markers were extracted from tree `d66848b66` into
`.tmp/m0-conflicts/` (ephemeral); upstream's per-file diffs into `.tmp/m0-updiffs/`.

Upstream's stage-1 change, from `git diff --stat b9aeedcb4 c3ff8c53f`: `68 files changed, 5436
insertions(+), 5088 deletions(-)`, of which `parsers/c/c_parser_error.messages | 7577 ++++------`
(regenerated menhir messages) and `frontend/model/*.lem` 26 files. `git diff --name-status` shows
only additions beyond modifications: `tests/ci/034{2,3,4}-*.c` and their `expected/` files — no
file is deleted or renamed in this range (the removals begin at stage 2's `4d3b03322`). The upstream
tip moved once since the scoping: `ae70925fc 2026-10-22 (cparser) fix: parameterise error message`,
outside stage 1.

### 0.2 Corrections to the charter (accepted [AGENT 2026-10-29], orchestrator)

1. **The growth from 11 to 13 conflicted files is the two backports, not the refusals.**
   `git merge-tree --write-tree 3ac3ff336 c3ff8c53f` (the scoping's base) already lists
   `cabs_to_ail.lem` and `translation.lem`, the files of the anonymous-member (D12) and
   compound-assignment (D13) refusals. The two new names are `frontend/model/translation_aux.lem`
   and `tests/tests.sh`; the only fork commits since `3ac3ff336` touching them are the backports I0
   `f928cddbb` and I0b `1e7df2ac2` — the backports colliding with their own upstream originals
   (`f10329b44`, `3230aa494`), i.e. the merge-away case. The refusals re-thread inside files that
   were conflicted anyway.
2. **The union-initializer refusal (D11) is not in a conflicted file.** It lives in
   `frontend/model/desugaring_init.lem` (fork commit `f8afa8a1d`), which auto-merges. Upstream's
   change there (588672e95: `is_integer_constant_expression` gains a leading `bool`,
   `evaluate_integer_constant_expression` loses its `Loc.t`, both in the `desugaring_init_funcs`
   record the refusal sits beside) gives D11 a post-merge build check and its witness re-run
   (`scripts/check_union_init_refusals.sh`), not a conflict resolution.
3. **The `NULL + 0` TODO line is an M6 edit.** `lean_frontend/TODO.md:205-207` currently says the
   upstream fix exists and a backport ruling is pending; at M6 the entry is rewritten to say arm 4 is
   retired by the bump (f4a3a3d54 carried by the base), with no refusal written.

### 0.3 Rulings recorded

[USER 2026-10-29], relayed by the orchestrator, each as the charter recommended:

- **Q1** The bump is a true merge commit of upstream into the fork on this arc branch, landed
  ff-only after the audit; the fork's earlier upstream merge `24c3314c0` is the precedent.
- **Q5** The stage-1 cut is `c3ff8c53f`.
- **Q9** Upstream's new switch `branching_on_unspec_is_nd` is REFUSED by `--switches` like every
  other non-PNVI switch (R-PNVI-12 class), not mirrored.
- **Q10** Tray filings 01, 04, 15 and 33 are closed at stage 1 in the INDEX as fixed upstream and
  carried by the base.

Standing from the charter: [USER 2026-10-29] the bump runs now, before the remaining
crash-to-refusal arms of the survey; fork-ahead deltas are limited to the fork's own fixes and the
backports a delivery needed; `monomorphic 2.1.0` is installed. Q2 is done; Q3/Q4/Q6/Q8 are stage 2
and nothing in stage 1 pre-empts them (§0.5 rule R1).

### 0.4 Resolution rules (the per-file plan rests on these; [AGENT 2026-10-29])

- **R1 — fork-ahead parameters precede upstream's new configuration parameter.** Every entry that
  the fork extended with explicit state (`sup`, `top`) and upstream extended with a configuration
  value (`desug_conf`, `elab_conf`) takes the fork's parameters first, then upstream's list in
  upstream's order; lem-lean reader seeds precede everything (the N-ary rule). So
  `desugar sup top desug_conf core_eval_stuff cn_eval_stuff startup_str tunit`,
  `translate sup (ailnames, stdlib) elab_conf impl prog` (the `callconv` slot becomes `elab_conf`,
  as §8 predicted), `evalIntegerConstantExpression[_seeded] [en tds] sup top elab_conf core_env
  sigm mode d_expr`. Q4 (fold `top` into the configuration) stays open for stage 2: `top` remains
  its own parameter.
- **R2 — upstream's text everywhere the fork has no mechanism**; the fork's mechanisms (symbol
  supply, address-space top, run digest, enum reader seeds, switch instance reader, the three
  refusals, the fuel/measure declares) are re-threaded once onto upstream's rewritten text, never
  the reverse. Where upstream deleted something the fork had only annotated (declares, comments),
  the annotation goes with it.
- **R3 — upstream's names.** `elab_initial_state` (with the fork's supply parameter) replaces the
  fork's `elab_init`; `runElabM_errors conf` replaces `runStateM_errors`; `collect_switch_content_aux`
  replaces `collect_cases_` (and its declares/proof); `ArityMismatchRun` replaces the fork's R3
  `MismatchExpected "run"` guard text.
- **R4 — the C1 mint rule** for every ambient `Symbol.fresh_*` upstream added or kept: one
  `E.fresh_elab_*` draw at the same chain position, list order kept (`E.mapM` over upstream's
  `List.map`; OCaml's `List.map` applies left to right, so the oracle's ambient draw order equals the
  Lean threaded order).
- **R5 — mirror doctrine for the Lean seams**: where upstream MOVED OCaml code
  (layout from `impl_mem.ml` to `ocaml_implementation.ml`), the Lean mirror moves the same way
  (§0.7 S1); where upstream changed a crash into a verdict, the mirror does the same and the stop
  site retires (§0.7 S2).

### 0.5 Per-file resolution plan (the 13 conflicts)

Hunk/line counts *derived* from the extracted files. "U" = upstream's side, "F" = the fork's.

| file | hunks / lines | what collides | resolution |
|---|---|---|---|
| `backend/common/pipeline.ml` | 2 / 24 | U `desugar desug_conf …`, `translate … elab_conf …`; F dead-supply `0`, `conf.address_space_top`, the arc-13 `Ail_sym_hwm` window check after desugar, the 3-tuple bind | `Cabs_to_ail.desugar 0 conf.address_space_top desug_conf (ailnames, core_stdlib_fun_map, core_impl) cn_init_scope "main" cabs_tunit >>= fun (markers_env, ail_prog, _dead_supply) ->` + F's window check; `let (core_file, _dead_supply) = Translation.translate 0 core_stdlib elab_conf core_impl ailtau_prog in`. Review the auto-merged parts: `c_frontend`'s new `desug_conf` parameter, `mk_elab_config` (the OCaml source of the Lean `mkElabConfig` mirror, §0.7 S5) |
| `frontend/model/cabs_to_ail.lem` | 6 / 58 | h1 the const-expr mini-run call (`eval_mode` vs F's supply/top draw + D3 seed); h2 `typeof(e)` (U `get_current_return_type_opt` + loc-taking `annotate_block`; F `annotate_expression_seeded`); h3 `sizeof e` (same); h4 `Init_expr` (F `typecheckAil_seeded`; U's `fail_ailtyping` arm); h5/h6 the `desugar` entry | h1: F's `get_fresh_sym_supply`/`get_address_space_top` + `E.read_config >>= fun conf ->` + `Mini_pipeline.evalIntegerConstantExpression_seeded (Map.fromList sigm.enum_definitions) E.desugar_time_tagDefs sup address_space_top conf.E.elab_conf core_env sigm mode d_expr >>= fun (n, sup') -> E.set_fresh_sym_supply sup' >> E.return n` (U's `mode` replaces `loc ty_opt`); h2: U's `ret_ty_opt` into F's seed (the seed already takes `maybe ctype`; the callback is built inside the seed, audit E1); h3: F's seeded call unchanged; h4: F's seeded call + U's `Left (loc, tcause) -> E.fail_ailtyping loc tcause`; h5/h6: `val desugar: nat -> integer -> E.desug_config -> … -> Exception.exceptM (E.fin_markers_env * ail_program unit * nat) Errors.error`, `E.eval sup address_space_top desug_conf …` (R1). Auto-merged regions to re-thread: U's new `Mini_pipeline.typecheckAil_promoted impl sigm gamm d_e` in the switch arm → the new `typecheckAil_promoted_seeded` (§0.7 S3); the D12 arm, the asm refusal (`CabsSasm`), the tray-47 `_Alignas` completeness check — verified unchanged by the merge and re-measured (M4) |
| `frontend/model/cabs_to_ail_effect.lem` | 3 / 76 | h1 `initial_state` (U `desug_conf`; F `sup top`); h2 F's `get/set_fresh_sym_supply`, `get_address_space_top`, `eval` returning the triple vs U's `eval desug_conf …`; h3 `get_alignof` (U builds the real `(loc, StructDef/UnionDef)` map and calls `Implementation.alignof_ty tagDefs`; F's pseudo-map + `alignof_ty_seeded`) | h1: `initial_state sup top desug_conf core_eval_stuff cn_eval_stuff` with state fields = U's (`desug_conf`) + F's (`fresh_sym_supply`, `address_space_top`); h2: F's getters kept, `cabs_to_ail_effect_eval sup top desug_conf …` returning `(markers, res, sup')`; h3: U's real map, then `return (fun z -> alignof_ty_seeded (enum_map_of_tag_definitions tagDefs) desugar_time_tagDefs tagDefs z)` with `alignof_ty_seeded en tds tagDefs ty = Implementation.alignof_ty tagDefs ty` (type `map Symbol.sym (Loc.t * Ctype.tag_definition) -> ctype -> integer`); the pseudo-map disappears (§0.7 S1) |
| `frontend/model/core_typing.lem` | 1 / 6 | the `Erun` arity guard: F's audit-R3 `MismatchExpected "run" …`, U's `ArityMismatchRun` | U's text (R3); F's `FORK 2026-09-23 (audit R3)` comment goes; the module stays a fork-drift delta for the tuple-arity guards (tray 45) |
| `frontend/model/formatted.lem` | 1 / 14 | F's absorbing fuel declare on `load_character_array_aux` sits where U changed `load_character_array`'s signature (`Loc.t` first) | F's comment + `declare {lean} fuel val load_character_array_aux = …` kept, followed by U's `val load_character_array: Loc.t -> …` / `let load_character_array loc …` (payload unchanged, §0.8) |
| `frontend/model/implementation.lem` | 1 / 133 | F's whole E-A enum-reader block + the old `alignof_ty` (pseudo map, `maybe nat`, `alignof_proxy`); U's `sizeof_ty`/`alignof_ty : map … -> ctype -> integer` with OCaml reps `Ocaml_implementation.sizeof/alignof` | the E-A block stays verbatim; F's old `alignof_ty` val + 3 declares deleted; U's two vals + OCaml reps, plus Lean reps `CerberusImpl.sizeof_ty`/`alignof_ty` with `declare {lean} fuel_consumer` and `reader_consumer` on both (§0.7 S1) |
| `frontend/model/mem.lem` | 1 / 25 | U deleted `sizeof_ival`/`alignof_ival`; F's declare block (offsetof/sizeof/alignof reps, fuel/reader consumers, the FUEL CONSUMERS comment) | keep F's `offsetof_ival` Lean rep + consumers and the comment block (count "19 vals" → 17); delete the eight `sizeof_ival`/`alignof_ival` lines; `CerbMem.sizeofIval/alignofIval` deleted with them |
| `frontend/model/mini_pipeline.lem` | 5 / 169 | h1 F's `run_const_expr_driver` (reader_seed) + `evalConstantExpressionAux sup top loc …` vs U's `eval_mode` + `evalIntegerConstantExpressionAux elab_conf …`; h2 the elaboration run point (F `runStateM`/`elab_init sup callconv`/`sup_after_elab`; U `runElabM elab_conf … elab_initial_state`); h3/h4 `evalIntegerConstantExpression` signature/result (F `(integer * nat)`); h5 F's four D3 seeds vs U's `typecheckAil_promoted` | h1: F's `run_const_expr_driver` kept (Q3 is stage 2) + U's `eval_mode` type + `evalIntegerConstantExpressionAux: nat -> integer -> TranslateEff.elab_config -> … -> eval_mode -> A.expression unit -> Eff.exceptM (C.value * nat) Errors.error` (R1); h2: `TranslateEff.runElabM elab_conf (toCore a_expr) (TranslateEff.elab_initial_state sup)`, `sup_after_elab` from `translate_final_st.fresh_supply`, F's `(dr_st, sup_after_init)` pair with `initial_driver_state_given sup_after_elab address_space_top (Symbol.digest ()) …`, dummy file `C.calling_convention= elab_conf.TranslateEff.calling_convention` + F's `C.enumDefs= Map.empty`, U's `Core_run.current_loc= Loc.locOf d_expr` (U dropped the `loc` parameter in 588672e95: upstream's judgement, adopted; diagnostic locations may move, §0.9); h3/h4: `evalIntegerConstantExpression sup top elab_conf core_env sigm mode d_expr : Eff.exceptM (integer * nat) Errors.error`, the guard's `Loc.locOf d_expr`; h5: BOTH — F's four seeds re-typed (`evalIntegerConstantExpression_seeded en tds sup top elab_conf …`; `annotate_expression_seeded en tds ret_ty_opt sigm gamm ctx expr = GenTyping.annotate_expression (fun loc -> GenTyping.annotate_block loc ret_ty_opt) sigm gamm ctx expr`; `typecheckAil_seeded`, `qualified_ctype_of_seeded` unchanged) + U's `typecheckAil_promoted` + a fifth seed `typecheckAil_promoted_seeded en tds impl sigm gamm d_expr` (§0.7 S3). Header: U's (`open import Pervasives Utils` / `import Symbol`, 3771dce03) and the fork's one bare `digest ()` becomes `Symbol.digest ()` (pre-scan of the seven Symbol-qualified files: this is the only fork-added bare use) |
| `frontend/model/translation.lem` | 5 / 74 | h1 `while_` mint, h2 the `do` rewrite (83b1a7424) with its mints, h3 the switch mints over `collect_switch_content` (cabe81c3b) vs F's `collect_cases`+`list_init`, h4 F's `core_enumDefs` beside U's deletion of context, h5 `translate`'s signature/body | h1/h2: `E.fresh_elab_pretty_with_id (fun x -> "while_"/"do_" ^ show x) >>= fun sym_loop ->` on U's new bodies (U's two `wrapped_fresh_symbol`s already draw from the supply); h3: `E.mapM (fun (case_selector, case_visibles) -> E.fresh_elab_pretty_with_id (fun x -> "case_" ^ show x) >>= fun case_sym -> E.return (case_selector, case_sym, case_visibles)) switch_content.found_cases >>= fun case_infos ->` then `E.fresh_elab_pretty_with_id (fun x -> "default_" ^ show x) >>= fun default_sym ->` (R4: cases in U's list order, default after); h4: keep `core_enumDefs`; h5: `val translate: nat -> (…) -> E.elab_config -> C.impl -> A.ail_program … -> (C.file unit * nat)`, `E.runElabM_errors conf (translate_program translation_stdlib prog) (E.elab_initial_state sup)`, `C.calling_convention= conf.E.calling_convention` + `C.enumDefs= core_enumDefs`, returning `(file, st.E.fresh_supply)`. Declares: `collect_cases_` → `collect_switch_content_aux` (same payload shape `fuelExhausted (fun st => ((), st))`, measure `lemSize stmt`); the D13 walker gains `| A.AilElabel_addressGNU _ -> false` (an address-of-label is side-effect free; Lean's exhaustiveness would otherwise fail the build); `extra_import CerbCtypeInstances` stays. Auto-merged: the rest of U's switch/do rewrites, `conf.E.is_CN`/`is_CHERI`/`strict_pointer_arith`/`calling_convention` reads replacing `Global.*`/`get_calling_convention` (U's own edits; the fork's untouched `Global.is_CHERI ()` reads elsewhere stay valid lem), the I0 hunk (§0.11) |
| `frontend/model/translation_aux.lem` | 1 / 5 | the header only: U qualifies `Symbol` and imports `Mem`; F (I0b) imported `Mem` with `Symbol` open | U's two lines. The I0b `conv_arith` body auto-merges onto U's identical text (§0.11) |
| `frontend/model/translation_effect.lem` | 5 / 60 | h1 the `elab_state` record (F `fresh_supply`; U drops `calling_convention`); h2 F's `elab_init sup callconv` vs U's `elab_config` type + `elab_initial_state`; h3 `with_block_objects` (F's supply-threaded fold; U's `fun conf st ->`); h4/h5 `record_object_types_marker` (F `bind fresh_elab_int`; U `Symbol.fresh_int ()` + `elab_update`) | h1: U's fields + `fresh_supply`; h2: U's `elab_ub_or_nd`/`elab_config`/`elab_config` constructor verbatim, then `val elab_initial_state: nat -> elab_state` / `let elab_initial_state fresh_supply_seed = <| … fresh_supply= fresh_supply_seed; … |>` (R3); h3: U's two-argument lambda with F's threaded fold (`fresh_elab_int conf stx`, `ma conf st'`); h4/h5: `fresh_elab_int >>= fun marker_id -> … end >>= fun () -> return marker_id` with U's `elab_update`. Non-conflicting rewrites in the same file: `fresh_elab_int = fun _ st -> …`, `with_fresh_supply f = fun _ st -> …`, `fresh_elab_sym`/`fresh_elab_pretty_with_id`/`wrapped_fresh_symbol[_]` from `bind` to U's inline `>>=`/`return` (U removed `include State`); OCaml rep `Fork_renumber.fresh_elab_int` becomes two-argument (`let fresh_elab_int _conf st = (Cerb_fresh.int (), st)`, `ocaml_frontend/fork_renumber.ml:81`). U's new `let rec elab_mapM_aux`/`elab_foldlM_aux` get `declare {lean} termination_argument … = automatic` (the `state.lem:108` form; list-structural). The `elabM` type is U's function type: the fork's `declare {lean} fuel` wrappers follow mechanically (§0.7 S4) |
| `ocaml_frontend/ocaml_implementation.mli` | 1 / 11 | F exports `enum_definitions` + `alignof_proxy`; U exports `offsetsof/sizeof/alignof` | keep `enum_definitions`, drop `alignof_proxy`, take U's three exports; delete the `alignof_proxy` body from the auto-merged `.ml` (an unexported value would be an unused-value warning; warnings are fixed, not left) |
| `tests/tests.sh` | 1 / 2 | U adds `0342`; F (I0/I0b) added `0343`/`0344` just below | union: `0342`, `0343`, `0344` |

### 0.6 Auto-merged but load-bearing (reviewed at M1 before the commit)

`backend/driver/main.ml` (U's `elab_conf` threading through `prelude`/`frontend`; the fork's
`--cabs-json` path at `:308` calls `c_frontend (conf, io) core_std ~filename` and must pass
`Cabs_to_ail_effect.{ elab_conf }` — the OCaml build fails loudly otherwise; `--address-space-top`,
`--batch-alloc-census`, `driver_conf` untouched by U at stage 1), `backend/common/driver_ocaml.ml`
(U's `--json-batch` rewrite; the fork's census output), `backend/lean_export/cabs_json.ml` (§0.7
S6), `frontend/model/desugaring_init.lem` (§0.2 item 2), `frontend/model/driver.lem` (U's
`alignof_ival` closures over `Implementation.alignof_ty file.tagDefs`, `memcmp loc`; the fork's
`initial_driver_state*`/digest/fuel declares untouched), `frontend/model/core_eval.lem` (U's
`Implementation.sizeof_ty/alignof_ty file.tagDefs` at `Civsizeof`/`Civalignof`; `array_shift_ptrval
loc` bound through `Exception.return`), `frontend/model/nondeterminism.lem` (U's `lift_undef`; the
fork's `nd_bind`/`liftND`/`liftAction` declares), `frontend/model/ail/genTyping.lem` (U's
loc-taking `annotate_block`, the `AilSreturn` permissive arm, the `AilElabel_addressGNU` arm,
`GNUFileScopeStatementExpression`; the fork's E-A edits), `frontend/model/{errors,cabs,
constraint,undefined,ctype,core_linking,integerType,scope_table}.lem` (U's constructors and
`Symbol` qualification), `parsers/c/c_parser.mly` (U's three grammar edits + the fork's asm-refusal
edit `+8/-1`) with `c_parser_error.messages` entirely U's (the fork never edited it) — menhir
checks the messages against the merged grammar at build: a vanished error state fails loudly, and
the fix is a regeneration with the menhir in the switch (first-build finding, §0.13),
`runtime/libcore/std.core` + `std_inner_arg_temps.core` (U's `loaded_ivfromfloat`, byte-equal to
the I0b backport's; the fork's tray-45 `pread`/`pwrite` arity hunk stays — the only remaining
difference), `util/cerb_floating.ml` (U's `mul` fix; the fork never touched the file: tray 01
closes), `ocaml_frontend/switches.ml` (U's new switch, OCaml-only), `cerberus-lib.opam` +
`ocaml_frontend/dune` (`monomorphic`), `tests/run-ci.sh` (U's two-calling-convention CI; the fork's
CI lane is `test_exec.sh` over `tests/ci` with `scripts/exec_ci_baseline.txt`, so this file is
carried, not consumed).

### 0.7 Seam plan (hand-written Lean and OCaml; M2 unless noted)

- **S1 — sizeof/alignof out of the memory interface (§3.3), by moving the Lean layout where
  upstream moved the OCaml.** Finding: the generated `Implementation.lean` cannot import `CerbMem`
  (the transitive import cone of `CerbMem` already contains `Implementation` — 44 modules, via
  `Nondeterminism`/`AilTypesAux`; *derived* from the `import` lines of `generated/*.lean`), so the
  scoping's "reps implemented over `CerbMem.sizeofCtype`" cannot be placed as written. Upstream's
  own move (b3e11ea33: `offsetsof`/`sizeof`/`alignof` from `impl_mem.ml` into
  `ocaml_implementation.ml`) has an exact Lean mirror: the layout block of `CerbMem.lean` (the
  header `:380-436`, `targetPtrSize`, the two private abbrevs, `memberAlign`/`offsetsofMembers`/
  `offsetsof`/`sizeofCtype`/`alignofCtype` `_lemFuel` workers and wrappers, `:437-699`) moves into
  `CerberusImpl.lean` (whose stated purpose is the implementation-defined layout, and whose cone —
  `CerbStopSites`, `IntegerType`, `Ctype` — plus `CerbTags`/`CerbTagsWf`/`CerbFuel` never reaches
  `Implementation`), namespace `CerberusImpl`; `CerbMem` uses the moved names. Two-map form KEPT:
  upstream's moved `alignof` still reads the `Tags` global in its union arm
  (`ocaml_implementation.ml:566` at `c3ff8c53f`: `Pmap.find tag_sym (Tags.tagDefs ())`), so the
  fork's `(ambient, tagDefs)` form with `CerbTagsWf.AcyclicPair` remains a faithful mirror — no
  hypothesis restatement at stage 1 (that is stage 2's Tags removal, §3.2/§5). The reps:
  `CerberusImpl.sizeof_ty [LemFuel] (enumDefs) (readerTagDefs) (tagDefs : CerbTags.TagDefsMap)
  (ty) : Int := Int.ofNat (sizeofCtype_lemFuel LemFuel.fuel enumDefs readerTagDefs tagDefs ty)`
  (the reader's map where upstream reads the global, the explicit map where upstream passes it —
  at desugar time the reader is `desugar_time_tagDefs = Map.empty` and the explicit map is real,
  which is what the fork's pseudo-map stand-in approximated) and `alignof_ty` likewise. Bookkeeping
  that moves with the block: `scripts/fuel_hypotheses.txt` rows `CerbMem.{sizeofCtype,
  alignofCtype, memberAlign, offsetsof, offsetsofMembers}_lemFuel` → `CerberusImpl.*` (hypotheses
  unchanged; the cites `impl_mem.ml:173/:255` → `ocaml_implementation.ml` lines at `c3ff8c53f`);
  the five obligations of `CerbMem_lemMeasureProofs.lean` → a new carrier
  `CerberusImpl_lemMeasureProofs.lean` (Lake root, `handwritten_copy.manifest`; the fuel-forms
  gate enumerates carriers by the `generated/*_lemMeasureProofs.lean` glob); the failure-reach
  register rows of the moved leaves re-sealed (file column); `CerbStopSites` cites of the moved
  code through the existing `implSource` helper; `check_theorem_axioms.sh` cone names checked. The
  tray-47 `_Alignas` completeness refusal (cabs_to_ail.lem `:2811-2907`) is re-measured against the
  `coverage/alignas/*` witnesses at M4: `alignof_ty` on an incomplete type must stay a loud
  refusal, never `0`.
- **S2 — `array_shift_ptrval` in the UB monad with a loc (§3.4).** `CerbMem.arrayShiftPtrval
  [LemFuel] enumDefs tagDefs (loc : CerbLocation.Loc) pv elemTy iv : Undefined.t PointerValue`;
  the null AND function-pointer arms return `.Undef loc [.UB046_array_pointer_outside]` exactly as
  upstream's new text (both were crashes); the concrete arm `.Defined`; R-PNVI-06 stays a
  `failwithI` refusal inside the `Undefined.t`-typed body (a refusal is not a UB verdict). The
  internal pure shifts of `CerbMem.memcpy` and `memcmpM` (which gains `loc`) go through
  `Nondeterminism.lift_undef` as upstream's do; `effArrayShiftPtrval` unchanged. Retired:
  `CerbStopSites.arrayShiftNull`/`arrayShiftFunction` (the sites are gone), failure-reach register
  rows 111 (REACHABLE, witness `tests/minimal/097-null-ptr-arith.undef.c`) and 112 (UNKNOWN);
  row 110 (R-PNVI-06) stays; the migration map
  `docs/2026-10-20_outcome-protocol-register-migration.tsv` rows 93/94 are marked retired in the
  manner its header prescribes (a record is not rewritten; checked at M2). Generated callers
  (`formatted.lem`, `core_eval.lem`, `driver.lem`) follow from lem.
- **S3 — the fifth reader seed.** Upstream's switch desugaring calls
  `Mini_pipeline.typecheckAil_promoted (Implementation.integerImpl ()) sigm gamm d_e` at desugar
  time; on Lean the enum reader must be seeded with the enums registered so far (the D3 rule of
  2026-09-20), so `typecheckAil_promoted_seeded en tds impl sigm gamm d_expr` joins the four seeds
  and the cabs_to_ail.lem call site uses it.
- **S4 — the translation-fuel wrappers against the elabM environment (§3.5).** `translate_expression`
  / `translate_stmt` keep their binder lists (upstream changed neither signature: *derived* from the
  diff, no `val translate_expression`/`val translate_stmt` line moves); only the result type becomes
  upstream's function type `elab_config → elab_state → (α × elab_state)`. The absorbing payload
  `failwithI CerbFuel.fuelExhaustedMsg` is unchanged (Lean's `Inhabited` for a function type comes
  from its codomain, already derived for the tuple). `test/Unit/TranslationFuelTest.lean`'s two
  `_zero_boundary` theorems are expected to compile unchanged; if lem-lean's fuel validator rejects
  the function-typed worker shape, that is a lem-lean slice (re-pin dance), reported, not patched
  around.
- **S5 — the configuration mirrors in `Main.lean`.** `mkElabConfig [CerbGlobal.Switches] :
  Translation_effect.elab_config` mirrors `pipeline.ml` `mk_elab_config` line by line through the
  generated `Global.*` instance readers: `calling_convention := CerbDriverConfig.callingConvention`,
  `is_PNVI := Global.is_PNVI ()`, `is_CHERI := Global.is_CHERI ()`, `is_CN := (Global.backend_name
  () == "Cn")`, `strict_pointer_arith := Global.has_strict_pointer_arith ()`,
  `branching_on_unspec := .Elab_UB` (Q9: the switch is never accepted, so the constant is the
  mirror of `mk_elab_config` with the switch absent); `desug_config := { elab_conf := … }`; the two
  entry calls `Main.lean:803` (`desugar … supply addressSpaceTop desugConf …`) and `:852`
  (`translate … (ailnames, stdFunMap) elabConf coreImpl typedProg`). Error arms: the verbose
  desugar printer gains `.EXTENSION _` (`pp_errors.ml` `short_message`: "use of GNU address-of-label
  extension (try --permissive)"); the batch path prints the fork's `Error {msg: "desugaring failed at
  …"}` line as today (the oracle prints `Pp_errors.to_string` to stderr), so no byte-exact text is
  mirrored there; `ArityMismatchRun` has no Lean printer to extend (Main carries no
  `core_typing_cause` printer: *derived* from `grep`). The `0213` message change and the `agnotic`
  typo fix are oracle-side `pp_errors.ml` text with no Lean mirror (`grep` over `lean_frontend/*.lean`
  finds neither string) — the batch-diagnostics rider of Tier A row 7 is measured, not assumed.
- **S6 — the GNU label-as-value constructor.** `backend/lean_export/cabs_json.ml`: the exhaustive
  `cabs_expression` match gains `CabsElabel_addressGNU id` (warning 8 is an error in
  `ocaml_frontend/dune`, so the OCaml build is loud); `CabsImport.lean` gains the arm (today the
  tag would fall into the fail-closed `unknown tag`); `AilSyntax.AilElabel_addressGNU` is generated.
  `CerbPP.lean` has no Cabs/Ail expression printer (*derived*: no `AilEgcc_statement`/
  `CabsEgcc_statement` arm in it) — nothing to add, contrary to the charter's seam list; recorded.
  In matched mode both engines refuse the construct (`guard_extension` under `isPermissive = false`,
  `CerbGlobal.isPermissive` by `rfl`): a scratch probe at M4 records the agreement.
- **S7 — the refused switch (Q9).** No `CerbSwitch` constructor; `judgeSwitches` refuses
  `branching_on_unspec_is_nd` as an unknown name (R-PNVI-12). `scripts/check_cli_refusals.sh` gains
  `expect_refused "--switches=branching_on_unspec_is_nd" "R-PNVI-12"`; SUPPORTED/CONTRACT lines at M6.
- **S8 — the Core-quotation constructor census.** `undefined.lem` adds `UB_unspec_if`/`_while`/
  `_switch` to `unspecified_ub_context`, a Core-reachable type: `CerbQuote.lean:512-513`,
  `test/Unit/CoreQuoteTest.lean:727-728` (and its pinned "638 model constructors" line → 641) and
  `speclab/test/SLUnit/EmitCore.lean:252-253` each gain three arms (exhaustive matches: the build
  names them). The Cabs/Ail constructors are outside the quotation surface.

### 0.8 Measure-proof list (M3; stage-1 share of §5)

| carrier | change | effort (*derived* from the template) |
|---|---|---|
| `Translation_lemMeasureProofs.lean` | `collect_cases__stable` / `_measure_sufficient` (`:91-125`) deleted; `collect_switch_content_aux_stable` / `_measure_sufficient` written on the same template (strong induction on `statement.lemSize`, `key`/`keys`, `cases node <;> simp`); the new state threads `visible_switch_syms` through `AilSblock` with a save/restore — same recursion shape | ~35 lines, 0.5 day incl. the `St.get`/`St.update` arms |
| `CerberusImpl_lemMeasureProofs.lean` (new) | the five layout obligations moved verbatim from `CerbMem_lemMeasureProofs.lean` (namespace rename only); `CerbMem_lemMeasureProofs.lean` keeps `typeofMval`/`unqualifyAndUnatomic`/`memValueToBytes`/`reconstructValue`/`reconstructValueAbst` | mechanical; kernel replay over both |
| `Formatted` | `load_character_array_aux` absorbing: `_zero` statement regenerated with the `loc` binder | build check |
| `TranslationFuelTest` | `translate_expression`/`translate_stmt` `_zero_boundary` over the function-typed result | build check (S4) |
| `scripts/fuel_hypotheses.txt` | 5 rows renamed (S1) with cites moved to `ocaml_implementation.ml`; the `hack`/`to_pure`/`to_pures` rows' `driver.lem` cites shift by upstream's insertions (one line before `prepare_exit`: `1309-1316` → `1310-1317`, likewise `1275-1296`, `1331-1338`, `1352-1356`, `1369`, `1473-1477`, `1611-1616` — verified by `grep` after the merge), and `CerbCoreShape.lean`'s header cite | 0.1 day |
| kernel replay (the named gate) | `lake env leanchecker` over `Translation_lemMeasureProofs`, `Translation_auxiliary`, `CerberusImpl_lemMeasureProofs`, `CerbMem_lemMeasureProofs`, `Formatted_auxiliary`, `TranslationFuelTest`; exit statuses quoted | — |

No option bumps, kernel-only tactics. `collect_visibles_`, `erase_loop_control_aux`,
`translate_constant` and the other measured functions are untouched by upstream at stage 1
(*derived*: no line of the upstream diff names them).

### 0.9 Baseline-movement forecast (M4; each moved row is dispositioned, never silently re-recorded)

| lane | forecast | why |
|---|---|---|
| A1 `test_unit.sh` | gate lists move: Lake roots +1 and manifest +1 (S1 carrier), `check_cli_refusals` +1 line (S7), core-quote census 638→641 (S8), failure-reach register (rows 111/112 retired; the S1 leaves re-sealed by file), fork-drift (M5), fuel-forms (new carrier), `check_handwritten_sync` | §0.7 |
| A2 `tests/minimal` (`exec_baseline.txt`) | `097-null-ptr-arith.undef.c`: both engines crash today → both UB046 (tray 04, f4a3a3d54); switch/do-while rows: Core shape changes, verdicts expected unchanged — any verdict movement must trace to 588672e95/cabe81c3b/ad233f84f or is a finding; float multiplication rows (766073467): any recorded DIFF where Lean multiplied and the oracle added becomes MATCH | FIX commits |
| A3 `tests/coverage` | `alignas/*` stay (tray 47 unfixed); union-init rows unchanged (D11 is a fork refusal); switch/do-while re-measured | |
| A4 / A4b / A4c | debug: as A2; float: the `mul` fix (any DIFF→MATCH flips; the lane is 93/93 MATCH today, so none expected unless Lean mirrored the bug — measured); bytes: MUST NOT move (oracle-independent) | 766073467 |
| A5 `test_libc_exec.sh` + Tier B 14 `libc_prep.sh` | `tests/libc/libc.core.sha256` RE-PIN expected: the libc dump's Core TEXT changes wherever libc has a `do`/`switch` (83b1a7424, cabe81c3b, 588672e95); verdict rows must not move; the quotation pins `test/CoreQuote/core-quote-libc*.sha256` re-derive with it (A15's inner_arg_temps pin too) | ADD/FIX |
| A6 / A6b multi-TU | no movement; 6b's failure-class projection is the tell for the C1 mint order (R4) | |
| A7 / A8, Tier B 2/3 (`tests/ci` parse/core) | tests/ci 252 → 253 files (0342); `--pp core` round trips over the new do/switch shapes: no movement expected | |
| A9 `test_elab.sh` | signature-level dump: no movement expected (body shapes only) | |
| A10 libxml2 URI, B1 chvalid | no movement expected; measured | |
| A11 CN coverage | unchanged (the CN parser split is stage 2) | |
| A12 address-space, A13 memory-access | MUST NOT move (fork-only mechanisms) | |
| A14 PNVI | `097` under `tests/minimal` moves as in A2; `R-PNVI-06`/`-07`/`-01 ORACLE_CRASH` rows stay (upstream's symbolic arm unchanged; trays 51/52/53 open) | f4a3a3d54 |
| A15 inner_arg_temps gate | 0343/0344 already adopted; the libc pin propagation only | |
| B4 `test_verify.sh` / `check_fixture_freeze.sh` | `scripts/fixture_corpus.sha256` + the `tests/verify` pins re-derive where a fixture's Core text has a `do`/`switch` — a dedicated re-pin citing 83b1a7424/cabe81c3b | |
| B5 immaculate | tray-44 rows stay; the `zd-z2fl03` diagnostic-text row stays | |
| B6 speclab | rebuild (S8 arms); gates unchanged | |
| B7 gcc second oracle | the `SKIP_LEAN_CRASH` row for the null-shift class flips to agreement (loud improvement, re-recorded) | tray 04 |
| B10 / B12 pristine oracle | instrument rebuilt at `c3ff8c53f` (§0.10); the 9 register cases re-derived: 8 `shared-model-fix` (trays 37/44/47 unfixed in range) expected to remain with refreshed rationale, the `diagnostic-text` case re-checked; new rows only where the new base changed something the fork mirrors differently (none expected) | §6.4 |
| Tier C `exec_ci_baseline.txt` (244 rows) | +1 row (`0342`, MATCH expected); `0120`/`0121 … .error.c CERB_SKIP` → both-UB agreement (the `.undef.c` rename is stage 2's 0676e9fca; the names stay); `0343`/`0344` stay CERB_SKIP (exhaustive timeout); `0213` stays | f4a3a3d54 |
| Tier C csmith, `test_upstream_oracle --corpus ci/csmith`, `test_ci_sweep` | reporting re-runs; movement in the `CERB_SKIP` class only if a desugaring fix unlocks a file | |
| Tier A row 7 rider `test_batch_diagnostics.py` | no movement expected (S5); measured | 06759464d, 97371d8ed |

### 0.10 Pristine-instrument and fork-drift plan (M5; §6)

1. Scratch pristine source at `c3ff8c53f` from the mirror, no network: `git -C
   deps/mirrors/cerberus.git archive c3ff8c53f | tar -x -C .tmp/pristine-c3ff8c53f/`; then
   `scripts/ce make -C .tmp/pristine-c3ff8c53f prelude-src` with the fork's lem `e6d8db5` → the new
   `CERB_UPSTREAM_TREE` for this worktree's gate runs (`.tmp/pristine-c3ff8c53f/ocaml_frontend/
   generated`, shell-scoped; the container's `deps/cerberus-upstream` and `scripts/env.sh` move only
   at landing, by the orchestrator). File count expected 86 → 86 (no stage-1 deletions; `config.ml`
   is stage 2).
2. `scripts/fork_drift_manifest.txt`: `[meta] merge-base=c3ff8c53f05982745f9b3a10b3d05442e214bcb5`,
   `lem-pin` unchanged (`e6d8db5…`), `renumber=arc13` unchanged; `--refresh` and a reviewed WHOLE
   re-derivation of layer 2 (the one case where the set is rebuilt rather than single-row edited;
   said so in the NOTE). Expected dispositions (*derived* from the per-file history): [files]/
   [source-content] (93 rows) all re-pinned against the new base; rows expected to LEAVE: none by
   name at stage 1 (`translation_aux.lem` keeps the fork's totality declares), the I0/I0b NOTEs
   closed; [expected-semantic] (22): `translation_aux.ml` expected to leave (its only generated
   delta was the I0b backport, now upstream's), `core_typing.ml`'s justification loses the R3 part
   (tray 45 keeps it), `implementation.ml` loses the `alignof_proxy` part (the E-A reader keeps it;
   the new Lean-only declares emit nothing into OCaml), the supply/top/seed/refusal deltas
   (`cabs_to_ail*.ml`, `mini_pipeline.ml`, `translation.ml`, `translation_effect.ml`) re-derived;
   [expected-cosmetic] (10) re-derived (`mem.ml`'s `(*val …*)` lines move with the deleted vals).
   Every surviving justification re-read against upstream's new text; the ones that merged away
   dropped. `check_fork_drift.sh` + `--selftest`, `check_pin_sites.sh` green.
3. The pristine EXECUTABLE: `scripts/build_independent_oracle.py` `CERBERUS_REV` →
   `c3ff8c53f05982745f9b3a10b3d05442e214bcb5`; `LEM_REV` `3802cb0…` kept if it builds the new base
   (the commit is present in `lem-lean`'s object store: `git cat-file -t` → `commit`, so the build is
   offline: `--lem-repo lem-lean --cerberus-repo <this worktree> --out .tmp/upstream-oracle-c3ff8c53f`);
   `test_upstream_oracle.py --build-manifest … --corpus tier-b` and `--plant` (Tier B rows 10/12);
   `scripts/upstream_oracle_differences.json` (schema + 9 cases) re-derived per §0.9.
4. Everything citing `b9aeedcb4` as the base outside dated records moves (`CONTRACT.md`'s matched-mode
   line, `build_independent_oracle.py`, the manifest); dated records are untouched. `CerbStopSites`
   cites stay pinned to the revision they quote except for the sites whose source moved or retired
   (S1, S2), which cite `c3ff8c53f`.

### 0.11 The backports' merge-away checks (M1, before the merge commit)

Already byte-equal to upstream before the merge (*derived*: `git diff --stat c3ff8c53f HEAD` prints
no line for them): `tests/ci/0343-subzero-floating-to-_Bool.c`, `tests/ci/0344-ptr-to-_Bool-param.c`
and both `expected/` files. After the merge: `translation_aux.lem`'s `conv_arith` region equals
`c3ff8c53f`'s (the whole file differs from upstream only by the fork's totality declares);
`translation.lem`'s shared argument-conversion helper (the I0 hunk) equals upstream's; `std.core` and
`std_inner_arg_temps.core` differ from upstream only by the fork's tray-45 `pread`/`pwrite` hunk
(today: `3 files changed, 7 insertions(+), 5 deletions(-)` including `cerb_floating.ml`, which
upstream's `mul` fix closes). Tray 15 and the PR-1020 entry are marked carried by the base at M6;
the manifest NOTEs close at M5.

### 0.12 The three refusals (D11–D13)

- D11 union-initializer (`desugaring_init.lem`, auto-merged; §0.2): build check + witness re-run.
- D12 anonymous members (`cabs_to_ail.lem` `desugar_struct_declaration`, `:2735-2747`, outside the
  hunks): verified unchanged after the merge; `check_anonymous_members_refusal.sh`.
- D13 compound assignment (`translation.lem`, the walker `:1403-1464` and its arm; the walker gains
  the `AilElabel_addressGNU` arm): `check_compound_assignment_refusal.sh`; its run point is the
  elaboration of `AilEcompoundAssign`, which 334a1563b does not move; the constant-expression path
  (`eval_mode`) reaches it through the mini-run's `toCore`, where the refusal must stay a pure
  `error`, undiscardable — re-measured with the witness inside a case label and an array bound.
- Also re-run: `check_asm_refusal.sh`, `check_item_g_refusals.sh`, `check_union_init_refusals.sh`,
  `check_cli_refusals.sh`, `check_runtime_resolution.sh`.

### 0.13 Expected first-build findings (reported as findings, not patched around)

1. menhir's `c_parser_error.messages` against the merged grammar (the fork's asm-refusal edit on
   upstream's regenerated messages).
2. lem-lean's renamer on `Symbol`-qualified references (3771dce03): the declaration-name set of
   `lean_frontend/generated/*.lean` is diffed before/after as the one-off check of §3.6.
3. lem-lean's fuel validator on the function-typed `elabM` workers (S4).
4. upstream Lem `3802cb0` on the `c3ff8c53f` sources (§0.10 item 3).
5. `Inhabited`/`BEq` derivation for the new types `elab_config`, `elab_ub_or_nd`, `eval_mode`,
   `desug_config` and the `switch_info.promoted_ty` field.
6. OCaml warnings-as-errors in the fork's `main.ml`/`cabs_json.ml` (§0.6, S6) — loud by design.

### 0.14 Headline numbers (*derived*)

- Upstream: 25 commits, 68 files, +5436/−5088 (7577 of those lines are the menhir messages file);
  11 of the 16 FIX rows, 4 ADD, 3 REF; 6 files added, 0 deleted, 0 renamed.
- Conflicts: 13 files, 33 hunks, 657 marker-region lines; the hot four (`mini_pipeline` 169,
  `implementation` 133, `cabs_to_ail_effect` 76, `translation` 74) carry 452 of them.
- Seams: 8 (S1–S8), of which S1 moves ~320 lines of `CerbMem.lean` into `CerberusImpl.lean` and
  adds one proof carrier; 2 stop sites and 2 register rows retire (S2); 1 new reader seed (S3);
  6 hand-written exhaustive matches gain arms (S6: `cabs_json.ml`, `CabsImport.lean`; S8: three; the D13 walker).
- Proofs: 1 new obligation (`collect_switch_content_aux`), 1 deleted, 5 moved, 2 build checks;
  `fuel_hypotheses.txt`: 5 rows renamed and re-cited, 3 rows re-cited.
- Baselines expected to move: `exec_baseline` (097), `exec_ci_baseline` (+1 row, 2 rows
  crash→UB), the libc content pin + 2 quotation pins, B4 fixture pins where Core text moved, the
  gcc-oracle row for the null-shift class, A14's 097 row; MUST-NOT-move: bytes (A4c), address-space
  (A12), memory-access (A13).
- Fork drift: 93 + 93 + 22 + 10 rows re-derived as a whole; 2 NOTEs closed; `translation_aux.ml`
  expected to leave layer 2.

### 0.15 M1 in order

1. `git merge --no-ff c3ff8c53f` (Q1) in this worktree; resolve the 13 files per §0.5 (R1–R5);
   review §0.6; apply the OCaml-side seam edits that the OCaml build needs (`fork_renumber.ml`
   arity, `cabs_json.ml` arm, `main.ml` `c_frontend` call, `ocaml_implementation.ml` dead body);
   the `monomorphic` dependency is upstream's own `cerberus-lib.opam`/`dune` lines.
2. `scripts/ce make clean-prelude-src prelude-src` (lem on the merged model; the `Symbol`
   qualification and exhaustiveness warnings read), OCaml build (`dune build backend/driver/main.exe
   cerberus-lib.install`, local install, `cerberus.install`), `make lean-prelude-src` (the Lean tree
   regenerates; the Lean build is M2's).
3. §0.11 checks; the declaration-name set snapshot of the generated Lean tree (§0.13 item 2) taken
   before and after.
4. One merge commit whose message lists every resolution by file with its rule; report with the
   hash, `git diff --stat`, the lem/dune last lines verbatim, and the first-build findings.

---

## 1. M1 — the merge (2026-10-29)

`git merge --no-ff --no-commit c3ff8c53f` on `6a0771381` (M0): the 13 conflicts of §0.1, resolved per
§0.5 (rules R1–R5), each hunk replaced by the planned text; git `rerere` (repository config, not this
slice's) recorded the preimages. Edits outside the conflict hunks that the resolutions required:

- `translation_effect.lem`: `fresh_elab_int`/`with_fresh_supply` take upstream's reader component
  (`fun _ st ->`); `fresh_elab_sym`, `fresh_elab_pretty_with_id`, `wrapped_fresh_symbol[_]` use
  upstream's inline `>>=`/`return` (upstream removed `include State`, so `bind` is gone);
  `fresh_elab_int conf stx` inside `with_block_objects`' fold; `declare {lean} termination_argument
  elab_mapM_aux / elab_foldlM_aux = automatic` (the `state.lem:108` form); the fork-added, never-called
  single-argument helpers `push_block_objects`/`pop_block_objects` (absent from upstream's file, no
  caller in the model — *derived*: `grep` over `frontend/model`) deleted rather than re-typed.
- `translation.lem`: the `default_` mint on upstream's new line (`E.fresh_elab_pretty_with_id … >>=
  fun default_sym ->`, R4); the fuel/measure declares `collect_cases_` → `collect_switch_content_aux`
  (R3); the D13 walker's `| A.AilElabel_addressGNU _ -> false`; three fork comments reworded to the new
  names and the moved run-point line (`mini_pipeline.lem:181`).
- `mini_pipeline.lem`: the one bare `digest ()` → `Symbol.digest ()` (3771dce03).
- `cabs_to_ail.lem`: upstream's `Mini_pipeline.typecheckAil_promoted impl sigm gamm d_e` in the switch
  arm → `typecheckAil_promoted_seeded (Map.fromList sigm.enum_definitions) E.desugar_time_tagDefs
  impl sigm gamm d_e` (S3, the fifth seed, defined beside the four in `mini_pipeline.lem`).
- `cabs_to_ail_effect.lem`: `alignof_ty_seeded`'s type follows upstream's `Implementation.alignof_ty`
  (`map Symbol.sym (Loc.t * Ctype.tag_definition) -> ctype -> integer`); `get_alignof` names upstream's
  rebuilt map `ctype_tagDefs` so the enum seed still reads the desugar state's own definitions.
- `defacto_memory.lem`: the fork's `declare {lean} termination_argument impl_sizeof_ival_aux =
  automatic` removed with upstream's deletion of the function (first-build finding 1, R2).
- OCaml seams: `ocaml_frontend/fork_renumber.ml` `fresh_elab_int _conf st` (two arguments);
  `backend/lean_export/cabs_json.ml` `CabsElabel_addressGNU id -> tag "CabsElabel_addressGNU"
  [("label", json_of_identifier id)]`; `backend/common/ail_sym_hwm.ml` `AilElabel_addressGNU sym ->
  note_sym sym` (first-build finding 2; the label symbol is minted by the TU's desugarer, so it is
  in the window as `AilEident`'s is). `backend/driver/main.ml` needed nothing: its `c_frontend` call
  auto-merged to upstream's `Cabs_to_ail_effect.{ elab_conf }` form and the `--cabs-json` path uses
  the parser only. `alignof_proxy` has no body left anywhere (*derived*: `git grep`), so there was
  nothing to delete.

### 1.1 First-build findings (both the §0.13 item-6 class; none needed a lem-lean change)

1. lem, OCaml target, first run — `.tmp/m1-prelude-src.log`:
   ```
   File "frontend/model/defacto_memory.lem", line 2619, character 1 to line 2619, character 68
     Type error: unbound name: impl_sizeof_ival_aux
   make: *** [Makefile:231: ocaml_frontend/generated/utils.ml] Error 1
   ```
   A fork declare on a function upstream deleted (b3e11ea33); removed (R2).
2. dune, first run — `.tmp/m1-dune-build.log`:
   ```
   File "backend/common/ail_sym_hwm.ml", lines 159-204, characters 19-48:
   Error (warning 8 [partial-match]): this pattern-matching is not exhaustive.
     Here is an example of a case that is not matched: AilElabel_addressGNU _
   ```
   The arc-13 symbol-window walker's exhaustive match; the arm added as above.

Not fired: §0.13 item 1 (menhir accepted upstream's messages file against the merged grammar: `Read
1207 sample input sentences and 1207 error messages.`; the grammar-conflict warnings in the log are
those of upstream's `c_parser.mly` — whether the fork's asm edit adds any is checked against the
pristine build at M5), item 2 (declaration-name set below: no existing name moved), items 3–5 are
Lean-build items (M2). lem's warnings (`ocaml_frontend/lem.log`, 115; `lean_frontend/lem.log`) are
upstream's pre-existing non-exhaustiveness warnings in `frontend/concurrency/cmm_csem.lem` and the
renamer's notices; in the files the merge touched only renamer notices appear, two of them new and
upstream-caused: `Cabs_to_ail_effect.read_config` → `read_config0` and the constructor function
`Translation_effect.elab_config` → `elab_config0`, identically on both targets (the OCaml log line
`renaming 'read_config' to 'read_config0' for target ocaml`, cabs_to_ail_effect.lem:408).

### 1.2 Build lines (verbatim)

`scripts/ce make clean-prelude-src prelude-src` (second run, `.tmp/m1-prelude-src-2.log`), last lines:
```
[SED] patching things up in [sibylfs/generated]
exit=0
```
86 files in `ocaml_frontend/generated/` (*derived*: `ls … | wc -l`).

`dune build backend/driver/main.exe cerberus-lib.install`, `dune install --prefix _build/local-install
cerberus-lib`, `dune build cerberus.install` (`.tmp/m1-dune-build-2.log`):
```
build exit=0
install exit=0
check_lem_sync: OK (src 3a149c2d55cd9e61e589be19dd37eecff6c26aa6001f2ff1eebb86a01e749ce0, gen c5da13b2beeccb1e5e24007e0fed576ceea04fe5851518cee5ba0f1ad02e2f21)
(debug 0): constructValue_aux: is WRONG for union ==> always assigning the first member
cerberus.install exit=0
```
(the `(debug 0)` line is upstream's standing print during the libc staging, as before the merge.)
Smoke, `main.exe --runtime=_build/install/default --exec --batch` on `int main(void){ return 42; }`:
```
Defined {value: "Specified(42)", stdout: "", stderr: "", blocked: "false"}
```

`scripts/ce make lean-prelude-src` (`.tmp/m1-lean-prelude-src.log`), last lines:
```
check_handwritten_sync: OK (56 hand-written files byte-identical to lean_frontend/generated/; manifest lean_frontend/handwritten_copy.manifest)
[STAMP] recording Lean lem-sync content stamp
check_lem_sync: recorded lean_frontend/lem_sync.sha256 (src 3a149c2d55cd9e61e589be19dd37eecff6c26aa6001f2ff1eebb86a01e749ce0, gen 1d54c255786e0f25fb4a408ae68e63fd07bd6ab397a8bda09929c52ccb7631cc)
exit=0
```
228 files in `lean_frontend/generated/` (unchanged count). The Lean side is not built at M1 (M2).

### 1.3 The backports merged away (§0.11)

- `git diff c3ff8c53f -- frontend/model/translation_aux.lem`: only the fork's nine lines of
  thread-B `termination_argument` declares and their comment; the I0b `conv_arith` body is upstream's.
- `translate_function_call` (the I0 hunks' home) against `c3ff8c53f`: the only difference is the fork's
  C1 supply draw (`E.mapM (fun (i, arg_e) -> E.fresh_elab_sym (Symbol.SD_FunArg …)) …` for upstream's
  `mapi … Symbol.fresh_funarg …`), a documented fork-ahead delta; the argument-conversion sharing is
  upstream's text.
- `runtime/libcore/std.core`, `std_inner_arg_temps.core` against `c3ff8c53f`: `2 files changed, 6
  insertions(+), 4 deletions(-)` — exactly the fork's tray-45 `pread`/`pwrite` arity hunk in each.
- `util/cerb_floating.ml`: no difference (tray 01's `mul` fix carried by the base).
- `tests/ci/0343*`, `0344*` and their expecteds: no difference (already before the merge).

### 1.4 Declaration-name set of the generated Lean tree (§0.13 item 2)

Before (M0 tree) 4618 names, after 4636 (*derived*: `grep -oE '^(def|theorem|…) +name'` over
`lean_frontend/generated/*.lean`, sorted; `.tmp/m1-declnames-{before,after}.txt`). `diff`: 18 removed —
`collect_cases`, `collect_cases_`, `collect_cases__lemFuel`, `collect_cases__lemFuel_zero`,
`collect_cases__measure_sufficient`, `collect_cases_state`, `elab_init`, `empty_switch_info`,
`evalConstantExpressionAux`, `get_calling_convention`, `get_current_return_type`, `impl_alignof_ival`,
`impl_sizeof_ival`, `impl_sizeof_ival_aux`, `is_in_switch`, `pop_block_objects`, `push_block_objects`,
`runStateM_errors`; 36 added — upstream's new definitions (`collect_switch_content[_aux][_lemFuel]`,
`collect_switch_content_state`, `elab_bind/return/update/mapM[_aux]/foldlM[_aux]`, `elab_config`,
`elab_config0`, `elab_ub_or_nd`, `elab_initial_state`, `eval_mode`, `evalIntegerConstantExpressionAux`,
`evaluate_case_constant_expression`, `evaluate_integer_constant_expression_aux`, `extension_cause`,
`get_current_return_type_opt`, `get_switch_promoted_type`, `guard_extension`, `init_switch_info`,
`is_inner_arg_temps`, `lift_undef`, `read_config`, `read_config0`, `runElabM`, `runElabM_errors`,
`translate_branch_on_unspec`, `typecheckAil_promoted`, `desug_config`), the generated obligation pair
`collect_switch_content_aux_lemFuel_zero` / `_measure_sufficient`, and the fork's
`typecheckAil_promoted_seeded`. No pre-existing name was renamed by the `Symbol` qualification.

### 1.5 Refusals at M1

D11 (`desugaring_init.lem`) type-checked and generated on both targets with upstream's record change
(the build check of §0.2 item 2); D12's arm and the asm refusal are untouched by the merge (outside the
hunks, verified by reading); D13's walker gained the label arm. Witness re-runs are M4's.

---

## 2. M2 — seams, the Lean build and the registers (2026-10-29)

### 2.1 Seams as applied (§0.7)

- **S1 (layout move).** `CerbMem.lean`'s layout block (`targetPtrSize`, the two abbreviations, the
  five `_lemFuel` workers and their measured one-map wrappers; 330 lines) moved into
  `CerberusImpl.lean` under `namespace CerberusImpl` (`import CerbTagsWf` added; its cone never
  reaches `Implementation`); `CerbMem` uses the names through its existing `open CerberusImpl`;
  `mkCtype` moved with it (first build pass: `Unknown identifier mkCtype`). The reps
  `CerberusImpl.sizeof_ty`/`alignof_ty (enumDefs) (_readerTagDefs) (tagDefs) (ty) : Int` are the
  measured one-map wrappers over the EXPLICIT map, fuel-free — so `implementation.lem`'s two
  `fuel_consumer` declares planned in §0.5 were dropped again ([AGENT 2026-10-29]: a declare that
  says "reads the fuel" over a fuel-free body is false; the `reader_consumer` declares stay).
  Deviation from a perfect mirror, documented in both files: at `c3ff8c53f` upstream's moved
  `sizeof` reads the threaded map in its union arm (`:502`) while `alignof` still reads the Tags
  global (`:566`); the Lean worker keeps both union arms on `ambient`. `CerbTagsWf.Ranked` is
  symmetric over the two lookups, but the stable proof's single potential `tp` would need a
  per-function lookup to mirror the half-moved arm — a restatement, excluded at stage 1 (§0.3,
  accepted plan); unobservable at every stage-1 call site (the wrappers pass one map twice;
  `sizeof_ty`/`alignof_ty` are those wrappers); stage 2's Tags removal is the mover. The
  `_readerTagDefs` parameter is received and unused: at desugar time (`get_alignof`) the explicit
  map is the desugar state's real table where upstream's global is empty (Not_found) — the value
  the fork's pre-merge pseudo-map `alignof_ty` already gave; M4's alignas witnesses re-measure it.
  Bookkeeping moved: `CerberusImpl_lemMeasureProofs.lean` (new carrier: the Layout, LayoutStable
  and LayoutObligations sections of `CerbMem_lemMeasureProofs.lean`, 774 lines, namespace rename
  only; the CerbMem carrier keeps typeofMval/unqualifyAndUnatomic/memValueToBytes/reconstruct and
  imports the new one), Lake root + `handwritten_copy.manifest` (+1 each), five `fuel_hypotheses.txt`
  rows re-keyed (`CerberusImpl.*_lemFuel`, hypotheses unchanged, the offsetsof row's cite extended
  to `c3ff8c53f`), 14 failure-reach register rows re-keyed (§2.4), `CerbStopSites`: the 14 layout
  sites relabelled `CerberusImpl.*` and re-cited to `ocaml_implementation.ml` at `c3ff8c53f`
  through a new `implSourceStage1` helper (targetPtrSize `:484-488` — upstream's failure there is
  now `raise Missing_implementation_detail`, still a crash; offsetsof `:439-440`; sizeofVoid/
  IncompleteArray/Function `:470-471`; sizeofInteger `:472-476`; sizeofFloat `:477-481`;
  sizeofUnion `:501-504`; alignofVoid `:523`; alignofFunction `:535-536`; alignofInteger
  `:524-528`; alignofFloat `:529-533`; alignofStruct `:544-547`; alignofUnion `:565-568`).
  `CerbCall.allocErrno` mirrors `drive`'s new `alignof_ival` closure (`CerbMem.integerIval
  (CerberusImpl.alignof_ty enumDefs tagDefs file1.tagDefs signed_int)`, a `fileTagDefs` parameter);
  `test/Unit/FuelExemplar.lean`'s `alignofIval_signed_int` becomes `alignof_ty_signed_int (tds)`
  (`rfl`, any map: the integer arm never consults it) and its two `sizeofCtype` facts re-point;
  `OpaqueFailureTest`'s `targetPtrSize` probe re-points; `CerbTagsWf`'s comment.
- **S2 (array shift).** `CerbMem.arrayShiftPtrval [LemFuel] enumDefs tagDefs (loc) pv elemTy iv :
  t0 PointerValue` (the generated `Undefined.t` is the top-level `t0`): null and function-pointer
  arms `.Undef loc [.UB046_array_pointer_outside]`, concrete `.Defined`, R-PNVI-06 unchanged
  (`failwithI` inside the UB-typed body). `memcpyM`'s per-byte loop lifts the dst then src shifts
  through the generated `lift_undef` in upstream's order (`impl_mem.ml:2459-2462` at `c3ff8c53f`);
  `memcmpM` gains `loc` (used by the per-byte load, which read `CerbLocation.unknown` before) and
  lifts its shift (`:2471-2480`). `CerbStopSites.arrayShiftNull`/`arrayShiftFunction` deleted with a
  dated note; register rows and the migration map in §2.4.
- **S3** done at M1 (`typecheckAil_promoted_seeded`). **S4**: `TranslationFuelTest` compiled
  unchanged over the function-typed `elabM` (lem-lean's validator accepted the shape; §0.13 item 3
  did not fire). **S5**: `Main.lean` builds `elabConf : elab_config` field by field as
  `pipeline.ml:726-737 mk_elab_config` does (`calling_convention1` is the generated field name;
  `is_PNVI`/`has_strict_pointer_arith` through the switch instance; `branching_on_unspec := .Elab_UB`,
  the constant `mk_elab_config` computes with the never-accepted switch absent) and `desugConf`;
  the two entry calls take them; the verbose desugar printer gains the `.EXTENSION
  .EXT_GNUlabelAsValue` arm (pp_errors.ml:47-49/:574-575). **S6**: `CabsImport` arm
  `CabsElabel_addressGNU` (field `label`). **S7**: `check_cli_refusals.sh` expects
  `--switches=branching_on_unspec_is_nd` refused as an unknown switch name. **S8**: the three
  `unspecified_ub_context` arms in `CerbQuote.lean`, `test/Unit/CoreQuoteTest.lean`,
  `speclab/test/SLUnit/EmitCore.lean`; the visitor's census assertion
  (`test/CoreQuote/CoreQuoteVisitor.lean:85`) 638 → 641.

### 2.2 M3 work pulled into M2 (the obligation shells are Lake roots; the build cannot be green without them)

- `Translation_lemMeasureProofs.lean`: `collect_cases__stable`/`_measure_sufficient` → the
  `collect_switch_content_aux` pair, the C2 template unchanged apart from the names (the new
  AilSblock arm's save/restore binds are outside the recursive positions the `key`/`keys`
  rewrites touch).
- `Defacto_memory_lemMeasureProofs.lean`: `memcmp_load_aux_stable_aux`/`_measure_sufficient`
  gain the `loc1` binder (upstream f4a3a3d54 changed `defacto_memory.lem`'s worker too — a
  stage-1 proof item the scoping's §5 listed only under stage 2's deletions; recursion and measure
  unchanged).
- A fork RESTATEMENT in shared lem (finding): upstream f4a3a3d54 rewrote `Formatted.
  store_chars_in_array` as `let rec … zero_terminated ptrval = let loc = … in function …`; the Lean
  target renders the `function` as a lambda in the body, and Lean's structural recursion no longer
  sees the decreasing list (`fail to show termination … Cannot use parameter ptrval`). The fork
  makes the list an explicit parameter (`… ptrval cs = let loc = … in match cs with … end`) — an
  eta-expansion, OCaml semantics identical, the arc-3/threadB restatement class (as `many`/`many1`);
  the generated `formatted.ml` now differs from upstream's by the let placement, a fork-ahead
  delta to register at M5. A lem-lean improvement (eta-expanding `let … in function` recursive
  bodies into parameters) would remove the delta; not needed for this slice, reported.

### 2.3 Build and warnings (verbatim)

Three passes: pass 1 `error: generated/CerberusImpl.lean:535:69: Unknown identifier `mkCtype``
(fixed: moved); pass 2 three roots (`Formatted` termination, `Defacto_memory_lemMeasureProofs`,
`Translation_lemMeasureProofs` — §2.2); pass 3 after `scripts/ce make prelude-src
lean-prelude-src` (`.tmp/m2-build-3.log`):
```
21:47:49
regen exit=0
21:48:40
build exit=0
21:49:11
```
(`capped lake build CerberusLean cerberus-lean` from `lean_frontend/`, `CERB_MEM_MAX=32G`: every
Lake root and the driver, 31 s on the warm tree.) Warnings in the rebuilt closure: 828, all in
generated modules (`Cmm_csem` 144, `Defacto_memory` 92, `Core_reduction` 56, `Core_typing` 53,
`Core_run` 48, …) except ONE in a hand-written file,
`warning: generated/CerbMem.lean:1647:28: Variable name `onConcurRead` is not explicitly
referenced.` — pre-existing (`git diff 676f9f21c -- lean_frontend/CerbMem.lean` has no hunk at
`caseMemValue`; the whole module was recompiled because its text moved). No new hand-written
warning. The §0.13 Lean-side items: 3 (fuel validator) and 5 (`Inhabited`/`BEq` for the new types)
did not fire.

### 2.4 Gates and register movements (verbatim last lines)

```
check_exec_totality: CLEAN (22 generated modules + hand-written CerbND, 0 allowlisted)
check_lakefile_roots: OK (228 roots = 228 generated modules + the exe root Main; 86 auxiliary modules listed as roots — names only; every carrier is built by check_fuel_forms.sh)
check_failure_reach: resealed 238 rows of scripts/failure_reach_register.txt (review change: commit with the justification)
check_failure_reach: OK (238 pure failure sites = the 238 register rows exactly (236 in the exec dependency closure + 2 unresolved-owner; key = file/owner/token/message, shared keys lengthened, both d
check_fuel_forms: forms partition OK (67 MEASURED + 13 ABSORBING + 0 ambient-reachable + 8 ambient-unreachable = 88 fuel'd workers)
check_handwritten_sync: OK (57 hand-written files byte-identical to lean_frontend/generated/; manifest lean_frontend/handwritten_copy.manifest)
```
(The exec-totality list is unchanged at stage 1 — no module was added or removed; the 88 fuel'd
workers are the 88 of the base: `collect_switch_content_aux` replaced `collect_cases_`, the five
layout workers moved namespaces.)

Register movements (`scripts/failure_reach_register.txt`, 240 → 238 rows):
- MOVED, re-keyed `lean_frontend/CerbMem.lean` → `lean_frontend/CerberusImpl.lean`,
  `CerbMem.*` → `CerberusImpl.*`, leaf/position/reach/reason unchanged, history appended: the 14
  layout rows — `targetPtrSize` (TAIL, UNREACHABLE-BY-INVARIANT), `offsetsof_lemFuel` (TAIL,
  UNREACHABLE-BY-INVARIANT), `sizeofCtype_lemFuel` ×6 (Void, IncompleteArray, Function, Integer,
  Float: TAIL, UNREACHABLE-BY-INVARIANT; Union: TAIL, REACHABLE — witness
  `tests/immaculate/nolibc/offsetof-union-member.c`), `alignofCtype_lemFuel` ×6 (Void, Function,
  Integer, Float: TAIL, UNREACHABLE-BY-INVARIANT; Struct, Union: LET-BOUND, UNREACHABLE-BY-INVARIANT).
  The gate's first run named exactly these 14 as NEW and their old keys as STALE.
- RETIRED: `CerbMem.arrayShiftPtrval` × `CerbStopSites.arrayShiftNull` (STMT-NEWLINE, REACHABLE;
  witness `tests/minimal/097-null-ptr-arith.undef.c`) and × `arrayShiftFunction` (STMT-NEWLINE,
  UNKNOWN) — the sites are UB046 verdicts now; a dated header note records both; the R-PNVI-06 row
  stays (its key is unchanged; the gate did not name it).
- Stop sites: 14 relabelled + re-cited (§2.1), 2 deleted. The migration map
  `docs/2026-10-20_outcome-protocol-register-migration.tsv` gains a dated note naming the two
  retired rows by their old/new lines and seals and the 14 moved rows; its rows are the record of
  the C migration and are not rewritten.

Baseline rows the S2 verdict is expected to move at M4 (measured there, not now):
`scripts/exec_baseline.txt:99 097-null-ptr-arith.undef.c CERB_SKIP`,
`scripts/gcc_oracle_baseline.txt:2040 … SKIP_LEAN_CRASH`, and
`tests/pnvi_lane/baseline.txt:175 minimal/097-null-ptr-arith.undef AGREE` (both engines now UB —
may stay AGREE with a new oracle hash).

Cites for M3 (`fuel_hypotheses.txt` hack/to_pure/to_pures rows, `CerbCoreShape.lean`): upstream's
insertions shifted `driver.lem` by five lines before `prepare_exit` — `1309-1316` → `1314-1321`,
`1331-1338` → `1336-1343`, `1352-1356` → `1357-1361`, `1369` → `1374`, `1473-1477` → `1478-1482`,
`1611-1616` → `1619-1623` (*derived* from `grep` on the merged file).

The separate `speclab` package (its `EmitCore.lean` gained the three arms), `capped lake build`
from `lean_frontend/speclab` (`.tmp/m2-speclab.log`): `21:51:17` … `exit=0` … `21:52:56`; its
639 warnings are LemLib's and the generated modules' (none in `speclab/`'s own sources).

---

## 2b. M2b — the Tier A findings on bb62d0017, the libc re-pin and the focused lanes (2026-10-30)

Tier A on `bb62d0017` (orchestrator-run, evidence
`/home/dev/projects/cerberus-lean-proj/.tmp/release/bump-fast-m2-20261029T215352Z`): `fast: failed;
12/20 selected commands completed successfully.` Failed rows A1, A2, A5, A7, A10, A14.1, A14.2, A15.
Forecast rows (§0.9), verified against the evidence: A5/A10/A14/A15 stopped at the libc pin
(`libc_prep.sh --jsons failed (pin drift or oracle missing)`), A2's `improvement:
097-null-ptr-arith.undef.c baseline=CERB_SKIP current=UB_MATCH` (S2). A1 also fails the fork-drift
gate until M5 (the merge-base moved at M1). Three findings:

### 2b.1 Finding 1 (A2 `REGRESSION: 106-sizeof-struct-array.c baseline=MATCH current=CERB_SKIP`) — upstream's regression at the cut

Root cause: upstream b3e11ea33 made `core_eval.lem`'s `Civsizeof`/`Civalignof` arms read
`Implementation.sizeof_ty file.tagDefs ty` where `Mem.sizeof_ival` read the Tags global that the
desugarer populates as tags are registered; the constant-expression mini-run
(`mini_pipeline.lem` `evalIntegerConstantExpressionAux`, upstream's own text) builds its dummy Core
file with `C.tagDefs= Map.empty`, so at `c3ff8c53f` every `sizeof`/`_Alignof` of a struct or union
inside an integer constant expression raises `Not_found` (`Pmap.find`, via
`Ocaml_implementation.offsetsof`). Decided by the pristine oracles (all `--nolibc --exec --batch`):

```
pristine b9aeedcb4 (deps/cerberus-upstream), tests/minimal/106-sizeof-struct-array.c:
Defined {value: "Specified(32)", stdout: "", stderr: "", blocked: "false"}
pristine c3ff8c53f (.tmp/pristine-c3ff8c53f, built from the mirror with the fork's lem and switch; dune exit=0):
cerberus: internal error, uncaught exception:
          Not_found
          Raised at Pmap.find in file "pmap.ml", line 81, characters 10-25
```
The merged oracle printed the same `Not_found`; the Lean driver the same class (`UPSTREAM_CRASH
CerberusImpl.offsetsof … unknown tag`, the empty explicit map reaching the moved `offsetsof`).
Upstream fixed it in its NEXT commit, 736690a65 (the Tags removal): `git log
-S'C.tagDefs= Map.empty' c3ff8c53f..upstream/master -- frontend/model/mini_pipeline.lem` names only
that commit, which sets `C.tagDefs= core_tagDefs`. No `tests/ci` file at `c3ff8c53f` has a struct
`sizeof` in an array bound, case label, enumerator or `_Static_assert`. Reported (stop) and ruled:

**[USER 2026-10-30]** (relayed by the orchestrator): option (a) — carry the one-line part of
736690a65 into the mini-run as an authorized backport of upstream's own next-commit fix, both
engines by generation; register it as a fork-ahead delta (manifest NOTE, this record, upstream
hash); mark it absorbed at stage 2 when 736690a65 arrives; cite the mechanism; keep
`106-sizeof-struct-array.c` at MATCH; add an upstream-tray note for completeness.

Applied: `mini_pipeline.lem` computes `core_tagDefs = Translation.translate_tag_definitions
sigm.A.tag_definitions` once, puts it in the dummy Core file's `C.tagDefs` and passes the same value
to the fork's reader seed `run_const_expr_driver` (previously computed there a second time);
`scripts/fork_drift_manifest.txt` top NOTE (dated, the mechanism, the hashes, "absorbed at stage
2", and that the whole manifest is re-derived at M5); upstream-tray report draft
`docs/upstream-tray/67-const-expr-sizeof-struct-not-found-window.md` + its INDEX row (the window
b3e11ea33..736690a65, the reproducer, the fixing commit; "fixed upstream before it was filed").

### 2b.2 Finding 2 (A7, one Lean failure) — the same root cause on the Lean side

The lane's failing file is `tests/minimal/106-sizeof-struct-array.c` (the Lean driver on its
cabs-json: `PANIC … cerberus-lean stop ["1","UPSTREAM_CRASH","CerberusImpl.offsetsof","Mirrored
upstream failure: CerberusImpl.offsetsof: unknown tag (OCaml: Pmap.find Not_found)", …`): the
mini-run's `Implementation.sizeof_ty file.tagDefs` reaches `CerberusImpl.sizeof_ty` with the dummy
file's EMPTY explicit map (the reader map is seeded with the real one, but the rep uses the explicit
map, as upstream does). The backport fixes both engines: after it, both answer `Specified(32)`.

### 2b.3 Finding 3 (A1 `totality-proof-test` build) — the test-executable surface

`build_lean` builds the library roots and the driver, not the `[[lean_exe]]` test modules under
`test/`; M2's "every root" claim did not cover them. Fixed and swept (`grep` over `test/` and
`speclab/` for every changed name): `TranslationFuelTest` (`collect_cases_` → the
`collect_switch_content_aux` fuel equation; the `_zero_boundary` theorems drop their now-unused
`[CerbGlobal.Switches]` binder; comment names), `TotalityProofTest` (`translate_expression`/
`translate_stmt` no longer bind the switch instance — upstream 334a1563b reads the switches through
`elab_config` — so their fuel-parametricity examples are `@f ⟨n⟩ = @f_lemFuel ⟨n⟩ n`),
`MonadicFailstop` (`memcmpM … loc …` ×2), `PnviArmsTest` (the R-PNVI-06 pin passes
`CerbLocation.unknown`), `FuelExemplar` (`drive_after_setup`: the `rw [alignofIval_signed_int]`
step is gone — `drive`'s `alignof_ival` closure is now the fuel-FREE `CerberusImpl.alignof_ty` over
the exemplar's concrete map, so the alignment reduces to `integerIval 4` inside the unification;
`alignof_ty_signed_int` states the fact by `rfl`). The build of EVERY `[[lean_exe]]` target
(`lake build CerberusLean cerberus-lean core-parser-test … core-quote-test`, 23 executables):
`exes build exit=0` (`.tmp/m2b-exes-build-3.log`; the earlier passes: zsh passed the target list as
one word; `beta_reduce` is not a core tactic — both reported, neither a finding).

### 2b.4 The libc content re-pin (pulled forward from M4)

`scripts/libc_prep.sh --record` on the rebuilt oracle (`libc record exit=0`):
```
libc_prep: content hash: f856081198f0d654188e02e14e649bf185e4a38ea701ba15dc1e180ba892b956  libc.core
libc_prep: content hash: 06a1f84c288e6192f483773935df6f6b6e6c25cb27335f69a582cb818bb1a588  libc_inner_arg_temps.core
```
(from `d93b99cd…` / `56986871…`; `tests/libc/bare_name_census.tsv` unchanged.) The Core-text
movement, accounted for (*derived*, `.tmp/m2b-libc-*` scripts over the old and new dumps):
`libc.core` 89610 → 89640 lines, 21747 raw changed lines; after normalising symbol numbers
(`name_N`, `{N}`) 529 changed lines in 469 hunks over 98 procs; `libc_inner_arg_temps.core` 87306
→ 87336, 20741 raw, 680 normalised in 601 hunks over 109 procs. So the bulk is symbol
RENUMBERING: upstream's new mints (the `while_`/`do_`/`case_`/`default_` labels and
`wrapped_fresh_symbol`s of cee382443, 83b1a7424 and cabe81c3b) shift every later symbol number. The
semantic hunks are upstream's elaboration changes, marker census over the normalised hunks:
`UB_CERB004_unspecified__while` 110 (cee382443 `translate_branch_on_unspec`: a `while` test
elaborates `[e == 0]` into a loaded integer and branches with `undef(<<UB_CERB004_unspecified__while>>)`
where it was `nd(pure(True), pure(False))` — the largest hunk, in `vfscanf`), `switch` /
`unspecified__switch` 9 (cabe81c3b's `collect_switch_content` + cee382443), `do_` /
`unspecified__do` 2 (83b1a7424's `mkTestExpression` do-while), `conv_int` 2 (588672e95's case
conversions); most-changed procs `decfloat` 64, `vfscanf` 62, `hexfloat` 28, `__intscan` 25,
`twoway_strstr` 23, `__floatscan` 22. The quotation pins (`test/CoreQuote/core-quote-libc*.sha256`,
Tier B 13) are M4's.

### 2b.5 The focused lanes (verbatim last lines, `.tmp/m2b-lanes.log`)

```
=== test_exec minimal 00:29:56
improvement: 097-null-ptr-arith.undef.c baseline=CERB_SKIP current=UB_MATCH
Baseline check: 0 regression(s), 1 improvement(s)
BASELINE OK
test_exec exit=0
=== test_parse minimal 00:30:27
Success rate:   100% (of cerberus successes)
batch diagnostic producers: 8/8 passed
ALL PASSED
test_parse exit=0
--- 097-null-ptr-arith.undef oracle:
Undefined {ub: "UB046_array_pointer_outside", stderr: "", loc: "<5:12--5:17>"}
--- 097-null-ptr-arith.undef lean:
Undefined {ub: "UB046_array_pointer_outside", stderr: "", loc: "<5:12--5:17>"}
--- 106-sizeof-struct-array oracle:
Defined {value: "Specified(32)", stdout: "", stderr: "", blocked: "false"}
--- 106-sizeof-struct-array lean:
Defined {value: "Specified(32)", stdout: "", stderr: "", blocked: "false"}
libc_prep exit=0
check_union_init_refusals: OK (26 cases: …)
check_anonymous_members_refusal: OK (42 cases: …)
check_compound_assignment_refusal: OK (30 cases: …)
check_asm_refusal: OK (9 cases: …)
```
Pristine `c3ff8c53f` on the same two files: `097` → `Undefined {ub: "UB046_array_pointer_outside",
…}` (agrees with both engines, S2); `106` → `Not_found` (upstream's regression, §2b.1 — the fork
answers `Specified(32)` by the backport). The `097` baseline row (`exec_baseline.txt:99 CERB_SKIP`)
is M4's re-record (an upstream fix, tray 04), not re-recorded here; `106` stays MATCH as ruled. The
witness scripts' full lines are in the log (the D11/D12/D13 refusals fire with their texts on the
merged base).

---

## 2c. M2c — the Tier A findings on df2598e47 (2026-10-30)

Tier A on `df2598e47` (orchestrator-run, evidence `.tmp/release/bump-fast-m2b-20261030T003344Z`):
`fast: failed; 16/20 selected commands completed successfully.` Failed A1, A5, A14.2, A15. Expected:
A14.2 (`minimal/097-null-ptr-arith.undef: default-mode comparison same != baseline changed` — the 097 row,
M4) and A1's fork-drift gate (M5). Findings:

### 2c.1 Finding 1 — `libc/016-strstr-twoway-oob` DIFF (A5, A15): a location-only divergence from the fork's libc transport — STOP, awaiting ruling

Both engines report the same UB on the same program; they differ in the LOCATION only. Verbatim
(libc mode, `--exec --batch`):
```
pristine b9aeedcb4 memcmp (impl_mem.ml): load Cerb_location.unknown Ctype.unsigned_char ptrval   -- the pre-merge text
pristine c3ff8c53f:  Undefined {ub: "UB_CERB002a_out_of_bound_load", stderr: "", loc: "<265:22--265:26>"}
merged oracle:       Undefined {ub: "UB_CERB002a_out_of_bound_load", stderr: "", loc: "<265:22--265:26>"}
Lean (pinned dump + 12 metadata TUs): Undefined {ub: "UB_CERB002a_out_of_bound_load", stderr: "", loc: "<unknown location>"}
```
Root cause: upstream f4a3a3d54 gave `memcmp` the memop's `loc` and loads each byte at it (before,
`Cerb_location.unknown` — so both engines printed `<unknown location>` and the row matched by
coincidence). The Lean mirror is right: `CerbMem.memcmpM … loc …` loads at `loc` and `loadM`'s kill
reports it (`CerbMem.lean` `fail_`). The `loc` reaching Lean's `Memcmp` memop is `unknown` because
the Lean engine runs libc from the pinned Core TEXT dump (`tests/libc/libc.core`), and that dump
carries NO location annotations: the oracle's Basic Core printer hard-wires `show_locations = false`
(`ocaml_frontend/pprinters/pp_core.ml:923`; `maybe_print_location` prints nothing), `grep -c '{-#'`
over the dump is 0, and `CoreParser.lean` has no grammar for location comments — every memop,
load and store inside libc runs with an empty annotation list on Lean, while the oracle keeps the
C locations of its in-memory Core. A pre-existing transport limitation, latent until upstream made
a libc-internal UB location-bearing on a row the lanes compare. Not fixable in the mirror (the
location is not there to mirror); fixing it is a transport slice (print locations into the dump,
parse them in `CoreParser`, re-pin, and carry them through the quotation instrument) — outside
this arc's charter. Reported as a STOP per the orchestrator's rule; the row stays red in A5/A15
(`test_libc_exec exit=1`, `inner_arg_temps: FAIL — failed rows: ['libc/016-strstr-twoway-oob']`,
186 rows otherwise `AGREE=138 AGREE-FIRST=40 BOTH_FAIL=5`) until ruled. Not baselined.

### 2c.2 Finding 2 — `match-pattern-arity-test` R3 `Erun` rows: the witness's classifier restated for upstream's guard (fixed)

The R3 witness's grid classifiers (`classifyR3E`, `isArgArityE "run"`) recognised the fork's
`MismatchExpected "run" (BTy_tuple _) "argument list of a different arity"`; the merge took upstream's
`ArityMismatchRun expected found` for `Erun` (resolution rule R3; the `PEcall` guard stays the fork's).
Both classifiers gain the arm (the `isExprMismatch`/`classifyExprTyping` pair too, for completeness);
the fail-closed behaviour pinned is unchanged:
```
PASS R3 typecheck_expr Erun loop with 0 actual(s) for 1 formal: got Exception (ArityMismatchRun 1 0); pre-fix: Result with 0 arguments (ACCEPTED — the defect)
PASS R3 typecheck_expr Erun loop with 2 actual(s) for 1 formal: got Exception (ArityMismatchRun 1 2); …
PASS R3 typecheck_expr Erun loop with 3 actual(s) for 1 formal: got Exception (ArityMismatchRun 1 3); …
match-pattern-arity-test: OK (8/8 item-7 witnesses + 19/19 closure-round witnesses + 33/33 round-3 argument-list witnesses; …)
```
`test_unit.sh` stops at the executable tally before any gate script (`exit 1` at its line 150), so in
Tier A's A1 the gates after the executables had not run; they are run here (§2c.4).

### 2c.3 Finding 3 (surfaced by the rerun) — the fuel-forms SELFTEST's decoys named the moved obligations (fixed)

`test_unit.sh` on the fixed tree: `Total: 21 passed, 0 failed`, then
`check_fuel_forms: SELFTEST FAILED (4)` — at M2 the plain gate was run, not its selftest. Its decoy
theorems and plants (`scripts/check_fuel_forms.sh`) restate the REAL layout obligations by name
(`CerbMem.sizeofCtype_measure_sufficient` with an extra binder, `CerbMem.alignofCtype_measure_sufficient`
under `cty ≠ cty`, the P8 deletion of the `CerbMem.sizeofCtype_lemFuel` register row): re-keyed to
`CerberusImpl.*`, the decoys import `CerberusImpl`, and the decoy run excludes BOTH carriers
(`FUELFORMS_EXCLUDE_MODULES="CerberusImpl_lemMeasureProofs CerbMem_lemMeasureProofs"`: the CerbMem
carrier imports the layout carrier since the split, so excluding the latter alone let the real
theorem back in — `uncaught exception: import FuelFormsPlantExtra failed, environment already
contains 'CerberusImpl.sizeofCtype_measure_sufficient'`). The plant logic is unchanged.
```
check_fuel_forms: SELFTEST OK (25 plants with the declared label — 6 on the table (incl. the ABSORBING-cone plant), 3 on the hypothesis register, 15 compiled decoys: …
check_fuel_forms: OK (88 fuel'd workers: 67 MEASURED (…
```

### 2c.4 Row-1 gates and the lanes (verbatim last lines)

`test_unit.sh` (`.tmp/m2c-test-unit-2.log`): `Total: 21 passed, 0 failed`; the gates it reached:
`check_handwritten_sync: OK`, `check_exec_purity: SELFTEST OK` / `CLEAN`, `check_theorem_axioms: OK`,
`check_sorry_token: OK`, `test_exec: SELFTEST OK`, `check_no_fuel_numerals: SELFTEST OK` / `OK`,
`gen_fuel_parametricity: SELFTEST OK` / `OK`, `check_lakefile_roots: SELFTEST OK` / `OK`; it stopped
at the fuel-forms selftest (§2c.3). By hand after the fix (`.tmp/m2c-fuel-forms-2.log`,
`.tmp/m2c-gates.log`, `.tmp/m2c-lanes.log`):
```
check_fuel_forms: SELFTEST OK (25 plants …)        check_fuel_forms: OK (88 fuel'd workers: …)
check_failure_reach: SELFTEST OK (8 plants …)      check_failure_reach: OK (238 pure failure sites = the 238 register rows exactly …)
test_version: OK (untagged, exact annotated tag, dirty tag, post-tag, archive fallback)
test_exec_totality: OK (8 plants and 2 clean controls)
check_exec_totality: CLEAN (22 generated modules + hand-written CerbND, 0 allowlisted)
check_lem_sync: OK (src 6f59f409…, gen 14399a38…)   check_lem_sync: lean OK (src 6f59f409…, gen a478f16e…)
check_fork_drift: FAIL — merge-base moved: manifest pins b9aeedcb4dd438763b0eef7f95ac19e93875d7de, live is c3ff8c53f05982745f9b3a10b3d05442e214bcb5 — … run the refresh recipe   (EXPECTED until M5; its --selftest stops on the same line)
check_pin_sites: SELFTEST OK (8 plants red with the declared message, unplanted copies green)
check_pin_sites: OK — lem-pin e6d8db5680962f49060257d6c2bcb13c284b910f at every site (lakefile rev, 3 lake-manifests rev+inputRev, README pin command)
check_fixture_freeze: OK (16 fixture files match the pinned manifest; name set exact)
test_renumber_plants: OK (12 plants: refusals refuse, admits admit with declared class)
check_cli_refusals: OK (unsupported switch sets, mixtures, duplicates, unknown names, placement and repeated options refused; PNVI_ae_udi and inner_arg_temps accepted alone …
check_runtime_resolution: OK (35 witnesses: …)
```
Lanes: `test_libc_exec.sh`: every row MATCH except `016-strstr-twoway-oob DIFF` (§2c.1), `exit=1`;
`test_inner_arg_temps.sh --gate`: `SUMMARY: inner_arg_temps rows=186 AGREE=138 AGREE-FIRST=40
BOTH_FAIL=5 RESOURCE oracle:KILL=2 failures=1` / `FAIL — failed rows: ['libc/016-strstr-twoway-oob']`
(the same row). The gates that `test_unit.sh` lists after `check_runtime_resolution` (the refusal
witnesses, `check_libc_float_literals.py`, `test_translation_fuel.sh`) were run at M2b (the four
refusal scripts) or are covered by M3/M4.
