# Quotation hygiene and the stop-vocabulary amendment — slice record (2026-10-26)

Branch `feature/quotation-hygiene`, worktree `worktrees/cerberus-lean-feature/quotation-hygiene`,
based on mainline `mdd/cerberus-lean` = `704c4e697` (Lean 4.35.0, lem `e6d8db5`). Charter:
`docs/2026-10-26_worker-charter-quotation-hygiene.md` (committed `1616d46ad`). Worker: a Fable
subagent [AGENT]. Every judgement below that no operator ruling covers is [AGENT 2026-10-26];
the operator's rulings are [USER 2026-10-21] B and C (the Core-quoting D5 re-review,
`docs/2026-10-20_core-quote-d5-rereview.md`) and the standing rules of the container's
working-practices doc. Checkpoints Q1–Q6 each close with a commit; the close-out section
carries the full battery. Quoted machine output is verbatim; derived tallies are labelled.

Build in the worktree before any change (from the repository root, through the container's
`scripts/ce`): `dune build backend/driver/main.exe cerberus-lib.install`, `dune install
--prefix "$PWD/_build/local-install" cerberus-lib`, `dune build cerberus.install`,
`CERB_MEM_MAX=32G ./scripts/capped make lean-native-obj`, `capped lake build CerberusLean
cerberus-lean` (`Build completed successfully (408 jobs).`), speclab `capped lake build`
(`Build completed successfully (150 jobs).`). Clean tree at `1616d46ad`.

## Q1 — the resolved-path library-location rule mirrored into the oracle (ruling B)

**What stood.** The oracle's `util/cerb_location.ml` `is_library_location` (pristine
`b9aeedcb4` :512-523, byte-identical in the fork until this slice) looked
`Filename.dirname path` up LITERALLY in the three keys `Cerb_runtime.in_runtime "libc/include"`
/ `"libcore"` / `"libcore/impls"` — the runtime argument as spelled plus the suffix. The port
(`CerbLocation.isLibraryLocation`, a suffix test; `Main.refuseLibraryLocations`, the import-time
resolved-membership guard, D2b [USER 2026-10-19]) accepted any spelling resolving to a library
directory. So cpp's own `./_build/...` header positions under `--runtime=_build/install/default`
were library on the port and not on the oracle, and the served UB location differed
(`core_eval.lem:602`'s substitution): the D5 pin, oracle `<2:10--2:15>` vs port `<11:10--11:23>`.

**The change** (`util/cerb_location.ml`, `is_library_location` and the four helpers above it;
comment at the site cites the port's rule): the fork oracle classifies a location as library iff
(1) `Filename.dirname path` ends with one of `runtime/libc/include`, `runtime/libcore`,
`runtime/libcore/impls` (`has_library_suffix`, the mirror of `CerbLocation.isLibraryPathSuffix`:
`dir == d || dir.endsWith ("/" ++ d)`) AND (2) `Unix.realpath dir` is one of the realpaths of
this run's three runtime library directories (`resolved_library_dirs`, lazily from
`Cerb_runtime.in_runtime`, the mirror of `Main.refuseLibraryLocations`'s `exact` list).

[AGENT 2026-10-26] decisions, with reasons:
- Suffix AND resolved membership, not resolved membership alone (the charter's wording): the
  port's served rule IS the suffix test, under a guard that refuses suffix-without-membership; so
  on every served input the port = suffix = suffix ∧ member. Membership alone would classify a
  foreign-named symlink to a library directory as library where the port's suffix test says
  not — a divergence in the other direction. With both conjuncts the two engines classify every
  served input identically.
- The suffix is tested first, so user files and `<internal>` (`Loc_other`, `dirname` = `.`)
  never touch the filesystem.
- A suffix-bearing directory that cannot be resolved (`ENOENT`) is REFUSED on the oracle
  (`failwith "Cerb_location.is_library_location: refused - source location ... cannot be resolved
  ..."`, the fork's oracle refusal shape: uncaught `Failure`, exit 125): that is exactly the
  input the port refuses at import ("cannot resolve the source directory"); an unresolvable
  runtime library directory is refused likewise (the port refuses "cannot resolve this run's
  runtime library directories"). Never classified by suffix alone (fail-closed).
- Memoised per directory string (`library_dir_cache`) and the three runtime directories resolved
  once: `core_run.lem:782` tests the location of EVERY thread step; without the cache every step
  would cost realpath syscalls. The lazy forces after `Cerb_runtime.specified_runtime` is set at
  the CLI (the witness's probe sets it explicitly, as before).
- Paths resolve from the process working directory, as the port's do; no label is rewritten.

Probed by hand on the rebuilt oracle (`.tmp`, deleted): the `./`, unprefixed, absolute and
`libcore` `#line` plants all answer `<11:10--11:23>` (the port: the same four); the ghost plant
`#line 1 "./lib/runtime/libcore/plant.h"` is refused (`Failure("Cerb_location.is_library_location:
refused - source location `./lib/runtime/libcore/plant.h' names a directory with a runtime
library suffix that cannot be resolved (`./lib/runtime/libcore'); ...")`); a user file under a
directory merely named `runtime/libcore` stays non-library (`<2:10--2:15>`; the port refuses
that input at import, the Z-67 witness `l1`), so nothing is served divergently.

**The witness** (`scripts/check_runtime_resolution.sh`): the fixture-001 classifier probe now
expects the oracle's actual `is_library_location` TRUE on the `./`-prefixed label (was FALSE),
TRUE on the unprefixed control, and a NEW probe FALSE on the foreign `runtime/libcore` user
directory; the served-divergence pin is now a served AGREEMENT pin over FOUR plants (`dot`,
`nodot`, `abs` = the absolute spelling under the relative runtime, `core` = `libcore`): both
engines must report `<11:10--11:23>`, a plant whose engines disagree is red. The two selftest
plants (`ignore-runtime`, `refuse-all`) catch 30 and 40 failing witnesses. Verbatim:

```text
check_runtime_resolution: selftest plant 'ignore-runtime' caught: 30 failing witness(es)
check_runtime_resolution: selftest plant 'refuse-all' caught: 40 failing witness(es)
check_runtime_resolution: fixture-001 --runtime=_build/install/default: 154 ./-prefixed header positions; oracle library=true; port library=true; oracle without ./=true; oracle on a foreign runtime/libcore directory=false (both engines agree: suffix AND resolved membership)
check_runtime_resolution: served agreement pin (dot): oracle=[Undefined {ub: "UB036_exceptional_condition", stderr: "", loc: "<11:10--11:23>"}] port=[Undefined {ub: "UB036_exceptional_condition", stderr: "", loc: "<11:10--11:23>"}]
check_runtime_resolution: served agreement pin (nodot): oracle=[Undefined {ub: "UB036_exceptional_condition", stderr: "", loc: "<11:10--11:23>"}] port=[Undefined {ub: "UB036_exceptional_condition", stderr: "", loc: "<11:10--11:23>"}]
check_runtime_resolution: served agreement pin (abs): oracle=[Undefined {ub: "UB036_exceptional_condition", stderr: "", loc: "<11:10--11:23>"}] port=[Undefined {ub: "UB036_exceptional_condition", stderr: "", loc: "<11:10--11:23>"}]
check_runtime_resolution: served agreement pin (core): oracle=[Undefined {ub: "UB036_exceptional_condition", stderr: "", loc: "<11:10--11:23>"}] port=[Undefined {ub: "UB036_exceptional_condition", stderr: "", loc: "<11:10--11:23>"}]
check_runtime_resolution: OK (27 witnesses: --runtime/CERB_INSTALL_PREFIX resolution and priority, planted cwd std.core ignored, planted prefix used, 5 runtime refusals, 1 cross-runtime and 3 library-location refusals, 1 control agreeing with the oracle, relative fixture-001 classifier agreement (both engines: suffix AND resolved membership) and execution control, 4 served UB-location agreement pins (./, unprefixed, absolute, libcore))
```

**The fork-ahead delta.** `util/cerb_location.ml` was byte-identical to upstream, so the
fork-drift manifest gains a NEW `[files]` row and a NEW `[source-content]` row
(`100644 776d942e10023b990787ba0f302c2b9f810f90a9bf2af3e0d48f119e0616d116 util/cerb_location.ml`)
with a dated header NOTE ("quotation hygiene Q1"), no `--refresh`; `[expected-semantic]`
untouched (no generated-model change). Gate and selftest, verbatim:

```text
check_fork_content: OK — 93 source files content/mode-pinned
check_fork_drift: OK — layer 1: 93 oracle-surface files = manifest (set, C-locale canonical, no duplicates); layer 2: 32 differing generated files, all hash-pinned (merge-base b9aeedcb4dd438763b0eef7f95ac19e93875d7de; lem-pin e6d8db5680962f49060257d6c2bcb13c284b910f matches lem -v lean-backend-v0.1.0-alpha.1-78-ge6d8db5 (hex prefix))
check_fork_drift: SELFTEST OK (31 plants with declared verdict/message: S1-S10 prerequisite/locale/name controls; S31 advanced upstream ref (not drift); S11 copied-content control; S12 inside-listed-file drift; S13/S14 duplicate/missing content pins; S15-S30 version forms, full-pin validation and refresh retention; unplanted gate green)
```

Tray 58 (`docs/upstream-tray/58-relative-runtime-library-location.md`): state line and remedy
section mark the remedy IMPLEMENTED IN THE FORK (the report stands for upstream's literal
rule); INDEX row and summary line updated. VALIDATION §3 gains a "Fork-ahead rule —
library-location classification by resolved directory" inventory entry (0 register rows; the
B10 re-run below); its §3(c) library-location bullet, the in-process-consumers bullet and the
§6 gate-table row now state the mirrored rule and that the admitted divergence class no longer
exists; README's convention bullet, `CerbLocation.lean`'s and `Main.refuseLibraryLocations`'s
docstrings, the caesium Core-quotation consumer note (a dated update paragraph), and LADDER
row 1 likewise.

**The pristine lanes (B10, row 10 of Tier B)** — the pristine binary keeps the literal rule;
every walked corpus runs both engines under one absolute runtime spelling on real files, so no
row was expected to move. Re-run after the change (`python3 scripts/test_upstream_oracle.py`,
through the container's `scripts/ce`, `CERB_MEM_MAX=32G`; the first attempt failed closed on the
oracle freshness stamp because the oracle had been rebuilt by plain `dune build` — re-recorded
with `tools/check_driver_fresh.sh --record-oracle`, then run), verbatim last lines:

```text
Independent oracle: passed; {'semantic_agreement': 950, 'matching_failure': 36, 'reviewed_difference': 9, 'interface_agreement': 2}; <worktree>/.tmp/upstream-oracle-zhsrlqw4/report.json
```

(997 cases; no `difference`/`incomplete` row, i.e. no walked case moved against pristine; the
report directory is ephemeral and deleted. Derived: the register is the 9 reviewed rows the
lane loaded.)


Lean side: `make lean-prelude-src` (sync gate OK), `capped lake build CerberusLean
cerberus-lean` (docstring-only changes to `CerbLocation.lean`/`Main.lean`, both hand-written
copies byte-identical to `generated/`), `tools/check_driver_fresh.sh --record-lean`.

Tier A (`python3 scripts/release.py --mode fast`, `CERB_MEM_MAX=32G`, box load 2.9, no other
`release.py`; evidence `.tmp/release/20261026T182630.780631Z`, deleted after reading), verbatim:

```text
PASSED A1 (820.4s)
PASSED A2 (31.4s)
PASSED A3 (82.1s)
PASSED A4 (30.9s)
PASSED A4b (27.1s)
PASSED A4c (3.2s)
PASSED A5 (108.7s)
PASSED A6 (4.5s)
PASSED A6b (4.0s)
PASSED A7 (11.6s)
PASSED A8 (9.5s)
PASSED A9 (17.6s)
PASSED A10 (18.7s)
PASSED A11 (64.6s)
PASSED A12.1 (5.2s)
PASSED A12.2 (4.7s)
PASSED A13 (1.7s)
PASSED A14.1 (119.6s)
PASSED A14.2 (168.9s)
PASSED A15 (404.6s)
fast: passed; 20/20 selected commands completed successfully.
Source unchanged: True. Complete tier selection: True.
Release certification: incomplete: reporting/adoption/audit exits require separate evidence.
```
