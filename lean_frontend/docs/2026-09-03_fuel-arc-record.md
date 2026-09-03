# FUEL arc — implementation record

Date: 2026-09-03. Branch `arc/fuel` (rebased onto mainline `72164481a`;
design note commits a0ff26ea9..35f23b745). Governing document:
`docs/2026-09-02_fuel-arc-design.md` (R3; Option C [USER 2026-09-02]).
Consumer manifest: `docs/2026-09-03_fuel-arc-change-manifest.md`. Worker:
[AGENT] implementation worker; every decision below is [AGENT] unless
marked, and every quoted output is verbatim (derived tallies are labelled).

Rulings received during the slice (provenance verbatim, relayed by the
orchestrator):

- [USER 2026-09-03] "fuel is a reasonable exception because we could
  always just run the semantics with more fuel." Frame: all Lean-vs-
  oracle execution discrepancies are bugs, with exactly two accepted
  exception classes — (a) failure-path message text may differ (the
  failure-vs-success classification must match), (b) resource limits:
  Lean must not fail where the oracle succeeds; fuel exhaustion is
  accepted under (b) because the bound is a PARAMETER of the port, not a
  semantic limit — for any oracle-terminating run there is a fuel at
  which Lean agrees. Carried into VALIDATION.md's fuel paragraph as the
  design rationale (not a shipped theorem: fuel monotonicity is not
  provided). Documentation only; no implementation change.

Commits on the branch (this slice):

| commit | what |
|---|---|
| `18ceb18b2` | COMMIT 1 — mechanism, budget unchanged (`driverFuel` = 10^6) |
| `7ffe05156` | commit-1 baseline re-record: the four FUEL rows (§5) |
| `da444eb19` | budget: `driverFuel` = 10^8 on the coupled six + `ndDefaultFuel` |
| `00a3d2b49` | commit-2 baseline re-record (§8) |
| (close-out) | this record + the parse-lane bound + the operator ruling in VALIDATION.md |

## 1. Contract realisation checklist (design §1 → file:line at `18ceb18b2`)

| §1 item | realised at |
|---|---|
| §1.1 `CerbFuel.fuelExhaustedLoc` (pure opaque, value `Loc.other "lem: fuel exhausted"`) | `lean_frontend/CerbFuel.lean:42` |
| §1.1 `CerbFuel.fuelExhaustedMsg` | `CerbFuel.lean:49` |
| §1.1 `CerbFuel.driverFuel` (commit 1: `1000000`) | `CerbFuel.lean:67` |
| §1.1 `export CerbFuel (fuelExhaustedLoc fuelExhaustedMsg driverFuel)` in `CerbND` | `lean_frontend/CerbND.lean:70` |
| §1.1 `CerbND.fuelExhaustedKill {err} := Error0 CerbFuel.fuelExhaustedLoc CerbFuel.fuelExhaustedMsg` | `CerbND.lean:80` |
| §1.1 `CerbND.drive_lemFuel` (verbatim mirror, one substitution) | `CerbND.lean:446` |
| §1.2 nine generated arms, unwrapped | `generated/Nondeterminism.lean:190,308,311`; `generated/Driver.lean:232,347,382`; `generated/Defacto_memory.lean:806,821,900` (from `frontend/model/nondeterminism.lem` declares at the `Totality declares` block, `driver.lem` block, `defacto_memory.lem` trio) |
| §1.2 extra_import mechanism | `frontend/model/nondeterminism.lem` (`declare {lean} extra_import \`CerbFuel\``) → `generated/Nondeterminism.lean:6 import CerbFuel` |
| §1.2 `nd_bind_lemFuel_zero` … `memcmp_load_aux_lemFuel_zero` (nine, fully applied, `rfl`) | `CerbND.lean:298-354` |
| §1.2 `runNDFuel_zero` / `runND1Fuel_zero` / `runND1TraceFuel_zero` (Q3) | `CerbND.lean:356-364`; leaves at `CerbND.lean` `runNDFuel`/`runND1Fuel`/`runND1TraceFuel` fuel-0 arms |
| §1.3 `fuelExhaustedKill_ne_Undef0` / `_ne_Other` (labelled NOT distinctness from Error) | `CerbND.lean:378-386` |
| §1.2 wrappers: `driverFuel_eq`, `driver2_wrapper_defeq`, `nd_bind_wrapper_defeq` (fully applied — deviation recorded in the manifest §2), `runND_eq` (+ `print_eval_conv_aux`/`drive_nonmemory_steps_aux2`/`hack` siblings, `runND1_eq`) | `CerbND.lean:389-413` |
| §1.6 `drive_wrapper_defeq : drive = drive_lemFuel CerbFuel.driverFuel := rfl` — the SYNC GUARANTEE | `CerbND.lean:463` — held by `rfl` at first build |
| §1.4/§6 exemplar | `lean_frontend/test/Unit/FuelExemplar.lean` — the consumer shape at fuel 0 (`:132`) and fuel 1 (`:195`); the ∀-fuel statement is the STOP-AND-REPORT of §4 below |
| §2 census registration of `fuelExhaustedLoc` | `scripts/check_theorem_axioms.sh` `OPAQUE_WANT` (population pin, 26 rows) |
| §2 VALIDATION paragraph (parametricity wording) | `lean_frontend/VALIDATION.md` "Known, LOUD limits" first bullet |
| §3 FUEL class | `scripts/fuel_classify.sh`; `test_exec.sh` FUEL, `test_gcc_oracle.sh` SKIP_LEAN_FUEL, `test_ci_sweep.sh` LEAN_FUEL, `test_cn_coverage.sh` FUEL, `tests/mem-scale-probes/measure.sh` note `FUEL(kill|panic);` |
| §3.4 selftest + plants | `scripts/test_fuel_classifier.sh` (test_unit.sh leg), `scripts/test_fuel_plant.sh` (LADDER Tier B row 8) |
| §5 sorry closure + token leg | `frontend/concurrency/cmm_op.lem` rep → `CerbMem.stringFromMemValue`; `scripts/check_sorry_token.sh` (test_unit.sh leg) |
| §0.5 errata (F7) | `docs/2026-08-31_C1-change-manifest.md` §8 erratum box; `docs/2026-09-01_C1-adoption-record.md` (d) erratum |
| §7 TODO entries | `lean_frontend/TODO.md`: ceiling entry re-stated; `finalize`/`hack` leaf; cross-block fuel threading; backend `sorry` refusal (+ the cmm_csem finding, §9) |

Binder names: the generated ones throughout (`_lemReader_tagDefs`,
`n`/`f1`, `get2`/`put1`/`liftInfo`/`liftErr`, `ival_`, `loc1`); recorded
in the manifest §2 as the design permitted ("exact binder names follow
the generated signatures at implementation").

## 2. OCaml neutrality (the byte-identity proof)

Pre-edit snapshot of `ocaml_frontend/generated` taken after a clean
`make clean-prelude-src prelude-src` at the branch head; after the `.lem`
edits (nine declares + extra_import + cmm_op rep + comment blocks),
`make prelude-src` again, then:

```
=== OCaml diff vs baseline snapshot ===
diff rc=0
```

(`diff -rq .tmp/fuel/ocaml_gen_baseline ocaml_frontend/generated` printed
nothing.) The lem-sync OCaml gen hash is unchanged:
`check_lem_sync: recorded ocaml_frontend/lem_sync.sha256 (src 59093551d4cefefccc0d1920d9885ab65a17c924c8c27fe93427b93490609cf8, gen 295e4f8291c9ffd57a4061dd38e8ec273f18d6c1cfe3a0465291f1a4bcff8100)`
(gen `295e4f8291c9…` = the value the release-hygiene G6 commit recorded).
Fork-drift gate at the head, ZERO manifest change:
`check_fork_drift: OK — layer 1: 71 oracle-surface files = manifest; layer 2: 22 differing generated files, all hash-pinned (merge-base b9aeedcb4dd438763b0eef7f95ac19e93875d7de)`.

## 3. Gate outputs at `18ceb18b2` (`scripts/test_unit.sh`, rc 0)

```
✓ effects-proof-test PASSED
✓ totality-proof-test PASSED
✓ core-parser-test PASSED
✓ fresh-int-test PASSED
✓ pp-test PASSED
✓ fuel-exemplar-test PASSED
Total: 6 passed, 0 failed
check_exec_purity: CLEAN (11 modules)
check_theorem_axioms: hand-written axiom census OK (0 axioms — the arc-17 S2b end state)
check_theorem_axioms: generated-tree census OK (193 files: 0 axioms, boundary-opaque population = the 26 registered rows exactly-once (incl. CerbFuel.fuelExhaustedLoc), 0 unsafeCast)
check_theorem_axioms: C2 ratchet OK (290 files scanned recursively: 0 axioms, 0 runEffectful, seam population = the 66 pinned path-qualified counted rows exactly incl. the extern class; lem tests/ scaffolds asserted outside the surface)
check_theorem_axioms: D14 grep-ban OK (no native_decide/bv_decide in 1 tree(s) + 23 hand-written seam files + LemLibTest.lean)
check_theorem_axioms: driver2 cone sorryAx-free + ofReduce*-free + DAEMON-free (arc-8 S3 bar)
check_theorem_axioms: C2 entry census OK (9 entries, every cone ⊆ [propext, Classical.choice, Quot.sound])
check_theorem_axioms: mem-scale S1 leg OK (6 C1/C3 equality theorems, every cone ⊆ [propext, Classical.choice, Quot.sound])
'CerbND.nd_bind_lemFuel_zero' does not depend on any axioms
'CerbND.liftND_lemFuel_zero' does not depend on any axioms
'CerbND.liftAction_lemFuel_zero' does not depend on any axioms
'CerbND.print_eval_conv_aux_lemFuel_zero' depends on axioms: [propext, Classical.choice, Quot.sound]
'CerbND.drive_nonmemory_steps_aux2_lemFuel_zero' depends on axioms: [propext, Classical.choice, Quot.sound]
'CerbND.driver2_lemFuel_zero' depends on axioms: [propext, Classical.choice, Quot.sound]
'CerbND.find_array_index_lemFuel_zero' depends on axioms: [propext, Classical.choice, Quot.sound]
'CerbND.easy_update_mem_value_aux_lemFuel_zero' depends on axioms: [propext, Classical.choice, Quot.sound]
'CerbND.memcmp_load_aux_lemFuel_zero' depends on axioms: [propext, Classical.choice, Quot.sound]
'CerbND.runNDFuel_zero' does not depend on any axioms
'CerbND.runND1Fuel_zero' does not depend on any axioms
'CerbND.runND1TraceFuel_zero' depends on axioms: [propext]
'CerbND.fuelExhaustedKill_ne_Undef0' does not depend on any axioms
'CerbND.fuelExhaustedKill_ne_Other' does not depend on any axioms
'CerbND.driverFuel_eq' does not depend on any axioms
'CerbND.driver2_wrapper_defeq' depends on axioms: [propext, Classical.choice, Quot.sound]
'CerbND.nd_bind_wrapper_defeq' does not depend on any axioms
'CerbND.runND_eq' does not depend on any axioms
'CerbND.drive_wrapper_defeq' depends on axioms: [propext, Classical.choice, Quot.sound]
'CerbND.drive_lemFuel' depends on axioms: [propext, Classical.choice, Quot.sound]
'FuelExemplar.exemplar_certified_shipped_zero' depends on axioms: [propext, Classical.choice, Quot.sound]
'FuelExemplar.exemplar_run_one_kernel' depends on axioms: [propext, Classical.choice, Quot.sound]
'FuelExemplar.exemplar_certified_shipped_one' depends on axioms: [propext, Classical.choice, Quot.sound]
check_theorem_axioms: FUEL arc leg OK (23 contract lemmas + drive_lemFuel + the exemplar instances, every cone ⊆ [propext, Classical.choice, Quot.sound])
check_theorem_axioms: OK (effect-retirement C2 bar: zero axiom declarations anywhere; entry cones ⊆ the standard three)
check_sorry_token: OK (255 files scanned comment-stripped — generated 193, hand-written+test 29, LemLib 33; 0 sorry tokens)
test_fuel_classifier: 18 fixtures, ALL OK
check_exec_totality: CLEAN (22 generated modules + hand-written CerbND, 0 allowlisted)
check_lem_sync: OK (src 59093551d4cefefccc0d1920d9885ab65a17c924c8c27fe93427b93490609cf8, gen 295e4f8291c9ffd57a4061dd38e8ec273f18d6c1cfe3a0465291f1a4bcff8100)
check_lem_sync: lean OK (src 59093551d4cefefccc0d1920d9885ab65a17c924c8c27fe93427b93490609cf8, gen e2c63e4da5eab46d3c7bdea1fede8a3421f3bd827a046d7160b1e4cd03bebd5c)
check_fork_drift: OK — layer 1: 71 oracle-surface files = manifest; layer 2: 22 differing generated files, all hash-pinned (merge-base b9aeedcb4dd438763b0eef7f95ac19e93875d7de)
check_fixture_freeze: OK (16 fixture files match the pinned manifest; name set exact)
```

### 3.1 Plants (each on a scratch/restored copy; the tree was byte-restored and `check_handwritten_sync` re-run green after each)

Boundary-opaque census (population pin):
```
=== CENSUS PLANT P1: opaque -> def in the build copy of CerbFuel.lean ===
check_theorem_axioms: FAIL — boundary-opaque census: registered opaque CerbFuel.lean:fuelExhaustedLoc found 0 time(s) in the build copy, expected exactly 1 (0 = copy-pipeline/scanner drift or opaque->def; 2+ = duplicated; fail-closed)
=== CENSUS PLANT P2: duplicate the opaque declaration ===
check_theorem_axioms: FAIL — boundary-opaque census: registered opaque CerbFuel.lean:fuelExhaustedLoc found 2 time(s) in the build copy, expected exactly 1 (0 = copy-pipeline/scanner drift or opaque->def; 2+ = duplicated; fail-closed)
=== CENSUS PLANT P3: a NEW unregistered opaque in a generated (lem-output) file ===
check_theorem_axioms: FAIL — boundary-opaque census: UNREGISTERED opaque Cmm_op.lean:plantedBarrier (x1) in the build tree — every opaque is a declared-boundary decision; register it in OPAQUE_WANT with its class, or remove it
```
`sorry`-token leg (scratch root with a planted copy of generated/):
```
=== PLANT A: planted token in a scratch copy of a generated file ===
check_sorry_token: FAIL — `sorry` token(s) in non-comment, non-string position (expected 0; the tree's last one, cmm_op.lem's target_rep, was closed by the FUEL arc rider):
SORRY /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-arc/fuel/.tmp/fuel/sorryplant.LxMk/lean_frontend/generated/Cmm_op.lean:614
rc=1
=== PLANT B: token only inside a comment and a string -> NOT counted ===
check_sorry_token: OK (254 files scanned comment-stripped — generated 193, hand-written+test 28, LemLib 33; 0 sorry tokens)
rc=0
=== PLANT C: empty generated scan set ===
check_sorry_token: FAIL — generated scan set is EMPTY (fail-closed; vacuous scan)
rc=1
```
(Plant A/B/C ran before `FuelExemplar.lean` existed — 28 hand-written+test
files then, 29 at the head.)

Harness FUEL class, `scripts/test_fuel_plant.sh` (stubs via
`CERB_LEAN_BIN_OVERRIDE`; verbatim `PLANT OK` lines):
```
PLANT OK   [exec/kill -> FUEL]: [1/1] FUEL 001-return-literal (FUEL:kill, exit 1): lem: fuel exhausted
PLANT OK   [exec/kill fatal]: FAILED: 1 Lean fuel exhaustion(s) — the fuel budget is a port artifact; a FUEL row is never agreement
PLANT OK   [exec/kill summary fuel=1]: SUMMARY: total=1 match=0 ub_match=0 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=1 lean_error=0 timeout=0 hang=0 cerb_skip=0 cerb_floor=0 cerb_inconsistent=0
PLANT OK   [exec/panic -> FUEL]: [1/1] FUEL 001-return-literal (FUEL:panic, exit 134): lem: fuel exhausted
PLANT OK   [exec/assert -> FAIL (not FUEL)]: [1/1] FAIL 001-return-literal: assert() failure
PLANT OK   [exec/assert no FUEL row]: no /^\[1/1\] FUEL /
PLANT OK   [exec/words no FUEL row]: no /^\[1/1\] FUEL /
PLANT OK   [exec/words is a verdict row]: [1/1] MISMATCH 001-return-literal: Lean=VAL:Specified(0) Cerberus=VAL:Specified(42)
PLANT OK   [gcc/kill -> SKIP_LEAN_FUEL]: [1/1] SKIP_LEAN_FUEL  tests/minimal/001-return-literal.c: (FUEL:kill, exit 1) lem: fuel exhausted
PLANT OK   [gcc/assert -> SKIP_LEAN_FAIL (not FUEL)]: [1/1] SKIP_LEAN_FAIL  tests/minimal/001-return-literal.c: msg: "assert() failure"
PLANT OK   [gcc/assert no FUEL row]: no /^\[1/1\] SKIP_LEAN_FUEL/
PLANT OK   [ci_sweep/kill -> LEAN_FUEL]: ci	tests/ci/0001-emptymain.c	LEAN_FUEL	FUEL:kill, exit 1: lem: fuel exhausted
PLANT OK   [ci_sweep/panic -> LEAN_FUEL]: ci	tests/ci/0001-emptymain.c	LEAN_FUEL	FUEL:panic, exit 134: lem: fuel exhausted
PLANT OK   [ci_sweep/assert -> LEAN_FAIL (not FUEL)]: ci	tests/ci/0001-emptymain.c	LEAN_FAIL	msg: "assert() failure"
PLANT OK   [ci_sweep/assert no FUEL row]: no /	LEAN_FUEL	/
PLANT OK   [cn_coverage/kill -> FUEL]: [1/1] FUEL alloc_create.c (FUEL:kill, exit 1): lem: fuel exhausted
PLANT OK   [cn_coverage/assert -> REJECT (not FUEL)]: [1/1] REJECT_DIFF alloc_create.c (Lean refuses: msg: "assert() failure"; oracle runs: VAL:Specified(0))
PLANT OK   [cn_coverage/assert no FUEL row]: no /^\[1/1\] FUEL /
PLANT OK   [measure/kill -> FUEL(kill) note]: 001-return-literal	nolibc	lean-first	1	0.00	1968	ERR:lem: fuel exhausted	FUEL(kill);	0.00
PLANT OK   [measure/panic -> FUEL(panic) note]: 001-return-literal	nolibc	lean-first	134	0.00	2220	NONE	FUEL(panic);	0.00
PLANT OK   [measure/assert no FUEL]: no /FUEL\(/
test_fuel_plant: ALL PLANTS OK (FUEL classification live in exec/gcc/ci_sweep/cn_coverage/measure; negatives not FUEL)
```

## 4. STOP-AND-REPORT: the ∀-fuel exemplar theorem

Statement (design §1.4/§6, the consumer's §6 shape), over the program of
`test/Unit/FuelExemplar.lean` (`main` returning `Specified(42)`, no
globals; `dst₀ := (initial_driver_state 0 exemplarFile fs_initial_state).1`):

```lean
theorem exemplar_certified_shipped (fuel : Nat) :
  ∀ o ∈ CerbND.runND (CerbND.drive_lemFuel fuel fmapEmpty false exemplarFile ["cmdname"]) dst₀,
    (∃ st, o.1 = Killed st CerbND.fuelExhaustedKill) ∨ (∃ r, o.1 = Active r ∧ post r o.2.2)
```

What was established (scratch probes via `scripts/lean_probe.sh`, this
file's definitions verbatim, `CERB_MEM_MAX=32G`, default heartbeats
unless stated):

- Exploration (`#eval`, instrument only): fuel 0 → `Killed(Error0 lem:
  fuel exhausted)`; fuel 1,2,3,4,10 → `Active(steps=0, val=Specified(42))`
  — the program completes in ONE driver round.
- Fuel 0, consumer shape: closes by `intro o ho; have h :=
  List.mem_singleton.mp ho; subst h; exact Or.inl ⟨_, rfl⟩` in < 1 s wall
  (whole file). SHIPPED as `exemplar_certified_shipped_zero`.
- Fuel `n+1`, `n` SYMBOLIC, consumer shape, canon route (`unfold run
  CerbND.drive_lemFuel at ho; rw [driver2_lemFuel.eq_2] at ho; generalize
  hm : CerbGlobal.current_execution_mode () = m at ho; cases m …; List.mem_
  singleton.mp; subst; exact ⟨_, rfl, rfl⟩`): the `generalize` FINDS the
  opaque read (the round's one configuration read) and the proof CLOSES
  with `set_option maxHeartbeats 0` — 25.4 s wall for the file
  (`24.85s user 0.45s system 99% cpu 25.359 total`); with the default
  200000: `(deterministic) timeout at whnf`; at 400000: timeout; at
  800000: timeout (`20.81s user … 21.332 total` before the cut). The
  `length = 1` variant by `rfl` per branch, uncapped: 70.6 s.
- The same round evaluated by the KERNEL (closed instance, fuel 1,
  `decide +kernel` per scheduler-mode branch, shape-only predicate):
  `0.43s user 0.25s system 91% cpu 0.737 total` for the whole file;
  `'P.k3' depends on axioms: [propext, Classical.choice, Quot.sound]`.
  SHIPPED as `exemplar_run_one_kernel` → `exemplar_certified_shipped_one`.
- `decide +kernel` refuses the open term ("Expected type must not contain
  free variables"; `+revert` would need `Decidable (∀ n, …)`, which does
  not exist).

Reading: the shape IS provable in practice with the shipped lemmas — the
block is the ELABORATOR's (Meta-level) evaluation of one driver round on
the open term, ~100× the kernel's cost and above the default heartbeat
budget by more than 4×. No heartbeat bump was applied (registered-defect
shape; the brief's hard invariant). Remedies, each a ruling for the
second design review: (a) a kernel-only reflexivity elaboration (the
`decide +kernel` mechanism applied to an open `Eq.refl`, e.g. `∀ n,
run (n+1) = run 1` — ~10 lines of meta code; kernel-trusted; a NEW
proof-method mechanism in the tree); (b) a per-theorem heartbeat budget
registered as a defect with a named remover; (c) symbolic round lemmas
(the consumer's DriverCollapse discipline, ~1.6 kLOC on their side). The
consumer's own ∀-fuel proofs are unaffected in shape: their `n+1` case
already `cases` the same opaque read.

Also measured: with the supply seed `sup` SYMBOLIC in `dst₀ sup`, the fuel-0
unification (`List.mem_singleton.mp ho`) does not see a singleton
("Application type mismatch … expected `?m ∈ [?m]`"); the shipped
instances fix `sup = 0`. Not investigated further in this slice.

## 5. Baseline movement, commit 1 (the FUEL witness rows)

gcc second-oracle lane, `SKIP_BUILD=1 ./scripts/test_gcc_oracle.sh --check-baseline` at `18ceb18b2` (fresh stamps), rc 0:
```
[1424/1953] SKIP_LEAN_FUEL  csmith/sia_csmith_477.c: (FUEL:kill, exit 1) lem: fuel exhausted
[1716/1953] SKIP_LEAN_FUEL  csmith/sia_csmith_769.c: (FUEL:kill, exit 1) lem: fuel exhausted
    SKIP_LEAN_FUEL: 2
SUMMARY: total=1953 compared=1880 agree=1871 agree_nd=0 triaged=9 disagree=0 o2_agree=190 skip_lean_crash=7 skip_lean_fail=9 skip_lean_fuel=2 skip_lean_timeout=11 skip_ub=44 triaged_addr=9
changed (same rank): csmith/sia_csmith_477.c baseline=SKIP_LEAN_CRASH/- current=SKIP_LEAN_FUEL/-
changed (same rank): csmith/sia_csmith_769.c baseline=SKIP_LEAN_CRASH/- current=SKIP_LEAN_FUEL/-
Baseline check: 0 regression(s), 0 improvement(s)
```
Both rows are the KILL sub-kind (driver-family exhaustion), answering the
design's open question (§3.3 last paragraph). No other row moved.

csmith corpus lane (`test_csmith_corpus.sh --check-baseline --shard K/6`, K = 1..6, `SKIP_BUILD=1`, at `18ceb18b2`):
```
shard 1: SUMMARY: total=279 match=127 ub_match=0 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=1 hang=0 cerb_skip=151 cerb_floor=0 cerb_inconsistent=0
         Baseline check: 0 regression(s), 0 improvement(s)  /  BASELINE OK
shard 2: SUMMARY: total=279 match=159 ub_match=0 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=3 hang=0 cerb_skip=117 cerb_floor=0 cerb_inconsistent=0
         Baseline check: 0 regression(s), 0 improvement(s)  /  BASELINE OK  /  shard 2 rc=0
shard 3: SUMMARY: total=279 match=144 ub_match=0 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=2 hang=0 cerb_skip=133 cerb_floor=0 cerb_inconsistent=0
         Baseline check: 0 regression(s), 0 improvement(s)  /  BASELINE OK  /  shard 3 rc=0
shard 4: SUMMARY: total=279 match=234 ub_match=0 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=45 cerb_floor=0 cerb_inconsistent=0
         Baseline check: 0 regression(s), 0 improvement(s)  /  BASELINE OK  /  shard 4 rc=0
shard 5: [24/279] FUEL sia_csmith_477 (FUEL:kill, exit 1): lem: fuel exhausted
         SUMMARY: total=279 match=268 ub_match=0 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=1 lean_error=0 timeout=0 hang=0 cerb_skip=10 cerb_floor=0 cerb_inconsistent=0
         changed (same rank, non-regressing): sia_csmith_477.c baseline=LEAN_CRASH current=FUEL
         Baseline check: 0 regression(s), 0 improvement(s)  /  BASELINE OK  /  shard 5 rc=0
shard 6: [37/274] FUEL sia_csmith_769 (FUEL:kill, exit 1): lem: fuel exhausted
         SUMMARY: total=274 match=228 ub_match=0 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=1 lean_error=0 timeout=2 hang=0 cerb_skip=43 cerb_floor=0 cerb_inconsistent=0
         changed (same rank, non-regressing): sia_csmith_769.c baseline=LEAN_CRASH current=FUEL
         Baseline check: 0 regression(s), 0 improvement(s)  /  BASELINE OK  /  shard 6 rc=0
(shards 2-6 ran in parallel on a 32-core box at load ~2-12; shard 1's
"rc=" wrapper line is absent because its serial driver script was
stopped to launch the others — its own log ends BASELINE OK.)
```

mem-scale record rows (`tests/mem-scale-probes/measure.sh`, Lean engines only, at `18ceb18b2`; TSV columns probe mode engine exit wall_s maxrss_kb verdict note cpu_s):
```
b_zero_local_1000000	nolibc	lean-first	134	1.10	103404	NONE	FUEL(panic);	0.02
b_zero_local_1000000	nolibc	lean-exh	134	1.10	103232	NONE	FUEL(panic);	0.03
d_loop_100000	nolibc	lean-first	1	4.38	325184	ERR:lem: fuel exhausted	FUEL(kill);	4.38
d_loop_100000	nolibc	lean-exh	1	4.33	325700	ERR:lem: fuel exhausted	FUEL(kill);	4.32
d_loop_1000000	nolibc	lean-first	1	5.06	450136	ERR:lem: fuel exhausted	FUEL(kill);	5.06
d_loop_1000000	nolibc	lean-exh	1	5.04	452092	ERR:lem: fuel exhausted	FUEL(kill);	5.03
b_zero_local_10000000	nolibc	lean-first	134	1.10	103944	NONE	FUEL(panic);	0.02
b_zero_local_10000000	nolibc	lean-exh	134	1.10	103132	NONE	FUEL(panic);	0.03
e_memcpy_100000	libc	lean-first	1	5.89	457176	ERR:lem: fuel exhausted	FUEL(kill);	5.88
e_memcpy_100000	libc	lean-exh	1	6.00	457148	ERR:lem: fuel exhausted	FUEL(kill);	6.00
e_memcpy_1000000	libc	lean-first	1	10.69	1273848	ERR:lem: fuel exhausted	FUEL(kill);	10.69
e_memcpy_1000000	libc	lean-exh	1	10.78	1272948	ERR:lem: fuel exhausted	FUEL(kill);	10.78
```
FINDING (deviation from design §3.3's table, which predicted `FUEL(kill)`
for all five C8 rows): the two `b_zero_local_*` rows are the PANIC
sub-kind — a pure-return worker. Symbolised from the panic backtrace
(`addr2line -f -C` on the driver binary):
`lp_CerberusLean_mkListN__aux__lemFuel` ← `lp_CerberusLean_constructValue__aux`
← `lp_CerberusLean_wip__desugar__initializer___00__lam__6` — the FRONT
END's `mkListN` (a list of n elements for an n-element zero initialiser)
exhausts `lemDefaultFuel` at n = 10^6. It is outside the coupled driver
family, so the budget commit does not move these rows (Q4: budgets
beyond the ruled six are out of scope; evidence for a follow-up budget
declare is recorded here).

## 6. Commit 2 — budget

Commit `da444eb19`. The L1 numeric budget form beside the sentinel
declares: `declare {lean} fuel val nd_bind = 100000000` (nondeterminism
.lem) and `… print_eval_conv_aux / drive_nonmemory_steps_aux2 / driver2 /
hack = 100000000` (driver.lem); `CerbFuel.driverFuel := 100000000`;
`CerbND.driverFuel_eq : CerbFuel.driverFuel = 100000000 := rfl`;
`CerbND.ndDefaultFuel := CerbFuel.driverFuel` (since commit 1). liftND/
liftAction + the defacto trio keep `lemDefaultFuel` (Q4). Generated
wrappers at the head (derived: grep `_lemFuel 100000000`): Nondeterminism
.lean:193 `nd_bind`, Driver.lean:237 `print_eval_conv_aux`, :351
`drive_nonmemory_steps_aux2`, :386 `driver2`, :395 `hack` — five, plus the
hand-written runner budget = the six; Defacto_memory.lean still carries
its five `lemDefaultFuel` wrappers.

Build (`.tmp/fuel/c2_build.sh`: `make prelude-src` → byte-compare →
`make lean-prelude-src lean-native-obj` → `build_cerberus` (DUNE_CACHE=
disabled) → `build_lean`), verbatim excerpts:
```
check_lem_sync: recorded ocaml_frontend/lem_sync.sha256 (src 4f2e089b39d5b371973513b3350f81d1b89871976f77df9ba4a25da3421d0c54, gen 295e4f8291c9ffd57a4061dd38e8ec273f18d6c1cfe3a0465291f1a4bcff8100)
=== OCaml diff vs baseline snapshot (commit 2) ===
diff rc=0 (empty)
check_driver_fresh: recorded oracle stamp (bin e448c1da358796cd98f2121dbbe8fd50b98c0a55b9332ad9a6659c018e7f074d, src c9c1a7067139b3ceb4eb0ad6870b93d8d0dbbaa9bd39e0397f11e8c975737a3b)
✔ [271/271] Built «cerberus-lean»:exe (605ms)
Build completed successfully (271 jobs).
check_driver_fresh: recorded lean stamp (bin fd035977259b0ec27d1ecd717cfd6a7439a3a3e9a0db40eeb4997afac641eb7a, src 57fab015e7287ac6839a36515660904f795eade13acb4bf20f5de379690ae24c)
```
The generated OCaml gen hash `295e4f8291c9…` is the same value as before
the arc (only the src hash moved). The wrapper `rfl`s (`driver2_wrapper_
defeq` and siblings, `drive_wrapper_defeq`) elaborated at the new budget
— the build is the check.

`scripts/test_unit.sh` at this tree: FIRST run rc 1 — `totality-proof-
test` build failed: `test/Unit/TotalityProofTest.lean` Part 1 stated the
five budgeted wrappers as `… = <worker>_lemFuel lemDefaultFuel … := rfl`,
which is exactly the consumer-side `rfl` the design (§4.3) said stops
holding; restated at `CerbFuel.driverFuel` (the other 47 examples keep
`lemDefaultFuel`, the L1 opt-in guarantee held structurally). SECOND run
rc 0:
```
Total: 6 passed, 0 failed
check_theorem_axioms: generated-tree census OK (193 files: 0 axioms, boundary-opaque population = the 26 registered rows exactly-once (incl. CerbFuel.fuelExhaustedLoc), 0 unsafeCast)
check_theorem_axioms: FUEL arc leg OK (23 contract lemmas + drive_lemFuel + the exemplar instances, every cone ⊆ [propext, Classical.choice, Quot.sound])
check_theorem_axioms: OK (effect-retirement C2 bar: zero axiom declarations anywhere; entry cones ⊆ the standard three)
check_sorry_token: OK (255 files scanned comment-stripped — generated 193, hand-written+test 29, LemLib 33; 0 sorry tokens)
test_fuel_classifier: 18 fixtures, ALL OK
check_fork_drift: OK — layer 1: 71 oracle-surface files = manifest; layer 2: 22 differing generated files, all hash-pinned (merge-base b9aeedcb4dd438763b0eef7f95ac19e93875d7de)
```

mem-scale rows at 10^8 (`measure.sh`, `--engines lean-first`, 600 s timeout; TSV columns as in §5):
```
b_zero_local_1000000	nolibc	lean-first	134	1.11	104988	NONE	FUEL(panic);	0.02
d_loop_100000	nolibc	lean-first	0	36.91	1828344	VAL:Specified(-97)	-	36.90
d_loop_1000000	nolibc	lean-first	134	44.58	2215456	NONE	-	43.49
b_zero_local_10000000	nolibc	lean-first	134	1.10	104760	NONE	FUEL(panic);	0.02
e_memcpy_100000	libc	lean-first	0	28.72	1342460	VAL:Specified(7)	-	28.50
e_memcpy_1000000	libc	lean-first	134	99.84	3087864	NONE	-	80.59
```
Readings against the design's §3.3/§4.4 column ("expected to complete;
else TIMEOUT or FUEL"):
- `d_loop_100000` and `e_memcpy_100000` COMPLETE with the oracle's recorded
  values (`VAL:Specified(-97)`, `VAL:Specified(7)`; mem-scale record
  :700/:703) — the two rows leave BLOCKER C8 (improvement; the mem-scale
  record's parity columns are re-measured by that arc's instrument, not
  here — these are witness rows, the oracle side was not re-run).
- `d_loop_1000000` and `e_memcpy_1000000`: exit 134 after 44.6 s / 99.8 s
  with stderr `Stack overflow detected. Aborting.` (verbatim .err) — a
  crash class the design did NOT enumerate: the registered process-STACK
  ceiling (TODO.md "Step-runner execution ceiling", re-characterised
  2026-08-30 as masked by the 10^6 fuel ceiling) is unmasked at 10^8. A
  harness reads it as its crash class (LEAN_CRASH / `(no PANIC line
  captured)`), never FUEL, never agreement. FINDING for the second review;
  no stack knob was touched (the registered-defect shape).
- `b_zero_local_*`: FUEL(panic) unchanged (front-end `mkListN`, §5).


## 7. Close-out battery

At the commit-2 head (`da444eb19` + the close-out parse-lane fix), binaries
freshly built cache-disabled and stamped (oracle bin `e448c1da…`, Lean bin
`fd035977…`, §6), `SKIP_BUILD=1` everywhere (the stamps are the freshness
proof), `.tmp/fuel/battery.sh` + `battery_tail.sh` (row order = LADDER).
Every row rc 0:

```
Tier A (LADDER)                                                      rc
 1  scripts/test_unit.sh                                               0   (§6, second run; 6/6 exes + every gate)
 2  test_exec.sh --check-baseline                                      0
 3  test_exec.sh --check-baseline=scripts/exec_coverage_baseline.txt   0
 4  test_exec.sh --check-baseline=scripts/exec_debug_baseline.txt      0
 4b test_exec.sh --check-baseline=scripts/exec_float_baseline.txt      0
 4c test_bytes.sh                                                      0
 5  test_libc_exec.sh                                                  0
 6  test_multi_tu.sh                                                   0
 7  test_parse.sh                                                      0   (run twice: before and after the --pp-core fix; 106/106 both)
 8  test_core.sh                                                       0
 9  test_elab.sh                                                       0
 10 test_libxml2_uri.sh                                                0
 11 test_cn_coverage.sh --check-baseline                               0
Tier B
 1  test_libxml2.sh                                                    0   (10.7 min)
 2  test_parse.sh tests/ci                                             0   (after the fix: "Total: 250 / Cerberus parse: 247 ok, 3 failed / Lean parse: 247 ok, 0 failed, 0 timeout (>60s; fatal) / ALL PASSED", 23 s; the first attempt, default mode, was stopped after > 4 min on one file — §9.6)
 3  test_core.sh tests/ci                                              0   ("Success rate: 100% (of cerberus successes) / ALL PASSED")
 4  test_verify.sh                                                     0
 5  test_immaculate.sh                                                 0
 6  test_speclab.sh --selftest; --plant; test_speclab_{divmod,bytearr,list,tree,seed}.sh --gate   0 (all seven)
 7  test_gcc_oracle.sh --check-baseline                                0   (§8 second pass: 0 regression(s), 2 improvement(s))
 8  test_hang_plant.sh                                                 0
 8  test_kill_plant.sh                                                 0
 8  test_fuel_plant.sh                                                 0
Tier C witness
    test_csmith_corpus.sh --check-baseline --shard K/6, K=1..6          §8 (shard 2 re-run on a quiet box: rc 0, BASELINE OK)
```


## 8. Baseline movement, commit 2

Lanes at `da444eb19` (SKIP_BUILD=1, fresh stamps). FIRST pass ran the gcc
lane, the six csmith shards and the mem-scale rows CONCURRENTLY (load
~7-12); per the gcc lane's recorded load caveat (script header; LADDER
Tier B row 7), TIMEOUT-only movements from that pass were re-run alone
on a quiet box (second pass) before being read.

gcc second-oracle lane, first pass (concurrent; rc 1):
```
[1424/1953] AGREE  csmith/sia_csmith_477.c: gcc=132 lean={132}
[1716/1953] AGREE  csmith/sia_csmith_769.c: gcc=9 lean={9}
SUMMARY: total=1953 compared=1881 agree=1872 agree_nd=0 triaged=9 disagree=0 o2_agree=190 skip_lean_crash=7 skip_lean_fail=9 skip_lean_timeout=12 skip_ub=44 triaged_addr=9
improvement: csmith/sia_csmith_477.c baseline=SKIP_LEAN_FUEL/- current=AGREE/-
REGRESSION: csmith/sa_csmith_231.c baseline=AGREE/- current=SKIP_LEAN_TIMEOUT/-
improvement: csmith/sia_csmith_769.c baseline=SKIP_LEAN_FUEL/- current=AGREE/-
Baseline check: 1 regression(s), 2 improvement(s)
```
gcc lane, second pass (quiet box, load at start 2.53):
```
[435/1953] AGREE  csmith/sa_csmith_231.c: gcc=225 lean={225}
[1424/1953] AGREE  csmith/sia_csmith_477.c: gcc=132 lean={132}
[1716/1953] AGREE  csmith/sia_csmith_769.c: gcc=9 lean={9}
SUMMARY: total=1953 compared=1882 agree=1873 agree_nd=0 triaged=9 disagree=0 o2_agree=190 skip_lean_crash=7 skip_lean_fail=9 skip_lean_timeout=11 skip_ub=44 triaged_addr=9
improvement: csmith/sia_csmith_477.c baseline=SKIP_LEAN_FUEL/- current=AGREE/-
improvement: csmith/sia_csmith_769.c baseline=SKIP_LEAN_FUEL/- current=AGREE/-
Baseline check: 0 regression(s), 2 improvement(s)
rc=0
```
(`sa_csmith_231.c` AGREEs on the quiet box — the first-pass SKIP_LEAN_
TIMEOUT was the recorded load class, not a code effect; a second agent's
parallel Go harness pushed the box to load 52 mid-run even in this pass,
without effect on the outcome.)
```
```

csmith corpus lane, first pass (six shards concurrent):
```
shard 1: SUMMARY: total=279 match=127 ub_match=0 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=1 hang=0 cerb_skip=151 cerb_floor=0 cerb_inconsistent=0
         Baseline check: 0 regression(s), 0 improvement(s)  /  BASELINE OK  /  shard 1 rc=0
shard 2: SUMMARY: total=279 match=158 ub_match=0 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=4 hang=0 cerb_skip=117 cerb_floor=0 cerb_inconsistent=0
         REGRESSION: sa_csmith_369.c baseline=MATCH current=TIMEOUT
         Baseline check: 1 regression(s), 0 improvement(s)  /  shard 2 rc=1     (TIMEOUT-only movement under load — re-run below)
shard 3: SUMMARY: total=279 match=144 ub_match=0 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=2 hang=0 cerb_skip=133 cerb_floor=0 cerb_inconsistent=0
         Baseline check: 0 regression(s), 0 improvement(s)  /  BASELINE OK  /  shard 3 rc=0
shard 4: SUMMARY: total=279 match=234 ub_match=0 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=45 cerb_floor=0 cerb_inconsistent=0
         Baseline check: 0 regression(s), 0 improvement(s)  /  BASELINE OK  /  shard 4 rc=0
shard 5: [24/279] TIMEOUT sia_csmith_477 (Lean TIMEOUT(cpu 15.03s of 15.04s wall; timeout 15s))
         SUMMARY: total=279 match=268 ub_match=0 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=1 hang=0 cerb_skip=10 cerb_floor=0 cerb_inconsistent=0
         changed (same rank, non-regressing): sia_csmith_477.c baseline=FUEL current=TIMEOUT
         Baseline check: 0 regression(s), 0 improvement(s)  /  BASELINE OK  /  shard 5 rc=0
shard 6: SUMMARY: total=274 match=229 ub_match=0 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=2 hang=0 cerb_skip=43 cerb_floor=0 cerb_inconsistent=0
         improvement: sia_csmith_769.c baseline=FUEL current=MATCH
         Baseline check: 0 regression(s), 1 improvement(s)  /  BASELINE OK  /  shard 6 rc=0
```
csmith shard 2, second pass (quiet box, after the close-out battery):
```
=== SHARD 2/6 re-run start 2026-09-03T03:48:20Z load:  03:48:20 up 10 days, 13:18,  ? user,  load average: 45.92, 20.13, 15.07 ===
[23/279] MATCH sa_csmith_369: VAL:Specified(57)|VAL:Specified(57)|…
SUMMARY: total=279 match=159 ub_match=0 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=3 hang=0 cerb_skip=117 cerb_floor=0 cerb_inconsistent=0
Baseline check: 0 regression(s), 0 improvement(s)
BASELINE OK
shard 2 rc=0
```
(`sa_csmith_369.c` MATCHes — the first-pass TIMEOUT was load; note the
load figure at this run's start is another agent's spike, the lane still
came out clean, and the row's baseline status is unchanged.)
```
```

Movement summary (commit-2 column of design §3.3):

| row | commit 1 | commit 2 | design expectation |
|---|---|---|---|
| gcc `csmith/sia_csmith_477.c` | SKIP_LEAN_FUEL | AGREE (gcc=132 lean={132}) | "SKIP_LEAN_TIMEOUT, or AGREE if it completes within 30 s — NOT FUEL" ✓ |
| gcc `csmith/sia_csmith_769.c` | SKIP_LEAN_FUEL | AGREE (gcc=9 lean={9}) | same ✓ |
| csmith `sia_csmith_477.c` | FUEL | TIMEOUT (15 s lane) | "TIMEOUT, or MATCH — NOT FUEL" ✓ |
| csmith `sia_csmith_769.c` | FUEL | MATCH | same ✓ |
| mem-scale `d_loop_100000`, `e_memcpy_100000` | FUEL(kill) | complete, oracle's values | "expected to complete" ✓ |
| mem-scale `d_loop_1000000`, `e_memcpy_1000000` | FUEL(kill) | exit 134 `Stack overflow detected` | NOT enumerated — FINDING (§6) |
| mem-scale `b_zero_local_1000000/10000000` | FUEL(panic) | FUEL(panic) | "expected to complete" ✗ — front-end `mkListN`, outside the family (§5) |

The two gcc AGREE rows are new second-oracle agreements on programs that
never completed before (both at Lean `--first`, the csmith tier's mode).


## 9. Findings and residuals (for the second design review)

1. §4: the ∀-fuel exemplar theorem — provable, over budget in the
   elaborator; ruling needed on the remedy.
2. §5: `b_zero_local_*` are pure-worker (front-end `mkListN`) panics, not
   driver kills; the design's "expected to complete" prediction for them
   was wrong; the d_loop/e_memcpy rows are driver kills as predicted.
3. `frontend/concurrency/cmm_csem.lem` carries 24 `declare lean target_rep
   function … = \`sorry\`` declares (observable_filter … overlap_behaviour)
   that are UNREFERENCED in the Lean build — zero `sorry` tokens in the
   generated tree (`check_sorry_token.sh`), so the design's "exactly one
   real sorry" holds for the generated TEXT but not for the `.lem` source;
   registered with the backend `sorry`-refusal rider in TODO.md.
4. `nd_bind_wrapper_defeq` is fully applied (implicit-binder order), not
   the design's point-free spelling (manifest §2).
5. The exemplar's supply seed is fixed at 0 (§4, last paragraph).
6. `scripts/test_parse.sh` (and the `test_cabs_json.sh` smoke) ran the
   Lean driver in its DEFAULT mode — parse AND execute — with no timeout;
   the 10^6 fuel ceiling was that lane's implicit bound. At 10^8 the
   close-out battery's Tier B row 2 (`test_parse.sh tests/ci`) stalled on
   `tests/ci/0025-jump3.c` (CERB_SKIP in the exec lane, CERB_TIMEOUT in
   the sweep — an oracle-long program) for > 4 min before being stopped.
   Fixed in the close-out commit: the lane runs `--pp-core` (front end
   through linking, no execution — its documented purpose is the Cabs
   bridge) under a fail-NOISY per-file timeout (60 s default; counted as
   its own class and fatal). tests/minimal re-verified 106/106 before
   the tail battery. This is the general lesson of the budget move:
   every lane that executes must carry its own bound (all classifying
   and byte-compare lanes already do; `test_core.sh` uses `--parse-core`,
   no execution).
7. Freshness-stamp hygiene during the slice: the oracle stamp hashes
   `frontend/**.lem`, the Lean stamp hashes `lakefile.toml`/hand-written/
   generated sources — each source edit after a build invalidated a stamp
   and a lane refused (`CERB_DRIVER_STALE`, twice) until the side was
   rebuilt/re-recorded; the lanes in this record all ran on re-stamped
   binaries. Working as designed.
