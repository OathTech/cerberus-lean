# The cerberus re-pin for lem TODO 54: record (2026-11-10)

Worker [AGENT], branch `arc/todo54-repin`, worktree `worktrees/cerberus-lean-arc/todo54-repin`. Charter
`docs/2026-11-10_worker-charter-todo54-repin.md` (roadmap item 1, [USER 2026-11-10]). Base: the charter names
mainline `b66374eac`; the branch sits on `a5ff9d42e`, one empty landing-note commit later, the same tree.
Commits: M1 `4d4801eae` (the re-pin), M2 `aa4c9869f` (the lane rider), M3 this record
and the notes. Quoted machine output is verbatim; every count labelled derived was computed by a script over the
named artefacts, not printed by a gate. All runs 2026-11-10, capped at `CERB_MEM_MAX=32G`, one heavy job at a time,
1-minute load between 1.2 and 3.9 at each start.

## 0. Summary

- The lem pin moved `e6d8db5` → `2220010bc25f0c5682d8200f016e786ee66d65c6` at every site; `check_pin_sites.sh` green.
- Generated OCaml: byte-identical (86 files, recursive diff empty). Generated Lean: 52 modules changed, in the three
  expected shapes only — 147 `termination_by structural` clauses removed, 601 binders renamed `_name`, 75 derived
  `Inhabited` binders blanked — every hunk classified token by token, 0 findings, per-module counts equal to the
  lem-lean consumer note's table.
- No hand-written Lean file needed a change.
- Stored Lake warnings for modules of the tree: 823 before, 0 after (derived). `-DwarningAsError=true` is in the
  root package's `moreLeanArgs` ([AGENT 2026-11-10]); every root-package and speclab target builds under it.
- Every gate the charter names is green; kernel replay exit 0.
- The lane rider (M2): a RESOURCE baseline row no longer pins the kill kind; two rows re-recorded; `--gate` green.
- **Failures and findings, stated as such:** (F1) the third Lake package `tests/mem-scale-probes/micro` does NOT
  build — pre-existing type errors in `Micro.lean`, not caused by the re-pin, not fixed here (§6). (F2) a standalone
  `test_inner_arg_temps.sh --selftest` run before the baseline was re-recorded exited 1, as the new check intends
  (§9). (F3) stale prose found, not edited: `README.md:8` and `SUPPORTED.md:4` still call `2d3a492` the current
  pin (stale since the 2026-10-26 re-pin), and LADDER row 15 says 186 rows where the lane runs 188 (§10).

## 1. What moved (M1)

| Site | Change |
|---|---|
| `lean_frontend/lakefile.toml` `[[require]]` LemLib `rev` | `e6d8db5…` → `2220010bc25f0c5682d8200f016e786ee66d65c6`, a dated comment |
| `lean_frontend/lake-manifest.json`, `lean_frontend/speclab/lake-manifest.json`, `tests/mem-scale-probes/micro/lake-manifest.json` | LemLib `rev` and `inputRev`, written by `lake update LemLib` in each package (through `scripts/ce` and `scripts/capped`; offline, rc 0 each; no manifest was hand-edited; the diff is those six lines) |
| `scripts/fork_drift_manifest.txt` `[meta] lem-pin` | the full hash |
| `lean_frontend/README.md` newcomer `opam pin add` command | the full hash |
| `lean_frontend/CLAUDE.md` dated pin line | the previous pin put in the past tense, the current pin and this record named |
| `lean_frontend/lakefile.toml` `moreLeanArgs` | `"-DwarningAsError=true"` added (§5) |

Shared state (the orchestrator's, before the slice): `deps/lem-pinned` at `2220010`, the shared switch's
`lem -v` = `Lem lean-backend-v0.1.0-alpha.1-88-g2220010` (re-read by this worker before generating). No `opam`
package command was run by this worker. The LemLib package checkout under `lean_frontend/.lake/packages/LemLib` is
at the pin after the update.

## 2. Regeneration

`scripts/ce make clean-prelude-src prelude-src lean-prelude-src`, rc 0. The pre-re-pin trees were the worktree's
primed copies of the primary checkout's generated trees (lem `e6d8db5`, mainline `a5ff9d42e`), snapshotted before
the first edit; the old lem was not re-run by this worker (the shared switch had already moved).

- `ocaml_frontend/generated/`: `diff -r` against the snapshot empty; 86 files on both sides.
- `lean_frontend/generated/`: 229 files on both sides, none added or removed, 52 differ (`diff -rq`); the 57
  hand-written copies identical.

## 3. The hunk classification (derived; token level)

Method: for each differing file, the line hunks of `difflib.SequenceMatcher`; in each hunk the removed lines that
are exactly `termination_by structural (cmpx_|sizex_)…` are counted and set aside; the remaining old and new lines
are tokenized (identifiers, numerals, single symbols) and compared position by position. Admitted differences: an
identifier starting with a letter that gained one leading underscore (R); `x<n>` → `_` directly after `fun (` and
before `:` (I). Anything else is a finding: a different token count, any other token change, an added
`termination_by`, a file added or removed, or a change in a file's multiset of `__`-prefixed tokens.

| Module | `termination_by` removed | binders `_name` | Inhabited `x<n>` → `_` | line hunks |
|---|---|---|---|---|
| `AilSyntax` | 4 | 0 | 0 | 4 |
| `AilTypesAux` | 0 | 15 | 0 | 13 |
| `AilTyping` | 0 | 1 | 0 | 1 |
| `Annot` | 6 | 3 | 0 | 9 |
| `Cabs` | 8 | 0 | 0 | 8 |
| `Cabs_to_ail` | 0 | 17 | 0 | 16 |
| `Cabs_to_ail_aux` | 0 | 2 | 0 | 2 |
| `Cabs_to_ail_effect` | 8 | 9 | 0 | 16 |
| `Cmm_aux` | 0 | 1 | 0 | 1 |
| `Cmm_csem` | 16 | 120 | 8 | 92 |
| `Cmm_op` | 0 | 22 | 0 | 17 |
| `Cn` | 10 | 1 | 0 | 11 |
| `Constraint` | 4 | 0 | 0 | 4 |
| `Core` | 2 | 2 | 0 | 4 |
| `Core_aux` | 0 | 23 | 0 | 11 |
| `Core_eval` | 0 | 10 | 0 | 8 |
| `Core_linking` | 0 | 1 | 0 | 1 |
| `Core_reduction` | 8 | 33 | 15 | 39 |
| `Core_reduction_aux` | 0 | 1 | 0 | 1 |
| `Core_rewrite` | 0 | 3 | 0 | 3 |
| `Core_run` | 6 | 41 | 1 | 24 |
| `Core_run_aux` | 0 | 2 | 0 | 2 |
| `Core_sequentialise` | 0 | 3 | 0 | 2 |
| `Core_typing` | 0 | 53 | 0 | 33 |
| `Core_typing_aux` | 0 | 5 | 0 | 3 |
| `Ctype` | 0 | 1 | 0 | 1 |
| `Ctype_aux` | 2 | 3 | 0 | 4 |
| `Defacto_memory` | 0 | 92 | 0 | 56 |
| `Defacto_memory_aux` | 0 | 20 | 0 | 11 |
| `Defacto_memory_types` | 2 | 0 | 0 | 2 |
| `Desugaring_init` | 6 | 1 | 6 | 9 |
| `Dlist` | 2 | 0 | 1 | 3 |
| `Driver` | 2 | 17 | 0 | 19 |
| `ErrorMonad` | 2 | 0 | 1 | 3 |
| `Errors` | 14 | 0 | 0 | 14 |
| `Formatted` | 4 | 5 | 0 | 6 |
| `GenTypesAux` | 0 | 1 | 0 | 1 |
| `GenTyping` | 2 | 45 | 0 | 43 |
| `Implementation` | 0 | 1 | 0 | 1 |
| `IntegerImpl` | 2 | 4 | 2 | 7 |
| `IntegerType` | 4 | 0 | 0 | 4 |
| `Mem` | 0 | 2 | 0 | 2 |
| `Mem_common` | 14 | 1 | 0 | 15 |
| `Mini_pipeline` | 0 | 2 | 0 | 2 |
| `Monadic_parsing` | 2 | 0 | 1 | 3 |
| `Nondeterminism` | 5 | 9 | 1 | 12 |
| `Scope_table` | 0 | 1 | 0 | 1 |
| `Symbol` | 4 | 1 | 0 | 5 |
| `Translation` | 2 | 24 | 0 | 23 |
| `Translation_aux` | 2 | 3 | 39 | 5 |
| `TypingError` | 2 | 0 | 0 | 2 |
| `Undefined` | 2 | 0 | 0 | 2 |
| **total (52 modules)** | **147** (29) | **601** (41) | **75** (10) | **581** |

hunk classes (T=termination_by removed, R=rename, I=Inhabited, reflow=line re-wrap, token-identical apart from R/I): {'T': 147, 'R': 403, 'R+reflow': 10, 'I': 18, 'I+reflow': 3}

FINDINGS: 0

The three totals and all 52 per-module rows equal the table in lem-lean
`doc/lean-backend/2026-11-07_consumer-note-cerberus-unreferenced-binders.md` §3 (compared by `diff`, no line
differs but the total row's wording). Of the 676 renamed or blanked binders, 80 are signature parameters of 61
definitions (derived; listed in the two consumer notes), the rest pattern, lambda and let binders.

## 4. Hand-written fixes

None. No hand-written Lean file under `lean_frontend/`, `test/`, `speclab/` failed to compile or was edited; the
measure proofs re-elaborated unchanged; no `set_option`, linter option or resource limit was touched.

## 5. Builds and the warning census

- OCaml: `dune build backend/driver/main.exe cerberus-lib.install`, the worktree-local `dune install`,
  `dune build cerberus.install`: rc 0.
- Lean root package, all 28 `lean_lib`/`lean_exe` targets of `lakefile.toml`: `Build completed successfully (614
  jobs).` rc 0 (339 `Built` lines: LemLib, the changed generated modules and their dependents).
- speclab, all 13 targets: `Build completed successfully (336 jobs).` rc 0.
- After adding `-DwarningAsError=true`: the root package again, `Build completed successfully (614 jobs).` rc 0,
  all 257 root-package modules recompiled (derived: every module trace under `lib/lean` names the flag); speclab
  `Build completed successfully (336 jobs).` rc 0. Wall time of each pass under two minutes.

Warning census (DERIVED: the `log` entries with `level` = `warning` in the `.trace` files under each package's
`.lake/build`, counted by a script):

| | traces read | warnings | of which |
|---|---|---|---|
| before, root package (the primed build of mainline) | 606 | 911 in 60 modules | 147 inert `termination_by` + 676 unreferenced variable = 823 in 52 modules of the tree; 88 in stale artefacts with no source |
| after, root package + speclab + LemLib | 690 | 0 | — |

Note on the before row: the script's kinds are 147 inert `termination_by`, 682 unreferenced-variable and 82 other
(all under `RelSem`, an unused simp argument); 6 of the 682 sit in stale artefacts (`Core_unstruct` 4,
`RelSem/Kit/Eval` 2), leaving 676. speclab had no build directory before this slice, so its before-count is
unmeasured (0 traces); after, 0 warnings in 83 traces. The 823 join the lem-lean note's 147 + 676.

[AGENT 2026-11-10] The flag is adopted for the root package: the root library, every test executable and library
and every speclab target build clean under it. speclab's own modules are compiled with speclab's `moreLeanArgs`
(unchanged, the charter names the root package only); they carry 0 stored warnings. See §6 for the package the
decision does not cover.

### Stale artefacts deleted (this worktree's `lean_frontend/.lake/build` only, by named path)

Artefacts of modules that have no source in any source directory of the package (`.`, `generated`, `test`,
`test/CoreQuote`), found by a scan and deleted by exact path: the directories `lib/lean/RelSem` and `ir/RelSem`;
the top-level `lib/lean/RelSem.{ilean,ilean.hash,olean,olean.hash,trace}` and `ir/RelSem.{c,c.hash,setup.json}`;
and the 82 files of `Core_unstruct`, `Core_unstruct_auxiliary`, `CerbCoreInstances`, `CerbInhabitedInstances`,
`Unit/AppWalkTest`, `Unit/EmitLeanCore`, `Unit/EmitLeanCoreTest`, `Unit/T4EnvWitnessTest`:

```
ir/CerbCoreInstances.c
ir/CerbCoreInstances.c.hash
ir/CerbCoreInstances.c.o.export
ir/CerbCoreInstances.c.o.export.hash
ir/CerbCoreInstances.c.o.export.trace
ir/CerbCoreInstances.setup.json
ir/CerbInhabitedInstances.c
ir/CerbInhabitedInstances.c.hash
ir/CerbInhabitedInstances.c.o.export
ir/CerbInhabitedInstances.c.o.export.hash
ir/CerbInhabitedInstances.c.o.export.trace
ir/CerbInhabitedInstances.setup.json
ir/Core_unstruct.c
ir/Core_unstruct.c.hash
ir/Core_unstruct.setup.json
ir/Core_unstruct_auxiliary.c
ir/Core_unstruct_auxiliary.c.hash
ir/Core_unstruct_auxiliary.setup.json
ir/Unit/AppWalkTest.c
ir/Unit/AppWalkTest.c.hash
ir/Unit/AppWalkTest.c.o.export
ir/Unit/AppWalkTest.c.o.export.hash
ir/Unit/AppWalkTest.c.o.export.trace
ir/Unit/AppWalkTest.setup.json
ir/Unit/EmitLeanCore.c
ir/Unit/EmitLeanCore.c.hash
ir/Unit/EmitLeanCore.c.o.export
ir/Unit/EmitLeanCore.c.o.export.hash
ir/Unit/EmitLeanCore.c.o.export.trace
ir/Unit/EmitLeanCore.setup.json
ir/Unit/EmitLeanCoreTest.c
ir/Unit/EmitLeanCoreTest.c.hash
ir/Unit/EmitLeanCoreTest.c.o.export
ir/Unit/EmitLeanCoreTest.c.o.export.hash
ir/Unit/EmitLeanCoreTest.c.o.export.trace
ir/Unit/EmitLeanCoreTest.setup.json
ir/Unit/T4EnvWitnessTest.c
ir/Unit/T4EnvWitnessTest.c.hash
ir/Unit/T4EnvWitnessTest.c.o.export
ir/Unit/T4EnvWitnessTest.c.o.export.hash
ir/Unit/T4EnvWitnessTest.c.o.export.trace
ir/Unit/T4EnvWitnessTest.setup.json
lib/lean/CerbCoreInstances.ilean
lib/lean/CerbCoreInstances.ilean.hash
lib/lean/CerbCoreInstances.olean
lib/lean/CerbCoreInstances.olean.hash
lib/lean/CerbCoreInstances.trace
lib/lean/CerbInhabitedInstances.ilean
lib/lean/CerbInhabitedInstances.ilean.hash
lib/lean/CerbInhabitedInstances.olean
lib/lean/CerbInhabitedInstances.olean.hash
lib/lean/CerbInhabitedInstances.trace
lib/lean/Core_unstruct.ilean
lib/lean/Core_unstruct.ilean.hash
lib/lean/Core_unstruct.olean
lib/lean/Core_unstruct.olean.hash
lib/lean/Core_unstruct.trace
lib/lean/Core_unstruct_auxiliary.ilean
lib/lean/Core_unstruct_auxiliary.ilean.hash
lib/lean/Core_unstruct_auxiliary.olean
lib/lean/Core_unstruct_auxiliary.olean.hash
lib/lean/Core_unstruct_auxiliary.trace
lib/lean/Unit/AppWalkTest.ilean
lib/lean/Unit/AppWalkTest.ilean.hash
lib/lean/Unit/AppWalkTest.olean
lib/lean/Unit/AppWalkTest.olean.hash
lib/lean/Unit/AppWalkTest.trace
lib/lean/Unit/EmitLeanCore.ilean
lib/lean/Unit/EmitLeanCore.ilean.hash
lib/lean/Unit/EmitLeanCore.olean
lib/lean/Unit/EmitLeanCore.olean.hash
lib/lean/Unit/EmitLeanCore.trace
lib/lean/Unit/EmitLeanCoreTest.ilean
lib/lean/Unit/EmitLeanCoreTest.ilean.hash
lib/lean/Unit/EmitLeanCoreTest.olean
lib/lean/Unit/EmitLeanCoreTest.olean.hash
lib/lean/Unit/EmitLeanCoreTest.trace
lib/lean/Unit/T4EnvWitnessTest.ilean
lib/lean/Unit/T4EnvWitnessTest.ilean.hash
lib/lean/Unit/T4EnvWitnessTest.olean
lib/lean/Unit/T4EnvWitnessTest.olean.hash
lib/lean/Unit/T4EnvWitnessTest.trace
```

A re-scan finds no orphan. The primary checkout's `.lake` carries the same remnants (this worktree's was a copy);
removing them there follows the landing and is the orchestrator's.

## 6. Finding F1: `tests/mem-scale-probes/micro` does not build (pre-existing; not fixed)

`scripts/ce scripts/capped lake build` in `tests/mem-scale-probes/micro`: **rc 1**. First error, verbatim:

```
error: Micro.lean:85:45: Application type mismatch: The argument
  tagDefs
has type
  CerbTags.TagDefsMap
but is expected to have type
  CerbMem.EnumDefs✝
in the application
  memValueToBytes tagDefs
```

The same shape repeats at `Micro.lean:90`, `:95`, `:115`, `:116` (calls of `reconstructValue`). The errors are
hand-written call sites against hand-written `CerbMem` signatures that take an `EnumDefs` parameter;
`CerbMem.lean` is not modified on this branch, the generated delta contains no signature change (§3), and
`Micro.lean` was last edited at `537641a34` (2026-10-25), before the last commit that touched `EnumDefs` in
`CerbMem.lean` (`bb62d0017`, 2026-10-29). So the package was already broken on the base; the base build was not
re-run to prove it. No ladder row builds this package (`check_pin_sites.sh` reads its manifest only). Its manifest
is re-pinned; its source is left as found: repairing a probe against a changed seam is outside the charter.

## 7. Gates (the last line of each, verbatim; all on the M1 tree with the flag in place unless noted)

`scripts/check_pin_sites.sh --selftest` — rc 0:

```
check_pin_sites: SELFTEST OK (8 plants red with the declared message, unplanted copies green)
```

`scripts/check_pin_sites.sh` — rc 0:

```
check_pin_sites: OK — lem-pin 2220010bc25f0c5682d8200f016e786ee66d65c6 at every site (lakefile rev, 3 lake-manifests rev+inputRev, README pin command)
```

`scripts/check_fork_drift.sh --selftest` — rc 0:

```
check_fork_drift: SELFTEST OK (31 plants with declared verdict/message: S1-S10 prerequisite/locale/name controls; S31 advanced upstream ref (not drift); S11 copied-content control; S12 inside-listed-file drift; S13/S14 duplicate/missing content pins; S15-S30 version forms, full-pin validation and refresh retention; unplanted gate green)
```

`scripts/check_fork_drift.sh` — rc 0:

```
check_fork_drift: OK — layer 1: 96 oracle-surface files = manifest (set, C-locale canonical, no duplicates); layer 2: 33 differing generated files, all hash-pinned (merge-base c3ff8c53f05982745f9b3a10b3d05442e214bcb5; lem-pin 2220010bc25f0c5682d8200f016e786ee66d65c6 matches lem -v lean-backend-v0.1.0-alpha.1-88-g2220010 (hex prefix))
```

`tools/check_handwritten_sync.sh` — rc 0:

```
check_handwritten_sync: OK (57 hand-written files byte-identical to lean_frontend/generated/; manifest lean_frontend/handwritten_copy.manifest)
```

`scripts/check_lakefile_roots.sh --selftest` — rc 0:

```
check_lakefile_roots: SELFTEST OK (4 plants red, baseline green)
```

`scripts/check_lakefile_roots.sh` — rc 0:

```
check_lakefile_roots: OK (228 roots = 228 generated modules + the exe root Main; 86 auxiliary modules listed as roots — names only; every carrier is built by check_fuel_forms.sh)
```

`python3 scripts/gen_fuel_parametricity.py --selftest` — rc 0:

```
gen_fuel_parametricity: SELFTEST OK (6 --check plants + 1 --emit plant with the declared FAIL, both unplanted controls OK, real tree OK)
```

`python3 scripts/gen_fuel_parametricity.py --check` — rc 0:

```
gen_fuel_parametricity: OK (17 ambient fuel wrappers in the generated tree = the 17 pins of TotalityProofTest.lean Part 1, both directions)
```

`scripts/check_theorem_axioms.sh` — rc 0:

```
check_theorem_axioms: OK (effect-retirement C2 bar: zero axiom declarations anywhere; entry cones ⊆ the standard three)
```

`ENFORCE=1 scripts/check_exec_totality.sh` — rc 0:

```
check_exec_totality: CLEAN (22 generated modules + hand-written CerbND, 0 allowlisted)
```

`scripts/check_fuel_forms.sh --selftest` — rc 0:

```
check_fuel_forms: SELFTEST OK (25 plants with the declared label — 6 on the table (incl. the ABSORBING-cone plant), 3 on the hypothesis register, 15 compiled decoys: the C4 four (type True / wrong worker / contradictory hypothesis caught by the register / extra binder), the whole-project audit's two decoys verbatim (review_bad _zero about runNDFuel; review_shift at literal 0), wrong fuel position, swapped worker-side and wrapper-side arguments, changed measure, wrapper calling another worker, hidden premise, and three _zero decoys (a POSITIVE control ABSORBING, a term for a binder, fuel 1) — each rejected with its own message; and the F-1 stale-carrier plant P24 (a stale-valid .olean over a source that no longer compiles: the gate FAILS naming the module); unplanted table green)
```

`scripts/check_fuel_forms.sh` — rc 0:

```
check_fuel_forms: OK (88 fuel'd workers: 67 MEASURED (obligation of the contract's shape incl. argument correspondence against the wrapper's body; every obligation + proof cone ⊆ the standard three; 13 of them under a hypothesis, each = a reviewed row of fuel_hypotheses.txt, both directions), 13 ABSORBING = kill at zero (the _zero lemma is the worker at literal 0 on its own binders = the monad's absorbing element, cone ⊆ the standard three; propagation NOT proved — lem TODO 13), 0 reachable-AMBIENT = the 0 rows of fuel_forms_pending.txt exactly, 8 ambient unreachable from the drive cone)
```

`scripts/check_failure_reach.sh --selftest` — rc 0:

```
check_failure_reach: SELFTEST OK (8 plants with the declared message — a new site in a generated exec-closure definition, a DISCARDABLE dead let-binding, an unsealed class edit, a phantom row, an edited tally, mis-shaped lem_if heads over a registered arm, a mis-shaped lemSeq continuation, a same-owner reach+seal swap (A3) — 7 classifier witnesses (lem_if arms/condition, lemSeq continuation, controls), the key-group witness K1, theorem/worker ownership R1 and the unplanted register green)
```

`scripts/check_failure_reach.sh` — rc 0:

```
check_failure_reach: OK (235 pure failure sites = the 235 register rows exactly (233 in the exec dependency closure + 2 unresolved-owner; key = file/owner/token/message, shared keys lengthened, both directions); position classes unchanged; 0 DISCARDABLE; reach UNREACHABLE-BY-INVARIANT=174 REACHABLE=40 UNKNOWN=21; every row sealed; tally line consistent)
```

`scripts/libc_prep.sh --check` — rc 0:

```
libc_prep: census OK (libc_inner_arg_temps: 192 transported procs/funs; 6 shared bare names in 5 procs = the register; a speedbump on the printed spelling, not transport fidelity)
```

`scripts/test_unit.sh core-quote-test` — rc 0 (1327 s; the script runs the selected executable and then the whole
row-1 gate tail, which passed):

```
CORE_QUOTE_TOTAL inputs=28; model constructors=219; floating=0; NaN=0; memory-values=0; positions=8514197; absolute-paths=0
Core quote round trip: PASS (whole-file representation, comparator syntax, auxiliary BEq)
✓ core-quote-test PASSED
Total: 1 passed, 0 failed
```

Notes. The fork-drift gate's layer-2 rows did not move (33 differing generated OCaml files, all hash-pinned: the
OCaml is identical) and no `[source-content]`/`[expected-semantic]` row was edited. The failure-reach register did
not need re-keying: its key is file/owner/token/message, and the 235 rows matched as recorded. The pin-site,
drift, sync, roots and fuel-pin gates ran before the flag was added and are independent of it; `check_fork_drift.sh`
was re-run after M2 (rc 0).

## 8. Kernel replay (named trust gate)

From `lean_frontend/`, `scripts/ce scripts/capped lake env leanchecker <modules>`; leanchecker prints nothing on
success.

- The owed set, 30 modules — `AilTypesAux_lemMeasureProofs CerberusImpl_lemMeasureProofs CerbMem_lemMeasureProofs
  Core_aux_lemMeasureProofs Core_eval_lemMeasureProofs Core_lemMeasureProofs Core_reduction_lemMeasureProofs
  Core_run_aux_lemMeasureProofs Ctype_aux_lemMeasureProofs Ctype_lemMeasureProofs
  Defacto_memory_aux_lemMeasureProofs Defacto_memory_lemMeasureProofs Driver_lemMeasureProofs
  Formatted_lemMeasureProofs Monadic_parsing_lemMeasureProofs Translation_lemMeasureProofs Utils_lemMeasureProofs`
  (all 17), the proof seams `CerbParserProgress CerbCoreShape CerbCoreMeasure CerbCtypeMeasure CerbMeasureLemmas
  CerbFailProofs CerbNDFuelProofs CerbMemAllocatorProofs CerbTagsWf`, `CerbMemAccessFacts CerbMemDefaultFacts`,
  `Unit.MemoryAccessProofs`, the exemplar `Unit.FuelExemplar`: **`leanchecker exit=0`** (16 s).
- Beyond the owed set, 138 modules — the 52 changed generated modules (§3's table) and the 86 `*_auxiliary`
  obligation carriers: **`leanchecker exit=0`** (78 s).

Both ran after the rebuild under `-DwarningAsError=true` (§5), i.e. on the `.olean` files of the M1 tree as
committed.

### The Core quotation digests: none moves (measured)

Row 1's `core-quote-test` (§7) pins no digest; the two committed SHA-256 pins belong to the Tier B leg, which was
run for this question: `scripts/test_unit.sh --core-quote-libc` — rc 0 (732 s), on the M2 tree:

```
libc sha256: 0a845b19bf8cde9762b89d3975abd709a2b8107cb0ab27c51732bc93611cd41c
Core quote round trip: PASS (whole-file representation, comparator syntax, auxiliary BEq)
✓ core-quote-test PASSED
libc sha256: addb1648a4d131fa73f9f8efa3ca926185884ce7591a287c0663a9b1139ae2d6
Core quote round trip: PASS (whole-file representation, comparator syntax, auxiliary BEq)
✓ core-quote-test (inner_arg_temps) PASSED
Total: 2 passed, 0 failed
```

Both values equal the committed `test/CoreQuote/core-quote-libc.sha256` and
`core-quote-libc-inner-arg-temps.sha256`; the leg's six literal replays (`LibcLiteral`, `LinkedLiteral`,
`LinkedRichLiteral` in each convention) report `leanchecker … exit 0`. Why nothing moves: a digest is over the
quoted literal, a Core term written as applications of the model's constructors to data; this re-pin renames
binders inside generated definitions and removes inert clauses, and changes no constructor, field or type name
and no libc Core text.


## 9. The lane rider (M2)

`scripts/inner_arg_temps_lane.py`: the baseline projection (`baseline_side`, `baseline_class`, `status_hash`,
`baseline_row`) spells a resource outcome at the memory cap and one at the wall clock as one pinned outcome,
`KILL|TIMEOUT`, in the row class, the Normal controls' class and every pinned side hash; recording and checking
both go through it; `check_baseline` refuses a baseline that still pins the kind. [AGENT 2026-11-10] The direction
(oracle versus Lean) stays pinned and FUEL stays its own kind (deterministic). The row line and `results.json`
keep the observed kind. The selftest gained two plant groups, run through the real comparator.

Re-recorded through `--record-baseline` (188 rows, 375 s); the baseline diff is two rows, nothing else:
`corpus/p07_list_sum` and `corpus/p08_list_reverse`, class `RESOURCE oracle:KILL` → `RESOURCE oracle:KILL|TIMEOUT`,
the four hashes of each `8aae6f4ef8b6` → `082663a812d6`.

`./scripts/test_inner_arg_temps.sh --gate` — rc 0 (384 s):

```
SUMMARY: inner_arg_temps rows=5 AGREE=3 AGREE-FIRST=1 BOTH_FAIL=1 failures=0
BASELINE OK (inner_arg_temps: 5 rows; classes and both distinct-observation/status hashes exact)
BASELINE OK (inner_arg_temps: 1 rows; classes and both distinct-observation/status hashes exact)
BASELINE OK (inner_arg_temps: 1 rows; classes and both distinct-observation/status hashes exact)
BASELINE OK (inner_arg_temps: 1 rows; classes and both distinct-observation/status hashes exact)
PLANT OK (baseline resource kind: a row recorded at the memory cap accepts the wall clock on either engine and on the Normal controls)
PLANT OK (baseline resource kind: FUEL, a Lean-only resource outcome and a completed row rejected; a kind-pinning baseline rejected)
SELFTEST OK (control; both stripped-switch stubs; Normal-only main/libc mutations; both dump/mode plants; both binder plants; printer collision; sequence/set controls; five baseline plants; the resource-kind plants; outcome failures)
SUMMARY: inner_arg_temps rows=188 AGREE=138 AGREE-FIRST=41 BOTH_FAIL=5 LOC_ONLY-FIRST=2 RESOURCE oracle:KILL=2 failures=0
BASELINE OK (inner_arg_temps: 188 rows; classes and both distinct-observation/status hashes exact)
inner_arg_temps elapsed: 363.74s
```

F2: the first standalone `--selftest` (14 s, before the re-record) exited 1 with `inner_arg_temps: FAIL —
corpus/p07_list_sum: the baseline pins a load-dependent resource kind (RESOURCE oracle:KILL); re-record it` — the
new refusal acting on the old baseline. After the re-record the standalone `--selftest` is rc 0. Not exercised: a
row actually hitting the wall clock first (the flake was not reproduced; the plants cover the comparison).
LADDER row 15 and VALIDATION's lane paragraph state the rule.

## 10. For the orchestrator

- **lem-lean TODO row (not this repository's to write):** GNU make prints two recipe-override warnings while
  building lem, at `Makefile:10` and `ocamlbuild.mk:20` (lem-lean
  `doc/lean-backend/2026-11-07_unreferenced-binders-premerge-review.md` line 176 names them). This worker ran no
  lem build, so they are not in this slice's logs; they are listed here for the lem-lean TODO as the charter asks.
- The container doc's pin line (`e6d8db5` → `2220010`) is the orchestrator's.
- At the landing, the primary checkout's stale `.lake` artefacts (§5's list) and its regeneration.
- F3, stale prose left as found: `lean_frontend/README.md:8` and `lean_frontend/SUPPORTED.md:4` describe
  `2d3a492` as the current pin; LADDER row 15 opens with 186 rows where the lane runs and pins 188.
- F1 (§6) wants a decision: repair `Micro.lean`, or retire the package and its pin site.
- Consumer notes: `docs/2026-11-10_consumer-note-cerberus-{sl,caesium}-unreferenced-binders.md`.

## 11. Not done

- `scripts/release.py` in any mode (Tier A on M1 and the battery on the tip are the orchestrator's); no Tier A/B
  lane beyond the gates listed here; `lake check`.
- No opam command, no push, no mainline commit, nothing outside this worktree.
- The base tree was not rebuilt with the old lem (§2) and the micro package's breakage on the base was inferred
  from history, not re-run (§6).
- No pre-merge review of this slice has been run.
