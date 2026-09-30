# Pre-merge audit: bug-hunt fixes, `4198f9194..1f72155d2` (2026-09-30)

Auditor: a fresh Claude (Opus 5.5) agent with no prior context. Branch `audit/bug-hunt-fixes-20260930` at
`1f72155d2`. Scope, verbatim: [USER 2026-09-30] "Go ahead with the audit in parallel with the ladder". The range is
10 commits on `arc/bug-hunt-fixes`, proposed for a fast-forward of `mdd/cerberus-lean`. The operator rule applied
throughout, verbatim: [USER 2026-09-30] "we should not fix deviations with special 'magic mode' paths that work
exclusively in one situation".

## Verdict

**MERGEABLE WITH FIXES** [AGENT].

The code is correct on every point I checked:
- runtime resolution mirrors `util/cerb_runtime.ml`;
- the suffix and exact library tests agree on every input the driver accepts;
- the UTF-8 refusal is correct and attributed;
- the `ub:` field is printed as bytes, and nothing else in the printer changed;
- every harness passes the oracle's runtime to the driver.

The three new checks fail closed under my own plants as well as the scripts' own plants. No change in the range adds
a special-mode path.

The findings are about records and small check holes. Two of them concern provenance (M1, M2). The house rules treat
provenance as trust-critical, so I recommend fixing M1 and M2 before the merge. The LOW items can be fixed before the
merge or queued.

## Findings, ranked

### M1 (MEDIUM, provenance): `resolveRuntime` attributes [AGENT] choices to the [USER] ruling

`lean_frontend/Main.lean:580-590`, verbatim:
```
    - DELIBERATE DIVERGENCE (bug-hunt fixes S2, [USER 2026-09-29] "Agree on
      everything, yes on the fixes"): the oracle's last arm, `OPAM` — ...
    - DELIBERATE DIVERGENCE (same ruling, fail-closed): an EMPTY value (either
      source) is refused.
```
The fix record labels the same two choices differently. `docs/2026-09-29_bug-hunt-fixes-record.md:5-8`: "the slice
list and the refusal choices (BUG-2's `OPAM_SWITCH_PREFIX`, ...) are from the orchestrator's brief under that ruling".
`:26`: "[AGENT] an EMPTY `--runtime`/`CERB_INSTALL_PREFIX` is refused".

The bug hunt's BUG-2 options (`docs/2026-09-29_discrepancy-bug-hunt.md:177-180`, (a)–(c)) do not include refusing the
OPAM arm, so the ruling did not pick it. The code therefore says [USER] where the record says [AGENT] (orchestrator).

Fix: relabel both bullets. For example: "[AGENT] (orchestrator's brief under [USER 2026-09-29] "Agree on everything,
yes on the fixes")" for the OPAM refusal, and "[AGENT]" for the empty-value refusal.

### M2 (MEDIUM, provenance): the N3 ruling's option numbers point to a list that is not recorded

The ruling is quoted identically in four places, and the quote itself is consistent:
- VALIDATION §2b N3 (`VALIDATION.md:293`);
- CONTRACT D8 (`CONTRACT.md:158-159`);
- the record (`2026-09-29_bug-hunt-fixes-record.md:373`);
- TODO (`TODO.md:654`, a shortened form).

It reads: "Right, I think (3) is the right answer for now, and (1) or (2) might be work for later."

The problem is the numbering. The record's own option list is labelled (A)–(E) (`:306-332`). No committed document
defines options (1), (2) and (3); I grepped `docs/2026-09-29_*`, VALIDATION, CONTRACT and TODO. Three mappings are
agent interpretations, and none is labelled [AGENT]:
- the record maps "(3)" to "option (E), extended" (`:372`);
- TODO.md defines "(1)" as a round-tripping printer and "(2)" as libc built from C sources;
- `test_unit.sh:414` and `CoreParser.lean:101` say "[USER 2026-09-30] option (3)", as if (3) were a recorded option.

A reader cannot check what the operator agreed to.

Fix: commit, verbatim, the orchestrator's message that listed options (1)–(3). Add it to the record's S5 addendum and
label the mapping to (E) and to the TODO routes [AGENT].

### L1 (LOW, records): stale failure-reach cites after `2fbdc3e29`

Commit `be5cb76b9` kept the CoreParser note at the same line count. The record states it at
`2026-09-29_bug-hunt-fixes-record.md:338-339`: "Same line count as before, so the failure-reach register's
`CoreParser.lean:NNNN` cites are not shifted". Commit `2fbdc3e29` then made the note 2 lines longer (the diff hunk is
`@@ -92,14 +92,16 @@`). Every CoreParser line after 106 moved down by 2:
- `scripts/failure_reach_register.txt` cites `CoreParser.lean:514-525` 4 times. At HEAD the `enum` arm is at 516-527,
  so the cited range misses the arm's own line 527 and includes two `signed`/`unsigned` lines.
- `CoreParser.lean:2408-2416` still contains the moved `failwithI`, which is now at 2415.

S4 updated the `Main.lean` cites for exactly this kind of shift. I verified that `Main.lean:1573-1607` is correct at
HEAD. Cites are outside the seal hash, so no gate catches this.

Fix: re-cite to `516-527` and `2410-2418`, and correct the record sentence (it was true only until `2fbdc3e29`).

### L2 (LOW, check hole): `check_libc_float_literals.py` compares sets, not multisets

`scripts/check_libc_float_literals.py:54-55`:
```
    have = {(l, t) for l, t in live}
    want = {(l, t) for l, t, _ in rows}
```
Two plants of mine pass the check. The harness was a scratch copy that imported `check()`:
```
P1 dup literal same line: PASS []
P7 dup register row EXACT+LOSSY for a 1-digit literal: PASS []
```
- P1 appends a second `0.` to line 53379, which already holds `0.`.
- P7 adds a conflicting duplicate register row.

This conflicts with N3's claim at `VALIDATION.md:293`: "every float literal of the dump = the reviewed register ...
both directions".

Fix: compare `collections.Counter`s, reject duplicate `(line, literal)` register keys in `load_register`, and add both
plants to `--selftest`.

Two related notes (information only):
- The census regex ignores `inf`. The dump holds 4 `Specified(inf)`, which is why the record's census counts 28 and
  the register 24. `inf` is exact, but the "every float literal" wording should say "every finite decimal literal".
- The 12-significant-digit rule is necessary, not sufficient. A short literal can be lossy: plant P4, `0.3` for a
  computed `0.1+0.2`, passes when registered EXACT-BY-SOURCE. EXACT-BY-SOURCE therefore rests on review, as its name
  says. No wording claims otherwise, but the register header could say so.

### L3 (LOW, fail-open shape): a repeated `--runtime` silently takes the last value; the oracle rejects it

`lean_frontend/Main.lean:1483` is `| "--runtime" :: v :: rest => runtimeArg := some v; pending := rest`, and the
`--runtime=` arm below it does the same. Measured, verbatim:
```
cerberus: option --runtime cannot be repeated          (oracle, rc=124)
Defined {value: "Specified(0)", stdout: "", stderr: "", blocked: "false"}   (Lean, --runtime=/nonexist --runtime=<real>, rc=0)
```
`--fuel` and the other value flags follow the same silent pattern. That behaviour predates the range, but the new flag
copies it.

Fix: refuse a second `--runtime` (exit 2, attributed) and add a witness to `check_runtime_resolution.sh`. Consider the
same fix for the other value flags as a separate slice.

### L4 (LOW, records scope): the retirement of Z-67 holds for the driver only

Two places state that Z-67 is gone:
- `CerbLocation.lean:234`: "This replaces the earlier documented residual Z-67";
- the record, `:39`: "the old residual "Z-67" is retired".

The docstring's equivalence argument is correctly scoped: "on every input the driver ACCEPTS". But an in-process
consumer that calls `CabsImport.parseJson`, which is kept unchanged, and the pure `CerbLocation.isLibraryLocation`
never passes through `Main.refuseLibraryLocations`. For such a consumer the Z-67 residual still exists: a user path
under `…/runtime/libcore` is classified as library code by Lean and not by the oracle. cerberus-sl is the named
consumer.

Fix: either state the consumer-API residual in the docstring and in VALIDATION §3 ("In-process consumers" bullet,
`:469`), or expose a library-level check that consumers can call (the file list from `parseJsonWithFiles` plus the
runtime). Record the choice.

### L5 (LOW, records): VALIDATION §6 has no row for the float-literal check

`VALIDATION.md:812-813` adds §6 gate-table rows for `check_runtime_resolution.sh` and `check_cabs_json_utf8.sh`.
`check_libc_float_literals.py` also runs from `test_unit.sh` (`:419-423`, wired correctly, both `--selftest` and the
real check), and LADDER row 1 names it. §6 does not.

Fix: add the row (what it pins, the 6 plants, N3).

### L6 (LOW, records): R2's widened scope is not reflected in its ruling and 2nd-oracle columns

The R2 row at `VALIDATION.md:277` widens the difference column and the pins. Two cells are unchanged:
- the "2nd oracle" cell still says only "gcc 127";
- the ruling cell still says only "**ADMITTED** [USER 2026-09-03]".

The widening's gcc values (200, 199) appear only in the fixture comments (`tests/immaculate/libc/zd-r2-*.c`). Its
ruling ("[USER 2026-09-29] "Agree on everything"") appears only in the `tests/immaculate/baseline.txt` comment. N1's
widening, in the same range, did add its ruling to the ruling cell. The ISO-fix register carries the highest evidence
bar in the project.

Fix: add "gcc 200 / 199 (widened rows)" to the 2nd-oracle cell and "scope widened [USER 2026-09-29] ("Agree on
everything, yes on the fixes")" to the ruling cell.

### L7 (LOW, stale recipe): the failure-probes replay recipe now refuses

`tests/failure-probes/reach/README.md:16` runs `lean_frontend/.lake/build/bin/cerberus-lean --batch --first ...
x.json` with no `--runtime`. The recipe says to source `scripts/env.sh` first (`:10-11`), but the container's `env.sh`
does not export `CERB_INSTALL_PREFIX`; I grepped it. The driver therefore refuses with "no runtime given". That is
loud and correct behaviour, but this is the documented replay route for the register's REACHABLE witnesses. The
record's harness census (`:44-56`) covers scripts only.

Fix: add `--runtime=$RT` (the recipe already defines `RT=_build/install/default`).

### Information only (no action required)

- **N3 has no behavioural pin.** N1 and N2 each carry DIFF rows that flip when the mover lands. N3's witness column
  names only the inventory check. The bug hunt's `b2_lb09`/`b2_sd5` (`strtod` ERANGE) could become a `tests/immaculate/libc/` DIFF row if its
  running time is acceptable; `zd-funptr-libc-conflate` shows that libc-mode rows exist.
- **Gaps in the UTF-8 witnesses.** `check_cabs_json_utf8.sh` covers user-file inputs only. `--stdin` and the
  libc-metadata-TU path use the same `decodeCabsJson`, but no witness exercises them. The `Loc_other` and
  magic-comment members, which VALIDATION §3(c) lists, are also not witnessed.
- **Stale function name.** `scripts/check_cabs_json_utf8.sh:14` cites "Main.lean readCabsJson". The functions are
  `decodeCabsJson`/`readCabsJsonFile`.
- **Out-of-driver readers of the source-tree `std.core`.** Two Lean programs other than the driver still read the
  source tree's `std.core` through a relative or working-directory search:
  - `speclab/test/SLUnit/EmitCore.lean:790,1060,1378` (`findRoot`, then `root ++ "runtime/libcore/std.core"`);
  - `test/Unit/CoreParserTest.lean:827,844` (`"../runtime/libcore/…"`).

  Neither is the Lean driver, and the range's claim is about the driver, but the working-directory lookup pattern is
  the same. The installed `std.core` is a symlink into `_build/default/runtime/libcore/std.core`, which comes from the
  source tree, so today they read the same content.
- **Attribution of arbitrary non-UTF-8 input.** `decodeCabsJson` attributes any non-UTF-8 input to the exporter, for
  example a non-JSON file passed by mistake. The message states the fact first ("… is not valid UTF-8"), so this is
  acceptable.
- **No special-mode path found.**
  - `--runtime` mirrors the oracle's own flag.
  - The library-location refusal applies to every run and to every Cabs file, user TUs and libc metadata TUs alike.
  - The UTF-8 refusal covers every Cabs read path.
  - `printUndefinedLine` serves all three batch `Undefined` sites.
  - `CERB_INSTALL_PREFIX` is exported once in `common.sh`.
  - N3 explicitly declined the opt-in printer.
- **The N1 widening classifies an oracle bug as a named deviation.** BUG-1 is a case where Lean is ISO-right and the
  oracle is wrong, and it is recorded in N1 (class (e)) rather than in the ISO-fix register (class (d)). That was the
  bug hunt's option (a) (`discrepancy-bug-hunt.md:114-117`), and the ruling covered it. I note it only for
  consistency with R2, which took the class (d) route for a Lean-right case.

## What I verified and how

**Code: runtime resolution.**
- Read `Main.lean` `filenameConcat`, `runtimeOfPrefix`, `resolveRuntimeRoot`, `resolveRuntime` and `runPipeline`
  against `util/cerb_runtime.ml:9,38-56,76-84` and `backend/common/pipeline.ml:28-50`.
- Order: `--runtime` (SPECIFIED arm), then `CERB_INSTALL_PREFIX` (ENV_VAR arm), then refuse. The runtime is
  `prefix/lib/cerberus-lib/runtime`, built with an exact `Filename.concat` mirror.
- The `std.core` and `.impl` paths are built the way `pipeline.ml` builds them, and the same strings are stamped by
  `CoreParser.parseLibraryFile`.
- The only divergences are the refused OPAM arm and the refused empty value, both documented at the definition (but
  see M1).
- Measured: a trailing slash (`--runtime=<p>/`) resolves to the same string. A relative prefix given against an
  absolute-prefix export is refused, not misclassified:
  ```
  cerberus-lean: refused — library-location classification: the input … carries a source location in `…/bug-hunt-20260929/_build/install/default/lib/cerberus-lib/runtime/libc/include/builtins.h`, …
  ```

**Code: suffix test equals exact test.**
- Direction exact ⇒ suffix: `runtimeOfPrefix` always ends in `…/cerberus-lib/runtime`, because `"cerberus-lib"`
  never ends in `/`. Each exact directory therefore ends in `/runtime/{libc/include,libcore,libcore/impls}`.
- Direction suffix ⇒ exact: `refuseLibraryLocations` refuses when the suffix test passes and exact membership fails.
- Coverage of `positionFiles`: `cabs_json.ml:28-58` emits file strings only through `json_of_pos`
  (`{"file","line","col"}`), and `positionFiles` collects every such object, cursors and region ends included. It is
  an over-approximation, which can only cause over-refusal.
- Other file-carrying locations:
  - `std.core` and `.impl` stamps: exact by construction.
  - `--libc` dump bodies: `parseFile`, with no stamped file.
  - `Loc_other`: `getFilename` gives `"<internal>"` in both engines, and its dirname `.` is never a library
    directory.
  - `CoreParser.lean:238`, file `""`: dirname `.`.
- `dirname` against OCaml's `generic_dirname`: I traced `"a//b"`, `"/b"`, `"//b"`, `"/"`, `"R/libcore/"` and a bare
  name, and they agree.
- `#line` paths and user headers are covered by the witnesses (below). Relative and absolute prefixes are covered
  above.

**Code: UTF-8.** Every Cabs read goes through `IO.FS.readBinFile` or a byte `stdin.read` loop, then
`String.fromUTF8?`: the input files, `--stdin` and the libc metadata TUs (`loadLibc`). `firstInvalidUtf8` is
diagnostic only. The message names the fields with `cabs_json.ml` cites and points to §3(c).

**Code: `ub:` printed as bytes.**
- `printUndefinedLine` replaces exactly the three batch `Undefined` sites (`Main.lean:719,751,1275`).
- The `stderr` and `loc` fields are the same strings, UTF-8-encoded as before.
- Source of the payload: `stringFromUndefined_behaviour` (`undefined.lem:1092-1108`) returns ASCII bimap names,
  `DUMMY(…)` with ASCII payloads (every `DUMMY` construction in `frontend/model/*.lem`), or
  `Invalid_format[<format bytes>]`.
- The non-ASCII characters of `std.core`/`.impl` are in comments only (grep), and `libc.core` has none.
- The refusal above U+00FF is therefore a guard that cannot be reached today, which is fail-closed.
- The human-mode printers are unchanged.

**Silent defaults.** Apart from L3, I found no absorbed failures in the touched code:
- empty values are refused;
- a missing `std.core` or `.impl` is refused;
- the input-name label falls back to `"<input>"`, which is cosmetic.

**Harness completeness.**
- I grepped every non-doc file for `build/bin/cerberus-lean`, `CERBERUS_LEAN_BIN`, `LEAN_BIN`, `lean_bin` and
  `run_cerberus_lean`: 47 files.
- All shell harnesses source `common.sh`, which exports `CERB_INSTALL_PREFIX="$PROJECT_ROOT/_build/install/default"`
  (hash `3ef7b1ae…`, which equals the fork-drift manifest row). The exceptions pass `--runtime` explicitly:
  - `check_cli_refusals.sh`;
  - `check_runtime_resolution.sh` and `check_cabs_json_utf8.sh`;
  - `tests/{z2,parity,noodle}-probes`, `…/dynamic-addrs/run_dynaddr.sh` and `tests/mem-scale-probes/measure.sh`, each
    using its oracle's `$RUNTIME`.
- Every lane's `RUNTIME_DIR=` is `"$PROJECT_ROOT/_build/install/default"` (18 definitions).
- The Python drivers:
  - `test_upstream_oracle.py` sets `CERB_INSTALL_PREFIX` to the fork bridge runtime;
  - `test_cabs_bytes_probe.py` sets it explicitly;
  - `test_batch_diagnostics.py` and `test_observation_lanes.py` inherit it from `common.sh`-sourcing parents;
  - `release.py` and `measure_csmith_cpu.py` launch lanes, not the driver.
- No harness scrubs the environment around a Lean call (`env -i` occurs only in the gcc lane's program run).
  `tests/common.sh:15` unsets the variable only for the upstream OCaml test harness, which never runs Lean.
- The other Lean executables (`speclab-*`, `memory-access-test`, `failure-probes`, the unit tests) do not load a
  runtime through the driver (see the information note).
- Missed documentation recipe: L7.

**New checks: selftests.** I re-ran all three from a scratch shadow root inside my worktree. The shadow root holds
copies of the scripts; the binaries, `_build` and the runtime are symlinks, so the ladder worktree was not written.
The binaries are that worktree's built `1f72155d2`: the stamp `driver_fresh.lean.sha256` says `commit 1f72155d2…`,
and `bin e7b907c9…` equals the binary's sha256. The runs were wrapped in `CERB_MEM_MAX=32G scripts/capped`. Verbatim:
```
check_runtime_resolution: selftest plant 'ignore-runtime' caught: 11 failing witness(es)
check_runtime_resolution: selftest plant 'refuse-all' caught: 17 failing witness(es)
check_runtime_resolution: OK (17 witnesses: --runtime/CERB_INSTALL_PREFIX resolution and priority, planted cwd std.core ignored, planted prefix used, 5 runtime refusals, 1 cross-runtime and 3 library-location refusals, 1 control agreeing with the oracle)
check_cabs_json_utf8: selftest plant 'uncaught' caught: 9 failing witness(es)
check_cabs_json_utf8: selftest plant 'refuse-all' caught: 9 failing witness(es)
check_cabs_json_utf8: OK (9 witnesses: 5 non-UTF-8 Cabs JSONs refused with the attributed message (#line raw byte, #line octal escape, real file name, #include name, attribute string); 4 ASCII controls agree with the oracle)
check_libc_float_literals: SELFTEST OK (6 plants: unplanted OK; added, dropped, relabelled-lossy, empty dump, malformed register all FAIL)
check_libc_float_literals: OK (24 float literals in tests/libc/libc.core = the register exactly; 1 LOSSY-N3)
```
These lines match the record's quotes (`:99-101`, `:172-174`).

**New checks: my own plants** (verbatim tails):
- A stub that exits 0 with empty output: `check_runtime_resolution: 17 of 17 witnesses FAILED` and
  `check_cabs_json_utf8: 9 of 9 witnesses FAILED`. An empty result never reads as a pass.
- The real driver with the BUG-3 refusal masked (it prints a verdict instead):
  `check_runtime_resolution: 4 of 17 witnesses FAILED`.
- The real driver with an `OPAM_SWITCH_PREFIX` fallback added: `check_runtime_resolution: 1 of 17 witnesses FAILED`.
- The real driver fed a UTF-8-repaired copy of each JSON: `check_cabs_json_utf8: 5 of 9 witnesses FAILED`.
- Float check plants:
  - an empty register (comments only) FAILS;
  - a new 12-digit literal registered EXACT-BY-SOURCE FAILS;
  - a moved lossy literal FAILS;
  - P1, P4, P5, P7 and P8 pass (L2 and its notes). P8 is a hex literal, which the `%.12g` printer cannot emit.

**Wiring.** All three checks are called from `scripts/test_unit.sh:394-423` with `if ! …; then exit 1`: both shell
scripts with `--selftest` (which ends with the real run, `"$0"; exit $?`), and the float check with `--selftest` and
then the real check. All three are described in LADDER row 1. VALIDATION §6 lacks the float check (L5).

**Records.**
- VALIDATION §2b:
  - N1 (widened) matches the witness row `zd-funptr-libc-conflate DIFF` and tray 48;
  - N3 matches the code note (marker `NAMED DEVIATION N3`), the register (24 rows, 1 LOSSY-N3) and the check;
  - R2 (widened) matches the new pins `zd-r2-highbyte DIFF` and `zd-r2-crash-digit9 ORACLE_CRASH` (but see L6).
- VALIDATION §3(c): the three new entries match the code's refusal prefixes and messages.
- CONTRACT: the rows and D8 match VALIDATION. Z1-A1 is present at `VALIDATION.md:456`.
- Tray 48 and the INDEX: the counts (53 files, 48 Draft) match the new draft.
- The claims-register line matches the range. The diffstat shows no `.lem` change.
- The fork-drift manifest re-pin hash equals `sha256sum scripts/common.sh`.
- [USER] quotes are consistent across documents: "Agree on everything, yes on the fixes" appears in the record,
  Main.lean, the manifest and N1, and a prefix form in the baseline; the (3)/(1)/(2) quote and the "magic mode" quote
  are identical wherever they appear. M1 and M2 are the provenance gaps.

## What I could not verify

- **The full ladder.** I did not run it. It is running in `bug-hunt-20260929`. At the time of writing its log shows,
  verbatim, `PASSED A1 (240.6s)` through `PASSED A6 (8.0s)`, then `RUN A6b: …` with no `=== RELEASE EXIT` line. The
  lane verdicts quoted in the fix record (S2–S4 and Tier A) are the worker's claims. I did not re-derive them; the
  orchestrator's ladder is the independent re-verification.
- **Tier B.** Including `test_upstream_oracle.py`, which gains the new immaculate case. The record also marks it
  not run.
- **A cache-disabled rebuild.** I did not build. I relied on the driver-freshness stamp of the other worktree for
  binary identity. I did not recompute the `src` hash.
- **The bug hunt's hand-run witnesses** for BUG-4 (`b1_*`) and BUG-5 (`b2_*`, `--libc`, up to 300 s each). Box
  discipline during the ladder ruled out the libc runs. BUG-4 is covered by the immaculate MATCH row in the ladder.
- **gcc values** for the widened R2 fixtures (200, 199) are fixture-comment claims. I did not measure them.
