# Program-data parameters S0.5 — the cerberus half: Lake pin bump to the N-ary `reader_seed` lem (record, 2026-09-19/20)

Branch `arc/program-data-parameters` (cerberus-lean), from `d5a1025ff` (the
S0 record's successor head on this branch). Charter:
`lean_frontend/docs/2026-09-19_charter-program-data-parameters-S0.5.md`,
Part B; Part A (lem-lean) is recorded in lem-lean
`doc/lean-backend/2026-09-19_nary-reader-seed-record.md` at `4307dc5`.
Worker [AGENT] (Fable-class, chartered); the orchestrator's re-verification
and rulings quoted with `[AGENT, orchestrator]` provenance; every quoted
output is verbatim from this worktree
(`worktrees/cerberus-lean-arc/program-data-parameters`, evidence under its
ephemeral `.tmp/s05/`: `gen-before.sha256`, `gen-after.sha256`,
`stamps-before/`, `build_b3.log`, `release-tierA/` (report.json + per-lane
stdout/stderr), `row1_rerun.{stdout,stderr}`, `noise/`,
`scratch-forkdrift/`, `orch-partA-suite.log`,
`orch-partA-sweep-logs-only/`); tallies marked "derived" are derived.
Nothing merged, nothing pushed.

## 0. Summary

- The lem-lean backend rule the S0 record §1.6 asked for — with N declared
  readers a `reader_seed` def's first N parameters seed them, positionally
  in the global sorted reader order — landed as lem-lean `4307dc5`
  (Part A). This half moves cerberus-lean's Lake pin `LemLib` from
  `f6542f8` to `4307dc5108bbe71de2f323712443cab6c2b3c0da` and proves the
  bump is inert on this tree: the model declares ONE reader today, so the
  fixed backend must emit byte-for-byte what the pinned one emitted.
- Proven: both generated trees re-derived from wiped trees under
  `Lem 4307dc5` are byte-identical to the A0 snapshot taken under
  `Lem f6542f8` — 305 = 305 files, hash-list diff EMPTY (§5).
- Tier A: rows 2–12 (incl. 4b, 4c, 6b) green on the fresh binaries; row 1
  went red on ONE gate by that gate's design — the fork-drift manifest's
  `[meta] lem-pin` cross-check against `lem -v` — a rule conflict with the
  charter's fence (stop rule S4). The orchestrator extended the fence for
  exactly one manifest row plus one header NOTE; row 1 re-run green (§7).
- One follow-up finding from the stderr-noise adjudication (§8): a latent
  locale mismatch around `comm` in `scripts/check_lakefile_roots.sh:45-46`
  (fail-closed in the verdict direction by my analysis; the printed
  diagnostic can be wrong) — recorded, not fixed.

## 1. Rulings and the Q-B decision (restated, with its flag)

- [USER 2026-09-19]: *"I'm interested in making decisions that are
  consequential in some way but for the other kinds of decisions, which
  are really more implementation-focused, I think you can make the
  calls."* / *"yeah, I agree on Q2, let's roll it together"* — D-A and E-A
  are one arc, one consumer re-pin; S0.5 is its backend prerequisite.
- [USER 2026-09-04]: *"we don't change the lem structure for ocaml"* — no
  `.lem` and no hand-written Lean changed here; the generated OCaml tree
  is byte-identical (§5).
- [USER 2026-09-08]: *"we should \*NOT\* be building anything new
  out-of-policy"* — a pin bump, one manifest row, this record.
- **Q-B [AGENT, orchestrator], flagged to the operator** (charter §0; S0
  record §5): N-ary positional seeding in the global sorted reader order.
  Cerberus consequence, for E-A/D-A (NOT here): `mini_pipeline.lem:70
  run_const_expr_driver tds dr_st` becomes `run_const_expr_driver <digest>
  <enum_definitions> tds dr_st` — two leading parameters DEAD on the OCaml
  target, the precedent being the supply threading
  (`mini_pipeline.lem:80-86` *"On the OCaml target the threaded values are
  DEAD (the mints redirect ambiently)"*; `cabs_to_ail.lem:1131-1133`),
  accepted under the [USER 2026-09-04] rule. The partial-seed alternative
  would need a lifted-AND-seeded def shape the backend refuses ("reader_seed
  def unexpectedly reader-lifted"). Revisitable by the operator; if
  reversed, lem-lean Part A is what changes and this pin moves again.

## 2. Part A summary (lem-lean `4307dc5`; cited from its record)

Rule: `St.reader_seed_param` became a per-reader association (binder →
seed), built in `seed_info` over the first N clause patterns paired with
the sorted reader list; `reader_inject_name` looks the binder up; the
"exactly one declared reader" guard deleted (its concern — one seed name
overriding every binder — met by the association); two new refusals
(`reader_seed def must take N seed arguments (… order: …)`, `reader_seed
declared but no reader is declared (nothing to seed)`), the simple-variable
refusal reworded to the plural. Tests: `test_reader_multi.lem` +
`TestReaderMulti{Impl,Check,Exec}.lean` + phase `lean-reader-multi`,
`neg_seed_{arity,noreader,nonvar}.lem`, `inv_reader_multi.lem`. Suite tails
(lem-lean record §5): `=== Generation: 55 passed, 0 failed, 0 skipped ===`,
`Build completed successfully (169 jobs).`, `OK: compiled N-ary seed
injection holds`, 101/101 `OK (rejected as declared)`, `OK:
inv_reader_multi.lem (5 artifacts byte-identical across ocaml/hol/isa/coq)`,
parity 36 probes (26 OK + 6 both-fail + 4 registered XFAIL; derived),
`SUITE EXIT=0`; `via_seed3`/`uses_three` depend on `[propext,
Classical.choice, Quot.sound]`. Sweep (record §4): pinned `Lem f6542f8` vs
new — Lean output byte-identical on tests/comprehensive (57 invocations),
tests/backends (12), examples/ppcmem-model, examples/cpp; the only delta is
`test_reader_multi.lem`, which the pinned lem refuses (`reader_seed
requires exactly one declared reader`). `lean-lib/` byte-identical between
`f6542f8` and `4307dc5`.

## 3. Orchestrator boundary (the orchestrator's independent re-run, quoted)

From the re-launch message [AGENT, orchestrator] and its copied logs
(`.tmp/s05/orch-partA-suite.log`, `.tmp/s05/orch-partA-sweep-logs-only/`):
`scripts/ce make -C tests/comprehensive lean` at `4307dc5` → `=== SUITE
EXIT=0 ===`; `=== Generation: 55 passed, 0 failed, 0 skipped ===`; `Build
completed successfully (169 jobs).`; `  OK: compiled N-ary seed injection
holds`; 101 `OK (rejected as declared)` incl.
`negative/neg_seed_arity.lem`, `neg_seed_nonvar.lem`, `neg_seed_noreader.lem`;
`  OK: inv_reader_multi.lem (5 artifacts byte-identical across
ocaml/hol/isa/coq)`; parity 26 `OK: parity` + 6 `OK: both fail` + 4 registered
XFAIL (counts re-derived from the copied log: 26/6/4/4 FAIL-paired);
`'via_seed3' depends on axioms: [propext, Classical.choice, Quot.sound]`,
same for `'uses_three'`. The orchestrator's sweep (pinned `scripts/ce lem`
vs `./lem`, `-outdir` scratch): comprehensive identical except `Only in
…/c-new/test_reader_multi: Test_reader_multi.lean,
Test_reader_multi_auxiliary.lean`; backends 22/22, ppcmem 20/20 identical;
cpp refused on both. `c-old.test_reader_multi.log` (verbatim):

```
File "test_reader_multi.lem", line 81, character 30 to line 81, character 46
  Error: Lean backend: reader_seed requires exactly one declared reader
  original input: "draws_and_reads x"
```

The pin move, done by the orchestrator: `git -C deps/lem-pinned reset
--hard 4307dc5108bbe71de2f323712443cab6c2b3c0da` → `HEAD is now at 4307dc5
…`; `scripts/ce make rebuild-lem` → `⊘ removed lem.2026-05-01 / ∗ installed
lem.2026-05-01 / [LEM] installed Lem 4307dc5`; `scripts/ce lem -v` → `Lem
4307dc5`; `opam pin list --switch=.` → `lem.2026-05-01 git
git+file:///home/dev/projects/cerberus-lean-proj/deps/lem-pinned#cerberus-pin`.

## 4. B1 — the Lake pin, and the pin triple after the move

`lean_frontend/lakefile.toml` `rev` → the full hash, a six-line comment
block naming this slice in the existing trail (audit N2: not "one line"); then `scripts/ce
../scripts/capped lake update LemLib` in `lean_frontend/` (verbatim: `info:
LemLib: URL has changed; deleting '…/lean_frontend/.lake/packages/LemLib'
and cloning again` / `info: LemLib: cloning
https://github.com/OathTech/lem-lean` / `info: LemLib: checking out revision
'4307dc5108bbe71de2f323712443cab6c2b3c0da'` / `info: toolchain not updated;
already up-to-date`), then in `speclab/` and `tests/mem-scale-probes/micro/`
(`info: toolchain not updated; already up-to-date`) — the three
`lake-manifest.json` moved by Lake, not by hand. Exactly `be1cebe36`'s four
files (`git diff --stat`: `lean_frontend/lake-manifest.json | 4`,
`lean_frontend/lakefile.toml | 8`, `lean_frontend/speclab/lake-manifest.json |
4`, `tests/mem-scale-probes/micro/lake-manifest.json | 4`); every `"rev"` /
`"inputRev"` = `4307dc5108bbe71de2f323712443cab6c2b3c0da`. Fetched package
`git -C lean_frontend/.lake/packages/LemLib rev-parse HEAD` →
`4307dc5108bbe71de2f323712443cab6c2b3c0da`; `git -C <lem-lean worktree> diff
--stat f6542f8 4307dc5108… -- lean-lib` → empty; `diff -r` of the fetched
`lean-lib` against the lem-lean worktree's → empty. (Lake's re-clone means
the LemLib artifacts under `.lake/packages` were rebuilt in B3.)

**The pin triple after the move:** `deps/lem-pinned` HEAD
`4307dc5108bbe71de2f323712443cab6c2b3c0da` = opam pin target
(`lem.2026-05-01 git git+file:///…/deps/lem-pinned#cerberus-pin`, `lem -v` →
`Lem 4307dc5`) = Lake `LemLib` rev in the four files = lem-lean branch
`program-data-parameters` head `4307dc5108…`. **What is NOT yet true:**
lem-lean mainline `mdd/lean-backend` is still `f6542f8` — the pin dance's
remaining steps are the lem-lean pre-merge audit ask + ff-only merge of
`program-data-parameters` (then the pin equals the merged mainline head),
and cerberus's own ff-only merge of this branch on sign-off.

## 5. B2 — byte identity of both generated trees

A0 (before any lem-lean edit; `scripts/ce lem -v` → `Lem f6542f8`;
`scripts/ce make prelude-src lean-prelude-src`; the sync stamps re-recorded
to identical content): `find ocaml_frontend/generated lean_frontend/generated
-type f | sort | xargs sha256sum` → `.tmp/s05/gen-before.sha256`, 305 files
(86 + 219; derived split); extra `gen-before-sibylfs.sha256`, 16 files.

Precision (pre-merge audit N2 + delta re-read N8, 2026-09-20): whether
A0's `make prelude-src` re-ran lem on `ocaml_frontend/generated` is NOT
witnessed (no A0 log exists; the circumstantial evidence — `cp -a` priming
mtimes, the `stamps-before/` copy — taken post-A0, pre-B2-second-pass —
already at `src 037dee26…` — is undetermined either way; timing per the
audit's final-confirmation NOTE). Either way the snapshot's OCaml half hashes a tree generated
under `Lem f6542f8` with the lem-sync stamp in force, and that tree IS the
`f6542f8` reference: three wiped re-derivations
reproduce every one of its hashes — B2's second pass below (new lem), the
orchestrator's old-lem scratch worktree at `4e01a8811`
(`.tmp/s05/orch-oldlem-scratch-trees.sha256`, 305 = 305, `diff` empty)
and the auditor's third witness under both lems
(`2026-09-20_program-data-parameters-S0.5-audit-premerge.md` §2.2). The
lem-sync stamps themselves are git-ignored, so `git status` cannot
witness them; `check_lem_sync.sh --check`/`--check-lean` do (§5, §7).

B2 first pass — NOT a valid witness for the OCaml tree (charter erratum,
§9): `scripts/ce make prelude-src lean-prelude-src` with the `.lem` sources
unchanged is a timestamp no-op for `ocaml_frontend/generated` (only the
Lean-side `[LEM]` ran), so its empty diff re-hashed A0's own files.

B2 second pass — the witness: `scripts/ce lem -v` → `Lem 4307dc5`;
`scripts/ce make clean-prelude-src clean-sibylfs-src; rm -rf
lean_frontend/generated`; `scripts/ce make prelude-src lean-prelude-src`
(verbatim lines): `[LEM] generating files in [ocaml_frontend/generated]`,
`check_lem_sync: recorded ocaml_frontend/lem_sync.sha256 (src
037dee26c6472b1bf7f8d628bec1b7e64d2f9d12d67c81bd37b55e634fd34b2d, gen
08b84774381fd86eeb1a658efa47a9b372ebb438085530b5ab6ba045da3eec8d)`, `[LEM]
generating files in [sibylfs/generated]`, `[LEM] generating Lean files in
[lean_frontend/generated]`, `check_handwritten_sync: OK (49 hand-written
files byte-identical to lean_frontend/generated/; …)`, `check_lem_sync:
recorded lean_frontend/lem_sync.sha256 (src 037dee26…, gen
cd499eab48146463197f60b35a9fb26c31337bab7d06b2f1d9af43047c2619b5)`.
Then:

```
before: 305 files; after: 305 files
diff rc=0 (0 = EMPTY)
sibylfs diff rc=0 (16 files)
ocaml stamp IDENTICAL
lean stamp IDENTICAL
check_lem_sync: OK (src 037dee26c6472b1bf7f8d628bec1b7e64d2f9d12d67c81bd37b55e634fd34b2d, gen 08b84774381fd86eeb1a658efa47a9b372ebb438085530b5ab6ba045da3eec8d)
check_lem_sync: lean OK (src 037dee26c6472b1bf7f8d628bec1b7e64d2f9d12d67c81bd37b55e634fd34b2d, gen cd499eab48146463197f60b35a9fb26c31337bab7d06b2f1d9af43047c2619b5)
```

(`diff .tmp/s05/gen-before.sha256 .tmp/s05/gen-after.sha256` EMPTY at
305 = 305; the stamps compared against copies taken BEFORE regeneration —
the Makefile recipe always re-records, so "without re-record" is witnessed
by the re-recorded stamps being byte-identical to the previous ones and by
`tools/check_lem_sync.sh --check` / `--check-lean` both OK.) Stop rule S2
not triggered.

## 6. B3 — build and freshness

`DUNE_CACHE=disabled scripts/ce bash -c 'source scripts/common.sh &&
build_cerberus && build_lean'` then `scripts/ce ../../scripts/capped lake
build` in `lean_frontend/speclab` (`.tmp/s05/build_b3.log`): `check_driver_fresh:
recorded oracle stamp (bin
2751fb71ae2fee1847a6c57b2f3f03952a2d08fc797d33d225f10159489044cf, src
2b8b576816681316ce0c0b690dc78a63f813ac8a7391f976bdf4684a18f47634)`; `Build
completed successfully (285 jobs).` (`build_lean` retains lake's last three
lines only, by design); `check_driver_fresh: recorded lean stamp (bin
8e9f7fb1a1c99ef9a8ea05fcdddc8fa5f7cc961f1644a3680306699534595729, src
86bb9da365eeee8ef529e25f520a46c1f6753599861b219792ba13e5c168fa97)`;
`build_cerberus+build_lean rc=0 wall=260s`; speclab `Build completed
successfully (148 jobs).` `rc=0 wall=95s`; **`TOTAL wall=355s`** (5 min 55 s
— the charter's "one full Lean rebuild" was cheaper than budgeted: Lake
replayed the unchanged modules). `tools/check_driver_fresh.sh --check` →
`oracle OK (bin 2751fb71…)` / `lean OK (bin 8e9f7fb1…)`.

## 7. B4 — Tier A

Runner: `SKIP_BUILD=1 scripts/ce python3 scripts/release.py --mode fast
--out .tmp/s05/release-tierA` (rows A1–A12.2 serially; evidence
`report.json` + per-lane `stdout`/`stderr`); wall 501 s. Result: `fast:
failed; 15/16 selected commands completed successfully.` / `Source
unchanged: True. Complete tier selection: True.`

### 7.1 Rows 2–12 (all `rc=0`; verbatim summary lines)

| Row | Verbatim |
|---|---|
| A2 minimal | `SUMMARY: total=113 match=90 ub_match=18 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=5 cerb_floor=0 cerb_inconsistent=0` / `Baseline check: 0 regression(s), 0 improvement(s)` / `BASELINE OK` |
| A3 coverage | `SUMMARY: total=212 match=183 ub_match=16 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=13 cerb_floor=0 cerb_inconsistent=0` / `Baseline check: 0 regression(s), 0 improvement(s)` / `BASELINE OK` |
| A4 debug | `SUMMARY: total=90 match=66 ub_match=20 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=4 cerb_floor=0 cerb_inconsistent=0` / `Baseline check: 0 regression(s), 0 improvement(s)` / `BASELINE OK` |
| A4b float | `SUMMARY: total=93 match=93 ub_match=0 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=0 cerb_floor=0 cerb_inconsistent=0` / `Baseline check: 0 regression(s), 0 improvement(s)` / `BASELINE OK` |
| A4c bytes | `SUMMARY: exec_match=9 neg_pinned=5 fail=0` |
| A5 libc_exec | `SUMMARY: match=12 diff=0` / `ALL MATCH RECORDED BASELINE` |
| A6 multi_tu | `SUMMARY: total=2 match=2 fail=0` / `ALL PASSED` |
| A6b multi_tu tray | `SUMMARY: total=7 match=7 fail=0` / `ALL PASSED` |
| A7 parse | `Success rate:   100% (of cerberus successes)` / `ALL PASSED` |
| A8 core | `Success rate:   100% (of cerberus successes)` / `ALL PASSED` |
| A9 elab | `SUMMARY: total=113 same=108 diff=5 ocaml_fail=0 lean_fail=0` |
| A10 libxml2 uri | `[lean+libc] EXACT MATCH with ORACLE_LIBC (16/16 URI corpus)` / `GATE PASS: all lane expectations pinned-green + baseline unchanged (16/16)` |
| A11 cn coverage | `SUMMARY: total=213 match=207 ub_match=6 ub_diff=0 reject_match=0 diff=0 mismatch=0 reject_diff=0 lean_fail=0 lean_crash=0 fuel=0 lean_error=0 lean_timeout=0 oracle_fail=0 oracle_timeout=0 oracle_inconsistent=0` / `BASELINE OK (213 entries, exact match)` |
| A12.1 address space selftest | `test_address_space: SELFTEST OK (14 plants — …; the committed file green)` |
| A12.2 address space | `EXPECT OK    18 pinned rows = 18 observed cases, every token identical` / `test_address_space: OK (18 cases: LEAN = FORK through the shared codec at tops 64 32 8; every fork observation = its pinned row in expectations.txt)` |

These rows were NOT re-run after §7.3's manifest edit: no source, binary
or generated file moved (`Source unchanged: True`; the edit is to the
fork-drift manifest, which only row 1's `check_fork_drift.sh` reads), so
the tails above stand.

### 7.2 Row 1 first run — red on one gate (verbatim), stop rule S4

`FAILED A1 (228.5s)`. Every sub-gate green (`Total: 12 passed, 0 failed`
for the unit exes; `check_lem_sync: OK` / `lean OK`; `check_exec_totality:
CLEAN (22 generated modules + hand-written CerbND, 0 allowlisted)`;
`check_failure_reach: OK (233 pure failure sites = the 233 register rows
exactly …)`; the fork-drift selftest's fourteen plants `PLANT OK`) except:

```
  UNPLANTED:
  PLANT FAIL [unplanted gate is not green]:
      check_fork_drift: FAIL — lem-pin stale: manifest records lem-pin=f6542f8, 'lem -v' says 4307dc5 — both generated trees must be re-derived with the pinned lem and the manifest refreshed deliberately
check_fork_drift: SELFTEST FAILED (1)
test_unit: fork-drift gate SELFTEST FAILED
```

Standalone: `scripts/ce scripts/check_fork_drift.sh` → the same line, rc 1.
Cause: `scripts/check_fork_drift.sh:169-175` cross-checks the manifest's
`[meta] lem-pin=` against `lem -v` (audit F4 (c), P0 2026-09-05; plant S9
pins it). The charter §2 B4 asserted the gate passes "with no manifest
change" and §3 forbade editing `scripts/fork_drift_manifest.txt` — a rule
conflict; I stopped (S4), committed nothing, and reported. Evidence that
the lem-pin line was the ONLY stale element (no tree edit): the gate's own
plants S1–S3/S11 run the REAL fork/upstream trees with a stand-in lem
(`:336` `lem-ok` echoing the manifest's pin) and report `check_fork_drift:
OK — layer 1: 76 oracle-surface files = manifest …; layer 2: 25 differing
generated files, all hash-pinned` rc 0; and on a SCRATCH copy of the
manifest and the gate script (`.tmp/s05/scratch-forkdrift/`, `ROOT` and
`MANIFEST_DEFAULT` re-pointed) a `--refresh` produced a 286-line diff whose
only content change is `lem-pin=f6542f8` → `lem-pin=4307dc5` — the hash SET
is unchanged (rows reordered), the documented header is stripped and the
documentary `renumber=arc13` meta line dropped (the gate does not read it:
`grep renumber scripts/check_fork_drift.sh` → comment only) — after which
the scratch gate passes with `lem-pin 4307dc5 = lem -v`. The manifest's own
history therefore edits single rows and never runs `--refresh` wholesale.

### 7.3 S4 resolution [AGENT, orchestrator] and the manifest edit

The orchestrator's ruling (verbatim from the re-launch): *"S4 resolved
[AGENT, orchestrator]: the fence is EXTENDED for exactly one manifest row
plus one header NOTE — proceed to finish Part B."* with the premise
re-verified by the orchestrator (`check_fork_drift.sh:169-175`; the
manifest's header defines the line as *"the lem-lean commit BOTH generated
trees were derived with (the layer-2 hashes are relative to it)"*;
standing practice single-row edits + a header NOTE; precedent the
effect-retirement C1 note *"lem-pin -> af5df71 … the pin bump alone was
byte-identical on this tree"*). Done exactly as instructed:
`scripts/fork_drift_manifest.txt` `lem-pin=f6542f8` → `lem-pin=4307dc5`
(the `[meta]` row) and one dated NOTE at the top of the header (`git diff`
shows `+7` header lines and the one `-/+` row, nothing else). Standalone
gate after the edit:

```
check_fork_content: OK — 76 source files content/mode-pinned
check_fork_drift: OK — layer 1: 76 oracle-surface files = manifest (set, C-locale canonical, no duplicates); layer 2: 25 differing generated files, all hash-pinned (merge-base b9aeedcb4dd438763b0eef7f95ac19e93875d7de; lem-pin 4307dc5 = lem -v)
```

### 7.4 Row 1 re-run in full (`scripts/ce ./scripts/test_unit.sh`)

`test_unit rc=0 wall=241s` (`.tmp/s05/row1_rerun.stdout`, 750 lines;
`.stderr`, 90 lines). The gate's line, verbatim (stdout `:736`; the
selftest's unplanted pass at `:733` is the same line):

```
check_fork_drift: OK — layer 1: 76 oracle-surface files = manifest (set, C-locale canonical, no duplicates); layer 2: 25 differing generated files, all hash-pinned (merge-base b9aeedcb4dd438763b0eef7f95ac19e93875d7de; lem-pin 4307dc5 = lem -v)
check_fork_drift: SELFTEST OK (14 plants with declared verdict/message: S1-S10 prerequisite/locale/name controls; S11 copied-content control; S12 inside-listed-file drift; S13/S14 duplicate/missing content pins; unplanted gate green)
```

The runner's final line (stdout `:750`):
`test_renumber_plants: OK (12 plants: refusals refuse, admits admit with declared class)`.
Other row-1 tails unchanged from the first run (`Total: 12 passed, 0
failed`; `check_lem_sync: OK` / `lean OK`; `check_exec_totality: CLEAN
…`; `check_failure_reach: OK (233 …)`; `check_lakefile_roots: OK (218 roots
= 218 generated modules + the exe root Main; 85 auxiliary modules all
built)`; `check_fuel_forms: OK (81 fuel'd workers: 62 MEASURED …)`).

## 8. The two stderr noise shapes in row 1 (adjudicated; nothing fixed)

Both reproduced identically in the re-run (`row1_rerun.stderr:84-90`) and
attributed by running each candidate gate alone with stderr captured
(`.tmp/s05/noise/`): `check_fork_drift.sh --selftest` 0 comm lines;
`check_lakefile_roots.sh` (real path) 0; `check_lakefile_roots.sh
--selftest` **6**; `test_exec.sh --selftest` 0 comm / **1** OBSERVATION
ERROR; `check_fuel_forms.sh` 0.

**(a)** `OBSERVATION ERROR: unknown or malformed stdout record: b'Defined
{value: "Specified(0)", stdout: "'` — emitted by
`scripts/observations.py:420` (`print(f'OBSERVATION ERROR: {exc}',
file=sys.stderr)`) for the `ProtocolError` raised at `:332`, when
`scripts/test_exec.sh --selftest` plant E7 (`test_exec.sh:335`: `check "E7
no token from a truncated Defined line" '' 'Defined {value: "Specified(0)",
stdout: "'`) feeds the extractor a deliberately truncated line and expects
NO token. Expected plant noise: stdout `:619` `test_exec: SELFTEST OK (…
truncated line is no token)`. Not a finding.

**(b)** the six `comm: file 1 is not in sorted order` / `file 2 …` /
`input is not in sorted order` lines (2 × 3) — emitted by
`scripts/check_lakefile_roots.sh:45-46` (`missing=$(comm -13 <(echo
"$roots") <(echo "$gens"))`, `extra=$(comm -23 …)`) during its
`--selftest` plants (a root removed; a phantom root added). Cause: both
inputs are sorted in the C locale (`:22-33` `roots_of … | LC_ALL=C sort`,
`:42` `gens=… | LC_ALL=C sort`) but `comm` runs under the ambient locale
(`LANG=en_US.UTF-8`, `LC_ALL` unset under `scripts/ce`; `LC_COLLATE=
"en_US.UTF-8"`), whose collation orders names like `Core_aux`/`CoreParser`
differently. GNU `comm` checks input order by default ONLY when it meets
unpairable lines — so the REAL path (218 roots = 218 modules, all
pairable) is silent today, and the plants (unpairable lines by
construction) trip the check. **Finding (follow-up, not fixed here — out
of fence):** on the real path the `comm` inputs are genuinely
sorted-for-a-different-locale, the same shape `check_fork_drift.sh:84`/`:125`
repaired for that gate (`export LC_ALL=C`, audit F4). Consequence by my
analysis [AGENT]: when a real drift occurs, `comm`'s merge over
mis-ordered input can misattribute names to columns, so the printed
`missing`/`extra` lists may be WRONG — but every unpaired input line is
still emitted in some column and equality is string identity, so a
genuinely missing/extra module cannot be hidden as "common": the verdict
stays fail-closed (false FAILs possible, false PASS not); the three plants
did go red as declared. Remedy for the owner: `export LC_ALL=C` in
`check_lakefile_roots.sh` (mirror of `check_fork_drift.sh:84`), then the
selftest's stderr is clean. `check_fuel_forms.sh:161-162,183-184` sort and
`comm` in the same (ambient) locale — consistent, 0 warnings.

## 9. Charter errata

- §3 fence / §2 B4 assumed the fork-drift gate needs no manifest change on
  a pin bump: it does — the `[meta] lem-pin` cross-check
  (`check_fork_drift.sh:169-175`) exists since the P0 2026-09-05 repair;
  resolved by the orchestrator's one-row fence extension (§7.3). Future
  pin-bump charters should list `scripts/fork_drift_manifest.txt` (one
  `lem-pin=` row + NOTE) among the bump's files.
- §2 B2 "regenerate" via `make prelude-src` is a timestamp no-op for the
  OCaml tree when no `.lem` changed; the valid witness is a wiped
  re-derivation (`make clean-prelude-src clean-sibylfs-src; rm -rf
  lean_frontend/generated; make prelude-src lean-prelude-src`), as
  `be1cebe36` did — redone here (§5).
- Lake's `lake update LemLib` re-cloned the package ("URL has changed"),
  so the "full Lean rebuild" the charter budgeted at up to ~1 h took 260 s
  (Lake replayed the unchanged modules).
- Pre-merge audit M1 (MINOR, 2026-09-20): the S0 evidence directory's
  `logs/` had 11 of its 12 `INDEX.txt`-listed files UNCOMMITTED — the
  repository-wide `.gitignore:59` `*.log` (a Coq/LaTeX artefact rule)
  swallowed them at `f417066ff`; the three generation-time quotes drawn
  from them (S0 record §1.5 N0/N1/N2) were re-derived true by the auditor;
  the build-log quotes (§1.4 tail, N3, N4) rest on the files matching
  INDEX.txt's hashes (audit delta re-read M2). Fixed in the audit-fix commit by
  `git add -f` of the 11 files (each `sha256sum -c` OK against INDEX). A
  `.gitignore` negation for evidence directories is an operator call (no
  earlier evidence directory carries a `.log`); not made here.

## 10. Inputs to the E-A/D-A charter

- Pre-merge audit N1 (2026-09-20): positional seeding takes a def's OWN
  leading parameter as the N-th seed whenever the parameter count is ≥ N
  (`let seed_two av bv x` under three readers compiles with `x` as
  gamma's seed AND the own argument — type-guarded only). Every seed def
  E-A/D-A writes therefore gets a per-seed VALUE pin (a swap or a slide
  changes an observable value), and lem-lean `DESIGN.md`'s `reader_seed`
  row gains that sentence at its next touch.
- The `.lem` head change the N-ary rule enables: `mini_pipeline.lem:70
  run_const_expr_driver tds dr_st` → `run_const_expr_driver <digest>
  <enum_definitions> tds dr_st` (seed order = sorted reader names:
  `digest`, `enum_definitions`, `tagDefs`), dead on the OCaml target
  (§1's precedent) — the generated OCaml moves at one function + one
  caller, so `scripts/fork_drift_manifest.txt`'s layer-2 hash pins for
  `mini_pipeline.ml` (and its caller's module) are re-pinned THERE, by
  single-row edits with a NOTE (§7.2's `--refresh` observation).
- The E-A rules 1–7 of the S0 record §1.6 (sorted-name order everywhere;
  every lifted def takes all readers; value pins for the two same-typed
  maps; seeds' callers pass values; supply/fuel compose unchanged;
  non-lifted positions fail-closed; reserved names).
- Consumer (cerberus-sl) re-pin note: `+2 leading arguments` on every
  reader-taking signature, at E-A/D-A's end, not here.

## 11. Commit and worktree state

One commit: the four pin files (§4), `scripts/fork_drift_manifest.txt`
(§7.3, one row + one NOTE), this record. Untracked evidence stays under
`.tmp/s05/` (ephemeral, deleted at slice end; the verbatim lines above
are the record). Nothing pushed; `arc/program-data-parameters` awaits the
pre-merge audit ask and sign-off; lem-lean `program-data-parameters` awaits
its own.

## 12. Landing (2026-09-20)

[USER 2026-09-20], verbatim: *"Go ahead with both merges"* — the sign-off
for the two named merges of the orchestrator's merge ask: **merge 1**
lem-lean `mdd/lean-backend` `f6542f8` → `4307dc5` (ff-only, one commit, the
pinned hash unchanged); **merge 2** cerberus `mdd/cerberus-lean`
`b7e45d55e` → the arc head including this landing commit (ff-only: the
audited range `b7e45d55e..aa6effbd2`, the three audit-document commits
cherry-picked from `audit/program-data-parameters-S0.5`, and this note).
Order lem-lean first, then cerberus, by the orchestrator in the primary
checkouts. After both, the pin invariant re-closes: lem-lean mainline =
`deps/lem-pinned` = opam pin (`lem -v` → `Lem 4307dc5`) = the Lake
`LemLib` rev. Then: the primary checkout's generated trees are re-derived
(stale since before the 2026-09-17..19 merges — audit N4); the lem-lean
worker and audit worktrees and the cerberus audit worktree retire;
`arc/program-data-parameters` continues into E-A/D-A.

Follow-ups carried forward (none blocks): audit N1 → per-seed VALUE pins
in the E-A/D-A charter + the `DESIGN.md` `reader_seed` sentence at the next
lem-lean touch; audit N6 → `scripts/check_lakefile_roots.sh` `export
LC_ALL=C` (a one-line gate fix, its own commit); the `.gitignore` negation
for evidence-directory logs — an operator call.
