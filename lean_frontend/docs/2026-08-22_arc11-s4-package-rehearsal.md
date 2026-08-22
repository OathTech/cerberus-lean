# Arc-11 / S4 — THE PACKAGE REHEARSAL (record)

Date: 2026-08-22. Provenance: [AGENT:arc11-S4] throughout. Work
order: charter S4 (the [USER] two-part-design item) under D3's
in-session pivot clause. Rehearsal ONLY — no repo split; all commands
capped `CERB_MEM_MAX=40G`.

## What landed

* **`relsem/` is its own Lake package** (`relsem/lakefile.toml`,
  `relsem/lean-toolchain`): requires the semantics package
  (`CerberusLean`) BY PATH (`path = ".."`); the git dependencies
  (batteries/iris/Qq/LemLib) are SHARED via
  `packagesDir = "../.lake/packages"` — no re-clone, no re-build,
  offline-safe (first standalone build: 363 jobs, RelSem modules
  only).
* **The exec/proof boundary, measured** (finding 1): `Main.lean`
  (the driver) imports `RelSem.Call` — the verify harness closure
  {Call, Machine, RunND, ExecModel, Cerberus} is EXEC-FACING and
  cannot leave the root package (Lake forbids require cycles). It
  now lives root-side as the **`RelSemCore`** lib
  (`lean_frontend/relsemcore/RelSem/`, module names UNCHANGED,
  explicit roots, in `defaultTargets`). The PROOF layers (Kit/,
  Tactics/, Iris*, Slate*, fixtures, T1-T5*, Audit*) build in the
  relsem package.
* **Prefix-resolution finding** (finding 2): Lake resolves imports
  by root-module PREFIX — a nested-package lib with root module
  `RelSem` would claim the dep-provided `RelSem.*` core modules too
  (measured: `bad import 'RelSem.Machine'` / missing-file failures).
  The relsem lib therefore ENUMERATES its 34 leaf-module roots
  (component-wise prefix semantics keep `RelSem.T1` and
  `RelSem.T1AppEq` disjoint), with `RelSemAll` (the old
  `RelSem.lean`, renamed) as the aggregator. A same-prefix split
  across packages is otherwise impossible — the real-split design
  datum this rehearsal was chartered to surface.
* **Gates re-homed + fail-closed** (charter requirement): the
  in-build audits (RelSem/Audit.lean — DAEMON absence, statement-TCB
  gate, axiom sweep; Kit/Audit — 54 exactness pins) elaborate on the
  relsem package's plain `lake build`:

  ```
  info: RelSem/Audit.lean:144:0: RelSem DAEMON absence gate: no constant named DAEMON or DAEMON1 exists in the environment; neither is allowlisted
  info: RelSem/Audit.lean:490:0: RelSem statement gate: 16 slate statements fuel-opsem-clean (negative tests: t1_wp and the wrapper-hole probe correctly rejected)
  info: RelSem/Audit.lean:541:0: RelSem audit sweep: 3021 declarations across RelSem.* modules, all within the declared axiom boundary (0 recorded sorryAx exceptions)
  Build completed successfully (363 jobs).
  ```

  PLANT-TESTED: corrupting one Kit/Audit pin ⇒ the package build
  FAILS (`Some required targets logged failures: - RelSem.Kit.Audit`,
  `error: build failed`); restore ⇒ 363 jobs green.
* **The plain-build property** (charter requirement, honest form):
  the ROOT plain `lake build` stays green (367 jobs: the semantics
  tree + `RelSemCore` + the driver, which links against the root-side
  core) — everything the ROOT package owns still elaborates on a
  plain root build. The PROOF layers' in-build gates necessarily ride
  the RELSEM package's plain build (the dependency direction makes a
  single all-covering root build impossible — finding 1);
  `test_unit.sh` therefore builds BOTH packages, with the relsem
  build as an explicit fail-closed gate step BEFORE the test loop
  (fires even under a filtered test selection). This split is
  precisely what a real repo split would face; recorded as the
  rehearsal's main structural result.
* **Re-homed executables**: `app-walk-test`, `emit-lean-core-test`,
  `t4-env-witness`, `t5-probe` (the RelSem-importing exes) moved to
  `relsem/test/Unit/` + relsem lakefile (`moreLinkArgs` via
  `../native/*.o`); `bench/WalkBench.lean` → `relsem/bench/`;
  probes run via `lake env lean` from `relsem/`. All four exes
  build and pass from the package (AppWalkTest ALL PASSED incl.
  E9/E10; EmitLeanCoreTest ALL PASSED; T4EnvWitnessTest ALL
  PASSED).
* **Scripts**: `test_unit.sh` — the relsem-package gate build + a
  package-aware test loop (`RELSEM_TESTS` mapping, binaries at
  `relsem/.lake/build/bin/`); `test_verify.sh` — t4-env-witness
  path. `check_proof_size.sh` unchanged (the scanned paths did not
  move). CLAUDE.md rows updated in the same commit.

## Regression bar (verbatim tails at the commit)

(the commit message carries the full battery; headline lines:)

* ROOT plain `lake build`: `Build completed successfully (367
  jobs).` — driver linked.
* RELSEM plain `lake build`: `Build completed successfully (363
  jobs).` with all three audit-gate lines above.
* `test_unit.sh` (both packages driven): see commit tail.
* `test_verify.sh` / exec-minimal: see commit tail.

## Deviations / notes

* The charter phrase "`lake build` from the root still elaborates
  everything" is satisfiable only per-package (finding 1); the
  preserved property is: plain root build green AND the proof gates
  in-build fail-closed on the relsem package's plain build, with the
  gate scripts driving both. Flagged for the S5 audit (scope d).
* The 5 core modules moved to `relsemcore/` are the SAME FILES
  (git-mv; module names and declaration names unchanged — every
  Kit/Audit pin and theorem cone identical; the audit sweep count
  3021 is unchanged).
* R-S2-1/R-S2-2 (the climb register items) are untouched by S4.
