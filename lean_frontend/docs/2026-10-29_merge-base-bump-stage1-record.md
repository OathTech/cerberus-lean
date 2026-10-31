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

**Forecast misses found later** (added as they were found, the table above left as planned): B5's three
`zd-ta-alignas-huge-*` rows and the `s4b-memcmp-hugesize` token (M4, §4.7 — b3e11ea33/f4a3a3d54, upstream's fixes);
the A5 row omitted the libc float-literal inventory register `scripts/libc_float_literals.txt`, which pins the dump's
literals by line and had to be re-derived with the libc re-pin (M5b, §5b — pure relocation, +28 lines).

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
  accepted plan); unobservable at every stage-1 call site [CORRECTED 2026-10-30, §6b: FALSE — observable at desugar-time `get_alignof` on a union-containing type (the oracle crashes, Lean answers; pre-merge review P1) and at elaboration-time `offsetof` over a union-containing struct (both crash, different arms; P2)] (the wrappers pass one map twice;
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

---

## 2d. M2d — the ruling on finding 1 and its disposition (2026-10-30)

**Ruling [AGENT 2026-10-30]** (the orchestrator's, to be reported to the operator, who may overrule):
the `libc/016-strstr-twoway-oob` row is a declared transport limitation, not a semantic divergence;
recorded as such, neither baselined as DIFF nor fixed in this arc. Applied:

1. Both lanes gain a reviewed `LOC_ONLY` disposition for exactly that row, keyed on the two
   observations being identical once the `loc` field is removed and every Lean location being
   `<unknown location>` (no oracle one is); any other difference on the row, or this class on any
   other row, stays RED. `scripts/test_libc_exec.sh`: status `LOC_ONLY` requires a dated line in the
   new reviewed register `tests/libc_exec/dispositions.txt` (else DIFF, fail-closed); the baseline row
   carries the class; `--selftest` plants the classifier (8 plants: identical → MATCH; the pair with a
   disposition → LOC_ONLY; the pair WITHOUT one → DIFF; a real Lean location, a differing UB, a
   multi-line value difference, an oracle at unknown location → DIFF; multi-line loc-only → LOC_ONLY).
   `scripts/inner_arg_temps_lane.py`: `loc_only`, classes `LOC_ONLY`/`LOC_ONLY-FIRST`, `same_sequence`
   admits the pair, the baseline row carries the class and a dated `disposition` text (pinned by the
   exact-equality baseline check), the selftest plants the pair in both modes and five rejected
   neighbours (a real Lean location, a differing UB, an oracle unknown, a length difference, another
   observation differing).
2. VALIDATION.md 2b row **N4** and the §5 lane row; SUPPORTED.md states the limitation plainly (the
   oracle's location is the reference).
3. TODO queues the remover: locations in the Core text transport (printer, parser, libc re-pin,
   quotation impact), with this row as its witness.
4. The pre-merge coincidence (both engines at `<unknown location>`: the oracle's `memcmp` loaded at
   `Cerb_location.unknown` at b9aeedcb4) and the exact outputs are in §2c.1.

The lanes after the disposition (verbatim last lines, `.tmp/m2d-lanes.log`, `.tmp/m2d-iat-selftest.log`):
```
test_libc_exec: SELFTEST OK (8 plants)
  LOC_ONLY 016-strstr-twoway-oob (reviewed: 2026-10-30 — the Lean engine reports no source location inside libc):
SUMMARY: match=41 loc_only=1 diff=0
ALL MATCH RECORDED BASELINE
  LOC_ONLY-FIRST            libc/016-strstr-twoway-oob cross-mode=SAME_SET
SUMMARY: inner_arg_temps rows=186 AGREE=138 AGREE-FIRST=40 BOTH_FAIL=5 LOC_ONLY-FIRST=1 RESOURCE oracle:KILL=2 failures=0
inner_arg_temps: FAIL — minimal/097-null-ptr-arith.undef: baseline changed: {'class': 'BOTH_FAIL', …   (the 097 row: both engines UB now, M4's re-record, not this slice's)
PLANT OK (LOC_ONLY: the location-only pair classified in both modes; five neighbours rejected)
SELFTEST OK (control; both stripped-switch stubs; Normal-only main/libc mutations; both dump/mode plants; both binder plants; printer collision; sequence/set controls; five baseline plants; outcome failures)
```
The inner_arg_temps baseline row for 016 before the disposition was
`{"class": "AGREE-FIRST", "cross_mode": "SAME_SET", "lean": "e3e1024ddb83", "mode": "first", "oracle": "e3e1024ddb83"}`:
the oracle's and Lean's observation hashes were EQUAL — the pre-merge coincidence in hash form (both
engines at `<unknown location>`); after the merge the Lean hash is unchanged (`e3e1024ddb83`) and the
oracle's is `54a5577345c4` (the location). The row now carries `LOC_ONLY-FIRST` and the dated
`disposition` text.

---

## 3. M3 — proofs: kernel replay, the axiom censuses, the cite shifts (2026-10-30)

The carrier work itself was forced into M2/M2b (the obligation shells are Lake roots, §2.2): the
`collect_switch_content_aux` obligation (new, the C2 template), the five layout obligations moved
into `CerberusImpl_lemMeasureProofs.lean` (namespace rename only), the Defacto `memcmp_load_aux`
obligation's `loc` binder, the fuel wrappers' `_zero` boundaries compiled unchanged, the exemplar's
errno step by unfolding. M3 adds the register cites and runs the named trust gate.

### 3.1 Cite shifts (`scripts/fuel_hypotheses.txt` rows `hack`/`to_pure`/`to_pures`, `lean_frontend/CerbCoreShape.lean` header)

Upstream's stage-1 insertions in `driver.lem` moved every cited line by +5 (verified by content on the
merged file): `prepare_exit` `1309-1316` → `1314-1321`; `process_core_step2`'s `Step_done2` arm
`1331-1338` → `1336-1343`; `Step_fs2`/`FS_done` `1352-1356` → `1357-1361`; `driver2` `1369` → `1374`;
`finalize` `1473-1477` → `1478-1482`; `driver_globals`' `to_pure` `1611-1616` → `1618-1623` (+7: two
more insertions in between); `new_drive_core_threads` `1275-1296` → `1280-1301`; the erratum's
commented-out `drive_core_thread2` `485-486` → `490-491` and `452-510` → `457-515`. 12 + 2 cites in
the register rows, 7 + 3 in the header; no old line remains (`grep` over both files). The hypotheses
and their invariants are unchanged (the terminal arms still rewrite through `prepare_exit`; the fuel-
forms gate re-reads the rows: `check_fuel_forms: OK (88 fuel'd workers: 67 MEASURED …`).

### 3.2 Kernel replay — the named trust gate (verbatim)

```
lake env leanchecker Translation_lemMeasureProofs Translation_auxiliary CerberusImpl_lemMeasureProofs CerbMem_lemMeasureProofs Defacto_memory_lemMeasureProofs Defacto_memory_auxiliary Formatted_auxiliary CerberusImpl CerbMem CerbCoreShape Driver_lemMeasureProofs Unit.TranslationFuelTest Unit.FuelExemplar Unit.TotalityProofTest Unit.MatchPatternArityTest Unit.PnviArmsTest Unit.MonadicFailstop
leanchecker exit=0
lake env leanchecker CerbCoreShape Driver_lemMeasureProofs Core_aux_lemMeasureProofs      (after the cite edit's recopy and rebuild)
leanchecker exit=0
```
(`.tmp/m3-chain.log`, `.tmp/m3-replay-2.log`; no output on success. Every changed carrier and seam
of stage 1: the Translation and Defacto carriers and their obligation shells, the new layout carrier
and the CerbMem carrier it split from, the Formatted shell (the `load_character_array_aux` `_zero`
payload), the seams `CerberusImpl` (the moved layout, `sizeof_ty`/`alignof_ty`) and `CerbMem` (the S2
arms), `CerbCoreShape`, `Driver_lemMeasureProofs`, and the test modules whose statements or proofs
moved.)

### 3.3 Censuses (verbatim last lines)

```
check_theorem_axioms: FUEL arc leg OK (63 contract lemmas — generated _zero, runner leaves/parametricity, ∀-fuel exemplar, measured obligations, fail-stop propagation, and six-worker ND stability, every cone ⊆ [propext, Classical.choi
check_theorem_axioms: OK (effect-retirement C2 bar: zero axiom declarations anywhere; entry cones ⊆ the standard three)
check_sorry_token: OK (353 files scanned comment-stripped — generated 229, hand-written+test 89, LemLib 35; 0 sorry tokens)
check_fuel_forms: OK (88 fuel'd workers: 67 MEASURED (obligation of the contract's shape incl. argument correspondence against the wrapper's body; every obligat
check_handwritten_sync: OK (57 hand-written files byte-identical to lean_frontend/generated/; manifest lean_frontend/handwritten_copy.manifest)
```
No option bump anywhere in the slice (`grep -rn 'maxHeartbeats\|maxRecDepth' lean_frontend/*.lean
lean_frontend/test` unchanged from the base); every tactic kernel-only.

---

## 4. M4 — lanes and baselines on the moved base (2026-10-30)

Scope as staged by the orchestrator [AGENT 2026-10-30]: every baseline row that moved is dispositioned here as
**upstream's fix**, a **retired refusal** or a **finding** — never a silent re-record — and each new class is cited
to the upstream commit (carried by the new base) and the seam that mirrors it. Nothing moved that §0.9 did not
forecast; no finding arose. Lanes ran through `scripts/ce` with `CERB_MEM_MAX=32G`; logs `.tmp/m4-chain-a.log`,
`.tmp/m4-exec-ci.log`, `.tmp/m4-verify-full.log`, `.tmp/m4-chain-b.log`, `.tmp/m4-pins/*` (ephemeral).

### 4.0 The disposition table (all moved rows)

| lane / file | row | was → is | disposition | cited to |
|---|---|---|---|---|
| A2 `scripts/exec_baseline.txt` | `097-null-ptr-arith.undef.c` | `CERB_SKIP` → `UB_MATCH` | upstream's fix (both engines crashed; both now `UB046_array_pointer_outside`) | f4a3a3d54; seam S2 (§2.1); tray 04 closes at M6 |
| A14 `tests/pnvi_lane/baseline.txt` | `minimal/097-null-ptr-arith.undef` | `AGREE … default=changed` → `AGREE … default=same` | upstream's fix (the PNVI-ae-udi verdict now equals the default-mode verdict, `oracle=0a319c85b2ca` unchanged) | f4a3a3d54; S2 |
| A15 `tests/inner_arg_temps/baseline.json` | `minimal/097-null-ptr-arith.undef` | `BOTH_FAIL` (lean `8ed9a0170fd9`, oracle `37a96bce2405`) → `AGREE` (both `0a319c85b2ca`) | upstream's fix | f4a3a3d54; S2 |
| Tier C `scripts/exec_ci_baseline.txt` | `0120-addition_null_pointer.error.c` | `CERB_SKIP` → `UB_MATCH` | upstream's fix (both `UB046_array_pointer_outside`, loc `<4:3--4:8>`); the `.error.c` name stays until stage 2's 0676e9fca | f4a3a3d54; S2 |
| Tier C `scripts/exec_ci_baseline.txt` | `0121-addition_null_pointer_zero.error.c` | `CERB_SKIP` → `UB_MATCH` | upstream's fix (as 0120) | f4a3a3d54; S2 |
| Tier C `scripts/exec_ci_baseline.txt` | `0342-empty-range-case.c` | (new file) → `MATCH` | adoption of upstream's witness (`Specified(111)` on both) | ad233f84f (keeping the body of empty GNU case ranges) |
| B4 `tests/verify/*.core` (14), `tests/corpus/*.core` (7), `*_funs.core` (7), `*.core.sha256` (6) | 34 provenance rows | Core TEXT re-pinned, no verdict moved | upstream's fix (text only) | cee382443 (all), 83b1a7424 (p15 only); S5 — §4.4 |
| Tier B 13 `lean_frontend/test/CoreQuote/core-quote-libc*.sha256` | the two libc literal digests | re-pinned with the M2b libc re-pin | upstream's fix (libc Core text: `do`/`switch`/unspecified arms) | 83b1a7424, cabe81c3b, 588672e95, cee382443 — §4.5 |
| B5 `tests/immaculate/baseline.txt` | `zd-ta-alignas-huge-desugar` / `-sizeof` / `-union-alignof` | `ORACLE_CRASH` → `MATCH` (Lean token unchanged) | upstream's fix (the oracle's `Z.to_int` alignment reads are gone; it now gives the unbounded answer Lean computed under ISO-fix register R7 — **R7 retired**); a §0.9 forecast miss | b3e11ea33; S1 — §4.7 |
| B5 `tests/immaculate/baseline.txt` | `ts-fmt-s-null` | `MATCH \| L=CRASH` → `MATCH \| L=UB046 <7:38--7:57>` | upstream's fix (both crashed; both now UB046) | f4a3a3d54; S2 — §4.7 |
| B5 `tests/immaculate/baseline.txt` | `s4b-memcmp-hugesize` | `ORACLE_CRASH \| L=… <unknown location>` → `… <13:10--13:34>` | upstream's fix, Lean token only (`Loc.t` threaded into `memcmp`); the oracle's crash (tray 13) and register R3 unchanged | f4a3a3d54; S2 — §4.7 |
| B7 `scripts/gcc_oracle_baseline.txt` | `tests/minimal/097-null-ptr-arith.undef.c`, `tests/immaculate/nolibc/ts-fmt-s-null.c` | `SKIP_LEAN_CRASH` → `SKIP_UB` | upstream's fix (Lean's verdict is now UB, never compared with gcc); full run DISAGREE=0, ledger set-equal to the run | f4a3a3d54; S2 — §4.8 |

Rows that did NOT move, as forecast (§0.9): `0343`/`0344` stay `CERB_SKIP` (the exhaustive oracle's 30 s timeout,
verbatim `[244/245] CERB_SKIP 0343-subzero-floating-to-_Bool (Cerberus timeout: TIMEOUT(cpu 30.13s of 30.17s wall;
timeout 30s))`), `0213` stays `CERB_SKIP`; the PNVI `R-PNVI-*` rows; every verdict row of the verify and corpus
lanes; the libc_exec rows (M2d's `LOC_ONLY` for 016 included); tests/ci parse and core round trips.

### 4.1 A2 — `tests/minimal`, the 097 row

The measurement on the M2b tip (`.tmp/m2b-lanes.log`, verbatim):
```
improvement: 097-null-ptr-arith.undef.c baseline=CERB_SKIP current=UB_MATCH
--- 097-null-ptr-arith.undef oracle:
Undefined {ub: "UB046_array_pointer_outside", stderr: "", loc: "<5:12--5:17>"}
--- 097-null-ptr-arith.undef lean:
Undefined {ub: "UB046_array_pointer_outside", stderr: "", loc: "<5:12--5:17>"}
```
Before the bump both engines crashed on `((int *) 0) + 1` (the oracle's `failwith` in `array_shift_ptrval`, the
Lean `PANIC` in `arrayShiftNull`, §2.1 S2; tray 04). Upstream f4a3a3d54 puts `array_shift_ptrval` in the UB monad
and makes the null-pointer shift `UB046_array_pointer_outside`; S2 mirrors it (`arrayShiftPtrval … : t0
PointerValue` with `.Undef loc [.UB046_array_pointer_outside]`). Re-recorded as `UB_MATCH` with a header note in
`scripts/exec_baseline.txt`; re-check on the edited file (`.tmp/m4-chain-a.log`, verbatim):
```
SUMMARY: total=113 match=90 ub_match=19 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=4 cerb_floor=0 cerb_inconsistent=0
Baseline check: 0 regression(s), 0 improvement(s)
BASELINE OK
```

### 4.2 Tier C — `tests/ci` (`scripts/exec_ci_baseline.txt`, 244 → 245 rows)

Measured against the committed baseline on the M3 tip (`.tmp/m4-exec-ci.log`, verbatim):
```
[100/245] UB_MATCH 0120-addition_null_pointer.error: UB:{ub: "UB046_array_pointer_outside", stderr: "", loc: "<4:3--4:8>"}
[101/245] UB_MATCH 0121-addition_null_pointer_zero.error: UB:{ub: "UB046_array_pointer_outside", stderr: "", loc: "<4:3--4:8>"}
[122/245] CERB_SKIP 0213-label-statement-outside-switch.error (exit 1)
[243/245] MATCH 0342-empty-range-case: VAL:{value: "Specified(111)", stdout: "", stderr: "", blocked: "false"}
[244/245] CERB_SKIP 0343-subzero-floating-to-_Bool (Cerberus timeout: TIMEOUT(cpu 30.13s of 30.17s wall; timeout 30s))
[245/245] CERB_SKIP 0344-ptr-to-_Bool-param (Cerberus timeout: TIMEOUT(cpu 30.12s of 30.13s wall; timeout 30s))
SUMMARY: total=245 match=92 ub_match=43 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=110 cerb_floor=0 cerb_inconsistent=0
improvement: 0121-addition_null_pointer_zero.error.c baseline=CERB_SKIP current=UB_MATCH
improvement: 0120-addition_null_pointer.error.c baseline=CERB_SKIP current=UB_MATCH
new file (not in baseline, not fatal): 0342-empty-range-case.c MATCH
Baseline check: 0 regression(s), 2 improvement(s)
BASELINE OK
```
Three rows edited by hand (header note in the file): 0120/0121 `UB_MATCH` (f4a3a3d54, S2 — the same crash-to-UB
movement as 097; the files keep their upstream `.error.c` names, the rename is stage 2's 0676e9fca), 0342 `MATCH`
(ad233f84f's witness). Re-check on the edited file: §4.6.

### 4.3 A14 PNVI and A15 inner_arg_temps — the 097 row

`test_pnvi.sh --record-baseline` (`.tmp/m4-chain-a.log`, verbatim; the lane re-adds its header and rewrites every
row — the diff against the committed file is exactly one row):
```
  AGREE                              minimal/097-null-ptr-arith.undef  default=same
pnvi_lane: wrote 164 rows to …/.tmp/scripts/observations/test_pnvi.KUsWGEi0QI/pnvi.toyvKTq5/baseline.new (header must be
 1 file changed, 1 insertion(+), 1 deletion(-)
-minimal/097-null-ptr-arith.undef AGREE oracle=0a319c85b2ca default=changed
+minimal/097-null-ptr-arith.undef AGREE oracle=0a319c85b2ca default=same
```
`default=changed` recorded that the PNVI-ae-udi verdict (`0a319c85b2ca`, the UB) differed from the default-mode
verdict (then a crash); the default mode now reaches the same UB, so `default=same`. The `R-PNVI-06/07/01` rows are
untouched (upstream's symbolic arm is unchanged; trays 51/52/53 stay open).

`test_inner_arg_temps.sh --rows '^minimal/097-null-ptr-arith.undef$'` (verbatim):
```
  AGREE                     minimal/097-null-ptr-arith.undef
SUMMARY: inner_arg_temps rows=1 AGREE=1 failures=0
inner_arg_temps: FAIL — minimal/097-null-ptr-arith.undef: baseline changed: {'class': 'BOTH_FAIL', 'lean': '8ed9a0170fd9', 'mode': 'exhaustive', 'normal_status': {'class': 'BOTH_FAIL', 'lean': '8ed9a0170fd9', 'oracle': '37a96bce2405'}, 'oracle': '37a96bce2405'}
```
The row was spliced into `tests/inner_arg_temps/baseline.json` from the lane's `results.json` (one row per line
preserved, as for 016 at M2d):
```
-  "minimal/097-null-ptr-arith.undef": {"class": "BOTH_FAIL", "lean": "8ed9a0170fd9", "mode": "exhaustive", "normal_status": {"class": "BOTH_FAIL", "lean": "8ed9a0170fd9", "oracle": "37a96bce2405"}, "oracle": "37a96bce2405"},
+  "minimal/097-null-ptr-arith.undef": {"class": "AGREE", "lean": "0a319c85b2ca", "mode": "exhaustive", "oracle": "0a319c85b2ca"},
```
The `--gate` run on the spliced file: §4.6.

### 4.4 B4 — the fixture pins (`tests/verify/*.core`, `tests/corpus/*`), re-derived by the oracle

Lane `test_verify.sh` on the M3 tip (`.tmp/m4-verify-full.log`, verbatim last line):
```
test_verify: 93 passed, 34 failed (25 fixtures, 28 call points, 14 corpus fixtures, 21 corpus points)
```
All 34 failures are provenance rows (`pin provenance`, `content-hash provenance`, `funs-extraction
provenance`); every main-mode and call-point differential row passes (*derived* from the log: 0 non-provenance
failures). Every pinned dump was re-derived with the worktree's oracle exactly as the lane does it
(`cerberus --nolibc --pp=core`, `.tmp/m4-pins/rederive.sh`), the drifted ones written over the pins, and byte-equality
of every written pin against its fresh dump checked (`mismatches=0`; the six arena rows by SHA-256, below).

The Core-text movement, classified by diffing the pinned text against the fresh dump (symbol numbers
normalised for p15; `.tmp/m4-pins/arena-diff.log`): with one exception every hunk is upstream cee382443's
unspecified-branch arm — `nd(pure(True), pure(False))` → `pure(undef(<<UB_CERB004_unspecified__if>>))` /
`…__while>>))` — the oracle's default `branching_on_unspec = Elab_UB` (the switch `branching_on_unspec_is_nd`
is REFUSED, §0.12 Q9) that seam S5 mirrors in `Main.lean`. The exception is p15 (a `switch` and a `do … while`),
where the three further hunks are cee382443's `switch` arm (`UB036_exceptional_condition` →
`UB_CERB004_unspecified__switch`), 83b1a7424's `do`-loop test (`mkTestExpression TestEq`: the controlling
expression becomes `E == 0` and the loop re-runs on `not(case = 1)`, exactly upstream's own comment in
`translation.lem`) and the `DUMMY(unspecified AilSdo)` arm becoming `UB_CERB004_unspecified__do` (cee382443).
No hunk lies outside the `-- Fun map` section of any dump (p15's six hunks are at lines ≥ 209846 of a dump whose
`-- Fun map` starts at 209764). Disposition: all **upstream's fix** (cee382443, 83b1a7424); no verdict moved.

| pin | hunks (if / while / other) | disposition |
|---|---|---|
| `tests/verify/c3a_accguard.core` | 2 / 0 / – | cee382443 |
| `tests/verify/c3b_leaddigit.core` | 0 / 1 / – | cee382443 |
| `tests/verify/c4_hexval.core` | 3 / 0 / – | cee382443 |
| `tests/verify/c5_pcthi.core` | 1 / 0 / – | cee382443 |
| `tests/verify/e1_clamp.core` | 1 / 0 / – | cee382443 |
| `tests/verify/e2_abs.core` | 1 / 0 / – | cee382443 |
| `tests/verify/e4_isdigit.core` | 1 / 0 / – | cee382443 |
| `tests/verify/e5_ismark.core` | 1 / 0 / – | cee382443 |
| `tests/verify/m1_sgn.core` | 2 / 0 / – | cee382443 |
| `tests/verify/t5_sum.core` | 0 / 1 / – | cee382443 |
| `tests/verify/t6_branch.core` | 1 / 0 / – | cee382443 |
| `tests/verify/t7_flip.core` | 1 / 1 / – | cee382443 |
| `tests/verify/x2_break.core` | 1 / 1 / – | cee382443 |
| `tests/verify/x7_earlyret.core` | 1 / 1 / – | cee382443 |
| `tests/corpus/p01_clamp.core` | 1 / 0 / – | cee382443 |
| `tests/corpus/p02_sat_add.core` | 2 / 0 / – | cee382443 |
| `tests/corpus/p03_swap_mayalias.core` | 1 / 0 / – | cee382443 |
| `tests/corpus/p10_gcd_rec.core` | 1 / 0 / – | cee382443 |
| `tests/corpus/p11_gcd_iter.core` | 0 / 1 / – | cee382443 |
| `tests/corpus/p12_pt_midpoint.core` | 1 / 0 / – | cee382443 |
| `tests/corpus/p14_count_pairs.core` + `_funs.core` | 1 / 3 / – | cee382443 |
| `tests/corpus/p04_arr_sum.core.sha256` + `_funs.core` | 0 / 2 / – | cee382443 |
| `tests/corpus/p05_find_first.core.sha256` + `_funs.core` | 1 / 2 / – | cee382443 |
| `tests/corpus/p06_arr_reverse.core.sha256` + `_funs.core` | 1 / 3 / – | cee382443 |
| `tests/corpus/p07_list_sum.core.sha256` + `_funs.core` | 0 / 2 / – | cee382443 |
| `tests/corpus/p08_list_reverse.core.sha256` + `_funs.core` | 1 / 3 / – | cee382443 |
| `tests/corpus/p15_scan_classify.core.sha256` + `_funs.core` | 0 / 1 / switch arm, `do` test, `do` arm | cee382443, 83b1a7424 |

Unchanged (byte-identical re-derivation, no edit): `c9_arrw`, `e3_scale`, `t1_id`, `t2_add`, `t3_roundtrip`,
`t4_struct_member`, `x3_call`, `z1_chain`, `z2_bool_param`, `z2_errno_order`, `z2_wide`, `p09_call_contract`;
`scripts/fixture_corpus.sha256` (the C sources are untouched; `check_fixture_freeze` below).

The six content-hash pins, with the OLD pins' provenance re-established by deriving the same six programs with
the mainline checkout's oracle (`cerberus-lean/` at `676f9f21c`, the old base; `.tmp/m4-pins/old-oracle.sh`) —
each old-oracle digest equals the pin at `9a8c9febf`, each fresh digest is the new pin (verbatim):
```
p04_arr_sum
  old-oracle(676f9f21c)=5ae7f17902dde8a6a8f1b73f47ea6abb52a410e8546a15361dff57a3879d925f
  pinned@9a8c9febf     =5ae7f17902dde8a6a8f1b73f47ea6abb52a410e8546a15361dff57a3879d925f  OLD-REPRODUCED
  fresh-oracle(M4 tree)=3def8502c0693c05d4955701e95f05cb44eabb3da77b2819cda834af2cff28f0
  new pin              =3def8502c0693c05d4955701e95f05cb44eabb3da77b2819cda834af2cff28f0  NEW-PINNED
p05_find_first
  old-oracle(676f9f21c)=1e5d49caf9a62cc7fdb669c0f803abc4e3f8b0f8b20d4f7b9e9851a3bb3a31ba
  pinned@9a8c9febf     =1e5d49caf9a62cc7fdb669c0f803abc4e3f8b0f8b20d4f7b9e9851a3bb3a31ba  OLD-REPRODUCED
  fresh-oracle(M4 tree)=3b4bed49f9e3128ee86e3482e573bf3685da0958af5dcd9f0195665f6e839a05
  new pin              =3b4bed49f9e3128ee86e3482e573bf3685da0958af5dcd9f0195665f6e839a05  NEW-PINNED
p06_arr_reverse
  old-oracle(676f9f21c)=ec47d15f421367563060bb31cfdb44ab7d3a58b07055fdbda95d723378b1d381
  pinned@9a8c9febf     =ec47d15f421367563060bb31cfdb44ab7d3a58b07055fdbda95d723378b1d381  OLD-REPRODUCED
  fresh-oracle(M4 tree)=2e28022ccfc3c01c6cb0129f0a73ee94a7a99a2b7c7310cfbb0c832a8d43b6dd
  new pin              =2e28022ccfc3c01c6cb0129f0a73ee94a7a99a2b7c7310cfbb0c832a8d43b6dd  NEW-PINNED
p07_list_sum
  old-oracle(676f9f21c)=730269e83ed6aea53ec3520b074feb24591e18c85664825d449f319b61002623
  pinned@9a8c9febf     =730269e83ed6aea53ec3520b074feb24591e18c85664825d449f319b61002623  OLD-REPRODUCED
  fresh-oracle(M4 tree)=3324c840bb1ded8c33f25ed1d51f25312f11b327657a5da96f8aea18f8b24242
  new pin              =3324c840bb1ded8c33f25ed1d51f25312f11b327657a5da96f8aea18f8b24242  NEW-PINNED
p08_list_reverse
  old-oracle(676f9f21c)=190b706010ce5c983cc2e09ac6eae396ead523d71aeeef335a6baf992fc2bb67
  pinned@9a8c9febf     =190b706010ce5c983cc2e09ac6eae396ead523d71aeeef335a6baf992fc2bb67  OLD-REPRODUCED
  fresh-oracle(M4 tree)=28fdb9bcd50c2f038ee39bbc5d547aa3e5d8796ff8840e54bfd87c5404f82d6e
  new pin              =28fdb9bcd50c2f038ee39bbc5d547aa3e5d8796ff8840e54bfd87c5404f82d6e  NEW-PINNED
p15_scan_classify
  old-oracle(676f9f21c)=21ae794192ce5d37ee801053cb104e6a0043b8eaffa08c1c7899dd75dea76f53
  pinned@9a8c9febf     =21ae794192ce5d37ee801053cb104e6a0043b8eaffa08c1c7899dd75dea76f53  OLD-REPRODUCED
  fresh-oracle(M4 tree)=01a30241ef2bfafecf5d040b2940d1c15d9170235ebbcc8c9249ba49733b4e1a
  new pin              =01a30241ef2bfafecf5d040b2940d1c15d9170235ebbcc8c9249ba49733b4e1a  NEW-PINNED
```
The arena dumps' whole-text movement (old-oracle dump vs fresh dump, symbol numbers normalised, verbatim
`.tmp/m4-pins/arena-diff.log` headers): p04 `raw-hunks=2 normalised-hunks=2`, p05 `3/3`, p06 `4/4`, p07 `2/2`,
p08 `4/4` — every hunk the cee382443 arm; p15 `raw-hunks=94 normalised-hunks=6` (the 94 raw hunks are the
symbol renumbering that 83b1a7424's two extra fresh symbols cause downstream; the six normalised hunks are the
ones named above).

### 4.5 Tier B row 13 — the libc quotation pins (`lean_frontend/test/CoreQuote/core-quote-libc*.sha256`)

The two libc literal digests follow the M2b libc content re-pin (§2b.4: `tests/libc/libc.core.sha256` =
`f856081198f0…`, `libc_inner_arg_temps.core.sha256` = `06a1f84c288e…`; the libc Core text moved by 83b1a7424 /
cabe81c3b / 588672e95 / cee382443). First run on the old pins (`.tmp/m4-chain-b.log`, verbatim; the round trips
themselves pass and only the pin check fails):
```
Libc-compare: exit 0, 12.49s
Libc round trip: 155.31s
RuntimeError: libc literal SHA-256 drift: 90d09e847ca3569173b748ecc1089e63883423219844a7aeea1323b86bee4373, pinned c165410918073f7c01762238e12ff4ec6d527141ec06bc81c7c5508d41fd4873
✗ core-quote-test FAILED
Libc-compare: exit 0, 7.99s
Libc round trip: 140.74s
RuntimeError: libc literal SHA-256 drift: b7e2711ee7533a4629236b82a6d7f7149cbcc15eb52d16da844a0b3fee47c916, pinned 6f2514217b637cedd4109b7c9698942a63b07e59f126ef257cabcf1fe10db0ca
✗ core-quote-test (inner_arg_temps) FAILED
```
The two digests from those messages written as the pins (`core-quote-libc.sha256` = `90d09e847ca3…`,
`core-quote-libc-inner-arg-temps.sha256` = `b7e2711ee753…`); the re-run (`.tmp/m4-corequote.log`, verbatim last
lines):
```
✓ core-quote-test PASSED
libc sha256: b7e2711ee7533a4629236b82a6d7f7149cbcc15eb52d16da844a0b3fee47c916
Libc-kernel-replay: exit 0, 1.85s
LibcLiteral leanchecker: 1.79 seconds; 838848 KB peak RSS; exit 0
Linked-kernel-replay: exit 0, 1.83s
LinkedLiteral leanchecker: 1.78 seconds; 839084 KB peak RSS; exit 0
LinkedRich-kernel-replay: exit 0, 1.92s
LinkedRichLiteral leanchecker: 1.86 seconds; 837896 KB peak RSS; exit 0
CORE_QUOTE_TOTAL inputs=3; model constructors=248; floating=84; NaN=0; memory-values=0; positions=44510; absolute-paths=0
Core quote round trip: PASS (whole-file representation, comparator syntax, auxiliary BEq)
✓ core-quote-test (inner_arg_temps) PASSED
Total: 2 passed, 0 failed
```
Disposition: upstream's fix (text only; the quotation round trips and the three `leanchecker` replays are green).

### 4.6 The re-checks on the edited baselines and the remaining focused lanes (`.tmp/m4-chain-b.log`, verbatim)

Every lane's own verdict line (the chain wrapper's `exit=` lines are not quoted: they reported the filter's status,
a wrapper slip found while reading the log, not the lane's).
```
=== exec_ci --check-baseline 02:39:12 load=7.66
SUMMARY: total=245 match=92 ub_match=43 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=110 cerb_floor=0 cerb_inconsistent=0
Baseline check: 0 regression(s), 0 improvement(s)
BASELINE OK
=== exec_coverage --check-baseline 02:41:55 load=4.73
SUMMARY: total=277 match=222 ub_match=37 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=16 cerb_floor=0 cerb_inconsistent=0
Baseline check: 0 regression(s), 0 improvement(s)
BASELINE OK
=== exec_debug --check-baseline 02:43:13 load=4.18
SUMMARY: total=90 match=66 ub_match=20 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=4 cerb_floor=0 cerb_inconsistent=0
Baseline check: 0 regression(s), 0 improvement(s)
BASELINE OK
=== exec_float --check-baseline 02:43:38 load=3.58
SUMMARY: total=93 match=93 ub_match=0 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=0 cerb_floor=0 cerb_inconsistent=0
Baseline check: 0 regression(s), 0 improvement(s)
BASELINE OK
=== pnvi 02:44:05 load=4.06
SUMMARY: rows=164 AGREE=152 AGREE-FIRST=3 BOTH_FAIL=2 REFUSAL=7 | switch vs default (oracle): litmus:same=27,changed=17 minimal:same=112,changed=1 pkvm:same=1,changed=3 witness:same=0,changed=3
pnvi_lane: BASELINE OK (164 rows = the baseline, classes, oracle hashes and BOTH_FAIL/RESOURCE lean hashes exact)
=== check_fixture_freeze 02:46:48 load=4.34
check_fixture_freeze: OK (16 fixture files match the pinned manifest; name set exact)
=== test_verify (re-pinned) 02:46:48 load=4.34
test_verify: 127 passed, 0 failed (25 fixtures, 28 call points, 14 corpus fixtures, 21 corpus points)
=== inner_arg_temps --gate 02:47:35 load=4.16
SUMMARY: inner_arg_temps rows=186 AGREE=138 AGREE-FIRST=40 BOTH_FAIL=5 LOC_ONLY-FIRST=1 RESOURCE oracle:KILL=2 failures=0
BASELINE OK (inner_arg_temps: 186 rows; classes and both distinct-observation/status hashes exact)
inner_arg_temps elapsed: 411.84s
```
A3/A4/A4b (coverage, debug, float) did not move: the switch/do-while re-measurement §0.9 asked for is these three
`0 regression(s), 0 improvement(s)` lines plus A2's; the float lane stays 93/93 `MATCH` (no row had mirrored the
`mul` bug, §0.9 A4). Also green on the M3 tip and unchanged since (`.tmp/m4-chain-a.log`): `libc_prep.sh
--selftest` exit 0, `test_parse.sh tests/ci` (`Cerberus parse: 250 ok, 3 failed` / `Lean parse: 131 ok, 0 failed,
0 timeout … 0 lean failure(s)`, 253 files = 252 + 0342), `test_core.sh tests/ci` `131 ok … ALL PASSED`.

### 4.7 B5 immaculate — five rows moved; a §0.9 forecast miss, all upstream's fixes

`test_immaculate.sh` on the M3 tip (`.tmp/m4-chain-b.log`, verbatim):
```
DEVIATION: s4b-memcmp-hugesize expected [ORACLE_CRASH | L=UB:{ub: "UB_CERB002a_out_of_bound_load", stderr: "", loc: "<unknown location>"}] got [ORACLE_CRASH | L=UB:{ub: "UB_CERB002a_out_of_bound_load", stderr: "", loc: "<13:10--13:34>"}]
DEVIATION: ts-fmt-s-null expected [MATCH | L=CRASH] got [MATCH | L=UB:{ub: "UB046_array_pointer_outside", stderr: "", loc: "<7:38--7:57>"}]
DEVIATION: zd-ta-alignas-huge-desugar expected [ORACLE_CRASH | L=ERR:{msg: "MerrOther "Concrete.allocator: failed (out of memory)""}] got [MATCH | L=ERR:{msg: "MerrOther "Concrete.allocator: failed (out of memory)""}]
DEVIATION: zd-ta-alignas-huge-sizeof expected [ORACLE_CRASH | L=VAL:{value: "Specified(0)", stdout: "", stderr: "", blocked: "false"}] got [MATCH | L=VAL:{value: "Specified(0)", stdout: "", stderr: "", blocked: "false"}]
DEVIATION: zd-ta-alignas-huge-union-alignof expected [ORACLE_CRASH | L=VAL:{value: "Specified(0)", stdout: "", stderr: "", blocked: "false"}] got [MATCH | L=VAL:{value: "Specified(0)", stdout: "", stderr: "", blocked: "false"}]
```
§0.9 forecast B5 as "tray-44 rows stay" and did not foresee the three `zd-ta-alignas-huge-*` rows (the forecast's
"`alignas/*` stay (tray 47)" was about the coverage lane, which did stay, §4.6). Each row was triangulated with
three oracles on the same inputs — the mainline checkout's (`676f9f21c`, old base), the worktree's (fork at
`c3ff8c53f`) and the pristine upstream build at `c3ff8c53f` (`.tmp/pristine-c3ff8c53f`, §0.10) — verbatim
(`--nolibc --exec --batch --mode=exhaustive`; the libc row without `--nolibc`):
```
=== nolibc/zd-ta-alignas-huge-desugar
  old exit=125: cerberus: internal error, uncaught exception:           Z.Overflow
  fork exit=1: Error {msg: "MerrOther "Concrete.allocator: failed (out of memory)""}
  pristine exit=1: Error {msg: "MerrOther "Concrete.allocator: failed (out of memory)""}
=== nolibc/zd-ta-alignas-huge-sizeof
  old exit=125: cerberus: internal error, uncaught exception:           Z.Overflow
  fork exit=0: Defined {value: "Specified(0)", stdout: "", stderr: "", blocked: "false"}
  pristine exit=0: Defined {value: "Specified(0)", stdout: "", stderr: "", blocked: "false"}
=== nolibc/zd-ta-alignas-huge-union-alignof
  old exit=125: cerberus: internal error, uncaught exception:           Z.Overflow
  fork exit=0: Defined {value: "Specified(0)", stdout: "", stderr: "", blocked: "false"}
  pristine exit=0: Defined {value: "Specified(0)", stdout: "", stderr: "", blocked: "false"}
=== nolibc/ts-fmt-s-null
  old exit=125: cerberus: internal error, uncaught exception:           Failure("TODO(pure shift a null pointer should be undefined behaviour), offset:0")
  fork exit=1: Undefined {ub: "UB046_array_pointer_outside", stderr: "", loc: "<7:38--7:57>"}
  pristine exit=1: Undefined {ub: "UB046_array_pointer_outside", stderr: "", loc: "<7:38--7:57>"}
=== libc/s4b-memcmp-hugesize
  old exit=125: cerberus: internal error, uncaught exception:           Z.Overflow
  fork exit=125: cerberus: internal error, uncaught exception:           Z.Overflow
  pristine exit=125: cerberus: internal error, uncaught exception:           Z.Overflow
```
(The ANSI colour codes around "uncaught exception" are stripped in this quotation; nothing else is altered.)

| row | was → is | disposition | cited to |
|---|---|---|---|
| `zd-ta-alignas-huge-desugar` | `ORACLE_CRASH` → `MATCH` (L unchanged) | upstream's fix: b3e11ea33 moved sizeof/alignof out of the memory interface and computes them unbounded in `Ocaml_implementation.sizeof_ty`/`alignof_ty` (its diff deletes the four `Z.to_int al_n` reads of `impl_mem.ml:248/:267` and `ocaml_implementation.ml:483/:501`); the oracle now gives the answer Lean computed under ISO-fix register R7 ([USER 2026-10-03]). **R7 RETIRED** (VALIDATION.md §2 row and the marker sentence edited; the `CerberusImpl.lean` marker comments are rewritten at M6 with the other cite reconciliation — a comment-only Lean edit would force a full rebuild under this milestone's lane runs [AGENT 2026-10-30]) | b3e11ea33; seam S1 |
| `zd-ta-alignas-huge-sizeof` | `ORACLE_CRASH` → `MATCH` (L `Specified(0)` unchanged) | as above | b3e11ea33; S1 |
| `zd-ta-alignas-huge-union-alignof` | `ORACLE_CRASH` → `MATCH` (L `Specified(0)` unchanged) | as above | b3e11ea33; S1 |
| `ts-fmt-s-null` | `MATCH \| L=CRASH` → `MATCH \| L=UB046 <7:38--7:57>` | upstream's fix: both engines crashed on `printf("%s", NULL)`'s null shift (the oracle's `Failure("TODO(pure shift a null pointer …")`); both now `UB046_array_pointer_outside` at the same location | f4a3a3d54; S2 (`formatted.lem` restatement §2.1); tray 04 |
| `s4b-memcmp-hugesize` | `ORACLE_CRASH \| L=… <unknown location>` → `ORACLE_CRASH \| L=… <13:10--13:34>` | upstream's fix, Lean side only: f4a3a3d54 threads `Loc.t` into `Mem.memcmp` (`mem.lem` `val memcmp: Loc.t -> …`; S2 `memcmpM` gains `loc`), so the per-byte load's UB now carries the call's location; the oracle's crash (tray 13, `impl_mem.ml` memcmp `Z.to_int`, unchanged at `c3ff8c53f`) and register R3 stay as recorded | f4a3a3d54; S2 |

The five rows were hand-edited in `tests/immaculate/baseline.txt` with a header note (the lane's own
`--record-baseline` rewrites the row set; the file's precedent for a row move with a cited reason is a hand edit,
e.g. the 2026-10-03 rows). Re-check on the edited file (`.tmp/m4-chain-c.log`, verbatim):
```
=== immaculate (re-check on the edited baseline) 03:15:30 load=4.41
OK: lane matches the committed baseline (MATCH except the ISO-fix register pins R1 g5-decode-question/zd-e2-ptr-string-literals ORACLE_CRASH, R2 g5-escape-roundtrip/zd-r2-highbyte DIFF and zd-r2-crash-digit9 ORACLE_CRASH
```

### 4.8 B7 — the gcc second oracle (`scripts/gcc_oracle_baseline.txt`)

§0.9 forecast the `tests/minimal/097-null-ptr-arith.undef.c SKIP_LEAN_CRASH -` row flipping. One full run of the
lane written to a scratch ledger and diffed row-for-row against the committed one (`.tmp/m4-chain-c.log`,
verbatim):
```
=== gcc_oracle --write-baseline (scratch) 03:17:21 load=2.73
  Total files:  2030
  Compared:     1934  (agree=1918 agree_nd=0 triaged=16 DISAGREE=0)
  Skipped:      96  (every skip enumerated below and in the baseline rows)
SUMMARY: total=2030 compared=1934 agree=1918 agree_nd=0 triaged=16 disagree=0 o2_agree=197 skip_gcc_compile=4 skip_gcc_stdout=2 skip_lean_crash=16 skip_lean_fail=14 skip_lean_timeout=11 skip_ub=49 triaged_addr=14 triaged
Baseline written: .tmp/m4-pins/gcc_oracle_baseline.new (2030 rows)
gcc second-oracle lane OK
=== diff committed ledger vs scratch (rows only) 03:42:13 load=4.10
```
The lane's own output order differs from the committed file's (rows hand-inserted "sorted by key" over the years sit
a line away from where the lane now writes them), so the raw diff is mostly displacement; the SORTED row sets differ
in exactly two rows (verbatim, `LC_ALL=C sort` both sides, 2030 rows each):
```
1892c1892
< tests/immaculate/nolibc/ts-fmt-s-null.c SKIP_LEAN_CRASH -
---
> tests/immaculate/nolibc/ts-fmt-s-null.c SKIP_UB -
2014c2014
< tests/minimal/097-null-ptr-arith.undef.c SKIP_LEAN_CRASH -
---
> tests/minimal/097-null-ptr-arith.undef.c SKIP_UB -
```
Both rows: Lean no longer crashes (`PANIC` in the null array shift) but reports `UB046_array_pointer_outside`, a
verdict the lane never compares with a native run — `SKIP_LEAN_CRASH` → `SKIP_UB`. Disposition: upstream's fix
(f4a3a3d54, S2). The §0.9 forecast said "flips to agreement"; a UB program has no gcc agreement to reach, so the
flip is to the correct skip class (the forecast's wording was loose, not the lane). The two rows hand-edited in
`scripts/gcc_oracle_baseline.txt` with a header note (the ledger's precedent for a row move); the check that the
edited ledger equals the full run is the sorted-row diff, re-run after the edit: `IDENTICAL (2030 rows)`. The
`--check-baseline` form (Tier B row 7, ~25 min) is keyed by row (`B_S[$f]`, order-insensitive) and runs in the
orchestrator's battery; a second full run was not spent here.

### 4.9 What M4 verified, and what carries forward

Files in this commit: `scripts/exec_baseline.txt` (1 row), `scripts/exec_ci_baseline.txt` (3 rows),
`tests/pnvi_lane/baseline.txt` (1 row), `tests/inner_arg_temps/baseline.json` (1 row),
`tests/immaculate/baseline.txt` (5 rows), `scripts/gcc_oracle_baseline.txt` (2 rows),
`lean_frontend/test/CoreQuote/core-quote-libc{,-inner-arg-temps}.sha256` (2 pins), the 34 fixture pins of §4.4,
`lean_frontend/VALIDATION.md` (R7 retired), this record. No Lean, lem or OCaml source changed in M4: the Lean binary
and the oracle are M3's (`check_driver_fresh` stamps in `.tmp/m4-chain-b.log`: oracle `bin 52bc5ed6a7d3…`, Lean
`bin be8bd66aef0e…`).

Green in this milestone, each on the edited files (§4.1–4.8): A2 minimal, Tier C ci, A3 coverage, A4 debug, A4b
float, A14 PNVI, A15 inner_arg_temps `--gate`, B4 verify (127/0) + `check_fixture_freeze`, Tier B 13 core-quote libc
(both modes, three `leanchecker` replays), B5 immaculate, B7 gcc (full run, DISAGREE=0, ledger set-equal), Tier B 14
`libc_prep --selftest`, Tier B 2/3 parse/core over tests/ci. Not run here (the orchestrator's Tier A on this tip):
row 1 `test_unit.sh` and the other Tier A rows unchanged since 9a8c9febf's run; the expected red there remains A1's
fork-drift gate until M5.

Forecast reconciliation against §0.9 (*derived*): 9 of 10 forecast movements materialised exactly (A2, A14, A15,
Tier C ×3, A5/B13 pins, B4 pins, B7); one forecast miss — B5's three `zd-ta-alignas-huge-*` rows and the
`s4b-memcmp-hugesize` loc token (§4.7), both upstream's fixes; A3/A4/A4b/A6/A7/A8/A9/A12/A13 did not move. No
finding; nothing refused; nothing silently re-recorded. [2026-10-30: the pre-merge review found what M4's witnesses did not reach — P1, §6b.]

Carried forward: **M5** — `upstream_oracle_differences.json`'s register rows for the three
`tests/coverage/alignas/*` cases (tray 47) are re-derived on the pristine instrument at `c3ff8c53f` with the rest
of the register (§0.10); the three `zd-ta-alignas-huge-*` pins are not register cases (both engines now agree).
**M6** — the three `CerberusImpl.lean` R7 marker comments (lines 326–340, 543–548, 559) rewritten as historical
notes citing b3e11ea33 and this section; tray 04 closes with these rows as its evidence (Q10); VALIDATION's
narrative paragraph on R7 (already annotated) and the TODO's open-bugs list re-read for R7. The ephemeral
`.tmp/m4-pins/{old,fresh,norm}` dumps (~500 MB) are deleted at this commit; `rederive.sh` / `old-oracle.sh`
rebuild them.

---

## 5. M5 — fork drift on the moved base, the pristine instrument (2026-10-30)

Scope as staged ([AGENT 2026-10-30], the orchestrator's go after Tier A on `87ec91341`: 19/20, the one red A1's
fork-drift gate on the pinned merge-base): the pristine instrument rebuilt at `c3ff8c53f`, the differences register
re-derived on it, the manifest rebuilt as the one sanctioned whole-layer re-derivation and reviewed hunk by hunk, the
gates and their selftests, the §0.10 item-4 citations. Logs `.tmp/m5-*.log`, the scratch pristine tree
`.tmp/pristine-c3ff8c53f/` (§0.10 item 1, built at M2b), the instrument `.tmp/upstream-oracle-c3ff8c53f/` (ephemeral).

### 5.1 The pristine instrument (`scripts/build_independent_oracle.py`, `ensure_independent_oracle.py`)

`CERBERUS_REV` moved to `c3ff8c53f05982745f9b3a10b3d05442e214bcb5`; `LEM_REV` `3802cb04…` kept (it builds the new
base). Built offline from the two object stores (`.tmp/m5-oracle-build.log`, verbatim):
```
ensure_independent_oracle: ABSENT — building the pristine oracle into /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-arc/merge-base-bump/.tmp/upstream-oracle-c3ff8c53f
lem-compiler: passed (7.157s)
lem-libraries: passed (1.418s)
lem-runtime-build: passed (4.442s)
lem-runtime-install: passed (0.146s)
cerberus-generation: passed (21.722s)
cerberus-build: passed (9.894s)
ensure_independent_oracle: BUILT+VALID standing build: …/.tmp/upstream-oracle-c3ff8c53f/manifest.json (cerberus c3ff8c53
```
Manifest: `sources: cerberus c3ff8c53f05982745f9b3a10b3d05442e214bcb5, lem 3802cb04b53d5f1096a464e51ecbfb2a750a7ccd`;
`versions: dune 3.23.1, lem "Lem 3802cb0", ocamlc 5.4.0`. A second build of the same archives was made at the lane's
default standing path (§5.6); the two manifests record the same cerberus archive (`archive_sha256` `6809611c6f08c6ab…`)
and the same tools, but the two oracle binaries are NOT byte-identical (`18e53020918ae654…` under `.tmp/`,
`2c96740ef8c003cb…` under `.validation-foundations/` — the build prefix is embedded); the first run of §5.3 used the
`.tmp/` build, the confirming runs the standing one.

### 5.2 The manifest (`scripts/fork_drift_manifest.txt`) — the whole-layer re-derivation

Procedure (the script's refresh recipe plus the merge-base pin, which the gate checks before it refreshes): `[meta]
merge-base=` set to `c3ff8c53f05982745f9b3a10b3d05442e214bcb5` by hand, then `check_fork_drift.sh --refresh` with
`CERB_UPSTREAM_TREE` = the scratch pristine tree. **A first refresh was wrong and was discarded**: run through
`scripts/ce`, the container's `scripts/env.sh` exports `CERB_UPSTREAM_TREE` to `deps/cerberus-upstream/…` (still the
`b9aeedcb4` tree) over the variable given on the command line, so the fork's generated tree was diffed against the OLD
pristine tree and nine upstream-changed modules (`cabs`, `constraint`, `core_eval`, `defacto_memory`, `errors`,
`integerType`, `scope_table`, `undefined`, `formatted`) entered `[expected-semantic]` (22 → 31). Caught by
`diff -rq` of the two trees (only `formatted.ml` among the nine differs); the manifest was restored from the committed
copy and refreshed again with the override applied after `env.sh` (`scripts/ce env CERB_UPSTREAM_TREE=… sh -c …`,
verbatim `tree=…/.tmp/pristine-c3ff8c53f/ocaml_frontend/generated` echoed by the run). Consequence for every gate run
until landing: the fork-drift gate must be given the new tree explicitly (§5.6); `env.sh` and `deps/cerberus-upstream`
move at landing (§0.10 item 1).

The refresh drops the hand-written NOTE header and the `renumber=arc13` line (it emits only `merge-base` and
`lem-pin` under `[meta]`); both were restored by hand — the new NOTE block at the top records this re-derivation, closes
the I0/I0b notes as merged away (kept below it as history) and registers the two stage-1 fork-ahead deltas.

Row counts (*derived* from the two files; `.tmp/m5-manifest-before.txt` is the committed manifest):

| section | before (`87ec91341`) | after | movement |
|---|---|---|---|
| `[files]` | 93 | 93 | set unchanged |
| `[source-content]` | 93 rows (103 lines incl. in-section notes) | 93 | 36 rows re-pinned — the fork's own oracle-surface files the merge changed: `backend/common/{ail_sym_hwm,driver_ocaml,pipeline}.ml`, `pipeline.mli`, `backend/driver/main.ml`, `backend/lean_export/cabs_json.ml`, `cerberus-lib.opam`, 19 `frontend/model/*.lem`, the four `memory/*/impl_mem.ml`, `ocaml_frontend/{dune,fork_renumber.ml,memory_model.ml,ocaml_implementation.ml,ocaml_implementation.mli}`, `parsers/c/c_parser.mly` |
| `[expected-semantic]` | 22 | 22 | `translation_aux.ml` LEFT; `formatted.ml` ENTERED; 11 hashes moved; 10 unchanged |
| `[expected-cosmetic]` | 10 | 10 | `ctype.ml`'s hash moved (one blank line; still comment/blank-only); 9 unchanged |

Layer-2 review, hunk by hunk (`diff` of the pristine generated file against the fork's, every differing file read;
the 10 semantic rows whose hash did not move carry deltas byte-identical to the previously reviewed ones):

| generated file | delta lines | what the delta is | §0.10 expectation |
|---|---|---|---|
| `translation_aux.ml` | 0 (left) | the I0b backport of 3230aa494 is upstream's text now | expected to leave — yes |
| `formatted.ml` | 12 (entered) | `store_chars_in_array` restated with the list as an explicit parameter (an eta-expansion of f4a3a3d54's `let loc = … in function …`; §2.1 deviation 3) | registered fork-ahead delta (2) |
| `translation.ml` | 294 | C1 elaboration mints (`fresh_elab_*`) on 334a1563b's `elabM`, incl. the `case_` mints of cabe81c3b (a threaded `elab_mapM` over upstream's `List.map`) and the `while_`/`do_` mints on 83b1a7424's text; D13 compound-assignment refusal with the `AilElabel_addressGNU` arm (c8c085d47, S6); E-A `enumDefs`; `translate sup …` (R1) | supply/refusal deltas re-derived — yes |
| `translation_effect.ml` | 93 | C1 `fresh_supply` field and mints on upstream's `elab_config -> elab_state -> …`; `elab_initial_state seed` | yes |
| `cabs_to_ail.ml` | 169 | supply/top drawn around the const-expr mini-run; D3 seeds incl. the fifth (`typecheckAil_promoted_seeded`, on 588672e95's switch desugaring); D12 anonymous-member, asm and alignas (P2d-3) refusals unchanged; `desugar sup top desug_conf …` (R1) | yes |
| `cabs_to_ail_effect.ml` | 233 | `fresh_sym_supply`/`address_space_top` state fields before upstream's `desug_config` (R1); D3 seed defs; E-A `enum_definitions_of_tag_definitions`; `alignof_ty_seeded` over `Ocaml_implementation.alignof` (b3e11ea33's host) | yes |
| `mini_pipeline.ml` | 188 | supply/top before `elab_config` (R1); `run_const_expr_driver` and the five D3 seeds; **the 736690a65 backport** (`C.tagDefs = core_tagDefs`) | registered fork-ahead delta (1) |
| `implementation.ml` | 108 | E-A enum reader (`enum_compatible_type`, `typeof_enum`, `resolve_enum`); the `sizeof_ty`/`alignof_ty` Lean target_reps on b3e11ea33's vals (the former `alignof_proxy` part is gone with `impl_mem.ml`'s layout) | loses the `alignof_proxy` part — yes |
| `core_typing.ml` | 81 | tray-45 arity guards (R1/R3 of the 2026-09 audit) and E-A `enumDefs` — unchanged mechanisms; upstream's surrounding text moved | yes (its "R3 part" is the audit's R3, kept with tray 45) |
| `driver.ml` | 27 | `initial_driver_state_with/_given` (C1, address-space top, D-S digest) — unchanged; b3e11ea33 moved the surrounding lines | yes |
| `genTyping.ml`, `ailSyntax.ml` | 1, 11 | E-A `enum_definitions` — unchanged; a trailing-space line and the surrounding text moved | yes |
| `core_aux`, `core_reduction`, `core_run`, `ctype_aux`, `desugaring_init`, `monadic_parsing`, `core_run_aux`, `symbol`, `mem_common`, `core`, `core_linking` | unchanged hashes | byte-identical deltas (C1 supply, D11 refusal, measure restatements, SC WP0 receipts, E-A) | unchanged |
| `ctype.ml` (cosmetic) | 1 | one blank line | still cosmetic |

No hunk is unexplained; no new differing file beyond `formatted.ml`; nothing left silently.

### 5.3 The pristine-difference register (`scripts/upstream_oracle_differences.json`), re-derived on the new instrument

First run on the committed register (`scripts/test_upstream_oracle.py --corpus tier-b --build-manifest
.tmp/upstream-oracle-c3ff8c53f/manifest.json`, `.tmp/m5-upstream-oracle-tierb.log`, verbatim last lines; `source
unchanged: False` because the manifest and the docs were being edited during the 220 s run — the confirming run
below is clean):
```
Independent oracle scope: tier-b; 996 rows in 220.6s; source unchanged: False
Independent oracle: failed; {'semantic_agreement': 953, 'difference': 5, 'reviewed_difference': 6, 'matching_failure': 30, 'interface_agreement': 2}; …
```
The eleven non-agreeing rows (verbatim from the log, `difference` = fails the lane; `reviewed_difference` = a
register row reproduced exactly):
```
106/996 difference: minimal/106-sizeof-struct-array.c (pristine 0.0s, fork 0.0s)
112/996 reviewed_difference: minimal/112-allocator-exhausted-single-request.c (pristine 0.0s, fork 0.0s)
113/996 reviewed_difference: minimal/113-allocator-exhausted-single-request-overlap.c (pristine 0.0s, fork 0.0s)
114/996 reviewed_difference: coverage/alignas/alignas-001-self-char.c (pristine 30.3s, fork 0.1s)
115/996 difference: coverage/alignas/alignas-002-fwd-char.c (pristine 0.1s, fork 0.1s)
116/996 difference: coverage/alignas/alignas-003-self-int.c (pristine 0.1s, fork 0.1s)
644/996 reviewed_difference: multi_tu_tray/node (pristine 30.1s, fork 0.0s)
900/996 reviewed_difference: immaculate/nolibc/tray44-allocator-exhausted-single-request-overlap (pristine 0.0s, fork 0.0s)
901/996 reviewed_difference: immaculate/nolibc/tray44-allocator-exhausted-single-request (pristine 0.0s, fork 0.0s)
924/996 difference: immaculate/nolibc/zd-z2fl03-nan-to-int (pristine 0.0s, fork 0.0s)
948/996 difference: immaculate/libc/zd-r2-crash-digit9 (pristine 0.3s, fork 0.2s)
```
Each of the nine committed cases re-examined on the captures (`.tmp/m5-upstream-oracle-tierb.json/NNNN/{upstream,fork}.stderr`;
the lane's diagnostic projection keeps frame NAMES and order and normalises frame positions, `project_diagnostics`):

| case (class) | observation at `c3ff8c53f` | disposition |
|---|---|---|
| `multi_tu_tray/node` (shared-model-fix, tray 37) | pristine rc 124 (30 s, non-terminating `are_compatible`), fork rc 1 — signatures as pinned | kept; rationale notes the re-observation |
| `minimal/112`, `minimal/113`, `immaculate/nolibc/tray44-*` ×2 (shared-model-fix, tray 44) | pristine rc 0 with the pre-fix allocator's values, fork rc 1 (out-of-memory kill) — as pinned; the allocator idiom is the same text at `c3ff8c53f` `impl_mem.ml:1077` (was `:1254`) | kept; re-observation noted |
| `coverage/alignas/alignas-001-self-char.c` (shared-model-fix, tray 47) | pristine rc 124 (non-terminating), fork rc 1 (constraint violation) — as pinned | kept; re-observation noted |
| `coverage/alignas/alignas-002-fwd-char.c`, `-003-self-int.c` (shared-model-fix, tray 47) | pristine still `uncaught exception: Not_found` rc 125, now raised from `Ocaml_implementation.alignof` (`ocaml_implementation.ml:545`) — b3e11ea33 moved the layout out of `impl_mem.ml`, so the pristine diagnostic signature moved; the fork's signature (`…:6:38: error: constraint violation: invalid application of '_Alignof' to an incomplete type 'struct Fwd'` / `…:5:35 … 'struct A'`) unchanged | pristine signature RE-PINNED (`a99db77e…` → `82df5a8b…`, `a81fc0c4…` → `b172126e…`); rationale extended |
| `immaculate/nolibc/zd-z2fl03-nan-to-int` (diagnostic-text) | both engines rc 125, `Z.Overflow` at `Impl_mem.Concrete.ivfromfloat`, identical projected diagnostics (`e09a529f…` both): the two extra `Core_eval.step_eval_pexpr` frames the I0b backport (3230aa494) added to the fork are upstream's own at `c3ff8c53f` | **REMOVED** — the case no longer differs |

Two cases differ that no row covered, both consequences of decisions already recorded in this slice (reported here so
the orchestrator can reject either row):

| case | observation | row added |
|---|---|---|
| `minimal/106-sizeof-struct-array.c` | pristine `c3ff8c53f` rc 125 `Not_found` at `Pmap.find` from `Ocaml_implementation.offsetsof` (`:439`) via `sizeof` (`:497`) from `core_eval.ml` — upstream's regression (b3e11ea33 → fixed by its next commit 736690a65; §2b.1, tray 67); fork rc 0 `Specified(32)` by the one-line backport ([USER 2026-10-30] ruling (a)) | class `shared-model-fix`, citing tray 67 and this record; leaves at stage 2 with 736690a65 |
| `immaculate/libc/zd-r2-crash-digit9` | both rc 125 with the same `Failure("decode_character_constant, started like an octal constant, but failed: 199")` and the same frames; the ONE projected difference is the frame name `Cerb_frontend__Formatted.store_chars_in_array` (fork) vs `…store_chars_in_array.(fun)` (pristine): the `function`-bound list of f4a3a3d54's text is an anonymous function, the fork's restatement (§2.1 deviation 3) a named parameter | class `diagnostic-text` (the zd-z2fl03 precedent: a frame-shape difference from a registered fork delta), citing this record and tray 11; leaves with the restatement |

Register case list, before → after (*derived*): 9 → 10 — `multi_tu_tray/node`, `minimal/112…`, `minimal/113…`,
`immaculate/nolibc/tray44-…` ×2, `coverage/alignas/alignas-00{1,2,3}…` kept (two re-pinned);
`immaculate/nolibc/zd-z2fl03-nan-to-int` removed; `minimal/106-sizeof-struct-array.c` and
`immaculate/libc/zd-r2-crash-digit9` added. The committed key order and JSON formatting are preserved (the diff is
the rows named). The 106 row's program text was checked against `tests/minimal/106-sizeof-struct-array.c`.

Confirming runs on the edited register against the standing build (`.validation-foundations/independent-oracle-v2`,
§5.6; `.tmp/m5-chain-d.log`, verbatim last lines):
```
=== test_upstream_oracle --corpus tier-b 04:28:04 load=2.83
Independent oracle scope: tier-b; 996 rows in 187.4s; source unchanged: True
Independent oracle: passed; {'semantic_agreement': 953, 'reviewed_difference': 10, 'matching_failure': 31, 'interface_agreement': 2}; …/.tmp/m5-tierb-confirm/report.json
=== test_upstream_oracle --plant 04:31:11 load=2.55
3/3 plant_ok: plant/withheld-row:minimal/106-sizeof-struct-array.c — minimal/106-sizeof-struct-array.c: with its register row -> reviewed_difference; row withheld -> difference (fatal engine diagnostic; no completed observation)
Independent oracle scope: plant; 53 rows in 1.5s; source unchanged: True
Independent oracle: plants_passed; {'semantic_agreement': 1, 'plant_rejected': 1, 'plant_ok': 51}; …/.tmp/m5-plant/report.json
=== test_upstream_oracle --corpus libxml2_chvalid 04:31:13 load=2.55
4/4 semantic_agreement: libxml2/chvalid/chvalid_battery_03 (pristine 57.8s, fork 55.5s)
Independent oracle scope: libxml2_chvalid; 4 rows in 422.3s; source unchanged: True
Independent oracle: passed; {'semantic_agreement': 4}; …/.tmp/m5-chvalid/report.json
```
(*derived*: `matching_failure` 30 → 31 is `zd-z2fl03-nan-to-int` moving from a register row to a both-sides-identical
failure; `reviewed_difference` 6 → 10 is the eight kept rows plus the two added; the withheld-row plant now exercises the
106 row — with the row the case is `reviewed_difference`, without it `difference`.)

### 5.4 The merge-base citations (§0.10 item 4)

Moved (they name the base): `scripts/build_independent_oracle.py` `CERBERUS_REV`; the manifest's `[meta]`;
`lean_frontend/CONTRACT.md` §2 (the matched-mode line); `lean_frontend/VALIDATION.md` §0 (the "upstream/pristine"
definition and "THE reference"), §… "Pristine upstream, the reference" and the gate table's row-10 line;
`scripts/LADDER.md` Tier B row 10 and the Tier C three-engine row. Left in place (they quote a line at the revision
they name, and that text has not moved or retired — item 4's rule): the D11/D12/D13/item-G refusal texts and scripts
(`check_{union_init,anonymous_members,compound_assignment,item_g}_refusals.sh`, CONTRACT §§, VALIDATION §§ —
`b9aeedcb4 :2697`, `:2505-2531`, `:576`, `:2636`), `scripts/fuel_hypotheses.txt`'s `impl_mem.ml:173/:255` row,
`scripts/test_stops.py` / `test_observation_lanes.py` (`UP = ['cerberus', 'b9aeedcb4…', 'memory/concrete/impl_mem.ml',
'2658', '2659', 'assert false']` — the fixture of the stop record `CerbStopSites.lean` still emits for `CerbMem.memcmp`,
whose site did not move at stage 1), VALIDATION's measured facts ("non-functional at `b9aeedcb4`", the allocator
register narrative — re-read in §5.3), `test_address_space.sh`'s pre-fix allocator note, the test READMEs; every
dated record. `CerbStopSites` keeps `b9aeedcb4` for every site whose source did not move (M2: the S1/S2 sites cite
`c3ff8c53f` through `implSourceStage1`).

### 5.5 Gates (verbatim last lines; `CERB_UPSTREAM_TREE` = the scratch pristine tree, applied after `env.sh`)

```
check_fork_content: OK — 93 source files content/mode-pinned
check_fork_drift: OK — layer 1: 93 oracle-surface files = manifest (set, C-locale canonical, no duplicates); layer 2: 32 differing generated files, all hash-pinned (merge-base c3ff8c53f05982745f9b3a10b3d05442e214bcb5; lem-pin e6d8db5680962f49060257d6c2bcb13c284b910f matches lem -v lean-backend-v0.1.0-alpha.1-78-ge6d8db5 (hex prefix))
check_fork_drift: SELFTEST OK (31 plants with declared verdict/message: S1-S10 prerequisite/locale/name controls; S31 advanced upstream ref (not drift); S11 copied-content control; S12 inside-listed-file drift; S13/S14 duplicate/missing content pins; S15-S30 version forms, full-pin validation and refresh retention; unplanted gate green)
check_pin_sites: OK — lem-pin e6d8db5680962f49060257d6c2bcb13c284b910f at every site (lakefile rev, 3 lake-manifests rev+inputRev, README pin command)
check_pin_sites: SELFTEST OK (8 plants red with the declared message, unplanted copies green)
```

### 5.6 What the next gate runs need (until landing)

- **The fork-drift gate's tree.** `scripts/env.sh` exports `CERB_UPSTREAM_TREE` to the container's
  `deps/cerberus-upstream/ocaml_frontend/generated`, still `b9aeedcb4`'s. Against it the gate on this tip is RED for a
  new reason (verbatim tail of a run through plain `scripts/ce`):
  ```
      undefined.ml
  --- excused in the manifest but byte-identical now (stale manifest or stale build):
  If ocaml_frontend/generated might be stale, regenerate with the pinned
  lem ('opam exec --switch=. -- make prelude-src') before concluding drift.
  ```
  (the nine upstream-changed modules differ from the OLD tree). A1 on this tip needs
  `CERB_UPSTREAM_TREE=<worktree>/.tmp/pristine-c3ff8c53f/ocaml_frontend/generated` exported after `env.sh`
  (`scripts/ce env CERB_UPSTREAM_TREE=… <cmd>`), or `deps/cerberus-upstream` moved to `c3ff8c53f` and regenerated
  with lem `e6d8db5` — the landing act (§0.10 item 1), the operator's.
- **The standing pristine build.** `.validation-foundations/independent-oracle-v2` held a `b9aeedcb4` build (status
  `built`, 2026-10-29 20:46), which the lane's validator would now refuse (`CERBERUS_REV` moved). Removed here
  [AGENT 2026-10-30] (an ephemeral, gitignored build; `ensure_independent_oracle.py` names the directory for removal
  rather than overwriting) and rebuilt at the default path by `ensure_independent_oracle.py`, so Tier B rows 10/12 find a
  valid build without an environment variable; §5.1's `.tmp/upstream-oracle-c3ff8c53f` is the same sources and tools
  (the two binaries differ by the embedded prefix, §5.1).


### 5.7 What M5 verified, and what carries forward

Files in this commit: `scripts/fork_drift_manifest.txt` (the whole-layer re-derivation + NOTE block),
`scripts/upstream_oracle_differences.json` (9 → 10 cases), `scripts/build_independent_oracle.py` (`CERBERUS_REV`),
`lean_frontend/{CONTRACT,VALIDATION}.md` and `scripts/LADDER.md` (the base citations of §5.4), this record. No Lean,
lem or OCaml source changed in M5; the binaries are M3's.

Green: `check_fork_drift.sh` + `--selftest` and `check_pin_sites.sh` + `--selftest` (§5.5, with the new tree);
Tier B rows 10 and 12 and `--plant` on the edited register (§5.3). Not run here: Tier A row 1 (the orchestrator's,
with the tree override of §5.6); the fork-drift gate under the container's `env.sh` stays RED until the operator moves
`deps/cerberus-upstream` (§0.10 item 1).

Carried forward to **M6**: the records (this file's §6), the tray INDEX closures (Q10: 01/04/15/33; PR 1020 carried
by the base; tray 67 open as filed), `TODO.md` (arm-4 retirement, the bump entry, the stage-2 queue incl. the two
fork-ahead deltas' removal and the R7 marker rewrite of §4.7), the lem-lean TODO item for the `let … in function`
shape, CONTRACT/VALIDATION/SUPPORTED/README base moves beyond §5.4, the consumer notes (cerberus-caesium, cerberus-sl:
the §8 stage-1 list), `lean_frontend/CLAUDE.md`'s reconciliation line, and the report of the finding-1 ruling to the
operator. Ephemeral at this commit: `.tmp/pristine-c3ff8c53f/` (the gate's tree until landing — kept),
`.tmp/upstream-oracle-c3ff8c53f/` (deleted: the standing build at `.validation-foundations/` replaces it),
`.tmp/m5-upstream-oracle-tierb.json/`, `.tmp/m5-tierb-confirm/`, `.tmp/m5-plant/`, `.tmp/m5-chvalid/` (deleted; the
logs stay).

---

## 5b. M5b — the libc float-literal inventory register, re-derived (2026-10-30)

Found by the orchestrator's Tier A on `33026c2d5` (evidence `.tmp/release/bump-fast-m5-20261030T043957Z`; the one red
step of A1, verbatim as relayed):
```
check_libc_float_literals: SELFTEST FAIL — plant 'unplanted': expected OK, got ["unregistered literal '3.40282347e+38' at line 41726 (x1)", "unregistered literal '0.' at line 53407 (x1)", "unregiste…
test_unit: libc dump float-literal inventory FAILED
```
The register `scripts/libc_float_literals.txt` (named deviation N3, VALIDATION §2b) pins every float literal of
`tests/libc/libc.core` by LINE; M2b re-pinned the dump (§2b.4) without re-deriving the register — a step §0.9's A5 row
did not list (forecast miss, noted under §0.9). Reproduced here (`scripts/check_libc_float_literals.py`, verbatim last
lines of the 48): every registered line "is not in the dump", every literal "unregistered" 28 lines later.

Re-derivation (`.tmp/m5b-libc-old.core` = the dump at the old base `676f9f21c`; *derived* by a census of both dumps
with the script's own regex): old dump 24 literals, new dump 24, `tests/libc/libc_inner_arg_temps.core` 24; the three
multisets AND the literal order are identical; every literal moved by exactly `+28` lines (`41698 → 41726`, …,
`64811 → 64839`), none added, none dropped. The +28, with symbol numbers normalised (469 hunks between the dumps):
453 hunks are cee382443's `nd(pure(True), pure(False))` → `pure(undef(<<UB_CERB004_unspecified__if/while>>))` arms
(one line for one; one arm +2 lines, after the last literal), 9 the `switch` arms, 4 the `do` arms (`DUMMY(unspecified
AilSdo)` → `UB_CERB004_unspecified__do`), and exactly two hunks change the line count before the first literal:
new lines 30439 and 30719, the two `do … while` tests of `proc strcspn` rewritten by 83b1a7424's `mkTestExpression`
shape (`load('char', …)` compared with `Specified(0)` under `if conv_int(…) = conv_int(…)`), +14 lines each. So every
row is a RELOCATION; no new literal, no upstream commit to cite for a literal; the one `LOSSY-N3` row
(`1.84467440737e+19`, `decfloat`'s `0x1p64`) is unchanged in value and disposition.

Register rewritten: the 24 rows' line numbers +28, dispositions and notes carried unchanged, a dated header note.
Check and selftest on the rewritten register (verbatim):
```
check_libc_float_literals: OK (24 float literals in tests/libc/libc.core = the register exactly; 1 LOSSY-N3)
check_libc_float_literals: SELFTEST OK (8 plants: unplanted OK; added, dropped, relabelled-lossy, empty dump, malformed register, second copy on a registered line, duplicated register row all FAIL)
```
The register covers `tests/libc/libc.core` only (the script's `DUMP`); the `inner_arg_temps` dump is not pinned by it
and was censused here for information only (identical multiset).

---

## 6. M6 — records, closures, consumer notes; the slice's close-out (2026-10-30)

Scope as staged by the orchestrator after Tier A on `33026c2d5` and M5b [AGENT 2026-10-30]. No separate Tier A on this
tip: the orchestrator runs the full battery on it with a fresh reviewer.

### 6.1 The one Lean edit: the retired ISO-fix markers (comments only)

`lean_frontend/CerberusImpl.lean` — the three R7 marker comments (the layout header's DECLARED paragraph, the struct
fold, the union fold) are historical notes: the `Z.to_int al_n` reads they cited are `b9aeedcb4`'s; at `c3ff8c53f`
`Ocaml_implementation.alignof_ty` folds the same maximum on Z (`ocaml_implementation.ml:535-549`, verified against the
pristine tree), so the folds are plain mirrors and the pins `zd-ta-alignas-huge-*` are `MATCH` (§4.7).
`lean_frontend/CerbFloat.lean` — the R6 marker is a historical note too: upstream 766073467 (tray 01, Cerberus #1009)
fixed `Cerb_floating.mul` to `( *. )` (`util/cerb_floating.ml:5` at `c3ff8c53f`, verbatim `let mul = ( *. )`; the fork
never touched the file, §1.3), so `floatMul` is a plain mirror. VALIDATION §2: the R6 row prefixed RETIRED like R7's;
the marker sentence says the live register is R1, R2, R3, R5 and that the R6/R7 markers stay as notes so the grep
still finds the sites. Regeneration and the warm build (`.tmp/m6-build.log`, verbatim):
```
[COPY] 57 hand-written Lean files (lean_frontend/handwritten_copy.manifest) into [lean_frontend/generated]
check_handwritten_sync: OK (57 hand-written files byte-identical to lean_frontend/generated/; manifest lean_frontend/handwritten_copy.manifest)
check_lem_sync: recorded lean_frontend/lem_sync.sha256 (src 6f59f40954fda517a8462abbcc6534d8e8512ec14ecda94453bda78271a0a1a6, gen a478f16e3e7575e58c9ffeedbe3745e2e05d73833ae7f12adff238d164458a7c)
Build completed successfully (409 jobs).
check_lem_sync: lean OK (src 6f59f40954fda517a8462abbcc6534d8e8512ec14ecda94453bda78271a0a1a6, gen a478f16e3e7575e58c9ffeedbe3745e2e05d73833ae7f12adff238d164458a7c)
check_lem_sync: OK (src 6f59f40954fda517a8462abbcc6534d8e8512ec14ecda94453bda78271a0a1a6, gen 14399a384896605c710655f49cdac2204002baa00f12805ea1c429898fb29345)
```
(the generated tree is byte-identical to M3's apart from the two copied seams; the stamp file is not tracked.)

### 6.2 Closures and documents

- **Tray INDEX** (Q10, [USER 2026-10-29]): reports 01, 04, 15 and 33 are closed as fixed upstream and carried by the
  base since stage 1 — 01 `766073467` (keeps its Filed state, Cerberus #1009), 04 `f4a3a3d54` (its commit message
  `Fixes: cerberus-lean-04`), 15 `3230aa494` (the I0b backport merged away), 33 `cee382443` (the question answered:
  UB by default, the ND reading behind the refused switch). The backports paragraph says PR 1020 and 3230aa494 are
  upstream's own text now; report 67 stays open as filed with its backport a registered fork-ahead delta.
- **TODO.md**: the bump entry rewritten (stage 1 DONE on `arc/merge-base-bump`, the landing the operator's; stage 2
  QUEUED with its list — `Config`, the `tagDefs`-reader retirement, the CN parser split, `calling_convention0`, the
  `.undef.c` renames, the two fork-ahead deltas' departure, the `CerbStopSites` re-check, the register's tray-37/44/47
  rows); arm (4) of "Crashes on valid C become declared refusals" (`NULL + 0`) RETIRED as carried by the base; the
  "Locations in the Core text transport" slice (M2d) stays queued.
- **Consumer notes**: `docs/2026-10-30_consumer-note-cerberus-caesium-merge-base-bump-stage1.md` (the §8 stage-1
  list in full: `desug_config`/`elab_config` arguments, the two `…Elabel_addressGNU` constructors, the Core-text
  re-quotes, `Undefined.t` array shift, the layout move to `CerberusImpl.*`, the moved verdicts, the stops) and
  `docs/2026-10-30_consumer-note-cerberus-sl-merge-base-bump-stage1.md` (the driver/outcome-protocol/memory-model
  view, with the N4 transport limitation).
- **Reconciliation stamps**: `lean_frontend/CLAUDE.md`, `README.md` and `SUPPORTED.md` carry a dated stage-1 line
  (base `c3ff8c53f`, Lem `e6d8db5`) before their 2026-09-25 checks (which name the FORK commit `bb487dda7`, left as
  history). CONTRACT §2 and VALIDATION's base lines moved at M5 (§5.4); SUPPORTED's N4 paragraph at M2d.
- **The backports' disappearance** (§0.11): verified at M1 (§1.3: `translation_aux.lem`'s I0b text and the
  `util/cerb_floating.ml` mul fix are upstream's, `pp_symbol` and the PR 1020 arms identical) and confirmed by the M5
  manifest (`translation_aux.ml` left layer 2, §5.2).

### 6.3 For the operator (relayed through the orchestrator)

- **Finding 1's ruling** (§2b.1, [USER 2026-10-30] option (a)): the one-line backport of 736690a65 is in the shared
  Lem, registered as fork-ahead delta (1) in the manifest and as the `minimal/106` row of the pristine-difference
  register; tray 67 is the report. Nothing else was overridden; every other movement is upstream's own fix.
- **lem-lean TODO item 59** (docs-only on `mdd/lean-backend`, the operator's precedent `3f48fc2`; not committed by this
  worker), drafted for the register's table — item | source | price | provenance:
  > **59** | A `let rec f x y = let v = … in function | … ` (the list bound by `function` after a `let`, upstream
  > Cerberus `formatted.lem` `store_chars_in_array` since f4a3a3d54) renders on the Lean target as a lambda inside the
  > body, so structural recursion no longer sees the decreasing argument (`fail to show termination`); the consumer
  > restated it with the list as an explicit parameter (an eta-expansion, OCaml semantics identical; a registered
  > fork-ahead delta and a diagnostic-text difference against pristine, cerberus-lean
  > `docs/2026-10-29_merge-base-bump-stage1-record.md` §2.1 deviation 3, §5.3). Backend fix: eta-expand a
  > trailing `function` (and `fun`) in a `let rec` body up to the let-bindings when the matched argument is the
  > recursion's structural argument, or at least report the shape with a pointer to the restatement. Price S–M. |
  > cerberus-lean record §2.1/§5.3; the D1 `many`/`many1` restatement precedent | [AGENT 2026-10-30]
- **At landing** (§0.10 item 1): `deps/cerberus-upstream` to `c3ff8c53f`, regenerated with lem `e6d8db5`, and
  `scripts/env.sh`'s `CERB_UPSTREAM_TREE` following it; until then the fork-drift gate needs the worktree's
  `.tmp/pristine-c3ff8c53f/ocaml_frontend/generated` (§5.6). The standing pristine build at
  `.validation-foundations/independent-oracle-v2` is at `c3ff8c53f` already (worktree-local).

### 6.4 What stage 2 inherits

The TODO's queue (§6.2) and, from this record: the resolution rules R1–R5 (§0.4) and the seam list S1–S8 (§2.1) as
the shape of the next re-threading; the two fork-ahead deltas with their leave conditions; the register's eight
tray-37/44/47 rows and the `106`/`digit9` rows; the `CerbStopSites` cites at `b9aeedcb4`; `CerberusImpl`'s two-map
union arms (the stage-2 mover, §2.1 S1); the refusals of §0.12 (Q9 switch, D11–D13, asm) unchanged; the B5 and A5
forecast misses (§0.9's note) as checks on the next forecast.

### 6.5 Commits of the slice (*derived* from `git log`)

`6a0771381` M0 · `a44c6e0b8` M1 (the merge) · `bb62d0017` M2 · `df2598e47` M2b · `5915e5b3e` M2c · `cec77e5a2` M2d ·
`9a8c9febf` M3 · `87ec91341` M4 · `33026c2d5` M5 · `7bfaec1a2` M5b · M6 = this commit. Scratch: every `.tmp/m*-*`
log, script and draft of this slice is deleted with this commit (reconstructible; the record quotes what mattered);
`.tmp/pristine-c3ff8c53f/` stays until landing (the gate's tree).

---

## 6b. M6b — the pre-merge review's P2 and P3, and P1 raised (2026-10-30)

The fresh reviewer's report: `.tmp/review-bump/2026-10-30_merge-base-bump-stage1-premerge-review.md` (container
scratch; placed beside this record at the close-out commit). Verdict as written: NOT MERGEABLE as it stands — one P1
(an operator ruling), one P2, two P3; everything else checked held up (the 13 resolutions, S2 on three oracles, the
backport, the restatement, LOC_ONLY, the refusals, the manifest re-derivation, its own kernel replay of five modules,
six upstream commits end to end). The orchestrator stopped the full battery; M6b fixes P2 and P3 now, P1 waits for the
ruling (M6c). Dispositions, one by one:

| finding | disposition |
|---|---|
| **P1** — desugar-time `alignof` of a union-containing type crashes the merged fork oracle (and pristine c3ff8c53f) with `Failure("Tags definitions must be set …")` where the pre-merge fork, pristine b9aeedcb4 and Lean answer; unregistered; the record's "unobservable at every stage-1 call site" false; the failure misnamed `Not_found` | **RAISED with the operator** through the orchestrator (the ruling on extending the 736690a65 backport to its alignof line). Done now: the divergence registered in VALIDATION §3's open-bugs list with its owner; the record's §2.1 claim corrected inline and §4.9 annotated; `CerberusImpl.lean`'s two comments corrected (observable at two sites; the global is UNSET, the failure is the `Failure(…)`); the three reproducers prepared under `.tmp/m6b/` with the P1 package (§6b.2) |
| **P2** — the `offsetof-union-member` Lean stop cites `ocaml_implementation.ml:501-504`, which reads the threaded map and does not fail; register row 75's reason says `CerbMem:478` | **FIXED**: `CerbStopSites.sizeofUnion` re-cited to the live upstream failure, alignof's union arm `:565-568` reached from `offsetsof :455`, with a doc comment naming the arm difference (Lean fails in `sizeofCtype`'s `ambient` lookup, the b9aeedcb4 `impl_mem.ml:173` shape); row 75's reason rewritten (`CerberusImpl.lean:505`, both arms named; the reason column is outside the seal — `SEALED = file, definition, token, msg, scope, position, position_reviewed, reach` — so no reseal). The per-function lookup itself is P1's package: with the backport both union arms read the threaded map and the cite returns to `:501-504` |
| **P3** — the charter's D13 constant-expression re-measure unrecorded | **FIXED** (recorded below, re-measured here, not copied from the review) |
| **P3** — the cerberus-sl note says `LOCATION-ONLY` | **FIXED**: `LOC_ONLY` (`LOC_ONLY-FIRST` in the inner_arg_temps lane) |

### 6b.1 The re-measurements (`.tmp/m6b/experiment.sh`, verbatim; five engines: the merged fork oracle, pristine `c3ff8c53f`
(the standing build), pristine `c3ff8c53f` with ONLY 736690a65's alignof line applied and rebuilt in scratch, the pre-merge
fork oracle of the mainline checkout `676f9f21c`, and Lean on the fork oracle's cabs-json)

```
##### p24_alignas_union_twice.c
  fork(merged)       exit=125: cerberus: internal error, uncaught exception:           Failure("Tags definitions must be set by Tags.set_tagDefs before any use")
  pristine c3ff8c53f exit=125: cerberus: internal error, uncaught exception:           Failure("Tags definitions must be set by Tags.set_tagDefs before any use")
  pristine+736690a65-alignof-line exit=0: Defined {value: "Specified(8)", stdout: "", stderr: "", blocked: "false"}
  pre-merge fork 676f9f21c exit=0: Defined {value: "Specified(8)", stdout: "", stderr: "", blocked: "false"}
  lean              exit=0: Defined {value: "Specified(8)", stdout: "", stderr: "", blocked: "false"}
##### p25_alignas_union_redecl.c
  fork(merged)       exit=125: … Failure("Tags definitions must be set by Tags.set_tagDefs before any use")
  pristine c3ff8c53f exit=125: … the same
  pristine+736690a65-alignof-line exit=0: Defined {value: "Specified(0)", …}
  pre-merge fork 676f9f21c exit=0: Defined {value: "Specified(0)", …}
  lean              exit=0: Defined {value: "Specified(0)", …}
##### p27_alignas_struct_union_twice.c
  fork(merged)       exit=125: … the same Failure;  pristine c3ff8c53f exit=125: … the same
  pristine+736690a65-alignof-line exit=0: Defined {value: "Specified(8)", …};  pre-merge fork exit=0: Specified(8);  lean exit=0: Specified(8)
##### p28_alignas_struct_twice_control.c
  all five: exit=0: Defined {value: "Specified(8)", stdout: "", stderr: "", blocked: "false"}
##### p29b_offsetof_union_member_witness.c   (= tests/immaculate/nolibc/offsetof-union-member.c)
  fork(merged)       exit=125: … Failure("Tags definitions must be set by Tags.set_tagDefs before any use")
  pristine c3ff8c53f exit=125: … the same
  pristine+736690a65-alignof-line exit=0: Defined {value: "Specified(0)", stdout: "", stderr: "", blocked: "false"}
  pre-merge fork 676f9f21c exit=125: … the same Failure
  lean              exit=134: lean_frontend/.lake/build/bin/cerberus-lean(+0x4e73a76) [0x59ad7e4f9a76]
##### p15_d13_in_case.c   (switch (1) { case (i += 1, 1): return 2; })
  fork(merged)       exit=1:     expressions with values that duplicate case constant expressions in the enclosing     switch statement.)
  pristine c3ff8c53f exit=1:     … the same (the constraint-violation text of 97371d8ed)
  pristine+736690a65-alignof-line exit=1: … the same
  pre-merge fork 676f9f21c exit=125: cerberus: internal error, uncaught exception:           Failure("internal error: gentpying.annotate_expression: AilEident symbol couldn't be resolved => Symbol(504, SD_ObjectAddress\"i\")")
  lean              exit=1: Error {msg: "desugaring failed at …/.tmp/m6b/p15_d13_in_case.c:3:21-32"}
```
(p24/p25/p27/p28/p15 are the reviewer's probes, copied; p29b is the committed witness. The crash lines are cut after the
exception text; the ANSI colour codes are stripped.)

**The D13 re-measure (P3).** A compound assignment inside a case label is rejected before elaboration on both engines at
the new base — upstream 97371d8ed's integer-constant check (`constraint violation: expression is not an integer
constant expression`, exit 1 on the oracle; Lean's batch record renders the desugar failure as `desugaring failed at
<loc>`, exit 1, the known unattributed rendering of desugar causes, TODO's outcome-protocol mover) — where the old base
crashed in `annotate_expression`. The D13 refusal is therefore no longer reachable from a case label; its
pure-`error` shape still matters for the remaining constant-expression entries (array bounds, enumerators,
`_Static_assert`), which the D13 record's rationale rests on. Measured, not changed.

**P1's scope (for the ruling).** The one alignof line makes the oracle answer p24/p25/p27 AND the `offsetof-union-member`
witness, on which Lean still crashes (its `sizeofCtype` union arm reads `ambient`, the empty elaboration-time table):
the backport alone would turn a pinned both-crash pair into a Lean-only crash on valid C. The package is therefore:
the OCaml line; the Lean mirror — both union arms of the layout workers read the threaded map (`tagDefs`), the proof
carrier's `tp` union case follows (`lookup tagDefs`; worker signatures, wrappers and `scripts/fuel_hypotheses.txt`
unchanged); kernel replay; the `offsetof-union-member` immaculate row, gcc ledger row and register row 75 re-recorded
from both-crash to agreement; the three new immaculate pins at `MATCH`; `ocaml_implementation.ml`'s `[source-content]`
re-pin and NOTE (1) extended to "two lines of 736690a65"; tray 67 extended; `CerbStopSites.sizeofUnion` back to
`:501-504`; the TODO stage-2 list. Fallback if declined: a declared refusal at `get_alignof` on both engines
(the oracle's crash becomes a refusal too), the three pins at the refusal class, a census row.

### 6b.2 Gates and lanes on the M6b tree (verbatim; `.tmp/m6b/build.log`)

```
=== make lean-prelude-src 05:44:44 load=3.99
check_handwritten_sync: OK (57 hand-written files byte-identical to lean_frontend/generated/; manifest lean_frontend/handwritten_copy.manifest)
=== capped lake build 05:45:15 load=4.31
Build completed successfully (409 jobs).
=== check_lem_sync --check-lean
check_lem_sync: lean OK (src 6f59f40954fda517a8462abbcc6534d8e8512ec14ecda94453bda78271a0a1a6, gen a478f16e3e7575e58c9ffeedbe3745e2e05d73833ae7f12adff238d164458a7c)
=== check_failure_reach --selftest
check_failure_reach: SELFTEST OK (8 plants with the declared message — …)
=== check_failure_reach
check_failure_reach: OK (238 pure failure sites = the 238 register rows exactly (236 in the exec dependency closure + 2 unresolved-owner; key = file/owner/token/message, shared keys lengthened, both directions); position classes unchanged; 0 DISCARDABLE; …
=== test_stops.py
Ran 23 tests in 0.008s
OK
=== the stop record on the offsetof witness (Lean), re-cited
PANIC at _private.LemLib.0.failwithIImpl LemLib:226:2: cerberus-lean stop ["1","UPSTREAM_CRASH","CerberusImpl.sizeofUnion","Mirrored upstream failure: CerberusImpl.sizeofCtype: Union tag not a UnionDef (OCaml: assert false / Not_found)",["cerberus","c3ff8c53f05982745f9b3a10b3d05442e214bcb5","ocaml_frontend/ocaml_implementation.ml","565","568","  | Union tag_sym ->\n      begin match Pmap.find tag_
=== test_immaculate
OK: lane matches the committed baseline (MATCH except the ISO-fix register pins R1 g5-decode-question/zd-e2-ptr-string-literals ORACLE_CRASH, R2 g5-escape-roundtrip/zd-r2-highbyte DIFF and zd-r2-crash-digit9 ORACLE_CRASH, R3 s4b-memcmp-hugesize ORACLE_CRASH, …
```

(the register's reason column is outside the seal, so the gate stays green on the refreshed row without a reseal; the
immaculate row `offsetof-union-member MATCH | L=CRASH` is unchanged — a crash token carries no text.)

### 6b.3 The P1 package, prepared (`.tmp/m6b/p1/`, applied on the ruling as M6c)

`apply.py` (every tree edit): the OCaml line (`ocaml_frontend/ocaml_implementation.ml`, alignof's union arm,
736690a65's hunk verbatim); `CerbMem.offsetofIval` passes the explicit map as both maps (the ONE call in the tree that
passed two different maps — every other caller of the two-map layout workers already passes one map twice, so the
workers, the obligations and `scripts/fuel_hypotheses.txt` stay as they are; the asymmetry the two-map form mirrored is
gone with the backported line); `CerbStopSites.sizeofUnion` back to `:501-504`; the `CerberusImpl`, `Main.lean` and
witness-header comments; the three reproducers as `tests/immaculate/nolibc/zd-ta-alignas-{union-twice,union-redecl,
struct-union-twice}.c`; manifest NOTE (1) → "the TWO lines of 736690a65" with the `ocaml_implementation.ml`
`[source-content]` re-pin by `--refresh`-free single-row re-derivation (`check_fork_content.py --emit`); tray 67's
second half; the TODO stage-2 line; VALIDATION's open-bug row resolved and `offsetof-union-member` out of the
both-crash list; register row 75 `REACHABLE` → `UNREACHABLE-BY-INVARIANT` (a review change: `--reseal`). Then:
regeneration, the oracle and Lean builds, `check_failure_reach` (+ selftest), `test_stops.py`, the immaculate lane
(the four rows re-recorded by hand from the lane's lines: three new `MATCH | L=VAL …`, `offsetof-union-member`
`MATCH | L=CRASH` → `MATCH | L=VAL Specified(0)`), the gcc ledger row for `offsetof-union-member`
(`SKIP_LEAN_CRASH` → measured), `check_fork_drift` (+ selftest), the alignas witnesses (`tests/coverage/alignas`,
`check_*_refusals.sh`), and `test_upstream_oracle --corpus tier-b`, where `immaculate/nolibc/offsetof-union-member`
and the three new pins become fork-answers/pristine-crashes differences and get `shared-model-fix` register rows
citing tray 67 — four more rows (10 → 14). Fallback if declined: a declared refusal at `get_alignof` on
union-containing types on both engines (the oracle's crash becomes a refusal too), the pins at the refusal class, a
census row.

---

## 6c. M6c — the ruling on P1 applied: the second line of 736690a65 and its one-call Lean mirror (2026-10-30)

**Ruling [USER 2026-10-30], relayed by the orchestrator: option 1.** The 736690a65 backport authorization (§2b.1,
ruling (a)) is extended to the one OCaml line of the same commit — `Ocaml_implementation.alignof`'s union arm reads
the threaded `tagDefs` instead of `Tags.tagDefs ()` — together with the one-call Lean mirror measured in §6b.1
(`CerbMem.offsetofIval` passes the explicit map twice, upstream's post-736690a65 one-map shape; no proof change).

### 6c.1 The edits (the staged package of §6b.3, `apply.py`)

- `ocaml_frontend/ocaml_implementation.ml:579`: `begin match Pmap.find tag_sym tagDefs with` (736690a65's hunk
  verbatim, with a FORK marker comment). The fork's generated OCaml is unchanged (hand-written file): the manifest's
  `[source-content]` row re-pinned `36203e0b…` → `5ec9b096…` (the row's hash is `sha256sum` of the file, checked on
  `Makefile`), NOTE (1) rewritten as the TWO lines of 736690a65 with the mechanism of each half; layer 2 untouched.
- `lean_frontend/CerbMem.lean` `offsetofIval`: `offsetsof enumDefs tagDefsMap tagDefsMap tag` — the ONE call in the
  tree that passed two different maps (the reader, empty at elaboration time, as `ambient`); every call of the
  two-map layout workers is now one-map, so the workers, their obligations and `scripts/fuel_hypotheses.txt` are
  untouched (the `offsetsof_lemFuel` row's two-map hypothesis is still the worker's; `Acyclic.pair` is its instance
  at every call).
- `lean_frontend/CerbStopSites.lean` `sizeofUnion`: back to upstream's `sizeof` union arm `:501-504` (the mirror
  again; the leaf is unreachable by the typing invariant); the `CerberusImpl.lean`, `Main.lean` and witness-header
  comments say the asymmetry is closed; `tests/immaculate/nolibc/offsetof-union-member.c`'s header keeps its history.
- `tests/immaculate/nolibc/zd-ta-alignas-{union-twice,union-redecl,struct-union-twice}.c`: the three reproducers
  (the reviewer's p24/p25/p27 with pin headers).
- `scripts/failure_reach_register.txt` row 75 (`CerberusImpl.sizeofCtype_lemFuel`, the `sizeofUnion` leaf):
  `REACHABLE` → `UNREACHABLE-BY-INVARIANT` with the reason (the former witness answers), `--reseal` (verbatim:
  `check_failure_reach: resealed 238 rows of scripts/failure_reach_register.txt (review change: commit with the
  justification)`; tally `UNREACHABLE-BY-INVARIANT=175 REACHABLE=42`).
- Tray 67: the second half of the window appended (reproducers, the `Failure(…)` text, the two lines); `TODO.md`'s
  stage-2 line names both lines and the dead `ambient` parameter's retirement; VALIDATION's open-bugs entry closed
  by the ruling and `offsetof-union-member` taken out of the both-crash list.

### 6c.2 Builds and the five programs (verbatim, `.tmp/m6b/p1/build.log`)

```
=== oracle: dune build 21:37:14 load=2.13
dune exit=0
=== make lean-prelude-src 21:37:16 load=2.13
check_handwritten_sync: OK (57 hand-written files byte-identical to lean_frontend/generated/; manifest lean_frontend/handwritten_copy.manifest)
=== capped lake build 21:37:49 load=3.49
Build completed successfully (409 jobs).
check_lem_sync: OK (src 6f59f40954fda517a8462abbcc6534d8e8512ec14ecda94453bda78271a0a1a6, gen 14399a384896605c710655f49cdac2204002baa00f12805ea1c429898fb29345)
check_lem_sync: lean OK (src 6f59f40954fda517a8462abbcc6534d8e8512ec14ecda94453bda78271a0a1a6, gen a478f16e3e7575e58c9ffeedbe3745e2e05d73833ae7f12adff238d164458a7c)
=== the five probes + witness on the rebuilt fork oracle and Lean 21:39:43 load=13.17
  p24_alignas_union_twice.c: oracle exit=0 Defined {value: "Specified(8)", stdout: "", stderr: "", blocked: "false"} | lean exit=0 Defined {value: "Specified(8)", stdout: "", stderr: "", blocked: "false"}
  p25_alignas_union_redecl.c: oracle exit=0 Defined {value: "Specified(0)", stdout: "", stderr: "", blocked: "false"} | lean exit=0 Defined {value: "Specified(0)", stdout: "", stderr: "", blocked: "false"}
  p27_alignas_struct_union_twice.c: oracle exit=0 Defined {value: "Specified(8)", stdout: "", stderr: "", blocked: "false"} | lean exit=0 Defined {value: "Specified(8)", stdout: "", stderr: "", blocked: "false"}
  p28_alignas_struct_twice_control.c: oracle exit=0 Defined {value: "Specified(8)", stdout: "", stderr: "", blocked: "false"} | lean exit=0 Defined {value: "Specified(8)", stdout: "", stderr: "", blocked: "false"}
  offsetof-union-member.c: oracle exit=0 Defined {value: "Specified(0)", stdout: "", stderr: "", blocked: "false"} | lean exit=0 Defined {value: "Specified(0)", stdout: "", stderr: "", blocked: "false"}
```
(the generated OCaml tree is unchanged: `check_lem_sync: OK` with the same `gen 14399a38…` as M5; the Lean generated
tree moved by the two copied seams only.)

### 6c.3 The measuring lanes (verbatim, `.tmp/m6b/p1/lanes.log`) and the rows they moved

```
=== test_immaculate (measure) 21:40:03 load=11.28
  MATCH          offsetof-union-member  O[VAL:{value: "Specified(0)", stdout: "", stderr: "", blocked: "false"}] L[VAL:{value: "Specified(0)", stdout: "", stderr: "", blocked: "false"}]
  MATCH          zd-ta-alignas-struct-union-twice  O[VAL:{value: "Specified(8)", …}] L[VAL:{value: "Specified(8)", …}]
  MATCH          zd-ta-alignas-union-redecl  O[VAL:{value: "Specified(0)", …}] L[VAL:{value: "Specified(0)", …}]
  MATCH          zd-ta-alignas-union-twice  O[VAL:{value: "Specified(8)", …}] L[VAL:{value: "Specified(8)", …}]
DEVIATION: zd-ta-alignas-union-twice expected [<absent>] got [MATCH | L=VAL:{value: "Specified(8)", stdout: "", stderr: "", blocked: "false"}]
DEVIATION: zd-ta-alignas-struct-union-twice expected [<absent>] got [MATCH | L=VAL:{value: "Specified(8)", stdout: "", stderr: "", blocked: "false"}]
DEVIATION: zd-ta-alignas-union-redecl expected [<absent>] got [MATCH | L=VAL:{value: "Specified(0)", stdout: "", stderr: "", blocked: "false"}]
DEVIATION: offsetof-union-member expected [MATCH | L=CRASH] got [MATCH | L=VAL:{value: "Specified(0)", stdout: "", stderr: "", blocked: "false"}]
=== gcc lane partial over tests/immaculate/nolibc (scratch ledger) 21:41:58 load=5.27
[32/68] AGREE  tests/immaculate/nolibc/offsetof-union-member.c: gcc=0 lean={0}
[62/68] AGREE  tests/immaculate/nolibc/zd-ta-alignas-struct-union-twice.c: gcc=8 lean={8}
[63/68] AGREE  tests/immaculate/nolibc/zd-ta-alignas-union-redecl.c: gcc=0 lean={0}
[64/68] AGREE  tests/immaculate/nolibc/zd-ta-alignas-union-twice.c: gcc=8 lean={8}
SUMMARY: total=68 compared=35 agree=28 agree_nd=0 triaged=7 disagree=0 o2_agree=1 skip_gcc_compile=4 skip_gcc_stdout=2 skip_lean_crash=12 skip_lean_fail=5 skip_ub=10 triaged_addr=5 triaged_float=1 tri…
=== test_upstream_oracle --corpus tier-b (measure) 21:46:13 load=19.66
894/999 difference: immaculate/nolibc/offsetof-union-member (pristine 0.0s, fork 0.0s)
924/999 difference: immaculate/nolibc/zd-ta-alignas-struct-union-twice (pristine 0.0s, fork 0.0s)
925/999 difference: immaculate/nolibc/zd-ta-alignas-union-redecl (pristine 0.0s, fork 0.0s)
926/999 difference: immaculate/nolibc/zd-ta-alignas-union-twice (pristine 0.0s, fork 0.0s)
Independent oracle scope: tier-b; 999 rows in 203.3s; source unchanged: True
Independent oracle: failed; {'semantic_agreement': 953, 'reviewed_difference': 10, 'matching_failure': 30, 'interface_agreement': 2, 'difference': 4}; …
```
Exactly the four predicted movements, nothing else. Rows written by hand from these lines: `tests/immaculate/baseline.txt`
(`offsetof-union-member` → `MATCH | L=VAL Specified(0)`; three new rows after `zd-ta-alignas-huge-union-alignof`; header
note), `scripts/gcc_oracle_baseline.txt` (`offsetof-union-member.c SKIP_LEAN_CRASH -` → `AGREE -`; three rows `AGREE -`
inserted by key; header note; the lane's `--check-baseline` is keyed and runs in the battery), and four
`shared-model-fix` rows in `scripts/upstream_oracle_differences.json` (10 → 14: `immaculate/nolibc/offsetof-union-member`,
`…/zd-ta-alignas-union-twice`, `…/zd-ta-alignas-union-redecl`, `…/zd-ta-alignas-struct-union-twice`; each pins pristine
`125` / fork `0` and quotes pristine's `cerberus: internal error, uncaught exception: Failure("Tags definitions must be set
by Tags.set_tagDefs before any use")` from the run's capture; citations tray 67 and this record).

### 6c.4 Gates and lanes (verbatim; `.tmp/m6b/p1/lanes.log`, `confirm.log`)

```
check_failure_reach: SELFTEST OK (8 plants with the declared message — …)
check_failure_reach: OK (238 pure failure sites = the 238 register rows exactly (236 in the exec dependency closure + 2 unresolved-owner; …); position classes unchanged; 0 DISCARDABLE; …
test_stops.py: Ran 23 tests in 0.008s — OK
check_fork_content: OK — 93 source files content/mode-pinned
check_fork_drift: OK — layer 1: 93 oracle-surface files = manifest (set, C-locale canonical, no duplicates); layer 2: 32 differing generated files, all hash-pinned (merge-base c3ff8c53f05982745f9b3a10b3d05442e214bcb5; lem-pin e6d8db5680962f49060257d6c2bcb13c…
check_fork_drift: SELFTEST OK (31 plants with declared verdict/message: …)
exec coverage: SUMMARY: total=277 match=222 ub_match=37 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=16 cerb_floor=0 cerb_inconsistent=0 / Baseline check: 0 regression(s), 0 improvement(s) / BASELINE OK
check_union_init_refusals: OK (26 cases: …)
check_anonymous_members_refusal: OK (42 cases: …)
check_compound_assignment_refusal: OK (30 cases: …)
check_item_g_refusals: OK (19 cases: …)
check_cli_refusals: OK (…)
=== test_immaculate (check on the edited baseline) 21:50:52 load=7.85
OK: lane matches the committed baseline (MATCH except the ISO-fix register pins R1 g5-decode-question/zd-e2-ptr-string-literals ORACLE_CRASH, R2 g5-escape-roundtrip/zd-r2-highbyte DIFF and zd-r2-crash-digit9 ORACLE_CRASH, R3 s4b-memcmp-hugesize ORACLE_CRASH, R5 r5-hex-subnormal-double-rounding DIFF, …
=== test_upstream_oracle --corpus tier-b (check on the edited register) 21:52:49 load=6.42
Independent oracle scope: tier-b; 999 rows in 204.4s; source unchanged: True
Independent oracle: passed; {'semantic_agreement': 953, 'reviewed_difference': 14, 'matching_failure': 30, 'interface_agreement': 2}; …/.tmp/m6b/p1/tierb-confirm/report.json
=== test_upstream_oracle --plant 21:56:14 load=13.91
3/3 plant_ok: plant/withheld-row:minimal/106-sizeof-struct-array.c — minimal/106-sizeof-struct-array.c: with its register row -> reviewed_difference; row withheld -> difference (fatal engine diagnostic; no completed observation)
Independent oracle: plants_passed; {'semantic_agreement': 1, 'plant_rejected': 1, 'plant_ok': 51}; …/.tmp/m6b/p1/plant/report.json
```
(the `tests/coverage/alignas` witnesses are unchanged — `alignas-002/003` stay `CERB_SKIP`, the fork's constraint
violation, tray 47; the 1-minute load touched 19.7 during the refusal scripts, which fan out oracle and Lean processes —
noted for the box discipline, no run was started above 12.)

### 6c.5 What this closes, and what stage 2 inherits from it

Closed: the pre-merge review's P1 (both halves of tray 67's window carried ahead; no arm of the layout family reads the
Tags global on either engine; the `offsetof-union-member` crash pair of 2026-09-01 is a MATCH). Fork-ahead deltas at
stage 1 are now (1a) `mini_pipeline.ml`'s tag map, (1b) `ocaml_implementation.ml`'s alignof line with its one-call Lean
mirror, (2) the `formatted.ml` restatement — each registered in the manifest NOTE, the differences register and tray 67.
Stage 2 inherits: with 736690a65 in the base (1a)/(1b) leave, `CerbMem.offsetofIval`'s two-map call and the workers'
dead `ambient` parameter retire with the Tags removal (the one-map restatement of the carrier's `tp`), and the
`AcyclicPair` row of `scripts/fuel_hypotheses.txt` collapses to `Acyclic`.

---

## 6.6 Close-out — the full battery on `e1280cf3a`, the review beside the record, the landing recipe (2026-10-30)

### 6.6.1 The full battery (orchestrator-run; evidence `.tmp/release/bump-full-m6c-*`; verbatim as relayed)

```
--- the full battery on e1280cf3a (evidence .tmp/release/bump-full-m6c-20261030T215729Z, 21:57:29 to 00:45:52 UTC, start load 9.21 with two other sessions' batteries running):
full: failed; 43/45 selected commands completed successfully.
Source unchanged: True. Complete tier selection: True.
Release certification: incomplete: reporting/adoption/audit exits require separate evidence.
release rc=1
FAILED A15 (474.8s): `inner_arg_temps: FAIL — corpus/p08_list_reverse: baseline changed: {'class': 'RESOURCE oracle:KILL', …`
FAILED B8.2 (394.5s): `test_kill_plant: FAILED` / `PLANT FAIL [libc_exec SIGKILL stub -> DIFF (not KILL)]: expected /^SUMMARY: match=0 diff=/; got: …`
Every other row PASSED (A1 1086.1 s, B7 1633.8 s, B9 2723.0 s, B10.1 287.9 s, B13 883.5 s).
--- the targeted re-run of the two rows on a quieter box (evidence .tmp/release/bump-rerun-m6c-20261031T004646Z, 00:46:46 to 01:03:15 UTC, start load 5.86):
PASSED A15 (414.6s): SUMMARY: inner_arg_temps rows=186 AGREE=138 AGREE-FIRST=40 BOTH_FAIL=5 LOC_ONLY-FIRST=1 RESOURCE oracle:KILL=2 failures=0
FAILED B8.2 (573.5s): test_kill_plant: FAILED
--- B8.2 after M6d's fix (worker-run by hand, .tmp/m6b/closeout/plant.log):
=== test_kill_plant 01:11:55 load=9.48
PLANT OK   [libc_exec no MATCH]: SUMMARY: match=0 loc_only=0 diff=42
PLANT OK   [libc_exec SIGKILL stub -> DIFF (not KILL)]: SUMMARY: match=0 loc_only=0 diff=42
PLANT OK   [immaculate -> KILL status on a C row]:   KILL           g1-ge-funptr          O[ERR:{msg: "Memory WIP: ge_ptrval"}] L[KILL]
PLANT OK   [immaculate no MATCH]
PLANT OK   [libxml2_uri -> killed label]: FAIL: LEAN_NOLIBC killed by SIGKILL (exit 137 — the per-test cgroup memory cap CERB_TEST_MEM_MAX=4G if the lane's stderr carries capped's OOM-KILLED witness banner, otherwise an external SIGKILL): …
PLANT OK   [libxml2 -> Lean OOM-KILLED]: [chvalid_battery_00] FAIL: Lean OOM-KILLED (exit 137; cgroup memory cap CERB_TEST_MEM_MAX=4G breached — memory.events oom_kill=1)
PLANT OK   [gcc_oracle exit(137) native -> compared (AGREE gcc=137 lean={137}), not SKIP_GCC_KILL]: [1/1] AGREE O2_AGREE …/gcc137/exit137.c: gcc=137 lean={137}
test_kill_plant: all plants read as expected (cap breach -> OOM-KILLED witness; ci_sweep LEAN_KILL, libc_exec KILL, immaculate KILL, uri/libxml2 FAIL-killed; SIGKILL stub NOT the cap class; native exit(137) still compared; no MATCH anywhere)
kill-plant exit=0
```

A15's first failure was a load artefact (a resource-class row moving under load; the standing LOAD CAVEAT of the
harnesses) — the re-run on a quiet box reproduced the baseline exactly. B8.2 was genuine and M2d's: §6.6.1b.

### 6.6.1b M6d — the kill-plant's libc_exec expectation (the one real red)

`scripts/test_kill_plant.sh:94` expected `^SUMMARY: match=0 diff=` from `test_libc_exec.sh`, whose summary line has
read `SUMMARY: match=$pass loc_only=$loccnt diff=$failcnt` since M2d's `LOC_ONLY` class (§2d) — the new field broke the
plant's regex, and M2d's own lane runs did not include the Tier B plant battery. Fixed: the expectation is
`^SUMMARY: match=0 loc_only=[0-9]+ diff=` (the plant's intent — the SIGKILL stub reads as DIFF, not the cap's KILL
class — unchanged; the sibling check at `:90`, `^SUMMARY: match=0 `, still matched). Every other consumer of a
`SUMMARY:` line was grepped: `release.py` reads `^SUMMARY: total=(\d+) ` and filters `^SUMMARY:` lines for its
report (shape-agnostic), and the other lanes print their own shapes (`test_exec`, `test_multi_tu`, `test_libxml2`,
`test_bytes`, `test_cn_coverage`); no Python classifier reads the libc_exec line. One commit (M6d).

### 6.6.2 The pre-merge review and its dispositions

The fresh reviewer's report is copied beside this record as
`docs/2026-10-30_merge-base-bump-stage1-premerge-review.md` (verbatim; a "Dispositions" appendix added at the end,
the same table as here). Its verdict at `055602f61` was NOT MERGEABLE as it stood; every finding is dispositioned:

| finding | disposition | where |
|---|---|---|
| P1 — desugar-time `alignof` of a union-containing type crashes the fork oracle where Lean answers; unregistered; the record's unobservability claim false; the failure misnamed | **FIXED by the ruling** [USER 2026-10-30] (option 1): the second line of 736690a65 carried ahead with its one-call Lean mirror; the three shapes and the former crash pair pinned `MATCH`; four register rows; the manifest, tray 67, TODO and VALIDATION moved; the record's claims corrected inline | §6b (registered and raised), §6c (applied) |
| P2 — the `offsetof-union-member` stop cited a non-failing arm; register row 75's reason stale | **FIXED**: re-cited to the live arm at M6b; with M6c's one-map calls the leaf mirrors `:501-504` again and row 75 is `UNREACHABLE-BY-INVARIANT` (resealed) | §6b, §6c.1 |
| P3 — the D13 constant-expression re-measure unrecorded | **FIXED**: re-measured on five engines (97371d8ed rejects it before elaboration on both; the old base crashed) | §6b.1 |
| P3 — the cerberus-sl note's class name | **FIXED**: `LOC_ONLY` / `LOC_ONLY-FIRST` | §6b |
| Residual: no lane run by the reviewer; 5 of 17 modules replayed | the battery of §6.6.1 and M3's 17-module replay (§3.2) stand in | — |
| Residual: the libc-mode Lean path (N4) not exercised | Tier A row 5 (`test_libc_exec`, the `LOC_ONLY` row) and Tier B 13 (the libc quotation round trips) exercise it in the battery | §2d, §4.5 |
| Residual: other desugar-time paths into `alignof_ty` not enumerated | enumerated here (`git grep` over `frontend/model`): `Implementation.alignof_ty`/`sizeof_ty` are reached only through `cabs_to_ail_effect.lem`'s `get_alignof` (the seed `alignof_ty_seeded`) at desugar time, `core_eval.lem`'s `Civsizeof`/`Civalignof` and `driver.lem`'s `alignof_ival` closures (`:194`, `:1737`) at run time, and on the Lean side the fork's own `CerbCall.lean:265` (`allocErrno`, the `--call` entry); the elaboration-time path is `mem.lem`'s `offsetof_ival` (`CerbMem.offsetofIval`); with M6c every one of them is one-map on both engines | §6c.1 |
| Residual: the two-map union arms at run time argued from code | moot since M6c: no call passes two different maps (`CerbMem.offsetofIval` was the one); at run time both maps were already the Core file's table | §6c.1 |

### 6.6.3 The landing recipe for the container's pristine checkout (operator; §0.10 item 1)

`deps/cerberus-upstream` is a clone of `https://github.com/rems-project/cerberus` at `b9aeedcb4` without the
`c3ff8c53f` object; the local mirror has it. What built this worktree's `.tmp/pristine-c3ff8c53f` (M2b), adapted to
the checkout — every command from the container root, no network:

```
# 1. the source at the stage-1 base, from the mirror (the checkout has no network; the mirror was fetched 2026-10-29)
git -C deps/cerberus-upstream fetch /home/dev/projects/cerberus-lean-proj/deps/mirrors/cerberus.git c3ff8c53f05982745f9b3a10b3d05442e214bcb5
git -C deps/cerberus-upstream checkout --detach c3ff8c53f05982745f9b3a10b3d05442e214bcb5
# 2. regenerate the OCaml tree with the fork's lem (e6d8db5, the opam switch env.sh selects): clean first — the
#    checkout holds b9aeedcb4's 86 files, and prelude-src alone would leave stale ones in place
scripts/ce make -C deps/cerberus-upstream clean-prelude-src prelude-src
# 3. verify: 86 files, byte-identical to the tree every gate run of this arc used
ls deps/cerberus-upstream/ocaml_frontend/generated | wc -l        # 86
diff -rq deps/cerberus-upstream/ocaml_frontend/generated worktrees/cerberus-lean-arc/merge-base-bump/.tmp/pristine-c3ff8c53f/ocaml_frontend/generated && echo IDENTICAL
# 4. env.sh needs no edit (CERB_UPSTREAM_TREE already names deps/cerberus-upstream/ocaml_frontend/generated); then the
#    fork-drift gate runs green through plain scripts/ce, and the worktree's .tmp/pristine-c3ff8c53f can go
scripts/ce ./scripts/check_fork_drift.sh          # from the landed checkout
# 5. (optional, the upstream-repro baseline) the pristine oracle in that checkout, as the worktree's scratch build was made:
scripts/ce opam exec --switch=cerberus-lean -- dune build --root deps/cerberus-upstream backend/driver/main.exe cerberus-lib.install cerberus.install
# 6. the primary checkout's standing pristine build for Tier B rows 10/12 (per checkout; the validator refuses the
#    old b9aeedcb4 build, remove it first):
rm -rf cerberus-lean/.validation-foundations/independent-oracle-v2
(cd cerberus-lean && ../scripts/ce ./scripts/capped python3 scripts/ensure_independent_oracle.py --lem-repo ../lem-lean --cerberus-repo "$PWD")
```
(the worktree's scratch build used the same `make prelude-src` on a `git archive` of the mirror at `c3ff8c53f`, with
the same switch; its `generated/` is what every `check_fork_drift` run of this arc compared against.)

### 6.6.4 Scratch at the close-out

Deleted with this commit: `.tmp/m6b/` (the P1 probes, `apply.py`, the logs, the close-out drafts). Kept until landing:
`.tmp/pristine-c3ff8c53f/` (the gate's tree, 371 MB) and `.validation-foundations/independent-oracle-v2` (the standing
pristine build, gitignored). The container's `.tmp/review-bump/` is the orchestrator's.
