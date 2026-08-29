# 2026-08-31 — the semantics-first split (branch `core/semantics-first`)

Operator-ratified separation [USER 2026-08-31]: the reasoning/proof
layer is PARKED (branch `arc/segment-ladder`, tag
`park/reasoning-era-20260831` — the complete record lives there,
untouched); this branch presents ONE thing — a well-presented,
differentially-validated executable Core semantics in Lean. Base:
the park head `39f3a64a4` (all semantics improvements kept, incl.
the threadB totalization). Executed by the semantics-first worker
[AGENT]; classification rule applied throughout: anything the
semantics binaries or differential test lanes consume STAYS;
anything that exists to state or prove theorems GOES (deletion here;
the park branch already holds it).

Commits: `d864b6714` (C1 strip), `bf6a051b5` (C2 test_verify
re-base), `f4a4baf21` (C3 docs pass), this record (C4).

## 1. Removed vs kept — module level

### Removed (theorem-facing)

| Artifact | Disposition |
|---|---|
| `lean_frontend/relsem/` (entire Lake package: RelSem lib incl. Kit/, RoundEval/, CerbState*, Segment*, PerStep*, T1–T5/M1/Corpus statements+proofs, Audit gates; test exes `emit-lean-core-test`, `t4-env-witness`; its lakefile/manifest) | deleted (C1) |
| `relsemcore/RelSem/Threaded.lean` (threaded statement faces) | deleted (C1) |
| `relsemcore/RelSem/Call.lean` statement block: `callConfig`, `CallReaches`, `CallAdequate`, `CallUBFree`, `CallHarnessAdequate`, `CallHarnessUBFree`, `ofStatus_value_inv` (consumed only by the deleted statements) | deleted from the file; `callND` + injection stages (the `--call` engine Main consumes) stay |
| speclab `SpecLabAudit.lean`, `proofs/SpecLabProofs.lean` | deleted (C1); lakefile default targets and the relsem path-require dropped |
| speclab `SpecLab/*Files.lean` statement sections: `HarnessFinalAllocs`, the `*FileOfStream_encode` bridge theorems, the `import RelSem.Threaded` + `open RelSem.Cerb (…Thr…)` lines, statement-section commentary | deleted; the FILE-ASSEMBLY defs (`*FileU`, `*File`, `*FileOf`, `*FileOfStream`, `byteToInt`, `wireBytes`, `driverBaseline`) stay — measured consumers: the `speclab-*core-test` gate exes the `--gate` lanes run |
| root lakefile requires `iris`, `Qq`, `batteries` | dropped — measured zero imports anywhere in the semantics package; manifests pruned to `LemLib` (+ `CerberusLean` path in speclab) |
| root `emit-lean-core` exe + `test/Unit/EmitLeanCore{,Main}.lean` (regenerated relsem `T1Core.lean` only) | deleted (speclab's `SLUnit.EmitCore` is its own attributed adaptation and stays) |
| Gate scripts: `check_one_route.sh`, `check_engine_size.sh` (+ `engine_size_baseline.txt`), `check_speclab_statements.sh`, `check_proof_size.sh` (proof legs), `perf_timing_lane.sh`, `core_shape_census.sh` | deleted; every runner row removed in the same commit (§2) |
| `docs/reasoning-era/` (39 files) + 79 reasoning-arc records (arcs 7/9/11/16/17/18 complete, iris/lithium surveys, harness-statement template + registers, target-corpus statement docs, V0–V3 + perf records, kill-list, chase post-mortem, assessments, wireguard scoping, cn-comparison, tree worked example, relsem spike, concurrency-survey) | deleted (park-only) |
| `PROOF.md` | deleted; replaced by `VALIDATION.md` (§4) |

### Kept (the product)

| Artifact | Note |
|---|---|
| The entire Lean port pipeline: `generated/` (incl. the threadB-totalized tree), all `Cerb*` seams, `CabsImport`, `CoreParser`, `CerbND`, `Main`, `native/`, the driver exe | untouched |
| `relsemcore/RelSem/{Call,Machine,RunND,ExecModel,Cerberus}.lean` (the `RelSemCore` lib) | KEEP per scoping (exec-facing: Main imports `RelSem.Call`). NOTE (honest residue): Machine/RunND/Cerberus retain the relational exec model, the proved runner-soundness theorems, and some Prop-valued adequacy statement SHAPES + arc-era comments — kept as the module-level KEEP call; a future polish pass may trim the unused Prop shapes |
| speclab `SpecLab/{Codec,MkHarness}.lean`, the five model modules, `*Harness.lean` templates, `*Core.lean` generated terms, `*Files.lean` file-assembly defs, `test/` emit + gate exes | the differential lanes' machinery; model/codec round-trip lemmas kept (pure-model self-validation, no driver vocabulary) |
| `corpus/` (16 files) | RE-ROLED as differential test fixtures ([USER] ruling); README rewritten; freeze language replaced by fixture-set integrity (§2 fixture-freeze gate); `tests/corpus` pins + expectation rows stay |
| All semantics gates: sync, lem-sync, fork-drift, exec-purity, exec-totality, axiom censuses + cones + D14 + unsafeCast ban (`check_theorem_axioms.sh`, D14 scan re-pointed at `relsemcore/`) | green (§5) |
| All differential lanes: exec (minimal/coverage/debug/float), bytes, core, parse, elab, multi_tu, libc_exec, libxml2 + uri, cn_coverage, immaculate, csmith, ci-sweep, verify, the 6 speclab scripts | green (§5); csmith/ci-sweep at reporting tier |
| Semantics docs history (78 records): arcs 1–6/8/10/12–14, arc-15 lane charter + rung records + results, ci-sweep, libc diagnosis, renumbering case, axiom endgame, threadB totalization, CN-0 exporter, inhabited archaeology, CLAUDE.md pre-prune archive | kept |

## 2. Gate-list edits (each an explicit edit, same commit as its deletion)

`scripts/test_unit.sh` (C1): the relsem in-build-audit build block
REMOVED; `emit-lean-core-test` + the `RELSEM_TESTS` machinery
REMOVED; the proof-size row REPLACED by the fixture-freeze row
(`check_proof_size.sh` → `check_fixture_freeze.sh`, keeping only the
corpus hash + name-set legs — the proof-file line/step bars, Kit
fixture-free counter, and debug-surface bans left with the proof
package); the single-interpretation (one-route) and engine-size rows
REMOVED with their scripts. Remaining slimmed gate list, in order:
5 unit exes → exec-purity → theorem-axiom censuses/cones →
exec-totality → lem-sync → fork-drift → fixture-freeze. No gate
silently skipped: every deleted gate's runner row was removed in the
deleting commit.

Speclab lane scripts (C1): the `check_speclab_statements.sh`
invocation removed from all six `test_speclab*.sh` scripts (the
statement-TCB gate guarded a statement surface that no longer
exists); the differential substance of every lane is unchanged.

`scripts/test_verify.sh` (C1): the `t4-env-witness` probe block
removed (a relsem exe).

`scripts/LADDER.md` (C3): Tier A row 1 updated to the slimmed list;
Tier B rows added for `test_verify.sh`, `test_immaculate.sh`, and
the speclab gate lanes.

## 3. The test_verify re-base (C2)

The expectations rows (`tests/verify/expectations.txt`,
`tests/corpus/expectations.txt`) formerly compared the Lean `--call`
verdict against recorded theorem-spec values ("the SPEC the theorems
quantify"). Re-based to pure oracle-differential: for each row the
script renders a wrapper TU — the fixture with `main`
preprocessor-renamed (`#define main cerb_fixture_main_` before
inclusion) plus a fresh `main` returning `f(args)` — runs it through
the oracle main-mode, and requires Lean-`--call` == oracle == the
recorded pin (pin role: drift detection with provenance recorded in
the expectations headers). Fail-closed: a wrapper the oracle cannot
run yields no verdict and FAILS the row. Plant-tested: corrupting
the `t1_id id 5` pin to `Specified(6)` went red loudly
(`pin Specified(6), lean Specified(5), oracle Specified(5)`), then
reverted and re-verified green.

## 4. Docs rewritten (C3)

`README.md` (semantics-port presentation + headline numbers),
`DESIGN.md` (effects/totality re-based; §6 package structure; §8
pointers), `PROOF.md` → deleted, `VALIDATION.md` → new (what is
compared / against what / how often / gate guarantees / what is and
is not established), `TODO.md` (semantics-only backlog),
`lean_frontend/CLAUDE.md` (operational map, build, unit tests, gate
list, status pointers made current), `corpus/README.md` (fixture-set
role), `speclab/README.md` (differential-lane package), root
`README.md`/`CLAUDE.md` pointers.

## 5. Validation — the full battery (this tree, run serially, exit 0 each)

(Verbatim summary lines from the logged runs in the container's
`.core-split-logs/`; derived tallies labeled as such.)

`test_unit.sh` (5/5 exes: effects-proof, totality-proof, core-parser,
fresh-int, pp; then the gates):

```
Total: 5 passed, 0 failed
check_exec_purity: CLEAN (11 modules)
check_theorem_axioms: hand-written axiom census OK (0 axioms — the arc-17 S2b end state)
check_theorem_axioms: generated-tree census OK (195 files: 0 axioms, boundary opaques present, 0 unsafeCast)
check_theorem_axioms: D14 grep-ban OK (no native_decide/bv_decide in 2 tree(s) + LemLibTest.lean)
check_theorem_axioms: OK (arc-8 S3 bar: DAEMON-free cones everywhere)
check_exec_totality: CLEAN (20 generated modules + hand-written CerbND, 0 allowlisted)
check_lem_sync: OK (src 9105135ef8a9f41cf7aafc398407a341194cc458f81b393407c4cb5ddd698cdc, gen 50b87c916a110d01d86b05580aafda8f78761a614ac4305d963541758bf31029)
check_fork_drift: OK — layer 1: 63 oracle-surface files = manifest; layer 2: 20 differing generated files, all hash-pinned (merge-base b9aeedcb4dd438763b0eef7f95ac19e93875d7de)
check_fixture_freeze: OK (16 fixture files match the pinned manifest; name set exact)
```

Differential lanes (each exit 0; one verbatim summary line each):

```
test_exec --check-baseline (tests/minimal):   Baseline check: 0 regression(s), 0 improvement(s) / BASELINE OK
test_exec (coverage baseline):                Baseline check: 0 regression(s), 0 improvement(s) / BASELINE OK
test_exec (debug baseline):                   Baseline check: 0 regression(s), 0 improvement(s) / BASELINE OK   [after the compat-04 re-record, commit acf65b54c — §6.7]
test_exec (float baseline):                   Baseline check: 0 regression(s), 0 improvement(s) / BASELINE OK
test_bytes:                                   SUMMARY: exec_match=9 neg_pinned=5 fail=0 / ALL AT COMMITTED EXPECTEDS
test_libc_exec:                               SUMMARY: match=7 diff=0 / ALL MATCH RECORDED BASELINE
test_multi_tu:                                SUMMARY: total=2 match=2 fail=0 / ALL PASSED
test_parse (tests/minimal):                   Success rate:   100% (of cerberus successes) / ALL PASSED
test_core (tests/minimal):                    Success rate:   100% (of cerberus successes) / ALL PASSED
test_elab:                                    SUMMARY: total=106 same=103 diff=3 ocaml_fail=0 lean_fail=0   [the 3 diff are the recorded state]
test_libxml2_uri:                             GATE PASS: all lane expectations pinned-green + baseline unchanged (16/16)
test_cn_coverage --check-baseline:            BASELINE OK (213 entries, exact match)
test_immaculate:                              OK: lane matches the committed post-S1 baseline (mostly MATCH; the intended non-MATCH rows: g5-decode-question ORACLE_CRASH/L=63 and g5-escape-roundtrip DIFF/L=127 are oracle-wrong — upstream-tray #10/#11 — and g6 is TRIPWIRE).
test_verify:                                  test_verify: 117 passed, 0 failed (23 fixtures, 22 call points, 14 corpus fixtures, 21 corpus points)
test_speclab --selftest:                      test_speclab: PASS (both pipelines agree on Specified(0))
test_speclab --plant:                         test_speclab: PASS (both pipelines agree on Specified(2))
test_speclab_divmod --gate:                   test_speclab_divmod: PASS (--gate)
test_speclab_bytearr --gate:                  test_speclab_bytearr: PASS (--gate)
test_speclab_list --gate:                     test_speclab_list: PASS (--gate)
test_speclab_tree --gate:                     test_speclab_tree: PASS (--gate)
test_speclab_seed --gate:                     test_speclab_seed: PASS (--gate)
test_csmith_corpus --check-baseline --shard 1/6:  SUMMARY: total=279 match=127 ub_match=0 ub_diff=0 mismatch=0 fail=0 crash=0 lean_error=0 timeout=1 cerb_skip=151 cerb_floor=0 cerb_inconsistent=0 / Baseline check: 0 regression(s), 0 improvement(s) / BASELINE OK
```

(The left-hand labels and the `/`-joined pairing are derived
formatting; each quoted fragment is verbatim from the logs in the
container's `.core-split-logs/final_*.log`. csmith ran as one full
shard — the LADDER's sanctioned spot-shard form for a
reporting-tier lane; the ~2.7 h full pass was not run at this slice
[runtime]. The ci-sweep reporting instrument was likewise not
re-run; its recorded state is unchanged by this branch.)

## 6. Adjudications under the classification rule

1. **`RelSemCore` internals kept whole.** Scoping named
   Call/Machine/RunND/ExecModel as KEEP; Cerberus.lean rode along as
   part of the measured exec closure. Their internal
   runner-soundness theorems and unused Prop statement shapes remain
   (noted above) — module-level keep beat declaration-level surgery
   everywhere except Call.lean, whose statement block was severed
   cleanly because nothing imports it.
2. **speclab `*Files.lean` split, not deleted.** The lanes' `--gate`
   exes execute the file-assembly defs (discovered by build
   breakage, confirmed by imports), so the files stay minus their
   statement sections — "exactly what the differential lanes need".
3. **Model/codec lemmas kept.** `Codec.lean` round-trips and the
   pure model lemmas validate the lanes' triangulation models and
   mention no driver/state vocabulary; deleting them would degrade
   the lanes' honesty, not the statement layer.
4. **`check_theorem_axioms.sh` keeps its name** (references
   everywhere; its content is semantics-side: censuses + cones +
   D14) — renaming was judged churn without information.
5. **Docs doubt-rule.** Arc-15 rung records kept (they document the
   standing lanes' construction + differential campaigns); the
   registers/templates/worked-example deleted (statement doctrine).
   Arc-8 kept (backend axiom-trust history); arc-17 S2b axiom-endgame
   kept (cited by the live gate).
6. **Worktree staleness remediation (pre-existing).** The first
   test_unit run failed exec-totality: the worktree's `generated/`
   trees were stale vs the threadB `.lem` totalization (commit
   `ee02f3031`). Remediated per the lem-sync recipe
   (`clean-prelude-src prelude-src` + `lean-prelude-src` + oracle
   rebuild) before any green claim; not caused by the split.
7. **Debug-lane movement surfaced and re-recorded.** With the fresh
   trees, `compat-04-funcptr-enum-int.c` moved DIFF → UB_MATCH — the
   threadB `are_compatible` totalization's behavioral fix, masked at
   threadB time by the stale tree. Re-recorded in a dedicated
   baseline commit (`acf65b54c`) with justification in the baseline
   header; lane re-run clean.

The record ends the slice.
