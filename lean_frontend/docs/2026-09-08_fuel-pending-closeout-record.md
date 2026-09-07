# Fuel-pending close-out — record (2026-09-08)

**Status: SLICE RECORD [AGENT worker], branch `arc/fuel-pending-closeout`** (worktree
`worktrees/cerberus-lean-arc/fuel-pending-closeout`) from mainline `mdd/cerberus-lean` @
`94f339eb4`. Nothing merged, nothing pushed; the primary checkout, every other worktree,
lem-lean, `deps/` and refined-cerberus untouched; the fence (`CerbMem.lean`,
`CerbTagsWf.lean`, `CerbMem_lemMeasureProofs.lean`, `Core_reduction_lemMeasureProofs.lean`,
`core_reduction.lem`, the μ text of existing `fuel_hypotheses.txt` rows) untouched. Every
quoted line is verbatim from this worktree's logs (`.tmp/closeout/`, ephemeral); tallies
marked derived are derived. Decisions carry [USER]/[AGENT] provenance.

## 0. The ruling, verbatim

[USER 2026-09-07]: "create a branch and send a worker to do option C" — option C of the
pure-failure reachability census (`docs/2026-09-07_pure-failure-reachability-census.md`
§Q6: status quo + register; close the three always-on-path sentinels by the one-iteration
measure; keep the F1 probe suite as a tripwire). The parked twin design
(`docs/2026-09-07_pure-failure-correspondence-design.md`) stays parked; its flip conditions
are what the new register check (D4) watches.

## 1. Commits (this branch, oldest first)

```
c5b3bce1b fuel-pending close-out D3: the are_compatible trio stays PENDING (no honest hypothesis); upstream-tray draft 37 (cross-TU recursive-struct non-termination) + reproducer
f93fba8d6 fuel-pending close-out D2: many / many1 stay PENDING — the precise blocker recorded (no parameter-level measure exists)
8d59b3132 fuel-pending close-out D1: hack / to_pure / to_pures MEASURED under the arena SHAPE hypothesis — pending 8 -> 5
(+ D4 and this record — see the branch log)
```

| Deliverable | Content |
|---|---|
| D1 `8d59b3132` | `hack`, `to_pure`, `to_pures` MEASURED under the arena SHAPE hypothesis; NEW seam `CerbCoreShape.lean`; NEW `Driver_lemMeasureProofs.lean`; `Core_aux_lemMeasureProofs` extended; registers 8 → 5 / +3 hypothesis rows; pins 22 → 19; `CerbND.hack_wrapper_defeq` retired; fork-drift layer-3 pins refreshed |
| D2 `f93fba8d6` | `many`/`many1` stay pending with the precise blocker in the register |
| D3 `c5b3bce1b` | the `are_compatible` trio stays pending; upstream-tray draft 37 + INDEX + reproducer |
| D4 | `scripts/failure_reach_register.txt` (233 rows) + `check_failure_reach.{py,sh}` + `failure_position.py`; wired into `test_unit.sh` and LADDER Tier B row 11 |
| D5 | this record; VALIDATION.md §6/§7; TODO.md; CLAUDE.md key files |

## 2. Per-row disposition of the eight pending rows

| Worker (`.lem`) | Disposition | μ | H (the tool's `hyp` text = the register row) | Proof | Invariant cite |
|---|---|---|---|---|---|
| `hack` (driver.lem) | **CLOSED — MEASURED under hypothesis** | `lemSize pexpr1` | `CerbCoreShape.IsValuePexpr pexpr1` | `Driver_lemMeasureProofs.hack_measure_sufficient` (NEW module): `step_eval_pexpr_value` (a `PEval` steps to itself with annotations reset, core_eval.lem PEval arm), `hack_value` (one iteration), both sides of the obligation are the value | `prepare_exit` driver.lem:1309-1316 via the two terminal arms of `process_core_step2` :1331-1338 / :1352-1356; `finalize` :1473-1477 |
| `to_pure` (core_aux.lem) | **CLOSED — MEASURED under hypothesis** | `lemSize g` | `CerbCoreShape.IsPureExpr g` | `Core_aux_lemMeasureProofs.to_pure_pure` + `to_pure_measure_sufficient` | same; call sites `finalize` :1473-1477, `driver_globals` :1611-1616 |
| `to_pures` (core_aux.lem) | **CLOSED — MEASURED under hypothesis** (mutual sibling, all-or-none) | `List.length l + 1` | `CerbCoreShape.AllPureExprs l` | `to_pures_stable` (fold congruence on members) + `to_pures_measure_sufficient` | never entered on the exec path (to_pure's Eunseq/Ecase arms need a non-Epure arena) |
| `many` (monadic_parsing.lem) | **PENDING** — no parameter-level measure | — | — | — | blocker: the recursion argument is the INPUT `cs`, bound inside the `ParserM` lambda (monadic_parsing.lem:38-40, :52-56, :100-103); the only parameter is the parser `p`; a measure fixes the counter before the input arrives (D2 note in the register) |
| `many1` | **PENDING** — mutual sibling | — | — | — | same |
| `are_compatible_aux` (ctype_aux.lem) | **PENDING** — no honest hypothesis | — | — | — | F-C4-1: the sufficient hypothesis (a rank through ALL references) is violated by legal C; census UNKNOWN ×4 quoted in the register; tray draft 37 written (D3) |
| `are_compatible_params_aux0` | **PENDING** | — | — | — | sibling |
| `are_compatible_params0` | **PENDING** | — | — | — | sibling |

Why the measures are not the numeral 1: lem refuses a numeral measure (FM-literal, the
no-magic-values rule); `lemSize x ≥ 1` (`CerbMeasureLemmas.pexpr_lemSize_pos` /
`expr_lemSize_pos`) is the least parameter expression bounding one hop; the proof uses
only `1 ≤ μ`. On inputs violating H the fuel-free wrapper may exhaust (the loud sentinel),
exactly as the C4 layout rows on a cyclic table.

### 2.1 Erratum to the census's Q4 cite [AGENT]

The census says the arena is `Epure` of a value at `finalize` "because `Step_done` requires
it (core_run.lem:1557-1589) and `Step_done2` leaves the arena untouched (driver.lem:485-486)".
`driver.lem:485-486` is inside the commented-out `drive_core_thread2` (:452-510), and
`core_run.core_thread_step2` is not on the drive path (the census itself notes the driver
steps through `Core_reduction.step_ctx`). The OPERATIVE mechanism is `prepare_exit`
(driver.lem:1309-1316): `driver2` (:1369) returns only through `process_core_step2`'s two
terminal arms — `Step_done2` (:1331-1338) and `Step_fs2`/`FS_done` (:1352-1356); every
other arm re-enters `driver2` or is an `error`; `new_drive_core_threads` (:1275-1296) never
yields a `Nothing` step for the `(_, Nothing)` arm — and both terminal arms set the initial
thread's arena to `Core_aux.mk_value_e cval` = `Expr [] (Epure (Pexpr [] () (PEval cval)))`
(core_aux.lem:454-455, :2077-2082) and its stack to `Stack_empty`. The conclusion (one
iteration) is the census's; the cite is corrected in `CerbCoreShape.lean`'s header and the
register rows. The `exit` builtin's `Step_done2` (core_reduction.lem:996) takes the same
path.

## 3. The census lines, verbatim

Before (the mainline's committed record, `docs/2026-09-07_risk-map-baseline.md:500`, the
gate as it read on the base; the primary checkout may not be touched by this worker, so the
committed line is the honest "before"):

```
check_fuel_forms: OK (81 fuel'd workers: 54 MEASURED (obligation of the contract's shape incl. argument correspondence against the wrapper's body; every obligation + proof cone ⊆ the standard three; 7 of them under a hypothesis, each = a reviewed row of fuel_hypotheses.txt, both directions), 13 ABSORBING = kill at zero (the _zero lemma is the worker at literal 0 on its own binders = the monad's absorbing element, cone ⊆ the standard three; propagation NOT proved — lem TODO 13), 8 reachable-AMBIENT = the 8 rows of fuel_forms_pending.txt exactly, 6 ambient unreachable from the drive cone)
```

After (this worktree, `check_fuel_forms.sh`, rc 0; identical after D2's register note):

```
check_fuel_forms: forms partition OK (57 MEASURED + 13 ABSORBING + 5 ambient-reachable + 6 ambient-unreachable = 81 fuel'd workers)
check_fuel_forms: OK (81 fuel'd workers: 57 MEASURED (obligation of the contract's shape incl. argument correspondence against the wrapper's body; every obligation + proof cone ⊆ the standard three; 10 of them under a hypothesis, each = a reviewed row of fuel_hypotheses.txt, both directions), 13 ABSORBING = kill at zero (the _zero lemma is the worker at literal 0 on its own binders = the monad's absorbing element, cone ⊆ the standard three; propagation NOT proved — lem TODO 13), 5 reachable-AMBIENT = the 5 rows of fuel_forms_pending.txt exactly, 6 ambient unreachable from the drive cone)
```

## 4. Gate lines, verbatim (D1 head unless stated)

Generation (`make prelude-src` / `make lean-prelude-src` via `scripts/ce`) — the OCaml
tree is BYTE-IDENTICAL (the `gen` hash is the mainline's `295e4f82…`; `src` moves with the
`.lem` text by construction):

```
check_lem_sync: recorded ocaml_frontend/lem_sync.sha256 (src cc8591e650624c8386b8384f625ae07b33962ec3d226b339e5588ce02aa18b55, gen 295e4f8291c9ffd57a4061dd38e8ec273f18d6c1cfe3a0465291f1a4bcff8100)
check_lem_sync: recorded lean_frontend/lem_sync.sha256 (src cc8591e650624c8386b8384f625ae07b33962ec3d226b339e5588ce02aa18b55, gen cd0016e3ef1d1ba98a2c442d73c3cb998d4febff8d77db932c4f9c1a9d1927d9)
```

Build (`CERB_MEM_MAX=32G scripts/capped lake build`): `Build completed successfully (380 jobs).`

`test_unit.sh` rc 0 — the gate lines (sorted, unique):

```
Total: 6 passed, 0 failed
UNIT rc=0
check_exec_purity: CLEAN (11 modules)
check_exec_totality: CLEAN (22 generated modules + hand-written CerbND, 0 allowlisted)
check_fixture_freeze: OK (16 fixture files match the pinned manifest; name set exact)
check_handwritten_sync: OK (39 hand-written files byte-identical to lean_frontend/generated/; manifest lean_frontend/handwritten_copy.manifest)
check_lakefile_roots: OK (208 roots = 208 generated modules + the exe root Main; 85 auxiliary modules all built)
check_lem_sync: OK (src cc8591e650624c8386b8384f625ae07b33962ec3d226b339e5588ce02aa18b55, gen 295e4f8291c9ffd57a4061dd38e8ec273f18d6c1cfe3a0465291f1a4bcff8100)
check_lem_sync: lean OK (src cc8591e650624c8386b8384f625ae07b33962ec3d226b339e5588ce02aa18b55, gen cd0016e3ef1d1ba98a2c442d73c3cb998d4febff8d77db932c4f9c1a9d1927d9)
check_no_fuel_numerals: OK (297 files scanned comment-stripped; no lemDefaultFuel/driverFuel/ndDefaultFuel, no LemFuel instance, no literal fuel (F1-F6); allowed Main.lean sites seen: 4 of 4 (hand-written + generated copy))
check_sorry_token: OK (290 files scanned comment-stripped — generated 209, hand-written+test 46, LemLib 35; 0 sorry tokens)
check_theorem_axioms: C2 entry census OK (9 entries, every cone ⊆ [propext, Classical.choice, Quot.sound])
check_theorem_axioms: C2 ratchet OK (331 files scanned recursively: 0 axioms, 0 runEffectful, seam population = the 38 pinned path-qualified counted rows exactly incl. the extern class; lem tests/ scaffolds asserted outside the surface)
check_theorem_axioms: D14 grep-ban OK (no native_decide/bv_decide in 1 tree(s) + 39 hand-written seam files + LemLibTest.lean)
check_theorem_axioms: FUEL arc leg OK (35 contract lemmas — 9 generated _zero + the CerbND runner leaves/parametricity pins + the ∀-fuel exemplar and its instances + the 3 C1 fuel_measure sufficiency obligations + hack's (generated statement + hand-written proof), every cone ⊆ [propext, Classical.choice, Quot.sound])
check_theorem_axioms: OK (effect-retirement C2 bar: zero axiom declarations anywhere; entry cones ⊆ the standard three)
check_theorem_axioms: generated-tree census OK (209 files: 0 axioms, boundary-opaque population = the 15 registered rows exactly-once (incl. CerbFuel.fuelExhaustedLoc), 0 unsafeCast)
check_theorem_axioms: hand-written axiom census OK (0 axioms — the arc-17 S2b end state)
check_theorem_axioms: mem-scale S1 leg OK (6 C1/C3 equality theorems, every cone ⊆ [propext, Classical.choice, Quot.sound])
gen_fuel_parametricity: OK (19 ambient fuel wrappers in the generated tree = the 19 pins of TotalityProofTest.lean Part 1, both directions)
test_fuel_classifier: 18 fixtures, ALL OK
test_renumber_plants: OK (12 plants: refusals refuse, admits admit with declared class)
check_fuel_forms: SELFTEST OK (24 plants with the declared label — 6 on the table (incl. the ABSORBING-cone plant), 3 on the hypothesis register, 15 compiled decoys: the C4 four (type True / wrong worker / contradictory hypothesis caught by the register / extra binder), the whole-project audit's two decoys verbatim (review_bad _zero about runNDFuel; review_shift at literal 0), wrong fuel position, swapped worker-side and wrapper-side arguments, changed measure, wrapper calling another worker, hidden premise, and three _zero decoys (a POSITIVE control ABSORBING, a term for a binder, fuel 1) — each rejected with its own message; unplanted table green)
```

The four exec baseline lanes (Tier A rows 2, 3, 4, 4b; fresh stamps
`check_driver_fresh: recorded oracle stamp (bin db7ade92e95b25253a5abcedf66478d0ebd6982caeb1d782d98ff801739f2fcf, src bbf4fab97b743ccbfb0417eeeecef50e8bbea5a5974acfdbe68d0d98e4de67a2)` / `check_driver_fresh: recorded lean stamp (bin 30860806f0c74afcc198c43f96ddda1127db3c09678863d9add67b13a6eac439, src cffea1d346fafe59597c8e5a168819f3d1705b3b606fefec8133d733d36eecbd)`), each rc 0, zero movement:

- tests/minimal (row 2):
  ```
  SUMMARY: total=106 match=85 ub_match=18 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=3 cerb_floor=0 cerb_inconsistent=0
  Baseline check: 0 regression(s), 0 improvement(s)
  BASELINE OK
  ```
- tests/coverage (row 3):
  ```
  SUMMARY: total=212 match=183 ub_match=16 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=13 cerb_floor=0 cerb_inconsistent=0
  Baseline check: 0 regression(s), 0 improvement(s)
  BASELINE OK
  ```
- tests/debug (row 4):
  ```
  SUMMARY: total=90 match=66 ub_match=20 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=4 cerb_floor=0 cerb_inconsistent=0
  Baseline check: 0 regression(s), 0 improvement(s)
  BASELINE OK
  ```
- tests/float (row 4b):
  ```
  SUMMARY: total=69 match=69 ub_match=0 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=0 cerb_floor=0 cerb_inconsistent=0
  Baseline check: 0 regression(s), 0 improvement(s)
  BASELINE OK
  ```

Axiom cones of the six new constants (`#print axioms` on a scratch file importing
`Driver_auxiliary` and `Core_aux_auxiliary`; `check_theorem_axioms.sh`'s FUEL leg probes
the first two by name):

```
'hack_measure_sufficient' depends on axioms: [propext, Classical.choice, Quot.sound]
'Driver_lemMeasureProofs.hack_measure_sufficient' depends on axioms: [propext, Classical.choice, Quot.sound]
'Ctype_lemMeasureProofs.ctypeEqual_measure_sufficient' depends on axioms: [propext, Classical.choice, Quot.sound]
'Core_lemMeasureProofs.eq_core_base_type_measure_sufficient' depends on axioms: [propext, Classical.choice, Quot.sound]
'Defacto_memory_aux_lemMeasureProofs.fake_mem_value_eq_measure_sufficient' depends on axioms: [propext, Quot.sound]
'ctypeEqual_measure_sufficient' depends on axioms: [propext, Classical.choice, Quot.sound]
'eq_core_base_type_measure_sufficient' depends on axioms: [propext, Classical.choice, Quot.sound]
'fake_mem_value_eq_measure_sufficient' depends on axioms: [propext, Quot.sound]
```

Fork drift (layer 3 pins for `core_aux.lem` `64a7e8ab… → 547a673e…` and `driver.lem`
`5035f993… → 067f1830…`, refreshed by editing the two `[source-content]` lines with the
identities `check_fork_content.py --emit` prints, plus a dated header note; layer 2 stays 22):

```
check_fork_drift: OK — layer 1: 76 oracle-surface files = manifest (set, C-locale canonical, no duplicates); layer 2: 22 differing generated files, all hash-pinned (merge-base b9aeedcb4dd438763b0eef7f95ac19e93875d7de; lem-pin f6542f8 = lem -v)
```

## 5. D4 — the failure-reach register and its check

`scripts/failure_reach_register.txt`: one row per PURE failure site in the exec dependency
closure (231) + the two pure sites whose kernel owner the compiler ranges do not resolve
(`CoreParser.scanStep`, `Main.loadCoreImpl`; scope `UNRESOLVED-OWNER`, reach `UNKNOWN`,
read by hand) — file · kernel owner · token · message key · scope · live position class ·
reviewed position (the census's Q1, incl. its 4 `manual:` outer-match corrections and the
33 hand-written newline rows read as TAIL) · reach class · need/invariant/witness · cite ·
note · seal. Seeded from the census evidence `sites231_classified.tsv` by (file, owner,
token, message) with the line as tie-break; the reviewed columns are copied, not
re-derived. Tally line: `sites=233 exec=231 unresolved-owner=2 reviewed-TAIL=179
reviewed-NON-TAIL=54 UNREACHABLE-BY-INVARIANT=166 REACHABLE=48 UNKNOWN=19 discardable=0`
(the census's 178/53 · 166/48/17 + the two unresolved rows). The seal
(`sha256(file|owner|token|msg|scope|position|position_reviewed|reach)[:16]`) makes any class
edit a deliberate `--reseal` in a commit.

`scripts/check_failure_reach.sh` (gate; `--selftest`; `--emit [SEED]`): builds the
declaration-dependency instrument `tests/failure-probes/FailureReach.lean` as a fresh
scratch Lake package requiring `lean_frontend` by path (always re-elaborated; ~6–7 s and
~1.8 GB when the semantics is built), runs `failure_census.py`, then
`check_failure_reach.py`: the live site multiset (key file/owner/token/message) must equal
the register's, both directions; live position class (the census's classifier, ported to
`scripts/failure_position.py` with a DISCARDABLE test — a LET-BOUND/LET-BOUND-FUN unit in a
GENERATED file whose bound names are dead) must equal the row's; every row sealed, classes
reviewed, tally consistent. The token-level classifier is reliable on generated text; the
hand-written NON-TAIL rows are the census's READING (the register's `position_reviewed`),
and a new hand-written site is RED by key regardless. This is the tripwire the parked twin
design names: a DISCARDABLE site that is REACHABLE would flip it. Verbatim:

```
check_failure_reach: instrument built + census taken in 7 s (FAILURE_REACH rows 21083, FAILURE_RANGE rows 11234; counts: {"generated:monadic_ascribed":263,"generated:pure_or_unresolved":1253,"handwritten:monadic_ascribed":7,"handwritten:pure_or_unresolved":121})
check_failure_reach: OK (233 pure failure sites = the 233 register rows exactly (231 in the exec dependency closure + 2 unresolved-owner; key = file/owner/token/message, both directions); position classes unchanged; 0 DISCARDABLE; reach UNREACHABLE-BY-INVARIANT=166 REACHABLE=48 UNKNOWN=19; every row sealed; tally line consistent)
```

```
check_failure_reach: SELFTEST — plants on scratch copies of the scanned sources and the register (loud plant banner; nothing in the tree is touched)
  PLANT OK   [P1 a new failwithI planted into generated valueFromPexpr] rc=1 ->   NEW pure exec-closure site (no register row — review it): lean_frontend/generated/Core_aux.lean:479 valueFromPexpr failwithI «"PLANT-NEW-SITE" : Option (value)) /- removed value specific» position=TAIL scope=EXEC
  PLANT OK   [P2 a DEAD let-bound failwithI planted into generated valueFromPexprs (the F1 shape)] rc=1 ->   DISCARDABLE position (the F1 shape: a dead let-binding of a failure in a generated definition — the twin design's flip condition): lean_frontend/generated/Core_aux.lean:483 valueFromPexprs «"PLANT-DEAD" : Nat); lemListFoldr (
  PLANT OK   [P3 a REACHABLE row's reach class edited to UNKNOWN without --reseal] rc=1 ->   SEAL MISMATCH (row edited without --reseal; a class change is a review change): lean_frontend/CerbDecode.lean _private.CerbDecode.0.CerbDecode.decode_character_constant_aux «s!"decode_character_constant: invalid char constant =
  PLANT OK   [P4 a phantom register row (re-sealed) -> stale] rc=1 ->   STALE register row (site gone or its key moved): lean_frontend/generated/Core_aux.lean phantom_def failwithI «"phantom"» scope=EXEC
  PLANT OK   [P5 the tally line edited] rc=1 ->   `# tally:` line does not equal the rows: register says `sites=0 exec=231 unresolved-owner=2 reviewed-TAIL=179 reviewed-NON-TAIL=54 UNREACHABLE-BY-INVARIANT=166 REACHABLE=48 UNKNOWN=19 discardable=0`, rows give `sites=233 exec=23
check_failure_reach: SELFTEST OK (5 plants with the declared message — a new site in a generated exec-closure definition, a DISCARDABLE dead let-binding, an unsealed class edit, a phantom row, an edited tally — and the unplanted register green)
```

Wired into `test_unit.sh` (after the fuel-forms gate; `--selftest` then the gate) — its cost
is unit-scale (instrument + census 6–7 s; measured above) — and into LADDER Tier B as its
own row 11 per the brief (redundant with Tier A row 1 by inclusion; the orchestrator may
trim). Evidence kept for this record: `reach.log` sha256 `05d2e656f0a2c47e44ab0a64df34886ad9e0ee2968fe2ffbd27f78cb8d0102b7`, `census.json`
sha256 `83cf7f555dea83b9f749469d7778fe861d01f2bad2b51d9a51f33cabc65f4f26` (ephemeral `.tmp/closeout/reach/`, not committed; the census's
whole-tree counts are unchanged from the census record: 263/1253/7/121).

## 6. D3 — the trio and the tray draft

`tests/failure-probes/cross_tu_node/` (`node_a.c`, `node_b.c`, `node_single_control.c`),
run 2026-09-08:

```
--- [fork oracle 2-TU cross_tu_node] rc=124 elapsed=60s
--- [upstream oracle 2-TU cross_tu_node] rc=124 elapsed=60s
--- [lean 2-TU cross_tu_node (default fuel)] rc=134 elapsed=3s
Stack overflow detected. Aborting.
--- [fork oracle single-TU control] Defined {value: "Specified(7)", stdout: "", stderr: "", blocked: "false"}
--- [upstream oracle single-TU control] Defined {value: "Specified(7)", stdout: "", stderr: "", blocked: "false"}
--- [lean single-TU control] Defined {value: "Specified(7)", stdout: "", stderr: "", blocked: "false"}
```

Draft: `docs/upstream-tray/37-are-compatible-cross-tu-recursive-struct-nontermination.md`
(TRUE BUG; cites at upstream `b9aeedcb4` line numbers: ctype_aux.lem:69-192, :92, :95-136,
:98, :109, :120, :137-176; core_aux.lem:182-184; symbol.lem:274; remedy = an
assumed-compatible set of tag pairs). INDEX entry 37; the duplicate-search caveat now
reads 15–37.

## 7. What remains

- **The trio** (`are_compatible_aux`, `are_compatible_params_aux0`, `are_compatible_params0`):
  pending until upstream fixes the recursion (tray 37) — a lem body change is not Lean-only
  and fixes a non-termination on the OCaml side too (C4 record §8 item 2(c), operator
  decision).
- **`many`/`many1`**: pending; a lem-lean backend item (a `lemTail`-style hoist through a
  single-constructor wrapper) would make the input a head parameter Lean-only; an
  eta-expansion in the lem text is a body change (forbidden).
- **The twin design's flip conditions** (unchanged): a DISCARDABLE site that is REACHABLE
  (tripwires: D4's check — today 0 DISCARDABLE among the 231 — and the lem probe suite
  `tests/failure-probes/discarded_failures.lem`); a REACHABLE step-level site where the
  oracle succeeds (today 0 — the 36 one-sided rows are all `CerbFS`, outside the step-level
  closure); growth of the well-typed-UB-free reachable set beyond 4; an operator ruling that
  values the logical property over oracle conformance.
- **Register reviewer fields**: the three new `fuel_hypotheses.txt` rows carry `[AGENT
  worker 2026-09-08]; reviewer/operator sign-off pending` — the pre-merge audit signs them
  (the C4 pattern); the operator's merge "yes" is the final signature.
- **17 UNKNOWN sites** of the census stay UNKNOWN in the register (with their needs); the
  register is the place they move when a witness or an invariant arrives.

## 8. Consumer note (refined-cerberus) — change manifest

Constants whose SIGNATURE changed (all Lean-only; OCaml byte-identical):
- `to_pure {a} (g : expr a) : Option pexpr` and `to_pures {a} (l : List (expr a)) : Option
  (List pexpr)` LOST their `[LemFuel]` instance binder (measured wrappers are fuel-free);
  `to_pure e` still elaborates under any instance context; an explicit `@to_pure a ⟨n⟩ e`
  or `@to_pures a ⟨n⟩ l` no longer typechecks (drop the instance argument).
- `hack` keeps its type and its `[LemFuel]` binder (for `step_eval_pexpr`'s ambient callees)
  but its BODY changed: `hack_lemFuel (generic_pexpr.lemSize pexpr1) …` instead of
  `hack_lemFuel LemFuel.fuel …` — `@hack ⟨n⟩ = @hack_lemFuel ⟨n⟩ n` is FALSE by design;
  `CerbND.hack_wrapper_defeq` is REMOVED. The fuel-freedom of the three is pinned by the
  obligations below.
- `finalize`, `driver_globals`, `drive`, `driver2`: types unchanged (they still carry
  `[LemFuel]` for the driver family).
New constants: `CerbCoreShape.IsValuePexpr / IsPureExpr / AllPureExprs` (Props by
constructor shape); `hack_measure_sufficient` (Driver_auxiliary) and
`Driver_lemMeasureProofs.{step_eval_pexpr_value, hack_value, hack_measure_sufficient}`;
`to_pure_measure_sufficient`, `to_pures_measure_sufficient` (Core_aux_auxiliary) and
`Core_aux_lemMeasureProofs.{to_pure_pure, to_pure_measure_sufficient, to_pures_stable,
to_pures_measure_sufficient}`. Consumer-shaped statements: `∀ pe, IsValuePexpr pe → ∀ n ≥
lemSize pe, hack_lemFuel n … pe = hack … pe`, and likewise for `to_pure`/`to_pures`; the
hypotheses are the arena shape after `prepare_exit` (§2.1), which a theorem about `drive`'s
final state can discharge from `prepare_exit`'s definition. New hypothesis rows in
`scripts/fuel_hypotheses.txt`; `scripts/fuel_forms_pending.txt` 8 → 5. The `_zero` lemmas
are unchanged (generated). Nothing else in the generated tree changed textually except the
three wrappers, the two `import CerbCoreShape` lines and the two `_auxiliary` obligation
files (derived: `diff -rq` of the lem-generated files vs the mainline's tree — the D1
commit's stat).

## 9. What was not done

- No merge, no push, no Tier B battery (the orchestrator's).
- The Lean-side lem-generated-tree `diff -rq` against a pre-slice snapshot was not taken
  (the primary checkout may not be touched); the OCaml identity is by the lem-sync `gen`
  hash, and the Lean tree's change set is the D1 commit's generated-file diff (derived).
- The three new hypothesis rows are not yet reviewer-signed (§7).
- `check_failure_reach.sh --selftest` runs the census on copies of ~210 files three times;
  a hand-written NON-TAIL site is classified by READING, not by the tool (§5) — the census's
  own limit, recorded in the register header.
