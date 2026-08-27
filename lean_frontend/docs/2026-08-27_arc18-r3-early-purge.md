# Arc-18 R3 — THE EARLY PURGE (slice record)

STATUS: R3 CLOSED at this record (park-ends-slice; the record is the
stop signal). Worker slice of the segment ladder (charter:
`docs/2026-08-26_arc18-segment-ladder-charter.md`, rung R3, scope
deflated by [F2]), branch `arc/segment-ladder`, base `86dcd5ce1`.
Provenance: [AGENT] worker build throughout; the [F2] scoping rule —
delete ONLY zero-importer retirement-register entries, determined by
a FRESH import scan of the current tree — was followed exactly. The
zero-importer set turned out TINY (three files); per the brief, a
tiny honest slice is the correct outcome and scope was not inflated.

## 1. The import scan (re-derived on this tree, 2026-08-27 [AGENT])

Method: the retirement register was enumerated from the contracts doc
§7 (`docs/2026-08-25_reasoning-layer-contracts.md`) PLUS the one-route
gate's retirement-register allowlist (`scripts/check_one_route.sh`
OWNP_ALLOWED). For every entry surface, the transitive importer set
was computed by grep over all `import` lines in
`relsem/`/`relsemcore/`/`speclab/` (excluding `.lake`), plus lakefile
roots/exes, test exes, and gate scripts referencing the file by name.
REGISTRATIONS (RelSemAll aggregator imports, lakefile roots, Audit
sweep-closure imports with no consumed declarations, gate allowlists,
pin lists) were counted as re-registration obligations, NOT importers;
Audit imports that PIN theorems from a file (standing capability) or
drive an in-build gate WERE counted as live importers.

## 2. DELETED (the zero-importer set; one commit, same-commit
      re-registrations)

| File | Register entry | Importer evidence (zero) |
|---|---|---|
| `relsem/bench/WalkBench.lean` | Entry 3 (chase corpus; the arc-11 §12.2 metrics bench) | Imported by NOTHING; not a lakefile root or exe (never compiled by any build target); only references were the chase-freeze ALLOWLIST entry (a registration) and a policy comment in `check_proof_size.sh` |
| `relsem/test/Unit/T5ProbeMain.lean` + the `t5-probe` `[[lean_exe]]` | Entry 3 (named explicitly: "the `t5-probe` exe") | Imported by nothing; no gate script builds or runs it (grep over `scripts/` + `lean_frontend/scripts/`: only the lakefile block); run-on-demand instrument, arc-9 era |
| `relsem/RelSem/IrisCoupling.lean` | One-route OWNP_ALLOWED register surface (arc-7 paper-only coupling sketch, SUPERSEDED banner since arc-7 S4; 1 marker decl `paperOnly`) | Only import sites: `RelSemAll.lean:13` (aggregator registration) and `Audit.lean:125` (sweep-closure registration — Audit consumes ZERO declarations from it; grep `paperOnly` in Audit = 0). All other mentions are comments (IrisLang, relsemcore Machine/ExecModel/Cerberus) |

No deleted file carried any `@[app_eq]`/`@[step_law]`/`@[seg_*]`
attribute (grep-verified before deletion) — no equation supply was
re-homed because none lived in the deleted files. Orphaned `.lake`
build artifacts of `IrisCoupling` were deleted from BOTH package
trees (stale-shadow doctrine; WalkBench/T5ProbeMain had none).

## 3. Gate re-registrations (same commit as the deletions)

- `relsem/lakefile.toml`: `RelSem.IrisCoupling` removed from the lib
  roots; the `t5-probe` `[[lean_exe]]` block removed (tombstone
  comments point here).
- `relsem/RelSemAll.lean`: the IrisCoupling import removed (tombstone
  comment).
- `relsem/RelSem/Audit.lean`: the IrisCoupling sweep-closure import
  removed; audit sweep RE-PINNED 8404 → 8403 with provenance line
  (the one paper-only marker decl leaves the closure).
- `scripts/check_one_route.sh`: `IrisCoupling.lean` removed from
  OWNP_ALLOWED (tombstone comment in place).
- `scripts/check_chase_freeze.sh`: `WalkBench.lean` removed from the
  legacy ALLOWLIST (8 → 7 files); header inventory comment updated.
- `scripts/check_proof_size.sh`: the scan-surface policy comment's
  `relsem/bench/` exclusion note updated (directory gone).
- `lean_frontend/CLAUDE.md`: the `t5-probe` operating-manual
  parenthetical replaced with the deletion note.
- Stale comment pointers to the deleted IrisCoupling fixed in the
  LIVE relsemcore modules (`Machine.lean`, `ExecModel.lean`,
  `Cerberus.lean` — now cite the arc-7 S4 record /
  the realized CerbMemInterp). The remaining mention inside
  `IrisLang.lean`'s banner was deliberately left: IrisLang is itself
  register entry 1 and deletes at R7.

## 4. KEPT LIVE (the importer table — this is R7's work order)

| Register surface | Live importers (grep evidence, this tree) | Retires at |
|---|---|---|
| `IrisLang.lean` | `IrisState.lean:17`; Audit pins | R7 (entry 1) |
| `IrisState.lean` | `IrisRules.lean:25` | R7 (entry 1) |
| `IrisRules.lean` | `IrisAdequacy.lean:31` | R7 (entry 1) |
| `IrisAdequacy.lean` | `SlateWP.lean:20`, `T1.lean:31` | R7 (entry 1) |
| `SlateWP.lean` | `T2.lean:25`, `T3.lean:19`, `T4.lean:51` | R7 (entry 1) |
| `PerStepOwnP.lean` | `IrisState.lean:18`, `PerStepSmoke.lean:30`, `PerStepTacSmoke.lean:32` | R7 (entry 1/4) |
| `PerStepRunner.lean` | `Audit.lean:168` — the in-build gate PINS the runner-algebra cones (a live consumer, per brief) | R7 sweep |
| `Tactics/AppWalk.lean` | `T1AppEq.lean:35`, `T5Prefix.lean:27`, `test/Unit/AppWalkTest.lean:25` (the app-walk-test gate exe) | R7 (entry 3) |
| `Tactics/WalkTrace.lean` | `Tactics/AppWalk.lean:51` | R7 (entry 3) |
| `Tactics/AppEqAttr.lean` | LIVE-ROUTE Kit modules: `Kit/AppEq.lean:17`, `Kit/Eval.lean:21`, `Kit/Map.lean:28`, `Kit/Mem.lean:21`, `Kit/Round.lean:40` | C1-registry disposition (evolve-vs-delete) |
| `T1AppEq.lean` | `T4Threaded.lean:33` (LIVE flagship), `T2AppEq.lean:29`, `T3AppEq.lean:32`, `T4Defs.lean:37`, `T5Fixture.lean:18`, `PerStepSmoke.lean:32` | R4/R5/R7 (per brief) |
| `T2AppEq.lean` | `T2.lean:26`, `T3AppEq.lean:33`, `T4Defs.lean:38`; Audit pins | R5/R7 |
| `T3AppEq.lean` | `T3.lean:20`, `T4Defs.lean:39` | R5/R7 |
| `T4AppEq.lean` | `T4.lean:52` | R5/R7 |
| `T5Fixture.lean` | `T5Prefix.lean:22` | R4 |
| `T5Prefix.lean` | `T5Iter.lean:17` (WalkBench importer now gone) | R4 |
| `T5Iter.lean` | `Audit.lean:151` — pins the STANDING T5 flagships (entry walk + env-lookup family; the ambient T5-prefix capability stands until R4 lands T5 through the layer) | R4 |
| `test/Unit/AppWalkTest.lean` | the `app-walk-test` exe, run by `scripts/test_unit.sh` (a gate) | R7 (entry 3) |
| Ambient family (T1/T2/T3/T4/T4Defs, PerStepSmoke, PerStepTacSmoke, ambient Call faces, speclab ambient substrate) | Excluded from R3 BY CHARTER ("Ambient family NOT here — waits on R5"); importers anyway: the Threaded flagships (`T1Threaded.lean:39`, `T2Threaded.lean:26`, `T3Threaded.lean:25`, `T4Threaded.lean:34`), the 112-carrier pin, the statement gate | R5 → R7 |

## 5. Census movements

- Audit sweep: 8404 → 8403 (IrisCoupling's `paperOnly`; provenance
  comment at the pin).
- Law registry census: UNCHANGED (105 laws; no deleted file carried a
  registered law).
- Engine-size baseline: UNCHANGED (no engine file touched).
- Chase-freeze allowlist: 8 → 7 files present.
- one-route OWNP allowlist: 17 → 16 entries.
- Statement texts: UNTOUCHED (statement gate + EmitLeanCore drift
  gate green below).
- FF-3 (engine-size re-baseline ≤R3): engine size did not move this
  slice; the R2-close re-baseline 6533 with provenance stands — the
  fix-forward's "re-baseline with provenance" was satisfied at R2
  close (recorded here for the register).

## 6. Plant tests (both red, then removed; gates green on the clean
      tree in the final battery)

- chase-freeze: a re-added `relsem/bench/WalkBench.lean` importing
  `RelSem.Tactics.AppWalk` + using `app_walk_rec` → gate FAILED
  (exit 1), both the import and the token reported, non-allowlisted.
- one-route: a re-added `relsem/RelSem/IrisCoupling.lean` binding
  `[CerbGS ...]`/`CerbGpreS` → gate FAILED (exit 1): "NEW
  OwnP-binding file outside the retirement register + labeled
  exemption".

## 7. Validation (verbatim gate lines, final battery)

Full Tier A at the closing tree: `./scripts/test_unit.sh` exit 0,
`./scripts/test_verify.sh` exit 0, both speclab gate lanes exit 0.
All lines below VERBATIM from the run logs (the test_unit capture kept
the last 60 lines; the earlier per-exe ✓ lines and the sync-gate line
were cut by that window — the fail-closed script's exit 0 and the
"Total" line cover them; this note is the honest label):

```
Total: 7 passed, 0 failed
check_exec_purity: CLEAN (11 modules)
check_theorem_axioms: hand-written axiom census OK (0 axioms — the arc-17 S2b end state)
check_theorem_axioms: generated-tree census OK (195 files: 0 axioms, boundary opaques present, 0 unsafeCast)
check_theorem_axioms: D14 grep-ban OK (no native_decide/bv_decide in 2 tree(s) + LemLibTest.lean)
check_theorem_axioms: OK (arc-8 S3 bar: DAEMON-free cones everywhere)
check_exec_totality: CLEAN (16 generated modules + hand-written CerbND, 0 allowlisted)
check_lem_sync: OK (src e51f885203ccdb8e83aa379e7e1ff3372598759c5b8e216ded6554f0d6181105, gen 50b87c916a110d01d86b05580aafda8f78761a614ac4305d963541758bf31029)
check_fork_drift: OK — layer 1: 59 oracle-surface files = manifest; layer 2: 20 differing generated files, all hash-pinned (merge-base b9aeedcb4dd438763b0eef7f95ac19e93875d7de)
check_proof_size: T7.lean — 249 lines (bar 250), 19 manual steps (bar 40)
check_proof_size: OK
check_chase_freeze: OK — no chase-surface imports/uses outside the legacy allowlist (7/7 allowlisted files present)
check_one_route: OK — one state interpretation on the live route (40 modules OwnP-free; coexistence hazard clear; OwnP binders confined to the retirement register)
check_engine_size: engine total 6533 lines (baseline 6533)
check_engine_size: OK (reporting instrument; enforcement lives in the R3 register row)
test_verify: 41 passed, 0 failed (7 fixtures, 26 harness points)
test_speclab_divmod: PASS (--gate)
test_speclab_seed: PASS (--gate)
```

From the relsem `lake build` log of the same tree (the in-build audit;
the 8403 sweep pin is a `#guard_msgs` — a wrong count fails the
build, which completed green):

```
info: RelSem/Audit.lean:659:0: RelSem statement gate: 29 slate statements fuel-opsem-clean (negative tests: t1_wp and the wrapper-hole probe correctly rejected)
info: RelSem/Audit.lean:1217:0: runEffectful no-cone gate: carrier set exact (112 registered ambient-family theorems; no acquisition, no stale entries)
Build completed successfully (406 jobs).
```

Derived tally (LABELED): 7/7 unit executables + every gate script OK;
statement texts untouched (EmitLeanCore drift gate inside the 7/7);
carrier pin unchanged at 112; statement slate unchanged at 29.

## 8. Commit

- (this commit) — the three deletions + every re-registration +
  plant-tested gates + this record, one coherent commit on green
  Tier A.
