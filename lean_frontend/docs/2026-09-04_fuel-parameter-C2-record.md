# Fuel-parameter arc, cerberus half, slice C2 — record (2026-09-04)

Branch `arc/fuel-parameter-C2` (worktree
`worktrees/cerberus-lean-arc/zero-discrepancy`), base mainline
`mdd/cerberus-lean` @ `753644005` (the merged C1). Worker [AGENT] (the C2
worker); every decision below is [AGENT] unless marked; every quoted output
is verbatim from this tree (derived tallies are labelled). Consumer
manifest: `2026-09-04_fuel-parameter-C2-change-manifest.md`. Lem side
unchanged: lem-lean `mdd/lean-backend` = `deps/lem-pinned` = opam `lem` =
the Lake pin = `ecf75b4` (the two-repo invariant holds; nothing moved).
Nothing merged, nothing pushed.

## 0. Summary — READ THIS FIRST

- The consumer's (A)/(B)/(C) requirement (refined-cerberus
  `docs/2026-09-04_review-of-fuel-parameter-design.md` §2) is now MECHANICAL:
  `scripts/check_fuel_forms.sh` (in `test_unit.sh`) classifies EVERY fuel'd
  worker in the compiled environment — generated and hand-written, 81 in all
  — from the kernel: MEASURED (its sufficiency obligation exists and its
  axiom cone ⊆ the standard three), ABSORBING (its `_zero` lemma's RHS is
  its monad's absorbing element at the fuel atom), or AMBIENT, which is RED
  iff reachable from the `drive` cone (kernel constant closure, mutual
  blocks included) and not a reviewed row of `scripts/fuel_forms_pending.txt`.
  On this tree, verbatim: `check_fuel_forms: OK (81 fuel'd workers: 41
  MEASURED (every obligation + proof cone ⊆ the standard three), 13
  ABSORBING, 21 reachable-AMBIENT = the 21 rows of fuel_forms_pending.txt
  exactly, 6 ambient unreachable from the drive cone)`. Five plants red.
- MEASURED: 35 more `declare {lean} fuel_measure val` rows (Lean-only; the
  OCaml generated tree is BYTE-IDENTICAL, §5) with hand-written kernel
  proofs — 38 generated measured wrappers with C1's three — plus THREE
  hand-written `CerbMem` seams (`typeofMval`, `unqualifyAndUnatomic`,
  `memValueToBytes`) measured by hand with the same-shape theorems. The
  measured functions are fuel-FREE for their callers: for them "the fuel
  simply doesn't matter, so it's no longer a parameter" [USER 2026-09-04].
- ABSORBING: the four (B) rows that still returned a VALUE at exhaustion
  (`full_eval_pexpr`, `eval_pexpr_aux2`, `eval_pexpr_aux_broken`: the
  undefined monad's `Result (Error fuelExhaustedLoc fuelExhaustedMsg)`;
  `load_character_array_aux`: the ND kill) now exhaust into their monad's
  absorbing element (Lean-only payload change; the generated `_zero` lemmas
  state it, §3). With the driver family, `nd_bind`/`liftND`/`liftAction`
  and the three `CerbND` runners: 13.
- PENDING (reachable, ambient, registered with reasons): 21 — 9 tag-lookup
  recursions (the `CerbMem` layout oracle ×5, `reconstructValue`, the
  `ctype_aux` `are_compatible` trio: a measure needs a well-formedness
  hypothesis on the tag environment the unconditional obligation cannot
  carry — D-C2-1), 6 point-free `function` tails (BLOCKED on lem-lean TODO
  row 17), `hack`, `to_pure`/`to_pures` (the recursion argument is
  `subst_pattern`'s result, whose ill-typed arms are an opaque `failwithI`
  value — F-C2-3), `many`/`many1`, `showNonNegativeWithBasis_aux`
  (`lemNatDiv n 0` is the opaque `lemDivByZero` — F-C2-7). Decisions §9.
- UNREACHABLE from `drive` (kernel closure): 6 ambient workers — the whole
  DEFACTO memory model's fuel'd rows are dead code for the exec pipeline
  (F-C2-4: `CerbMem` is the wired model), so the consumer's flagged
  `simplify_integer_value_base` payload is (C); `zeros_aux` (front end),
  `list_unfoldr_aux`, and the two `CerbMem` reference forms.
- `[LemFuel]` binders (derived, comment-stripped `grep`): generated model
  397 → 298; hand-written seam definitions (`CerbCall`, `CerbMem`,
  `CerbND`, `Main`) 48 → 45 (`CerbMem.lean` 39 → 36: `typeofMval`,
  `unqualifyAndUnatomic`, `ctypeMemCompatible` dropped theirs); ambient
  generated wrappers 64 → 29 (the parametricity pins regenerated, 29 = 29).
- Battery at the default fuel: §6 (Tier A + Tier B, fresh stamped
  binaries) — ZERO movement expected; see the verbatim lines there.
- Commits: §12. Two of them (2/n, 3/n) were made with `test_unit.sh` RED
  (my shell chain masked the exit); each was repaired in the next commit
  (2b/n, 3b/n) with the slip stated in its message — F-C2-8.

## 1. Rulings in force (verbatim, as relayed by the orchestrator)

[USER 2026-09-04]: "we don't change the lem structure for ocaml … we have to
do more work, but it's just bounded kernel checked work"; "the fuel simply
doesn't matter, so it's no longer a parameter" (measured pure functions);
"Any and all magic values that are hardcoded and can't be quantified over
are definitionally bugs"; each fuel'd call starts from the FULL ambient
(consumer requirement); no in-repo mirror models — ship theorems, not
alternative definitions.

## 2. The 67-row disposition (the lem fuel-measure record §6.2 numbering)

Form: M = MEASURED (generated obligation `<f>_measure_sufficient` proved in
`<Module>_lemMeasureProofs.lean`, kernel-only tactics, no option bumps, no
`sorry`; every cone ⊆ [propext, Classical.choice, Quot.sound] — probed by
the gate for all 41), A = ABSORBING, P = PENDING (reachable ambient,
registered), U = ambient, UNREACHABLE from the drive cone. "reach" is the
gate's kernel-closure verdict (`yes`/`no`), `[LemFuel]` marks a measured
wrapper that keeps the binder because its body reaches an ambient callee.

| # | function (module) | form | measure / payload | theorem (namespace) | reach |
|---|---|---|---|---|---|
| 1 | `showNonNegativeWithBasis_aux` (Formatted) | P | precondition `b ≥ 2`; `n + 1` is provable for `b ≠ 0` (b = 1 exhausts on both sides: constant payload) but at `b = 0` the next argument is `lemNatDiv n 0 = lemDivByZero = failwithI …`, opaque — no bound (F-C2-7) | — | yes |
| 2 | `load_character_array_aux` (Formatted) | A | payload → `ND (fun st => (NDkilled (Error0 fuelExhaustedLoc fuelExhaustedMsg), st))` (was `fuelExhausted (nd_return [])`) | `load_character_array_aux_lemFuel_zero` | yes |
| 3 | `many` (Monadic_parsing) | P | parser: the depth is the INPUT's length, inside the `ParserM` lambda, not a parameter; payload `ParserM (fun _ => [])` = the parser zero, indistinguishable from a normal failure | — | yes |
| 4 | `many1` (Monadic_parsing) | P | mutual sibling of 3 | — | yes |
| 5 | `add_to_sb` (Core_run_aux) | M | `lemSize g` | `Core_run_aux_lemMeasureProofs.add_to_sb_measure_sufficient` | no |
| 6 | `add_to_asw` (Core_run_aux) | M | `lemSize g` | `…add_to_asw_measure_sufficient` | yes |
| 7 | `convert_pexpr` (Core_run_aux) | M | `lemSize g` | `…convert_pexpr_measure_sufficient` | no (front) |
| 8 | `convert_expr` (Core_run_aux) | M | `lemSize g`; the wrapper DROPPED `[LemFuel]` (its only fuel'd callee, `convert_pexpr`, is measured) | `…convert_expr_measure_sufficient` | no (front) |
| 9 | `ctypeEqual` (Ctype) | M (C1) | `lemSize c` | `Ctype_lemMeasureProofs.ctypeEqual_measure_sufficient` | yes |
| 10 | `zeros_aux` (Core_aux) | U | tag lookup; front end (`Translation`) | — | no |
| 11 | `in_pattern` (Core_aux) | M | `lemSize g` | `Core_aux_lemMeasureProofs.in_pattern_measure_sufficient` | yes |
| 12 | `subst_wait` (Core_aux) | M | `lemSize g` | `…subst_wait_measure_sufficient` | yes |
| 13 | `find_labeled_continuation2_aux` (Core_aux) | M | `lemSize g` | `…find_labeled_continuation2_aux_measure_sufficient` | no |
| 14 | `loadedValueFromMemValue` (Core_aux) | M | `CerbMem.memValueSize mem_val` (NEW hand-written structural size of the seam's `MemValue`, CerbMem.lean) | `…loadedValueFromMemValue_measure_sufficient` | yes |
| 15 | `memValueFromValue` (Core_aux) | M `[LemFuel]` | `lemSize ty1` (descends `unatomic ty1`: `CerbMeasureLemmas.unatomic_size_le`); keeps the binder for the ambient `are_compatible0` | `…memValueFromValue_measure_sufficient` | yes |
| 16 | `subst_sym_pexpr` (Core_aux) | M | `lemSize g` | `…subst_sym_pexpr_measure_sufficient` | yes |
| 17 | `subst_sym_expr` (Core_aux) | M | `lemSize g` | `…subst_sym_expr_measure_sufficient` | yes |
| 18 | `subst_pattern_val` (Core_aux) | M | `lemSize g` (the pattern) | `…subst_pattern_val_measure_sufficient` | yes |
| 19 | `unsafe_subst_sym_pexpr` (Core_aux) | M | `lemSize g0` | `…unsafe_subst_sym_pexpr_measure_sufficient` | yes |
| 20 | `unsafe_subst_sym_expr` (Core_aux) | M | `lemSize g` | `…unsafe_subst_sym_expr_measure_sufficient` | yes |
| 21 | `unsafe_subst_pattern` (Core_aux) | M | `lemSize g` | `…unsafe_subst_pattern_measure_sufficient` | no |
| 22 | `subst_pattern` (Core_aux) | M | `lemSize g` | `…subst_pattern_measure_sufficient` | yes |
| 23 | `match_pattern` (Core_aux) | M | `lemSize g` | `…match_pattern_measure_sufficient` | yes |
| 24 | `to_pure` (Core_aux) | P | opaque-arg: `to_pure_aux` recurses on `e` from `subst_pattern pat pe1 e2 = some e`; `subst_pattern_val`'s ill-typed fallthrough is `failwithI …` (opaque, LemLib) so `lemSize e ≤ lemSize e2` is not provable (F-C2-3); its payload `fuelExhausted none` reaches `Driver.finalize` (failwith, loud) and `Core_run.core_thread_step2` | — | yes |
| 25 | `to_pures` (Core_aux) | P | mutual sibling of 24 | — | yes |
| 26 | `collect_saves_aux` (Core_aux) | M | `lemSize g` | `…collect_saves_aux_measure_sufficient` | yes (via `initial_driver_state`) |
| 27 | `m_collect_saves_aux` (Core_aux) | M | `lemSize g` | `…m_collect_saves_aux_measure_sufficient` | no |
| 28 | `find_labeled_continuation` (Core_aux) | M | `lemSize g` | `…find_labeled_continuation_measure_sufficient` | no |
| 29 | `update_env_aux` (Core_aux) | M | `lemSize g` | `…update_env_aux_measure_sufficient` | yes |
| 30 | `are_compatible_aux` (Ctype_aux) | P | tag lookup (`tagDefs1`/`tagDefs2`); reached via `memValueFromValue` | — | yes |
| 31 | `are_compatible_params_aux` (Ctype_aux; Lean `are_compatible_params_aux0`) | P | sibling (mutual block; also point-free) | — | yes |
| 32 | `are_compatible_params` (Ctype_aux; Lean `are_compatible_params0`) | P | sibling | — | yes |
| 33 | `mkListN_aux` (Utils) | M | `Int.toNat (n - i) + 1` | `Utils_lemMeasureProofs.mkListN_aux_measure_sufficient` | no |
| 34 | `mkListFromTo_aux` (Utils) | M | `Int.toNat (max2 + 1 - i) + 1` — the table's `Int.toNat (max2 - i) + 1` is ONE SHORT (inclusive guard `≤`): the obligation refused it (F-C2-2) | `…mkListFromTo_aux_measure_sufficient` | no |
| 35 | `replicate_list_` (Utils) | M | `n + 1` | `…replicate_list__measure_sufficient` | no |
| 36 | `list_unfoldr_aux` (Utils) | U | client-function unfold | — | no |
| 37 | `one_step_unseq_aux` (Core_reduction) | P | point-free tail → lem TODO 17 | — | yes |
| 38 | `has_ccall` (Core_reduction) | M | `lemSize g` | `Core_reduction_lemMeasureProofs.has_ccall_measure_sufficient` | yes |
| 39 | `get_ctx` (Core_reduction) | P | point-free (via sibling) → lem TODO 17 | — | yes |
| 40 | `get_ctx_unseq_aux` (Core_reduction) | P | point-free → lem TODO 17 | — | yes |
| 41 | `full_eval_pexpr` (Core_reduction) | A | payload → `fun st => Result (Error fuelExhaustedLoc fuelExhaustedMsg, st)` (was `fuelExhausted (fun st => Result (Undef …, st))`): `stExceptUndef_bind` propagates `Result (Error …)`, `Driver` maps it to `kill (Error0 loc str)` | `full_eval_pexpr_lemFuel_zero` | yes |
| 42 | `print_eval_conv_aux` (Driver) | A | ND kill (as at C1) | `print_eval_conv_aux_lemFuel_zero` | yes |
| 43 | `drive_nonmemory_steps_aux2` (Driver) | A | ND kill | `drive_nonmemory_steps_aux2_lemFuel_zero` | yes |
| 44 | `driver2` (Driver) | A | ND kill | `driver2_lemFuel_zero` | yes |
| 45 | `hack` (Driver) | P | pure step-until-value loop returning a Core `value` (`Driver.finalize`); no absorbing element in the codomain | — | yes |
| 46 | `pull_constrained` (Core_eval) | M | `lemSize g` (the counter `n` only grows) | `Core_eval_lemMeasureProofs.pull_constrained_measure_sufficient` | yes |
| 47 | `step_eval_pexpr` (Core_eval) | M `[LemFuel]` | `lemSize pexpr1` (every `self` argument is a component; the Core call result goes through `exception_undef_return`, `pull_constrained` is measured) | `…step_eval_pexpr_measure_sufficient` | yes |
| 48 | `eval_pexpr_aux2` (Core_eval) | A | payload → `Result (Error fuelExhaustedLoc fuelExhaustedMsg)` (was `fuelExhausted (Result (Undef …))`) | `eval_pexpr_aux2_lemFuel_zero` | yes |
| 49 | `eval_pexpr_aux_broken` (Core_eval) | A | as 48 | `eval_pexpr_aux_broken_lemFuel_zero` | no |
| 50 | `tmp_compl_aux` (Defacto_memory_aux) | M | `nbits + 1` | `Defacto_memory_aux_lemMeasureProofs.tmp_compl_aux_measure_sufficient` | no |
| 51 | `tmp_AND_aux` | M | `nbits + 1` | `…tmp_AND_aux_measure_sufficient` | no |
| 52 | `tmp_OR_aux` | M | `nbits + 1` | `…tmp_OR_aux_measure_sufficient` | no |
| 53 | `tmp_XOR_aux` | M | `nbits + 1` | `…tmp_XOR_aux_measure_sufficient` | no |
| 54 | `fake_mem_value_eq` (Defacto_memory_aux) | M (C1) | `lemSize mval1` | `…fake_mem_value_eq_measure_sufficient` | no |
| 55 | `simplify_integer_value_base` (Defacto_memory_aux) | U | the consumer's flagged "returns its input unsimplified" payload (`Sum.inr ival_`): a (B)-VIOLATION were it reachable (its caller `eval_integer_value_base` would continue with `none` = "symbolic"), but the DEFACTO model is not the memory model wired into `drive` (F-C2-4) — classification (C) | — | no |
| 56 | `nd_bind` (Nondeterminism) | A | ND kill | `nd_bind_lemFuel_zero` | yes |
| 57 | `liftND` (Nondeterminism) | A | ND kill | `liftND_lemFuel_zero` | yes |
| 58 | `liftAction` (Nondeterminism) | A | `fun _ => NDkilled (Error0 …)` (codomain-ascribed lemma) | `liftAction_lemFuel_zero` | yes (mutual with 57) |
| 59 | `has_concurRead` (Defacto_memory) | M | `lemSize ival_` | `Defacto_memory_lemMeasureProofs.has_concurRead_measure_sufficient` | no |
| 60 | `find_array_index` (Defacto_memory) | M | `size - i + 1` | `…find_array_index_measure_sufficient` | no |
| 61 | `easy_update_mem_value_aux` (Defacto_memory) | M `[LemFuel]` | `List.length sh + 1`; keeps the binder for the ambient `mkUnspec`/`simplify_integer_value_base` | `…easy_update_mem_value_aux_measure_sufficient` | no |
| 62 | `memcmp_load_aux` (Defacto_memory) | M `[LemFuel]` | `Int.toNat (max_offset - offset) + 1`; keeps the binder for the ambient `impl_load` | `…memcmp_load_aux_measure_sufficient` | no |
| 63 | `mkUnspec` (Defacto_memory) | U | tag lookup; defacto model | — | no |
| 64 | `are_compatible` (AilTypesAux) | P | point-free (via sibling) → lem TODO 17. REACHABLE from `drive` (`step_eval_pexpr`'s `PEare_compatible` arm), contrary to the lem table's "off the execution path" (F-C2-5) | — | yes (also front) |
| 65 | `are_compatible_params_aux` (AilTypesAux) | P | point-free → lem TODO 17 | — | yes |
| 66 | `are_compatible_params` (AilTypesAux) | P | sibling | — | yes |
| 67 | `eq_core_base_type` (Core) | M (C1) | `lemSize bTy1` | `Core_lemMeasureProofs.eq_core_base_type_measure_sufficient` | no |

Tally (derived from the form column): M 38 (35 this slice + C1's 3; 20
drive-reachable), A 10, P 15, U 4 — 38 + 10 + 15 + 4 = 67. The brief's "38 →
the remaining 35" undercounted by two (F-C2-1): the lem table's 38 MEASURED
rows include `fake_mem_value_eq` but not `ctypeEqual`/`eq_core_base_type`
(SAME-MODULE rows), so 37 measured candidates remained; 35 are proved,
`to_pure`/`to_pures` are P.

### 2.1 The hand-written seams (14 workers the gate also classifies)

| worker (CerbMem / CerbND) | form | measure / reason | theorem | reach |
|---|---|---|---|---|
| `CerbMem.typeofMval_lemFuel` | M | `memValueSize mval` (MVarray head); wrapper fuel-FREE (binder dropped) | `CerbMem.typeofMval_measure_sufficient` (CerbMem_lemMeasureProofs) | yes |
| `CerbMem.unqualifyAndUnatomic_lemFuel` | M | `ctype.lemSize cty` (structural; `Function` params via `Ctype_lemMeasureProofs.ctype_param_lt`); wrapper fuel-FREE; `ctypeMemCompatible` fuel-FREE; both no longer `private` | `CerbMem.unqualifyAndUnatomic_measure_sufficient` | yes |
| `CerbMem.memValueToBytes_lemFuel` | M `[LemFuel]` | `memValueSize val_` (MVarray/MVstruct/MVunion components); keeps the binder for the ambient layout oracle; `memValueToBytes_eq_append` restated at the measure | `CerbMem.memValueToBytes_measure_sufficient` | yes |
| `CerbMem.sizeofCtype_lemFuel`, `alignofCtype_lemFuel`, `offsetsof_lemFuel`, `offsetsofMembers_lemFuel`, `memberAlign_lemFuel` | P | tag-lookup layout oracle (impl_mem.ml sizeof/alignof/offsetsof): the `Struct` arm recurses through member types read from `tagDefs` — no data measure; the well-formedness (acyclicity) hypothesis the true bound needs cannot be stated in an unconditional wrapper (D-C2-1) | — | yes |
| `CerbMem.reconstructValue_lemFuel` | P | tag lookup (Struct/Union member types from `offsetsof`/`UnionDef`) | — | yes |
| `CerbMem.memValueToBytes_append_lemFuel`, `reconstructValue_indexed_lemFuel` | U | the C1/C3 reference forms (equality theorems only; never executed) | — | no |
| `CerbND.runNDFuel`, `runND1Fuel`, `runND1TraceFuel` | A | `[(Killed st0 fuelExhaustedKill, [], st0)]` (the runner leaves) | `CerbND.run*Fuel_zero` | yes |

Gate totals: 41 M (38 + 3), 13 A (10 + 3), 21 P (15 + 6), 6 U (4 + 2) = 81.

## 3. The absorbing payloads (Lean-only sentinel declares; the generated `_zero` statements verbatim)

| function | monad | absorbing element | `_zero` RHS as generated |
|---|---|---|---|
| `full_eval_pexpr` | `b → exceptM (t0 value × b) core_run_cause` (stExceptUndef) | `Result (Error loc str, st)` — `stExceptUndef_bind` returns `stExpect_return (error0 loc1 str) st'` on it, never running the continuation; `Driver` (`Driver.lean:286`) maps `Error loc1 str` to `kill (Error0 loc1 str)` | `(full_eval_pexpr_lemFuel 0 _lemReader_tagDefs th_st core_extern1 mem_st file1 pe : b → exceptM ((t0 (value) ×b)) (core_run_cause)) = (fun st => Result (Error CerbFuel.fuelExhaustedLoc CerbFuel.fuelExhaustedMsg, st))` |
| `eval_pexpr_aux2` | `exceptM (t0 (pexpr ⊕ value)) core_run_cause` | `Result (Error …)` — `exception_undef_bind` propagates it | `eval_pexpr_aux2_lemFuel 0 … pe = (Result (Error CerbFuel.fuelExhaustedLoc CerbFuel.fuelExhaustedMsg))` |
| `eval_pexpr_aux_broken` | as above | as above | `eval_pexpr_aux_broken_lemFuel 0 … pe = (Result (Error CerbFuel.fuelExhaustedLoc CerbFuel.fuelExhaustedMsg))` |
| `load_character_array_aux` | `memM` = `ndM … CerbMem.MemState` | `NDkilled (Error0 fuelExhaustedLoc fuelExhaustedMsg)` (as the driver family) | `load_character_array_aux_lemFuel 0 … acc = (ND (fun st => (NDkilled (Error0 CerbFuel.fuelExhaustedLoc CerbFuel.fuelExhaustedMsg), st)))` |

The remaining six (B) rows already carried the ND kill at C1 (§2 rows
42–44, 56–58). The gate's ABSORBING test (FuelFormsTool): the RHS mentions
the fuel atom (`CerbFuel.fuelExhaustedLoc` or `CerbND.fuelExhaustedKill`)
under an absorbing head (`nd_action.NDkilled`, `nd_status.Killed`,
`t0.Error`) and none of `fuelExhausted`/`fuelExhaustedWith`/`failwithI`/
`panic`. Note the panic wrapper is GONE from these four payloads: exhaustion
is a pure kill value the run reports (the harness FUEL classifier reads the
message `lem: fuel exhausted` in the kill), not a panic.

Where a (B) row is NOT in a monad with an absorbing element it is P, not
re-payloaded: `hack` (pure `value`), `to_pure`/`to_pures` (`Option`: `none`
is the ordinary "not pure" answer, not distinguishable), `many`/`many1`
(the parser zero is the ordinary failure), `showNonNegativeWithBasis_aux`
(`List Char`). Decisions §9.

## 4. The proofs — shape, toolbox, and what resisted

- Template (all 38 proofs, `*_lemMeasureProofs.lean`): the C1 stability
  lemma by strong induction on the size bound (`∀ f g ≥ μ x, W f x = W g
  x`); at `Nat.succ f`/`Nat.succ g` the body is unfolded and every
  recursive call on a strict sub-term is rewritten by `key : ∀ …, μ y < μ x
  → W f … y = W g … y` as a `simp` rewrite whose side condition the
  `size_lt` discharger (unfold the derived sizes at `*`, `omega`) proves;
  the list traversals (`List.map`/`any`/`foldl`, `lemListFoldr`) by
  membership-relative congruence with the derived helpers' member bounds
  (`expr_mem_lt_aux1/2`, `pexpr_mem_lt_aux1..4`, `pattern_mem_lt_aux1`,
  `ival_mem_lt_aux2`, `memValue_mem_lt_list/members`); the obligation is
  the instance `g := μ x`. Shared toolbox: `lean_frontend/CerbMeasureLemmas.lean`
  (congruences, member bounds, positivity, `unatomic_size_le`, `size_lt`,
  and the depth-agnostic `to_congr`: try the congruence lemmas, else open
  one level — a primitive projection by `congrArg Prod.snd/fst`, otherwise
  `congr 1` — bounded at 12 levels).
- The multi-discriminant matches of the pattern family
  (`subst_pattern_val`, `unsafe_subst_pattern`, `subst_pattern`,
  `match_pattern`, `update_env_aux`, `memValueFromValue`) are opened by
  `split` after unfolding: it produces exactly the arms the decision tree
  has (one residual goal per function — the `Ctuple` fold), where a
  brute-force `cases` product had ~7000 leaves (measured on a probe:
  `unsafe_subst_pattern` by `split` = 1 residual goal, 3 s).
- Findings on the way (tactic-level, recorded for the next proofs writer):
  `simp` reduces `match` on `Unit`- and pair-typed scrutinees by structure
  eta, so the debug `match print_debug_pure … with | () =>` wrappers vanish
  and fixed-depth `congr N` over-descends (hence `to_congr`); `congr 1`
  SUCCEEDS WITHOUT PROGRESS on a primitive projection `x.2` (so the
  `congrArg` openers precede it); `exact lfoldl_congr _ _ _ (fun …)`
  elaborates the lambda before unification (use `apply … ; intro`).
- `to_pure`/`to_pures` (F-C2-3): NOT provable with `lemSize g`; the
  declares were withdrawn (the failed attempt is not in the tree). No
  `set_option` bump was needed anywhere; none exists in the proof modules.
- Row 34's measure corrected (F-C2-2) — the obligation caught it:
  verbatim `error: generated/Utils_lemMeasureProofs.lean:73:51: omega could
  not prove the goal:` at `Int.toNat (max2 - i) + 1`; with the exact depth
  `Int.toNat (max2 + 1 - i) + 1` the proof goes through.

## 5. OCaml byte identity and the two trees

Pre-slice snapshot of `ocaml_frontend/generated` (86 files, lem-sync `gen
295e4f82…`) taken before the first declare. After EVERY `.lem` edit of the
slice (35 + 4 payload declares, comments, the withdrawn `to_pure` pair),
`make prelude-src` then `diff -rq` against the snapshot, verbatim:

```
check_lem_sync: recorded ocaml_frontend/lem_sync.sha256 (src 928a08cd72f10e899385191821266f915008a499c4033de8b44893b9fcac2e8a, gen 295e4f8291c9ffd57a4061dd38e8ec273f18d6c1cfe3a0465291f1a4bcff8100)
OCAML GENERATED TREE BYTE-IDENTICAL (86 files) vs the pre-C2 snapshot
```

(`diff -rq` printed nothing.) The `src` stamp moves with the `.lem` text by
construction (C1 record §2.2). The Lean tree: `check_lem_sync: recorded
lean_frontend/lem_sync.sha256 (src 928a08cd…, gen 76d138a3a8e6f5866edaebfc9725d265812de4fdaab908a650fbdb567f279f35)`;
`lake build` of the whole package: `Build completed successfully (373
jobs).`

## 6. Battery (fresh stamped binaries; default fuel; serial)

Stamps at the battery: `check_driver_fresh: oracle OK (bin b1cc0bd9d4feae575bbc652a9d3d9e90adb4b22e96dfa4b02374f3c082bb20c7, src 754ef1e991debf6bffb4d03bdc38928f686295441ce149d0cddfe2f06f11e768)` /
`check_driver_fresh: lean OK (bin 797d1383ba69f288f1b936c31060667e56f27c7347136e2c3ea5127b13e66993, src 0760dd53cd77d202816c85500b814ee659708b9873f9995a9076229fe905a474)`
(oracle rebuilt `DUNE_CACHE=disabled` after the last `.lem` edit; the Lean
binary from the last `lake build` of the tree). Tier A row 1
(`test_unit.sh`) ran on this head before the last two commits' verification
(§12): `Total: 6 passed, 0 failed`, every gate green, verbatim in §7 for the
fuel-forms gate and `gen_fuel_parametricity: OK (29 …)`, `check_lakefile_roots:
OK (202 roots …)`, `check_exec_totality: CLEAN (22 generated modules +
hand-written CerbND, 0 allowlisted)`, `check_theorem_axioms: OK …`,
`check_sorry_token: OK (276 files …; 0 sorry tokens)`. Rows 2–11 and Tier B
ran serially under `SKIP_BUILD=1` on the stamps above (`.tmp/c2/battery.sh`,
23:24–00:12 UTC), every lane `rc=0`; ZERO baseline movement anywhere; no
instrument commit. The lane summary lines, verbatim:

### 6.1 Tier A rows 2–11

| Row | Verbatim |
|---|---|
| A2_minimal (rc 0) | `SUMMARY: total=106 match=85 ub_match=18 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=3 cerb_floor=0 cerb_inconsistent=0` / `Baseline check: 0 regression(s), 0 improvement(s)` / `BASELINE OK` |
| A3_coverage (rc 0) | `SUMMARY: total=212 match=183 ub_match=16 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=13 cerb_floor=0 cerb_inconsistent=0` / `Baseline check: 0 regression(s), 0 improvement(s)` / `BASELINE OK` |
| A4_debug (rc 0) | `SUMMARY: total=90 match=66 ub_match=20 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=4 cerb_floor=0 cerb_inconsistent=0` / `Baseline check: 0 regression(s), 0 improvement(s)` / `BASELINE OK` |
| A4b_float (rc 0) | `SUMMARY: total=69 match=69 ub_match=0 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=0 cerb_floor=0 cerb_inconsistent=0` / `Baseline check: 0 regression(s), 0 improvement(s)` / `BASELINE OK` |
| A4c_bytes (rc 0) | `SUMMARY: exec_match=9 neg_pinned=5 fail=0` |
| A5_libc_exec (rc 0) | `SUMMARY: match=11 diff=0` / `ALL MATCH RECORDED BASELINE` |
| A6_multi_tu (rc 0) | `SUMMARY: total=2 match=2 fail=0` / `ALL PASSED` |
| A7_parse (rc 0) | `Lean front end: 0 rejected (exit 1 + a printed Error/Undefined verdict; not a parse failure), 0 internal-error-expected (failwithI panic on an *.error.c input, oracle-mirrored)` / `Success rate:   100% (of cerberus successes)` / `ALL PASSED` |
| A8_core (rc 0) | `Success rate:   100% (of cerberus successes)` / `ALL PASSED` |
| A9_elab (rc 0) | `OCAML_FAIL: 0` / `LEAN_FAIL:  0` / `SUMMARY: total=106 same=103 diff=3 ocaml_fail=0 lean_fail=0` |
| A10_uri (rc 0) | `[ocaml-nolibc] exit=1: Error {msg: "ill-formed program: `calling an unknown procedure: Symbol(1451, SD_Id("memset"))'"}` / `[lean-nolibc] exit=1 wall=0:01.07 maxRSS=236484kB: Error {msg: "ill-formed program: `calling an unknown procedure: Symbol(968, SD_Id("memset"))'"}` / `[lean+libc] EXACT MATCH with ORACLE_LIBC (16/16 URI corpus)` / `GATE PASS: all lane expectations pinned-green + baseline unchanged (16/16)` |
| A11_cn (rc 0) | `LEAN_FAIL:     0  LEAN_CRASH: 0  FUEL: 0  LEAN_ERROR: 0  LEAN_TIMEOUT: 0` / `ORACLE_FAIL:   0  ORACLE_TIMEOUT: 0  ORACLE_INCONSISTENT: 0` / `SUMMARY: total=213 match=207 ub_match=6 ub_diff=0 reject_match=0 diff=0 mismatch=0 reject_diff=0 lean_fail=0 lean_crash=0 fuel=0 lean_error=0 lean_timeout=0 oracle_fail=0 oracle_timeout=0 oracle_inconsistent=0` / `BASELINE OK (213 entries, exact match)` |

### 6.2 Tier B rows 1–8

| Row | Verbatim |
|---|---|
| B1_libxml2 (rc 0) | `SUMMARY: total=4 match=4 fail=0 (points: 1354, 22 observations each)` / `ALL PASSED` |
| B2_parse_ci (rc 0) | `Lean front end: 117 rejected (exit 1 + a printed Error/Undefined verdict; not a parse failure), 2 internal-error-expected (failwithI panic on an *.error.c input, oracle-mirrored)` / `Success rate:   51% (of cerberus successes)` / `ALL PASSED` |
| B3_core_ci (rc 0) | `Success rate:   100% (of cerberus successes)` / `ALL PASSED` |
| B4_verify (rc 0) | `test_verify: 127 passed, 0 failed (25 fixtures, 28 call points, 14 corpus fixtures, 21 corpus points)` |
| B5_immaculate (rc 0) | `OK: lane matches the committed baseline (MATCH except the ISO-fix register pins R1 g5-decode-question/zd-e2-ptr-string-literals ORACLE_CRASH, R2 g5-escape-roundtrip DIFF, R3 s4b-memcmp-hugesize ORACLE_CRASH — VALIDATION.md 'ISO-fix register' — and the in-Lean probes g6 TRIPWIRE / illtyped-store KILL).` |
| B6a_speclab_self (rc 0) | `test_speclab: PASS (both pipelines agree on Specified(0))` |
| B6b_speclab_plant (rc 0) | `test_speclab: PASS (both pipelines agree on Specified(2))` |
| B6c_divmod (rc 0) | `PASS  exec [b] (-5,3): Specified(0)` / `PASS  exec [d] (-6,3): Specified(0)` / `PASS  exec [c] (-128,-1): Specified(0)` / `PASS  exec [plant]: Specified(1) — the wrong-operator plant is RED in-logic` / `CoreGateTest: ALL PASSED` / `test_speclab_divmod: PASS (--gate)` |
| B6d_bytearr (rc 0) | `PASS  exec [memcpy plant]: Specified(3) — the off-by-one plant is RED in-logic at dst byte 0` / `PASS  exec [getarr A]: Specified(0)` / `PASS  exec [getarr B]: Specified(0)` / `PASS  exec [getarr plant]: Specified(1) — the wrong-index plant is RED in-logic` / `ByteArrGateTest: ALL PASSED` / `test_speclab_bytearr: PASS (--gate)` |
| B6e_list (rc 0) | `PASS  exec [append elem-plant]: Specified(3) — the wrong-element plant is RED in-logic at element 0` / `PASS  leak [append elem-plant]: final allocations = 1` / `PASS  exec [build-only]: Specified(0) — builder-walker round trip through the heap` / `PASS  leak [build-only]: final allocations = 1` / `ListGateTest: ALL PASSED` / `test_speclab_list: PASS (--gate)` |
| B6f_tree (rc 0) | `PASS  exec [rotate drop-plant]: Specified(255) — structural break in the length arm; +1 = the orphaned middle subtree` / `PASS  leak [rotate drop-plant]: final allocations = 2` / `PASS  exec [build-only]: Specified(0) — builder-walker round trip through the heap` / `PASS  leak [build-only]: final allocations = 1` / `TreeGateTest: ALL PASSED` / `test_speclab_tree: PASS (--gate)` |
| B6g_seed (rc 0) | `PASS  exec [swap b]: Specified(0)` / `PASS  exec [swap d]: Specified(0)` / `PASS  exec [swap c]: Specified(0)` / `PASS  exec [swap plant]: Specified(9) — the lost-update plant is RED in-logic at post-state cell 1, byte 0` / `SeedGateTest: ALL PASSED` / `test_speclab_seed: PASS (--gate)` |
| B7_gcc (rc 0) | `[267/1963] SKIP_LEAN_FAIL  tests/immaculate/nolibc/g1-lt-null.c: msg: "Memory WIP: lt_ptrval ==> one null pointer"` / `[1962/1963] SKIP_LEAN_FAIL  csmith/smx_csmith_6.c: msg: "typechecking failed at /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-arc/zero-discrepancy/.tmp/scripts/gcc-oracle.NIeDeKCvjQ/csmith-stage/smx_csmith_6.c:191:16-21 (cursor: 191:14)"` / `SKIP_LEAN_FAIL: 9` / `SUMMARY: total=1963 compared=1885 agree=1873 agree_nd=0 triaged=12 disagree=0 o2_agree=190 skip_gcc_compile=1 skip_gcc_stdout=1 skip_lean_crash=9 skip_lean_fail=9 skip_lean_timeout=11 skip_ub=47 triaged_addr=11 triaged_ub=1` / `Baseline check: 0 regression(s), 0 improvement(s)` / `gcc second-oracle lane OK` |
| B8a_hang (rc 0) | `test_hang_plant: all plants read as expected (sleep→HANG, busy→TIMEOUT, both lanes; missing record→harness error)` |
| B8b_kill (rc 0) | `test_kill_plant: all plants read as expected (cap breach -> OOM-KILLED witness; ci_sweep LEAN_KILL, libc_exec KILL, immaculate KILL, uri/libxml2 FAIL-killed; SIGKILL stub NOT the cap class; native exit(137) still compared; no MATCH anywhere)` |
| B8c_fuel (rc 0) | `test_fuel_plant: ALL PLANTS OK (FUEL classification live in exec/gcc/ci_sweep/cn_coverage/measure; negatives not FUEL; the real driver at --fuel 1 reads FUEL and at the default MATCH; --fuel 0/non-numeral/out-of-position/missing refused)` |

(B2's `Success rate: 51%` counts the lane's classified REJECTED rows out, as
at C1; its gating line is `ALL PASSED` with 0 failed/timeout. B7 is
row-for-row the C1 result: `compared=1885 agree=1873 … disagree=0`.)

## 7. The gate — design and plants

`scripts/check_fuel_forms.sh` (Tier A row 1 via `test_unit.sh`, after the
lakefile-roots gate) drives `lean_frontend/test/Unit/FuelFormsTool.lean`
(`lean_exe fuel-forms-tool`, `supportInterpreter`): at RUNTIME, under `lake
env`, it imports the exec entries (`Driver`, `CerbCall`, `CerbND`, `Main`),
every generated `*_auxiliary` module and every `*_lemMeasureProofs` module
(the obligation carriers) and classifies every definition named `*_lemFuel`
(or a `CerbND.run*Fuel` runner) from the KERNEL environment — no source
regex: MEASURED iff the constant `<f>_measure_sufficient` exists (its axiom
cone and the delegated proof's cone via `collectAxioms`); ABSORBING iff the
`<worker>_zero` lemma's conclusion RHS satisfies §3's test; reachability =
the kernel constant closure (`ConstantInfo.getUsedConstantsAsSet`) of
`drive`, `initial_driver_state`, the three runners and `CerbCall.driveCall`,
closed under mutual blocks (`Lean.Elab.Structural/WF.eqnInfoExt` — a mutual
block compiles to ONE recursor term in which the siblings' names do not
occur; without the closure `liftAction`/`to_pures`/`get_ctx_unseq_aux` read
unreachable, F-C2-6); a second, informational column marks the front-end
pipeline closure (`desugar`…`convert_file`). The tool fails closed on a
missing entry or a vacuous table. The script's POLICY: RED on any
reachable AMBIENT worker not in `scripts/fuel_forms_pending.txt`, on any
register row that is no longer a reachable ambient worker (stale pin), on a
measured cone outside the standard three, on a truncated table; vacuity
guards (≥ 60 workers, ≥ 30 measured, ≥ 10 absorbing). Limitation (stated
in the script): the kernel closure stops at `partial def`/`opaque`/
`implemented_by` boundaries — none exist on the drive cone's generated
modules (`check_exec_totality`), and the seam externs (`CerbFS`,
`CerbDebug`) call no fuel'd function; the front-end column is unreliable for
that reason and is informational only.

`--selftest` plants on a scratch copy of the table, verbatim:

```
check_fuel_forms: SELFTEST — plants on a scratch copy of the classification table (loud plant banner; nothing in the tree is touched)
  PLANT OK   [P1 measured->ambient reachable (step_eval_pexpr)] -> check_fuel_forms: FAIL — fuel'd worker(s) REACHABLE from drive with an opaque (fail-open) exhaustion, not in …/scripts/fuel_forms_pending.txt:
  PLANT OK   [P2 stale pending pin (hack removed from the table)] -> check_fuel_forms: FAIL — pending register row(s) no longer a reachable ambient worker (stale pin; edit the register):
  PLANT OK   [P3 measured obligation with sorryAx in its cone] -> check_fuel_forms: FAIL — measured obligation(s) with an axiom cone outside [propext, Classical.choice, Quot.sound] (or no proof constant):
  PLANT OK   [P4 truncated table] -> check_fuel_forms: FAIL — no FUEL_FORMS_SUMMARY line (the tool did not complete; fail-closed)
  PLANT OK   [P5 phantom register row] -> check_fuel_forms: FAIL — pending register row(s) no longer a reachable ambient worker (stale pin; edit the register):
  UNPLANTED:
    check_fuel_forms: OK (81 fuel'd workers: 41 MEASURED (every obligation + proof cone ⊆ the standard three), 13 ABSORBING, 21 reachable-AMBIENT = the 21 rows of fuel_forms_pending.txt exactly, 6 ambient unreachable from the drive cone)
check_fuel_forms: SELFTEST OK (5 plants red with the declared label; unplanted table green)
```

The MEASURE plant (the brief's): `has_ccall`'s declare edited to the
disguised constant `` `lemSize g - lemSize g + 1` `` (the numeral gate
refuses a bare numeral; the obligation is the backstop for this shape —
lem fuel-measure record N1), regenerated, verbatim:

```
365:def has_ccall  {a : Type} {b : Type} {c : Type} (g : generic_expr c b a) : Bool := has_ccall_lemFuel (generic_expr.lemSize g - generic_expr.lemSize g + 1) g
✖ [102/103] Building Core_reduction_lemMeasureProofs (1.3s)
error: generated/Core_reduction_lemMeasureProofs.lean:56:2: Type mismatch
  has_ccall_stable_aux g.lemSize g lemFuel g.lemSize (Nat.le_refl g.lemSize) lemMeasureLe (Nat.le_refl g.lemSize)
has type
  has_ccall_lemFuel lemFuel g = has_ccall_lemFuel g.lemSize g
but is expected to have type
```

— reverted; regenerated (`src 928a08cd…, gen 76d138a3…` again); `Build
completed successfully (103 jobs).`

Other gates touched: `check_theorem_axioms.sh`'s FUEL leg keeps its C1 pin
(34 names, all still present) with a header note that the C2 obligations
are probed by the fuel-forms gate; `gen_fuel_parametricity.py --check`
reads `OK (29 ambient fuel wrappers in the generated tree = the 29 pins of
TotalityProofTest.lean Part 1, both directions)` (Part 1 regenerated with
`--emit`; Part 2's `has_ccall`/`subst_sym_pexpr` examples restated for the
measured/fuel-free forms); `check_lakefile_roots: OK (202 roots …)` (the
seven new hand-written modules are roots); `check_no_fuel_numerals: OK (281
files scanned …)` — a numeral INSIDE a measure (`n + 1`, `size - i + 1`) is
not a fuel numeral (F3 tightened at the lem slice).

## 8. Findings

- F-C2-1: "35 remaining" was 37 (§2 tally).
- F-C2-2: row 34's proposed measure one short (inclusive guard); caught by
  the obligation (§4).
- F-C2-3: `to_pure`/`to_pures` unprovable with the data measure: the
  recursion argument is `subst_pattern`'s result and `subst_pattern_val`'s
  ill-typed fallthrough is `failwithI` — `opaque` in LemLib (`LemLib.lean:177`),
  so no size fact about it is provable. Not a false obligation: an
  unprovable one (the true value is the default, whose size is small, but
  the kernel cannot see it).
- F-C2-4: the DEFACTO memory model (`Defacto_memory`, `Defacto_memory_aux`:
  12 fuel'd rows) is NOT reachable from `drive` — `mem.lem`'s reps are the
  hand-written `CerbMem`; its rows are (C) for the consumer, including the
  flagged `simplify_integer_value_base`. Its 9 measured rows are still
  proved (they are in the tree and typed).
- F-C2-5: `AilTypesAux.are_compatible` IS drive-reachable
  (`step_eval_pexpr`'s `PEare_compatible`); the lem table's "front-end
  typing, off the execution path" was wrong for it.
- F-C2-6: mutual-block siblings are absent from the kernel constant closure
  (one recursor term); the tool closes under `eqnInfoExt` blocks.
- F-C2-7: `lemNatDiv n 0 = lemDivByZero = failwithI "Division_by_zero"`
  (opaque): `showNonNegativeWithBasis_aux`'s `n + 1` obligation is
  unprovable at `b = 0` (row 1).
- F-C2-8: commits 2/n and 3/n were made with `test_unit.sh` RED — a shell
  chain `(… | grep …) && git commit` took the grep's exit; both repaired
  in 2b/3b, whose messages say so; the later verifications check `rc`
  explicitly. Nothing merged, so the mainline never saw a red state.
- F-C2-9: `unsafe def main` in a test exe is an unregistered seam row for
  the axiom census (2b) — `importModules` is plain `IO`.
- F-C2-10 (tactic): §4's three.

## 9. Decisions for the operator (nothing here was decided by me)

- **D-C2-1 — the tag-lookup family (9 P rows: `CerbMem` layout ×5,
  `reconstructValue`, `ctype_aux` `are_compatible_aux` + 2).** The
  recursion is bounded only by the tag environment's acyclicity (a C struct
  cannot contain itself by value, but a `TagDefs` map can), so the
  unconditional obligation `∀ tagDefs, …` is FALSE for cyclic maps and the
  true measure needs a hypothesis. Options: (a) lem/seam vocabulary for a
  HYPOTHESIS-CARRYING measured form (an obligation `wf tagDefs → …` and a
  wrapper that stays ambient but whose theorem carries the hypothesis) —
  new backend vocabulary + a `TagDefs` well-formedness predicate the
  consumer states; (b) totalize the hand-written layout oracle by structure
  (an explicit "tags not yet visited" argument — changes the mirror's shape
  against impl_mem.ml); (c) keep P: the consumer's theorems carry a
  layout-depth hypothesis for these six seams. The lem-side gap for the
  three generated rows is the same hypothesis.
- **D-C2-2 — point-free tails (6 P rows): lem-lean TODO row 17.** They
  flip to MEASURED with no cerberus change but a proof each when that
  lands (the `are_compatible` trios are `ctype`-structural; `one_step_unseq_aux`/
  `get_ctx_unseq_aux` list-structural).
- **D-C2-3 — `to_pure`/`to_pures`.** Options: (a) make `failwithI`
  transparent-to-default (LemLib: a `def` with the panic as
  `implemented_by`) — the typed-failure pass's territory (2026-09-03
  ruling); (b) a "well-typed pattern" hypothesis on `subst_pattern` (same
  class as D-C2-1); (c) keep P. The runtime is loud either way.
- **D-C2-4 — `hack`** (pure `value` loop, `Driver.finalize`): only a lem
  body change (into the ND monad) or a hypothesis makes it (B)/(A); keep P
  unless the operator allows the former.
- **D-C2-5 — `many`/`many1`**: the printf format parser; a Lean-only
  measure-by-position over the input (the TODO 17 flavour) would need lem
  backend work; the payload (parser zero) cannot be distinguished without a
  lem change. Keep P; note the format strings are short.
- **D-C2-6 — `showNonNegativeWithBasis_aux`**: provable if `lemNatDiv n 0`
  were transparent (LemLib `lemDivByZero`) — the same typed-failure
  question as D-C2-3(a).
- **D-C2-7 — the defacto model's rows (F-C2-4):** dead for `drive`; the
  operator may want them pruned from the exec-cone module list or kept as
  typed-but-unwired model (no change made).
- **D-C2-8 — reachability = kernel closure** (stops at opaque/partial/
  implemented_by): accepted as the (C) definition here; the seam externs are
  the declared boundary.
- **Pre-merge audit ask (unconditional):** proposed scope = the full range
  `753644005..HEAD`; proof-bearing surface = the 38 obligation proofs + the
  3 seam proofs + `CerbMeasureLemmas`; mirror-doctrine surface = the four
  payload declares and the `CerbMem` wrapper changes; gate surface =
  `check_fuel_forms.sh`/`FuelFormsTool.lean`/the pending register.

## 10. Not done, and why

- `to_pure`/`to_pures`, `showNonNegativeWithBasis_aux`: F-C2-3/F-C2-7
  (unprovable, not unattempted).
- The layout family's measured forms: D-C2-1 (a hypothesis is needed).
- The point-free tails: lem TODO 17.
- refined-cerberus untouched (the manifest is theirs); no lem-lean change.
- The mem-scale sweep and the csmith shards were not run (not asked).

## 11. Worktree state at close

Branch `arc/fuel-parameter-C2`; `lean_frontend/generated/` and
`ocaml_frontend/generated/` are the REAL trees (lem-sync stamped, §5); both
driver binaries fresh (`check_driver_fresh --check`: oracle OK, lean OK);
`.tmp/c2/` (the pre-slice OCaml snapshot, lane logs, the classification
table) and `lean_frontend/.probe/` (the tactic probes) are ephemeral and
deleted at slice end; everything load-bearing is quoted here.

## 12. Commits

| # | Commit | Content | Verified before commit |
|---|---|---|---|
| 1/n | `bd8e9c75c` | 35 `fuel_measure` declares + proofs (7 modules), `CerbMeasureLemmas`, `CerbMem.memValueSize`, the 4 absorbing payloads, manifest/roots, `TotalityProofTest` pins | OCaml byte identity; `lake build` 372 jobs; `test_unit.sh` green; oracle stamp cache-disabled; exec minimal `BASELINE OK` |
| 2/n | `e2bbacfc1` | the fuel-forms gate: `check_fuel_forms.sh`, `FuelFormsTool.lean`, `fuel_forms_pending.txt` (24 rows), `test_unit.sh` wiring | gate `--selftest` 5 plants + OK; `test_unit.sh` was RED at the axiom-cone gate (F-C2-8) — committed anyway by a masked shell exit |
| 2b/n | `b64748d52` | `FuelFormsTool.main` is plain `IO` (the `unsafe` was an unregistered seam row) | `check_theorem_axioms` OK, `check_fuel_forms` OK, `test_unit.sh` rc 0 |
| 3/n | `b25ea0aac` | `CerbMem` seams measured by hand (`typeofMval`, `unqualifyAndUnatomic`, `memValueToBytes`) + `CerbMem_lemMeasureProofs`; bounded `to_congr`; register 24 → 21 | `lake build` 373 jobs; exec minimal `BASELINE OK`; `test_unit.sh` was RED at the fuel-forms gate (the gate did not import the seam proofs module) — committed by the same masked exit |
| 3b/n | `75240ce01` | the gate imports every `*_lemMeasureProofs` module | `--selftest` 5 plants + `OK (81 … 41 MEASURED … 13 ABSORBING … 21 …)`; `test_unit.sh` rc 0 (checked explicitly) |
| 4/n | (this commit) | docs: this record, the change manifest, `VALIDATION.md` ((A)/(B)/(C) table + gate row), `TODO.md`, `CLAUDE.md` | the battery of §6 on the 3b head; docs-only change |

The intermediate trees of 1/n are not individually buildable in smaller
groups (declares + proofs must land together — the fail-closed design);
2/n and 3/n are each RED at one gate until the next commit (F-C2-8): a
bisect across `e2bbacfc1` or `b25ea0aac` must read the following commit
with it.
